/* test_callfield.c -- behavioral gate for call()->field: a function returning StructType* then ->field
 * (the parser idiom iiip_peek2(st)->kind), incl chained call()->a->b.  Runtime-fills the globals so this
 * isolates call()->field from global-struct-INITIALIZERS (a separate, still-unsupported ccsv feature). */
typedef struct { int kind; int val; } tok_t;
typedef struct { tok_t *cur; int n; } stream_t;

static tok_t g_tok;
static stream_t g_st;

static tok_t *peek(void) { return &g_tok; }
static stream_t *strm(void) { return &g_st; }

int main(void) {
    g_tok.kind = 7; g_tok.val = 42;
    g_st.cur = &g_tok; g_st.n = 3;
    if (peek()->kind != 7) return 1;
    if (peek()->val != 42) return 2;
    if (strm()->n != 3) return 3;
    if (strm()->cur->kind != 7) return 4;   /* chained call()->a->b */
    if (strm()->cur->val != 42) return 5;
    return 99;
}
