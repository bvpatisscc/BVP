`timescale 1ns / 1ps

module BVP_SPI_ctrl #(
    parameter SPI_TDATA_BW = 16,
    SPI_RAM_WR_DATA_MAX_BW = 576,
    SPI_RAM_ADDR_BW = 16
) (
    input  logic                              arst_n,
    output logic [       SPI_RAM_ADDR_BW-1:0] csr_raddr,
    input  logic [          SPI_TDATA_BW-1:0] csr_rdata,
    output logic [          SPI_TDATA_BW-1:0] csr_rdata_2spi,
    output logic                              csr_rden,
    output logic [       SPI_RAM_ADDR_BW-1:0] csr_waddr,
    output logic [          SPI_TDATA_BW-1:0] csr_wdata,
    output logic                              csr_wren,
    input  logic                              sclk,
    input  logic [       SPI_RAM_ADDR_BW-1:0] spi_wr_addr_r,
    input  logic [       SPI_RAM_ADDR_BW-1:0] spi_wr_addr_w,
    input  logic [          SPI_TDATA_BW-1:0] spi_wr_control,
    input  logic [          SPI_TDATA_BW-1:0] spi_wr_wdata,
    output logic [       SPI_RAM_ADDR_BW-1:0] sram_addr,
    output logic [                       7:0] sram_ceb,
    input  logic [                      63:0] sram_rdata_in_act_dout,
    output logic [                      15:0] sram_rdata_in_act_next,
    input  logic [                     127:0] sram_rdata_in_bias_dout,
    output logic [                      15:0] sram_rdata_in_bias_next,
    input  logic [                      63:0] sram_rdata_in_fc_wgt_dout,
    output logic [                      15:0] sram_rdata_in_fc_wgt_next,
    input  logic [                      63:0] sram_rdata_in_instr_dout,
    output logic [                      15:0] sram_rdata_in_instr_next,
    input  logic [                     575:0] sram_rdata_in_wgt_dout,
    output logic [                      15:0] sram_rdata_in_wgt_next,
    input  logic [                      63:0] sram_rdata_out_act_dout,
    output logic [                      15:0] sram_rdata_out_act_next,
    output logic [SPI_RAM_WR_DATA_MAX_BW-1:0] sram_wdata,
    output logic                              sram_web
);

  import bvp_spi_param::*;
  logic [   SPI_TDATA_BW-1:0] control_cur;
  logic [SPI_RAM_ADDR_BW-1:0] sram_addr_r_cur;
  logic [SPI_RAM_ADDR_BW-1:0] addr_r_spi_cur;
  logic                       sram_wrrd_ctrl;
  logic                       csr_wren_ctrl;
  logic                       csr_rden_ctrl;
  logic                       csr_wrrd_enable;
  logic                       csr_wren_next;
  logic                       csr_rden_next;
  logic                       sram_web_next;
  logic [SPI_RAM_ADDR_BW-1:0] sram_addr_next;
  logic [                7:0] sram_ceb_next;
  logic [SPI_RAM_ADDR_BW-1:0] sram_addr_r_next;
  always_ff @(negedge sclk or negedge arst_n) begin
    if (~arst_n) begin
      control_cur <= {$bits(control_cur) {1'b0}};
    end else begin
      control_cur <= spi_wr_control;
    end
  end
  always_ff @(negedge sclk or negedge arst_n) begin
    if (~arst_n) begin
      sram_ceb <= {$bits(sram_ceb) {1'b0}};
      sram_web <= 1'b1;
      sram_addr <= {$bits(sram_addr) {1'b0}};
      sram_addr_r_cur <= {$bits(sram_addr_r_cur) {1'b0}};
      addr_r_spi_cur <= {$bits(addr_r_spi_cur) {1'b0}};
    end else begin
      if (!csr_wrrd_enable) begin
        sram_ceb        <= sram_ceb_next;
        sram_web        <= sram_web_next;
        sram_addr       <= sram_addr_next;
        sram_addr_r_cur <= sram_addr_r_next;

        addr_r_spi_cur  <= spi_wr_addr_r;
      end
    end
  end

  always_ff @(negedge sclk or negedge arst_n) begin
    if (~arst_n) begin
      sram_wdata <= {$bits(sram_wdata) {1'b0}};
    end else begin
      if (sram_wrrd_ctrl) begin
        case (control_cur[CTRL_REG_BYTE_SEL_MSB:CTRL_REG_BYTE_SEL_LSB])
          SRAM_2BYTE_0: sram_wdata[15:0] <= spi_wr_wdata;
          SRAM_2BYTE_1: sram_wdata[31:16] <= spi_wr_wdata;
          SRAM_2BYTE_2: sram_wdata[47:32] <= spi_wr_wdata;
          SRAM_2BYTE_3: sram_wdata[63:48] <= spi_wr_wdata;
          SRAM_2BYTE_4: sram_wdata[79:64] <= spi_wr_wdata;
          SRAM_2BYTE_5: sram_wdata[95:80] <= spi_wr_wdata;
          SRAM_2BYTE_6: sram_wdata[111:96] <= spi_wr_wdata;
          SRAM_2BYTE_7: sram_wdata[127:112] <= spi_wr_wdata;
          SRAM_2BYTE_8: sram_wdata[143:128] <= spi_wr_wdata;
          SRAM_2BYTE_9: sram_wdata[159:144] <= spi_wr_wdata;
          SRAM_2BYTE_10: sram_wdata[175:160] <= spi_wr_wdata;
          SRAM_2BYTE_11: sram_wdata[191:176] <= spi_wr_wdata;
          SRAM_2BYTE_12: sram_wdata[207:192] <= spi_wr_wdata;
          SRAM_2BYTE_13: sram_wdata[223:208] <= spi_wr_wdata;
          SRAM_2BYTE_14: sram_wdata[239:224] <= spi_wr_wdata;
          SRAM_2BYTE_15: sram_wdata[255:240] <= spi_wr_wdata;
          SRAM_2BYTE_16: sram_wdata[271:256] <= spi_wr_wdata;
          SRAM_2BYTE_17: sram_wdata[287:272] <= spi_wr_wdata;
          SRAM_2BYTE_18: sram_wdata[303:288] <= spi_wr_wdata;
          SRAM_2BYTE_19: sram_wdata[319:304] <= spi_wr_wdata;
          SRAM_2BYTE_20: sram_wdata[335:320] <= spi_wr_wdata;
          SRAM_2BYTE_21: sram_wdata[351:336] <= spi_wr_wdata;
          SRAM_2BYTE_22: sram_wdata[367:352] <= spi_wr_wdata;
          SRAM_2BYTE_23: sram_wdata[383:368] <= spi_wr_wdata;
          SRAM_2BYTE_24: sram_wdata[399:384] <= spi_wr_wdata;
          SRAM_2BYTE_25: sram_wdata[415:400] <= spi_wr_wdata;
          SRAM_2BYTE_26: sram_wdata[431:416] <= spi_wr_wdata;
          SRAM_2BYTE_27: sram_wdata[447:432] <= spi_wr_wdata;
          SRAM_2BYTE_28: sram_wdata[463:448] <= spi_wr_wdata;
          SRAM_2BYTE_29: sram_wdata[479:464] <= spi_wr_wdata;
          SRAM_2BYTE_30: sram_wdata[495:480] <= spi_wr_wdata;
          SRAM_2BYTE_31: sram_wdata[511:496] <= spi_wr_wdata;
          SRAM_2BYTE_32: sram_wdata[527:512] <= spi_wr_wdata;
          SRAM_2BYTE_33: sram_wdata[543:528] <= spi_wr_wdata;
          SRAM_2BYTE_34: sram_wdata[559:544] <= spi_wr_wdata;
          SRAM_2BYTE_35: sram_wdata[575:560] <= spi_wr_wdata;
          default: sram_wdata <= 0;
        endcase
      end
    end
  end
  always_ff @(negedge sclk or negedge arst_n) begin
    if (~arst_n) begin
      csr_wdata <= {$bits(csr_wdata) {1'b0}};
      csr_waddr <= {$bits(csr_waddr) {1'b0}};
    end else begin
      if (csr_wren_ctrl) begin
        csr_wdata <= spi_wr_wdata;
        csr_waddr <= spi_wr_addr_w;
      end
    end
  end
  always_ff @(negedge sclk or negedge arst_n) begin
    if (~arst_n) begin
      csr_raddr <= {$bits(csr_raddr) {1'b0}};
      csr_rdata_2spi <= {$bits(csr_rdata_2spi) {1'b0}};
    end else begin
      if (csr_rden_ctrl) begin
        csr_raddr      <= spi_wr_addr_r;
        csr_rdata_2spi <= csr_rdata;
      end
    end
  end
  always_ff @(negedge sclk or negedge arst_n) begin
    if (~arst_n) begin
      csr_wren <= {$bits(csr_wren) {1'b0}};
      csr_rden <= {$bits(csr_rden) {1'b0}};
    end else begin
      csr_wren <= csr_wren_next;
      csr_rden <= csr_rden_next;
    end
  end

  assign sram_wrrd_ctrl  = control_cur[CTRL_REG_SRAM_WRRD_EN_BIT];
  assign csr_wren_ctrl   = control_cur[CTRL_REG_CSR_WRITE_EN_BIT];
  assign csr_rden_ctrl   = control_cur[CTRL_REG_CSR_READ_EN_BIT];
  assign csr_wrrd_enable = csr_wren_ctrl | csr_rden_ctrl;

  always_comb begin

    if (csr_wren_ctrl) begin
      csr_wren_next = 1'b1;
      csr_rden_next = 1'b0;
    end else if (csr_rden_ctrl) begin
      csr_wren_next = 1'b0;
      csr_rden_next = 1'b1;
    end else begin
      csr_wren_next = 1'b0;
      csr_rden_next = 1'b0;
    end
  end

  always_comb begin
    if (csr_wrrd_enable) begin
      sram_web_next  = 1'b1;
      sram_addr_next = sram_addr;
      sram_ceb_next  = 8'b11111111;
    end else begin
      if (sram_wrrd_ctrl) begin

        sram_web_next  = 1'b0;
        sram_addr_next = spi_wr_addr_w;

        case (control_cur[CTRL_REG_SRAM_TYPE_MSB:CTRL_REG_SRAM_TYPE_LSB])
          SRAM_TYPE_IN_ACT:    sram_ceb_next = 8'b1111_1110;
          SRAM_TYPE_IN_WGT:    sram_ceb_next = 8'b1111_1101;
          SRAM_TYPE_IN_FC_WGT: sram_ceb_next = 8'b1111_1011;
          SRAM_TYPE_IN_BIAS:   sram_ceb_next = 8'b1111_0111;
          SRAM_TYPE_IN_INSTR:  sram_ceb_next = 8'b1110_1111;
          SRAM_TYPE_OUT_ACT:   sram_ceb_next = 8'b1101_1111;
          default:             sram_ceb_next = 8'b1111_1111;
        endcase
      end else begin

        sram_web_next  = 1'b1;
        sram_addr_next = sram_addr_r_cur;
        sram_ceb_next  = 8'b0000_0000;
      end
    end
  end

  always_comb begin
    sram_addr_r_next = addr_r_spi_cur;
  end

  always_comb begin
    case (control_cur[CTRL_REG_BYTE_SEL_MSB:CTRL_REG_BYTE_SEL_LSB])
      SRAM_2BYTE_0   : sram_rdata_in_act_next = sram_rdata_in_act_dout[15:0];
      SRAM_2BYTE_1   : sram_rdata_in_act_next = sram_rdata_in_act_dout[31:16];
      SRAM_2BYTE_2   : sram_rdata_in_act_next = sram_rdata_in_act_dout[47:32];
      SRAM_2BYTE_3   : sram_rdata_in_act_next = sram_rdata_in_act_dout[63:48];
      default: sram_rdata_in_act_next = sram_rdata_in_act_dout[15:0];
    endcase
  end

  always_comb begin
    case (control_cur[CTRL_REG_BYTE_SEL_MSB:CTRL_REG_BYTE_SEL_LSB])
      SRAM_2BYTE_0   : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[15:0];
      SRAM_2BYTE_1   : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[31:16];
      SRAM_2BYTE_2   : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[47:32];
      SRAM_2BYTE_3   : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[63:48];
      SRAM_2BYTE_4   : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[79:64];
      SRAM_2BYTE_5   : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[95:80];
      SRAM_2BYTE_6   : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[111:96];
      SRAM_2BYTE_7   : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[127:112];
      SRAM_2BYTE_8   : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[143:128];
      SRAM_2BYTE_9   : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[159:144];
      SRAM_2BYTE_10  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[175:160];
      SRAM_2BYTE_11  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[191:176];
      SRAM_2BYTE_12  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[207:192];
      SRAM_2BYTE_13  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[223:208];
      SRAM_2BYTE_14  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[239:224];
      SRAM_2BYTE_15  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[255:240];
      SRAM_2BYTE_16  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[271:256];
      SRAM_2BYTE_17  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[287:272];
      SRAM_2BYTE_18  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[303:288];
      SRAM_2BYTE_19  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[319:304];
      SRAM_2BYTE_20  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[335:320];
      SRAM_2BYTE_21  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[351:336];
      SRAM_2BYTE_22  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[367:352];
      SRAM_2BYTE_23  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[383:368];
      SRAM_2BYTE_24  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[399:384];
      SRAM_2BYTE_25  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[415:400];
      SRAM_2BYTE_26  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[431:416];
      SRAM_2BYTE_27  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[447:432];
      SRAM_2BYTE_28  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[463:448];
      SRAM_2BYTE_29  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[479:464];
      SRAM_2BYTE_30  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[495:480];
      SRAM_2BYTE_31  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[511:496];
      SRAM_2BYTE_32  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[527:512];
      SRAM_2BYTE_33  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[543:528];
      SRAM_2BYTE_34  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[559:544];
      SRAM_2BYTE_35  : sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[575:560];
      default: sram_rdata_in_wgt_next = sram_rdata_in_wgt_dout[15:0];
    endcase
  end

  always_comb begin
    case (control_cur[CTRL_REG_BYTE_SEL_MSB:CTRL_REG_BYTE_SEL_LSB])
      SRAM_2BYTE_0   : sram_rdata_in_fc_wgt_next = sram_rdata_in_fc_wgt_dout[15:0];
      SRAM_2BYTE_1   : sram_rdata_in_fc_wgt_next = sram_rdata_in_fc_wgt_dout[31:16];
      SRAM_2BYTE_2   : sram_rdata_in_fc_wgt_next = sram_rdata_in_fc_wgt_dout[47:32];
      SRAM_2BYTE_3   : sram_rdata_in_fc_wgt_next = sram_rdata_in_fc_wgt_dout[63:48];
      default: sram_rdata_in_fc_wgt_next = sram_rdata_in_fc_wgt_dout[15:0];
    endcase
  end

  always_comb begin
    case (control_cur[CTRL_REG_BYTE_SEL_MSB:CTRL_REG_BYTE_SEL_LSB])
      SRAM_2BYTE_0   : sram_rdata_in_bias_next = sram_rdata_in_bias_dout[15:0];
      SRAM_2BYTE_1   : sram_rdata_in_bias_next = sram_rdata_in_bias_dout[31:16];
      SRAM_2BYTE_2   : sram_rdata_in_bias_next = sram_rdata_in_bias_dout[47:32];
      SRAM_2BYTE_3   : sram_rdata_in_bias_next = sram_rdata_in_bias_dout[63:48];
      SRAM_2BYTE_4   : sram_rdata_in_bias_next = sram_rdata_in_bias_dout[79:64];
      SRAM_2BYTE_5   : sram_rdata_in_bias_next = sram_rdata_in_bias_dout[95:80];
      SRAM_2BYTE_6   : sram_rdata_in_bias_next = sram_rdata_in_bias_dout[111:96];
      SRAM_2BYTE_7   : sram_rdata_in_bias_next = sram_rdata_in_bias_dout[127:112];
      default: sram_rdata_in_bias_next = sram_rdata_in_bias_dout[15:0];
    endcase
  end

  always_comb begin
    case (control_cur[CTRL_REG_BYTE_SEL_MSB:CTRL_REG_BYTE_SEL_LSB])
      SRAM_2BYTE_0   : sram_rdata_in_instr_next = sram_rdata_in_instr_dout[15:0];
      SRAM_2BYTE_1   : sram_rdata_in_instr_next = sram_rdata_in_instr_dout[31:16];
      SRAM_2BYTE_2   : sram_rdata_in_instr_next = sram_rdata_in_instr_dout[47:32];
      SRAM_2BYTE_3   : sram_rdata_in_instr_next = sram_rdata_in_instr_dout[63:48];
      default: sram_rdata_in_instr_next = sram_rdata_in_instr_dout[15:0];
    endcase
  end

  always_comb begin
    case (control_cur[CTRL_REG_BYTE_SEL_MSB:CTRL_REG_BYTE_SEL_LSB])
      SRAM_2BYTE_0   : sram_rdata_out_act_next = sram_rdata_out_act_dout[15:0];
      SRAM_2BYTE_1   : sram_rdata_out_act_next = sram_rdata_out_act_dout[31:16];
      SRAM_2BYTE_2   : sram_rdata_out_act_next = sram_rdata_out_act_dout[47:32];
      SRAM_2BYTE_3   : sram_rdata_out_act_next = sram_rdata_out_act_dout[63:48];
      default: sram_rdata_out_act_next = sram_rdata_out_act_dout[15:0];
    endcase
  end

endmodule
