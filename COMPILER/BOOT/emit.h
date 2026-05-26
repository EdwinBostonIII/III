/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\emit.h
 *
 * III Stage-0 Binary Emitter — public interface.
 *
 * Drives the host gcc + ld to assemble + link the codegen's `.s` /
 * `.iii` output into one of:
 *     - PE/EXE, PE/DLL, PE/SYS  (Windows, MS x64 ABI)
 *     - ELF/EXE                 (Linux, SysV ABI)
 *     - RAW-BIN                 (bare-metal, freestanding)
 *     - SANCTUM-OBJECT          (sealed `.xii_sanctum.text` blob at
 *                                a pinned VMA, generated linker script)
 *
 * Stage-0 host tools per ADR-021 §Boundaries: gcc, ld, dlltool,
 * objcopy, objdump.  No third-party deps.  Strict NIH on the III
 * side — libc only.  See SPEC.XII §Reproducibility.
 *
 * ─── DEEPENINGS (citations local to this header) ─────────────────
 *  D1.  SOURCE_DATE_EPOCH=0 forced into every gcc/ld child env.
 *       cite: https://reproducible-builds.org/specs/source-date-epoch/
 *  D2.  --build-id=none on every ld invocation (and as
 *       -Wl,--build-id=none through gcc-as-driver).
 *       cite: ld(1) "--build-id"; reproducible-builds.org
 *  D3.  -ffile-prefix-map=$cwd=. on gcc.
 *       cite: gcc(1) "-ffile-prefix-map";
 *             https://reproducible-builds.org/docs/build-path/
 *  D4.  -frandom-seed=$basename on gcc — deterministic per-TU.
 *       cite: gcc(1) "-frandom-seed"
 *  D5.  LC_ALL=C, TZ=UTC0, LANG=C in every child env.
 *       cite: POSIX.1-2017 §7.3 (Locale), §8.3 (TZ);
 *             https://reproducible-builds.org/docs/locales/
 *  D6.  CCACHE_DISABLE=1 in every child env.
 *       cite: ccache(1) §"CCACHE_DISABLE"
 *  D7.  Format-specific flag tables — see III_EMIT_FORMAT_* below.
 *  D8.  Output mhash: post-emission SHA-256 over the output bytes;
 *       exposed via iii_emit_get_output_mhash().
 *  D9.  Build-witness JSON sidecar `<output>.witness.json` — sorted
 *       keys, no whitespace, deterministic byte stream:
 *         {"command_line_mhash":"…","env_mhash":"…","format":"…",
 *          "gcc_version_mhash":"…","ld_version_mhash":"…",
 *          "output_mhash":"…","source_date_epoch":"0"}
 *  D10. Golden-bytes mode: iii_emit_set_expected_mhash() arms a
 *       check; iii_emit_link returns III_EMIT_E_MHASH_MISMATCH on
 *       divergence.  CI gate.
 *  D11. Argv mhash: SHA-256 of the canonical command string passed
 *       to gcc/ld; embedded in build-witness.
 *  D12. Env mhash: SHA-256 of the sorted env-var "K=V\n" stream we
 *       force on the child; embedded in build-witness.
 *  D13. NIH gcc/ld version capture: invoke `gcc --version` /
 *       `ld --version`, take first line, hash.  Embedded in witness.
 *  D14. Sanctum format: linker script generated on the fly,
 *       `.xii_sanctum.text` pinned at fixed VMA
 *       (III_EMIT_SANCTUM_VMA).  Inputs lacking the section are
 *       REFUSED (III_EMIT_E_NO_SANCTUM_SECTION).
 *  D15. Stable error codes (III_EMIT_E_*) — numeric values are
 *       part of the ABI; never reused.
 *  D16. Audit sink callback per emission (assemble + link).
 *  D17. Spec citations are inlined on every helper (in emit.c).
 *  D18. Lock-and-seal: iii_emit_seal() flips the state to
 *       read-only.  Subsequent setters return III_EMIT_E_SEALED.
 *
 * Deterministic by construction — that is the entire point.
 */
