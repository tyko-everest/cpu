module rom #(
    // 512 B addressed in 4 byte words
    parameter ADDR_WIDTH = 9,
    parameter DATA_WIDTH = 32
) (
    output reg [DATA_WIDTH-1:0] data,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire clk
);

    // ADDR_WIDTH - 2 because address is for byte addressing, but actually defined as words
    reg [DATA_WIDTH-1:0] mem [(1 << (ADDR_WIDTH - 2))-1:0];

    initial begin
        `include "build/test.rom"
    end

    // TODO this always writes/reads addr word
    always @(posedge clk) begin
        data <= mem[addr[ADDR_WIDTH-1:2]];
    end

endmodule