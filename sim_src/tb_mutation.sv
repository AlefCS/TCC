`timescale 1ns / 1ps

`include "../src/mutation.sv"
`include "../src/rng8.sv"
`include "../src/lfsr_rng.sv"

`define SEED 32'h0000_0001
`define MUT_RATE 12

module tb_mutation ();
    // 'mutation' module ports
    logic signed [7:0] mut_child1;
    logic signed [7:0] mut_child2;
    logic signed [7:0] orig_child1;
    logic signed [7:0] orig_child2;
    logic reset;
    logic clk;

    // Extra ports needed by 'rng8' module
    logic [31:0] seed;

    logic signed [7:0] sim_mut_child1;
    logic signed [7:0] sim_mut_child2;

    logic unsigned [31:0] rng_rnd[4];
    logic unsigned [7:0]  rng_subrnd[16];

    // int unsigned comb_i, comb_j;
    // always_comb begin
    //     for (comb_i = 0; comb_i < 4; comb_i = comb_i + 1) begin
    //         for (comb_j = 0; comb_j < 4; comb_j = comb_j + 1) begin
    //             rng_subrnd[4*comb_i + comb_j] = rng_rnd[comb_i][8*(comb_j + 1) - 1 : 8*comb_j];
    //         end
    //     end
    // end

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

        for (i = 0; i < num_tests; i = i + 1) begin
            // Generate simulated mutation
            {sim_mut_child1, sim_mut_child2} = sim_mutation(orig_child1, orig_child2);

            // Wait for hardware mutation
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
    function reg signed [15:0] sim_mutation();
        input reg signed [7:0] child1;
        input reg signed [7:0] child2;

        int unsigned sm_i, sm_j;
        reg signed [7:0] sm_child1;
        reg signed [7:0] sm_child2;

        for (sm_i = 0; sm_i < 4; sm_i = sm_i + 1) begin
            for (sm_j = 0; sm_j < 4; sm_j = sm_j + 1) begin
                if (sm_i < 2) begin
                    if (rng_subrnd[4*sm_i + sm_j] < `MUT_RATE) begin
                        sm_child1[4*sm_i + sm_j] = child1[4*sm_i + sm_j] ^ 1'b1;
                    end else begin
                        sm_child1[4*sm_i + sm_j] = child1[4*sm_i + sm_j];
                    end
                end else begin
                    if (rng_subrnd[4*sm_i + sm_j] < `MUT_RATE) begin
                        sm_child2[4*(sm_i - 2) + sm_j] = child2[4*(sm_i - 2) + sm_j] ^ 1'b1;
                    end else begin
                        sm_child2[4*(sm_i - 2) + sm_j] = child2[4*(sm_i - 2) + sm_j];
                    end
                end
            end
        end

        sim_mutation = {sm_child1, sm_child2};
    endfunction

    // Check hardware module correctness
    task check_correctness();
        #1
        if ({sim_mut_child1, sim_mut_child2} == {mut_child1, mut_child2}) begin
            // If it's correct increase 'passed_tests'
            passed_tests = passed_tests + 1;
        end else begin
            // If it's incorrect display values
            $display("[FAILED TEST]");
            $display("MUT_CHILD1     = %2H, MUT_CHILD2     = %2H", mut_child1, mut_child2);
            $display("SIM_MUT_CHILD1 = %2H, SIM_MUT_CHILD2 = %2H\n", sim_mut_child1, sim_mut_child2);
            $stop();
        end
    endtask

    mutation #(
        .SEED     (`SEED),
        .MUT_RATE (`MUT_RATE)
    ) mut (
        .mut_child1  (mut_child1),
        .mut_child2  (mut_child2),
        .orig_child1 (orig_child1),
        .orig_child2 (orig_child2),
        .reset       (reset),
        .clk         (clk)
    );

    rng8 rcg (
        .rnd1  (orig_child1),
        .rnd2  (orig_child2),
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );

    // Generate the 'lfsr_rng's needed
    genvar gen_i, gen_j;
    generate
        for (gen_i = 0; gen_i < 4; gen_i = gen_i + 1) begin : rng_genblk
            lfsr_rng rng (
                .rnd   (rng_rnd[gen_i]),
                .seed  (`SEED + gen_i*(32'h1248_8421)),
                .reset (reset),
                .clk   (clk)
            );

            for (gen_j = 0; gen_j < 4; gen_j = gen_j + 1) begin
                assign rng_subrnd[4*gen_i + gen_j] = rng_rnd[gen_i][8*(gen_j + 1) - 1 : 8*gen_j];
            end
        end
    endgenerate
endmodule