#ifndef III_BOOT_EMIT_H
#define III_BOOT_EMIT_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ─── D7: Output formats ─────────────────────────────────────────── */
typedef enum {
    III_EMIT_FORMAT_PE_EXE         = 0,
    III_EMIT_FORMAT_PE_DLL         = 1,
    III_EMIT_FORMAT_PE_SYS         = 2,
    III_EMIT_FORMAT_ELF_EXE        = 3,
    III_EMIT_FORMAT_RAW_BIN        = 4,
    III_EMIT_FORMAT_SANCTUM_OBJECT = 5
} iii_emit_format_t;

/* ─── D15: Stable error codes (ABI; never reused) ────────────────── */
#define III_EMIT_OK                       0
#define III_EMIT_E_NULL_ARG               1
#define III_EMIT_E_BAD_FORMAT             2
#define III_EMIT_E_CMD_OVERFLOW           3
#define III_EMIT_E_GCC_FAIL               4
#define III_EMIT_E_LD_FAIL                5
#define III_EMIT_E_OBJCOPY_FAIL           6
#define III_EMIT_E_IO                     7
#define III_EMIT_E_OOM                    8
#define III_EMIT_E_MHASH_MISMATCH         9   /* D10 */
#define III_EMIT_E_NO_SANCTUM_SECTION    10   /* D14 */
#define III_EMIT_E_LDSCRIPT_WRITE        11
#define III_EMIT_E_WITNESS_WRITE         12
#define III_EMIT_E_VERSION_PROBE         13
#define III_EMIT_E_SEALED                14   /* D18 */
#define III_EMIT_E_ENV                   15
#define III_EMIT_E_INTERNAL              99

/* ─── D14: Sanctum constants ─────────────────────────────────────── */
#define III_EMIT_SANCTUM_SECTION   ".xii_sanctum.text"
#define III_EMIT_SANCTUM_VMA       0xFFFF800000200000ULL

/* ─── D1: SOURCE_DATE_EPOCH literal kept verbatim per spec ───────── */
#define III_EMIT_SOURCE_DATE_EPOCH "0"

/* ─── D16: Audit sink ────────────────────────────────────────────── */
typedef enum {
    III_EMIT_PHASE_ASSEMBLE = 1,
    III_EMIT_PHASE_LINK     = 2,
    III_EMIT_PHASE_OBJCOPY  = 3,
    III_EMIT_PHASE_VERSION  = 4,
    III_EMIT_PHASE_WITNESS  = 5
} iii_emit_phase_t;

typedef void (*iii_emit_audit_fn)(iii_emit_phase_t   phase,
                                  iii_emit_format_t  fmt,
                                  const char        *command_line,
                                  int                child_status,
                                  const uint8_t      argv_mhash[32],
                                  void              *user_data);

/* ─── Lifecycle ──────────────────────────────────────────────────── */
/* The emitter has process-global state (the child env it forces on
 * gcc/ld is process-global by definition).  These calls are *not*
 * thread-safe; callers serialize.  Safe to call without any prior
 * init — implicit zero-init applies. */

void iii_emit_reset(void);   /* clear armed expected mhash + audit sink */
int  iii_emit_seal(void);    /* D18 — returns III_EMIT_OK */
bool iii_emit_is_sealed(void);

/* ─── Original public API (preserved modulo rename) ──────────────── */

/* Assemble `asm_path` to `out_obj_path` via `gcc -c`.
 * Forces D1/D2/D3/D4/D5/D6.  Returns III_EMIT_OK or III_EMIT_E_*. */
int iii_emit_assemble(const char *asm_path, const char *out_obj_path);

/* Link `obj_paths[0..obj_count)` into `out_path` per `fmt`.
 * `linker_script_or_null` overrides the format-default script.
 * For SANCTUM, the script is generated internally (D14) and the
 * argument is treated as an additional script (or NULL to use only
 * the generated one).
 *
 * Forces D1/D2/D3/D5/D6 + D7 flag table + D8 output mhash +
 * D9 witness emission + D10 mhash gate + D11/D12/D13 mhashes. */
int iii_emit_link(iii_emit_format_t  fmt,
                  const char *const *obj_paths,
                  size_t             obj_count,
                  const char        *out_path,
                  const char        *linker_script_or_null);

/* Stable, lowercase, hyphenated format names. */
const char *iii_emit_format_name(iii_emit_format_t fmt);

/* ─── Deepening API ──────────────────────────────────────────────── */

/* D8 — last successful link's output SHA-256.  Returns
 * III_EMIT_E_NULL_ARG if `out` is NULL, III_EMIT_E_INTERNAL if no
 * emission has occurred yet. */
