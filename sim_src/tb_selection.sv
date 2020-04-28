`timescale 1ns / 1ps

`include "../src/rng8.sv"
`include "../src/fitness_function.sv"
`include "../src/selection.sv"

module tb_selection ();
    // 'selection' module ports
    logic selected;
    logic signed [26:0] fitness1;
    logic signed [26:0] fitness2;
    logic clk;

    // Extra ports needed by 'rng8' module
    logic signed [7:0] chrom1;
    logic signed [7:0] chrom2;
    logic reset;
    logic [31:0] seed;

    bit sim_selected;

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

        // Wait for reset is finished
        @ (negedge clk);
        // Wait for first 'fitness_function' is finished
        @ (negedge clk);
        for (i = 0; i < num_tests; i = i + 1) begin
            // Generate simulated selected
            sim_selected = f_sim_selected(fitness1, fitness2);

            // Wait for hardware selected
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
    function bit f_sim_selected();
        input reg signed [26:0] fitness1;
        input reg signed [26:0] fitness2;

        if (fitness1 < fitness2) begin
            f_sim_selected = 0;
        end else begin
            f_sim_selected = 1;
        end
    endfunction

    // Check hardware module correctness
    task check_correctness();
        #1
        if (sim_selected == selected) begin
            // If it's correct increase 'passed_tests'
            passed_tests = passed_tests + 1;
        end else begin
            // If it's incorrect display values
            $display("[FAILED TEST]");
            $display("SELECTED     = %b", selected);
            $display("SIM_SELECTED = %b\n", sim_selected);
            $stop();
        end
    endtask

    selection sel (
        .selected (selected),
        .fitness1 (fitness1),
        .fitness2 (fitness2),
        .clk (clk)
    );

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
