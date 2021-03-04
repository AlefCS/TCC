`timescale 1ns / 1ps

module get_best #(
    parameter FIT_WIDTH = 27,
    parameter CHROM_WIDTH = 8
)(
    output logic unsigned   [FIT_WIDTH - 1:0] best_fit,
    output logic unsigned [CHROM_WIDTH - 1:0] best,
    input  logic unsigned   [FIT_WIDTH - 1:0] fitness1,
    input  logic unsigned   [FIT_WIDTH - 1:0] fitness2,
    input  logic unsigned [CHROM_WIDTH - 1:0] chrom1,
    input  logic unsigned [CHROM_WIDTH - 1:0] chrom2,
    input  logic enable_second,
    input  logic reset,
    input  logic clk
);
    always @(posedge clk) begin
        if (reset) begin
            best_fit <= {FIT_WIDTH {1'b1}};
        end else begin
            if (enable_second) begin
                if (fitness1 < fitness2) begin
                    if (fitness1 < best_fit) begin
                        best_fit <= fitness1;
                        best     <= chrom1;
                    end
                end else begin
                    if (fitness2 < best_fit) begin
                        best_fit <= fitness2;
                        best     <= chrom1;
                    end
                end
            end else begin
                if (fitness1 < best_fit) begin
                    best_fit <= fitness1;
                    best     <= chrom1;
                end
            end
        end
    end
endmodule
