.globl _start

# Referências
# s0 <- _start após main
# s1 <- input_address
# s2 <- num de digitos da largura
# s3 <- num de digitos da altura
# s4 <- largura
# s5 <- altura
# s6 <- main após draw_on_canvas

open:
    la a0, input_file
    li a1, 0
    li a2, 0
    li a7, 1024
    ecall
    ret

read:
    la a1, input_address  # buffer to write the data to
    li a7, 63             # syscall read (63)
    ecall
    ret

set_pixel:
    # a0: x coordinate
    # a1: y coordinate
    # a2: concatenated pixel's colors: R|G|B|A
        # A2[31..24]: Red
        # A2[23..16]: Green
        # A2[15..8]: Blue
        # A2[7..0]: Alpha
    li a7, 2200
    ecall
    ret

set_canvas_size:
    # a0: canvas width (largura 0-512)
    # a1: canvas height (altura 0-512)
    li a7, 2201
    ecall
    ret

# get_number_of_digitos: retorna o número de caracteres de um endereço
# de memória até o próximo espaço ou newline.
# Parâmetros:
#   a0: o endereço do primeiro caracter
# Retorno:
#   a0: a quantidade de dígitos do trecho até o próximo espaço (ASCII 32) ou 
#   newline (ASCII 10)
get_number_of_digits:
    li t0, 0            # t0 será a quantidade de caracteres. Começa como 0.
    lbu t1, (a0)        # t1 <- Mem[a0]

    li t2, ' '          # t2 <- espaço. Para comparação.
    li t3, '\n'         # t3 <- newline. Para comparação

    beq t1, t2, 1f      # Verifica se inicia no espaço. Se sim, não entra no "while"
    beq t1, t3, 1f      # Verifica se inicia no newline. Se sim, não entra no "while"
    0:
    # inicio while                   
        addi t0, t0, 1  # Mais um dígito foi encontrado
        addi a0, a0, 1  # a0 <- próximo endereço [a0 + 1]
        lbu t1, (a0)    # t1 <- Mem[a0]
        beq t1, t2, 1f  # Verifica se é um espaço...
        beq t1, t3, 1f  # ... ou newline.
        j 0b            # Se não, volta para a label '0' anterior
    # fim while
    
    1: 
    mv a0, t0   # a0 <- t0
    ret


to_int:
    addi t0, a0, -1
    li t1, 1
    li t2, 10

    beqz t0, 1f         # Essa parte calcula a maior potência de 10
    0:                  # e a guarda em t1. t0 e t2 podem ser reutilizados.
    mul t1, t1, t2
    addi t0, t0, -1
    bnez t0, 0b
    1:

    mv t0, a1           # t0 <- endereço do primeiro dígito
    lbu t2, (t0)        # t2 <- Mem[a1] (endereço do primeiro dígito da largura)
    li t3, 10           # t3 <- 10
    li t4, 0            # t4 guarda o resultado


    0:
    # inicio while
        addi t2, t2, -48    # Pega o byte atual e converte de caracter para inteiro
        mul t2, t2, t1      # Multiplica o inteiro pela potência de 10 atual
        add t4, t4, t2      # Adicionar ao resultado atual
        addi t0, t0, 1      # t0++, para alcançar o próximo endereço
        lbu t2, (t0)        # t2 <- Mem[t0] (próximo caracter)
        divu t1, t1, t3     # t1 <- t1 / 10 (Divide a potência atual por 10, para obter a próxima potência)
        bnez t1, 0b         # Se t1 != 0, retorna ao inicio do while
    1:
    # fim while

    mv a0, t4   # a0 <- t4. Resultado.
    ret


draw_on_canvas:
    li t0, 0                # guarda o y. altura está em s5
    li t1, 0                # guarda o x. largura está em s4
    li t2, 0                # t2 será o byte
    li a2, 0                # a2 será o valor do pixel em grayscale
    mv a3, a0               # a3 guarda o endereço de memória do pixel

    bge t0, s5, 3f          # Não entra no "for" se a coordenada y atual for maior ou igual à altura.
    0:
    # inicio for
        li t1, 0                # x = 0
        bge t1, s4, 2f          # Não entra no "for" se a coordenada x atual for maior ou igual à largura.
        1: 
        # início for 
            lbu t2, (a3)        # t2 <- Mem[a3]
            mv a0, t1           # a0 <- t1 (coordenada x)
            mv a1, t0           # a1 <- t0 (coordenada y)
            li a2, 0            # zera o pixel

            slli t3, t2, 24     # t3 <- t2 << 24 (Guardando R)
            add a2, a2, t3      # a2 <- a2 + t3

            slli t3, t2, 16     # t3 <- t2 << 16 (Guardando G)
            add a2, a2, t3      # a2 <- a2 + t3
            
            slli t3, t2, 8      # t3 <- t2 << 8 (Guardando B)      
            add a2, a2, t3      # a2 <- a2 + t3
            addi a2, a2, 255    # (Guardando alpha)

            jal set_pixel

            addi a3, a3, 1      # Próximo endereço (byte)
            addi t1, t1, 1      # x++  
            bltu t1, s4, 1b     # Volta para label '1' se x < largura
        # fim for
        2:
        
    addi t0, t0, 1      # y++
    bltu t0, s5, 0b     # Volta para label '0' se y < altura
    # fim for
    3: 

    jr s6

main:
    jal open

    li a2, 262159
    jal read    # a1 <- input_address
    mv s1, a1   # s1 <- a1

    addi a0, s1, 3
    mv a1, a0
    jal get_number_of_digits    # a0 <- número de digitos da largura
    
    mv s2, a0                   # s2 <- a0       
    jal to_int                  # a0 <- valor da largura
    mv s4, a0                   # s4 <- largura

    addi a0, s1, 3              # a0 <- endereço do primeiro dígito da largura
    addi t2, s2, 1              # t2 <- num de dígitos da largura + espaço
    add a0, a0, t2              # a0 <- a0 + t2
    mv a1, a0                   # a1 <- a0 (endereço do primeiro dígito da altura)
    jal get_number_of_digits    # a0 <- número de dígitos da altura
    mv s3, a0
    jal to_int                  # a0 <- valor da altura
    mv s5, a0                   # s5 <- altura
    
    mv a0, s4   # a0 <- largura
    mv a1, s5   # a1 <- altura
    jal set_canvas_size  # define tamanho do Canvas

    addi a0, s1, 9  # Definindo o "offset" até o endereço do primeiro pixel
    add a0, a0, s2 
    add a0, a0, s3  # a0 <- endereço do primeiro pixel
    lbu t0, (a0)    # t0 <- Mem[a0] (primeiro pixel)

    jal s6, draw_on_canvas  # Desenhando no Canvas

    jr s0

exit:
    li a0, 0
    li a7, 93
    ecall

_start:
    jal s0, main
    jal exit

.bss
input_address: .skip 262159

.data
input_file: .asciz "image.pgm"