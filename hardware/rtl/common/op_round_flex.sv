`timescale 1ns / 1ps

module op_round_flex #(
    parameter DIN_WIDTH = 16
) (
    input  signed [DIN_WIDTH-1:0] din,
    output signed [DIN_WIDTH-1:0] dout,

    input [4:0] truncate_frac_width,
    input [3:0] truncate_frac_width_m1
);

  logic signed [  DIN_WIDTH:0] temp;
  logic signed [  DIN_WIDTH:0] dout_temp;
  logic signed [DIN_WIDTH-1:0] round_bits;
  always_comb begin
    for (int i = 0; i < DIN_WIDTH; i++) begin
      if (i < truncate_frac_width_m1) begin
        round_bits[i] = !din[truncate_frac_width];
      end else if (i == truncate_frac_width_m1) begin
        round_bits[i] = din[truncate_frac_width];
      end else begin
        round_bits[i] = 1'b0;
      end
    end
  end

  assign temp = din + round_bits;

  assign dout_temp = (temp >>> (truncate_frac_width));
  assign dout = dout_temp[DIN_WIDTH-1:0];
endmodule
