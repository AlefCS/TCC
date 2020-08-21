`timescale 1ns / 1ps

module rng (
    output logic [31:0] rnd1,
    output logic [31:0] rnd2,
    input  logic [31:0] seed,
    input  logic reset,
    input  logic clk
);
    wire [31:0] seed2;
    assign seed2 = ~seed;

    lfsr_rng rng1 (
        .rnd   (rnd1),
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );

    lfsr_rng rng2 (
        .rnd   (rnd2),
        .seed  (seed2),
        .reset (reset),
        .clk   (clk)
    );
endmodule
