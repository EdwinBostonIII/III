/* probe9.c -- 8-byte struct BY-VALUE argument falsifier (the emit_function(name) killer):
 *   cg_r3 passes d->u.fn_decl.name (iii_src_text_t {u32 offset; u32 length}) BY VALUE into
 *   emit_function / emit_raw_symbol / emit_decl_label; the seed's .asciz reads back EMPTY
 *   ("" not "main") and is_main_fn sees length!=4 -> no .global main, label "L_".
 *   Mirrors the exact node shape: kind + 2 shorts, union payload, name-first struct.
 *   70 = local struct arg broken            71 = p->u.fn_decl.name struct arg broken
 *   72 = nested dot read via pointer wrong  73 = callee param field reads wrong
 *   74 = second field (length) lost         99 = all green (gcc oracle) */
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
static node N;
static unsigned int take(txt t)
{
    return t.offset * 100u + t.length;
}
int main(void)
{
    txt x;
    node *p;
    unsigned int r;
    x.offset = 3u; x.length = 4u;
    r = take(x);
    if (r != 304u) return 70;
    N.kind = 12;
    N.u.fn_decl.name.offset = 7u;
    N.u.fn_decl.name.length = 4u;
    N.u.fn_decl.body_block = 9u;
    p = &N;
    r = take(p->u.fn_decl.name);
    if (r != 704u) return 71;
    if (p->u.fn_decl.name.offset != 7u) return 72;
    if (p->u.fn_decl.name.length != 4u) return 74;
    r = take(N.u.fn_decl.name);
    if (r != 704u) return 73;
    return 99;
}
