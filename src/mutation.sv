`timescale 1ns / 1ps

`include "lfsr_rng.sv"

module mutation #(
    parameter CHROM_WIDTH = 8,
    parameter MUT_RATE = 12              // $floor(0.05*256) ou 5%
)(
    output logic [CHROM_WIDTH - 1:0] mut_child1,
    output logic [CHROM_WIDTH - 1:0] mut_child2,
    input  logic [CHROM_WIDTH - 1:0] orig_child1,
    input  logic [CHROM_WIDTH - 1:0] orig_child2,
    input  logic [CHROM_WIDTH - 1:0] seed,
    input  logic reset,
    input  logic clk
);
    genvar i;
    generate
        for (i = 0; i < `CHROM_WIDTH; i = i + 1) begin : rng_genblk
            wire unsigned [7:0] rnd;

            lfsr_rng #(8) rng (
                .rnd   (rnd),
                .seed  (seed + i*(8'h5C)),
                .reset (reset),
                .clk   (clk)
            );

            always @ (posedge clk) begin
                if (rnd < MUT_RATE) begin
                    mut_child1[i] <= orig_child1[i] ^ 1'b1;
                end else begin
                    mut_child1[i] <= orig_child1[i];
                end
            end
        end

        for (i = 0; i < `CHROM_WIDTH; i = i + 1) begin : rng2_genblk
            wire unsigned [7:0] rnd;

            lfsr_rng #(8) rng (
                .rnd   (rnd),
                .seed  ((~seed) + i*(8'h5C)),
                .reset (reset),
                .clk   (clk)
            );

            always @ (posedge clk) begin
                if (rnd < MUT_RATE) begin
                    mut_child2[i] <= orig_child2[i] ^ 1'b1;
                end else begin
                    mut_child2[i] <= orig_child2[i];
                end
            end
        end
    endgenerate
endmodule
