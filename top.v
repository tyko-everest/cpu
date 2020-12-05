`include "cpu.v"
// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    output LED,   // User/boot LED next to power LED
    output USBPU,  // USB pull-up resistor
    input PIN_1
);
    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    // rename CLK to clk
    wire clk;
    assign clk = CLK;

    wire dbus_wen;

    reg int;

    wire [15:0] ibus_addr, dbus_addr;
    wire [31:0] dbus_read, ibus_read, dbus_write;

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

    rom rom (
        .data(ibus_read),
        .addr(ibus_addr),
        .clk(clk)
    );

    ram ram (
        .out(dbus_read),
        .in(dbus_write),
        .addr(dbus_addr),
        .wen(dbus_wen),
        .clk(clk)
    );

    assign LED = dbus_wen;



endmodule
