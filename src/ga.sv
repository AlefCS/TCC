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

    // Signals for 'sel_buffer1' module
    wire  [(8 + 27) - 1:0] selbuffer1_out;
    logic [(8 + 27) - 1:0] selbuffer1_in;
    logic selbuffer1_renable;
    logic selbuffer1_wenable;

    // Signals for 'sel_buffer2' module
    wire  [(8 + 27) - 1:0] selbuffer2_out;
    logic [(8 + 27) - 1:0] selbuffer2_in;
    logic selbuffer2_renable;
    logic selbuffer2_wenable;
    reg  [(8 + 27) - 1:0] pipelineSbSb[2];

    // Signals for 'buffer' module
    logic buffer_renable;
    logic buffer_wenable;
    wire [(8 << 1) - 1:0] buffer_out;

    // Signals for 'mut' module
    wire [7:0] mut_child1;
    wire [7:0] mut_child2;

    // Signals for 'xover' module
    logic xover_enable;
    wire  [7:0] xover_child1;
    wire  [7:0] xover_child2;
    logic [7:0] xover_parent1;
    logic [7:0] xover_parent2;
    
    // Signals for 'sel1' module
    logic sel1_enable;
    wire  sel1_selected;
    // Registers for the pipeline between selection and crossover
    reg [7:0] pipelineSC_seltd;

    // Signals for 'sel2' module
    logic sel2_enable;
    wire  sel2_selected;

    // Signals for 'ff' module
    logic ff_enable;
    logic [7:0] ff_chrom1;
    logic [7:0] ff_chrom2;
    wire signed [26:0] ff_fit1;
    wire signed [26:0] ff_fit2;
    // Registers for the pipeline between fitness and selection
    reg [7:0]  pipelineFS_pop[2];
    reg [26:0] pipelineFS_fit[2];             // Hold the fitnesses for the selbuffer

    // Signals for 'pop_init' module
    wire [7:0] pop_init_out1;
    wire [7:0] pop_init_out2;
    // Register for the pipeline between initializer and fitness
    reg [7:0] pipelineIF_pop[2];

    // Counter to know when to change to steady state
    reg [$clog2(`POP_SIZE >> 2) - 1:0] init3_counter;
    // Counter to know when to stop getting init population
    reg [$clog2(`POP_SIZE):0] firstTicks_counter;

    // Main
    always @ (posedge clk) begin
        if (reset) begin
            state <= INIT0;
            init3_counter <= 0;
            firstTicks_counter <= 0;

            // Initializing enable signals
            ff_enable          <= 1'b0;
            sel1_enable        <= 1'b0;
            sel2_enable        <= 1'b0;
            xover_enable       <= 1'b0;
            buffer_renable     <= 1'b0;
            buffer_wenable     <= 1'b0;
            selbuffer1_renable <= 1'b0;
            selbuffer1_wenable <= 1'b0;
            selbuffer2_renable <= 1'b0;
            selbuffer2_wenable <= 1'b0;
        end else begin
            /*** CONNECT PIPELINES ***/
            // Receive the same input of 'ff'
            pipelineIF_pop <= {ff_chrom1, ff_chrom2};
            pipelineFS_pop <= pipelineIF_pop;
            pipelineFS_fit <= {ff_fit1, ff_fit2};
            pipelineSbSb <= {selbuffer1_out, selbuffer2_out};

            /*** ENABLE SIGNALS ***/
            if (firstTicks_counter < (`POP_SIZE >> 1) - 1) begin
                buffer_renable <= 1'b0;
            end else if (firstTicks_counter < `POP_SIZE >> 1) begin
                buffer_renable <= 1'b1;
            end else begin
                buffer_renable <= 1'b1;
                selbuffer2_renable <= 1'b1;
            end

            /*************************
            * Entrada dos selbuffers *
            *************************/
            if (sel1_selected == 1'b0) begin
                selbuffer1_in <= {pipelineFS_pop[0], 27'b0};
            end else begin
                selbuffer1_in <= {pipelineFS_pop[1], 27'b0};
            end

            if (firstTicks_counter <= (`POP_SIZE >> 1) + 2) begin
                if (sel1_selected == 1'b0) begin
                    selbuffer2_in <= {pipelineFS_pop[0], pipelineFS_fit[0]};
                end else begin
                    selbuffer2_in <= {pipelineFS_pop[1], pipelineFS_fit[1]};
                end
            end else begin
                if (sel2_selected == 1'b0) begin
                    selbuffer2_in <= pipelineSbSb[0];
                end else begin
                    selbuffer2_in <= pipelineSbSb[1];
                end
            end

            // Counting 'firstTicks_counter'
            if (firstTicks_counter < {($clog2(`POP_SIZE) + 1){1'b1}}) begin
                // Until maximum value increment
                firstTicks_counter <= firstTicks_counter + 1;
            end else begin
                // When reaches maximum stop incrementing
                firstTicks_counter <= firstTicks_counter;
            end

            /* if (state == INIT2_2 ||  state == INIT3) begin
                if (sel1_selected == 1'b0) begin
                    pipelineSC_seltd[0] <= pipelineFS_pop[0];
                end else begin
                    pipelineSC_seltd[0] <= pipelineFS_pop[1];
                end
            end else begin
                if (sel1_selected == 1'b0) begin
                    pipelineSC_seltd[1] <= pipelineFS_pop[0];
                end else begin
                    pipelineSC_seltd[1] <= pipelineFS_pop[1];
                end
            end 
            
            ** SUBSTITUÍDO PELA SOLUÇÃO LOGO ABAIXO **
            */
            if (sel1_selected == 1'b0) begin
                pipelineSC_seltd <= pipelineFS_pop[0];
            end else begin
                pipelineSC_seltd <= pipelineFS_pop[1];
            end

            if (state == STEADY) begin
                if (sel1_selected == 1'b0) begin
                    xover_parent1 <= pipelineFS_pop[0];
                end else begin
                    xover_parent1 <= pipelineFS_pop[1];
                end

                if (sel2_selected == 1'b0) begin
                    xover_parent2 <= pipelineSbSb[0][7:0];
                end else begin
                    xover_parent2 <= pipelineSbSb[1][7:0];
                end
            end else begin
                xover_parent1 <= pipelineSC_seltd;
                if (sel1_selected == 1'b0) begin
                    xover_parent2 <= pipelineFS_pop[0];
                end else begin
                    xover_parent2 <= pipelineFS_pop[1];
                end
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
                end
                INIT2_2: begin
                    state <= INIT3;

                    selbuffer1_wenable <= 1'b0;
                    selbuffer2_wenable <= 1'b1;
                    xover_enable <= 1'b1;
                end
                INIT3: begin
                    // Check pass to STEADY state condition
                    if (init3_counter < (`POP_SIZE >> 2) - 1) begin
                        state <= INIT4;

                        xover_enable       <= 1'b0;
                        selbuffer1_wenable <= 1'b1;
                        selbuffer2_wenable <= 1'b0;

                        if (init3_counter == (`POP_SIZE >> 2) - 2) begin
                            selbuffer1_renable <= 1'b1;
                        end
                    end else begin
                        state <= STEADY;

                        selbuffer1_wenable <= 1'b1;
                        selbuffer2_wenable <= 1'b1;
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
                    if (init3_counter == (`POP_SIZE >> 2) - 1) begin
                        sel2_enable <= 1'b1;
                    end
                end
                STEADY: begin
                    // TODO - Estado estacionário -- Atingiu condição de término vai para FINISHED
                    // TODO se está indo para FINISHED então desabilitar todos os enables

                end
                FINISHED: begin
                    // TODO - Terminou execução do algoritmo
                end
                default: state <= INIT0;
                /* TODO *****************************************
                * estados de PRE-INIT para forçar um reset caso *
                * atinja um estado desconhecido (no default).   *
                *                                               *
                * Se for implementado então o default levaria a *
                * esse estado.                                  *
                ************************************************/
            endcase
            // TODO o resto de tudo
        end
    end

    // Main - Combinational
    always_comb begin
        // Mux for 'ff' input
        if (firstTicks_counter <= (`POP_SIZE >> 1)) begin
            // Select input as init population
            ff_chrom1 = pop_init_out1;
            ff_chrom2 = pop_init_out2;
        end else begin
            if (`POP_SIZE == 16) begin
                if (firstTicks_counter < 12) begin 
                    // Select input as 'mut' out (passing through buffer)
                    ff_chrom1 = buffer_out[ 7:0];
                    ff_chrom2 = buffer_out[15:8];
                end else begin
                    // Select input as 'mut' out
                    ff_chrom1 = mut_child1;
                    ff_chrom2 = mut_child2;
                end
            end else begin
                // Select input as 'mut' out (ALWAYS passing through buffer)
                ff_chrom1 = buffer_out[ 7:0];
                ff_chrom2 = buffer_out[15:8];
            end
        end

        // TODO apagar essa parte pois é só para testes
        {best, best_fit} = selbuffer1_out;
    end

    // Population initializer - RNG
    rng8 pop_init (
        .rnd1  (pop_init_out1),
        .rnd2  (pop_init_out2),
        .seed  (seed),
        .reset (reset),
        .clk   (clk)
    );

    // Fitness Function - FIT
    fitness_function ff (
        .fitness1 (ff_fit1),
        .fitness2 (ff_fit2),
        .chrom1   (ff_chrom1),
        .chrom2   (ff_chrom2),
        .enable   (ff_enable),
        .clk      (clk)
    );

    // Selection  #1 - SEL
    selection sel1 (
        .selected (sel1_selected),
        .fitness1 (ff_fit1),
        .fitness2 (ff_fit2),
        .enable   (sel1_enable),
        .clk      (clk)
    );

    // Selection  #2 - SEL
    selection sel2 (
        .selected (sel2_selected),
        .fitness1 (selbuffer1_out[(8 + 27) - 1:8]),
        .fitness2 (selbuffer2_out[(8 + 27) - 1:8]),
        .enable   (sel2_enable),
        .clk      (clk)
    );

    // Crossover - XOVER
    crossover xover (
        .child1  (xover_child1),
        .child2  (xover_child2),
        .parent1 (xover_parent1),
        .parent2 (xover_parent2),
        .enable  (xover_enable),
        .clk     (clk)
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

    // SEL Buffer #1 - BUFFER
    buffer #(
        .SIZE  (`POP_SIZE >> 2),
        .WIDTH (8 + 27)                         // Chromossome width + Fitness width
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
        .SIZE  (`POP_SIZE >> 2),
        .WIDTH (8 + 27)                         // Chromossome width + Fitness width
    ) sel_buffer2 (
        .out      (selbuffer2_out),
        .in       (selbuffer2_in),
        .r_enable (selbuffer2_renable),
        .w_enable (selbuffer2_wenable),
        .reset    (reset),
        .clk      (clk)
    );

endmodule
