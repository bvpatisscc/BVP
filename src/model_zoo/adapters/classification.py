import torch
import torch.nn.functional as F
from torch import nn


class _GlobalMaxPool2d(nn.Module):
    def forward(self, inputs: torch.Tensor) -> torch.Tensor:
        return F.max_pool2d(inputs, kernel_size=inputs.shape[-2:])


class ConvClassifier(nn.Module):
    """A configurable convolution chain with one pooled linear classifier."""

    def __init__(self, spec: dict, channels: list[int], *, batch_norm: bool = False):
        super().__init__()
        self.spec = spec
        self.channels = tuple(channels)
        self.batch_norm = batch_norm
        previous = spec["input_shape"][0]
        for index, (width, stride) in enumerate(zip(channels, spec["strides"], strict=True), 1):
            setattr(self, f"conv{index}", nn.Conv2d(previous, width, 3, stride=stride, padding=1))
            if batch_norm:
                setattr(self, f"bn{index}", nn.BatchNorm2d(width))
            previous = width
        self.pool = nn.MaxPool2d(2, 2)
        self.global_pool = (
            nn.AdaptiveAvgPool2d(1) if spec["global_pool"] == "avg" else _GlobalMaxPool2d()
        )
        self.fc = nn.Linear(previous, spec["outputs"])

    @property
    def layers(self):
        return tuple(f"conv{i}" for i in range(1, len(self.channels) + 1)) + ("fc",)

    def forward(self, inputs: torch.Tensor) -> torch.Tensor:
        temporal = self.spec.get("temporal", "none")
        if inputs.ndim == 5:
            if temporal == "sum":
                inputs = inputs.sum(1)
            elif temporal == "mean_logits":
                batch, bins = inputs.shape[:2]
                return self(inputs.flatten(0, 1)).reshape(batch, bins, -1).mean(1)
            else:
                raise ValueError("NTCHW inputs require model.temporal to be sum or mean_logits")
        if tuple(inputs.shape[1:]) != tuple(self.spec["input_shape"]):
            raise ValueError(f"input shape {tuple(inputs.shape[1:])} != {self.spec['input_shape']}")
        crop = self.spec.get("crop", 0)
        x = inputs[:, :, crop:-crop, crop:-crop] if crop else inputs
        for index in range(1, len(self.channels) + 1):
            x = getattr(self, f"conv{index}")(x)
            if self.batch_norm:
                x = getattr(self, f"bn{index}")(x)
            x = F.relu(x)
            if index in self.spec["pool_after"]:
                x = self.pool(x)
        return self.fc(self.global_pool(x).flatten(1))
