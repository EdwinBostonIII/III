/* probe11.c -- POINTER-ARRAY struct field indexed store/read falsifier (the pe_static_fp killer):
 *   `const char *fp[N]` is an INLINE array whose ELEMENTS are pointers; SFPSZ>0 (char pointee)
 *   made the p->field[i] store/read arms take the SCALAR-POINTER deref path: LOAD64 the field,
 *   +i*1, store 1 byte -> cg->pe_static_fp[i]=NULL wrote byte 0 AT ADDRESS i (i=0..127), wiping
 *   the module's low const data (incl. iii_mhash_file's "rb" mode literal -> fopen NULL -> the
 *   silent EMIT_FAIL 16 with a byte-identical .o).  The fix: fieldisarr gates the deref arm.
 *   30 = neighbor field before the array clobbered   31 = neighbor after clobbered
 *   32 = element read-back wrong                     33 = zeroed element not zero
 *   34 = low memory clobbered (the address-i class)  99 = all green (gcc oracle) */
typedef struct { unsigned int pad; const char *fp[8]; unsigned int tail; } CGS;
static CGS G;
int main(void)
{
    unsigned int i;
    CGS *cg;
    const char *q;
    const char *MODE = "rb";   /* the seed's fopen(path,"rb") shape: an inline literal held in a pointer */
    if (MODE[0] != 'r') return 29;
    G.pad = 7u;
    G.tail = 9u;
    cg = &G;
    for (i = 0u; i < 8u; i++) { cg->fp[i] = 0; }
    if (G.pad != 7u) return 30;
    if (G.tail != 9u) return 31;
    cg->fp[3] = MODE;
    q = cg->fp[3];
    if (q[0] != 'r') return 32;
    if (q[1] != 'b') return 32;
    if (cg->fp[2] != 0) return 33;
    if (MODE[0] != 'r') return 34;
    return 99;
}
