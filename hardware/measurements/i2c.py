"""I2C register access through the AXI IIC controller of the FPGA overlay."""


class I2CBus:
    def __init__(self, overlay, ip_name="axi_iic_0"):
        self.ctrl = getattr(overlay, ip_name)

    def read_register(self, address, register, length=1):
        ffi = self.ctrl._ffi
        buf = ffi.new(f"unsigned char[{length}]")
        sent = self.ctrl.send(
            address, ffi.new("unsigned char[1]", [register]), 1, self.ctrl.REPEAT_START
        )
        n = self.ctrl.receive(address, buf, length)
        self.ctrl.wait()
        if sent != 1 or n != length:
            raise OSError(f"I2C 0x{address:02x}: read {n} of {length} bytes")
        return bytes(ffi.buffer(buf, length))

    def write_register(self, address, register, data):
        ffi = self.ctrl._ffi
        payload = bytes([register, *data])
        n = self.ctrl.send(
            address, ffi.new(f"unsigned char[{len(payload)}]", payload), len(payload)
        )
        self.ctrl.wait()
        if n != len(payload):
            raise OSError(f"I2C 0x{address:02x}: wrote {n} of {len(payload)} bytes")


class Device:
    def __init__(self, bus, address):
        self.bus = bus
        self.address = address

    def read_u8(self, register):
        return self.bus.read_register(self.address, register)[0]

    def write_u8(self, register, value):
        self.bus.write_register(self.address, register, [value])

    def read_u16(self, register, signed=False):
        return int.from_bytes(
            self.bus.read_register(self.address, register, 2), "big", signed=signed
        )

    def write_u16(self, register, value):
        self.bus.write_register(self.address, register, value.to_bytes(2, "big"))
