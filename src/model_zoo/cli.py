import argparse
import copy
import json
import os
import random
import sys
from pathlib import Path

import numpy as np
import torch

from model_zoo.accumulator import load_checkpoint
from model_zoo.adapters import ConvClassifier
from model_zoo.batch_norm import fold_batch_norm
from model_zoo.calibration import calibrate_activations
from model_zoo.checkpoints import fp32_checkpoint, load_training_checkpoint
from model_zoo.config import load_config
from model_zoo.cssd import SymmetricNzdTable, quantize_symmetric_nzd
from model_zoo.equalization import cross_layer_equalize
from model_zoo.quantization import (
    add_power_of_two_quantizer_state,
    load_quantized_weights,
)
from model_zoo.structured_pruning import channel_schedule, prune_channel_chain
from model_zoo.training import evaluate, fit, load_data
from model_zoo.weight_calibration import search_weight_decimals


def fit_settings(section: dict, learning_rate: float) -> dict:
    return {
        "learning_rate": section.get("learning_rate", learning_rate),
        "momentum": section.get("momentum", 0.9),
        "weight_decay": section.get("weight_decay", 0.0),
        "scheduler": section.get("scheduler", "constant"),
        "warmup_epochs": section.get("warmup_epochs", 0),
        "optimizer_name": section.get("optimizer", "sgd"),
        "loss_name": section.get("loss", "cross_entropy"),
        "augmentation": section.get("augmentation", {}),
        "bbox_loss_weight": section.get("bbox_loss_weight", 0.0),
        "ema_decay": section.get("ema_decay", 0.0),
        "bn_recalibration": section.get("bn_recalibration", False),
    }


def log_progress(stage, **extra):
    return lambda metrics: print(
        json.dumps({"stage": stage, **extra, **metrics}), file=sys.stderr, flush=True
    )


