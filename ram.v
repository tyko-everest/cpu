module ram #(
    // 4 KiB addressed in 4 byte words
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32
) (
    output wire [DATA_WIDTH-1:0] out,
    input wire [DATA_WIDTH-1:0] in,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire wen, clk
);

    reg [ADDR_WIDTH-1:0] raddr;
    // ADDR_WIDTH - 2 because address is for byte addressing, but actually defined as words
    reg [DATA_WIDTH-1:0] mem [(1 << (ADDR_WIDTH - 2))-1:0];

    // TODO this always writes/reads addr word
    always @(posedge clk) begin
        if (wen) begin
            mem[addr[ADDR_WIDTH-1:2]] <= in;
        end
        raddr <= addr;
    end

    assign out = mem[raddr[ADDR_WIDTH-1:2]];

endmodule