`timescale 1ns / 1ps

module lfsr_rng (
    output reg [31:0] rnd,
    input [31:0] seed,
    input reset,
    input clk
);    
    always @ (posedge clk) begin
        if (reset) begin
            rnd <= seed;                                                    // Load seed
        end else begin
            if (^rnd === 1'bx || |rnd == 1'b0) begin
                rnd <= 32'hAAAA_AAAA;                                       // If previous value is 0 or has some "undefined" bit load default
            end else begin
                rnd <= {rnd[31] ^ rnd[21] ^ rnd[1] ^ rnd[0], rnd[31:1]};    // Run LFSR
            end
        end
    end
endmodule