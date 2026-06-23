#include <stdint.h>
struct S { uint32_t h[8]; uint8_t buf[16]; };
static struct S g;
static int dst[8];
static void fill(const int src[8], int n) {        /* array param (int -> stride 8) */
    for (int i = 0; i < n; i++)                     /* braceless for body */
        dst[i] = src[i] * 2;
}
int main() {
    struct S *c = &g;
    for (int i = 0; i < 8; i++) c->h[i] = i;        /* braceless body + field-array store */
    uint32_t h = c->h[5];                           /* local 'h' vs struct field 'h' (no spurious-array collision) */
    if (h != 5) { return 1; }
    uint8_t buf = c->buf[2];                         /* local 'buf' vs field 'buf' */
    if (buf != 0) { return 2; }
    int s[8];
    for (int i = 0; i < 8; i++) s[i] = i + 1;
    fill(s, 8);                                      /* array-param call */
    if (dst[3] != 8) { return 3; }                   /* (3+1)*2 */
    if (dst[7] != 16) { return 4; }
    return 99;
}
