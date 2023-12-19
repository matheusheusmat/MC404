.text
.globl set_engine
.globl set_handbrake
.globl read_sensor_distance
.globl get_position
.globl get_rotation
.globl get_time
.globl puts
.globl gets
.globl atoi
.globl itoa
.globl strlen_custom
.globl approx_sqrt
.globl get_distance
.globl fill_and_pop


# set_engine: define direção do motor e ângulo do volante.
# Parâmetros:
#   a0 - Direção do motor {-1, 0, 1}
#   a1 - Direção do volante [-127, 127]
# Retorno:
#   a0 - 0, se definido com sucesso, ou -1, se parâmetros inválidos.
set_engine:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)

    li a7, 10
    ecall

    lw ra, (sp)         # Recuperando conteúdo de RA
    addi sp, sp, 4
    ret


# set_handbrake: aciona ou desativa o freio de mão.
# Parâmetros:
#   a0 - Parâmetro para o freio de mão. Aciona se 1, e desativa se 0.
# Retorno:
#   a0 - 0, se definido com sucesso, ou -1, se parâmetros inválidos.
set_handbrake:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)

    li t0, 0
    blt a0, t0, 0f

    li t0, 2
    bge a0, t0, 0f

    li a7, 11
    ecall
    li a0, 0

    lw ra, (sp)         # Recuperando conteúdo de RA
    addi sp, sp, 4

    ret

    0:
    li a0, -1

    lw ra, (sp)         # Recuperando conteúdo de RA
    addi sp, sp, 4
    ret


# read_sensor_distance: retorna distância fornecida pelo sensor
# do carro.
# Retorno: distância até 20 metros, e -1 se nada detectado 
# nesse alcance.
read_sensor_distance:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)

    li a7, 13
    ecall

    lw ra, (sp)         # Recuperando conteúdo de RA
    addi sp, sp, 4
    ret


# get_position: retorna a posição aproximada do carro segundo
# seu GPS, em forma X, Y, Z.
# Parâmetros:
# a0 - endereço da variável para guardar posição X
# a1 - endereço da variável para guardar posição Y
# a2 - endereço da variável para guardar posição Z
get_position:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)

    li a7, 15
    ecall

    lw ra, (sp)         # Recuperando conteúdo de RA
    addi sp, sp, 4
    ret


# get_rotation: retorna a rotação Euler em cada eixo, como
# fornecido pelo GPS do carro.
# Parâmetros:
# a0 - endereço da variável para guardar rotação X
# a1 - endereço da variável para guardar rotação Y
# a2 - endereço da variável para guardar rotação Z
get_rotation:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)

    li a7, 16
    ecall

    lw ra, (sp)         # Recuperando conteúdo de RA
    addi sp, sp, 4
    ret


# get_time: retorna o system time
# Retorno:
# a0 - tempo desde o início da execução do programa.
get_time:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)

    li a7, 20
    ecall

    lw ra, (sp)         # Recuperando conteúdo de RA
    addi sp, sp, 4
    ret


# puts: Troca o /0 no final de um buffer por /n e o imprime
# no Serial Port.
# Parâmetros:
#   a0 - endereço do buffer terminado em /0 que será impresso
#   no Serial Port
puts:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)

    mv t0, a0

    0:
        lb t1, (t0)
        beqz t1, 1f
        addi t0, t0, 1
        j 0b
    1:

    li t1, '\n'
    sb t1, (t0)
    sb zero, 1(t0)

    li a7, 18
    ecall

    lw ra, (sp)         # Recuperando conteúdo de RA
    addi sp, sp, 4

    ret


# gets: lê do Serial Port até encontrar /0.
# Parâmetros:
#   a0 - endereço do buffer que será preenchido com
# a entrada do Serial Port
# Retorno:
#   a0 - endereço desse mesmo buffer
gets:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)

    mv t6, a0
    mv t5, a0
    li t0, '\n'
    li a7, 17       # Código da syscall = 17
    
    0:
        li a1, 1        # a1 <- 1 byte a ser lido
        mv a0, t5       # a0 <- t5 (posição atual do buffer)

        ecall           # Realiza chamada de sistema, code 17

        lb t1, (t5)
        beq t1, t0, 1f
        addi t5, t5, 1  # Próximo endereço de memória
        j 0b
    1:

    sb zero, (t5)
    mv a0, t6

    lw ra, (sp)         # Recuperando conteúdo de RA
    addi sp, sp, 4

    ret


