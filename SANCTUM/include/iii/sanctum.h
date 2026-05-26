/* ============================================================================
 * III-SANCTUM — Ring -2 Discipline
 * Document: III-SANCTUM.md  (Doc-ID A8, R1.A8)
 *
 * The Sanctum is the only Ring -2 surface III exposes.  Exactly 10 sealed
 * call slots (slot 0 = INVALID guard; slots 1..9 functional).  Every entry
 * is the 8-step Sealed-Cycle Box: intent mint → trampoline (IBPB+VERW+SSBD)
 * → PKRU rewrite → dispatch → body → exit.  Every call is Trinity-Gate
 * admitted (intent × cap × causality × sanctum-state).
 *
 * This module owns:
 *   §1 — the 10 sealed slots and their step kinds
 *   §2 — the 8-step box and the entry judgment
 *   §3 — Trinity-Gate prerequisites
 *   §4 — DRTM relaunch (the sovereign reset)
 *   §5 — the live Sanctum data manifold (Phantom NVRAM, quote chain,
 *        Phoenix bookmarks, frames, epoch+VDF, compiler closure root,
 *        denied-quote/policy state) + pattern-recognition primitives
 *   §5.5 — predictive specialization (PIP/SRPA hot-path)
 *   §8 — Catalyst extension pathway (rejected unless full preconditions)
 * ============================================================================
 */
#ifndef III_SANCTUM_H
#define III_SANCTUM_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ----------------------------------------------------------------------------
 * §1 — The 10 sealed-call slots.  Adding an 11th requires a header bump and
 * a constitutional amendment; XII_SANCTUM_SEAL_COUNT is locked at 10.
 * ---------------------------------------------------------------------------- */
#define XII_SANCTUM_SEAL_COUNT  10u

typedef enum iii_sanctum_seal {
    III_SEAL_INVALID            = 0,    /* §1.1 — structural guard */
    III_SEAL_DRTM_RELAUNCH      = 1,
    III_SEAL_PFS_VAR_SET        = 2,
    III_SEAL_PFS_DENY_QUOTE     = 3,
    III_SEAL_CRCC_KEY_EXPORT    = 4,
    III_SEAL_PHOENIX_EMERGENCY  = 5,
    III_SEAL_CHRONOS_SET_EPOCH  = 6,
    III_SEAL_COMPROMISE_QUOTE   = 7,
    III_SEAL_PHOENIX_BOOKMARK   = 8,
    III_SEAL_COMPILE_MODULE     = 9
} iii_sanctum_seal_t;

const char *iii_sanctum_seal_name(iii_sanctum_seal_t s);

/* §1 — witness step kinds emitted on each sealed call's lifecycle. */
typedef enum iii_sanctum_step_kind {
    XII_STEP_KIND_SANCTUM_INVALID_REJECT     = 0x0080,
    XII_STEP_KIND_DRTM_RELAUNCH              = 0x0081,
    XII_STEP_KIND_PFS_VAR_SET                = 0x0082,
    XII_STEP_KIND_PFS_DENY_QUOTE             = 0x0083,
    XII_STEP_KIND_CRCC_KEY_EXPORT            = 0x0084,
    XII_STEP_KIND_PHOENIX_EMERGENCY          = 0x0085,
    XII_STEP_KIND_CHRONOS_SET_EPOCH          = 0x0086,
    XII_STEP_KIND_COMPROMISE_QUOTE           = 0x0087,
    XII_STEP_KIND_PHOENIX_BOOKMARK           = 0x0088,
    XII_STEP_KIND_SANCTUM_COMPILE_MODULE     = 0x0089,

    /* Lifecycle of every entry */
    XII_STEP_KIND_SANCTUM_INTENT_MINT        = 0x008A,
    XII_STEP_KIND_SANCTUM_GATE_ENTER         = 0x008B,
    XII_STEP_KIND_SANCTUM_PKRU_REWRITE       = 0x008C,
    XII_STEP_KIND_SANCTUM_DISPATCH           = 0x008D,
    XII_STEP_KIND_SANCTUM_BODY               = 0x008E,
    XII_STEP_KIND_SANCTUM_EXIT               = 0x008F,
    XII_STEP_KIND_SANCTUM_TRINITY_REJECT     = 0x0090,

    /* Specialization */
    XII_STEP_KIND_SANCTUM_SPECIALIZE         = 0x0091,
    XII_STEP_KIND_SANCTUM_DESPECIALIZE       = 0x0092
} iii_sanctum_step_kind_t;

const char *iii_sanctum_step_kind_name(iii_sanctum_step_kind_t k);

