/* _create_probe2.c -- separate "deref-sizeof in general" from "deref-sizeof of the self-declared pointer".
 * Probe #2 pinned create's 1405 calloc(1,sizeof(*st)) -> NULL while sizeof(TYPE) was sane. This isolates
 * whether ANY sizeof(*ptr) diverges, or only the same-statement `T *st = calloc(1,sizeof(*st))` form. */
#include "lex.c"

int main(void)
{
    iii_lex_state_t *p;                                  /* unevaluated in sizeof; need not be valid */
    unsigned long ds = (unsigned long)sizeof(*p);        /* deref-sizeof, SEPARATE declaration */
    unsigned long ts = (unsigned long)sizeof(iii_lex_state_t);   /* type-sizeof (probe #2: sane) */

    if (ds == 0ul)       return 20;        /* deref-sizeof -> 0 */
    if (ds != ts)        return 23;        /* deref-sizeof (separate decl) != type-sizeof -> general bug */
    if (ds > 100000ul)   return 21;        /* deref-sizeof absurd */

    /* separate-decl deref-sizeof is SANE and == type. Now the SAME-STATEMENT form the seed uses: */
    iii_lex_state_t *st = (iii_lex_state_t *)calloc(1, sizeof(*st));
    if (!st) return 12;                    /* self-declared deref-sizeof OR calloc/null-check fails */
    return 99;
}
