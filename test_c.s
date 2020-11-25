    jal     main
    mv      t0,a0
halt:
    j halt

main:
    addi    sp,sp,-32
    sw      s0,28(sp)
    addi    s0,sp,32
    li      a5,4
    sw      a5,-20(s0)
    lw      a4,-20(s0)
    lui     a5,0x3
    addi    a5,a5,56
    blt     a5,a4,L2
    lw      a5,-20(s0)
    addi    a5,a5,6
    sw      a5,-20(s0)
    j       L3

L2:
    lw      a5,-20(s0)
    addi    a5,a5,-6
    sw      a5,-20(s0)

L3:
    lw      a5,-20(s0)
    mv      a0,a5
    lw      s0,28(sp)
    addi    sp,sp,32
    ret
