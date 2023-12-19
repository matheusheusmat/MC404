# Inicializando as pilhas da ISR e do usuário, respectivamente.
.bss
.align 4
isr_stack: 
.skip 1024
isr_stack_end:
.text
.align 2

.align 4

# Tabela de endereços dos periféricos
# General Purpose Timer
.set GPT_BASE, 0xFFFF0100
.set GPT_TRIG, GPT_BASE+0
.set GPT_TIME, GPT_BASE+4
.set GPT_EXTINT_TIME, GPT_BASE+8

# Self-Driving Car
.set CAR_BASE, 0xFFFF0300
.set GPS_TRIG, CAR_BASE+0x00
.set LINECAM_TRIG, CAR_BASE+0x01
.set SENSOR_TRIG, CAR_BASE+0x02
.set EULER_X, CAR_BASE+0x04
.set EULER_Y, CAR_BASE+0x08
.set EULER_Z, CAR_BASE+0x0c 
.set POS_X, CAR_BASE+0x10
.set POS_Y, CAR_BASE+0x14
.set POS_Z, CAR_BASE+0x18
.set SENSOR_DIST, CAR_BASE+0x1c
.set STEER_DIR, CAR_BASE+0x20
.set ENG_DIR, CAR_BASE+0x21
.set SET_HANDB, CAR_BASE+0x22
.set LINECAM_IMG, CAR_BASE+0x24

# Serial Port
.set SERIAL_BASE, 0xFFFF0500
.set WRITE_TRIG, SERIAL_BASE+0
.set WRITE_BYTE, SERIAL_BASE+1
.set READ_TRIG, SERIAL_BASE+2
.set READ_BYTE, SERIAL_BASE+3

# Tabela com endereço das syscalls
isr_table:
    .word syscall_set_engine_and_steering   # Code 10
    .word syscall_set_handbrake             # Code 11
    .word syscall_read_sensors              # Code 12
    .word syscall_read_sensor_distance      # Code 13
    .skip 4                                 # Code 14 (inexistente)
    .word syscall_get_position              # Code 15
    .word syscall_get_rotation              # Code 16
    .word syscall_read_serial               # Code 17
    .word syscall_write_serial              # Code 18
    .skip 4                                 # Code 19 (inexistente)
    .word syscall_get_systime               # Code 20