# atoi: converte de char para inteiro
# Parâmetros:
#   a0 - endereço da string
# Retorno:
#   a0 - valor inteiro
atoi:
    li t0, 1            # Sinal inicial do número.

    # Parte 1: Pegar sinal, vendo se é negativo ou positivo
    li t1, '-'
    lb t2, (a0)
    bne t2, t1, 0f          # Se for positivo, tudo certo
    
    # Tratamento se for negativo
    li t0, -1               # Fator de sinal = -1
    addi a0, a0, 1          # Endereço do primeiro dígito do número.

    0: 
    # Parte 2: Achando o número de dígitos. EM USO: t0 (fator de sinal) e a0 (endereço do primeiro dígito)
    li t1, 0        # t1 será a quantidade de caracteres.
    lb t2, (a0)     # t2 <- Mem[a0] (primeiro dígito)
    li t3, 0        # t3 <- 0 (NULL). Para comparação
    mv t4, a0       # t4 <- a0 (endereço do primeiro dígito)

    beq t2, t3, 1f  # Verifica se inicia no NULL. Se sim, não entra no while
    0:
        addi t1, t1, 1      # Mais um dígito foi encontrado.
        addi t4, t4, 1      # t4 <- próximo endereço
        lb t2, (t4)         # t2 <- Mem[t4]
        bne t2, t3, 0b      # Se t2 != NULL, volta para a label '0' anterior
    1:
    # t1 agora possui a qtd de dígitos!
    
    
    # Parte 3: Converter o módulo para inteiro. Em uso: t0 (fator de sinal), t1 (qtd de dígitos) e a0 (end. prim. dig)
    
    # Calculando a maior potência de 10
    addi t1, t1, -1         # t1--
    li t2, 1                # Caso-base: 10^0 = 1
    li t3, 10               # Base da potência

    beqz t1, 1f
    0:
        mul t2, t2, t3      # t2 <- t2 * t3
        addi t1, t1, -1     # t1--
        bnez t1, 0b         # Se t1 != 0, retorna à label '0' anterior
    1:

    # Maior potência de 10 está em t2! Em uso: t0, t2, a0
    mv t1, a0       # t1 <- endereço do primeiro dígito
    lb t3, (t1)     # t3 <- Mem[t1]
    li t4, 10       # t4 <- 10 (para divisão)
    li t5, 0        # t5 será o resultado
    
    0:
        addi t3, t3, -48    # Caracter -> inteiro
        mul t3, t3, t2      # Multiplica o inteiro pela potência de 10 atual
        add t5, t5, t3      # Adicionar ao resultado atual
        addi t1, t1, 1      # t1++, para alcançar o próximo endereço
        lb t3, (t1)         # t3 <- Mem[t1] (próximo caracter)
        divu t2, t2, t4     # Dividindo a potência atual por 10
        bnez t2, 0b         # Se t1 != 0, retorna à label '0' anterior
    1:

    # Parte 4: Multiplicar o módulo pelo fator de sinal
    mul a0, t5, t0

    # Parte 5: Retornar
    ret


# itoa: converte um inteiro para char e o salva no buffer dado na entrada.
# Parâmetros
#   a0 - valor a ser convertido
#   a1 - endereço da string
#   a2 - base (10 ou 16)
# Retorno:
#   a0 - endereço da string
itoa:
    mv t5, a1
    li t6, 0

    li t0, 16
    beq a2, t0, base16

    # Para a base decimal #
    base10: 
    la t0, output_aux

    #### Verificação se é negativo ####
    li t1, 0
    bge a0, t1, 0f      # Se o número for positivo, pula essa parte e vai para label '0' seguinte
    neg a0, a0          # a0 <- -a0
    li t6, -1           # t6 <- -1 (para posterior comparação)
    addi t0, t0, 1      # Mem[t0++]
    #### Fim da verificação ####
    0:

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
    
    j 3f

    # Para a base hexadecimal #
    base16:

    li t1, 16               # t1 <- 16 (base)
    li t3, 0                # t3 guarda o número de dígitos
    li t4, 10               # t4 <- 10. Para comparação.
    la t0, output_aux

    0:
        remu t2, a0, t1      # t2 <- a0 % 16

        blt t2, t4, 1f      # Se estiver entre 0 e 9, pula para '1'
        addi t2, t2, -10    # Subtrai 10
        addi t2, t2, 65     # Se 10 < t2 < 15, soma 97 para ir ao 'a'
        j 2f
        1:
        addi t2, t2, 48     # t2 <- t2 + 48 (int para char)
        2:
        
        sb t2, (t0)         # Mem[t0] <- t2 (caracter)
        addi t3, t3, 1      # t3++ (mais um dígito)
        divu a0, a0, t1      # a0 <- a0 / 16
        addi t0, t0, 1      # Mem[t0]++
        bnez a0, 0b         # Volta à label "0" se a0 != 0

    3:                      # Parte de inverter o auxiliar

    addi t3, t3, -1         # t3-- 
    
    la t0, output_aux       
    mv t1, a1

    #### Verificação se é negativo ####
    li t2, -1
    bne t6, t2, 0f

    li t2, '-'
    sb t2, (t1)
    addi t0, t0, 1
    addi t1, t1, 1

    #### Fim da verificação ####
    0:

    add t2, t0, t3          # t2 <- t0 + t3 (endereço do primeiro caracter da saída)
    1:                      # Invertendo o aux e salvando no output
        lb t4, (t2)
        sb t4, (t1)
        addi t1, t1, 1
        addi t2, t2, -1
        bge t2, t0, 1b
    
    li t0, 0
    sb t0, (t1)             # Salvando NULL no fim do output

    addi t3, t3, 1          # t3++
    sub t1, t1, t3          # Retornando ao primeiro dígito do output

    0:
    mv a0, t5               # a0 <- t5
    ret


