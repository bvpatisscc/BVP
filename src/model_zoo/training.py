import copy
import math

import numpy as np
import torch
import torch.nn.functional as F
from torch.optim.swa_utils import update_bn
from torch.utils.data import DataLoader, TensorDataset

from model_zoo.quantization import qat_forward


def augment_batch(inputs, settings, *, boxes=None):
    """Apply train-time augmentations; each sample gets one spatial transform across time bins."""
    if not settings:
        return inputs if boxes is None else (inputs, boxes)
    if boxes is not None and (settings.get("shift", 0) or settings.get("quarter_turns", False)):
        raise ValueError("box targets only support flips and brightness")
    targets = boxes.clone() if boxes is not None else None
    n, h, w = inputs.shape[0], inputs.shape[-2], inputs.shape[-1]
    broadcast = (n,) + (1,) * (inputs.ndim - 1)
    channels = settings.get("channels", inputs.shape[-3])
    x = inputs.narrow(-3, 0, channels)
    shape = x.shape
    shift = settings.get("shift", 0)
    if shift:
        padded = F.pad(x.reshape(n, -1, h, w), (shift,) * 4)
        offset = torch.randint(2 * shift + 1, (n, 2), device=x.device)
        rows = torch.arange(h, device=x.device)[None, :, None] + offset[:, 0, None, None]
        cols = torch.arange(w, device=x.device)[None, None, :] + offset[:, 1, None, None]
        indices = (rows * (w + 2 * shift) + cols).flatten(1)[:, None]
        x = padded.flatten(2).gather(2, indices.expand(-1, padded.shape[1], -1))
        x = x.reshape(shape)
    for key, axis in (("horizontal_flip", -1), ("vertical_flip", -2)):
        if settings.get(key, False):
            mask = (torch.rand(n, device=x.device) < 0.5).reshape(broadcast)
            x = torch.where(mask, x.flip(axis), x)
            if targets is not None:
                coordinate = 0 if axis == -1 else 1
                targets[:, coordinate] = torch.where(
                    mask.flatten(), 1 - targets[:, coordinate], targets[:, coordinate]
                )
    if settings.get("quarter_turns", False):
        turns = torch.randint(4, (n,), device=x.device).reshape(broadcast)
        original = x
        for turn in (1, 2, 3):
            x = torch.where(turns == turn, original.rot90(turn, (-2, -1)), x)
    brightness = settings.get("brightness", 0)
    if brightness:
        scale = 1 + brightness * (2 * torch.rand(broadcast, device=x.device) - 1)
        x = x * scale
    result = torch.cat((x, inputs.narrow(-3, channels, inputs.shape[-3] - channels)), dim=-3)
    return result if targets is None else (result, targets)


def load_data(
    path, *, classes: int, batch_size: int, shuffle: bool, seed: int, include_boxes=False
):
    with np.load(path, allow_pickle=False) as data:
        inputs, labels = data["inputs"].copy(), data["labels"].copy()
        boxes = None
        if include_boxes:
            boxes = data["boxes"].copy()
    if inputs.dtype != np.float32 or inputs.ndim not in (4, 5):
        raise ValueError(f"{path}: inputs must be float32 NCHW or NTCHW")
    if len(labels) != len(inputs) or labels.min() < 0 or labels.max() >= classes:
        raise ValueError(f"{path}: labels must be in [0, {classes})")
    tensors = [torch.from_numpy(inputs), torch.from_numpy(labels.astype(np.int64))]
    if boxes is not None:
        tensors.append(torch.from_numpy(boxes))
    return DataLoader(
        TensorDataset(*tensors),
        batch_size=batch_size,
        shuffle=shuffle,
        generator=torch.Generator().manual_seed(seed),
    )


