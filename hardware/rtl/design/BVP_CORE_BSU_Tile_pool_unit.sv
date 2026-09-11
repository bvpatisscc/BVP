`timescale 1ns / 1ps

module BVP_CORE_BSU_Tile_pool_unit #(
    parameter POOL_WIDTH = 8
) (
    input logic signed [POOL_WIDTH-1:0] din_0,
    input logic signed [POOL_WIDTH-1:0] din_1,
    input logic cfg_pool_type,
    output logic signed [POOL_WIDTH-1:0] dout
);

  always_comb begin
    if (cfg_pool_type == 1'b0) begin
      dout = din_0 > din_1 ? din_0 : din_1;
    end else begin
      dout = din_0 + din_1;
    end
  end

endmodule
