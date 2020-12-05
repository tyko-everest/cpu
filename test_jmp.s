    li t0, 1
    li t1, 2
    beq t0, t1, test1
    li t2, 3
    bne t0, t1, test2
    li t0, 6
test2:
    j test1
    li t0, 5
    nop
    nop
    nop
    nop
    nop
    nop
test1:
    li t3, 4
    nop
    nop
    nop
    