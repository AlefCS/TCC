`timescale 1ns / 1ps

// Uncomment only the one you will use
`define RNG8
// `define RNG16
// `define RNG32

`ifdef RNG8
    `include "../src/rng8.sv"
    `define LSFR_MAX 9'h100
`elsif RNG16
    `include "../src/rng16.sv"
    `define LSFR_MAX 17'h1_0000
`elsif RNG32
    `include "../src/rng.sv"
    `define LSFR_MAX 33'h1_0000_0000
`endif

module tb_rng ();
`ifdef RNG8
    wire [7:0] rnd1;
    wire [7:0] rnd2;
`elsif RNG16
    wire [15:0] rnd1;
    wire [15:0] rnd2;
`elsif RNG32
    wire [31:0] rnd1;
    wire [31:0] rnd2;
`endif
    reg  [31:0] seed;
    reg reset;
    reg clk;

    reg [31:0] sim_rnd1_aux;
    reg [31:0] sim_rnd2_aux;
`ifdef RNG8
    reg [7:0] sim_rnd1;
    reg [7:0] sim_rnd2;
`elsif RNG16
    reg [15:0] sim_rnd1;
    reg [15:0] sim_rnd2;
`elsif RNG32
    reg [31:0] sim_rnd1;
    reg [31:0] sim_rnd2;
`endif
    parameter num_tests = 1000005;
    int unsigned passed_tests = 0;
    int unsigned counter[10];
    int unsigned i, sorted;
    bit sim_free_run;

    initial begin
        // Generate waves data and file
        $dumpfile("dump.vcd");
        $dumpvars;

        $display("\n\n########## STARTING SIMULATION ##########\n");

        // Initialize signals
        reset        = 0;
        clk          = 0;
        sim_rnd1     = 0;
        sim_rnd2     = 0;
        sim_free_run = 0;
        for (i = 0; i < 10; i = i + 1) begin
            counter[i] = 0;
        end

        // Some tests to check reset
        $display("##### RESET TESTS #####");
        // Test 1
        seed = 32'hAAAA_AAAA;
        @ (negedge clk);
        sim_gen_rnd1(seed,  1'b1);
        sim_gen_rnd2(~seed, 1'b1);
        reset = 1;
        @ (negedge clk);
        reset = 0;
        check_correctness();
        // Test 2
        seed = 32'hFFFF_FFFE;
        sim_gen_rnd1(seed,  1'b1);
        sim_gen_rnd2(~seed, 1'b1);
        reset = 1;
        @ (negedge clk);
        reset = 0;
        check_correctness();
        // Test 3
        seed = 32'hFFFF_0000;
        sim_gen_rnd1(seed,  1'b1);
        sim_gen_rnd2(~seed, 1'b1);
        reset = 1;
        @ (negedge clk);
        reset = 0;
        check_correctness();
        // Test 4
        seed = 32'h0000_FFFF;
        sim_gen_rnd1(seed,  1'b1);
        sim_gen_rnd2(~seed, 1'b1);
        reset = 1;
        @ (negedge clk);
        reset = 0;
        check_correctness();
        // Test 5
        seed = ~(32'hAAAA_AAAA);
        sim_gen_rnd1(seed,  1'b1);
        sim_gen_rnd2(~seed, 1'b1);
        reset = 1;
        @ (negedge clk);
        reset = 0;
        check_correctness();
        $display("\nRESULT: %1d/%1d passed\n", passed_tests, 5);

        // Run tests to see if it's really random
        $display("\n##### RANDOMNESS TESTS #####");
        sim_free_run = 1;
        @ (negedge clk);
        for (i = 0; i < num_tests - 5; i = i + 1) begin
            @ (negedge clk);
            check_correctness();
            sorted = $floor(10*(real'(rnd1)/`LSFR_MAX));
            counter[sorted] = counter[sorted] + 1;
            sorted = $floor(10*(real'(rnd2)/`LSFR_MAX));
            counter[sorted] = counter[sorted] + 1;
        end

        for (i = 0; i < 10; i = i + 1) begin
            $display("Chance %d: %2.2f %%", i, 100*(real'(counter[i])/(2*(num_tests - 5))));
        end
        $display("\nFINAL RESULT: %1d/%1d passed\n\n", passed_tests, num_tests);

        // Finish simulation
        $display("########## FINISHING SIMULATION ##########");
        $finish();
    end

    // Clock generator
    always begin
        #5 clk = ~clk;
    end

    always @ (posedge clk) begin
        if (sim_free_run) begin
            sim_gen_rnd1(1'b0,  1'b0);
            sim_gen_rnd2(~1'b0, 1'b0);
        end
    end

    // First simulated random number
    task sim_gen_rnd1(input int unsigned seed, input bit load);
        if (load) begin
            sim_rnd1_aux = seed;
        end else begin
            sim_rnd1_aux = {(sim_rnd1_aux[31] ^ sim_rnd1_aux[21] ^ sim_rnd1_aux[1] ^ sim_rnd1_aux[0]), sim_rnd1_aux[31:1]};
        end
`ifdef RNG8
            sim_rnd1 = {sim_rnd1_aux[31:30], sim_rnd1_aux[21:20], sim_rnd1_aux[3:0]};
`elsif RNG16
            sim_rnd1 = {sim_rnd1_aux[31:21], sim_rnd1_aux[4:0]};
`elsif RNG32
            sim_rnd1 = sim_rnd1_aux;
`endif
    endtask

    // Second simulated random number
    task sim_gen_rnd2(input int unsigned seed, input bit load);
        if (load) begin
            sim_rnd2_aux = seed;
        end else begin
            sim_rnd2_aux = {(sim_rnd2_aux[31] ^ sim_rnd2_aux[21] ^ sim_rnd2_aux[1] ^ sim_rnd2_aux[0]), sim_rnd2_aux[31:1]};
        end
`ifdef RNG8
            sim_rnd2 = {sim_rnd2_aux[31:30], sim_rnd2_aux[21:20], sim_rnd2_aux[3:0]};
`elsif RNG16
            sim_rnd2 = {sim_rnd2_aux[31:21], sim_rnd2_aux[4:0]};
`elsif RNG32
            sim_rnd2 = sim_rnd2_aux;
`endif
    endtask

    // Check hardware module correctness
    task check_correctness();
        #1
        if ({rnd1, rnd2} == {sim_rnd1, sim_rnd2}) begin
            // If it's correct increase 'passed_tests'
            passed_tests = passed_tests + 1;
        end else begin
            // If it's incorrect display values
            $display("[FAILED TEST]");
            $display("RND1     = %32b, RND2     = %32b", rnd1, rnd2);
            $display("SIM_RND1 = %32b, SIM_RND2 = %32b\n", sim_rnd1, sim_rnd2);
            $stop();
        end
    endtask

    // Instantiate 'rng' module
`ifdef RNG8
    rng8 dut (
        .rnd1  (rnd1),
        .rnd2  (rnd2),
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );
`elsif RNG16
    rng16 dut (
        .rnd1  (rnd1),
        .rnd2  (rnd2),
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );
`elsif RNG32
    rng dut (
        .rnd1  (rnd1),
        .rnd2  (rnd2),
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );
`endif
endmodule