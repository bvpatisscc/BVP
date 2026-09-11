# BVP

This is a software/hardware co-design project. It covers training, structured channel
pruning and CSSD quantization, and the RTL implementation of the bit serial accelerator.

## Install

```sh
uv sync --frozen
```

Python 3.10 to 3.12 and PyTorch 2.11.

## Quick start

```sh
export DATA_ROOT=./data/CIFAR-10
uv run model-zoo train models/CIFAR-10/config.yaml --output runs/fp32.pt --evaluate
uv run model-zoo prune models/CIFAR-10/config.yaml --checkpoint runs/fp32.pt --output runs/slim.pt --evaluate
uv run model-zoo cssd  models/CIFAR-10/config.yaml --checkpoint runs/slim.pt --output runs/cssd.pt --evaluate
```

## Pretrained checkpoints

CSSD checkpoints for every model under `models/` are attached to the GitHub release.
Download the one matching the config and evaluate it on the validation split:

```sh
export DATA_ROOT=./data/CIFAR-10
uv run model-zoo evaluate models/CIFAR-10/config.yaml --checkpoint CIFAR-10.pt
```

## Config File Example

```yaml
name: CIFAR-10
training:
  epochs: 150
  batch_size: 128
  learning_rate: 0.05
  momentum: 0.9
  weight_decay: 0.0005
  scheduler: cosine
  seed: 42
  batch_norm: true
  augmentation:
    shift: 4
    horizontal_flip: true
data:
  root: ${oc.env:DATA_ROOT,./data}
model:
  input_shape: [4, 32, 32]
  init_channels: [16, 64, 72, 56, 40]  # trained width
  channels: [8, 24, 40, 40, 32]        # pruned width
  strides: [1, 1, 1, 1, 1]
  pool_after: [2, 3, 4, 5]
  global_pool: max
  classes: 10
  outputs: 16                          # physical FC width (padded)
pruning:
  recovery:
    epochs: [50, 50, 50, 200]          # a list prunes gradually
    learning_rate: 0.05
    weight_decay: 0.0005
    scheduler: cosine
    augmentation:
      shift: 4
      horizontal_flip: true
cssd:
  qat_learning_rate: 0.0001
  calibration_batches: 32
  qat_epochs: 5
  table: ../shared/symmetric_2nzd.json
```

## Hardware

`hardware/rtl/` contains the accelerator RTL.

```sh
make hw-lint   # elaborate with Verilator
```

## Layout

```
src/model_zoo/   training, pruning, quantization and the CLI
models/          config files and the shared 2-NZD code table
hardware/rtl/    accelerator RTL
```
