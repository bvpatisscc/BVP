`timescale 1ns / 1ps

module BVP_CORE_CTRL_FSM_layer_dec (
    input  logic csr_layer_cfg_padding_enable,
    input  logic csr_layer_cfg_pool_enable,
    output logic ctrl_fc_only_en,
    output logic ctrl_pea_en,
    output logic ctrl_pool_en
);
  `include "bvp_layer_type_def.svh"

  logic [1:0] layer_sign;

  assign layer_sign = {csr_layer_cfg_padding_enable, csr_layer_cfg_pool_enable};

  always_comb begin
    case (layer_sign)
      `LAYER_FC: begin
        ctrl_pea_en     = 1'b1;
        ctrl_pool_en    = 1'b0;
        ctrl_fc_only_en = 1'b1;
      end
      `LAYER_POOL: begin
        ctrl_pea_en     = 1'b0;
        ctrl_pool_en    = 1'b1;
        ctrl_fc_only_en = 1'b0;
      end
      `LAYER_CONV: begin
        ctrl_pea_en     = 1'b1;
        ctrl_pool_en    = 1'b0;
        ctrl_fc_only_en = 1'b0;
      end
      `LAYER_CONVPOOL: begin
        ctrl_pea_en     = 1'b1;
        ctrl_pool_en    = 1'b1;
        ctrl_fc_only_en = 1'b0;
      end
      default: begin
        ctrl_pea_en     = 1'b0;
        ctrl_pool_en    = 1'b0;
        ctrl_fc_only_en = 1'b0;
      end
    endcase
  end

endmodule
