.globl _start

.set write_trig, 0xFFFF0100
.set write_byte, 0xFFFF0101
.set read_trig, 0xFFFF0102
.set read_byte, 0xFFFF0103


exit:
    li a0, 0
    li a7, 93
    ecall
    

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

# read_op: lê a operação desejada para ida à rotina correta.
# Retorna:
#   a0 - inteiro correspondente à operação desejada (1, 2, 3 ou 4)
read_op:
    li t0, 1            # Habilitando a leitura do Serial Port
    li t1, read_trig    #
    sb t0, (t1)         #

    0:                  # Busy waiting - verificação se a leitura já foi
    lb t0, (t1)         # completada
    bnez t0, 0b         #

    li t1, read_byte    # Lendo o byte do Serial Port
    lb a0, (t1)         # a0 <- t1

    li t0, 1            # Habilitando a leitura do Serial Port
    li t1, read_trig    # (para pular o '/n')
    sb t0, (t1)         #

    0:                      # Busy waiting - verificação se a leitura já foi
        lb t0, (t1)         # completada
        bnez t0, 0b         #

    li t1, read_byte    # Lê o '/n'
    lb t0, (t1)         #

    addi a0, a0, -48    # ASCII para inteiro

    ret


# op_1: operação 1 - escrever string no Serial Port
op_1:
    li t2, '\n'

    0:
        li t0, 1            # Habilitando a leitura do Serial Port
        li t1, read_trig    #
        sb t0, (t1)         #

        1:                  # Busy waiting - verificação se a leitura já foi
            lb t0, (t1)     # completada
            bnez t0, 1b     #

        li t1, read_byte    
        lb a0, (t1)         # a0 <- byte a ser escrito na saída

        li t1, write_byte   # Escrevendo o byte na saída
        sb a0, (t1)

        li t0, 1            # Habilitando a escrita no Serial Port
        li t1, write_trig   #
        sb t0, (t1)         #

        1:                  # Busy waiting - verificação se a escrita já foi
            lb t0, (t1)     # completada
            bnez t0, 1b     #

    bne a0, t2, 0b          # Retorna se o byte não for '/n'

    ret


# op_2: operação 2 - inverter string e escrevê-la no Serial Port
op_2:
    li t2, '\n'
    li t3, 0

    0:
        li t0, 1            # Habilitando a leitura do Serial Port
        li t1, read_trig    #
        sb t0, (t1)         #

        1:                  # Busy waiting - verificação se a leitura já foi
            lb t0, (t1)     # completada
            bnez t0, 1b     #

        li t1, read_byte
        lb a0, (t1)         # a0 <- byte a ser escrito na saída

        beq a0, t2, 1f      # Sai do loop se o byte for '/n'

        addi sp, sp, -1     # Alocando espaço para 1 byte na pilha
        sb a0, (sp)         # Empilhando o byte
        addi t3, t3, 1      # t3++ (contador de bytes)

    j 0b

    1:
        lb a0, (sp)         # Desempilhando o byte
        addi sp, sp, 1      #

        li t1, write_byte   # Escrevendo o byte na saída
        sb a0, (t1)

        li t0, 1            # Habilitando a escrita no Serial Port
        li t1, write_trig   #  
        sb t0, (t1)         #

        2:                  # Busy waiting - verificação se a escrita já foi
            lb t0, (t1)     # completada
            bnez t0, 2b

        addi t3, t3, -1     # t3-- (contador de bytes)

    bnez t3, 1b             # Se o contador de bytes não for 0, volta à label '1' anterior

    li t1, write_byte       # Imprimindo o '/n'
    sb t2, (t1)             #

    li t0, 1            # Habilitando a escrita no Serial Port
    li t1, write_trig   # 
    sb t0, (t1)         #

    0:                  # Busy waiting - verificação se a escrita já foi
        lb t0, (t1)     # completada
        bnez t0, 0b     #
        
    ret


# op_3: operação 3 - conversão de decimal para hexadecimal
op_3:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)

    li t2, '\n'         # Condição de parada: newline

    la t3, input_buffer  # t3 <- endereço de input_buffer
    mv t4, t3            # t4 <- t3

    # Lendo da entrada do Serial Port e salvando o conteúdo em input_buffer
    0:
        li t0, 1            
        li t1, read_trig
        sb t0, (t1)

        1:
            lb t0, (t1)
            bnez t0, 1b

        li t1, read_byte
        lb a0, (t1)

        beq a0, t2, 1f  # Sai do loop se a0 == '/n'
        
        sb a0, (t4)
        addi t4, t4, 1

    j 0b
    1:

    li t0, 0
    sb t0, (t4)

    mv a0, t3
    jal atoi        # Conversão ASCII para inteiro
    
    la a1, output_buffer
    li a2, 16
    jal itoa        # Conversão inteiro para ASCII na base 16

    jal print_buffer    # Imprimindo o buffer

    lw ra, (sp)         # Recuperando conteúdo de RA
    addi sp, sp, 4
    ret


