#include <stdio.h>
#include <stdint.h>
extern uint32_t populate(void);
extern uint32_t five_add_locals(void);
extern uint32_t five_add_via_array(void);
int main(void) {
    populate();
    printf("five_add_locals: %u (expect 1500)\n", five_add_locals());
    printf("five_add_via_array: %u (expect 1500)\n", five_add_via_array());
    return 0;
}
