# interrupts always get sent to 0
loop:
    nop
    bne t0,x0,loop
    li t0,1
loop2:
    nop
    j loop2
    