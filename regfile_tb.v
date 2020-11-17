`include "regfile.v"
module tb;
    reg [31:0] d;
    reg [4:0] s1sel, s2sel, dsel;
    reg wen, clk;
    wire [31:0] s1, s2;
  
    regfile regs(
        .d(d),
        .s1sel(s1sel),
        .s2sel(s2sel),
        .dsel(dsel),
        .wen(wen),
        .clk(clk),
        .s1(s1),
        .s2(s2)
    );
  
    initial
        begin
            $dumpfile("test.vcd");
            $dumpvars;
            clk = 0;
            wen = 1;
            s1sel = 0;
            s2sel = 0;
            dsel = 0;
            // try to write to x0 and check it still outputs 0
            d = 32'h1234;
            dsel = 0;
            s1sel = 0;
            #2;
            // write to x1 and check it works
            dsel = 1;
            s1sel = 1;
            #2;
            // write to x2 with wen disabled and check it fails
            wen = 0;
            dsel = 2;
            s1sel = 2;
            #2;            
            // check x1 is still the same
            s1sel = 1;
            #2
            $finish;
        end
    
    always begin
        #1 clk = !clk;
    end

endmodule