#include <stdio.h>

void main() {
    int num;
    scanf("%d", &num);
    if ((num % 2) == 0)
        printf("É par essa porra!\n");
    else
        printf("É ímpar, se fudeu!\n");
}