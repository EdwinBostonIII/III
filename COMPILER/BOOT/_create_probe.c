/* _create_probe.c -- faithful pin of iii_lex_create's NULL under ccsv->interp.
 * #includes the REAL lex.c (like _lexharness.c) so it uses the REAL iii_lex_state_t + the REAL static
 * iii_sha256_init/iii_intern_init, then replicates create's create-sequence with a distinct exit code per
 * failure point.  gcc == reference (expect 99); ccsv->SVIR->svir_interp == the code that pins the null path.
 * See DOCS/III-CCSV-LEX-NULL-AUDIT.md.  Exit codes < 256 (8-bit). */
#include "lex.c"

int main(void)
{
    /* A. sizeof of the FULL type vs the DEREF form (FIX #30/#31/#32 class) */
    unsigned long tsz = (unsigned long)sizeof(iii_lex_state_t);
    if (tsz == 0ul)      return 20;        /* sizeof(TYPE) -> 0 */
    if (tsz > 100000ul)  return 21;        /* sizeof(TYPE) -> absurd */

    iii_lex_state_t *st = (iii_lex_state_t *)calloc(1, sizeof(*st));  /* deref-sizeof at the real calloc */
    if (!st) return 12;                    /* == create's 1405 NULL (outer calloc) */

    unsigned long dsz = (unsigned long)sizeof(*st);
    if (dsz == 0ul)      return 22;        /* sizeof(*st) -> 0 (deref differs from type) */
    if (dsz != tsz)      return 23;        /* deref-sizeof != type-sizeof (the FIX #30 class) */

    iii_sha256_init(&st->stream_sha);
    int r = iii_intern_init(&st->intern);
    if (r != 0) return 13;                 /* == create's 1433 NULL (intern_init in context) */
    if (st->intern.slots == (iii_intern_slot_t *)0) return 14;
    if (st->intern.cap != 1024ul)          return 15;

    return 99;                             /* create-sequence fully correct */
}
