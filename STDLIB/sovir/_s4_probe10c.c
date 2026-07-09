/* probe10c.c -- the <=8B struct-return chain falsifier (iiip_text_of -> fn_decl.name),
 *   independent of the big-token links so both defects localize in parallel:
 *     txt s; s.offset=..; s.length=..; return s;      (<=8B struct RETURN, no sret)
 *     g_name = text_of(..);                            (global <=8B struct dest)
 *     loc = text_of(..);                               (local <=8B struct-value assign)
 *     nn->u.fn.name2 = text_of(..);                    (the fn_decl.name arrow-chain dest)
 *   40/41 = global dest offset/length wrong    42/43 = local dest offset/length wrong
 *   44/45 = arrow-chain dest offset/length wrong      99 = all green (gcc oracle) */
typedef struct { unsigned int offset; unsigned int length; } txt;
typedef struct { txt name2; unsigned int extra; } pay;
typedef struct { int kind; union { pay fn; unsigned int other; } u; } nd;
static txt g_name;
static nd NODE;

static txt text_of(unsigned int a, unsigned int b)
{
    txt s;
    s.offset = a;
    s.length = b - a;
    return s;
}

int main(void)
{
    nd *nn;
    txt loc;
    g_name = text_of(13u, 17u);
    if (g_name.offset != 13u) return 40;
    if (g_name.length != 4u) return 41;
    loc = text_of(13u, 17u);
    if (loc.offset != 13u) return 42;
    if (loc.length != 4u) return 43;
    nn = &NODE;
    nn->u.fn.name2 = text_of(13u, 17u);
    if (nn->u.fn.name2.offset != 13u) return 44;
    if (nn->u.fn.name2.length != 4u) return 45;
    return 99;
}
