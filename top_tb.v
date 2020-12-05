`include "top.v"

module tb;

    reg clk, int;

    top top (
        .CLK(clk),
        .PIN_1(int)
    );

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        clk = 0;
        int = 0;
        #15;
        int = 0;
        #2;
        int = 0;
        #12;
        $finish;
    end

    always begin
        #1; clk = ~clk;
    end
    
endmodule