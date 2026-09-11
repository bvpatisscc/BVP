"""16-bit fixed-point accumulation in the accelerator's summation order.

Each Conv/FC layer multiplies INT8 inputs by two-digit CSSD weights and sums
the products in signed 16-bit saturating arithmetic: per digit, then the even
and odd channel lanes, then the kernel rows, then the bias. The result is
shifted with round-to-nearest-even and clipped to INT8. A Triton kernel runs
on CUDA; a slower PyTorch implementation of the same order runs elsewhere.
"""

import copy
import json
from contextlib import contextmanager
from functools import lru_cache
from pathlib import Path

import torch
import torch.nn.functional as F
from torch import nn

try:
    import triton
    import triton.language as tl
except ImportError:
    triton = None


def _jit(function):
    return triton.jit(function) if triton is not None else function


@_jit
def _add16(a, b):
    value = a + b
    clipped = (value < -32768) | (value > 32767)
    return tl.minimum(tl.maximum(value, -32768), 32767), clipped.to(tl.int32)


@_jit
def _kernel(
    X,
    D,
    B,
    Y,
    Stats,
    N: tl.constexpr,
    IC: tl.constexpr,
    OC: tl.constexpr,
    H: tl.constexpr,
    W: tl.constexpr,
    OH: tl.constexpr,
    OW: tl.constexpr,
    K: tl.constexpr,
    S: tl.constexpr,
    P: tl.constexpr,
    BLOCK: tl.constexpr,
):
    index = tl.program_id(0) * BLOCK + tl.arange(0, BLOCK)
    valid = index < N * OC * OH * OW
    ox = index % OW
    oy = index // OW % OH
    oc = index // (OH * OW) % OC
    n = index // (OC * OH * OW)
    total = tl.full((BLOCK,), 0, tl.int32)
    pe_clips = tl.full((BLOCK,), 0, tl.int32)
    lane_clips = tl.full((BLOCK,), 0, tl.int32)
    row_clips = tl.full((BLOCK,), 0, tl.int32)
    for ky in tl.static_range(K):
        even = tl.full((BLOCK,), 0, tl.int32)
        odd = tl.full((BLOCK,), 0, tl.int32)
        iy = oy * S + ky - P
        for kx in tl.static_range(K):
            ix = ox * S + kx - P
            inside = valid & (iy >= 0) & (iy < H) & (ix >= 0) & (ix < W)
            for ch in range(0, IC, 2):
                a0 = tl.load(X + ((n * IC + ch) * H + iy) * W + ix, inside, 0)
                a1 = tl.load(X + ((n * IC + ch + 1) * H + iy) * W + ix, inside, 0)
                for digit in tl.static_range(2):
                    d0 = tl.load(D + ((((oc * IC + ch) * K + ky) * K + kx) * 2 + digit), valid, 0)
                    offset1 = (((oc * IC + ch + 1) * K + ky) * K + kx) * 2 + digit
                    d1 = tl.load(D + offset1, valid, 0)
                    even, c0 = _add16(even, a0 * d0)
                    odd, c1 = _add16(odd, a1 * d1)
                    pe_clips += c0 + c1
        row, c = _add16(even, odd)
        lane_clips += c
        total, c = _add16(total, row)
        row_clips += c
    bias = tl.load(B + oc, valid, 0)
    total, bias_clips = _add16(total, bias)
    tl.store(Y + index, total, valid)
    base = tl.program_id(0) * 4
    tl.store(Stats + base, tl.sum(tl.where(valid, pe_clips, 0)))
    tl.store(Stats + base + 1, tl.sum(tl.where(valid, lane_clips, 0)))
    tl.store(Stats + base + 2, tl.sum(tl.where(valid, row_clips, 0)))
    tl.store(Stats + base + 3, tl.sum(tl.where(valid, bias_clips, 0)))


def _integer_layer_torch(x, digits, bias, stride, k, pad):
    n, ic, h, w = x.shape
    oc = digits.shape[0]
    oh, ow = (h + 2 * pad - k) // stride + 1, (w + 2 * pad - k) // stride + 1
    padded = F.pad(x, (pad, pad, pad, pad))
    digits = digits.reshape(oc, ic, k, k, 2)
    counts = [0, 0, 0, 0]

    def add16(a, b, slot):
        value = a + b
        counts[slot] += int(((value < -32768) | (value > 32767)).sum())
        return value.clamp(-32768, 32767)

    total = torch.zeros((n, oc, oh, ow), dtype=torch.int32, device=x.device)
    for ky in range(k):
        even = torch.zeros_like(total)
        odd = torch.zeros_like(total)
        for kx in range(k):
            patch = padded[:, :, ky : ky + stride * oh : stride, kx : kx + stride * ow : stride]
            for ch in range(0, ic, 2):
                a0, a1 = patch[:, ch : ch + 1], patch[:, ch + 1 : ch + 2]
                for digit in range(2):
                    d0 = digits[:, ch, ky, kx, digit].view(1, oc, 1, 1)
                    d1 = digits[:, ch + 1, ky, kx, digit].view(1, oc, 1, 1)
                    even = add16(even, a0 * d0, 0)
                    odd = add16(odd, a1 * d1, 0)
        total = add16(total, add16(even, odd, 1), 2)
    total = add16(total, bias.view(1, oc, 1, 1), 3)
    return total, torch.tensor(counts, dtype=torch.int64)


