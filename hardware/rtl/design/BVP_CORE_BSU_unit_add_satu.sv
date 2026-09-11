`timescale 1ns / 1ps

module BVP_CORE_BSU_unit_add_satu #(
    parameter DIN_WIDTH  = 16,
    parameter DOUT_WIDTH = 16
) (
    input  logic [ DIN_WIDTH-1:0] add_din_0,
    input  logic [ DIN_WIDTH-1:0] add_din_1,
    output logic [DOUT_WIDTH-1:0] dout
);

  localparam ADDER_DOUT_WIDTH = DIN_WIDTH + 1;
  logic [ADDER_DOUT_WIDTH-1:0] add_dout;
  logic [      DOUT_WIDTH-1:0] saturate_dout;

  BVP_CORE_BSU_PE_unit_adder #(
      .DIN_WIDTH (DIN_WIDTH),
      .DOUT_WIDTH(ADDER_DOUT_WIDTH)
  ) adder (
      .din_0(add_din_0),
      .din_1(add_din_1),
      .dout (add_dout)
  );

  op_saturate #(
      .DIN_WIDTH (ADDER_DOUT_WIDTH),
      .DOUT_WIDTH(DOUT_WIDTH)
  ) satu (
      .din (add_dout),
      .dout(saturate_dout)
  );

  assign dout = saturate_dout;

endmodule
