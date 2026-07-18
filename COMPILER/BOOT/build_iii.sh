#!/usr/bin/env bash
# COMPILER/BOOT/build_iii.sh
#
# Build iii: THE ORGANISM -- the engine fleet dissolved into one body.
#
#     iii                    THE FACE: every skill's standing, dues, vitality
#     iii <skill> [args...]  any engine's whole surface, one level down
#     iii due | earn | law   drift, proof-earning, the organism's laws
#
# This ONE build replaces the thirty per-engine build_iii_*.sh scripts.  Its
# source list is the UNION of every retired recipe (each engine's fresh-organ
# closure, faithfully carried into the holos manifest -- katabasis/holos.iii
# asserts at every invocation that every dep path it pins is cited HERE: the
# two-source law).  A LEAF tool build: the PINNED in-tree compiler
# (COMPILED/iiis-2) + the committed stdlib archive; the bootstrap chain is
# never touched.
#
# Usage: bash build_iii.sh [--out <path>]
# Exit:  0 OK | 2 ENV | 3 COMPILE | 4 LINK

set -euo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1

LOG_TAG="[iii build]"
log()  { printf '%s %s\n' "$LOG_TAG" "$*" >&2; }
die()  { printf '%s ERROR: %s\n' "$LOG_TAG" "$2" >&2; exit "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT_DIR="$SCRIPT_DIR"
SOVIR_DIR="$III_ROOT/STDLIB/sovir"
OUT_DIR="$III_ROOT/COMPILED"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

OUT_BIN="$OUT_DIR/iii${BIN_SUFFIX}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --out) OUT_BIN="$2"; shift 2 ;;
        *)     die 2 "unknown arg: $1" ;;
    esac
done

IIIS="$OUT_DIR/iiis-2${BIN_SUFFIX}"
[[ -x "$IIIS" ]] || die 2 "pinned compiler not found: $IIIS"
CC="${CC:-gcc}"
command -v "$CC" >/dev/null 2>&1 || die 2 "linker not found: $CC"
ARCHIVE="$III_ROOT/STDLIB/build/iii/libiii_native.a"
[[ -f "$ARCHIVE" ]] || die 2 "stdlib archive not found: $ARCHIVE"

TMP_ROOT="$III_ROOT/STDLIB/build/holos/obj"
mkdir -p "$TMP_ROOT" "$OUT_DIR"

# --- the compiler-chain TUs (compiled with CWD=BOOT, the build_iii_prove mold) ---
BOOT_TUS=( cg_sha lex_rt lex ast parse eval cg_svir eval_main events_main prove_main iii_main )
# The chain's full citation surface (the holos two-source law reads THIS text;
# every dep the organism pins must appear here) -- also the existence guard:
for dep in \
    COMPILER/BOOT/cg_sha.iii COMPILER/BOOT/lex_rt.iii COMPILER/BOOT/lex.iii \
    COMPILER/BOOT/ast.iii COMPILER/BOOT/parse.iii COMPILER/BOOT/eval.iii \
    COMPILER/BOOT/cg_svir.iii COMPILER/BOOT/eval_main.iii COMPILER/BOOT/events_main.iii \
    COMPILER/BOOT/prove_main.iii COMPILER/BOOT/iii_main.iii STDLIB/sovir/svir_event.iii; do
    [[ -f "$III_ROOT/$dep" ]] || die 3 "missing chain TU: $dep"
done

