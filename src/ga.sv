`timescale 1ns / 1ps

`include "buffer.sv"
`include "crossover.sv"
`include "fitness_function.sv"
`include "get_best.sv"
`include "mutation.sv"
`include "rng.sv"
`include "selection.sv"

`define FITNESS_WIDTH ((CHROM_WIDTH + 1) * 3)

module ga #(
    parameter POP_SIZE = 32,
    parameter GENS = 500,
    parameter CHROM_WIDTH = 16
)(
    output logic unsigned [CHROM_WIDTH - 1:0] best,
    output logic unsigned [`FITNESS_WIDTH - 1:0] best_fit,
    output logic finished,
    input  logic [31:0] seed,
    input  logic reset,
    input  logic clk
);
    // States for the state machine
    typedef enum {
        INIT0,
        INIT1,
        INIT2_1,
        INIT2_2,
        INIT3,
        INIT4,
        STEADY,
        FINISHED
    } states_t;

    // State variable
    states_t state;

    // Signals for 'get_best' module
    wire [`FITNESS_WIDTH - 1:0] getbest_bestfit;
    wire   [CHROM_WIDTH - 1:0] getbest_best;
    wire [`FITNESS_WIDTH - 1:0] getbest_fitness1;
    wire [`FITNESS_WIDTH - 1:0] getbest_fitness2;
    wire   [CHROM_WIDTH - 1:0] getbest_chrom1;
    wire   [CHROM_WIDTH - 1:0] getbest_chrom2;
    logic getbest_reset;
    logic getbest_enablesecond;

    // Signals for 'sel_buffer1' module
    wire  [(CHROM_WIDTH + `FITNESS_WIDTH) - 1:0] selbuffer1_out;
    logic [(CHROM_WIDTH + `FITNESS_WIDTH) - 1:0] selbuffer1_in;
    logic selbuffer1_renable;
    logic selbuffer1_wenable;

    // Signals for 'sel_buffer2' module
    wire  [(CHROM_WIDTH + `FITNESS_WIDTH) - 1:0] selbuffer2_out;
    logic [(CHROM_WIDTH + `FITNESS_WIDTH) - 1:0] selbuffer2_in;
    logic selbuffer2_renable;
    logic selbuffer2_wenable;
    reg  [(CHROM_WIDTH + `FITNESS_WIDTH) - 1:0] pipelineSbSb[2];

    // Signals for 'buffer' module
    logic buffer_renable;
    logic buffer_wenable;
    wire [(CHROM_WIDTH << 1) - 1:0] buffer_out;

    // Signals for 'mut' module
    wire [CHROM_WIDTH - 1:0] mut_child1;
    wire [CHROM_WIDTH - 1:0] mut_child2;

    // Signals for 'xover' module
    logic xover_enable;
    wire  [CHROM_WIDTH - 1:0] xover_child1;
    wire  [CHROM_WIDTH - 1:0] xover_child2;
    logic [CHROM_WIDTH - 1:0] xover_parent1;
    logic [CHROM_WIDTH - 1:0] xover_parent2;

    // Signals for 'sel1' module
    logic sel1_enable;
    wire  sel1_selected;
    // Registers for the pipeline between selection and crossover
    reg [CHROM_WIDTH - 1:0] pipelineSC_seltd;

    // Signals for 'sel2' module
    logic sel2_enable;
    wire  sel2_selected;

    // Signals for 'ff' module
    logic ff_enable;
    logic [CHROM_WIDTH - 1:0] ff_chrom1;
    logic [CHROM_WIDTH - 1:0] ff_chrom2;
    wire signed [`FITNESS_WIDTH - 1:0] ff_fit1;
    wire signed [`FITNESS_WIDTH - 1:0] ff_fit2;
    // Registers for the pipeline between fitness and selection
    reg   [CHROM_WIDTH - 1:0] pipelineFS_pop[2];
    reg [`FITNESS_WIDTH - 1:0] pipelineFS_fit[2];             // Hold the fitnesses for the selbuffer

    // Signals for 'pop_init' module
    wire [CHROM_WIDTH - 1:0] pop_init_out1;
    wire [CHROM_WIDTH - 1:0] pop_init_out2;
    // Register for the pipeline between initializer and fitness
    reg [CHROM_WIDTH - 1:0] pipelineIF_pop[2];

    // Counter to know when to change to steady state
    reg [$clog2(POP_SIZE >> 2) - 1:0] init3_counter;
    // Counter to know when to stop getting init population
    reg [$clog2(POP_SIZE):0] firstTicks_counter;
    // Counter of generations
    reg [15:0] gen_counter;
    // Counter to know when best of generation is ready
    reg [$clog2(POP_SIZE) - 1:0] best_ready_counter;

    assign xover_parent1 = (state == STEADY) ? // if
        (sel1_selected ? pipelineFS_pop[1] : pipelineFS_pop[0]) : // else
        (pipelineSC_seltd);
    assign xover_parent2 = (state == STEADY) ? // if
        (sel2_selected ? pipelineSbSb[1][CHROM_WIDTH + `FITNESS_WIDTH - 1:`FITNESS_WIDTH] : pipelineSbSb[0][CHROM_WIDTH + `FITNESS_WIDTH - 1:`FITNESS_WIDTH]) : // else
        (sel1_selected ? pipelineFS_pop[1] : pipelineFS_pop[0]);

    assign selbuffer1_in = sel1_selected ? {pipelineFS_pop[1], pipelineFS_fit[1]} : {pipelineFS_pop[0], pipelineFS_fit[0]};
    assign selbuffer2_in = (state != STEADY) ? // if
        (sel1_selected ? {pipelineFS_pop[1], pipelineFS_fit[1]} : {pipelineFS_pop[0], pipelineFS_fit[0]}) : // else
        (sel2_selected ? pipelineSbSb[1] : pipelineSbSb[0]);

    assign {getbest_chrom1, getbest_fitness1} = selbuffer1_in;
    assign {getbest_chrom2, getbest_fitness2} = selbuffer2_in;

    // Main
    always @ (posedge clk) begin
        if (reset) begin
            state <= INIT0;
            init3_counter <= 0;
            firstTicks_counter <= 0;
            gen_counter <= -1;
            best_ready_counter <= 0;
            finished <= 1'b0;

            // Initializing enable signals
            ff_enable            <= 1'b0;
            sel1_enable          <= 1'b0;
            sel2_enable          <= 1'b0;
            xover_enable         <= 1'b0;
            buffer_renable       <= 1'b0;
            buffer_wenable       <= 1'b0;
            selbuffer1_renable   <= 1'b0;
            selbuffer1_wenable   <= 1'b0;
            selbuffer2_renable   <= 1'b0;
            selbuffer2_wenable   <= 1'b0;
            getbest_enablesecond <= 1'b0;
            getbest_reset        <= 1'b1;
        end else begin
            /*** CONNECT PIPELINES ***/
            // Receive the same input of 'ff'
            pipelineIF_pop <= {ff_chrom1, ff_chrom2};
            pipelineFS_pop <= pipelineIF_pop;
            pipelineFS_fit <= {ff_fit1, ff_fit2};
            pipelineSbSb <= {selbuffer1_out, selbuffer2_out};

            /*** ENABLE SIGNALS ***/
            if (firstTicks_counter < (POP_SIZE >> 1) - 1) begin
                buffer_renable <= 1'b0;
            end else if (firstTicks_counter < POP_SIZE >> 1) begin
                buffer_renable <= 1'b1;
            end else begin
                buffer_renable <= 1'b1;
                selbuffer2_renable <= 1'b1;
            end

            /*************************
            * Entrada dos selbuffers *
            *************************/
            // Counting 'firstTicks_counter'
            if (firstTicks_counter < {($clog2(POP_SIZE) + 1){1'b1}}) begin
                // Until maximum value increment
                firstTicks_counter <= firstTicks_counter + 1;
            end else begin
                // When reaches maximum stop incrementing
                firstTicks_counter <= firstTicks_counter;
            end

            if (sel1_selected == 1'b0) begin
                pipelineSC_seltd <= pipelineFS_pop[0];
            end else begin
                pipelineSC_seltd <= pipelineFS_pop[1];
            end

            // Counting generation and to know when to update best
            if (!getbest_reset && getbest_enablesecond) begin
                if (best_ready_counter == (POP_SIZE >> 1) - 2) begin
                    best_ready_counter <= 0;
                end else begin
                    best_ready_counter <= best_ready_counter + 2;
                end
            end else if (!getbest_reset) begin
                if (best_ready_counter == (POP_SIZE >> 1) - 1) begin
                    best_ready_counter <= 0;
                end else begin
                    best_ready_counter <= best_ready_counter + 1;
                end
            end

            // Update best
            if (!getbest_reset && best_ready_counter == 0) begin
                best <= getbest_best;
                best_fit <= getbest_bestfit;
                gen_counter <= gen_counter + 1;
            end

            case (state)
                INIT0: begin
                    state <= INIT1;

                    ff_enable <= 1'b1;
                end
                INIT1: begin
                    state <= INIT2_1;

                    sel1_enable <= 1'b1;
                end
                INIT2_1: begin
                    state <= INIT2_2;

                    selbuffer1_wenable <= 1'b1;
                    getbest_reset <= 1'b0;
                end
                INIT2_2: begin
                    state <= INIT3;

                    selbuffer1_wenable <= 1'b0;
                    selbuffer2_wenable <= 1'b1;
                    xover_enable <= 1'b1;
                end
                INIT3: begin
                    // Check pass to STEADY state condition
                    if (init3_counter < (POP_SIZE >> 2) - 1) begin
                        state <= INIT4;

                        xover_enable       <= 1'b0;
                        selbuffer1_wenable <= 1'b1;
                        selbuffer2_wenable <= 1'b0;

                        if (init3_counter == (POP_SIZE >> 2) - 2) begin
                            selbuffer1_renable <= 1'b1;
                        end
                    end else begin
                        state <= STEADY;

                        selbuffer1_wenable   <= 1'b1;
                        selbuffer2_wenable   <= 1'b1;
                        getbest_enablesecond <= 1'b1;
                    end

                    // Enable signals
                    buffer_wenable <= 1'b0;
                    // Counters
                    init3_counter <= init3_counter + 1;
                end
                INIT4: begin
                    state <= INIT3;
                    // Enable signals
                    selbuffer1_wenable <= 1'b0;
                    selbuffer2_wenable <= 1'b1;
                    xover_enable       <= 1'b1;
                    buffer_wenable     <= 1'b1;

                    // Check if it's going to last INIT3
                    if (init3_counter == (POP_SIZE >> 2) - 1) begin
                        sel2_enable <= 1'b1;
                    end
                end
                STEADY: begin
                    if (gen_counter == GENS - 1 && best_ready_counter == 0) begin
                        state <= FINISHED;
                        finished <= 1'b1;
                        // Disable everything
                        ff_enable            <= 1'b0;
                        sel1_enable          <= 1'b0;
                        sel2_enable          <= 1'b0;
                        xover_enable         <= 1'b0;
                        buffer_renable       <= 1'b0;
                        buffer_wenable       <= 1'b0;
                        selbuffer1_renable   <= 1'b0;
                        selbuffer1_wenable   <= 1'b0;
                        selbuffer2_renable   <= 1'b0;
                        selbuffer2_wenable   <= 1'b0;
                        getbest_enablesecond <= 1'b0;
                        getbest_reset        <= 1'b1;
                    end else begin
                        buffer_wenable <= 1'b1;
                    end
                end
                FINISHED: begin
                    finished <= 1'b1;
                    state <= FINISHED;
                end
                default: begin
                    state <= INIT0;
                    init3_counter <= 0;
                    firstTicks_counter <= 0;
                    gen_counter <= -1;
                    best_ready_counter <= 0;
                    finished <= 1'b0;

                    // Initializing enable signals
                    ff_enable            <= 1'b0;
                    sel1_enable          <= 1'b0;
                    sel2_enable          <= 1'b0;
                    xover_enable         <= 1'b0;
                    buffer_renable       <= 1'b0;
                    buffer_wenable       <= 1'b0;
                    selbuffer1_renable   <= 1'b0;
                    selbuffer1_wenable   <= 1'b0;
                    selbuffer2_renable   <= 1'b0;
                    selbuffer2_wenable   <= 1'b0;
                    getbest_enablesecond <= 1'b0;
                    getbest_reset        <= 1'b1;
                end
            endcase
        end
    end

    // Main - Combinational
    always_comb begin
        // Mux for 'ff' input
        if (firstTicks_counter <= (POP_SIZE >> 1)) begin
            // Select input as init population
            ff_chrom1 = pop_init_out1;
            ff_chrom2 = pop_init_out2;
        end else begin
            if (POP_SIZE == 16) begin
                if (firstTicks_counter < 12) begin
                    // Select input as 'mut' out (passing through buffer)
                    ff_chrom1 = buffer_out[(CHROM_WIDTH << 1) - 1:CHROM_WIDTH];
                    ff_chrom2 = buffer_out[CHROM_WIDTH - 1:0];
                end else begin
                    // Select input as 'mut' out
                    ff_chrom1 = mut_child1;
                    ff_chrom2 = mut_child2;
                end
            end else begin
                // Select input as 'mut' out (ALWAYS passing through buffer)
                ff_chrom1 = buffer_out[(CHROM_WIDTH << 1) - 1:CHROM_WIDTH];
                ff_chrom2 = buffer_out[CHROM_WIDTH - 1:0];
            end
        end
    end

    // Population initializer - RNG
    rng #(CHROM_WIDTH) pop_init (
        .rnd1  (pop_init_out1),
        .rnd2  (pop_init_out2),
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );

    // Fitness Function - FIT
    fitness_function #(
        .CHROM_WIDTH   (CHROM_WIDTH)
    ) ff (
        .fitness1 (ff_fit1),
        .fitness2 (ff_fit2),
        .chrom1   (ff_chrom1),
        .chrom2   (ff_chrom2),
        .enable   (ff_enable),
        .clk      (clk)
    );

    // Selection  #1 - SEL
    selection #(`FITNESS_WIDTH) sel1 (
        .selected (sel1_selected),
        .fitness1 (ff_fit1),
        .fitness2 (ff_fit2),
        .enable   (sel1_enable),
        .clk      (clk)
    );

    // Selection  #2 - SEL
    selection #(`FITNESS_WIDTH) sel2 (
        .selected (sel2_selected),
        .fitness1 (selbuffer1_out[`FITNESS_WIDTH - 1:0]),
        .fitness2 (selbuffer2_out[`FITNESS_WIDTH - 1:0]),
        .enable   (sel2_enable),
        .clk      (clk)
    );

    // Crossover - XOVER
    crossover #(CHROM_WIDTH) xover (
        .child1  (xover_child1),
        .child2  (xover_child2),
        .parent1 (xover_parent1),
        .parent2 (xover_parent2),
        .enable  (xover_enable),
        .clk     (clk)
    );

    // Mutation - MUT
    mutation #(
        .CHROM_WIDTH (CHROM_WIDTH)
    ) mut (
        .mut_child1  (mut_child1),
        .mut_child2  (mut_child2),
        .orig_child1 (xover_child1),
        .orig_child2 (xover_child2),
        .seed        (~seed),
        .reset       (reset),
        .clk         (clk)
    );

    // Buffer - BUFFER
    buffer #(
        .SIZE  ((POP_SIZE >> 2) - 1),
        .WIDTH (CHROM_WIDTH << 1)
    ) buffer (
        .out      (buffer_out),
        .in       ({mut_child1, mut_child2}),
        .r_enable (buffer_renable),
        .w_enable (buffer_wenable),
        .reset    (reset),
        .clk      (clk)
    );

    // SEL Buffer #1 - BUFFER
    buffer #(
        .SIZE  (POP_SIZE >> 2),
        .WIDTH (CHROM_WIDTH + `FITNESS_WIDTH)
    ) sel_buffer1 (
        .out      (selbuffer1_out),
        .in       (selbuffer1_in),
        .r_enable (selbuffer1_renable),
        .w_enable (selbuffer1_wenable),
        .reset    (reset),
        .clk      (clk)
    );

    // SEL Buffer #2 - BUFFER
    buffer #(
        .SIZE  (POP_SIZE >> 2),
        .WIDTH (CHROM_WIDTH + `FITNESS_WIDTH)
    ) sel_buffer2 (
        .out      (selbuffer2_out),
        .in       (selbuffer2_in),
        .r_enable (selbuffer2_renable),
        .w_enable (selbuffer2_wenable),
        .reset    (reset),
        .clk      (clk)
    );

    // Get Best
    get_best #(
        .FITNESS_WIDTH (`FITNESS_WIDTH),
        .CHROM_WIDTH   (CHROM_WIDTH)
    ) get_best (
        .best_fit      (getbest_bestfit),
        .best          (getbest_best),
        .fitness1      (getbest_fitness1),
        .fitness2      (getbest_fitness2),
        .chrom1        (getbest_chrom1),
        .chrom2        (getbest_chrom2),
        .enable_second (getbest_enablesecond),
        .reset         (getbest_reset),
        .clk           (clk)
    );

endmodule
