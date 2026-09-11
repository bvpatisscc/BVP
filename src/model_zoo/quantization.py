import copy
from collections import OrderedDict
from collections.abc import Mapping, Sequence
from contextlib import contextmanager

import torch
from torch import nn

from model_zoo.batch_norm import require_folded_batch_norm


def add_power_of_two_quantizer_state(
    source: Mapping[str, torch.Tensor],
    *,
    weight_decimals: Mapping[str, int],
    activation_decimals: Mapping[str, int],
    layers: Sequence[str],
) -> OrderedDict[str, torch.Tensor]:
    state: OrderedDict[str, torch.Tensor] = copy.deepcopy(OrderedDict(source))
    for layer in layers:
        weight = state[f"{layer}.weight"]
        weight_decimal = int(weight_decimals[layer])
        activation_decimal = int(activation_decimals[layer])
        weight_scale = 2.0**weight_decimal
        state[f"{layer}.n_bits_w"] = torch.tensor([8.0])
        state[f"{layer}.n_bits_a"] = torch.tensor([8.0])
        state[f"{layer}.quantized_weight"] = (
            torch.clamp(torch.round(weight * weight_scale), -128, 127) / weight_scale
        )
        for prefix, decimal in (
            ("weight_quantizer", weight_decimal),
            ("act_quantizer", activation_decimal),
        ):
            scale = 2.0**decimal
            for suffix, value in (
                ("scale", 1.0 / scale),
                ("integer_num", 8.0 - decimal),
                ("decimal_num", float(decimal)),
                ("pow2_scale", 1.0 / scale),
            ):
                state[f"{layer}.{prefix}.{suffix}"] = torch.tensor([value])
    return state


def load_quantized_weights(
    model: nn.Module,
    state: Mapping[str, torch.Tensor],
    *,
    layers: Sequence[str],
) -> nn.Module:
    require_folded_batch_norm(model)
    quantized = copy.deepcopy(model)
    modules = dict(quantized.named_modules())
    with torch.no_grad():
        for layer in layers:
            modules[layer].weight.copy_(state[f"{layer}.quantized_weight"])
            modules[layer].bias.copy_(state[f"{layer}.bias"])
    return quantized


def _scalar_decimal(state: Mapping[str, torch.Tensor], key: str) -> int:
    return int(state[key].reshape(-1)[0].item())


def quantize_signed(tensor: torch.Tensor, bits: int, decimal: int) -> torch.Tensor:
    scale = 2.0**decimal
    lower = -(1 << (bits - 1))
    upper = (1 << (bits - 1)) - 1
    return torch.clamp(torch.round(tensor * scale), lower, upper) / scale


def load_full_hardware_weights(
    model: nn.Module,
    state: Mapping[str, torch.Tensor],
    *,
    layers: Sequence[str],
) -> nn.Module:
    """Return a copy that quantizes layer inputs to INT8 and biases to INT16."""
    quantized = load_quantized_weights(model, state, layers=layers)
    modules = dict(quantized.named_modules())
    for layer in layers:
        module = modules[layer]
        weight_decimal = _scalar_decimal(state, f"{layer}.weight_quantizer.decimal_num")
        activation_decimal = _scalar_decimal(state, f"{layer}.act_quantizer.decimal_num")
        if module.bias is not None:
            bias_decimal = weight_decimal + activation_decimal
            codes = torch.round(module.bias.detach() * 2.0**bias_decimal)
            clipped = int((codes.abs() > (1 << 15) - 1).sum())
            if clipped:
                raise ValueError(f"{layer}: {clipped} biases overflow INT16")
            with torch.no_grad():
                module.bias.copy_(quantize_signed(module.bias, 16, bias_decimal))

        def quantize_input(
            _module: nn.Module,
            inputs: tuple[torch.Tensor, ...],
            decimal: int = activation_decimal,
        ) -> tuple[torch.Tensor, ...]:
            return (quantize_signed(inputs[0], 8, decimal), *inputs[1:])

        module.register_forward_pre_hook(quantize_input)
    return quantized.eval()


def fake_quantize_signed(tensor, bits, decimal):
    """Quantize with a straight-through gradient, clipped at the representable range."""
    scale = 2.0**decimal
    bounded = tensor.clamp(-(1 << (bits - 1)) / scale, ((1 << (bits - 1)) - 1) / scale)
    return bounded + (quantize_signed(tensor, bits, decimal) - bounded).detach()


@contextmanager
def activation_fake_quantization(model, decimals):
    modules = dict(model.named_modules())
    handles = []
    try:
        for name, decimal in decimals.items():

            def quantize_input(_module, inputs, decimal=decimal):
                return (fake_quantize_signed(inputs[0], 8, decimal), *inputs[1:])

            handles.append(modules[name].register_forward_pre_hook(quantize_input))
        yield
    finally:
        for handle in handles:
            handle.remove()


def qat_forward(model, inputs, *, table, weight_decimals, activation_decimals):
    """QAT forward pass with CSSD weights, INT8 layer inputs and INT16 accumulation."""
    from torch.func import functional_call

    from model_zoo.accumulator import int16_qat_forward

    parameters = dict(model.named_parameters())
    for name, decimal in weight_decimals.items():
        weight = parameters[f"{name}.weight"]
        discrete = table.quantize(weight, decimal)
        parameters[f"{name}.weight"] = weight + (discrete - weight).detach()
        bias_name = f"{name}.bias"
        if bias_name in parameters:
            parameters[bias_name] = fake_quantize_signed(
                parameters[bias_name], 16, decimal + activation_decimals[name]
            )
    accumulate = int16_qat_forward(model, table, weight_decimals, activation_decimals)
    with activation_fake_quantization(model, activation_decimals), accumulate:
        return functional_call(model, parameters, (inputs,))
