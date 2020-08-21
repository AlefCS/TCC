`timescale 1ns / 1ps

module best(
    output logic [7:0] index,
    input  logic signed [26:0] fitness [16]
);

    always_comb begin
        reg signed [26:0] max;
        max = 27'h400_0001;                // The minimum possible value

        for (integer i = 0; i < 16; i = i + 1) begin
            if (fitness[i] > max) begin
                max = fitness[i];
                index = i;
            end
        end
    end

endmodule
