/* III HEXAD — Asymmetric Ternary Ground (R1.A6).
 *
 * Implements III-HEXAD.md in full: the asymmetric ternary algebra over
 * {NEG, ZERO, POS}, the 6-trit hexad packed into a u16, the 144-byte
 * reachability bitmap `xii_asym_reach6`, the Representability Theorem
 * (six PFS bricking ops are structurally absent), Dynamic / Epistemic /
 * Möbius hexads.
 *
 * NIH discipline: pure C11, no third-party headers. Depends on
 * libiii_types.a (TYPES brick metadata) and libiii_lex.a (SHA-256).
 */
#ifndef III_HEXAD_H
#define III_HEXAD_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ---------------------------------------------------------------- §1 */
/* §1.1 — The Trit. Numerical balanced encoding. */
typedef enum iii_trit {
    III_TRIT_NEG  = -1,
    III_TRIT_ZERO =  0,
    III_TRIT_POS  = +1
} iii_trit_t;

/* §1.2 — Trit operations (asymmetric tables). */
iii_trit_t iii_trit_not(iii_trit_t a);
iii_trit_t iii_trit_and(iii_trit_t a, iii_trit_t b);
iii_trit_t iii_trit_or (iii_trit_t a, iii_trit_t b);
iii_trit_t iii_trit_sum(iii_trit_t a, iii_trit_t b);   /* "add" */
iii_trit_t iii_trit_mul(iii_trit_t a, iii_trit_t b);
iii_trit_t iii_trit_sub(iii_trit_t a, iii_trit_t b);   /* sum(a, not(b)) */
/* Alias for `not` (NEG↔POS, ZERO→ZERO). Suffixed to avoid collision
 * with TYPES `iii_trit_neg` which uses a different trit numeric ABI. */
iii_trit_t iii_trit_neg6(iii_trit_t a);

/* Asymmetric numerical weight: NEG=-2, ZERO=0, POS=+1. */
int iii_trit_weight(iii_trit_t t);

/* Validity. */
bool iii_trit_valid(int v);

/* ---------------------------------------------------------------- §2 */
/* §2 — The Hexad. Six trits, ternary-packed into a u16 (0..728). */

#define III_HEXAD_MAX        729u   /* 3^6 */
#define III_HEXAD_BITMAP_LEN 144u   /* canonical 144-byte reachability table */

/* Public packed type: u16 holding ternary-packed value 0..728. */
typedef uint16_t iii_hexad_t;

/* Pillar names per §2.1. */
typedef enum iii_pillar {
    III_PILLAR_INVERSE_DERIV    = 0,  /* P1 */
    III_PILLAR_CAUSALITY_DEPTH  = 1,  /* P2 */
    III_PILLAR_CONSENT_RECENCY  = 2,  /* P3 */
    III_PILLAR_REPLICATION_TIER = 3,  /* P4 */
    III_PILLAR_ADVERSARIALITY   = 4,  /* P5 */
    III_PILLAR_COHERENCE_IMPACT = 5   /* P6 */
} iii_pillar_t;

const char *iii_pillar_name(iii_pillar_t p);

/* Pack/unpack. Both endpoints reject invalid trits and out-of-range u16.
 *
 * NOTE: function names carry the `6` suffix because TYPES exports
 * symbols `iii_hexad_pack`/`_unpack`/`_eq`/`_compose`/`_neg` with a
 * struct-based ABI. The HEXAD module uses a u16 ABI per spec; the
 * suffix prevents a silent ABI clash at static-link time. */
iii_hexad_t iii_hexad_pack6(const iii_trit_t pillars[6]);
bool        iii_hexad_unpack6(iii_hexad_t h, iii_trit_t out[6]);
iii_trit_t  iii_hexad_pillar(iii_hexad_t h, iii_pillar_t p);

/* §2.4 Hexad composition: AND on P1..P4, OR on P5..P6. */
iii_hexad_t iii_hexad_compose6(iii_hexad_t a, iii_hexad_t b);

/* Pillar-wise hexad algebra (broadcast trit op). */
iii_hexad_t iii_hexad_add(iii_hexad_t a, iii_hexad_t b);  /* SUM */
iii_hexad_t iii_hexad_sub(iii_hexad_t a, iii_hexad_t b);
iii_hexad_t iii_hexad_mul(iii_hexad_t a, iii_hexad_t b);
iii_hexad_t iii_hexad_neg6(iii_hexad_t h);                /* trit-wise NOT */

/* §3.5-style "active" negation: flip pillars 1..4, keep 0 and 5. */
iii_hexad_t iii_hexad_active_neg(iii_hexad_t h);

bool iii_hexad_eq6(iii_hexad_t a, iii_hexad_t b);

