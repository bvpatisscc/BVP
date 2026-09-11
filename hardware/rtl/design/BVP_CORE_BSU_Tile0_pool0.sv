`timescale 1ns / 1ps

module BVP_CORE_BSU_Tile0_pool0 #(
    parameter NLAYER_ACT_WIDTH = 8,
    parameter POOL_FIFO_DEPTH  = 8
) (
    input  logic                        arst_n,
    input  logic                        clk,
    input  logic                        clk_en,
    input  logic                        csr_layer_cfg_pool_sizeh,
    input  logic                        csr_layer_cfg_pool_sizew,
    input  logic                        csr_model_cfg_last_pool_type,
    input  logic                        ctrl_bias_relu_out_row_done,
    input  logic                        ctrl_pea_en,
    input  logic                        cur_ifm_done,
    input  logic                        dn_prdy_i,
    output logic                        dn_pvld_o,
    input  logic                        incnt_fm_height_done,
    input  logic                        incnt_ich_num_done,
    input  logic                        pool_last_pixel,
    output logic [NLAYER_ACT_WIDTH-1:0] pool_res_data_o,
    input  logic [NLAYER_ACT_WIDTH-1:0] up_data_i,
    output logic                        up_rdy_o,
    input  logic                        up_vld_i
);

  localparam POOL_WIDTH = NLAYER_ACT_WIDTH + 4;

  logic                               cfg_last_pool_type;
  logic                               up_vld_i_gate;
  logic                               up_data_recv;
  logic                               pool_sizew_cnt_en;
  logic                               pool_sizew_cnt_1st;
  logic                               pool_sizew_cnt_last;
  logic                               pool_sizew_cnt_1st_en;
  logic                               pool_sizew_cnt_last_en;
  logic                               pool_sizew_cnt_clr;
  logic        [                 0:0] pool_sizew_cnt;
  logic                               pool_sizeh_cnt_en;
  logic                               pool_sizeh_cnt_clr;
  logic                               pool_sizeh_cnt_1st;
  logic                               pool_sizeh_cnt_last;
  logic                               pool_sizeh_cnt_last_en;
  logic        [                 0:0] pool_sizeh_cnt;
  logic                               lyr_pool_first_pixel_flag_clr;
  logic                               lyr_pool_first_pixel_flag_set;
  logic                               lyr_pool_first_pixel_flag;
  logic        [      POOL_WIDTH-1:0] pool_din_0;
  logic        [      POOL_WIDTH-1:0] pool_din_1;
  logic        [      POOL_WIDTH-1:0] pooled_value_nxt_tmp;
  logic                               conv_first_pixel;
  logic                               pool_first_pixel;
  logic        [      POOL_WIDTH-1:0] pooled_value_nxt;
  logic                               pool_fifo_wren_lyr_conv;
  logic                               pool_fifo_rden_lyr_conv;
  logic                               pool_fifo_wren_lyr_pool;
  logic                               pool_fifo_rden_lyr_pool;
  logic                               pool_fifo_wren;
  logic                               pool_fifo_rden;
  logic                               pool_fifo_rd_data_vld;
  logic                               pool_fifo_full;
  logic        [      POOL_WIDTH-1:0] pool_fifo_rdata;
  logic                               pool_fifo_rempty;

  logic signed [      POOL_WIDTH-1:0] pooled_value_cur;
  logic signed [NLAYER_ACT_WIDTH-1:0] avg_value_cur;
  logic signed [NLAYER_ACT_WIDTH-1:0] max_value_cur;
  assign cfg_last_pool_type = csr_model_cfg_last_pool_type && !ctrl_pea_en;

  assign up_vld_i_gate = ctrl_pea_en ? (pool_sizeh_cnt_last && pool_sizew_cnt_last) : pool_last_pixel;

  assign up_rdy_o = ~(dn_pvld_o) || (dn_prdy_i);
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      dn_pvld_o <= {$bits(dn_pvld_o) {1'b0}};
    end else begin
      if (clk_en) begin
        if (up_rdy_o) dn_pvld_o <= up_vld_i && up_vld_i_gate;
      end
    end
  end

  assign up_data_recv           = up_vld_i && up_rdy_o;

  assign pool_sizew_cnt_en      = up_data_recv;
  assign pool_sizew_cnt_1st     = pool_sizew_cnt == 0;
  assign pool_sizew_cnt_last    = pool_sizew_cnt == csr_layer_cfg_pool_sizew;
  assign pool_sizew_cnt_1st_en  = pool_sizew_cnt_1st && pool_sizew_cnt_en;
  assign pool_sizew_cnt_last_en = pool_sizew_cnt_last && pool_sizew_cnt_en;
  assign pool_sizew_cnt_clr     = pool_sizew_cnt_last_en || ctrl_bias_relu_out_row_done;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      pool_sizew_cnt <= {$bits(pool_sizew_cnt) {1'b0}};
    end else begin
      if (clk_en) begin
        if (pool_sizew_cnt_clr) begin
          pool_sizew_cnt <= 0;
        end else if (pool_sizew_cnt_en) begin
          pool_sizew_cnt <= pool_sizew_cnt + 1;
        end
      end
    end
  end

  assign pool_sizeh_cnt_en      = ctrl_bias_relu_out_row_done;
  assign pool_sizeh_cnt_clr     = pool_sizeh_cnt_last_en;
  assign pool_sizeh_cnt_1st     = pool_sizeh_cnt == 0;
  assign pool_sizeh_cnt_last    = pool_sizeh_cnt == csr_layer_cfg_pool_sizeh;
  assign pool_sizeh_cnt_last_en = pool_sizeh_cnt_last && pool_sizeh_cnt_en;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      pool_sizeh_cnt <= {$bits(pool_sizeh_cnt) {1'b0}};
    end else begin
      if (clk_en) begin
        if (pool_sizeh_cnt_clr) begin
          pool_sizeh_cnt <= 0;
        end else if (pool_sizeh_cnt_en) begin
          pool_sizeh_cnt <= pool_sizeh_cnt + 1;
        end
      end
    end
  end

  assign lyr_pool_first_pixel_flag_clr = !ctrl_pea_en && incnt_fm_height_done && lyr_pool_first_pixel_flag;
  assign lyr_pool_first_pixel_flag_set = !ctrl_pea_en && incnt_ich_num_done && !lyr_pool_first_pixel_flag;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      lyr_pool_first_pixel_flag <= {$bits(lyr_pool_first_pixel_flag) {1'b0}};
    end else begin
      if (clk_en) begin
        if (lyr_pool_first_pixel_flag_clr) begin
          lyr_pool_first_pixel_flag <= 1'b0;
        end else if (lyr_pool_first_pixel_flag_set) begin
          lyr_pool_first_pixel_flag <= 1'b1;
        end
      end
    end
  end

  assign pool_res_data_o = cfg_last_pool_type ? avg_value_cur : max_value_cur;
  assign avg_value_cur   = pooled_value_cur >>> 2;
  assign max_value_cur   = pooled_value_cur[NLAYER_ACT_WIDTH-1:0];

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      pooled_value_cur <= {$bits(pooled_value_cur) {1'b0}};
    end else begin
      if (clk_en) begin
        if (up_data_recv) begin
          pooled_value_cur <= pooled_value_nxt;
        end
      end
    end
  end

  assign pool_din_0 = pool_fifo_rd_data_vld ? pool_fifo_rdata : pooled_value_cur;
  assign pool_din_1 = {{(POOL_WIDTH - NLAYER_ACT_WIDTH) {1'b0}}, up_data_i};

  BVP_CORE_BSU_Tile_pool_unit #(
      .POOL_WIDTH(POOL_WIDTH)
  ) uPU (
      .din_0        (pool_din_0),
      .din_1        (pool_din_1),
      .cfg_pool_type(cfg_last_pool_type),
      .dout         (pooled_value_nxt_tmp)
  );
  assign conv_first_pixel = pool_sizeh_cnt_1st && pool_sizew_cnt_1st_en;
  assign pool_first_pixel = !lyr_pool_first_pixel_flag;

  assign pooled_value_nxt = ctrl_pea_en ?
                         (conv_first_pixel ? {{(POOL_WIDTH-NLAYER_ACT_WIDTH){1'b0}}, up_data_i} : pooled_value_nxt_tmp) :
                         (pool_first_pixel ? {{(POOL_WIDTH-NLAYER_ACT_WIDTH){1'b0}}, up_data_i} : pooled_value_nxt_tmp);

  assign pool_fifo_wren_lyr_conv = !pool_sizeh_cnt_last && pool_sizew_cnt_last && up_data_recv;
  assign pool_fifo_rden_lyr_conv = (pool_sizeh_cnt != 0) && !pool_sizew_cnt_last && up_data_recv;

  assign pool_fifo_wren_lyr_pool = up_data_recv;
  assign pool_fifo_rden_lyr_pool = lyr_pool_first_pixel_flag && up_data_recv;

  assign pool_fifo_wren = ctrl_pea_en ? pool_fifo_wren_lyr_conv : pool_fifo_wren_lyr_pool;
  assign pool_fifo_rden = ctrl_pea_en ? pool_fifo_rden_lyr_conv : pool_fifo_rden_lyr_pool;

  assign pool_fifo_rd_data_vld = pool_fifo_rden && !pool_fifo_rempty;

  sync_fifo_ram_flush #(
      .DATA_WIDTH(POOL_WIDTH),
      .FIFO_DEPTH(POOL_FIFO_DEPTH)
  ) uFIFO (
      .clk       (clk),
      .arst_n    (arst_n),
      .flush_fifo(cur_ifm_done),
      .wren      (pool_fifo_wren),
      .wdata     (pooled_value_nxt),
      .wfull     (pool_fifo_full),
      .rden      (pool_fifo_rden),
      .rdata     (pool_fifo_rdata),
      .rempty    (pool_fifo_rempty)
  );

endmodule
