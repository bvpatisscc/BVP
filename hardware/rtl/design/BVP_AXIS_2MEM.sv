`timescale 1ns / 1ps

module BVP_AXIS_2MEM #(
    parameter DIN_WIDTH = 8,
    parameter MEM_WIDTH = 64
) (
    input  logic                 arst_n,
    input  logic                 axis2mem_addr_cnt_clr,
    output logic                 axis2mem_addr_cnt_en,
    output logic                 axis2mem_frame_computing,
    output logic [MEM_WIDTH-1:0] axis2mem_wdata,
    output logic                 axis2mem_web,
    input  logic [DIN_WIDTH-1:0] axis_i_tdata,
    output logic                 axis_i_tready,
    input  logic                 axis_i_tvalid,
    input  logic                 clk,
    output logic                 csr_chip_cfg_frame_ready_clr,
    input  logic                 csr_chip_cfg_frame_ready_out,
    output logic                 csr_chip_cfg_frame_ready_set,
    input  logic                 out_mem2axis_addr_clr
);
  logic [MEM_WIDTH-1:0] deser_data_o;
  logic                 deser_data_vld_o;
  logic [DIN_WIDTH-1:0] deser_data_i;
  logic                 deser_data_vld_i;
  logic                 axis2mem_addr_cnt_en_nxt;
  logic                 axis2mem_web_nxt;
  logic                 frame_ready;

  BVP_CORE_BSU_Cluster_deser #(
      .DIN_WIDTH        (DIN_WIDTH),
      .PEC_OUT_BUS_WIDTH(MEM_WIDTH)
  ) u_deser (
      .arst_n  (arst_n),
      .clk     (clk),
      .clk_en  (!axis2mem_frame_computing),
      .din     (deser_data_i),
      .din_vld (deser_data_vld_i),
      .dout    (deser_data_o),
      .dout_vld(deser_data_vld_o)
  );

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      deser_data_i <= {$bits(deser_data_i) {1'b0}};
      deser_data_vld_i <= {$bits(deser_data_vld_i) {1'b0}};
    end else begin
      deser_data_i     <= axis_i_tdata;
      deser_data_vld_i <= axis_i_tvalid;
    end
  end

  assign axis_i_tready = !frame_ready;

  assign axis2mem_addr_cnt_en_nxt = deser_data_vld_o && !frame_ready;

  assign axis2mem_web_nxt = frame_ready ? 1'b1 : ~deser_data_vld_o;

  always_ff @(negedge clk or negedge arst_n) begin
    if (~arst_n) begin
      axis2mem_addr_cnt_en <= {$bits(axis2mem_addr_cnt_en) {1'b0}};
      axis2mem_web <= {$bits(axis2mem_web) {1'b0}};
      axis2mem_wdata <= {$bits(axis2mem_wdata) {1'b0}};
    end else begin
      axis2mem_addr_cnt_en <= axis2mem_addr_cnt_en_nxt;
      axis2mem_web <= axis2mem_web_nxt;
      axis2mem_wdata <= deser_data_o;
    end
  end

  assign csr_chip_cfg_frame_ready_clr = out_mem2axis_addr_clr && frame_ready;
  assign csr_chip_cfg_frame_ready_set = axis2mem_addr_cnt_clr && !frame_ready;
  assign frame_ready = csr_chip_cfg_frame_ready_out;

  assign axis2mem_frame_computing = frame_ready;

endmodule
