/* rm2_driver.c -- stage-4 runner for the III Ring -2 (sanctum) codegen.
 * Calls the emitted sealed_call do_thing(x) and checks it computes 3*x (x + x + x).
 * The sanctum function is SysV-ABI (params in rdi...); we cross the Win64->SysV boundary with
 * gcc's sysv_abi attribute. iii_cap_verify (auto D10 cap-verify) and the mangled cap_revoke are
 * sanctum-runtime primitives -- stubbed here so the function is self-contained for the test.
 *   do_thing(7) = 7 + 7 + 7 = 21  -> exit code 21 */
#include <stdint.h>
#include <stdio.h>

extern uint64_t L_sanctum_do_thing(uint64_t x) __attribute__((sysv_abi));

/* called BY the sanctum function (SysV ABI); they ignore the arg, so the stub ABI is irrelevant */
void     iii_cap_verify(uint64_t h)            { (void)h; }
uint64_t L_sanctum_iii_cap_revoke(uint64_t h)  { (void)h; return 0; }

int main(void) {
    uint64_t r = L_sanctum_do_thing(7);
    printf("do_thing(7) = %llu (expect 21)\n", (unsigned long long)r);
    return (int)(r & 0xFF);
}
