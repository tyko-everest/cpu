#!/usr/bin/python
import os
import sys
import struct

# make the assembler file
os.system("riscv64-unknown-linux-gnu-as -march=rv32i -o build/test.elf {}".format(sys.argv[1]))
# make a raw binary file
os.system("riscv64-unknown-linux-gnu-objcopy -O binary build/test.elf build/test.bin")

with open("build/test.bin", "rb") as f:
    machine_code = f.read()

with open("build/test.rom", "w") as f:
    i = 0
    for b1, b2, b3, b4 in zip(*[iter(machine_code)]*4):
        f.write("mem[{}] = 32'h{};\n".format(i, hex(b1 | b2 << 8 | b3 << 16 | b4 << 24)[2:]))
        i += 1
