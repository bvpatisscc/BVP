`timescale 1ns / 1ps

module BVP_CORE_MEM_in_wgt_wrp #(
    parameter MEM_OVERALL_WIDTH = 576,
    parameter MEM_SLICE_NUM = 4
) (
    input  logic                         clk,
    input  logic [                  2:0] csr_mem_cfg_wgt_cfg2,
    input  logic                         csr_mem_cfg_wgt_cfg4,
    input  logic [                  1:0] csr_mem_cfg_wgt_cfg3,
    input  logic                         csr_mem_cfg_wgt_cfg1,
    input  logic                         csr_mem_cfg_wgt_cfg0,
    input  logic [                  8:0] mem_in_wgt_addr,
    input  logic                         mem_in_wgt_ceb,
    input  logic [MEM_OVERALL_WIDTH-1:0] mem_in_wgt_din,
    output logic [MEM_OVERALL_WIDTH-1:0] mem_in_wgt_dout_sram,
    input  logic                         mem_in_wgt_web
);

  localparam MEM_SLICE_WIDTH = MEM_OVERALL_WIDTH / MEM_SLICE_NUM;
  logic [MEM_SLICE_WIDTH-1:0] mem_in_wgt_dout_sram_0;
  logic [MEM_SLICE_WIDTH-1:0] mem_in_wgt_dout_sram_1;
  logic [MEM_SLICE_WIDTH-1:0] mem_in_wgt_dout_sram_2;
  logic [MEM_SLICE_WIDTH-1:0] mem_in_wgt_dout_sram_3;
  logic [MEM_SLICE_WIDTH-1:0] mem_in_wgt_din_0;
  logic [MEM_SLICE_WIDTH-1:0] mem_in_wgt_din_1;
  logic [MEM_SLICE_WIDTH-1:0] mem_in_wgt_din_2;
  logic [MEM_SLICE_WIDTH-1:0] mem_in_wgt_din_3;

  sram_stub #(
      .RAM_DATA_BW(MEM_SLICE_WIDTH),
      .RAM_ADDR_BW(9)
  ) um_stub0 (
      .addr(mem_in_wgt_addr),
      .ce_n(mem_in_wgt_ceb),
      .clk(clk),
      .wdata(mem_in_wgt_din_0),
      .rdata(mem_in_wgt_dout_sram_0),
      .we_n(mem_in_wgt_web)
  );
  sram_stub #(
      .RAM_DATA_BW(MEM_SLICE_WIDTH),
      .RAM_ADDR_BW(9)
  ) um_stub1 (
      .addr(mem_in_wgt_addr),
      .ce_n(mem_in_wgt_ceb),
      .clk(clk),
      .wdata(mem_in_wgt_din_1),
      .rdata(mem_in_wgt_dout_sram_1),
      .we_n(mem_in_wgt_web)
  );
  sram_stub #(
      .RAM_DATA_BW(MEM_SLICE_WIDTH),
      .RAM_ADDR_BW(9)
  ) um_stub2 (
      .addr(mem_in_wgt_addr),
      .ce_n(mem_in_wgt_ceb),
      .clk(clk),
      .wdata(mem_in_wgt_din_2),
      .rdata(mem_in_wgt_dout_sram_2),
      .we_n(mem_in_wgt_web)
  );
  sram_stub #(
      .RAM_DATA_BW(MEM_SLICE_WIDTH),
      .RAM_ADDR_BW(9)
  ) um_stub3 (
      .addr(mem_in_wgt_addr),
      .ce_n(mem_in_wgt_ceb),
      .clk(clk),
      .wdata(mem_in_wgt_din_3),
      .rdata(mem_in_wgt_dout_sram_3),
      .we_n(mem_in_wgt_web)
  );

  always_comb begin
    mem_in_wgt_din_0 = mem_in_wgt_din[0*MEM_SLICE_WIDTH+:MEM_SLICE_WIDTH];
    mem_in_wgt_din_1 = mem_in_wgt_din[1*MEM_SLICE_WIDTH+:MEM_SLICE_WIDTH];
    mem_in_wgt_din_2 = mem_in_wgt_din[2*MEM_SLICE_WIDTH+:MEM_SLICE_WIDTH];
    mem_in_wgt_din_3 = mem_in_wgt_din[3*MEM_SLICE_WIDTH+:MEM_SLICE_WIDTH];
  end
  always_comb begin
    mem_in_wgt_dout_sram[0*MEM_SLICE_WIDTH+:MEM_SLICE_WIDTH] = mem_in_wgt_dout_sram_0;
    mem_in_wgt_dout_sram[1*MEM_SLICE_WIDTH+:MEM_SLICE_WIDTH] = mem_in_wgt_dout_sram_1;
    mem_in_wgt_dout_sram[2*MEM_SLICE_WIDTH+:MEM_SLICE_WIDTH] = mem_in_wgt_dout_sram_2;
    mem_in_wgt_dout_sram[3*MEM_SLICE_WIDTH+:MEM_SLICE_WIDTH] = mem_in_wgt_dout_sram_3;
  end

endmodule
