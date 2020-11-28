`include "muldiv.v"

module tb;

    reg clk;

    reg [31:0] a, b;
    wire [31:0] q;
    reg [2:0] mode;

    muldiv muldiv (
        .a(a),
        .b(b),
        .q(q),
        .mode(mode)
    );

    integer i;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
        a = 32'h0000FF78;
        b = 32'h80234567;
        for (i = 0; i < 8; i = i + 1) begin
            mode <= i; #1;
        end
        $finish;
    end
    
endmodule