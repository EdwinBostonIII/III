#include <stdio.h>
#include <stdint.h>
extern uint32_t probe_arr_init(void);
extern uint32_t probe_get(uint32_t i);
extern uint32_t probe_get_filler(uint32_t i);
extern uint32_t probe_get2(uint32_t i);

int main(void) {
    probe_arr_init();
    printf("TEST_ARR[0] = 0x%08X (expect 0x11111111)\n", probe_get(0));
    printf("TEST_ARR[1] = 0x%08X (expect 0x22222222)\n", probe_get(1));
    printf("TEST_ARR[2] = 0x%08X (expect 0x33333333)\n", probe_get(2));
    printf("TEST_ARR[3] = 0x%08X (expect 0x44444444)\n", probe_get(3));
    for (int i = 0; i < 16; i++) {
        printf("FILLER[%2d]  = 0x%08X (expect 0xAAAA00%02X)\n", i, probe_get_filler(i), i);
    }
    for (int i = 0; i < 8; i++) {
        printf("TEST_ARR2[%d] = 0x%08X (expect 0xBB0000%02X)\n", i, probe_get2(i), i);
    }
    return 0;
}