# --- the organ union (every retired engine's fresh closure + the faces + holos) ---
SRCS=(
    "$III_ROOT/STDLIB/iii/katabasis/holos.iii"
    "$III_ROOT/STDLIB/iii/katabasis/kardia.iii"
    "$III_ROOT/STDLIB/iii/katabasis/ergon.iii"
    "$III_ROOT/STDLIB/iii/katabasis/introspection.iii"
    "$III_ROOT/STDLIB/iii/katabasis/autognosis.iii"
    "$III_ROOT/STDLIB/iii/katabasis/soma.iii"
    "$III_ROOT/STDLIB/iii/katabasis/doxa.iii"
    "$III_ROOT/STDLIB/iii/katabasis/pulse.iii"
    "$III_ROOT/STDLIB/iii/katabasis/agon.iii"
    "$III_ROOT/STDLIB/iii/katabasis/isa_admit.iii"
    "$III_ROOT/STDLIB/iii/katabasis/nomos_admit.iii"
    "$III_ROOT/STDLIB/iii/katabasis/crucible.iii"
    "$III_ROOT/STDLIB/iii/katabasis/cpu_census.iii"
    "$III_ROOT/STDLIB/iii/katabasis/behavioral_fp.iii"
    "$III_ROOT/STDLIB/iii/oneiros/cassandra.iii"
    "$III_ROOT/STDLIB/iii/aether/lagrangian.iii"
    "$III_ROOT/STDLIB/iii/aether/entangle.iii"
    "$III_ROOT/STDLIB/iii/aether/admix.iii"
    "$III_ROOT/STDLIB/iii/aether/autophasis.iii"
    "$III_ROOT/STDLIB/iii/aether/xeno_ontogenesis.iii"
    "$III_ROOT/STDLIB/iii/aether/xeno_isa.iii"
    "$III_ROOT/STDLIB/iii/aether/mathesis_ontogenesis.iii"
    "$III_ROOT/STDLIB/iii/aether/mathesis_forge.iii"
    "$III_ROOT/STDLIB/iii/aether/substrate_ontogenesis.iii"
    "$III_ROOT/STDLIB/iii/aether/isa_ontogenesis.iii"
    "$III_ROOT/STDLIB/iii/aether/isa_friction_judge.iii"
    "$III_ROOT/STDLIB/iii/aether/oneiros.iii"
    "$III_ROOT/STDLIB/iii/aether/reversibility.iii"
    "$III_ROOT/STDLIB/iii/aether/symmetria.iii"
    "$III_ROOT/STDLIB/iii/aether/synapse.iii"
    "$III_ROOT/STDLIB/iii/aether/glossa.iii"
    "$III_ROOT/STDLIB/iii/aether/iscene.iii"
    "$III_ROOT/STDLIB/iii/aether/iform.iii"
    "$III_ROOT/STDLIB/iii/aether/aether_lens.iii"
    "$III_ROOT/STDLIB/iii/aether/kfield.iii"
    "$III_ROOT/STDLIB/iii/aether/sqrt_sum_sign.iii"
    "$III_ROOT/STDLIB/iii/aether/exact_denest.iii"
    "$III_ROOT/STDLIB/iii/aether/sturm.iii"
    "$III_ROOT/STDLIB/iii/aether/sturm_big.iii"
    "$III_ROOT/STDLIB/iii/aether/algnum.iii"
    "$III_ROOT/STDLIB/iii/aether/resultant.iii"
    "$III_ROOT/STDLIB/iii/aether/logos_wire.iii"
    "$III_ROOT/STDLIB/iii/aether/xring.iii"
    "$III_ROOT/STDLIB/iii/aether/xenos.iii"
    "$III_ROOT/STDLIB/iii/aether/anglos.iii"
    "$III_ROOT/STDLIB/iii/aether/stoma_proc.iii"
    "$III_ROOT/STDLIB/iii/aether/testament.iii"
    "$III_ROOT/STDLIB/iii/aether/pyrgos.iii"
    "$III_ROOT/STDLIB/iii/glossa/topos.iii"
    "$III_ROOT/STDLIB/iii/verba/lexicon.iii"
    "$III_ROOT/STDLIB/iii/verba/json.iii"
    "$III_ROOT/STDLIB/iii/verba/builder.iii"
    "$III_ROOT/STDLIB/iii/verba/nl_lex.iii"
    "$III_ROOT/STDLIB/iii/verba/nl_parse.iii"
    "$III_ROOT/STDLIB/iii/memoria/arena.iii"
    "$III_ROOT/STDLIB/iii/numera/trit.iii"
    "$III_ROOT/STDLIB/iii/numera/sat_arith.iii"
    "$III_ROOT/STDLIB/iii/numera/idfold.iii"
    "$III_ROOT/STDLIB/iii/numera/sha256.iii"
    "$III_ROOT/STDLIB/iii/numera/bigint.iii"
    "$III_ROOT/STDLIB/iii/numera/bigint_div.iii"
    "$III_ROOT/STDLIB/iii/numera/bv_ring.iii"
    "$III_ROOT/STDLIB/iii/numera/cpufeat.iii"
    "$III_ROOT/STDLIB/iii/numera/typecheck.iii"
    "$III_ROOT/STDLIB/iii/numera/ccl.iii"
    "$III_ROOT/STDLIB/iii/numera/cost_lattice.iii"
    "$III_ROOT/STDLIB/iii/numera/combinator.iii"
    "$III_ROOT/STDLIB/iii/numera/weave_blocks.iii"
    "$III_ROOT/STDLIB/iii/omnia/eidolos.iii"
    "$III_ROOT/STDLIB/iii/omnia/event_substrate.iii"
    "$III_ROOT/STDLIB/iii/omnia/exec_cert.iii"
    "$III_ROOT/STDLIB/iii/omnia/friction.iii"
    "$III_ROOT/STDLIB/iii/omnia/hexad_reach.iii"
    "$III_ROOT/STDLIB/iii/omnia/hexad_pfs.iii"
    "$III_ROOT/STDLIB/iii/omnia/hexad_algebra.iii"
    "$III_ROOT/STDLIB/iii/omnia/involution.iii"
    "$III_ROOT/STDLIB/iii/omnia/isub.iii"
    "$III_ROOT/STDLIB/iii/intent/lex_ontology.iii"
    "$III_ROOT/STDLIB/iii/intent/intent_lex.iii"
    "$III_ROOT/STDLIB/iii/intent/disambiguate.iii"
    "$III_ROOT/STDLIB/iii/eidos/exact_line.iii"
    "$III_ROOT/STDLIB/iii/eidos/exact_plane.iii"
    "$III_ROOT/STDLIB/iii/eidos/exact_space.iii"
    "$III_ROOT/STDLIB/iii/eidos/exact_worldline.iii"
    "$III_ROOT/STDLIB/iii/eidos/exact_manifold.iii"
    "$III_ROOT/STDLIB/iii/eidos/exact_motion.iii"
    "$III_ROOT/STDLIB/iii/eidos/kinesis.iii"
    "$III_ROOT/STDLIB/iii/eidos/eidolon.iii"
    "$III_ROOT/STDLIB/iii/eidos/eid_plan.iii"
    "$III_ROOT/STDLIB/iii/eidos/ripple_eidolon.iii"
    "$III_ROOT/STDLIB/iii/eidos/proofcarry.iii"
    "$III_ROOT/STDLIB/iii/sanctus/closure.iii"
    "$III_ROOT/STDLIB/iii/sanctus/closure_graph.iii"
    "$III_ROOT/COMPILER/BOOT/cg_glossa_rules.iii"
    "$III_ROOT/COMPILER/BOOT/cg_phys_rules.iii"
    "$III_ROOT/STDLIB/iii/aether/agon_cli.iii"
    "$III_ROOT/STDLIB/iii/aether/author_cli.iii"
    "$III_ROOT/STDLIB/iii/aether/closure_cli.iii"
    "$III_ROOT/STDLIB/iii/aether/crypto_cli.iii"
    "$III_ROOT/STDLIB/iii/aether/exact_cli.iii"
    "$III_ROOT/STDLIB/iii/aether/friction_cli.iii"
    "$III_ROOT/STDLIB/iii/aether/judge_cli.iii"
    "$III_ROOT/STDLIB/iii/aether/pulse_cli.iii"
    "$III_ROOT/STDLIB/iii/aether/substrate_cli.iii"
    "$III_ROOT/STDLIB/iii/aether/testament_cli.iii"
    "$III_ROOT/STDLIB/iii/aether/typecheck_cli.iii"
    "$III_ROOT/STDLIB/iii/aether/witness_cli.iii"
    "$III_ROOT/STDLIB/iii/aether/xeno_cli.iii"
    "$III_ROOT/STDLIB/iii/aether/xenos_cli.iii"
    "$III_ROOT/STDLIB/iii/aether/anglos_cli.iii"
    "$III_ROOT/STDLIB/iii/omnia/hexad_cli.iii"
    "$III_ROOT/STDLIB/iii/intent/intent_cli.iii"
    "$III_ROOT/COMPILER/BOOT/kardia_main.iii"
    "$III_ROOT/COMPILER/BOOT/doxa_main.iii"
    "$III_ROOT/COMPILER/BOOT/eidolos_main.iii"
    "$III_ROOT/COMPILER/BOOT/ergon_main.iii"
    "$III_ROOT/COMPILER/BOOT/soma_main.iii"
    "$III_ROOT/COMPILER/BOOT/line_main.iii"
    "$III_ROOT/COMPILER/BOOT/plane_main.iii"
    "$III_ROOT/COMPILER/BOOT/space_main.iii"
    "$III_ROOT/COMPILER/BOOT/worldline_main.iii"
    "$III_ROOT/COMPILER/BOOT/manifold_main.iii"
    "$III_ROOT/COMPILER/BOOT/motion_main.iii"
    "$III_ROOT/COMPILER/BOOT/proofcarry_main.iii"
)
for s in "${SRCS[@]}"; do [[ -f "$s" ]] || die 3 "missing source: $s"; done

