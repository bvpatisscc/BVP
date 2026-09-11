`timescale 1ns / 1ps

module BVP_CORE_BSU_PEArray_accu #(
    parameter PE_DOUT_WIDTH  = 16,
    parameter PEA_DOUT_WIDTH = 3 * PE_DOUT_WIDTH
) (
    input  logic                      arst_n,
    input  logic                      clk,
    input  logic                      clk_en,
    input  logic [PEA_DOUT_WIDTH-1:0] din_pea0,
    input  logic [PEA_DOUT_WIDTH-1:0] din_pea1,
    input  logic                      dn_prdy_i,
    output logic                      dn_pvld_o,
    output logic [ PE_DOUT_WIDTH-1:0] dout_accu_row0,
    output logic [ PE_DOUT_WIDTH-1:0] dout_accu_row1,
    output logic [ PE_DOUT_WIDTH-1:0] dout_accu_row2,
    output logic                      up_rdy_o,
    input  logic                      up_vld_i
);
  logic                     up_data_recv;
  logic [PE_DOUT_WIDTH-1:0] din_pea0_row0_gated;
  logic [PE_DOUT_WIDTH-1:0] din_pea1_row0_gated;
  logic [PE_DOUT_WIDTH-1:0] din_pea0_row1_gated;
  logic [PE_DOUT_WIDTH-1:0] din_pea1_row1_gated;
  logic [PE_DOUT_WIDTH-1:0] din_pea0_row2_gated;
  logic [PE_DOUT_WIDTH-1:0] din_pea1_row2_gated;
  logic [PE_DOUT_WIDTH-1:0] dout_accu_row0_comb;
  logic [PE_DOUT_WIDTH-1:0] dout_accu_row1_comb;
  logic [PE_DOUT_WIDTH-1:0] dout_accu_row2_comb;
  logic [PE_DOUT_WIDTH-1:0] din_pea0_row0;
  logic [PE_DOUT_WIDTH-1:0] din_pea1_row0;
  logic [PE_DOUT_WIDTH-1:0] din_pea0_row1;
  logic [PE_DOUT_WIDTH-1:0] din_pea1_row1;
  logic [PE_DOUT_WIDTH-1:0] din_pea0_row2;
  logic [PE_DOUT_WIDTH-1:0] din_pea1_row2;

  assign up_rdy_o = ~(dn_pvld_o) || (dn_prdy_i);
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      dn_pvld_o <= {$bits(dn_pvld_o) {1'b0}};
    end else begin
      if (clk_en) begin
        if (up_rdy_o) dn_pvld_o <= up_vld_i;
      end
    end
  end

  assign up_data_recv = up_rdy_o && up_vld_i;
  assign din_pea0_row0_gated = up_data_recv ? din_pea0_row0 : {{PE_DOUT_WIDTH} {1'b0}};
  assign din_pea1_row0_gated = up_data_recv ? din_pea1_row0 : {{PE_DOUT_WIDTH} {1'b0}};
  assign din_pea0_row1_gated = up_data_recv ? din_pea0_row1 : {{PE_DOUT_WIDTH} {1'b0}};
  assign din_pea1_row1_gated = up_data_recv ? din_pea1_row1 : {{PE_DOUT_WIDTH} {1'b0}};
  assign din_pea0_row2_gated = up_data_recv ? din_pea0_row2 : {{PE_DOUT_WIDTH} {1'b0}};
  assign din_pea1_row2_gated = up_data_recv ? din_pea1_row2 : {{PE_DOUT_WIDTH} {1'b0}};

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      dout_accu_row0 <= {$bits(dout_accu_row0) {1'b0}};
      dout_accu_row1 <= {$bits(dout_accu_row1) {1'b0}};
      dout_accu_row2 <= {$bits(dout_accu_row2) {1'b0}};
    end else begin
      if (clk_en) begin
        if (up_data_recv) begin
          dout_accu_row0 <= dout_accu_row0_comb;
          dout_accu_row1 <= dout_accu_row1_comb;
          dout_accu_row2 <= dout_accu_row2_comb;
        end
      end
    end
  end

  BVP_CORE_BSU_unit_add_satu #(
      .DIN_WIDTH (PE_DOUT_WIDTH),
      .DOUT_WIDTH(PE_DOUT_WIDTH)
  ) u_PEA_Accu_0 (
      .add_din_0(din_pea0_row0_gated),
      .add_din_1(din_pea1_row0_gated),
      .dout     (dout_accu_row0_comb)
  );
  BVP_CORE_BSU_unit_add_satu #(
      .DIN_WIDTH (PE_DOUT_WIDTH),
      .DOUT_WIDTH(PE_DOUT_WIDTH)
  ) u_PEA_Accu_1 (
      .add_din_0(din_pea0_row1_gated),
      .add_din_1(din_pea1_row1_gated),
      .dout     (dout_accu_row1_comb)
  );
  BVP_CORE_BSU_unit_add_satu #(
      .DIN_WIDTH (PE_DOUT_WIDTH),
      .DOUT_WIDTH(PE_DOUT_WIDTH)
  ) u_PEA_Accu_2 (
      .add_din_0(din_pea0_row2_gated),
      .add_din_1(din_pea1_row2_gated),
      .dout     (dout_accu_row2_comb)
  );
  assign din_pea0_row0 = din_pea0[PE_DOUT_WIDTH-1:0];
  assign din_pea1_row0 = din_pea1[PE_DOUT_WIDTH-1:0];
  assign din_pea0_row1 = din_pea0[1*PE_DOUT_WIDTH+:PE_DOUT_WIDTH];
  assign din_pea1_row1 = din_pea1[1*PE_DOUT_WIDTH+:PE_DOUT_WIDTH];
  assign din_pea0_row2 = din_pea0[2*PE_DOUT_WIDTH+:PE_DOUT_WIDTH];
  assign din_pea1_row2 = din_pea1[2*PE_DOUT_WIDTH+:PE_DOUT_WIDTH];

endmodule
