`timescale 1ns / 1ps

`include "../src/fitness_function.sv"
`include "../src/rng8.sv"

module tb_fitness_function ();
    logic signed [26:0] fitness1;
    logic signed [26:0] fitness2;
    logic signed [7:0]  chrom1;
    logic signed [7:0]  chrom2;
    logic clk;

    logic clk, reset;
    logic [31:0] seed;

    reg signed [26:0] sim_fitness1;
    reg signed [26:0] sim_fitness2;

    int unsigned i;
    int unsigned num_tests = 1000000;
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

        @ (negedge clk);
        for (i = 0; i < num_tests; i = i + 1) begin
            // Generate simulated fitnesses
            sim_fitness1 = sim_fitness_function(chrom1);
            sim_fitness2 = sim_fitness_function(chrom2);

            @ (negedge clk);
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
    function reg signed [26:0] sim_fitness_function();
        input reg signed [7:0] chrom;
        
        // Function: f(x) = x^3 - 15*x^2 + 500
        sim_fitness_function = (chrom - 10)*(chrom - 10)*(chrom + 5);
    endfunction

    // Check hardware module correctness
    task check_correctness();
        #1
        if ({fitness1, fitness2} == {sim_fitness1, sim_fitness2}) begin
            // If it's correct increase 'passed_tests'
            passed_tests = passed_tests + 1;
        end else begin
            // If it's incorrect display values
            $display("[FAILED TEST]");
            $display("FITNESS1     = %7H, FITNESS2     = %7H", fitness1, fitness2);
            $display("SIM_FITNESS1 = %7H, SIM_FITNESS2 = %7H\n", sim_fitness1, sim_fitness2);
            $stop();
        end
    endtask

    fitness_function ff (
        .fitness1 (fitness1),
        .fitness2 (fitness2),
        .chrom1  (chrom1),
        .chrom2  (chrom2),
        .clk  (clk)
    );

    rng8 rng (
        .rnd1  (chrom1),
        .rnd2  (chrom2),
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );
endmodule
