/* sizeof(v.field) on struct VALUES/globals (emit_link's `sizeof G_EMIT.witness_json`):
 * esizeof's identifier arm had arr[i]/bare cases but NO DOT case.  Arms: array field
 * (whole fieldbytes), scalar field, CHAINED embedded field, element [0], paren-free. */
typedef struct { long pad; char buf[100]; unsigned tail; } g_t;
static g_t G;
typedef struct { int a; char inner[7]; } em_t;
typedef struct { long x; em_t em; } h_t;
static h_t H;
int main(void) {
    unsigned long s1 = sizeof(G.buf);
    unsigned long s2 = sizeof G.buf;
    unsigned long s3 = sizeof(G.tail);
    unsigned long s4 = sizeof(H.em.inner);
    unsigned long s5 = sizeof(G.buf[0]);
    if (s1 != 100) { return 1; }
    if (s2 != 100) { return 1; }
    if (s3 != 4) { return 1; }
    if (s4 != 7) { return 1; }
    if (s5 != 1) { return 1; }
    return 99;
}