# op_4: operação 4 - efetuar operação algébrica
op_4:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)

    ### Parte 1 - Lendo o primeiro operando ###
    li t2, 32           # Condição de parada: ASCII 32 - Space

    la t3, input_buffer
    mv t4, t3

    # Lendo da entrada do Serial Port e salvando conteúdo em input_buffer
    0:
        li t0, 1
        li t1, read_trig
        sb t0, (t1)

        1:
            lb t0, (t1)
            bnez t0, 1b

        li t1, read_byte
        lb a0, (t1)

        beq a0, t2, 1f
        
        sb a0, (t4)
        addi t4, t4, 1

    j 0b
    1:

    li t0, 0        # Salvando 0 (NULL) no final do buffer
    sb t0, (t4)

    mv a0, t3
    jal atoi    # Conversão ASCII para inteiro
    mv s0, a0   # Primeiro operando em s0.

    ### Parte 2 - Lendo a operação ###
    li t0, 1            # Habilitando a leitura do Serial Port
    li t1, read_trig    #
    sb t0, (t1)         #

    0:                      # Busy waiting - verificação se a leitura já foi
        lb t0, (t1)         # completada
        bnez t0, 0b         #

    li t1, read_byte    # Lendo o byte do Serial Port
    lb a0, (t1)         # a0 <- t1
    
    mv s2, a0   # Operação salva em s2
    
    li t0, 1            # Habilitando a leitura do Serial Port
    li t1, read_trig    # (para pular o espaço)
    sb t0, (t1)         #

    
    0:                      # Busy waiting - verificação se a leitura já foi
        lb t0, (t1)         # completada
        bnez t0, 0b         #

    ### Parte 3 - Lendo o segundo operando ###
    li t2, '\n'             # Condição de parada: newline

    la t3, input_buffer
    mv t4, t3

    # Lendo da entrada do Serial Port e salvando conteúdo em input_buffer
    0:
        li t0, 1
        li t1, read_trig
        sb t0, (t1)

        1:
            lb t0, (t1)
            bnez t0, 1b

        li t1, read_byte
        lb a0, (t1)

        beq a0, t2, 1f
        
        sb a0, (t4)
        addi t4, t4, 1

    j 0b
    1:

    li t0, 0        # Salvando 0 (NULL) no final do buffer
    sb t0, (t4)

    mv a0, t3
    jal atoi    # Conversão ASCII para inteiro
    mv s1, a0

    # Segundo operando em s1

    ### Parte 4 - Identificando e realizando a operação ###
    mv a0, s0   # a0 <- s0 (primeiro operando)
    mv a1, s1   # a1 <- s1 (segundo operando)
    mv a2, s2   # a2 <- s2 (símbolo da operação)
    
    li t0, '+'
    bne a2, t0, 0f
    add a0, a0, a1
    j 3f

    0:
    li t0, '-'
    bne a2, t0, 1f
    sub a0, a0, a1
    j 3f

    1:
    li t0, '*'
    bne a2, t0, 2f
    mul a0, a0, a1
    j 3f 

    2:
    li t0, '/'
    bne a2, t0, 3f
    div a0, a0, a1

    3:

    # Resultado está em a0
    la a1, output_buffer    # Saída será salva em output_buffer
    li a2, 10
    jal itoa                # Conversão de inteiro para ASCII na base 10

    jal print_buffer        # Imprimindo o resultado

    lw ra, (sp)
    addi sp, sp, 4

    ret


# print_buffer: imprime um buffer terminado em caracter newline na
# Serial Port.
# Parâmetros:
#   a0 - endereço do buffer
print_buffer:
    mv t1, a0

    0:
        lb t0, (t1)
        beqz t0, 1f
        addi t1, t1, 1
        j 0b
    1:

    li t0, '\n'
    sb t0, (t1)

    li t2, '\n'
    # Buffer em a0
    0:
        lb t0, (a0)
        li t1, write_byte
        sb t0, (t1)

        li t0, 1
        li t1, write_trig
        sb t0, (t1)

        1:
            lb t0, (t1)
            bnez t0, 1b

        addi a0, a0, 1
        bne t0, t2, 0b

    ret


# op_list: guarda o endereço das rotinas que realizam as
# operações. 
op_list:
    .word op_1     # Operação 1 (escrever string no Serial Port)
    .word op_2     # Operação 2 (inverter string e escrevê-la no Serial Port)
    .word op_3     # Operação 3 (conversão decimal -> hexadecimal)
    .word op_4     # Operação 4 (efetuar operação algébrica)


main:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)     

    jal read_op

    addi a0, a0, -1     # Encontrando o endereço da rotina desejada
    slli a0, a0, 2      
    la a1, op_list      # O endereço está em op_list
    add a1, a1, a0
    lw a0, (a1)         # a0 <- endereço da operação
    jalr a0             # Realizando a operação

    lw ra, (sp)         # Recuperando conteúdo de RA
    addi sp, sp, 4
    ret


_start:
    jal main
    jal exit

.bss
input_buffer: .skip 1000
output_aux: .skip 200
output_buffer: .skip 200