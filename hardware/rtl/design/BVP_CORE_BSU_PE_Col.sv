`timescale 1ns / 1ps

module BVP_CORE_BSU_PE_Col #(
    parameter ACT_WIDTH = 8,
    parameter WGT_ENC_WIDTH = 3,
    parameter DOUT_WIDTH = 16
) (
    input  logic                     arst_n,
    input  logic                     clk,
    input  logic                     clk_en,
    input  logic                     clk_en_last_pe,
    input  logic [    ACT_WIDTH-1:0] col_act_in_0,
    input  logic [    ACT_WIDTH-1:0] col_act_in_1,
    input  logic [    ACT_WIDTH-1:0] col_act_in_2,
    output logic [   DOUT_WIDTH-1:0] col_pe_out_0,
    output logic [   DOUT_WIDTH-1:0] col_pe_out_1,
    output logic [   DOUT_WIDTH-1:0] col_pe_out_2,
    input  logic [   DOUT_WIDTH-1:0] col_pe_psum_in_0,
    input  logic [   DOUT_WIDTH-1:0] col_pe_psum_in_1,
    input  logic [   DOUT_WIDTH-1:0] col_pe_psum_in_2,
    input  logic                     col_use_prev_out_0,
    input  logic                     col_use_prev_out_1,
    input  logic                     col_use_prev_out_2,
    input  logic [WGT_ENC_WIDTH-1:0] col_wgt_in_enc_0,
    input  logic [WGT_ENC_WIDTH-1:0] col_wgt_in_enc_1,
    input  logic [WGT_ENC_WIDTH-1:0] col_wgt_in_enc_2,
    input  logic                     ctrl_first_wgt_vld,
    input  logic                     flush_pe_prev_out
);

  BVP_CORE_BSU_PE_unit #(
      .ACT_WIDTH    (ACT_WIDTH),
      .WGT_ENC_WIDTH(WGT_ENC_WIDTH),
      .DOUT_WIDTH   (DOUT_WIDTH)
  ) uPE0 (
      .act_in            (col_act_in_0),
      .arst_n            (arst_n),
      .clk               (clk),
      .clk_en            (clk_en),
      .ctrl_first_wgt_vld(ctrl_first_wgt_vld),
      .flush_pe_prev_out (flush_pe_prev_out),
      .pe_out            (col_pe_out_0),
      .pe_psum_in        (col_pe_psum_in_0),
      .use_prev_out      (col_use_prev_out_0),
      .wgt_in_enc        (col_wgt_in_enc_0)
  );
  BVP_CORE_BSU_PE_unit #(
      .ACT_WIDTH    (ACT_WIDTH),
      .WGT_ENC_WIDTH(WGT_ENC_WIDTH),
      .DOUT_WIDTH   (DOUT_WIDTH)
  ) uPE1 (
      .act_in            (col_act_in_1),
      .arst_n            (arst_n),
      .clk               (clk),
      .clk_en            (clk_en),
      .ctrl_first_wgt_vld(ctrl_first_wgt_vld),
      .flush_pe_prev_out (flush_pe_prev_out),
      .pe_out            (col_pe_out_1),
      .pe_psum_in        (col_pe_psum_in_1),
      .use_prev_out      (col_use_prev_out_1),
      .wgt_in_enc        (col_wgt_in_enc_1)
  );
  BVP_CORE_BSU_PE_unit #(
      .ACT_WIDTH    (ACT_WIDTH),
      .WGT_ENC_WIDTH(WGT_ENC_WIDTH),
      .DOUT_WIDTH   (DOUT_WIDTH)
  ) uPE2 (
      .act_in            (col_act_in_2),
      .arst_n            (arst_n),
      .clk               (clk),
      .clk_en            (clk_en_last_pe),
      .ctrl_first_wgt_vld(ctrl_first_wgt_vld),
      .flush_pe_prev_out (flush_pe_prev_out),
      .pe_out            (col_pe_out_2),
      .pe_psum_in        (col_pe_psum_in_2),
      .use_prev_out      (col_use_prev_out_2),
      .wgt_in_enc        (col_wgt_in_enc_2)
  );
endmodule