/* ----------------------------------------------------------------------------
 * §2 — the Sealed-Cycle Box.
 *
 * Each entry executes the 8-step box deterministically.  Step 4 is the
 * trampoline (hand-written x86-64 in the real substrate); we model it as a
 * sequence of flags the caller can verify executed.
 * ---------------------------------------------------------------------------- */

typedef enum iii_sanctum_box_step {
    III_BOX_STEP_NONE             = 0,
    III_BOX_STEP_INTENT_MINT      = 1,
    III_BOX_STEP_LOAD_INTENT      = 2,
    III_BOX_STEP_INTENT_WITNESS   = 3,
    III_BOX_STEP_TRAMPOLINE       = 4,    /* IBPB+VERW+SSBD+RSP-swap+GPR-save */
    III_BOX_STEP_PKRU_REWRITE     = 5,
    III_BOX_STEP_DISPATCH         = 6,
    III_BOX_STEP_BODY             = 7,
    III_BOX_STEP_EXIT             = 8,
    III_BOX_STEP_COUNT            = 9
} iii_sanctum_box_step_t;

const char *iii_sanctum_box_step_name(iii_sanctum_box_step_t s);

/* §2.3 — the four hardenings the trampoline performs. */
typedef struct iii_sanctum_hardening {
    bool ibpb_executed;
    bool verw_executed;
    bool ssbd_executed;
    bool rsp_swapped;
    bool gpr_saved;
} iii_sanctum_hardening_t;

/* §2 — the 64-byte intent token. */
typedef struct iii_sanctum_intent {
    uint8_t  operator_consent_mhash[32];
    uint64_t cap_id;
    uint8_t  causality_witness[16];
    uint64_t sanctum_frame_id;
} iii_sanctum_intent_t;

/* ----------------------------------------------------------------------------
 * §3 — Trinity-Gate prerequisites.
 *
 * The Trinity admission is a 4-conjunct check.  All must pass; on rejection
 * the call is not dispatched and the sanctum frame unwinds via SID inverse.
 * ---------------------------------------------------------------------------- */

typedef struct iii_trinity_admit_in {
    iii_sanctum_seal_t       seal;
    bool                     intent_valid;
    bool                     cap_valid;
    bool                     causality_valid;
    bool                     sanctum_state_valid;
    iii_sanctum_intent_t     intent;
    /* Optional convergence-point computation hint */
    uint64_t                 convergence_hint;
} iii_trinity_admit_in_t;

typedef struct iii_trinity_admit_out {
    bool      admitted;
    bool      rejected_intent;
    bool      rejected_cap;
    bool      rejected_causality;
    bool      rejected_sanctum_state;
    uint64_t  convergence_point;     /* derived from the four conjuncts */
} iii_trinity_admit_out_t;

void iii_trinity_admit(const iii_trinity_admit_in_t *in,
                       iii_trinity_admit_out_t      *out);

/* ----------------------------------------------------------------------------
 * §4 — DRTM-relaunch quote (312 bytes per spec §4 step 5).
 *
 *  silicon_fingerprint[32] || R1[32] || cycle_table_mhash[32] ||
 *  hexad_bitmap_mhash[32]  || observatory_mhash[32] ||
 *  pfs_mhash[32]           || federation_member_list_mhash[32] ||
 *  prior_quote_mhash[32]   || epoch (8 LE) || pad[32]
 *  → total 312 bytes
 * ---------------------------------------------------------------------------- */
#define III_DRTM_QUOTE_BYTES  312u

typedef struct iii_drtm_quote {
    uint8_t  silicon_fingerprint[32];      /* 0x000 */
    uint8_t  spec_root_R1[32];             /* 0x020 */
    uint8_t  cycle_table_mhash[32];        /* 0x040 */
    uint8_t  hexad_bitmap_mhash[32];       /* 0x060 */
    uint8_t  observatory_snapshot_mhash[32];/*0x080 */
    uint8_t  phantom_nvram_mhash[32];      /* 0x0A0 */
    uint8_t  federation_members_mhash[32]; /* 0x0C0 */
    uint8_t  prior_quote_mhash[32];        /* 0x0E0 */
    uint64_t epoch;                        /* 0x100 */
    uint8_t  pad[48];                      /* 0x108..0x137 — total = 312 */
} iii_drtm_quote_t;

/* ----------------------------------------------------------------------------
 * §5 — The data manifold.
 *
 * Phantom NVRAM (PFS): file-backed key/value store.  Keys are bounded
 * length; values are bounded length.  Sealed-only access — every read or
 * write is witnessed.
 * ---------------------------------------------------------------------------- */

