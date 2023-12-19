.globl _start

# Referências
# s0 <- _start após main
# s1 <- d1
# s2 <- d2
# s3 <- d3
# s4 <- d4
# s5 <- p1 (esse 'parity bit' e os próximos são do segundo input)
# s6 <- p2
# s7 <- p3

.text
read:
    li a0, 0                    # file descriptor = 0 (stdin)
    li a7, 63                   # syscall read (63)
    ecall
    ret

write:
    li a0, 1                    # file descriptor = 1 (stdout)
    li a7, 64                   # syscall write (64)
    ecall
    ret

# save_data_bits: guarda os bits de dados do primeiro input em registradores
# e nas posições certas output.
# Parâmetros:
#   a1 - endereço do input
#   a2 - endereço do output
# Retorno:
#   s1 - d1
#   s2 - d2
#   s3 - d3
#   s4 - d4
save_data_bits:
    lb t0, (a1)                 # t0 <- Mem[a1] (d1)
    addi s1, t0, -48            # s1 <- t0 - 48 (char to int)
    sb t0, 2(a2)                # Mem[a2 + 2] <- t0 

    lb t0, 1(a1)                # t0 <- Mem[a1 + 1] (d2)
    addi s2, t0, -48            # s2 <- t0 - 48 (char to int)
    sb t0, 4(a2)                # Mem[a2 + 4] <- t0

    lb t0, 2(a1)                # t0 <- Mem[a1 + 2] (d3)
    addi s3, t0, -48            # s3 <- t0 - 48 (char to int)
    sb t0, 5(a2)                # Mem[a2 + 5] <- t0

    lb t0, 3(a1)                # t0 <- Mem[a1 + 3] (d4)
    addi s4, t0, -48            # s4 <- t0 - 48 (char to int)
    sb t0, 6(a2)                # Mem[a2 + 6] <- t0

    ret

# parity_bit_1: calcula o primeiro 'parity bit' segundo o Código de
# Hamming (7,4) e o retorna.
# Parâmetros:
#   s1, s2, s4 - respectivamente, d1, d2 e d4.
# Retorno:
#   a0 - o 'parity bit' calculado.
parity_bit_1:
    li t0, 0            # t0 será o número de bits iguais a 1
    li t1, 1            # t1 guarda o 1 para comparação

    # Verificando o d1
    bne s1, t1, 1f      # Se d1 != 1, pula para próxima label '1'
    addi t0, t0, 1      # Se d1 == 1, t0++

    1:
    # Verificando o d2
    bne s2, t1, 1f      # Se d2 != 1, pula para próxima label '1'
    addi t0, t0, 1      # Se d2 == 1, t0++

    1:
    # Verificando o d4
    bne s4, t1, 1f      # Se d4 != 1, pula para próxima label '1'
    addi t0, t0, 1      # Se d4 == 1, t0++

    1:
    li t1, 2            # t1 <- 2
    rem t2, t0, t1      # t2 <- t0 % 2 (0 se t0 par, 1 se t0 ímpar)
    addi t2, t2, '0'    # t2 <- t0 + '0'
    mv a0, t2           # a0 <- t2

    ret

# parity_bit_2: calcula o segundo 'parity bit' segundo o Código de
# Hamming (7,4) e o retorna.
# Parâmetros:
#   s1, s3, s4 - respectivamente, d1, d3 e d4.
# Retorno:
#   a0 - o 'parity bit' calculado.
parity_bit_2:
    li t0, 0            # t0 será o número de bits iguais a 1
    li t1, 1            # t1 guarda o 1 para comparação

    # Verificando o d1
    bne s1, t1, 1f      # Se d1 != 1, pula para próxima label '1' 
    addi t0, t0, 1      # Se d1 == 1, t0++

    1:
    # Verificando o d3
    bne s3, t1, 1f      # Se d3 != 1, pula para próxima label '1'
    addi t0, t0, 1      # Se d3 == 1, t0++

    1:
    # Verificando o d4
    bne s4, t1, 1f      # Se d4 != 1, pula para próxima label '1'
    addi t0, t0, 1      # Se d4 == 1, t0++

    1:
    li t1, 2            # t1 <- 2
    rem t2, t0, t1      # t2 <- t0 % 2 (0 se t0 par, 1 se t0 ímpar)
    addi t2, t2, '0'    # t2 <- t0 + '0'
    mv a0, t2           # a0 <- t2

    ret

