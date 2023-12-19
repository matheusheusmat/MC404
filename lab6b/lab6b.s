.globl _start

# Referências
# s0 <- _start apos main
# s1 <- Yb
# s2 <- Xc
# s3 <- Ta (antes do calc da dist até satélite) // da (depois)
# s4 <- Tb // db (idem)
# s5 <- Tc // dc (idem)
# s6 <- Tr (antes do calc de Y) // Ypos (depois)
# s7 <- X1pos
# s8 <- X2pos
# s9 <- bestX

.text
read_ln1:
    li a0, 0                  # file descriptor = 0 (stdin)
    la a1, ln1_input_address  # buffer to write the data
    li a2, 12                 # size (reads 12 bytes)
    li a7, 63                 # syscall read (63)
    ecall
    ret

read_ln2:
    li a0, 0                  # file descriptor = 0 (stdin)
    la a1, ln2_input_address  # buffer to write the data
    li a2, 20                 # size (reads 20 bytes)
    li a7, 63                 # syscall read (63)
    ecall
    ret

write:
    li a0, 1              # file descriptor = 1 (stdout)
    la a1, output_address  # buffer
    li a2, 12             # size (12 bytes)
    li a7, 64             # syscall write (64)
    ecall
    ret

# sqrt:
# Retorna:
#   a0 - sqrt(a0)
# Parâmetros:
#   a0 - inteiro para o qual se deseja calcular a raiz quadrada
sqrt:
    li t0, 21           # t0 <- 21 (será usado para o loop)
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

# to_int:
# Retorna:
#   a0 - valor inteiro
# Parametros:
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

# signal_verify: verifica se o número da entrada é positivo ou negativo
# Retorna:
#   a0 - o número com sinal correto
# Parametros:
#   a0 - o módulo do número
#   a1 - input_address
#   a3 - offset
signal_verify:
    add t0, a1, a3   # t0 - endereço do bloco = input_address + offset
    
    lb t1, (t0) 
    li t2, '-'  # t1 <- '-' (ascii)

    beq t1, t2, 1f  # Se o número for precedido de '-', é negativo
    ret             # e pula para a label "1" seguinte

    1:
        li t0, -1       # t0 <- -1 
        mul a0, a0, t0  # a0 <- a0 * -1
        ret

# dist_to_sat: calcula a distância da pessoa a um satélite
# Retorna:
#   a0 - a distância até o satélite
# Parâmetros:
#   a1 - o satélite desejado ('a', 'b' ou 'c')
dist_to_sat:
    li t0, 'a'  # t0 <- 'a'
    li t1, 'b'  # t0 <- 'b' 
    li t2, 'c'  # t0 <- 'c' 

    beq a1, t0, dist_to_a   # Se a1 == a, calcula distancia ate o sat. A
    beq a1, t1, dist_to_b   # Se a1 == b, calcula distancia ate o sat. B
    beq a1, t2, dist_to_c   # Se a1 == c, calcula distancia ate o sat. C

    # Modo de calcular distancia, comum a A, B e C
    # Deve-se calcular a diferença entre Tr e o T do satelite, multiplicar por 3
    # e dividir por 10.

    dist_to_a:          
        li t0, 3            # t0 <- 3
        sub t1, s6, s3      # t1 <- Tr - Ta
        mul t1, t1, t0      # t1 <- t1 * 3
        li t0, 10           # t0 <- 10
        div t1, t1, t0      # t1 <- t1 / 10
        mv a0, t1           # a0 <- t1 (distância até A)
        ret

    dist_to_b:
        li t0, 3            # t0 <- 3
        sub t1, s6, s4      # t1 <- Tr - Tb
        mul t1, t1, t0      # t1 <- t1 * 3
        li t0, 10           # t0 <- 10
        div t1, t1, t0      # t1 <- t1 / 10
        mv a0, t1            # a0 <- t1 (distância até B)
        ret

    dist_to_c:
        li t0, 3            # t0 <- 3
        sub t1, s6, s5      # t1 <- Tr - Tc
        mul t1, t1, t0      # t1 <- t1 * 3
        li t0, 10           # t0 <- 10
        div t1, t1, t0      # t1 <- t1 / 10
        mv a0, t1           # a0 <- t1 (distância até C)
        ret

