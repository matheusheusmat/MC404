.globl _start

exit:
    li a0, 0
    li a7, 93
    ecall

_start: 

    li t5, 2000
    5:
    addi t5, t5, -1
    bnez t5, 5b

    jal exit
    
