#include <stdio.h>
#include <stdint.h>

extern uint32_t sha256_oneshot(unsigned char *input, uint64_t len, unsigned char *out);

int main(void) {
    unsigned char input[3] = {'a','b','c'};
    unsigned char out[32];
    sha256_oneshot(input, 3, out);
    for (int i = 0; i < 32; i++) printf("%02x", out[i]);
    printf("\n");
    /* Expected: ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad */
    return 0;
}
