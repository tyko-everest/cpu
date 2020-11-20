module rom (
    output reg [31:0] data,
    input [15:0] addr,
    input clk
);
    
    reg [7:0] mem [2**16-1:0];

    initial begin
        mem[0] = 8'h13;
        mem[1] = 0;
        mem[2] = 8'hF0;
        mem[3] = 8'hFF;
    end

    always @(posedge clk ) begin
        data <= {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
    end

endmodule