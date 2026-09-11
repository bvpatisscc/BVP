`timescale 1ns / 1ps

module BVP_CORE_BSU_Tile_br_s2 #(
    parameter DIN_WIDTH = 16,
    parameter NLAYER_ACT_WIDTH = 8
) (
    input  logic                        arst_n,
    input  logic                        aux_rp_calc_skip_rounding,
    input  logic [                 4:0] aux_rp_calc_truncate_frac_width,
    input  logic [                 3:0] aux_rp_calc_truncate_frac_width_m1,
    output logic [NLAYER_ACT_WIDTH-1:0] bias_relu_data_o,
    output logic                        bias_relu_data_pvld_o,
    input  logic                        bias_relu_din_vld_s2,
    input  logic [       DIN_WIDTH-1:0] bias_relu_dout_biased,
    input  logic                        bias_relu_prdy_i,
    output logic                        bias_relu_prdy_o_s2,
    input  logic                        clk,
    input  logic                        clk_en,
    input  logic                        ctrl_fc_only_en
);
  logic [       DIN_WIDTH-1:0] bias_relu_dout_biased_rounded_temp;
  logic [       DIN_WIDTH-1:0] bias_relu_dout_biased_rounded;
  logic [NLAYER_ACT_WIDTH-1:0] bias_relu_dout_biased_satu;
  logic                        relu_en;
  logic [NLAYER_ACT_WIDTH-1:0] bias_relu_dout_biased_relu;

  bintf_vldrdy_skbuf #(
      .DATA_WIDTH(NLAYER_ACT_WIDTH)
  ) u_vr_skbuf (
      .arst_n   (arst_n),
      .clk      (clk),
      .clk_en   (clk_en),
      .dn_data_o(bias_relu_data_o),
      .dn_prdy_i(bias_relu_prdy_i),
      .dn_pvld_o(bias_relu_data_pvld_o),
      .up_data_i(bias_relu_dout_biased_relu),
      .up_rdy_o (bias_relu_prdy_o_s2),
      .up_vld_i (bias_relu_din_vld_s2)
  );

  op_round_flex #(
      .DIN_WIDTH(DIN_WIDTH)
  ) u_round (
      .din                   (bias_relu_dout_biased),
      .dout                  (bias_relu_dout_biased_rounded_temp),
      .truncate_frac_width   (aux_rp_calc_truncate_frac_width),
      .truncate_frac_width_m1(aux_rp_calc_truncate_frac_width_m1)
  );

  assign bias_relu_dout_biased_rounded = aux_rp_calc_skip_rounding ? bias_relu_dout_biased : bias_relu_dout_biased_rounded_temp;

  op_saturate #(
      .DIN_WIDTH (DIN_WIDTH),
      .DOUT_WIDTH(NLAYER_ACT_WIDTH)
  ) u_satu (
      .din (bias_relu_dout_biased_rounded),
      .dout(bias_relu_dout_biased_satu)
  );

  assign relu_en = !ctrl_fc_only_en;
  BVP_CORE_BSU_Tile_relu #(
      .DATA_WIDTH(NLAYER_ACT_WIDTH)
  ) u_relu (
      .din    (bias_relu_dout_biased_satu),
      .relu_en(relu_en),
      .dout   (bias_relu_dout_biased_relu)
  );

endmodule
