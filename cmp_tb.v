`include "cmp.v"

module tb;
    reg [31:0] a, b;
    reg [2:0] mode;
    wire q;
    
    cmp cmp_test(.a(a), .b(b), .mode(mode), .q(q));

    integer i;
    
    initial
        begin
            $dumpfile("test.vcd");
            $dumpvars;
            a = -2;
            b = -1;
            for (i = 0; i < 8; i = i + 1) begin
                mode <= i; #1;
            end
            $finish;
        end
endmodule