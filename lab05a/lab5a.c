/* Máscaras */

// 0b00000000000000000000000000000111
int mask3lsb = 7;

// 0b00000000000000000000000000011111
int mask5lsb = 31;

// 0b00000000000000000000000011111111
int mask8lsb = 255;

// 0b00000000000000000000011111111111
int mask11lsb = 2047;

/* File descriptors */
#define STDIN_FD 0    // Entrada padrão de dados
#define STDOUT_FD 1   // Saída padrão de dados
#define STDERR_FD 2   // Saída de erro

/* exit
  * Parâmetros:
  * code: código de retorno fornecido pela função main()
*/
void exit(int code) {
  __asm__ __volatile__(
    "mv a0, %0           # return code\n"
    "li a7, 93           # syscall exit (64) \n"
    "ecall"
    :             // Output list
    :"r"(code)    // Input list
    : "a0", "a7"
  );
}

/* read
 * Parâmetros:
 *  __fd:  file descriptor do arquivo a ser lido.
 *  __buf: buffer para armazenar o dado lido.
 *  __n:   quantidade máxima de bytes a serem lidos.
 * Retorno:
 *  Número de bytes lidos.
 */
int read(int __fd, const void *__buf, int __n) {
    int ret_val;
  __asm__ __volatile__(
    "mv a0, %1           # file descriptor\n"
    "mv a1, %2           # buffer \n"
    "mv a2, %3           # size \n"
    "li a7, 63           # syscall read code (63) \n"
    "ecall               # invoke syscall \n"
    "mv %0, a0           # move return value to ret_val\n"
    : "=r"(ret_val)                   // Output list
    : "r"(__fd), "r"(__buf), "r"(__n) // Input list
    : "a0", "a1", "a2", "a7"
  );
  return ret_val;
}

/* write
 * Parâmetros:
 *  __fd:  files descriptor para escrita dos dados.
 *  __buf: buffer com dados a serem escritos.
 *  __n:   quantidade de bytes a serem escritos.
 * Retorno:
 *  Número de bytes efetivamente escritos.
 */
void write(int __fd, const void *__buf, int __n) {
  __asm__ __volatile__(
    "mv a0, %0           # file descriptor\n"
    "mv a1, %1           # buffer \n"
    "mv a2, %2           # size \n"
    "li a7, 64           # syscall write (64) \n"
    "ecall"
    :                                   // Output list
    :"r"(__fd), "r"(__buf), "r"(__n)    // Input list
    : "a0", "a1", "a2", "a7"
  );
}

/* power - potenciação iterativa
 * Parâmetros:
 *  int base:  a base da potência
 *  int exp:   o expoente da potência
 * Retorno:
 *  o resultado da operação de potenciação
*/
int power(int base, int exp) {
    int result = 1;

    for (int i = 0; i < exp; i++) {
        result *= base;
    }

    return result;
}

/* array_copy - copia "size" caracteres de um vetor a partir de "start" 
  para a partir da posição 0 de outro vetor. 
  * Parâmetros:
  *  char *src_array: vetor de origem
  *  char *dest_array: vetor de destino
  *  int start: posição de início de cópia do src_array;
  *  int size: quantidade de caracteres a serem copiados.
  */
void array_copy(char *src_array, char *dest_array, char start, int size) {
    int j = 0;
    for (int i = start; i < size + start; i++) {
        dest_array[j] = src_array[i];
        j++;
    }
}

/* char_to_int - caracter em valor 
  * Parâmetros:
  *   char input: o caracter a ser convertido (de '0' a '9', de 
  *   'a' = 10 a 'f' = 15, usados na base hexadecimal)
  * Retorno:
  *   o valor inteiro correspondente
*/
int char_to_int(char input) {
  if (input >= 'a' && input <= 'f')
    return input - 'a' + 10; 
  else 
    return input - 48;
}

/* get_value - converte um vetor de char que representa um número 
decimal em um valor inteiro.
  * Parâmetros:
  *  char *curr_decimal: o vetor a ser convertido. 
*/
int get_value(char *curr_decimal) {
    int abs_value = 0;
    int signal_factor = 1;
    if (curr_decimal[0] == '-') {
        signal_factor = -1; 
    }
    
    int curr_power = power(10, 3);
    int curr_int = 0;

  for (int i = 1; i < 5; i++) {
    curr_int = char_to_int(curr_decimal[i]);
    abs_value += curr_int * curr_power;
    curr_power /= 10;
  }

    return abs_value * signal_factor;
}

/* mask_value - retorna os bits menos significativos conforme a máscara. 
  * Parâmetros:
  *  int value: valor inteiro
  *  int mask: máscara que contém os bits desejados */
int mask_value(int value, int mask) {
    return (value & mask);
}

/* pack - realiza "empacotamento" do número após a máscara e é 
feito também o deslocamento para a esquerda, conforme apontado. 
  * Parâmetros:
  *  int masked_value: valor após a seleção dos bits menos 
    significativos desejados.
  *  int lshift: quantidade de casas para fazer o deslocamento
    binário para a esquerda.
  *  int packed_value: valor atual do "empacotamento".
  * Retorno:
  *  valor do empacotamento após a comparação "ou" bit a bit com
  * o valor shifted_value*/
int pack(int masked_value, int lshift, int packed_value) {
    int shifted_value = masked_value << lshift;
    packed_value = packed_value | shifted_value;
    return packed_value;
}

/* hex_code - dado um valor inteiro, o transforma em um vetor de 
char com sua respectiva representação em base hexadecimal.
  * Parâmetros:
  *  int val: valor inteiro a ser convertido */
void hex_code(int val) {
    char hex[11];
    unsigned int uval = (unsigned int) val, aux;
    
    hex[0] = '0';
    hex[1] = 'x';
    hex[10] = '\n';

    for (int i = 9; i > 1; i--){
        aux = uval % 16;
        if (aux >= 10)
            hex[i] = aux - 10 + 'A';
        else
            hex[i] = aux + '0';
        uval = uval / 16;
    }
    write(1, hex, 11);
}

/* main */
int main() {
    int i, packed_value = 0; /* i vai guardar as iterações. São 5, uma para cada valor. */

    char input_buffer[30];
    int n = read(STDIN_FD, (void*) input_buffer, 30);
    int masks[] = {mask3lsb, mask8lsb, mask5lsb, mask5lsb, mask11lsb};
    int lshifts[] = {0, 3, 11, 16, 21};

    char curr_decimal[6];
    for (int i = 0; i <= 24; i += 6) {
        array_copy(input_buffer, curr_decimal, i, 5);
        int value = get_value(curr_decimal);
        int masked_value = mask_value(value, masks[i / 6]);                      
        packed_value = pack(masked_value, lshifts[i / 6], packed_value);
    }
    hex_code(packed_value);
    return 0;
}

/* _start */
void _start() {
  int ret_code = main();
  exit(ret_code);
}