`timescale 1ns / 1ps

module bintf_vldrdy_skbuf #(
    parameter DATA_WIDTH = 16
) (
    input  logic                  arst_n,
    input  logic                  clk,
    input  logic                  clk_en,
    output logic [DATA_WIDTH-1:0] dn_data_o,
    input  logic                  dn_prdy_i,
    output logic                  dn_pvld_o,
    input  logic [DATA_WIDTH-1:0] up_data_i,
    output logic                  up_rdy_o,
    input  logic                  up_vld_i
);
  logic [DATA_WIDTH-1:0] int_data;
  logic                  int_pvld;
  logic                  int_prdy;

  bintf_vldrdy #(
      .DATA_WIDTH(DATA_WIDTH)
  ) u_intf_vldrdy (
      .arst_n   (arst_n),
      .clk      (clk),
      .clk_en   (clk_en),
      .dn_data_o(int_data),
      .dn_prdy_i(int_prdy),
      .dn_pvld_o(int_pvld),
      .up_data_i(up_data_i),
      .up_rdy_o (up_rdy_o),
      .up_vld_i (up_vld_i)
  );
  skid_buffer #(
      .DATA_WIDTH(DATA_WIDTH)
  ) u_skid_buffer (
      .arst_n    (arst_n),
      .clk       (clk),
      .clk_en    (clk_en),
      .dn_data_o (dn_data_o),
      .dn_ready_i(dn_prdy_i),
      .dn_valid_o(dn_pvld_o),
      .up_data_i (int_data),
      .up_ready_o(int_prdy),
      .up_valid_i(int_pvld)
  );

endmodule
