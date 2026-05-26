/* ============================================================================
 * III-PHASES — r1_a7.c
 *
 * Closure identity:  R1.A7 = SHA-256(canonical_byte_form(III-PHASES.md)).
 *
 * Computed via:  iii_phases_tool hash DOCS/III-PHASES.md
 *   = 8f3ff2e175a282dd24036224a97e4d67d5f58c298ea734294b9ba0d51edee1c9
 *
 * Federation peers reject any cycle whose closure manifest carries a value
 * different from this constant; any change to III-PHASES.md must be paired
 * with a corresponding change to this constant (an unsealed development
 * tree is permitted to carry zeros, recomputing on each rebuild).
 * ============================================================================
 */
#include "iii/phases.h"

const uint8_t III_PHASES_R1_A7[32] = {
    0x8f, 0x3f, 0xf2, 0xe1, 0x75, 0xa2, 0x82, 0xdd,
    0x24, 0x03, 0x62, 0x24, 0xa9, 0x7e, 0x4d, 0x67,
    0xd5, 0xf5, 0x8c, 0x29, 0x8e, 0xa7, 0x34, 0x29,
    0x4b, 0x9b, 0xa0, 0xd5, 0x1e, 0xde, 0xe1, 0xc9
};
