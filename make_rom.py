#!/usr/bin/python
import os
import sys
import struct

# make the assembler file
os.system("riscv64-unknown-linux-gnu-as -o build/test.elf {}".format(sys.argv[1]))
# make a raw binary file
os.system("riscv64-unknown-linux-gnu-objcopy -O binary build/test.elf build/test.bin")

with open("build/test.bin", "rb") as f:
    machine_code = f.read()

with open("build/test.rom", "w") as f:
    for b in range(0, len(machine_code)):
        f.write("mem[{}] = 8'd{};\n".format(b, int(machine_code[b])))
