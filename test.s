li t0, 0x123
nop
li t1, 0x321
nop
add t2, t0, t1
nop
sw t2, -4(t0)
nop
li t3, 0x111
nop
lw t3, -4(t0)
nop
lui t0, 1234
nop
auipc t1, 1234
nop
