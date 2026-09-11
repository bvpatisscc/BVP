`timescale 1ns / 1ps

module sync_fifo_ram_flush #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 8
) (
    input  logic                  clk,
    input  logic                  arst_n,
    input  logic                  flush_fifo,
    input  logic                  wren,
    input  logic [DATA_WIDTH-1:0] wdata,
    output logic                  wfull,

    input  logic                  rden,
    output logic [DATA_WIDTH-1:0] rdata,
    output logic                  rempty
);

  logic [$clog2(FIFO_DEPTH)-1:0] wrptr_rg;
  logic [$clog2(FIFO_DEPTH)-1:0] rdptr_rg;
  logic [$clog2(FIFO_DEPTH)-1:0] nxt_rdptr;
  logic [$clog2(FIFO_DEPTH)-1:0] rdaddr;

  logic                          wren_s;
  logic                          rden_s;
  logic                          full_s;
  logic                          empty_s;
  logic                          empty_rg;
  logic                          state_rg;
  logic                          ex_rg;
  logic                          wrptr_reset;
  logic                          rdptr_reset;

  dual_port_ram #(
      .DATA_WIDTH(DATA_WIDTH),
      .FIFO_DEPTH(FIFO_DEPTH)
  ) ram (
      .clk(clk),

      .wren (wren),
      .waddr(wrptr_rg),
      .wdata(wdata),

      .raddr(rdaddr),
      .rdata(rdata)
  );

  always @(posedge clk or negedge arst_n) begin

    if (!arst_n) begin

      wrptr_rg <= 0;
      rdptr_rg <= 0;
      state_rg <= 1'b0;
      ex_rg    <= 1'b0;
      empty_rg <= 1'b1;
    end else begin

      if (flush_fifo) begin
        wrptr_rg <= 0;
      end else if (wren_s) begin
        if (wrptr_reset) begin
          wrptr_rg <= 0;
        end else begin
          wrptr_rg <= wrptr_rg + 1;
        end
      end

      if (flush_fifo) begin
        rdptr_rg <= 0;
      end else if (rden_s) begin
        if (rdptr_reset) begin
          rdptr_rg <= 0;
        end else begin
          rdptr_rg <= rdptr_rg + 1;
        end
      end

      if (flush_fifo) begin
        state_rg <= 1'b0;
      end else if (state_rg == 1'b0) begin
        ex_rg <= 1'b0;
        if (wren_s && !rden_s) begin
          state_rg <= 1'b1;
        end else if (wren_s && rden_s && (rdaddr == wrptr_rg)) begin
          ex_rg <= 1'b1;
        end
      end else begin
        if (!wren_s && rden_s) begin
          state_rg <= 1'b0;
        end
      end

      empty_rg <= empty_s;
    end
  end

  assign wrptr_reset = (wrptr_rg == FIFO_DEPTH - 1);
  assign rdptr_reset = (rdptr_rg == FIFO_DEPTH - 1);

  assign full_s      = (wrptr_rg == rdptr_rg) && (state_rg == 1'b1);
  assign empty_s     = ((wrptr_rg == rdptr_rg) && (state_rg == 1'b0)) || ex_rg;

  assign wren_s      = wren & !full_s;
  assign rden_s      = rden & !empty_s & !empty_rg;

  assign wfull       = full_s;
  assign rempty      = empty_s || empty_rg;

  assign nxt_rdptr   = (rdptr_rg == FIFO_DEPTH - 1) ? 'b0 : rdptr_rg + 1;
  assign rdaddr      = rden_s ? nxt_rdptr : rdptr_rg;

endmodule
