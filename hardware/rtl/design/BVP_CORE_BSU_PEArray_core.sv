`timescale 1ns / 1ps

module BVP_CORE_BSU_PEArray_core #(
    parameter ACT_WIDTH = 8,
    parameter WGT_ENC_WIDTH = 4,
    parameter PEA_WGT_BUS_WIDTH = 9 * WGT_ENC_WIDTH,
    parameter DOUT_WIDTH = 16,
    parameter PEA_DOUT_WIDTH = 3 * DOUT_WIDTH
) (
    input  logic                         arst_n,
    input  logic                         clk,
    input  logic                         clk_en,
    input  logic                         clk_en_last_pe,
    input  logic                         ctrl_fc_only_en,
    input  logic                         ctrl_first_wgt_vld,
    input  logic                         ctrl_flush_pe2obuf,
    input  logic                         ctrl_pe_use_prev_out,
    input  logic                         flush_pe_prev_out,
    input  logic [        ACT_WIDTH-1:0] inbuf2pe_act_data,
    input  logic                         inbuf2pe_act_vld,
    input  logic [    WGT_ENC_WIDTH-1:0] inbuf2pe_fc_wgt_data,
    input  logic [PEA_WGT_BUS_WIDTH-1:0] inbuf2pe_wgt_data,
    input  logic                         inbuf2pe_wgt_vld,
    input  logic                         outbuf2pe_prdy,
    output logic                         pe2inbuf_act_rdy,
    output logic                         pe2inbuf_wgt_rdy,
    output logic [   PEA_DOUT_WIDTH-1:0] pe2outbuf_data,
    output logic                         pe2outbuf_pvld,
    input  logic [       DOUT_WIDTH-1:0] pedata_col0_buf_in_0,
    input  logic [       DOUT_WIDTH-1:0] pedata_col0_buf_in_1,
    input  logic [       DOUT_WIDTH-1:0] pedata_col0_buf_in_2
);
  logic [        ACT_WIDTH-1:0] arr_act_in_data;
  logic [PEA_WGT_BUS_WIDTH-1:0] arr_wgt_in_data;
  logic [   PEA_DOUT_WIDTH-1:0] pe2outbuf_data_int;
  logic [       DOUT_WIDTH-1:0] col0_pe_out_0;
  logic [       DOUT_WIDTH-1:0] col0_pe_out_1;
  logic [       DOUT_WIDTH-1:0] col0_pe_out_2;
  logic [       DOUT_WIDTH-1:0] col1_pe_out_0;
  logic [       DOUT_WIDTH-1:0] col1_pe_out_1;
  logic [       DOUT_WIDTH-1:0] col1_pe_out_2;
  logic [       DOUT_WIDTH-1:0] pedata_col2_pe_out_0;
  logic [       DOUT_WIDTH-1:0] pedata_col2_pe_out_1;
  logic [       DOUT_WIDTH-1:0] pedata_col2_pe_out_2;
  logic [                  7:0] col0_act_in_0;
  logic [                  7:0] col0_act_in_1;
  logic [                  7:0] col0_act_in_2;
  logic [                  7:0] col1_act_in_0;
  logic [                  7:0] col1_act_in_1;
  logic [                  7:0] col1_act_in_2;
  logic [                  7:0] col2_act_in_0;
  logic [                  7:0] col2_act_in_1;
  logic [                  7:0] col2_act_in_2;
  logic [                  3:0] col0_wgt_in_enc_0;
  logic [                  3:0] col0_wgt_in_enc_1;
  logic [                  3:0] col0_wgt_in_enc_2;
  logic [                  3:0] col1_wgt_in_enc_0;
  logic [                  3:0] col1_wgt_in_enc_1;
  logic [                  3:0] col1_wgt_in_enc_2;
  logic [                  3:0] col2_wgt_in_enc_0;
  logic [                  3:0] col2_wgt_in_enc_1;
  logic [                  3:0] col2_wgt_in_enc_2;
  logic                         col0_use_prev_out_0;
  logic                         col0_use_prev_out_1;
  logic                         col0_use_prev_out_2;
  logic                         col1_use_prev_out_0;
  logic                         col1_use_prev_out_1;
  logic                         col1_use_prev_out_2;
  logic                         col2_use_prev_out_0;
  logic                         col2_use_prev_out_1;
  logic                         col2_use_prev_out_2;

  BVP_CORE_BSU_PE_intf #(
      .ACT_WIDTH        (ACT_WIDTH),
      .WGT_ENC_WIDTH    (WGT_ENC_WIDTH),
      .PEA_WGT_BUS_WIDTH(PEA_WGT_BUS_WIDTH),
      .DOUT_WIDTH       (PEA_DOUT_WIDTH)
  ) uintf (
      .arr_act_in_data   (arr_act_in_data[ACT_WIDTH-1:0]),
      .arr_wgt_in_data   (arr_wgt_in_data[PEA_WGT_BUS_WIDTH-1:0]),
      .arst_n            (arst_n),
      .clk               (clk),
      .clk_en            (clk_en),
      .ctrl_flush_pe2obuf(ctrl_flush_pe2obuf),
      .inbuf2pe_act_data (inbuf2pe_act_data[ACT_WIDTH-1:0]),
      .inbuf2pe_act_vld  (inbuf2pe_act_vld),
      .inbuf2pe_wgt_data (inbuf2pe_wgt_data[PEA_WGT_BUS_WIDTH-1:0]),
      .inbuf2pe_wgt_vld  (inbuf2pe_wgt_vld),
      .outbuf2pe_prdy    (outbuf2pe_prdy),
      .pe2inbuf_act_rdy  (pe2inbuf_act_rdy),
      .pe2inbuf_wgt_rdy  (pe2inbuf_wgt_rdy),
      .pe2outbuf_data    (pe2outbuf_data[PEA_DOUT_WIDTH-1:0]),
      .pe2outbuf_data_int(pe2outbuf_data_int[PEA_DOUT_WIDTH-1:0]),
      .pe2outbuf_pvld    (pe2outbuf_pvld)
  );
  assign pe2outbuf_data_int = {pedata_col2_pe_out_2, pedata_col2_pe_out_1, pedata_col2_pe_out_0};

  BVP_CORE_BSU_PE_Col #(
      .ACT_WIDTH    (ACT_WIDTH),
      .WGT_ENC_WIDTH(WGT_ENC_WIDTH),
      .DOUT_WIDTH   (DOUT_WIDTH)
  ) pecol0 (
      .arst_n            (arst_n),
      .clk               (clk),
      .clk_en            (clk_en),
      .clk_en_last_pe    (clk_en),
      .col_act_in_0      (col0_act_in_0[ACT_WIDTH-1:0]),
      .col_act_in_1      (col0_act_in_1[ACT_WIDTH-1:0]),
      .col_act_in_2      (col0_act_in_2[ACT_WIDTH-1:0]),
      .col_pe_out_0      (col0_pe_out_0[DOUT_WIDTH-1:0]),
      .col_pe_out_1      (col0_pe_out_1[DOUT_WIDTH-1:0]),
      .col_pe_out_2      (col0_pe_out_2[DOUT_WIDTH-1:0]),
      .col_pe_psum_in_0  (pedata_col0_buf_in_0[DOUT_WIDTH-1:0]),
      .col_pe_psum_in_1  (pedata_col0_buf_in_1[DOUT_WIDTH-1:0]),
      .col_pe_psum_in_2  (pedata_col0_buf_in_2[DOUT_WIDTH-1:0]),
      .col_use_prev_out_0(col0_use_prev_out_0),
      .col_use_prev_out_1(col0_use_prev_out_1),
      .col_use_prev_out_2(col0_use_prev_out_2),
      .col_wgt_in_enc_0  (col0_wgt_in_enc_0[WGT_ENC_WIDTH-1:0]),
      .col_wgt_in_enc_1  (col0_wgt_in_enc_1[WGT_ENC_WIDTH-1:0]),
      .col_wgt_in_enc_2  (col0_wgt_in_enc_2[WGT_ENC_WIDTH-1:0]),
      .ctrl_first_wgt_vld(ctrl_first_wgt_vld),
      .flush_pe_prev_out (flush_pe_prev_out)
  );
  BVP_CORE_BSU_PE_Col #(
      .ACT_WIDTH    (ACT_WIDTH),
      .WGT_ENC_WIDTH(WGT_ENC_WIDTH),
      .DOUT_WIDTH   (DOUT_WIDTH)
  ) pecol1 (
      .arst_n            (arst_n),
      .clk               (clk),
      .clk_en            (clk_en),
      .clk_en_last_pe    (clk_en),
      .col_act_in_0      (col1_act_in_0[ACT_WIDTH-1:0]),
      .col_act_in_1      (col1_act_in_1[ACT_WIDTH-1:0]),
      .col_act_in_2      (col1_act_in_2[ACT_WIDTH-1:0]),
      .col_pe_out_0      (col1_pe_out_0[DOUT_WIDTH-1:0]),
      .col_pe_out_1      (col1_pe_out_1[DOUT_WIDTH-1:0]),
      .col_pe_out_2      (col1_pe_out_2[DOUT_WIDTH-1:0]),
      .col_pe_psum_in_0  (col0_pe_out_0[DOUT_WIDTH-1:0]),
      .col_pe_psum_in_1  (col0_pe_out_1[DOUT_WIDTH-1:0]),
      .col_pe_psum_in_2  (col0_pe_out_2[DOUT_WIDTH-1:0]),
      .col_use_prev_out_0(col1_use_prev_out_0),
      .col_use_prev_out_1(col1_use_prev_out_1),
      .col_use_prev_out_2(col1_use_prev_out_2),
      .col_wgt_in_enc_0  (col1_wgt_in_enc_0[WGT_ENC_WIDTH-1:0]),
      .col_wgt_in_enc_1  (col1_wgt_in_enc_1[WGT_ENC_WIDTH-1:0]),
      .col_wgt_in_enc_2  (col1_wgt_in_enc_2[WGT_ENC_WIDTH-1:0]),
      .ctrl_first_wgt_vld(ctrl_first_wgt_vld),
      .flush_pe_prev_out (flush_pe_prev_out)
  );
  BVP_CORE_BSU_PE_Col #(
      .ACT_WIDTH    (ACT_WIDTH),
      .WGT_ENC_WIDTH(WGT_ENC_WIDTH),
      .DOUT_WIDTH   (DOUT_WIDTH)
  ) pecol2 (
      .arst_n            (arst_n),
      .clk               (clk),
      .clk_en            (clk_en),
      .clk_en_last_pe    (clk_en_last_pe),
      .col_act_in_0      (col2_act_in_0[ACT_WIDTH-1:0]),
      .col_act_in_1      (col2_act_in_1[ACT_WIDTH-1:0]),
      .col_act_in_2      (col2_act_in_2[ACT_WIDTH-1:0]),
      .col_pe_out_0      (pedata_col2_pe_out_0[DOUT_WIDTH-1:0]),
      .col_pe_out_1      (pedata_col2_pe_out_1[DOUT_WIDTH-1:0]),
      .col_pe_out_2      (pedata_col2_pe_out_2[DOUT_WIDTH-1:0]),
      .col_pe_psum_in_0  (col1_pe_out_0[DOUT_WIDTH-1:0]),
      .col_pe_psum_in_1  (col1_pe_out_1[DOUT_WIDTH-1:0]),
      .col_pe_psum_in_2  (col1_pe_out_2[DOUT_WIDTH-1:0]),
      .col_use_prev_out_0(col2_use_prev_out_0),
      .col_use_prev_out_1(col2_use_prev_out_1),
      .col_use_prev_out_2(col2_use_prev_out_2),
      .col_wgt_in_enc_0  (col2_wgt_in_enc_0[WGT_ENC_WIDTH-1:0]),
      .col_wgt_in_enc_1  (col2_wgt_in_enc_1[WGT_ENC_WIDTH-1:0]),
      .col_wgt_in_enc_2  (col2_wgt_in_enc_2[WGT_ENC_WIDTH-1:0]),
      .ctrl_first_wgt_vld(ctrl_first_wgt_vld),
      .flush_pe_prev_out (flush_pe_prev_out)
  );

  assign col0_act_in_0 = arr_act_in_data;
  assign col0_act_in_1 = arr_act_in_data;
  assign col0_act_in_2 = arr_act_in_data;
  assign col1_act_in_0 = arr_act_in_data;
  assign col1_act_in_1 = arr_act_in_data;
  assign col1_act_in_2 = arr_act_in_data;
  assign col2_act_in_0 = arr_act_in_data;
  assign col2_act_in_1 = arr_act_in_data;
  assign col2_act_in_2 = arr_act_in_data;
  assign col0_wgt_in_enc_0 = arr_wgt_in_data[WGT_ENC_WIDTH*0+:WGT_ENC_WIDTH];
  assign col0_wgt_in_enc_1 = arr_wgt_in_data[WGT_ENC_WIDTH*1+:WGT_ENC_WIDTH];
  assign col0_wgt_in_enc_2 = arr_wgt_in_data[WGT_ENC_WIDTH*2+:WGT_ENC_WIDTH];
  assign col1_wgt_in_enc_0 = arr_wgt_in_data[WGT_ENC_WIDTH*3+:WGT_ENC_WIDTH];
  assign col1_wgt_in_enc_1 = arr_wgt_in_data[WGT_ENC_WIDTH*4+:WGT_ENC_WIDTH];
  assign col1_wgt_in_enc_2 = arr_wgt_in_data[WGT_ENC_WIDTH*5+:WGT_ENC_WIDTH];
  assign col2_wgt_in_enc_0 = arr_wgt_in_data[WGT_ENC_WIDTH*6+:WGT_ENC_WIDTH];
  assign col2_wgt_in_enc_1 = arr_wgt_in_data[WGT_ENC_WIDTH*7+:WGT_ENC_WIDTH];
  assign col2_wgt_in_enc_2 = ctrl_fc_only_en ? inbuf2pe_fc_wgt_data :
                           arr_wgt_in_data[WGT_ENC_WIDTH * 8 +: WGT_ENC_WIDTH];

  assign col0_use_prev_out_0 = ctrl_pe_use_prev_out;
  assign col0_use_prev_out_1 = ctrl_pe_use_prev_out;
  assign col0_use_prev_out_2 = ctrl_pe_use_prev_out;
  assign col1_use_prev_out_0 = ctrl_pe_use_prev_out;
  assign col1_use_prev_out_1 = ctrl_pe_use_prev_out;
  assign col1_use_prev_out_2 = ctrl_pe_use_prev_out;
  assign col2_use_prev_out_0 = ctrl_pe_use_prev_out;
  assign col2_use_prev_out_1 = ctrl_pe_use_prev_out;
  assign col2_use_prev_out_2 = ctrl_pe_use_prev_out;

endmodule
