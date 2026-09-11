import copy

import torch
from torch import nn

from model_zoo.adapters import ConvClassifier
from model_zoo.batch_norm import require_folded_batch_norm


@torch.no_grad()
def cross_layer_equalize(model: ConvClassifier, *, rounds: int) -> ConvClassifier:
    """Cross-layer equalization: rescale each channel boundary so weight ranges match.

    The function is unchanged because ReLU and pooling commute with positive scaling.
    Factors are clamped to [1/16, 16] per round.
    """
    require_folded_batch_norm(model)
    equalized = copy.deepcopy(model).cpu().eval()
    modules = dict(equalized.named_modules())
    layers = [modules[name] for name in equalized.layers]
    for _ in range(rounds):
        for upstream, downstream in zip(layers, layers[1:]):
            left = upstream.weight.flatten(1).abs().amax(1).double()
            right = (
                downstream.weight.abs()
                .amax((0, 2, 3) if isinstance(downstream, nn.Conv2d) else 0)
                .double()
            )
            valid = (left > 0) & (right > 0)
            scale = torch.ones_like(left)
            scale[valid] = (left[valid] / right[valid]).sqrt().clamp(1 / 16, 16)
            scale = scale.to(upstream.weight.dtype)
            upstream.weight.div_(scale.reshape(-1, *([1] * (upstream.weight.ndim - 1))))
            if upstream.bias is not None:
                upstream.bias.div_(scale)
            shape = (1, -1, 1, 1) if isinstance(downstream, nn.Conv2d) else (1, -1)
            downstream.weight.mul_(scale.reshape(shape))
    return equalized