def fit(
    model,
    loader,
    *,
    epochs,
    learning_rate,
    device,
    classes,
    table=None,
    decimals=None,
    activation_decimals=None,
    momentum=0.9,
    weight_decay=0.0,
    scheduler="constant",
    warmup_epochs=0,
    optimizer_name="sgd",
    loss_name="cross_entropy",
    augmentation=None,
    bbox_loss_weight=0.0,
    ema_decay=0.0,
    bn_recalibration=False,
    seed=None,
    history=None,
    progress=None,
):
    if scheduler not in ("constant", "cosine"):
        raise ValueError(f"unknown scheduler {scheduler!r}")
    if optimizer_name not in ("sgd", "adam", "adamw"):
        raise ValueError(f"unknown optimizer {optimizer_name!r}")
    if loss_name not in ("cross_entropy", "mse"):
        raise ValueError(f"unknown loss {loss_name!r}")
    augmentation = augmentation or {}
    if seed is not None:
        torch.manual_seed(seed)
        if loader.generator is not None:
            loader.generator.manual_seed(seed)
    model.to(device).train()
    averaged = copy.deepcopy(model).eval().requires_grad_(False) if ema_decay else None
    if optimizer_name == "sgd":
        optimizer = torch.optim.SGD(
            model.parameters(), lr=learning_rate, momentum=momentum, weight_decay=weight_decay
        )
    else:
        constructor = torch.optim.Adam if optimizer_name == "adam" else torch.optim.AdamW
        optimizer = constructor(model.parameters(), lr=learning_rate, weight_decay=weight_decay)
    if warmup_epochs:

        def rate_factor(epoch):
            if epoch < warmup_epochs:
                return (epoch + 1) / warmup_epochs
            if scheduler == "constant":
                return 1.0
            progress = (epoch - warmup_epochs) / max(1, epochs - warmup_epochs)
            return 0.5 * (1 + math.cos(math.pi * progress))

        schedule = torch.optim.lr_scheduler.LambdaLR(optimizer, rate_factor)
    else:
        schedule = (
            torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)
            if scheduler == "cosine"
            else None
        )
    for epoch in range(epochs):
        loss_sum = correct = total = 0
        rate = optimizer.param_groups[0]["lr"]
        for batch in loader:
            inputs, labels = batch[:2]
            inputs, labels = inputs.to(device), labels.to(device)
            boxes = None
            if bbox_loss_weight:
                inputs, boxes = augment_batch(inputs, augmentation, boxes=batch[2].to(device))
            else:
                inputs = augment_batch(inputs, augmentation)
            optimizer.zero_grad(set_to_none=True)
            if table is None:
                logits = model(inputs)
            else:
                logits = qat_forward(
                    model,
                    inputs,
                    table=table,
                    weight_decimals=decimals,
                    activation_decimals=activation_decimals,
                )
            scores = logits[:, :classes]
            loss = (
                F.cross_entropy(scores, labels)
                if loss_name == "cross_entropy"
                else F.mse_loss(scores, F.one_hot(labels, classes).to(scores.dtype))
            )
            if boxes is not None:
                positive = labels == 1
                if positive.any():
                    loss = loss + bbox_loss_weight * F.smooth_l1_loss(
                        logits[positive, 2:6].sigmoid(), boxes[positive]
                    )
            if not torch.isfinite(loss):
                raise ValueError(f"loss is {loss.item()} at epoch {epoch + 1}")
            loss.backward()
            optimizer.step()
            if averaged is not None:
                with torch.no_grad():
                    current = model.state_dict()
                    for name, value in averaged.state_dict().items():
                        if value.is_floating_point():
                            value.mul_(ema_decay).add_(current[name], alpha=1 - ema_decay)
                        else:
                            value.copy_(current[name])
            loss_sum += loss.detach().item() * len(labels)
            correct += int((logits.detach()[:, :classes].argmax(1) == labels).sum())
            total += len(labels)
        metrics = {
            "epoch": epoch + 1,
            "learning_rate": rate,
            "loss": loss_sum / total,
            "accuracy": correct / total,
        }
        if history is not None:
            history.append(metrics)
        if progress is not None:
            progress(metrics)
        if schedule is not None:
            schedule.step()
    if averaged is not None:
        model.load_state_dict(averaged.state_dict(), strict=True)
    if bn_recalibration:
        if seed is not None and loader.generator is not None:
            loader.generator.manual_seed(seed)
        update_bn((batch[0] for batch in loader), model, device=device)
    return model.cpu().eval()


@torch.inference_mode()
def evaluate(model, loader, *, device, classes):
    model.to(device).eval()
    correct = total = 0
    for inputs, labels in loader:
        predicted = model(inputs.to(device))[:, :classes].argmax(1).cpu()
        correct += int((predicted == labels).sum())
        total += len(labels)
    model.cpu()
    return {"correct": correct, "total": total, "accuracy": correct / total}