def integer_layer(x, digits, bias, stride=1):
    """Return the INT16 layer output before output rounding, plus four saturation counts."""
    fc = digits.ndim == 3
    if fc:
        x = x[:, :, None, None]
    if x.shape[1] % 2:
        x = F.pad(x, (0, 0, 0, 0, 0, 1))
        digits = F.pad(digits, (0, 0) * (digits.ndim - 2) + (0, 1))
    n, ic, h, w = x.shape
    oc, k = digits.shape[0], 1 if fc else 3
    assert stride in (1, 2)
    assert digits.shape == ((oc, ic, 2) if fc else (oc, ic, 3, 3, 2))
    assert x.dtype == digits.dtype == bias.dtype == torch.int32
    x, digits, bias = x.contiguous(), digits.contiguous(), bias.contiguous()
    pad = 0 if fc else 1
    if not x.is_cuda:
        output, stats = _integer_layer_torch(x, digits, bias, stride, k, pad)
        return (output[:, :, 0, 0] if fc else output), stats
    oh, ow = (h + 2 * pad - k) // stride + 1, (w + 2 * pad - k) // stride + 1
    output = torch.empty((n, oc, oh, ow), device=x.device, dtype=torch.int32)
    blocks = triton.cdiv(output.numel(), 256)
    stats = torch.empty((blocks, 4), device=x.device, dtype=torch.int32)
    _kernel[(blocks,)](x, digits, bias, output, stats, n, ic, oc, h, w, oh, ow, k, stride, pad, 256)
    return (output[:, :, 0, 0] if fc else output), stats.sum(0, dtype=torch.int64)


def decode_digits(raw, database):
    """Split each CSSD code into its two signed power-of-two digits."""
    raw = raw.cpu()
    assert torch.equal(raw, raw.round())
    digits = torch.zeros((*raw.shape, 2), dtype=torch.int32)
    for code in raw.unique().tolist():
        code = int(code)
        if code == 0:
            continue
        entry = database.get(str(code))
        if entry is None or int(entry["bc_decimal"]) != code:
            candidates = [e for e in database.values() if int(e["bc_decimal"]) == code]
        else:
            candidates = [entry]
        decoded = None
        for candidate in candidates:
            powers = candidate["powers"]
            values = [
                (-1 if str(p).startswith("-") else 1) * 2 ** int(str(p).lstrip("-")) for p in powers
            ]
            if len(values) == 2 and sum(values) == code:
                decoded = values
                break
        if decoded is None:
            raise ValueError(f"No valid two-digit encoding for code {code}")
        if abs(decoded[0]) <= 1 or any(abs(v) > 128 for v in decoded):
            raise ValueError(f"Unsupported digit encoding: {code} {decoded}")
        digits[raw == code] = torch.tensor(decoded, dtype=torch.int32)
    assert torch.equal(digits.sum(-1).float(), raw.float())
    return digits


def round_shift(value, shift):
    """Arithmetic right shift with round-to-nearest-even."""
    if not 0 <= shift <= 15:
        raise ValueError(f"output shift {shift} must be in [0, 15]")
    if shift == 0:
        return value
    select = (value >> shift) & 1
    rounding = (1 << (shift - 1)) - 1 + select
    return (value + rounding) >> shift


@lru_cache(maxsize=16)
def digit_lut(table_path, device):
    database = json.loads(Path(table_path).read_text())
    codes = torch.tensor(sorted({int(v["bc_decimal"]) for v in database.values()}))
    if int(codes.min()) < -129 or int(codes.max()) > 127:
        raise ValueError("unsupported two-digit CSSD code range")
    lut = torch.zeros((257, 2), dtype=torch.int32)
    lut[codes + 129] = decode_digits(codes, database)
    return lut.to(device)


