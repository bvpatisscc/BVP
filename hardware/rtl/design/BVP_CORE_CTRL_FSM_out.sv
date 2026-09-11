`timescale 1ns / 1ps

module BVP_CORE_CTRL_FSM_out #(
    parameter ST_IDLE = 3'd0,
    parameter ST_NEW_LAYER = 3'd1,
    parameter ST_NEW_OCH_ROW = 3'd2,
    parameter ST_PE_INTRA_LOOP = 3'd3,
    parameter ST_PE_INTER_SHIFT = 3'd4,
    parameter ST_NON_CONV = 3'd5,
    parameter ST_WAIT_FOR_OCH_DONE = 3'd6,
    parameter ST_DONE = 3'd7
) (
    input  logic       accu2ofifo_pvld,
    input  logic       accu2pea_rdy,
    input  logic       arst_n,
    input  logic       bias_relu_prdy_o,
    input  logic       clk,
    input  logic       clk_en,
    input  logic [1:0] csr_layer_cfg_strideh,
    input  logic [1:0] csr_layer_cfg_stridew,
    output logic       ctrl_bias_relu_out_row_done,
    input  logic       ctrl_cur_layer_done,
    input  logic       ctrl_fc_only_en,
    output logic       ctrl_flush_pe2obuf,
    output logic       ctrl_flush_pe_prev_out,
    output logic       ctrl_ofifo_accu_stridew_valid,
    output logic       ctrl_ofifo_avail_for_ih,
    input  logic       ctrl_padding_enable_nxt,
    output logic       ctrl_pe_use_prev_out,
    input  logic       ctrl_pea_en,
    output logic       ctrl_send_act_from_mem_en,
    output logic       ctrl_send_act_from_padding_en,
    output logic       ctrl_send_fc_wgt_from_mem_en,
    output logic       ctrl_send_wgt_from_mem_en,
    output logic       ctrl_send_wgt_from_padding_en,
    output logic       ctrl_update_layer_req,
    output logic       cur_ifm_done,
    input  logic [2:0] cur_state,
    input  logic       fsm_st_intraloop_2newrow,
    input  logic       last_och_row_done,
    input  logic       mem_in_load_done_ack,
    input  logic [2:0] next_state,
    input  logic       och_row_done,
    input  logic       ofifo_accu_rdy,
    input  logic       ofifo_rdy
);
  logic ctrl_update_layer_req_nxt;
  logic ctrl_flush_pe2obuf_nxt;
  logic ctrl_pe_use_prev_out_nxt;
  logic ctrl_flush_pe_prev_out_nxt;
  logic ctrl_send_act_wgt_en_nxt;

  BVP_CORE_CTRL_FSM_out_mem u_fsm_out_mem (
      .arst_n                       (arst_n),
      .clk                          (clk),
      .clk_en                       (clk_en),
      .ctrl_fc_only_en              (ctrl_fc_only_en),
      .ctrl_flush_pe_prev_out       (ctrl_flush_pe_prev_out),
      .ctrl_ofifo_avail_for_ih      (ctrl_ofifo_avail_for_ih),
      .ctrl_padding_enable_nxt      (ctrl_padding_enable_nxt),
      .ctrl_pea_en                  (ctrl_pea_en),
      .ctrl_send_act_from_mem_en    (ctrl_send_act_from_mem_en),
      .ctrl_send_act_from_padding_en(ctrl_send_act_from_padding_en),
      .ctrl_send_act_wgt_en_nxt     (ctrl_send_act_wgt_en_nxt),
      .ctrl_send_fc_wgt_from_mem_en (ctrl_send_fc_wgt_from_mem_en),
      .ctrl_send_wgt_from_mem_en    (ctrl_send_wgt_from_mem_en),
      .ctrl_send_wgt_from_padding_en(ctrl_send_wgt_from_padding_en),
      .cur_ifm_done                 (cur_ifm_done),
      .mem_in_load_done_ack         (mem_in_load_done_ack)
  );
  BVP_CORE_CTRL_FSM_out_pea u_fsm_out_pea (
      .accu2ofifo_pvld              (accu2ofifo_pvld),
      .accu2pea_rdy                 (accu2pea_rdy),
      .arst_n                       (arst_n),
      .bias_relu_prdy_o             (bias_relu_prdy_o),
      .clk                          (clk),
      .clk_en                       (clk_en),
      .csr_layer_cfg_strideh        (csr_layer_cfg_strideh[1:0]),
      .csr_layer_cfg_stridew        (csr_layer_cfg_stridew[1:0]),
      .ctrl_bias_relu_out_row_done  (ctrl_bias_relu_out_row_done),
      .ctrl_cur_layer_done          (ctrl_cur_layer_done),
      .ctrl_fc_only_en              (ctrl_fc_only_en),
      .ctrl_flush_pe2obuf           (ctrl_flush_pe2obuf),
      .ctrl_flush_pe2obuf_nxt       (ctrl_flush_pe2obuf_nxt),
      .ctrl_ofifo_accu_stridew_valid(ctrl_ofifo_accu_stridew_valid),
      .ctrl_pea_en                  (ctrl_pea_en),
      .cur_ifm_done                 (cur_ifm_done),
      .fsm_st_intraloop_2newrow     (fsm_st_intraloop_2newrow),
      .last_och_row_done            (last_och_row_done),
      .och_row_done                 (och_row_done),
      .ofifo_accu_rdy               (ofifo_accu_rdy),
      .ofifo_rdy                    (ofifo_rdy)
  );

  always_comb begin
    ctrl_update_layer_req_nxt = 1'b0;
    ctrl_flush_pe2obuf_nxt = 1'b0;
    ctrl_pe_use_prev_out_nxt = 1'b0;
    ctrl_flush_pe_prev_out_nxt = 1'b0;
    ctrl_send_act_wgt_en_nxt = 1'b0;

    case (next_state)
      ST_IDLE: begin

      end

      ST_NEW_LAYER: begin
        ctrl_update_layer_req_nxt = 1'b1;
      end

      ST_NEW_OCH_ROW: begin
        ctrl_send_act_wgt_en_nxt = 1'b1;
        case (cur_state)
          ST_PE_INTRA_LOOP: begin
            ctrl_flush_pe2obuf_nxt = 1'b1;
            ctrl_flush_pe_prev_out_nxt = 1'b1;
          end
          default: begin

          end
        endcase

      end

      ST_PE_INTRA_LOOP: begin
        ctrl_pe_use_prev_out_nxt = 1'b1;
        ctrl_send_act_wgt_en_nxt = 1'b1;
      end

      ST_PE_INTER_SHIFT: begin
        ctrl_flush_pe2obuf_nxt   = 1'b1;
        ctrl_send_act_wgt_en_nxt = 1'b1;
      end

      ST_NON_CONV: begin
        ctrl_send_act_wgt_en_nxt = 1'b1;
      end

      ST_WAIT_FOR_OCH_DONE: begin
      end

      ST_DONE: begin
      end

      default: begin

      end
    endcase
  end
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      ctrl_update_layer_req  <= {$bits(ctrl_update_layer_req) {1'b0}};
      ctrl_pe_use_prev_out   <= {$bits(ctrl_pe_use_prev_out) {1'b0}};
      ctrl_flush_pe_prev_out <= {$bits(ctrl_flush_pe_prev_out) {1'b0}};
    end else begin
      if (clk_en) begin
        ctrl_update_layer_req  <= ctrl_update_layer_req_nxt;
        ctrl_pe_use_prev_out   <= ctrl_pe_use_prev_out_nxt;
        ctrl_flush_pe_prev_out <= ctrl_flush_pe_prev_out_nxt;
      end
    end
  end

endmodule
