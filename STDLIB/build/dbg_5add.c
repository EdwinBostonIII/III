#include <stdio.h>
#include <stdint.h>
extern uint32_t five_add_direct(uint32_t,uint32_t,uint32_t,uint32_t,uint32_t);
extern uint32_t five_add_via_local(uint32_t,uint32_t,uint32_t,uint32_t,uint32_t);
extern uint32_t five_add_pairwise(uint32_t,uint32_t,uint32_t,uint32_t,uint32_t);
extern uint32_t six_arg_use_all(uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,uint32_t);
extern uint32_t six_arg_via_local(uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,uint32_t);
int main(void) {
    /* Expected: 1+2+3+4+5 = 15 */
    printf("5add direct: %u (expect 15)\n", five_add_direct(1,2,3,4,5));
    printf("5add via-local: %u (expect 15)\n", five_add_via_local(1,2,3,4,5));
    printf("5add pairwise: %u (expect 15)\n", five_add_pairwise(1,2,3,4,5));
    /* 6 args: 1+2+3+4+5+6 = 21 */
    printf("6arg direct: %u (expect 21)\n", six_arg_use_all(1,2,3,4,5,6));
    printf("6arg via-local: %u (expect 21)\n", six_arg_via_local(1,2,3,4,5,6));
    return 0;
}
