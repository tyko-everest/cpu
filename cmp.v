module cmp (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [2:0] mode,
    output reg q
);
    
    always @* begin
        case (mode)
            3'b000:         q <= a == b; // EQ
            3'b001:         q <= a != b; // NEQ
            3'b100, 3'b010: q <= $signed(a) < $signed(b);  // LT
            3'b101:         q <= $signed(a) >= $signed(b); // GE
            3'b110, 3'b011: q <= a < b;  // LTU
            3'b111:         q <= a >= b; // GEU
        endcase
    end
endmodule