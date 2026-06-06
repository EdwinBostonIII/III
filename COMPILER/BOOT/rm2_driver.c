/* rm2_driver.c -- runner for the Ring -2 (sanctum) end-to-end reseal gate (check_rm2.sh).
 * Calls the emitted sealed_call do_thing(x); do_thing(7) must compute 3*x = 21.
 * The sanctum function is SysV-ABI; we cross the Win64->SysV boundary via gcc's sysv_abi attribute.
 * iii_cap_verify (auto D10) and the mangled cap_revoke are sanctum-runtime primitives, stubbed here. */
#include <stdint.h>

extern uint64_t L_sanctum_do_thing(uint64_t x) __attribute__((sysv_abi));
extern uint64_t L_sanctum_do_ord(uint64_t x)   __attribute__((sysv_abi));
extern uint64_t L_sanctum_do_sord(uint64_t x)  __attribute__((sysv_abi));

void     iii_cap_verify(uint64_t h)            { (void)h; }
uint64_t L_sanctum_iii_cap_revoke(uint64_t h)  { (void)h; return 0; }

int main(void) {
    if (L_sanctum_do_thing(7) != 21) return 1;                  /* arithmetic spine: 3*7 */
    if (L_sanctum_do_ord(0x4000000000000000ULL) != 1) return 2; /* UNSIGNED u64 ordering: 0x4..<0x8.. (the fix) */
    if (L_sanctum_do_sord(0) != 1) return 3;                    /* SIGNED i64 ordering unchanged: -7<5 */
    return 21;   /* all three pass -> exit 21 (the gate's expected value) */
}
