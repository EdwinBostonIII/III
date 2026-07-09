/* probe7.c -- C pointer-arithmetic falsifier battery (the EV_PSZ fix):
 *   50 = local ptr + int broken     51 = struct-FIELD ptr + int broken (the ast.c:1316 memcpy-dest class)
 *   52 = ptr - ptr broken           53 = int + ptr broken             99 = all green (gcc oracle) */
typedef struct { unsigned int f0; unsigned int *arena; unsigned int used; } A;
static unsigned int BUF[8];
static A g;

static unsigned int rd(A *ast, unsigned int i) {
    unsigned int *w = ast->arena + i;
    return w[0];
}

int main(void) {
    unsigned int *p;
    unsigned int *q;
    unsigned int r;
    unsigned int d;
    g.arena = BUF; g.used = 0;
    BUF[2] = 777;
    p = BUF;
    q = p + 2;
    r = q[0]; if (r != 777) return 50;
    r = rd(&g, 2); if (r != 777) return 51;
    d = (unsigned int)(q - p); if (d != 2) return 52;
    q = 2 + p;
    r = q[0]; if (r != 777) return 53;
    return 99;
}
