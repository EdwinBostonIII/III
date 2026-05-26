/* III TYPES — Hexad / asymmetric ternary kernel (§4, §11.2).
 *
 * Native ternary primitives, used by both the type system and the CIC
 * proof kernel (the "native ternary extension" of §11.2).
 */
#ifndef III_TYPES_HEXAD_H
#define III_TYPES_HEXAD_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum iii_trit { III_TRIT_NEG = 0, III_TRIT_ZERO = 1, III_TRIT_POS = 2 } iii_trit_t;

/* Six-pillar hexad: pillars 0..5.  Packed canonically into a u16 by
 *   sum_{p=0..5} trit_p * 3^p     (each trit ∈ {0=NEG,1=ZERO,2=POS}).
 * Maximum value: 728 (= 3^6-1), so the bitmap has 729 entries → 92 bytes
 * (round up to 144 to match the spec's 144-byte block reservation). */
#define III_HEXAD_BITMAP_SLOTS 729u
#define III_HEXAD_BITMAP_BYTES 144u

typedef struct iii_hexad {
    iii_trit_t pillar[6];
} iii_hexad_t;

uint16_t       iii_hexad_pack(const iii_hexad_t *h);
void           iii_hexad_unpack(uint16_t packed, iii_hexad_t *out);
bool           iii_hexad_eq(const iii_hexad_t *a, const iii_hexad_t *b);

/* Asymmetric trit composition (NEG dominates POS in pillars 1..4 per
 * spec; identity for ZERO; POS-POS = POS; NEG-NEG = NEG; NEG-POS = NEG;
 * POS-NEG = NEG; ZERO is identity). */
iii_trit_t     iii_trit_compose(iii_trit_t a, iii_trit_t b);
iii_trit_t     iii_trit_neg(iii_trit_t a);

/* Hexad composition (pillar-wise asymmetric compose). */
iii_hexad_t    iii_hexad_compose(const iii_hexad_t *a, const iii_hexad_t *b);
/* Hexad negation (per §3.5: r ⟲ negates pillars 1..4, leaves 0,5 alone). */
iii_hexad_t    iii_hexad_neg(const iii_hexad_t *a);

/* Reachability bitmap (`xii_asym_reach6`).  Bit set iff hexad is admitted.
 * The bitmap has ALL of 729 entries set EXCEPT the six PFS bricking
 * hexads of §4.3 (capsule_update, microcode_load, bootorder_set,
 * real_nvram_write, me_psp_mailbox, smram_write).  This implements the
 * Representability Theorem as a typing rule. */
bool           iii_hexad_admitted(const iii_hexad_t *h);
bool           iii_hexad_packed_admitted(uint16_t packed);

/* Identify the six bricking-hexad presets. */
typedef enum iii_brick {
    III_BRICK_CAPSULE_UPDATE      = 0,
    III_BRICK_MICROCODE_LOAD      = 1,
    III_BRICK_BOOTORDER_SET       = 2,
    III_BRICK_REAL_NVRAM_WRITE    = 3,
    III_BRICK_ME_PSP_MAILBOX      = 4,
    III_BRICK_SMRAM_WRITE         = 5,
    III_BRICK__COUNT              = 6
} iii_brick_t;

iii_hexad_t    iii_hexad_brick(iii_brick_t which);
const char    *iii_hexad_brick_name(iii_brick_t which);

/* Compute the SHA-256 of the canonical bitmap (for closure-root sealing). */
void           iii_hexad_bitmap_hash(uint8_t out[32]);

#ifdef __cplusplus
}
#endif
#endif