class Int16Layer(nn.Module):
    """Inference replacement for one Conv/FC layer using the INT16 accumulator."""

    def __init__(self, state, name, module, next_decimal, database):
        super().__init__()
        self.ad = int(state[f"{name}.act_quantizer.decimal_num"].item())
        self.wd = int(state[f"{name}.weight_quantizer.decimal_num"].item())
        self.od = next_decimal
        assert 0 <= self.ad <= 7 and 0 <= self.wd <= 15
        self.shift = self.ad + self.wd - self.od
        assert 0 <= self.shift <= 15
        self.stride = module.stride[0] if isinstance(module, nn.Conv2d) else 1
        if isinstance(module, nn.Conv2d):
            assert module.kernel_size == (3, 3) and module.padding == (1, 1)
            assert module.dilation == (1, 1) and module.groups == 1
        raw = state[f"{name}.quantized_weight"].cpu() * 2**self.wd
        self.register_buffer("digits", decode_digits(raw, database))
        bias = (state[f"{name}.bias"].cpu() * 2 ** (self.ad + self.wd)).round()
        assert bool(((bias >= -32768) & (bias <= 32767)).all())
        self.register_buffer("bias", bias.to(torch.int32))
        self.register_buffer("clips", torch.zeros(5, dtype=torch.int64))
        self.output_count = 0

    def forward(self, inputs):
        x = (inputs * 2**self.ad).round().clamp(-128, 127).to(torch.int32)
        y, clips = integer_layer(x, self.digits, self.bias, self.stride)
        self.clips[:4] += clips
        self.output_count += y.numel()
        rounded = round_shift(y, self.shift)
        self.clips[4] += ((rounded < -128) | (rounded > 127)).sum()
        return rounded.clamp(-128, 127).float() / 2**self.od

    def statistics(self):
        return dict(
            zip(
                ("pe_digit", "lane_merge", "row_merge", "bias_add", "output_int8"),
                self.clips.cpu().tolist(),
            ),
            output_elements=self.output_count,
            activation_decimal=self.ad,
            weight_decimal=self.wd,
            output_decimal=self.od,
            round_shift=self.shift,
        )


def load_checkpoint(model, state, *, table):
    """Return a copy of the model whose Conv/FC layers run on the INT16 accumulator."""
    database = json.loads(Path(table.path).read_text())
    model = copy.deepcopy(model)
    layers = model.layers
    for i, name in enumerate(layers):
        next_name = layers[min(i + 1, len(layers) - 1)]
        od = int(state[f"{next_name}.act_quantizer.decimal_num"].item())
        model.set_submodule(name, Int16Layer(state, name, model.get_submodule(name), od, database))
    return model.eval()


class ExactForward(torch.autograd.Function):
    @staticmethod
    def forward(ctx, surrogate, exact):
        return exact

    @staticmethod
    def backward(ctx, gradient):
        return gradient, None


@contextmanager
def int16_qat_forward(model, table, weight_decimals, activation_decimals):
    """Replace each layer's forward value with the INT16 result; gradients stay straight-through."""
    if set(model.layers) != set(weight_decimals) or set(model.layers) != set(activation_decimals):
        raise ValueError("scales must cover every quantized layer")
    handles = []
    try:
        for i, name in enumerate(model.layers):
            module = model.get_submodule(name)
            ad, wd = activation_decimals[name], weight_decimals[name]
            following = model.layers[min(i + 1, len(model.layers) - 1)]
            od = activation_decimals[following]
            shift = ad + wd - od
            if not (0 <= ad <= 7 and 0 <= wd <= 15 and 0 <= shift <= 15):
                raise ValueError(f"unsupported scale for {name}: {ad=} {wd=} {od=}")
            if not isinstance(module, nn.Conv2d | nn.Linear):
                raise TypeError(f"unsupported layer {name}")
            stride = module.stride[0] if isinstance(module, nn.Conv2d) else 1
            if isinstance(module, nn.Conv2d) and (
                module.kernel_size != (3, 3)
                or module.padding != (1, 1)
                or module.dilation != (1, 1)
                or module.groups != 1
            ):
                raise ValueError("only dense padded 3x3 convolutions are supported")

            def exact_hook(layer, inputs, output, ad=ad, wd=wd, od=od, shift=shift, stride=stride):
                with torch.no_grad():
                    x = (inputs[0] * 2**ad).round().clamp(-128, 127).to(torch.int32)
                    codes = (layer.weight * 2**wd).round().long()
                    digits = digit_lut(str(table.path), str(x.device))[codes + 129]
                    bias = layer.bias * 2 ** (ad + wd)
                    bias = bias.round().clamp(-32768, 32767).to(torch.int32)
                    y, _ = integer_layer(x, digits, bias, stride)
                    exact = round_shift(y, shift).clamp(-128, 127).float() / 2**od
                return ExactForward.apply(output, exact)

            handles.append(module.register_forward_hook(exact_hook))
        yield
    finally:
        for handle in handles:
            handle.remove()
