/* test_desig.c -- behavioral gate for designated-initializer arrays with a NAMED-CONST size and
 * string-pointer elements (the seed's `static const char *const III_TOKEN_KIND_NAMES[III_TOK_KIND_COUNT]
 * = { [III_TOK_X] = "X", ... }` idiom, indexed by iii_token_kind_name). */
enum { K_A, K_B, K_C, KCOUNT };
static const char *const NAMES[KCOUNT] = {
    [K_A] = "aa",
    [K_B] = "bb",
    [K_C] = "cc",
};
const char *kind_name(int k) {
    if ((unsigned)k >= KCOUNT) return "?";
    const char *s = NAMES[k];
    return s ? s : "?";
}
int main(void) {
    const char *a = kind_name(0);  if (a[0] != 'a') return 1;
    const char *b = kind_name(1);  if (b[0] != 'b') return 2;
    const char *c = kind_name(2);  if (c[0] != 'c') return 3;
    const char *q = kind_name(99); if (q[0] != '?') return 4;
    return 99;
}
