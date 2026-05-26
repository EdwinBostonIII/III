/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\link.h
 *
 * III Stage-0 Linker — public interface.
 *
 * Responsibility:
 *   - Verify closure-pinned imports: every `use X @closure(0xMHASH)`
 *     is checked against the registered closure_root of module X
 *     (where registered means a manifest emitted by a previous
 *     iiis-0 invocation in this build session, or a sealed manifest
 *     from a prior build).
 *   - Symbol dedup across linked TUs (handled by host ld; III link
 *     stage records III-level metadata).
 *   - Ceiling-manifest embed: writes the SCBA bitarray (per ceiling.c)
 *     into the substrate image's `.xii_ccmanifest` section.
 *
 * Strict NIH per ADR-021.  No third-party linker; we wrap host `ld`
 * via system() in emit.c and use this module to verify III-level
 * invariants before that.
 *
 * ─── DEEPENINGS (all citations local to this header) ─────────────
 *  D1. Merkle linkage closure invariant:
 *        closure_mhash = SHA-256( "III_LINK_v1" || local_mhash ||
 *                                 sorted(direct_dep_closure_mhashes) )
 *      Recursive but memoized (each module's closure computed once).
 *  D2. Tarjan 1972 SCC over the import graph: cyclic imports are
 *      REFUSED with a cycle witness (the SCC vertex list).  See
 *      Tarjan, "Depth-First Search and Linear Graph Algorithms",
 *      SIAM J. Comput. 1(2), 1972.
 *  D3. Two-phase resolution: (a) parse all module headers and
 *      register; (b) resolve.  Phase boundary is hard — no
 *      resolution begins until phase (a) succeeds for ALL modules.
 *  D4. Transactional manifest: built into a temp buffer; only
 *      published on success.  On any error the published manifest
 *      is empty, never partial.
 *  D5. Sorted manifest entries by (module_mhash lex, symbol_name
 *      lex) — deterministic byte stream.
 *  D6. Manifest format (V1 = 0x494C4D31 'ILM1'):
 *        offset  size  field
 *          0      4    magic         (LE u32 = III_LINK_MANIFEST_V1)
 *          4      4    version       (LE u32 = 1)
 *          8      4    entry_count   (LE u32)
 *         12      4    reserved      (LE u32 = 0)
 *         16     ...   entries[]
 *        eof-32  32    footer mhash  (SHA-256, see below)
 *      Each entry:
 *          0     32    module_mhash  (defining module local_mhash)
 *         32      4    sym_len       (LE u32, bytes; ≤ 255)
 *         36     N     sym_bytes     (no NUL terminator)
 *       36+N      8    addr_token    (LE u64)
 *      Footer = SHA-256( "III_LINK_v1\0footer" || header || entries ).
 *  D7. Symbol-collision detection: if the same exported symbol is
 *      defined in two modules reachable in any module's closure,
 *      the link is REFUSED and a collision witness (both module
 *      mhashes + the symbol name) is emitted.
 *  D8. Visibility enforcement: each export has a visibility in
 *      iii_visibility_t.  PRIVATE exports REFUSE cross-module
 *      imports; MODULE exports REFUSE cross-package imports
 *      (package = top-level qualified-name segment); PUBLIC
 *      exports are always importable; FEDERATED exports are
 *      importable iff the importer is also FEDERATED.
 *  D9. Pin-check (the "closure-pinned" property): if a re-link
 *      presents the same modules with the same local mhashes but
 *      a different transitive closure (added/removed transitive
 *      dep), the link is REFUSED.
 *  D10. Audit sink: optional callback fired on every successful
 *       resolution (importer_mhash, symbol, definer_mhash, addr).
 *  D11. Self-check API: iii_link_verify_manifest() re-derives the
 *       closure mhash chain assertions and the footer over the
 *       byte stream — gates a golden-bytes invariant.
 *  D12. SHA-256: NIH FIPS-180-4; domain-tagged "III_LINK_v1".
 *  D13. Stable error codes: III_LINK_E_*  (numeric values are
 *       part of the ABI; never reused).
 *  D14. Lock-and-seal: iii_link_seal() flips the state to
 *       read-only.  Subsequent registration/finalize calls return
 *       III_LINK_E_SEALED.
 *  D15. Spec citations are inlined on every helper.
 */

#ifndef III_BOOT_LINK_H
#define III_BOOT_LINK_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "ast.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ─── D13: Stable error codes (ABI) ──────────────────────────────── */
#define III_LINK_OK                       0
#define III_LINK_E_NULL_ARG               1
#define III_LINK_E_CLOSURE_MISMATCH       2
#define III_LINK_E_UNKNOWN_MODULE         3
#define III_LINK_E_OOM                    4
#define III_LINK_E_CYCLE                  5   /* D2 */
#define III_LINK_E_COLLISION              6   /* D7 */
#define III_LINK_E_VISIBILITY             7   /* D8 */
#define III_LINK_E_PIN_MISMATCH           8   /* D9 */
#define III_LINK_E_UNRESOLVED             9
#define III_LINK_E_SEALED                10   /* D14 */
#define III_LINK_E_PHASE                 11   /* D3 */
#define III_LINK_E_BAD_MANIFEST          12   /* D11 */
#define III_LINK_E_TOO_MANY              13
#define III_LINK_E_INTERNAL              99

/* ─── D6: Manifest constants ─────────────────────────────────────── */
#define III_LINK_MANIFEST_V1     0x494C4D31u  /* 'ILM1' little-endian */
#define III_LINK_MANIFEST_VER    1u
#define III_LINK_DOMAIN_TAG      "III_LINK_v1"
#define III_LINK_MAX_SYM_LEN     255u
#define III_LINK_HEADER_BYTES    16u
#define III_LINK_FOOTER_BYTES    32u

/* ─── D8: Visibility lattice ─────────────────────────────────────── */
typedef enum {
    III_VIS_PRIVATE   = 0,   /* same module only */
    III_VIS_MODULE    = 1,   /* same package only */
    III_VIS_PUBLIC    = 2,   /* anyone */
    III_VIS_FEDERATED = 3    /* federated importers only */
} iii_visibility_t;

/* ─── Error record ───────────────────────────────────────────────── */
typedef struct {
    int          code;
    const char  *message;
    uint32_t     use_node;     /* AST node index when relevant */
    /* witness payload: meaning depends on `code`:
     *   E_CYCLE      : count = SCC size, mhash = first member local_mhash
     *   E_COLLISION  : count = 2,        mhash = first colliding module
     *   E_VISIBILITY : count = visibility, mhash = definer local_mhash
     *   E_PIN_MISMATCH: count = 0,       mhash = previous closure_mhash
     */
    uint32_t     witness_count;
    uint8_t      witness_mhash[32];
} iii_link_error_t;

/* ─── Audit sink (D10) ───────────────────────────────────────────── */
typedef void (*iii_link_audit_fn)(const uint8_t importer_mhash[32],
                                  const char   *symbol,
                                  const uint8_t definer_mhash[32],
                                  uint64_t      addr_token,
                                  void         *user_data);

/* ─── Opaque handle ──────────────────────────────────────────────── */
struct iii_link_state;
typedef struct iii_link_state iii_link_state_t;

/* ─── Lifecycle ──────────────────────────────────────────────────── */
iii_link_state_t *iii_link_create(void);
void              iii_link_destroy(iii_link_state_t *l);

/* ─── Phase (a): registration (D3) ───────────────────────────────── */

/* Original API (preserved modulo rename): register a module by name
 * and a pre-computed closure_root.  Useful for the legacy
 * "manifest-from-prior-build" path.  Sets local_mhash := closure_root
 * and dep_count := 0; the resulting closure_mhash equals closure_root.
 */
int iii_link_register_module(iii_link_state_t *l,
                             const char       *qualified_name,
                             const uint8_t     closure_root[32]);

/* Extended API: register a module with its local_mhash, direct
 * dependencies (by qualified name; need not be registered yet — D3),
 * and exported symbols with visibility.  Cite: D1, D3, D7, D8.
 *
 * Ownership: all const pointers are copied internally. */
int iii_link_register_module_ex(iii_link_state_t *l,
                                const char       *qualified_name,
                                const uint8_t     local_mhash[32],
                                uint32_t          dep_count,
                                const char *const dep_qualified_names[],
                                uint32_t          export_count,
                                const char *const export_symbols[],
                                const iii_visibility_t *export_visibility,
                                const uint64_t   *export_addr_tokens);

/* ─── Phase (b): finalize / resolve (D3) ─────────────────────────── */

/* Run Tarjan SCC (D2), compute Merkle linkage closure mhashes (D1),
 * detect collisions (D7), enforce visibility on imports recorded via
 * verify_imports (D8), check pin (D9), and build the manifest into
 * a temp buffer (D4), sorted (D5).  On any failure the manifest is
 * left empty and an error is recorded.
 */
int iii_link_finalize(iii_link_state_t *l);

/* ─── Verify @closure(...) pins on AST use-decls ─────────────────── */
int iii_link_verify_imports(iii_link_state_t *l, iii_ast_t *ast);

/* ─── Pin-check (D9) ─────────────────────────────────────────────── */
/* Compare a module's freshly-computed closure_mhash against a value
 * persisted from a previous link.  Returns III_LINK_E_PIN_MISMATCH
 * if and only if the local_mhash matches but the closure differs. */
int iii_link_pin_check(const iii_link_state_t *l,
                       const char *qualified_name,
                       const uint8_t prior_local[32],
                       const uint8_t prior_closure[32]);

/* ─── Manifest (D4, D5, D6) ──────────────────────────────────────── */
/* On success returns III_LINK_OK and sets *out_buf / *out_len to a
 * pointer owned by `l` (valid until destroy or another finalize). */
int iii_link_get_manifest(const iii_link_state_t *l,
                          const uint8_t **out_buf,
                          size_t         *out_len);

/* Self-check: re-parses header, recomputes footer, validates sort
 * order, magic, version, entry framing.  Pure (no state). (D11) */
int iii_link_verify_manifest(const uint8_t *buf, size_t len);

/* ─── Audit (D10) ────────────────────────────────────────────────── */
void iii_link_set_audit_sink(iii_link_state_t *l,
                             iii_link_audit_fn fn,
                             void *user_data);

/* ─── Lock-and-seal (D14) ────────────────────────────────────────── */
int  iii_link_seal(iii_link_state_t *l);
bool iii_link_is_sealed(const iii_link_state_t *l);

/* ─── Errors ─────────────────────────────────────────────────────── */
uint32_t iii_link_error_count(const iii_link_state_t *l);
void     iii_link_error_at  (const iii_link_state_t *l,
                             uint32_t i,
                             iii_link_error_t *out);

/* ─── Closure mhash query ────────────────────────────────────────── */
int iii_link_get_closure_mhash(const iii_link_state_t *l,
                               const char *qualified_name,
                               uint8_t out[32]);

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_LINK_H */
