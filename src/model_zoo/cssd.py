import copy
import json
from collections import OrderedDict
from collections.abc import Mapping, Sequence
from pathlib import Path
from typing import Any

import torch


class SymmetricNzdTable:
    """Maps each signed INT8 code to the nearest code with at most two nonzero digits."""

    def __init__(self, mapped_codes: torch.Tensor, path: Path | None = None):
        self.mapped_codes = mapped_codes
        self.path = path

    @classmethod
    def load(cls, path: Path) -> "SymmetricNzdTable":
        table = json.loads(Path(path).read_text())
        codes = [int(table[str(code)]["bc_decimal"]) for code in range(-128, 128)]
        return cls(torch.tensor(codes, dtype=torch.int64), Path(path))

    def quantize(self, weight: torch.Tensor, decimal: int) -> torch.Tensor:
        scale = 1 << decimal
        codes = torch.clamp(torch.round(weight * scale), -128, 127).to(torch.int64)
        mapped = self.mapped_codes.to(codes.device)[codes + 128]
        return mapped.to(weight.dtype) / float(scale)


def quantize_symmetric_nzd(
    source: Mapping[str, torch.Tensor],
    *,
    table: SymmetricNzdTable,
    weight_decimals: Mapping[str, int],
    layers: Sequence[str],
) -> tuple[OrderedDict[str, torch.Tensor], dict[str, Any]]:
    state: OrderedDict[str, torch.Tensor] = copy.deepcopy(OrderedDict(source))
    per_layer: dict[str, Any] = {}
    total_weights = total_changed = 0
    for layer in layers:
        decimal = int(weight_decimals[layer])
        weight = state[f"{layer}.weight"]
        scale = 1 << decimal
        original_codes = torch.clamp(torch.round(weight * scale), -128, 127).to(torch.int64)
        state[f"{layer}.quantized_weight"] = table.quantize(weight, decimal)
        mapped_codes = torch.round(state[f"{layer}.quantized_weight"] * scale).to(torch.int64)
        changed = int((mapped_codes != original_codes).sum())
        total_changed += changed
        total_weights += weight.numel()
        per_layer[layer] = {"decimal": decimal, "weights": weight.numel(), "changed": changed}
        for suffix, value in (
            ("scale", 1.0 / scale),
            ("integer_num", 8.0 - decimal),
            ("decimal_num", float(decimal)),
            ("pow2_scale", 1.0 / scale),
        ):
            key = f"{layer}.weight_quantizer.{suffix}"
            state[key] = torch.full_like(state[key], value)
    return state, {"weights": total_weights, "changed": total_changed, "layers": per_layer}
