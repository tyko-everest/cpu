#!/usr/bin/python
import os
import sys

with open("build/vram.txt", "r") as f:
    byte_string = f.read()
    byte_string = byte_string.split()

with open("build/vram.rom", "w") as f:
    i = 0
    for b1, b2, b3, b4 in zip(*[iter(byte_string)]*4):
        f.write("mem[{}] = 32'h{};\n".format(i, b1 + b2 + b3 + b4))
        i += 1
