"""Core rail current and power over I2C."""

from i2c import Device

CONFIG = 0x00
SHUNT_VOLTAGE = 0x01
BUS_VOLTAGE = 0x02
SHUNT_LSB = 2.5e-6
BUS_LSB = 1.25e-3


class Monitor(Device):
    def __init__(self, bus, address=0x45, shunt_ohms=0.05):
        super().__init__(bus, address)
        self.shunt_ohms = shunt_ohms

    def configure(self, value=0x4127):
        self.write_u16(CONFIG, value)

    def sample(self):
        """Return (bus voltage V, current A, power mW) from one shunt and bus reading."""
        shunt_v = self.read_u16(SHUNT_VOLTAGE, signed=True) * SHUNT_LSB
        bus_v = self.read_u16(BUS_VOLTAGE) * BUS_LSB
        current = shunt_v / self.shunt_ohms
        return bus_v, current, bus_v * current * 1e3