int iii_emit_get_output_mhash(uint8_t out[32]);

/* D10 — arm an expected output mhash.  Pass NULL to disarm.
 * Subsequent successful emissions whose output mhash differs return
 * III_EMIT_E_MHASH_MISMATCH and the output file is left as-written
 * (so CI can diff it). */
int iii_emit_set_expected_mhash(const uint8_t expected_or_null[32]);

/* D9 — last successful link's witness JSON (NUL-terminated, owned
 * by the emitter, stable until the next emission). */
const char *iii_emit_get_witness_json(void);

/* D11/D12/D13 — last emission's component mhashes. */
int iii_emit_get_argv_mhash      (uint8_t out[32]);
int iii_emit_get_env_mhash       (uint8_t out[32]);
int iii_emit_get_gcc_version_mhash(uint8_t out[32]);
int iii_emit_get_ld_version_mhash (uint8_t out[32]);

/* D16 — install audit sink.  Pass NULL fn to disable. */
int iii_emit_set_audit_sink(iii_emit_audit_fn fn, void *user_data);

/* Convenience: hex-encode 32 bytes into `out[65]` (NUL-terminated). */
void iii_emit_hex32(const uint8_t in[32], char out[65]);

/* Lattice plan Step 0024 — D17 layered-seal continuity.
 *
 * Writes a 128-byte sealed binary record at `out_path` containing:
 *   bytes  [0..32)   prev_root_32        (caller-supplied closure_root)
 *   bytes  [32..64)  new_root_32         (post-this-emission closure_root)
 *   bytes  [64..96)  delta_mhash_32      (mhash domain "seal_step_NNNN" || prev || new || step_no_le_8)
 *   bytes  [96..128) mac_32              (HMAC-SHA-256(slot4_subkey, prev||new||delta||step_no))
 *
 * The chain is verifiable: given prev_root and step_no, anyone can
 * recompute delta_mhash and verify mac.  Each successful emission
 * extends the layered seal.  Step 0114's master tree_root emit
 * walks this chain end-to-end.
 *
 *   step_no                 — monotonic counter (0 = genesis)
 *   prev_root_32            — root anchor at start of step
 *   new_root_32             — root anchor at end of step
 *   slot4_subkey_32         — HMAC subkey (caller supplies; sanctus/attest::attest_get_subkey(slot=4))
 *
 * Returns III_EMIT_OK on success, III_EMIT_E_NULL_ARG on null pointer,
 * III_EMIT_E_IO on file write failure. */
int iii_emit_layered_seal(const char *out_path,
                              uint32_t step_no,
                              const uint8_t prev_root_32[32],
                              const uint8_t new_root_32[32],
                              const uint8_t slot4_subkey_32[32]);

/* Read back a layered-seal record from disk for verification. */
int iii_emit_layered_seal_read(const char *in_path,
                                   uint8_t prev_root_32[32],
                                   uint8_t new_root_32[32],
                                   uint8_t delta_mhash_32[32],
                                   uint8_t mac_32[32]);

/* Recompute delta_mhash from (step_no, prev_root, new_root) and verify
 * it matches the recorded delta_mhash; recompute MAC and verify it
 * matches.  Returns 1 if both match, 0 otherwise. */
int iii_emit_layered_seal_verify(uint32_t step_no,
                                     const uint8_t prev_root_32[32],
                                     const uint8_t new_root_32[32],
                                     const uint8_t delta_mhash_32[32],
                                     const uint8_t mac_32[32],
                                     const uint8_t slot4_subkey_32[32]);

/* Lattice plan Step 0114 — Master tree_root emit.
 *
 * Walks a sequence of layered-seal records and emits a final master
 * root.  The chain is given as an array of 128-byte records (in
 * increasing step_no order); the master root is
 *   sha256("master_tree_root" || record[0] || record[1] || ... || record[N-1]).
 *
 * Used by the build's terminal seal step to produce the final closure
 * anchor for the entire layered chain since genesis.
 *
 * Returns III_EMIT_OK on success.  out[32] receives the master root. */
int iii_emit_master_tree_root(const uint8_t *records,
                                  uint32_t      record_count,
                                  uint8_t       out_master_root_32[32]);

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_EMIT_H */
