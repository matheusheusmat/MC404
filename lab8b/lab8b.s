.globl _start

# Referências
# s0 <- _start após main
# s1 <- input_address
# s2 <- num de digitos da largura
# s3 <- num de digitos da altura
# s4 <- largura
# s5 <- altura
# s6 <- main após draw_on_canvas
# s7 <- cor do pixel
# s8 <- 256
# s9 <- largura - 1
# s10 <- altura - 1

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

# get_number_of_digits: retorna o número de caracteres de um endereço
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

# to_int: char para inteiro
# Parâmetros:
#   a0: número de dígitos
#   a1: endereço do primeiro dígito
# Retorno:
#   a0: valor inteiro
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

# create_filter_matrix: cria a matriz 3x3 de filtro, com o valor -1 em todas as posições,
# exceto na central, que é 8.
# Parâmetros: 
#   a0: endereço da matriz de filtro
create_filter_matrix:
    mv t0, a0
    li t1, 0
    li t2, -1
    li t3, 9

    bge t1, t3, 1f
    0:
        sb t2, (t0)         # Guarda "-1" na matriz
        addi t0, t0, 1      # Próximo endereço
        addi t1, t1, 1      # t1++ (variável de iteração)
        bltu t1, t3, 0b     # Volta para label '0' se t1 < 9
    1:

    li t0, 8                
    sb t0, 4(a0)            # Guarda "8" na matriz

    ret

# apply_filter: dado um pixel, aplica a matriz de filtro.
# Parâmetros:
#   a3: endereço do pixel atual da imagem
#   a4: endereço da matriz de filtro
# Retorno 
#   s7: valor do pixel (com filtro)
apply_filter:
    # a4: endereço do primeiro valor da filter_matrix
    # a3: endereço do pixel atual da imagem
    mv t0, a4       # endereço da filter_matrix
    li t1, 0        # primeiro iterador de 0 a 2 (linha)
    li t2, 0        # segundo iterador de 0 a 2 (coluna)
    li t3, 3        # limite de iteração
    li t4, 0        # guarda o valor atual da filter_matrix
    mv t5, a3       # endereço do pixel atual da imagem
    li t6, 0        # pixel atual
    addi a5, s4, -3   # largura - 3

    li s7, 0
    li s8, 256

    sub t5, t5, s4      # Achando o endereço do pixel na diagonal esquerda superior do atual
                        # pixel da imagem
    addi t5, t5, -1     # OK
    
    bge t1, t3, 3f      # Se t1 > 3, não entra no for
    0:
        li t2, 0
        
        1:
            lb t4, (t0)         # Carrega o byte da filter_matrix
            lbu t6, (t5)        # Carrega o pixel desejado da imagem
        
            mul t6, t6, t4      # t6 = t6 * t5
            add s7, s7, t6      # s7 = s7 + t6

            addi t0, t0, 1      # t0++ (próximo endereço da filter_matrix)
            addi t2, t2, 1      # t2++ (próxima iteração)
            addi t5, t5, 1      # t5++ (próximo endereço de um pixel da imagem)
        
            bltu t2, t3, 1b     # Volta para label '0' se t2 < 3
        2:

        add t5, t5, a5      # Adicionando largura - 2 para ir para a próxima linha
        addi t1, t1, 1
        bltu t1, t3, 0b     # Volta para label '0' se t1 < 3
    3:

    bge s7, zero, 0f        # Se s7 >= 0, ok
    li s7, 0                # 0 caso contrário
    0:
    blt s7, s8, 1f          # Se s7 < 255, ok
    li s7, 255              # 255 caso contrário
    1:

    ret

# filter_and_draw_on_canvas: aplica o filtro nos píxeis da entrada, exceto nas bordas,
# e imprime no canvas.
# Parâmetros:
#   filter_matrix - endereço da matriz de filtro
#   a0 - endereço do primeiro pixel da imagem de entrada
filter_and_draw_on_canvas:
    mv a3, a0               # a3 guarda o endereço do pixel (0, 0)
    li a0, 0                # x
    li a1, 0                # y
    li a2, 0                # cor do pixel atual
    la a4, filter_matrix    # a4 guarda o endereço da matriz de filtro
    li t0, 0                # t será o byte
    
    # Larugra - 1 e altura - 1 para posterior comparação
    addi s9, s4, -1
    addi s10, s5, -1
    
    aqui:
    bge a1, s5, 3f          # Não entra no "for" se a coordenada y atual for maior ou igual à altura.
    0:
        li a0, 0                    # x = 0
        1: 

            lbu t0, (a3)            # carrega o valor do pixel atual       
            li a2, 0                # zera o pixel
            li t0, 0                # zera o auxiliar para deslocamento R, G, B

            beqz a0, continue       # pula o filtro se a coordenada x for 0
            beqz a1, continue       # pula o filtro se a coordenada y for 0
            beq a0, s9, continue    # pula o filtro se a coordenada x for (largura - 1)
            beq a1, s10, continue   # pula o filtro se a coordenada y for (altura - 1)
            
            mv s7, t0           # s7 <- t0
            jal apply_filter    # aplicando o filtro
            mv t0, s7           # t0 <- s7            
            
            slli t0, t0, 8      # t3 <- t0 << 8 (Guardando B)
            add a2, a2, t0      # a2 <- a2 + t0

            slli t0, t0, 8     # t0 <- t0 << 8 (Guardando G)
            add a2, a2, t0      # a2 <- a2 + t0
            
            slli t0, t0, 8      # t3 <- t0 << 8 (Guardando R)

            continue:

            add a2, a2, t0      # a2 <- a2 + t0
            addi a2, a2, 255    # (Guardando alpha)

            jal set_pixel       # desenhando no canvas

            addi a3, a3, 1      # Próximo endereço (byte)
            addi a0, a0, 1      # x++  
            bltu a0, s4, 1b     # Volta para label '1' se x < largura
        # fim for
        2:
        addi a1, a1, 1      # y++
        bltu a1, s5, 0b     # Volta para label '0' se y < altura
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
    
    mv a0, s4            # a0 <- largura
    mv a1, s5            # a1 <- altura
    jal set_canvas_size  # define tamanho do Canvas

    la a0, filter_matrix        # a0 <- endereço da matriz de filtro
    jal create_filter_matrix    # criando a matriz de filtro

    addi a0, s1, 9  # Definindo o "offset" até o endereço do primeiro pixel
    add a0, a0, s2 
    add a0, a0, s3  # a0 <- endereço do primeiro pixel
    lbu t0, (a0)    # t0 <- Mem[a0] (primeiro pixel)

    jal s6, filter_and_draw_on_canvas  # Desenhando no Canvas

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
filter_matrix: .skip 9


.data
input_file: .asciz "image.pgm"