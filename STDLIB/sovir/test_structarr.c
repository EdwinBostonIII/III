#include <stdint.h>
struct Ctx { uint32_t h[8]; uint8_t buf[16]; int len; };
static struct Ctx ctx;
static void fill(struct Ctx *c) {
    for (int i = 0; i < 8; i++) { c->h[i] = i * 100; }       /* ptr->arrfield[i] = e (cell) */
    for (int i = 0; i < 16; i++) { c->buf[i] = i + 1; }      /* ptr->arrfield[i] = e (byte) */
    c->len = 42;
}
int main() {
    fill(&ctx);
    if (ctx.h[0] != 0) { return 1; }
    if (ctx.h[7] != 700) { return 2; }                        /* v.arrfield[i] (cell) */
    if (ctx.buf[0] != 1) { return 3; }
    if (ctx.buf[15] != 16) { return 4; }                      /* v.arrfield[i] (byte) */
    if (ctx.len != 42) { return 5; }
    struct Ctx *p = &ctx;
    p->h[3] = 999;                                            /* ptr->arrfield[i] store */
    if (p->h[3] != 999) { return 6; }
    if (ctx.h[3] != 999) { return 7; }                        /* aliases same memory */
    int sum = 0;
    for (int i = 0; i < 16; i++) { sum = sum + p->buf[i]; }   /* 1+..+16 = 136 */
    if (sum != 136) { return 8; }
    return 99;
}
