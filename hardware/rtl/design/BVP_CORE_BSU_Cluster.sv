`timescale 1ns / 1ps

module BVP_CORE_BSU_Cluster #(
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
    parameter PEC_OUT_BUS_WIDTH = 8 * NLAYER_ACT_WIDTH,
    parameter PEC_WGT_BUS_WIDTH = 8 * TILE_WGT_BUS_WIDTH,
    parameter PEC_BIAS_BUS_WIDTH = 8 * BIAS_WIDTH,
    parameter TILE_FC_WGT_BUS_WIDTH = 2 * WGT_ENC_WIDTH,
    parameter PEC_FC_WGT_BUS_WIDTH = 8 * TILE_FC_WGT_BUS_WIDTH
) (
    output logic                            accu2ofifo_pvld,
    output logic                            accu2pea_rdy,
    input  logic                            arst_n,
    input  logic                            aux_rp_calc_skip_rounding,
    input  logic [                     4:0] aux_rp_calc_truncate_frac_width,
    input  logic [                     3:0] aux_rp_calc_truncate_frac_width_m1,
    output logic                            bias_relu_prdy_o,
    input  logic                            clk,
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
    input  logic [  PEC_BIAS_BUS_WIDTH-1:0] mem_in_bias_dout,
    input  logic                            mem_in_bias_vld,
    output logic                            ofifo_accu_rdy,
    output logic                            ofifo_rdy,
    output logic                            pe2inbuf_rdy,
    output logic                            pea_act_recv,
    output logic                            pea_data_recv,
    output logic                            pea_pool_up_data_vld_i,
    output logic [   PEC_OUT_BUS_WIDTH-1:0] pec_data_o,
    input  logic                            pec_data_prdy_i,
    output logic                            pec_data_pvld_o,
    input  logic [   TILE_ACT_BUS_WIDTH-1:0] pec_mem_in_act_dout,
    input  logic                            pec_mem_in_act_vld,
    input  logic [PEC_FC_WGT_BUS_WIDTH-1:0] pec_mem_in_fc_wgt_dout,
    input  logic                            pec_mem_in_fc_wgt_vld,
    input  logic [   PEC_WGT_BUS_WIDTH-1:0] pec_mem_in_wgt_dout,
    input  logic                            pec_mem_in_wgt_vld,
    input  logic [           SUM_WIDTH-1:0] pedata_col0_buf_in_0_pea0,
    input  logic [           SUM_WIDTH-1:0] pedata_col0_buf_in_0_pea1,
    input  logic [           SUM_WIDTH-1:0] pedata_col0_buf_in_1_pea0,
    input  logic [           SUM_WIDTH-1:0] pedata_col0_buf_in_1_pea1,
    input  logic [           SUM_WIDTH-1:0] pedata_col0_buf_in_2_pea0,
    input  logic [           SUM_WIDTH-1:0] pedata_col0_buf_in_2_pea1,
    input  logic                            pool_last_pixel
);
  logic                         clk_en_data_disp;
  logic                         clk_en_pec_deser;
  logic                         clk_en_pool;
  logic                         clk_en_pool_aux;
  logic                         clk_en_mac_ops;
  logic                         clk_en_conv_all_pes;
  logic [PEC_OUT_BUS_WIDTH-1:0] deser_pec_data_o;
  logic                         deser_pec_data_pvld_o;
  logic                         accu2ofifo_pvld_tile0;
  logic                         accu2pea_rdy_tile0;
  logic                         bias_relu_prdy_o_tile0;
  logic                         ofifo_accu_rdy_tile0;
  logic                         ofifo_rdy_tile0;
  logic                         pe2inbuf_rdy_tile0;
  logic                         pea_act_recv_tile0;
  logic                         pea_data_recv_tile0;
  logic [ NLAYER_ACT_WIDTH-1:0] tile_data_o_tile0;
  logic                         tile_data_pvld_o_tile0;
  logic                         accu2ofifo_pvld_tile1;
  logic                         accu2pea_rdy_tile1;
  logic                         bias_relu_prdy_o_tile1;
  logic                         ofifo_accu_rdy_tile1;
  logic                         ofifo_rdy_tile1;
  logic                         pe2inbuf_rdy_tile1;
  logic                         pea_act_recv_tile1;
  logic                         pea_data_recv_tile1;
  logic [ NLAYER_ACT_WIDTH-1:0] tile_data_o_tile1;
  logic                         tile_data_pvld_o_tile1;
  logic                         accu2ofifo_pvld_tile2;
  logic                         accu2pea_rdy_tile2;
  logic                         bias_relu_prdy_o_tile2;
  logic                         ofifo_accu_rdy_tile2;
  logic                         ofifo_rdy_tile2;
  logic                         pe2inbuf_rdy_tile2;
  logic                         pea_act_recv_tile2;
  logic                         pea_data_recv_tile2;
  logic [ NLAYER_ACT_WIDTH-1:0] tile_data_o_tile2;
  logic                         tile_data_pvld_o_tile2;
  logic                         accu2ofifo_pvld_tile3;
  logic                         accu2pea_rdy_tile3;
  logic                         bias_relu_prdy_o_tile3;
  logic                         ofifo_accu_rdy_tile3;
  logic                         ofifo_rdy_tile3;
  logic                         pe2inbuf_rdy_tile3;
  logic                         pea_act_recv_tile3;
  logic                         pea_data_recv_tile3;
  logic [ NLAYER_ACT_WIDTH-1:0] tile_data_o_tile3;
  logic                         tile_data_pvld_o_tile3;
  logic                         accu2ofifo_pvld_tile4;
  logic                         accu2pea_rdy_tile4;
  logic                         bias_relu_prdy_o_tile4;
  logic                         ofifo_accu_rdy_tile4;
  logic                         ofifo_rdy_tile4;
  logic                         pe2inbuf_rdy_tile4;
  logic                         pea_act_recv_tile4;
  logic                         pea_data_recv_tile4;
  logic [ NLAYER_ACT_WIDTH-1:0] tile_data_o_tile4;
  logic                         tile_data_pvld_o_tile4;
  logic                         accu2ofifo_pvld_tile5;
  logic                         accu2pea_rdy_tile5;
  logic                         bias_relu_prdy_o_tile5;
  logic                         ofifo_accu_rdy_tile5;
  logic                         ofifo_rdy_tile5;
  logic                         pe2inbuf_rdy_tile5;
  logic                         pea_act_recv_tile5;
  logic                         pea_data_recv_tile5;
  logic [ NLAYER_ACT_WIDTH-1:0] tile_data_o_tile5;
  logic                         tile_data_pvld_o_tile5;
  logic                         accu2ofifo_pvld_tile6;
  logic                         accu2pea_rdy_tile6;
  logic                         bias_relu_prdy_o_tile6;
  logic                         ofifo_accu_rdy_tile6;
  logic                         ofifo_rdy_tile6;
  logic                         pe2inbuf_rdy_tile6;
  logic                         pea_act_recv_tile6;
  logic                         pea_data_recv_tile6;
  logic [ NLAYER_ACT_WIDTH-1:0] tile_data_o_tile6;
  logic                         tile_data_pvld_o_tile6;
  logic                         accu2ofifo_pvld_tile7;
  logic                         accu2pea_rdy_tile7;
  logic                         bias_relu_prdy_o_tile7;
  logic                         ofifo_accu_rdy_tile7;
  logic                         ofifo_rdy_tile7;
  logic                         pe2inbuf_rdy_tile7;
  logic                         pea_act_recv_tile7;
  logic                         pea_data_recv_tile7;
  logic [ NLAYER_ACT_WIDTH-1:0] tile_data_o_tile7;
  logic                         tile_data_pvld_o_tile7;
  logic [PEC_OUT_BUS_WIDTH-1:0] all_pec_data_o;
  logic                         all_pec_data_pvld_o;
  logic [                 15:0] mem_in_bias_dout_tile7;
  logic [                 15:0] mem_in_bias_dout_tile6;
  logic [                 15:0] mem_in_bias_dout_tile5;
  logic [                 15:0] mem_in_bias_dout_tile4;
  logic [                 15:0] mem_in_bias_dout_tile3;
  logic [                 15:0] mem_in_bias_dout_tile2;
  logic [                 15:0] mem_in_bias_dout_tile1;
  logic [                 15:0] mem_in_bias_dout_tile0;
  logic [                 71:0] tile_mem_in_wgt_dout_tile7;
  logic [                 71:0] tile_mem_in_wgt_dout_tile6;
  logic [                 71:0] tile_mem_in_wgt_dout_tile5;
  logic [                 71:0] tile_mem_in_wgt_dout_tile4;
  logic [                 71:0] tile_mem_in_wgt_dout_tile3;
  logic [                 71:0] tile_mem_in_wgt_dout_tile2;
  logic [                 71:0] tile_mem_in_wgt_dout_tile1;
  logic [                 71:0] tile_mem_in_wgt_dout_tile0;
  logic [                  7:0] tile_mem_in_fc_wgt_dout_tile7;
  logic [                  7:0] tile_mem_in_fc_wgt_dout_tile6;
  logic [                  7:0] tile_mem_in_fc_wgt_dout_tile5;
  logic [                  7:0] tile_mem_in_fc_wgt_dout_tile4;
  logic [                  7:0] tile_mem_in_fc_wgt_dout_tile3;
  logic [                  7:0] tile_mem_in_fc_wgt_dout_tile2;
  logic [                  7:0] tile_mem_in_fc_wgt_dout_tile1;
  logic [                  7:0] tile_mem_in_fc_wgt_dout_tile0;

  assign clk_en_data_disp    = !ctrl_pea_en && ctrl_pool_en;
  assign clk_en_pec_deser    = clk_en_data_disp;

  assign clk_en_pool         = ctrl_pool_en;
  assign clk_en_pool_aux     = ctrl_pea_en && ctrl_pool_en;

  assign clk_en_mac_ops      = ctrl_pea_en;
  assign clk_en_conv_all_pes = ctrl_pea_en && !ctrl_fc_only_en;

  BVP_CORE_BSU_Cluster_deser #(
      .DIN_WIDTH        (ACT_WIDTH),
      .PEC_OUT_BUS_WIDTH(PEC_OUT_BUS_WIDTH)
  ) u_deser (
      .arst_n  (arst_n),
      .clk     (clk),
      .clk_en  (clk_en_pec_deser),
      .din     (tile_data_o_tile0),
      .din_vld (tile_data_pvld_o_tile0),
      .dout    (deser_pec_data_o),
      .dout_vld(deser_pec_data_pvld_o)
  );

  BVP_CORE_BSU_Tile0 #(
      .ACT_WIDTH           (ACT_WIDTH),
      .WGT_ENC_WIDTH       (WGT_ENC_WIDTH),
      .POOL_FIFO_DEPTH     (POOL_FIFO_DEPTH),
      .PEA_OFIFO_DEPTH     (PEA_OFIFO_DEPTH),
      .PEA_WGT_BUS_WIDTH   (PEA_WGT_BUS_WIDTH),
      .SUM_WIDTH           (SUM_WIDTH),
      .BIAS_WIDTH          (BIAS_WIDTH),
      .NLAYER_ACT_WIDTH    (NLAYER_ACT_WIDTH),
      .TILE_ACT_BUS_WIDTH   (TILE_ACT_BUS_WIDTH),
      .TILE_WGT_BUS_WIDTH   (TILE_WGT_BUS_WIDTH),
      .PEA_DOUT_WIDTH      (PEA_DOUT_WIDTH),
      .TILE_FC_WGT_BUS_WIDTH(TILE_FC_WGT_BUS_WIDTH)
  ) u_tile0 (
      .accu2ofifo_pvld                   (accu2ofifo_pvld_tile0),
      .accu2pea_rdy                      (accu2pea_rdy_tile0),
      .arst_n                            (arst_n),
      .aux_rp_calc_skip_rounding         (aux_rp_calc_skip_rounding),
      .aux_rp_calc_truncate_frac_width   (aux_rp_calc_truncate_frac_width[4:0]),
      .aux_rp_calc_truncate_frac_width_m1(aux_rp_calc_truncate_frac_width_m1[3:0]),
      .bias_relu_prdy_o                  (bias_relu_prdy_o_tile0),
      .clk                               (clk),
      .clk_en_conv_all_pes               (clk_en_conv_all_pes),
      .clk_en_data_disp                  (clk_en_data_disp),
      .clk_en_mac_ops                    (clk_en_mac_ops),
      .clk_en_pool                       (clk_en_pool),
      .csr_layer_cfg_pool_sizeh          (csr_layer_cfg_pool_sizeh),
      .csr_layer_cfg_pool_sizew          (csr_layer_cfg_pool_sizew),
      .csr_model_cfg_last_pool_type      (csr_model_cfg_last_pool_type),
      .ctrl_bias_relu_out_row_done       (ctrl_bias_relu_out_row_done),
      .ctrl_fc_only_en                   (ctrl_fc_only_en),
      .ctrl_first_wgt_vld                (ctrl_first_wgt_vld),
      .ctrl_flush_pe2obuf                (ctrl_flush_pe2obuf),
      .ctrl_ofifo_accu_stridew_valid     (ctrl_ofifo_accu_stridew_valid),
      .ctrl_ofifo_avail_for_ih           (ctrl_ofifo_avail_for_ih),
      .ctrl_pe_use_prev_out              (ctrl_pe_use_prev_out),
      .ctrl_pea_en                       (ctrl_pea_en),
      .ctrl_pool_en                      (ctrl_pool_en),
      .cur_ifm_done                      (cur_ifm_done),
      .flush_pe_prev_out                 (flush_pe_prev_out),
      .incnt_fm_height_done              (incnt_fm_height_done),
      .incnt_ich_num_done                (incnt_ich_num_done),
      .mem_in_bias_dout                  (mem_in_bias_dout_tile0),
      .mem_in_bias_vld                   (mem_in_bias_vld),
      .ofifo_accu_rdy                    (ofifo_accu_rdy_tile0),
      .ofifo_rdy                         (ofifo_rdy_tile0),
      .pe2inbuf_rdy                      (pe2inbuf_rdy_tile0),
      .pea_act_recv                      (pea_act_recv_tile0),
      .pea_data_recv                     (pea_data_recv_tile0),
      .pea_pool_up_data_vld_i            (pea_pool_up_data_vld_i),
      .tile_data_o                        (tile_data_o_tile0),
      .tile_data_prdy_i                   (pec_data_prdy_i),
      .tile_data_pvld_o                   (tile_data_pvld_o_tile0),
      .tile_mem_in_act_dout               (pec_mem_in_act_dout[TILE_ACT_BUS_WIDTH-1:0]),
      .tile_mem_in_act_vld                (pec_mem_in_act_vld),
      .tile_mem_in_fc_wgt_dout            (tile_mem_in_fc_wgt_dout_tile0),
      .tile_mem_in_fc_wgt_vld             (pec_mem_in_fc_wgt_vld),
      .tile_mem_in_wgt_dout               (tile_mem_in_wgt_dout_tile0),
      .tile_mem_in_wgt_vld                (pec_mem_in_wgt_vld),
      .pedata_col0_buf_in_0_pea0         (pedata_col0_buf_in_0_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_0_pea1         (pedata_col0_buf_in_0_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea0         (pedata_col0_buf_in_1_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea1         (pedata_col0_buf_in_1_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea0         (pedata_col0_buf_in_2_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea1         (pedata_col0_buf_in_2_pea1[SUM_WIDTH-1:0]),
      .pool_last_pixel                   (pool_last_pixel)
  );
  BVP_CORE_BSU_Tile #(
      .ACT_WIDTH           (ACT_WIDTH),
      .WGT_ENC_WIDTH       (WGT_ENC_WIDTH),
      .POOL_FIFO_DEPTH     (POOL_FIFO_DEPTH),
      .PEA_OFIFO_DEPTH     (PEA_OFIFO_DEPTH),
      .PEA_WGT_BUS_WIDTH   (PEA_WGT_BUS_WIDTH),
      .SUM_WIDTH           (SUM_WIDTH),
      .BIAS_WIDTH          (BIAS_WIDTH),
      .NLAYER_ACT_WIDTH    (NLAYER_ACT_WIDTH),
      .TILE_ACT_BUS_WIDTH   (TILE_ACT_BUS_WIDTH),
      .TILE_WGT_BUS_WIDTH   (TILE_WGT_BUS_WIDTH),
      .PEA_DOUT_WIDTH      (PEA_DOUT_WIDTH),
      .TILE_FC_WGT_BUS_WIDTH(TILE_FC_WGT_BUS_WIDTH)
  ) u_tile1 (
      .accu2ofifo_pvld                   (accu2ofifo_pvld_tile1),
      .accu2pea_rdy                      (accu2pea_rdy_tile1),
      .arst_n                            (arst_n),
      .aux_rp_calc_skip_rounding         (aux_rp_calc_skip_rounding),
      .aux_rp_calc_truncate_frac_width   (aux_rp_calc_truncate_frac_width[4:0]),
      .aux_rp_calc_truncate_frac_width_m1(aux_rp_calc_truncate_frac_width_m1[3:0]),
      .bias_relu_prdy_o                  (bias_relu_prdy_o_tile1),
      .clk                               (clk),
      .clk_en_conv_all_pes               (clk_en_conv_all_pes),
      .clk_en_mac_ops                    (clk_en_mac_ops),
      .clk_en_pool_aux                   (clk_en_pool_aux),
      .csr_layer_cfg_pool_sizeh          (csr_layer_cfg_pool_sizeh),
      .csr_layer_cfg_pool_sizew          (csr_layer_cfg_pool_sizew),
      .ctrl_bias_relu_out_row_done       (ctrl_bias_relu_out_row_done),
      .ctrl_fc_only_en                   (ctrl_fc_only_en),
      .ctrl_first_wgt_vld                (ctrl_first_wgt_vld),
      .ctrl_flush_pe2obuf                (ctrl_flush_pe2obuf),
      .ctrl_ofifo_accu_stridew_valid     (ctrl_ofifo_accu_stridew_valid),
      .ctrl_ofifo_avail_for_ih           (ctrl_ofifo_avail_for_ih),
      .ctrl_pe_use_prev_out              (ctrl_pe_use_prev_out),
      .ctrl_pool_en                      (ctrl_pool_en),
      .cur_ifm_done                      (cur_ifm_done),
      .flush_pe_prev_out                 (flush_pe_prev_out),
      .mem_in_bias_dout                  (mem_in_bias_dout_tile1),
      .mem_in_bias_vld                   (mem_in_bias_vld),
      .ofifo_accu_rdy                    (ofifo_accu_rdy_tile1),
      .ofifo_rdy                         (ofifo_rdy_tile1),
      .pe2inbuf_rdy                      (pe2inbuf_rdy_tile1),
      .pea_act_recv                      (pea_act_recv_tile1),
      .pea_data_recv                     (pea_data_recv_tile1),
      .tile_data_o                        (tile_data_o_tile1),
      .tile_data_prdy_i                   (pec_data_prdy_i),
      .tile_data_pvld_o                   (tile_data_pvld_o_tile1),
      .tile_mem_in_act_dout               (pec_mem_in_act_dout[TILE_ACT_BUS_WIDTH-1:0]),
      .tile_mem_in_act_vld                (pec_mem_in_act_vld),
      .tile_mem_in_fc_wgt_dout            (tile_mem_in_fc_wgt_dout_tile1),
      .tile_mem_in_fc_wgt_vld             (pec_mem_in_fc_wgt_vld),
      .tile_mem_in_wgt_dout               (tile_mem_in_wgt_dout_tile1),
      .tile_mem_in_wgt_vld                (pec_mem_in_wgt_vld),
      .pedata_col0_buf_in_0_pea0         (pedata_col0_buf_in_0_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_0_pea1         (pedata_col0_buf_in_0_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea0         (pedata_col0_buf_in_1_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea1         (pedata_col0_buf_in_1_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea0         (pedata_col0_buf_in_2_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea1         (pedata_col0_buf_in_2_pea1[SUM_WIDTH-1:0])
  );
  BVP_CORE_BSU_Tile #(
      .ACT_WIDTH           (ACT_WIDTH),
      .WGT_ENC_WIDTH       (WGT_ENC_WIDTH),
      .POOL_FIFO_DEPTH     (POOL_FIFO_DEPTH),
      .PEA_OFIFO_DEPTH     (PEA_OFIFO_DEPTH),
      .PEA_WGT_BUS_WIDTH   (PEA_WGT_BUS_WIDTH),
      .SUM_WIDTH           (SUM_WIDTH),
      .BIAS_WIDTH          (BIAS_WIDTH),
      .NLAYER_ACT_WIDTH    (NLAYER_ACT_WIDTH),
      .TILE_ACT_BUS_WIDTH   (TILE_ACT_BUS_WIDTH),
      .TILE_WGT_BUS_WIDTH   (TILE_WGT_BUS_WIDTH),
      .PEA_DOUT_WIDTH      (PEA_DOUT_WIDTH),
      .TILE_FC_WGT_BUS_WIDTH(TILE_FC_WGT_BUS_WIDTH)
  ) u_tile2 (
      .accu2ofifo_pvld                   (accu2ofifo_pvld_tile2),
      .accu2pea_rdy                      (accu2pea_rdy_tile2),
      .arst_n                            (arst_n),
      .aux_rp_calc_skip_rounding         (aux_rp_calc_skip_rounding),
      .aux_rp_calc_truncate_frac_width   (aux_rp_calc_truncate_frac_width[4:0]),
      .aux_rp_calc_truncate_frac_width_m1(aux_rp_calc_truncate_frac_width_m1[3:0]),
      .bias_relu_prdy_o                  (bias_relu_prdy_o_tile2),
      .clk                               (clk),
      .clk_en_conv_all_pes               (clk_en_conv_all_pes),
      .clk_en_mac_ops                    (clk_en_mac_ops),
      .clk_en_pool_aux                   (clk_en_pool_aux),
      .csr_layer_cfg_pool_sizeh          (csr_layer_cfg_pool_sizeh),
      .csr_layer_cfg_pool_sizew          (csr_layer_cfg_pool_sizew),
      .ctrl_bias_relu_out_row_done       (ctrl_bias_relu_out_row_done),
      .ctrl_fc_only_en                   (ctrl_fc_only_en),
      .ctrl_first_wgt_vld                (ctrl_first_wgt_vld),
      .ctrl_flush_pe2obuf                (ctrl_flush_pe2obuf),
      .ctrl_ofifo_accu_stridew_valid     (ctrl_ofifo_accu_stridew_valid),
      .ctrl_ofifo_avail_for_ih           (ctrl_ofifo_avail_for_ih),
      .ctrl_pe_use_prev_out              (ctrl_pe_use_prev_out),
      .ctrl_pool_en                      (ctrl_pool_en),
      .cur_ifm_done                      (cur_ifm_done),
      .flush_pe_prev_out                 (flush_pe_prev_out),
      .mem_in_bias_dout                  (mem_in_bias_dout_tile2),
      .mem_in_bias_vld                   (mem_in_bias_vld),
      .ofifo_accu_rdy                    (ofifo_accu_rdy_tile2),
      .ofifo_rdy                         (ofifo_rdy_tile2),
      .pe2inbuf_rdy                      (pe2inbuf_rdy_tile2),
      .pea_act_recv                      (pea_act_recv_tile2),
      .pea_data_recv                     (pea_data_recv_tile2),
      .tile_data_o                        (tile_data_o_tile2),
      .tile_data_prdy_i                   (pec_data_prdy_i),
      .tile_data_pvld_o                   (tile_data_pvld_o_tile2),
      .tile_mem_in_act_dout               (pec_mem_in_act_dout[TILE_ACT_BUS_WIDTH-1:0]),
      .tile_mem_in_act_vld                (pec_mem_in_act_vld),
      .tile_mem_in_fc_wgt_dout            (tile_mem_in_fc_wgt_dout_tile2),
      .tile_mem_in_fc_wgt_vld             (pec_mem_in_fc_wgt_vld),
      .tile_mem_in_wgt_dout               (tile_mem_in_wgt_dout_tile2),
      .tile_mem_in_wgt_vld                (pec_mem_in_wgt_vld),
      .pedata_col0_buf_in_0_pea0         (pedata_col0_buf_in_0_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_0_pea1         (pedata_col0_buf_in_0_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea0         (pedata_col0_buf_in_1_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea1         (pedata_col0_buf_in_1_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea0         (pedata_col0_buf_in_2_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea1         (pedata_col0_buf_in_2_pea1[SUM_WIDTH-1:0])
  );
  BVP_CORE_BSU_Tile #(
      .ACT_WIDTH           (ACT_WIDTH),
      .WGT_ENC_WIDTH       (WGT_ENC_WIDTH),
      .POOL_FIFO_DEPTH     (POOL_FIFO_DEPTH),
      .PEA_OFIFO_DEPTH     (PEA_OFIFO_DEPTH),
      .PEA_WGT_BUS_WIDTH   (PEA_WGT_BUS_WIDTH),
      .SUM_WIDTH           (SUM_WIDTH),
      .BIAS_WIDTH          (BIAS_WIDTH),
      .NLAYER_ACT_WIDTH    (NLAYER_ACT_WIDTH),
      .TILE_ACT_BUS_WIDTH   (TILE_ACT_BUS_WIDTH),
      .TILE_WGT_BUS_WIDTH   (TILE_WGT_BUS_WIDTH),
      .PEA_DOUT_WIDTH      (PEA_DOUT_WIDTH),
      .TILE_FC_WGT_BUS_WIDTH(TILE_FC_WGT_BUS_WIDTH)
  ) u_tile3 (
      .accu2ofifo_pvld                   (accu2ofifo_pvld_tile3),
      .accu2pea_rdy                      (accu2pea_rdy_tile3),
      .arst_n                            (arst_n),
      .aux_rp_calc_skip_rounding         (aux_rp_calc_skip_rounding),
      .aux_rp_calc_truncate_frac_width   (aux_rp_calc_truncate_frac_width[4:0]),
      .aux_rp_calc_truncate_frac_width_m1(aux_rp_calc_truncate_frac_width_m1[3:0]),
      .bias_relu_prdy_o                  (bias_relu_prdy_o_tile3),
      .clk                               (clk),
      .clk_en_conv_all_pes               (clk_en_conv_all_pes),
      .clk_en_mac_ops                    (clk_en_mac_ops),
      .clk_en_pool_aux                   (clk_en_pool_aux),
      .csr_layer_cfg_pool_sizeh          (csr_layer_cfg_pool_sizeh),
      .csr_layer_cfg_pool_sizew          (csr_layer_cfg_pool_sizew),
      .ctrl_bias_relu_out_row_done       (ctrl_bias_relu_out_row_done),
      .ctrl_fc_only_en                   (ctrl_fc_only_en),
      .ctrl_first_wgt_vld                (ctrl_first_wgt_vld),
      .ctrl_flush_pe2obuf                (ctrl_flush_pe2obuf),
      .ctrl_ofifo_accu_stridew_valid     (ctrl_ofifo_accu_stridew_valid),
      .ctrl_ofifo_avail_for_ih           (ctrl_ofifo_avail_for_ih),
      .ctrl_pe_use_prev_out              (ctrl_pe_use_prev_out),
      .ctrl_pool_en                      (ctrl_pool_en),
      .cur_ifm_done                      (cur_ifm_done),
      .flush_pe_prev_out                 (flush_pe_prev_out),
      .mem_in_bias_dout                  (mem_in_bias_dout_tile3),
      .mem_in_bias_vld                   (mem_in_bias_vld),
      .ofifo_accu_rdy                    (ofifo_accu_rdy_tile3),
      .ofifo_rdy                         (ofifo_rdy_tile3),
      .pe2inbuf_rdy                      (pe2inbuf_rdy_tile3),
      .pea_act_recv                      (pea_act_recv_tile3),
      .pea_data_recv                     (pea_data_recv_tile3),
      .tile_data_o                        (tile_data_o_tile3),
      .tile_data_prdy_i                   (pec_data_prdy_i),
      .tile_data_pvld_o                   (tile_data_pvld_o_tile3),
      .tile_mem_in_act_dout               (pec_mem_in_act_dout[TILE_ACT_BUS_WIDTH-1:0]),
      .tile_mem_in_act_vld                (pec_mem_in_act_vld),
      .tile_mem_in_fc_wgt_dout            (tile_mem_in_fc_wgt_dout_tile3),
      .tile_mem_in_fc_wgt_vld             (pec_mem_in_fc_wgt_vld),
      .tile_mem_in_wgt_dout               (tile_mem_in_wgt_dout_tile3),
      .tile_mem_in_wgt_vld                (pec_mem_in_wgt_vld),
      .pedata_col0_buf_in_0_pea0         (pedata_col0_buf_in_0_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_0_pea1         (pedata_col0_buf_in_0_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea0         (pedata_col0_buf_in_1_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea1         (pedata_col0_buf_in_1_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea0         (pedata_col0_buf_in_2_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea1         (pedata_col0_buf_in_2_pea1[SUM_WIDTH-1:0])
  );
  BVP_CORE_BSU_Tile #(
      .ACT_WIDTH           (ACT_WIDTH),
      .WGT_ENC_WIDTH       (WGT_ENC_WIDTH),
      .POOL_FIFO_DEPTH     (POOL_FIFO_DEPTH),
      .PEA_OFIFO_DEPTH     (PEA_OFIFO_DEPTH),
      .PEA_WGT_BUS_WIDTH   (PEA_WGT_BUS_WIDTH),
      .SUM_WIDTH           (SUM_WIDTH),
      .BIAS_WIDTH          (BIAS_WIDTH),
      .NLAYER_ACT_WIDTH    (NLAYER_ACT_WIDTH),
      .TILE_ACT_BUS_WIDTH   (TILE_ACT_BUS_WIDTH),
      .TILE_WGT_BUS_WIDTH   (TILE_WGT_BUS_WIDTH),
      .PEA_DOUT_WIDTH      (PEA_DOUT_WIDTH),
      .TILE_FC_WGT_BUS_WIDTH(TILE_FC_WGT_BUS_WIDTH)
  ) u_tile4 (
      .accu2ofifo_pvld                   (accu2ofifo_pvld_tile4),
      .accu2pea_rdy                      (accu2pea_rdy_tile4),
      .arst_n                            (arst_n),
      .aux_rp_calc_skip_rounding         (aux_rp_calc_skip_rounding),
      .aux_rp_calc_truncate_frac_width   (aux_rp_calc_truncate_frac_width[4:0]),
      .aux_rp_calc_truncate_frac_width_m1(aux_rp_calc_truncate_frac_width_m1[3:0]),
      .bias_relu_prdy_o                  (bias_relu_prdy_o_tile4),
      .clk                               (clk),
      .clk_en_conv_all_pes               (clk_en_conv_all_pes),
      .clk_en_mac_ops                    (clk_en_mac_ops),
      .clk_en_pool_aux                   (clk_en_pool_aux),
      .csr_layer_cfg_pool_sizeh          (csr_layer_cfg_pool_sizeh),
      .csr_layer_cfg_pool_sizew          (csr_layer_cfg_pool_sizew),
      .ctrl_bias_relu_out_row_done       (ctrl_bias_relu_out_row_done),
      .ctrl_fc_only_en                   (ctrl_fc_only_en),
      .ctrl_first_wgt_vld                (ctrl_first_wgt_vld),
      .ctrl_flush_pe2obuf                (ctrl_flush_pe2obuf),
      .ctrl_ofifo_accu_stridew_valid     (ctrl_ofifo_accu_stridew_valid),
      .ctrl_ofifo_avail_for_ih           (ctrl_ofifo_avail_for_ih),
      .ctrl_pe_use_prev_out              (ctrl_pe_use_prev_out),
      .ctrl_pool_en                      (ctrl_pool_en),
      .cur_ifm_done                      (cur_ifm_done),
      .flush_pe_prev_out                 (flush_pe_prev_out),
      .mem_in_bias_dout                  (mem_in_bias_dout_tile4),
      .mem_in_bias_vld                   (mem_in_bias_vld),
      .ofifo_accu_rdy                    (ofifo_accu_rdy_tile4),
      .ofifo_rdy                         (ofifo_rdy_tile4),
      .pe2inbuf_rdy                      (pe2inbuf_rdy_tile4),
      .pea_act_recv                      (pea_act_recv_tile4),
      .pea_data_recv                     (pea_data_recv_tile4),
      .tile_data_o                        (tile_data_o_tile4),
      .tile_data_prdy_i                   (pec_data_prdy_i),
      .tile_data_pvld_o                   (tile_data_pvld_o_tile4),
      .tile_mem_in_act_dout               (pec_mem_in_act_dout[TILE_ACT_BUS_WIDTH-1:0]),
      .tile_mem_in_act_vld                (pec_mem_in_act_vld),
      .tile_mem_in_fc_wgt_dout            (tile_mem_in_fc_wgt_dout_tile4),
      .tile_mem_in_fc_wgt_vld             (pec_mem_in_fc_wgt_vld),
      .tile_mem_in_wgt_dout               (tile_mem_in_wgt_dout_tile4),
      .tile_mem_in_wgt_vld                (pec_mem_in_wgt_vld),
      .pedata_col0_buf_in_0_pea0         (pedata_col0_buf_in_0_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_0_pea1         (pedata_col0_buf_in_0_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea0         (pedata_col0_buf_in_1_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea1         (pedata_col0_buf_in_1_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea0         (pedata_col0_buf_in_2_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea1         (pedata_col0_buf_in_2_pea1[SUM_WIDTH-1:0])
  );
  BVP_CORE_BSU_Tile #(
      .ACT_WIDTH           (ACT_WIDTH),
      .WGT_ENC_WIDTH       (WGT_ENC_WIDTH),
      .POOL_FIFO_DEPTH     (POOL_FIFO_DEPTH),
      .PEA_OFIFO_DEPTH     (PEA_OFIFO_DEPTH),
      .PEA_WGT_BUS_WIDTH   (PEA_WGT_BUS_WIDTH),
      .SUM_WIDTH           (SUM_WIDTH),
      .BIAS_WIDTH          (BIAS_WIDTH),
      .NLAYER_ACT_WIDTH    (NLAYER_ACT_WIDTH),
      .TILE_ACT_BUS_WIDTH   (TILE_ACT_BUS_WIDTH),
      .TILE_WGT_BUS_WIDTH   (TILE_WGT_BUS_WIDTH),
      .PEA_DOUT_WIDTH      (PEA_DOUT_WIDTH),
      .TILE_FC_WGT_BUS_WIDTH(TILE_FC_WGT_BUS_WIDTH)
  ) u_tile5 (
      .accu2ofifo_pvld                   (accu2ofifo_pvld_tile5),
      .accu2pea_rdy                      (accu2pea_rdy_tile5),
      .arst_n                            (arst_n),
      .aux_rp_calc_skip_rounding         (aux_rp_calc_skip_rounding),
      .aux_rp_calc_truncate_frac_width   (aux_rp_calc_truncate_frac_width[4:0]),
      .aux_rp_calc_truncate_frac_width_m1(aux_rp_calc_truncate_frac_width_m1[3:0]),
      .bias_relu_prdy_o                  (bias_relu_prdy_o_tile5),
      .clk                               (clk),
      .clk_en_conv_all_pes               (clk_en_conv_all_pes),
      .clk_en_mac_ops                    (clk_en_mac_ops),
      .clk_en_pool_aux                   (clk_en_pool_aux),
      .csr_layer_cfg_pool_sizeh          (csr_layer_cfg_pool_sizeh),
      .csr_layer_cfg_pool_sizew          (csr_layer_cfg_pool_sizew),
      .ctrl_bias_relu_out_row_done       (ctrl_bias_relu_out_row_done),
      .ctrl_fc_only_en                   (ctrl_fc_only_en),
      .ctrl_first_wgt_vld                (ctrl_first_wgt_vld),
      .ctrl_flush_pe2obuf                (ctrl_flush_pe2obuf),
      .ctrl_ofifo_accu_stridew_valid     (ctrl_ofifo_accu_stridew_valid),
      .ctrl_ofifo_avail_for_ih           (ctrl_ofifo_avail_for_ih),
      .ctrl_pe_use_prev_out              (ctrl_pe_use_prev_out),
      .ctrl_pool_en                      (ctrl_pool_en),
      .cur_ifm_done                      (cur_ifm_done),
      .flush_pe_prev_out                 (flush_pe_prev_out),
      .mem_in_bias_dout                  (mem_in_bias_dout_tile5),
      .mem_in_bias_vld                   (mem_in_bias_vld),
      .ofifo_accu_rdy                    (ofifo_accu_rdy_tile5),
      .ofifo_rdy                         (ofifo_rdy_tile5),
      .pe2inbuf_rdy                      (pe2inbuf_rdy_tile5),
      .pea_act_recv                      (pea_act_recv_tile5),
      .pea_data_recv                     (pea_data_recv_tile5),
      .tile_data_o                        (tile_data_o_tile5),
      .tile_data_prdy_i                   (pec_data_prdy_i),
      .tile_data_pvld_o                   (tile_data_pvld_o_tile5),
      .tile_mem_in_act_dout               (pec_mem_in_act_dout[TILE_ACT_BUS_WIDTH-1:0]),
      .tile_mem_in_act_vld                (pec_mem_in_act_vld),
      .tile_mem_in_fc_wgt_dout            (tile_mem_in_fc_wgt_dout_tile5),
      .tile_mem_in_fc_wgt_vld             (pec_mem_in_fc_wgt_vld),
      .tile_mem_in_wgt_dout               (tile_mem_in_wgt_dout_tile5),
      .tile_mem_in_wgt_vld                (pec_mem_in_wgt_vld),
      .pedata_col0_buf_in_0_pea0         (pedata_col0_buf_in_0_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_0_pea1         (pedata_col0_buf_in_0_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea0         (pedata_col0_buf_in_1_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea1         (pedata_col0_buf_in_1_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea0         (pedata_col0_buf_in_2_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea1         (pedata_col0_buf_in_2_pea1[SUM_WIDTH-1:0])
  );
  BVP_CORE_BSU_Tile #(
      .ACT_WIDTH           (ACT_WIDTH),
      .WGT_ENC_WIDTH       (WGT_ENC_WIDTH),
      .POOL_FIFO_DEPTH     (POOL_FIFO_DEPTH),
      .PEA_OFIFO_DEPTH     (PEA_OFIFO_DEPTH),
      .PEA_WGT_BUS_WIDTH   (PEA_WGT_BUS_WIDTH),
      .SUM_WIDTH           (SUM_WIDTH),
      .BIAS_WIDTH          (BIAS_WIDTH),
      .NLAYER_ACT_WIDTH    (NLAYER_ACT_WIDTH),
      .TILE_ACT_BUS_WIDTH   (TILE_ACT_BUS_WIDTH),
      .TILE_WGT_BUS_WIDTH   (TILE_WGT_BUS_WIDTH),
      .PEA_DOUT_WIDTH      (PEA_DOUT_WIDTH),
      .TILE_FC_WGT_BUS_WIDTH(TILE_FC_WGT_BUS_WIDTH)
  ) u_tile6 (
      .accu2ofifo_pvld                   (accu2ofifo_pvld_tile6),
      .accu2pea_rdy                      (accu2pea_rdy_tile6),
      .arst_n                            (arst_n),
      .aux_rp_calc_skip_rounding         (aux_rp_calc_skip_rounding),
      .aux_rp_calc_truncate_frac_width   (aux_rp_calc_truncate_frac_width[4:0]),
      .aux_rp_calc_truncate_frac_width_m1(aux_rp_calc_truncate_frac_width_m1[3:0]),
      .bias_relu_prdy_o                  (bias_relu_prdy_o_tile6),
      .clk                               (clk),
      .clk_en_conv_all_pes               (clk_en_conv_all_pes),
      .clk_en_mac_ops                    (clk_en_mac_ops),
      .clk_en_pool_aux                   (clk_en_pool_aux),
      .csr_layer_cfg_pool_sizeh          (csr_layer_cfg_pool_sizeh),
      .csr_layer_cfg_pool_sizew          (csr_layer_cfg_pool_sizew),
      .ctrl_bias_relu_out_row_done       (ctrl_bias_relu_out_row_done),
      .ctrl_fc_only_en                   (ctrl_fc_only_en),
      .ctrl_first_wgt_vld                (ctrl_first_wgt_vld),
      .ctrl_flush_pe2obuf                (ctrl_flush_pe2obuf),
      .ctrl_ofifo_accu_stridew_valid     (ctrl_ofifo_accu_stridew_valid),
      .ctrl_ofifo_avail_for_ih           (ctrl_ofifo_avail_for_ih),
      .ctrl_pe_use_prev_out              (ctrl_pe_use_prev_out),
      .ctrl_pool_en                      (ctrl_pool_en),
      .cur_ifm_done                      (cur_ifm_done),
      .flush_pe_prev_out                 (flush_pe_prev_out),
      .mem_in_bias_dout                  (mem_in_bias_dout_tile6),
      .mem_in_bias_vld                   (mem_in_bias_vld),
      .ofifo_accu_rdy                    (ofifo_accu_rdy_tile6),
      .ofifo_rdy                         (ofifo_rdy_tile6),
      .pe2inbuf_rdy                      (pe2inbuf_rdy_tile6),
      .pea_act_recv                      (pea_act_recv_tile6),
      .pea_data_recv                     (pea_data_recv_tile6),
      .tile_data_o                        (tile_data_o_tile6),
      .tile_data_prdy_i                   (pec_data_prdy_i),
      .tile_data_pvld_o                   (tile_data_pvld_o_tile6),
      .tile_mem_in_act_dout               (pec_mem_in_act_dout[TILE_ACT_BUS_WIDTH-1:0]),
      .tile_mem_in_act_vld                (pec_mem_in_act_vld),
      .tile_mem_in_fc_wgt_dout            (tile_mem_in_fc_wgt_dout_tile6),
      .tile_mem_in_fc_wgt_vld             (pec_mem_in_fc_wgt_vld),
      .tile_mem_in_wgt_dout               (tile_mem_in_wgt_dout_tile6),
      .tile_mem_in_wgt_vld                (pec_mem_in_wgt_vld),
      .pedata_col0_buf_in_0_pea0         (pedata_col0_buf_in_0_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_0_pea1         (pedata_col0_buf_in_0_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea0         (pedata_col0_buf_in_1_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea1         (pedata_col0_buf_in_1_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea0         (pedata_col0_buf_in_2_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea1         (pedata_col0_buf_in_2_pea1[SUM_WIDTH-1:0])
  );
  BVP_CORE_BSU_Tile #(
      .ACT_WIDTH           (ACT_WIDTH),
      .WGT_ENC_WIDTH       (WGT_ENC_WIDTH),
      .POOL_FIFO_DEPTH     (POOL_FIFO_DEPTH),
      .PEA_OFIFO_DEPTH     (PEA_OFIFO_DEPTH),
      .PEA_WGT_BUS_WIDTH   (PEA_WGT_BUS_WIDTH),
      .SUM_WIDTH           (SUM_WIDTH),
      .BIAS_WIDTH          (BIAS_WIDTH),
      .NLAYER_ACT_WIDTH    (NLAYER_ACT_WIDTH),
      .TILE_ACT_BUS_WIDTH   (TILE_ACT_BUS_WIDTH),
      .TILE_WGT_BUS_WIDTH   (TILE_WGT_BUS_WIDTH),
      .PEA_DOUT_WIDTH      (PEA_DOUT_WIDTH),
      .TILE_FC_WGT_BUS_WIDTH(TILE_FC_WGT_BUS_WIDTH)
  ) u_tile7 (
      .accu2ofifo_pvld                   (accu2ofifo_pvld_tile7),
      .accu2pea_rdy                      (accu2pea_rdy_tile7),
      .arst_n                            (arst_n),
      .aux_rp_calc_skip_rounding         (aux_rp_calc_skip_rounding),
      .aux_rp_calc_truncate_frac_width   (aux_rp_calc_truncate_frac_width[4:0]),
      .aux_rp_calc_truncate_frac_width_m1(aux_rp_calc_truncate_frac_width_m1[3:0]),
      .bias_relu_prdy_o                  (bias_relu_prdy_o_tile7),
      .clk                               (clk),
      .clk_en_conv_all_pes               (clk_en_conv_all_pes),
      .clk_en_mac_ops                    (clk_en_mac_ops),
      .clk_en_pool_aux                   (clk_en_pool_aux),
      .csr_layer_cfg_pool_sizeh          (csr_layer_cfg_pool_sizeh),
      .csr_layer_cfg_pool_sizew          (csr_layer_cfg_pool_sizew),
      .ctrl_bias_relu_out_row_done       (ctrl_bias_relu_out_row_done),
      .ctrl_fc_only_en                   (ctrl_fc_only_en),
      .ctrl_first_wgt_vld                (ctrl_first_wgt_vld),
      .ctrl_flush_pe2obuf                (ctrl_flush_pe2obuf),
      .ctrl_ofifo_accu_stridew_valid     (ctrl_ofifo_accu_stridew_valid),
      .ctrl_ofifo_avail_for_ih           (ctrl_ofifo_avail_for_ih),
      .ctrl_pe_use_prev_out              (ctrl_pe_use_prev_out),
      .ctrl_pool_en                      (ctrl_pool_en),
      .cur_ifm_done                      (cur_ifm_done),
      .flush_pe_prev_out                 (flush_pe_prev_out),
      .mem_in_bias_dout                  (mem_in_bias_dout_tile7),
      .mem_in_bias_vld                   (mem_in_bias_vld),
      .ofifo_accu_rdy                    (ofifo_accu_rdy_tile7),
      .ofifo_rdy                         (ofifo_rdy_tile7),
      .pe2inbuf_rdy                      (pe2inbuf_rdy_tile7),
      .pea_act_recv                      (pea_act_recv_tile7),
      .pea_data_recv                     (pea_data_recv_tile7),
      .tile_data_o                        (tile_data_o_tile7),
      .tile_data_prdy_i                   (pec_data_prdy_i),
      .tile_data_pvld_o                   (tile_data_pvld_o_tile7),
      .tile_mem_in_act_dout               (pec_mem_in_act_dout[TILE_ACT_BUS_WIDTH-1:0]),
      .tile_mem_in_act_vld                (pec_mem_in_act_vld),
      .tile_mem_in_fc_wgt_dout            (tile_mem_in_fc_wgt_dout_tile7),
      .tile_mem_in_fc_wgt_vld             (pec_mem_in_fc_wgt_vld),
      .tile_mem_in_wgt_dout               (tile_mem_in_wgt_dout_tile7),
      .tile_mem_in_wgt_vld                (pec_mem_in_wgt_vld),
      .pedata_col0_buf_in_0_pea0         (pedata_col0_buf_in_0_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_0_pea1         (pedata_col0_buf_in_0_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea0         (pedata_col0_buf_in_1_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_1_pea1         (pedata_col0_buf_in_1_pea1[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea0         (pedata_col0_buf_in_2_pea0[SUM_WIDTH-1:0]),
      .pedata_col0_buf_in_2_pea1         (pedata_col0_buf_in_2_pea1[SUM_WIDTH-1:0])
  );
  assign accu2ofifo_pvld =
      accu2ofifo_pvld_tile7 &
      accu2ofifo_pvld_tile6 &
      accu2ofifo_pvld_tile5 &
      accu2ofifo_pvld_tile4 &
      accu2ofifo_pvld_tile3 &
      accu2ofifo_pvld_tile2 &
      accu2ofifo_pvld_tile1 &
      accu2ofifo_pvld_tile0 ;
  assign accu2pea_rdy =
      accu2pea_rdy_tile7 &
      accu2pea_rdy_tile6 &
      accu2pea_rdy_tile5 &
      accu2pea_rdy_tile4 &
      accu2pea_rdy_tile3 &
      accu2pea_rdy_tile2 &
      accu2pea_rdy_tile1 &
      accu2pea_rdy_tile0 ;
  assign bias_relu_prdy_o =
      bias_relu_prdy_o_tile7 &
      bias_relu_prdy_o_tile6 &
      bias_relu_prdy_o_tile5 &
      bias_relu_prdy_o_tile4 &
      bias_relu_prdy_o_tile3 &
      bias_relu_prdy_o_tile2 &
      bias_relu_prdy_o_tile1 &
      bias_relu_prdy_o_tile0 ;
  assign ofifo_accu_rdy =
      ofifo_accu_rdy_tile7 &
      ofifo_accu_rdy_tile6 &
      ofifo_accu_rdy_tile5 &
      ofifo_accu_rdy_tile4 &
      ofifo_accu_rdy_tile3 &
      ofifo_accu_rdy_tile2 &
      ofifo_accu_rdy_tile1 &
      ofifo_accu_rdy_tile0 ;
  assign ofifo_rdy =
      ofifo_rdy_tile7 &
      ofifo_rdy_tile6 &
      ofifo_rdy_tile5 &
      ofifo_rdy_tile4 &
      ofifo_rdy_tile3 &
      ofifo_rdy_tile2 &
      ofifo_rdy_tile1 &
      ofifo_rdy_tile0 ;
  assign pe2inbuf_rdy =
      pe2inbuf_rdy_tile7 &
      pe2inbuf_rdy_tile6 &
      pe2inbuf_rdy_tile5 &
      pe2inbuf_rdy_tile4 &
      pe2inbuf_rdy_tile3 &
      pe2inbuf_rdy_tile2 &
      pe2inbuf_rdy_tile1 &
      pe2inbuf_rdy_tile0 ;
  assign pea_act_recv =
      pea_act_recv_tile7 &
      pea_act_recv_tile6 &
      pea_act_recv_tile5 &
      pea_act_recv_tile4 &
      pea_act_recv_tile3 &
      pea_act_recv_tile2 &
      pea_act_recv_tile1 &
      pea_act_recv_tile0 ;
  assign pea_data_recv =
      pea_data_recv_tile7 &
      pea_data_recv_tile6 &
      pea_data_recv_tile5 &
      pea_data_recv_tile4 &
      pea_data_recv_tile3 &
      pea_data_recv_tile2 &
      pea_data_recv_tile1 &
      pea_data_recv_tile0 ;
  assign all_pec_data_o = {
    tile_data_o_tile7,
    tile_data_o_tile6,
    tile_data_o_tile5,
    tile_data_o_tile4,
    tile_data_o_tile3,
    tile_data_o_tile2,
    tile_data_o_tile1,
    tile_data_o_tile0
  };
  assign all_pec_data_pvld_o =
      tile_data_pvld_o_tile7 &
      tile_data_pvld_o_tile6 &
      tile_data_pvld_o_tile5 &
      tile_data_pvld_o_tile4 &
      tile_data_pvld_o_tile3 &
      tile_data_pvld_o_tile2 &
      tile_data_pvld_o_tile1 &
      tile_data_pvld_o_tile0 ;
  assign {
      mem_in_bias_dout_tile7,
      mem_in_bias_dout_tile6,
      mem_in_bias_dout_tile5,
      mem_in_bias_dout_tile4,
      mem_in_bias_dout_tile3,
      mem_in_bias_dout_tile2,
      mem_in_bias_dout_tile1,
      mem_in_bias_dout_tile0} = mem_in_bias_dout;
  assign {
      tile_mem_in_wgt_dout_tile7,
      tile_mem_in_wgt_dout_tile6,
      tile_mem_in_wgt_dout_tile5,
      tile_mem_in_wgt_dout_tile4,
      tile_mem_in_wgt_dout_tile3,
      tile_mem_in_wgt_dout_tile2,
      tile_mem_in_wgt_dout_tile1,
      tile_mem_in_wgt_dout_tile0} = pec_mem_in_wgt_dout;
  assign {
      tile_mem_in_fc_wgt_dout_tile7,
      tile_mem_in_fc_wgt_dout_tile6,
      tile_mem_in_fc_wgt_dout_tile5,
      tile_mem_in_fc_wgt_dout_tile4,
      tile_mem_in_fc_wgt_dout_tile3,
      tile_mem_in_fc_wgt_dout_tile2,
      tile_mem_in_fc_wgt_dout_tile1,
      tile_mem_in_fc_wgt_dout_tile0} = pec_mem_in_fc_wgt_dout;

  assign pec_data_o = ctrl_pea_en ? all_pec_data_o : deser_pec_data_o;
  assign pec_data_pvld_o = ctrl_pea_en ? all_pec_data_pvld_o : deser_pec_data_pvld_o;

endmodule
