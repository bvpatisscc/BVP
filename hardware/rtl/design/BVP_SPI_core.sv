`timescale 1ns / 1ps

module BVP_SPI_core #(
    parameter SPI_TDATA_BW = 16,
    parameter SPI_RAM_ADDR_BW = 16,
    parameter SPI_SFT_LEN = 8
) (
    input  logic                       arst_n,
    input  logic [  2*SPI_SFT_LEN-1:0] csr_rdata_2spi,
    output logic                       miso,
    input  logic                       mosi,
    input  logic                       sclk,
    output logic [SPI_RAM_ADDR_BW-1:0] spi_wr_addr_r,
    output logic [SPI_RAM_ADDR_BW-1:0] spi_wr_addr_w,
    output logic [  2*SPI_SFT_LEN-1:0] spi_wr_control,
    output logic [   SPI_TDATA_BW-1:0] spi_wr_wdata,
    input  logic [  2*SPI_SFT_LEN-1:0] sram_rdata_in_act_next,
    input  logic [  2*SPI_SFT_LEN-1:0] sram_rdata_in_bias_next,
    input  logic [  2*SPI_SFT_LEN-1:0] sram_rdata_in_fc_wgt_next,
    input  logic [  2*SPI_SFT_LEN-1:0] sram_rdata_in_instr_next,
    input  logic [  2*SPI_SFT_LEN-1:0] sram_rdata_in_wgt_next,
    input  logic [  2*SPI_SFT_LEN-1:0] sram_rdata_out_act_next,
    input  logic                       ss_n
);

  import bvp_spi_param::*;

  localparam                  STATE_BW        = 2;
  localparam                  SPI_CNT_BW      = $clog2(SPI_SFT_LEN << 1) + 1;

  localparam [SPI_CNT_BW-1:0] SPI_SFT_LEN_INT = SPI_SFT_LEN;
  localparam [  SPI_CNT_BW:0] CNT_MAX         = 2 * SPI_SFT_LEN - 1;

  localparam [  STATE_BW-1:0] STATE_CMD       = 2'b00;
  localparam [  STATE_BW-1:0] STATE_DATA      = 2'b01;

  logic                   counter_clr;
  logic [ SPI_CNT_BW-1:0] counter;
  logic [SPI_SFT_LEN-1:0] spcr;
  logic                   cnt_for_cmd;
  logic                   cnt_for_data;
  logic [   STATE_BW-1:0] state;
  logic                   wr_en;
  logic                   rd_en;
  logic [SPI_SFT_LEN-1:0] spdw;
  logic                   write_shift_done;
  logic                   read_shift_done;
  logic [SPI_SFT_LEN-1:0] spdr;

  assign counter_clr = counter == CNT_MAX;
  always_ff @(posedge sclk or negedge arst_n) begin
    if (~arst_n) begin
      counter <= {$bits(counter) {1'b0}};
    end else begin
      if (counter_clr) counter <= 0;
      else if (!ss_n) counter <= counter + 1;
    end
  end

  always_ff @(posedge sclk or negedge arst_n) begin
    if (~arst_n) begin
      spcr <= {$bits(spcr) {1'b0}};
    end else begin
      if (state == STATE_CMD) spcr <= {spcr[SPI_SFT_LEN-2:0], mosi};
    end
  end

  assign cnt_for_cmd = counter < SPI_SFT_LEN_INT ? 1'b1 : 1'b0;
  assign cnt_for_data = ~cnt_for_cmd;

  assign state = {ss_n, cnt_for_data};
  assign wr_en = (state == STATE_DATA) && (spcr[SPI_SFT_LEN-1] == SPI_CMD_WRITE);
  assign rd_en = (state == STATE_DATA) && (spcr[SPI_SFT_LEN-1] == SPI_CMD_READ);

  always_ff @(posedge sclk or negedge arst_n) begin
    if (~arst_n) begin
      spdw <= {$bits(spdw) {1'b0}};
    end else begin
      if (wr_en) begin
        spdw <= {spdw[SPI_SFT_LEN-2:0], mosi};
      end
    end
  end

  assign write_shift_done = counter == CNT_MAX;
  always_ff @(posedge sclk or negedge arst_n) begin
    if (~arst_n) begin
      spi_wr_control <= {$bits(spi_wr_control) {1'b0}};
      spi_wr_addr_w  <= {$bits(spi_wr_addr_w) {1'b0}};
      spi_wr_addr_r  <= {$bits(spi_wr_addr_r) {1'b0}};
      spi_wr_wdata   <= {$bits(spi_wr_wdata) {1'b0}};
    end else begin
      if (wr_en && write_shift_done) begin
        case (spcr[SPI_SFT_LEN-2:0])
          SPI_CMD_CONTROL_0: spi_wr_control[SPI_SFT_LEN-1:0] <= {spdw[SPI_SFT_LEN-2:0], mosi};
          SPI_CMD_CONTROL_1:
          spi_wr_control[2*SPI_SFT_LEN-1:1*SPI_SFT_LEN] <= {spdw[SPI_SFT_LEN-2:0], mosi};
          SPI_CMD_ADDR_W_0: spi_wr_addr_w[SPI_SFT_LEN-1:0] <= {spdw[SPI_SFT_LEN-2:0], mosi};
          SPI_CMD_ADDR_W_1:
          spi_wr_addr_w[2*SPI_SFT_LEN-1:1*SPI_SFT_LEN] <= {spdw[SPI_SFT_LEN-2:0], mosi};
          SPI_CMD_ADDR_R_0: spi_wr_addr_r[SPI_SFT_LEN-1:0] <= {spdw[SPI_SFT_LEN-2:0], mosi};
          SPI_CMD_ADDR_R_1:
          spi_wr_addr_r[2*SPI_SFT_LEN-1:1*SPI_SFT_LEN] <= {spdw[SPI_SFT_LEN-2:0], mosi};
          SPI_CMD_SRAM_W_0: spi_wr_wdata[SPI_SFT_LEN-1:0] <= {spdw[SPI_SFT_LEN-2:0], mosi};
          SPI_CMD_SRAM_W_1:
          spi_wr_wdata[2*SPI_SFT_LEN-1:1*SPI_SFT_LEN] <= {spdw[SPI_SFT_LEN-2:0], mosi};
        endcase
      end
    end
  end

  assign read_shift_done = counter == SPI_SFT_LEN_INT;
  always_ff @(negedge sclk or negedge arst_n) begin
    if (~arst_n) begin
      spdr <= {$bits(spdr) {1'b0}};
    end else begin
      if (rd_en && read_shift_done) begin
        case (spcr[SPI_SFT_LEN-2:0])
          SPI_CMD_CONTROL_0: spdr <= spi_wr_control[SPI_SFT_LEN-1:0];
          SPI_CMD_CONTROL_1: spdr <= spi_wr_control[2*SPI_SFT_LEN-1:1*SPI_SFT_LEN];
          SPI_CMD_CSR_RDATA_0: spdr <= csr_rdata_2spi[SPI_SFT_LEN-1:0];
          SPI_CMD_CSR_RDATA_1: spdr <= csr_rdata_2spi[2*SPI_SFT_LEN-1:1*SPI_SFT_LEN];
          SPI_CMD_ADDR_W_0: spdr <= spi_wr_addr_w[SPI_SFT_LEN-1:0];
          SPI_CMD_ADDR_W_1: spdr <= spi_wr_addr_w[2*SPI_SFT_LEN-1:1*SPI_SFT_LEN];
          SPI_CMD_ADDR_R_0: spdr <= spi_wr_addr_r[SPI_SFT_LEN-1:0];
          SPI_CMD_ADDR_R_1: spdr <= spi_wr_addr_r[2*SPI_SFT_LEN-1:1*SPI_SFT_LEN];
          SPI_CMD_SRAM_W_0: spdr <= spi_wr_wdata[SPI_SFT_LEN-1:0];
          SPI_CMD_SRAM_W_1: spdr <= spi_wr_wdata[2*SPI_SFT_LEN-1:1*SPI_SFT_LEN];
          SPI_CMD_SRAM_RD_IN_ACT_0: spdr <= sram_rdata_in_act_next[SPI_SFT_LEN-1:0];
          SPI_CMD_SRAM_RD_IN_ACT_1: spdr <= sram_rdata_in_act_next[2*SPI_SFT_LEN-1:1*SPI_SFT_LEN];
          SPI_CMD_SRAM_RD_IN_WGT_0: spdr <= sram_rdata_in_wgt_next[SPI_SFT_LEN-1:0];
          SPI_CMD_SRAM_RD_IN_WGT_1: spdr <= sram_rdata_in_wgt_next[2*SPI_SFT_LEN-1:1*SPI_SFT_LEN];
          SPI_CMD_SRAM_RD_IN_FC_WGT_0: spdr <= sram_rdata_in_fc_wgt_next[SPI_SFT_LEN-1:0];
          SPI_CMD_SRAM_RD_IN_FC_WGT_1:
          spdr <= sram_rdata_in_fc_wgt_next[2*SPI_SFT_LEN-1:1*SPI_SFT_LEN];
          SPI_CMD_SRAM_RD_IN_BIAS_0: spdr <= sram_rdata_in_bias_next[SPI_SFT_LEN-1:0];
          SPI_CMD_SRAM_RD_IN_BIAS_1: spdr <= sram_rdata_in_bias_next[2*SPI_SFT_LEN-1:1*SPI_SFT_LEN];
          SPI_CMD_SRAM_RD_IN_INSTR_0: spdr <= sram_rdata_in_instr_next[SPI_SFT_LEN-1:0];
          SPI_CMD_SRAM_RD_IN_INSTR_1:
          spdr <= sram_rdata_in_instr_next[2*SPI_SFT_LEN-1:1*SPI_SFT_LEN];
          SPI_CMD_SRAM_RD_OUT_ACT_0: spdr <= sram_rdata_out_act_next[SPI_SFT_LEN-1:0];
          SPI_CMD_SRAM_RD_OUT_ACT_1: spdr <= sram_rdata_out_act_next[2*SPI_SFT_LEN-1:1*SPI_SFT_LEN];
          default: spdr <= 0;
        endcase
      end else begin
        spdr <= spdr << 1;
      end

    end
  end

  always_comb begin
    miso = spdr[SPI_SFT_LEN-1];
  end

endmodule
