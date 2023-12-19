#define STDIN_FD 0    // Entrada padrão de dados
#define STDOUT_FD 1   // Saída padrão de dados
#define STDERR_FD 2   // Saída de erro

/* Buffer para leitura de dados */
char input_buffer[11];

/* Buffer para saída de dados */
char output_buffer[35];

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

int power(int base, int exp) {
    int result = 1;

    for (int i = 0; i < exp; i++) {
        result *= base;
    }

    return result;
}

int char_to_int(char input) {
  if (input >= 'a' && input <= 'f')
    return input - 'a' + 10; 
  else 
    return input - 48;
}

void output_reset() {
  for (int i = 0; i < 35; i++)
    output_buffer[i] = 0;
}

void all_zero_output() {
  for (int i = 0; i < 35; i++)
    output_buffer[i] = '0';
}

int array_copy(char *src_array, char *dest_array, int start) {
  int i, size = 0;

  for (i = start; src_array[i] != '\n'; i++) {
    dest_array[size] = src_array[i];
    size++;
  }
  dest_array[i] = '\n';
  return size;
}

void output_shift() {
  char aux_buffer[35];
  int i = 0;
  array_copy(output_buffer, aux_buffer, 0);
  output_reset();
  output_buffer[0] = '-';

  for (i = 0; aux_buffer[i] != '\n'; i++) {
    output_buffer[i + 1] = aux_buffer[i];
  }

  output_buffer[i + 2] = '\n';
}

void array_inverter(char *array, int places, int offset) {
  int curr_place = places - 1; 
  for (int i = 0; i < places + offset; i++) {
    output_buffer[i + offset] = array[curr_place];
    curr_place--;
  }
}

void bit_inverter() {
  for (int i = 2; i < 34; i++) {
    if (output_buffer[i] == '0')
      output_buffer[i] = '1';
    else 
      output_buffer[i] = '0';
  }
}



int get_type() {
  // 1 - Decimal
  // 2 - Hexadecimal
  if (input_buffer[1] == 'x')
    return 0;
  else
    return 1; 
}

int get_hex_signal() {
  if (input_buffer[2] >= '0' && input_buffer[2] <= '7')
    return 0;
  if (input_buffer[10] != '\n')
    return 0;
  return 1;
}


/*
Ordem:
1 - Número em binário, com "0b" no começo. Se for negativo, mostrar representação em complemento de 2.
2 - Número em decimal.
3 - Número em hexadecimal. Se for negativo, fazer representação em complemento de 2 (do binário) e converter esse número pra hex.
4 - Número em decimal, mas assumindo que o número em 32-bits foi feito em representação sem sinal e sua 'endianness' foi invertida.
*/


void two_compliment() {
  char aux_array[35];
  int j = 0;

  int aux_size = array_copy(output_buffer, aux_array, 2);
  all_zero_output();

  output_buffer[0] = '0';
  output_buffer[1] = 'b';
  for (int i = 34 - aux_size; i < 34; i++) {
    output_buffer[i] = aux_array[j];
    j++;
  }
  output_buffer[34] = '\n';
  bit_inverter();
}

unsigned int get_dec_value(int start) {
  char curr_char = input_buffer[start];
  int curr_int;
  int num_places = 0;
  unsigned int abs_value = 0;

  for (int i = start + 1; curr_char != '\n'; i++) {
    num_places++;
    curr_char = input_buffer[i];
  }

  int first_power = power(10, num_places - 1);
  int curr_power = first_power;

  for (int i = start; i < num_places + start; i++) {
    curr_int = char_to_int(input_buffer[i]);
    abs_value += curr_int * curr_power;
    curr_power /= 10;
  }
  return abs_value;
}

unsigned int get_hex_value() {
  char curr_char = input_buffer[2];
  int curr_int;
  int num_places = 0;
  unsigned int abs_value = 0;

  for (int i = 2 + 1; curr_char != '\n'; i++) {
    num_places++;
    curr_char = input_buffer[i];
  }

  int first_power = power(16, num_places - 1);
  int curr_power = first_power;

  for (int i = 2; i < num_places + 2; i++) {
    curr_int = char_to_int(input_buffer[i]);
    abs_value += curr_int * curr_power;
    curr_power /= 16;
  }
  return abs_value;
}

void value_to_dec(unsigned int value) {
  unsigned int places = 0, remainder, curr_value = value;
  char aux_array[32], curr_char;

  while (curr_value != 0) {
    remainder = curr_value % 10;
    curr_char = remainder + '0';
    aux_array[places] = curr_char;
    places++;
    curr_value /= 10;
  }

  array_inverter(aux_array, places, 0);
  output_buffer[places] = '\n';
}

void value_to_bin(unsigned int value) {
  char aux_array[32];
  int places = 0;
  int remainder = 0;

  output_buffer[0] = '0';
  output_buffer[1] = 'b';

  if (value == 0 || value == 1) {
    output_buffer[3] = value + '0';
    output_buffer[4] = '\n';
  }

  while(value != 0) {
    remainder = value % 2;
    aux_array[places] = remainder + '0';
    places++;
    value /= 2;
  }
  
  array_inverter(aux_array, places, 2);

  output_buffer[places + 2] = '\n';
}

