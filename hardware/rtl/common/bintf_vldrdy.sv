`timescale 1ns / 1ps

module bintf_vldrdy #(
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
  logic up_data_recv;

  assign up_rdy_o = ~(dn_pvld_o) || (dn_prdy_i);
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      dn_pvld_o <= {$bits(dn_pvld_o) {1'b0}};
    end else begin
      if (clk_en) begin
        if (up_rdy_o) dn_pvld_o <= up_vld_i;
      end
    end
  end

  assign up_data_recv = up_rdy_o && up_vld_i;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      dn_data_o <= {$bits(dn_data_o) {1'b0}};
    end else begin
      if (clk_en) begin
        if (up_data_recv) dn_data_o <= up_data_i;
      end
    end
  end

endmodule
