module rom (
    output reg [31:0] q,
    input [15:0] a,
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
        q <= {mem[a+3], mem[a+2], mem[a+1], mem[a]};
    end

endmodule