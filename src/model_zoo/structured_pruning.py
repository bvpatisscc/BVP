from dataclasses import dataclass
from typing import Any

import torch
from torch import nn


def channel_schedule(init, target, steps):
    """Channel widths for each pruning step, interpolated linearly from init to target."""
    return [
        [b + (a - b) * (steps - index) // steps for a, b in zip(init, target, strict=True)]
        for index in range(1, steps + 1)
    ]


@dataclass(frozen=True)
class StructuredPruningResult:
    model: nn.Module
    selected: dict[str, list[int]]


def _direct_modules(model: nn.Module, module_type: type[nn.Module]) -> list[tuple[str, Any]]:
    return [
        (name, module) for name, module in model.named_children() if isinstance(module, module_type)
    ]


def _validate_chain(source: nn.Module, target: nn.Module):
    source_convs = _direct_modules(source, nn.Conv2d)
    target_convs = _direct_modules(target, nn.Conv2d)
    source_bns = _direct_modules(source, nn.BatchNorm2d)
    target_bns = _direct_modules(target, nn.BatchNorm2d)
    source_fcs = _direct_modules(source, nn.Linear)
    target_fcs = _direct_modules(target, nn.Linear)
    if [name for name, _ in source_convs] != [name for name, _ in target_convs]:
        raise ValueError("source and target convolution chains differ")
    if bool(source_bns) != bool(target_bns):
        raise ValueError("only one of the models has BatchNorm")
    for name, source_conv in source_convs:
        if source_conv.groups != 1:
            raise ValueError(f"{name}: grouped convolutions are not supported")
    for (name, source_conv), (_, target_conv) in zip(source_convs, target_convs, strict=True):
        if target_conv.out_channels > source_conv.out_channels:
            raise ValueError(f"{name}: target is wider than source")
    return (
        source_convs,
        source_bns,
        source_fcs[0],
        target_convs,
        target_bns,
        target_fcs[0],
    )


def two_layer_channel_scores(
    current_weight: torch.Tensor,
    downstream_weight: torch.Tensor,
    input_indices: torch.Tensor,
    norm: str,
) -> torch.Tensor:
    if norm not in ("l1", "l2"):
        raise ValueError(f"unknown norm {norm!r}")
    current = current_weight.detach().to(device="cpu", dtype=torch.float64)
    current = current.index_select(1, input_indices.to(device="cpu"))
    downstream = downstream_weight.detach().to(device="cpu", dtype=torch.float64)
    current_dimensions = tuple(range(1, current.ndim))
    downstream_dimensions = (0,) if downstream.ndim == 2 else (0, 2, 3)
    if norm == "l1":
        return current.abs().sum(dim=current_dimensions) + downstream.abs().sum(
            dim=downstream_dimensions
        )
    return (
        current.square().sum(dim=current_dimensions)
        + downstream.square().sum(dim=downstream_dimensions)
    ).sqrt()


def _select(scores: torch.Tensor, count: int) -> tuple[int, ...]:
    ranked = sorted(range(scores.numel()), key=lambda index: (-float(scores[index]), index))
    return tuple(sorted(ranked[:count]))


def _copy_batch_norm(
    source: nn.BatchNorm2d,
    target: nn.BatchNorm2d,
    output_indices: torch.Tensor,
) -> None:
    if target.num_features != output_indices.numel():
        raise ValueError("BatchNorm width does not match selected channels")
    with torch.no_grad():
        if (
            source.affine != target.affine
            or source.track_running_stats != target.track_running_stats
        ):
            raise ValueError("BatchNorm affine or track_running_stats settings differ")
        if source.affine:
            target.weight.copy_(source.weight.index_select(0, output_indices))
            target.bias.copy_(source.bias.index_select(0, output_indices))
        if source.track_running_stats:
            target.running_mean.copy_(source.running_mean.index_select(0, output_indices))
            target.running_var.copy_(source.running_var.index_select(0, output_indices))
            target.num_batches_tracked.copy_(source.num_batches_tracked)


def prune_channel_chain(
    source: nn.Module,
    target: nn.Module,
    *,
    norm: str = "l2",
    score_source: nn.Module | None = None,
) -> StructuredPruningResult:
    (
        source_convs,
        source_bns,
        source_fc,
        target_convs,
        target_bns,
        target_fc,
    ) = _validate_chain(source, target)
    score_convs = source_convs
    score_fc = source_fc
    if score_source is not None:
        score_convs = _direct_modules(score_source, nn.Conv2d)
        score_fc = _direct_modules(score_source, nn.Linear)[0]
    input_indices = torch.arange(source_convs[0][1].in_channels, dtype=torch.long)
    selected: dict[str, list[int]] = {}
    selected_by_layer: list[torch.Tensor] = []
    for index, ((name, source_conv), (_, target_conv)) in enumerate(
        zip(source_convs, target_convs, strict=True)
    ):
        downstream = (
            score_convs[index + 1][1].weight if index + 1 < len(score_convs) else score_fc[1].weight
        )
        scores = two_layer_channel_scores(
            score_convs[index][1].weight,
            downstream,
            input_indices,
            norm,
        )
        selected[name] = list(_select(scores, target_conv.out_channels))
        selected_tensor = torch.tensor(selected[name], dtype=torch.long)
        selected_by_layer.append(selected_tensor)
        input_indices = selected_tensor

    previous_inputs = torch.arange(source_convs[0][1].in_channels, dtype=torch.long)
    with torch.no_grad():
        for index, ((_, source_conv), (_, target_conv), outputs) in enumerate(
            zip(source_convs, target_convs, selected_by_layer, strict=True)
        ):
            weight = source_conv.weight.index_select(0, outputs).index_select(1, previous_inputs)
            target_conv.weight.copy_(weight)
            if source_conv.bias is not None and target_conv.bias is not None:
                target_conv.bias.copy_(source_conv.bias.index_select(0, outputs))
            elif source_conv.bias is not None or target_conv.bias is not None:
                raise ValueError("convolution bias mismatch")
            if source_bns:
                _copy_batch_norm(source_bns[index][1], target_bns[index][1], outputs)
            previous_inputs = outputs
        target_fc[1].weight.copy_(source_fc[1].weight.index_select(1, previous_inputs))
        if source_fc[1].bias is not None and target_fc[1].bias is not None:
            target_fc[1].bias.copy_(source_fc[1].bias)
        elif source_fc[1].bias is not None or target_fc[1].bias is not None:
            raise ValueError("linear bias mismatch")
    return StructuredPruningResult(model=target, selected=selected)
