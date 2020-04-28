module selection (
    output logic selected,
    input  logic signed [26:0] fitness1,
    input  logic signed [26:0] fitness2,
    input  logic clk
);
    always @ (posedge clk) begin
        if (fitness1 < fitness2) begin
            selected <= 0;
        end else begin
            selected <= 1;
        end
    end
endmodule
