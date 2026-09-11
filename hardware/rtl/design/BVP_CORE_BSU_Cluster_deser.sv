`timescale 1ns / 1ps

module BVP_CORE_BSU_Cluster_deser #(
    parameter DIN_WIDTH = 8,
    parameter PEC_OUT_BUS_WIDTH = 8 * DIN_WIDTH
) (
    input  logic                         arst_n,
    input  logic                         clk,
    input  logic                         clk_en,
    input  logic [        DIN_WIDTH-1:0] din,
    input  logic                         din_vld,
    output logic [PEC_OUT_BUS_WIDTH-1:0] dout,
    output logic                         dout_vld
);
  logic                         accum_cnt_rch_max;
  logic                         accum_cnt_clr;
  logic                         accum_cnt_en;
  logic [                  2:0] accum_cnt;
  logic [PEC_OUT_BUS_WIDTH-1:0] data_buffer;

  assign accum_cnt_rch_max = (accum_cnt == 7) && accum_cnt_en;
  assign accum_cnt_clr = accum_cnt_rch_max;
  assign accum_cnt_en = din_vld;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      accum_cnt <= {$bits(accum_cnt) {1'b0}};
    end else begin
      if (clk_en) begin
        if (accum_cnt_clr) begin
          accum_cnt <= 0;
        end else if (accum_cnt_en) begin
          accum_cnt <= accum_cnt + 1;
        end
      end
    end
  end

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      data_buffer <= {$bits(data_buffer) {1'b0}};
    end else begin
      if (clk_en) begin
        if (din_vld) begin
          data_buffer <= {din, data_buffer[8*DIN_WIDTH-1:DIN_WIDTH]};
        end
      end
    end
  end

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      dout <= {$bits(dout) {1'b0}};
      dout_vld <= {$bits(dout_vld) {1'b0}};
    end else begin
      if (clk_en) begin
        if (accum_cnt_rch_max) begin
          dout <= {din, data_buffer[8*DIN_WIDTH-1:DIN_WIDTH]};
          dout_vld <= 1'b1;
        end else begin
          dout_vld <= 1'b0;
        end
      end
    end
  end

endmodule
