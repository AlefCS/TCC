`timescale 1ns / 1ps

`include "../src/ram.sv"
`include "../src/lfsr_rng.sv"

`define DATA_WIDTH 8
`define RAM_SIZE   64
`define ADDR_WIDTH $clog2(`RAM_SIZE)

module tb_ram ();
    // 'ram' module ports
    logic [`DATA_WIDTH - 1:0] data_out;
    logic [`DATA_WIDTH - 1:0] data_in;
    logic [`ADDR_WIDTH - 1:0] r_addr;
    logic [`ADDR_WIDTH - 1:0] w_addr;
    logic w_enable;
    logic clk;

    // Extra ports needed by 'lfsr_rng' modules
    logic [31:0] seed;
    logic reset;

    logic signed [`DATA_WIDTH - 1:0] sim_data_out;
    reg [`DATA_WIDTH - 1:0] sim_mem[`RAM_SIZE];

    int unsigned i;
    int unsigned num_tests = 1000000;
    int unsigned passed_tests = 0;

    bit go_crazy;
    logic [`ADDR_WIDTH - 1:0] alt_w_addr;

    always_comb begin
        if (go_crazy) begin
            assign data_in  = data_in_rng.rnd[`DATA_WIDTH - 1:0];
            assign w_addr   = w_addr_rng.rnd[31:31 - (`ADDR_WIDTH - 1)];
            assign w_enable = w_enable_rng.rnd[31];
        end else begin
            assign data_in  = 'b0;
            assign w_addr   = alt_w_addr;
            assign w_enable = 'b1;
        end

        assign r_addr = r_addr_rng.rnd[`ADDR_WIDTH - 1:0];
    end

    initial begin
        // Generate waves data and file
        $dumpfile("dump.vcd");
        $dumpvars;

        $display("\n\n########## STARTING SIMULATION ##########\n");

        // Initialize signals
        clk      = 0;
        reset    = 0;
        go_crazy = 0;
        seed     = 32'hA1EF_CDE5;

        // Reset 'rng'
        @ (negedge clk);
        reset = 1;
        @ (negedge clk);
        reset = 0;

        // Clear whole memory
        for (i = 0; i < `RAM_SIZE; i = i + 1) begin
            alt_w_addr = i;

            @ (negedge clk);
            sim_ram();
        end
        // alt_w_addr = 0;
        // @ (negedge clk);
        // sim_ram();
        // alt_w_addr = 1;
        // @ (negedge clk);
        // sim_ram();
        // alt_w_addr = 2;
        // @ (negedge clk);
        // sim_ram();
        // alt_w_addr = 3;
        // @ (negedge clk);
        // sim_ram();

        // Go with the random module
        go_crazy = 1;
        for (i = 0; i < num_tests; i = i + 1) begin
            // Generate simulated RAM operation
            @ (posedge clk);
            sim_ram();

            // Wait for hardware RAM operation
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

    // Task that simulate the hardware module
    task sim_ram();
        sim_data_out = sim_mem[r_addr];

        if (w_enable) begin
            sim_mem[w_addr] = data_in;
        end
    endtask

    // Check hardware module correctness
    task check_correctness();
        #1
        if ((sim_data_out == data_out) && (sim_mem == mem.mem)) begin
            // If it's correct increase 'passed_tests'
            passed_tests = passed_tests + 1;
        end else begin
            // If it's incorrect display values
            $display("[FAILED TEST]");
            $display("DATA_OUT     = %1H", data_out);
            $display("SIM_DATA_OUT = %1H\n", sim_data_out);

            $stop();
        end
    endtask

    ram #(
        .DATA_WIDTH (`DATA_WIDTH),
        .RAM_SIZE   (`RAM_SIZE)
    ) mem (
        .data_out (data_out),
        .data_in  (data_in),
        .r_addr   (r_addr),
        .w_addr   (w_addr),
        .w_enable (w_enable),
        .clk       (clk)
    );

    lfsr_rng data_in_rng (
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );

    lfsr_rng w_addr_rng (
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );

    lfsr_rng r_addr_rng (
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );

    lfsr_rng w_enable_rng (
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );
endmodule
