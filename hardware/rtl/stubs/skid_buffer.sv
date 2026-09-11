`timescale 1ns / 1ps

module skid_buffer #(
    parameter DATA_WIDTH = 8
) (
    input logic arst_n,
    input logic clk,
    input logic clk_en,
    output logic [DATA_WIDTH-1:0] dn_data_o,
    input logic dn_ready_i,
    output logic dn_valid_o,
    input logic [DATA_WIDTH-1:0] up_data_i,
    output logic up_ready_o,
    input logic up_valid_i
);

  assign dn_data_o  = up_data_i;
  assign dn_valid_o = up_valid_i;
  assign up_ready_o = dn_ready_i;

endmodule
