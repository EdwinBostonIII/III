#!/usr/bin/env bash
# Build all STDLIB/iii/ modules to .o under STDLIB/build/iii/.
# Each module is compiled separately via the deployed `iiis`.
# Module dependency order is encoded explicitly for clarity.

set -euo pipefail
IFS=$'\n\t'
umask 022

# Pinned reproducibility env (matches build_iiis2.sh)
export LC_ALL=C
export LANG=C
export TZ=UTC0
export SOURCE_DATE_EPOCH=0
export CCACHE_DISABLE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STDLIB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$STDLIB_DIR/iii"
BUILD_DIR="$STDLIB_DIR/build/iii"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

# CLI parsing -- handle --clean / --help BEFORE iiis location detection so
# that `bash build_stdlib.sh --clean` works without iiis on PATH.
DO_CLEAN=0
usage() {
    cat <<'EOF' >&2
Usage: bash build_stdlib.sh [options]

With no options: compile every STDLIB/iii/ module to STDLIB/build/iii/<name>.iii.o
and aggregate into STDLIB/build/iii/libiii_native.a.

Options:
  --clean      Remove all generated artifacts under STDLIB/build/ and exit.
               Specifically:
                 STDLIB/build/iii/*.iii.o
                 STDLIB/build/iii/*.iii.o.s
                 STDLIB/build/iii/*.build.log
                 STDLIB/build/iii/libiii_native.a
                 STDLIB/build/iii/libiii_native.a.mhash
                 STDLIB/build/corpus/*  (all corpus test outputs)
  -h, --help   Show this help and exit.

Exit codes:
  0  success (or clean completed)
  N  number of modules that failed to compile (capped at 255)
  2  iiis compiler not found on PATH and no fallback present
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean)        DO_CLEAN=1; shift ;;
        -h|--help)      usage; exit 0 ;;
        *)              printf 'unknown argument: %s\n' "$1" >&2; usage; exit 1 ;;
    esac
done

if [[ "$DO_CLEAN" -eq 1 ]]; then
    echo "[build_stdlib] clean: removing STDLIB/build/ artifacts"
    BUILD_ROOT="$STDLIB_DIR/build"
    if [[ -d "$BUILD_ROOT/iii" ]]; then
        find "$BUILD_ROOT/iii" -maxdepth 1 \( \
              -name '*.iii.o' \
           -o -name '*.iii.o.s' \
           -o -name '*.build.log' \
           -o -name 'libiii_native.a' \
           -o -name 'libiii_native.a.mhash' \
        \) -delete -print
    fi
    if [[ -d "$BUILD_ROOT/corpus" ]]; then
        find "$BUILD_ROOT/corpus" -maxdepth 1 -type f -delete -print
    fi
    echo "[build_stdlib] clean: done"
    exit 0
fi

# Locate iiis.  Pin the IN-TREE production compiler FIRST -- the SAME
# discipline run_corpus.sh enforces (its lines 22-42).  Auto-picking a
# stale external `iiis` (PATH / Program Files) silently compiles the whole
# stdlib against the WRONG compiler: a determinism violation that produces
# phantom failures.  Observed: the May-11 `/c/Program Files/III/bin/iiis`
# rejects newer AVX-512 metal blocks in numera/bigint + numera/sha256 with
# "lex error: byte not recognised", FAILing ~7 crypto modules though the
# in-tree iiis-2 compiles them cleanly.  An explicit IIIS=... env override
# still wins (used by the seal-gated build_iiis*.sh wrappers).
IIIS="${IIIS:-}"
if [[ -z "$IIIS" ]]; then
    _III_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    if [[ -x "$_III_ROOT/COMPILED/iiis-2$BIN_SUFFIX" ]]; then
        IIIS="$_III_ROOT/COMPILED/iiis-2$BIN_SUFFIX"
    elif command -v iiis >/dev/null 2>&1; then
        IIIS="$(command -v iiis)"
    elif [[ -x "/c/Program Files/III/bin/iiis$BIN_SUFFIX" ]]; then
        IIIS="/c/Program Files/III/bin/iiis$BIN_SUFFIX"
    else
        echo "[build_stdlib] FATAL: iiis not found (COMPILED/iiis-2, PATH, Program Files)" >&2
        exit 2
    fi
fi

echo "[build_stdlib] using iiis: $IIIS"
mkdir -p "$BUILD_DIR"

# --- Stage 3.7 composition-table drift gate -----------------------------
# prespec.iii's auto-generated section (and iii_compositions.h) must
# byte-match what iii_compositions.def generates -- iii_compositions.def
# is the single source of truth.  A hand-edit to the generated section is
# a build-stopping drift (gen_compositions.sh --check exits non-zero).
GEN_COMP="$STDLIB_DIR/../COMPILER/BOOT/gen_compositions.sh"
if [[ -x "$GEN_COMP" ]]; then
    echo "[build_stdlib] composition drift-check: $GEN_COMP --check"
    if ! bash "$GEN_COMP" --check; then
        echo "[build_stdlib] FATAL: composition-table drift -- prespec.iii / iii_compositions.h diverged from iii_compositions.def." >&2
        echo "[build_stdlib]        Re-run 'bash COMPILER/BOOT/gen_compositions.sh' to regenerate (do not hand-edit the auto-generated section)." >&2
        exit 2
    fi
fi

# --- KATABASIS SVM-layout drift gate (plan 6.9) -------------------------
# katabasis/svm_layout.iii's generated region table (the §4.7 safety typing)
# must byte-match what iii_svm_layout.def generates; a hand-edit that diverges
# from the §0.4 layout fails the build (gen_svm_layout.sh --check exits 3).
GEN_SVM="$STDLIB_DIR/../COMPILER/BOOT/gen_svm_layout.sh"
if [[ -f "$GEN_SVM" ]]; then
    echo "[build_stdlib] SVM-layout drift-check: $GEN_SVM --check"
    if ! bash "$GEN_SVM" --check; then
        echo "[build_stdlib] FATAL: SVM-layout drift -- katabasis/svm_layout.iii diverged from iii_svm_layout.def." >&2
        echo "[build_stdlib]        Re-run 'bash COMPILER/BOOT/gen_svm_layout.sh' to regenerate (do not hand-edit the auto-generated section)." >&2
        exit 2
    fi
fi

# --- KATABASIS cycle-family drift gate (plan 6.9 / FR-9) ----------------
# katabasis/cycle_family.iii's generated taxonomy (the plan-3.0 nine families)
# must byte-match what iii_cycle_family.def generates; a hand-edit that diverges
# fails the build (gen_cycle_family.sh --check exits 3).
GEN_CF="$STDLIB_DIR/../COMPILER/BOOT/gen_cycle_family.sh"
if [[ -f "$GEN_CF" ]]; then
    echo "[build_stdlib] cycle-family drift-check: $GEN_CF --check"
    if ! bash "$GEN_CF" --check; then
        echo "[build_stdlib] FATAL: cycle-family drift -- katabasis/cycle_family.iii diverged from iii_cycle_family.def." >&2
        echo "[build_stdlib]        Re-run 'bash COMPILER/BOOT/gen_cycle_family.sh' to regenerate (do not hand-edit the auto-generated section)." >&2
        exit 2
    fi
fi

# --- KATABASIS census drift gate (plan 6.9 / FR-9) ----------------------
# katabasis/census.iii's generated silicon fact vector (plan 0.1-0.2) must
# byte-match what iii_census.def generates, and the count-coupled constants
# (array dimension / fact_count / hash byte-length) must stay 8x the fact
# count; a hand-edit that diverges fails the build (gen_census.sh --check exits 3).
GEN_CEN="$STDLIB_DIR/../COMPILER/BOOT/gen_census.sh"
if [[ -f "$GEN_CEN" ]]; then
    echo "[build_stdlib] census drift-check: $GEN_CEN --check"
    if ! bash "$GEN_CEN" --check; then
        echo "[build_stdlib] FATAL: census drift -- katabasis/census.iii diverged from iii_census.def." >&2
        echo "[build_stdlib]        Re-run 'bash COMPILER/BOOT/gen_census.sh' to regenerate (do not hand-edit the auto-generated section)." >&2
        exit 2
    fi
fi

# --- KATABASIS bar-layout drift gate (plan 6.9 / FR-9 / FR-7) ------------
# katabasis/bar_layout.iii's generated BAR bounds + region classifier must
# byte-match what iii_bar_layout.def generates; a hand-edit that diverges from
# the verified AD103 BAR windows fails the build (gen_bar_layout.sh --check exits 3).
GEN_BAR="$STDLIB_DIR/../COMPILER/BOOT/gen_bar_layout.sh"
if [[ -f "$GEN_BAR" ]]; then
    echo "[build_stdlib] bar-layout drift-check: $GEN_BAR --check"
    if ! bash "$GEN_BAR" --check; then
        echo "[build_stdlib] FATAL: bar-layout drift -- katabasis/bar_layout.iii diverged from iii_bar_layout.def." >&2
        echo "[build_stdlib]        Re-run 'bash COMPILER/BOOT/gen_bar_layout.sh' to regenerate (do not hand-edit the auto-generated section)." >&2
        exit 2
    fi
fi

# --- KATABASIS vmexit-set drift gate (plan 6.9 / FR-9 / plan 4.8) --------
# katabasis/vmexit.iii's generated minimal-VMEXIT taxonomy must byte-match what
# iii_vmexit.def generates; a hand-edit fails the build (gen_vmexit.sh --check exits 3).
GEN_VX="$STDLIB_DIR/../COMPILER/BOOT/gen_vmexit.sh"
if [[ -f "$GEN_VX" ]]; then
    echo "[build_stdlib] vmexit-set drift-check: $GEN_VX --check"
    if ! bash "$GEN_VX" --check; then
        echo "[build_stdlib] FATAL: vmexit-set drift -- katabasis/vmexit.iii diverged from iii_vmexit.def." >&2
        echo "[build_stdlib]        Re-run 'bash COMPILER/BOOT/gen_vmexit.sh' to regenerate (do not hand-edit the auto-generated section)." >&2
        exit 2
    fi
fi

# --- KATABASIS ring-lattice drift gate (plan 6.9 / FR-9 / plan 4.6) ------
# katabasis/ring_lattice.iii's generated legal-crossing cascade must byte-match
# what iii_ring_lattice.def generates; a hand-edit fails the build (gen_ring_lattice.sh --check exits 3).
GEN_RL="$STDLIB_DIR/../COMPILER/BOOT/gen_ring_lattice.sh"
if [[ -f "$GEN_RL" ]]; then
    echo "[build_stdlib] ring-lattice drift-check: $GEN_RL --check"
    if ! bash "$GEN_RL" --check; then
        echo "[build_stdlib] FATAL: ring-lattice drift -- katabasis/ring_lattice.iii diverged from iii_ring_lattice.def." >&2
        echo "[build_stdlib]        Re-run 'bash COMPILER/BOOT/gen_ring_lattice.sh' to regenerate (do not hand-edit the auto-generated section)." >&2
        exit 2
    fi
fi

# --- Sovereign Forge closure meta-gate (SOVEREIGN_FORGE.md §2) -----------
# Beyond the per-citizen drift gates above: assert the manifest itself is self-
# consistent -- no orphan generator, every K1-K6 full-spec seal recomputes to its
# recorded value, and the descent sub-closure root matches. A stale ledger (an
# artifact changed without re-sealing) fails the build.
FORGE_CHECK="$STDLIB_DIR/../COMPILER/BOOT/forge_check.sh"
if [[ -f "$FORGE_CHECK" ]]; then
    echo "[build_stdlib] Forge closure meta-gate: $FORGE_CHECK"
    if ! bash "$FORGE_CHECK"; then
        echo "[build_stdlib] FATAL: Forge closure violation -- DOCS/SOVEREIGN-LEDGER.md is not self-consistent." >&2
        echo "[build_stdlib]        Re-seal after a legitimate .def change: 'bash COMPILER/BOOT/forge_check.sh --print', then update the ledger seals + sub-closure root." >&2
        exit 2
    fi
fi

# --- Trusted-base content-address seal (SEPARATE-2 / W2.4) --------------
# The kernel's ENTIRE trusted computational base = the CCL reducer (numera/ccl.iii) + the
# TC<->CCL translation (tc_to_ccl).  Its source bytes are content-addressed into one root
# (DOCS/TRUSTED-BASE-SEAL.md); any edit to the reducer or the translation moves the hash and
# reddens the build until an explicit reseal -- "the trusted base is small + bounded" as a
# machine-checked fact (FORGE_CLOSURE-lite; STDLIB).
TRUSTED_BASE_CHECK="$STDLIB_DIR/../COMPILER/BOOT/trusted_base_check.sh"
if [[ -f "$TRUSTED_BASE_CHECK" ]]; then
    echo "[build_stdlib] trusted-base seal: $TRUSTED_BASE_CHECK --check"
    if ! bash "$TRUSTED_BASE_CHECK" --check; then
        echo "[build_stdlib] FATAL: trusted-base drift -- numera/ccl.iii or tc_to_ccl changed without a reseal." >&2
        echo "[build_stdlib]        Re-seal after an intended kernel change: 'bash COMPILER/BOOT/trusted_base_check.sh --print', then update TRUSTED_BASE_ROOT in DOCS/TRUSTED-BASE-SEAL.md." >&2
        exit 2
    fi
fi

# --- Architectural invariant gate (cartographer --gate) ----------------
# Beyond the per-.def drift gates above, the cartographer (sibling tree)
# enforces the STRUCTURAL graph invariants: no un-allowlisted dependency
# CYCLE and no duplicate @export SYMBOL (a Trap-2 link bomb). A NEW cycle or
# export-collision fails the build HERE, before any compile -- making the
# architecture self-governing instead of vigilance-dependent. Intentional
# exceptions live in III-CARTOGRAPHER/gate_allow.json. SOFT dependency: the
# tool lives OUTSIDE the sealed tree, so its (or python's) absence skips the
# gate rather than breaking the bootstrap; it touches no .iii / no MODULES
# order / no emitted byte (pre-compile, read-only) -> ZERO seal impact.
CARTO_DIR="$STDLIB_DIR/../../III-CARTOGRAPHER"
_carto_done=0
if [[ -d "$CARTO_DIR" ]]; then
    pushd "$CARTO_DIR" >/dev/null
    # NATIVE iii/c gate: carto.c (C) computes the structural facts -> carto_gate.iii (III)
    # issues the verdict (apotheosis C.13: in-tree NIH).  Auto-build carto.exe if a C
    # compiler is present and the binary is missing/stale.
    if [[ -f carto.c ]] && { command -v gcc >/dev/null 2>&1 || command -v cc >/dev/null 2>&1; }; then
        _CC=$(command -v gcc || command -v cc)
        if [[ ! -x carto.exe || carto.c -nt carto.exe ]]; then "$_CC" -O2 -o carto.exe carto.c 2>/dev/null || true; fi
    fi
    if [[ -x carto.exe ]]; then
        if ./carto.exe --emit-graph >/dev/null 2>&1 && [[ -x carto_gate.exe ]]; then
            echo "[build_stdlib] architectural invariant gate: native carto (iii/c) -> carto_gate"
            ./carto_gate.exe; _rc=$?; _carto_done=1     # the III policy verdict (PASS/FAIL)
        else
            echo "[build_stdlib] architectural invariant gate: native carto --gate (C)"
            ./carto.exe --gate; _rc=$?; _carto_done=1   # the C verdict (fallback when carto_gate.exe absent)
        fi
        if [[ $_carto_done -eq 1 && $_rc -ne 0 ]]; then
            popd >/dev/null
            echo "[build_stdlib] FATAL: architectural invariant violation -- a new dependency cycle or duplicate @export symbol." >&2
            echo "[build_stdlib]        Fix it, or record an intentional exception in III-CARTOGRAPHER/gate_allow.json." >&2
            exit 2
        fi
    fi
    popd >/dev/null
fi
# Legacy fallback: the original Python gate, only if the native tool is unavailable.
if [[ $_carto_done -eq 0 ]]; then
    CARTO="$CARTO_DIR/cartographer.py"
    if [[ -f "$CARTO" ]] && command -v python >/dev/null 2>&1; then
        echo "[build_stdlib] architectural invariant gate: cartographer.py (legacy fallback)"
        if ! python "$CARTO" --gate; then
            echo "[build_stdlib] FATAL: architectural invariant violation -- a new dependency cycle or duplicate @export symbol." >&2
            echo "[build_stdlib]        Fix it, or record an intentional exception in III-CARTOGRAPHER/gate_allow.json." >&2
            exit 2
        fi
    fi
fi

# Module list in dependency order: each entry is "subsphere/name".
MODULES=(
    "numera/scalar"
    "numera/sha256"
    "numera/sha256_ni"
    "numera/hex"
    "memoria/tempaloc"
    "memoria/region"
    "memoria/span"
    "memoria/arena"
    "verba/rune"
    "verba/string"
    "verba/builder"
    "omnia/option"
    "omnia/result"
    "omnia/iter"
    "omnia/vec"
    "sanctus/mhash"
    "sanctus/kchain"
    "omnia/map"
    "omnia/set"
    "omnia/queue"
    "omnia/pq"
    "omnia/fold"
    "omnia/zip"
    "omnia/either"
    "numera/trit"
    "numera/uncertainty"
    "omnia/hexad_algebra"
    "omnia/hexad_pfs"
    "omnia/hexad_reach"
    "omnia/hexad_epistemic"
    "omnia/hexad_mobius"
    "omnia/hexad_dynamic"
    "numera/safety_type"
    "omnia/hexad"
    "omnia/spec_probe"
    "numera/checked"
    "numera/modular"
    "numera/fixed"
    "numera/q128"
    "verba/parse"
    "verba/markup"
    "numera/bigint"
    "verba/format"
    "verba/regex"
    "aether/capability"
    "aether/handle"
    "aether/fs"
    "tempora/instant"
    "tempora/duration"
    "tempora/deadline"
    "sanctus/witness"
    "sanctus/attest"
    "omnia/crystal"
    "sanctus/mandate"
    "sanctus/closure"
    "sanctus/legacy_artifact"
    "sanctus/sovereign_witness"
    "numera/bigint_div"
    "numera/field"
    "verba/normalise_ascii"
    "aether/net"
    "verba/json"
    "numera/sha512"
    "aether/http_client"
    "numera/fe25519"
    "numera/ed_scalar_modl"
    "numera/crypt_ed25519"
    "numera/founders_anchor"
    "numera/constants"
    "numera/aes"
    "numera/aes_gcm"
    "numera/aes_siv"
    "aether/http_server"
    "verba/uri"
    "numera/chacha20"
    "numera/poly1305"
    "numera/chacha20_poly1305"
    "numera/xchacha20_poly1305"
    "numera/x25519"
    "verba/normalise"
    "numera/hmac"
    "numera/drbg"
    "numera/fp256"
    "numera/fn256"
    "numera/ec256"
    "numera/ecdsa_p256"
    "numera/fp384"
    "numera/fn384"
    "numera/ec384"
    "numera/ecdsa_p384"
    "numera/rsa"
    "numera/zk_field"
    "numera/zk_snark"
    "numera/zk_stark"
    "numera/zk_air"
    "numera/zk_prune"
    "verba/base64"
    "numera/hkdf"
    "numera/crc32"
    "numera/blake2s"
    "numera/xoshiro"
    "numera/pbkdf2"
    "verba/uuid"
    "numera/murmur3"
    "numera/ntt"
    "numera/ntt_fri_organ"
    "numera/zk_stark_seal"
    "numera/ntt_bigint"
    "verba/csv"
    "verba/ini"
    "verba/leb128"
    "verba/base32"
    "verba/ulid"
    "tempora/calendar"
    "tempora/rfc3339"
    "memoria/seal_organ"
    "verba/timing_safe"
    "numera/endian"
    "verba/path"
    "verba/html_escape"
    "omnia/crystal_deps"
    "sanctus/quality"
    "omnia/ripple"
    "numera/bitops"
    "aether/inet"
    "verba/semver"
    "omnia/proof_ripple"
    "verba/glob"
    "omnia/list"
    "omnia/lru"
    "omnia/dynamic_record"
    "omnia/jit_swap"
    "omnia/layered_seal"
    "omnia/dynamic_impact"
    "numera/field_crystal"
    "omnia/crystal_edges"
    "numera/bigint_karatsuba"
    "numera/q128_f64"
    "numera/checked_crystal"
    "numera/modular_mont"
    "numera/fixed_extra"
    "numera/scalar_provenance"
    "numera/cpufeat"
    "numera/sha256_dispatch"
    "aether/tcp"
    "aether/http"
    "omnia/async"
    "numera/keccak"
    "numera/keccak256"
    "numera/identifier"
    "numera/cad"
    "numera/h2_charter"
    "numera/h1_charter"
    "numera/h3_charter"
    "numera/h8_charter"
    "numera/h10_charter"
    "numera/h6_charter"
    "numera/h9_charter"
    "numera/h11_charter"
    "numera/h4_charter"
    "numera/h5_charter"
    "numera/h7_charter"
    "numera/h12_charter"
    "numera/h13_charter"
    "numera/charter_terminal"
    "numera/algebraic_time"
    "aether/witness_hook"
    "sanctus/observe"
    "sanctus/onelang"
    "aether/hotstuff"
    "aether/hotstuff_predict"
    # APOTHEOSIS C.11: the tier-aware certified-monotone pacemaker -- constitutional-constant
    # timeouts (no-ML), monotone+bounded backoff (liveness), explicit BFT 2f+1 quorum. Safety stays
    # the mhash vote-block match in hotstuff.iii. Compiler-unreferenced -> LIBNATIVE.
    "aether/hotstuff_unified"
    # APOTHEOSIS C.11: the tournament quorum optimizer -- selects the 2f+1 most-available peers by
    # SEALED fact (no-ML: a data input, never observed-and-adapted), Byzantine-available by
    # construction. Composes hotstuff_unified. Compiler-unreferenced -> LIBNATIVE.
    "aether/hotstuff_predict_opt"
    "aether/hotstuff_heal"
    "numera/sha3_256"
    "numera/sha3_512"
    "numera/shake128"
    "numera/shake256"
    "numera/pq_params"
    "numera/ntt_ctx"
    "numera/keccak_sponge"
    "numera/mldsa"
    "numera/mlkem"
    "numera/slhdsa"
    "numera/pq_dispatch"
    "sanctus/mandate_m22"
    "sanctus/quality_q7"
    "sanctus/seal_resolver"
    "verba/pattern"
    "sanctus/resolver_replay"
    "aether/fed_tier"
    "aether/fed_sybil"
    "aether/fed_eclipse"
    "aether/fed_admit"
    "aether/fed_genesis"
    "aether/fed_seal"
    "omnia/sandbox_ctor"
    "omnia/sandbox_quota"
    "omnia/sandbox_exec"
    "numera/merkle"
    "omnia/obs_log"
    "omnia/obs_metric"
    "omnia/obs_trace"
    "omnia/obs_observatory"
    "sanctus/catalyst"
    "sanctus/genesis"
    "sanctus/promote"
    "sanctus/demote"
    "verba/glyph_core"
    "verba/glyph_u8"
    "verba/glyph_u32"
    "verba/glyph_u64"
    "verba/glyph_i64"
    "verba/glyph_f64"
    "verba/glyph_bytes"
    "verba/glyph_str"
    "verba/glyph_crystal"
    "verba/glyph_vec"
    "verba/glyph_map"
    "verba/glyph_set"
    "verba/glyph_enum"
    "verba/glyph_record"
    "verba/glyph_witness"
    "verba/glyph_proof"
    "verba/glyph_recursive"
    # FROZEN SPEC III-RES-FROZEN-001 — resolver runtime modules
    "numera/sat_arith"
    "verba/intent"
    "verba/ast_intent"
    "verba/intent_form"
    "verba/pattern_form"
    "omnia/call_context"
    "omnia/unify"
    "omnia/pattern_table"
    "omnia/resolver"
    # APOTHEOSIS C.9: discharge the resolver fast-path shortcut into a proven equivalence theorem --
    # cold-vs-fast differential (RESOLVER_FORCE_COLD) proves the asm shortcut == the 11-step contract
    # per input, sealed via cad. The optimization is PROVEN, not deleted. Compiler-unreferenced -> LIBNATIVE.
    "omnia/proof_resolve"
    "omnia/resolver_replay"
    "omnia/proof_ripple_resolution"
    "omnia/transform"
    "verba/transform_form"
    "omnia/transform_patterns"
    "omnia/codegen_patterns"
    "omnia/babel"
    "omnia/babel_intent"
    "omnia/governance"
    "omnia/self_reformatter"
    "aether/pattern_set_federation"
    "omnia/ai_resolve"
    "omnia/resolution_meta_dispatch"
    "omnia/codegen_dispatch"
    "omnia/resolution_init"
    # 24 transform codec implementations (FROZEN SPEC §7B.6, §F.D.TP)
    "omnia/tp_raw_hex"
    "omnia/tp_iii_hex"
    "omnia/tp_pe_hex"
    "omnia/tp_iii_to_md"
    "omnia/tp_iii_to_latex"
    "omnia/tp_iii_to_c99"
    "omnia/tp_x86_disasm"
    "omnia/tp_x86_assemble"
    "omnia/tp_iii_to_asm"
    "omnia/tp_asm_to_pe"
    "omnia/tp_iii_to_babel_json"
    "omnia/tp_babel_json_to_iii"
    "omnia/tp_iii_to_ast_bin"
    "omnia/tp_ast_bin_to_iii"
    "omnia/tp_babel_text"
    "omnia/tp_babel_text_back"
    "omnia/tp_babel_json_cbor"
    "omnia/tp_babel_cbor_json"
    "omnia/tp_ripple_dot"
    "omnia/tp_ripple_md"
    "omnia/tp_ast_dot"
    "omnia/tp_c99hdr_to_iii"
    "omnia/tp_ast_to_babel_json"
    "omnia/tp_babel_json_to_ast"
    # The Intent Calculus v1.0 (supersedes FROZEN SPEC III-RES-FROZEN-001).
    # calculus_v1 + irreducibility_proof are placed at end of MODULES list
    # so adding them never shifts the BSS layout of any pre-existing module
    # (defensive: some pre-existing crypto modules have latent codegen
    # sensitivities documented as iiis-0 traps). Link order is unaffected:
    # resolution_init's externs to calculus_init / proof_init resolve via
    # libiii_native.a's archive symbol index regardless of position.
    "sanctus/calculus_v1"
    "sanctus/irreducibility_proof"
    # L1 mini-crystals (8-byte) for the lazy-crystal three-level
    # architecture (Phase B). Placed at end with the other Phase A/B
    # modules to preserve BSS adjacency of pre-existing modules.
    "omnia/mini_crystal"
    # Phase C.3: deterministic content-addressed memoization for resolve().
    # ~180 KiB BSS isolated to its own module to keep resolver.iii's
    # BSS layout undisturbed.
    "omnia/resolver_memo"
    # Phase C.5: bounded JIT fusion (8-instruction window, 64 slots).
    "omnia/jit_fuse"
    # Phase C.1: pre-specialization registry consumed by cg_r3 partial evaluator.
    "omnia/prespec"
    # Phase C.2: hardware-lowering registry (SHA-NI/AES-NI/AVX-2/AVX-512).
    "omnia/hw_offload"
    # Phase D wire stack (HTTP/HTML/TLS replacement).
    "aether/babel_wire"
    "aether/cap_handshake"
    "aether/sealed_channel"
    "aether/idoc"
    "verba/nl_lex"
    "verba/nl_parse"
    "verba/hip"
    # Benchmark facade over COMPILER/BOOT/bench_helpers.s (RDTSC/RDTSCP/CPUID/PAUSE).
    # Placed at end so it never shifts the BSS layout of any pre-existing module.
    "omnia/bench"
    # XII Phase α-ζ — Lattice / Horizon / canonicalisation subsystem.
    # Per DOCS/III-XII.md and DOCS/XII-IMPLEMENTATION.md.  All 25 modules
    # placed at the end so they cannot perturb BSS layout of pre-existing
    # modules (defensive: iiis-0 has documented BSS sensitivities).
    "omnia/xii_term"
    "omnia/xii_basis"
    "numera/xii_subforms"
    "omnia/xii_hj"
    "omnia/xii_savings"
    "omnia/xii_rewrite"
    "omnia/xii_canonicalise"
    "omnia/xii_horizon"
    "omnia/xii_horizon_reach"
    "omnia/xii_circ"
    "omnia/xii_chd"
    "omnia/xii_lattice"
    "numera/xii_nop_tables"
    "omnia/xii_emit_gen"
    "omnia/xii_kernel_emit"
    "omnia/xii_curated_payloads"
    # W1.2/CUT-12: xii_curated_crypto{,_extended,_final} + xii_curated_arm64_crypto deleted --
    # they registered ONLY crypto-horizon (<24) overrides, all refused by the emit chokepoint
    # (dead matter, emission byte-identical).  The mixed catalogs below keep their non-crypto rows.
    "omnia/xii_curated_embedded"
    "omnia/xii_curated_riscv"
    "omnia/xii_curated_extended"
    "sanctus/xii_sml"
    "sanctus/xii_atm"
    "sanctus/xii_curate"
    "sanctus/xii_antidrift"
    "sanctus/anchor_xii"
    "sanctus/xii_register_all"
    # KATABASIS descent substrate (DOCS/III-KATABASIS.md).  Appended at the very
    # end so it never shifts the BSS layout of any pre-existing module.
    "katabasis/svm_layout"
    "katabasis/cycle_family"
    "katabasis/bar_layout"
    "katabasis/cycle_admit"
    "katabasis/vmexit"
    "katabasis/ring_lattice"
    "katabasis/gate_verdict"
    "katabasis/census"
    "katabasis/bricking"
    "katabasis/cycle_term"
    "katabasis/gate"
    "katabasis/seal"
    "katabasis/caps"
    "katabasis/admit"
    # --- CONVERGENCE Wave 1 (numera leaves; appended at end to preserve pre-existing BSS layout) ---
    "numera/rev_invoke"
    "numera/tiebreak"
    "numera/galois"
    "numera/rscode"
    "numera/shamir"
    "numera/erasure_store"
    "numera/threshold_vault"
    "numera/hamming_secded"
    "numera/gf_poly"
    "numera/rscode_ec"
    "numera/lzss"
    "numera/cas_blob"
    "numera/crt"
    "numera/bitio"
    "numera/elias"
    "numera/huffman"
    "numera/lzh"
    "numera/heaplet"
    "numera/sep_logic"
    "numera/tso"
    "numera/ptr_provenance"
    "numera/mem_rewrite"
    "numera/csl"
    "numera/congruence_closure"
    "numera/mcmc_egraph"
    "numera/relational_ematch"
    "numera/algo_synth"
    "numera/k0_referee"
    "numera/golden_shift"
    "numera/conjecture_refute"
    "numera/self_engine"
    "numera/verified_search"
    "numera/omega_engine"
    "numera/pareto_frontier"
    "numera/verified_ripple"
    "numera/optimality_cert"
    "numera/logic_synth"
    "numera/contract_gate"
    "numera/ring_opt"
    "numera/matrix_ring"
    "numera/bft_quorum"
    "numera/affine_check"
    "numera/rewrite_schedule"
    "numera/interval_lattice"
    "numera/loop_optimizer"
    "numera/kleene_fixpoint"
    "numera/widening"
    "numera/align_domain"
    "numera/bv_ring"
    "numera/congruence"
    "numera/sat"
    "numera/egraph"
    "numera/cost_lattice"
    "omnia/sovval"
    "numera/microarch_model"
    "numera/quine_verifier"
    "numera/entropy_monitor"
    "numera/curry_howard"
    # --- CONVERGENCE Wave 1 batch 2 (appended at end to preserve pre-existing BSS layout) ---
    "numera/category"
    "omnia/sov_morphism"
    "omnia/xii_morphism"
    "omnia/tp_morphism"
    "numera/h9_mig2_tie"
    "numera/sheaf"
    "aether/manifest"
    "aether/quarantine"
    "aether/node_identity"
    "aether/snapshot_lattice"
    "aether/topology_atlas"
    "aether/cap_forge"
    "numera/xii_ldil"
    "aether/triple_check"
    "aether/context_awareness"
    "numera/symbolic_regression"
    # --- CONVERGENCE Wave 2 batch 1 (deps satisfied by Wave 1 + built) ---
    "numera/constitution"
    "numera/witness_spine"
    "numera/reversible"
    "numera/smt"
    "numera/proof_term"
    "numera/sat_at_scale"
    # --- CONVERGENCE Wave 2 batch 2 (deps: Wave 1 + batch 1 + built; appended to preserve BSS layout) ---
    "numera/groebner"
    "numera/proof_carrying"
    "numera/cost_calculus"
    # APOTHEOSIS C.8: the 6-D Pareto frontier (antichain of non-dominated cost vectors) -- the
    # honest multi-dimensional cost selection the e-graph extraction + ripple consult vs a scalar
    # argmin. Self-contained integer dominance. Compiler-unreferenced -> LIBNATIVE.
    "numera/pareto_extraction"
    # APOTHEOSIS C.8: the closed-form cost manifold -- uc_formula_latency = critical-path DP (latency
    # queryable DURING e-graph saturation, not just at extraction) + the 6-D vector assembly the
    # pareto frontier + ripple J consult. Compiler-unreferenced -> LIBNATIVE.
    "numera/unified_cost_manifold"
    # APOTHEOSIS C.14: the mechanistic provable cycle bound -- derives a fast path's bound from the
    # C.8 cost manifold (critical path = analytic lower bound); a path slower than bound+margin is a
    # PROVABLE regression, not advisory. Composes unified_cost_manifold. Compiler-unreferenced -> LIBNATIVE.
    "numera/cost_lattice_unified"
    "aether/bone_marrow"
    "numera/cost_lattice_synth"
    "aether/basal_probe"
    # --- CONVERGENCE Wave 3 (12; deps built or earlier in this block; appended to preserve BSS layout) ---
    "numera/temporal_logic"
    "numera/computation_graph"
    "numera/memo_lattice"
    "numera/theorem_carrier"
    "numera/synthesis_spec"
    "aether/reversibility_audit"
    "numera/branch_anchor"
    "aether/branch_governance"
    "numera/math_library"
    "numera/math_library_curation"
    "aether/memo_query"
    "numera/constitution_preserver"
    # --- CONVERGENCE Wave 4 (deps built; appended to preserve BSS layout) ---
    "aether/bisimulation_witness"
    "aether/witness_compactor"
    "aether/distress_witness"
    "aether/cost_overrun_handler"
    "aether/firmware_quarantine"
    "aether/shape_negotiator"
    "aether/memo_compactor_coordination"
    "numera/reflection_constrained"
    "numera/reflection_governance"
    # nous: the proposer faculty + the Search Trichotomy closure (DOCS/III-NOUS-ARCHITECTURE.md).
    # Appended at the very end so it never shifts the BSS layout of any pre-existing module
    # (iiis-0 BSS sensitivity).  The chain nous_socket->nous_policy->nous_features->xii_term
    # is acyclic; the archive resolves all externs regardless of this listing order.
    "nous/nous_features"
    "nous/nous_costlin"
    "nous/nous_value"
    "nous/nous_policy"
    "nous/nous_socket"
    "nous/nous_lattice"
    "nous/nous_search"
    "nous/nous_charter"
    "nous/nous_completion"
    "nous/nous_commons"
    "nous/nous_train"
    "nous/nous_synth"
    "nous/nous_behavioral_key"
    "nous/nous_conjecture"
    "nous/nous_conjecture_term"
    "nous/nous_conjecture_gen"
    "nous/nous_conjecture_lemma"
    # mig4 Step 1: declarative XII rule LHS pattern table + structural matcher (consumed by
    # the Step-2 unifier for critical-pair enumeration).  Additive; externs xii_term +
    # xii_rewrite (built above).  Placed last so it cannot perturb any module's BSS layout.
    "omnia/xii_rule_patterns"
    # mig4 Step 2: the LHS unifier + critical-overlap predicates (consumes Step 1's table
    # via the xrp_*_at accessors; additive, externs xii_rule_patterns only).
    "omnia/xii_rule_overlap"
    # mig4 Step 3: dynamic critical-pair enumeration (records the overlaps from the Step-2
    # predicates into a table the Step-4 joinability gate iterates; externs Steps 1+2).
    "omnia/xii_critpair_enum"
    # mig4 Step 4: the dynamic joinability gate -- proves root-overlap confluence GREEN and
    # detects the subterm-overlap non-confluence (consumes Steps 1-3 + the canonicaliser).
    "omnia/xii_joinability"
    # mig4 Step 5: the termination / measure-decrease gate -- proves every rule strictly decreases
    # the lexicographic triple (canon_weight, node_count, assoc_penalty), Newman's termination half
    # (consumes Steps 1/2/4 + the canonicaliser).  Additive; placed last so it cannot perturb BSS.
    "omnia/xii_termination"
    # mig4 Step 6: the rule-set admission gate -- ADMIT iff root-confluent (Step 4) AND terminating
    # (Step 5); the deterministic-normaliser treatment of the Step-4 non-confluence.  Additive; last.
    "omnia/xii_admission"
    # mig4 Step 7: lower the FIRST domain (the free composition monoid) through XII -- the first
    # payload of "route all computation through XII".  A consumer of canonicalise (engine untouched);
    # the engine's own rules (R001 assoc + R017/R037/R038 identity) ARE the monoid axioms; gated by
    # xad_admit.  Additive; placed last so it cannot perturb BSS.
    "omnia/xii_lower_compose"
    # mig4 Step 8: lower the remaining structured-programming primitives -- SELECTION onto FIF
    # (decide: R030 equal-branch + R007/R008 branch-lift) and ITERATION onto FLOOP (iterate: R013
    # once + R014 fold + R015 distribute + R041 null-wipe).  With Step 7's composition they complete
    # the sequence/selection/iteration trinity, each = XII canonicalisation.  Additive; gated by xad_admit.
    "omnia/xii_lower_decide"
    "omnia/xii_lower_iterate"
    # mig4 Step 9: caller migration (additive form) -- a structured program built from the lowered
    # operators (compose/if/loop), computed by canonicalise, proving the three domains interoperate
    # (the grand mix fires branch-lift + equal-branch + loop-distribute in one reduction).
    "omnia/xii_lower_program"
    # mig4 Step 8c-e: the remaining three composition-operator lowerings -- FTHEN (then, a monoid),
    # FWITH (with, left-unital + right-absorbing), FUNDER (under, left-assoc + right-absorbing).  The
    # four composition operators have FOUR distinct algebras; these complete the binary-fusion coverage.
    "omnia/xii_lower_then"
    "omnia/xii_lower_with"
    "omnia/xii_lower_under"
    # mig4 Step 10: retire the syntactic path + SEAL -- the terminal gate folding all THIRTEEN mig4 stage
    # selftests (xrp/xro/cpe/xjn/xtm/xad/xlc/xld/xli/xlp/xlt/xlw/xlu) into one verdict + a content-address seal
    # (via cad) of the lowered domains' normal forms.  Completes + seals the migration.
    "omnia/xii_mig4_seal"
    # Confluence-Core Certificate (DOCS/III-XII-CONFLUENCE-CERT-IMPL-PLAN.md): Tier 1 strategy-
    # determinism floor + Tier 2a discharge grader. Additive; compiler-unreferenced; seal-neutral.
    "omnia/xii_strategy_det"
    "omnia/xii_discharge"
    "omnia/xii_conf_cert"
    "omnia/xii_cap_preserve"
    # The Reach (DOCS/III-THE-REACH-ARCHITECTURE.md), Phase 1: the content-addressed transport spine.
    # reach_store (L1 disk content-store) -> reach_core (resolver + emit; verifies the returned value
    # re-hashes to its address = tamper-evident; an absent/corrupt address = a typed GAP, never an
    # error).  Additive; externs fs/cad/capability/uncertainty (built above); appended last so it
    # cannot perturb any pre-existing module's BSS layout (iiis-0 BSS sensitivity).
    "aether/backend_memo"
    "aether/reach_store"
    "aether/backend_remote"
    "aether/backend_ipc"
    "aether/reach_core"
    "aether/reach_oracle"
    "aether/backend_loopback"
    # The directional ripple-field (omnia::ripple_field): thickens the thin
    # topology ripple into a signed, content-derived gradient (xii_savings
    # magnitude x xii_hj dominance sign).  Appended last (BSS-neutral); externs
    # only the already-sealed xii_savings + xii_hj built above.
    "omnia/ripple_field"
    # FORCEFIELD bricks: the coherence gate (pleroma) + the ripple network value
    # & signed-dynamic layers.  Appended last (BSS-neutral); compiler-unreferenced.
    "forcefield/pleroma"
    "forcefield/ripple"
    "forcefield/ripple_dyn"
    "forcefield/optinvoke"
    "numera/typecheck"
    "numera/combinator"
    "numera/ccl"
    # P6: the sound-evolution commit gate (composes xii_admission + pleroma + cad).
    "forcefield/commit_gate"
    "forcefield/forked_walk"
    # The Sovereign ISA Descent: the Sovereign Calculus's differential descent over
    # the cost-field, wiring egraph (saturate) + cost_lattice (cost) into a proof-
    # preserving min-cost optimizer.  Externs egraph + cost_lattice (built above).
    "numera/sov_isa"
    # The Theorem Commons: a content-addressed registry of kernel-VERIFIED statements (tc_check-gated admit).
    # Persists what the autocatalytic loop proves so the optimizer can CITE by hash, not re-prove.  Externs
    # cad + typecheck (built above).
    "numera/theorem_commons"
    "numera/certified_morphism"
    # The Autocatalytic Synthesis Loop ("Dream Sandbox"): a seeded-deterministic mutagen proposes alien
    # candidate optimizations, the sov_isa synthesizer attempts a CIC proof, and the tc_check kernel
    # disposes -- only kernel-certified discoveries are cad-sealed.  Additive consumers of sov_isa /
    # typecheck / cad; NOT in the compiler link closure (golden + trusted-base unmoved).
    "numera/egraph_stochastic"
    "forcefield/cg_autocatalyst"
    "forcefield/bv_dispose"
    "forcefield/daemon_dream"
    # The Isomorphic Scythe (Autonomous Semantic Refactoring): hunts legacy logic, kernel-PROVES it
    # universally equivalent to a cheaper optimal (bisimulation via the CIC kernel), records the certified
    # rewrite, and SURFACES the cull set (operator-gated reseal -- no autonomous golden shift / source edit).
    # Additive consumers of sov_isa / typecheck; NOT in the compiler link closure (golden + TB unmoved).
    "numera/ast_hunter"
    "omnia/proof_bisimulation"
    "forcefield/cg_surgical_strike"
    "forcefield/daemon_scythe"
    "forcefield/scythe_census"
    "forcefield/sovereign_optimizer"
    # The verification missile on III's LIVE rules: drives the real xii_canonicalise
    # engine over the trit fragment and verifies it against an INDEPENDENT Kleene spec
    # (non-tautological, unlike corpus 670).  Externs only the live XII engine.
    "omnia/xii_rule_verify"
    # Second strike: the semantic-soundness gate extended to XII's LIVE fusion identity-null
    # rewrites (R016/R017/R021/R022), verified against the independent monoid-identity authority.
    "omnia/xii_fusion_verify"
    # The Sovereign Pipeline: every kernel faculty (conversion, induction, superposition,
    # proof-carrying optimization, kernel-governed admission) actively used through ONE
    # kernel-disposed path (the kernel tc_check is the universal disposer). Externs sov_isa
    # + typecheck + egraph + cost_lattice (built above); compiler-unreferenced -> LIBNATIVE
    # only. Appended last (BSS-neutral).
    "numera/sov_pipeline"
    # The Sovereign Ripple Calculus (Inc 1): the objective made computable -- measures
    # noise / good-complexity / separation / unification over the module graph (a graph-level
    # MDL proxy; the decidable fragment). Standalone (no externs), compiler-unreferenced
    # -> LIBNATIVE. Appended last (BSS-neutral).
    "forcefield/ripple_metric"
    # Inc 2: the first certified refactoring -- unification. Composes ripple_metric (the intent
    # gate) + congruence (the faithfulness-gated merge) + a kernel proof. Decider only (no file
    # edits). Compiler-unreferenced -> LIBNATIVE.
    "forcefield/ripple_unify"
    # APOTHEOSIS C.7: the UNIFIED Ripple-move decider -- proof_ripple_decision over MERGE/CUT/EXTRACT
    # via the three certified deciders + the kernel-first gate (blocks all moves while blind) + the
    # move crystal. Composes ripple_unify/cut/extract + cad. Compiler-unreferenced -> LIBNATIVE.
    "forcefield/proof_ripple_unified"
    # Inc 3: the closed loop -- propose -> decide (commit_gate + ripple_unify) -> apply-in-model
    # -> loop until dry. Composes ripple_metric + ripple_unify + congruence + commit_gate.
    # Decider/planner (no file edits). Compiler-unreferenced -> LIBNATIVE.
    "forcefield/ripple_loop"
    # Inc 4: the second certified refactoring -- NOISE CUT (the "minimize noise" half). Composes
    # ripple_metric + commit_gate. Decider/sweep (no file edits). Compiler-unreferenced -> LIBNATIVE.
    "forcefield/ripple_cut"
    # Phase B1: Topological Extraction decider -- the 4 conditions (capability conservation,
    # MDL boundary penalty, acyclic insertion, H10 anti-thrashing) permitting a new-file write.
    # Composes congruence + ripple_metric + commit_gate. Compiler-unreferenced -> LIBNATIVE.
    "forcefield/ripple_extract"
    # Phase C: Proof-Carrying Code -- the one permitted generative synthesis. pcc_verify =
    # typecheck.iii tc_check(proof, spec): the kernel evaluates the constructive proof against the
    # dependent-type spec; flawless -> commit, flawed -> destroy. Compiler-unreferenced -> LIBNATIVE.
    "forcefield/pcc_gate"
    # III -> Silicon HW1: certified combinator/boolean -> gate-netlist lowering (BinaryGate/
    # TernaryGate/DFlipFlop) with truth-table equivalence as the proof. Composes trit only.
    # Compiler-unreferenced -> LIBNATIVE.
    "numera/hdl"
    # APOTHEOSIS C.8: the certified gate-identity proof DB -- 10 boolean identities proven bit-exact
    # over their full 2^n truth tables (hdl_equiv2), so the netlist optimizer's rewrites are
    # sound by construction; a non-equivalent rewrite is rejected. Compiler-unreferenced -> LIBNATIVE.
    "numera/hdl_gate_db"
    # APOTHEOSIS C.8 capstone: the certified netlist optimizer -- CONSUMES hdl_gate_db's identities +
    # hdl to reduce redundant gates (AND(a,a)/OR(a,a)/NOT NOT) with the output function PROVEN preserved
    # (truth table before==after) while live gates drop; a wrong rewrite is caught. Compiler-unreferenced -> LIBNATIVE.
    "numera/hdl_optimize"
    # APOTHEOSIS C.8 item 4: the combinator->netlist compiler -- lowers a postfix combinator program
    # to an hdl netlist, then NORMALIZES it via the certified hdl_optimize fixpoint (function PROVEN
    # preserved while gates drop). Closes the edge hdl_compiler -> hdl_optimize. Compiler-unreferenced -> LIBNATIVE.
    "numera/hdl_compiler"
    # APOTHEOSIS C.9 item 3: the container-honesty proof -- HANDLE-TABLE balance on a real container
    # (list, 32-slot table): balanced new->drop is unbounded, a leak (new w/o drop) fills the table and
    # the overflow is REFUSED (the documented slot-exhaustion mode caught). Consumes list + arena. -> LIBNATIVE.
    "omnia/arena_slot_witness"
    # III -> Silicon HW3: the hardware Axiom Enforcement Unit -- III's hexad axioms as a parallel
    # combinational verifier (certified === the conjunction via hdl). Composes hdl + hexad_reach.
    # Compiler-unreferenced -> LIBNATIVE.
    "numera/aeu"
    # Sovereign Enhancement G1: unified integrity phi + non-vacuity falsifier ledger.
    # Composes commit_gate + aeu + hexad_reach. Compiler-unreferenced -> LIBNATIVE.
    "forcefield/integrity"
    # Sovereign Enhancement G3: the real argmax M-search (value-maximal selection + s0-in-M abstention).
    "forcefield/ripple_search"
    "forcefield/ripple_synthesizer"
    "forcefield/ripple_journal"
    "numera/costed_cat"
    # Sovereign Enhancement G5: the inductive bridge (sample -> forall via tc_natrec; false universal rejected).
    "numera/induct"
    # Structural-Audit Wave 0 / W0.1 (COMBINE-7): the boundary-trust organ -- the single source of
    # the @export door's range/wrap/overflow discipline.  Pure leaf, NO BSS (cannot perturb layout),
    # libc-free; every boundary @export routes through bnd_index/bnd_cap_ok/bnd_mul_ok/bnd_alloc_size.
    "omnia/bound"
    "omnia/caindex"
    # --- M23: below-OS behavioral quine-seal (capability 11); leaf, tiny BSS, appended last ---
    "katabasis/quine_seal"
)

PASS=0
FAIL=0
FAILED=()
# Namespace .o filenames by replacing '/' with '_' so two modules with
# the same leaf name (e.g. sanctus/resolver_replay vs omnia/resolver_replay)
# do not collide on the same .o output path.  Without this, the second
# compilation silently overwrites the first, and the archive contains
# the same .o twice -- which manifests as `multiple definition` errors
# when --whole-archive is used to force-link the archive contents.
for mod in "${MODULES[@]}"; do
    name="${mod//\//_}"
    src="$SRC_DIR/${mod}.iii"
    obj="$BUILD_DIR/${name}.iii.o"
    if [[ ! -f "$src" ]]; then
        echo "[build_stdlib] MISSING $src"
        FAIL=$((FAIL+1)); FAILED+=("$mod (missing)")
        continue
    fi
    # OneDrive/Defender transient-lock hardening (DOCS/III-DISPOSITION-EXECUTION.md): the
    # $obj write can be momentarily blocked by sync/AV. rm (fresh inode) + retry; a genuine
    # compile error is deterministic and still fails every attempt (the .build.log shows the
    # real cause), so this never turns a real failure green -- it only stops a transient
    # lock from spuriously failing GATE1 and REVERTing a good ripple_apply edit.
    _crc=1
    for _ca in 1 2 3; do
        rm -f "$obj"
        if "$IIIS" "$src" --compile-only --out "$obj" 2>"$BUILD_DIR/${name}.build.log"; then _crc=0; break; fi
        sleep 1
    done
    if [[ $_crc -eq 0 ]]; then
        echo "[build_stdlib] OK   $mod -> $obj"
        PASS=$((PASS+1))
    else
        echo "[build_stdlib] FAIL $mod (see $BUILD_DIR/${name}.build.log)"
        FAIL=$((FAIL+1)); FAILED+=("$mod")
    fi
done

echo ""
echo "============================================================"
echo " STDLIB native module build"
echo "============================================================"
echo "  PASS = $PASS"
echo "  FAIL = $FAIL"
echo "  TOTAL= ${#MODULES[@]}"
if [[ $FAIL -gt 0 ]]; then
    echo "  FAILED MODULES:"
    for f in "${FAILED[@]}"; do echo "    - $f"; done
fi
echo "============================================================"

# Aggregate library archive
if [[ $FAIL -eq 0 ]]; then
    AR="${AR:-ar}"
    CC="${CC:-gcc}"
    OBJS=()
    for mod in "${MODULES[@]}"; do
        OBJS+=("$BUILD_DIR/${mod//\//_}.iii.o")
    done

    # Phase C.4: assemble Software Resolution Unit hand-written asm.
    # COMPILER/BOOT/resolver_unit.s -> STDLIB/build/iii/resolver_unit.o
    RU_SRC="$STDLIB_DIR/../COMPILER/BOOT/resolver_unit.s"
    RU_OBJ="$BUILD_DIR/resolver_unit.o"
    if [[ -f "$RU_SRC" ]]; then
        "$CC" -c -ffile-prefix-map="$PWD=." -o "$RU_OBJ" "$RU_SRC"
        echo "[build_stdlib] OK   resolver_unit.s -> $RU_OBJ"
        OBJS+=("$RU_OBJ")
    fi

    # Phase C.4: AVX-512 sibling of the Software Resolution Unit.
    # COMPILER/BOOT/resolver_unit_avx512.s -> STDLIB/build/iii/resolver_unit_avx512.o
    # Exposes iii_resolver_unit_resolve_avx512 (parallel to scalar/AVX-2
    # symbol). Bit-identical output across the full 4096-pattern set.
    RU512_SRC="$STDLIB_DIR/../COMPILER/BOOT/resolver_unit_avx512.s"
    RU512_OBJ="$BUILD_DIR/resolver_unit_avx512.o"
    if [[ -f "$RU512_SRC" ]]; then
        "$CC" -c -ffile-prefix-map="$PWD=." -o "$RU512_OBJ" "$RU512_SRC"
        echo "[build_stdlib] OK   resolver_unit_avx512.s -> $RU512_OBJ"
        OBJS+=("$RU512_OBJ")
    fi

    # Bench: assemble cycle-counting + serialisation helpers hand-written asm.
    # COMPILER/BOOT/bench_helpers.s -> STDLIB/build/iii/bench_helpers.o
    # Exposes bench_rdtsc, bench_rdtscp, bench_cpuid_serialize,
    # bench_pause_loop. Consumed by omnia/bench.iii facade.
    BH_SRC="$STDLIB_DIR/../COMPILER/BOOT/bench_helpers.s"
    BH_OBJ="$BUILD_DIR/bench_helpers.o"
    if [[ -f "$BH_SRC" ]]; then
        "$CC" -c -ffile-prefix-map="$PWD=." -o "$BH_OBJ" "$BH_SRC"
        echo "[build_stdlib] OK   bench_helpers.s -> $BH_OBJ"
        OBJS+=("$BH_OBJ")
    fi

    # COMPILER/BOOT/cpuid_helper.s -> STDLIB/build/iii/cpuid_helper.o
    # Exposes iii_cpuid, iii_xgetbv. Consumed by numera/cpufeat (P4.1: native
    # CPU-feature detection, replacing the kernel32 IsProcessorFeaturePresent
    # umbilical).
    CPUID_SRC="$STDLIB_DIR/../COMPILER/BOOT/cpuid_helper.s"
    CPUID_OBJ="$BUILD_DIR/cpuid_helper.o"
    if [[ -f "$CPUID_SRC" ]]; then
        "$CC" -c -ffile-prefix-map="$PWD=." -o "$CPUID_OBJ" "$CPUID_SRC"
        echo "[build_stdlib] OK   cpuid_helper.s -> $CPUID_OBJ"
        OBJS+=("$CPUID_OBJ")
    fi

    # Phase C.5: hand-written hot-path resolver fast path.
    # COMPILER/BOOT/resolver_hot.s -> STDLIB/build/iii/resolver_hot.o
    # Exposes iii_resolve_hot, called from resolver.iii::resolve() to
    # bypass iiis-0 push/pop spillage on memo-hit invocations.
    RH_SRC="$STDLIB_DIR/../COMPILER/BOOT/resolver_hot.s"
    RH_OBJ="$BUILD_DIR/resolver_hot.o"
    if [[ -f "$RH_SRC" ]]; then
        "$CC" -c -ffile-prefix-map="$PWD=." -o "$RH_OBJ" "$RH_SRC"
        echo "[build_stdlib] OK   resolver_hot.s -> $RH_OBJ"
        OBJS+=("$RH_OBJ")
    fi

    # Build the archive FRESH. ar's `r` (insert/replace) does NOT remove members
    # absent from OBJS, so a module dropped from MODULES (e.g. the sid->crystal_deps
    # rename) leaves a STALE .o baked in -> duplicate L_* symbols under --whole-archive
    # (the cause of run_xii_corpus's 93/93 link failures: a leftover omnia_sid.iii.o
    # colliding with omnia_crystal_deps.iii.o on L_SID_DELTA_DOMAIN etc.). Removing the
    # .a first makes every build contain EXACTLY the current MODULES' objects.
    # -D: deterministic mode (zero timestamps/uids/gids in archive headers).
    # The OBJS list outgrew the single-command ARG_MAX -- "ar: Argument list too long"
    # once the module count crossed ~375 (charter + nous additions).  ar's @response-file
    # reads paths RAW (no MSYS /c/ -> C:\ translation, so ar.exe cannot find them), but it
    # DOES translate real argv -- so feed the objects as argv via xargs (null-delimited,
    # space-safe for the "Edwin Boston" path), batched under ARG_MAX: q=quick-append (c
    # creates the archive on the first batch); a final `s` builds the deterministic index
    # once.  Member order = OBJS order, so the archive stays deterministic.
    # OneDrive/Defender transient-lock hardening (DOCS/III-DISPOSITION-EXECUTION.md): a .o
    # input can be momentarily read-locked during sync -> ar yields an incomplete archive
    # (-> spurious run_corpus "undefined reference" link flakes, the 817 case). Rebuild fresh
    # until the archive exists with a valid symbol index; deterministic content, so a genuine
    # bad input still fails every attempt (never masks a real GATE1 failure).
    for _aa in 1 2 3; do
        rm -f "$BUILD_DIR/libiii_native.a"
        printf '%s\0' "${OBJS[@]}" | xargs -0 "$AR" qcD "$BUILD_DIR/libiii_native.a"
        "$AR" sD "$BUILD_DIR/libiii_native.a"
        { [[ -s "$BUILD_DIR/libiii_native.a" ]] && "$AR" t "$BUILD_DIR/libiii_native.a" >/dev/null 2>&1; } && break
        sleep 1
    done
    echo "[build_stdlib] aggregated -> $BUILD_DIR/libiii_native.a"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$BUILD_DIR/libiii_native.a" > "$BUILD_DIR/libiii_native.a.mhash"
        echo "[build_stdlib] mhash:"
        cat "$BUILD_DIR/libiii_native.a.mhash"
    fi
fi

exit $FAIL
