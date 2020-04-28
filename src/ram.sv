module ram #(
    parameter  RAM_SIZE   = 64,
    parameter  DATA_WIDTH = 8,
    localparam ADDR_WIDTH = $clog2(RAM_SIZE)
)(
    output logic [DATA_WIDTH - 1:0] data_out,
    input  logic [DATA_WIDTH - 1:0] data_in,
    input  logic [ADDR_WIDTH - 1:0] r_addr,
    input  logic [ADDR_WIDTH - 1:0] w_addr,
    input  logic w_enable,
    input  logic clk
);
    reg [DATA_WIDTH - 1:0] mem[RAM_SIZE];

    always @ (posedge clk) begin
        if (w_enable) begin
            mem[w_addr] <= data_in;
        end

        data_out <= mem[r_addr];
    end
endmodule
