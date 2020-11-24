    li t1, 10
    nop
    li t0, 0
    nop
start:
    addi t1, t1, -1
    nop
    bgt t1, t0, start
    li t2, 0xF
