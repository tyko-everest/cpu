module alu (
    input [31:0] a, b,
    input [2:0] mode,
    output reg [31:0] q
);
    
    always @* begin
        case (mode)
            3'b000 : q <= a + b;
            3'b001 : q <= a << b[4:0];
            3'b010 : q <= a - b;
            3'b011 : q <= $signed(a) >>> b[4:0];
            3'b100 : q <= a ^ b;
            3'b101 : q <= a >> b[4:0];
            3'b110 : q <= a | b;
            3'b111 : q <= a & b;
        endcase
    end
endmodule