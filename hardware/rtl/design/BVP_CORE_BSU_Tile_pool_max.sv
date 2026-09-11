`timescale 1ns / 1ps

module BVP_CORE_BSU_Tile_pool_max #(
    parameter NLAYER_ACT_WIDTH = 8
) (
    input  logic signed [NLAYER_ACT_WIDTH-1:0] din_0,
    input  logic signed [NLAYER_ACT_WIDTH-1:0] din_1,
    output logic signed [NLAYER_ACT_WIDTH-1:0] dout
);

  always_comb begin
    dout = din_0 > din_1 ? din_0 : din_1;
  end

endmodule
