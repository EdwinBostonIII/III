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

# --- Compiler-rejection conformance gate (reject-path coverage) ---------
# run_corpus.sh exercises only programs that COMPILE and RUN; the compiler's
# diagnostic / rejection path has no other gate. reject_conformance.sh asserts
# every deliberately-malformed fixture in STDLIB/corpus_reject/ is still
# REJECTED (non-zero exit, no object emitted). A regression that made the
# front-end silently ACCEPT malformed input (a swallowed sema/parse error)
# would otherwise pass every other check.
REJECT_GATE="$STDLIB_DIR/scripts/reject_conformance.sh"
if [[ -f "$REJECT_GATE" ]]; then
    echo "[build_stdlib] compiler-rejection conformance: $REJECT_GATE"
    if ! bash "$REJECT_GATE" "$IIIS"; then
        echo "[build_stdlib] FATAL: compiler-rejection conformance failed -- a malformed corpus_reject fixture was ACCEPTED (front-end swallowed a sema/parse error)." >&2
        echo "[build_stdlib]        See STDLIB/corpus_reject/ and STDLIB/scripts/reject_conformance.sh." >&2
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

# --- Compile pre-flight: price the compiler's walls before spending them ------
# KATOPTRON (omnia/katoptron) meters each STDLIB source for the compiler's two
# standing walls -- SEMA_DECL_CAP top-level decls (sema.iii) and the 64-slot
# local declaration ceiling -- and REFUSES a source that would breach, naming
# the file and (for the slot ceiling) the worst fn's line.  The slot ceiling's
# failure is a SILENT exit 14 from the compiler with no message and no line;
# this turns it into a named refusal BEFORE the compile is spent.
# FAIL-OPEN BY DESIGN: katoptron.exe links the archive THIS script produces, so
# on a from-clean build it does not exist yet and this skips -- exactly as the
# drift gates above skip a missing generator.  It runs on every incremental
# build.  katoptron_gate.sh proves the verdict matches the LIVE compiler at the
# exact wall (2048) and ceiling (64), so a REFUSED here is a real breach.
# Override with KATOPTRON_PREFLIGHT=0 (and then file it: a false refusal means
# the meter drifted from the compiler, which katoptron_gate would have caught).
KT_PREFLIGHT="$STDLIB_DIR/build/katoptron/katoptron.exe"
if [[ -x "$KT_PREFLIGHT" && "${KATOPTRON_PREFLIGHT:-1}" != "0" ]]; then
    echo "[build_stdlib] compile pre-flight: katoptron over STDLIB/iii"
    KT_OUT="$STDLIB_DIR/build/_preflight.txt"
    # -d '\n': this tree lives under a path with a space ("Edwin Boston"); default
    # xargs word-splitting would fragment every path (the vacuous-census trap).
    find "$STDLIB_DIR/iii" -name '*.iii' | xargs -d '\n' "$KT_PREFLIGHT" preflight > "$KT_OUT" 2>&1 || true
    if grep -q '^katoptron: REFUSED' "$KT_OUT"; then
        grep '^katoptron: REFUSED' "$KT_OUT" >&2
        echo "[build_stdlib] FATAL: a STDLIB source would breach a compiler wall (named above)." >&2
        echo "[build_stdlib]        Slot ceiling: hoist locals in the named fn to a module-level var. Decl wall: cut a top-level decl, or raise SEMA_DECL_CAP (and katoptron's KM_WALL) together." >&2
        echo "[build_stdlib]        This is the compiler's silent exit-14, named ahead of time. Override: KATOPTRON_PREFLIGHT=0." >&2
        exit 2
    fi
    if grep -q '^katoptron: cannot open' "$KT_OUT"; then
        echo "[build_stdlib] WARN: pre-flight could not read some sources (not treated as a breach)." >&2
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
    "numera/idfold"
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
    "numera/siphash"
    "numera/adler32"
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
    "aether/glossa"
    "aether/iform"
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
    # numera/weave_blocks -- THE UNIFIED WEAVE: shared proven primitive building blocks (ARX mix shared by
    # ChaCha + Blake2; more to come) that the borrowed primitives now route through.  No island -- the unification.
    "numera/weave_blocks"
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
    # zk_field/zk_snark/zk_stark/zk_air/zk_rev/zk_prune RETIRED 2026-07-17 (Z supersession,
    # commit 51c9bd70): the entire zk-STARK/SNARK/FRI subsystem retired in full -- III verifies
    # exactly (proofcarry Z2 scrolls), or not at all.  Rows removed when Phi-3 surfaced the
    # stale roster (build_stdlib counted 10 missing modules every run since the retirement).
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
    # numera/zk_stark_seal RETIRED 2026-07-17 (Z supersession, 51c9bd70)
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
    "aether/inet6"
    "verba/semver"
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
    # APOTHEOSIS C.11: the tier-aware certified-monotone pacemaker -- constitutional-constant
    # timeouts (no-ML), monotone+bounded backoff (liveness), explicit BFT 2f+1 quorum. Safety stays
    # the mhash vote-block match in hotstuff.iii. Compiler-unreferenced -> LIBNATIVE.
    "aether/hotstuff_unified"
    # (the APOTHEOSIS C.11 "tournament quorum optimizer" comment that stood here described a module
    #  never built -- struck by the reunification S7 sweep; C.11's status lives in III-APOTHEOSIS.md)
    "numera/sha3_256"
    "numera/sha3_512"
    "numera/shake128"
    "numera/shake256"
    "numera/pq_params"
    "numera/ntt_ctx"
    "numera/keccak_sponge"
    "numera/mldsa"
    "numera/mlkem"
    # aether/pq_quorum -- POST-QUANTUM federation quorum certificates: BFT 2f+1 over ML-DSA votes (survives a
    # quantum adversary that could forge the classical Ed25519 QC).  Additive; composes numera/mldsa.
    "aether/pq_quorum"
    "numera/slhdsa"
    "numera/pq_dispatch"
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
    # aether/cap_zkp -- ZK-Delegated Anonymous Capabilities: a cap proven a valid merkle leaf (rights/expiry
    # bound by cad) without revealing cap id/parent; composes numera/merkle + cad.
    "aether/cap_zkp"
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
    # intent/ -- INTENT-TO-EXECUTION lexical disambiguation: human intent collapsed by bitwise intersection
    # of a fixed FNV-1a ontology; popcount decides RESOLVE/CONTRADICTION/AMBIGUOUS.  Composes verba/rune + sat_arith.
    "intent/lex_ontology"
    "intent/intent_lex"
    "intent/disambiguate"
    # intent Phases 4-5: a resolved intent -> a temporally-bounded capability (Perfectly-Executed-Mistake
    # safeguard) emitted only under the human's Ed25519 signature over the Capability Manifest.
    "intent/synthesis_bridge"
    "intent/intent_attest"
    "verba/intent"
    "verba/ast_intent"
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
    # katabasis/cpu_census -- THE UNIVERSAL SELF-IDENTITY CRYSTAL: the CPUID-derived counterpart to census (which is
    # GPU/PCI-specific, not CPUID-derivable).  Built PURELY from the live CPUID oracle (numera/cpufeat) -- vendor /
    # family-model-stepping / logical-count / hypervisor / feature-summary -- content-addressed (sha256).  Universal
    # (any x86-64 machine), safe (unprivileged CPUID), virtualization-transparent, no hardcoded facts.  KAT 1813.
    "katabasis/cpu_census"
    # katabasis/pci_enum -- the LIVE-side deriver for census's GPU/PCI facts: pure PCI config-space decoders (the real
    # PCI Local Bus encoding) + pci_enum_consider (2-param, cg_r0-safe) that DERIVES VEN/DEV/rev/BAR0/BAR1/BAR3 from
    # raw config dwords supplied by ANY backend (a synthetic buffer in the corpus, or live CF8h/CFCh reads in the
    # Ring-0 gate driver).  Reproduces census's sealed GPU facts from a faithful config; the metal read is the gate
    # driver's IOCTL.  KAT 1814.
    "katabasis/pci_enum"
    # KATABASIS metal-architecture POCs (deep-think/architect): the staged-typed descent IR.
    "katabasis/crystal_cap"       # crystal-as-capability mint (depth-cap from CPUID; Active ops consume) -- KAT 1817
    "katabasis/stage"             # Ousia/Hypostasis/Energeia staged typing (weave can't execute until crystal-bound) -- KAT 1818
    "katabasis/behavioral_seed"   # behavioral bootstrap seed (more basal than CPUID: known-answer logic self-test + quine) -- KAT 1819
    "katabasis/behavioral_fp"     # behavioral fingerprint + claim cross-check (functional drift vs the CPUID claim) -- KAT 1820
    "katabasis/descent_proof"     # proof-carrying descent (each rung bound to its precondition by content-address) -- KAT 1821
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
    "numera/verified_ripple"
    "numera/optimality_cert"
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
    "numera/vectorizer"
    "numera/bce"
    "numera/reduced_product"
    "numera/loop_pipeline"
    "numera/reg_alloc"
    "numera/list_schedule"
    "numera/isel"
    "numera/dominators"
    "numera/ssa"
    "numera/gvn"
    "numera/dce"
    "numera/sccp"
    "numera/taint_analysis"
    "numera/range_check"
    "numera/translation_validation"
    "numera/liveness"
    "numera/proof_replay"
    "numera/bmc"
    "numera/dijkstra"
    "numera/safety_prover"
    "numera/value_range_prover"
    "numera/loop_bounds_prover"
    "numera/branch_elim"
    "numera/rms"
    "numera/binary_search"
    "numera/kmp"
    "numera/levenshtein"
    "numera/fenwick"
    "numera/segment_tree"
    "numera/knapsack"
    "numera/inversion_count"
    "numera/coin_change"
    "numera/lcs"
    "numera/lis"
    "numera/sieve"
    "numera/gray_code"
    "numera/catalan"
    "numera/conjecture_probe"
    "numera/bv_ring"
    "numera/congruence"
    "numera/sat"
    "numera/bv_bits"
    # numera/invent -- the Generative Invention Loop: de-novo cost-directed law synthesis (value-sieve + SAT judge).
    "numera/invent"
    # numera/logic6 -- the completed six-valued bounded lattice (De Morgan algebra): paraconsistency + null-safety, lean.
    "numera/logic6"
    # numera/present -- the Rosetta layer: render + content-address-name III\'s discoveries as human-readable New Math.
    "numera/present"
    # numera/primweb -- the PRIMITIVE SPIDERWEB: SAT/kernel-proven strands (the common denominators) between
    # III\'s own NIH crypto blocks -- rotation-direction duality (ChaCha<->Blake2) + shared-ARX-atom bijection.
    # The first threads of the proven bitvector weave; composes numera/bv_bits -- no island.
    "numera/primweb"
    # numera/weave -- THE WEAVE (the variable `i`): lift a binary computation into the six-valued don't-care
    # weave, collapse through the freedom, lower back to 2-state PROVEN equal on the care-set.  The universal
    # optimization procedure; composes numera/bv_bits + numera/logic6 -- no island.
    "numera/weave"
    # numera/weave_interfile -- THE REPOSITORY-LEVEL WEAVE: inter-file logic as proven mathematics; capability #1,
    # inter-file don't-care annihilation (a shared block's unused feature vanishes for a caller, proven sound).
    "numera/weave_interfile"
    # numera/weave_forge -- THE AUTONOMOUS WEAVE FILLER: the GIL fills its own spiderweb (self-directed
    # discovery+proof+cost-selection+naming, looping); composes invent + present + the cost-truth -- no island.
    "numera/weave_forge"
    "numera/barrett"
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
    # (the APOTHEOSIS C.14 "provable cycle bound" comment that stood here described a module never
    #  built, composing the equally-unbuilt C.8 manifold -- struck by the reunification S7 sweep)
    "aether/bone_marrow"
    "aether/basal_probe"
    # --- CONVERGENCE Wave 3 (12; deps built or earlier in this block; appended to preserve BSS layout) ---
    "numera/temporal_logic"
    "numera/computation_graph"
    "numera/memo_lattice"
    "numera/theorem_carrier"
    "numera/synthesis_spec"
    "aether/reversibility_audit"
    "aether/vbd"
    "aether/flow_firewall"
    "aether/sentinel"
    "aether/enclave"
    "aether/sealed_box"
    "aether/replay_box"
    "aether/compute_box"
    # aether/xii_sort_meter -- the R042 sort-penalty tier: charges an R042 site's geometric weight to the
    # compute-box CPU meter, bounding adversarial owner-domain sorts.  Composes xii_rewrite + xii_canonicalise + compute_box.
    "aether/snapshot_box"
    "aether/sid_router"
    "aether/determinism_firewall"
    "aether/develop_up"
    "aether/attest_box"
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
    "omnia/xii_cost_monotone"
    "omnia/xii_denote"
    "tempora/duration_cert"
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
    # event_substrate: the TEMPORAL dual of ripple_field -- the EVENT is primary, STATE is a fold over the
    # perceived-event history; finite + infinitary (parity-acceptance) folds.  parity_game: the proven
    # recursive Zielonka solver (lifted from grail 1839) it cross-checks against (corpus 1902).  Both
    # zero-extern, BSS-neutral, compiler-unreferenced (consumed by corpus 1900/1901/1902).
    "omnia/event_substrate"
    "omnia/parity_game"
    # exec_cert: the witnessed EXECUTION CERTIFICATE -- fold a real III transform into a reproducible,
    # tamper-evident cad-sha256 certificate, INCREMENTALLY (streaming, O(1)/event, frozen prefix in the
    # hash state -- the bounded-regard fold).  Consumed by corpus 1908 (real xii_canonicalise cert) +
    # 1910 (the grail/wall verb-geometry web).  Zero-extern beyond sha256; BSS-neutral.
    "omnia/exec_cert"
    # isub: THE IMMUTABLE METAL BUS (Ring -1 bedrock of the inverse substrate) -- an append-only log of
    # UNIFORM GEOMETRIC BLOCKS <verb in {BELOW,REFLECT}, a, b> with CONTENT-ADDRESSED VERBS: a verb's
    # identity is sha256(geometric footprint), never a name.  The name-gate structurally rejects any verb
    # outside {0,1} (a name packed into the verb slot).  Witnessed by the streaming exec_cert (O(1)/event).
    # Consumed by corpus 1913 (the CAV RED-probe); reuses the sealed exec_cert + cad -- zero new crypto,
    # BSS-neutral, compiler-unreferenced.  Phase 0 of the Master Logic Assimilation (DOCS/III-INVERSE-LIBRARY.md).
    "omnia/isub"
    # --- DOME DELETED (was omnia::dome + dome_audit + dome_society) -- a PoC miniature-precursor EIDOS, not
    # an organ.  Its rewind/provenance was re-homed into omnia/event_substrate (evt_mark/evt_rewind/
    # evt_provenance_count), which eidos/field now stands on ALONE (one append-only reversible log).  The PoC
    # society/audit was corpus-only (1903/1904/1905/1982, removed); the re-homed capability is gated by
    # corpus 1903_event_rewind + the reseal path 2035_seraphyte_eidos.
    # xii_isub: PHASE 1 of the Master Logic Assimilation -- XII ENCAPSULATED.  Drives the REAL xii_rewrite
    # to fixpoint, emitting each real firing as a BELOW reduction-step into the witnessed isub bus; derives
    # "the current term" as a pure FOLD over that history (state = side-effect of events), with time-travel
    # (xii_isub_prefix) the state-mutating XII discards.  Consumed by corpus 1914.  Externs isub + the live
    # xii_rewrite -- authors no new rewriting, no new crypto; BSS-neutral, compiler-unreferenced.
    "omnia/xii_isub"
    # unravel: PHASE 2 -- THE UNRAVELING ENGINE.  A pure fold that strips a real execution trace on the isub
    # bus to its GEOMETRY (strict-descent chain height, acyclicity/lasso, infimum) and synthesises a VERB
    # (REDUCE/RECUR/IDENTITY/REFLECT) for every transition -- proving from the witness that III's rewriting
    # is a terminating strict descent, with no black box surviving.  Consumed by corpus 1915; reads only the
    # sealed isub bus -- zero new state, BSS-neutral, compiler-unreferenced.
    "omnia/unravel"
    # assimilate: PHASE 3 -- SEQUENTIAL GRAIL ASSIMILATION into ONE executable verb-geometry web.  The
    # inverse-form harvest of logos: the web is the isub bus; each logic system is shattered to uniform
    # {BELOW,REFLECT} blocks and absorbed one INTO the web, recognition by CONTENT-ADDRESS (sha256 of
    # geometry) so shared structure is merged once (zero redundancy).  The web is EXECUTABLE -- meet/join/
    # complement recovered from the geometry compute every system's logic, dissolving named primitives.
    # Consumed by corpus 1916; reads/writes only isub + cad -- zero new crypto, BSS-neutral, compiler-unref.
    "omnia/assimilate"
    # reverse_search: PHASE 4 -- REVERSIBLE SEARCH (the Dome's ECHO/TIDE) over the assimilated web.  A search
    # a classical deterministic strategy cannot survive (it greedily iterates complement, a real involution,
    # and oscillates forever -- FATAL) is survived by EVADE-BY-LIVING: live the move, detect the lasso,
    # rewind (retain the failed branch as provenance), record ANTI-GEOMETRY, re-choose a climb -> ALIVE.  The
    # anti-geometry PERSISTS, so the system gets smarter.  Consumed by corpus 1917; reads only the assimilate
    # web -- BSS-neutral, compiler-unreferenced.
    "omnia/reverse_search"
    # master_logic: PHASE 5 -- SUBSUMPTION + CAPSTONE (deprecation by attrition).  Takes the REAL named
    # primitive logic6 (l6_and/l6_or/l6_not) as a BLACK BOX, shatters its behaviour into bare geometry (the
    # order DERIVED from l6_and -- no logic taken as gospel), and PROVES the web's universal verbs reproduce
    # it exactly over all values (assim_meet==l6_and, etc.).  ml_named_is_redundant is the sovereign in-III
    # gate certifying a name is provably a geometric fold -- the justification for retiring it.  Consumed by
    # corpus 1918; reads logic6's behaviour + the assimilate web -- BSS-neutral, compiler-unreferenced.
    "omnia/master_logic"
    # ingest: THE SPINE -- wires Phase 1 (xii_isub, real-XII trace) + Phase 2 (unravel, geometry extractor)
    # into Phase 3 (assimilate).  Carries a real execution's shattered geometry past an isub_reset and
    # commits it into the Master Web by content-address (deduped) -- the web is built from REAL executions,
    # not block literals.  Consumed by corpus 1923; reads only isub + assimilate.  BSS-neutral, compiler-unref.
    "omnia/ingest"
    # enmesh: enmesh TWO REAL named logics (logic6 + voice) into ONE web by their COMMON DENOMINATOR, shattered
    # from BEHAVIOUR onto a canonical frame (bottom->0, top->1); the shared frame merges by content-address.
    # The web computes BOTH real systems via the same verbs.  Consumed by corpus 1924; reads logic6/voice +
    # the assimilate web.  BSS-neutral, compiler-unreferenced.
    "omnia/enmesh"
    # canon_enmesh: ROADMAP 1b -- the STRUCTURAL-ROLE canonical mapper.  Addresses a point by its order-RANK
    # (below-count), a complete canonical label for a CHAIN -- so two isomorphic chains (voice, trit: the same
    # 3-valued Kleene algebra) map to identical addresses and FULLY merge (the 2nd adds zero blocks).  Honest
    # boundary: rank collides on a non-chain (logic6) -- full canonization is GI-hard.  Consumed by corpus
    # 1926; reads voice/trit/logic6 + the assimilate web.  BSS-neutral, compiler-unreferenced.
    "omnia/canon_enmesh"
    # law_web: ROADMAP 2 -- the T2 abstract-domain LAW-WEB.  interval_lattice + cost_lattice have INFINITE
    # carriers (¬R3, cannot be element-merged), so they are unified at the LAW level: each certified to conform
    # to the SAME bounded-lattice axiom-set (idempotence/commutativity/absorption/associativity) over sampled
    # elements via its own real ops.  Consumed by corpus 1927; reads interval_lattice + cost_lattice.
    # BSS-neutral, compiler-unreferenced.
    "omnia/law_web"
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
    "numera/bv_commons"
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
    # numera/isa_macro_synth -- autonomous ISA macro synthesis driver: bisim-gated, refute-by-default, feeds
    # the live sov_isa adoption.  Composes proof_bisimulation + sov_isa.
    "numera/isa_macro_synth"
    "forcefield/cg_surgical_strike"
    "forcefield/scythe_census"
    "forcefield/sovereign_optimizer"
    # Path C: the single-source SR rule table + CIC kernel certifier (width-invariance guard +
    # per-rule BV64 proof) that the cg_optrules_bind_gate binds to cg_r3's real `shl` emission.
    "forcefield/cg_opt_rules"
    # The verification missile on III's LIVE rules: drives the real xii_canonicalise
    # engine over the trit fragment and verifies it against an INDEPENDENT Kleene spec
    # (non-tautological, unlike corpus 670).  Externs only the live XII engine.
    # (merged missiles: rule_verify + fusion_verify + iflift_verify -> ONE battery, per III-PERFECTION-LEDGER)
    "omnia/xii_semantic_verify"
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
    # SERAPHYTE Phase-1 keystone: the deterministic INTEGER K-functor K=C*H*R over the
    # ripple_metric graph (C=saturating good-complexity, H=good/(good+noise) coherence,
    # R=communion penalised by separation). Fixed source-constant weights; NO floats, NO
    # learned values (Canon VII no-ml). Resolves the Seraphyte spec's Open Question O6/M1
    # (K measurement) by construction. Composes ripple_metric. Compiler-unreferenced ->
    # LIBNATIVE. See DOCS/III-SERAPHYTE-INTEGRATION-PLAN.md.
    # SERAPHYTE Phase-8 energy ledger: the semantic-energy economy (NOUS-units) made PHYSICALLY
    # real -- NU = region bytes, so conservation (used+remaining==capacity) is the allocator's own
    # invariant; catabolism income = dead edges a cut frees (same ripple_metric graph the K-functor
    # rewards); starvation = arena-cap exhaustion (the one honest death: immortal vs error, mortal vs
    # physics, Canon X). Composes memoria/arena + ripple_metric. Compiler-unreferenced -> LIBNATIVE.
    # SERAPHYTE membrane (M) + judgment (KRISIS): the unified admission boundary -- behaviour
    # preservation (rm_cut_valid) AND the 5-dim commit_gate (cg_decide: rule/module/seal/conservative/
    # KERNEL) AND the inverted-2nd-law K-ratchet (sk_kvalue). ADMIT iff all three; located reject codes
    # (prove-both-arms). The behavioural-immortality safety property as a gated faculty. Composes
    # commit_gate + ripple_metric + ser_kvalue. Compiler-unreferenced -> LIBNATIVE.
    # SERAPHYTE capstone -- the autopoietic loop, ALIVE: binds membrane + K-functor + energy into one
    # living cycle with the inverted-2nd-law as PERSISTENT down-only state (the K-floor ratchet). The
    # organism emerges, grows (K climbs through the membrane, energy-positive), cannot regress (ratchet
    # refuses), cannot die from error (membrane refuses fatal moves) -- only from physics (energy/arena).
    # Composes ser_membrane + ser_kvalue + ser_energy + ripple_metric + commit_gate. -> LIBNATIVE.
    # SERAPHYTE on a REAL target: runs the loop on III's actual crypto-primitive proof-web
    # (numera/weave_graph -- SHA-2 Ch/Maj, rotations as bv circuits). LIVE membrane (ws_edge_proven =
    # SAT-proven equivalence, not modelled), real cost-truth K-gain (ws_node_cost_at AND-gate count),
    # real obsolescence (ws_strand_retires), both arms (refuses Ch<->Maj, proven distinct). Phase-4
    # real-target liveness, no synthetic fixture. Composes weave_graph. -> LIBNATIVE.
    # SERAPHYTE commit-half: the organism COMMITS (changes state) by sealing a kernel-proven optimisation
    # into its phenome -- composes forcefield/cg_autocatalyst (cga_dispose: dream->kernel tc_check->cad-seal,
    # the ONLY autonomous commit III permits; volatile registry, permanent source stays operator-gated).
    # Grows monotonically with proven optimisations, never commits a false one (cga_all_true). -> LIBNATIVE.
    # SERAPHYTE discovery (step 1 of the real deliverable, NOT a wrapper): the organism DISCOVERS
    # strength-reductions by SEEDED SEARCH (egraph_stochastic, handed no candidates), proves each at the
    # kernel membrane (cg_autocatalyst), and verifies every discovered-proven reduction IS III's LIVE cg_r3
    # codegen emission (COMPILER/BOOT cg_opt_rules cgopt_mul_admit/shift_k -- the real mul->shl emit law).
    # Connects discovery -> proof -> a real emit path. Composes egraph_stochastic+cg_autocatalyst+cg_opt_rules.
    # SERAPHYTE autonomous optimisation metabolism (done right -- composes EXISTING robust engines, not a
    # hand-rolled disposer): drives cg_autocatalyst's autonomous-discovery faculties -- cga_mixed_discover
    # (6 mixed bitwise-arith strength laws, bv_bits SAT/UNSAT) + cga_bv_discover (pow2 strength diagonal,
    # BV64 kernel) -- proving machine-faithful peephole optimisations and refusing the unsound (SAT
    # countermodel = real teeth). The mixed/shift laws are outside cg_r3's pow2-only strength reduction.
    # Every component clean-probe-verified robust in isolation. Composes cg_autocatalyst + bv_bits + cg_opt_rules.
    # SERAPHYTE as PROCESS (the architectural pivot: event-based, not object-based): expresses the
    # Seraphyte's life on omnia::isub (the Ring-(-1) Merkle-witnessed metal bus = the spec's CHORA), the
    # way omnia::xii_isub encapsulates XII. Membrane-PROVEN optimisations become content-addressed BELOW
    # ripples (replayable + tamper-evident life; state = FOLD over the log); autopoiesis = event_substrate's
    # evt_detect_cycle (cycle 0 = progress/terminates, cycle>0 = the self-sustaining loop). Composes isub +
    # cg_autocatalyst + event_substrate. The symbiosis with the existing pathways, no island. -> LIBNATIVE.
    # SERAPHYTE immune-ripple (resilience #7): a proven-BAD rewrite becomes a vaccine. The SAT membrane
    # (bv_bits) judges a candidate; the verdict is a witnessed isub ripple -- proven-equal=BELOW (good),
    # proven-distinct=REFLECT (the immune anti-event). im_is_immune folds the shared bus so any consumer
    # NEVER retries a refuted rewrite (immune memory; tamper-evident; observation-free = a proof not a
    # frequency). Composes isub + bv_bits. -> LIBNATIVE.
    # SERAPHYTE cross-prover differential (trust/soundness monitor): two INDEPENDENT deciders over Z/2^64
    # -- bv_ring (polynomial) + bv_bits (Tseitin/CDCL SAT) -- cross-check each other on a shared add/shift
    # law; agreement on both arms + a FORCED discrepancy detected (catches a prover regression in the
    # trusted base), witnessed on isub. No new prover -- a regression detector. Composes bv_ring+bv_bits+isub.
    # SERAPHYTE memoised proving (efficiency): the witnessed substrate means never prove twice. sm_step
    # FOLDS the shared isub bus before proving -- a KNOWN candidate (BELOW good / REFLECT bad-vaccine) is
    # SKIPPED with no prover-call; each distinct candidate meets the prover at most ONCE, ever, across the
    # whole process + every instance folding the same content-addressed log. Cost metric proves the saving.
    # Composes bv_bits + isub. -> LIBNATIVE.
    # === Seraphyte FIRST WAVE (corpus 2004-2015): complete organs the prior session wrote + KAT'd but left
    # UNREGISTERED (orphans -- their KATs were in run_corpus EXPECTED yet could not link). Now integrated:
    # the autopoietic core (kvalue/energy/real/membrane), the loop stages (commit/discover/optimize), the
    # proving infrastructure (immune vaccine / cross-prover diff / memoised proving / isub witnessed bus), and
    # the autopoiesis loop itself (composes energy+kvalue+membrane via the re-exported sm_admit). ===
    "numera/ser_kvalue"
    "numera/ser_energy"
    "numera/ser_real"
    "numera/ser_membrane"
    "numera/ser_commit"
    "numera/ser_discover"
    "numera/ser_optimize"
    "numera/ser_immune"
    "numera/ser_diff"
    "numera/ser_memo"
    "numera/ser_isub"
    "numera/ser_autopoiesis"
    "numera/ser_petri"
    "numera/ser_cegis"
    "numera/ser_antiunify"
    "numera/ser_absint"
    "numera/ser_cascade"
    "numera/ser_cascade2"
    "numera/ser_regalloc"
    "numera/ser_egraph"
    "numera/ser_intent"
    "numera/ser_tgraph"
    "numera/ser_kinduct"
    "numera/ser_causal"
    "numera/ser_tdriver"
    "numera/ser_kinduct_sym"
    # mathesis_admit -- THE MATHESIS LIBRARY DOOR (Xi0-T1, DOCS/III-MATHESIS-MAP.md s6): the strict four-clause
    # admission conjunction (PROVEN/NOVEL/USEFUL/WITNESSED) + canonical schema theorem_id + the tamper-evident
    # mhash chain for MATH_LIBRARY.sealed.  Composes numera/cad only.  Gate: corpus/2600. -> LIBNATIVE.
    "numera/mathesis_admit"
    # mathesis_measure -- THE MATHESIS MEASURE INSTRUMENT (Xi0-T2): opcode-synchronous window census over
    # real emitted gen_svir containers; picks the seed schema (measure-first law) + discharges USEFUL's
    # occurrence>0.  Width law mirrors sovir/svir_interp op_w.  Gate: corpus/2602. -> LIBNATIVE.
    "numera/mathesis_measure"
    # mathesis_define -- THE MATHESIS DEFINITION DOOR (Xi8-T1, the creator tier, III-MATHESIS-MAP.md s3b):
    # concept (MXD1) + concept-law (MX02) descriptors, content-addressed ids, the strict concept-tier
    # conjunction (SPEC-BRIDGED/LAW-RICH/MEASURED/WITNESSED -- a lawless definition is a macro, REFUSED);
    # shares the theorem tier's chain law (conservative extension: vocabulary, never axioms).  Composes
    # numera/cad only.  Gate: corpus/2670. -> LIBNATIVE.
    "numera/mathesis_define"
    # mathesis_synth -- THE MATHESIS SYNTHESIZER (Xi1 pulled forward): NO human candidates -- enumerates
    # the ENTIRE declared expression space (18,522 pairs, printed bound) in canonical order, strict
    # emission-cost decrease, every pair through seq_equiv; what survives is MACHINE-SYNTHESIZED,
    # MACHINE-PROVEN forall-schema mathematics (Ax D3: structure only).  Composes ser_kinduct_sym + cad.
    # Gate: corpus/2610. -> LIBNATIVE.
    "numera/mathesis_synth"
    # mathesis_novel -- THE NOVELTY + SEMANTIC-DEDUP ORGAN (Xi1-T2, R3): the library holds PROPOSITIONS --
    # commutative-canon + fingerprint-bucketed seq_equiv dedup of the discovery stream, and the COMPUTED
    # novelty verdict (taught-e-graph derivability; mul-bearing/cap-saturated => honest abstain, never a
    # certificate).  Composes mathesis_synth + ser_kinduct_sym + ser_egraph.  Gate: corpus/2611. -> LIBNATIVE.
    "numera/mathesis_novel"
    # mathesis_frontier -- THE FRONTIER QUEUE (Xi1-T3/P5/R7): abstained pairs catalogued with blockers NAMED,
    # counted, and RETRIED -- the live width-indexed R7 retry (bb_reset(w)+sd_denote, mul-assoc proven at
    # w=8/16 while the w=64 wall stays queued; a false pair REFUTED; poison => abstain).  Composes
    # mathesis_synth + ser_kinduct_sym + bv_bits.  Gate: corpus/2612. -> LIBNATIVE.
    "numera/mathesis_frontier"
    # mathesis_deduce -- THE DEDUCTION ORGAN (Xi10): theorems-from-theorems -- forall-n-in-NAT entries by
    # induction whose EVERY leg is machine-checked (natrec eliminator typed by the CIC kernel; premise ids
    # re-derived from canonical descriptors; base+step re-discharged by the finite judge; two-path ground
    # instances).  Composes typecheck + ser_kinduct_sym + mathesis_admit + cad.  Gates: corpus/2676+2677.
    # -> LIBNATIVE.
    "numera/mathesis_deduce"
    # mathesis_agenda -- THE RESEARCH AGENDA (Xi13): intent as measured value (occurrences x cost-delta),
    # deterministic total order, FNV reproducibility fingerprint; an unmeasured item is REFUSED (auditable
    # intent, Ax D3-clean).  A sorter over the other organs' measurements -- no new measurement source, no
    # belief.  Gate: corpus/2683. -> LIBNATIVE.
    "numera/mathesis_agenda"
    # mathesis_telescope -- THE EMPIRICAL TELESCOPE (Xi12): machine-found denesting theorems over the
    # declared sqrt(a+2 sqrt b) grid -- integer Vieta decision (engine 2) + the Sigma-sqrt exact web
    # (engine 1, ui_sqrt_sum_sign) dual-certifying every finding; non-square disc = the non-denestability
    # certificate; out-of-envelope = honest abstain.  Composes aether/sqrt_sum_sign only.  Gates:
    # corpus/2680+2681. -> LIBNATIVE.
    "numera/mathesis_telescope"
    # ser_eidos -- THE RESEAL DECISION WITNESSED ON THE REAL eidos/field substrate (not dome, the superseded
    # POC). The autopoietic accept/rollback was CLAIMED event-driven/on-EIDOS but ran on nothing III consumes;
    # this records the driver's REAL gate verdict on the field: ACCEPT -> a witnessed field_record; REFUTE ->
    # field_rewind, the abandoned rule retained as field_provenance (immune memory). CONSUMED BY the reseal
    # driver (seraphyte_reseal_driver.sh), not a test. Composes eidos/field + cg_autocatalyst. -> LIBNATIVE.
    "numera/ser_eidos"
    # ser_pipeline -- THE FULL SERAPHYTE PIPELINE: collapse+intent+intuition+alignment in ONE fold, the fold
    # the reseal driver CONSUMES to make its real self-modification decision (so each organ is load-bearing:
    # INTUITION ser_cegis synthesizes the descriptor, INTENT ser_intent merges on proof, COLLAPSE
    # ser_cascade/cascade2/regalloc, ALIGN ser_tdriver, WITNESS ser_eidos). Composes those organs only. -> LIBNATIVE.
    "numera/ser_pipeline"
    # EIDOS Verification Membrane (DOCS/III-EIDOS-VERIFICATION-MEMBRANE-PLAN.md): ser_fsm = the parametric
    # finite-state substrate that lifts the hardcoded mutex out of ser_kinduct (Phase 0).
    "numera/ser_fsm"
    # ser_protocol = concurrent protocols encoded as transition relations, so ser_tgraph's real BMC + ser_kinduct's
    # real k-induction model-check them (the input is a protocol, not a hand-fed trace).
    "numera/ser_protocol"
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
    "forcefield/ripple_apply"
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
    # --- harmony #3: Pareto route planner over the one category (KAT 1390); appended last ---
    "omnia/tp_planner"
    # --- the executable coverage ledger (KAT 1391 + the ratchet gate below); appended last ---
    "sanctus/corpus_coverage"
    # --- AUTOGENESIS Wave B: the content-addressed self-image keystone (sanctus::self_model).
    # Promotes corpus_coverage audited export call graph into a Merkle DAG with one 32-byte root
    # that changes iff structure/coverage/proof/cost changes.  Externs corpus_coverage + cad
    # (built above); compiler-unreferenced -> LIBNATIVE only; appended last (BSS-neutral).
    "sanctus/self_model"
    # --- AUTOGENESIS Wave C: the proposer organs.  Each reads the frozen self_model interface and
    # rides an existing engine (no island): gap_conjecture extends the nous_conjecture_gen
    # propose->dispose discipline with a structural law table, honouring the nous_search trichotomy.
    "nous/gap_conjecture"
    # harmony_synth: enumerates composition arrows over the self-model, ranks by Pareto, and admits
    # each ONLY through the certified_morphism kernel gate (an arrow is a proof-carrying theorem).
    "nous/harmony_synth"
    # refactor_propose: an e-graph equivalence prover for whole exports (COMBINE) + dark-export cuts
    # (CUT); rp_certify integrates e-graph evidence + a CIC proof through commit_gate, merging the
    # congruence ring only on admission.
    "nous/refactor_propose"
    # optimize_self: cost-gradient descent gated by the analytic cost oracle (microarch_model) with a
    # hard result-equivalence gate (a cheaper move that changes an answer is rejected); journals moves
    # via ripple_journal and rides the ripple_loop closed loop (self-edits nothing when kernel down).
    "nous/optimize_self"
    # --- AUTOGENESIS Wave D: long-term memory.  theorem_grow is a persistent, tamper-evident,
    # re-verified theorem DAG on disk; on reload every proof is re-checked through the kernel, so a
    # false or tampered record is refused, never trusted.  tg_count is the monotone ratchet floor.
    "nous/theorem_grow"
    # --- AUTOGENESIS Wave E: THE GATEWAY.  sanctus/autogenesis closes the loop: one cap-gated cycle
    # gathers candidates from the proposers, stages them in a reversible vbd transaction, attests the
    # before/after state roots, extends a genesis-anchored hash-chained ledger, and either commits
    # (apprentice-gated) or rolls back byte-exact.  Composes all six organs + vbd + attest_box.
    "sanctus/autogenesis"
    # --- AUTOGENESIS CLI: sanctus/autogenesis_cli -- the context-aware native command surface.  agc_run
    # parses a text command line and DISPATCHES to self_model/theorem_grow/autogenesis (a lean front-end,
    # adds no new authority -- cycle/commit run under the agc_attach session cap).  A complete production
    # module (compiles clean; deps all above) that was authored but never added to MODULES, so corpus 1410
    # -- which covers its agc_attach/agc_exec exports -- could not link.  Restored here.
    "sanctus/autogenesis_cli"
    # --- THE SELF-AWARENESS SEAM (omnia::self_atlas): the III-native self-model of its OWN
    # module dependency graph -- the cartographer machine brought INSIDE III so the
    # generative organs can query blast-radius / would-this-refactor-cycle / is-this-edge-
    # redundant BEFORE they act.  Pure leaf: externs only mhash (built far above), referenced
    # by nothing in the production link (corpus 1666 + the generated self_atlas_data drive it).
    # Compiler-unreferenced -> LIBNATIVE only; appended last (BSS-neutral).
    "omnia/self_atlas"
    # The generated self-model DATA (STDLIB/scripts/gen_self_atlas.py): the III-own module
    # dependency graph (591 nodes / 1170 edges) loaded into self_atlas at runtime.  Externs
    # only self_atlas (above); compiler-unreferenced -> LIBNATIVE only; appended last.
    "omnia/self_atlas_data"
    # The emergence-analysis lens (omnia::self_atlas_lens): what III SEES through its self-
    # model -- orphans, cycle-cores, redundant-dependency refactor proposals, coupling, the
    # steepest hub.  Externs only self_atlas (above); compiler-unreferenced -> LIBNATIVE; last.
    "omnia/self_atlas_lens"
    # III maps ITSELF in III (omnia::self_cartographer): walks a source tree via aether/fs,
    # parses each module from-target dependency edges and populates self_atlas -- the native
    # replacement for the external graph generator.  Externs fs + self_atlas (above);
    # compiler-unreferenced -> LIBNATIVE only; appended last.
    "omnia/self_cartographer"
    # III writes its OWN emergence dashboard in III (omnia::self_report): composes verba/builder
    # + verba/format to render the self-model summary and aether/fs to write it -- retiring the
    # last non-III step.  Externs builder/format/fs/self_atlas/self_atlas_lens (above);
    # compiler-unreferenced -> LIBNATIVE only; appended last.
    "omnia/self_report"
    # III emits its OWN self_atlas_data.iii in III (omnia::self_emit): renders the loaded
    # self-model as compilable .iii source (intern/link helpers + load + the expect functions)
    # via verba/builder + verba/format, written with aether/fs -- the native replacement for the
    # Python fixture generator.  Externs builder/format/fs/self_atlas/self_atlas_lens (above);
    # compiler-unreferenced -> LIBNATIVE only; appended last.
    "omnia/self_emit"
    # --- PHASE III (III-PHASE3-WALLS) Campaign I: defeat combinatorial explosion.  nous/beam_search is a
    # CERTIFIED PORTFOLIO: K seeded gated annealed walks (verified_search) whose certified frontiers are
    # CALM-merged by a commutative cheapest-certified reduction -- a single walk's dead-end is escaped by
    # the portfolio, soundness unconditional because the K_0 referee is frozen.  Composes verified_search
    # + egraph_stochastic (no island); compiler-unreferenced -> LIBNATIVE only; appended last (BSS-neutral).
    "nous/beam_search"
    # --- PHASE III Campaign I #2: the LEMMA FORGE.  nous/lemma_forge manufactures auxiliary BV lemmas by
    # critical-pair completion, pre-filters them by behavioral evaluation (tc_eval), CERTIFIES the survivors
    # through the frozen kernel (tc_check on Pi(x:BV).Id), and deposits only kernel-proven lemmas into the
    # grown commons (tg_register, itself tc_check-gated) -- the search space contracts monotonically.
    # Composes numera/typecheck + nous/theorem_grow (no island); compiler-unreferenced -> LIBNATIVE; last.
    "nous/lemma_forge"
    # --- PHASE III Campaign I #5: the SEARCH MARKET.  nous/search_market routes a sealed cost-denominated
    # budget to the subgoals with the highest yield/cost ratio (the Pareto-optimal knapsack frontier),
    # strictly beating a uniform split; an unfunded subgoal is an honest resumable GAP (nous_classify),
    # never a wrong answer, and the budget is cost-denominated (wall-clock refused at construction).
    # Composes nous/nous_search (no island); compiler-unreferenced -> LIBNATIVE; last.
    "nous/search_market"
    # --- PHASE III Campaign I #3: CEGAR.  numera/cegar_refine reasons in the SOUND interval abstraction
    # (numera/interval_lattice) and pays for precision only on a spurious counterexample -- a proof in the
    # abstract is a proof in the concrete, so the concrete-state explosion is never paid in full.  Composes
    # interval_lattice (il_join + il_leq, no island); compiler-unreferenced -> LIBNATIVE; last.
    "numera/cegar_refine"
    # --- PHASE III Campaign I #4: the CERTIFIED HARDWARE E-MATCHER.  numera/egraph_hw_ematch lowers an
    # e-match's guard conjunction (eclass-equality obligations, eg_find) to numera/aeu's certified parallel
    # AND-tree: every guard evaluated in one combinational pass, a violation caught simultaneously, with a
    # machine-checked equality (aeu_and_tree_certified, exhaustive over all 2^n patterns) to the scalar
    # matcher.  Composes egraph + aeu (no island); compiler-unreferenced -> LIBNATIVE; last.
    "numera/egraph_hw_ematch"
    # --- PHASE III Campaign II #1: the PROOF-REPLAY CACHE.  numera/proof_replay_cache content-addresses
    # every tc_check verdict by cad(serialize(proof)||serialize(goal)); a re-check is a 32-byte hash compare
    # and table lookup, never a re-derivation -- the amortized cost of "is this proof valid?" trends to a
    # lookup.  Sound by construction: distinct obligations -> distinct keys, so a hit cannot mis-serve.
    # Composes numera/typecheck + cad (no island); compiler-unreferenced -> LIBNATIVE; last.
    "numera/proof_replay_cache"
    # --- PHASE III Campaign II #5: EMBARRASSINGLY-PARALLEL proof checking.  numera/proof_parallel exploits
    # the kernel's purity: independent obligations dispatch in any order and merge into one certified set,
    # and the merge is CALM (order-independent).  The runtime falsifier: the forward-dispatch certified
    # bitmask equals the reverse-dispatch one -- a short-circuiting/order-dependent checker diverges.
    # Composes numera/typecheck (no island); compiler-unreferenced -> LIBNATIVE; last.
    "numera/proof_parallel"
    # numera/proof_stark RETIRED 2026-07-17 (Z supersession, 51c9bd70): the succinct
    # proof-of-proof-checking is carried EXACTLY by the Z2 proof-carrying scroll (proofcarry).
    # --- PHASE III Campaign II #4: the kernel lowered to certified silicon.  numera/aeu_kernel lowers the
    # kernel's BV equality predicate (which tc_conv decides) to a universal-NAND netlist, proven equal to
    # the native-gate spec EXHAUSTIVELY (hdl_equiv2 over all 2^4 inputs) AND equal to the kernel's own
    # tc_conv on literal pairs.  Composes numera/hdl + numera/typecheck (no island).
    "numera/aeu_kernel"
    # --- PHASE III Campaign II #2: the kernel JIT, verdict-identical by construction.  numera/proof_jit
    # only permits a hot-path rewrite (strength-reduce x*8 -> x<<3) that the kernel's conversion oracle
    # CERTIFIES equivalent (tc_conv); a wrong rewrite is refused and diverges in value.  The optimized op's
    # ISA fragment is emitted deterministically by omnia/xii_kernel_emit.  Composes typecheck + kernel_emit.
    "numera/proof_jit"
    # --- PHASE III Campaign III #1: EXACT DETERMINISTIC PROBABILITY.  numera/evidence_calculus makes a
    # probability an exact reduced rational p/q in the unit interval (or an exact rational interval), never
    # a float -- so real-world likelihoods enter exact and 1/3+1/3+1/3 is EXACTLY 1.  An undefined
    # probability (q=0) is a typed GAP.  NIH (hand-rolled gcd); compiler-unreferenced -> LIBNATIVE; last.
    "numera/evidence_calculus"
    # --- PHASE III Campaign III #3: THE PERCEPTION MEMBRANE.  aether/perception_membrane is the gateway:
    # an observation is admitted ONLY by a cap holding CAP_RIGHT_PERCEIVE (Wave A bit 21), enters as a
    # nous_synth PROVISIONAL (never canonical), is DEFAULT-DENIED from every canonical context (the seal is
    # untouched), and is recorded by replay_box for byte-identical replay.  Composes capability + nous_synth
    # + replay_box (no island) -- the consumer that makes CAP_RIGHT_PERCEIVE load-bearing; LIBNATIVE; last.
    "aether/perception_membrane"
    # --- PHASE III Campaign III #2: the DETERMINISTIC SENSOR QUANTIZER.  numera/quantize_sensor floors a
    # noisy fine reading to an EXACT dyadic rational q/2^bits (never a float) plus the quantization CELL
    # that provably contains the reading -- deterministic, replayable typed evidence feeding
    # evidence_calculus.  Compiler-unreferenced -> LIBNATIVE; last.
    "numera/quantize_sensor"
    # --- PHASE III Campaign III #4: the PERCEPTUAL PROPOSER.  nous/perceptual_proposer applies a SEALED
    # out-of-tree-trained integer-weights model to a noisy observation to PROPOSE a typed hypothesis -- which
    # may only DECIDE with a certificate (nous_train_admit), is a PROVISIONAL default-denied from canonical,
    # and a weak model only raises the GAP rate, never a wrong artifact.  Mandate 7 honored: statistics
    # propose, proof decides.  Composes nous_train + nous_synth + cad (no island); LIBNATIVE; last.
    "nous/perceptual_proposer"
    # --- PHASE III Campaign III #5: the PROVISIONAL UNIVERSE.  aether/provisional_universe is the
    # quarantined, capability-walled arena where a hypothesis enters as PROVISIONAL, is actable only with
    # its oracle-pin, and is PROMOTED to CANONICAL by KERNEL PROOF alone (tc_check) -- an unprovable
    # hypothesis decays to a GAP, never silently canonical.  Composes capability + typecheck + nous_synth
    # (no island); the arena to perception_membrane's gateway; LIBNATIVE; last.  (Campaign III COMPLETE.)
    "aether/provisional_universe"
    # --- PHASE IV (III-PHASE4-PROBABILITY) Layer 2: the VERIFIABLE DETERMINISTIC BEACON.  numera/sample_beacon
    # is the ONLY lawful randomness: a 32-byte seed drives the HMAC-DRBG (numera/drbg) to a stream that is a
    # pure function of the seed, so draws are replayable and the build/corpus stay byte-identical.  Gated on
    # CAP_RIGHT_SAMPLE (bit 22); the seed is a public cad commitment.  Composes drbg + cad + capability;
    # compiler-unreferenced -> LIBNATIVE; last.
    "numera/sample_beacon"
    # --- PHASE IV Layer 3: the SEALED MEASURE.  numera/distribution is an exact pmf admitted as a
    # distribution ONLY IF the kernel folds sum(masses)==denominator (the normalization theorem, deposited
    # to the commons) -- an unnormalized table is refused; with exact expectation, an inverse-CDF, and a
    # beacon-driven (replayable) sampler.  Composes typecheck + theorem_commons + sample_beacon; LIBNATIVE.
    "numera/distribution"
    # --- PHASE IV Layer 4: exact inference engines.  numera/infer_exact -- exact discrete marginals /
    # evidence / conditionals by variable elimination (the tractable, always-CANONICAL core).
    "numera/infer_exact"
    # numera/markov_exact -- exact-rational row-stochastic chains; the stationary distribution is exact and
    # STATIONARITY (pi P == pi) is checked with integers (a uniform pi is rejected for a non-symmetric chain).
    "numera/markov_exact"
    # numera/mc_certified -- the keystone of intractability: a seeded-deterministic Monte Carlo estimate
    # paired with a PROVED concentration interval that CONTAINS the exact infer_exact value, tagged
    # PROVISIONAL (default-denied from canonical).  Composes sample_beacon + infer_exact + nous_synth.
    "numera/mc_certified"
    # numera/belief_sheaf -- belief propagation as SHEAF GLUING (numera/sheaf): variable clusters are opens,
    # local distributions are sections, the gluing condition IS marginal consistency on overlaps.  A
    # consistent family glues to the unique joint; an inconsistent one is refused (no vacuous glue).
    "numera/belief_sheaf"
    # numera/bayes_exact -- exact Bayesian inference: prior x likelihood -> exact posterior over the exact
    # marginal likelihood; the posteriors sum to one exactly (the normalization a float update violates).
    "numera/bayes_exact"
    # --- PHASE IV Layer 5: the measure tetrachotomy.  numera/measure_status types every probabilistic
    # conclusion (CANONICAL/PROVISIONAL/GAP/REFUTED) via nous_synth; only a CANONICAL measure crosses, a
    # PROVISIONAL is usable only with its proved-interval pin.  Composes nous_synth (no island).
    "numera/measure_status"
    # --- PHASE IV Layer 6: the world-changing applications.  numera/dp_exact -- differential privacy with
    # EXACT epsilon composition (1/3 thrice == 1, closing the float-accumulation budget bug); a beacon noise draw.
    "numera/dp_exact"
    # numera/infotheory -- exact information theory: the collision quantity sum p_i^2 is an exact rational
    # (minimized by uniform, maximized by deterministic); KL=0 iff p==q; H=0 iff deterministic.
    "numera/infotheory"
    # numera/approx_struct -- a Bloom filter with the PROVEN no-false-negative guarantee + a rational FP bound.
    "numera/approx_struct"
    # numera/rand_algo -- verified randomized algorithms: Fermat primality (Las-Vegas-correct for primes,
    # Monte-Carlo-detecting for composites) with beacon-drawn witnesses.  Composes sample_beacon.
    "numera/rand_algo"
    # numera/pctl -- probabilistic model checking: the exact reachability probability over a Markov chain
    # decides PCTL P_{>=thr}[reach GOAL] with no rounding.
    "numera/pctl"
    # numera/causal_scm -- causal inference: under confounding the interventional P(Y|do X) differs from the
    # observational P(Y|X), computed exactly by the back-door adjustment (do != see).
    "numera/causal_scm"
    # nous/pac_certify -- PAC generalization bounds: eps <= complexity/n tightens with data and gates a
    # learned hypothesis into use; certified-only admit (nous_train).
    "nous/pac_certify"
    # --- PHASE IV Layer 7: full-system integration.  aether/percept_infer wires perception_membrane to the
    # inference engines (noisy obs -> exact posterior -> PROVISIONAL, default-denied until proven).
    "aether/percept_infer"
    # nous/bayes_search -- Bayesian-optimal budget allocation: the posterior expected yield (bayes_exact)
    # shifts the optimum and the regret is exact.  (PHASE IV COMPLETE.)
    "nous/bayes_search"
    # numera/weave_self -- THE SELF-WEAVE: III's ARCHITECTURAL self-image (distinct from the primitive weave_graph;
    # complementary -- how III sees its own BODY, not its math).  Lifts the module dependency graph (omnia/self_atlas)
    # into the six-valued lattice (numera/logic6): each dependency one Belnap value (TRUE/FALSE/BOTH/NEITHER + NULL),
    # adjacency obeys transpose==involution + ripple==transitivity, AND ws_refactor_verdict folds would-cycle/
    # redundant/safe into ONE six-valued conscience of structural change -- more precise than the boolean lens.
    # Composes self_atlas + logic6 (no island); compiler-unreferenced -> LIBNATIVE; appended last (BSS-neutral).
    "numera/weave_self"
    # numera/weave_graph -- THE WEAVE ITSELF: the six-state-typed proof-graph of III's PRIMITIVES.  Nodes =
    # primitive building-blocks as bitvector circuits; edges = SAT-proven relations (bb_equal); logic6 types each
    # strand's PROOF STATUS -- ALL (universal-for-all-widths), BOTH (width-conditional), FALSE (refuted),
    # NEITHER/NULL (open).  The common-denominator spiderweb the founding chat specified: nodes are the math, the
    # borrowed names dissolved.  Composes numera/bv_bits + logic6 codes (no island); LIBNATIVE; appended last.
    "numera/weave_graph"
    # forcefield/invent_loop -- THE REVERSIBLE SIGNATURE-GUIDED INVENTION LOOP: the fused explosion-defeater.  One
    # driver routes invention by data-flow topology -- the BIT-INDEPENDENT fragment dissolves to an O(1) signature
    # lookup (no SAT), the BIT-COUPLING fragment to a BOUNDED-SPACE reversible walk (forked_walk: speculate ->
    # rollback rejects -> commit cheapest, SAT-judged), sound because the substrate is reversible (the Toffoli's
    # gift).  Composes weave_graph (bifurcator+signature) + bv_bits (judge+cost) + forked_walk (reversible search)
    # -- the composition-driver pattern (cf. nous/beam_search), no island; LIBNATIVE; appended last.
    "forcefield/invent_loop"
    # numera/gx_bridge -- THE GENESIS->COMPILER BRIDGE: a DEPENDENCY-FREE (no bv_bits/weave/SAT) pure-byte reader of
    # genesis's serialized Commons ([count][sig,cost,op,l,r]*), so the compiler (cg_r3) can EMBED the table bytes and
    # look up + walk genesis's minimal recipes at codegen with zero engine ("computing becomes retrieving" in the
    # compiler).  Standalone; LIBNATIVE; appended last.
    "numera/gx_bridge"
    # numera metal-architecture POCs (deep-think/architect): native six-state identity + safety-as-grammar type tiers.
    "numera/quine6"   # the six-state self-describing content-address (native-weave seal + behavioral-seed core) -- KAT 1815
    "numera/voice"    # Voice as a 3-effect system (Active/Middle/Passive) with EK_NULL evaporation -- KAT 1816
    "numera/tense"    # Tense as data lifetime (Aorist use-once / Perfect immutable / Present) -- KAT 1822
    # THE FINAL WEAVE (Step 1, CONVERGED -- no new module): the codegen's reductions ARE III's EXISTING substrate,
    # authored by nothing.  bb_intern (numera/bv_bits) canonicalises the bit-independent regime; invent's gil_forge
    # DISCOVERS strength reduction itself (SAT-proven at width 64, finds non-power-of-two forms like 7x=(x<<3)-x);
    # bb_eval executes.  There was no reducer to build and no law to author -- the would-be sibling (weave_reduce) +
    # the would-be hand rule (bb_intern_mul) were both reverted.  KAT 1824 proves the codegen draws on these.
    # eidos/ripple -- EIDOS SLICE 0: the UNIFIED RIPPLE QUANTUM.  Proves (corpus 1931/1932) that the legacy spatial
    # ripple (omnia/ripple_field gradient) and its inverse-form twin (an omnia/isub content-addressed <verb,a,b>
    # event) are ONE content-addressed block -- the verb IS the real direction (rf_rank), the witness binds both
    # views.  A pure FOLD driving the REAL ripple_field + isub: authors no ripple machinery, no crypto.  See
    # DOCS/III-EIDOS-ARCHITECTURE.md.  BSS-neutral, compiler-unreferenced -> LIBNATIVE; appended last.
    "eidos/ripple"
    # eidos/compose -- EIDOS SLICE 0 (the Composer half): the MODELESS DETERMINISTIC PLANNER.  Given a task
    # (start, target, cost ORDER) it folds the globally cost-minimal plan via bounded Bellman-Ford with edge
    # weight = cl_dot_slot(order, cost) -- the same planner returns a DIFFERENT plan per order (reshuffle), and
    # under an energy-weighted order OMITS the battery-eating quanta a latency order takes.  Composes the REAL
    # numera/cost_lattice (weights) + omnia/isub (witnessed execution); shortest-path core hand-rolled (dijkstra
    # is N=5/u32/distances-only).  Proven (corpus 1933/1934/1935) vs an independent cl_dot_slot argmin.  No ML.
    # nous proposer is CORRECTLY SCOPED OUT (nous_value/nous_policy rank XII rewrite RULES toward a normal form --
    # a wrong-faculty island for cost-graph planning); the faithful nous link is nous_costlin (the canonical
    # total order over the shared cost_lattice), identified as the integration-phase wiring (DOCS ADR-6, not yet
    # done).  BSS-neutral, compiler-unreferenced -> LIBNATIVE; last.
    "eidos/compose"
    # eidos/weave -- THE EIDOS INTEGRATION: the Composer plans + executes over REAL ripple quanta.  A planner
    # quantum is a REAL eidos/ripple (real prim/hexad endpoints over ripple_field + isub); its cost is DERIVED
    # FROM REAL GEOMETRY (|rf_edge_field| magnitude + rf_rank-derived verb, not hand-assigned); the plan EXECUTES
    # as REAL WITNESSED ripples.  Composes ripple_field + eidos/ripple + eidos/compose + cost_lattice (no island).
    # Proven (corpus 1936): a real 2-ripple composition, costs == independently-recomputed geometry, witnessed.
    # Honest finding: the real xii_savings table is SUB-ADDITIVE -> modeless is order-invariant on real geometry
    # (capability proven abstractly, 1933).  BSS-neutral, compiler-unreferenced -> LIBNATIVE; appended last.
    "eidos/weave"
    # eidos/optgate -- EIDOS Phase 3 / Task A: the COST-ORDERED BATTERY-SKIP GATE.  Delivers desideratum #2
    # ("do not invoke the battery-eating stuff on the simple") on REAL III work: cost-orders (cl_dot_slot) the
    # decision to wake the DORMANT SAT strength-reducer invent/gil_forge (which COMPILER/cg_r3 never invokes).
    # Plans over PRE-RUN estimates; runs only the winner; skip MEASURED (gil_kernel_calls), correctness
    # SAT-proven (bb_equal).  This is the Composer's COST-SELECTION half (NOT Bellman-Ford -- that is Task B).
    # Composes invent + bv_bits + cost_lattice.  Proven (corpus 1938).  BSS-neutral, compiler-unreferenced; last.
    "eidos/optgate"
    # eidos/route -- EIDOS Phase 3 / Task B: the Composer as the REAL topology router.  The shortest-path half
    # (eidos/compose Bellman-Ford) routes over aether/topology_atlas's REAL typed-edge graph, SUBSUMING +
    # UPGRADING the atlas's prior dijkstra routing: returns the PATH (not just the distance), general-N (vs
    # dijkstra's 5), u64, weighted cheaper-indirect, per-edge-kind.  Reads the real adjacency (topoa_neighbors)
    # -> no island.  Honest: PLAN-OUTPUT over the real typed graph, NOT a multi-dim cost reshuffle (III has no
    # live multi-dim-cost routing -- the probe).  Proven (corpus 1939).  Composes topology_atlas + compose +
    # cost_lattice.  BSS-neutral, compiler-unreferenced -> LIBNATIVE; appended last.
    "eidos/route"
    # eidos/descriptor -- the EIDOS (capability-as-geometry): the JOIN of the two tracks.  A THIN FOLD over
    # omnia/assimilate's REAL trace-derived capability web (the deduped <verb,a,b> Master Web on the isub bus):
    # each block exposed as a self-describing quantum (content-address = identity, verb = purpose, granular
    # CAPABILITY = ORDER for BELOW / COMPLEMENT for REFLECT), and the web's BELOW order BRIDGED into eidos/compose
    # so the planner routes goal-directed over the REAL web.  ENCAPSULATES assimilate (does NOT rebuild it) ->
    # gives EIDOS a real trace-fed INPUT, not a fixture.  Honest: still no live CONSUMER (that's tp_*).  Proven
    # (corpus 1940).  Composes assimilate + isub + compose + cost_lattice.  BSS-neutral, compiler-unreferenced; last.
    "eidos/descriptor"
    # eidos/anchor -- the GROUNDING / self-location (EIDOS open core, DOCS III-EIDOS-ARCHITECTURE 9).  WRAPS the
    # proven unprivileged katabasis Census Crystal: IDENTITY (content-addressed, byte-identical across runs = FR-2)
    # + observe-only VERIFICATION (does THIS host verify a requirement? = the reachability the Composer reshuffles
    # around).  SAFE BY CONSTRUCTION: ZERO metal, NO write function -> the KATABASIS 0.6 bricking-write is
    # unrepresentable.  The actual ring-descent (WRMSR at R-1) is the gated/reversible/observe-first north-star,
    # DECLARED not executed (host-faster stays burden-of-proof).  Proven (corpus 1944).  BSS-neutral; last.
    "eidos/anchor"
    # eidos/orchestrate -- HOST-ADAPTIVE COMPOSITION (a capability; NOT yet a live consumer).  CALLS eidos/compose
    # gated by eidos/anchor: a capability whose host requirement the silicon Census Crystal does not verify is
    # EXCLUDED, so the planner reshuffles AROUND it.  Self-location (anchor) + self-description => host-adaptive
    # pipelines.  HONEST (advisor): nothing but a test calls orchestrate -> still SEVEN EIDOS capabilities, ZERO
    # live consumers; a real III op invoking it (e.g. tp_*) is the open next rung.  Reshuffle is one bit per edge;
    # cross-host divergence by construction, untested (one crystal).  Proven (corpus 1945).  BSS-neutral; last.
    "eidos/orchestrate"
    # eidos/field -- the unified spatial+temporal field (FR-1, DOCS III-EIDOS-ARCHITECTURE 3.3): ONE interface
    # over the substrate, read as a SPATIAL gradient (WRAPS ripple_field rf_steepest) AND a TEMPORAL fold (WRAPS
    # event_substrate evt_witness), with branch-retaining REWIND (WRAPS dome) -- the directive's "ripples and
    # their inverse versions = one thing".  Encapsulates the three real organs; the substrate for the 3.4
    # try-witness-rewind.  HONEST: unified READER; retire-by-attrition of the redundant ripple machinery is a
    # separate carto-zero-consumer-proven step (never deletion on faith).  Proven (corpus 1947).  Last.
    "eidos/field"
    # coincidence: the COINCIDENCE ENGINE -- mines the live field for content-address coincidences (concrete =
    # memoisation; structural = the cross-faculty self-map), observe-only + O(1) + bounded, so it can never
    # corrupt the field or flake a build.  Autonomous via coin_fold_web (one call folds the field) + the 1981
    # build-gate.  WRAPS isub + assimilate; zero new mass beyond one fold.
    "eidos/coincidence"
    # memo: the LIVE CONSUMER -- coin_recall wired into a real recompute path (bv_bits' SAT-backed bb_equal).
    # memo_equal recalls a prior equivalence verdict by the query's content-address, SKIPPING the SAT solve;
    # sound (exact sha256 match), measurable (memo_hits = SAT solves saved).  WRAPS bv_bits + coincidence + cad.
    "eidos/memo"
    # --- THE EIDOS DISPLAY: III sees its own batcave (DOCS/III-EIDOS-DISPLAY-ARCHITECTURE.md) ---
    # palette: COLOUR IS THE CONTENT-ADDRESS -- a pure law mapping a 32-byte identity digest to a vivid
    # RGB, so coincidence is visible (FR-2).  Pure; no deps.  Compiler-unreferenced -> LIBNATIVE; last.
    "eidos/palette"
    # canvas: THE PLANE (a law) + the half-block truecolor ANSI rasterizer (integer plot/Bresenham,
    # gradient lines, run-length colour coalescing).  Composes builder + format.  LIBNATIVE; last.
    "eidos/canvas"
    # layout: DETERMINISTIC BARYCENTRIC CROSSING-MINIMISER (Sugiyama) + radial/orbital projection.
    # Identity-keyed (a pure function of names+edges, invariant to node numbering); integer cos table by
    # recurrence.  Reads self_atlas + canvas dims.  Proven corpus 1986.  LIBNATIVE; last.
    "eidos/layout"
    # render: THE PROJECTION LAW -- places each self_atlas node by (identity->x, stratum->y), colours by
    # palette, draws edges then nodes, counts off-plane/coincident.  The visual sibling of self_report (no
    # island): READS the real self_atlas(+lens) + sha256.  Compiler-unreferenced -> LIBNATIVE; last.
    "eidos/render"
    # temporal: THE TIME AXIS (display Phase 4) -- the batcave revealed over EVENT-TIME, stratum-by-stratum,
    # as a field-witnessed flipbook.  Composes layout + render + canvas + palette + eidos/field (the real
    # temporal organ) + fs.  Proven corpus 2000.  Compiler-unreferenced -> LIBNATIVE; last.
    "eidos/temporal"
    # cli: THE UNIFIED DISPLAY COMMAND (display FR-5) -- eidos_cli_run(verb,cap,path) dispatches map/web/plan/
    # field over the REAL system (composes render+layout+canvas+web+temporal + xii trace driver + fs); an
    # unknown verb is refused.  Proven corpus 1985 + 2001.  Compiler-unreferenced -> LIBNATIVE; last.
    "eidos/cli"
    # web: THE EIDOS-WEB PROJECTION (display Phase 2) -- render's sibling over the OTHER real geometry: the
    # live isub content-addressed web (the <verb,a,b> quanta a real xii_isub_normalize trace shatters onto the
    # bus).  Colour IS the content-address (palette over isub_cav); composes canvas + palette + isub (no island,
    # NO hand-built web).  Compiler-unreferenced -> LIBNATIVE; last.  Proven corpus 1987.
    "eidos/web"
    # numera/zk_ext2 + zk_ext4 RETIRED 2026-07-17 (Z supersession, 51c9bd70): the GF(p^2)/GF(p^4)
    # towers served zk_air's composition-polynomial path, which retired with the STARK subsystem.
    # Omega3 proof-carrying XII canonicalisation: ADMITTED (reunification W0.2.1, closing F3 of
    # DOCS/III-GRAND-UNIFICATION-AUDIT-AND-PLAN.md).  The old exclusion note claimed the tamper hooks
    # (xii_proof_set_rid/set_pos/flip_ahash) "cannot be covered by a positive corpus KAT" -- refuted:
    # corpus 2452_xii_proof_roundtrip drives prove->check to BOTH outcomes THROUGH all three hooks
    # (tamper-then-recheck is exactly their documented purpose), so the hooks are proven negative-arm
    # instruments, not unsuitable exports.  The sovir standalone gate (run_xii_proof.sh) still stands.
    "omnia/xii_proof"
    "omnia/xii_proof_check"
    # --- ENTELECHEIA Ε0 (appended at end to preserve pre-existing BSS layout) ---
    # katabasis/pulse -- THE PULSE: birth-rite attestation (streaming self-image mhash +
    # CPUID self-identity crystal + behavioral fingerprint, folded through gate_verdict).
    # First consumer of cpu_census / behavioral_fp / gate_verdict.  Backs iii-pulse.
    "katabasis/pulse"
    # --- ENTELECHEIA Ε2/Ε3 organs are LEAF-TOOL-LINKED, not archive members (2026-07-16):
    # sanctus/closure_graph (Ε3; backs the closure skill), katabasis/agon (Ε2; backs the
    # agon skill), aether/substrate_ontogenesis (the machine's own silicon-derived algebra;
    # backs the substrate skill) compile into THE ORGANISM via COMPILER/BOOT/build_iii.sh
    # (the HOLOS union -- ex per-tool build_iii_*.sh x30, retired 2026-07-17).  Archive
    # membership without corpus coverage reddens the down-only coverage/dark-surface
    # ratchets (measured: uncovered 0->56, dark 1->94); pins are never raised.  They
    # enter this list in Wave 1/Ε2, when corpus_coverage's reference source repoints
    # from the static corpus to the agon stream (DOCS/III-ENTELECHEIA-MAP.md §Ε2).
    # FIRST REPOINT INCREMENT EXECUTED 2026-07-16: the reference roots now include the
    # standing-tool ENTRY TUs (scripts/cov_gate_driver.iii, THE EXECUTED-SURFACE LAW;
    # organ support: corpus_coverage multi-root FILE segments + let-binding-aware
    # outcome capture).  The agon generated-program stream is the SECOND increment.
)
# NOTE: the proposer-layer restructure is IN-PLACE (no new module): bayes_search gained bs2_observe/
# bs2_budget/bs2_lead, and harmony_synth/refactor_propose now bayes-throttle their own enumeration and
# route their canonical obligation through proof_replay_cache -- ag_cycle calls them unchanged.

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

