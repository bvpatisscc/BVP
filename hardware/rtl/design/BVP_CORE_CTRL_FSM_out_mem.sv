`timescale 1ns / 1ps

module BVP_CORE_CTRL_FSM_out_mem (
    input  logic arst_n,
    input  logic clk,
    input  logic clk_en,
    input  logic ctrl_fc_only_en,
    input  logic ctrl_flush_pe_prev_out,
    output logic ctrl_ofifo_avail_for_ih,
    input  logic ctrl_padding_enable_nxt,
    input  logic ctrl_pea_en,
    output logic ctrl_send_act_from_mem_en,
    output logic ctrl_send_act_from_padding_en,
    input  logic ctrl_send_act_wgt_en_nxt,
    output logic ctrl_send_fc_wgt_from_mem_en,
    output logic ctrl_send_wgt_from_mem_en,
    output logic ctrl_send_wgt_from_padding_en,
    input  logic cur_ifm_done,
    input  logic mem_in_load_done_ack
);
  logic       ctrl_send_act_en_nxt;
  logic       act_send_cnt_en;
  logic       act_send_cnt_clr;
  logic [0:0] act_send_cnt;
  logic       ctrl_send_act_wgt_en_nxt_neg;
  logic       ctrl_send_act_from_mem_en_nxt;
  logic       ctrl_send_wgt_from_mem_en_nxt;
  logic       ctrl_send_fc_wgt_from_mem_en_nxt;
  logic       ctrl_padding_enable_nxt_tmp;
  logic       ctrl_send_act_from_padding_en_nxt;
  logic       ctrl_send_wgt_from_padding_en_nxt;
  logic       ofifo_avail_for_ih_clr;
  logic       ofifo_avail_for_ih_set;

  assign ctrl_send_act_en_nxt = (act_send_cnt == 0) && ctrl_send_act_wgt_en_nxt;

  assign act_send_cnt_en = ctrl_send_act_wgt_en_nxt;
  assign act_send_cnt_clr = ctrl_send_act_wgt_en_nxt_neg;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      act_send_cnt <= {$bits(act_send_cnt) {1'b0}};
    end else begin
      if (clk_en) begin
        if (act_send_cnt_clr) begin
          act_send_cnt <= 0;
        end else if (act_send_cnt_en) begin
          act_send_cnt <= act_send_cnt + 1;
        end
      end
    end
  end

  assign ctrl_send_act_wgt_en_nxt_neg = !ctrl_send_act_wgt_en_nxt && ctrl_send_wgt_from_mem_en;

  assign ctrl_send_act_from_mem_en_nxt = ctrl_send_act_en_nxt && !ctrl_padding_enable_nxt && !mem_in_load_done_ack;
  assign ctrl_send_wgt_from_mem_en_nxt = ctrl_send_act_wgt_en_nxt && !ctrl_padding_enable_nxt && ctrl_pea_en && !ctrl_fc_only_en;
  assign ctrl_send_fc_wgt_from_mem_en_nxt = ctrl_send_act_wgt_en_nxt && !ctrl_padding_enable_nxt && ctrl_fc_only_en;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      ctrl_send_act_from_mem_en <= {$bits(ctrl_send_act_from_mem_en) {1'b0}};
      ctrl_send_wgt_from_mem_en <= {$bits(ctrl_send_wgt_from_mem_en) {1'b0}};
      ctrl_send_fc_wgt_from_mem_en <= {$bits(ctrl_send_fc_wgt_from_mem_en) {1'b0}};
    end else begin
      if (clk_en) begin
        ctrl_send_act_from_mem_en <= ctrl_send_act_from_mem_en_nxt;
        ctrl_send_wgt_from_mem_en <= ctrl_send_wgt_from_mem_en_nxt;
        ctrl_send_fc_wgt_from_mem_en <= ctrl_send_fc_wgt_from_mem_en_nxt;
      end
    end
  end

  assign ctrl_padding_enable_nxt_tmp = ctrl_fc_only_en ? (ctrl_padding_enable_nxt && !mem_in_load_done_ack) : ctrl_padding_enable_nxt;
  assign ctrl_send_act_from_padding_en_nxt = ctrl_send_act_en_nxt && ctrl_padding_enable_nxt_tmp;
  assign ctrl_send_wgt_from_padding_en_nxt = ctrl_send_act_wgt_en_nxt && ctrl_padding_enable_nxt_tmp;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      ctrl_send_act_from_padding_en <= {$bits(ctrl_send_act_from_padding_en) {1'b0}};
      ctrl_send_wgt_from_padding_en <= {$bits(ctrl_send_wgt_from_padding_en) {1'b0}};
    end else begin
      if (clk_en) begin
        ctrl_send_act_from_padding_en <= ctrl_send_act_from_padding_en_nxt;
        ctrl_send_wgt_from_padding_en <= ctrl_send_wgt_from_padding_en_nxt;
      end
    end
  end

  assign ofifo_avail_for_ih_clr = cur_ifm_done;
  assign ofifo_avail_for_ih_set = ctrl_flush_pe_prev_out && !ctrl_fc_only_en;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      ctrl_ofifo_avail_for_ih <= {$bits(ctrl_ofifo_avail_for_ih) {1'b0}};
    end else begin
      if (clk_en) begin
        if (ofifo_avail_for_ih_clr) begin
          ctrl_ofifo_avail_for_ih <= 0;
        end else if (ofifo_avail_for_ih_set) begin
          ctrl_ofifo_avail_for_ih <= 1;
        end
      end
    end
  end

endmodule
