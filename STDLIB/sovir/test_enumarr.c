/* ENUM-TYPEDEF LOCAL ARRAYS (parse_primary/parse_pattern's `iii_ast_trit_t trits[6];`,
 * recover_follow's `iii_token_kind_t buf[16];` + `static const iii_token_kind_t
 * fallback[] = {..};`).  Two arms: a mutable local array (4B elements, distinct values
 * pin size+addressing) and a static-const initialized table with empty [] (size from
 * init count; runtime re-init per call is value-identical for a const table -- the
 * second look(0) call pins it). */
typedef enum { KA = 3, KB = 7, KC = 11 } kind_t;
typedef enum { TA = 5, TB = 9, TEND = 0 } tok_t;
static int look(int i) {
    static const tok_t fallback[] = { TA, TB, TEND };
    return (int)fallback[i];
}
int main(void) {
    kind_t buf[4];
    buf[0] = KC;
    buf[1] = KA;
    kind_t x = buf[0];
    if (x != KC) { return 1; }
    if (buf[1] != KA) { return 1; }
    if (look(0) != 5) { return 1; }
    if (look(1) != 9) { return 1; }
    if (look(0) != 5) { return 1; }
    return 99;
}
