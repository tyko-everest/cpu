`include "top.v"

module tb;

    reg clk;

    top top (
        .CLK(clk)
    );

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        clk = 0;
        #80;
        $finish;
    end

    always begin
        #1; clk = ~clk;
    end
    
endmodule