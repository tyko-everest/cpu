    # interrupts always get sent to 0
    li t0, 0xA
loop:
    beq t0, t1, loop
    li t1, 0xA
wait:
    j wait