def main(argv=None):
    parser = argparse.ArgumentParser(description="Train, prune and quantize BVP models")
    parser.add_argument("command", choices=("train", "prune", "cssd", "run", "evaluate"))
    parser.add_argument("config", type=Path)
    parser.add_argument("--checkpoint", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--norm", choices=("l1", "l2"), help="channel scoring norm")
    parser.add_argument("--recovery-epochs", type=int, help="epochs per pruning stage")
    parser.add_argument("--qat-epochs", type=int, help="QAT epochs; 0 selects PTQ")
    parser.add_argument("--epochs", type=int, help="training epochs")
    parser.add_argument("--learning-rate", type=float)
    parser.add_argument("--batch-size", type=int)
    parser.add_argument("--seed", type=int)
    parser.add_argument("--device", default="cpu")
    parser.add_argument("--deterministic", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--evaluate", action="store_true")
    args = parser.parse_args(argv)

    config = load_config(args.config)
    training = dict(config["training"])
    recovery = config["pruning"].get("recovery", {})
    cssd = config["cssd"]
    scratch = args.command == "train" or (args.command == "run" and args.checkpoint is None)
    if args.command == "train" and args.checkpoint is not None:
        parser.error("train does not accept --checkpoint")
    if args.command in ("prune", "cssd", "evaluate") and args.checkpoint is None:
        parser.error(f"{args.command} requires --checkpoint")
    if args.command != "evaluate" and args.output is None:
        parser.error(f"{args.command} requires --output")
    if args.output is not None and args.output.exists():
        parser.error(f"{args.output} exists")
    recovery_schedule = [0]
    if args.command in ("prune", "run"):
        epochs = recovery.get("epochs", 0)
        recovery_schedule = epochs if isinstance(epochs, list) else [epochs]
        if args.recovery_epochs is not None:
            recovery_schedule = [args.recovery_epochs] * len(recovery_schedule)
    qat_epochs = 0
    if args.command in ("cssd", "run"):
        qat_epochs = cssd.get("qat_epochs", 0) if args.qat_epochs is None else args.qat_epochs
    if args.epochs is not None:
        training["epochs"] = args.epochs
    if scratch and training.get("epochs", 0) <= 0:
        parser.error("set training.epochs in the config or pass --epochs")
    if args.learning_rate is not None:
        training["learning_rate"] = args.learning_rate
    batch_size = args.batch_size or training.get("batch_size", 128)
    seed = args.seed if args.seed is not None else training.get("seed", 42)
    norm = args.norm or config["pruning"]["norm"]

    if args.deterministic and torch.device(args.device).type == "cuda":
        os.environ.setdefault("CUBLAS_WORKSPACE_CONFIG", ":4096:8")
    torch.use_deterministic_algorithms(args.deterministic)
    torch.backends.cudnn.deterministic = args.deterministic
    torch.backends.cudnn.benchmark = False
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.set_num_threads(4)

    spec = config["model"]
    if args.command == "evaluate":
        state = torch.load(args.checkpoint, map_location="cpu", weights_only=True)["model"]
        spec = dict(spec, outputs=state["fc.weight"].shape[0])
        model = ConvClassifier(spec, spec["channels"])
        model.load_state_dict({key: state[key] for key in model.state_dict()}, strict=True)
        table = SymmetricNzdTable.load(args.config.parent / cssd["table"])
        validation = load_data(
            Path(config["data"]["root"]) / "val.npz",
            classes=spec["classes"],
            batch_size=batch_size,
            shuffle=False,
            seed=seed,
        )
        model = load_checkpoint(model, state, table=table)
        print(json.dumps(evaluate(model, validation, device=args.device, classes=spec["classes"])))
        return
    channels = spec["channels"] if args.command == "cssd" else spec["init_channels"]
    train_batch_norm = scratch and training.get("batch_norm", False)
    model = ConvClassifier(spec, channels, batch_norm=train_batch_norm)
    if args.checkpoint is not None:
        checkpoint = torch.load(args.checkpoint, map_location="cpu", weights_only=True)
        source = checkpoint.get("model", checkpoint)
        if "training_model" not in checkpoint and any("running_" in key for key in source):
            parser.error("checkpoint contains unfolded BatchNorm")
        if "training_model" in checkpoint:
            training_model = load_training_checkpoint(checkpoint, spec, channels)
            model = fold_batch_norm(training_model) if args.command == "cssd" else training_model
        else:
            model.load_state_dict({key: source[key] for key in model.state_dict()}, strict=True)

    metadata = {"name": config["name"], "seed": seed, "deterministic": args.deterministic}
    data_root = Path(config["data"]["root"])
    loader = None
    if scratch or any(recovery_schedule) or qat_epochs:
        loader = load_data(
            data_root / "train.npz",
            classes=spec["classes"],
            batch_size=batch_size,
            shuffle=True,
            seed=seed,
            include_boxes=bool(
                (scratch and training.get("bbox_loss_weight", 0))
                or (any(recovery_schedule) and recovery.get("bbox_loss_weight", 0))
            ),
        )

    if scratch:
        settings = fit_settings(training, 0.05)
        history = []
        fit(
            model,
            loader,
            **settings,
            epochs=training["epochs"],
            device=args.device,
            classes=spec["classes"],
            history=history,
            seed=seed,
            progress=log_progress("train"),
        )
        metadata["training"] = {
            **settings,
            "epochs": training["epochs"],
            "batch_size": batch_size,
            "batch_norm": train_batch_norm,
            "history": history,
        }

    if args.command in ("prune", "run"):
        settings = fit_settings(recovery, 0.001)
        if args.learning_rate is not None:
            settings["learning_rate"] = args.learning_rate
        pruning_stages, recovery_stages = [], []
        widths = channel_schedule(model.channels, spec["channels"], len(recovery_schedule))
        for stage, (channels, epochs) in enumerate(zip(widths, recovery_schedule, strict=True), 1):
            result = prune_channel_chain(
                model,
                ConvClassifier(spec, channels, batch_norm=model.batch_norm),
                norm=norm,
                score_source=fold_batch_norm(model.eval()) if model.batch_norm else None,
            )
            model = result.model
            pruning_stages.append({"channels": channels, "selected": result.selected})
            history = []
            if epochs:
                fit(
                    model,
                    loader,
                    **settings,
                    epochs=epochs,
                    device=args.device,
                    classes=spec["classes"],
                    history=history,
                    seed=seed,
                    progress=log_progress("recovery", pruning_stage=stage),
                )
            recovery_stages.append(
                {
                    **settings,
                    "epochs": epochs,
                    "batch_size": batch_size,
                    "batch_norm": model.batch_norm,
                    "history": history,
                }
            )
        metadata["pruning"] = {"norm": norm, "stages": pruning_stages}
        metadata["recovery"] = {"epochs": sum(recovery_schedule), "stages": recovery_stages}

    model, fp32_payload = fp32_checkpoint(model)
    state = fp32_payload["model"]
    cases = {}
    if args.command in ("cssd", "run"):
        original_fp32 = copy.deepcopy(model)
        equalization_rounds = cssd.get("equalization_rounds", 0)
        if equalization_rounds:
            model = cross_layer_equalize(model, rounds=equalization_rounds)
        qat_learning_rate = args.learning_rate or cssd.get("qat_learning_rate", 0.001)
        qat_optimizer = cssd.get("qat_optimizer", "sgd")
        qat_loss = cssd.get("qat_loss", "cross_entropy")
        qat_augmentation = cssd.get("qat_augmentation", {})
        calibration_batches = cssd.get("calibration_batches", 32)
        table = SymmetricNzdTable.load(args.config.parent / cssd["table"])
        calibration = load_data(
            data_root / "train.npz",
            classes=spec["classes"],
            batch_size=batch_size,
            shuffle=True,
            seed=seed,
        )
        if cssd.get("weight_scale_search", True):
            decimals, search = search_weight_decimals(
                model,
                calibration,
                layers=model.layers,
                table=table,
                batches=calibration_batches,
                device=args.device,
                output_counts=(
                    {"fc": spec["classes"]} if cssd.get("weight_scale_semantic_head") else None
                ),
            )
        else:
            decimals = dict.fromkeys(model.layers, cssd.get("weight_decimal", 7))
            search = None
        # Activation calibration runs on the CSSD-quantized weights.
        preliminary = add_power_of_two_quantizer_state(
            model.state_dict(),
            weight_decimals=decimals,
            activation_decimals=dict.fromkeys(model.layers, 7),
            layers=model.layers,
        )
        preliminary, _ = quantize_symmetric_nzd(
            preliminary, table=table, weight_decimals=decimals, layers=model.layers
        )
        weight_model = load_quantized_weights(model, preliminary, layers=model.layers)
        activation_search = {}
        activation_decimals = calibrate_activations(
            weight_model,
            calibration,
            layers=model.layers,
            batches=calibration_batches,
            device=args.device,
            weight_decimals=decimals,
            method=cssd.get("activation_calibration", "max_range"),
            report=activation_search,
        )
        metadata["quantization"] = {
            "equalization_rounds": equalization_rounds,
            "weight_decimals": decimals,
            "weight_scale_search": search,
            "activation_decimals": activation_decimals,
            "activation_calibration": activation_search,
            "calibration_batches": calibration_batches,
            "qat_epochs": qat_epochs,
            "qat_learning_rate": qat_learning_rate,
            "qat_optimizer": qat_optimizer,
            "qat_loss": qat_loss,
            "qat_augmentation": qat_augmentation,
        }
        ptq = add_power_of_two_quantizer_state(
            model.state_dict(),
            weight_decimals=decimals,
            activation_decimals=activation_decimals,
            layers=model.layers,
        )
        ptq, _ = quantize_symmetric_nzd(
            ptq, table=table, weight_decimals=decimals, layers=model.layers
        )
        cases = {
            "pruned_fp32": original_fp32,
            "cssd_weight_only": weight_model,
            "cssd_ptq": load_checkpoint(model, ptq, table=table),
        }
        if equalization_rounds:
            cases["equalized_fp32"] = copy.deepcopy(model)
        if qat_epochs:
            history = []
            fit(
                model,
                loader,
                epochs=qat_epochs,
                learning_rate=qat_learning_rate,
                optimizer_name=qat_optimizer,
                loss_name=qat_loss,
                augmentation=qat_augmentation,
                device=args.device,
                classes=spec["classes"],
                table=table,
                decimals=decimals,
                activation_decimals=activation_decimals,
                history=history,
                seed=seed,
                progress=log_progress("qat"),
            )
            metadata["quantization"]["history"] = history
        state = add_power_of_two_quantizer_state(
            model.state_dict(),
            weight_decimals=decimals,
            activation_decimals=activation_decimals,
            layers=model.layers,
        )
        state, metadata["cssd"] = quantize_symmetric_nzd(
            state, table=table, weight_decimals=decimals, layers=model.layers
        )
        model = load_checkpoint(model, state, table=table)

    if args.evaluate:
        validation = load_data(
            data_root / "val.npz",
            classes=spec["classes"],
            batch_size=batch_size,
            shuffle=False,
            seed=seed,
        )
        metadata["evaluation"] = evaluate(
            model, validation, device=args.device, classes=spec["classes"]
        )
        if cases:
            metadata["evaluations"] = {
                name: evaluate(candidate, validation, device=args.device, classes=spec["classes"])
                for name, candidate in cases.items()
            }
            final = "cssd_qat" if qat_epochs else "cssd_ptq"
            metadata["evaluations"][final] = metadata["evaluation"]

    args.output.parent.mkdir(parents=True, exist_ok=True)
    payload = {} if args.command in ("cssd", "run") else fp32_payload
    with args.output.open("xb") as output:
        torch.save(
            {**payload, "model": state, "channels": list(model.channels), "metadata": metadata},
            output,
        )
    print(json.dumps(metadata))


if __name__ == "__main__":
    main()
