# li t0, 0x123
# li t1, 0x321
# add t2, t0, t1
li t0, 0x123
sw t0, 0(x0)
lw t1, 0(x0)
