#include <stdio.h>
#include <stdint.h>
extern uint32_t nc_init_and_emit(unsigned char *out);
int main(void) {
    unsigned char out[32];
    nc_init_and_emit(out);
    printf("init H: ");
    for (int i = 0; i < 32; i++) printf("%02x", out[i]);
    printf("\n");
    printf("expect: 6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19\n");
    return 0;
}
