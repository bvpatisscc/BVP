`timescale 1ns / 1ps

module BVP_CORE_AUX_rp_calc (
    input  logic       arst_n,
    output logic       aux_rp_calc_skip_rounding,
    output logic [4:0] aux_rp_calc_truncate_frac_width,
    output logic [3:0] aux_rp_calc_truncate_frac_width_m1,
    input  logic       clk,
    input  logic [2:0] csr_layer_cfg_cur_act_frac_width,
    input  logic [3:0] csr_layer_cfg_cur_wgt_frac_width,
    input  logic [2:0] csr_layer_cfg_nxt_act_frac_width
);

  logic [2:0] dout_frac_width;
  logic [4:0] din_frac_width_nxt;
  logic [4:0] truncate_frac_width_nxt;
  logic [3:0] truncate_frac_width_m1_nxt;
  logic       skip_rounding_nxt;

  assign dout_frac_width = csr_layer_cfg_nxt_act_frac_width;
  always_comb begin
    din_frac_width_nxt = csr_layer_cfg_cur_act_frac_width + csr_layer_cfg_cur_wgt_frac_width;
    truncate_frac_width_nxt = din_frac_width_nxt - dout_frac_width;
    truncate_frac_width_m1_nxt = truncate_frac_width_nxt - 1;
  end

  assign skip_rounding_nxt = (truncate_frac_width_nxt == 0);
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      aux_rp_calc_truncate_frac_width <= {$bits(aux_rp_calc_truncate_frac_width) {1'b0}};
      aux_rp_calc_truncate_frac_width_m1 <= {$bits(aux_rp_calc_truncate_frac_width_m1) {1'b0}};
      aux_rp_calc_skip_rounding <= {$bits(aux_rp_calc_skip_rounding) {1'b0}};
    end else begin
      aux_rp_calc_truncate_frac_width    <= truncate_frac_width_nxt;
      aux_rp_calc_truncate_frac_width_m1 <= truncate_frac_width_m1_nxt;
      aux_rp_calc_skip_rounding          <= skip_rounding_nxt;
    end
  end

endmodule