# find_Y_pos: calcula a coordenada Y
# Retorna:
#   a0 - posição em Y
# Parâmetros:
#   s1 - Yb
#   s3 - da
#   s4 - db
find_Y_pos: 
    mul t0, s3, s3  # t0 <- da ^ 2
    mul t1, s1, s1  # t1 <- Yb ^ 2
    mul t2, s4, s4  # t2 <- db ^ 2

    add t0, t0, t1  # t0 <- t0 + t1
    sub t0, t0, t2  # t0 <- t0 - t2
    li t1, 2        # t1 <- 2
    mul t1, t1, s1  # t1 <- 2 * Yb

    div t0, t0, t1  # t0 <- t0 / t1
    mv a0, t0       # a0 <- t0
    ret

# find_X_module: calcula o módulo da coordenada X
# Retorna:
#   a0 - o módulo da coordenada X
# Parâmetros:
#   s3 - da
#   s6 - Ypos
find_X_module:
    mul t0, s3, s3  # t0 <- da ^ 2
    mul t1, s6, s6  # t1 <- Ypos ^ 2
    sub t0, t0, t1  # t0 <- t0 - t1

    mv a0, t0       # a0 <- t0
    jal sqrt        # a0 <- sqrt(a0)

    jalr zero, s11, 0

# find_best_X: calcula a coordenada verdadeira de X
# Retorna:
#   a0 - a coordenada verdadeira de X
# Parâmetros:
#   s5 - dc
#   s6 - Ypos
#   s7 - X1pos (positiva)
#   s8 - X2pos (negativa)
find_best_X:
    mul t0, s5, s5  # t0 <- dc ^ 2 (resultado esperado)
    mul t1, s6, s6  # t1 <- Ypos ^ 2

    # Para o X1pos (s7 - positivo)
    sub t2, s7, s2  # t2 <- X1pos - Xc
    mul t2, t2, t2  # t2 <- t2 ^ 2
    add t2, t2, t1  # t2 <- t2 + (Ypos ^ 2)

    # Para o X2pos (s8 - negativo)
    sub t3, s8, s2  # t2 <- X2pos - Xc
    mul t3, t3, t3  # t2 <- t2 ^ 2
    add t3, t3, t1  # t2 <- t2 + (Ypos ^ 2)

    # Calculando o modulo da diferença de t2 e t0
    sub t2, t2, t0      # t2 <- t2 - t0
    bge t2, zero, 1f    # Se t2 e maior ou igual que 0, já e positivo
    li t1, -1           # t1 <- -1
    mul t2, t2, t1      # t2 <- t1 * -1

    1:
    # Calculando o modulo da diferença de t3 e t0
    sub t3, t3, t0      # t2 <- t2 - t0
    bge t3, zero, 1f    # Se t2 e maior ou igual que 0, já e positivo
    li t1, -1           # t1 <- -1
    mul t3, t3, t1      # t2 <- t1 * -1

    1:
    blt t2, t3, 1f      # Se o modulo da diferença de t2 e menor que de t1...
    mv a0, s8           # X2pos é o correto
    ret                 

    1:                  # Caso contrário
    mv a0, s7           # X1pos é o correto
    ret

