`ifndef __BVP_SPI_REG_PARAM_SVH__
`define __BVP_SPI_REG_PARAM_SVH__

parameter [SPI_SFT_LEN-2:0] SPI_CMD_CONTROL_0 = 'h00;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_CONTROL_1 = 'h01;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_CSR_RDATA_0 = 'h02;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_CSR_RDATA_1 = 'h03;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_ADDR_W_0 = 'h04;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_ADDR_W_1 = 'h05;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_ADDR_R_0 = 'h06;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_ADDR_R_1 = 'h07;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_SRAM_W_0 = 'h08;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_SRAM_W_1 = 'h09;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_SRAM_RD_IN_ACT_0 = 'h0A;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_SRAM_RD_IN_ACT_1 = 'h0B;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_SRAM_RD_IN_WGT_0 = 'h0C;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_SRAM_RD_IN_WGT_1 = 'h0D;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_SRAM_RD_IN_FC_WGT_0 = 'h0E;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_SRAM_RD_IN_FC_WGT_1 = 'h0F;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_SRAM_RD_IN_BIAS_0 = 'h10;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_SRAM_RD_IN_BIAS_1 = 'h11;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_SRAM_RD_IN_INSTR_0 = 'h12;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_SRAM_RD_IN_INSTR_1 = 'h13;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_SRAM_RD_OUT_ACT_0 = 'h14;
parameter [SPI_SFT_LEN-2:0] SPI_CMD_SRAM_RD_OUT_ACT_1 = 'h15;

parameter SPI_CMD_WRITE = 1'b0;
parameter SPI_CMD_READ = 1'b1;

`endif
