`include "cpu.v"

module tb;

    reg clk;

    cpu cpu(clk);

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        clk = 0;
        #50;
        $finish;
    end

    always begin
        #1; clk = ~clk;
    end
    
endmodule