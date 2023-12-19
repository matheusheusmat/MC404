# Inicializando as pilhas da ISR e do usuário, respectivamente.
.bss
.align 4
isr_stack: 
.skip 1024
isr_stack_end:
user_stack: 
.skip 1024
user_stack_end:
.text
.align 2

.align 4

# Tabela de endereços do periférico
.set BASE_ADDR, 0xFFFF0100
.set GPS_TRIG, BASE_ADDR+0x00
.set POS_X, BASE_ADDR+0x10
.set POS_Y, BASE_ADDR+0x14
.set POS_Z, BASE_ADDR+0x18
.set STEER_DIR, BASE_ADDR+0x20
.set ENG_DIR, BASE_ADDR+0x21
.set SET_HANDB, BASE_ADDR+0x22


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

# int_handler: tratador de interrupções.
int_handler:
    # Salvando o contexto
    csrrw sp, mscratch, sp
    addi sp, sp, -16

    sw t0, 0(sp)
    sw t1, 4(sp)

    # Tratando a interrupção
    li t0, 10
    beq a7, t0, sc10

    li t0, 11
    beq a7, t0, sc11

    li t0, 15
    beq a7, t0, sc15

    # Set engine and steering syscall (code: 10)
    # Parâmetros:
    #   a0 - direção do movimento (-1, 0, 1)
    #   a1 - ângulo do volante [-127, 127]
    sc10:   
    li t0, ENG_DIR
    sb a0, (t0) 
    li t0, STEER_DIR
    sb a1, (t0) 
    j isr_end   

    # Set handbrake syscall (code: 11)
    # Parâmetros:
    #   a0 - ativar (1) ou desativar (outro valor) o freio de mão
    sc11:
    li t0, SET_HANDB
    sb a0, (t0) 
    j isr_end   

    # Get position syscall (code: 15)
    # Parâmetros:
    #   a0 - endereço para guardar posição X
    #   a1 - endereço para guardar posição Y
    #   a2 - endereço para guardar posição Z
    sc15:
    li t0, GPS_TRIG
    li t1, 1
    sb t1, (t0) 

    0:              # Busy-waiting até completar a leitura das posições
        lb t1, (t0) #
        bnez t1, 0b #
      
    li t0, POS_X    # Mem[a0] <- Posição X
    lw t1, (t0)     #
    sw t1, (a0)     #

    li t0, POS_Y    # Mem[a1] <- Posição Y
    lw t1, (t0)     #
    sw t1, (a1)     #

    li t0, POS_Z    # Mem[a2] <- Posição Z
    lw t1, (t0)     #
    sw t1, (a2)     #
    
    isr_end:

    # Recuperando o contexto
    lw t1, 4(sp)
    lw t0, 0(sp)

    addi sp, sp, 16
    csrrw sp, mscratch, sp

    # Retornando à execução
    csrr t0, mepc   # load return address (address of 
                    # the instruction that invoked the syscall)
    addi t0, t0, 4  # adds 4 to the return address (to return after ecall) 
    csrw mepc, t0   # stores the return address back on mepc
    mret            # Recover remaining context (pc <- mepc)
  

.globl _start
_start:
    # Inicializar a pilha do programa
    # Já feito.

    # 1 - Registrar a ISR
    la t0, int_handler  # Load the address of the routine that will handle interrupts
    csrw mtvec, t0      # (and syscalls) on the register MTVEC to set the interrupt array.

    # 2 - Configurar o mscratch para apontar para a pilha da ISR
    la t0, isr_stack_end
    csrw mscratch, t0
    la sp, user_stack_end

    # 3 - Habilitar as interrupções por software
    li t0, 0x8
    csrs mie, t0

    # 4 - Habilitar as interrupções globais
    csrs mstatus, t0

    # Mudando para modo de usuário e chamando a função user_main
    csrr t1, mstatus
    li t2, ~0x1800
    and t1, t1, t2
    csrw mstatus, t1

    la t0, user_main
    csrw mepc, t0

    mret

# control_logic: lógica de controle do carro autônomo baseada em cálculo de tangentes.
.globl control_logic
control_logic:
    addi sp, sp, -4     # Salvando endereço de RA
    sw ra, (sp)


    # Parte 1: Cálculo da tangente de referência
    la a0, curr_X
    la a1, curr_Y
    la a2, curr_Z
    li a7, 15
    ecall
    
    lw a0, (a0)     # a0 <- curr_X
    lw a1, (a2)     # a1 <- curr_Z
    jal calc_angle  # Calculando a tangente de referência
    mv t6, a0       # t6 será a tangente de referência
    
    # Parte 2: Loop
    0:
    li a0, 1            # Acelerando o carro
    la t0, curr_steer   #
    lb a1, (t0)         #
    li a7, 10           #
    ecall               #

    li t5, 1000         # Thread: atraso na execução
    4:                  #
    addi t5, t5, -1     #
    bnez t5, 4b         #

    li a0, -1           # Para de acelerar (freia)
    ecall               #

    la a0, curr_X
    la a1, curr_Y   
    la a2, curr_Z
    li a7, 15
    ecall

    lw a0, (a0)     # a0 <- posição X atual
    lw a1, (a2)     # a1 <- posição Z atual

    mv s11, a0          # s11 <- a0
    jal verify_finish   # verifica se chegou ao destino
    bnez a0, loop_end   # se chegou, sai do loop
    mv a0, s11          # a0 <- s11

    jal calc_angle      # Calcula a tangente da posição atual

    beq a0, t6, 3f      # Se for igual à referência, não vira o carro.
    bge a0, t6, 2f      # Se for maior que a referência, pula para a label '2' seguinte

    # Tangente menor -> Virar à esquerda
    li a0, -1
    li a1, -30
    la t0, curr_steer
    sb a1, (t0)
    li a7, 10
    ecall
    j 3f

    # Tangente maior -> Virar à direita
    2:
    li a0, -1
    li a1, 30
    la t0, curr_steer
    sb a1, (t0)
    li a7, 10
    ecall

    3:

    li t5, 500          # Thread: atraso na execução
    4:                  #
    addi t5, t5, -1     #
    bnez t5, 4b         #

    j 0b                # Retorna ao início do loop
    loop_end:

    # Parte 3: Parando o carro
    li a0, 0    # Parando o motor
    li a1, 0    # Deixando o volante reto
    li a7, 10  
    ecall

    li a0, 1    # Acionando freio de mão
    li a7, 11   
    ecall

    li t5, 10000        # Thread: atraso na execução
    4:                  #
    addi t5, t5, -1     #
    bnez t5, 4b         #

    lw ra, (sp)     # Recuperando endereço de RA
    addi sp, sp, 4
    ret

.bss
curr_X: .skip 4
curr_Y: .skip 4
curr_Z: .skip 4
curr_steer: .skip 1