`timescale 1ns / 1ps

module mutation #(
    parameter SEED     = 32'hA1EF_CDE5,
    parameter MUT_RATE = 12              // $floor(0.05*256) ou 5%
)(
    output logic signed [7:0] mut_child1,
    output logic signed [7:0] mut_child2,
    input  logic signed [7:0] orig_child1,
    input  logic signed [7:0] orig_child2,
    input  logic reset,
    input  logic clk
);
    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : rng_genblk
            wire unsigned [31:0] super_rnd;

            lfsr_rng rng (
                .rnd   (super_rnd),
                .seed  (SEED + i*(32'h1248_8421)),
                .reset (reset),
                .clk   (clk)
            );

            for (j = 0; j < 4; j = j + 1) begin
                wire unsigned [7:0] rnd;

                assign rnd = super_rnd[8*(j + 1) - 1 : 8*j];

                always @ (posedge clk) begin
                    if (i < 2) begin
                        if (rnd < MUT_RATE) begin
                            mut_child1[4*i + j] <= orig_child1[4*i + j] ^ 1'b1;
                        end else begin
                            mut_child1[4*i + j] <= orig_child1[4*i + j];
                        end
                    end else begin
                        if (rnd < MUT_RATE) begin
                            mut_child2[4*(i - 2) + j] <= orig_child2[4*(i - 2) + j] ^ 1'b1;
                        end else begin
                            mut_child2[4*(i - 2) + j] <= orig_child2[4*(i - 2) + j];
                        end
                    end
                end
            end
        end
    endgenerate
endmodule
