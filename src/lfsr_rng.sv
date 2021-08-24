`timescale 1ns / 1ps

module lfsr_rng #(
    parameter WIDTH = 8
)(
    output reg [WIDTH - 1:0] rnd,
    input [WIDTH - 1:0] seed,
    input reset,
    input clk
);
    always @ (posedge clk) begin
        if (reset) begin
            rnd <= seed;                                                    // Load seed
        end else begin
            if (^rnd === 1'bx || |rnd == 1'b0) begin
                rnd <= {(WIDTH >> 3){8'hAA}};                               // If previous value is 0 or has some "undefined" bit load default
            end else begin
                if (WIDTH == 32) begin
                    rnd <= {rnd[31] ^ rnd[21] ^ rnd[1] ^ rnd[0], rnd[31:1]};    // Run LFSR
                end else if (WIDTH == 16) begin
                    rnd <= {rnd[15] ^ rnd[13] ^ rnd[12] ^ rnd[10], rnd[15:1]};
                end else if (WIDTH == 8) begin
                    rnd <= {rnd[7] ^ rnd[5] ^ rnd[4] ^ rnd[3], rnd[7:1]};
                end
            end
        end
    end
endmodule