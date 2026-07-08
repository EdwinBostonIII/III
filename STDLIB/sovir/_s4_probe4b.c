/* probe4b.c -- the EXACT ast.c:1227 shape: append via a helper taking the struct POINTER as a
 * PARAMETER (iii_ast_list_append(iii_ast_t *ast, ..., uint32_t node_index) does
 * `ast->list_arena[ast->list_used++] = node_index;`).
 * gcc oracle 99.  48 = byte-scaled store signature (the S4 arena read).  20 = used++ lost.
 * 21/22 = value landed elsewhere.  7 = other garbage. */
typedef struct { unsigned int *arena; unsigned int used; unsigned int cap; } A;
static unsigned int BUF[8];
static A g;

static void app(A *ast, unsigned int node_index) {
    ast->arena[ast->used++] = node_index;
}

int main(void) {
    unsigned int r;
    g.arena = BUF; g.used = 1; g.cap = 8;
    app(&g, 0x30000004u);
    if (g.used != 2) return 20;
    r = g.arena[1];
    if (r == 0x30000004u) return 99;
    if (r == 48u) return 48;
    if (r == 0u) { if (BUF[0] != 0u) return 21; return 22; }
    return 7;
}
