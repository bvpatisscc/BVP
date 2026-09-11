from itertools import islice

import torch
import torch.nn.functional as F
from torch import nn


@torch.inference_mode()
def search_weight_decimals(
    model, loader, *, layers, table, batches=32, device="cpu", output_counts=None
):
    """Pick each layer's weight decimal (0..15) by the MSE of its output against FP32.

    Every candidate sees the same FP32 inputs, so the bias cancels. Ties go to the
    smaller decimal. `output_counts` restricts scoring to the first N outputs of a layer.
    """
    layers = tuple(layers)
    modules = dict(model.named_modules())
    output_counts = output_counts or {}
    candidates = tuple(range(16))
    errors = {name: [0.0] * len(candidates) for name in layers}
    counts = dict.fromkeys(layers, 0)
    original_device = next(model.parameters()).device
    modes = {module: module.training for module in model.modules()}
    handles = []
    seen_batches = 0
    try:
        model.to(device).eval()
        for name in layers:
            layer = modules[name]
            differences = [table.quantize(layer.weight, d) - layer.weight for d in candidates]

            def observe(module, inputs, output, name=name, differences=differences):
                x = inputs[0]
                for index, difference in enumerate(differences):
                    if isinstance(module, nn.Conv2d):
                        error = F.conv2d(
                            x,
                            difference,
                            None,
                            module.stride,
                            module.padding,
                            module.dilation,
                            module.groups,
                        )
                    else:
                        error = F.linear(x, difference)
                    if name in output_counts:
                        axis = 1 if isinstance(module, nn.Conv2d) else -1
                        error = error.narrow(axis, 0, output_counts[name])
                    errors[name][index] += float(error.double().square().sum())
                if name in output_counts:
                    axis = 1 if isinstance(module, nn.Conv2d) else -1
                    output = output.narrow(axis, 0, output_counts[name])
                counts[name] += output.numel()

            handles.append(layer.register_forward_hook(observe))
        for batch in islice(loader, batches):
            model(batch[0].to(device).float())
            seen_batches += 1
        if not all(counts.values()):
            raise ValueError("calibration loader is empty")
    finally:
        for handle in handles:
            handle.remove()
        model.to(original_device)
        for module, training in modes.items():
            module.training = training
    selected = {name: min(candidates, key=lambda d: errors[name][d]) for name in layers}
    report = {
        "batches": seen_batches,
        "candidates": list(candidates),
        "output_counts": output_counts,
        "layers": {
            name: {
                "decimal": selected[name],
                "mse": errors[name][selected[name]] / counts[name],
                "candidate_mse": [value / counts[name] for value in errors[name]],
                "output_elements": counts[name],
            }
            for name in layers
        },
    }
    return selected, report
