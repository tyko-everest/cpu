`include "alu.v"
module tb;

    reg [31:0] a, b;
    reg [2:0] mode;
    wire [31:0] q;

    alu alu (.a(a), .b(b), .q(q), .mode(mode));
    
    initial
        begin
        $dumpfile("test.vcd");
        $dumpvars;
        a = -32'h1;
        b = 32'h10e3;
        mode = 3'b000;
        #1;
        mode = 3'b001;
        #1;
        mode = 3'b010;
        #1;
        mode = 3'b011;
        #1;
        mode = 3'b100;
        #1;
        mode = 3'b101;
        #1;
        mode = 3'b110;
        #1;
        mode = 3'b111;
        #1;
        $finish;
    end
endmodule