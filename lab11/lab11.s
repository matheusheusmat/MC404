.globl _start

# Tabela de endereços do periférico
# Valores cessados pelos registradores com li rd, lab
.set base_addr, 0xFFFF0100
.set steering_dir, 0xFFFF0120
.set engine_dir, 0xFFFF0121
.set pos_X, 0xFFFF0110
.set pos_Y, 0xFFFF0114
.set pos_Z, 0xFFFF0118


exit:
    li a0, 0
    li a7, 93
    ecall

# calc_angle: calcula a tangente do ângulo entre o ponto atual do
# veículo e o ponto de destino, multiplicada por 100, para fins de
# precisão.
# Parâmetros:
#   a0 - posição X atual
#   a1 - posição Z atual
# Retorno:
#   a0 - tg(ângulo) * 100
calc_angle:
    li t0, 73
    sub t0, t0, a0      # delta X
    neg t0, t0          # módulo de delta X

    li t1, -19
    sub t1, t1, a1      # delta Z

    li t2, 100          # delta Z * 100
    mul t1, t1, t2

    div t2, t1, t0      # tg(ângulo) = delta Z / delta X
    
    mv a0, t2           # a0 <- t2
    ret


# sqrt: raiz quadrada
# Parâmetros:
#   a0 - inteiro para o qual se deseja calcular a raiz quadrada
# Retorno:
#   a0 - sqrt(a0)
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


# verify_finish: verifica se chegou ou não ao destino
# Parâmetros: 
#   a0 - posição X atual
#   a1 - posição Z atual
# Retorno:
#   a0 - 1 se chegou ao destino, 0 se não chegou
verify_finish:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)    

    li t0, 73
    sub t0, t0, a0      # delta X
    mul t0, t0, t0      # delta X^2

    li t1, -19
    sub t1, t1, a1      # delta Z
    mul t1, t1, t1      # delta Z^2

    add a0, t0, t1      # a0 <- X^2 + Z^2
    jal sqrt            # Raiz quadrada do valor acima

    li t0, 15           # t0 <- 15 (para comparação)

    blt a0, t0, 1f      # Se for menor que 15, chegou ao destino

    li a0, 0    # Não chegou, a0 <- 0
    j 2f

    1:
    li a0, 1    # Chegou, a0 <- 1

    2:
    lw ra, (sp)         # Recuperando conteúdo de RA
    addi sp, sp, 4

    ret

main:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)     

    li t0, 1            # Ativando o GPS
    li t1, base_addr    #
    sb t0, (t1)         #

    0:                  # Busy-waiting: espera até a leitura das
    lb t0, (t1)         # coordenadas estar finalizada.
    bnez t0, 0b

    li t0, pos_X        # t0 <- endereço da pos_X 
    lw a0, (t0)         # a0 <- pos_X

    li t0, pos_Z        # t0 <- endereço da pos_Z
    lw a1, (t0)         # a1 <- pos_Z

    jal calc_angle      # Calculando a tangente de referência
    mv t6, a0           # t6 <- a0 (t6 será a tangente de referência)


    ####### INICIO LOOP #######
    0:

    li t0, 1            # Acelerando o carro
    li t1, engine_dir   #   
    sb t0, (t1)         #

    li t5, 1000         # Thread: atraso na execução
    5:                  #
    addi t5, t5, -1     #
    bnez t5, 5b         #

    li t2, -1
    sb t2, (t1)

    li t0, 1            # Ativando o GPS
    li t1, base_addr    #
    sb t0, (t1)         #

    4:                  # Busy-waiting: espera até a leitura das
    lb t0, (t1)         # coordenadas estar finalizada.
    bnez t0, 4b         # 

    li t0, pos_X        # t0 <- endereço da pos_X 
    lw a0, (t0)         # a0 <- pos_X

    li t0, pos_Z        # t0 <- endereço da pos_Z
    lw a1, (t0)         # a1 <- pos_Z

    mv s11, a0          # s11 <- a0
    jal verify_finish   # Verifica se chegou ao destino
    bnez a0, 6f         # Se chegou, sai do loop
    mv a0, s11          # a0 <- s11

    jal calc_angle      # Calcula a tangente da posição atual

    beq a0, t6, 3f      # Se for igual à referência, não vira o carro
    bge a0, t6, 2f      # Se for maior que a referência, pula para label '2' seguinte

    1:
    # Tangente menor -> Virar à esquerda
    li t0, -30
    li t1, steering_dir
    sb t0, (t1)
    j 3f

    2:
    # Tangente maior -> Virar à direita
    li t0, 30
    li t1, steering_dir
    sb t0, (t1)

    3:

    li t5, 500          # Thread: atraso na execução
    5:                  #
    addi t5, t5, -1     #
    bnez t5, 5b         #

    j 0b                # Retorna ao início do loop
    ####### FIM LOOP #######
    6:

    lw ra, (sp)         # Recuperando conteúdo de RA
    addi sp, sp, 4

    ret

_start:
    jal main
    jal exit
