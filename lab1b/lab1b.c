#define STDIN_FD 0    // Entrada padrão de dados
#define STDOUT_FD 1   // Saída padrão de dados
#define STDERR_FD 2   // Saída de erro

/* Buffer para leitura de dados */
char input_buffer[5];

/* Buffer para saída de dados */
char output_buffer[2];


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

/* getValue
  * Parâmetros:
  *  input: caracter a ser 'convertido'.
  * Retorno:
  *  Inteiro representado pelo caracter "input", na faixa de 0 a 9.
  */
int get_value(char input) {
  return input - 48;
}

/* calculate
  * Parâmetros:
  *  (nenhum, mas utiliza o vetor global de char input_buffer
  *  para extrair os valores para operação.)
  * Retorno:
  *  (nenhum, mas escreve o resultado no vetor global de char
  *  output_buffer.)
*/
void calculate() {
  int value1 = get_value(input_buffer[0]);
  int value2 = get_value(input_buffer[4]);
  int result;

  switch (input_buffer[2]) {
    case ('+'):
      result = value1 + value2 + 48;
      break;
    case ('-'):
      result = value1 - value2 + 48;
      break;
    case ('*'):
      result = value1 * value2 + 48;
      break;
  }

  output_buffer[0] = result;
  output_buffer[1] = '\n';
}

/* main */
int main() {
  int n = read(STDIN_FD, (void*) input_buffer, 5);
  calculate();
  write(STDOUT_FD, (void*) output_buffer, 2);
  return 0;
}

/* _start */
void _start() {
  int ret_code = main();
  exit(ret_code);
}

