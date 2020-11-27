module ram #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
) (
    output wire [DATA_WIDTH-1:0] out,
    input wire [DATA_WIDTH-1:0] in,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire wen, clk
);
    // takes in 10 bit byte address, then ignores last two bits
    // so treated like 8 bit word addressable memory
    reg [ADDR_WIDTH-1:0] raddr;
    // 1 KiB of ram organized in 32 bit words
    reg [DATA_WIDTH:0] mem [(1<<ADDR_WIDTH)-1:0];

    // TODO this always writes/reads addr word
    always @(posedge clk) begin
        if (wen) begin
            mem[addr[9:2]] <= in;
        end
        raddr <= addr;
    end

    assign out = mem[raddr[9:2]];

endmodule