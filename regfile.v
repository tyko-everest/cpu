module regfile(s1, s2, d, s1sel, s2sel, dsel, wen, clk);
    input [31:0] d;
    input [4:0] s1sel, s2sel, dsel;
    input wen, clk;
    output [31:0] s1, s2;

    reg [31:0] regs [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            regs[i] = 0;
        end
    end

    assign s1 = regs[s1sel];
    assign s2 = regs[s2sel];

    always @(posedge clk) begin
        if (wen && (dsel != 0))
            regs[dsel] <= d;
    end

endmodule