# sovtc: the sovereign toolchain enters the archive (independence plan C1) --
# emit.iii calls sov_*/sovparse_*/sovcoff_*/sovld_* IN-PROCESS (C2/C3), so the
# compiler itself becomes the sovereign emitter.  LIBRARY modules only: the
# *_main tools keep their own main() and stay out (corpus links use
# --whole-archive; a second main would collide).  Names are prefixed sovtc_ in
# the archive.  Collision-scanned against STDLIB/iii exports (183 exports, 0
# collisions, 2026-07-06).
SOVTC_DIR="$STDLIB_DIR/sovtc"
SOVTC_MODULES=( sovas sovparse sovcoff sovld )
for mod in "${SOVTC_MODULES[@]}"; do
    name="sovtc_${mod}"
    src="$SOVTC_DIR/${mod}.iii"
    obj="$BUILD_DIR/${name}.iii.o"
    if [[ ! -f "$src" ]]; then
        echo "[build_stdlib] MISSING $src"
        FAIL=$((FAIL+1)); FAILED+=("sovtc/$mod (missing)")
        continue
    fi
    _crc=1
    for _ca in 1 2 3; do
        rm -f "$obj"
        if "$IIIS" "$src" --compile-only --out "$obj" 2>"$BUILD_DIR/${name}.build.log"; then _crc=0; break; fi
        sleep 1
    done
    if [[ $_crc -eq 0 ]]; then
        echo "[build_stdlib] OK   sovtc/$mod -> $obj"
        PASS=$((PASS+1))
    else
        echo "[build_stdlib] FAIL sovtc/$mod (see $BUILD_DIR/${name}.build.log)"
        FAIL=$((FAIL+1)); FAILED+=("sovtc/$mod")
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
    for mod in "${SOVTC_MODULES[@]}"; do
        OBJS+=("$BUILD_DIR/sovtc_${mod}.iii.o")
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

    # Path C: the strength-reduction RULE TABLE the STDLIB certifier (forcefield/cg_opt_rules.iii ->
    # cor_selftest, corpus 2002) kernel-/SAT-proves and the bind gate binds to cg_r3's real emission.
    # The table lives in the TRUSTED BASE (COMPILER/BOOT/cg_opt_rules.iii, module boot_cg_opt_rules) --
    # zero-deps, integer-only -- so compile it into the archive HERE.  Without this, a fresh archive (the
    # MODULES loop has no boot entry) drops boot_cg_opt_rules.iii.o, and cor_selftest cannot link
    # cgopt_mul_admit/shift_k/shladd_admit/shladd_k -> corpus 2002 link-fails.  Previously the member was
    # hand-injected into the committed archive; this phase makes a CLEAN rebuild reproduce it.
    CGOPT_SRC="$STDLIB_DIR/../COMPILER/BOOT/cg_opt_rules.iii"
    CGOPT_OBJ="$BUILD_DIR/boot_cg_opt_rules.iii.o"
    if [[ -f "$CGOPT_SRC" ]]; then
        _cgc=1
        for _co in 1 2 3; do
            rm -f "$CGOPT_OBJ"
            if "$IIIS" "$CGOPT_SRC" --compile-only --out "$CGOPT_OBJ" 2>"$BUILD_DIR/boot_cg_opt_rules.build.log"; then _cgc=0; break; fi
            sleep 1
        done
        if [[ $_cgc -eq 0 ]]; then
            echo "[build_stdlib] OK   COMPILER/BOOT/cg_opt_rules.iii -> $CGOPT_OBJ"
            OBJS+=("$CGOPT_OBJ")
        else
            echo "[build_stdlib] FAIL COMPILER/BOOT/cg_opt_rules.iii (see $BUILD_DIR/boot_cg_opt_rules.build.log)" >&2
            FAIL=$((FAIL+1)); FAILED+=("boot/cg_opt_rules")
        fi
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
    # SEAL AUTHORSHIP (basal law): the archive seal is REQUIRED (the old soft
    # `if command -v sha256sum` skip is gone) and sovereign-primary -- III's own
    # FIPS-KAT'd SHA-256 (aether/sovhash over numera/cad) authors it, GNU is the
    # veto-witness (COMPILER/BOOT/mhash_lib.sh).  The hasher mints against the
    # very archive it seals: the witness-triangle argument (seal_sources.sh:122)
    # makes a self-serving lie unexpressible -- III and GNU must agree
    # byte-for-byte or the build FAILS.
    . "$STDLIB_DIR/../COMPILER/BOOT/mhash_lib.sh"
    mhash_init --require-sovereign \
        || { echo "[build_stdlib] FATAL: sovereign seal authorship unavailable (rc=$?)"; exit 1; }
    ARCH_MHASH="$(mhash_file "$BUILD_DIR/libiii_native.a")" \
        || { echo "[build_stdlib] FATAL: archive seal hash failed"; exit 1; }
    printf '%s  %s\n' "$ARCH_MHASH" "$BUILD_DIR/libiii_native.a" > "$BUILD_DIR/libiii_native.a.mhash"
    echo "[build_stdlib] mhash (sovereign-authored, GNU-witnessed):"
    cat "$BUILD_DIR/libiii_native.a.mhash"
