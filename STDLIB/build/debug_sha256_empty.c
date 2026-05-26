#include <stdio.h>
#include <stdint.h>

extern uint32_t sha256_init(void);
extern uint32_t sha256_update(unsigned char *input, uint64_t len, unsigned char *out);
extern uint32_t sha256_final(unsigned char *out);
extern uint32_t sha256_oneshot(unsigned char *input, uint64_t len, unsigned char *out);

int main(void) {
    unsigned char out[32];
    /* Empty input via init/final without any update */
    sha256_init();
    sha256_final(out);
    printf("empty: ");
    for (int i = 0; i < 32; i++) printf("%02x", out[i]);
    printf("\n");
    printf("expect: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\n");

    /* Empty input via oneshot with len=0 */
    unsigned char dummy = 0;
    sha256_oneshot(&dummy, 0, out);
    printf("oneshot0: ");
    for (int i = 0; i < 32; i++) printf("%02x", out[i]);
    printf("\n");

    /* "abc" via oneshot */
    unsigned char abc[3] = {'a','b','c'};
    sha256_oneshot(abc, 3, out);
    printf("abc: ");
    for (int i = 0; i < 32; i++) printf("%02x", out[i]);
    printf("\n");
    printf("expect: ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad\n");
    return 0;
}
