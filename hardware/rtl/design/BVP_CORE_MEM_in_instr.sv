`timescale 1ns / 1ps

module BVP_CORE_MEM_in_instr #(
    parameter BVP_CORE_INSTR_WIDTH = 64
) (
    input  logic                            arst_n,
    input  logic [                     4:0] base_instr_addr_cnt,
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
    output logic                            csr_layer_cfg_hw_wren,
    input  logic                            csr_mem_cfg_mem_in_instr_ceb,
    input  logic [                     2:0] csr_mem_cfg_aux_cfg2,
    input  logic                            csr_mem_cfg_aux_cfg4,
    input  logic [                     1:0] csr_mem_cfg_aux_cfg3,
    input  logic                            csr_mem_cfg_aux_cfg1,
    input  logic                            csr_mem_cfg_aux_cfg0,
    input  logic                            csr_spi_cfg_spi_wr_mode,
    output logic                            mem_in_instr_ack,
    input  logic [BVP_CORE_INSTR_WIDTH-1:0] mem_in_instr_din,
    output logic [BVP_CORE_INSTR_WIDTH-1:0] mem_in_instr_dout,
    input  logic                            mem_in_instr_req,
    input  logic [                     4:0] spi_mem_in_instr_addr,
    input  logic                            spi_mem_in_instr_ceb,
    input  logic                            spi_mem_in_instr_web
);

  logic       mem_in_instr_ceb;
  logic       mem_in_instr_vld;
  logic [4:0] mem_in_instr_addr;
  logic       mem_in_instr_web;

  assign csr_layer_cfg0_ich_num_in = mem_in_instr_dout[7:0];
  assign csr_layer_cfg0_och_num_in = mem_in_instr_dout[15:8];
  assign csr_layer_cfg1_fm_height_in = mem_in_instr_dout[31:24];
  assign csr_layer_cfg1_fm_width_in = mem_in_instr_dout[23:16];
  assign csr_layer_cfg2_ofm_height_in = mem_in_instr_dout[47:40];
  assign csr_layer_cfg2_ofm_width_in = mem_in_instr_dout[39:32];
  assign csr_layer_cfg3_padding_enable_in = mem_in_instr_dout[52:52];
  assign csr_layer_cfg3_pool_enable_in = mem_in_instr_dout[53:53];
  assign csr_layer_cfg3_strideh_in = mem_in_instr_dout[49:48];
  assign csr_layer_cfg3_stridew_in = mem_in_instr_dout[51:50];
  assign csr_layer_cfg4_cur_act_frac_width_in = mem_in_instr_dout[56:54];
  assign csr_layer_cfg4_cur_wgt_frac_width_in = mem_in_instr_dout[60:57];
  assign csr_layer_cfg4_nxt_act_frac_width_in = mem_in_instr_dout[63:61];

  assign csr_layer_cfg_hw_wren = mem_in_instr_ack;

  assign mem_in_instr_ceb = csr_spi_cfg_spi_wr_mode ? spi_mem_in_instr_ceb : csr_mem_cfg_mem_in_instr_ceb;
  assign mem_in_instr_vld = mem_in_instr_req && !mem_in_instr_ceb;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      mem_in_instr_ack <= {$bits(mem_in_instr_ack) {1'b0}};
    end else begin
      if (clk_en) begin
        if (mem_in_instr_vld && !mem_in_instr_ack) begin
          mem_in_instr_ack <= 1'b1;
        end else if (!mem_in_instr_vld && mem_in_instr_ack) begin
          mem_in_instr_ack <= 1'b0;
        end
      end
    end
  end

  sram_stub #(
      .RAM_DATA_BW(BVP_CORE_INSTR_WIDTH),
      .RAM_ADDR_BW(5)
  ) u_mem_in_instr_stub (
      .addr(mem_in_instr_addr),
      .ce_n(mem_in_instr_ceb),
      .clk(clk),
      .wdata(mem_in_instr_din),
      .rdata(mem_in_instr_dout),
      .we_n(mem_in_instr_web)
  );

  assign mem_in_instr_addr = csr_spi_cfg_spi_wr_mode ? spi_mem_in_instr_addr : base_instr_addr_cnt;
  assign mem_in_instr_web  = csr_spi_cfg_spi_wr_mode ? spi_mem_in_instr_web : 1'b1;

endmodule
