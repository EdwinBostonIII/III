/* III HEXAD — Cross-module bridge to TYPES (libiii_types.a).
 *
 * Verifies that the six PFS hexads in our local table match the brick
 * hexads exported by TYPES (`iii_hexad_brick`). This file deliberately
 * does NOT include "iii/hexad.h" (TYPES' types_hexad.h defines
 * `iii_trit_t` and `iii_hexad_t` with different storage). It exposes
 * one C-linkage symbol declared in hexad.h, returning 0 on agreement.
 */
#include "iii/types_hexad.h"
#include <string.h>

/* Local copy of the canonical PFS pillar table — must match
 * hexad_pfs.c and III-HEXAD.md §4.2 verbatim. */
typedef struct {
    int        types_brick;       /* iii_brick_t */
    iii_trit_t pillars[6];
} bridge_entry_t;

#define N III_TRIT_NEG
#define Z III_TRIT_ZERO

static const bridge_entry_t BRIDGE[] = {
    { III_BRICK_CAPSULE_UPDATE,   { N, N, N, N, Z, Z } },
    { III_BRICK_MICROCODE_LOAD,   { N, N, N, Z, Z, Z } },
    { III_BRICK_BOOTORDER_SET,    { N, N, Z, N, Z, Z } },
    { III_BRICK_REAL_NVRAM_WRITE, { N, Z, N, N, Z, Z } },
    { III_BRICK_ME_PSP_MAILBOX,   { Z, N, N, N, Z, Z } },
    { III_BRICK_SMRAM_WRITE,      { N, N, N, N, N, Z } }
};
#define BRIDGE_LEN ((int)(sizeof BRIDGE / sizeof BRIDGE[0]))

int iii_hexad_types_bridge_verify(void) {
    for (int i = 0; i < BRIDGE_LEN; ++i) {
        iii_hexad_t local;
        memcpy(local.pillar, BRIDGE[i].pillars, sizeof local.pillar);
        iii_hexad_t types_h = iii_hexad_brick((iii_brick_t)BRIDGE[i].types_brick);
        if (!iii_hexad_eq(&local, &types_h)) return -(i + 1);
        /* Confirm packed values agree (shared 0..728 ternary index). */
        if (iii_hexad_pack(&local) != iii_hexad_pack(&types_h)) return -(100 + i);
        /* Confirm TYPES considers it inadmissible (Representability
         * Theorem must hold across both module surfaces). */
        if (iii_hexad_admitted(&types_h)) return -(200 + i);
    }
    return 0;
}
