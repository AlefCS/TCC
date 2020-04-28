`timescale 1ns / 1ps

`include "../src/crossover.sv"
`include "../src/rng8.sv"

module tb_crossover ();
    // 'crossover' module ports
    logic signed [7:0] child1;
    logic signed [7:0] child2;
    logic signed [7:0] parent1;
    logic signed [7:0] parent2;
    logic clk;

    // Extra ports needed by 'rng8' module
    logic [31:0] seed;
    logic reset;

    reg signed [7:0] sim_child1;
    reg signed [7:0] sim_child2;
    
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
        for (i = 0; i < num_tests; i = i + 1) begin
            // Generate simulated selected
            {sim_child1, sim_child2} = sim_crossover(parent1, parent2);

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
    function reg signed [15:0] sim_crossover();
        input reg signed [7:0] parent1;
        input reg signed [7:0] parent2;

        sim_crossover = {parent1[7:4], parent2[3:0], parent2[7:4], parent1[3:0]};
    endfunction

    // Check hardware module correctness
    task check_correctness();
        #1
        if ({sim_child1, sim_child2} == {child1, child2}) begin
            // If it's correct increase 'passed_tests'
            passed_tests = passed_tests + 1;
        end else begin
            // If it's incorrect display values
            $display("[FAILED TEST]");
            $display("CHILD1     = %2H, CHILD2     = %2H", child1, child2);
            $display("SIM_CHILD1 = %2H, SIM_CHILD2 = %2H\n", sim_child1, sim_child2);
            $stop();
        end
    endtask

    crossover crossover (
        .child1  (child1),
        .child2  (child2),
        .parent1 (parent1),
        .parent2 (parent2),
        .clk     (clk)
    );

    rng8 rng (
        .rnd1  (parent1),
        .rnd2  (parent2),
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );
endmodule
