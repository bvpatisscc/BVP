`timescale 1ns / 1ps

module BVP_CORE_BSU_Tile0 #(
    parameter ACT_WIDTH = 8,
    parameter WGT_ENC_WIDTH = 4,
    parameter POOL_FIFO_DEPTH = 8,
    parameter PEA_OFIFO_DEPTH = 128,
    parameter PEA_WGT_BUS_WIDTH = 9 * WGT_ENC_WIDTH,
    parameter SUM_WIDTH = 16,
    parameter BIAS_WIDTH = 16,
    parameter NLAYER_ACT_WIDTH = 8,
    parameter PEA_DOUT_WIDTH = 3 * SUM_WIDTH,
    parameter TILE_ACT_BUS_WIDTH = 2 * ACT_WIDTH,
    parameter TILE_WGT_BUS_WIDTH = 2 * PEA_WGT_BUS_WIDTH,
    parameter TILE_FC_WGT_BUS_WIDTH = 2 * WGT_ENC_WIDTH
) (
    output logic                            accu2ofifo_pvld,
    output logic                            accu2pea_rdy,
    input  logic                            arst_n,
    input  logic                            aux_rp_calc_skip_rounding,
    input  logic [                     4:0] aux_rp_calc_truncate_frac_width,
    input  logic [                     3:0] aux_rp_calc_truncate_frac_width_m1,
    output logic                            bias_relu_prdy_o,
    input  logic                            clk,
    input  logic                            clk_en_conv_all_pes,
    input  logic                            clk_en_data_disp,
    input  logic                            clk_en_mac_ops,
    input  logic                            clk_en_pool,
    input  logic                            csr_layer_cfg_pool_sizeh,
    input  logic                            csr_layer_cfg_pool_sizew,
    input  logic                            csr_model_cfg_last_pool_type,
    input  logic                            ctrl_bias_relu_out_row_done,
    input  logic                            ctrl_fc_only_en,
    input  logic                            ctrl_first_wgt_vld,
    input  logic                            ctrl_flush_pe2obuf,
    input  logic                            ctrl_ofifo_accu_stridew_valid,
    input  logic                            ctrl_ofifo_avail_for_ih,
    input  logic                            ctrl_pe_use_prev_out,
    input  logic                            ctrl_pea_en,
    input  logic                            ctrl_pool_en,
    input  logic                            cur_ifm_done,
    input  logic                            flush_pe_prev_out,
    input  logic                            incnt_fm_height_done,
    input  logic                            incnt_ich_num_done,
    input  logic [          BIAS_WIDTH-1:0] mem_in_bias_dout,
    input  logic                            mem_in_bias_vld,
    output logic                            ofifo_accu_rdy,
    output logic                            ofifo_rdy,
    output logic                            pe2inbuf_rdy,
    output logic                            pea_act_recv,
    output logic                            pea_data_recv,
    output logic                            pea_pool_up_data_vld_i,
    output logic [    NLAYER_ACT_WIDTH-1:0] tile_data_o,
    input  logic                            tile_data_prdy_i,
    output logic                            tile_data_pvld_o,
    input  logic [   TILE_ACT_BUS_WIDTH-1:0] tile_mem_in_act_dout,
    input  logic                            tile_mem_in_act_vld,
    input  logic [TILE_FC_WGT_BUS_WIDTH-1:0] tile_mem_in_fc_wgt_dout,
    input  logic                            tile_mem_in_fc_wgt_vld,
    input  logic [   TILE_WGT_BUS_WIDTH-1:0] tile_mem_in_wgt_dout,
    input  logic                            tile_mem_in_wgt_vld,
    input  logic [           SUM_WIDTH-1:0] pedata_col0_buf_in_0_pea0,
    input  logic [           SUM_WIDTH-1:0] pedata_col0_buf_in_0_pea1,
    input  logic [           SUM_WIDTH-1:0] pedata_col0_buf_in_1_pea0,
    input  logic [           SUM_WIDTH-1:0] pedata_col0_buf_in_1_pea1,
    input  logic [           SUM_WIDTH-1:0] pedata_col0_buf_in_2_pea0,
    input  logic [           SUM_WIDTH-1:0] pedata_col0_buf_in_2_pea1,
    input  logic                            pool_last_pixel
);
  logic                         clk_en_pea_pool;
  logic                         clk_en_din_splitter;
  logic                         clk_en_bias_relu;
  logic                         clk_en_pea_core;
  logic                         clk_en_pea_accu;
  logic                         clk_en_pea_core_aux;
  logic                         clk_en_ofifo;
  logic                         inbuf2pe_wgt_vld_pea_sel;
  logic                         inbuf2pe_act_vld_pea0;
  logic                         inbuf2pe_wgt_vld_pea0;
  logic [        ACT_WIDTH-1:0] inbuf2pe_act_data_pea0;
  logic [PEA_WGT_BUS_WIDTH-1:0] inbuf2pe_wgt_data_pea0;
  logic [                  3:0] inbuf2pe_fc_wgt_data_pea0;
  logic                         inbuf2pe_act_vld_pea1;
  logic                         inbuf2pe_wgt_vld_pea1;
  logic [        ACT_WIDTH-1:0] inbuf2pe_act_data_pea1;
  logic [PEA_WGT_BUS_WIDTH-1:0] inbuf2pe_wgt_data_pea1;
  logic [                  3:0] inbuf2pe_fc_wgt_data_pea1;
  logic [TILE_ACT_BUS_WIDTH-1:0] tile_mem_in_act_dout_presplit;
  logic                         tile_mem_in_act_dout_presplit_vld;
  logic [ NLAYER_ACT_WIDTH-1:0] tile_mem_in_act_dout_split;
  logic                         tile_mem_in_act_dout_split_vld;
  logic [ NLAYER_ACT_WIDTH-1:0] pea_pool_up_data_i;
  logic                         bias_relu_prdy_i;
  logic                         pea_pool_dn_prdy_i;
  logic                         pea_pool_dn_pvld_o;
  logic [ NLAYER_ACT_WIDTH-1:0] pea_pool_res_data_o;
  logic                         pea_pool_up_rdy_o;
  logic [       BIAS_WIDTH-1:0] bias_relu_data_o_s1;
  logic                         bias_relu_data_pvld_o_s1;
  logic [ NLAYER_ACT_WIDTH-1:0] bias_relu_data_o;
  logic                         bias_relu_data_pvld_o;
  logic                         bias_relu_prdy_i_s1;
  logic [        SUM_WIDTH-1:0] bias_relu_din_act;
  logic                         bias_relu_din_act_vld;
  logic [        SUM_WIDTH-1:0] ofifo_accu_dout;
  logic                         ofifo_accu_dout_vld;
  logic                         pe2inbuf_act_rdy_pea0;
  logic                         pe2inbuf_wgt_rdy_pea0;
  logic [   PEA_DOUT_WIDTH-1:0] pea2accu_data_pea0;
  logic                         pea2accu_pvld_pea0;
  logic                         pe2inbuf_act_rdy_pea1;
  logic                         pe2inbuf_wgt_rdy_pea1;
  logic [   PEA_DOUT_WIDTH-1:0] pea2accu_data_pea1;
  logic                         pea2accu_pvld_pea1;
  logic [        SUM_WIDTH-1:0] accu2ofifo_data_row0;
  logic [        SUM_WIDTH-1:0] accu2ofifo_data_row1;
  logic [        SUM_WIDTH-1:0] accu2ofifo_data_row2;
  logic                         pea2accu_vld;
  logic                         accu2pea_prdy_pea0;
  logic                         accu2pea_prdy_pea1;

  assign clk_en_pea_pool = clk_en_pool;
  assign clk_en_din_splitter = clk_en_data_disp;

  assign clk_en_bias_relu = clk_en_mac_ops;
  assign clk_en_pea_core = clk_en_mac_ops;
  assign clk_en_pea_accu = clk_en_mac_ops;

  assign clk_en_pea_core_aux = clk_en_conv_all_pes;
  assign clk_en_ofifo = clk_en_conv_all_pes;

  assign inbuf2pe_wgt_vld_pea_sel = ctrl_fc_only_en ? tile_mem_in_fc_wgt_vld : tile_mem_in_wgt_vld;
  assign inbuf2pe_act_vld_pea0 = tile_mem_in_act_vld;
  assign inbuf2pe_wgt_vld_pea0 = inbuf2pe_wgt_vld_pea_sel;
  assign inbuf2pe_act_data_pea0 = tile_mem_in_act_dout[ACT_WIDTH-1:0];
  assign inbuf2pe_wgt_data_pea0 = tile_mem_in_wgt_dout[PEA_WGT_BUS_WIDTH-1:0];
  assign inbuf2pe_fc_wgt_data_pea0 = tile_mem_in_fc_wgt_dout[WGT_ENC_WIDTH-1:0];
  assign inbuf2pe_act_vld_pea1 = tile_mem_in_act_vld;
  assign inbuf2pe_wgt_vld_pea1 = inbuf2pe_wgt_vld_pea_sel;
  assign inbuf2pe_act_data_pea1 = tile_mem_in_act_dout[1*ACT_WIDTH+:ACT_WIDTH];
  assign inbuf2pe_wgt_data_pea1 = tile_mem_in_wgt_dout[1*PEA_WGT_BUS_WIDTH+:PEA_WGT_BUS_WIDTH];
  assign inbuf2pe_fc_wgt_data_pea1 = tile_mem_in_fc_wgt_dout[1*WGT_ENC_WIDTH+:WGT_ENC_WIDTH];

  assign tile_mem_in_act_dout_presplit = tile_mem_in_act_dout;
  assign tile_mem_in_act_dout_presplit_vld = tile_mem_in_act_vld && !tile_mem_in_wgt_vld;
  splitter_i1o2 #(
      .DIN_WIDTH (TILE_ACT_BUS_WIDTH),
      .DOUT_WIDTH(NLAYER_ACT_WIDTH)
  ) uDIN_splitter (
      .arst_n  (arst_n),
      .clk     (clk),
      .clk_en  (clk_en_din_splitter),
      .din     (tile_mem_in_act_dout_presplit),
      .din_vld (tile_mem_in_act_dout_presplit_vld),
      .dout    (tile_mem_in_act_dout_split),
      .dout_vld(tile_mem_in_act_dout_split_vld)
  );

  always_comb begin
    if (ctrl_pea_en && ctrl_pool_en) begin

      pea_pool_up_data_i     = bias_relu_data_o;
      pea_pool_up_data_vld_i = bias_relu_data_pvld_o;
      bias_relu_prdy_i       = pea_pool_up_rdy_o;
    end else if (ctrl_pool_en) begin

      pea_pool_up_data_i     = tile_mem_in_act_dout_split;
      pea_pool_up_data_vld_i = tile_mem_in_act_dout_split_vld;
      bias_relu_prdy_i       = tile_data_prdy_i;
    end else begin

      pea_pool_up_data_i     = 0;
      pea_pool_up_data_vld_i = 0;
      bias_relu_prdy_i       = tile_data_prdy_i;
    end
  end

  always_comb begin
    if (ctrl_pool_en) begin

      tile_data_o         = pea_pool_res_data_o;
      tile_data_pvld_o    = pea_pool_dn_pvld_o;
      pea_pool_dn_prdy_i = tile_data_prdy_i;
    end else begin

      tile_data_o         = bias_relu_data_o;
      tile_data_pvld_o    = bias_relu_data_pvld_o;
      pea_pool_dn_prdy_i = 0;
    end
  end
  BVP_CORE_BSU_Tile0_pool0 #(
      .NLAYER_ACT_WIDTH(NLAYER_ACT_WIDTH),
      .POOL_FIFO_DEPTH (POOL_FIFO_DEPTH)
  ) upool0 (
      .arst_n                      (arst_n),
      .clk                         (clk),
      .clk_en                      (clk_en_pea_pool),
      .csr_layer_cfg_pool_sizeh    (csr_layer_cfg_pool_sizeh),
      .csr_layer_cfg_pool_sizew    (csr_layer_cfg_pool_sizew),
      .csr_model_cfg_last_pool_type(csr_model_cfg_last_pool_type),
      .ctrl_bias_relu_out_row_done (ctrl_bias_relu_out_row_done),
      .ctrl_pea_en                 (ctrl_pea_en),
      .cur_ifm_done                (cur_ifm_done),
      .dn_prdy_i                   (pea_pool_dn_prdy_i),
      .dn_pvld_o                   (pea_pool_dn_pvld_o),
      .incnt_fm_height_done        (incnt_fm_height_done),
      .incnt_ich_num_done          (incnt_ich_num_done),
      .pool_last_pixel             (pool_last_pixel),
      .pool_res_data_o             (pea_pool_res_data_o),
      .up_data_i                   (pea_pool_up_data_i),
      .up_rdy_o                    (pea_pool_up_rdy_o),
      .up_vld_i                    (pea_pool_up_data_vld_i)
  );

  BVP_CORE_BSU_Tile_br_s1 #(
      .DIN_WIDTH(BIAS_WIDTH)
  ) ubrs1 (
      .arst_n                  (arst_n),
      .bias_relu_data_o_s1     (bias_relu_data_o_s1),
      .bias_relu_data_pvld_o_s1(bias_relu_data_pvld_o_s1),
      .bias_relu_din_act       (bias_relu_din_act),
      .bias_relu_din_act_vld   (bias_relu_din_act_vld),
      .bias_relu_din_bias      (mem_in_bias_dout),
      .bias_relu_din_bias_vld  (mem_in_bias_vld),
      .bias_relu_prdy_i_s1     (bias_relu_prdy_i_s1),
      .bias_relu_prdy_o        (bias_relu_prdy_o),
      .clk                     (clk),
      .clk_en                  (clk_en_bias_relu)
  );
  BVP_CORE_BSU_Tile_br_s2 #(
      .DIN_WIDTH       (BIAS_WIDTH),
      .NLAYER_ACT_WIDTH(NLAYER_ACT_WIDTH)
  ) ubrs2 (
      .arst_n                            (arst_n),
      .aux_rp_calc_skip_rounding         (aux_rp_calc_skip_rounding),
      .aux_rp_calc_truncate_frac_width   (aux_rp_calc_truncate_frac_width[4:0]),
      .aux_rp_calc_truncate_frac_width_m1(aux_rp_calc_truncate_frac_width_m1[3:0]),
      .bias_relu_data_o                  (bias_relu_data_o[NLAYER_ACT_WIDTH-1:0]),
      .bias_relu_data_pvld_o             (bias_relu_data_pvld_o),
      .bias_relu_din_vld_s2              (bias_relu_data_pvld_o_s1),
      .bias_relu_dout_biased             (bias_relu_data_o_s1),
      .bias_relu_prdy_i                  (bias_relu_prdy_i),
      .bias_relu_prdy_o_s2               (bias_relu_prdy_i_s1),
      .clk                               (clk),
      .clk_en                            (clk_en_bias_relu),
      .ctrl_fc_only_en                   (ctrl_fc_only_en)
  );

  assign bias_relu_din_act     = ctrl_fc_only_en ? accu2ofifo_data_row2 : ofifo_accu_dout;
  assign bias_relu_din_act_vld = ctrl_fc_only_en ? accu2ofifo_pvld : ofifo_accu_dout_vld;

  BVP_CORE_BSU_Tile_OFIFO #(
      .OFIFO_WIDTH(SUM_WIDTH),
      .OFIFO_DEPTH(PEA_OFIFO_DEPTH)
  ) uofifo (
      .accu2ofifo_data_row0         (accu2ofifo_data_row0[SUM_WIDTH-1:0]),
      .accu2ofifo_data_row1         (accu2ofifo_data_row1[SUM_WIDTH-1:0]),
      .accu2ofifo_data_row2         (accu2ofifo_data_row2[SUM_WIDTH-1:0]),
      .accu2ofifo_pvld              (accu2ofifo_pvld),
      .arst_n                       (arst_n),
      .clk                          (clk),
      .clk_en                       (clk_en_ofifo),
      .ctrl_ofifo_accu_stridew_valid(ctrl_ofifo_accu_stridew_valid),
      .ctrl_ofifo_avail_for_ih      (ctrl_ofifo_avail_for_ih),
      .cur_ifm_done                 (cur_ifm_done),
      .ofifo_accu_dout              (ofifo_accu_dout[SUM_WIDTH-1:0]),
      .ofifo_accu_dout_vld          (ofifo_accu_dout_vld),
      .ofifo_accu_prdy_i            (bias_relu_prdy_o),
      .ofifo_accu_rdy               (ofifo_accu_rdy),
      .ofifo_rdy                    (ofifo_rdy)
  );

  BVP_CORE_BSU_PEArray_core #(
      .ACT_WIDTH        (ACT_WIDTH),
      .WGT_ENC_WIDTH    (WGT_ENC_WIDTH),
      .PEA_WGT_BUS_WIDTH(PEA_WGT_BUS_WIDTH),
      .DOUT_WIDTH       (SUM_WIDTH),
      .PEA_DOUT_WIDTH   (PEA_DOUT_WIDTH)
  ) upea_0 (
      .arst_n              (arst_n),
      .clk                 (clk),
      .clk_en              (clk_en_pea_core_aux),
      .clk_en_last_pe      (clk_en_pea_core),
      .ctrl_fc_only_en     (ctrl_fc_only_en),
      .ctrl_first_wgt_vld  (ctrl_first_wgt_vld),
      .ctrl_flush_pe2obuf  (ctrl_flush_pe2obuf),
      .ctrl_pe_use_prev_out(ctrl_pe_use_prev_out),
      .flush_pe_prev_out   (flush_pe_prev_out),
      .inbuf2pe_act_data   (inbuf2pe_act_data_pea0[ACT_WIDTH-1:0]),
      .inbuf2pe_act_vld    (inbuf2pe_act_vld_pea0),
      .inbuf2pe_fc_wgt_data(inbuf2pe_fc_wgt_data_pea0[WGT_ENC_WIDTH-1:0]),
      .inbuf2pe_wgt_data   (inbuf2pe_wgt_data_pea0[PEA_WGT_BUS_WIDTH-1:0]),
      .inbuf2pe_wgt_vld    (inbuf2pe_wgt_vld_pea0),
      .outbuf2pe_prdy      (accu2pea_prdy_pea0),
      .pe2inbuf_act_rdy    (pe2inbuf_act_rdy_pea0),
      .pe2inbuf_wgt_rdy    (pe2inbuf_wgt_rdy_pea0),
      .pe2outbuf_data      (pea2accu_data_pea0[PEA_DOUT_WIDTH-1:0]),
      .pe2outbuf_pvld      (pea2accu_pvld_pea0),
      .pedata_col0_buf_in_0(pedata_col0_buf_in_0_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1(pedata_col0_buf_in_1_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2(pedata_col0_buf_in_2_pea0[SUM_WIDTH-1:0])
  );
  BVP_CORE_BSU_PEArray_core #(
      .ACT_WIDTH        (ACT_WIDTH),
      .WGT_ENC_WIDTH    (WGT_ENC_WIDTH),
      .PEA_WGT_BUS_WIDTH(PEA_WGT_BUS_WIDTH),
      .DOUT_WIDTH       (SUM_WIDTH),
      .PEA_DOUT_WIDTH   (PEA_DOUT_WIDTH)
  ) upea_1 (
      .arst_n              (arst_n),
      .clk                 (clk),
      .clk_en              (clk_en_pea_core_aux),
      .clk_en_last_pe      (clk_en_pea_core),
      .ctrl_fc_only_en     (ctrl_fc_only_en),
      .ctrl_first_wgt_vld  (ctrl_first_wgt_vld),
      .ctrl_flush_pe2obuf  (ctrl_flush_pe2obuf),
      .ctrl_pe_use_prev_out(ctrl_pe_use_prev_out),
      .flush_pe_prev_out   (flush_pe_prev_out),
      .inbuf2pe_act_data   (inbuf2pe_act_data_pea1[ACT_WIDTH-1:0]),
      .inbuf2pe_act_vld    (inbuf2pe_act_vld_pea1),
      .inbuf2pe_fc_wgt_data(inbuf2pe_fc_wgt_data_pea1[WGT_ENC_WIDTH-1:0]),
      .inbuf2pe_wgt_data   (inbuf2pe_wgt_data_pea1[PEA_WGT_BUS_WIDTH-1:0]),
      .inbuf2pe_wgt_vld    (inbuf2pe_wgt_vld_pea1),
      .outbuf2pe_prdy      (accu2pea_prdy_pea1),
      .pe2inbuf_act_rdy    (pe2inbuf_act_rdy_pea1),
      .pe2inbuf_wgt_rdy    (pe2inbuf_wgt_rdy_pea1),
      .pe2outbuf_data      (pea2accu_data_pea1[PEA_DOUT_WIDTH-1:0]),
      .pe2outbuf_pvld      (pea2accu_pvld_pea1),
      .pedata_col0_buf_in_0(pedata_col0_buf_in_0_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1(pedata_col0_buf_in_1_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2(pedata_col0_buf_in_2_pea1[SUM_WIDTH-1:0])
  );

  BVP_CORE_BSU_PEArray_accu #(
      .PE_DOUT_WIDTH (SUM_WIDTH),
      .PEA_DOUT_WIDTH(PEA_DOUT_WIDTH)
  ) uaccu (
      .arst_n        (arst_n),
      .clk           (clk),
      .clk_en        (clk_en_pea_accu),
      .din_pea0      (pea2accu_data_pea0[PEA_DOUT_WIDTH-1:0]),
      .din_pea1      (pea2accu_data_pea1[PEA_DOUT_WIDTH-1:0]),
      .dn_prdy_i     (ofifo_accu_rdy),
      .dn_pvld_o     (accu2ofifo_pvld),
      .dout_accu_row0(accu2ofifo_data_row0[SUM_WIDTH-1:0]),
      .dout_accu_row1(accu2ofifo_data_row1[SUM_WIDTH-1:0]),
      .dout_accu_row2(accu2ofifo_data_row2[SUM_WIDTH-1:0]),
      .up_rdy_o      (accu2pea_rdy),
      .up_vld_i      (pea2accu_vld)
  );

  assign pea2accu_vld = pea2accu_pvld_pea0 & pea2accu_pvld_pea1;
  assign accu2pea_prdy_pea0 = accu2pea_rdy;
  assign accu2pea_prdy_pea1 = accu2pea_rdy;

  assign pe2inbuf_rdy = pe2inbuf_act_rdy_pea0 & pe2inbuf_act_rdy_pea1 & pe2inbuf_wgt_rdy_pea0 & pe2inbuf_wgt_rdy_pea1;
  assign pea_act_recv = inbuf2pe_act_vld_pea0 & pe2inbuf_act_rdy_pea0 & inbuf2pe_act_vld_pea1 & pe2inbuf_act_rdy_pea1;
  assign pea_data_recv = (
    inbuf2pe_wgt_vld_pea0 & pe2inbuf_wgt_rdy_pea0 &
    inbuf2pe_wgt_vld_pea1 & pe2inbuf_wgt_rdy_pea1
);
endmodule
