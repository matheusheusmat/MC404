.globl read
.globl write
.globl puts         # OK
.globl gets         # OK (aparentemente)
.globl atoi         # OK (aparentemente)
.globl itoa         # TODO
.globl linked_list_search   # OK
.globl exit                 # OK             


# Referências
# s0 <- start_ após main

read:
    # a1: endereço
    # a2: numero de bytes
    mv a1, t0
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


# Puts: Adiciona o caracter newline no fim do buffer (substituindo NULL)
# e imprime seus caracteres na saída-padrão (stdout)
# Parâmetros:
# a0 - buffer a ser imprimido
puts:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)

    mv t0, a0           # t0 <- Endereço do primeiro caracter
    li t1, 0            # Quantidade de caracteres
    lb t2, (t0)         # Primeiro caracter 

    li t3, 0            # NULL character para comparação

    beq t2, t3, 1f      # Se o primeiro caracter for NULL, não entra no loop
    0:
        addi t1, t1, 1  # Mais um caracter encontrado
        addi t0, t0, 1  # Próximo endereço
        lb t2, (t0)     # Carrega próximo caracter
        bne t2, t3, 0b  # Se não for null, volta para '0'
    1:

    # Colocando '/n' no final
    li t2, '\n'
    sb t2, (t0)
    addi t1, t1, 1

    # Imprimindo
    mv a1, a0
    mv a2, t1
    jal write

    lw ra, (sp)         # Recuperando conteúdo de RA
    addi sp, sp, 4      
    
    ret


# gets: Lê a entrada-padrão (stdin) até o newline, a armazena em 
# um buffer e adiciona o caracter NULL em seu final.
# Parâmetros:
#   a0 - buffer que armazena a entrada
# Retorno:
#   a0 - buffer com a entrada
gets:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)

    mv t0, a0       # t0 <- a0 (endereço do buffer a ser preenchido)
    mv s11, a0      
    li t1, '\n'     # t1 <- '/n' para comparação
    li a2, 1        # Número de bytes a serem lidos

    0:
        jal read            # Lê o stdin
        lbu t2, (t0)        # Carrega o caracter que acabou de ser lido no t2
        addi t0, t0, 1      # t0++
        bne t2, t1, 0b      # Volta à label '0' anterior se t2 != '/n'

    li t1, 0  
    sb t1, -1(t0)           # Coloca NULL no final da string

    mv a0, s11

    lw ra, (sp)       # Recuperando conteúdo de RA
    addi sp, sp, 4
    ret


# atoi: converte de char para inteiro
# Parâmetros:
#   a0 - endereço da string
# Retorno:
#   a0 - valor inteiro
atoi:
    addi sp, sp, -4     # Salvando conteúdo de RA
    sw ra, (sp)
    
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
    lw ra, (sp)         # Recuperando conteúdo de RA 
    addi sp, sp, 4
    ret

# linked_list_search: encontra o nó de uma lista ligada que contenha o valor desejado.
# Parâmetros:
#   a0 - head_node, o primeiro nó (nó 0)
#   a1 - o valor desejado
# Retorna:
#   a0 - o nó em que o valor for encontrado, começando no 0.
#   -1 caso o valor não for encontrado na lista ligada.
linked_list_search:
    li t0, 0           # índice do nó

    0:
    lw t1, (a0)        # t1 <- VAL1
    lw t2, 4(a0)       # t2 <- VAL2
    add t3, t1, t2     # t3 <- t1 + t2

    beq t3, a1, found  # Se for igual ao valor desejado, encontrado.

    # Se não...
    addi t0, t0, 1     # indice++
    lw a0, 8(a0)       # a1 <- end. prox nó
    bnez a0, 0b        # Continua a iteração se o ponteiro para o prox não for NULL.
    1:

    # Se chegou aqui, não encontrou.
    li a0, -1
    ret

    found:
    # Se chegou aqui, encontrou.
    mv a0, t0
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
    aqui:
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
        divu a0, a0, t1     # a0 <- a0 / 16
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

# exit: realiza a chamada de sistema para parar o código.
# Parâmetros:
#   a0 - código de saída
exit:
    li a7, 93
    ecall

.bss
output_aux: .skip 200