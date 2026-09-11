`timescale 1ns / 1ps

module BVP_CORE_BSU_Tile_OFIFO #(
    parameter OFIFO_WIDTH = 16,
    parameter OFIFO_DEPTH = 128
) (
    input  logic [OFIFO_WIDTH-1:0] accu2ofifo_data_row0,
    input  logic [OFIFO_WIDTH-1:0] accu2ofifo_data_row1,
    input  logic [OFIFO_WIDTH-1:0] accu2ofifo_data_row2,
    input  logic                   accu2ofifo_pvld,
    input  logic                   arst_n,
    input  logic                   clk,
    input  logic                   clk_en,
    input  logic                   ctrl_ofifo_accu_stridew_valid,
    input  logic                   ctrl_ofifo_avail_for_ih,
    input  logic                   cur_ifm_done,
    output logic [OFIFO_WIDTH-1:0] ofifo_accu_dout,
    output logic                   ofifo_accu_dout_vld,
    input  logic                   ofifo_accu_prdy_i,
    output logic                   ofifo_accu_rdy,
    output logic                   ofifo_rdy
);
  logic                   ofifo_accu_pvld;
  logic [OFIFO_WIDTH-1:0] ofifo_accu_dout_row0;
  logic [OFIFO_WIDTH-1:0] ofifo_accu_dout_row1;
  logic [OFIFO_WIDTH-1:0] ofifo_accu_dout_row2;
  logic                   ofifo_full_pea0;
  logic [OFIFO_WIDTH-1:0] ofifo_data_row0;
  logic                   ofifo_rempty_pea0;
  logic [OFIFO_WIDTH-1:0] ofifo_data_row0_reg;
  logic                   ofifo_full_pea1;
  logic [OFIFO_WIDTH-1:0] ofifo_data_row1;
  logic                   ofifo_rempty_pea1;
  logic [OFIFO_WIDTH-1:0] ofifo_data_row1_reg;
  logic                   ofifo_rden;

  BVP_CORE_BSU_Tile_OFIFO_accu #(
      .OFIFO_WIDTH(OFIFO_WIDTH)
  ) uPEA_OFIFO_Accu (
      .arst_n                       (arst_n),
      .clk                          (clk),
      .clk_en                       (clk_en),
      .ctrl_ofifo_accu_stridew_valid(ctrl_ofifo_accu_stridew_valid),
      .din_0_row0                   (accu2ofifo_data_row0),
      .din_0_row1                   (accu2ofifo_data_row1),
      .din_0_row2                   (accu2ofifo_data_row2),
      .din_1_row0                   ({OFIFO_WIDTH{1'b0}}),
      .din_1_row1                   (ofifo_data_row0_reg),
      .din_1_row2                   (ofifo_data_row1_reg),
      .dn_prdy_i                    (ofifo_rdy),
      .dn_pvld_o                    (ofifo_accu_pvld),
      .dout_accu_row0               (ofifo_accu_dout_row0),
      .dout_accu_row1               (ofifo_accu_dout_row1),
      .dout_accu_row2               (ofifo_accu_dout_row2),
      .ofifo_accu_dout_vld          (ofifo_accu_dout_vld),
      .up_rdy_o                     (ofifo_accu_rdy),
      .up_vld_i                     (accu2ofifo_pvld)
  );
  assign ofifo_accu_dout = ofifo_accu_dout_row2;

  sync_fifo_ram_flush #(
      .DATA_WIDTH(OFIFO_WIDTH),
      .FIFO_DEPTH(OFIFO_DEPTH)
  ) uPEA_OFIFO_0 (
      .clk       (clk),
      .arst_n    (arst_n),
      .flush_fifo(cur_ifm_done),
      .wren      (ofifo_accu_pvld),
      .wdata     (ofifo_accu_dout_row0),
      .wfull     (ofifo_full_pea0),
      .rden      (ofifo_rden),
      .rdata     (ofifo_data_row0),
      .rempty    (ofifo_rempty_pea0)
  );
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      ofifo_data_row0_reg <= {$bits(ofifo_data_row0_reg) {1'b0}};
    end else begin
      if (clk_en) begin
        if (ofifo_rden && !ofifo_rempty_pea0) begin
          ofifo_data_row0_reg <= ofifo_data_row0;
        end
      end
    end
  end
  sync_fifo_ram_flush #(
      .DATA_WIDTH(OFIFO_WIDTH),
      .FIFO_DEPTH(OFIFO_DEPTH)
  ) uPEA_OFIFO_1 (
      .clk       (clk),
      .arst_n    (arst_n),
      .flush_fifo(cur_ifm_done),
      .wren      (ofifo_accu_pvld),
      .wdata     (ofifo_accu_dout_row1),
      .wfull     (ofifo_full_pea1),
      .rden      (ofifo_rden),
      .rdata     (ofifo_data_row1),
      .rempty    (ofifo_rempty_pea1)
  );
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      ofifo_data_row1_reg <= {$bits(ofifo_data_row1_reg) {1'b0}};
    end else begin
      if (clk_en) begin
        if (ofifo_rden && !ofifo_rempty_pea1) begin
          ofifo_data_row1_reg <= ofifo_data_row1;
        end
      end
    end
  end
  assign ofifo_rdy  = !ofifo_full_pea0 && !ofifo_full_pea1 && ofifo_accu_prdy_i;

  assign ofifo_rden = ofifo_rdy && ctrl_ofifo_avail_for_ih && ofifo_accu_pvld;

endmodule
