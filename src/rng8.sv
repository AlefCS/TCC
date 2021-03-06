`timescale 1ns / 1ps

module rng8 (
    output logic [7:0] rnd1,
    output logic [7:0] rnd2,
    input  logic [31:0] seed,
    input  logic reset,
    input  logic clk
);

    wire [31:0] seed2;
    wire [31:0] lfsr_rnd1;
    wire [31:0] lfsr_rnd2;

    assign seed2 = ~seed;

    assign rnd1 = {lfsr_rnd1[31:30], lfsr_rnd1[21:20], lfsr_rnd1[3:0]};
    assign rnd2 = {lfsr_rnd2[31:30], lfsr_rnd2[21:20], lfsr_rnd2[3:0]};

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
