`timescale 1ns / 1ps

module fitness_function (
    output logic signed [26:0] fitness1,
    output logic signed [26:0] fitness2,
    input  logic signed [7:0]  chrom1,
    input  logic signed [7:0]  chrom2,
    input  logic enable,
    input  logic clk
);
    ff_1v3d ff1 (
        .fitness (fitness1),
        .chrom   (chrom1),
        .enable  (enable),
        .clk     (clk)
    );

    ff_1v3d ff2 (
        .fitness (fitness2),
        .chrom   (chrom2),
        .enable  (enable),
        .clk     (clk)
    );
endmodule
