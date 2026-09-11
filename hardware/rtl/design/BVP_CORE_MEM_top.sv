`timescale 1ns / 1ps

module BVP_CORE_MEM_top #(
    parameter ACT_WIDTH = 8,
    parameter WGT_ENC_WIDTH = 4,
    parameter BIAS_WIDTH = 16,
    parameter RAM_DATA_MAX_BW = 576,
    parameter RAM_ADDR_MAX_BW = 12,
    parameter PEA_WGT_BUS_WIDTH = 9 * WGT_ENC_WIDTH,
    parameter TILE_WGT_BUS_WIDTH = 2 * PEA_WGT_BUS_WIDTH,
    parameter TILE_ACT_BUS_WIDTH = 2 * ACT_WIDTH,
    parameter PEC_WGT_BUS_WIDTH = 8 * TILE_WGT_BUS_WIDTH,
    parameter PEC_OUT_BUS_WIDTH = 8 * ACT_WIDTH,
    parameter PEC_BIAS_BUS_WIDTH = 8 * BIAS_WIDTH,
    parameter PEC_FC_WGT_BUS_WIDTH = 8 * 2 * WGT_ENC_WIDTH,
    parameter BVP_CORE_INSTR_WIDTH = 64
) (
    input  logic                            arst_n,
    output logic                            axis2mem_addr_cnt_clr,
    input  logic                            axis2mem_addr_cnt_en,
    input  logic                            axis2mem_frame_computing,
    input  logic [   PEC_OUT_BUS_WIDTH-1:0] axis2mem_wdata,
    input  logic                            axis2mem_web,
    input  logic                            axis_o_tready,
    input  logic                            clk,
    input  logic                            clk_en,
    output logic [                     7:0] csr_layer_cfg0_ich_num_in,
    output logic [                     7:0] csr_layer_cfg0_och_num_in,
    output logic [                     7:0] csr_layer_cfg1_fm_height_in,
    output logic [                     7:0] csr_layer_cfg1_fm_width_in,
    output logic [                     7:0] csr_layer_cfg2_ofm_height_in,
    output logic [                     7:0] csr_layer_cfg2_ofm_width_in,
    output logic                            csr_layer_cfg3_padding_enable_in,
    output logic                            csr_layer_cfg3_pool_enable_in,
    output logic [                     1:0] csr_layer_cfg3_strideh_in,
    output logic [                     1:0] csr_layer_cfg3_stridew_in,
    output logic [                     2:0] csr_layer_cfg4_cur_act_frac_width_in,
    output logic [                     3:0] csr_layer_cfg4_cur_wgt_frac_width_in,
    output logic [                     2:0] csr_layer_cfg4_nxt_act_frac_width_in,
    input  logic [                     7:0] csr_layer_cfg_fm_height,
    input  logic [                     7:0] csr_layer_cfg_fm_width,
    output logic                            csr_layer_cfg_hw_wren,
    input  logic [                     7:0] csr_layer_cfg_ich_num,
    input  logic [                     7:0] csr_layer_cfg_och_num,
    input  logic                            csr_mem_cfg_mem_in_act_ceb,
    input  logic                            csr_mem_cfg_mem_in_bias_ceb,
    input  logic                            csr_mem_cfg_mem_in_fc_wgt_ceb,
    input  logic                            csr_mem_cfg_mem_in_instr_ceb,
    input  logic                            csr_mem_cfg_mem_in_wgt_ceb,
    input  logic                            csr_mem_cfg_mem_out_act_ceb,
    input  logic [                     2:0] csr_mem_cfg_aux_cfg2,
    input  logic                            csr_mem_cfg_aux_cfg4,
    input  logic [                     1:0] csr_mem_cfg_aux_cfg3,
    input  logic                            csr_mem_cfg_aux_cfg1,
    input  logic                            csr_mem_cfg_aux_cfg0,
    input  logic [                     2:0] csr_mem_cfg_act_cfg2,
    input  logic                            csr_mem_cfg_act_cfg4,
    input  logic [                     1:0] csr_mem_cfg_act_cfg3,
    input  logic                            csr_mem_cfg_act_cfg1,
    input  logic                            csr_mem_cfg_act_cfg0,
    input  logic                            csr_mem_cfg_act_cfg5,
    input  logic [                     1:0] csr_mem_cfg_act_cfg6,
    input  logic [                     2:0] csr_mem_cfg_wgt_cfg2,
    input  logic                            csr_mem_cfg_wgt_cfg4,
    input  logic [                     1:0] csr_mem_cfg_wgt_cfg3,
    input  logic                            csr_mem_cfg_wgt_cfg1,
    input  logic                            csr_mem_cfg_wgt_cfg0,
    input  logic [                    11:0] csr_model_cfg_in_act_num,
    input  logic [                     2:0] csr_model_cfg_out_cls_num,
    input  logic                            csr_spi_cfg_spi_wr_mode_pos,
    input  logic                            ctrl_cur_layer_done,
    input  logic                            ctrl_enable_mem2axis,
    input  logic                            ctrl_mem_in_bias_cnt_clr,
    input  logic                            ctrl_mem_in_fc_wgt_cnt_clr,
    input  logic                            ctrl_mem_in_wgt_addr_update,
    input  logic                            ctrl_mem_in_wgt_cnt_clr,
    input  logic                            ctrl_mem_inout_act_cnt_clr,
    input  logic                            ctrl_mem_inout_act_fc_gate_en,
    input  logic                            ctrl_mem_out_act_och_round_update,
    input  logic                            ctrl_send_act_from_mem_en,
    input  logic                            ctrl_send_act_from_padding_en,
    input  logic                            ctrl_send_bias_from_mem_en,
    input  logic                            ctrl_send_fc_wgt_from_mem_en,
    input  logic                            ctrl_send_instr_from_mem_en,
    input  logic                            ctrl_send_wgt_from_mem_en,
    input  logic                            ctrl_send_wgt_from_padding_en,
    output logic                            dbg_out_mem_in_act_vld,
    output logic                            dbg_out_mem_in_wgt_vld,
    output logic [   TILE_ACT_BUS_WIDTH-1:0] mem_in_act_dout,
    output logic                            mem_in_act_vld,
    output logic [  PEC_BIAS_BUS_WIDTH-1:0] mem_in_bias_dout,
    output logic                            mem_in_bias_vld,
    output logic [PEC_FC_WGT_BUS_WIDTH-1:0] mem_in_fc_wgt_dout,
    output logic [PEC_FC_WGT_BUS_WIDTH-1:0] mem_in_fc_wgt_dout_sram,
    output logic                            mem_in_fc_wgt_vld,
    output logic [BVP_CORE_INSTR_WIDTH-1:0] mem_in_instr_dout,
    output logic                            mem_in_load_done_ack,
    output logic [   PEC_WGT_BUS_WIDTH-1:0] mem_in_wgt_dout,
    output logic [   PEC_WGT_BUS_WIDTH-1:0] mem_in_wgt_dout_sram,
    output logic                            mem_in_wgt_vld,
    output logic [   PEC_OUT_BUS_WIDTH-1:0] mem_out_act_sram_dout,
    output logic                            out_mem2axis_addr_clr,
    input  logic                            out_mem2axis_addr_inc,
    input  logic [                     4:0] outcnt_layer_num,
    input  logic [   PEC_OUT_BUS_WIDTH-1:0] pec_data_o,
    output logic                            pec_data_prdy_i,
    input  logic                            pec_data_pvld_o,
    input  logic [     RAM_ADDR_MAX_BW-1:0] sram_addr,
    input  logic [                     5:0] sram_ceb,
    output logic [   PEC_OUT_BUS_WIDTH-1:0] sram_rdata_in_act_dout,
    output logic [   PEC_OUT_BUS_WIDTH-1:0] sram_rdata_out_act_dout,
    input  logic [     RAM_DATA_MAX_BW-1:0] sram_wdata,
    input  logic                            sram_web
);

  localparam INT_MEM_INOUT_ACT_ADDR_BW = 12;
  localparam INT_MEM_IN_WGT_ADDR_BW = 9;
  localparam INT_MEM_IN_BIAS_ADDR_BW = 4;
  localparam INT_MEM_IN_FC_WGT_ADDR_BW = 6;
  localparam INT_MEM_IN_INSTR_ADDR_BW = 5;
  logic                          csr_spi_cfg_spi_wr_mode;
  logic [                   1:0] bias_spill_addr;
  logic                          bias_spill_req;
  logic [PEC_BIAS_BUS_WIDTH-1:0] mem_in_bias_dout_sram;
  logic                          mem_in_bias_vld_sram;
  logic                          bias_spill_vld;

  always_ff @(negedge clk or negedge arst_n) begin
    if (~arst_n) begin
      csr_spi_cfg_spi_wr_mode <= {$bits(csr_spi_cfg_spi_wr_mode) {1'b0}};
    end else begin
      csr_spi_cfg_spi_wr_mode <= csr_spi_cfg_spi_wr_mode_pos;
    end
  end

  BVP_CORE_MEM_inout_act #(
      .ACT_WIDTH        (ACT_WIDTH),
      .TILE_ACT_BUS_WIDTH(TILE_ACT_BUS_WIDTH),
      .PEC_OUT_BUS_WIDTH(PEC_OUT_BUS_WIDTH)
  ) u_MEM_inout_act (
      .arst_n                           (arst_n),
      .axis2mem_addr_cnt_clr            (axis2mem_addr_cnt_clr),
      .axis2mem_addr_cnt_en             (axis2mem_addr_cnt_en),
      .axis2mem_frame_computing         (axis2mem_frame_computing),
      .axis2mem_wdata                   (axis2mem_wdata[PEC_OUT_BUS_WIDTH-1:0]),
      .axis2mem_web                     (axis2mem_web),
      .axis_o_tready                    (axis_o_tready),
      .clk                              (clk),
      .clk_en                           (clk_en),
      .csr_layer_cfg_fm_height          (csr_layer_cfg_fm_height[7:0]),
      .csr_layer_cfg_fm_width           (csr_layer_cfg_fm_width[7:0]),
      .csr_layer_cfg_ich_num            (csr_layer_cfg_ich_num[7:0]),
      .csr_layer_cfg_och_num            (csr_layer_cfg_och_num[7:0]),
      .csr_mem_cfg_mem_in_act_ceb       (csr_mem_cfg_mem_in_act_ceb),
      .csr_mem_cfg_mem_out_act_ceb      (csr_mem_cfg_mem_out_act_ceb),
      .csr_mem_cfg_act_cfg2             (csr_mem_cfg_act_cfg2[2:0]),
      .csr_mem_cfg_act_cfg4             (csr_mem_cfg_act_cfg4),
      .csr_mem_cfg_act_cfg3             (csr_mem_cfg_act_cfg3[1:0]),
      .csr_mem_cfg_act_cfg1             (csr_mem_cfg_act_cfg1),
      .csr_mem_cfg_act_cfg0             (csr_mem_cfg_act_cfg0),
      .csr_mem_cfg_act_cfg5             (csr_mem_cfg_act_cfg5),
      .csr_mem_cfg_act_cfg6             (csr_mem_cfg_act_cfg6[1:0]),
      .csr_model_cfg_in_act_num         (csr_model_cfg_in_act_num[11:0]),
      .csr_model_cfg_out_cls_num        (csr_model_cfg_out_cls_num[2:0]),
      .csr_spi_cfg_spi_wr_mode          (csr_spi_cfg_spi_wr_mode),
      .ctrl_cur_layer_done              (ctrl_cur_layer_done),
      .ctrl_enable_mem2axis             (ctrl_enable_mem2axis),
      .ctrl_mem_inout_act_cnt_clr       (ctrl_mem_inout_act_cnt_clr),
      .ctrl_mem_inout_act_fc_gate_en    (ctrl_mem_inout_act_fc_gate_en),
      .ctrl_mem_out_act_och_round_update(ctrl_mem_out_act_och_round_update),
      .ctrl_send_act_from_padding_en    (ctrl_send_act_from_padding_en),
      .dbg_out_mem_in_act_vld           (dbg_out_mem_in_act_vld),
      .mem_in_act_dout                  (mem_in_act_dout[TILE_ACT_BUS_WIDTH-1:0]),
      .mem_in_act_req                   (ctrl_send_act_from_mem_en),
      .mem_in_act_vld                   (mem_in_act_vld),
      .mem_inout_act_mem0_dout          (sram_rdata_in_act_dout),
      .mem_inout_act_mem1_dout          (sram_rdata_out_act_dout),
      .mem_out_act_sram_dout            (mem_out_act_sram_dout[PEC_OUT_BUS_WIDTH-1:0]),
      .mem_out_up_data_i                (pec_data_o),
      .mem_out_up_data_rdy_o            (pec_data_prdy_i),
      .mem_out_up_data_vld_i            (pec_data_pvld_o),
      .out_mem2axis_addr_clr            (out_mem2axis_addr_clr),
      .out_mem2axis_addr_inc            (out_mem2axis_addr_inc),
      .spi_mem_inout_act_mem0_addr      (sram_addr[INT_MEM_INOUT_ACT_ADDR_BW-1:0]),
      .spi_mem_inout_act_mem0_ceb       (sram_ceb[0]),
      .spi_mem_inout_act_mem0_din       (sram_wdata[PEC_OUT_BUS_WIDTH-1:0]),
      .spi_mem_inout_act_mem0_web       (sram_web),
      .spi_mem_inout_act_mem1_addr      (sram_addr[INT_MEM_INOUT_ACT_ADDR_BW-1:0]),
      .spi_mem_inout_act_mem1_ceb       (sram_ceb[5]),
      .spi_mem_inout_act_mem1_din       (sram_wdata[PEC_OUT_BUS_WIDTH-1:0]),
      .spi_mem_inout_act_mem1_web       (sram_web)
  );

  BVP_CORE_MEM_in_wgt #(
      .WGT_ENC_WIDTH    (WGT_ENC_WIDTH),
      .PEA_WGT_BUS_WIDTH(PEA_WGT_BUS_WIDTH),
      .TILE_WGT_BUS_WIDTH(TILE_WGT_BUS_WIDTH),
      .PEC_WGT_BUS_WIDTH(PEC_WGT_BUS_WIDTH)
  ) u_MEM_in_wgt (
      .arst_n                       (arst_n),
      .bias_spill_addr              (bias_spill_addr),
      .bias_spill_req               (bias_spill_req),
      .clk                          (clk),
      .clk_en                       (clk_en),
      .csr_layer_cfg_ich_num        (csr_layer_cfg_ich_num[7:0]),
      .csr_mem_cfg_mem_in_wgt_ceb   (csr_mem_cfg_mem_in_wgt_ceb),
      .csr_mem_cfg_wgt_cfg2         (csr_mem_cfg_wgt_cfg2[2:0]),
      .csr_mem_cfg_wgt_cfg4         (csr_mem_cfg_wgt_cfg4),
      .csr_mem_cfg_wgt_cfg3         (csr_mem_cfg_wgt_cfg3[1:0]),
      .csr_mem_cfg_wgt_cfg1         (csr_mem_cfg_wgt_cfg1),
      .csr_mem_cfg_wgt_cfg0         (csr_mem_cfg_wgt_cfg0),
      .csr_spi_cfg_spi_wr_mode      (csr_spi_cfg_spi_wr_mode),
      .ctrl_mem_in_wgt_addr_update  (ctrl_mem_in_wgt_addr_update),
      .ctrl_mem_in_wgt_cnt_clr      (ctrl_mem_in_wgt_cnt_clr),
      .ctrl_send_wgt_from_padding_en(ctrl_send_wgt_from_padding_en),
      .dbg_out_mem_in_wgt_vld       (dbg_out_mem_in_wgt_vld),
      .mem_in_wgt_din               (sram_wdata[PEC_WGT_BUS_WIDTH-1:0]),
      .mem_in_wgt_dout              (mem_in_wgt_dout[PEC_WGT_BUS_WIDTH-1:0]),
      .mem_in_wgt_dout_sram         (mem_in_wgt_dout_sram[PEC_WGT_BUS_WIDTH-1:0]),
      .mem_in_wgt_req               (ctrl_send_wgt_from_mem_en),
      .mem_in_wgt_vld               (mem_in_wgt_vld),
      .spi_mem_in_wgt_addr          (sram_addr[INT_MEM_IN_WGT_ADDR_BW-1:0]),
      .spi_mem_in_wgt_ceb           (sram_ceb[1]),
      .spi_mem_in_wgt_web           (sram_web)
  );

  BVP_CORE_MEM_in_fc_wgt #(
      .WGT_ENC_WIDTH       (WGT_ENC_WIDTH),
      .PEC_FC_WGT_BUS_WIDTH(PEC_FC_WGT_BUS_WIDTH)
  ) u_MEM_in_fc_wgt (
      .arst_n                       (arst_n),
      .clk                          (clk),
      .clk_en                       (clk_en),
      .csr_layer_cfg_ich_num        (csr_layer_cfg_ich_num[7:0]),
      .csr_mem_cfg_mem_in_fc_wgt_ceb(csr_mem_cfg_mem_in_fc_wgt_ceb),
      .csr_mem_cfg_aux_cfg2         (csr_mem_cfg_aux_cfg2[2:0]),
      .csr_mem_cfg_aux_cfg4         (csr_mem_cfg_aux_cfg4),
      .csr_mem_cfg_aux_cfg3         (csr_mem_cfg_aux_cfg3[1:0]),
      .csr_mem_cfg_aux_cfg1         (csr_mem_cfg_aux_cfg1),
      .csr_mem_cfg_aux_cfg0         (csr_mem_cfg_aux_cfg0),
      .csr_spi_cfg_spi_wr_mode      (csr_spi_cfg_spi_wr_mode),
      .ctrl_mem_in_fc_wgt_cnt_clr   (ctrl_mem_in_fc_wgt_cnt_clr),
      .mem_in_fc_wgt_din            (sram_wdata[PEC_FC_WGT_BUS_WIDTH-1:0]),
      .mem_in_fc_wgt_dout           (mem_in_fc_wgt_dout[PEC_FC_WGT_BUS_WIDTH-1:0]),
      .mem_in_fc_wgt_dout_sram      (mem_in_fc_wgt_dout_sram[PEC_FC_WGT_BUS_WIDTH-1:0]),
      .mem_in_fc_wgt_req            (ctrl_send_fc_wgt_from_mem_en),
      .mem_in_fc_wgt_vld            (mem_in_fc_wgt_vld),
      .spi_mem_in_fc_wgt_addr       (sram_addr[INT_MEM_IN_FC_WGT_ADDR_BW-1:0]),
      .spi_mem_in_fc_wgt_ceb        (sram_ceb[2]),
      .spi_mem_in_fc_wgt_web        (sram_web)
  );

  BVP_CORE_MEM_in_bias #(
      .BIAS_WIDTH        (BIAS_WIDTH),
      .PEC_BIAS_BUS_WIDTH(PEC_BIAS_BUS_WIDTH)
  ) u_MEM_in_bias (
      .arst_n                     (arst_n),
      .bias_spill_addr            (bias_spill_addr),
      .bias_spill_req             (bias_spill_req),
      .clk                        (clk),
      .clk_en                     (clk_en),
      .csr_mem_cfg_mem_in_bias_ceb(csr_mem_cfg_mem_in_bias_ceb),
      .csr_mem_cfg_aux_cfg2       (csr_mem_cfg_aux_cfg2[2:0]),
      .csr_mem_cfg_aux_cfg4       (csr_mem_cfg_aux_cfg4),
      .csr_mem_cfg_aux_cfg3       (csr_mem_cfg_aux_cfg3[1:0]),
      .csr_mem_cfg_aux_cfg1       (csr_mem_cfg_aux_cfg1),
      .csr_mem_cfg_aux_cfg0       (csr_mem_cfg_aux_cfg0),
      .csr_spi_cfg_spi_wr_mode    (csr_spi_cfg_spi_wr_mode),
      .ctrl_mem_in_bias_cnt_clr   (ctrl_mem_in_bias_cnt_clr),
      .mem_in_bias_din            (sram_wdata[PEC_BIAS_BUS_WIDTH-1:0]),
      .mem_in_bias_dout           (mem_in_bias_dout_sram),
      .mem_in_bias_req            (ctrl_send_bias_from_mem_en),
      .mem_in_bias_vld            (mem_in_bias_vld_sram),
      .spi_mem_in_bias_addr       (sram_addr[INT_MEM_IN_BIAS_ADDR_BW-1:0]),
      .spi_mem_in_bias_ceb        (sram_ceb[3]),
      .spi_mem_in_bias_web        (sram_web)
  );

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      bias_spill_vld <= {$bits(bias_spill_vld) {1'b0}};
    end else begin
      if (clk_en) begin
        bias_spill_vld <= bias_spill_req;
      end
    end
  end

  assign mem_in_bias_vld = mem_in_bias_vld_sram || bias_spill_vld;
  assign mem_in_bias_dout = bias_spill_vld ?
                          mem_in_wgt_dout_sram[PEC_BIAS_BUS_WIDTH-1:0] :
                          mem_in_bias_dout_sram;

  BVP_CORE_MEM_in_instr #(
      .BVP_CORE_INSTR_WIDTH(BVP_CORE_INSTR_WIDTH)
  ) u_MEM_in_instr (
      .arst_n                              (arst_n),
      .base_instr_addr_cnt                 (outcnt_layer_num),
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
      .csr_layer_cfg_hw_wren               (csr_layer_cfg_hw_wren),
      .csr_mem_cfg_mem_in_instr_ceb        (csr_mem_cfg_mem_in_instr_ceb),
      .csr_mem_cfg_aux_cfg2                (csr_mem_cfg_aux_cfg2[2:0]),
      .csr_mem_cfg_aux_cfg4                (csr_mem_cfg_aux_cfg4),
      .csr_mem_cfg_aux_cfg3                (csr_mem_cfg_aux_cfg3[1:0]),
      .csr_mem_cfg_aux_cfg1                (csr_mem_cfg_aux_cfg1),
      .csr_mem_cfg_aux_cfg0                (csr_mem_cfg_aux_cfg0),
      .csr_spi_cfg_spi_wr_mode             (csr_spi_cfg_spi_wr_mode),
      .mem_in_instr_ack                    (mem_in_load_done_ack),
      .mem_in_instr_din                    (sram_wdata[BVP_CORE_INSTR_WIDTH-1:0]),
      .mem_in_instr_dout                   (mem_in_instr_dout[BVP_CORE_INSTR_WIDTH-1:0]),
      .mem_in_instr_req                    (ctrl_send_instr_from_mem_en),
      .spi_mem_in_instr_addr               (sram_addr[INT_MEM_IN_INSTR_ADDR_BW-1:0]),
      .spi_mem_in_instr_ceb                (sram_ceb[4]),
      .spi_mem_in_instr_web                (sram_web)
  );

endmodule
