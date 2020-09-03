`timescale 1ns / 1ps

`define POP_SIZE 16

module ga (
    output logic [ 7:0] best,
    output logic [26:0] best_fit,
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

    // Signals for 'buffer' module
    logic buffer_renable;
    logic buffer_wenable;
    wire [(8 << 1) - 1:0] buffer_out;

    // Signals for 'mut' module
    wire [7:0] mut_child1;
    wire [7:0] mut_child2;

    // Signals for 'xover' module
    logic xover_enable;
    wire [7:0] xover_child1;
    wire [7:0] xover_child2;
    
    // Signals for 'sel' module
    logic sel_enable;
    wire  sel_selected;
    // Registers for the pipeline between selection and crossover
    reg [7:0] pipelineSC_seltd[2];

    // Signals for 'ff' module
    logic ff_enable;
    wire signed [26:0] ff_fit1;
    wire signed [26:0] ff_fit2;
    // Registers for the pipeline between fitness and selection
    reg [7:0] pipelineFS_pop[2];

    // Signals for 'pop_init' module
    wire [7:0] pop_init_out1;
    wire [7:0] pop_init_out2;
    // Register for the pipeline between initializer and fitness
    reg [7:0] pipelineIF_pop[2];

    // Counter to know when to change to steady state
    reg [$clog2(`POP_SIZE >> 2) - 1:0] init3_counter;
    // Counter to know when to start consuming from buffer
    reg [$clog2(`POP_SIZE >> 1) - 1:0] fitTicks_counter;
    // Counter to know when to stop getting init population
    reg [$clog2(`POP_SIZE) - 1:0] initpop_counter;

    // Main
    always @ (posedge clk) begin
        if (reset) begin
            state <= INIT0;
            init3_counter <= 0;
            fitTicks_counter <= 0;

            // Initializing enable signals
            ff_enable      <= 1'b0;
            sel_enable     <= 1'b0;
            buffer_renable <= 1'b0;
            buffer_wenable <= 1'b0;
        end else begin
            // Connect pipelines
            initpop_counter <= initpop_counter + 2;
            if (initpop_counter < `POP_SIZE) begin
                pipelineIF_pop <= {pop_init_out1, pop_init_out2};
            end else begin
                pipelineIF_pop <= {buffer_out[7:0], buffer_out[15:8]};
            end

            pipelineFS_pop <= pipelineIF_pop;

            if (state == INIT2_1 ||  state == INIT3) begin
                if (sel_selected == 1'b0) begin
                    pipelineSC_seltd[0] <= pipelineFS_pop[0];
                end else begin
                    pipelineSC_seltd[0] <= pipelineFS_pop[1];
                end
            end else begin
                if (sel_selected == 1'b0) begin
                    pipelineSC_seltd[1] <= pipelineFS_pop[0];
                end else begin
                    pipelineSC_seltd[1] <= pipelineFS_pop[1];
                end
            end

            case (state)
                INIT0: begin
                    state <= INIT1;
                    ff_enable <= 1'b1;
                end
                INIT1: begin
                    state <= INIT2_1;
                    sel_enable <= 1'b1;
                end
                INIT2_1: begin
                    state <= INIT2_2;
                end
                INIT2_2: begin
                    state <= INIT3;
                    xover_enable <= 1'b1;
                end
                INIT3: begin
                    if (init3_counter < (`POP_SIZE >> 2) - 1) begin
                        state <= INIT4;
                        xover_enable <= 1'b0;
                    end else begin
                        state <= STEADY;
                        // TODO - ativar segundo SEL
                    end

                    buffer_wenable <= 1'b0;
                    init3_counter <= init3_counter + 1;
                end
                INIT4: begin
                    xover_enable <= 1'b1;
                    buffer_wenable     <= 1'b1;
                    state        <= INIT3;
                end
                STEADY: begin
                    // TODO - Estado estacionário -- Atingiu condição de término vai para FINISHED
                end
                FINISHED: begin
                    // TODO - Terminou execução do algoritmo
                end
                default: state <= INIT0;
            endcase

            if (ff_enable) begin
                if (fitTicks_counter == (`POP_SIZE >> 1) - 2) begin
                    fitTicks_counter <= fitTicks_counter;
                    buffer_renable <= 1'b1;
                end else begin
                    fitTicks_counter <= fitTicks_counter + 1;
                    buffer_renable <= 1'b0;
                end
            end else begin
                fitTicks_counter <= fitTicks_counter;
            end
            // TODO o resto de tudo
        end
    end

    // // SEL Buffer #1 - BUFFER
    // buffer #(
    //     .SIZE  (4),
    //     .WIDTH (8 + 27)                         // Chromossome width + Fitness width
    // ) sel_buffer1 (
    //     .out      (),
    //     .in       (),
    //     .r_enable (),
    //     .w_enable (),
    //     .reset    (reset),
    //     .clk      (clk)
    // );

    // // SEL Buffer #2 - BUFFER
    // buffer #(
    //     .SIZE  (4),
    //     .WIDTH (8 + 27)                         // Chromossome width + Fitness width
    // ) sel_buffer2 (
    //     .out      (),
    //     .in       (),
    //     .r_enable (),
    //     .w_enable (),
    //     .reset    (reset),
    //     .clk      (clk)
    // );

    // Buffer - BUFFER
    buffer #(
        .SIZE  ((`POP_SIZE >> 2) - 1),
        .WIDTH (8 << 1)                         // Chromossome width multiplied by 2
    ) buffer (
        .out      (buffer_out),
        .in       ({mut_child1, mut_child2}),
        .r_enable (buffer_renable),
        .w_enable (buffer_wenable),
        .reset    (reset),
        .clk      (clk)
    );

    // Mutation - MUT
    mutation mut (
        .mut_child1  (mut_child1),
        .mut_child2  (mut_child2),
        .orig_child1 (xover_child1),
        .orig_child2 (xover_child2),
        .reset       (reset),
        .clk         (clk)
    );

    // Crossover - XOVER
    crossover xover (
        .child1  (xover_child1),
        .child2  (xover_child2),
        .parent1 (pipelineSC_seltd[0]),
        .parent2 (pipelineSC_seltd[1]),
        .enable  (xover_enable),
        .clk     (clk)
    );

    // Selection - SEL
    selection sel (
        .selected (sel_selected),
        .fitness1 (ff_fit1),
        .fitness2 (ff_fit2),
        .enable   (sel_enable),
        .clk      (clk)
    );

    // Fitness Function - FIT
    fitness_function ff (
        .fitness1 (ff_fit1),
        .fitness2 (ff_fit2),
        .chrom1   (pipelineIF_pop[0]),
        .chrom2   (pipelineIF_pop[1]),
        .enable   (ff_enable),
        .clk      (clk)
    );

    // Population initializer - RNG
    rng8 pop_init (
        .rnd1  (pop_init_out1),
        .rnd2  (pop_init_out2),
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );

endmodule
