`timescale 1ns / 1ps

module selection (
    output logic selected,
    input  logic unsigned [26:0] fitness1,
    input  logic unsigned [26:0] fitness2,
    input  logic enable,
    input  logic clk
);
    always @ (posedge clk) begin
        if (enable) begin
            if (fitness1 < fitness2) begin
                selected <= 0;
            end else begin
                selected <= 1;
            end
        end
    end
endmodule
