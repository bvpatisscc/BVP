import math
from itertools import islice

import torch


@torch.inference_mode()
def calibrate_activations(
    model,
    loader,
    *,
    layers,
    batches=32,
    device="cpu",
    weight_decimals=None,
    method="max_range",
    report=None,
):
    """Choose a power-of-two INT8 input scale for each layer from unlabeled batches."""
    if method not in ("max_range", "mse"):
        raise ValueError(f"unknown calibration method {method!r}")
    modules = dict(model.named_modules())
    maxima = dict.fromkeys(layers, 0.0)
    seen = dict.fromkeys(layers, 0)
    candidates = tuple(range(-16, 8))
    errors = {name: [0.0] * len(candidates) for name in layers}
    counts = dict.fromkeys(layers, 0)
    hooks = []
    original_device = next(model.parameters()).device
    modes = {module: module.training for module in model.modules()}
    try:
        model.to(device).eval()
        for layer in layers:

            def observe(_module, inputs, name=layer):
                values = inputs[0].detach()
                maxima[name] = max(maxima[name], float(values.abs().max()))
                seen[name] += 1
                if method == "mse":
                    for index, decimal in enumerate(candidates):
                        scale = 2.0**decimal
                        quantized = (values * scale).round().clamp(-128, 127) / scale
                        errors[name][index] += float((values - quantized).double().square().sum())
                    counts[name] += values.numel()

            hooks.append(modules[layer].register_forward_pre_hook(observe))
        for batch in islice(loader, batches):
            inputs = batch[0].to(device).float()
            model(inputs)
        if not all(seen.values()):
            raise ValueError("calibration loader is empty")
    finally:
        for hook in hooks:
            hook.remove()
        model.to(original_device)
        for module, training in modes.items():
            module.training = training
    decimals = {
        name: min(7, math.floor(math.log2(127.0 / maximum))) if maximum else 7
        for name, maximum in maxima.items()
    }
    if method == "mse":
        for name in layers:
            admissible = list(candidates)
            if weight_decimals is not None and modules[name].bias is not None:
                bias = modules[name].bias.detach()
                admissible = [
                    d
                    for d in candidates
                    if bool(
                        ((bias * 2.0 ** (weight_decimals[name] + d)).round() >= -32768).all()
                        and ((bias * 2.0 ** (weight_decimals[name] + d)).round() <= 32767).all()
                    )
                ]
            if not admissible:
                raise ValueError(f"{name}: no activation scale keeps the bias within INT16")
            decimals[name] = min(admissible, key=lambda d: errors[name][d - candidates[0]])
    if weight_decimals is not None:
        for name in layers:
            bias = modules[name].bias
            if bias is None:
                continue
            while True:
                codes = torch.round(
                    bias.detach() * (2.0 ** (weight_decimals[name] + decimals[name]))
                )
                if not ((codes < -32768) | (codes > 32767)).any():
                    break
                decimals[name] -= 1
    if report is not None:
        report.update(
            method=method,
            candidates=list(candidates) if method == "mse" else None,
            layers={
                name: {
                    "decimal": decimals[name],
                    "maximum": maxima[name],
                    "candidate_mse": (
                        [value / counts[name] for value in errors[name]]
                        if method == "mse"
                        else None
                    ),
                }
                for name in layers
            },
        )
    return decimals
