`include "pc_block.v"

module tb;

reg [31:0] addr;
reg clk, branch;
wire [31:0] pc;

pc_block pc_block_test (
    .addr(addr),
    .clk(clk),
    .branch(branch),
    .pc(pc)
);

initial begin
    $dumpfile("test.vcd");
    $dumpvars;

    addr <= 32'h1234;
    clk <= 0;
    branch <= 0;
    #6;
    branch <= 1;
    #4;
    branch <= 0;
    #4;

    $finish;
end

always begin
    clk = ~clk;
    #1;
end
    
endmodule