`timescale 1ns / 1ps

`include "common_defines.vh"

module ff_1v3d (
    output logic unsigned [`FITNESS_WIDTH - 1:0] fitness,
    input  logic unsigned  [`CHROM_WIDTH - 1:0] chrom,
    input  logic enable,
    input  logic clk
);
    always @ (posedge clk) begin
        if (enable) begin
            fitness <= `FITNESS_FUNCTION;
        end
    end
endmodule
