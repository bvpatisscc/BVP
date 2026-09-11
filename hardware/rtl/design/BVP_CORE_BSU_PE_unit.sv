`timescale 1ns / 1ps

module BVP_CORE_BSU_PE_unit #(
    parameter ACT_WIDTH = 8,
    parameter WGT_ENC_WIDTH = 4,
    parameter DOUT_WIDTH = 16
) (
    input  logic [    ACT_WIDTH-1:0] act_in,
    input  logic                     arst_n,
    input  logic                     clk,
    input  logic                     clk_en,
    input  logic                     ctrl_first_wgt_vld,
    input  logic                     flush_pe_prev_out,
    output logic [   DOUT_WIDTH-1:0] pe_out,
    input  logic [   DOUT_WIDTH-1:0] pe_psum_in,
    input  logic                     use_prev_out,
    input  logic [WGT_ENC_WIDTH-1:0] wgt_in_enc
);

  localparam ADDER_WIDTH = DOUT_WIDTH + 1;
  logic                   wgt_is_zero;
  logic [ DOUT_WIDTH-1:0] sft_out;
  logic [ADDER_WIDTH-1:0] adder_out_temp;
  logic [ DOUT_WIDTH-1:0] adder_out;
  logic [ DOUT_WIDTH-1:0] mux_sel_zero;
  logic [ DOUT_WIDTH-1:0] mux_sel_prev;
  logic [ DOUT_WIDTH-1:0] pe_psum_in_sel;
  logic [ DOUT_WIDTH-1:0] prev_out;

  BVP_CORE_BSU_PE_unit_zero_detect #(
      .WGT_ENC_WIDTH(WGT_ENC_WIDTH)
  ) zdect (
      .arst_n            (arst_n),
      .clk               (clk),
      .clk_en            (clk_en),
      .ctrl_first_wgt_vld(ctrl_first_wgt_vld),
      .wgt_enc           (wgt_in_enc),
      .wgt_is_zero       (wgt_is_zero)
  );

  BVP_CORE_BSU_PE_unit_sft #(
      .ACT_WIDTH    (ACT_WIDTH),
      .WGT_ENC_WIDTH(WGT_ENC_WIDTH),
      .DOUT_WIDTH   (DOUT_WIDTH)
  ) sft (
      .din    (act_in),
      .dout   (sft_out),
      .wgt_enc(wgt_in_enc)
  );

  BVP_CORE_BSU_PE_unit_adder #(
      .DIN_WIDTH (DOUT_WIDTH),
      .DOUT_WIDTH(ADDER_WIDTH)
  ) adder (
      .din_0(mux_sel_zero),
      .din_1(mux_sel_prev),
      .dout (adder_out_temp)
  );

  op_saturate #(
      .DIN_WIDTH (ADDER_WIDTH),
      .DOUT_WIDTH(DOUT_WIDTH)
  ) satu (
      .din (adder_out_temp),
      .dout(adder_out)
  );

  assign mux_sel_zero   = wgt_is_zero ? {DOUT_WIDTH{1'b0}} : sft_out;

  assign mux_sel_prev   = use_prev_out ? prev_out : pe_psum_in_sel;
  assign pe_psum_in_sel = flush_pe_prev_out ? {DOUT_WIDTH{1'b0}} : pe_psum_in;

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      prev_out <= {$bits(prev_out) {1'b0}};
    end else begin
      if (clk_en) begin
        prev_out <= adder_out;
      end
    end
  end

  assign pe_out = prev_out;

endmodule