/* ---------------------------------------------------------------- §3 */
/* §3 — Reachability bitmap.
 *
 * `xii_asym_reach6` is exactly 144 bytes (1152 bits ≥ 729 hexads, with
 * the high pad zeroed). Bit-set iff the hexad is admitted.
 *
 * Default rule: structural admissibility — no NEG in pillars P1..P4.
 * Six PFS hexads are explicitly blocked (which the structural rule
 * already implies). The bitmap is mutable for Dynamic-Hexad promotions
 * (§5), but only monotonically.
 */
extern uint8_t xii_asym_reach6[III_HEXAD_BITMAP_LEN];

void  iii_hexad_init(void);                          /* idempotent */
bool  iii_hexad_reachable(iii_hexad_t h);
void  iii_hexad_bitmap_sha256(uint8_t out[32]);

/* Number of admissible hexads currently in the bitmap. */
size_t iii_hexad_reachable_count(void);

/* ---------------------------------------------------------------- §4 */
/* §4 — Representability Theorem: six PFS bricking ops. */
typedef enum iii_pfs_op {
    III_PFS_NONE             = 0,
    III_PFS_CAPSULE_UPDATE   = 1,
    III_PFS_MICROCODE_LOAD   = 2,
    III_PFS_BOOTORDER_SET    = 3,
    III_PFS_REAL_NVRAM_WRITE = 4,
    III_PFS_ME_PSP_MAILBOX   = 5,
    III_PFS_SMRAM_WRITE      = 6,
    III_PFS__COUNT           = 7
} iii_pfs_op_t;

iii_hexad_t   iii_hexad_pfs(iii_pfs_op_t op);
const char   *iii_hexad_pfs_name(iii_pfs_op_t op);
iii_pfs_op_t  iii_hexad_pfs_kind(iii_hexad_t h);

/* Cross-module bridge: confirm TYPES brick hexads agree with PFS table.
 * Returns 0 on success, non-zero on disagreement. */
int iii_hexad_types_bridge_verify(void);

/* ---------------------------------------------------------------- §5 */
/* §5 — Dynamic Hexads (Catalyst-promoted runtime extensions). */
typedef struct iii_hexad_candidate {
    iii_hexad_t hexad;
    double      mobius_coherence;     /* candidate Q14 */
    bool        trinity_admit;
    bool        ceiling_admit;
    bool        codegen_safe;
    /* internal — set after promote */
    bool        promoted;
    bool        escalates;            /* whether code is 0b10 (P5/P6 NEG) */
} iii_hexad_candidate_t;

iii_hexad_candidate_t iii_hexad_dynamic_create(iii_hexad_t h, double coherence);
/* Returns 0 on success and flips xii_asym_reach6 bit. Non-zero on
 * failure (any precondition unmet). Strictly monotonic: never clears
 * bits, never re-enables structural-NEG hexads. */
int iii_hexad_dynamic_promote(iii_hexad_candidate_t *c);

/* Number of dynamic promotions performed since init. */
size_t iii_hexad_dynamic_count(void);

/* ---------------------------------------------------------------- §6 */
/* §6 — Epistemic Hexads. */
typedef struct iii_hexad_epistemic {
    iii_hexad_t hexad;
    double      confidence;     /* in [0,1] (q-units) */
    uint32_t    open_questions; /* count */
    uint32_t    domain_tag;
} iii_hexad_epistemic_t;

#define III_EPISTEMIC_FLOOR_Q 0.85

iii_hexad_epistemic_t iii_hexad_epistemic_make(iii_hexad_t h, double conf,
                                               uint32_t questions,
                                               uint32_t domain);
/* Multiplicative confidence + summed open questions; hexads compose
 * via §2.4 compose. */
iii_hexad_epistemic_t iii_hexad_epistemic_combine(iii_hexad_epistemic_t a,
                                                  iii_hexad_epistemic_t b);
bool iii_hexad_epistemic_escalates(const iii_hexad_epistemic_t *e);

/* ---------------------------------------------------------------- §7 */
/* §7 — Möbius Hexads (bidirectional inverse pair). */
typedef struct iii_hexad_mobius {
    iii_hexad_t forward;
    iii_hexad_t inverse;
    double      coherence_floor;  /* default III_MOBIUS_FLOOR_Q */
} iii_hexad_mobius_t;

#define III_MOBIUS_FLOOR_Q 0.92

iii_hexad_mobius_t iii_hexad_mobius_make(iii_hexad_t forward,
                                         double coherence_floor);
/* Returns true iff hexads form an inverse pair under active negation. */
bool iii_hexad_mobius_valid(const iii_hexad_mobius_t *m);
/* Roundtrip: forward∘inverse must yield the all-ZERO hexad on
 * pillars 1..4 (the active region). */
bool iii_hexad_mobius_roundtrip(const iii_hexad_mobius_t *m);
bool iii_hexad_mobius_admits(const iii_hexad_mobius_t *m, double current_q);

#ifdef __cplusplus
}
#endif
#endif
