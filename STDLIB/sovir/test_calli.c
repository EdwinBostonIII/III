/* call()[i] KAT (the UPDATE-61 named gap; cg_r3's emit_field_label/emit_function shape
 * `iii_ast_source_buf(cg->ast)[name.offset + i]`): index a call's returned pointer DIRECTLY,
 * no intermediate local.  Value teeth: distinct bytes at distinct indices pin the load
 * ADDRESS (stride x index) and WIDTH (1 byte); a wrong stride, dropped index, or 8-byte load
 * returns 1, not 99.  The import-callee twin lives in test_import.c (gcc cannot link it). */
static unsigned char BUF[4] = {7, 9, 11, 13};
static const unsigned char *msrc(void) { return BUF; }
static unsigned int WTAB[3] = {100000, 200000, 300000};
static const unsigned int *wsrc(void) { return WTAB; }
int main(void) {
    unsigned char a = msrc()[2];              /* BUF[2] = 11 : byte pointee */
    unsigned char b = msrc()[0];              /* BUF[0] = 7  : index 0 */
    unsigned int w = wsrc()[1];               /* WTAB[1] = 200000 : 4-byte pointee (stride 4) */
    int i = 1;
    unsigned char c = msrc()[i + 2];          /* BUF[3] = 13 : expression index */
    if (a != 11) { return 1; }
    if (b != 7) { return 1; }
    if (w != 200000) { return 1; }
    if (c != 13) { return 1; }
    return 99;
}
