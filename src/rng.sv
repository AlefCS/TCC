`timescale 1ns / 1ps

`include "lfsr_rng.sv"

module rng #(
    parameter OUTPUT_WIDTH = 8
) (
    output logic [OUTPUT_WIDTH - 1:0] rnd1,
    output logic [OUTPUT_WIDTH - 1:0] rnd2,
    input  logic [OUTPUT_WIDTH - 1:0] seed,
    input  logic reset,
    input  logic clk
);

    wire [OUTPUT_WIDTH - 1:0] seed2;

    generate
        if (OUTPUT_WIDTH == 8) begin
            assign seed2 = {seed[7:6], seed[3:2], seed[1:0], seed[5:4]};
        end else if (OUTPUT_WIDTH == 16) begin
            assign seed2 = {seed[11:8], seed[7:4], seed[3:0], seed[15:12]};
        end else begin
            assign seed2 = {seed[31:24], seed[7:0], seed[23:16], seed[15:8]};
        end
    endgenerate

    lfsr_rng #(OUTPUT_WIDTH) rng1 (
        .rnd   (rnd1),
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );

    lfsr_rng #(OUTPUT_WIDTH) rng2 (
        .rnd   (rnd2),
        .seed  (seed2),
        .reset (reset),
        .clk   (clk)
    );
endmodule
