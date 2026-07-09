/* probe9b.c -- the FULL emit_function call-shape falsifier (probe9 was green; the seed still
 *   reads an EMPTY name).  Adds the shapes probe9 lacked:
 *     - SIX-arg call with 8-byte structs at positions 2 AND 3 (cg, did, name, params, body, is_cycle)
 *     - the receiving fn reads name.length as a LOOP BOUND (i < name.length)
 *     - the struct PARAM re-passed BY VALUE to a second fn (emit_raw_symbol/emit_decl_label shape)
 *     - call()[i] indexing (iii_ast_source_buf(cg->ast)[name.offset + i])
 *     - the node pointer obtained from a CALL (iii_ast_get shape)
 *   78 = get()->kind wrong           80 = name.length != 4 at callee (the observed seed symptom)
 *   81 = source-buf bytes wrong      82 = struct re-pass by value wrong
 *   83 = params (2nd struct arg) wrong  84 = later scalar arg wrong  85 = early scalar arg wrong
 *   99 = all green (gcc oracle) */
typedef struct { unsigned int offset; unsigned int length; } txt;
typedef struct { unsigned int off2; unsigned int cnt2; } lst;
typedef struct {
    txt          name;
    lst          params;
    unsigned int return_type;
    lst          modifiers;
    unsigned int body_block;
} fnpay;
typedef struct {
    int            kind;
    unsigned short flags;
    unsigned short reserved;
    union {
        fnpay        fn_decl;
        unsigned int other;
    } u;
} node;
typedef struct { int out; unsigned int cur; } CG;
static node POOL[4];
static char SRC[32];
static CG G;

static node *get(unsigned int idx) { return &POOL[idx]; }
static char *srcbuf(CG *cg) { return SRC; }

static unsigned int sub2(CG *cg, txt name)
{
    return name.offset * 100u + name.length;
}

static int emit_fn(CG *cg, unsigned int decl, txt name, lst params, unsigned int body, int is_cycle)
{
    unsigned int i;
    unsigned int acc = 0u;
    if (name.length != 4u) return 80;
    for (i = 0u; i < name.length; i++) {
        char b = srcbuf(cg)[name.offset + i];
        acc = acc + (unsigned int)b;
    }
    if (acc != 421u) return 81;
    if (sub2(cg, name) != 304u) return 82;
    if (params.cnt2 != 2u) return 83;
    if (body != 9u) return 84;
    if (decl != 1u) return 85;
    return 0;
}

int main(void)
{
    node *d;
    int r;
    SRC[3] = 'm'; SRC[4] = 'a'; SRC[5] = 'i'; SRC[6] = 'n';
    POOL[1].kind = 12;
    POOL[1].u.fn_decl.name.offset = 3u;
    POOL[1].u.fn_decl.name.length = 4u;
    POOL[1].u.fn_decl.params.off2 = 5u;
    POOL[1].u.fn_decl.params.cnt2 = 2u;
    POOL[1].u.fn_decl.body_block = 9u;
    d = get(1u);
    if (d->kind != 12) return 78;
    r = emit_fn(&G, 1u, d->u.fn_decl.name, d->u.fn_decl.params, d->u.fn_decl.body_block, 0);
    if (r != 0) return r;
    return 99;
}
