`timescale 1ns / 1ps

`include "lfsr_rng.sv"

module rng #(
    parameter OUTPUT_WIDTH = 8
) (
    output logic [OUTPUT_WIDTH - 1:0] rnd1,
    output logic [OUTPUT_WIDTH - 1:0] rnd2,
    input  logic [31:0] seed,
    input  logic reset,
    input  logic clk
);

    wire [31:0] seed2;
    wire [31:0] lfsr_rnd1;
    wire [31:0] lfsr_rnd2;

    assign seed2 = {seed[31:24], seed[7:0], seed[23:16], ~seed[15:8]};

    generate
        if (OUTPUT_WIDTH == 8) begin
            assign rnd1 = {lfsr_rnd1[31:30], lfsr_rnd1[21:20], lfsr_rnd1[3:0]};
            assign rnd2 = {lfsr_rnd2[31:30], lfsr_rnd2[21:20], lfsr_rnd2[3:0]};
        end else if (OUTPUT_WIDTH == 16) begin
            assign rnd1 = {lfsr_rnd1[31], lfsr_rnd1[21], lfsr_rnd1[13:0]};
            assign rnd2 = {lfsr_rnd2[31], lfsr_rnd2[21], lfsr_rnd2[13:0]};
        end else begin
            assign rnd1 = lfsr_rnd1;
            assign rnd2 = lfsr_rnd2;
        end
    endgenerate

    lfsr_rng rng1 (
        .rnd   (lfsr_rnd1),
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );

    lfsr_rng rng2 (
        .rnd   (lfsr_rnd2),
        .seed  (seed2),
        .reset (reset),
        .clk   (clk)
    );
endmodule
