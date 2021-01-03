module vram #(
    // 8 KiB addressed in 4 byte words
    parameter ADDR_WIDTH = 13,
    parameter DATA_WIDTH = 32
) (
    output wire [DATA_WIDTH-1:0] out_sys, out_ppu,
    input wire [DATA_WIDTH-1:0] in_sys,
    input wire [ADDR_WIDTH-1:0] addr_sys, addr_ppu,
    input wire wen, clk
);

    reg [ADDR_WIDTH-1:0] raddr_sys, raddr_ppu;
    // ADDR_WIDTH - 2 because address is for byte addressing, but actually defined as words
    reg [DATA_WIDTH-1:0] mem [(1 << (ADDR_WIDTH - 2))-1:0];

    initial begin
        `include "build/vram.rom"
    end

    // TODO this always writes/reads addr word
    always @(posedge clk) begin
        if (wen) begin
            mem[addr_sys[ADDR_WIDTH-1:2]] <= in_sys;
        end
        raddr_sys <= addr_sys;
        raddr_ppu <= addr_ppu;
    end

    assign out_sys = mem[raddr_sys[ADDR_WIDTH-1:2]];
    assign out_ppu = mem[raddr_ppu[ADDR_WIDTH-1:2]];

endmodule