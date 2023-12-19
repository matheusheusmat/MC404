.globl _start

.set steering_dir, 0xFFFF0120
.set engine_dir, 0xFFFF0121
.set handbrake, 0xFFFF0122

exit:
    li a0, 0
    li a7, 93
    ecall

main:

    li t0, 1            # Acelerando inicialmente
    li t1, engine_dir   # Endereço da porta
    sb t0, (t1)         # Começa a acelerar

    li t0, -127             # Virando à esquerda
    li t1, steering_dir     # Endereço da porta
    sb t0, (t1)             # Começa a virar

    li t6, 16000            # Thread: atraso
    4:                      # 
    addi t6, t6, -1         #
    bnez t6, 4b             #

    sb zero, (t1)           # Para de virar

    li t6, 63000            # Thread: Atraso
    4:                      # 
    addi t6, t6, -1         #
    bnez t6, 4b             #

    li t0, -1               # Frando o motor
    li t1, engine_dir       # Endereço da porta
    sb t0, (t1)             # Começa a frear

    li t6, 17000            # Thread: Atraso
    4:                      # 
    addi t6, t6, -1         #
    bnez t6, 4b             #

    sb zero, (t1)           # Para de frear

    li t0, 1                # Aciona o freio de mão
    li t1, handbrake        # Endereço da porta
    sb t0, (t1)             # 

    ret

_start:
    jal main
    jal exit