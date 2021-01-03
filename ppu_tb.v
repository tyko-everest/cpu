`include "ppu.v"
`include "vram.v"
module tb;

    reg clk;
    wire [31:0] data, addr;
    wire [15:0] colour;

    ppu ppu (
        .clk(clk),
        .addr(addr),
        .data(data),
        .colour(colour)
    );

    vram vram (
        .out_ppu(data),
        .addr_ppu(addr),
        .clk(clk)
    );

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        #320;
        $finish;
    end

    initial clk = 0;
    always begin
        #1; clk = ~clk;
    end
    
endmodule