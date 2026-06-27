/* test_globalptr.c -- COMPLETE global scalar-pointer support for DIRECT dtypes (int/unsigned int/char/unsigned char):
 *   init `*p = &G` (data section holds G's address), deref-READ `*p` rvalue (the dropped bug -> single-LOAD64
 *   fallback read the pointer's address, not *p), deref-STORE `*p = e`, deref-COMPOUND `*p += e`, across the
 *   supported pointee widths (4, 1) and signedness. The read now loads gp's value then eload()s the pointee at
 *   the tracked APSZ/APSG width.
 * SCOPE NOTE: `short`/`long`/`long long` are not ccsv dtypes, and typedef'd global SCALARS are a separate
 *   pre-existing gap (the file-scope scalar handler gates on dtype(q)); both are out of scope here and unchanged. */
static int gv = 42;
static int *gp = &gv;
static unsigned int gu = 0x12345678;
static unsigned int *gup = &gu;
static char gc = 65;
static char *gcp = &gc;
static unsigned char gb = 200;
static unsigned char *gbp = &gb;
int main(void) {
    if (*gp != 42) return 1;             /* int* deref-READ : width 4 (was dropped) */
    *gp = 7;   if (gv != 7)  return 2;   /* deref-store   */
    *gp += 3;  if (gv != 10) return 3;   /* deref-compound */
    if (*gup != 0x12345678) return 4;    /* unsigned int* deref-read : width 4 */
    if (*gcp != 65) return 5;            /* char* deref-read : width 1 */
    if (*gbp != 200) return 6;           /* unsigned char* deref-read : width 1, zero-extend (200 > 127) */
    *gbp = 99; if (gb != 99) return 7;   /* deref-store through uchar* */
    return 99;
}
