.text
.globl _start
.globl play_note
.globl _system_time

# Endereços do periférico General Purpose Timer
.set GPT_BASE, 0xFFFF0100
.set GPT_TRIG, GPT_BASE+0
.set GPT_TIME, GPT_BASE+4
.set GPT_EXTINT_TIME, GPT_BASE+8

# Endereços do periférico MIDI Synthetizer
.set MIDI_BASE, 0xFFFF0300
.set MIDI_CH, MIDI_BASE+0
.set MIDI_INST, MIDI_BASE+2
.set MIDI_NOTE, MIDI_BASE+4
.set MIDI_VEL, MIDI_BASE+5
.set MIDI_DUR, MIDI_BASE+6

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

# gpt_isr: trata a interrupção externa gerada pelo General Purpose Timer
gpt_isr:
    # Salvando o contexto
    csrrw sp, mscratch, sp
    addi sp, sp, -64
    
    sw t0, 0(sp)
    sw t1, 4(sp)
    # Tratando a interrupção
    
    li t0, 1            # Setando o GPT_TRIG
    li t1, GPT_TRIG     # 
    sb t0, (t1)         #
    0:                  # Espera ocupada até GPT_TRIG == 0
    lb t0, (t1)
    bnez t0, 0b

    li t1, GPT_TIME     # Lendo o valor de GPT_TIME
    lw t0, (t1)         # t0 <- GPT_TIME

    la t1, _system_time # Copiando o valor de GPT_TIME para _system_time
    sw t0, (t1)         # system_time <- t0

    li t0, 100               # Guardando 100 no GPT_EXTINT_TIME novamente
    li t1, GPT_EXTINT_TIME   #
    sw t0, (t1)              # GPT_EXTINT_TIME <- 100
    
    # Recuperando o contexto
    lw t1, 4(sp)
    lw t0, 0(sp)
    addi sp, sp, 64
    csrrw sp, mscratch, sp
    mret

# play_note: toca uma nota no dispositivo MIDI externo, usando MMIO.
# Parâmetros:
#   a0 - canal 
#   a1 - identificação do instrumento
#   a2 - nota musical
#   a3 - velocidade da nota
#   a4 - duração da nota
play_note:
    addi sp, sp, -4     # Guardando RA
    sw ra, (sp)

    li t0, MIDI_CH      # Setando o canal
    sb a0, (t0)         # MIDI_CH <- a0

    li t0, MIDI_INST    # Setando o instrumento
    sb a1, (t0)         # MIDI_INST <- a1

    li t0, MIDI_NOTE    # Setando a nota musical
    sb a2, (t0)         # MIDI_NOTE <- a2

    li t0, MIDI_VEL     # Setando a velocidade da nota
    sb a3, (t0)         # MIDI_VEL <- a3

    li t0, MIDI_DUR     # Setando a duração da nota
    sb a4, (t0)         # MIDI_DUR <- a4

    lw ra, (sp)         # Recuperando RA
    addi sp, sp, 4

    ret

_start:
    # Inicializar a pilha do programa
    # Já feito.

    # Configurando as interrupções
    # 1 - Registrar a ISR
    la t0, gpt_isr
    csrw mtvec, t0

    # 2 - Configurar o mscratch para apontar para a pilha da ISR
    la t0, isr_stack_end
    csrw mscratch, t0
    la sp, user_stack_end

    # 3 - Configurar os periféricos
    li t0, 0
    li t1, GPT_TRIG
    sb t0, (t1)

    li t1, GPT_TIME
    sw t0, (t1)

    li t0, 100
    li t1, GPT_EXTINT_TIME
    sw t0, (t1)

    # 4 - Habilitar as interrupções externas
    li t0, 0x800
    csrs mie, t0

    # 5 - Habilitar as interrupções globais
    li t0, 0x8
    csrs mstatus, t0

    jal main


.data
_system_time: .word 0   # Inicializa _system_time com 0.
