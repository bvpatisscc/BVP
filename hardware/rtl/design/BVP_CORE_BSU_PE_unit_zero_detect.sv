`timescale 1ns / 1ps

module BVP_CORE_BSU_PE_unit_zero_detect #(
    parameter WGT_ENC_WIDTH = 4
) (
    input  logic                     arst_n,
    input  logic                     clk,
    input  logic                     clk_en,
    input  logic                     ctrl_first_wgt_vld,
    input  logic [WGT_ENC_WIDTH-1:0] wgt_enc,
    output logic                     wgt_is_zero
);

  localparam WGT_ENC_VAL_WIDTH = WGT_ENC_WIDTH - 1;
  logic [WGT_ENC_VAL_WIDTH-1:0] wgt_enc_val;
  logic                         wgt_enc_val_is_zero;
  logic                         wgt_is_zero_set;
  logic                         wgt_is_zero_clr;
  logic                         wgt_is_zero_tmp;

  assign wgt_enc_val = wgt_enc[WGT_ENC_WIDTH-2:0];
  assign wgt_enc_val_is_zero = (wgt_enc_val == {WGT_ENC_VAL_WIDTH{1'b0}});

  assign wgt_is_zero = (wgt_is_zero_set || wgt_is_zero_tmp) &&
                    (!wgt_is_zero_clr || wgt_enc_val_is_zero);

  assign wgt_is_zero_set = wgt_enc_val_is_zero && ctrl_first_wgt_vld && !wgt_is_zero_tmp;

  assign wgt_is_zero_clr = ctrl_first_wgt_vld && wgt_is_zero_tmp && !wgt_enc_val_is_zero;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      wgt_is_zero_tmp <= {$bits(wgt_is_zero_tmp) {1'b0}};
    end else begin
      if (clk_en) begin
        if (wgt_is_zero_set) begin
          wgt_is_zero_tmp <= 1'b1;
        end else if (wgt_is_zero_clr) begin
          wgt_is_zero_tmp <= 1'b0;
        end
      end
    end
  end
endmodule
