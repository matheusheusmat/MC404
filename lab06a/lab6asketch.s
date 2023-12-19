.globl _start

.text
read:
    li a0, 0              # file descriptor = 0 (stdin)
    la a1, input_address  # buffer to write the data
    li t0, 20             # size (reads 20 bytes)
    li a7, 63             # syscall read (63)
    ecall
    ret


write:
    li a0, 1              # file descriptor = 1 (stdout)
    la a1, input_address  # buffer
    li t0, 20             # size (20 bytes)
    li a7, 64             # syscall write (64)
    ecall
    ret

_start:
    jal ra, read
    jal ra, write

    li a0, 0
    li a7, 93
    ecall

input_address: .skip 0x14
