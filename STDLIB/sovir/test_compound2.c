#include <stdint.h>
struct Ctx { uint32_t h[8]; int n; };
static struct Ctx ctx;
static int arr[8];
static uint8_t buf[8];
static void acc(struct Ctx *c) {
    for (int i = 0; i < 8; i++) { c->h[i] = i; }
    c->h[0] += 100;                                  /* struct ARRAY field compound (ptr) */
    c->h[7] += 7;
    c->n = 5;  c->n += 10;                           /* struct SCALAR field compound */
}
int main() {
    acc(&ctx);
    if (ctx.h[0] != 100) { return 1; }
    if (ctx.h[7] != 14) { return 2; }
    if (ctx.n != 15) { return 3; }
    for (int i = 0; i < 8; i++) { arr[i] = i; }
    arr[3] += 50;  if (arr[3] != 53) { return 4; }   /* array element compound */
    arr[5] *= 4;   if (arr[5] != 20) { return 5; }
    buf[0] = 0xF0;  buf[0] |= 0x0F;  if (buf[0] != 0xFF) { return 6; }   /* byte array compound */
    buf[1] = 0xFF;  buf[1] &= 0x0F;  if (buf[1] != 0x0F) { return 7; }
    ctx.h[3] += 1000;  if (ctx.h[3] != 1003) { return 8; }               /* direct struct array field compound */
    return 99;
}
