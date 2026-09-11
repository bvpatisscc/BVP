`timescale 1ns / 1ps

module op_saturate #(
    parameter DIN_WIDTH  = 14,
    parameter DOUT_WIDTH = 12
) (
    input  signed [ DIN_WIDTH-1:0] din,
    output signed [DOUT_WIDTH-1:0] dout
);

  localparam TRUNCATE_MSB = DIN_WIDTH - 1;
  localparam TRUNCATE_LSB = DOUT_WIDTH - 1;

  logic not_overflow;

  assign not_overflow = (&din[TRUNCATE_MSB:TRUNCATE_LSB]) | !(|din[TRUNCATE_MSB:TRUNCATE_LSB]);

  assign dout = not_overflow ? din[DOUT_WIDTH-1:0]:
                            {din[DIN_WIDTH-1], {(DOUT_WIDTH-1){!din[DIN_WIDTH-1]}}};

endmodule
