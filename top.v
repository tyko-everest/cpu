`include "cpu.v"
`include "rom.v"
`include "ram.v"
`include "vram.v"
`include "ppu.v"

// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    output LED,   // User/boot LED next to power LED
    output USBPU,  // USB pull-up resistor
    input PIN_1,
    output PIN_2
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    // rename CLK to clk
    wire clk;
    assign clk = CLK;

    wire dbus_wen;

    wire [15:0] colour;

    reg int;

    // instruction bus
    wire [15:0] ibus_addr;
    wire [31:0] ibus_read;
    // data bus
    wire [15:0] dbus_addr;
    wire [31:0] dbus_read, dbus_write;
    // graphics bus (used between vram and ppu, not user accessible)
    wire [12:0] gbus_addr;
    wire [31:0] gbus_read;

    ram ram (
        .out(dbus_read),
        .in(dbus_write),
        .addr(dbus_addr),
        .wen(dbus_wen),
        .clk(clk)
    );

    vram vram (
        .addr_ppu(gbus_addr),
        .out_ppu(gbus_read),
        .clk(clk)
    );

    rom rom (
        .data(ibus_read),
        .addr(ibus_addr),
        .clk(clk)
    );

    cpu cpu (
        .clk(clk),
        .interrupt(PIN_1),
        .dbus_addr(dbus_addr),
        .dbus_read(dbus_read),
        .dbus_write(dbus_write),
        .dbus_wen(dbus_wen),
        .ibus_addr(ibus_addr),
        .ibus_read(ibus_read)
    );

    ppu ppu (
        .clk(clk),
        .addr(gbus_addr),
        .data(gbus_read),
        .colour(colour)
    );

    assign LED = dbus_wen;
    assign PIN_2 = colour[5];



endmodule
