`timescale 1ns / 1ps

module BVP_CORE_top #(
    parameter ACT_WIDTH = 8,
    parameter WGT_ENC_WIDTH = 4,
    parameter POOL_FIFO_DEPTH = 64,
    parameter PEA_OFIFO_DEPTH = 128,
    parameter PEA_WGT_BUS_WIDTH = 9 * WGT_ENC_WIDTH,
    parameter SUM_WIDTH = 16,
    parameter BIAS_WIDTH = 16,
    parameter NLAYER_ACT_WIDTH = 8,
    parameter PEA_DOUT_WIDTH = 3 * SUM_WIDTH,
    parameter BVP_CSR_ADDR_W = 8,
    parameter BVP_CSR_DATA_W = 16,
    parameter TILE_WGT_BUS_WIDTH = 2 * PEA_WGT_BUS_WIDTH,
    parameter TILE_ACT_BUS_WIDTH = 2 * ACT_WIDTH,
    parameter PEC_WGT_BUS_WIDTH = 8 * TILE_WGT_BUS_WIDTH,
    parameter PEC_OUT_BUS_WIDTH = 8 * NLAYER_ACT_WIDTH,
    parameter PEC_BIAS_BUS_WIDTH = 8 * BIAS_WIDTH,
    parameter TILE_FC_WGT_BUS_WIDTH = 2 * WGT_ENC_WIDTH,
    parameter PEC_FC_WGT_BUS_WIDTH = 8 * TILE_FC_WGT_BUS_WIDTH,
    parameter BVP_CORE_INSTR_WIDTH = 64,
    parameter SPI_TDATA_BW = 16,
    parameter SPI_RAM_ADDR_BW = 16,
    parameter SPI_RAM_WR_DATA_MAX_BW = 576,
    parameter SPI_SFT_LEN = 8
) (
    input  logic                 arst_n,
    input  logic [ACT_WIDTH-1:0] axis_i_tdata,
    output logic                 axis_i_tready,
    input  logic                 axis_i_tvalid,
    output logic [ACT_WIDTH-1:0] axis_o_tdata,
    input  logic                 axis_o_tready,
    output logic                 axis_o_tvalid,
    input  logic                 clk,
    output logic                 csr_pad_cfg_ds0,
    output logic                 csr_pad_cfg_ds1,
    output logic                 csr_pad_cfg_lpm,
    output logic                 csr_pad_cfg_pe,
    output logic                 csr_pad_cfg_ps,
    output logic                 csr_pad_cfg_sr,
    output logic                 dbg_out_csr_rvalid,
    output logic                 dbg_out_csr_wready,
    output logic [          2:0] dbg_out_cur_state,
    output logic                 dbg_out_frame_ready,
    output logic                 dbg_out_mem_in_act_vld,
    output logic                 dbg_out_mem_in_wgt_vld,
    output logic                 spi_miso,
    input  logic                 spi_mosi,
    input  logic                 spi_sclk,
    input  logic                 spi_ss_n
);
  logic                              clk_en;
  logic                              arst_n_sync;
  logic                              arst_n_sync_spi_sclk;
  logic                              axis2mem_addr_cnt_en;
  logic                              axis2mem_frame_computing;
  logic [     PEC_OUT_BUS_WIDTH-1:0] axis2mem_wdata;
  logic                              axis2mem_web;
  logic                              csr_chip_cfg_frame_ready_clr;
  logic                              csr_chip_cfg_frame_ready_set;
  logic                              out_mem2axis_addr_inc;
  logic                              axis2mem_addr_cnt_clr;
  logic [                       7:0] csr_layer_cfg0_ich_num_in;
  logic [                       7:0] csr_layer_cfg0_och_num_in;
  logic [                       7:0] csr_layer_cfg1_fm_height_in;
  logic [                       7:0] csr_layer_cfg1_fm_width_in;
  logic [                       7:0] csr_layer_cfg2_ofm_height_in;
  logic [                       7:0] csr_layer_cfg2_ofm_width_in;
  logic                              csr_layer_cfg3_padding_enable_in;
  logic                              csr_layer_cfg3_pool_enable_in;
  logic [                       1:0] csr_layer_cfg3_strideh_in;
  logic [                       1:0] csr_layer_cfg3_stridew_in;
  logic [                       2:0] csr_layer_cfg4_cur_act_frac_width_in;
  logic [                       3:0] csr_layer_cfg4_cur_wgt_frac_width_in;
  logic [                       2:0] csr_layer_cfg4_nxt_act_frac_width_in;
  logic                              csr_layer_cfg_hw_wren;
  logic [     TILE_ACT_BUS_WIDTH-1:0] mem_in_act_dout;
  logic                              mem_in_act_vld;
  logic [    PEC_BIAS_BUS_WIDTH-1:0] mem_in_bias_dout;
  logic                              mem_in_bias_vld;
  logic [  PEC_FC_WGT_BUS_WIDTH-1:0] mem_in_fc_wgt_dout;
  logic [  PEC_FC_WGT_BUS_WIDTH-1:0] mem_in_fc_wgt_dout_sram;
  logic                              mem_in_fc_wgt_vld;
  logic [  BVP_CORE_INSTR_WIDTH-1:0] mem_in_instr_dout;
  logic                              mem_in_load_done_ack;
  logic [     PEC_WGT_BUS_WIDTH-1:0] mem_in_wgt_dout;
  logic [     PEC_WGT_BUS_WIDTH-1:0] mem_in_wgt_dout_sram;
  logic                              mem_in_wgt_vld;
  logic [     PEC_OUT_BUS_WIDTH-1:0] mem_out_act_sram_dout;
  logic                              out_mem2axis_addr_clr;
  logic                              pec_data_prdy_i;
  logic [     PEC_OUT_BUS_WIDTH-1:0] sram_rdata_in_act_dout;
  logic [     PEC_OUT_BUS_WIDTH-1:0] sram_rdata_out_act_dout;
  logic                              accu2ofifo_pvld;
  logic                              accu2pea_rdy;
  logic                              bias_relu_prdy_o;
  logic                              ofifo_accu_rdy;
  logic                              ofifo_rdy;
  logic                              pe2inbuf_rdy;
  logic                              pea_act_recv;
  logic                              pea_data_recv;
  logic                              pea_pool_up_data_vld_i;
  logic [     PEC_OUT_BUS_WIDTH-1:0] pec_data_o;
  logic                              pec_data_pvld_o;
  logic                              csr_layer_cfg_padding_enable_set;
  logic                              ctrl_bias_relu_out_row_done;
  logic                              ctrl_cur_layer_done;
  logic                              ctrl_enable_mem2axis;
  logic                              ctrl_fc_only_en;
  logic                              ctrl_first_wgt_vld;
  logic                              ctrl_flush_pe2obuf;
  logic                              ctrl_flush_pe_prev_out;
  logic                              ctrl_mem_in_bias_cnt_clr;
  logic                              ctrl_mem_in_fc_wgt_cnt_clr;
  logic                              ctrl_mem_in_wgt_addr_update;
  logic                              ctrl_mem_in_wgt_cnt_clr;
  logic                              ctrl_mem_inout_act_cnt_clr;
  logic                              ctrl_mem_inout_act_fc_gate_en;
  logic                              ctrl_mem_out_act_och_round_update;
  logic                              ctrl_ofifo_accu_stridew_valid;
  logic                              ctrl_ofifo_avail_for_ih;
  logic                              ctrl_pe_use_prev_out;
  logic                              ctrl_pea_en;
  logic                              ctrl_pool_en;
  logic                              ctrl_send_act_from_mem_en;
  logic                              ctrl_send_act_from_padding_en;
  logic                              ctrl_send_bias_from_mem_en;
  logic                              ctrl_send_fc_wgt_from_mem_en;
  logic                              ctrl_send_instr_from_mem_en;
  logic                              ctrl_send_wgt_from_mem_en;
  logic                              ctrl_send_wgt_from_padding_en;
  logic                              cur_ifm_done;
  logic                              incnt_fm_height_done;
  logic                              incnt_ich_num_done;
  logic [                       4:0] outcnt_layer_num;
  logic                              pool_last_pixel;
  logic [                       7:0] csr_layer_cfg_ich_num;
  logic [                       7:0] csr_layer_cfg_och_num;
  logic [                       7:0] csr_layer_cfg_fm_width;
  logic [                       7:0] csr_layer_cfg_fm_height;
  logic [                       7:0] csr_layer_cfg_ofm_width;
  logic [                       7:0] csr_layer_cfg_ofm_height;
  logic [                       1:0] csr_layer_cfg_strideh;
  logic [                       1:0] csr_layer_cfg_stridew;
  logic                              csr_layer_cfg_padding_enable;
  logic                              csr_layer_cfg_pool_enable;
  logic                              csr_layer_cfg_pool_sizeh;
  logic                              csr_layer_cfg_pool_sizew;
  logic [                       2:0] csr_layer_cfg_cur_act_frac_width;
  logic [                       3:0] csr_layer_cfg_cur_wgt_frac_width;
  logic [                       2:0] csr_layer_cfg_nxt_act_frac_width;
  logic [                       4:0] csr_model_cfg_layer_num;
  logic [                       2:0] csr_model_cfg_out_cls_num;
  logic                              csr_model_cfg_last_pool_type;
  logic [                      11:0] csr_model_cfg_in_act_num;
  logic                              csr_spi_cfg_spi_wr_mode_pos;
  logic                              csr_chip_cfg_frame_ready_out;
  logic                              csr_mem_cfg_mem_in_act_ceb;
  logic                              csr_mem_cfg_mem_in_wgt_ceb;
  logic                              csr_mem_cfg_mem_in_fc_wgt_ceb;
  logic                              csr_mem_cfg_mem_in_bias_ceb;
  logic                              csr_mem_cfg_mem_in_instr_ceb;
  logic                              csr_mem_cfg_mem_out_act_ceb;
  logic                              csr_mem_cfg_aux_cfg0;
  logic                              csr_mem_cfg_aux_cfg1;
  logic [                       2:0] csr_mem_cfg_aux_cfg2;
  logic [                       1:0] csr_mem_cfg_aux_cfg3;
  logic                              csr_mem_cfg_aux_cfg4;
  logic                              csr_mem_cfg_act_cfg0;
  logic                              csr_mem_cfg_act_cfg1;
  logic [                       2:0] csr_mem_cfg_act_cfg2;
  logic [                       1:0] csr_mem_cfg_act_cfg3;
  logic                              csr_mem_cfg_act_cfg4;
  logic                              csr_mem_cfg_act_cfg5;
  logic [                       1:0] csr_mem_cfg_act_cfg6;
  logic                              csr_mem_cfg_wgt_cfg0;
  logic                              csr_mem_cfg_wgt_cfg1;
  logic [                       2:0] csr_mem_cfg_wgt_cfg2;
  logic [                       1:0] csr_mem_cfg_wgt_cfg3;
  logic                              csr_mem_cfg_wgt_cfg4;
  logic [        BVP_CSR_DATA_W-1:0] csr_rdata_2spi;
  logic [       SPI_RAM_ADDR_BW-1:0] spi_2csr_raddr;
  logic                              spi_2csr_rden;
  logic [       SPI_RAM_ADDR_BW-1:0] spi_2csr_waddr;
  logic [          SPI_TDATA_BW-1:0] spi_2csr_wdata;
  logic                              spi_2csr_wren;
  logic [       SPI_RAM_ADDR_BW-1:0] spi_o_sram_addr;
  logic [                       7:0] sram_ceb;
  logic [SPI_RAM_WR_DATA_MAX_BW-1:0] sram_wdata;
  logic                              sram_web;
  logic                              aux_rp_calc_skip_rounding;
  logic [                       4:0] aux_rp_calc_truncate_frac_width;
  logic [                       3:0] aux_rp_calc_truncate_frac_width_m1;

  assign clk_en = 1'b1;

  arst_sync u_ASC_CLKR (
      .clk        (clk),
      .i_rst_async(arst_n),
      .o_rst_sync (arst_n_sync)
  );
  arst_sync u_ASC_SCLKR (
      .clk        (spi_sclk),
      .i_rst_async(arst_n),
      .o_rst_sync (arst_n_sync_spi_sclk)
  );

  BVP_AXIS_2MEM #(
      .DIN_WIDTH(ACT_WIDTH),
      .MEM_WIDTH(PEC_OUT_BUS_WIDTH)
  ) u_IAXIS (
      .arst_n                      (arst_n_sync),
      .axis2mem_addr_cnt_clr       (axis2mem_addr_cnt_clr),
      .axis2mem_addr_cnt_en        (axis2mem_addr_cnt_en),
      .axis2mem_frame_computing    (axis2mem_frame_computing),
      .axis2mem_wdata              (axis2mem_wdata[PEC_OUT_BUS_WIDTH-1:0]),
      .axis2mem_web                (axis2mem_web),
      .axis_i_tdata                (axis_i_tdata[ACT_WIDTH-1:0]),
      .axis_i_tready               (axis_i_tready),
      .axis_i_tvalid               (axis_i_tvalid),
      .clk                         (clk),
      .csr_chip_cfg_frame_ready_clr(csr_chip_cfg_frame_ready_clr),
      .csr_chip_cfg_frame_ready_out(csr_chip_cfg_frame_ready_out),
      .csr_chip_cfg_frame_ready_set(csr_chip_cfg_frame_ready_set),
      .out_mem2axis_addr_clr       (out_mem2axis_addr_clr)
  );

  BVP_OUT_mem2axis #(
      .DOUT_WIDTH(ACT_WIDTH),
      .MEM_WIDTH (PEC_OUT_BUS_WIDTH)
  ) u_OAXIS (
      .arst_n               (arst_n_sync),
      .axis_o_tdata         (axis_o_tdata[ACT_WIDTH-1:0]),
      .axis_o_tvalid        (axis_o_tvalid),
      .clk                  (clk),
      .ctrl_enable_mem2axis (ctrl_enable_mem2axis),
      .mem_out_dout         (mem_out_act_sram_dout),
      .out_mem2axis_addr_inc(out_mem2axis_addr_inc)
  );

  BVP_CORE_MEM_top #(
      .ACT_WIDTH           (ACT_WIDTH),
      .WGT_ENC_WIDTH       (WGT_ENC_WIDTH),
      .BIAS_WIDTH          (BIAS_WIDTH),
      .RAM_DATA_MAX_BW     (SPI_RAM_WR_DATA_MAX_BW),
      .RAM_ADDR_MAX_BW     (12),
      .PEA_WGT_BUS_WIDTH   (PEA_WGT_BUS_WIDTH),
      .TILE_WGT_BUS_WIDTH   (TILE_WGT_BUS_WIDTH),
      .TILE_ACT_BUS_WIDTH   (TILE_ACT_BUS_WIDTH),
      .PEC_OUT_BUS_WIDTH   (PEC_OUT_BUS_WIDTH),
      .PEC_WGT_BUS_WIDTH   (PEC_WGT_BUS_WIDTH),
      .PEC_BIAS_BUS_WIDTH  (PEC_BIAS_BUS_WIDTH),
      .PEC_FC_WGT_BUS_WIDTH(PEC_FC_WGT_BUS_WIDTH),
      .BVP_CORE_INSTR_WIDTH(BVP_CORE_INSTR_WIDTH)
  ) u_MEM (
      .arst_n                              (arst_n_sync),
      .axis2mem_addr_cnt_clr               (axis2mem_addr_cnt_clr),
      .axis2mem_addr_cnt_en                (axis2mem_addr_cnt_en),
      .axis2mem_frame_computing            (axis2mem_frame_computing),
      .axis2mem_wdata                      (axis2mem_wdata[PEC_OUT_BUS_WIDTH-1:0]),
      .axis2mem_web                        (axis2mem_web),
      .axis_o_tready                       (axis_o_tready),
      .clk                                 (clk),
      .clk_en                              (clk_en),
      .csr_layer_cfg0_ich_num_in           (csr_layer_cfg0_ich_num_in[7:0]),
      .csr_layer_cfg0_och_num_in           (csr_layer_cfg0_och_num_in[7:0]),
      .csr_layer_cfg1_fm_height_in         (csr_layer_cfg1_fm_height_in[7:0]),
      .csr_layer_cfg1_fm_width_in          (csr_layer_cfg1_fm_width_in[7:0]),
      .csr_layer_cfg2_ofm_height_in        (csr_layer_cfg2_ofm_height_in[7:0]),
      .csr_layer_cfg2_ofm_width_in         (csr_layer_cfg2_ofm_width_in[7:0]),
      .csr_layer_cfg3_padding_enable_in    (csr_layer_cfg3_padding_enable_in),
      .csr_layer_cfg3_pool_enable_in       (csr_layer_cfg3_pool_enable_in),
      .csr_layer_cfg3_strideh_in           (csr_layer_cfg3_strideh_in[1:0]),
      .csr_layer_cfg3_stridew_in           (csr_layer_cfg3_stridew_in[1:0]),
      .csr_layer_cfg4_cur_act_frac_width_in(csr_layer_cfg4_cur_act_frac_width_in[2:0]),
      .csr_layer_cfg4_cur_wgt_frac_width_in(csr_layer_cfg4_cur_wgt_frac_width_in[3:0]),
      .csr_layer_cfg4_nxt_act_frac_width_in(csr_layer_cfg4_nxt_act_frac_width_in[2:0]),
      .csr_layer_cfg_fm_height             (csr_layer_cfg_fm_height[7:0]),
      .csr_layer_cfg_fm_width              (csr_layer_cfg_fm_width[7:0]),
      .csr_layer_cfg_hw_wren               (csr_layer_cfg_hw_wren),
      .csr_layer_cfg_ich_num               (csr_layer_cfg_ich_num[7:0]),
      .csr_layer_cfg_och_num               (csr_layer_cfg_och_num[7:0]),
      .csr_mem_cfg_mem_in_act_ceb          (csr_mem_cfg_mem_in_act_ceb),
      .csr_mem_cfg_mem_in_bias_ceb         (csr_mem_cfg_mem_in_bias_ceb),
      .csr_mem_cfg_mem_in_fc_wgt_ceb       (csr_mem_cfg_mem_in_fc_wgt_ceb),
      .csr_mem_cfg_mem_in_instr_ceb        (csr_mem_cfg_mem_in_instr_ceb),
      .csr_mem_cfg_mem_in_wgt_ceb          (csr_mem_cfg_mem_in_wgt_ceb),
      .csr_mem_cfg_mem_out_act_ceb         (csr_mem_cfg_mem_out_act_ceb),
      .csr_mem_cfg_aux_cfg2                (csr_mem_cfg_aux_cfg2[2:0]),
      .csr_mem_cfg_aux_cfg4                (csr_mem_cfg_aux_cfg4),
      .csr_mem_cfg_aux_cfg3                (csr_mem_cfg_aux_cfg3[1:0]),
      .csr_mem_cfg_aux_cfg1                (csr_mem_cfg_aux_cfg1),
      .csr_mem_cfg_aux_cfg0                (csr_mem_cfg_aux_cfg0),
      .csr_mem_cfg_act_cfg2                (csr_mem_cfg_act_cfg2[2:0]),
      .csr_mem_cfg_act_cfg4                (csr_mem_cfg_act_cfg4),
      .csr_mem_cfg_act_cfg3                (csr_mem_cfg_act_cfg3[1:0]),
      .csr_mem_cfg_act_cfg1                (csr_mem_cfg_act_cfg1),
      .csr_mem_cfg_act_cfg0                (csr_mem_cfg_act_cfg0),
      .csr_mem_cfg_act_cfg5                (csr_mem_cfg_act_cfg5),
      .csr_mem_cfg_act_cfg6                (csr_mem_cfg_act_cfg6[1:0]),
      .csr_mem_cfg_wgt_cfg2                (csr_mem_cfg_wgt_cfg2[2:0]),
      .csr_mem_cfg_wgt_cfg4                (csr_mem_cfg_wgt_cfg4),
      .csr_mem_cfg_wgt_cfg3                (csr_mem_cfg_wgt_cfg3[1:0]),
      .csr_mem_cfg_wgt_cfg1                (csr_mem_cfg_wgt_cfg1),
      .csr_mem_cfg_wgt_cfg0                (csr_mem_cfg_wgt_cfg0),
      .csr_model_cfg_in_act_num            (csr_model_cfg_in_act_num[11:0]),
      .csr_model_cfg_out_cls_num           (csr_model_cfg_out_cls_num[2:0]),
      .csr_spi_cfg_spi_wr_mode_pos         (csr_spi_cfg_spi_wr_mode_pos),
      .ctrl_cur_layer_done                 (ctrl_cur_layer_done),
      .ctrl_enable_mem2axis                (ctrl_enable_mem2axis),
      .ctrl_mem_in_bias_cnt_clr            (ctrl_mem_in_bias_cnt_clr),
      .ctrl_mem_in_fc_wgt_cnt_clr          (ctrl_mem_in_fc_wgt_cnt_clr),
      .ctrl_mem_in_wgt_addr_update         (ctrl_mem_in_wgt_addr_update),
      .ctrl_mem_in_wgt_cnt_clr             (ctrl_mem_in_wgt_cnt_clr),
      .ctrl_mem_inout_act_cnt_clr          (ctrl_mem_inout_act_cnt_clr),
      .ctrl_mem_inout_act_fc_gate_en       (ctrl_mem_inout_act_fc_gate_en),
      .ctrl_mem_out_act_och_round_update   (ctrl_mem_out_act_och_round_update),
      .ctrl_send_act_from_mem_en           (ctrl_send_act_from_mem_en),
      .ctrl_send_act_from_padding_en       (ctrl_send_act_from_padding_en),
      .ctrl_send_bias_from_mem_en          (ctrl_send_bias_from_mem_en),
      .ctrl_send_fc_wgt_from_mem_en        (ctrl_send_fc_wgt_from_mem_en),
      .ctrl_send_instr_from_mem_en         (ctrl_send_instr_from_mem_en),
      .ctrl_send_wgt_from_mem_en           (ctrl_send_wgt_from_mem_en),
      .ctrl_send_wgt_from_padding_en       (ctrl_send_wgt_from_padding_en),
      .dbg_out_mem_in_act_vld              (dbg_out_mem_in_act_vld),
      .dbg_out_mem_in_wgt_vld              (dbg_out_mem_in_wgt_vld),
      .mem_in_act_dout                     (mem_in_act_dout[TILE_ACT_BUS_WIDTH-1:0]),
      .mem_in_act_vld                      (mem_in_act_vld),
      .mem_in_bias_dout                    (mem_in_bias_dout[PEC_BIAS_BUS_WIDTH-1:0]),
      .mem_in_bias_vld                     (mem_in_bias_vld),
      .mem_in_fc_wgt_dout                  (mem_in_fc_wgt_dout[PEC_FC_WGT_BUS_WIDTH-1:0]),
      .mem_in_fc_wgt_dout_sram             (mem_in_fc_wgt_dout_sram[PEC_FC_WGT_BUS_WIDTH-1:0]),
      .mem_in_fc_wgt_vld                   (mem_in_fc_wgt_vld),
      .mem_in_instr_dout                   (mem_in_instr_dout[BVP_CORE_INSTR_WIDTH-1:0]),
      .mem_in_load_done_ack                (mem_in_load_done_ack),
      .mem_in_wgt_dout                     (mem_in_wgt_dout[PEC_WGT_BUS_WIDTH-1:0]),
      .mem_in_wgt_dout_sram                (mem_in_wgt_dout_sram[PEC_WGT_BUS_WIDTH-1:0]),
      .mem_in_wgt_vld                      (mem_in_wgt_vld),
      .mem_out_act_sram_dout               (mem_out_act_sram_dout[PEC_OUT_BUS_WIDTH-1:0]),
      .out_mem2axis_addr_clr               (out_mem2axis_addr_clr),
      .out_mem2axis_addr_inc               (out_mem2axis_addr_inc),
      .outcnt_layer_num                    (outcnt_layer_num[4:0]),
      .pec_data_o                          (pec_data_o[PEC_OUT_BUS_WIDTH-1:0]),
      .pec_data_prdy_i                     (pec_data_prdy_i),
      .pec_data_pvld_o                     (pec_data_pvld_o),
      .sram_addr                           (spi_o_sram_addr[11:0]),
      .sram_ceb                            (sram_ceb[5:0]),
      .sram_rdata_in_act_dout              (sram_rdata_in_act_dout[PEC_OUT_BUS_WIDTH-1:0]),
      .sram_rdata_out_act_dout             (sram_rdata_out_act_dout[PEC_OUT_BUS_WIDTH-1:0]),
      .sram_wdata                          (sram_wdata[SPI_RAM_WR_DATA_MAX_BW-1:0]),
      .sram_web                            (sram_web)
  );

  BVP_CORE_BSU_Cluster #(
      .ACT_WIDTH           (ACT_WIDTH),
      .WGT_ENC_WIDTH       (WGT_ENC_WIDTH),
      .PEA_WGT_BUS_WIDTH   (PEA_WGT_BUS_WIDTH),
      .POOL_FIFO_DEPTH     (POOL_FIFO_DEPTH),
      .PEA_OFIFO_DEPTH     (PEA_OFIFO_DEPTH),
      .SUM_WIDTH           (SUM_WIDTH),
      .BIAS_WIDTH          (BIAS_WIDTH),
      .NLAYER_ACT_WIDTH    (NLAYER_ACT_WIDTH),
      .PEA_DOUT_WIDTH      (PEA_DOUT_WIDTH),
      .TILE_ACT_BUS_WIDTH   (TILE_ACT_BUS_WIDTH),
      .TILE_WGT_BUS_WIDTH   (TILE_WGT_BUS_WIDTH),
      .PEC_OUT_BUS_WIDTH   (PEC_OUT_BUS_WIDTH),
      .PEC_WGT_BUS_WIDTH   (PEC_WGT_BUS_WIDTH),
      .PEC_BIAS_BUS_WIDTH  (PEC_BIAS_BUS_WIDTH),
      .TILE_FC_WGT_BUS_WIDTH(TILE_FC_WGT_BUS_WIDTH),
      .PEC_FC_WGT_BUS_WIDTH(PEC_FC_WGT_BUS_WIDTH)
  ) u_PEC (
      .accu2ofifo_pvld                   (accu2ofifo_pvld),
      .accu2pea_rdy                      (accu2pea_rdy),
      .arst_n                            (arst_n_sync),
      .aux_rp_calc_skip_rounding         (aux_rp_calc_skip_rounding),
      .aux_rp_calc_truncate_frac_width   (aux_rp_calc_truncate_frac_width[4:0]),
      .aux_rp_calc_truncate_frac_width_m1(aux_rp_calc_truncate_frac_width_m1[3:0]),
      .bias_relu_prdy_o                  (bias_relu_prdy_o),
      .clk                               (clk),
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
      .flush_pe_prev_out                 (ctrl_flush_pe_prev_out),
      .incnt_fm_height_done              (incnt_fm_height_done),
      .incnt_ich_num_done                (incnt_ich_num_done),
      .mem_in_bias_dout                  (mem_in_bias_dout[PEC_BIAS_BUS_WIDTH-1:0]),
      .mem_in_bias_vld                   (mem_in_bias_vld),
      .ofifo_accu_rdy                    (ofifo_accu_rdy),
      .ofifo_rdy                         (ofifo_rdy),
      .pe2inbuf_rdy                      (pe2inbuf_rdy),
      .pea_act_recv                      (pea_act_recv),
      .pea_data_recv                     (pea_data_recv),
      .pea_pool_up_data_vld_i            (pea_pool_up_data_vld_i),
      .pec_data_o                        (pec_data_o[PEC_OUT_BUS_WIDTH-1:0]),
      .pec_data_prdy_i                   (pec_data_prdy_i),
      .pec_data_pvld_o                   (pec_data_pvld_o),
      .pec_mem_in_act_dout               (mem_in_act_dout[TILE_ACT_BUS_WIDTH-1:0]),
      .pec_mem_in_act_vld                (mem_in_act_vld),
      .pec_mem_in_fc_wgt_dout            (mem_in_fc_wgt_dout[PEC_FC_WGT_BUS_WIDTH-1:0]),
      .pec_mem_in_fc_wgt_vld             (mem_in_fc_wgt_vld),
      .pec_mem_in_wgt_dout               (mem_in_wgt_dout[PEC_WGT_BUS_WIDTH-1:0]),
      .pec_mem_in_wgt_vld                (mem_in_wgt_vld),
      .pedata_col0_buf_in_0_pea0         ({{SUM_WIDTH} {1'b0}}),
      .pedata_col0_buf_in_0_pea1         ({{SUM_WIDTH} {1'b0}}),
      .pedata_col0_buf_in_1_pea0         ({{SUM_WIDTH} {1'b0}}),
      .pedata_col0_buf_in_1_pea1         ({{SUM_WIDTH} {1'b0}}),
      .pedata_col0_buf_in_2_pea0         ({{SUM_WIDTH} {1'b0}}),
      .pedata_col0_buf_in_2_pea1         ({{SUM_WIDTH} {1'b0}}),
      .pool_last_pixel                   (pool_last_pixel)
  );

  BVP_CORE_CTRL_FSM_top u_CTRL_FSM (
      .accu2ofifo_pvld                  (accu2ofifo_pvld),
      .accu2pea_rdy                     (accu2pea_rdy),
      .arst_n                           (arst_n_sync),
      .axis2mem_frame_computing         (axis2mem_frame_computing),
      .bias_relu_prdy_o                 (bias_relu_prdy_o),
      .clk                              (clk),
      .clk_en                           (clk_en),
      .csr_layer_cfg_fm_height          (csr_layer_cfg_fm_height[7:0]),
      .csr_layer_cfg_fm_width           (csr_layer_cfg_fm_width[7:0]),
      .csr_layer_cfg_ich_num            (csr_layer_cfg_ich_num[7:0]),
      .csr_layer_cfg_och_num            (csr_layer_cfg_och_num[7:0]),
      .csr_layer_cfg_ofm_height         (csr_layer_cfg_ofm_height[7:0]),
      .csr_layer_cfg_ofm_width          (csr_layer_cfg_ofm_width[7:0]),
      .csr_layer_cfg_padding_enable     (csr_layer_cfg_padding_enable),
      .csr_layer_cfg_padding_enable_set (csr_layer_cfg_padding_enable_set),
      .csr_layer_cfg_pool_enable        (csr_layer_cfg_pool_enable),
      .csr_layer_cfg_strideh            (csr_layer_cfg_strideh[1:0]),
      .csr_layer_cfg_stridew            (csr_layer_cfg_stridew[1:0]),
      .csr_model_cfg_layer_num          (csr_model_cfg_layer_num[4:0]),
      .ctrl_bias_relu_out_row_done      (ctrl_bias_relu_out_row_done),
      .ctrl_cur_layer_done              (ctrl_cur_layer_done),
      .ctrl_enable_mem2axis             (ctrl_enable_mem2axis),
      .ctrl_fc_only_en                  (ctrl_fc_only_en),
      .ctrl_first_wgt_vld               (ctrl_first_wgt_vld),
      .ctrl_flush_pe2obuf               (ctrl_flush_pe2obuf),
      .ctrl_flush_pe_prev_out           (ctrl_flush_pe_prev_out),
      .ctrl_mem_in_bias_cnt_clr         (ctrl_mem_in_bias_cnt_clr),
      .ctrl_mem_in_fc_wgt_cnt_clr       (ctrl_mem_in_fc_wgt_cnt_clr),
      .ctrl_mem_in_wgt_addr_update      (ctrl_mem_in_wgt_addr_update),
      .ctrl_mem_in_wgt_cnt_clr          (ctrl_mem_in_wgt_cnt_clr),
      .ctrl_mem_inout_act_cnt_clr       (ctrl_mem_inout_act_cnt_clr),
      .ctrl_mem_inout_act_fc_gate_en    (ctrl_mem_inout_act_fc_gate_en),
      .ctrl_mem_out_act_och_round_update(ctrl_mem_out_act_och_round_update),
      .ctrl_ofifo_accu_stridew_valid    (ctrl_ofifo_accu_stridew_valid),
      .ctrl_ofifo_avail_for_ih          (ctrl_ofifo_avail_for_ih),
      .ctrl_pe_use_prev_out             (ctrl_pe_use_prev_out),
      .ctrl_pea_en                      (ctrl_pea_en),
      .ctrl_pool_en                     (ctrl_pool_en),
      .ctrl_send_act_from_mem_en        (ctrl_send_act_from_mem_en),
      .ctrl_send_act_from_padding_en    (ctrl_send_act_from_padding_en),
      .ctrl_send_bias_from_mem_en       (ctrl_send_bias_from_mem_en),
      .ctrl_send_fc_wgt_from_mem_en     (ctrl_send_fc_wgt_from_mem_en),
      .ctrl_send_instr_from_mem_en      (ctrl_send_instr_from_mem_en),
      .ctrl_send_wgt_from_mem_en        (ctrl_send_wgt_from_mem_en),
      .ctrl_send_wgt_from_padding_en    (ctrl_send_wgt_from_padding_en),
      .cur_ifm_done                     (cur_ifm_done),
      .dbg_out_cur_state                (dbg_out_cur_state[2:0]),
      .incnt_fm_height_done             (incnt_fm_height_done),
      .incnt_ich_num_done               (incnt_ich_num_done),
      .mem_in_fc_wgt_vld                (mem_in_fc_wgt_vld),
      .mem_in_load_done_ack             (mem_in_load_done_ack),
      .mem_in_wgt_vld                   (mem_in_wgt_vld),
      .ofifo_accu_rdy                   (ofifo_accu_rdy),
      .ofifo_rdy                        (ofifo_rdy),
      .out_mem2axis_addr_clr            (out_mem2axis_addr_clr),
      .outcnt_layer_num                 (outcnt_layer_num[4:0]),
      .pe2inbuf_rdy                     (pe2inbuf_rdy),
      .pea_act_recv                     (pea_act_recv),
      .pea_data_recv                    (pea_data_recv),
      .pea_pool_up_data_vld_i           (pea_pool_up_data_vld_i),
      .pec_data_pvld_o                  (pec_data_pvld_o),
      .pool_last_pixel                  (pool_last_pixel)
  );

  bvp_csr #(
      .ADDR_W(BVP_CSR_ADDR_W),
      .DATA_W(BVP_CSR_DATA_W)
  ) u_CSR (
      .clk                                  (clk),
      .rst                                  (arst_n_sync),
      .csr_layer_cfg0_ich_num_en            (csr_layer_cfg_hw_wren),
      .csr_layer_cfg0_ich_num_in            (csr_layer_cfg0_ich_num_in[7:0]),
      .csr_layer_cfg0_ich_num_out           (csr_layer_cfg_ich_num[7:0]),
      .csr_layer_cfg0_och_num_en            (csr_layer_cfg_hw_wren),
      .csr_layer_cfg0_och_num_in            (csr_layer_cfg0_och_num_in[7:0]),
      .csr_layer_cfg0_och_num_out           (csr_layer_cfg_och_num[7:0]),
      .csr_layer_cfg1_fm_width_en           (csr_layer_cfg_hw_wren),
      .csr_layer_cfg1_fm_width_in           (csr_layer_cfg1_fm_width_in[7:0]),
      .csr_layer_cfg1_fm_width_out          (csr_layer_cfg_fm_width[7:0]),
      .csr_layer_cfg1_fm_height_en          (csr_layer_cfg_hw_wren),
      .csr_layer_cfg1_fm_height_in          (csr_layer_cfg1_fm_height_in[7:0]),
      .csr_layer_cfg1_fm_height_out         (csr_layer_cfg_fm_height[7:0]),
      .csr_layer_cfg2_ofm_width_en          (csr_layer_cfg_hw_wren),
      .csr_layer_cfg2_ofm_width_in          (csr_layer_cfg2_ofm_width_in[7:0]),
      .csr_layer_cfg2_ofm_width_out         (csr_layer_cfg_ofm_width[7:0]),
      .csr_layer_cfg2_ofm_height_en         (csr_layer_cfg_hw_wren),
      .csr_layer_cfg2_ofm_height_in         (csr_layer_cfg2_ofm_height_in[7:0]),
      .csr_layer_cfg2_ofm_height_out        (csr_layer_cfg_ofm_height[7:0]),
      .csr_layer_cfg3_strideh_en            (csr_layer_cfg_hw_wren),
      .csr_layer_cfg3_strideh_in            (csr_layer_cfg3_strideh_in[1:0]),
      .csr_layer_cfg3_strideh_out           (csr_layer_cfg_strideh[1:0]),
      .csr_layer_cfg3_stridew_en            (csr_layer_cfg_hw_wren),
      .csr_layer_cfg3_stridew_in            (csr_layer_cfg3_stridew_in[1:0]),
      .csr_layer_cfg3_stridew_out           (csr_layer_cfg_stridew[1:0]),
      .csr_layer_cfg3_padding_enable_en     (csr_layer_cfg_hw_wren),
      .csr_layer_cfg3_padding_enable_set    (csr_layer_cfg_padding_enable_set),
      .csr_layer_cfg3_padding_enable_in     (csr_layer_cfg3_padding_enable_in),
      .csr_layer_cfg3_padding_enable_out    (csr_layer_cfg_padding_enable),
      .csr_layer_cfg3_pool_enable_en        (csr_layer_cfg_hw_wren),
      .csr_layer_cfg3_pool_enable_in        (csr_layer_cfg3_pool_enable_in),
      .csr_layer_cfg3_pool_enable_out       (csr_layer_cfg_pool_enable),
      .csr_layer_cfg3_pool_sizeh_out        (csr_layer_cfg_pool_sizeh),
      .csr_layer_cfg3_pool_sizew_out        (csr_layer_cfg_pool_sizew),
      .csr_layer_cfg4_cur_act_frac_width_en (csr_layer_cfg_hw_wren),
      .csr_layer_cfg4_cur_act_frac_width_in (csr_layer_cfg4_cur_act_frac_width_in[2:0]),
      .csr_layer_cfg4_cur_act_frac_width_out(csr_layer_cfg_cur_act_frac_width[2:0]),
      .csr_layer_cfg4_cur_wgt_frac_width_en (csr_layer_cfg_hw_wren),
      .csr_layer_cfg4_cur_wgt_frac_width_in (csr_layer_cfg4_cur_wgt_frac_width_in[3:0]),
      .csr_layer_cfg4_cur_wgt_frac_width_out(csr_layer_cfg_cur_wgt_frac_width[3:0]),
      .csr_layer_cfg4_nxt_act_frac_width_en (csr_layer_cfg_hw_wren),
      .csr_layer_cfg4_nxt_act_frac_width_in (csr_layer_cfg4_nxt_act_frac_width_in[2:0]),
      .csr_layer_cfg4_nxt_act_frac_width_out(csr_layer_cfg_nxt_act_frac_width[2:0]),
      .csr_model_cfg0_layer_num_out         (csr_model_cfg_layer_num[4:0]),
      .csr_model_cfg0_out_cls_num_out       (csr_model_cfg_out_cls_num[2:0]),
      .csr_model_cfg0_last_pool_type_out    (csr_model_cfg_last_pool_type),
      .csr_model_cfg1_in_act_num_out        (csr_model_cfg_in_act_num[11:0]),
      .csr_spi_cfg0_spi_wr_mode_out         (csr_spi_cfg_spi_wr_mode_pos),
      .csr_chip_cfg0_frame_ready_clr        (csr_chip_cfg_frame_ready_clr),
      .csr_chip_cfg0_frame_ready_set        (csr_chip_cfg_frame_ready_set),
      .csr_chip_cfg0_frame_ready_out        (csr_chip_cfg_frame_ready_out),
      .csr_pad_cfg0_ds0_out                 (csr_pad_cfg_ds0),
      .csr_pad_cfg0_ds1_out                 (csr_pad_cfg_ds1),
      .csr_pad_cfg0_pe_out                  (csr_pad_cfg_pe),
      .csr_pad_cfg0_ps_out                  (csr_pad_cfg_ps),
      .csr_pad_cfg0_sr_out                  (csr_pad_cfg_sr),
      .csr_pad_cfg0_lpm_out                 (csr_pad_cfg_lpm),
      .csr_mem_cfg0_mem_in_act_ceb_out      (csr_mem_cfg_mem_in_act_ceb),
      .csr_mem_cfg0_mem_in_wgt_ceb_out      (csr_mem_cfg_mem_in_wgt_ceb),
      .csr_mem_cfg0_mem_in_fc_wgt_ceb_out   (csr_mem_cfg_mem_in_fc_wgt_ceb),
      .csr_mem_cfg0_mem_in_bias_ceb_out     (csr_mem_cfg_mem_in_bias_ceb),
      .csr_mem_cfg0_mem_in_instr_ceb_out    (csr_mem_cfg_mem_in_instr_ceb),
      .csr_mem_cfg0_mem_out_act_ceb_out     (csr_mem_cfg_mem_out_act_ceb),
      .csr_mem_cfg1_aux_cfg0_out            (csr_mem_cfg_aux_cfg0),
      .csr_mem_cfg1_aux_cfg1_out            (csr_mem_cfg_aux_cfg1),
      .csr_mem_cfg1_aux_cfg2_out            (csr_mem_cfg_aux_cfg2[2:0]),
      .csr_mem_cfg1_aux_cfg3_out            (csr_mem_cfg_aux_cfg3[1:0]),
      .csr_mem_cfg1_aux_cfg4_out            (csr_mem_cfg_aux_cfg4),
      .csr_mem_cfg3_act_cfg0_out            (csr_mem_cfg_act_cfg0),
      .csr_mem_cfg3_act_cfg1_out            (csr_mem_cfg_act_cfg1),
      .csr_mem_cfg3_act_cfg2_out            (csr_mem_cfg_act_cfg2[2:0]),
      .csr_mem_cfg3_act_cfg3_out            (csr_mem_cfg_act_cfg3[1:0]),
      .csr_mem_cfg3_act_cfg4_out            (csr_mem_cfg_act_cfg4),
      .csr_mem_cfg3_act_cfg5_out            (csr_mem_cfg_act_cfg5),
      .csr_mem_cfg3_act_cfg6_out            (csr_mem_cfg_act_cfg6[1:0]),
      .csr_mem_cfg4_wgt_cfg0_out            (csr_mem_cfg_wgt_cfg0),
      .csr_mem_cfg4_wgt_cfg1_out            (csr_mem_cfg_wgt_cfg1),
      .csr_mem_cfg4_wgt_cfg2_out            (csr_mem_cfg_wgt_cfg2[2:0]),
      .csr_mem_cfg4_wgt_cfg3_out            (csr_mem_cfg_wgt_cfg3[1:0]),
      .csr_mem_cfg4_wgt_cfg4_out            (csr_mem_cfg_wgt_cfg4),
      .waddr                                (spi_2csr_waddr[BVP_CSR_ADDR_W-1:0]),
      .wdata                                (spi_2csr_wdata[BVP_CSR_DATA_W-1:0]),
      .wen                                  (spi_2csr_wren),
      .wstrb                                (2'b11),
      .wready                               (dbg_out_csr_wready),
      .raddr                                (spi_2csr_raddr[BVP_CSR_ADDR_W-1:0]),
      .ren                                  (spi_2csr_rden),
      .rdata                                (csr_rdata_2spi),
      .rvalid                               (dbg_out_csr_rvalid)
  );

  BVP_SPI_top #(
      .SPI_TDATA_BW          (SPI_TDATA_BW),
      .SPI_RAM_ADDR_BW       (SPI_RAM_ADDR_BW),
      .SPI_RAM_WR_DATA_MAX_BW(SPI_RAM_WR_DATA_MAX_BW),
      .SPI_SFT_LEN           (SPI_SFT_LEN)
  ) u_SPI (
      .arst_n                   (arst_n_sync_spi_sclk),
      .csr_raddr                (spi_2csr_raddr),
      .csr_rdata                (csr_rdata_2spi),
      .csr_rden                 (spi_2csr_rden),
      .csr_waddr                (spi_2csr_waddr),
      .csr_wdata                (spi_2csr_wdata),
      .csr_wren                 (spi_2csr_wren),
      .spi_miso                 (spi_miso),
      .spi_mosi                 (spi_mosi),
      .spi_sclk                 (spi_sclk),
      .spi_ss_n                 (spi_ss_n),
      .sram_addr                (spi_o_sram_addr),
      .sram_ceb                 (sram_ceb[7:0]),
      .sram_rdata_in_act_dout   (sram_rdata_in_act_dout[63:0]),
      .sram_rdata_in_bias_dout  (mem_in_bias_dout),
      .sram_rdata_in_fc_wgt_dout(mem_in_fc_wgt_dout_sram),
      .sram_rdata_in_instr_dout (mem_in_instr_dout),
      .sram_rdata_in_wgt_dout   (mem_in_wgt_dout_sram),
      .sram_rdata_out_act_dout  (sram_rdata_out_act_dout[63:0]),
      .sram_wdata               (sram_wdata[SPI_RAM_WR_DATA_MAX_BW-1:0]),
      .sram_web                 (sram_web)
  );

  BVP_CORE_AUX_rp_calc u_AUX_rp_calc (
      .arst_n                            (arst_n_sync),
      .aux_rp_calc_skip_rounding         (aux_rp_calc_skip_rounding),
      .aux_rp_calc_truncate_frac_width   (aux_rp_calc_truncate_frac_width[4:0]),
      .aux_rp_calc_truncate_frac_width_m1(aux_rp_calc_truncate_frac_width_m1[3:0]),
      .clk                               (clk),
      .csr_layer_cfg_cur_act_frac_width  (csr_layer_cfg_cur_act_frac_width[2:0]),
      .csr_layer_cfg_cur_wgt_frac_width  (csr_layer_cfg_cur_wgt_frac_width[3:0]),
      .csr_layer_cfg_nxt_act_frac_width  (csr_layer_cfg_nxt_act_frac_width[2:0])
  );

  assign dbg_out_frame_ready = axis2mem_frame_computing;

endmodule
