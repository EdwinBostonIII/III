#include <stdio.h>
#include <stdint.h>
extern uint32_t add_2(uint32_t,uint32_t);
extern uint32_t add_3(uint32_t,uint32_t,uint32_t);
extern uint32_t add_4(uint32_t,uint32_t,uint32_t,uint32_t);
extern uint32_t add_5_v1(uint32_t,uint32_t,uint32_t,uint32_t,uint32_t);
extern uint32_t just_e(uint32_t,uint32_t,uint32_t,uint32_t,uint32_t);
extern uint32_t just_d(uint32_t,uint32_t,uint32_t,uint32_t,uint32_t);
extern uint32_t just_a(uint32_t,uint32_t,uint32_t,uint32_t,uint32_t);
extern uint32_t ab_plus_e(uint32_t,uint32_t,uint32_t,uint32_t,uint32_t);
extern uint64_t return_e_u64(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
int main(void) {
    printf("add_2(1,2) = %u (expect 3)\n", add_2(1,2));
    printf("add_3(1,2,3) = %u (expect 6)\n", add_3(1,2,3));
    printf("add_4(1,2,3,4) = %u (expect 10)\n", add_4(1,2,3,4));
    printf("add_5(1,2,3,4,5) = %u (expect 15)\n", add_5_v1(1,2,3,4,5));
    printf("just_a(10,20,30,40,50) = %u (expect 10)\n", just_a(10,20,30,40,50));
    printf("just_d(10,20,30,40,50) = %u (expect 40)\n", just_d(10,20,30,40,50));
    printf("just_e(10,20,30,40,50) = %u (expect 50)\n", just_e(10,20,30,40,50));
    printf("ab_plus_e(10,20,30,40,50) = %u (expect 80)\n", ab_plus_e(10,20,30,40,50));
    printf("return_e_u64(1,2,3,4,5) = %llu (expect 5)\n", (unsigned long long)return_e_u64(1,2,3,4,5));
    return 0;
}
