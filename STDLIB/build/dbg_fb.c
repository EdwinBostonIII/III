#include <stdio.h>
#include <stdint.h>
extern uint32_t fb_run_empty(unsigned char *out);
int main(void) {
    unsigned char out[32];
    fb_run_empty(out);
    printf("fb_empty: ");
    for (int i = 0; i < 32; i++) printf("%02x", out[i]);
    printf("\nexpected: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\n");
    return 0;
}
