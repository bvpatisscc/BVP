`timescale 1ns / 1ps

module BVP_CORE_MEM_inout_act #(
    parameter ACT_WIDTH = 8,
    parameter TILE_ACT_BUS_WIDTH = 2 * ACT_WIDTH,
    parameter PEC_OUT_BUS_WIDTH = 8 * ACT_WIDTH
) (
    input  logic                         arst_n,
    output logic                         axis2mem_addr_cnt_clr,
    input  logic                         axis2mem_addr_cnt_en,
    input  logic                         axis2mem_frame_computing,
    input  logic [PEC_OUT_BUS_WIDTH-1:0] axis2mem_wdata,
    input  logic                         axis2mem_web,
    input  logic                         axis_o_tready,
    input  logic                         clk,
    input  logic                         clk_en,
    input  logic [                  7:0] csr_layer_cfg_fm_height,
    input  logic [                  7:0] csr_layer_cfg_fm_width,
    input  logic [                  7:0] csr_layer_cfg_ich_num,
    input  logic [                  7:0] csr_layer_cfg_och_num,
    input  logic                         csr_mem_cfg_mem_in_act_ceb,
    input  logic                         csr_mem_cfg_mem_out_act_ceb,
    input  logic [                  2:0] csr_mem_cfg_act_cfg2,
    input  logic                         csr_mem_cfg_act_cfg4,
    input  logic [                  1:0] csr_mem_cfg_act_cfg3,
    input  logic                         csr_mem_cfg_act_cfg1,
    input  logic                         csr_mem_cfg_act_cfg0,
    input  logic                         csr_mem_cfg_act_cfg5,
    input  logic [                  1:0] csr_mem_cfg_act_cfg6,
    input  logic [                 11:0] csr_model_cfg_in_act_num,
    input  logic [                  2:0] csr_model_cfg_out_cls_num,
    input  logic                         csr_spi_cfg_spi_wr_mode,
    input  logic                         ctrl_cur_layer_done,
    input  logic                         ctrl_enable_mem2axis,
    input  logic                         ctrl_mem_inout_act_cnt_clr,
    input  logic                         ctrl_mem_inout_act_fc_gate_en,
    input  logic                         ctrl_mem_out_act_och_round_update,
    input  logic                         ctrl_send_act_from_padding_en,
    output logic                         dbg_out_mem_in_act_vld,
    output logic [TILE_ACT_BUS_WIDTH-1:0] mem_in_act_dout,
    input  logic                         mem_in_act_req,
    output logic                         mem_in_act_vld,
    output logic [PEC_OUT_BUS_WIDTH-1:0] mem_inout_act_mem0_dout,
    output logic [PEC_OUT_BUS_WIDTH-1:0] mem_inout_act_mem1_dout,
    output logic [PEC_OUT_BUS_WIDTH-1:0] mem_out_act_sram_dout,
    input  logic [PEC_OUT_BUS_WIDTH-1:0] mem_out_up_data_i,
    output logic                         mem_out_up_data_rdy_o,
    input  logic                         mem_out_up_data_vld_i,
    output logic                         out_mem2axis_addr_clr,
    input  logic                         out_mem2axis_addr_inc,
    input  logic [                 11:0] spi_mem_inout_act_mem0_addr,
    input  logic                         spi_mem_inout_act_mem0_ceb,
    input  logic [PEC_OUT_BUS_WIDTH-1:0] spi_mem_inout_act_mem0_din,
    input  logic                         spi_mem_inout_act_mem0_web,
    input  logic [                 11:0] spi_mem_inout_act_mem1_addr,
    input  logic                         spi_mem_inout_act_mem1_ceb,
    input  logic [PEC_OUT_BUS_WIDTH-1:0] spi_mem_inout_act_mem1_din,
    input  logic                         spi_mem_inout_act_mem1_web
);

  logic                         mem_in_act_ceb;
  logic                         mem_in_act_vld_nxt;
  logic [                 11:0] mem_in_act_addr;
  logic                         mem_in_act_web;
  logic [PEC_OUT_BUS_WIDTH-1:0] mem_in_act_din;
  logic                         mem_in_act_read_cnt_rch;
  logic                         mem_in_act_read_cnt_en;
  logic                         mem_in_act_read_cnt_clr;
  logic [                  1:0] mem_in_act_read_cnt;
  logic [                 11:0] mem_in_act_addr_cnt_maxval;
  logic                         max_rch_cnt_clr;
  logic                         mem_in_act_addr_cnt_rch;
  logic                         mem_in_act_addr_cnt_en;
  logic                         mem_in_act_addr_cnt_clr;
  logic [                 11:0] mem_in_act_addr_cnt;
  logic                         mem_out_act_ceb;
  logic                         axis_o_tready_pos;
  logic [                 11:0] mem_out_act_addr;
  logic                         mem_out_act_web;
  logic [PEC_OUT_BUS_WIDTH-1:0] mem_out_act_din;
  logic                         och_round_cnt_en;
  logic                         och_round_cnt_clr;
  logic [                  4:0] och_round_cnt_nxt;
  logic [                  4:0] och_round_cnt;
  logic [                  7:0] mem_out_act_addr_cnt_incr_val;
  logic                         mem_out_act_addr_cnt_en;
  logic                         mem_out_act_addr_cnt_clr;
  logic                         mem_out_act_addr_cnt_och_round_set;
  logic [                 11:0] mem_out_act_addr_cnt;
  logic                         switch_mem_inout_act_func_clr;
  logic                         switch_mem_inout_act_func;
  logic [                 11:0] mem_inout_act_mem0_addr;
  logic [                 11:0] mem_inout_act_mem1_addr;
  logic                         mem_inout_act_mem0_ceb;
  logic                         mem_inout_act_mem1_ceb;
  logic                         mem_inout_act_mem0_web;
  logic                         mem_inout_act_mem1_web;
  logic [PEC_OUT_BUS_WIDTH-1:0] mem_inout_act_mem0_din;
  logic [PEC_OUT_BUS_WIDTH-1:0] mem_inout_act_mem1_din;
  logic [PEC_OUT_BUS_WIDTH-1:0] mem_in_act_sram_dout;

  assign dbg_out_mem_in_act_vld = mem_in_act_vld;

  assign mem_in_act_ceb = csr_mem_cfg_mem_in_act_ceb;

  assign mem_in_act_vld_nxt = (ctrl_send_act_from_padding_en || mem_in_act_req) && !mem_in_act_ceb;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      mem_in_act_vld <= {$bits(mem_in_act_vld) {1'b0}};
    end else begin
      if (clk_en) begin
        mem_in_act_vld <= mem_in_act_vld_nxt;
      end
    end
  end

  assign mem_in_act_addr = mem_in_act_addr_cnt;
  assign mem_in_act_web  = axis2mem_web;
  assign mem_in_act_din  = axis2mem_wdata;

  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      mem_in_act_dout <= {$bits(mem_in_act_dout) {1'b0}};
    end else begin
      if (clk_en) begin
        if (ctrl_send_act_from_padding_en || ctrl_mem_inout_act_fc_gate_en) begin
          mem_in_act_dout <= '0;
        end else if (mem_in_act_read_cnt_en) begin
          case (mem_in_act_read_cnt)
            2'd0: mem_in_act_dout <= mem_in_act_sram_dout[TILE_ACT_BUS_WIDTH-1:0];
            2'd1: mem_in_act_dout <= mem_in_act_sram_dout[1*TILE_ACT_BUS_WIDTH+:TILE_ACT_BUS_WIDTH];
            2'd2: mem_in_act_dout <= mem_in_act_sram_dout[2*TILE_ACT_BUS_WIDTH+:TILE_ACT_BUS_WIDTH];
            2'd3: mem_in_act_dout <= mem_in_act_sram_dout[3*TILE_ACT_BUS_WIDTH+:TILE_ACT_BUS_WIDTH];
            default: mem_in_act_dout <= '0;
          endcase
        end
      end
    end
  end

  assign mem_in_act_read_cnt_rch = (mem_in_act_read_cnt == 2'd3) && mem_in_act_read_cnt_en;

  assign mem_in_act_read_cnt_en = mem_in_act_req && !mem_in_act_ceb;
  assign mem_in_act_read_cnt_clr = mem_in_act_read_cnt_rch || ctrl_mem_inout_act_cnt_clr || ctrl_cur_layer_done;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      mem_in_act_read_cnt <= {$bits(mem_in_act_read_cnt) {1'b0}};
    end else begin
      if (clk_en) begin
        if (mem_in_act_read_cnt_clr) begin
          mem_in_act_read_cnt <= 0;
        end else if (mem_in_act_read_cnt_en) begin
          mem_in_act_read_cnt <= mem_in_act_read_cnt + 1;
        end
      end
    end
  end

  assign mem_in_act_addr_cnt_maxval = ((csr_layer_cfg_ich_num + 1) * (csr_layer_cfg_fm_width + 1) * (csr_layer_cfg_fm_height + 1)) >> 3;

  assign axis2mem_addr_cnt_clr = (mem_in_act_addr_cnt == csr_model_cfg_in_act_num) && mem_in_act_addr_cnt_en;

  assign max_rch_cnt_clr = axis2mem_frame_computing ? mem_in_act_addr_cnt_rch : axis2mem_addr_cnt_clr;

  assign mem_in_act_addr_cnt_rch = (mem_in_act_addr_cnt == mem_in_act_addr_cnt_maxval-1) && mem_in_act_addr_cnt_en;
  assign mem_in_act_addr_cnt_en = mem_in_act_read_cnt_rch || axis2mem_addr_cnt_en;
  assign mem_in_act_addr_cnt_clr = ctrl_cur_layer_done || ctrl_mem_inout_act_cnt_clr || max_rch_cnt_clr;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      mem_in_act_addr_cnt <= {$bits(mem_in_act_addr_cnt) {1'b0}};
    end else begin
      if (clk_en) begin
        if (mem_in_act_addr_cnt_clr) begin
          mem_in_act_addr_cnt <= 0;
        end else if (mem_in_act_addr_cnt_en) begin
          mem_in_act_addr_cnt <= mem_in_act_addr_cnt + 1;
        end
      end
    end
  end

  assign mem_out_act_ceb = csr_mem_cfg_mem_out_act_ceb;
  assign mem_out_up_data_rdy_o = !mem_out_act_ceb && axis_o_tready_pos;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      axis_o_tready_pos <= {$bits(axis_o_tready_pos) {1'b0}};
    end else begin
      axis_o_tready_pos <= axis_o_tready;
    end
  end

  assign mem_out_act_addr  = mem_out_act_addr_cnt;
  assign mem_out_act_web   = ~mem_out_act_addr_cnt_en || ctrl_enable_mem2axis;
  assign mem_out_act_din   = mem_out_up_data_i;

  assign och_round_cnt_en  = ctrl_mem_out_act_och_round_update;
  assign och_round_cnt_clr = ctrl_cur_layer_done || ctrl_mem_inout_act_cnt_clr;

  assign och_round_cnt_nxt = och_round_cnt + 1;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      och_round_cnt <= {$bits(och_round_cnt) {1'b0}};
    end else begin
      if (clk_en) begin
        if (och_round_cnt_clr) begin
          och_round_cnt <= 0;
        end else if (och_round_cnt_en) begin
          och_round_cnt <= och_round_cnt_nxt;
        end
      end
    end
  end

  assign mem_out_act_addr_cnt_incr_val = ctrl_enable_mem2axis ? 8'd1 : (csr_layer_cfg_och_num + 1) >> 3;
  assign mem_out_act_addr_cnt_en = (mem_out_up_data_vld_i && mem_out_up_data_rdy_o) || out_mem2axis_addr_inc;
  assign mem_out_act_addr_cnt_clr = ctrl_cur_layer_done || ctrl_mem_inout_act_cnt_clr || out_mem2axis_addr_clr;
  assign mem_out_act_addr_cnt_och_round_set = och_round_cnt_en;

  assign out_mem2axis_addr_clr = (mem_out_act_addr_cnt == csr_model_cfg_out_cls_num) && out_mem2axis_addr_inc;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      mem_out_act_addr_cnt <= {$bits(mem_out_act_addr_cnt) {1'b0}};
    end else begin
      if (clk_en) begin
        if (mem_out_act_addr_cnt_clr) begin
          mem_out_act_addr_cnt <= 0;
        end else if (mem_out_act_addr_cnt_och_round_set) begin
          mem_out_act_addr_cnt <= {$bits(mem_out_act_addr_cnt) {1'b0}} | och_round_cnt_nxt;
        end else if (mem_out_act_addr_cnt_en) begin
          mem_out_act_addr_cnt <= mem_out_act_addr_cnt + mem_out_act_addr_cnt_incr_val;
        end
      end
    end
  end

  localparam MEM0_INPUT_MEM1_OUTPUT = 1'b0;
  localparam MEM1_INPUT_MEM0_OUTPUT = 1'b1;

  assign switch_mem_inout_act_func_clr = out_mem2axis_addr_clr;
  always_ff @(posedge clk or negedge arst_n) begin
    if (~arst_n) begin
      switch_mem_inout_act_func <= {$bits(switch_mem_inout_act_func) {1'b0}};
    end else begin
      if (clk_en) begin
        if (switch_mem_inout_act_func_clr) begin
          switch_mem_inout_act_func <= MEM0_INPUT_MEM1_OUTPUT;
        end else if (ctrl_cur_layer_done) begin
          switch_mem_inout_act_func <= ~switch_mem_inout_act_func;
        end
      end
    end
  end

  always_comb begin
    if (csr_spi_cfg_spi_wr_mode) begin

      mem_inout_act_mem0_addr = spi_mem_inout_act_mem0_addr;
      mem_inout_act_mem1_addr = spi_mem_inout_act_mem1_addr;
    end else begin
      case (switch_mem_inout_act_func)
        MEM0_INPUT_MEM1_OUTPUT: begin
          mem_inout_act_mem0_addr = mem_in_act_addr;
          mem_inout_act_mem1_addr = mem_out_act_addr;
        end
        MEM1_INPUT_MEM0_OUTPUT: begin
          mem_inout_act_mem0_addr = mem_out_act_addr;
          mem_inout_act_mem1_addr = mem_in_act_addr;
        end
        default: begin
          mem_inout_act_mem0_addr = mem_in_act_addr;
          mem_inout_act_mem1_addr = mem_out_act_addr;
        end
      endcase
    end
  end
  always_comb begin
    if (csr_spi_cfg_spi_wr_mode) begin

      mem_inout_act_mem0_ceb = spi_mem_inout_act_mem0_ceb;
      mem_inout_act_mem1_ceb = spi_mem_inout_act_mem1_ceb;
    end else begin
      case (switch_mem_inout_act_func)
        MEM0_INPUT_MEM1_OUTPUT: begin
          mem_inout_act_mem0_ceb = mem_in_act_ceb;
          mem_inout_act_mem1_ceb = mem_out_act_ceb;
        end
        MEM1_INPUT_MEM0_OUTPUT: begin
          mem_inout_act_mem0_ceb = mem_out_act_ceb;
          mem_inout_act_mem1_ceb = mem_in_act_ceb;
        end
        default: begin
          mem_inout_act_mem0_ceb = mem_in_act_ceb;
          mem_inout_act_mem1_ceb = mem_out_act_ceb;
        end
      endcase
    end
  end
  always_comb begin
    if (csr_spi_cfg_spi_wr_mode) begin

      mem_inout_act_mem0_web = spi_mem_inout_act_mem0_web;
      mem_inout_act_mem1_web = spi_mem_inout_act_mem1_web;
    end else begin
      case (switch_mem_inout_act_func)
        MEM0_INPUT_MEM1_OUTPUT: begin
          mem_inout_act_mem0_web = mem_in_act_web;
          mem_inout_act_mem1_web = mem_out_act_web;
        end
        MEM1_INPUT_MEM0_OUTPUT: begin
          mem_inout_act_mem0_web = mem_out_act_web;
          mem_inout_act_mem1_web = mem_in_act_web;
        end
        default: begin
          mem_inout_act_mem0_web = mem_in_act_web;
          mem_inout_act_mem1_web = mem_out_act_web;
        end
      endcase
    end
  end
  always_comb begin
    if (csr_spi_cfg_spi_wr_mode) begin

      mem_inout_act_mem0_din = spi_mem_inout_act_mem0_din;
      mem_inout_act_mem1_din = spi_mem_inout_act_mem1_din;
    end else begin
      case (switch_mem_inout_act_func)
        MEM0_INPUT_MEM1_OUTPUT: begin
          mem_inout_act_mem0_din = mem_in_act_din;
          mem_inout_act_mem1_din = mem_out_act_din;
        end
        MEM1_INPUT_MEM0_OUTPUT: begin
          mem_inout_act_mem0_din = mem_out_act_din;
          mem_inout_act_mem1_din = mem_in_act_din;
        end
        default: begin
          mem_inout_act_mem0_din = mem_in_act_din;
          mem_inout_act_mem1_din = mem_out_act_din;
        end
      endcase
    end
  end
  always_comb begin
    case (switch_mem_inout_act_func)
      MEM0_INPUT_MEM1_OUTPUT: begin
        mem_in_act_sram_dout  = mem_inout_act_mem0_dout;
        mem_out_act_sram_dout = mem_inout_act_mem1_dout;
      end
      MEM1_INPUT_MEM0_OUTPUT: begin
        mem_in_act_sram_dout  = mem_inout_act_mem1_dout;
        mem_out_act_sram_dout = mem_inout_act_mem0_dout;
      end
      default: begin
        mem_in_act_sram_dout  = mem_inout_act_mem0_dout;
        mem_out_act_sram_dout = mem_inout_act_mem1_dout;
      end
    endcase
  end

  sram_stub #(
      .RAM_DATA_BW(PEC_OUT_BUS_WIDTH),
      .RAM_ADDR_BW(12)
  ) u_mem0_stub (
      .addr(mem_inout_act_mem0_addr),
      .ce_n(mem_inout_act_mem0_ceb),
      .clk(clk),
      .wdata(mem_inout_act_mem0_din),
      .rdata(mem_inout_act_mem0_dout),
      .we_n(mem_inout_act_mem0_web)
  );
  sram_stub #(
      .RAM_DATA_BW(PEC_OUT_BUS_WIDTH),
      .RAM_ADDR_BW(12)
  ) u_mem1_stub (
      .addr(mem_inout_act_mem1_addr),
      .ce_n(mem_inout_act_mem1_ceb),
      .clk(clk),
      .wdata(mem_inout_act_mem1_din),
      .rdata(mem_inout_act_mem1_dout),
      .we_n(mem_inout_act_mem1_web)
  );

endmodule
