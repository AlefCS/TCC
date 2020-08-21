`timescale 1ns / 1ps

module crossover(
    output logic signed [7:0] child1,
    output logic signed [7:0] child2,
    input  logic signed [7:0] parent1,
    input  logic signed [7:0] parent2,
    input  logic clk
);
    always @ (posedge clk) begin
        child1 <= {parent1[7:4], parent2[3:0]};
        child2 <= {parent2[7:4], parent1[3:0]};
    end
endmodule
