`timescale 1ns / 1ps

module BVP_CORE_MEM_in_bias #(
    parameter BIAS_WIDTH = 16,
    parameter PEC_BIAS_BUS_WIDTH = 8 * BIAS_WIDTH
) (
    input  logic                          arst_n,
    output logic [                   1:0] bias_spill_addr,
    output logic                          bias_spill_req,
    input  logic                          clk,
    input  logic                          clk_en,
    input  logic                          csr_mem_cfg_mem_in_bias_ceb,
    input  logic [                   2:0] csr_mem_cfg_aux_cfg2,
    input  logic                          csr_mem_cfg_aux_cfg4,
    input  logic [                   1:0] csr_mem_cfg_aux_cfg3,
    input  logic                          csr_mem_cfg_aux_cfg1,
    input  logic                          csr_mem_cfg_aux_cfg0,
    input  logic                          csr_spi_cfg_spi_wr_mode,
    input  logic                          ctrl_mem_in_bias_cnt_clr,
    input  logic [PEC_BIAS_BUS_WIDTH-1:0] mem_in_bias_din,
    output logic [PEC_BIAS_BUS_WIDTH-1:0] mem_in_bias_dout,
    input  logic                          mem_in_bias_req,
    output logic                          mem_in_bias_vld,
    input  logic [                   3:0] spi_mem_in_bias_addr,
    input  logic                          spi_mem_in_bias_ceb,
    input  logic                          spi_mem_in_bias_web
);

  logic       mem_in_bias_ceb;
  logic [3:0] mem_in_bias_addr;
  logic       mem_in_bias_web;
  logic       base_bias_addr_cnt_en;
  logic       base_bias_addr_cnt_clr;
  logic [4:0] base_bias_addr_cnt;

  assign bias_spill_req = !csr_spi_cfg_spi_wr_mode && base_bias_addr_cnt[4] && mem_in_bias_req;
  assign bias_spill_addr = base_bias_addr_cnt[1:0];
  assign mem_in_bias_ceb = csr_spi_cfg_spi_wr_mode ? spi_mem_in_bias_ceb :
                         bias_spill_req ? 1'b1 : csr_mem_cfg_mem_in_bias_ceb;
  assign mem_in_bias_vld = mem_in_bias_req && !bias_spill_req &&
                         !mem_in_bias_ceb && !ctrl_mem_in_bias_cnt_clr;

  sram_stub #(
      .RAM_DATA_BW(PEC_BIAS_BUS_WIDTH),
      .RAM_ADDR_BW(4)
  ) u_mem_in_bias_stub (
      .addr(mem_in_bias_addr),
      .ce_n(mem_in_bias_ceb),
      .clk(clk),
      .wdata(mem_in_bias_din),
      .rdata(mem_in_bias_dout),
      .we_n(mem_in_bias_web)
  );

  assign mem_in_bias_addr = csr_spi_cfg_spi_wr_mode ? spi_mem_in_bias_addr : base_bias_addr_cnt[3:0];
  assign mem_in_bias_web = csr_spi_cfg_spi_wr_mode ? spi_mem_in_bias_web : 1'b1;

  assign base_bias_addr_cnt_en = mem_in_bias_req;
  assign base_bias_addr_cnt_clr = ctrl_mem_in_bias_cnt_clr;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      base_bias_addr_cnt <= {$bits(base_bias_addr_cnt) {1'b0}};
    end else begin
      if (clk_en) begin
        if (base_bias_addr_cnt_clr) begin
          base_bias_addr_cnt <= 0;
        end else if (base_bias_addr_cnt_en) begin
          base_bias_addr_cnt <= base_bias_addr_cnt + 1;
        end
      end
    end
  end

endmodule
