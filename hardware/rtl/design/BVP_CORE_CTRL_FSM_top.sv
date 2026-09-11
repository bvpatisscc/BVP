`timescale 1ns / 1ps

module BVP_CORE_CTRL_FSM_top (
    input  logic       accu2ofifo_pvld,
    input  logic       accu2pea_rdy,
    input  logic       arst_n,
    input  logic       axis2mem_frame_computing,
    input  logic       bias_relu_prdy_o,
    input  logic       clk,
    input  logic       clk_en,
    input  logic [7:0] csr_layer_cfg_fm_height,
    input  logic [7:0] csr_layer_cfg_fm_width,
    input  logic [7:0] csr_layer_cfg_ich_num,
    input  logic [7:0] csr_layer_cfg_och_num,
    input  logic [7:0] csr_layer_cfg_ofm_height,
    input  logic [7:0] csr_layer_cfg_ofm_width,
    input  logic       csr_layer_cfg_padding_enable,
    output logic       csr_layer_cfg_padding_enable_set,
    input  logic       csr_layer_cfg_pool_enable,
    input  logic [1:0] csr_layer_cfg_strideh,
    input  logic [1:0] csr_layer_cfg_stridew,
    input  logic [4:0] csr_model_cfg_layer_num,
    output logic       ctrl_bias_relu_out_row_done,
    output logic       ctrl_cur_layer_done,
    output logic       ctrl_enable_mem2axis,
    output logic       ctrl_fc_only_en,
    output logic       ctrl_first_wgt_vld,
    output logic       ctrl_flush_pe2obuf,
    output logic       ctrl_flush_pe_prev_out,
    output logic       ctrl_mem_in_bias_cnt_clr,
    output logic       ctrl_mem_in_fc_wgt_cnt_clr,
    output logic       ctrl_mem_in_wgt_addr_update,
    output logic       ctrl_mem_in_wgt_cnt_clr,
    output logic       ctrl_mem_inout_act_cnt_clr,
    output logic       ctrl_mem_inout_act_fc_gate_en,
    output logic       ctrl_mem_out_act_och_round_update,
    output logic       ctrl_ofifo_accu_stridew_valid,
    output logic       ctrl_ofifo_avail_for_ih,
    output logic       ctrl_pe_use_prev_out,
    output logic       ctrl_pea_en,
    output logic       ctrl_pool_en,
    output logic       ctrl_send_act_from_mem_en,
    output logic       ctrl_send_act_from_padding_en,
    output logic       ctrl_send_bias_from_mem_en,
    output logic       ctrl_send_fc_wgt_from_mem_en,
    output logic       ctrl_send_instr_from_mem_en,
    output logic       ctrl_send_wgt_from_mem_en,
    output logic       ctrl_send_wgt_from_padding_en,
    output logic       cur_ifm_done,
    output logic [2:0] dbg_out_cur_state,
    output logic       incnt_fm_height_done,
    output logic       incnt_ich_num_done,
    input  logic       mem_in_fc_wgt_vld,
    input  logic       mem_in_load_done_ack,
    input  logic       mem_in_wgt_vld,
    input  logic       ofifo_accu_rdy,
    input  logic       ofifo_rdy,
    input  logic       out_mem2axis_addr_clr,
    output logic [4:0] outcnt_layer_num,
    input  logic       pe2inbuf_rdy,
    input  logic       pea_act_recv,
    input  logic       pea_data_recv,
    input  logic       pea_pool_up_data_vld_i,
    input  logic       pec_data_pvld_o,
    output logic       pool_last_pixel
);
  logic [2:0] cur_state;
  logic [2:0] next_state;
  logic       fsm_st_idle_2newlayer;
  logic       fsm_st_intraloop_2newrow;
  logic       fsm_st_waitforochdone_2newlayer;
  logic       fsm_st_waitforochdone_2done;
  logic       fsm_st_newochrow_2nonconv;
  logic       ctrl_padding_enable_nxt;
  logic       incnt_cur_ifm_och_done;
  logic       intra_loop_done;
  logic       last_och_row_done;
  logic       och_row_done;
  logic       outcnt_fm_height_done;
  logic       outcnt_layer_num_done;
  logic       outcnt_layer_num_done_state;
  logic       outcnt_och_num_done;
  logic       outcnt_och_num_done_state;
  logic       ctrl_update_layer_req;
  logic       psum_accum_done;
  logic       ctrl_enable_mem2axis_clr;
  logic       ctrl_enable_mem2axis_set;
  logic       ctrl_enable_mem2axis_temp;

  localparam ST_IDLE = 3'd0;
  localparam ST_NEW_LAYER = 3'd1;
  localparam ST_NEW_OCH_ROW = 3'd2;
  localparam ST_PE_INTRA_LOOP = 3'd3;
  localparam ST_PE_INTER_SHIFT = 3'd4;
  localparam ST_NON_CONV = 3'd5;
  localparam ST_WAIT_FOR_OCH_DONE = 3'd6;
  localparam ST_DONE = 3'd7;

  always @(posedge clk or negedge arst_n) begin
    if (!arst_n) begin
      cur_state <= ST_IDLE;
    end else if (clk_en) begin
      cur_state[2:0] <= next_state[2:0];
    end
  end

  always @(*) begin
    next_state = cur_state;

    case (cur_state)
      ST_IDLE: begin
        if (axis2mem_frame_computing) begin
          next_state = ST_NEW_LAYER;
        end
      end

      ST_NEW_LAYER: begin
        if (mem_in_load_done_ack) begin
          next_state = ST_NEW_OCH_ROW;
        end
      end

      ST_NEW_OCH_ROW: begin
        if (!ctrl_pea_en) begin
          next_state = ST_NON_CONV;
        end else if (pea_data_recv) begin
          next_state = ST_PE_INTRA_LOOP;
        end
      end

      ST_PE_INTRA_LOOP: begin
        if (incnt_cur_ifm_och_done) begin
          next_state = ST_WAIT_FOR_OCH_DONE;
        end else if (och_row_done && !ctrl_fc_only_en) begin
          next_state = ST_NEW_OCH_ROW;
        end else if (intra_loop_done) begin
          next_state = ST_PE_INTER_SHIFT;
        end
      end

      ST_PE_INTER_SHIFT: begin
        if (incnt_cur_ifm_och_done) begin
          next_state = ST_WAIT_FOR_OCH_DONE;
        end else if (psum_accum_done) begin
          next_state = ST_PE_INTRA_LOOP;
        end
      end

      ST_NON_CONV: begin
        if (incnt_fm_height_done) begin
          next_state = ST_WAIT_FOR_OCH_DONE;
        end
      end

      ST_WAIT_FOR_OCH_DONE: begin
        if (outcnt_layer_num_done_state || outcnt_layer_num_done) begin
          next_state = ST_DONE;
        end else if (outcnt_och_num_done_state || outcnt_och_num_done) begin
          next_state = ST_NEW_LAYER;
        end
      end

      ST_DONE: begin
        if (!axis2mem_frame_computing) begin
          next_state = ST_IDLE;
        end
      end

    endcase
  end

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      dbg_out_cur_state <= {$bits(dbg_out_cur_state) {1'b0}};
    end else begin
      dbg_out_cur_state <= cur_state;
    end
  end

  assign fsm_st_idle_2newlayer = (cur_state == ST_IDLE) && (next_state == ST_NEW_LAYER);
  assign fsm_st_intraloop_2newrow = (cur_state == ST_PE_INTRA_LOOP) && (next_state == ST_NEW_OCH_ROW);
  assign fsm_st_waitforochdone_2newlayer = (cur_state == ST_WAIT_FOR_OCH_DONE) && (next_state == ST_NEW_LAYER);
  assign fsm_st_waitforochdone_2done = (cur_state == ST_WAIT_FOR_OCH_DONE) && (next_state == ST_DONE);
  assign fsm_st_newochrow_2nonconv = (cur_state == ST_NEW_OCH_ROW) && (next_state == ST_NON_CONV);

  BVP_CORE_CTRL_FSM_cnt u_FSM_cnt (
      .arst_n                          (arst_n),
      .clk                             (clk),
      .clk_en                          (clk_en),
      .cnt_wgt_vld_rst_i           (1'b0),
      .csr_layer_cfg_fm_height         (csr_layer_cfg_fm_height[7:0]),
      .csr_layer_cfg_fm_width          (csr_layer_cfg_fm_width[7:0]),
      .csr_layer_cfg_ich_num           (csr_layer_cfg_ich_num[7:0]),
      .csr_layer_cfg_och_num           (csr_layer_cfg_och_num[7:0]),
      .csr_layer_cfg_ofm_height        (csr_layer_cfg_ofm_height[7:0]),
      .csr_layer_cfg_ofm_width         (csr_layer_cfg_ofm_width[7:0]),
      .csr_layer_cfg_padding_enable    (csr_layer_cfg_padding_enable),
      .csr_layer_cfg_padding_enable_set(csr_layer_cfg_padding_enable_set),
      .csr_model_cfg_layer_num         (csr_model_cfg_layer_num[4:0]),
      .ctrl_fc_only_en                 (ctrl_fc_only_en),
      .ctrl_first_wgt_vld              (ctrl_first_wgt_vld),
      .ctrl_padding_enable_nxt         (ctrl_padding_enable_nxt),
      .ctrl_pea_en                     (ctrl_pea_en),
      .cur_ifm_done                    (cur_ifm_done),
      .fsm_st_newochrow_2nonconv       (fsm_st_newochrow_2nonconv),
      .fsm_st_waitforochdone_2done     (fsm_st_waitforochdone_2done),
      .fsm_st_waitforochdone_2newlayer (fsm_st_waitforochdone_2newlayer),
      .incnt_cur_ifm_och_done          (incnt_cur_ifm_och_done),
      .incnt_fm_height_done            (incnt_fm_height_done),
      .incnt_ich_num_done              (incnt_ich_num_done),
      .intra_loop_done                 (intra_loop_done),
      .last_och_row_done               (last_och_row_done),
      .mem_in_fc_wgt_vld               (mem_in_fc_wgt_vld),
      .mem_in_load_done_ack            (mem_in_load_done_ack),
      .mem_in_wgt_vld                  (mem_in_wgt_vld),
      .och_row_done                    (och_row_done),
      .out_mem2axis_addr_clr           (out_mem2axis_addr_clr),
      .outcnt_fm_height_done           (outcnt_fm_height_done),
      .outcnt_layer_num                (outcnt_layer_num[4:0]),
      .outcnt_layer_num_done           (outcnt_layer_num_done),
      .outcnt_layer_num_done_state     (outcnt_layer_num_done_state),
      .outcnt_och_num_done             (outcnt_och_num_done),
      .outcnt_och_num_done_state       (outcnt_och_num_done_state),
      .pe2inbuf_rdy                    (pe2inbuf_rdy),
      .pea_act_recv                    (pea_act_recv),
      .pea_pool_up_data_vld_i          (pea_pool_up_data_vld_i),
      .pec_data_pvld_o                 (pec_data_pvld_o),
      .pool_last_pixel                 (pool_last_pixel)
  );

  BVP_CORE_CTRL_FSM_out #(
      .ST_IDLE             (ST_IDLE),
      .ST_NEW_LAYER        (ST_NEW_LAYER),
      .ST_NEW_OCH_ROW      (ST_NEW_OCH_ROW),
      .ST_PE_INTRA_LOOP    (ST_PE_INTRA_LOOP),
      .ST_PE_INTER_SHIFT   (ST_PE_INTER_SHIFT),
      .ST_NON_CONV         (ST_NON_CONV),
      .ST_WAIT_FOR_OCH_DONE(ST_WAIT_FOR_OCH_DONE),
      .ST_DONE             (ST_DONE)
  ) u_FSM_out (
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
      .ctrl_flush_pe_prev_out       (ctrl_flush_pe_prev_out),
      .ctrl_ofifo_accu_stridew_valid(ctrl_ofifo_accu_stridew_valid),
      .ctrl_ofifo_avail_for_ih      (ctrl_ofifo_avail_for_ih),
      .ctrl_padding_enable_nxt      (ctrl_padding_enable_nxt),
      .ctrl_pe_use_prev_out         (ctrl_pe_use_prev_out),
      .ctrl_pea_en                  (ctrl_pea_en),
      .ctrl_send_act_from_mem_en    (ctrl_send_act_from_mem_en),
      .ctrl_send_act_from_padding_en(ctrl_send_act_from_padding_en),
      .ctrl_send_fc_wgt_from_mem_en (ctrl_send_fc_wgt_from_mem_en),
      .ctrl_send_wgt_from_mem_en    (ctrl_send_wgt_from_mem_en),
      .ctrl_send_wgt_from_padding_en(ctrl_send_wgt_from_padding_en),
      .ctrl_update_layer_req        (ctrl_update_layer_req),
      .cur_ifm_done                 (cur_ifm_done),
      .cur_state                    (cur_state[2:0]),
      .fsm_st_intraloop_2newrow     (fsm_st_intraloop_2newrow),
      .last_och_row_done            (last_och_row_done),
      .mem_in_load_done_ack         (mem_in_load_done_ack),
      .next_state                   (next_state[2:0]),
      .och_row_done                 (och_row_done),
      .ofifo_accu_rdy               (ofifo_accu_rdy),
      .ofifo_rdy                    (ofifo_rdy)
  );

  BVP_CORE_CTRL_FSM_layer_dec u_FSM_layer_dec (
      .csr_layer_cfg_padding_enable(csr_layer_cfg_padding_enable),
      .csr_layer_cfg_pool_enable   (csr_layer_cfg_pool_enable),
      .ctrl_fc_only_en             (ctrl_fc_only_en),
      .ctrl_pea_en                 (ctrl_pea_en),
      .ctrl_pool_en                (ctrl_pool_en)
  );

  assign psum_accum_done = ofifo_accu_rdy;
  assign ctrl_cur_layer_done = fsm_st_waitforochdone_2newlayer;
  assign ctrl_send_bias_from_mem_en = fsm_st_idle_2newlayer || (outcnt_fm_height_done && ctrl_pea_en);
  assign ctrl_send_instr_from_mem_en = ctrl_update_layer_req;

  assign ctrl_mem_in_wgt_addr_update = outcnt_fm_height_done && !outcnt_och_num_done_state;
  assign ctrl_mem_out_act_och_round_update = outcnt_fm_height_done && !outcnt_och_num_done_state;

  assign ctrl_mem_in_wgt_cnt_clr = fsm_st_waitforochdone_2done;
  assign ctrl_mem_in_fc_wgt_cnt_clr = fsm_st_waitforochdone_2done;
  assign ctrl_mem_in_bias_cnt_clr = fsm_st_waitforochdone_2done;
  assign ctrl_mem_inout_act_cnt_clr = outcnt_layer_num_done;

  assign ctrl_mem_inout_act_fc_gate_en = ctrl_fc_only_en && (next_state == ST_NEW_OCH_ROW);

  assign ctrl_enable_mem2axis_clr = out_mem2axis_addr_clr;
  assign ctrl_enable_mem2axis_set = outcnt_layer_num_done;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      ctrl_enable_mem2axis_temp <= {$bits(ctrl_enable_mem2axis_temp) {1'b0}};
    end else begin
      if (ctrl_enable_mem2axis_clr) begin
        ctrl_enable_mem2axis_temp <= 0;
      end else if (ctrl_enable_mem2axis_set) begin
        ctrl_enable_mem2axis_temp <= 1;
      end
    end
  end
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      ctrl_enable_mem2axis <= {$bits(ctrl_enable_mem2axis) {1'b0}};
    end else begin
      ctrl_enable_mem2axis <= ctrl_enable_mem2axis_temp;
    end
  end

endmodule
