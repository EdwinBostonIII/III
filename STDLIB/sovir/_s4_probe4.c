/* probe4.c -- the ast.c:1227 append shape, exact: ptr-FIELD indexed by FIELD with POST-INCREMENT
 * as a STORE target.  gcc oracle 99.  48 = the byte-scaled-store signature (value landed 3 bytes
 * low; correct read at element 1 sees top byte 0x30 only).  20 = post-inc broken; 21/22 = landed
 * elsewhere; 7 = other garbage. */
typedef struct { unsigned int *arena; unsigned int used; unsigned int cap; } A;
static unsigned int BUF[8];
static A g;
int main(void) {
    unsigned int r;
    g.arena = BUF; g.used = 1; g.cap = 8;
    g.arena[g.used++] = 0x30000004;
    if (g.used != 2) return 20;
    r = g.arena[1];
    if (r == 0x30000004u) return 99;
    if (r == 48u) return 48;
    if (r == 0u) { if (BUF[0] != 0u) return 21; return 22; }
    return 7;
}
