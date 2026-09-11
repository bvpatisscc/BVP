`timescale 1ns / 1ps

module BVP_OUT_mem2axis #(
    parameter DOUT_WIDTH = 8,
    parameter MEM_WIDTH  = 64
) (
    input  logic                  arst_n,
    output logic [DOUT_WIDTH-1:0] axis_o_tdata,
    output logic                  axis_o_tvalid,
    input  logic                  clk,
    input  logic                  ctrl_enable_mem2axis,
    input  logic [ MEM_WIDTH-1:0] mem_out_dout,
    output logic                  out_mem2axis_addr_inc
);

  localparam NUM_BYTES = MEM_WIDTH / DOUT_WIDTH;
  localparam BYTE_CNT_WIDTH = $clog2(NUM_BYTES);
  logic                      clk_en;
  logic                      byte_cnt_clr;
  logic                      byte_cnt_en;
  logic [BYTE_CNT_WIDTH-1:0] byte_cnt;

  assign clk_en = ctrl_enable_mem2axis;

  assign byte_cnt_clr = (byte_cnt == NUM_BYTES - 1) && byte_cnt_en;
  assign byte_cnt_en = ctrl_enable_mem2axis;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      byte_cnt <= {$bits(byte_cnt) {1'b0}};
    end else begin
      if (byte_cnt_clr) begin
        byte_cnt <= 0;
      end else if (byte_cnt_en) begin
        byte_cnt <= byte_cnt + 1;
      end
    end
  end

  always_ff @(negedge clk or negedge arst_n) begin
    if (~arst_n) begin
      out_mem2axis_addr_inc <= {$bits(out_mem2axis_addr_inc) {1'b0}};
    end else begin
      if (clk_en) begin
        out_mem2axis_addr_inc <= (byte_cnt == NUM_BYTES - 2) && byte_cnt_en;
      end
    end
  end

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      axis_o_tdata <= {$bits(axis_o_tdata) {1'b0}};
    end else begin
      if (clk_en) begin
        case (byte_cnt)

          3'd0: axis_o_tdata <= mem_out_dout[0+:8];
          3'd1: axis_o_tdata <= mem_out_dout[8+:8];
          3'd2: axis_o_tdata <= mem_out_dout[16+:8];
          3'd3: axis_o_tdata <= mem_out_dout[24+:8];
          3'd4: axis_o_tdata <= mem_out_dout[32+:8];
          3'd5: axis_o_tdata <= mem_out_dout[40+:8];
          3'd6: axis_o_tdata <= mem_out_dout[48+:8];
          3'd7: axis_o_tdata <= mem_out_dout[56+:8];
        endcase
      end
    end
  end
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      axis_o_tvalid <= {$bits(axis_o_tvalid) {1'b0}};
    end else begin
      axis_o_tvalid <= byte_cnt_en;
    end
  end

endmodule
