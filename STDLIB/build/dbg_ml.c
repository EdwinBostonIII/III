#include <stdio.h>
#include <stdint.h>
extern uint32_t multi_let_loop(void);
extern uint32_t six_let_loop(void);
int main(void) {
    /* multi_let:
       i=0: x=0, y=0, z=0, sum+=0
       i=1: x=10, y=100, z=110, sum=110
       i=2: x=20, y=200, z=220, sum=330
       i=3: x=30, y=300, z=330, sum=660
       i=4: x=40, y=400, z=440, sum=1100
    */
    printf("multi_let_loop: %u (expect 1100)\n", multi_let_loop());
    /* six_let:
       i=0: a=1 b=2 c=3 d=2 e=1 f=5; sum=5
       i=1: a=2 b=3 c=5 d=6 e=3 f=11; sum=16
       i=2: a=3 b=4 c=7 d=12 e=11 f=19; sum=35
       i=3: a=4 b=5 c=9 d=20 e=29 f=29; sum=64
    */
    printf("six_let_loop: %u (expect 64)\n", six_let_loop());
    return 0;
}
