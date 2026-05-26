#include <stdio.h>
#include <stdint.h>
extern uint32_t ir_setup(void);
extern uint32_t ir_round_with_calls(void);
extern uint32_t ir_round_inline(void);
int main(void) {
    ir_setup();
    printf("with_calls: 0x%08X (expect 0x7377ED68)\n", ir_round_with_calls());
    printf("inline:     0x%08X (expect 0x7377ED68)\n", ir_round_inline());
    return 0;
}