OBJS=()
for tu in "${BOOT_TUS[@]}"; do
    src="$BOOT_DIR/${tu}.iii"
    obj="$TMP_ROOT/boot_${tu}.iii.o"
    [[ -f "$src" ]] || die 3 "missing source: $src"
    log "iiis-2 ${tu}.iii"
    ( cd "$BOOT_DIR" && "$IIIS" "${tu}.iii" --compile-only --out "$obj" ) > "$TMP_ROOT/build_${tu}.log" 2>&1 \
        || die 3 "iii compile failed: $src (see $TMP_ROOT/build_${tu}.log)"
    OBJS+=("$obj")
done

log "iiis-2 svir_event.iii"
( cd "$SOVIR_DIR" && "$IIIS" "svir_event.iii" --compile-only --out "$TMP_ROOT/sovir_svir_event.iii.o" ) \
    > "$TMP_ROOT/build_svir_event.log" 2>&1 \
    || die 3 "iii compile failed: $SOVIR_DIR/svir_event.iii (see $TMP_ROOT/build_svir_event.log)"
OBJS+=("$TMP_ROOT/sovir_svir_event.iii.o")

for s in "${SRCS[@]}"; do
    b="$(basename "$s" .iii)"
    d="$(basename "$(dirname "$s")")"
    o="$TMP_ROOT/${d}_${b}.iii.o"
    log "iiis-2 ${d}/${b}.iii"
    "$IIIS" "$s" --compile-only --out "$o" > "$TMP_ROOT/build_${d}_${b}.log" 2>&1 \
        || die 3 "iii compile failed: $s (see $TMP_ROOT/build_${d}_${b}.log)"
    OBJS+=("$o")
done

# OneDrive/Defender transient-lock hardening: fresh inode + retry (house discipline).
log "link -> $OUT_BIN"
rc=1
for _la in 1 2 3 4 5; do
    rm -f "$OUT_BIN"
    if "$CC" -o "$OUT_BIN" "${OBJS[@]}" "$ARCHIVE" -lws2_32 -lkernel32 > "$TMP_ROOT/build_link.log" 2>&1; then rc=0; else rc=$?; fi
    [[ $rc -eq 0 && -f "$OUT_BIN" ]] && break
    sleep 1
done
[[ $rc -eq 0 ]] || die 4 "link failed (see $TMP_ROOT/build_link.log)"
log "OK: $OUT_BIN"
exit 0
