`timescale 1ns / 1ps

`include "lfsr_rng.sv"

`define NUM_OF_RNG CHROM_WIDTH >> 1

module mutation #(
    parameter CHROM_WIDTH = 8,
    parameter MUT_RATE = 12              // $floor(0.05*256) ou 5%
)(
    output logic [CHROM_WIDTH - 1:0] mut_child1,
    output logic [CHROM_WIDTH - 1:0] mut_child2,
    input  logic [CHROM_WIDTH - 1:0] orig_child1,
    input  logic [CHROM_WIDTH - 1:0] orig_child2,
    input  logic [31:0] seed,
    input  logic reset,
    input  logic clk
);
    genvar i, j;
    generate
        for (i = 0; i < `NUM_OF_RNG; i = i + 1) begin : rng_genblk
            wire unsigned [31:0] super_rnd;

            lfsr_rng rng (
                .rnd   (super_rnd),
                .seed  (seed + i*(32'h1248_8421)),
                .reset (reset),
                .clk   (clk)
            );

            for (j = 0; j < 4; j = j + 1) begin
                wire unsigned [7:0] rnd;

                assign rnd = super_rnd[8*(j + 1) - 1 : 8*j];

                always @ (posedge clk) begin
                    if (i < (`NUM_OF_RNG >> 1)) begin
                        if (rnd < MUT_RATE) begin
                            mut_child1[4*i + j] <= orig_child1[4*i + j] ^ 1'b1;
                        end else begin
                            mut_child1[4*i + j] <= orig_child1[4*i + j];
                        end
                    end else begin
                        if (rnd < MUT_RATE) begin
                            mut_child2[4*(i - (`NUM_OF_RNG >> 1)) + j] <= orig_child2[4*(i - (`NUM_OF_RNG >> 1)) + j] ^ 1'b1;
                        end else begin
                            mut_child2[4*(i - (`NUM_OF_RNG >> 1)) + j] <= orig_child2[4*(i - (`NUM_OF_RNG >> 1)) + j];
                        end
                    end
                end
            end
        end
    endgenerate
endmodule