# parity_bit_3: calcula o terceiro 'parity bit' segundo o Código de
# Hamming (7,4) e o retorna.
# Parâmetros:
#   s2, s3, s4 - respectivamente, d2, d3 e d4.
# Retorno:
#   a0 - o 'parity bit' calculado.
parity_bit_3:
    li t0, 0            # t0 será o número de bits iguais a 1
    li t1, 1            # t1 guarda o 1 para comparação

    # Verificando o d2
    bne s2, t1, 1f      # Se d2 != 1, pula para próxima label '1'  
    addi t0, t0, 1      # Se d2 == 1, t0++

    1:
    # Verificando o d3
    bne s3, t1, 1f      # Se d3 != 1, pula para próxima label '1'  
    addi t0, t0, 1      # Se d3 == 1, t0++

    1:
    # Verificando o d4
    bne s4, t1, 1f      # Se d4 != 1, pula para próxima label '1'  
    addi t0, t0, 1      # Se d4 == 1, t0++

    1:
    li t1, 2            # t1 <- 2
    rem t2, t0, t1      # t2 <- t0 % 2 (0 se t0 par, 1 se t0 ímpar)
    addi t2, t2, '0'    # t2 <- t0 + '0'
    mv a0, t2           # a0 <- t2

    ret

# extract_data_bits: guarda os bits de dados do segundo input em registradores
# e no output.
# Parâmetros:
#   a1 - endereço do input
#   a2 - endereço do output
# Retorno:
#   s1 - d1
#   s2 - d2
#   s3 - d3
#   s4 - d4
extract_data_bits:
    lb t0, 2(a1)                 # t0 <- Mem[a1 + 2] (d1)
    addi s1, t0, -48             # s1 <- t0 - 48 (char to int)
    sb t0, (a2)                  # Mem[a2] <- t0

    lb t0, 4(a1)                 # t0 <- Mem[a1 + 4] (d1)
    addi s2, t0, -48             # s2 <- t0 - 48 (char to int)
    sb t0, 1(a2)                 # Mem[a2 + 1] <- t0

    lb t0, 5(a1)                 # t0 <- Mem[a1 + 5] (d1)
    addi s3, t0, -48             # s3 <- t0 - 48 (char to int)
    sb t0, 2(a2)                 # Mem[a2 + 2] <- t0

    lb t0, 6(a1)                 # t0 <- Mem[a1 + 6] (d1)
    addi s4, t0, -48             # s4 <- t0 - 48 (char to int)
    sb t0, 3(a2)                 # Mem[a2 + 3] <- t0                 

    ret

# extract_parity_bits: guarda os bits de paridade do segundo input em registradores
# para verificação de corretude do Código de Hamming (7,4).
# Parâmetros:
#   a1 - endereço do input
# Retorno:
#   s5 - p1
#   s6 - p2
#   s7 - p3
extract_parity_bits:
    lb t0, (a1)                  # t0 <- Mem[a1]
    addi s5, t0, -48             # s5 <- t0 - 48 (char to int)

    lb t0, 1(a1)                 # t0 <- Mem[a1 + 1]
    addi s6, t0, -48             # s6 <- t0 - 48 (char to int)

    lb t0, 3(a1)                 # t0 <- Mem[a1 + 3]
    addi s7, t0, -48             # s7 <- t0 - 48 (char to int)

    ret

# verify_parity_1: verifica se o primeiro bit de paridade está correto.
# Parâmetros:
#   a0 - p1
#   s1 - d1
#   s2 - d2
#   s4 - d4
# Retorno:
#   a0 = 0, se correto
#   a0 = 1, se incorreto
verify_parity_1:
    xor a0, a0, s1         # a0 <- a0 xor s1
    xor a0, a0, s2         # a0 <- a0 xor s2
    xor a0, a0, s4         # a0 <- a0 xor s4
    ret

# verify_parity_2: verifica se o primeiro bit de paridade está correto.
# Parâmetros:
#   a0 - p2
#   s1 - d1
#   s2 - d3
#   s4 - d4
# Retorno:
#   a0 = 0, se correto
#   a0 = 1, se incorreto
verify_parity_2:
    xor a0, a0, s1         # a0 <- a0 xor s1
    xor a0, a0, s3         # a0 <- a0 xor s3
    xor a0, a0, s4         # a0 <- a0 xor s4
    ret

