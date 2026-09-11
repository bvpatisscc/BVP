`timescale 1ns / 1ps

module arst_sync #(
    parameter STAGES  = 2,
    parameter RST_POL = 1'b0
) (
    input  logic clk,
    input  logic i_rst_async,
    output logic o_rst_sync
);

  assign o_rst_sync = i_rst_async;

endmodule
