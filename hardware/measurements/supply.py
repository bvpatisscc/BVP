"""Core supply voltage control over I2C."""

from i2c import Device

VOUT1 = 0x01
VOUT2 = 0x02
STATUS = 0x05
MIN_VOLTAGE = 0.4
MAX_VOLTAGE = 1.0
STEP = 0.0125


class Supply(Device):
    def __init__(self, bus, address=0x40):
        super().__init__(bus, address)

    def set_voltage(self, volts, register=VOUT1):
        code = round((volts - MIN_VOLTAGE) / STEP)
        if not 0 <= code <= 0x7F or volts > MAX_VOLTAGE:
            raise ValueError(f"{volts} V is outside the supply range")
        keep = self.read_u8(register) & 0x80 if register == VOUT2 else 0
        self.write_u8(register, code | keep)
        return self.get_voltage(register)

    def get_voltage(self, register=VOUT1):
        return MIN_VOLTAGE + (self.read_u8(register) & 0x7F) * STEP

    def power_good(self):
        return not self.read_u8(STATUS) & 0x02
