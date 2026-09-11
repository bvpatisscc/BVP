from pathlib import Path

from omegaconf import OmegaConf


def load_config(path: Path) -> dict:
    config = OmegaConf.to_container(OmegaConf.load(path), resolve=True)
    config.setdefault("pruning", {}).setdefault("norm", "l2")
    spec = config["model"]
    init, target = spec["init_channels"], spec["channels"]
    if len(init) != len(target) or len(init) != len(spec["strides"]):
        raise ValueError("init_channels, channels and strides must have the same length")
    if any(a < b for a, b in zip(init, target, strict=True)):
        raise ValueError("channels must not exceed init_channels")
    if not 0 < spec["classes"] <= spec["outputs"]:
        raise ValueError("classes must be positive and at most outputs")
    return config
