/* rm2_driver.c -- runner for the Ring -2 (sanctum) end-to-end reseal gate (check_rm2.sh).
 * Calls the emitted sealed_call do_thing(x); do_thing(7) must compute 3*x = 21.
 * The sanctum function is SysV-ABI; we cross the Win64->SysV boundary via gcc's sysv_abi attribute.
 * iii_cap_verify (auto D10) and the mangled cap_revoke are sanctum-runtime primitives, stubbed here. */
#include <stdint.h>

extern uint64_t L_sanctum_do_thing(uint64_t x) __attribute__((sysv_abi));

void     iii_cap_verify(uint64_t h)            { (void)h; }
uint64_t L_sanctum_iii_cap_revoke(uint64_t h)  { (void)h; return 0; }

int main(void) { return (int)(L_sanctum_do_thing(7) & 0xFF); }   /* exit = 21 on success */
