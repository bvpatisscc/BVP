import torch

from model_zoo.adapters import ConvClassifier
from model_zoo.batch_norm import fold_batch_norm


def fp32_checkpoint(model: ConvClassifier) -> tuple[ConvClassifier, dict]:
    """Return the folded inference model and a payload holding both views."""
    model.cpu().eval()
    folded = fold_batch_norm(model)
    payload = {"model": folded.state_dict()}
    if model.batch_norm:
        payload["training_model"] = model.state_dict()
    return folded, payload


def load_training_checkpoint(checkpoint: dict, spec: dict, channels) -> ConvClassifier:
    """Rebuild the BN training model and check it matches the saved folded view."""
    model = ConvClassifier(spec, channels, batch_norm=True).eval()
    model.load_state_dict(checkpoint["training_model"], strict=True)
    folded = fold_batch_norm(model).state_dict()
    saved = checkpoint["model"]
    for key, tensor in folded.items():
        if not torch.allclose(tensor, saved[key], rtol=1e-5, atol=1e-6):
            raise ValueError(f"{key}: folded model does not match training_model")
    return model
