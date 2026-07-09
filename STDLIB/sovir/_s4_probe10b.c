/* probe10b.c -- isolates WHICH link of the token-copy chain drops the bytes (probe10 = 91).
 *   A: tok t = st->lookahead;      (>8B local INIT from an arrow-field)
 *   B: tok t2 = advance(&ST);      (>8B sret RETURN into a local)
 *   C: *out = t3;                  (>8B store THROUGH an out-pointer)
 *   50/51 = link A start/end lost   52/53 = link B start/end lost
 *   54/55 = link C start/end lost   99 = all green (gcc oracle) */
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
static P ST;
static tok g_t;

static tok advance(P *st)
{
    tok t = st->lookahead;
    st->lookahead_valid = 0u;
    return t;
}

int main(void)
{
    P *st;
    tok t;
    tok t2;
    tok t3;
    tok *out;
    ST.lookahead.kind = 5u;
    ST.lookahead.start_byte = 13u;
    ST.lookahead.end_byte = 17u;
    st = &ST;
    t = st->lookahead;
    if (t.start_byte != 13u) return 50;
    if (t.end_byte != 17u) return 51;
    t2 = advance(&ST);
    if (t2.start_byte != 13u) return 52;
    if (t2.end_byte != 17u) return 53;
    t3.kind = 5u;
    t3.start_byte = 13u;
    t3.end_byte = 17u;
    out = &g_t;
    *out = t3;
    if (g_t.start_byte != 13u) return 54;
    if (g_t.end_byte != 17u) return 55;
    return 99;
}
