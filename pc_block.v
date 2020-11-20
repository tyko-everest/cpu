module pc_block (
    input wire [31:0] addr,
    input wire clk, branch,
    output reg [31:0] pc
);

    initial pc = 0;

    always @(posedge clk) begin
        if (branch) begin
            pc <= addr;
        end else begin
            pc <= pc + 4;
        end
    end
    
endmodule