void value_to_hex(unsigned int value) {
  char aux_array[32];
  int places = 0;
  int remainder = 0;

  output_buffer[0] = '0';
  output_buffer[1] = 'x';

  while (value != 0) {
    remainder = value % 16;

    if (remainder >= 10) {
      remainder -= 10;
      aux_array[places] = remainder + 'a';
    }
    else {
      aux_array[places] = remainder + '0';
    }
  places++;
  value /= 16;
  }

  array_inverter(aux_array, places, 2);
  output_buffer[places + 2] = '\n';
}

int bin_to_value() {
  int start = 2;
  char curr_char = output_buffer[start];
  int curr_int;
  int num_places = 0;
  int abs_value = 0;

  for (int i = start + 1; curr_char != '\n'; i++) {
    num_places++;
    curr_char = output_buffer[i];
  }

  int first_power = power(2, num_places - 1);
  int curr_power = first_power;

  for (int i = start; i < num_places + start; i++) {
    curr_int = char_to_int(output_buffer[i]);
    abs_value += curr_int * curr_power;
    curr_power /= 2;
  }
  return abs_value;
}

void bin_to_hex() {
  char aux_array[35];
  int i, j = 2, sum;
  array_copy(output_buffer, aux_array, 2);
  output_reset();

  output_buffer[0] = '0';
  output_buffer[1] = 'x';

  for (i = 0; i < 32; i += 4) {
    sum = 0;
    sum += char_to_int(aux_array[i]) * 8;
    sum += char_to_int(aux_array[i + 1]) * 4;
    sum += char_to_int(aux_array[i + 2]) * 2;
    sum += char_to_int(aux_array[i + 3]) * 1;

    if (sum >= 10) {
      output_buffer[j] = sum + 'a' - 10;
    }
    else {
      output_buffer[j] = '0' + sum;
    }
    j++;
  }
  output_buffer[j] = '\n';
}

void endian_swap() {
  int num_places = 0, j = 2;
  char aux_array[35];

  aux_array[0] = '0';
  aux_array[1] = 'x';
  for (int i = 2; i < 10; i++) {
    aux_array[i] = '0';
  } 
  aux_array[10] = '\n';
  // aux_array = '0x00000000\n'

  for (int i = 2; output_buffer[i] != '\n'; i++) {
    num_places++;
  }

  for (int i = 10 - num_places; output_buffer[j] != '\n'; i++) {
    aux_array[i] = output_buffer[j];
    j++;
  } 

  for (int i = 2; aux_array[i] != '\n'; i += 2) {
    output_buffer[10 - i] = aux_array[i];
    output_buffer[11 - i] = aux_array[i + 1];
  }

  output_buffer[10] = '\n';

  array_copy(output_buffer, input_buffer, 0);
  unsigned int value = get_hex_value();
  output_reset();
  value_to_dec(value);
}

int deal_with_dec() {
  unsigned int abs_value = 0;

  if (input_buffer[0] == '-') {
    abs_value = get_dec_value(1);
    value_to_bin(abs_value - 1);
    two_compliment();
    write(STDOUT_FD, (void*) output_buffer, 35);  // Binário
    write(STDOUT_FD, (void*) input_buffer, 11);   // Decimal
    bin_to_hex();
    write(STDOUT_FD, (void*) output_buffer, 35);  // Hexadecimal
    endian_swap();
    write(STDOUT_FD, (void*) output_buffer, 35);
  }

  else {
    abs_value += get_dec_value(0);
    value_to_bin(abs_value);
    write(STDOUT_FD, (void*) output_buffer, 35);    // Binário
    output_reset();
    write(STDOUT_FD, (void*) input_buffer, 11);     // Decimal
    value_to_hex(abs_value);
    write(STDOUT_FD, (void*) output_buffer, 35);    // Hexadecimal
    endian_swap();
    write(STDOUT_FD, (void*) output_buffer, 35);
  }

}

int deal_with_hex() {
  unsigned int abs_value;
  
  int is_negative = get_hex_signal();
  if (is_negative) {                                // O número é negativo
    abs_value = get_hex_value();
    value_to_bin(abs_value - 1);
    two_compliment();
    write(STDOUT_FD, (void*) output_buffer, 35);  // Binario
    output_reset();
    value_to_dec(abs_value);
    output_shift();
    write(STDOUT_FD, (void*) output_buffer, 35); // Decimal
    output_reset();
    write(STDOUT_FD, (void*) input_buffer, 11); // Hexadecimal
    array_copy(input_buffer, output_buffer, 0);
    endian_swap();
    write(STDOUT_FD, (void*) output_buffer, 35);
  }
  else {
    abs_value = get_hex_value();
    value_to_bin(abs_value);
    write(STDOUT_FD, (void*) output_buffer, 35); // Binário
    output_reset();
    value_to_dec(abs_value);
    write(STDOUT_FD, (void*) output_buffer, 35); // Decimal
    output_reset();
    write(STDOUT_FD, (void*) input_buffer, 11);  // Hexadecimal
    array_copy(input_buffer, output_buffer, 0);
    endian_swap();
    write(STDOUT_FD, (void*) output_buffer, 35);
  }
}


/* main */
int main() {
  int n = read(STDIN_FD, (void*) input_buffer, 20);
  int is_decimal = get_type();
  if (is_decimal)
    deal_with_dec();
  else
    deal_with_hex();

  return 0;
}

/* _start */
void _start() {
  int ret_code = main();
  exit(ret_code);
}

