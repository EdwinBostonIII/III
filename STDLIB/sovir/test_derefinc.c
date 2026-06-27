/* test_derefinc.c -- (*p)++ / (*p)-- : post-incr/decr the POINTEE (the seed's `uint32_t slot = (*count_p)++`).
 * Was: postfix ++/-- on a PARENTHESIZED deref dropped -> under-emit -> verify-fail. */
static int cnt=5; static int* getp(void){ return &cnt; }
int main(void){
    int v=10; int *p=&v;
    int old=(*p)++;                 /* old=10, v=11 */
    if (old!=10) return 1;
    if (v!=11) return 2;
    (*p)--; if (v!=10) return 3;    /* v back to 10 */
    int *cp=getp();
    int slot=(*cp)++;               /* call-result deref-incr: slot=5, cnt=6 */
    if (slot!=5) return 4;
    if (cnt!=6) return 5;
    return 99;
}
