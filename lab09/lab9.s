.globl _start

# Referências
# s0 <- start_ após main

read:
    # a1: endereço
    # a2: numero de bytes
    li a0, 0                    # file descriptor = 0 (stdin)
    li a7, 63                   # syscall read (63)
    ecall
    ret


write:
    # a1: endereço
    # a2: numero de bytes
    li a0, 1                    # file descriptor = 1 (stdout)
    li a7, 64                   # syscall write (64)
    ecall
    ret


# first_number_address: encontra endereço do primeiro dígito do número
# dado no input. 
# Retorno:
#   a0 - endereço do primeiro dígito.
#   a1 - sinal do número. -1 se negativo e 1 se positivo.
first_number_address:
    li t0, '-'
    lb t1, (a0)
    li t2, 1

    bne t1, t0, 0f      # Se não for negativo, pula essa parte.
    addi a0, a0, 1
    li t2, -1

    0:
    mv a1, t2

    ret

# get_number_of_digits: Dado o endereço do primeiro caracter de um número, encontra
# a quantidade de dígitos que possui.
# Parâmetros: 
#   a0 - endereço do primeiro caracter
# Retorno:
#   a0 - quantidade de dígitos
get_number_of_digits:
    li t0, 0            # t0 será a quantidade de caracteres. Começa como 0.
    lbu t1, (a0)        # t1 <- Mem[a0]

    li t2, ' '          # t2 <- espaço. Para comparação.
    li t3, '\n'         # t3 <- newline. Para comparação.

    beq t1, t2, 1f      # Verifica se inicia no espaço. Se sim, não entra no "while"
    beq t1, t3, 1f      # Verifica se inicia no newline. Se sim, não entra no "while"
    0:                 
        addi t0, t0, 1  # Mais um dígito foi encontrado
        addi a0, a0, 1  # a0 <- próximo endereço [a0 + 1]
        lbu t1, (a0)    # t1 <- Mem[a0]
        beq t1, t2, 1f  # Verifica se é um espaço...
        beq t1, t3, 1f  # ... ou newline.
        j 0b            # Se não, volta para a label '0' anterior
    
    1: 
    mv a0, t0   # a0 <- t0
    ret


# to_int: char para inteiro
# Parâmetros:
#   a0 - número de dígitos
#   a1 - endereço do primeiro dígito
#   a2 - sinal do número. -1 se negativo e 1 se positivo.
# Retorno:
#   a0 - valor inteiro
to_int:
    addi t0, a0, -1
    li t1, 1            
    li t2, 10           # 10 (base da potência de 10)

    beqz t0, 1f         # Essa parte calcula a maior potência de 10
    0:                  # e a guarda em t1. t0 e t2 podem ser reutilizados.
    mul t1, t1, t2
    addi t0, t0, -1
    bnez t0, 0b
    1:

    mv t0, a1           # t0 <- endereço do primeiro dígito
    lbu t2, (t0)        # t2 <- Mem[a1] (endereço do primeiro dígito)
    li t3, 10           # t3 <- 10
    li t4, 0            # t4 guarda o resultado

    0:
        addi t2, t2, -48    # Pega o byte atual e converte de caracter para inteiro
        mul t2, t2, t1      # Multiplica o inteiro pela potência de 10 atual
        add t4, t4, t2      # Adicionar ao resultado atual
        addi t0, t0, 1      # t0++, para alcançar o próximo endereço
        lbu t2, (t0)        # t2 <- Mem[t0] (próximo caracter)
        divu t1, t1, t3     # t1 <- t1 / 10 (Divide a potência atual por 10, para obter a próxima potência)
        bnez t1, 0b         # Se t1 != 0, retorna ao inicio do while
    1:

    mul t4, t4, a2      # Multiplica pelo sinal
    mv a0, t4           # a0 <- t4. Resultado.
    ret


# find_node: encontra o nó de uma lista ligada que contenha o valor desejado.
# Parâmetros:
#   a0 - o valor desejado
#   a1 - head_node, o primeiro nó (nó 0)
# Retorna:
#   a0 - o nó em que o valor for encontrado, começando no 0.
#   -1 caso o valor não for encontrado na lista ligada.
find_node:
    li t0, 0           # índice do nó

    0:
    lw t1, (a1)        # t1 <- VAL1
    lw t2, 4(a1)       # t2 <- VAL2
    add t3, t1, t2     # t3 <- t1 + t2

    beq t3, a0, found  # Se for igual ao valor desejado, encontrado.

    # Se não...
    addi t0, t0, 1     # indice++
    lw a1, 8(a1)       # a1 <- end. prox nó
    bnez a1, 0b        # Continua a iteração se o ponteiro para o prox não for NULL.
    1:

    # Se chegou aqui, não encontrou.
    li a0, -1
    ret

    found:
    # Se chegou aqui, encontrou.
    mv a0, t0
    ret

# to_char: converte um inteiro para char e o salva no output_address. 
# Parâmetros: 
#   a0 - valor a ser convertido (no caso, índice do nó)
to_char:
    li t0, -1
    beq a0, t0, 2f      # Pula para a label "2" seguinte se a0 == -1 (valor não encontrado)

    # Int to char

    la t0, output_aux
    li t1, 10           
    li t3, 0
    0:
        rem t2, a0, t1      # t2 <- a0 % 10
        addi t2, t2, 48     # t2 <- t2 + 48 (int para char)
        sb t2, (t0)         # Mem[t0] <- t2 (caracter)
        addi t3, t3, 1      # t3++ (mais um dígito)
        div a0, a0, t1      # a0 <- a0 / 10
        addi t0, t0, 1      # Mem[t0]++
        bnez a0, 0b         # Volta à label "0" se a0 != 0
    
    addi t3, t3, -1         # t3-- 
    la t0, output_aux       
    la t1, output_address   
    add t2, t0, t3          # t2 <- t0 + t3 (endereço do primeiro caracter da saída)
    1:                      # Invertendo o aux e salvando no output
        lb t4, (t2)
        sb t4, (t1)
        addi t1, t1, 1
        addi t2, t2, -1
        bge t2, t0, 1b
    
    li t0, '\n'
    sb t0, (t1)

    addi t3, t3, 2          # t3 <- t2 + 2 (número de bytes para impressão)
    mv a0, t3               # a0 <- t3
    ret 

    2:                      # Caso-base de a0 == -1. Salvando no output.
    li t0, '-'
    sb t0, (a1)

    li t0, '1'
    sb t0, 1(a1)

    li t0, '\n'
    sb t0, 2(a1)

    li a0, 3
    ret

main:
    la a1, input_address
    li a2, 7                    # Lendo número
    jal read

    mv a0, a1                   # a0 <- input_address
    jal first_number_address    
    mv a2, a1                   # a2 <- sinal do número (1 ou -1)

    mv a1, a0                   # a1 <- a0 (endereço do primeiro dígito)
    jal get_number_of_digits    # a0 <- número de dígitos
    jal to_int                  # a0 <- número inteiro procurado

    la a1, head_node            # a1 <- head_node
    jal find_node               # a0 <- índice do nó

    la a1, output_address       # a1 <- output_address

    jal to_char                 # Salvando o índice do nó no output_address
    
    mv a2, a0
    jal write                   # Imprimindo no stdout

    jr s0

exit:
    li a0, 0
    li a7, 93
    ecall

_start:
    jal s0, main
    jal exit

.bss
    input_address: .skip 7
    output_address: .skip 4
    output_aux: .skip 3
