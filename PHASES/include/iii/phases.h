/* ============================================================================
 * III-PHASES — The Cross-Ring Lattice
 * Document: III-PHASES.md  (Doc-ID A7, R1.A7)
 *
 * Public API for the phase system: ring lattice, phase polymorphism, cross-ring
 * constructors, marshalling, dynamic promotion, epistemic queries, ghost phases,
 * and predictive specialization.
 *
 * This is the runtime modelling library — the actual machine code that crosses
 * rings is emitted by SELF; this module owns the abstract semantics: legal
 * transitions, witness step kinds, lattice operations, rate caps, hot-path
 * tracking, and the synthesis bookkeeping for phase-polymorphic cycles.
 * ============================================================================
 */
#ifndef III_PHASES_H
#define III_PHASES_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ----------------------------------------------------------------------------
 * §1. Ring identity (encoded so the natural ordering matches privilege)
 *
 * The four canonical rings, encoded with R-2 = 0 and R3 = 3 so that "≼" (more-
 * privileged-or-equal) becomes the integer "≤" relation.
 * ---------------------------------------------------------------------------- */

typedef enum iii_phase_ring {
    III_RING_SANCTUM     = 0,  /* R-2 — sealed, DRTM-relaunchable */
    III_RING_HYPERVISOR  = 1,  /* R-1 — AMD-SVM only             */
    III_RING_KERNEL      = 2,  /* R0  — driver / kernel-mode      */
    III_RING_USER        = 3,  /* R3  — user-mode                 */
    III_RING_COUNT       = 4
} iii_phase_ring_t;

/* Aliases that mirror the spec's mathematical names */
#define III_RING_R_NEG2  III_RING_SANCTUM
#define III_RING_R_NEG1  III_RING_HYPERVISOR
#define III_RING_R0      III_RING_KERNEL
#define III_RING_R3      III_RING_USER

/* ----------------------------------------------------------------------------
 * §1.1 Phase-set bitmap (subset of {R-2,R-1,R0,R3}, never empty in valid form).
 * ---------------------------------------------------------------------------- */

typedef uint8_t iii_phase_set_t;

#define III_PHASE_SET_EMPTY         ((iii_phase_set_t)0u)
#define III_PHASE_SET_BIT(r)        ((iii_phase_set_t)(1u << ((unsigned)(r) & 3u)))
#define III_PHASE_SET_ALL           ((iii_phase_set_t)0x0Fu)

/* Constructors */
iii_phase_set_t iii_phase_set_singleton(iii_phase_ring_t r);
iii_phase_set_t iii_phase_set_pair(iii_phase_ring_t a, iii_phase_ring_t b);
iii_phase_set_t iii_phase_set_add(iii_phase_set_t s, iii_phase_ring_t r);
iii_phase_set_t iii_phase_set_remove(iii_phase_set_t s, iii_phase_ring_t r);
iii_phase_set_t iii_phase_set_union(iii_phase_set_t a, iii_phase_set_t b);
iii_phase_set_t iii_phase_set_intersect(iii_phase_set_t a, iii_phase_set_t b);
iii_phase_set_t iii_phase_set_difference(iii_phase_set_t a, iii_phase_set_t b);

/* Predicates */
bool iii_phase_set_contains(iii_phase_set_t s, iii_phase_ring_t r);
bool iii_phase_set_is_empty(iii_phase_set_t s);
bool iii_phase_set_equal(iii_phase_set_t a, iii_phase_set_t b);
bool iii_phase_set_subset(iii_phase_set_t a, iii_phase_set_t b);
unsigned iii_phase_set_cardinality(iii_phase_set_t s);

/* Iteration */
iii_phase_ring_t iii_phase_set_min(iii_phase_set_t s); /* most privileged in s; UB if empty */
iii_phase_ring_t iii_phase_set_max(iii_phase_set_t s); /* least privileged in s; UB if empty */

/* ----------------------------------------------------------------------------
 * §1.2 Lattice operations
 *
 * Lattice order: R-2 ≼ R-1 ≼ R0 ≼ R3.  iii_phase_leq(a,b) = "a is at least
 * as privileged as b".  Meet (greatest-lower-bound) is the more-privileged of
 * the two; join (least-upper-bound) is the less-privileged.
 * ---------------------------------------------------------------------------- */

bool iii_phase_leq(iii_phase_ring_t a, iii_phase_ring_t b);     /* a ≼ b ? */
bool iii_phase_lt(iii_phase_ring_t a, iii_phase_ring_t b);
iii_phase_ring_t iii_phase_meet(iii_phase_ring_t a, iii_phase_ring_t b); /* glb */
iii_phase_ring_t iii_phase_join(iii_phase_ring_t a, iii_phase_ring_t b); /* lub */

