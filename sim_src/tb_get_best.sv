`timescale 1ns / 1ps

`include "../src/rng8.sv"
`include "../src/fitness_function.sv"
`include "../src/get_best.sv"

`define FIT_WIDTH    27
`define CHROM_WIDTH   8

module tb_get_best ();
    logic unsigned   [`FIT_WIDTH - 1:0] best_fit;
    logic unsigned [`CHROM_WIDTH - 1:0] best;
    logic unsigned   [`FIT_WIDTH - 1:0] fitness1;
    logic unsigned   [`FIT_WIDTH - 1:0] fitness2;
    logic unsigned [`CHROM_WIDTH - 1:0] chrom1;
    logic unsigned [`CHROM_WIDTH - 1:0] chrom2;
    logic enable_second;
    logic reset;
    logic clk;

    reg rng_reset;

    initial begin
        clk = 0;
        reset = 1;
        rng_reset = 1;
        enable_second = 1;

        @ (posedge clk);
        @ (negedge clk);

        rng_reset = 0;

        @ (posedge clk);
        @ (negedge clk);

        // fill ff "pipeline"

        @ (posedge clk);
        @ (negedge clk);

        reset = 0;

        #100

        $finish();
    end

    always @(posedge clk) begin
        if (!rng.reset) begin
            chrom1 <= rng.rnd1;
            chrom2 <= rng.rnd2;
        end
    end

    always begin
        #5 clk = ~clk;
    end

    get_best #(
        `FIT_WIDTH,
        `CHROM_WIDTH
    ) DUT (
        .best          (best),
        .best_fit      (best_fit),
        .fitness1      (fitness1),
        .fitness2      (fitness2),
        .chrom1        (chrom1),
        .chrom2        (chrom2),
        .enable_second (enable_second),
        .reset         (reset),
        .clk           (clk)
    );

    fitness_function ff (
        .fitness1 (fitness1),
        .fitness2 (fitness2),
        .chrom1   (rng.rnd1),
        .chrom2   (rng.rnd2),
        .enable   (1'b1),
        .clk      (clk)
    );

    rng8 rng (
        .seed  (32'hCDE5_A1EF),
        .reset (rng_reset),
        .clk   (clk)
    );
endmodule
