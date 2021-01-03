module regfile(s1, s2, d, s1sel, s2sel, dsel, wen, clk);
    input wire [31:0] d;
    input wire [4:0] s1sel, s2sel, dsel;
    input wen, clk;
    output reg[31:0] s1, s2;

    reg [31:0] regs [1:31];
    integer i;

    initial begin
        for (i = 1; i < 32; i = i + 1) begin
            regs[i] = 0;
        end
    end

    always @(posedge clk) begin
        if (wen) begin
            if (dsel == 0) begin
                regs[dsel] <= 0;
            end else begin
                regs[dsel] <= d;
            end
        end
    end

    always @(*) begin
        if (s1sel == 0) begin
            s1 <= 0;
        end else begin
            s1 <= regs[s1sel];
        end
    end

    always @(*) begin
        if (s2sel == 0) begin
            s2 <= 0;
        end else begin
            s2 <= regs[s2sel];
        end
    end

    // debugging
    always @(posedge clk) begin
        $display("t0: %H, t1: %H, t2: %H, t3: %H", regs[5], regs[6], regs[7], regs[28]);
        // $display("ra: %H", regs[1]);
    end

endmodule