/* Adjacency — true iff the two rings are immediately adjacent in the lattice */
bool iii_phase_adjacent(iii_phase_ring_t a, iii_phase_ring_t b);

/* Format helpers */
const char *iii_phase_ring_name(iii_phase_ring_t r);          /* "R-2", "R-1", "R0", "R3" */
const char *iii_phase_ring_long_name(iii_phase_ring_t r);     /* "Sanctum", "Hypervisor", ... */
size_t iii_phase_set_format(iii_phase_set_t s, char *buf, size_t cap);  /* "{R-2,R-1}" form */

/* ----------------------------------------------------------------------------
 * §3. Cross-ring constructors (the only legal ways to cross rings).
 * ---------------------------------------------------------------------------- */

typedef enum iii_phase_constructor {
    III_XR_NONE              = 0,
    III_XR_MAGIC_MSR         = 1,  /* §3.1 — R3 ↔ R-1               */
    III_XR_IOCTL             = 2,  /* §3.2 — R3 ↔ R0                */
    III_XR_SANCTUM_GATE      = 3,  /* §3.3 — R-1 ↔ R-2              */
    III_XR_VMRUN             = 4,  /* §3.4 — R-1 ↔ R0               */
    III_XR_SYSRET            = 5,  /* §3.5 — R0 ↔ R3 (legacy)        */
    III_XR_COUNT             = 6
} iii_phase_constructor_t;

const char *iii_phase_constructor_name(iii_phase_constructor_t c);

/* Returns the constructor that implements a transition from `src` to `dst`,
 * or III_XR_NONE if none exists directly.  Symmetric: src↔dst yields the same
 * constructor as dst↔src. */
iii_phase_constructor_t iii_phase_constructor_for(iii_phase_ring_t src,
                                                  iii_phase_ring_t dst);

/* True iff a single direct constructor connects the two rings. */
bool iii_phase_directly_connected(iii_phase_ring_t a, iii_phase_ring_t b);

/* Indirect path: returns the next ring on the shortest constructor chain from
 * src toward dst.  Returns dst if directly connected; returns src if src==dst. */
iii_phase_ring_t iii_phase_next_hop(iii_phase_ring_t src, iii_phase_ring_t dst);

/* Length of the shortest chain in constructors. */
unsigned iii_phase_chain_length(iii_phase_ring_t src, iii_phase_ring_t dst);

/* ----------------------------------------------------------------------------
 * §3 (extended).  Witness step kinds — every cross-ring action emits one.
 * ---------------------------------------------------------------------------- */

typedef enum iii_phase_step_kind {
    XII_STEP_KIND_NONE                          = 0,

    /* §3.1 Magic-MSR */
    XII_STEP_KIND_MAGIC_MSR_INVOKE              = 0x01,
    XII_STEP_KIND_MAGIC_MSR_DISPATCH            = 0x02,
    XII_STEP_KIND_MAGIC_MSR_PROMOTE             = 0x03,

    /* §3.2 IOCTL */
    XII_STEP_KIND_IOCTL_ISSUE                   = 0x04,
    XII_STEP_KIND_IOCTL_DISPATCH                = 0x05,

    /* §3.3 Sanctum-Gate (8-step sealed-cycle box) */
    XII_STEP_KIND_SANCTUM_INTENT_MINT           = 0x06,
    XII_STEP_KIND_SANCTUM_GATE_ENTER            = 0x07,
    XII_STEP_KIND_SANCTUM_PKRU_REWRITE          = 0x08,
    XII_STEP_KIND_SANCTUM_DISPATCH              = 0x09,
    XII_STEP_KIND_SANCTUM_BODY                  = 0x0A,
    XII_STEP_KIND_SANCTUM_GATE_EXIT             = 0x0B,
    XII_STEP_KIND_SANCTUM_MSR_READ              = 0x0C,

    /* §3.4 VMRUN */
    XII_STEP_KIND_VMRUN                         = 0x0D,
    XII_STEP_KIND_VMEXIT                        = 0x0E,

    /* §3.5 SYSRET legacy */
    XII_STEP_KIND_SYSRET                        = 0x0F,
    XII_STEP_KIND_SYSCALL                       = 0x10,

    /* Per-ring lowerings */
    XII_STEP_KIND_R0_MSR_READ                   = 0x11,
    XII_STEP_KIND_R3_MAGIC_MSR_READ             = 0x12,
    XII_STEP_KIND_IRPD_MSR_READ                 = 0x13,

    /* Phase promotion / ghost / predictive */
    XII_STEP_KIND_PHASE_PROMOTE                 = 0x14,
    XII_STEP_KIND_PHASE_DEMOTE                  = 0x15,
    XII_STEP_KIND_GHOST_OBSERVE                 = 0x16,
    XII_STEP_KIND_PIP_SPECIALIZE                = 0x17,
    XII_STEP_KIND_PIP_DESPECIALIZE              = 0x18,

    XII_STEP_KIND_MAX                           = 0x18
} iii_phase_step_kind_t;

