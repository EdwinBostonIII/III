#include <stdio.h>
#include <stdint.h>
extern uint32_t r_setup_empty(void);
extern uint32_t r_round1_t1(void);
extern uint32_t r_round1_t1_split(void);
int main(void) {
    r_setup_empty();
    printf("t1 (one expr):      0x%08X (expect 0x7377ED68)\n", r_round1_t1());
    printf("t1 (split lets):    0x%08X (expect 0x7377ED68)\n", r_round1_t1_split());
    return 0;
}
