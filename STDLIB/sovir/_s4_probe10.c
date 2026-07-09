/* probe10.c -- the PARSE-side name-store chain falsifier (probes 9/9b were green: the READ
 *   side works; the seed's name must be lost on the WRITE side).  Mirrors parse.c's exact
 *   token->ast flow for `fn main(...)`:
 *     iiip_advance:  tok t = st->lookahead;   (BIG ~104B struct copy from arrow-field)
 *                    return t;                 (>8B struct return -> sret)
 *     iiip_expect:   tok t = iiip_advance(st); if (out) *out = t;   (store through out-ptr)
 *     iiip_text_of:  txt s; s.offset = t ? t->start_byte : 0; ... return s;  (8B struct return)
 *     fn_decl:       nn->u.fn_decl.name = iiip_text_of(&name);      (assign into arrow-field)
 *   90 = expect gate failed          91 = token.start_byte lost in the copy chain
 *   92 = token.end_byte lost         93 = text_of.offset wrong (global assign)
 *   94 = text_of.length wrong        95 = arrow-field assign .offset wrong
 *   96 = arrow-field assign .length wrong      99 = all green (gcc oracle) */
typedef struct { unsigned int offset; unsigned int length; } txt;
typedef struct {
    unsigned int       kind;
    unsigned int       start_byte;
    unsigned int       end_byte;
    unsigned int       line;
    unsigned int       col;
    unsigned int       logical_line;
    unsigned int       logical_col;
    char              *logical_path;
    unsigned long long int_value;
    unsigned int       int_suffix;
    unsigned char      mhash[32];
    unsigned int       string_len;
    unsigned char     *string_payload;
    unsigned int       interned_id;
    unsigned int       leading_doc;
} tok;
typedef struct { int dummy; tok lookahead; unsigned int lookahead_valid; } P;
typedef struct { txt name2; unsigned int extra; } pay;
typedef struct { int kind; union { pay fn; unsigned int other; } u; } nd;
static P ST;
static txt g_name;
static nd NODE;

static tok advance(P *st)
{
    tok t = st->lookahead;
    st->lookahead_valid = 0u;
    return t;
}

static int expect(P *st, unsigned int k, tok *out)
{
    if (st->lookahead.kind == k) {
        tok t = advance(st);
        if (out) *out = t;
        return 1;
    }
    return 0;
}

static txt text_of(tok *t)
{
    txt s;
    s.offset = t ? t->start_byte : 0u;
    s.length = t ? (t->end_byte - t->start_byte) : 0u;
    return s;
}

int main(void)
{
    tok name;
    nd *nn;
    ST.lookahead.kind = 5u;
    ST.lookahead.start_byte = 13u;
    ST.lookahead.end_byte = 17u;
    ST.lookahead_valid = 1u;
    if (!expect(&ST, 5u, &name)) return 90;
    if (name.start_byte != 13u) return 91;
    if (name.end_byte != 17u) return 92;
    g_name = text_of(&name);
    if (g_name.offset != 13u) return 93;
    if (g_name.length != 4u) return 94;
    nn = &NODE;
    nn->u.fn.name2 = text_of(&name);
    if (nn->u.fn.name2.offset != 13u) return 95;
    if (nn->u.fn.name2.length != 4u) return 96;
    return 99;
}