#define III_PFS_KEY_MAX     64u
#define III_PFS_VALUE_MAX   256u
#define III_PFS_ENTRIES_MAX 256u

typedef struct iii_pfs_entry {
    char     key[III_PFS_KEY_MAX];
    uint8_t  value[III_PFS_VALUE_MAX];
    size_t   value_len;
    bool     denied;          /* §1.1 slot 3 — quote/policy-denied entries */
} iii_pfs_entry_t;

/* Phoenix bookmark (§1 slot 5/8). */
#define III_PHOENIX_MAX_BOOKMARKS  16u
#define III_PHOENIX_PAYLOAD_MAX    1024u

typedef struct iii_phoenix_bookmark {
    uint64_t bookmark_id;
    uint64_t epoch;
    bool     emergency;
    uint8_t  payload[III_PHOENIX_PAYLOAD_MAX];
    size_t   payload_len;
    uint8_t  mhash[32];                /* sealed identity of the bookmark */
} iii_phoenix_bookmark_t;

/* §5 — runtime handle. */
typedef struct iii_sanctum_runtime iii_sanctum_runtime_t;

iii_sanctum_runtime_t *iii_sanctum_runtime_create(void);
void iii_sanctum_runtime_destroy(iii_sanctum_runtime_t *rt);

/* Inject the silicon fingerprint (32-byte hash of CPUID + DMI per the
 * PORTABILITY HAL).  Userland sanctum runtimes compute a deterministic
 * default; Ring-1/-2 deployments override here from the hardware. */
void iii_sanctum_runtime_set_fingerprint(iii_sanctum_runtime_t *rt,
                                         const uint8_t          fingerprint[32]);

/* §1.2 — bind a sealed-call slot's body.  Each slot binds exactly once.
 * Returns true on success, false on collision or slot==INVALID. */
typedef int (*iii_sanctum_seal_fn)(iii_sanctum_runtime_t *rt,
                                   const void            *args_in,
                                   void                  *args_out,
                                   void                  *user);

bool iii_sanctum_runtime_bind_seal(iii_sanctum_runtime_t  *rt,
                                   iii_sanctum_seal_t      seal,
                                   iii_sanctum_seal_fn     fn,
                                   void                   *user);

/* ----------------------------------------------------------------------------
 * §2 / §3 — sealed-call dispatch.  Returns III_SANCTUM_OK on success or one
 * of the III_SANCTUM_E_* values on rejection.
 * ---------------------------------------------------------------------------- */

typedef enum iii_sanctum_status {
    III_SANCTUM_OK                       = 0,
    III_SANCTUM_E_INVALID_SEAL           = 1,
    III_SANCTUM_E_TRINITY_REJECT         = 2,
    III_SANCTUM_E_NOT_BOUND              = 3,
    III_SANCTUM_E_BODY_FAILED            = 4,
    III_SANCTUM_E_FRAME_EXHAUSTED        = 5,
    III_SANCTUM_E_PFS_FULL               = 6,
    III_SANCTUM_E_PFS_DENIED             = 7,
    III_SANCTUM_E_PFS_NOT_FOUND          = 8,
    III_SANCTUM_E_PHOENIX_FULL           = 9,
    III_SANCTUM_E_RATE_CAP               = 10,
    III_SANCTUM_E_INVALID                = 11
} iii_sanctum_status_t;

const char *iii_sanctum_status_name(iii_sanctum_status_t s);

typedef struct iii_sanctum_call_request {
    iii_sanctum_seal_t           seal;
    iii_sanctum_intent_t         intent;

    /* Trinity inputs the caller has already evaluated. */
    bool                         intent_valid;
    bool                         cap_valid;
    bool                         causality_valid;
    bool                         sanctum_state_valid;

    /* Body payload (interpretation depends on the seal). */
    const void                  *args_in;
    void                        *args_out;
} iii_sanctum_call_request_t;

typedef struct iii_sanctum_call_trace {
    /* Records which of the 8 box steps actually executed (so the audit can
     * verify `C-SAN-2`).  Indexed by iii_sanctum_box_step_t. */
    bool                         executed[III_BOX_STEP_COUNT];
    iii_sanctum_hardening_t      hardening;
    bool                         specialized_path;
    iii_trinity_admit_out_t      trinity;
} iii_sanctum_call_trace_t;

iii_sanctum_status_t iii_sanctum_call(iii_sanctum_runtime_t            *rt,
                                      const iii_sanctum_call_request_t *req,
                                      iii_sanctum_call_trace_t         *out_trace);

