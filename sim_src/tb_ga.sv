`timescale 1ns / 1ps

`include "../src/ga.sv"

`define POP_SIZE 32
`define GENS 1000
`define CHROM_WIDTH 16
`define FITNESS_WIDTH ((`CHROM_WIDTH + 1) * 3)
`define SEED 32'h895C80A7
// `define SEED 32'hCDE5_A1EF

module tb_ga();
    logic [`CHROM_WIDTH - 1:0] best;
    logic [`FITNESS_WIDTH - 1:0] best_fit;
    logic finished;
    logic reset;
    logic clk;

    reg [`CHROM_WIDTH - 1:0] bests[`GENS];
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
        .POP_SIZE      (`POP_SIZE),
        .GENS          (`GENS),
        .CHROM_WIDTH   (`CHROM_WIDTH),
        .FITNESS_WIDTH (`FITNESS_WIDTH)
    ) DUT (
        .best     (best),
        .best_fit (best_fit),
        .finished (finished),
        .seed     (`SEED),
        .reset    (reset),
        .clk      (clk)
    );
endmodule
