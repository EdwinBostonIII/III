#include <stdio.h>
#include <stdint.h>
extern uint32_t sha256_oneshot_stub(unsigned char *in, uint64_t len, unsigned char *out);
int main(void) {
    unsigned char out[32];
    sha256_oneshot_stub((unsigned char*)"abc", 3, out);
    for (int i = 0; i < 32; i++) printf("%02x", out[i]);
    printf("\n");
    return 0;
}
