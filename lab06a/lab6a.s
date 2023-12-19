.globl _start

.text
read:
    li a0, 0              # file descriptor = 0 (stdin)
    la a1, input_address  # buffer to write the data
    li a2, 20             # size (reads 20 bytes)
    li a7, 63             # syscall read (63)
    ecall
    ret

write:
    li a0, 1              # file descriptor = 1 (stdout)
    la a1, output_address  # buffer
    li a2, 20             # size (20 bytes)
    li a7, 64             # syscall write (64)
    ecall
    ret

# to_int:
# Retorna:
#   a0 - valor inteiro
# Parâmetros:
#   a1 - input_address
#   a3 - offset
to_int:
    li t0, 0         # valor inicial de t0 = 0
    li a0, 0         # valor inicial de a0 = 0
    add t0, a1, a3   # t0 - endereço do bloco = input_address + curr_shift

    lb t1, (t0)      # t1 <- input_address[t0 + 0] (primeiro byte)
    addi t1, t1, -48     # t1 <- t1 - 48
    li t2, 1000      # t2 <- 1000
    mul t1, t1, t2   # t1 <- t1 * 1000
    add a0, a0, t1   # a0 <- a0 + t1
    
    lb t1, 1(t0)     # t1 <- input_address[t0 + 1] (segundo byte)
    addi t1, t1, -48     # t1 <- t1 - 48
    li t2, 100       # t2 <- 100
    mul t1, t1, t2   # t1 <- t1 * 100
    add a0, a0, t1   # a0 <- a0 + t1

    lb t1, 2(t0)     # t1 <- input_address[t0 + 2] (terceiro byte)
    addi t1, t1, -48     # t1 <- t1 - 48
    li t2, 10        # t2 <- 10
    mul t1, t1, t2   # t1 <- t1 * 10
    add a0, a0, t1   # a0 <- a0 + t1

    lb t1, 3(t0)     # t1 <- input_address[t0 + 3] (quarto byte)
    addi t1, t1, -48     # t1 <- t1 - 48
    add a0, a0, t1   # a0 <- a0 + t1
    ret

# sqrt:
# Retorna:
#   a0 - sqrt(a0)
# Parâmetros:
#   a0 - inteiro para o qual se deseja calcular a raiz quadrada
sqrt:
    li t0, 10           # t0 <- 10 (será usado para o loop)
    li t1, 2            # t1 <- 2 (será usado para a estimativa e iterações)
    div t2, a0, t1      # t2 <- a0 / 2 (estimativa inicial)
    
    1:
        div t3, a0, t2  # t3 <- a0 / t2
        add t2, t2, t3  # t2 <- t2 + t3
        div t2, t2, t1  # t2 <- t2 / 2
        addi t0, t0, -1     # Decrementa t0
        bnez t0, 1b     # Se t0 não for igual a 0, volta a label 1
    mv a0, t2           # a0 <- t2
    ret

# store:
# Retorna:
#   output_address com a raiz calculada 
# Parâmetros:
#   a0 - inteiro a ser armazenado
#   a2 - output_address
#   a3 - offset
store:
    add t0, a2, a3      # t0 - endereço do bloco = output_address + curr_shift
    li t1, 10           # t1 <- 10

    li t2, ' '          # t2 <- ' ' (caracter de espaço)
    sb t2, 4(t0)        # output_address[t0 + 4] <- t2

    rem t2, a0, t1      # t2 <- a0 % 10
    addi t2, t2, 48     # t2 <- t2 + 48
    sb t2, 3(t0)        # output_address[t0 + 3] <- t2
    div a0, a0, t1      # a0 <- a0 / 10

    rem t2, a0, t1      # t2 <- a0 % 10
    addi t2, t2, 48     # t2 <- t2 + 48
    sb t2, 2(t0)        # output_address[t0 + 2] <- t2
    div a0, a0, t1      # a0 <- a0 / 10

    rem t2, a0, t1      # t2 <- a0 % 10
    addi t2, t2, 48     # t2 <- t2 + 48
    sb t2, 1(t0)        # output_address[t0 + 1] <- t2
    div a0, a0, t1      # a0 <- a0 / 10

    rem t2, a0, t1      # t2 <- a0 % 10
    addi t2, t2, 48     # t2 <- t2 + 48
    sb t2, (t0)         # output_address[t0] <- t2

    ret

main:
    jal read                # input_address <- stdin
    
    la a2, output_address   # a2 <- output_address

    li a3, 0                # a3 <- 0 (offset)
    jal to_int              # adquirir primeiro valor
    jal sqrt                # calcular sua raiz quadrada pelo método babilônico
    jal store               # guardar no output_buffer

    li a3, 5                # a3 <- 5 (offset)
    jal to_int              # adquirir segundo valor
    jal sqrt                # calcular sua raiz quadrada pelo método babilônico
    jal store               # guardar no output_buffer

    li a3, 10               # a3 <- 10 (offset)
    jal to_int              # adquirir terceito valor
    jal sqrt                # calcular sua raiz quadrada pelo método babilônico
    jal store               # guardar no output_buffer

    li a3, 15               # a3 <- 15 (offset)
    jal to_int              # adquirir quarto valor
    jal sqrt                # calcular sua raiz quadrada pelo método babilônico             
    jal store               # guardar no output_buffer

    li t0, '\n'             # t0 <- 10 ('\n')
    sb t0, 19(a2)           # insere '\n' no final do output_buffer

    jal write               # stdout <- output_address
    jalr zero, s0, 0        # retornar para _start

exit:
    li a0, 0
    li a7, 93
    ecall

_start:
    jal s0, main
    jal exit

.bss
input_address: .skip 20     # input buffer
output_address: .skip 20    # output buffer