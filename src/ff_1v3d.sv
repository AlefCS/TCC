module ff_1v3d (
    output logic signed [26:0] fitness,
    input  logic signed [7:0] chrom,
    input  logic clk
);
    always @ (posedge clk) begin
        // Calculate output of 'f(x) = x^3 - 15*x^2 + 500'  
        fitness <= (chrom - 10)*(chrom - 10)*(chrom + 5);
    end
endmodule