uint64_t iii_sanctum_runtime_call_count(const iii_sanctum_runtime_t *rt);

/* ----------------------------------------------------------------------------
 * §1 slot 1 — drtm_relaunch.  Builds a fresh quote and rotates the epoch.
 * ---------------------------------------------------------------------------- */

iii_sanctum_status_t iii_sanctum_drtm_relaunch(iii_sanctum_runtime_t *rt,
                                               bool                   promote_compiler,
                                               iii_drtm_quote_t      *out_quote);

uint64_t iii_sanctum_runtime_epoch(const iii_sanctum_runtime_t *rt);
size_t   iii_sanctum_runtime_quote_count(const iii_sanctum_runtime_t *rt);
bool     iii_sanctum_runtime_quote_at(const iii_sanctum_runtime_t *rt,
                                      size_t idx,
                                      iii_drtm_quote_t *out);

/* ----------------------------------------------------------------------------
 * §1 slot 2/3 — Phantom NVRAM (PFS).
 * ---------------------------------------------------------------------------- */

iii_sanctum_status_t iii_sanctum_pfs_set(iii_sanctum_runtime_t *rt,
                                         const char            *key,
                                         const uint8_t         *value,
                                         size_t                 value_len);
iii_sanctum_status_t iii_sanctum_pfs_get(iii_sanctum_runtime_t *rt,
                                         const char            *key,
                                         uint8_t               *out_value,
                                         size_t                 cap,
                                         size_t                *out_len);
iii_sanctum_status_t iii_sanctum_pfs_deny(iii_sanctum_runtime_t *rt,
                                          const char            *key);

size_t iii_sanctum_runtime_pfs_count(const iii_sanctum_runtime_t *rt);

/* ----------------------------------------------------------------------------
 * §1 slot 5/8 — Phoenix bookmarks.
 * ---------------------------------------------------------------------------- */

iii_sanctum_status_t iii_sanctum_phoenix_save(iii_sanctum_runtime_t *rt,
                                              bool                   emergency,
                                              const uint8_t         *payload,
                                              size_t                 payload_len,
                                              uint64_t              *out_id);

iii_sanctum_status_t iii_sanctum_phoenix_restore(iii_sanctum_runtime_t *rt,
                                                 uint64_t               id,
                                                 iii_phoenix_bookmark_t *out);

size_t iii_sanctum_runtime_phoenix_count(const iii_sanctum_runtime_t *rt);

/* ----------------------------------------------------------------------------
 * §1 slot 4 — CRCC key export (HKDF from the master sub-key).
 * ---------------------------------------------------------------------------- */

iii_sanctum_status_t iii_sanctum_crcc_export(iii_sanctum_runtime_t *rt,
                                             uint64_t               cycle_root_id,
                                             uint8_t                out_key[32]);

/* ----------------------------------------------------------------------------
 * §1 slot 6 — chronos epoch advance (separately from a full relaunch).
 * ---------------------------------------------------------------------------- */

iii_sanctum_status_t iii_sanctum_chronos_advance(iii_sanctum_runtime_t *rt);

/* ----------------------------------------------------------------------------
 * §1 slot 7 — compromise quote (tier-gated; constitutional).
 * ---------------------------------------------------------------------------- */

iii_sanctum_status_t iii_sanctum_compromise_quote(iii_sanctum_runtime_t *rt,
                                                  uint16_t               tier,
                                                  const uint8_t         *evidence,
                                                  size_t                 evidence_len,
                                                  iii_drtm_quote_t      *out_quote);

/* ----------------------------------------------------------------------------
 * §5.5 — Predictive sanctum specialization.  When a particular seal is hot,
 * the caller marks it as specialised; subsequent calls take the fast path.
 * ---------------------------------------------------------------------------- */

iii_sanctum_status_t iii_sanctum_specialize(iii_sanctum_runtime_t *rt,
                                            iii_sanctum_seal_t     seal);

iii_sanctum_status_t iii_sanctum_despecialize(iii_sanctum_runtime_t *rt,
                                              iii_sanctum_seal_t     seal);

bool iii_sanctum_is_specialized(const iii_sanctum_runtime_t *rt,
                                iii_sanctum_seal_t           seal);

/* ----------------------------------------------------------------------------
 * §7 — Closure identity.
 * ---------------------------------------------------------------------------- */
extern const uint8_t III_SANCTUM_R1_A8[32];

#ifdef __cplusplus
}
#endif

#endif /* III_SANCTUM_H */
