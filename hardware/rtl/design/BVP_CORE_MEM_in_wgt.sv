`timescale 1ns / 1ps

module BVP_CORE_MEM_in_wgt #(
    parameter WGT_ENC_WIDTH = 4,
    parameter BIAS_SPILL_BASE_ADDR = 508,
    parameter PEA_WGT_BUS_WIDTH = 9 * WGT_ENC_WIDTH,
    parameter TILE_WGT_BUS_WIDTH = 2 * PEA_WGT_BUS_WIDTH,
    parameter PEC_WGT_BUS_WIDTH = 8 * TILE_WGT_BUS_WIDTH
) (
    input  logic                         arst_n,
    input  logic [                  1:0] bias_spill_addr,
    input  logic                         bias_spill_req,
    input  logic                         clk,
    input  logic                         clk_en,
    input  logic [                  7:0] csr_layer_cfg_ich_num,
    input  logic                         csr_mem_cfg_mem_in_wgt_ceb,
    input  logic [                  2:0] csr_mem_cfg_wgt_cfg2,
    input  logic                         csr_mem_cfg_wgt_cfg4,
    input  logic [                  1:0] csr_mem_cfg_wgt_cfg3,
    input  logic                         csr_mem_cfg_wgt_cfg1,
    input  logic                         csr_mem_cfg_wgt_cfg0,
    input  logic                         csr_spi_cfg_spi_wr_mode,
    input  logic                         ctrl_mem_in_wgt_addr_update,
    input  logic                         ctrl_mem_in_wgt_cnt_clr,
    input  logic                         ctrl_send_wgt_from_padding_en,
    output logic                         dbg_out_mem_in_wgt_vld,
    input  logic [PEC_WGT_BUS_WIDTH-1:0] mem_in_wgt_din,
    output logic [PEC_WGT_BUS_WIDTH-1:0] mem_in_wgt_dout,
    output logic [PEC_WGT_BUS_WIDTH-1:0] mem_in_wgt_dout_sram,
    input  logic                         mem_in_wgt_req,
    output logic                         mem_in_wgt_vld,
    input  logic [                  8:0] spi_mem_in_wgt_addr,
    input  logic                         spi_mem_in_wgt_ceb,
    input  logic                         spi_mem_in_wgt_web
);

  logic       mem_in_wgt_ceb;
  logic       mem_in_wgt_vld_nxt;
  logic [8:0] mem_in_wgt_addr;
  logic       mem_in_wgt_web;
  logic       prev_sum_layers_ich_num_clr;
  logic       prev_sum_layers_ich_num_set;
  logic [8:0] prev_sum_layers_ich_num_nxt;
  logic [8:0] prev_sum_layers_ich_num;
  logic [8:0] base_wgt_addr_cnt_max;
  logic       base_wgt_addr_cnt_rch;
  logic       base_wgt_addr_cnt_en;
  logic       base_wgt_addr_cnt_clr;
  logic       base_wgt_addr_cnt_reset;
  logic       base_wgt_addr_cnt_set;
  logic [8:0] base_wgt_addr_cnt;

  assign dbg_out_mem_in_wgt_vld = mem_in_wgt_vld;

  assign mem_in_wgt_ceb = csr_spi_cfg_spi_wr_mode ? spi_mem_in_wgt_ceb : csr_mem_cfg_mem_in_wgt_ceb;

  assign mem_in_wgt_vld_nxt = (ctrl_send_wgt_from_padding_en || mem_in_wgt_req) && !mem_in_wgt_ceb;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      mem_in_wgt_vld <= {$bits(mem_in_wgt_vld) {1'b0}};
    end else begin
      if (clk_en) begin
        mem_in_wgt_vld <= mem_in_wgt_vld_nxt;
      end
    end
  end

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      mem_in_wgt_dout <= {$bits(mem_in_wgt_dout) {1'b0}};
    end else begin
      if (clk_en) begin
        if (mem_in_wgt_vld_nxt) begin
          mem_in_wgt_dout <= mem_in_wgt_dout_sram;
        end
      end
    end
  end

  BVP_CORE_MEM_in_wgt_wrp #(
      .MEM_OVERALL_WIDTH(PEC_WGT_BUS_WIDTH),
      .MEM_SLICE_NUM    (4)
  ) wrp (
      .clk                 (clk),
      .csr_mem_cfg_wgt_cfg2(csr_mem_cfg_wgt_cfg2[2:0]),
      .csr_mem_cfg_wgt_cfg4(csr_mem_cfg_wgt_cfg4),
      .csr_mem_cfg_wgt_cfg3(csr_mem_cfg_wgt_cfg3[1:0]),
      .csr_mem_cfg_wgt_cfg1(csr_mem_cfg_wgt_cfg1),
      .csr_mem_cfg_wgt_cfg0(csr_mem_cfg_wgt_cfg0),
      .mem_in_wgt_addr     (mem_in_wgt_addr[8:0]),
      .mem_in_wgt_ceb      (mem_in_wgt_ceb),
      .mem_in_wgt_din      (mem_in_wgt_din[PEC_WGT_BUS_WIDTH-1:0]),
      .mem_in_wgt_dout_sram(mem_in_wgt_dout_sram[PEC_WGT_BUS_WIDTH-1:0]),
      .mem_in_wgt_web      (mem_in_wgt_web)
  );

  assign mem_in_wgt_addr = csr_spi_cfg_spi_wr_mode ? spi_mem_in_wgt_addr :
                         bias_spill_req ? BIAS_SPILL_BASE_ADDR + {{7{1'b0}}, bias_spill_addr} :
                         base_wgt_addr_cnt;
  assign mem_in_wgt_web = csr_spi_cfg_spi_wr_mode ? spi_mem_in_wgt_web : 1'b1;

  assign prev_sum_layers_ich_num_clr = ctrl_mem_in_wgt_cnt_clr;
  assign prev_sum_layers_ich_num_set = ctrl_mem_in_wgt_addr_update;
  assign prev_sum_layers_ich_num_nxt = base_wgt_addr_cnt_max + 1;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      prev_sum_layers_ich_num <= {$bits(prev_sum_layers_ich_num) {1'b0}};
    end else begin
      if (clk_en) begin
        if (prev_sum_layers_ich_num_clr) begin
          prev_sum_layers_ich_num <= 0;
        end else if (prev_sum_layers_ich_num_set) begin
          prev_sum_layers_ich_num <= prev_sum_layers_ich_num_nxt;
        end
      end
    end
  end

  assign base_wgt_addr_cnt_max = prev_sum_layers_ich_num + csr_layer_cfg_ich_num;

  assign base_wgt_addr_cnt_rch = (base_wgt_addr_cnt == base_wgt_addr_cnt_max) && base_wgt_addr_cnt_en;
  assign base_wgt_addr_cnt_en = mem_in_wgt_req;

  assign base_wgt_addr_cnt_clr = ctrl_mem_in_wgt_cnt_clr;
  assign base_wgt_addr_cnt_reset = base_wgt_addr_cnt_rch;
  assign base_wgt_addr_cnt_set = prev_sum_layers_ich_num_set;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      base_wgt_addr_cnt <= {$bits(base_wgt_addr_cnt) {1'b0}};
    end else begin
      if (clk_en) begin
        if (base_wgt_addr_cnt_clr) begin
          base_wgt_addr_cnt <= 0;
        end else if (base_wgt_addr_cnt_reset) begin
          base_wgt_addr_cnt <= prev_sum_layers_ich_num;
        end else if (base_wgt_addr_cnt_set) begin
          base_wgt_addr_cnt <= prev_sum_layers_ich_num_nxt;
        end else if (base_wgt_addr_cnt_en) begin
          base_wgt_addr_cnt <= base_wgt_addr_cnt + 1;
        end
      end
    end
  end

endmodule
