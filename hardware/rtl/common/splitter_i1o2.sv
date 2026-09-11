`timescale 1ns / 1ps

module splitter_i1o2 #(
    parameter DIN_WIDTH  = 16,
    parameter DOUT_WIDTH = 8
) (
    input  logic                  arst_n,
    input  logic                  clk,
    input  logic                  clk_en,
    input  logic [ DIN_WIDTH-1:0] din,
    input  logic                  din_vld,
    output logic [DOUT_WIDTH-1:0] dout,
    output logic                  dout_vld
);
  logic select;

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      select <= {$bits(select) {1'b0}};
    end else begin
      if (clk_en) begin
        if (din_vld) begin
          select <= 1'b1;
        end else if (select) begin
          select <= 1'b0;
        end
      end
    end
  end

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      dout <= {$bits(dout) {1'b0}};
    end else begin
      if (clk_en) begin
        if (!select) begin
          dout <= din[DOUT_WIDTH-1:0];
        end else begin
          dout <= din[DIN_WIDTH-1:DOUT_WIDTH];
        end
      end
    end
  end

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      dout_vld <= {$bits(dout_vld) {1'b0}};
    end else begin
      if (clk_en) begin
        dout_vld <= din_vld | select;
      end
    end
  end

endmodule