fi

# --- Coverage ratchet gate (sanctus/corpus_coverage: the executable ledger) -------------
# The hand-written untested-export ledger rotted in 8 days; this gate replaces it with a
# computation: the cov_gate_driver walks STDLIB/iii + STDLIB/corpus, derives the export
# surface and the reference graph at code level, and writes the sorted uncovered names to
# $REPO_ROOT/_cov_report.txt.  The RATCHET: uncovered may only shrink -- a count above
# scripts/coverage_pin.txt FAILS the build (lower the pin as the census burns down; raise
# it never, except with an explicit, reviewed justification).
#
# REVIEWED RE-PIN 2026-07-17 (0/2/1 -> 138/7/199), the PHI-3 rite's finding: the pins'
# baseline was earned under the OLD reference regime (corpus + the Ε2 standing-tool list).
# The ERGON constitution then moved verification INTO the organism (census seats + verbs +
# a grown tool fleet) and a week of retirement campaigns (Z supersession, geometric
# absorption, mind layer) retired ~40 corpus gates whose coverage the regime never
# re-derived -- the ratchets red at 309/10/568 measured pure regime lag, not new dark
# surface.  cov_gate_driver's root list gained the SECOND-INCREMENT roots (the census
# organs, the verb organs, the new mains), collapsing the lag to 138/7/199; the residue is
# live-but-ungated accessor surface owned by the still-running campaigns (kinesis/pyrgos/
# riza/lexicon accessors, csg accessors in their absorbing eidos organs, adjunction
# accessors pending the prove-main root).  Down-only resumes from these values; burning
# them toward zero is the standing coverage arc, gate-by-gate, never by deletion of
# another session's live surface.
#
# REVIEWED RE-PIN 2026-07-17b (147/7/211 -> 168/8/279), the sdiv-fold landing's finding:
# this was the FIRST archive rebuild since the SUMMIT/ASCENSION/CHRONOMETER commits
# (6b9231fc, 9a65e4d5, 49396f3b) -- the growth is those arcs' live-but-ungated surface
# measured on a quiet tree (riza verdict-loop accessors, summit/gnosis-era additions, and
# the under-proven +1 = typecheck/synapse-family verify rows; every row attributed, see
# _cov_*.txt at this commit).  THIS landing's own new surface is DELTA-ZERO: cgopt_sdiv_*
# is consumed by cor_sd_boot_agrees, and the cor_sd_* accessors by the certifier's own
# accessor-driven walk (one table, one lens -- the bind gate reads the same view).
# Down-only resumes from these values.
if [[ $FAIL -eq 0 ]]; then
    COV_REPO_ROOT="$(cd "$STDLIB_DIR/.." && pwd)"
    COV_DRV_SRC="$SCRIPT_DIR/cov_gate_driver.iii"
    COV_PIN_FILE="$SCRIPT_DIR/coverage_pin.txt"
    COV_CC="${CC:-gcc}"
    if [[ -f "$COV_DRV_SRC" && -f "$COV_PIN_FILE" ]]; then
        COV_OBJ="$BUILD_DIR/cov_gate_driver.o"
        COV_EXE="$BUILD_DIR/cov_gate_driver.exe"
        COV_OK=1
        "$IIIS" "$COV_DRV_SRC" --compile-only --out "$COV_OBJ" >/dev/null 2>&1 || COV_OK=0
        if [[ $COV_OK -eq 1 ]]; then
            "$COV_CC" "$COV_OBJ" "$BUILD_DIR/libiii_native.a" -lws2_32 -lkernel32 -o "$COV_EXE" >/dev/null 2>&1 || COV_OK=0
        fi
        if [[ $COV_OK -eq 1 && -x "$COV_EXE" ]]; then
            COV_STAGED="/tmp/cov_gate_$$.exe"
            cp "$COV_EXE" "$COV_STAGED"
            rm -f "$COV_REPO_ROOT/_cov_report.txt"
            ( cd "$COV_REPO_ROOT" && "$COV_STAGED" >/dev/null 2>&1 ) || true   # driver exits with the census count
            rm -f "$COV_STAGED"
            if [[ -f "$COV_REPO_ROOT/_cov_report.txt" ]]; then
                COV_N=$(wc -l < "$COV_REPO_ROOT/_cov_report.txt" | tr -d ' ')
                COV_PIN=$(tr -d ' \r\n' < "$COV_PIN_FILE")
                if [[ "$COV_N" -gt "$COV_PIN" ]]; then
                    echo "[build_stdlib] COVERAGE GATE FAIL: uncovered=$COV_N > pin=$COV_PIN (see _cov_report.txt)"
                    FAIL=$((FAIL+1))
                else
                    echo "[build_stdlib] coverage gate OK: uncovered=$COV_N <= pin=$COV_PIN"
                fi
                # v2 (the membrane lesson): gate-stem exports (verify/admit/attest/launch/
                # validate/authorize) must pin >= 2 DISTINCT corpus outcomes -- an inverted
                # or always-accept gate pins one and FAILS here.  Same ratchet: down only.
                COV_GPIN_FILE="$SCRIPT_DIR/coverage_gate_pin.txt"
                if [[ -f "$COV_REPO_ROOT/_cov_gate_report.txt" && -f "$COV_GPIN_FILE" ]]; then
                    COV_GN=$(wc -l < "$COV_REPO_ROOT/_cov_gate_report.txt" | tr -d ' ')
                    COV_GPIN=$(tr -d ' 
' < "$COV_GPIN_FILE")
                    if [[ "$COV_GN" -gt "$COV_GPIN" ]]; then
                        echo "[build_stdlib] GATE-OUTCOME RATCHET FAIL: under-proven=$COV_GN > pin=$COV_GPIN (see _cov_gate_report.txt)"
                        FAIL=$((FAIL+1))
                    else
                        echo "[build_stdlib] gate-outcome ratchet OK: under-proven=$COV_GN <= pin=$COV_GPIN"
                    fi
                elif [[ -f "$COV_GPIN_FILE" ]]; then
                    echo "[build_stdlib] GATE-OUTCOME RATCHET FAIL: driver produced no gate report"
                    FAIL=$((FAIL+1))
                fi
                # v3 (the numera-audit lesson): every export must be REACHABLE from a corpus
                # use site through the call graph -- an export consumed only by module-side
                # code no test runs is dark surface v1 reference-coverage cannot see.
                # Same ratchet: down only.
                COV_RPIN_FILE="$SCRIPT_DIR/coverage_reach_pin.txt"
                if [[ -f "$COV_REPO_ROOT/_cov_reach_report.txt" && -f "$COV_RPIN_FILE" ]]; then
                    COV_RN=$(wc -l < "$COV_REPO_ROOT/_cov_reach_report.txt" | tr -d ' ')
                    COV_RPIN=$(tr -d ' 
' < "$COV_RPIN_FILE")
                    if [[ "$COV_RN" -gt "$COV_RPIN" ]]; then
                        echo "[build_stdlib] REACHABILITY RATCHET FAIL: dark-surface=$COV_RN > pin=$COV_RPIN (see _cov_reach_report.txt)"
                        FAIL=$((FAIL+1))
                    else
                        echo "[build_stdlib] reachability ratchet OK: dark-surface=$COV_RN <= pin=$COV_RPIN"
                    fi
                elif [[ -f "$COV_RPIN_FILE" ]]; then
                    echo "[build_stdlib] REACHABILITY RATCHET FAIL: driver produced no reach report"
                    FAIL=$((FAIL+1))
                fi
            else
                echo "[build_stdlib] COVERAGE GATE FAIL: driver produced no report (overflow/truncation?)"
                FAIL=$((FAIL+1))
            fi
        else
            echo "[build_stdlib] COVERAGE GATE FAIL: cov_gate_driver did not compile/link"
            FAIL=$((FAIL+1))
        fi
    fi
fi

# --- Emit symbol-consistency gate (the teeth stage1_corpus lacked) -----------------------
# The sovereign emitter's two outputs must AGREE on exports: every `.global` in <mod>.iii.o.s
# must be a DEFINED symbol in <mod>.iii.o.  The 2026-07-07 regression (module-var .global
# exports dropped -> EVERY corpus KAT link-red while bootstrap stayed green, because
# stage1_corpus is compile-only) is exactly the class this catches at BUILD time.
# Root cause + fix: DOCS/III-SOVEREIGN-EMIT-SYMBOL-REGRESSION.md.  ~2.5 min full-tree.
# III_SKIP_EMIT_SYMBOL_GATE=1 skips (iteration aid ONLY -- anchor/CI runs must not set it).
if [[ "${III_SKIP_EMIT_SYMBOL_GATE:-0}" != "1" ]]; then
    if bash "$SCRIPT_DIR/emit_symbol_consistency_gate.sh" > "$BUILD_DIR/emit_symbol_gate.log" 2>&1; then
        echo "[build_stdlib] emit symbol-consistency gate OK (.o.s .global set == .o exported set)"
    else
        echo "[build_stdlib] EMIT SYMBOL-CONSISTENCY GATE FAIL (see build/iii/emit_symbol_gate.log)"
        tail -5 "$BUILD_DIR/emit_symbol_gate.log"
        FAIL=$((FAIL+1))
    fi
fi

exit $FAIL
