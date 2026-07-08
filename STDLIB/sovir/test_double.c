/* test_double.c -- EXACT IEEE-754 double-lowering KAT (ccsv soft-float vs gcc hardware doubles).
 *
 * Every case prints the 64-bit pattern of a double result as 16 lowercase hex digits + newline.
 * gcc compiles this with REAL hardware IEEE-754; ccsv lowers the same source to its iii_d_* integer
 * soft-float runtime (appended source tail).  Byte-identical stdout == the soft-float is exactly
 * IEEE-754 (round-to-nearest-even) on every exercised path: literals (exact decimal->binary64),
 * int->double conversion (decl-init, assignment, cast, mixed operands both sides), + - * /,
 * cancellation to +0, and repeating-binary fractions (0.1, 1/3).
 * Pure compute (no clock/imports) so every arm (verify/interp/x86/wasm/gcc) runs it.
 * Scope (named): no denormals, no inf/nan, no scientific notation -- the runtime LOUD-refuses those.
 */
#include <stdio.h>   /* gcc: putchar prototype ; ccsv: angle-includes are skipped by design */

typedef union { double d; unsigned long long u; } bits_t;

static void puthex(unsigned long long v)
{
    int i = 60;
    while (i >= 0) {
        int nib = (v >> i) & 15;
        if (nib < 10) putchar(48 + nib);
        else putchar(87 + nib);
        i = i - 4;
    }
    putchar(10);
}

static void show(double d)
{
    bits_t b;
    b.d = d;
    puthex(b.u);
}

int main(void)
{
    double a;
    double c;
    /* literals: exact decimal -> binary64 */
    show(0.5);
    show(0.1);
    show(1000.0);
    show(3.141592653589793);
    show(255.375);
    show(1.0);
    /* int -> double conversions */
    a = 1000;
    show(a);
    show((double)7);
    show((double)0 - 0.5);
    /* add / sub */
    show(0.1 + 0.2);
    show(1.0 - 0.9);
    show(1.5 - 1.5);
    /* mul */
    show(1000.0 * 1000.0);
    show(3.5 * 2.25);
    show(0.1 * 0.1);
    show(2.0 * 0.5);
    /* div */
    show(7.0 / 0.25);
    show(1.0 / 3.0);
    show(10.0 / 3.0);
    /* mixed int/double operands (both orders) */
    c = 42;
    show(c / 7.0);
    show(3 * 0.5);
    show(0.5 * 3);
    return 0;
}