const char *iii_phase_step_kind_name(iii_phase_step_kind_t k);

/* ----------------------------------------------------------------------------
 * §4. Marshalling — a record of one cross-ring transition.
 * ---------------------------------------------------------------------------- */

typedef struct iii_phase_marshal {
    iii_phase_ring_t          src;
    iii_phase_ring_t          dst;
    iii_phase_constructor_t   constructor;

    /* Glyph-bound zero-copy: if the source/destination glyph mhashes match,
     * the compiler/runtime is permitted to hand off the pointer directly. */
    bool                      glyph_bound;
    uint8_t                   src_glyph_mhash[32];
    uint8_t                   dst_glyph_mhash[32];

    /* Witness chain — predecessor mhash links forward to successor mhash. */
    uint8_t                   predecessor_mhash[32];
    uint8_t                   successor_mhash[32];

    /* Epistemic gating (§4.4) */
    bool                      uncertainty_present;
    uint16_t                  confidence_q12;     /* fixed-point 0..4096 = [0,1] */
    bool                      operator_confirmed; /* set by reflect(uncertainty) */

    /* Möbius coherence (§4.5) — minimum coherence required to admit. */
    uint16_t                  required_coherence_q12;
    uint16_t                  current_coherence_q12;

    iii_phase_step_kind_t     step_kind;
} iii_phase_marshal_t;

/* Marshalling outcome */
typedef enum iii_phase_marshal_status {
    III_PHASE_MARSHAL_OK                    = 0,
    III_PHASE_MARSHAL_ERR_NO_CONSTRUCTOR    = 1,  /* TYPE-RING-001 */
    III_PHASE_MARSHAL_ERR_GLYPH_DRIFT       = 2,  /* PANIC-GLYPH-DRIFT */
    III_PHASE_MARSHAL_ERR_UNCERTAINTY       = 3,  /* operator confirmation needed */
    III_PHASE_MARSHAL_ERR_COHERENCE         = 4,  /* RUNTIME-MARSHALL-001 */
    III_PHASE_MARSHAL_ERR_INVALID_RING      = 5,  /* invalid src/dst */
    III_PHASE_MARSHAL_ERR_RATE_CAP          = 6
} iii_phase_marshal_status_t;

const char *iii_phase_marshal_status_name(iii_phase_marshal_status_t s);

/* Validate a proposed marshalling against all five rules.  Does not emit a
 * witness; returns OK if the transition is admissible right now. */
iii_phase_marshal_status_t iii_phase_marshal_check(const iii_phase_marshal_t *m);

/* Validate AND emit the witness; updates internal counters. */
iii_phase_marshal_status_t iii_phase_marshal_apply(iii_phase_marshal_t *m);

/* Inverse-marshal:  given a forward marshal, fill in `inv` with the matching
 * inverse.  src/dst swapped, predecessor/successor swapped, step kind paired. */
void iii_phase_marshal_inverse(const iii_phase_marshal_t *fwd,
                               iii_phase_marshal_t *inv);

/* ----------------------------------------------------------------------------
 * §2. Phase polymorphism — cycles with multi-ring lowerings.
 * ---------------------------------------------------------------------------- */

#define III_PHASE_MAX_LOWERINGS  III_RING_COUNT

typedef struct iii_phase_lowering {
    iii_phase_ring_t          ring;
    bool                      explicit_body;     /* programmer-supplied?       */
    bool                      synthesized;       /* compiler-synthesized?      */
    iii_phase_step_kind_t     step_kind;
    uint64_t                  body_hash;         /* identity of emitted code   */
    uint32_t                  invocation_count;  /* SRPA observation           */
} iii_phase_lowering_t;

typedef struct iii_phase_cycle {
    uint64_t                  cycle_id;          /* global identity            */
    char                      name[64];
    iii_phase_set_t           declared_phases;   /* @ring(...) annotation      */
    iii_phase_set_t           ghost_phases;      /* @ghost(...) annotation     */
    bool                      candidate_for_promotion;
    bool                      sealed;            /* registration finalized     */
    iii_phase_lowering_t      lowerings[III_PHASE_MAX_LOWERINGS];
    unsigned                  lowering_count;
    /* Predictive specialization */
    iii_phase_ring_t          specialized_ring;  /* III_RING_COUNT = unspec   */
    uint64_t                  total_invocations;
} iii_phase_cycle_t;

