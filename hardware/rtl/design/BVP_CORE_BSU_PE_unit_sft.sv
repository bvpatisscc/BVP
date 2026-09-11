`timescale 1ns / 1ps

module BVP_CORE_BSU_PE_unit_sft #(
    parameter ACT_WIDTH = 8,
    WGT_ENC_WIDTH = 4,
    DOUT_WIDTH = 16
) (
    input  logic signed [    ACT_WIDTH-1:0] din,
    output logic signed [   DOUT_WIDTH-1:0] dout,
    input  logic        [WGT_ENC_WIDTH-1:0] wgt_enc
);
  logic                       wgt_enc_sign;
  logic [WGT_ENC_WIDTH-1-1:0] wgt_enc_val;
  logic [     DOUT_WIDTH-1:0] dout_shifted;

  assign wgt_enc_sign = wgt_enc[WGT_ENC_WIDTH-1];
  assign wgt_enc_val = wgt_enc[WGT_ENC_WIDTH-2:0];

  assign dout_shifted = din << wgt_enc_val;
  assign dout = wgt_enc_sign ? -dout_shifted : dout_shifted;

endmodule
