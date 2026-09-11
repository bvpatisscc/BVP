`timescale 1ns / 1ps

module BVP_CORE_MEM_in_fc_wgt #(
    parameter WGT_ENC_WIDTH = 4,
    parameter PEC_FC_WGT_BUS_WIDTH = 8 * 2 * WGT_ENC_WIDTH
) (
    input  logic                            arst_n,
    input  logic                            clk,
    input  logic                            clk_en,
    input  logic [                     7:0] csr_layer_cfg_ich_num,
    input  logic                            csr_mem_cfg_mem_in_fc_wgt_ceb,
    input  logic [                     2:0] csr_mem_cfg_aux_cfg2,
    input  logic                            csr_mem_cfg_aux_cfg4,
    input  logic [                     1:0] csr_mem_cfg_aux_cfg3,
    input  logic                            csr_mem_cfg_aux_cfg1,
    input  logic                            csr_mem_cfg_aux_cfg0,
    input  logic                            csr_spi_cfg_spi_wr_mode,
    input  logic                            ctrl_mem_in_fc_wgt_cnt_clr,
    input  logic [                    63:0] mem_in_fc_wgt_din,
    output logic [PEC_FC_WGT_BUS_WIDTH-1:0] mem_in_fc_wgt_dout,
    output logic [PEC_FC_WGT_BUS_WIDTH-1:0] mem_in_fc_wgt_dout_sram,
    input  logic                            mem_in_fc_wgt_req,
    output logic                            mem_in_fc_wgt_vld,
    input  logic [                     5:0] spi_mem_in_fc_wgt_addr,
    input  logic                            spi_mem_in_fc_wgt_ceb,
    input  logic                            spi_mem_in_fc_wgt_web
);

  logic       mem_in_fc_wgt_ceb;
  logic       mem_in_fc_wgt_vld_nxt;
  logic [5:0] mem_in_fc_wgt_addr;
  logic       mem_in_fc_wgt_web;
  logic [5:0] base_fc_wgt_addr_cnt_max;
  logic       base_fc_wgt_addr_cnt_en;
  logic       base_fc_wgt_addr_cnt_clr;
  logic [5:0] base_fc_wgt_addr_cnt;

  assign mem_in_fc_wgt_ceb = csr_spi_cfg_spi_wr_mode ? spi_mem_in_fc_wgt_ceb : csr_mem_cfg_mem_in_fc_wgt_ceb;

  assign mem_in_fc_wgt_vld_nxt = mem_in_fc_wgt_req && !mem_in_fc_wgt_ceb;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      mem_in_fc_wgt_vld <= {$bits(mem_in_fc_wgt_vld) {1'b0}};
    end else begin
      if (clk_en) begin
        mem_in_fc_wgt_vld <= mem_in_fc_wgt_vld_nxt;
      end
    end
  end

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      mem_in_fc_wgt_dout <= {$bits(mem_in_fc_wgt_dout) {1'b0}};
    end else begin
      if (clk_en) begin
        if (mem_in_fc_wgt_vld_nxt) begin
          mem_in_fc_wgt_dout <= mem_in_fc_wgt_dout_sram;
        end
      end
    end
  end

  sram_stub #(
      .RAM_DATA_BW(PEC_FC_WGT_BUS_WIDTH),
      .RAM_ADDR_BW(6)
  ) u_mem_in_fc_wgt_stub (
      .addr(mem_in_fc_wgt_addr),
      .ce_n(mem_in_fc_wgt_ceb),
      .clk(clk),
      .wdata(mem_in_fc_wgt_din),
      .rdata(mem_in_fc_wgt_dout_sram),
      .we_n(mem_in_fc_wgt_web)
  );

  assign mem_in_fc_wgt_addr = csr_spi_cfg_spi_wr_mode ? spi_mem_in_fc_wgt_addr : base_fc_wgt_addr_cnt;
  assign mem_in_fc_wgt_web = csr_spi_cfg_spi_wr_mode ? spi_mem_in_fc_wgt_web : 1'b1;

  assign base_fc_wgt_addr_cnt_max = {csr_layer_cfg_ich_num[4:0], 1'b1};
  assign base_fc_wgt_addr_cnt_en = mem_in_fc_wgt_req;

  assign base_fc_wgt_addr_cnt_clr  = ctrl_mem_in_fc_wgt_cnt_clr || (base_fc_wgt_addr_cnt == base_fc_wgt_addr_cnt_max);
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      base_fc_wgt_addr_cnt <= {$bits(base_fc_wgt_addr_cnt) {1'b0}};
    end else begin
      if (clk_en) begin
        if (base_fc_wgt_addr_cnt_clr) begin
          base_fc_wgt_addr_cnt <= 0;
        end else if (base_fc_wgt_addr_cnt_en) begin
          base_fc_wgt_addr_cnt <= base_fc_wgt_addr_cnt + 1;
        end
      end
    end
  end

endmodule
