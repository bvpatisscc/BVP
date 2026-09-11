`timescale 1ns / 1ps

module BVP_CORE_CTRL_FSM_cnt (
    input  logic       arst_n,
    input  logic       clk,
    input  logic       clk_en,
    input  logic       cnt_wgt_vld_rst_i,
    input  logic [7:0] csr_layer_cfg_fm_height,
    input  logic [7:0] csr_layer_cfg_fm_width,
    input  logic [7:0] csr_layer_cfg_ich_num,
    input  logic [7:0] csr_layer_cfg_och_num,
    input  logic [7:0] csr_layer_cfg_ofm_height,
    input  logic [7:0] csr_layer_cfg_ofm_width,
    input  logic       csr_layer_cfg_padding_enable,
    output logic       csr_layer_cfg_padding_enable_set,
    input  logic [4:0] csr_model_cfg_layer_num,
    input  logic       ctrl_fc_only_en,
    output logic       ctrl_first_wgt_vld,
    output logic       ctrl_padding_enable_nxt,
    input  logic       ctrl_pea_en,
    input  logic       cur_ifm_done,
    input  logic       fsm_st_newochrow_2nonconv,
    input  logic       fsm_st_waitforochdone_2done,
    input  logic       fsm_st_waitforochdone_2newlayer,
    output logic       incnt_cur_ifm_och_done,
    output logic       incnt_fm_height_done,
    output logic       incnt_ich_num_done,
    output logic       intra_loop_done,
    output logic       last_och_row_done,
    input  logic       mem_in_fc_wgt_vld,
    input  logic       mem_in_load_done_ack,
    input  logic       mem_in_wgt_vld,
    output logic       och_row_done,
    input  logic       out_mem2axis_addr_clr,
    output logic       outcnt_fm_height_done,
    output logic [4:0] outcnt_layer_num,
    output logic       outcnt_layer_num_done,
    output logic       outcnt_layer_num_done_state,
    output logic       outcnt_och_num_done,
    output logic       outcnt_och_num_done_state,
    input  logic       pe2inbuf_rdy,
    input  logic       pea_act_recv,
    input  logic       pea_pool_up_data_vld_i,
    input  logic       pec_data_pvld_o,
    output logic       pool_last_pixel
);

  logic       incnt_ich_num_done_1d;
  logic       incnt_ich_num_done_2d;
  logic       incnt_ich_num_done_3d;
  logic       incnt_fm_height_done_1d;
  logic       incnt_fm_height_done_2d;
  logic       incnt_fm_height_done_3d;
  logic       incnt_fm_width_done_1d;
  logic       incnt_fm_width_done_2d;
  logic       incnt_fm_width_done_3d;
  logic [8:0] padded_csr_layer_cfg_fm_width;
  logic [8:0] padded_csr_layer_cfg_fm_height;
  logic       ctrl_padding_enable_nxt_tmp;
  logic       incnt_ich_num_rst;
  logic       incnt_ich_num_en;
  logic [7:0] incnt_ich_num_max;
  logic [7:0] incnt_ich_num;
  logic       incnt_fm_width_rst;
  logic       incnt_fm_width_en;
  logic       incnt_fm_width_done;
  logic [8:0] incnt_fm_width;
  logic       incnt_fm_height_rst;
  logic       incnt_fm_height_en;
  logic [8:0] incnt_fm_height;
  logic       mem_in_wgt_vld_en;
  logic       cnt_wgt_vld_rst;
  logic       cnt_wgt_vld;
  logic       incnt_cur_ifm_och_rst;
  logic       incnt_cur_ifm_och_en;
  logic [4:0] incnt_cur_ifm_och;
  logic       outcnt_fm_width_rst;
  logic       outcnt_fm_width_en;
  logic       outcnt_fm_width_done;
  logic [7:0] outcnt_fm_width;
  logic       outcnt_fm_height_rst;
  logic       outcnt_fm_height_en;
  logic [7:0] outcnt_fm_height;
  logic       outcnt_och_num_rst;
  logic       outcnt_och_num_en;
  logic [7:0] outcnt_och_num;
  logic       outcnt_och_num_done_state_clr;
  logic       outcnt_och_num_done_state_set;
  logic       outcnt_layer_num_rst;
  logic       outcnt_layer_num_en;
  logic       outcnt_layer_num_done_state_clr;
  logic       outcnt_layer_num_done_state_set;

  assign intra_loop_done   = ctrl_fc_only_en ? incnt_ich_num_done_1d : incnt_ich_num_done_3d;
  assign last_och_row_done = ctrl_fc_only_en ? incnt_fm_height_done_1d : incnt_fm_height_done_3d;
  assign och_row_done      = ctrl_fc_only_en ? incnt_fm_width_done_1d : incnt_fm_width_done_3d;

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      incnt_ich_num_done_1d <= {$bits(incnt_ich_num_done_1d) {1'b0}};
      incnt_ich_num_done_2d <= {$bits(incnt_ich_num_done_2d) {1'b0}};
      incnt_ich_num_done_3d <= {$bits(incnt_ich_num_done_3d) {1'b0}};
    end else begin
      if (clk_en) begin
        if (pe2inbuf_rdy && ctrl_pea_en) begin
          incnt_ich_num_done_1d <= incnt_ich_num_done;
          incnt_ich_num_done_2d <= incnt_ich_num_done_1d;
          incnt_ich_num_done_3d <= incnt_ich_num_done_2d;
        end
      end
    end
  end

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      incnt_fm_height_done_1d <= {$bits(incnt_fm_height_done_1d) {1'b0}};
      incnt_fm_height_done_2d <= {$bits(incnt_fm_height_done_2d) {1'b0}};
      incnt_fm_height_done_3d <= {$bits(incnt_fm_height_done_3d) {1'b0}};
    end else begin
      if (clk_en) begin
        if (pe2inbuf_rdy && ctrl_pea_en) begin
          incnt_fm_height_done_1d <= incnt_fm_height_done;
          incnt_fm_height_done_2d <= incnt_fm_height_done_1d;
          incnt_fm_height_done_3d <= incnt_fm_height_done_2d;
        end
      end
    end
  end

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      incnt_fm_width_done_1d <= {$bits(incnt_fm_width_done_1d) {1'b0}};
      incnt_fm_width_done_2d <= {$bits(incnt_fm_width_done_2d) {1'b0}};
      incnt_fm_width_done_3d <= {$bits(incnt_fm_width_done_3d) {1'b0}};
    end else begin
      if (clk_en) begin
        if (pe2inbuf_rdy && ctrl_pea_en) begin
          incnt_fm_width_done_1d <= incnt_fm_width_done;
          incnt_fm_width_done_2d <= incnt_fm_width_done_1d;
          incnt_fm_width_done_3d <= incnt_fm_width_done_2d;
        end
      end
    end
  end

  assign padded_csr_layer_cfg_fm_width = csr_layer_cfg_padding_enable ? csr_layer_cfg_fm_width + 8'd2 : {1'b0,csr_layer_cfg_fm_width};
  assign padded_csr_layer_cfg_fm_height = csr_layer_cfg_padding_enable ? csr_layer_cfg_fm_height + 8'd2 : {1'b0,csr_layer_cfg_fm_height};

  assign ctrl_padding_enable_nxt_tmp = (incnt_fm_width == 0) || (incnt_fm_width == padded_csr_layer_cfg_fm_width) ||
                        (incnt_fm_height == 0) || (incnt_fm_height == padded_csr_layer_cfg_fm_height);

  assign ctrl_padding_enable_nxt = csr_layer_cfg_padding_enable && ctrl_padding_enable_nxt_tmp;

  assign csr_layer_cfg_padding_enable_set = out_mem2axis_addr_clr && !csr_layer_cfg_padding_enable;

  assign pool_last_pixel = (incnt_fm_width == padded_csr_layer_cfg_fm_width) && (incnt_fm_height == padded_csr_layer_cfg_fm_height);

  assign incnt_ich_num_rst = incnt_ich_num_done || fsm_st_waitforochdone_2newlayer || fsm_st_newochrow_2nonconv || fsm_st_waitforochdone_2done;
  assign incnt_ich_num_en = ctrl_pea_en ? (pea_act_recv && !mem_in_load_done_ack) : pea_pool_up_data_vld_i;
  assign incnt_ich_num_max = ctrl_pea_en ? (csr_layer_cfg_ich_num >> 1) : csr_layer_cfg_ich_num;
  assign incnt_ich_num_done = (incnt_ich_num == incnt_ich_num_max) && incnt_ich_num_en;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      incnt_ich_num <= {$bits(incnt_ich_num) {1'b0}};
    end else begin
      if (incnt_ich_num_rst) begin
        incnt_ich_num <= 0;
      end else if (incnt_ich_num_en) begin
        incnt_ich_num <= incnt_ich_num + 1;
      end
    end
  end

  assign incnt_fm_width_rst = incnt_fm_width_done || fsm_st_waitforochdone_2newlayer;
  assign incnt_fm_width_en = incnt_ich_num_done;

  assign incnt_fm_width_done = (incnt_fm_width == padded_csr_layer_cfg_fm_width) && incnt_fm_width_en;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      incnt_fm_width <= {$bits(incnt_fm_width) {1'b0}};
    end else begin
      if (incnt_fm_width_rst) begin
        incnt_fm_width <= 0;
      end else if (incnt_fm_width_en) begin
        incnt_fm_width <= incnt_fm_width + 1;
      end
    end
  end

  assign incnt_fm_height_rst = incnt_fm_height_done;
  assign incnt_fm_height_en = incnt_fm_width_done;

  assign incnt_fm_height_done = ((incnt_fm_height == padded_csr_layer_cfg_fm_height) && incnt_fm_height_en);
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      incnt_fm_height <= {$bits(incnt_fm_height) {1'b0}};
    end else begin
      if (incnt_fm_height_rst) begin
        incnt_fm_height <= 0;
      end else if (incnt_fm_height_en) begin
        incnt_fm_height <= incnt_fm_height + 1;
      end
    end
  end

  assign mem_in_wgt_vld_en = mem_in_wgt_vld || mem_in_fc_wgt_vld;
  assign ctrl_first_wgt_vld = mem_in_wgt_vld_en && cnt_wgt_vld == 0;
  assign cnt_wgt_vld_rst = cnt_wgt_vld_rst_i;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      cnt_wgt_vld <= {$bits(cnt_wgt_vld) {1'b0}};
    end else begin
      if (clk_en) begin
        if (cnt_wgt_vld_rst) begin
          cnt_wgt_vld <= 0;
        end else if (mem_in_wgt_vld_en) begin
          cnt_wgt_vld <= cnt_wgt_vld + 1;
        end
      end
    end
  end

  assign incnt_cur_ifm_och_rst = incnt_cur_ifm_och_done;
  assign incnt_cur_ifm_och_en = cur_ifm_done;
  assign incnt_cur_ifm_och_done  = (incnt_cur_ifm_och == (csr_layer_cfg_och_num) >> 3) && incnt_cur_ifm_och_en;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      incnt_cur_ifm_och <= {$bits(incnt_cur_ifm_och) {1'b0}};
    end else begin
      if (incnt_cur_ifm_och_rst) begin
        incnt_cur_ifm_och <= 0;
      end else if (incnt_cur_ifm_och_en) begin
        incnt_cur_ifm_och <= incnt_cur_ifm_och + 1;
      end
    end
  end

  assign outcnt_fm_width_rst  = outcnt_fm_width_done;
  assign outcnt_fm_width_en   = pec_data_pvld_o;

  assign outcnt_fm_width_done = (outcnt_fm_width == csr_layer_cfg_ofm_width) && outcnt_fm_width_en;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      outcnt_fm_width <= {$bits(outcnt_fm_width) {1'b0}};
    end else begin
      if (outcnt_fm_width_rst) begin
        outcnt_fm_width <= 0;
      end else if (outcnt_fm_width_en) begin
        outcnt_fm_width <= outcnt_fm_width + 1;
      end
    end
  end

  assign outcnt_fm_height_rst = outcnt_fm_height_done;
  assign outcnt_fm_height_en = outcnt_fm_width_done;

  assign outcnt_fm_height_done = (outcnt_fm_height == csr_layer_cfg_ofm_height) && outcnt_fm_height_en;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      outcnt_fm_height <= {$bits(outcnt_fm_height) {1'b0}};
    end else begin
      if (outcnt_fm_height_rst) begin
        outcnt_fm_height <= 0;
      end else if (outcnt_fm_height_en) begin
        outcnt_fm_height <= outcnt_fm_height + 1;
      end
    end
  end

  assign outcnt_och_num_rst = outcnt_och_num_done;
  assign outcnt_och_num_en = outcnt_fm_height_done;
  assign outcnt_och_num_done  = (outcnt_och_num == (csr_layer_cfg_och_num) >> 3) && outcnt_och_num_en;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      outcnt_och_num <= {$bits(outcnt_och_num) {1'b0}};
    end else begin
      if (outcnt_och_num_rst) begin
        outcnt_och_num <= 0;
      end else if (outcnt_och_num_en) begin
        outcnt_och_num <= outcnt_och_num + 1;
      end
    end
  end

  assign outcnt_och_num_done_state_clr = fsm_st_waitforochdone_2newlayer || fsm_st_waitforochdone_2done;
  assign outcnt_och_num_done_state_set = outcnt_och_num_done;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      outcnt_och_num_done_state <= {$bits(outcnt_och_num_done_state) {1'b0}};
    end else begin
      if (clk_en) begin
        if (outcnt_och_num_done_state_clr) begin
          outcnt_och_num_done_state <= 0;
        end else if (outcnt_och_num_done_state_set) begin
          outcnt_och_num_done_state <= 1;
        end
      end
    end
  end

  assign outcnt_layer_num_rst = outcnt_layer_num_done;
  assign outcnt_layer_num_en = outcnt_och_num_done;

  assign outcnt_layer_num_done = (outcnt_layer_num == csr_model_cfg_layer_num) && outcnt_layer_num_en;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      outcnt_layer_num <= {$bits(outcnt_layer_num) {1'b0}};
    end else begin
      if (outcnt_layer_num_rst) begin
        outcnt_layer_num <= 0;
      end else if (outcnt_layer_num_en) begin
        outcnt_layer_num <= outcnt_layer_num + 1;
      end
    end
  end

  assign outcnt_layer_num_done_state_clr = fsm_st_waitforochdone_2done;
  assign outcnt_layer_num_done_state_set = outcnt_layer_num_done;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      outcnt_layer_num_done_state <= {$bits(outcnt_layer_num_done_state) {1'b0}};
    end else begin
      if (clk_en) begin
        if (outcnt_layer_num_done_state_clr) begin
          outcnt_layer_num_done_state <= 0;
        end else if (outcnt_layer_num_done_state_set) begin
          outcnt_layer_num_done_state <= 1;
        end
      end
    end
  end

endmodule
