`include "alu.v"
module tb;

    reg [31:0] a, b;
    reg [6:0] opcode_reg, opcode_imm;
    reg [2:0] funct3;
    reg [6:0] funct7;
    wire [31:0] q_reg, q_imm;
    
    alu alu_test_reg (
        .a(a), 
        .b(b), 
        .q(q_reg), 
        .opcode(opcode_reg), 
        .funct3(funct3), 
        .funct7(funct7)
    );

    alu alu_test_imm (
        .a(a), 
        .b(b), 
        .q(q_imm), 
        .opcode(opcode_imm), 
        .funct3(funct3), 
        .funct7(funct7)
    );
    
    initial
        begin
        $dumpfile("test.vcd");
        $dumpvars;
        opcode_reg = 7'b0010011;
        opcode_imm = 7'b0110011;
        a = -32'h1;
        b = 32'h10e3;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        #1;
        funct7 = 7'b0100000;
        #1;
        funct3 = 3'b001;
        funct7 = 7'b0000000;
        #1;
        funct3 = 3'b010;
        #1;
        funct3 = 3'b011;
        #1;
        funct3 = 3'b100;
        #1;
        funct3 = 3'b101;
        #1;
        funct7 = 7'b0100000;
        #1;
        funct3 = 3'b110;
        funct7 = 7'b0000000;
        #1;
        funct3 = 3'b111;
        #1;
        $finish;
    end
endmodule