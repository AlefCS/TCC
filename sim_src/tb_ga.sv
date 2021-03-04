`timescale 1ns / 1ps

`include "../src/ga.sv"

`define POP_SIZE 16
`define GENS 100
`define SEED 32'h895C80A7
// `define SEED 32'hCDE5_A1EF

module tb_ga();
    logic [ 7:0] best;
    logic [26:0] best_fit;
    logic finished;
    logic reset;
    logic clk;

    reg [7:0] bests[`GENS];
    int unsigned i;

    initial begin
        clk = 0;
        reset = 1;
        i = 0;

        @ (posedge clk);
        @ (negedge clk);

        reset = 0;

        @ (posedge clk);
        @ (negedge clk);

        @ (posedge finished);
        $display("Bests:\n{");
        for (i = 0; i < `GENS - 1; i = i + 1) begin
            $write("%d, ", bests[i]);
        end
        $display("%d\n}", bests[i]);

        $finish();
    end

    always @(DUT.gen_counter) begin
        if (DUT.gen_counter > 0) begin
            bests[DUT.gen_counter - 1] = best;
        end
    end

    always begin
        #5 clk = ~clk;
    end

    ga #(
        .POP_SIZE (`POP_SIZE),
        .GENS     (`GENS)
    ) DUT (
        .best     (best),
        .best_fit (best_fit),
        .finished (finished),
        .seed     (`SEED),
        .reset    (reset),
        .clk      (clk)
    );
endmodule
