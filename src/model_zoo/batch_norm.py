import copy

from torch import nn
from torch.nn.utils.fusion import fuse_conv_bn_eval

from model_zoo.adapters import ConvClassifier


def require_folded_batch_norm(model: nn.Module) -> None:
    if any(
        isinstance(layer, nn.BatchNorm1d | nn.BatchNorm2d | nn.BatchNorm3d | nn.SyncBatchNorm)
        for layer in model.modules()
    ):
        raise ValueError("model contains unfolded BatchNorm")


def fold_batch_norm(model: ConvClassifier) -> ConvClassifier:
    """Return a copy with BatchNorm fused into the convolutions."""
    folded = copy.deepcopy(model)
    if folded.batch_norm:
        for index in range(1, len(folded.channels) + 1):
            conv, bn = getattr(folded, f"conv{index}"), getattr(folded, f"bn{index}")
            setattr(folded, f"conv{index}", fuse_conv_bn_eval(conv, bn))
            delattr(folded, f"bn{index}")
        folded.batch_norm = False
    return folded
