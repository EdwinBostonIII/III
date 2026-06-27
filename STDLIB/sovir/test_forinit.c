/* test_forinit.c -- declarations INSIDE the for-init for type forms that were dtype-ONLY before:
 * `unsigned`/`signed` (eaten by skipquals -> they are isqual) fell to the for-init EXPRESSION path,
 * which eval'd the type name -> under-emit -> seed verify-fail. Now detected before skipquals.
 * (Struct-typedef pointer for-inits ALSO now verify structurally -- they reduced the seed 85->83 --
 *  but their runtime is gated by a SEPARATE pre-existing bug: `local *p=&GLOBAL_struct; p->field`,
 *  see _latent_local_structptr_to_global_deref.c -- so they're not asserted behaviorally here.) */
int main(void){
    int s=0;
    for(unsigned k=0;k<4;k++) s+=k;        /* bare unsigned -> 0+1+2+3 = 6 */
    for(signed g=0;g<3;g++) s+=10;         /* bare signed   -> +30 = 36 */
    for(int i=0,m=2;i<m;i++) s+=100;       /* multi-declarator int -> +200 = 236 */
    if(s != 236) return 1;
    return 99;
}
