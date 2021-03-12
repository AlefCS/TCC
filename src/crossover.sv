`timescale 1ns / 1ps

module crossover #(
    parameter CHROM_WIDTH = 8
)(
    output logic [CHROM_WIDTH - 1:0] child1,
    output logic [CHROM_WIDTH - 1:0] child2,
    input  logic [CHROM_WIDTH - 1:0] parent1,
    input  logic [CHROM_WIDTH - 1:0] parent2,
    input  logic enable,
    input  logic clk
);

    always @ (posedge clk) begin
        if (enable) begin
            child1 <= {parent1[CHROM_WIDTH - 1:(CHROM_WIDTH >> 1)], parent2[(CHROM_WIDTH >> 1) - 1:0]};
            child2 <= {parent2[CHROM_WIDTH - 1:(CHROM_WIDTH >> 1)], parent1[(CHROM_WIDTH >> 1) - 1:0]};
        end
    end
endmodule
