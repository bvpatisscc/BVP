# Silicon measurements

`fv_sweep.csv` is the measured minimum core supply voltage and the core-rail power of
the chip.

## Setup

The chip sits on a carrier board attached to an FPGA host. The host sets the core
supply voltage and reads the core-rail current over I2C.

## Files

- `fv_sweep.csv`: frequency (MHz), minimum passing core voltage (V), core-rail power (mW).
- `sweep.py`: the frequency/voltage grid sweep. For each voltage from 0.9 V down in
  12.5 mV steps and each frequency in 10 MHz steps it streams a reference input through
  the chip and checks the output, then reduces the grid to the Vmin frontier with the
  rail sample at each frontier point. Clock control, model loading and streaming are
  board-specific hooks and are not included.
- `i2c.py`: register reads and writes through the AXI IIC controller of the FPGA overlay.
- `supply.py`: core supply voltage setting and readback.
- `monitor.py`: rail voltage, current and power from the shunt monitor.