# verify_parity_3: verifica se o primeiro bit de paridade está correto.
# Parâmetros:
#   a0 - p3
#   s1 - d2
#   s2 - d3
#   s4 - d4
# Retorno:
#   a0 = 0, se correto
#   a0 = 1, se incorreto
verify_parity_3:
    xor a0, a0, s2         # a0 <- a0 xor s2
    xor a0, a0, s3         # a0 <- a0 xor s3
    xor a0, a0, s4         # a0 <- a0 xor s4
    ret

main:
    # Encoding
    la a1, ln1_input_address    # buffer onde será escrito o primeiro input
    li a2, 5                    # quantos bytes ler (5 bytes)
    jal read

    la a2, ln1_output_address   # a2 <- ln1_output_address

    jal save_data_bits          # Salva os bits de dados na posição certa do encoding

    jal parity_bit_1            # Determina o primeiro bit de paridade
    sb a0, (a2)                 # Mem[a2] <- a0
    
    jal parity_bit_2            # Determina o segundo bit de paridade
    sb a0, 1(a2)                # Mem[a2 + 1] <- a0

    jal parity_bit_3            # Determina o terceiro bit de paridade
    sb a0, 3(a2)                # Mem[a2 + 3] <- a0

    li t0, '\n'
    sb t0, 7(a2)                # '/n' no final do ln1_output_address
             
    # Decoding
    la a1, ln2_input_address    # buffer onde será escrito o segundo input
    li a2, 8                    # quantos bytes ler (8 bytes)
    jal read

    # Gathering data
    # Data bits
    la a2, ln2_output_address   # a2 <- ln2_output_address
    jal extract_data_bits       # Extrai os bits de dados do input e os salva no output
    li t0, '\n'                 
    sb t0, 4(a2)                # '/n' no final do ln2_output_address

    # Parity bits
    jal extract_parity_bits     # Extrai os bits de paridade do input e os salva em registradores

    la a2, ln3_output_address   # a2 <- ln3_output_address
    li t0, '\n'                 
    sb t0, 1(a2)                # '/n' no final do ln3_output_address

    # Verifying encoding error
    mv a0, s5                   # a0 <- s5 (p1)
    jal verify_parity_1         # Verifica a corretude do primeiro bit de paridade    
    beqz a0, 0f                 # Se correto, próxima verificação (label '0' seguinte)
    j 1f                        # Se incorreto, o encoding já está errado (label '1' seguinte)
    
    0:
    mv a0, s6                   # a0 <- s6 (p2)
    jal verify_parity_2         # Verifica a corretude do primeiro bit de paridade   
    beqz a0, 0f                 # Se correto, próxima verificação (label '0' seguinte)
    j 1f                        # Se incorreto, o encoding já está errado (label '1' seguinte)

    0:
    mv a0, s7                   # a0 <- s7 (p3)
    jal verify_parity_3         # Verifica a corretude do primeiro bit de paridade   
    beqz a0, 0f                 # Se correto, o encoding está certo (label '0' seguinte)
    j 1f                        # Se incorreto, o encoding está errado (label '1' seguinte)

    0:                  # Não existe erro de encoding, guarda '0' no output
    li t0, '0'          
    sb t0, (a2)
    j print

    1:                  # Existe erro de encoding, guarda '1' no output
    li t0, '1'
    sb t0, (a2)
    
    print:          
    la a1, ln1_output_address   # a1 <- ln1_output_address
    li a2, 8                    # bytes para imprimir
    jal write

    la a1, ln2_output_address   # a1 <- ln2_output_address
    li a2, 5                    # bytes para imprimir
    jal write

    la a1, ln3_output_address   # a1 <- ln3_output_address
    li a2, 2                    # bytes para imprimir
    jal write

    jr s0   # volta ao _start

exit:
    li a0, 0
    li a7, 93
    ecall

_start:
    jal s0, main
    jal exit

.data
ln1_input_address: .skip 5     # first line input buffer
ln2_input_address: .skip 8     # second line input buffer
ln1_output_address: .skip 8    # first line output buffer
ln2_output_address: .skip 5    # second line output buffer
ln3_output_address: .skip 2    # third line output buffer