/* repro: GLOBAL STRUCT-ARRAY with a braced initializer -- the seed's strcmp-table idiom
 * (sema_is_irpd_method: III_IRPD_METHODS[i].name ; parse recover FOLLOW-sets ; dispatch tables).
 * Decoded root (seed_sema fn31 trace): the array never registers its element struct type ->
 * TBL[i].field emits NOTHING -> the consumer's arg SET underflows (11:x@-1). */
typedef struct { const char *name; int code; } entry_t;
static const entry_t TBL[3] = {
    { "alpha", 10 },
    { "beta",  20 },
    { "gamma", 30 },
};
static int lookup(const char *s) {
    for (int i = 0; i < 3; i++) {
        if (TBL[i].name[0] == s[0]) return TBL[i].code;   /* element field READs: ptr field + int field */
    }
    return -1;
}
int main(void) {
    if (lookup("beta") == 20 && lookup("gamma") == 30 && lookup("zeta") == -1) return 99;
    return 1;
}