int_handler:
    # Salvando o contexto
    csrrw sp, mscratch, sp
    addi sp, sp, -64

    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    sw t3, 12(sp)
    sw t4, 16(sp)
    sw t5, 20(sp)
    sw t6, 24(sp)

    # Tratando a interrupção
    mv t5, a7
    addi t5, t5, -10
    slli t5, t5, 2
    la t6, isr_table
    add t6, t6, t5
    lw t5, (t6)
    jalr t5 

    # syscall_set_engine_and_steering - Code 10
    # Parâmetros:
    #   a0 - direção do motor
    #   a1 - direção do volante
    # Retorno:
    #   a0 - 0, se definido com sucesso, ou -1, se parâmetros inválidos.
    syscall_set_engine_and_steering:
    # Verificação de parâmetros válidos

    li t0, -1
    blt a0, t0, 0f

    li t0, 2
    bge a0, t0, 0f

    li t0, -127
    blt a1, t0, 0f

    li t0, 128
    bge a1, t0, 0f

    # Se parâmetros ok, salva nos endereços
    li t0, ENG_DIR
    sb a0, (t0)
    li t0, STEER_DIR
    sb a1, (t0)
    li a0, 0
    j isr_end

    0:
    # Se parâmetros inválidos, apenas retorna -1
    li a0, -1
    j isr_end

    # syscall_set_handbrake - Code 11
    # Parâmetros:
    #   a0 - Ativa (1) ou desativa (0) o freio de mão
    syscall_set_handbrake:
    # Code 11
    li t0, SET_HANDB
    sb a0, (t0)
    j isr_end

    # syscall_read_sensors - Code 12
    # Parâmetros:
    # a0 - endereço de vetor que guardará os valores lidos pelo sensor de luminosidade.
    syscall_read_sensors:
    li t0, LINECAM_TRIG     # Habilitando a leitura dos sensores
    li t1, 1                # 
    sb t1, (t0)             #

    0:                      # Busy-waiting até completar a leitura
        lb t1, (t0)         #
        bnez t1, 0b         #


    li t0, LINECAM_IMG
    addi t1, t0, 256

    0:
        lb t2, (t0)
        sb t2, (a0)
        addi a0, a0, 1
        addi t0, t0, 1
        blt t0, t1, 0b
    j isr_end

    # syscall_read_sensor_distance - Code 13
    # Retorno:
    #   a0 - distância, de até 20 metros, ao obstáculo mais próximo. -1 se fora
    #   de alcance.
    syscall_read_sensor_distance:
    li t0, SENSOR_TRIG
    li t1, 1
    sb t1, (t0)

    0:
        lb t1, (t0)
        bnez t1, 0b
    
    li t0, SENSOR_DIST
    lw a0, (t0)

    j isr_end

    # syscall_get_position - Code 15
    # Parâmetros:
    #   a0 - endereço para guardar posição X
    #   a1 - endereço para guardar posição Y
    #   a2 - endereço para guardar posição Z
    syscall_get_position:
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

    j isr_end

    # syscall_get_rotation - Code 16
    # Parâmetros:
    #   a0 - endereço para guardar ângulo de Euler X
    #   a0 - endereço para guardar ângulo de Euler Y
    #   a0 - endereço para guardar ângulo de Euler Z
    syscall_get_rotation:
    li t0, GPS_TRIG
    li t1, 1
    sb t1, (t0) 

    0:              # Busy-waiting até completar a leitura das posições
        lb t1, (t0) #
        bnez t1, 0b #

    li t0, EULER_X    # Mem[a0] <- Ângulo Euler X
    lw t1, (t0)     #
    sw t1, (a0)     #

    li t0, EULER_Y    # Mem[a1] <- Ângulo Euler Y
    lw t1, (t0)     #
    sw t1, (a1)     #

    li t0, EULER_Z    # Mem[a2] <- Ângulo Euler Z
    lw t1, (t0)     #
    sw t1, (a2)     #

    j isr_end

    # syscall_read_serial - Code 17
    # Parâmetros: 
    #   a0 - endereço do buffer onde serão armazenados os bytes lidos pelo Serial Port.
    #   a1 - quantidade máxima de bytes a serem lidos.
    # Retorno:
    #   a0 - quantidade de bytes lidos.
    syscall_read_serial:
    li t0, READ_BYTE
    li t1, READ_TRIG
    li t4, 0

    1:
        li t2, 1            # Habilitando leitura do Serial Port
        sb t2, (t1)         #
        0:                      # Espera ocupada até a leitura do byte estar completa
            lb t2, (t1)         #
            bnez t2, 0b         #
        
        lb t2, (t0)         # Lê o byte do read_byte
        sb t2, (a0)         # Guardando o byte lido na posição atual do buffer
        beqz t2, 2f         # Se for 0, sai do loop

        addi a1, a1, -1     # a1-- (menos um byte ainda a ser lido)
        addi t4, t4, 1      # t4++ (mais um byte lido)
        beqz a1, 2f
        addi a0, a0, 1      # a0++ (próx. posição do buffer)
        
        j 1b

    2:
    

    mv a0, t4
    
    j isr_end

    # syscall_write_serial - Code 18
    # Parâmetros: 
    #   a0 - endereço do buffer a ser impresso no Serial Port.
    syscall_write_serial:
    li t0, WRITE_BYTE
    li t1, WRITE_TRIG

    1:
        lb t2, (a0)     # Lê o byte do buffer
        beqz t2, 2f     # Sai do loop se for 0
        sb t2, (t0)     # Guarda o byte no Serial Port

        li t2, 1        # Habilitando escrita no Serial Port
        sb t2, (t1)
        0:
            lb t2, (t1)     # Espera ocupada até escrita completa
            bnez t2, 0b     #

        addi a0, a0, 1      # Próxima posição de memória do buffer
        j 1b
    2:

    j isr_end

    # syscall_get_systime - Code 20
    # Retorno:
    #   a0 - tempo de execução do programa
    syscall_get_systime:
    li t0, GPT_TRIG
    li t1, 1
    sb t1, (t0)

    0:
        lb t1, (t0)
        bnez t1, 0b

    li t0, GPT_TIME
    lw a0, (t0)

    j isr_end

    isr_end:
    # Recuperando o contexto
    lw t6, 24(sp)
    lw t5, 20(sp)
    lw t4, 16(sp)
    lw t3, 12(sp)
    lw t2, 8(sp)
    lw t1, 4(sp)
    lw t0, 0(sp)

    addi sp, sp, 64
    csrrw sp, mscratch, sp

    # Retornando à execução
    csrr a6, mepc
    addi a6, a6, 4
    csrw mepc, a6
    mret


.globl _start
_start:
    # Inicializar a pilha do programa
    # Já feito.

    # 1 - Registrar a ISR
    la t0, int_handler
    csrw mtvec, t0 

    # 2 - Configurar o mscratch para apontar para a pilha da ISR
    la t0, isr_stack_end
    csrw mscratch, t0
    li sp, 0x07FFFFFC   # Configurando a pilha de usuário

    # 3 - Habilitar as interrupções externas
    li t0, 0x800
    csrs mie, t0

    # 4 - Habilita interrupções globais
    li t0, 0x8
    csrs mstatus, t0

    # Mudando para modo de usuário
    csrr t1, mstatus
    li t2, ~0x1800
    and t1, t1, t2
    csrw mstatus, t1

    # Chamando a função main
    la t0, main
    csrw mepc, t0

    mret
