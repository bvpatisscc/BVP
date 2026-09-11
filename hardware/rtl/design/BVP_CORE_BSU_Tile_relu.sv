`timescale 1ns / 1ps

module BVP_CORE_BSU_Tile_relu #(
    parameter DATA_WIDTH = 16
) (
    input logic signed [DATA_WIDTH-1:0] din,
    input logic relu_en,
    output logic signed [DATA_WIDTH-1:0] dout
);

  always_comb begin
    if (relu_en) begin
      dout = din[DATA_WIDTH-1] ? {DATA_WIDTH{1'b0}} : din;
    end else begin
      dout = din;
    end
  end

endmodule
