`timescale 1ns / 1ps

module BVP_CORE_BSU_Tile_OFIFO_accu #(
    parameter OFIFO_WIDTH = 16
) (
    input  logic                   arst_n,
    input  logic                   clk,
    input  logic                   clk_en,
    input  logic                   ctrl_ofifo_accu_stridew_valid,
    input  logic [OFIFO_WIDTH-1:0] din_0_row0,
    input  logic [OFIFO_WIDTH-1:0] din_0_row1,
    input  logic [OFIFO_WIDTH-1:0] din_0_row2,
    input  logic [OFIFO_WIDTH-1:0] din_1_row0,
    input  logic [OFIFO_WIDTH-1:0] din_1_row1,
    input  logic [OFIFO_WIDTH-1:0] din_1_row2,
    input  logic                   dn_prdy_i,
    output logic                   dn_pvld_o,
    output logic [OFIFO_WIDTH-1:0] dout_accu_row0,
    output logic [OFIFO_WIDTH-1:0] dout_accu_row1,
    output logic [OFIFO_WIDTH-1:0] dout_accu_row2,
    output logic                   ofifo_accu_dout_vld,
    output logic                   up_rdy_o,
    input  logic                   up_vld_i
);
  logic                   up_data_recv;
  logic [OFIFO_WIDTH-1:0] dout_accu_row0_comb;
  logic [OFIFO_WIDTH-1:0] dout_accu_row1_comb;
  logic [OFIFO_WIDTH-1:0] dout_accu_row2_comb;

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
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      ofifo_accu_dout_vld <= {$bits(ofifo_accu_dout_vld) {1'b0}};
    end else begin
      if (clk_en) begin
        if (up_rdy_o) ofifo_accu_dout_vld <= up_vld_i && ctrl_ofifo_accu_stridew_valid;
      end
    end
  end

  assign up_data_recv = up_rdy_o && up_vld_i;

  always_ff @(negedge clk or negedge arst_n) begin
    if (~arst_n) begin
      dout_accu_row0 <= {$bits(dout_accu_row0) {1'b0}};
      dout_accu_row1 <= {$bits(dout_accu_row1) {1'b0}};
      dout_accu_row2 <= {$bits(dout_accu_row2) {1'b0}};
    end else begin
      if (clk_en) begin
        if (up_data_recv) begin
          dout_accu_row0 <= dout_accu_row0_comb;
          dout_accu_row1 <= dout_accu_row1_comb;
          dout_accu_row2 <= dout_accu_row2_comb;
        end
      end
    end
  end

  BVP_CORE_BSU_unit_add_satu #(
      .DIN_WIDTH (OFIFO_WIDTH),
      .DOUT_WIDTH(OFIFO_WIDTH)
  ) u_PEA_Accu_0 (
      .add_din_0(din_0_row0),
      .add_din_1(din_1_row0),
      .dout     (dout_accu_row0_comb)
  );
  BVP_CORE_BSU_unit_add_satu #(
      .DIN_WIDTH (OFIFO_WIDTH),
      .DOUT_WIDTH(OFIFO_WIDTH)
  ) u_PEA_Accu_1 (
      .add_din_0(din_0_row1),
      .add_din_1(din_1_row1),
      .dout     (dout_accu_row1_comb)
  );
  BVP_CORE_BSU_unit_add_satu #(
      .DIN_WIDTH (OFIFO_WIDTH),
      .DOUT_WIDTH(OFIFO_WIDTH)
  ) u_PEA_Accu_2 (
      .add_din_0(din_0_row2),
      .add_din_1(din_1_row2),
      .dout     (dout_accu_row2_comb)
  );

endmodule
