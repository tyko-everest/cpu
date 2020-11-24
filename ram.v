module ram (
    output reg [31:0] out,
    input [31:0] in,
    input [15:0] addr,
    input wen, clk
);
    
    reg [7:0] mem [2**16-1:0];

    // testing with certain values defined initially
    initial begin
        mem[4] = 1;
        mem[5] = 2;
        mem[6] = 3;
        mem[7] = 4;
    end


    // TODO this always writes/reads addr word
    always @(posedge clk) begin
        if (wen) begin
            mem[addr] <= in[7:0];
            mem[addr + 1] <= in[15:8];
            mem[addr + 2] <= in[23:16];
            mem[addr + 3] <= in[31:24];
        end else begin
            out <= {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]};
        end
    end
endmodule