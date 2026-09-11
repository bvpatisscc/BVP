`timescale 1ns / 1ps

module BVP_CORE_BSU_PE_unit_adder #(
    parameter DIN_WIDTH  = 16,
    parameter DOUT_WIDTH = 17
) (
    input  logic signed [ DIN_WIDTH-1:0] din_0,
    input  logic signed [ DIN_WIDTH-1:0] din_1,
    output logic signed [DOUT_WIDTH-1:0] dout
);

  assign dout = din_0 + din_1;

endmodule
