`timescale 1ns / 1ps

module buffer #(
    parameter SIZE  = 3,
    parameter WIDTH = 8
)(
    output reg signed [WIDTH - 1:0] out,
    input signed [WIDTH - 1:0] in,
    input r_enable,
    input w_enable,
    input reset,
    input clk
);
    reg [WIDTH - 1:0] buf_data[SIZE];
    reg [$clog2(SIZE) - 1: 0] consumer_ptr;
    reg [$clog2(SIZE) - 1: 0] producer_ptr;

    always @ (posedge clk) begin
        if (reset) begin
            consumer_ptr <= 0;
            producer_ptr <= 0;
        end else begin
            if (r_enable) begin
                if (consumer_ptr == producer_ptr && w_enable) begin
                    out <= in;
                end else begin
                    out <= buf_data[consumer_ptr];
                end
                
                if (consumer_ptr == SIZE - 1) begin
                    consumer_ptr <= 0;
                end else begin
                    consumer_ptr <= consumer_ptr + 1;
                end
            end

            if (w_enable) begin
                buf_data[producer_ptr] <= in;
                
                if (producer_ptr == SIZE - 1) begin
                    producer_ptr <= 0;
                end else begin
                    producer_ptr <= producer_ptr + 1;
                end
            end
        end
    end
endmodule