#include <stdio.h>
#include <stdint.h>
extern uint32_t rotation_test(uint32_t steps, uint32_t idx);
extern uint32_t eight_rotation(uint32_t steps, uint32_t idx);
int main(void) {
    /* 4-rotation, steps=2: expect a=1000, b=0, c=100, d=200 */
    printf("4-rot steps=2:\n");
    char *n4 = "abcd";
    uint32_t exp4[4] = {1000, 0, 100, 200};
    for (int i = 0; i < 4; i++) {
        uint32_t v = rotation_test(2, i);
        printf("  %c=%u expect=%u %s\n", n4[i], v, exp4[i], v == exp4[i] ? "OK" : "DIFF");
    }
    
    /* 8-rotation: simulate manually
       Start: a=1,b=2,c=3,d=4,e=5,f=6,g=7,h=8
       iter 0: t1=h+100=108, t2=a+10=11
               h=g=7, g=f=6, f=e=5, e=d+t1=4+108=112,
               d=c=3, c=b=2, b=a=1, a=t1+t2=108+11=119
               state: a=119,b=1,c=2,d=3,e=112,f=5,g=6,h=7
       iter 1: t1=h+100=107, t2=a+10=129
               h=g=6, g=f=5, f=e=112, e=d+t1=3+107=110,
               d=c=2, c=b=1, b=a=119, a=t1+t2=107+129=236
               state: a=236,b=119,c=1,d=2,e=110,f=112,g=5,h=6
    */
    printf("\n8-rot steps=2:\n");
    char *n8 = "abcdefgh";
    uint32_t exp8[8] = {236, 119, 1, 2, 110, 112, 5, 6};
    for (int i = 0; i < 8; i++) {
        uint32_t v = eight_rotation(2, i);
        printf("  %c=%u expect=%u %s\n", n8[i], v, exp8[i], v == exp8[i] ? "OK" : "DIFF");
    }
    return 0;
}
