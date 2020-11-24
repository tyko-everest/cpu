module rom (
    output reg [31:0] data,
    input [15:0] addr,
    input clk
);
    
    reg [7:0] mem [2**16-1:0];

    initial begin
        `include "build/test.rom"
    end

    always @(posedge clk) begin
        data <= {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
    end

endmodule