# strlen_custom: encontra o tamanho de uma string, sem contar o /0 no final.
# Parâmetros:
#   a0 - endereço de um buffer, terminado em /0
# Retorno:
#   a0 - tamanho da string, sem contar o /0
strlen_custom:
    mv t0, a0
    li a0, 0

    0:
        lb t1, (t0)     # t1 <- Mem[t0]
        beqz t1, 1f     # Sai do loop se t1 == 0

        addi a0, a0, 1  # Mais um caracter != 0 encontrado
        addi t0, t0, 1  # Próximo caracter da string
        j 0b
    1:

    ret


# approx_sqrt: raiz quadrada aproximada usando o Método 
# Babilônico
# Parâmetros:
# a0 - valor para o qual se deseja calcular a raiz
# a1 - número de iterações (quanto mais, mais preciso o cálculo)
# Retorno:
# a0 - raiz quadrada aproximada do valor
approx_sqrt:

    mv t0, a1 
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


# get_distance - distância euclidiana entre dois pontos, A e B, em 
# um espaço tridimensional.
# Parâmetros: 
#   a0 - Posição X do ponto A
#   a1 - Posição Y do ponto A
#   a2 - Posição Z do ponto A
#   a3 - Posição X do ponto B
#   a4 - Posição Y do ponto B
#   a5 - Posição Z do ponto B
# Retorno:
#   a0 - distância entre A e B
get_distance:
    # Padrão: B é ponto final e A é ponto inicial.
    addi sp, sp, -4 # Salvando conteúdo de RA
    sw ra, (sp)
    
    sub a3, a3, a0  # Delta X
    mul a3, a3, a3  # Delta X^2

    sub a4, a4, a1  # Delta Y
    mul a4, a4, a4  # Delta Y^2

    sub a5, a5, a2  # Delta Z
    mul a5, a5, a5  # Delta Z^2

    add a0, a3, a4  # a0 <- X^2 + Y^2
    add a0, a0, a5  # a0 <- X^2 + Y^2 + Z^2
    
    li a1, 15           # 15 iterações para raiz quadrada
    jal approx_sqrt     # a0 <- sqrt(a0)

    lw ra, (sp)     # Recuperando conteúdo de RA
    addi sp, sp, 4

    ret


# fill_and_pop: copia todos os campos de um nó para outro e retorna
# o próximo nó da lista ligada.
# Parâmetros:
#   a0 - endereço do nó-cabeça atual da lista ligada
#   a1 - endereço do nó-destino dos dados do nó-cabeça lido
# Retorno:
#   a0 - endereço do nó seguinte ao nó-cabeça lido
fill_and_pop:
    lw t0, (a0)
    sw t0, (a1)

    lw t0, 4(a0)
    sw t0, 4(a1)

    lw t0, 8(a0)
    sw t0, 8(a1)

    lw t0, 12(a0)
    sw t0, 12(a1)

    lw t0, 16(a0)
    sw t0, 16(a1)

    lw t0, 20(a0)
    sw t0, 20(a1)

    lw t0, 24(a0)
    sw t0, 24(a1)

    lw t0, 28(a0)
    sw t0, 28(a1)

    mv a0, t0

    ret


.bss
output_aux: .skip 200