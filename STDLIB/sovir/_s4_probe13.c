/* probe13.c -- BARE-GLOBAL-STRUCT-BY-VALUE falsifier (the corpus-parity sema killer):
 *   a bare GLOBAL struct VARIABLE passed as a BY-VALUE argument compiled to its
 *   ADDRESS (the array-decay arm), not its packed 8-byte value -- the callee's
 *   field reads then decoded an address (length = addr>>32 = 0), so every
 *   sema/parse txt-keyed lookup that passes a global txt_t by value failed:
 *   30 of the 54 corpus-parity reds (rc=12 SEMA_FAIL on 24_var_global etc.).
 *   Fixed in eprim's global tail: a reg_var'd struct VAR (avtype>=0, ALEN==0,
 *   STSZ in {1,2,4,8}) LOADS its packed bytes; struct ARRAYS (ALEN>=1) still
 *   decay; >8B struct vars keep the aliased pass-by-pointer convention.
 *   Also pins: deref-pass (*p), arrow-field pass (p->name), local-copy pass,
 *   and a global struct var at arg position 2.
 *   32 = all green (gcc oracle)  32+bitN = the N-th pass mode broke */
typedef struct { unsigned int offset; unsigned int length; } txt_t;
typedef struct { txt_t name; unsigned int slot; } loc_t;
static txt_t NM;
static loc_t L1;
static unsigned int r_param(txt_t name) { return name.length; }
static unsigned int r_param2(unsigned int pad, txt_t name) { return name.length; }
int main(void)
{
    txt_t *nm = &NM;
    loc_t *l1 = &L1;
    txt_t loc;
    int bad = 0;
    nm->offset = 5; nm->length = 40;
    l1->name.offset = 30; l1->name.length = 41;
    loc = NM;
    if (r_param(NM) != 40) bad = bad + 1;        /* bit0: bare global struct var */
    if (r_param(*nm) != 40) bad = bad + 2;       /* bit1: deref of struct pointer */
    if (r_param(l1->name) != 41) bad = bad + 4;  /* bit2: arrow-field struct value */
    if (r_param(loc) != 40) bad = bad + 8;       /* bit3: local struct copy */
    if (r_param2(1u, NM) != 40) bad = bad + 16;  /* bit4: bare global at position 2 */
    return 32 + bad;
}
