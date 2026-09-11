`timescale 1ns / 1ps

module BVP_SPI_top #(
    parameter SPI_TDATA_BW = 16,
    SPI_RAM_ADDR_BW = 16,
    SPI_RAM_WR_DATA_MAX_BW = 576,
    SPI_SFT_LEN = 8
) (
    input  logic                              arst_n,
    output logic [       SPI_RAM_ADDR_BW-1:0] csr_raddr,
    input  logic [          SPI_TDATA_BW-1:0] csr_rdata,
    output logic                              csr_rden,
    output logic [       SPI_RAM_ADDR_BW-1:0] csr_waddr,
    output logic [          SPI_TDATA_BW-1:0] csr_wdata,
    output logic                              csr_wren,
    output logic                              spi_miso,
    input  logic                              spi_mosi,
    input  logic                              spi_sclk,
    input  logic                              spi_ss_n,
    output logic [       SPI_RAM_ADDR_BW-1:0] sram_addr,
    output logic [                       7:0] sram_ceb,
    input  logic [                      63:0] sram_rdata_in_act_dout,
    input  logic [                     127:0] sram_rdata_in_bias_dout,
    input  logic [                      63:0] sram_rdata_in_fc_wgt_dout,
    input  logic [                      63:0] sram_rdata_in_instr_dout,
    input  logic [                     575:0] sram_rdata_in_wgt_dout,
    input  logic [                      63:0] sram_rdata_out_act_dout,
    output logic [SPI_RAM_WR_DATA_MAX_BW-1:0] sram_wdata,
    output logic                              sram_web
);

  logic [SPI_RAM_ADDR_BW-1:0] spi_wr_addr_r;
  logic [SPI_RAM_ADDR_BW-1:0] spi_wr_addr_w;
  logic [  2*SPI_SFT_LEN-1:0] spi_wr_control;
  logic [   SPI_TDATA_BW-1:0] spi_wr_wdata;
  logic [   SPI_TDATA_BW-1:0] csr_rdata_2spi;
  logic [               15:0] sram_rdata_in_act_next;
  logic [               15:0] sram_rdata_in_bias_next;
  logic [               15:0] sram_rdata_in_fc_wgt_next;
  logic [               15:0] sram_rdata_in_instr_next;
  logic [               15:0] sram_rdata_in_wgt_next;
  logic [               15:0] sram_rdata_out_act_next;

  BVP_SPI_core #(
      .SPI_RAM_ADDR_BW(SPI_RAM_ADDR_BW),
      .SPI_TDATA_BW   (SPI_TDATA_BW),
      .SPI_SFT_LEN    (SPI_SFT_LEN)
  ) core (
      .arst_n                   (arst_n),
      .csr_rdata_2spi           (csr_rdata_2spi),
      .miso                     (spi_miso),
      .mosi                     (spi_mosi),
      .sclk                     (spi_sclk),
      .spi_wr_addr_r            (spi_wr_addr_r),
      .spi_wr_addr_w            (spi_wr_addr_w),
      .spi_wr_control           (spi_wr_control),
      .spi_wr_wdata             (spi_wr_wdata),
      .sram_rdata_in_act_next   (sram_rdata_in_act_next[2*SPI_SFT_LEN-1:0]),
      .sram_rdata_in_bias_next  (sram_rdata_in_bias_next[2*SPI_SFT_LEN-1:0]),
      .sram_rdata_in_fc_wgt_next(sram_rdata_in_fc_wgt_next[2*SPI_SFT_LEN-1:0]),
      .sram_rdata_in_instr_next (sram_rdata_in_instr_next[2*SPI_SFT_LEN-1:0]),
      .sram_rdata_in_wgt_next   (sram_rdata_in_wgt_next[2*SPI_SFT_LEN-1:0]),
      .sram_rdata_out_act_next  (sram_rdata_out_act_next[2*SPI_SFT_LEN-1:0]),
      .ss_n                     (spi_ss_n)
  );

  BVP_SPI_ctrl #(
      .SPI_TDATA_BW          (SPI_TDATA_BW),
      .SPI_RAM_WR_DATA_MAX_BW(SPI_RAM_WR_DATA_MAX_BW),
      .SPI_RAM_ADDR_BW       (SPI_RAM_ADDR_BW)
  ) ctrl (
      .arst_n                   (arst_n),
      .csr_raddr                (csr_raddr[SPI_RAM_ADDR_BW-1:0]),
      .csr_rdata                (csr_rdata[SPI_TDATA_BW-1:0]),
      .csr_rdata_2spi           (csr_rdata_2spi[SPI_TDATA_BW-1:0]),
      .csr_rden                 (csr_rden),
      .csr_waddr                (csr_waddr[SPI_RAM_ADDR_BW-1:0]),
      .csr_wdata                (csr_wdata[SPI_TDATA_BW-1:0]),
      .csr_wren                 (csr_wren),
      .sclk                     (spi_sclk),
      .spi_wr_addr_r            (spi_wr_addr_r[SPI_RAM_ADDR_BW-1:0]),
      .spi_wr_addr_w            (spi_wr_addr_w[SPI_RAM_ADDR_BW-1:0]),
      .spi_wr_control           (spi_wr_control[SPI_TDATA_BW-1:0]),
      .spi_wr_wdata             (spi_wr_wdata[SPI_TDATA_BW-1:0]),
      .sram_addr                (sram_addr[SPI_RAM_ADDR_BW-1:0]),
      .sram_ceb                 (sram_ceb[7:0]),
      .sram_rdata_in_act_dout   (sram_rdata_in_act_dout[63:0]),
      .sram_rdata_in_act_next   (sram_rdata_in_act_next[15:0]),
      .sram_rdata_in_bias_dout  (sram_rdata_in_bias_dout[127:0]),
      .sram_rdata_in_bias_next  (sram_rdata_in_bias_next[15:0]),
      .sram_rdata_in_fc_wgt_dout(sram_rdata_in_fc_wgt_dout[63:0]),
      .sram_rdata_in_fc_wgt_next(sram_rdata_in_fc_wgt_next[15:0]),
      .sram_rdata_in_instr_dout (sram_rdata_in_instr_dout[63:0]),
      .sram_rdata_in_instr_next (sram_rdata_in_instr_next[15:0]),
      .sram_rdata_in_wgt_dout   (sram_rdata_in_wgt_dout[575:0]),
      .sram_rdata_in_wgt_next   (sram_rdata_in_wgt_next[15:0]),
      .sram_rdata_out_act_dout  (sram_rdata_out_act_dout[63:0]),
      .sram_rdata_out_act_next  (sram_rdata_out_act_next[15:0]),
      .sram_wdata               (sram_wdata[SPI_RAM_WR_DATA_MAX_BW-1:0]),
      .sram_web                 (sram_web)
  );

endmodule
