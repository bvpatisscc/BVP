`timescale 1ns / 1ps

module BVP_CORE_BSU_PE_intf #(
    parameter ACT_WIDTH = 8,
    parameter WGT_ENC_WIDTH = 3,
    parameter PEA_WGT_BUS_WIDTH = 9 * WGT_ENC_WIDTH,
    parameter DOUT_WIDTH = 16
) (
    output logic [        ACT_WIDTH-1:0] arr_act_in_data,
    output logic [PEA_WGT_BUS_WIDTH-1:0] arr_wgt_in_data,
    input  logic                         arst_n,
    input  logic                         clk,
    input  logic                         clk_en,
    input  logic                         ctrl_flush_pe2obuf,
    input  logic [        ACT_WIDTH-1:0] inbuf2pe_act_data,
    input  logic                         inbuf2pe_act_vld,
    input  logic [PEA_WGT_BUS_WIDTH-1:0] inbuf2pe_wgt_data,
    input  logic                         inbuf2pe_wgt_vld,
    input  logic                         outbuf2pe_prdy,
    output logic                         pe2inbuf_act_rdy,
    output logic                         pe2inbuf_wgt_rdy,
    output logic [       DOUT_WIDTH-1:0] pe2outbuf_data,
    input  logic [       DOUT_WIDTH-1:0] pe2outbuf_data_int,
    output logic                         pe2outbuf_pvld
);
  logic pe2inbuf_rdy;
  logic pe2outbuf_pvld_int;
  logic outbuf2pe_prdy_int;
  logic pe2outbuf_pvld_int_final;

  assign pe2inbuf_rdy = ~(pe2outbuf_pvld_int) || (outbuf2pe_prdy_int);
  assign pe2inbuf_act_rdy = pe2inbuf_rdy;
  assign pe2inbuf_wgt_rdy = pe2inbuf_rdy;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      pe2outbuf_pvld_int <= {$bits(pe2outbuf_pvld_int) {1'b0}};
    end else begin
      if (clk_en) begin
        if (pe2inbuf_rdy) pe2outbuf_pvld_int <= inbuf2pe_act_vld && inbuf2pe_wgt_vld;
      end
    end
  end

  assign arr_act_in_data = inbuf2pe_act_data;

  assign arr_wgt_in_data = inbuf2pe_wgt_data;

  skid_buffer #(
      .DATA_WIDTH(DOUT_WIDTH)
  ) uskidbuf (
      .arst_n    (arst_n),
      .clk       (clk),
      .clk_en    (clk_en),
      .dn_data_o (pe2outbuf_data),
      .dn_ready_i(outbuf2pe_prdy),
      .dn_valid_o(pe2outbuf_pvld),
      .up_data_i (pe2outbuf_data_int),
      .up_ready_o(outbuf2pe_prdy_int),
      .up_valid_i(pe2outbuf_pvld_int_final)
  );

  assign pe2outbuf_pvld_int_final = ctrl_flush_pe2obuf;

endmodule
