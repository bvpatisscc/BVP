`timescale 1ns / 1ps

module BVP_CORE_CTRL_FSM_out_pea (
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
    input  logic       ctrl_flush_pe2obuf_nxt,
    output logic       ctrl_ofifo_accu_stridew_valid,
    input  logic       ctrl_pea_en,
    output logic       cur_ifm_done,
    input  logic       fsm_st_intraloop_2newrow,
    input  logic       last_och_row_done,
    input  logic       och_row_done,
    input  logic       ofifo_accu_rdy,
    input  logic       ofifo_rdy
);
  logic       pe_pipe_cnt_clr_tmp;
  logic       pe_pipe_cnt_en;
  logic       pe_pipe_cnt_clr;
  logic [0:0] pe_pipe_cnt;
  logic       ctrl_pe_pipe_full_clr;
  logic       ctrl_pe_pipe_full_set;
  logic       ctrl_pe_pipe_full;
  logic       ctrl_flush_pe2obuf_nxt_en;
  logic       ofifo_accu_pipe_cnt_clr;
  logic       ofifo_accu_pipe_cnt_en;
  logic [0:0] ofifo_accu_pipe_cnt;
  logic       ctrl_ofifo_accu_full_clr;
  logic       ctrl_ofifo_accu_full_set;
  logic       ctrl_ofifo_accu_pipe_full;
  logic       och_row_done_1d;
  logic       last_och_row_done_1d;
  logic       och_row_done_2d;
  logic       last_och_row_done_2d;
  logic       och_row_done_3d;
  logic       och_row_done_4d;
  logic       och_row_done_5d;
  logic       ctrl_ofifo_accu_strideh_valid_1d;
  logic       ctrl_ofifo_accu_strideh_valid_2d;
  logic       strideh_cnt_clr;
  logic       strideh_cnt_en;
  logic       stridew_cnt_clr;
  logic       stridew_cnt_en;
  logic       ctrl_ofifo_accu_strideh_valid;
  logic [1:0] strideh_cnt;
  logic [1:0] stridew_cnt;

  assign pe_pipe_cnt_clr_tmp = pe_pipe_cnt == 1'd1 && pe_pipe_cnt_en;
  assign pe_pipe_cnt_en = ctrl_flush_pe2obuf_nxt && !ctrl_pe_pipe_full && (!ctrl_fc_only_en && ctrl_pea_en);

  assign pe_pipe_cnt_clr = pe_pipe_cnt_clr_tmp || ctrl_cur_layer_done;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      pe_pipe_cnt <= {$bits(pe_pipe_cnt) {1'b0}};
    end else begin
      if (clk_en) begin
        if (pe_pipe_cnt_clr) begin
          pe_pipe_cnt <= 0;
        end else if (pe_pipe_cnt_en) begin
          pe_pipe_cnt <= pe_pipe_cnt + 1;
        end
      end
    end
  end

  assign ctrl_pe_pipe_full_clr = fsm_st_intraloop_2newrow || ctrl_cur_layer_done;
  assign ctrl_pe_pipe_full_set = pe_pipe_cnt_clr_tmp;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      ctrl_pe_pipe_full <= {$bits(ctrl_pe_pipe_full) {1'b0}};
    end else begin
      if (clk_en) begin
        if (ctrl_pe_pipe_full_clr) begin
          ctrl_pe_pipe_full <= 0;
        end else if (ctrl_pe_pipe_full_set) begin
          ctrl_pe_pipe_full <= 1;
        end
      end
    end
  end

  assign ctrl_flush_pe2obuf_nxt_en = ctrl_flush_pe2obuf_nxt && (ctrl_pe_pipe_full || ctrl_fc_only_en);
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      ctrl_flush_pe2obuf <= {$bits(ctrl_flush_pe2obuf) {1'b0}};
    end else begin
      if (clk_en) begin
        ctrl_flush_pe2obuf <= ctrl_flush_pe2obuf_nxt_en;
      end
    end
  end

  assign ofifo_accu_pipe_cnt_clr = ofifo_accu_pipe_cnt == 1'd1 && ofifo_accu_pipe_cnt_en;
  assign ofifo_accu_pipe_cnt_en  = och_row_done_3d && !ctrl_ofifo_accu_pipe_full;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      ofifo_accu_pipe_cnt <= {$bits(ofifo_accu_pipe_cnt) {1'b0}};
    end else begin
      if (clk_en) begin
        if (ofifo_accu_pipe_cnt_clr) begin
          ofifo_accu_pipe_cnt <= 0;
        end else if (ofifo_accu_pipe_cnt_en) begin
          ofifo_accu_pipe_cnt <= ofifo_accu_pipe_cnt + 1;
        end
      end
    end
  end

  assign ctrl_ofifo_accu_full_clr = cur_ifm_done;
  assign ctrl_ofifo_accu_full_set = ofifo_accu_pipe_cnt_clr;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      ctrl_ofifo_accu_pipe_full <= {$bits(ctrl_ofifo_accu_pipe_full) {1'b0}};
    end else begin
      if (clk_en) begin
        if (ctrl_ofifo_accu_full_clr) begin
          ctrl_ofifo_accu_pipe_full <= 0;
        end else if (ctrl_ofifo_accu_full_set) begin
          ctrl_ofifo_accu_pipe_full <= 1;
        end
      end
    end
  end

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      och_row_done_1d <= {$bits(och_row_done_1d) {1'b0}};
      last_och_row_done_1d <= {$bits(last_och_row_done_1d) {1'b0}};
    end else begin
      if (clk_en) begin
        if (accu2pea_rdy) begin
          och_row_done_1d <= och_row_done;
          last_och_row_done_1d <= last_och_row_done;
        end
      end
    end
  end
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      och_row_done_2d <= {$bits(och_row_done_2d) {1'b0}};
      last_och_row_done_2d <= {$bits(last_och_row_done_2d) {1'b0}};
    end else begin
      if (clk_en) begin
        if (ofifo_accu_rdy) begin
          och_row_done_2d <= och_row_done_1d;
          last_och_row_done_2d <= last_och_row_done_1d;
        end
      end
    end
  end
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      och_row_done_3d <= {$bits(och_row_done_3d) {1'b0}};
      cur_ifm_done <= {$bits(cur_ifm_done) {1'b0}};
    end else begin
      if (clk_en) begin
        if (ofifo_rdy) begin
          och_row_done_3d <= och_row_done_2d;
          cur_ifm_done <= last_och_row_done_2d;
        end
      end
    end
  end

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      och_row_done_4d <= {$bits(och_row_done_4d) {1'b0}};
      och_row_done_5d <= {$bits(och_row_done_5d) {1'b0}};
      ctrl_ofifo_accu_strideh_valid_1d <= {$bits(ctrl_ofifo_accu_strideh_valid_1d) {1'b0}};
      ctrl_ofifo_accu_strideh_valid_2d <= {$bits(ctrl_ofifo_accu_strideh_valid_2d) {1'b0}};
    end else begin
      if (clk_en) begin
        if (bias_relu_prdy_o) begin
          och_row_done_4d <= och_row_done_3d;
          och_row_done_5d <= och_row_done_4d;
          ctrl_ofifo_accu_strideh_valid_1d <= ctrl_ofifo_accu_strideh_valid;
          ctrl_ofifo_accu_strideh_valid_2d <= ctrl_ofifo_accu_strideh_valid_1d;
        end
      end
    end
  end

  assign ctrl_bias_relu_out_row_done = ctrl_ofifo_accu_strideh_valid_2d && och_row_done_5d;

  assign strideh_cnt_clr = ((strideh_cnt == csr_layer_cfg_strideh) && strideh_cnt_en) || cur_ifm_done;
  assign strideh_cnt_en = och_row_done_3d && ctrl_ofifo_accu_pipe_full;
  assign stridew_cnt_clr = ((stridew_cnt == csr_layer_cfg_stridew) && stridew_cnt_en) || cur_ifm_done;
  assign stridew_cnt_en = accu2ofifo_pvld && ctrl_ofifo_accu_strideh_valid;

  assign ctrl_ofifo_accu_strideh_valid = (strideh_cnt == 0) && ctrl_ofifo_accu_pipe_full;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      strideh_cnt <= {$bits(strideh_cnt) {1'b0}};
    end else begin
      if (clk_en) begin
        if (strideh_cnt_clr) begin
          strideh_cnt <= 0;
        end else if (strideh_cnt_en) begin
          strideh_cnt <= strideh_cnt + 1;
        end
      end
    end
  end

  assign ctrl_ofifo_accu_stridew_valid = (stridew_cnt == 0) && ctrl_ofifo_accu_strideh_valid;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      stridew_cnt <= {$bits(stridew_cnt) {1'b0}};
    end else begin
      if (clk_en) begin
        if (stridew_cnt_clr) begin
          stridew_cnt <= 0;
        end else if (stridew_cnt_en) begin
          stridew_cnt <= stridew_cnt + 1;
        end
      end
    end
  end

endmodule