typedef struct iii_phase_runtime iii_phase_runtime_t;

/* Module lifecycle */
iii_phase_runtime_t *iii_phase_runtime_create(void);
void iii_phase_runtime_destroy(iii_phase_runtime_t *rt);

/* Cycle registration */
iii_phase_cycle_t *iii_phase_runtime_register_cycle(iii_phase_runtime_t *rt,
                                                   const char        *name,
                                                   iii_phase_set_t    phases);

/* Add an explicit body for one ring */
bool iii_phase_cycle_add_body(iii_phase_cycle_t *c,
                              iii_phase_ring_t   ring,
                              uint64_t           body_hash,
                              iii_phase_step_kind_t step_kind);

/* Mark ghost rings */
bool iii_phase_cycle_mark_ghost(iii_phase_cycle_t *c, iii_phase_set_t ghosts);

/* Mark candidate-for-promotion */
void iii_phase_cycle_mark_candidate(iii_phase_cycle_t *c);

/* Synthesize the missing lowerings via cross-ring constructors.  Returns the
 * number of newly-synthesized lowerings, or -1 on error (untypable). */
int iii_phase_cycle_synthesize(iii_phase_cycle_t *c);

/* Seal the cycle — no further bodies may be added. */
bool iii_phase_cycle_seal(iii_phase_cycle_t *c);

/* Lookup */
iii_phase_lowering_t *iii_phase_cycle_lowering(iii_phase_cycle_t *c,
                                               iii_phase_ring_t   ring);

/* Validation — returns true iff the cycle is fully covered: every reachable
 * ring in declared_phases has a body or a synthesizable path. */
bool iii_phase_cycle_validate(const iii_phase_cycle_t *c);

/* ----------------------------------------------------------------------------
 * §5. Dynamic phase promotion.
 *
 * Rate cap: at most XII_PHASE_PROMOTE_RATE = 4 promotions per chronos-tick.
 * ---------------------------------------------------------------------------- */

#define XII_PHASE_PROMOTE_RATE  4u

typedef enum iii_phase_promote_status {
    III_PHASE_PROMOTE_OK                   = 0,
    III_PHASE_PROMOTE_ERR_NOT_CANDIDATE    = 1,
    III_PHASE_PROMOTE_ERR_HEXAD_REJECT     = 2,
    III_PHASE_PROMOTE_ERR_TRINITY_REJECT   = 3,
    III_PHASE_PROMOTE_ERR_COHERENCE        = 4,
    III_PHASE_PROMOTE_ERR_RATE_CAP         = 5,
    III_PHASE_PROMOTE_ERR_ALREADY_AT_RING  = 6,
    III_PHASE_PROMOTE_ERR_INVALID          = 7
} iii_phase_promote_status_t;

const char *iii_phase_promote_status_name(iii_phase_promote_status_t s);

typedef struct iii_phase_promote_request {
    iii_phase_cycle_t         *cycle;
    iii_phase_ring_t           target_ring;
    /* Catalyst observations */
    bool                       hot;
    uint32_t                   invocation_frequency;
    /* Hexad / Trinity / coherence checkpoint values */
    bool                       hexad_admissible_at_target;
    bool                       trinity_discharged;
    uint16_t                   coherence_q12;
    uint16_t                   coherence_floor_q12;
} iii_phase_promote_request_t;

iii_phase_promote_status_t iii_phase_runtime_promote(iii_phase_runtime_t *rt,
                                                    const iii_phase_promote_request_t *req);

/* Demote (inverse of a previous promotion) — replays the witness and restores
 * the prior phase set. */
iii_phase_promote_status_t iii_phase_runtime_demote(iii_phase_runtime_t *rt,
                                                   iii_phase_cycle_t   *cycle,
                                                   iii_phase_ring_t     ring_to_remove);

/* Begin a new chronos-tick — resets the per-tick rate counter. */
void iii_phase_runtime_tick(iii_phase_runtime_t *rt);

uint32_t iii_phase_runtime_promote_count_this_tick(const iii_phase_runtime_t *rt);

/* ----------------------------------------------------------------------------
 * §6. Epistemic phases (phase.current()).
 * ---------------------------------------------------------------------------- */

