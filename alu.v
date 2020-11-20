module alu (
    input [31:0] a, b,
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg [31:0] q
);
    
    always @* begin
        case (funct3)
        4'b000: begin
            if (opcode[5] & funct7[5]) begin
                q <= a - b;
            end else begin
                q <= a + b;
            end
        end 
        4'b001: q <= a << b[4:0];
        4'b010: q <= $signed(a) < $signed(b);
        4'b011: q <= a < b; 
        4'b100: q <= a ^ b;
        4'b101: begin
            case (funct7[5])
                1'b0: q <= a >> b[4:0];
                1'b1: q <= $signed(a) >>> b[4:0];
            endcase
        end
        4'b110: q <= a | b;
        4'b111: q <= a & b;
        endcase
    end
endmodule