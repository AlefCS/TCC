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

    // Signals for 'xover' module
    logic xover_enable;
    wire [31:0] xover_child1;
    wire [31:0] xover_child2;
    
    // Signals for 'sel' module
    logic sel_enable;
    wire  sel_selected;
    // Registers for the pipeline between selection and crossover
    reg [31:0] pipelineSC_seltd[2];

    // Signals for 'ff' module
    logic ff_enable;
    wire signed [26:0] ff_fit1;
    wire signed [26:0] ff_fit2;
    // Registers for the pipeline between fitness and selection
    reg [31:0] pipelineFS_pop[2];

    // Signals for 'pop_init' module
    wire [31:0] pop_init_out1;
    wire [31:0] pop_init_out2;
    // Register for the pipeline between initializer and fitness
    reg [31:0] pipelineIF_pop[2];

    // Counter to know when to change state
    shortint unsigned firstTicks_counter;

    // Main
    always @ (posedge clk) begin
        if (reset) begin
            state <= INIT;
            firstTicks_counter <= 0;

            // Initializing enable signals
            ff_enable  <= 1'b0;
            sel_enable <= 1'b0;
        end else begin
            // Connect pipelines
            pipelineIF_pop <= {pop_init_out1, pop_init_out2}; // TODO quando também tiver MUT tem que colocar a condicional que cria o mux que antecede o primeiro pipeline
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
                    if (firstTicks_counter < (`POP_SIZE >> 1) + 3) begin
                        state <= INIT4;
                        xover_enable <= 1'b0;
                        // TODO - ativar MUT
                    end else begin
                        state <= STEADY;
                        // TODO - ativar segundo SEL
                        // TODO - ativar MUT
                    end
                end
                INIT4: begin
                    // TODO - XOVER desativado e MUT ativado
                end
                STEADY: begin
                    // TODO - Estado estacionário
                end
                FINISHED: begin
                    // TODO - Terminou execução do algoritmo
                end
                default: state <= INIT0;
            endcase

            if (firstTicks_counter < (`POP_SIZE >> 1) + 3) begin
                firstTicks_counter <= firstTicks_counter + 1;
            end else begin
                firstTicks_counter <= firstTicks_counter;
            end
            // TODO o resto de tudo
        end
    end

    // Crossover - XOVER
    crossover xover (
        .child1  (),
        .child2  (),
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
    rng pop_init (
        .rnd1  (pop_init_out1),
        .rnd2  (pop_init_out2),
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );

endmodule
