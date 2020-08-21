`timescale 1ns / 1ps

`include "../src/best.sv"

module tb_best();
    logic [7:0] index;
    logic signed [26:0] fitness [16];

    // Extra for ff and rng devices
    logic clk, reset;
    logic [31:0] seed;

    logic [7:0] sim_index;
    logic signed [26:0] max;

    wire [7:0] rnd1;
    wire [7:0] rnd2;
    wire [26:0] fitness1;
    wire [26:0] fitness2;

    int unsigned i, j;
    int unsigned num_tests = 1000005;
    int unsigned passed_tests = 0;

    initial begin
        // Generate waves data and file
        $dumpfile("dump.vcd");
        $dumpvars;

        $display("\n\n########## STARTING SIMULATION ##########\n");

        // Initialize signals
        clk = 0;
        reset = 0;
        seed = 32'hA1EF_CDE5;

        // Reset 'rng'
        @ (negedge clk);
        reset = 1;
        @ (negedge clk);
        reset = 0;

        // Initialize all fitness
        for (j = 0; j < 16; j = j + 2) begin
            fitness[j] = fitness1;
            fitness[j + 1] = fitness2;
        end

        // Manual test #1
        fitness[0] = 27'h7FF_FFFF;
        sim_index = 0;
        check_correctness();
        fitness[0] = 27'h7FF_FFFE;        

        // Manual test #2
        fitness[3] = 27'h7FF_FFFF;
        sim_index = 3;
        check_correctness();
        fitness[3] = 27'h7FF_FFFE;

        // Manual test #3
        fitness[5] = 27'h7FF_FFFF;
        sim_index = 5;
        check_correctness();
        fitness[5] = 27'h7FF_FFFE;

        // Manual test #4
        fitness[6] = 27'h7FF_FFFF;
        sim_index = 6;
        check_correctness();
        fitness[6] = 27'h7FF_FFFE;

        // Manual test #5
        fitness[8] = 27'h7FF_FFFF;
        sim_index = 8;
        check_correctness();
        fitness[8] = 27'h7FF_FFFE;

        for (i = 0; i < num_tests - 5; i = i  + 1) begin
            // Get all fitness
            for (j = 0; j < 16; j = j + 2) begin
                @ (negedge clk);
                fitness[j] = fitness1;
                fitness[j + 1] = fitness2;
            end

            #1
            max = 27'h400_0001;
            sim_index = sim_best(fitness);
            check_correctness();
        end

        // Print result
        $display("\nRESULT: %1d/%1d passed\n\n", passed_tests, num_tests);

        // Finish simulation
        $display("########## FINISHING SIMULATION ##########");
        $finish();
    end

    // Clock generator
    always begin
        #5 clk = ~clk;
    end

    // Function that simulate the hardware module
    function logic [7:0] sim_best();
        input logic signed [26:0] sim_fitness [16];

        integer unsigned it;

        for (it = 0; it < 16; it = it + 1) begin
            if (sim_fitness[it] > max) begin
                max = sim_fitness[it];
                sim_best = it;
            end
        end
    endfunction

    task check_correctness();
        #1
        if (index == sim_index) begin
            // If it's correct increase 'passed_tests'
            passed_tests = passed_tests + 1;
        end else begin
            // If it's INcorrect display values
            $display("[FAILED TEST]");
            $display("index     = %2H", index);
            $display("sim_index = %2H\n", sim_index);
            $stop();
        end
    endtask

    best best (
        .index   (index),
        .fitness (fitness)
    );

    fitness_function ff (
        .fitness1 (fitness1),
        .fitness2 (fitness2),
        .chrom1   (rnd1),
        .chrom2   (rnd2),
        .clk      (clk)
    );

    rng8 rng (
        .rnd1  (rnd1),
        .rnd2  (rnd2),
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );
endmodule
