/* #define delta probe 2: the EXACT ast.h shape -- multi-space + u-suffix + TRAILING
 * BLOCK COMMENT on the #define line.  99 = correct; 42 = value read 0; 41 = other. */
#define PM   2u   /* mid-arity payloads */
#define PL   3u   /* high-arity */
int main(void) {
    if (PM == 2u && PL == 3u) { return 99; }
    if (PM == 0u) { return 42; }
    return 41;
}