# store:
# Retorna:
#   output_address com a posição atual calculada 
# Parâmetros:
#   a0 - inteiro a ser armazenado
#   a2 - output_address
#   a3 - offset
store:
    add t0, a2, a3      # t0 - endereço do bloco = output_address + curr_shift
    li t1, 10           # t1 <- 10

    li t2, ' '          # t2 <- ' ' (caracter de espaço)
    sb t2, 5(t0)        # output_address[t0 + 5] <- t2
    mv t3, a0           # t3 <- a0

    bge a0, zero, 1f    # Se a0 for maior ou igual a 0, pula para a label "1" à frente
    li t2, -1           # t2 <- -1
    mul a0, a0, t2      # Se a0 for negativo, a0 <- a0 * -1 (valor absoluto)

    1:
    rem t2, a0, t1      # t2 <- a0 % 10
    addi t2, t2, 48     # t2 <- t2 + 48
    sb t2, 4(t0)        # output_address[t0 + 4] <- t2
    div a0, a0, t1      # a0 <- a0 / 10

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
    sb t2, 1(t0)         # output_address[t0 + 1] <- t2

    blt t3, zero, 1f    # Se a0 for menor que 0, pula para a label "1" à frente
    li t1, '+'          # t1 <- '+'
    sb t1, (t0)         # output_address[t0] <- '+' (coloca o sinal)
    ret

    1:
    li t1, '-'          # t1 <- '-'
    sb t1, (t0)         # output_address[t0] <- '-' (coloca o sinal)
    ret

main:
    jal read_ln1    # read first line
    
    # Yb to_int
    li a3, 1    # a3 <- 1 (buffer offset)
    jal to_int  # converte o Yb lido para inteiro (salva em a0)
    li a3, 0    # a3 <- 0
    jal signal_verify # verificação de sinal 
    mv s1, a0   # s1 <- Yb

    # Xc to_int
    li a3, 7    # a3 <- 7 (buffer offset)
    jal to_int  # converte o Xc lido para inteiro
    li a3, 6    # a3 <- 6
    jal signal_verify
    mv s2, a0   # s1 <- Xc
   
    jal read_ln2 # read second line

    li a3, 0     # a3 <- 0 (buffer offset)  
    jal to_int   # converte o Ta lido para inteiro
    mv s3, a0    # s3 <- Ta

    li a3, 5     # a3 <- 5 (buffer offset)
    jal to_int   # converte o Tb lido para inteiro
    mv s4, a0    # s4 <- Tb

    li a3, 10    # a3 <- 10 (buffer offset)
    jal to_int   # converte o Tc lido para inteiro
    mv s5, a0    # s5 <- Tc

    li a3, 15    # a3 <- 15 (buffer offset)
    jal to_int   # converte o Tr lido para inteiro
    mv s6, a0    # s6 <- Tr

    li a1, 'a'          # a1 <- 'a'
    jal dist_to_sat     # calcula a distancia ate o satelite a
    mv s3, a0           # s3 <- da

    li a1, 'b'          # a1 <- 'b'
    jal dist_to_sat     # calcula a distancia ate o satelite b
    mv s4, a0           # s4 <- db
    
    li a1, 'c'          # a1 <- 'c'
    jal dist_to_sat     # calcula a distancia ate o satelite c
    mv s5, a0           # s5 <- dc

    jal find_Y_pos      # calcula a posição Y
    mv s6, a0           # s6 <- Ypos

    jal s11, find_X_module   # calcula o modulo da posição X
    mv s7, a0           # s7 <- X1pos
    li t0, -1           # t0 <- -1
    mul s8, s7, t0      # s8 <- X2pos = -X1pos

    jal find_best_X     # a0 <- X verdadeiro (bestX)
    mv s9, a0           # s9 <- bestX

    la a2, output_address   # a2 <- output_address
    li a3, 0                # a3 <- 0
    mv a0, s9               # a0 <- bestX
    jal store               # guardar o X no output_buffer

    li a3, 6                # a3 <- 6
    mv a0, s6               # a0 <- Ypos
    jal store               # guardar o Y no output_buffer

    li t0, '\n'             # t0 <- 10 ('\n')
    sb t0, 11(a2)           # insere '\n' no final do output_buffer

    jal write               # stdout <- output_address
    jalr zero, s0, 0        # retornar para _start

exit:
    li a0, 0
    li a7, 93
    ecall

_start:
    jal s0, main
    jal exit


.data
ln1_input_address: .skip 12     # first line input buffer
ln2_input_address: .skip 20     # second line input buffer
output_address: .skip 12        # output buffer
