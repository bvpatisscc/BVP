`timescale 1ns / 1ps

module sram_stub #(
    parameter RAM_DATA_BW = 8,
    parameter RAM_ADDR_BW = 1
) (
    input logic [RAM_ADDR_BW-1:0] addr,
    input logic ce_n,
    input logic clk,
    input logic [RAM_DATA_BW-1:0] wdata,
    output logic [RAM_DATA_BW-1:0] rdata,
    input logic we_n
);

  assign rdata = '0;

endmodule
