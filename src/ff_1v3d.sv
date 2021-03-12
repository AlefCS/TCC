`timescale 1ns / 1ps

`define OUTPUT_WIDTH ((INPUT_WIDTH + 1) * 3)

module ff_1v3d #(
    parameter INPUT_WIDTH = 8
)(
    output logic unsigned [`OUTPUT_WIDTH - 1:0] fitness,
    input  logic unsigned  [INPUT_WIDTH - 1:0] chrom,
    input  logic enable,
    input  logic clk
);
    always @ (posedge clk) begin
        if (enable) begin
            // Calculate output of 'f(x) = x^3 - 15*x^2 + 500'
            fitness <= (chrom - 10)*(chrom - 10)*(chrom + 5);
        end
    end
endmodule
