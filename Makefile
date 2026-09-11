UV ?= uv
VERILATOR ?= verilator

.PHONY: setup lint hw-lint

setup:
	$(UV) sync --frozen --group dev

lint:
	$(UV) run ruff check src

hw-lint:
	$(VERILATOR) --lint-only --timing -Wno-fatal --Mdir build/rtl --top-module BVP_CORE_top -f hardware/rtl/rtl.f
