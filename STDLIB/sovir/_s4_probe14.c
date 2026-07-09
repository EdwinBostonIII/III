/* probe14.c -- NAMED-CONST-dimensioned FIELD-ARRAY falsifier (the corpus-parity parse killer):
 *   struct fields `TypedefStruct f[NAMED_CONST]` and `TypedefEnum g[NAMED_CONST]` registered as
 *   ONE element (the dim resolves only for NUMERIC tokens in the struct-typed and enum-typedef
 *   field arms; the scalar-dtype arm has had the cidx fallback since link.c's
 *   sym[III_LINK_SYM_CAP]).  parse.c's bc_stack[III_PARSE_BREADCRUMB_CAP] (enum elems) and
 *   bc_detail[III_PARSE_BREADCRUMB_CAP] (iii_src_text_t elems) collapsed to 4/8 bytes, so
 *   iiip_bc_push at depth d overlaid witness_ctx/witness_sink/pratt_trace/reg tables --
 *   pratt_trace read {offset=44,len=4} ('main') -> CALL_INDIRECT 44 -> the corpus 12-class
 *   (spurious error nodes + false duplicate decls), plus the 124 hangs and 199 OOB traps.
 *   60/61 = sizeof collapsed   62..64 = element round-trip broken (writes overlaid)
 *   65..69 = neighbor fields clobbered by the overlay   99 = all green (gcc oracle) */
#define CAP8 8
typedef struct { unsigned int a; unsigned int b; } pair_t;
typedef enum { P0 = 0, P1 = 1 } prod_t;
enum { ECAP = 6 };
typedef struct {
    unsigned int head;
    prod_t stack[CAP8];
    unsigned int depth;
    pair_t detail[ECAP];
    unsigned int guard1;
    void *sink;
    unsigned int guard2;
} st_t;
static st_t S;
int main(void)
{
    st_t *s = &S;
    unsigned int i = 0;
    s->guard1 = 111; s->guard2 = 222; s->sink = 0;
    while (i < 8) { s->stack[i] = (prod_t)(i + 1); i = i + 1; }
    i = 0;
    while (i < 6) { s->detail[i].a = 1000 + i; s->detail[i].b = 2000 + i; i = i + 1; }
    if (sizeof(s->stack) != 8u * sizeof(s->stack[0])) return 60;
    if (sizeof(s->detail) != 6u * sizeof(s->detail[0])) return 61;
    if (s->stack[7] != 8) return 62;
    if (s->detail[5].a != 1005) return 63;
    if (s->detail[5].b != 2005) return 64;
    if (s->guard1 != 111) return 65;
    if (s->sink != 0) return 66;
    if (s->guard2 != 222) return 67;
    if (s->head != 0) return 68;
    if (s->depth != 0) return 69;
    return 99;
}
