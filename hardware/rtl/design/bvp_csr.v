module bvp_csr #(
    parameter ADDR_W = 8,
    parameter DATA_W = 16,
    parameter STRB_W = (DATA_W + 7) >> 3
) (

    input clk,
    input rst,

    input csr_layer_cfg0_ich_num_en,
    input [7:0] csr_layer_cfg0_ich_num_in,
    output [7:0] csr_layer_cfg0_ich_num_out,

    input csr_layer_cfg0_och_num_en,
    input [7:0] csr_layer_cfg0_och_num_in,
    output [7:0] csr_layer_cfg0_och_num_out,

    input csr_layer_cfg1_fm_width_en,
    input [7:0] csr_layer_cfg1_fm_width_in,
    output [7:0] csr_layer_cfg1_fm_width_out,

    input csr_layer_cfg1_fm_height_en,
    input [7:0] csr_layer_cfg1_fm_height_in,
    output [7:0] csr_layer_cfg1_fm_height_out,

    input csr_layer_cfg2_ofm_width_en,
    input [7:0] csr_layer_cfg2_ofm_width_in,
    output [7:0] csr_layer_cfg2_ofm_width_out,

    input csr_layer_cfg2_ofm_height_en,
    input [7:0] csr_layer_cfg2_ofm_height_in,
    output [7:0] csr_layer_cfg2_ofm_height_out,

    input csr_layer_cfg3_strideh_en,
    input [1:0] csr_layer_cfg3_strideh_in,
    output [1:0] csr_layer_cfg3_strideh_out,

    input csr_layer_cfg3_stridew_en,
    input [1:0] csr_layer_cfg3_stridew_in,
    output [1:0] csr_layer_cfg3_stridew_out,

    input  csr_layer_cfg3_padding_enable_en,
    input  csr_layer_cfg3_padding_enable_set,
    input  csr_layer_cfg3_padding_enable_in,
    output csr_layer_cfg3_padding_enable_out,

    input  csr_layer_cfg3_pool_enable_en,
    input  csr_layer_cfg3_pool_enable_in,
    output csr_layer_cfg3_pool_enable_out,

    output csr_layer_cfg3_pool_sizeh_out,

    output csr_layer_cfg3_pool_sizew_out,

    input csr_layer_cfg4_cur_act_frac_width_en,
    input [2:0] csr_layer_cfg4_cur_act_frac_width_in,
    output [2:0] csr_layer_cfg4_cur_act_frac_width_out,

    input csr_layer_cfg4_cur_wgt_frac_width_en,
    input [3:0] csr_layer_cfg4_cur_wgt_frac_width_in,
    output [3:0] csr_layer_cfg4_cur_wgt_frac_width_out,

    input csr_layer_cfg4_nxt_act_frac_width_en,
    input [2:0] csr_layer_cfg4_nxt_act_frac_width_in,
    output [2:0] csr_layer_cfg4_nxt_act_frac_width_out,

    output [4:0] csr_model_cfg0_layer_num_out,

    output [2:0] csr_model_cfg0_out_cls_num_out,

    output csr_model_cfg0_last_pool_type_out,

    output [11:0] csr_model_cfg1_in_act_num_out,

    output csr_spi_cfg0_spi_wr_mode_out,

    input  csr_chip_cfg0_frame_ready_clr,
    input  csr_chip_cfg0_frame_ready_set,
    output csr_chip_cfg0_frame_ready_out,

    output csr_pad_cfg0_ds0_out,

    output csr_pad_cfg0_ds1_out,

    output csr_pad_cfg0_pe_out,

    output csr_pad_cfg0_ps_out,

    output csr_pad_cfg0_sr_out,

    output csr_pad_cfg0_lpm_out,

    output csr_mem_cfg0_mem_in_act_ceb_out,

    output csr_mem_cfg0_mem_in_wgt_ceb_out,

    output csr_mem_cfg0_mem_in_fc_wgt_ceb_out,

    output csr_mem_cfg0_mem_in_bias_ceb_out,

    output csr_mem_cfg0_mem_in_instr_ceb_out,

    output csr_mem_cfg0_mem_out_act_ceb_out,

    output csr_mem_cfg1_aux_cfg0_out,

    output csr_mem_cfg1_aux_cfg1_out,

    output [2:0] csr_mem_cfg1_aux_cfg2_out,

    output [1:0] csr_mem_cfg1_aux_cfg3_out,

    output csr_mem_cfg1_aux_cfg4_out,

    output csr_mem_cfg3_act_cfg0_out,

    output csr_mem_cfg3_act_cfg1_out,

    output [2:0] csr_mem_cfg3_act_cfg2_out,

    output [1:0] csr_mem_cfg3_act_cfg3_out,

    output csr_mem_cfg3_act_cfg4_out,

    output csr_mem_cfg3_act_cfg5_out,

    output [1:0] csr_mem_cfg3_act_cfg6_out,

    output csr_mem_cfg4_wgt_cfg0_out,

    output csr_mem_cfg4_wgt_cfg1_out,

    output [2:0] csr_mem_cfg4_wgt_cfg2_out,

    output [1:0] csr_mem_cfg4_wgt_cfg3_out,

    output csr_mem_cfg4_wgt_cfg4_out,

    input  [ADDR_W-1:0] waddr,
    input  [DATA_W-1:0] wdata,
    input               wen,
    input  [STRB_W-1:0] wstrb,
    output              wready,
    input  [ADDR_W-1:0] raddr,
    input               ren,
    output [DATA_W-1:0] rdata,
    output              rvalid
);

  wire [15:0] csr_layer_cfg0_rdata;

  wire csr_layer_cfg0_wen;
  assign csr_layer_cfg0_wen = wen && (waddr == 8'h0);

  wire csr_layer_cfg0_ren;
  assign csr_layer_cfg0_ren = ren && (raddr == 8'h0);
  reg csr_layer_cfg0_ren_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg0_ren_ff <= 1'b0;
    end else begin
      csr_layer_cfg0_ren_ff <= csr_layer_cfg0_ren;
    end
  end

  reg [7:0] csr_layer_cfg0_ich_num_ff;

  assign csr_layer_cfg0_rdata[7:0]  = csr_layer_cfg0_ich_num_ff;

  assign csr_layer_cfg0_ich_num_out = csr_layer_cfg0_ich_num_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg0_ich_num_ff <= 8'h1;
    end else begin
      if (csr_layer_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_layer_cfg0_ich_num_ff[7:0] <= wdata[7:0];
        end
      end else if (csr_layer_cfg0_ich_num_en) begin
        csr_layer_cfg0_ich_num_ff <= csr_layer_cfg0_ich_num_in;
      end
    end
  end

  reg [7:0] csr_layer_cfg0_och_num_ff;

  assign csr_layer_cfg0_rdata[15:8] = csr_layer_cfg0_och_num_ff;

  assign csr_layer_cfg0_och_num_out = csr_layer_cfg0_och_num_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg0_och_num_ff <= 8'h3f;
    end else begin
      if (csr_layer_cfg0_wen) begin
        if (wstrb[1]) begin
          csr_layer_cfg0_och_num_ff[7:0] <= wdata[15:8];
        end
      end else if (csr_layer_cfg0_och_num_en) begin
        csr_layer_cfg0_och_num_ff <= csr_layer_cfg0_och_num_in;
      end
    end
  end

  wire [15:0] csr_layer_cfg1_rdata;

  wire csr_layer_cfg1_wen;
  assign csr_layer_cfg1_wen = wen && (waddr == 8'h1);

  wire csr_layer_cfg1_ren;
  assign csr_layer_cfg1_ren = ren && (raddr == 8'h1);
  reg csr_layer_cfg1_ren_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg1_ren_ff <= 1'b0;
    end else begin
      csr_layer_cfg1_ren_ff <= csr_layer_cfg1_ren;
    end
  end

  reg [7:0] csr_layer_cfg1_fm_width_ff;

  assign csr_layer_cfg1_rdata[7:0]   = csr_layer_cfg1_fm_width_ff;

  assign csr_layer_cfg1_fm_width_out = csr_layer_cfg1_fm_width_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg1_fm_width_ff <= 8'h7;
    end else begin
      if (csr_layer_cfg1_wen) begin
        if (wstrb[0]) begin
          csr_layer_cfg1_fm_width_ff[7:0] <= wdata[7:0];
        end
      end else if (csr_layer_cfg1_fm_width_en) begin
        csr_layer_cfg1_fm_width_ff <= csr_layer_cfg1_fm_width_in;
      end
    end
  end

  reg [7:0] csr_layer_cfg1_fm_height_ff;

  assign csr_layer_cfg1_rdata[15:8]   = csr_layer_cfg1_fm_height_ff;

  assign csr_layer_cfg1_fm_height_out = csr_layer_cfg1_fm_height_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg1_fm_height_ff <= 8'h7f;
    end else begin
      if (csr_layer_cfg1_wen) begin
        if (wstrb[1]) begin
          csr_layer_cfg1_fm_height_ff[7:0] <= wdata[15:8];
        end
      end else if (csr_layer_cfg1_fm_height_en) begin
        csr_layer_cfg1_fm_height_ff <= csr_layer_cfg1_fm_height_in;
      end
    end
  end

  wire [15:0] csr_layer_cfg2_rdata;

  wire csr_layer_cfg2_wen;
  assign csr_layer_cfg2_wen = wen && (waddr == 8'h2);

  wire csr_layer_cfg2_ren;
  assign csr_layer_cfg2_ren = ren && (raddr == 8'h2);
  reg csr_layer_cfg2_ren_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg2_ren_ff <= 1'b0;
    end else begin
      csr_layer_cfg2_ren_ff <= csr_layer_cfg2_ren;
    end
  end

  reg [7:0] csr_layer_cfg2_ofm_width_ff;

  assign csr_layer_cfg2_rdata[7:0] = csr_layer_cfg2_ofm_width_ff;

  assign csr_layer_cfg2_ofm_width_out = csr_layer_cfg2_ofm_width_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg2_ofm_width_ff <= 8'h7;
    end else begin
      if (csr_layer_cfg2_wen) begin
        if (wstrb[0]) begin
          csr_layer_cfg2_ofm_width_ff[7:0] <= wdata[7:0];
        end
      end else if (csr_layer_cfg2_ofm_width_en) begin
        csr_layer_cfg2_ofm_width_ff <= csr_layer_cfg2_ofm_width_in;
      end
    end
  end

  reg [7:0] csr_layer_cfg2_ofm_height_ff;

  assign csr_layer_cfg2_rdata[15:8] = csr_layer_cfg2_ofm_height_ff;

  assign csr_layer_cfg2_ofm_height_out = csr_layer_cfg2_ofm_height_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg2_ofm_height_ff <= 8'h7;
    end else begin
      if (csr_layer_cfg2_wen) begin
        if (wstrb[1]) begin
          csr_layer_cfg2_ofm_height_ff[7:0] <= wdata[15:8];
        end
      end else if (csr_layer_cfg2_ofm_height_en) begin
        csr_layer_cfg2_ofm_height_ff <= csr_layer_cfg2_ofm_height_in;
      end
    end
  end

  wire [15:0] csr_layer_cfg3_rdata;
  assign csr_layer_cfg3_rdata[4] = 1'b0;
  assign csr_layer_cfg3_rdata[15:9] = 7'h0;

  wire csr_layer_cfg3_wen;
  assign csr_layer_cfg3_wen = wen && (waddr == 8'h3);

  wire csr_layer_cfg3_ren;
  assign csr_layer_cfg3_ren = ren && (raddr == 8'h3);
  reg csr_layer_cfg3_ren_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg3_ren_ff <= 1'b0;
    end else begin
      csr_layer_cfg3_ren_ff <= csr_layer_cfg3_ren;
    end
  end

  reg [1:0] csr_layer_cfg3_strideh_ff;

  assign csr_layer_cfg3_rdata[1:0]  = csr_layer_cfg3_strideh_ff;

  assign csr_layer_cfg3_strideh_out = csr_layer_cfg3_strideh_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg3_strideh_ff <= 2'h1;
    end else begin
      if (csr_layer_cfg3_wen) begin
        if (wstrb[0]) begin
          csr_layer_cfg3_strideh_ff[1:0] <= wdata[1:0];
        end
      end else if (csr_layer_cfg3_strideh_en) begin
        csr_layer_cfg3_strideh_ff <= csr_layer_cfg3_strideh_in;
      end
    end
  end

  reg [1:0] csr_layer_cfg3_stridew_ff;

  assign csr_layer_cfg3_rdata[3:2]  = csr_layer_cfg3_stridew_ff;

  assign csr_layer_cfg3_stridew_out = csr_layer_cfg3_stridew_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg3_stridew_ff <= 2'h1;
    end else begin
      if (csr_layer_cfg3_wen) begin
        if (wstrb[0]) begin
          csr_layer_cfg3_stridew_ff[1:0] <= wdata[3:2];
        end
      end else if (csr_layer_cfg3_stridew_en) begin
        csr_layer_cfg3_stridew_ff <= csr_layer_cfg3_stridew_in;
      end
    end
  end

  reg csr_layer_cfg3_padding_enable_ff;

  assign csr_layer_cfg3_rdata[5] = csr_layer_cfg3_padding_enable_ff;

  assign csr_layer_cfg3_padding_enable_out = csr_layer_cfg3_padding_enable_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg3_padding_enable_ff <= 1'b1;
    end else begin
      if (csr_layer_cfg3_padding_enable_set) begin
        csr_layer_cfg3_padding_enable_ff <= 1'b1;
      end else if (csr_layer_cfg3_wen) begin
        if (wstrb[0]) begin
          csr_layer_cfg3_padding_enable_ff <= wdata[5];
        end
      end else if (csr_layer_cfg3_padding_enable_en) begin
        csr_layer_cfg3_padding_enable_ff <= csr_layer_cfg3_padding_enable_in;
      end
    end
  end

  reg csr_layer_cfg3_pool_enable_ff;

  assign csr_layer_cfg3_rdata[6] = csr_layer_cfg3_pool_enable_ff;

  assign csr_layer_cfg3_pool_enable_out = csr_layer_cfg3_pool_enable_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg3_pool_enable_ff <= 1'b1;
    end else begin
      if (csr_layer_cfg3_wen) begin
        if (wstrb[0]) begin
          csr_layer_cfg3_pool_enable_ff <= wdata[6];
        end
      end else if (csr_layer_cfg3_pool_enable_en) begin
        csr_layer_cfg3_pool_enable_ff <= csr_layer_cfg3_pool_enable_in;
      end
    end
  end

  reg csr_layer_cfg3_pool_sizeh_ff;

  assign csr_layer_cfg3_rdata[7] = csr_layer_cfg3_pool_sizeh_ff;

  assign csr_layer_cfg3_pool_sizeh_out = csr_layer_cfg3_pool_sizeh_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg3_pool_sizeh_ff <= 1'b1;
    end else begin
      if (csr_layer_cfg3_wen) begin
        if (wstrb[0]) begin
          csr_layer_cfg3_pool_sizeh_ff <= wdata[7];
        end
      end else begin
        csr_layer_cfg3_pool_sizeh_ff <= csr_layer_cfg3_pool_sizeh_ff;
      end
    end
  end

  reg csr_layer_cfg3_pool_sizew_ff;

  assign csr_layer_cfg3_rdata[8] = csr_layer_cfg3_pool_sizew_ff;

  assign csr_layer_cfg3_pool_sizew_out = csr_layer_cfg3_pool_sizew_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg3_pool_sizew_ff <= 1'b1;
    end else begin
      if (csr_layer_cfg3_wen) begin
        if (wstrb[1]) begin
          csr_layer_cfg3_pool_sizew_ff <= wdata[8];
        end
      end else begin
        csr_layer_cfg3_pool_sizew_ff <= csr_layer_cfg3_pool_sizew_ff;
      end
    end
  end

  wire [15:0] csr_layer_cfg4_rdata;
  assign csr_layer_cfg4_rdata[3] = 1'b0;
  assign csr_layer_cfg4_rdata[15:11] = 5'h0;

  wire csr_layer_cfg4_wen;
  assign csr_layer_cfg4_wen = wen && (waddr == 8'h4);

  wire csr_layer_cfg4_ren;
  assign csr_layer_cfg4_ren = ren && (raddr == 8'h4);
  reg csr_layer_cfg4_ren_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg4_ren_ff <= 1'b0;
    end else begin
      csr_layer_cfg4_ren_ff <= csr_layer_cfg4_ren;
    end
  end

  reg [2:0] csr_layer_cfg4_cur_act_frac_width_ff;

  assign csr_layer_cfg4_rdata[2:0] = csr_layer_cfg4_cur_act_frac_width_ff;

  assign csr_layer_cfg4_cur_act_frac_width_out = csr_layer_cfg4_cur_act_frac_width_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg4_cur_act_frac_width_ff <= 3'h6;
    end else begin
      if (csr_layer_cfg4_wen) begin
        if (wstrb[0]) begin
          csr_layer_cfg4_cur_act_frac_width_ff[2:0] <= wdata[2:0];
        end
      end else if (csr_layer_cfg4_cur_act_frac_width_en) begin
        csr_layer_cfg4_cur_act_frac_width_ff <= csr_layer_cfg4_cur_act_frac_width_in;
      end
    end
  end

  reg [3:0] csr_layer_cfg4_cur_wgt_frac_width_ff;

  assign csr_layer_cfg4_rdata[7:4] = csr_layer_cfg4_cur_wgt_frac_width_ff;

  assign csr_layer_cfg4_cur_wgt_frac_width_out = csr_layer_cfg4_cur_wgt_frac_width_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg4_cur_wgt_frac_width_ff <= 4'h6;
    end else begin
      if (csr_layer_cfg4_wen) begin
        if (wstrb[0]) begin
          csr_layer_cfg4_cur_wgt_frac_width_ff[3:0] <= wdata[7:4];
        end
      end else if (csr_layer_cfg4_cur_wgt_frac_width_en) begin
        csr_layer_cfg4_cur_wgt_frac_width_ff <= csr_layer_cfg4_cur_wgt_frac_width_in;
      end
    end
  end

  reg [2:0] csr_layer_cfg4_nxt_act_frac_width_ff;

  assign csr_layer_cfg4_rdata[10:8] = csr_layer_cfg4_nxt_act_frac_width_ff;

  assign csr_layer_cfg4_nxt_act_frac_width_out = csr_layer_cfg4_nxt_act_frac_width_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_layer_cfg4_nxt_act_frac_width_ff <= 3'h4;
    end else begin
      if (csr_layer_cfg4_wen) begin
        if (wstrb[1]) begin
          csr_layer_cfg4_nxt_act_frac_width_ff[2:0] <= wdata[10:8];
        end
      end else if (csr_layer_cfg4_nxt_act_frac_width_en) begin
        csr_layer_cfg4_nxt_act_frac_width_ff <= csr_layer_cfg4_nxt_act_frac_width_in;
      end
    end
  end

  wire [15:0] csr_model_cfg0_rdata;
  assign csr_model_cfg0_rdata[7:5]   = 3'h0;
  assign csr_model_cfg0_rdata[15:12] = 4'h0;

  wire csr_model_cfg0_wen;
  assign csr_model_cfg0_wen = wen && (waddr == 8'h7);

  wire csr_model_cfg0_ren;
  assign csr_model_cfg0_ren = ren && (raddr == 8'h7);
  reg csr_model_cfg0_ren_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_model_cfg0_ren_ff <= 1'b0;
    end else begin
      csr_model_cfg0_ren_ff <= csr_model_cfg0_ren;
    end
  end

  reg [4:0] csr_model_cfg0_layer_num_ff;

  assign csr_model_cfg0_rdata[4:0] = csr_model_cfg0_layer_num_ff;

  assign csr_model_cfg0_layer_num_out = csr_model_cfg0_layer_num_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_model_cfg0_layer_num_ff <= 5'h7;
    end else begin
      if (csr_model_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_model_cfg0_layer_num_ff[4:0] <= wdata[4:0];
        end
      end else begin
        csr_model_cfg0_layer_num_ff <= csr_model_cfg0_layer_num_ff;
      end
    end
  end

  reg [2:0] csr_model_cfg0_out_cls_num_ff;

  assign csr_model_cfg0_rdata[10:8] = csr_model_cfg0_out_cls_num_ff;

  assign csr_model_cfg0_out_cls_num_out = csr_model_cfg0_out_cls_num_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_model_cfg0_out_cls_num_ff <= 3'h1;
    end else begin
      if (csr_model_cfg0_wen) begin
        if (wstrb[1]) begin
          csr_model_cfg0_out_cls_num_ff[2:0] <= wdata[10:8];
        end
      end else begin
        csr_model_cfg0_out_cls_num_ff <= csr_model_cfg0_out_cls_num_ff;
      end
    end
  end

  reg csr_model_cfg0_last_pool_type_ff;

  assign csr_model_cfg0_rdata[11] = csr_model_cfg0_last_pool_type_ff;

  assign csr_model_cfg0_last_pool_type_out = csr_model_cfg0_last_pool_type_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_model_cfg0_last_pool_type_ff <= 1'b0;
    end else begin
      if (csr_model_cfg0_wen) begin
        if (wstrb[1]) begin
          csr_model_cfg0_last_pool_type_ff <= wdata[11];
        end
      end else begin
        csr_model_cfg0_last_pool_type_ff <= csr_model_cfg0_last_pool_type_ff;
      end
    end
  end

  wire [15:0] csr_model_cfg1_rdata;
  assign csr_model_cfg1_rdata[15:12] = 4'h0;

  wire csr_model_cfg1_wen;
  assign csr_model_cfg1_wen = wen && (waddr == 8'h8);

  wire csr_model_cfg1_ren;
  assign csr_model_cfg1_ren = ren && (raddr == 8'h8);
  reg csr_model_cfg1_ren_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_model_cfg1_ren_ff <= 1'b0;
    end else begin
      csr_model_cfg1_ren_ff <= csr_model_cfg1_ren;
    end
  end

  reg [11:0] csr_model_cfg1_in_act_num_ff;

  assign csr_model_cfg1_rdata[11:0] = csr_model_cfg1_in_act_num_ff;

  assign csr_model_cfg1_in_act_num_out = csr_model_cfg1_in_act_num_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_model_cfg1_in_act_num_ff <= 12'hfff;
    end else begin
      if (csr_model_cfg1_wen) begin
        if (wstrb[0]) begin
          csr_model_cfg1_in_act_num_ff[7:0] <= wdata[7:0];
        end
        if (wstrb[1]) begin
          csr_model_cfg1_in_act_num_ff[11:8] <= wdata[11:8];
        end
      end else begin
        csr_model_cfg1_in_act_num_ff <= csr_model_cfg1_in_act_num_ff;
      end
    end
  end

  wire [15:0] csr_spi_cfg0_rdata;
  assign csr_spi_cfg0_rdata[15:1] = 15'h0;

  wire csr_spi_cfg0_wen;
  assign csr_spi_cfg0_wen = wen && (waddr == 8'h9);

  wire csr_spi_cfg0_ren;
  assign csr_spi_cfg0_ren = ren && (raddr == 8'h9);
  reg csr_spi_cfg0_ren_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_spi_cfg0_ren_ff <= 1'b0;
    end else begin
      csr_spi_cfg0_ren_ff <= csr_spi_cfg0_ren;
    end
  end

  reg csr_spi_cfg0_spi_wr_mode_ff;

  assign csr_spi_cfg0_rdata[0] = csr_spi_cfg0_spi_wr_mode_ff;

  assign csr_spi_cfg0_spi_wr_mode_out = csr_spi_cfg0_spi_wr_mode_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_spi_cfg0_spi_wr_mode_ff <= 1'b0;
    end else begin
      if (csr_spi_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_spi_cfg0_spi_wr_mode_ff <= wdata[0];
        end
      end else begin
        csr_spi_cfg0_spi_wr_mode_ff <= csr_spi_cfg0_spi_wr_mode_ff;
      end
    end
  end

  wire [15:0] csr_chip_cfg0_rdata;
  assign csr_chip_cfg0_rdata[15:1] = 15'h0;

  wire csr_chip_cfg0_wen;
  assign csr_chip_cfg0_wen = wen && (waddr == 8'ha);

  wire csr_chip_cfg0_ren;
  assign csr_chip_cfg0_ren = ren && (raddr == 8'ha);
  reg csr_chip_cfg0_ren_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_chip_cfg0_ren_ff <= 1'b0;
    end else begin
      csr_chip_cfg0_ren_ff <= csr_chip_cfg0_ren;
    end
  end

  reg csr_chip_cfg0_frame_ready_ff;

  assign csr_chip_cfg0_rdata[0] = csr_chip_cfg0_frame_ready_ff;

  assign csr_chip_cfg0_frame_ready_out = csr_chip_cfg0_frame_ready_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_chip_cfg0_frame_ready_ff <= 1'b0;
    end else begin
      if (csr_chip_cfg0_frame_ready_set) begin
        csr_chip_cfg0_frame_ready_ff <= 1'b1;
      end else if (csr_chip_cfg0_frame_ready_clr) begin
        csr_chip_cfg0_frame_ready_ff <= 1'b0;
      end else if (csr_chip_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_chip_cfg0_frame_ready_ff <= wdata[0];
        end
      end else begin
        csr_chip_cfg0_frame_ready_ff <= csr_chip_cfg0_frame_ready_ff;
      end
    end
  end

  wire [15:0] csr_pad_cfg0_rdata;
  assign csr_pad_cfg0_rdata[15:6] = 10'h0;

  wire csr_pad_cfg0_wen;
  assign csr_pad_cfg0_wen = wen && (waddr == 8'hb);

  wire csr_pad_cfg0_ren;
  assign csr_pad_cfg0_ren = ren && (raddr == 8'hb);
  reg csr_pad_cfg0_ren_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_pad_cfg0_ren_ff <= 1'b0;
    end else begin
      csr_pad_cfg0_ren_ff <= csr_pad_cfg0_ren;
    end
  end

  reg csr_pad_cfg0_ds0_ff;

  assign csr_pad_cfg0_rdata[0] = csr_pad_cfg0_ds0_ff;

  assign csr_pad_cfg0_ds0_out  = csr_pad_cfg0_ds0_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_pad_cfg0_ds0_ff <= 1'b0;
    end else begin
      if (csr_pad_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_pad_cfg0_ds0_ff <= wdata[0];
        end
      end else begin
        csr_pad_cfg0_ds0_ff <= csr_pad_cfg0_ds0_ff;
      end
    end
  end

  reg csr_pad_cfg0_ds1_ff;

  assign csr_pad_cfg0_rdata[1] = csr_pad_cfg0_ds1_ff;

  assign csr_pad_cfg0_ds1_out  = csr_pad_cfg0_ds1_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_pad_cfg0_ds1_ff <= 1'b0;
    end else begin
      if (csr_pad_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_pad_cfg0_ds1_ff <= wdata[1];
        end
      end else begin
        csr_pad_cfg0_ds1_ff <= csr_pad_cfg0_ds1_ff;
      end
    end
  end

  reg csr_pad_cfg0_pe_ff;

  assign csr_pad_cfg0_rdata[2] = csr_pad_cfg0_pe_ff;

  assign csr_pad_cfg0_pe_out   = csr_pad_cfg0_pe_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_pad_cfg0_pe_ff <= 1'b0;
    end else begin
      if (csr_pad_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_pad_cfg0_pe_ff <= wdata[2];
        end
      end else begin
        csr_pad_cfg0_pe_ff <= csr_pad_cfg0_pe_ff;
      end
    end
  end

  reg csr_pad_cfg0_ps_ff;

  assign csr_pad_cfg0_rdata[3] = csr_pad_cfg0_ps_ff;

  assign csr_pad_cfg0_ps_out   = csr_pad_cfg0_ps_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_pad_cfg0_ps_ff <= 1'b0;
    end else begin
      if (csr_pad_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_pad_cfg0_ps_ff <= wdata[3];
        end
      end else begin
        csr_pad_cfg0_ps_ff <= csr_pad_cfg0_ps_ff;
      end
    end
  end

  reg csr_pad_cfg0_sr_ff;

  assign csr_pad_cfg0_rdata[4] = csr_pad_cfg0_sr_ff;

  assign csr_pad_cfg0_sr_out   = csr_pad_cfg0_sr_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_pad_cfg0_sr_ff <= 1'b0;
    end else begin
      if (csr_pad_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_pad_cfg0_sr_ff <= wdata[4];
        end
      end else begin
        csr_pad_cfg0_sr_ff <= csr_pad_cfg0_sr_ff;
      end
    end
  end

  reg csr_pad_cfg0_lpm_ff;

  assign csr_pad_cfg0_rdata[5] = csr_pad_cfg0_lpm_ff;

  assign csr_pad_cfg0_lpm_out  = csr_pad_cfg0_lpm_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_pad_cfg0_lpm_ff <= 1'b0;
    end else begin
      if (csr_pad_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_pad_cfg0_lpm_ff <= wdata[5];
        end
      end else begin
        csr_pad_cfg0_lpm_ff <= csr_pad_cfg0_lpm_ff;
      end
    end
  end

  wire [15:0] csr_mem_cfg0_rdata;
  assign csr_mem_cfg0_rdata[15:6] = 10'h0;

  wire csr_mem_cfg0_wen;
  assign csr_mem_cfg0_wen = wen && (waddr == 8'h10);

  wire csr_mem_cfg0_ren;
  assign csr_mem_cfg0_ren = ren && (raddr == 8'h10);
  reg csr_mem_cfg0_ren_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg0_ren_ff <= 1'b0;
    end else begin
      csr_mem_cfg0_ren_ff <= csr_mem_cfg0_ren;
    end
  end

  reg csr_mem_cfg0_mem_in_act_ceb_ff;

  assign csr_mem_cfg0_rdata[0] = csr_mem_cfg0_mem_in_act_ceb_ff;

  assign csr_mem_cfg0_mem_in_act_ceb_out = csr_mem_cfg0_mem_in_act_ceb_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg0_mem_in_act_ceb_ff <= 1'b0;
    end else begin
      if (csr_mem_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg0_mem_in_act_ceb_ff <= wdata[0];
        end
      end else begin
        csr_mem_cfg0_mem_in_act_ceb_ff <= csr_mem_cfg0_mem_in_act_ceb_ff;
      end
    end
  end

  reg csr_mem_cfg0_mem_in_wgt_ceb_ff;

  assign csr_mem_cfg0_rdata[1] = csr_mem_cfg0_mem_in_wgt_ceb_ff;

  assign csr_mem_cfg0_mem_in_wgt_ceb_out = csr_mem_cfg0_mem_in_wgt_ceb_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg0_mem_in_wgt_ceb_ff <= 1'b0;
    end else begin
      if (csr_mem_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg0_mem_in_wgt_ceb_ff <= wdata[1];
        end
      end else begin
        csr_mem_cfg0_mem_in_wgt_ceb_ff <= csr_mem_cfg0_mem_in_wgt_ceb_ff;
      end
    end
  end

  reg csr_mem_cfg0_mem_in_fc_wgt_ceb_ff;

  assign csr_mem_cfg0_rdata[2] = csr_mem_cfg0_mem_in_fc_wgt_ceb_ff;

  assign csr_mem_cfg0_mem_in_fc_wgt_ceb_out = csr_mem_cfg0_mem_in_fc_wgt_ceb_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg0_mem_in_fc_wgt_ceb_ff <= 1'b0;
    end else begin
      if (csr_mem_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg0_mem_in_fc_wgt_ceb_ff <= wdata[2];
        end
      end else begin
        csr_mem_cfg0_mem_in_fc_wgt_ceb_ff <= csr_mem_cfg0_mem_in_fc_wgt_ceb_ff;
      end
    end
  end

  reg csr_mem_cfg0_mem_in_bias_ceb_ff;

  assign csr_mem_cfg0_rdata[3] = csr_mem_cfg0_mem_in_bias_ceb_ff;

  assign csr_mem_cfg0_mem_in_bias_ceb_out = csr_mem_cfg0_mem_in_bias_ceb_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg0_mem_in_bias_ceb_ff <= 1'b0;
    end else begin
      if (csr_mem_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg0_mem_in_bias_ceb_ff <= wdata[3];
        end
      end else begin
        csr_mem_cfg0_mem_in_bias_ceb_ff <= csr_mem_cfg0_mem_in_bias_ceb_ff;
      end
    end
  end

  reg csr_mem_cfg0_mem_in_instr_ceb_ff;

  assign csr_mem_cfg0_rdata[4] = csr_mem_cfg0_mem_in_instr_ceb_ff;

  assign csr_mem_cfg0_mem_in_instr_ceb_out = csr_mem_cfg0_mem_in_instr_ceb_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg0_mem_in_instr_ceb_ff <= 1'b0;
    end else begin
      if (csr_mem_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg0_mem_in_instr_ceb_ff <= wdata[4];
        end
      end else begin
        csr_mem_cfg0_mem_in_instr_ceb_ff <= csr_mem_cfg0_mem_in_instr_ceb_ff;
      end
    end
  end

  reg csr_mem_cfg0_mem_out_act_ceb_ff;

  assign csr_mem_cfg0_rdata[5] = csr_mem_cfg0_mem_out_act_ceb_ff;

  assign csr_mem_cfg0_mem_out_act_ceb_out = csr_mem_cfg0_mem_out_act_ceb_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg0_mem_out_act_ceb_ff <= 1'b0;
    end else begin
      if (csr_mem_cfg0_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg0_mem_out_act_ceb_ff <= wdata[5];
        end
      end else begin
        csr_mem_cfg0_mem_out_act_ceb_ff <= csr_mem_cfg0_mem_out_act_ceb_ff;
      end
    end
  end

  wire [15:0] csr_mem_cfg1_aux_rdata;
  assign csr_mem_cfg1_aux_rdata[15:8] = 8'h0;

  wire csr_mem_cfg1_aux_wen;
  assign csr_mem_cfg1_aux_wen = wen && (waddr == 8'h11);

  wire csr_mem_cfg1_aux_ren;
  assign csr_mem_cfg1_aux_ren = ren && (raddr == 8'h11);
  reg csr_mem_cfg1_aux_ren_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg1_aux_ren_ff <= 1'b0;
    end else begin
      csr_mem_cfg1_aux_ren_ff <= csr_mem_cfg1_aux_ren;
    end
  end

  reg csr_mem_cfg1_aux_cfg0_ff;

  assign csr_mem_cfg1_aux_rdata[0] = csr_mem_cfg1_aux_cfg0_ff;

  assign csr_mem_cfg1_aux_cfg0_out = csr_mem_cfg1_aux_cfg0_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg1_aux_cfg0_ff <= 1'b0;
    end else begin
      if (csr_mem_cfg1_aux_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg1_aux_cfg0_ff <= wdata[0];
        end
      end else begin
        csr_mem_cfg1_aux_cfg0_ff <= csr_mem_cfg1_aux_cfg0_ff;
      end
    end
  end

  reg csr_mem_cfg1_aux_cfg1_ff;

  assign csr_mem_cfg1_aux_rdata[1] = csr_mem_cfg1_aux_cfg1_ff;

  assign csr_mem_cfg1_aux_cfg1_out = csr_mem_cfg1_aux_cfg1_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg1_aux_cfg1_ff <= 1'b1;
    end else begin
      if (csr_mem_cfg1_aux_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg1_aux_cfg1_ff <= wdata[1];
        end
      end else begin
        csr_mem_cfg1_aux_cfg1_ff <= csr_mem_cfg1_aux_cfg1_ff;
      end
    end
  end

  reg [2:0] csr_mem_cfg1_aux_cfg2_ff;

  assign csr_mem_cfg1_aux_rdata[4:2] = csr_mem_cfg1_aux_cfg2_ff;

  assign csr_mem_cfg1_aux_cfg2_out   = csr_mem_cfg1_aux_cfg2_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg1_aux_cfg2_ff <= 3'h7;
    end else begin
      if (csr_mem_cfg1_aux_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg1_aux_cfg2_ff[2:0] <= wdata[4:2];
        end
      end else begin
        csr_mem_cfg1_aux_cfg2_ff <= csr_mem_cfg1_aux_cfg2_ff;
      end
    end
  end

  reg [1:0] csr_mem_cfg1_aux_cfg3_ff;

  assign csr_mem_cfg1_aux_rdata[6:5] = csr_mem_cfg1_aux_cfg3_ff;

  assign csr_mem_cfg1_aux_cfg3_out   = csr_mem_cfg1_aux_cfg3_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg1_aux_cfg3_ff <= 2'h3;
    end else begin
      if (csr_mem_cfg1_aux_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg1_aux_cfg3_ff[1:0] <= wdata[6:5];
        end
      end else begin
        csr_mem_cfg1_aux_cfg3_ff <= csr_mem_cfg1_aux_cfg3_ff;
      end
    end
  end

  reg csr_mem_cfg1_aux_cfg4_ff;

  assign csr_mem_cfg1_aux_rdata[7] = csr_mem_cfg1_aux_cfg4_ff;

  assign csr_mem_cfg1_aux_cfg4_out = csr_mem_cfg1_aux_cfg4_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg1_aux_cfg4_ff <= 1'b1;
    end else begin
      if (csr_mem_cfg1_aux_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg1_aux_cfg4_ff <= wdata[7];
        end
      end else begin
        csr_mem_cfg1_aux_cfg4_ff <= csr_mem_cfg1_aux_cfg4_ff;
      end
    end
  end

  wire [15:0] csr_mem_cfg3_act_rdata;
  assign csr_mem_cfg3_act_rdata[15:11] = 5'h0;

  wire csr_mem_cfg3_act_wen;
  assign csr_mem_cfg3_act_wen = wen && (waddr == 8'h13);

  wire csr_mem_cfg3_act_ren;
  assign csr_mem_cfg3_act_ren = ren && (raddr == 8'h13);
  reg csr_mem_cfg3_act_ren_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg3_act_ren_ff <= 1'b0;
    end else begin
      csr_mem_cfg3_act_ren_ff <= csr_mem_cfg3_act_ren;
    end
  end

  reg csr_mem_cfg3_act_cfg0_ff;

  assign csr_mem_cfg3_act_rdata[0] = csr_mem_cfg3_act_cfg0_ff;

  assign csr_mem_cfg3_act_cfg0_out = csr_mem_cfg3_act_cfg0_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg3_act_cfg0_ff <= 1'b0;
    end else begin
      if (csr_mem_cfg3_act_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg3_act_cfg0_ff <= wdata[0];
        end
      end else begin
        csr_mem_cfg3_act_cfg0_ff <= csr_mem_cfg3_act_cfg0_ff;
      end
    end
  end

  reg csr_mem_cfg3_act_cfg1_ff;

  assign csr_mem_cfg3_act_rdata[1] = csr_mem_cfg3_act_cfg1_ff;

  assign csr_mem_cfg3_act_cfg1_out = csr_mem_cfg3_act_cfg1_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg3_act_cfg1_ff <= 1'b1;
    end else begin
      if (csr_mem_cfg3_act_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg3_act_cfg1_ff <= wdata[1];
        end
      end else begin
        csr_mem_cfg3_act_cfg1_ff <= csr_mem_cfg3_act_cfg1_ff;
      end
    end
  end

  reg [2:0] csr_mem_cfg3_act_cfg2_ff;

  assign csr_mem_cfg3_act_rdata[4:2] = csr_mem_cfg3_act_cfg2_ff;

  assign csr_mem_cfg3_act_cfg2_out   = csr_mem_cfg3_act_cfg2_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg3_act_cfg2_ff <= 3'h7;
    end else begin
      if (csr_mem_cfg3_act_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg3_act_cfg2_ff[2:0] <= wdata[4:2];
        end
      end else begin
        csr_mem_cfg3_act_cfg2_ff <= csr_mem_cfg3_act_cfg2_ff;
      end
    end
  end

  reg [1:0] csr_mem_cfg3_act_cfg3_ff;

  assign csr_mem_cfg3_act_rdata[6:5] = csr_mem_cfg3_act_cfg3_ff;

  assign csr_mem_cfg3_act_cfg3_out   = csr_mem_cfg3_act_cfg3_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg3_act_cfg3_ff <= 2'h3;
    end else begin
      if (csr_mem_cfg3_act_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg3_act_cfg3_ff[1:0] <= wdata[6:5];
        end
      end else begin
        csr_mem_cfg3_act_cfg3_ff <= csr_mem_cfg3_act_cfg3_ff;
      end
    end
  end

  reg csr_mem_cfg3_act_cfg4_ff;

  assign csr_mem_cfg3_act_rdata[7] = csr_mem_cfg3_act_cfg4_ff;

  assign csr_mem_cfg3_act_cfg4_out = csr_mem_cfg3_act_cfg4_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg3_act_cfg4_ff <= 1'b1;
    end else begin
      if (csr_mem_cfg3_act_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg3_act_cfg4_ff <= wdata[7];
        end
      end else begin
        csr_mem_cfg3_act_cfg4_ff <= csr_mem_cfg3_act_cfg4_ff;
      end
    end
  end

  reg csr_mem_cfg3_act_cfg5_ff;

  assign csr_mem_cfg3_act_rdata[8] = csr_mem_cfg3_act_cfg5_ff;

  assign csr_mem_cfg3_act_cfg5_out = csr_mem_cfg3_act_cfg5_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg3_act_cfg5_ff <= 1'b1;
    end else begin
      if (csr_mem_cfg3_act_wen) begin
        if (wstrb[1]) begin
          csr_mem_cfg3_act_cfg5_ff <= wdata[8];
        end
      end else begin
        csr_mem_cfg3_act_cfg5_ff <= csr_mem_cfg3_act_cfg5_ff;
      end
    end
  end

  reg [1:0] csr_mem_cfg3_act_cfg6_ff;

  assign csr_mem_cfg3_act_rdata[10:9] = csr_mem_cfg3_act_cfg6_ff;

  assign csr_mem_cfg3_act_cfg6_out = csr_mem_cfg3_act_cfg6_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg3_act_cfg6_ff <= 2'h0;
    end else begin
      if (csr_mem_cfg3_act_wen) begin
        if (wstrb[1]) begin
          csr_mem_cfg3_act_cfg6_ff[1:0] <= wdata[10:9];
        end
      end else begin
        csr_mem_cfg3_act_cfg6_ff <= csr_mem_cfg3_act_cfg6_ff;
      end
    end
  end

  wire [15:0] csr_mem_cfg4_wgt_rdata;
  assign csr_mem_cfg4_wgt_rdata[15:8] = 8'h0;

  wire csr_mem_cfg4_wgt_wen;
  assign csr_mem_cfg4_wgt_wen = wen && (waddr == 8'h14);

  wire csr_mem_cfg4_wgt_ren;
  assign csr_mem_cfg4_wgt_ren = ren && (raddr == 8'h14);
  reg csr_mem_cfg4_wgt_ren_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg4_wgt_ren_ff <= 1'b0;
    end else begin
      csr_mem_cfg4_wgt_ren_ff <= csr_mem_cfg4_wgt_ren;
    end
  end

  reg csr_mem_cfg4_wgt_cfg0_ff;

  assign csr_mem_cfg4_wgt_rdata[0] = csr_mem_cfg4_wgt_cfg0_ff;

  assign csr_mem_cfg4_wgt_cfg0_out = csr_mem_cfg4_wgt_cfg0_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg4_wgt_cfg0_ff <= 1'b0;
    end else begin
      if (csr_mem_cfg4_wgt_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg4_wgt_cfg0_ff <= wdata[0];
        end
      end else begin
        csr_mem_cfg4_wgt_cfg0_ff <= csr_mem_cfg4_wgt_cfg0_ff;
      end
    end
  end

  reg csr_mem_cfg4_wgt_cfg1_ff;

  assign csr_mem_cfg4_wgt_rdata[1] = csr_mem_cfg4_wgt_cfg1_ff;

  assign csr_mem_cfg4_wgt_cfg1_out = csr_mem_cfg4_wgt_cfg1_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg4_wgt_cfg1_ff <= 1'b1;
    end else begin
      if (csr_mem_cfg4_wgt_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg4_wgt_cfg1_ff <= wdata[1];
        end
      end else begin
        csr_mem_cfg4_wgt_cfg1_ff <= csr_mem_cfg4_wgt_cfg1_ff;
      end
    end
  end

  reg [2:0] csr_mem_cfg4_wgt_cfg2_ff;

  assign csr_mem_cfg4_wgt_rdata[4:2] = csr_mem_cfg4_wgt_cfg2_ff;

  assign csr_mem_cfg4_wgt_cfg2_out   = csr_mem_cfg4_wgt_cfg2_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg4_wgt_cfg2_ff <= 3'h7;
    end else begin
      if (csr_mem_cfg4_wgt_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg4_wgt_cfg2_ff[2:0] <= wdata[4:2];
        end
      end else begin
        csr_mem_cfg4_wgt_cfg2_ff <= csr_mem_cfg4_wgt_cfg2_ff;
      end
    end
  end

  reg [1:0] csr_mem_cfg4_wgt_cfg3_ff;

  assign csr_mem_cfg4_wgt_rdata[6:5] = csr_mem_cfg4_wgt_cfg3_ff;

  assign csr_mem_cfg4_wgt_cfg3_out   = csr_mem_cfg4_wgt_cfg3_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg4_wgt_cfg3_ff <= 2'h3;
    end else begin
      if (csr_mem_cfg4_wgt_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg4_wgt_cfg3_ff[1:0] <= wdata[6:5];
        end
      end else begin
        csr_mem_cfg4_wgt_cfg3_ff <= csr_mem_cfg4_wgt_cfg3_ff;
      end
    end
  end

  reg csr_mem_cfg4_wgt_cfg4_ff;

  assign csr_mem_cfg4_wgt_rdata[7] = csr_mem_cfg4_wgt_cfg4_ff;

  assign csr_mem_cfg4_wgt_cfg4_out = csr_mem_cfg4_wgt_cfg4_ff;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      csr_mem_cfg4_wgt_cfg4_ff <= 1'b1;
    end else begin
      if (csr_mem_cfg4_wgt_wen) begin
        if (wstrb[0]) begin
          csr_mem_cfg4_wgt_cfg4_ff <= wdata[7];
        end
      end else begin
        csr_mem_cfg4_wgt_cfg4_ff <= csr_mem_cfg4_wgt_cfg4_ff;
      end
    end
  end

  assign wready = 1'b1;

  reg [15:0] rdata_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      rdata_ff <= 16'h0;
    end else if (ren) begin
      case (raddr)
        8'h0: rdata_ff <= csr_layer_cfg0_rdata;
        8'h1: rdata_ff <= csr_layer_cfg1_rdata;
        8'h2: rdata_ff <= csr_layer_cfg2_rdata;
        8'h3: rdata_ff <= csr_layer_cfg3_rdata;
        8'h4: rdata_ff <= csr_layer_cfg4_rdata;
        8'h7: rdata_ff <= csr_model_cfg0_rdata;
        8'h8: rdata_ff <= csr_model_cfg1_rdata;
        8'h9: rdata_ff <= csr_spi_cfg0_rdata;
        8'ha: rdata_ff <= csr_chip_cfg0_rdata;
        8'hb: rdata_ff <= csr_pad_cfg0_rdata;
        8'h10: rdata_ff <= csr_mem_cfg0_rdata;
        8'h11: rdata_ff <= csr_mem_cfg1_aux_rdata;
        8'h13: rdata_ff <= csr_mem_cfg3_act_rdata;
        8'h14: rdata_ff <= csr_mem_cfg4_wgt_rdata;
        default: rdata_ff <= 16'h0;
      endcase
    end else begin
      rdata_ff <= 16'h0;
    end
  end
  assign rdata = rdata_ff;

  reg rvalid_ff;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      rvalid_ff <= 1'b0;
    end else if (ren && rvalid) begin
      rvalid_ff <= 1'b0;
    end else if (ren) begin
      rvalid_ff <= 1'b1;
    end
  end

  assign rvalid = rvalid_ff;

endmodule
