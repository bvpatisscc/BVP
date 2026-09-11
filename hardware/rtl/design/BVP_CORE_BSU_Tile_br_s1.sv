`timescale 1ns / 1ps

module BVP_CORE_BSU_Tile_br_s1 #(
    parameter DIN_WIDTH = 16
) (
    input  logic                 arst_n,
    output logic [DIN_WIDTH-1:0] bias_relu_data_o_s1,
    output logic                 bias_relu_data_pvld_o_s1,
    input  logic [DIN_WIDTH-1:0] bias_relu_din_act,
    input  logic                 bias_relu_din_act_vld,
    input  logic [DIN_WIDTH-1:0] bias_relu_din_bias,
    input  logic                 bias_relu_din_bias_vld,
    input  logic                 bias_relu_prdy_i_s1,
    output logic                 bias_relu_prdy_o,
    input  logic                 clk,
    input  logic                 clk_en
);
  logic [DIN_WIDTH-1:0] bias_relu_dout_biased;
  logic                 bias_relu_din_vld;
  logic [DIN_WIDTH-1:0] bias_relu_din_bias_reg;
  logic                 bias_relu_din_bias_reg_vld;

  bintf_vldrdy_skbuf #(
      .DATA_WIDTH(DIN_WIDTH)
  ) u_vr_skbuf (
      .arst_n   (arst_n),
      .clk      (clk),
      .clk_en   (clk_en),
      .dn_data_o(bias_relu_data_o_s1),
      .dn_prdy_i(bias_relu_prdy_i_s1),
      .dn_pvld_o(bias_relu_data_pvld_o_s1),
      .up_data_i(bias_relu_dout_biased),
      .up_rdy_o (bias_relu_prdy_o),
      .up_vld_i (bias_relu_din_vld)
  );
  BVP_CORE_BSU_unit_add_satu #(
      .DIN_WIDTH (DIN_WIDTH),
      .DOUT_WIDTH(DIN_WIDTH)
  ) u_add_satu (
      .add_din_0(bias_relu_din_act),
      .add_din_1(bias_relu_din_bias_reg),
      .dout     (bias_relu_dout_biased)
  );

  assign bias_relu_din_vld = bias_relu_din_act_vld && bias_relu_din_bias_reg_vld;

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      bias_relu_din_bias_reg <= {$bits(bias_relu_din_bias_reg) {1'b0}};
      bias_relu_din_bias_reg_vld <= {$bits(bias_relu_din_bias_reg_vld) {1'b0}};
    end else begin
      if (clk_en) begin
        if (bias_relu_din_bias_vld) begin
          bias_relu_din_bias_reg <= bias_relu_din_bias;
          bias_relu_din_bias_reg_vld <= bias_relu_prdy_o;
        end
      end
    end
  end

endmodule
