#include <stdint.h>
#include <string.h>
struct Ctx { uint8_t buf[16]; uint32_t h[4]; int len; };
static struct Ctx ctx;
static uint8_t src[8];
int main() {
    for (int i = 0; i < 8; i++) { src[i] = i + 1; }     /* src = 1..8 */
    struct Ctx *c = &ctx;
    memcpy(c->buf, src, 8);                              /* decay c->buf -> addr ; memcpy */
    if (c->buf[0] != 1) { return 1; }
    if (c->buf[7] != 8) { return 2; }
    uint8_t *p = c->buf;                                 /* bare decay -> pointer */
    if (p[0] != 1) { return 3; }
    if (p[7] != 8) { return 4; }
    memcpy(c->buf + 4, src, 4);                          /* ceiling.c pattern: field + offset -> buf[4..8]=1,2,3,4 */
    if (c->buf[4] != 1) { return 5; }
    if (c->buf[7] != 4) { return 6; }                    /* overwritten */
    if (c->buf[3] != 4) { return 7; }                    /* untouched (src[3]=4) */
    return 99;
}
