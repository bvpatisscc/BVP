`timescale 1ns / 1ps

module BVP_CORE_BSU_Tile_pool #(
    parameter NLAYER_ACT_WIDTH = 8,
    parameter POOL_FIFO_DEPTH  = 8
) (
    input  logic                        arst_n,
    input  logic                        clk,
    input  logic                        clk_en,
    input  logic                        csr_layer_cfg_pool_sizeh,
    input  logic                        csr_layer_cfg_pool_sizew,
    input  logic                        ctrl_bias_relu_out_row_done,
    input  logic                        cur_ifm_done,
    input  logic                        dn_prdy_i,
    output logic                        dn_pvld_o,
    output logic [NLAYER_ACT_WIDTH-1:0] pool_res_data_o,
    input  logic [NLAYER_ACT_WIDTH-1:0] up_data_i,
    output logic                        up_rdy_o,
    input  logic                        up_vld_i
);

  logic                        up_data_recv;
  logic                        pool_sizew_cnt_en;
  logic                        pool_sizew_cnt_1st;
  logic                        pool_sizew_cnt_last;
  logic                        pool_sizew_cnt_1st_en;
  logic                        pool_sizew_cnt_last_en;
  logic                        pool_sizew_cnt_clr;
  logic [                 0:0] pool_sizew_cnt;
  logic                        pool_sizeh_cnt_en;
  logic                        pool_sizeh_cnt_1st;
  logic                        pool_sizeh_cnt_last;
  logic                        pool_sizeh_cnt_last_en;
  logic                        pool_sizeh_cnt_clr;
  logic [                 0:0] pool_sizeh_cnt;
  logic [NLAYER_ACT_WIDTH-1:0] max_value_cur;
  logic [NLAYER_ACT_WIDTH-1:0] max_arith_din_0;
  logic [NLAYER_ACT_WIDTH-1:0] max_arith_din_1;
  logic [NLAYER_ACT_WIDTH-1:0] max_value_nxt_max;
  logic [NLAYER_ACT_WIDTH-1:0] max_value_nxt;
  logic                        pool_fifo_wren;
  logic                        pool_fifo_rden;
  logic                        pool_fifo_rd_data_vld;
  logic                        pool_fifo_full;
  logic [NLAYER_ACT_WIDTH-1:0] pool_fifo_rdata;
  logic                        pool_fifo_rempty;

  assign up_rdy_o = ~(dn_pvld_o) || (dn_prdy_i);
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      dn_pvld_o <= {$bits(dn_pvld_o) {1'b0}};
    end else begin
      if (clk_en) begin
        if (up_rdy_o) dn_pvld_o <= up_vld_i && pool_sizeh_cnt_last && pool_sizew_cnt_last;
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
  assign pool_sizeh_cnt_1st     = pool_sizeh_cnt == 0;
  assign pool_sizeh_cnt_last    = pool_sizeh_cnt == csr_layer_cfg_pool_sizeh;
  assign pool_sizeh_cnt_last_en = pool_sizeh_cnt_last && pool_sizeh_cnt_en;
  assign pool_sizeh_cnt_clr     = pool_sizeh_cnt_last_en;
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

  assign pool_res_data_o = max_value_cur;

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      max_value_cur <= {$bits(max_value_cur) {1'b0}};
    end else begin
      if (clk_en) begin
        if (up_data_recv) begin
          max_value_cur <= max_value_nxt;
        end
      end
    end
  end

  assign max_arith_din_0 = pool_fifo_rd_data_vld ? pool_fifo_rdata : max_value_cur;
  assign max_arith_din_1 = up_data_i;

  BVP_CORE_BSU_Tile_pool_max #(
      .NLAYER_ACT_WIDTH(NLAYER_ACT_WIDTH)
  ) uMAX (
      .din_0(max_arith_din_0),
      .din_1(max_arith_din_1),
      .dout (max_value_nxt_max)
  );

  assign max_value_nxt = (pool_sizeh_cnt_1st && pool_sizew_cnt_1st_en) ? up_data_i : max_value_nxt_max;

  assign pool_fifo_wren = !pool_sizeh_cnt_last && pool_sizew_cnt_last && up_data_recv;
  assign pool_fifo_rden = (pool_sizeh_cnt != 0) && !pool_sizew_cnt_last && up_data_recv;

  assign pool_fifo_rd_data_vld = pool_fifo_rden && !pool_fifo_rempty;

  sync_fifo_ram_flush #(
      .DATA_WIDTH(NLAYER_ACT_WIDTH),
      .FIFO_DEPTH(POOL_FIFO_DEPTH)
  ) uFIFO (
      .clk       (clk),
      .arst_n    (arst_n),
      .flush_fifo(cur_ifm_done),
      .wren      (pool_fifo_wren),
      .wdata     (max_value_nxt),
      .wfull     (pool_fifo_full),
      .rden      (pool_fifo_rden),
      .rdata     (pool_fifo_rdata),
      .rempty    (pool_fifo_rempty)
  );

endmodule
