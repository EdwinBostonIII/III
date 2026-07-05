/* test_forempty.c -- EMPTY for-increment clause: the reverse-loop idiom `for (i = n; i-- > 0; )`
 * (sema_local_lookup + the parse recover/witness family -- the decrement lives in the COND).
 * one_incr previously ran its ebin+DROP fallback on the bare `)` -> a DROP with nothing on the
 * stack (rc=8; pinned RED # 1 1 8 8 pre-fix).  Also pins `for (;;)`-style empty incr with break. */
static int SUM;
int main(void) {
    for (int i = 5; i-- > 0; ) { SUM += i; }          /* 4+3+2+1+0 = 10 */
    int k = 0;
    for (;;) { k++; if (k == 3) break; }              /* empty init+cond+incr */
    if (SUM == 10 && k == 3) return 99;
    return 1;
}
