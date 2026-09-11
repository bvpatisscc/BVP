"""Frequency / voltage shmoo of the chip from the FPGA host.

For every supply voltage from high to low, the clock is stepped down to the lowest
frequency; the highest passing frequency sets where the next voltage starts. The
lowest passing voltage per frequency is the Vmin frontier, and the power at that
point is read from the core rail.

Board-specific hooks: `Board.set_clock()`, `load_model()` (runs once) and
`run_workload()`, which streams one input through the chip and returns the output
bytes, compared with the reference byte for byte. A failed transfer is retried once.
"""

import argparse
import csv
import time

from i2c import I2CBus
from monitor import Monitor
from pynq import Overlay
from supply import Supply


class Board:
    def __init__(self, bitstream):
        self.overlay = Overlay(bitstream)
        bus = I2CBus(self.overlay)
        self.supply = Supply(bus)
        self.monitor = Monitor(bus)
        self.monitor.configure()

    def set_clock(self, mhz):
        """Set the chip clock. Board specific."""
        raise NotImplementedError


def load_model(board):
    """Program the model into the chip. Board specific."""
    raise NotImplementedError


def run_workload(board):
    """Return the chip's output bytes for the reference input. Board specific."""
    raise NotImplementedError


def sweep(board, expected, freqs, volts, settle_s=0.1):
    """Yield (frequency, voltage, passed, bus V, current A, power mW) for each point."""
    start = freqs[-1]
    for v in volts:
        best = None
        for f in [x for x in reversed(freqs) if x <= start]:
            board.set_clock(f)
            board.supply.set_voltage(v)
            time.sleep(settle_s)
            passed = False
            for _ in range(2):
                try:
                    passed = run_workload(board) == expected
                    break
                except Exception:
                    continue
            bus_v, current, power = board.monitor.sample()
            yield f, v, passed, bus_v, current, power
            if passed and best is None:
                best = f
        if best is None:
            continue
        start = min(best + 10, freqs[-1])


def frontier(points):
    """Lowest passing voltage per frequency; a pass at a higher frequency also counts.

    The rail sample is the one measured at that frequency and voltage when the grid
    visited it, otherwise the nearest passing frequency at that voltage.
    """
    freqs = sorted({p[0] for p in points})
    vmin = {}
    for f, v, passed, *_ in points:
        if passed:
            for g in freqs:
                if g <= f and v < vmin.get(g, 9.0):
                    vmin[g] = v
    rows = []
    for g, v in sorted(vmin.items()):
        at_point = [p for p in points if p[0] == g and p[1] == v]
        passes = [p for p in points if p[1] == v and p[2] and p[0] >= g]
        sample = at_point[0] if at_point else min(passes, key=lambda p: p[0])
        rows.append((g, v, *sample[3:]))
    return rows


def main():
    p = argparse.ArgumentParser()
    p.add_argument("bitstream")
    p.add_argument("--reference", required=True, help="file with the expected output bytes")
    p.add_argument(
        "--freq", nargs=3, type=float, default=(10, 400, 10), metavar=("START", "STOP", "STEP")
    )
    p.add_argument(
        "--volt", nargs=3, type=float, default=(0.4, 0.9, 0.0125), metavar=("START", "STOP", "STEP")
    )
    p.add_argument("--out", default="sweep")
    a = p.parse_args()
    freqs = [
        round(a.freq[0] + i * a.freq[2], 3)
        for i in range(int((a.freq[1] - a.freq[0]) / a.freq[2]) + 1)
    ]
    volts = [
        round(a.volt[1] - i * a.volt[2], 4)
        for i in range(int((a.volt[1] - a.volt[0]) / a.volt[2]) + 1)
    ]
    expected = open(a.reference, "rb").read()
    board = Board(a.bitstream)
    load_model(board)
    points = []
    with open(f"{a.out}_raw.csv", "w", newline="") as raw:
        w = csv.writer(raw)
        w.writerow(["frequency_mhz", "voltage_v", "passed", "bus_v", "current_a", "power_mw"])
        for point in sweep(board, expected, freqs, volts):
            points.append(point)
            w.writerow(point)
            raw.flush()
            print(*point)
    with open(f"{a.out}_frontier.csv", "w", newline="") as out:
        w = csv.writer(out)
        w.writerow(["frequency_mhz", "vmin_v", "bus_v", "current_a", "power_mw"])
        w.writerows(frontier(points))


if __name__ == "__main__":
    main()
