#include <stdio.h>
#include <stdint.h>
extern uint32_t sum_let_in_loop(void);
extern uint32_t sum_no_let_in_loop(void);
int main(void) {
    printf("let-in-loop:    %u (expect 100: 0+10+20+30+40)\n", sum_let_in_loop());
    printf("let-mut-out:    %u (expect 100)\n", sum_no_let_in_loop());
    return 0;
}