void iii_phase_runtime_set_current(iii_phase_runtime_t *rt, iii_phase_ring_t r);
iii_phase_ring_t iii_phase_runtime_current(const iii_phase_runtime_t *rt);

/* ----------------------------------------------------------------------------
 * §7. Ghost phases.
 * ---------------------------------------------------------------------------- */

typedef struct iii_phase_ghost_witness {
    uint64_t                  cycle_id;
    iii_phase_ring_t          ring;
    iii_phase_step_kind_t     step_kind;
    uint8_t                   predecessor_mhash[32];
    uint8_t                   ghost_mhash[32];
} iii_phase_ghost_witness_t;

/* Execute a cycle in ghost mode at the given ring — emits a full witness with
 * no real privileged work.  Caller supplies the predecessor mhash; the runtime
 * computes and returns the ghost mhash via SHA-256 of the canonical encoding. */
bool iii_phase_runtime_ghost_observe(iii_phase_runtime_t          *rt,
                                     iii_phase_cycle_t            *cycle,
                                     iii_phase_ring_t              ring,
                                     const uint8_t                 predecessor_mhash[32],
                                     iii_phase_ghost_witness_t    *out_witness);

/* ----------------------------------------------------------------------------
 * §8. Predictive phase specialization (PIP for rings).
 * ---------------------------------------------------------------------------- */

typedef enum iii_phase_specialize_status {
    III_PHASE_SPECIALIZE_OK                = 0,
    III_PHASE_SPECIALIZE_ERR_NO_HOT_RING   = 1,
    III_PHASE_SPECIALIZE_ERR_INVALID       = 2,
    III_PHASE_SPECIALIZE_ALREADY           = 3
} iii_phase_specialize_status_t;

/* Update SRPA observations: record one invocation at the given ring. */
void iii_phase_runtime_observe_invocation(iii_phase_runtime_t *rt,
                                          iii_phase_cycle_t   *cycle,
                                          iii_phase_ring_t     ring);

/* Decide which ring (if any) is hot enough to specialize.  Returns true and
 * writes the chosen ring iff specialization is recommended. */
bool iii_phase_cycle_hottest_ring(const iii_phase_cycle_t *cycle,
                                  iii_phase_ring_t        *out_ring);

/* Apply specialization (PIP_SPECIALIZE witness emitted). */
iii_phase_specialize_status_t iii_phase_runtime_specialize(iii_phase_runtime_t *rt,
                                                           iii_phase_cycle_t   *cycle,
                                                           iii_phase_ring_t     ring);

/* Reverse a prior specialization. */
iii_phase_specialize_status_t iii_phase_runtime_despecialize(iii_phase_runtime_t *rt,
                                                             iii_phase_cycle_t   *cycle);

/* ----------------------------------------------------------------------------
 * Witness emission interface (used by all the above).
 * ---------------------------------------------------------------------------- */

typedef struct iii_phase_witness {
    uint64_t                  seq;             /* monotonic per-runtime       */
    uint64_t                  cycle_id;
    iii_phase_ring_t          ring;
    iii_phase_step_kind_t     step_kind;
    uint8_t                   predecessor_mhash[32];
    uint8_t                   mhash[32];       /* SHA-256 of canonical bytes  */
} iii_phase_witness_t;

uint64_t iii_phase_runtime_witness_count(const iii_phase_runtime_t *rt);
bool     iii_phase_runtime_witness_at(const iii_phase_runtime_t *rt,
                                      uint64_t idx,
                                      iii_phase_witness_t *out);

/* ----------------------------------------------------------------------------
 * R1.A7 — Closure identity hash.  Computed at module init from the canonical
 * byte form of this header + all source files; exposed for closure-manifest
 * embedding. */
extern const uint8_t III_PHASES_R1_A7[32];

/* ----------------------------------------------------------------------------
 * Errors
 * ---------------------------------------------------------------------------- */
typedef enum iii_phase_err {
    III_PHASE_OK                            =   0,
    III_PHASE_E_TYPE_RING_001               = 100, /* no marshalling constructor */
    III_PHASE_E_PANIC_GLYPH_DRIFT           = 101,
    III_PHASE_E_RUNTIME_MARSHALL_001        = 102, /* coherence below threshold */
    III_PHASE_E_INVARIANT                   = 103,
    III_PHASE_E_UNDECLARED_RING             = 104,
    III_PHASE_E_SEALED                      = 105,
    III_PHASE_E_RATE_CAP                    = 106,
    III_PHASE_E_OOM                         = 107
} iii_phase_err_t;

const char *iii_phase_err_name(iii_phase_err_t e);

#ifdef __cplusplus
}
#endif

#endif /* III_PHASES_H */
