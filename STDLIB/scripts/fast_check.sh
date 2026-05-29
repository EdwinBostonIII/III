#!/usr/bin/env bash
# ============================================================================
# fast_check.sh -- FAST iteration harness for the numera/* (P5/Path C) bricks.
#
# The full gate rebuilds ALL ~413 stdlib modules (build_stdlib.sh) and runs ALL
# ~487 corpus tests (run_corpus.sh) -- minutes per cycle.  But a typecheck/
# combinator brick changes only 1-2 LEAF modules (nothing else imports them),
# so its blast radius is exactly the 84x/85x corpus tests.  This harness:
#   1. recompiles ONLY the named modules,
#   2. replaces just those members in libiii_native.a (ar rcs, re-indexed),
#   3. compiles+links+runs ONLY the named corpus tests (the run_corpus.sh link
#      recipe verbatim: selective --whole-archive of the side-effect set),
# giving ~30s feedback instead of minutes.
#
#   SOUNDNESS: valid ONLY for leaf modules (numera/typecheck, numera/combinator)
#   that no other module externs.  It is an ITERATION aid; the authoritative
#   green is still the FULL build_stdlib.sh + run_corpus.sh (deterministic
#   archive + all-test regression sweep).  Run the full gate before declaring a
#   brick DONE.  Do NOT run this while a full gate is in flight (both touch the
#   archive).
#
# Usage:
#   fast_check.sh                          # default: rebuild numera/{typecheck,combinator}; run 84x/85x
#   fast_check.sh "numera/combinator"      # rebuild one module; run default tests
#   fast_check.sh "numera/typecheck" "85"  # rebuild module(s); run only 85x tests
# Args: $1 = space-separated module paths (no .iii);  $2 = space-separated
#       corpus number prefixes (e.g. "84 85" = 84x + 85x).
# ============================================================================
set -u
ROOT="/c/Users/Edwin Boston/OneDrive/Desktop/III"
SRC_DIR="$ROOT/STDLIB/iii"
BUILD_DIR="$ROOT/STDLIB/build/iii"
CORPUS_DIR="$ROOT/STDLIB/corpus"
RUN_DIR="$ROOT/STDLIB/build/corpus_run"
IIIS="$ROOT/COMPILED/iiis-2.exe"
LIB="$BUILD_DIR/libiii_native.a"
mkdir -p "$RUN_DIR"

MODS="${1:-numera/typecheck numera/combinator}"
TESTS="${2:-84 85}"

if [[ ! -f "$LIB" ]]; then
    echo "FATAL: $LIB missing -- run build_stdlib.sh once first." >&2
    exit 2
fi

echo "=== fast: recompile changed modules ==="
brc=0
CHANGED_OBJS=()
for mod in $MODS; do
    name="${mod//\//_}"
    obj="$BUILD_DIR/${name}.iii.o"
    if "$IIIS" "$SRC_DIR/${mod}.iii" --compile-only --out "$obj" 2>"$BUILD_DIR/${name}.fast.log"; then
        echo "  OK   $mod"
        CHANGED_OBJS+=("$obj")
    else
        echo "  FAIL $mod -- compile error:"
        sed 's/^/      /' "$BUILD_DIR/${name}.fast.log" | head -25
        brc=1
    fi
done
[[ $brc -ne 0 ]] && { echo "=== BUILD FAILED -- not linking ==="; exit 1; }

echo "=== fast: re-archive libiii_native.a (replace changed members) ==="
ar rcs "$LIB" "${CHANGED_OBJS[@]}"
echo "  updated ${#CHANGED_OBJS[@]} member(s)"

# The side-effect set run_corpus.sh force-links (registration-only modules +
# resolver dispatch units), built from whichever objects exist.
SE=()
for o in omnia_resolution_init omnia_resolution_meta_dispatch omnia_proof_ripple_resolution \
         omnia_resolver omnia_resolver_memo omnia_resolver_replay omnia_codegen_patterns \
         omnia_transform_patterns omnia_xii_curated_payloads omnia_hw_offload \
         aether_pattern_set_federation sanctus_calculus_v1 sanctus_resolver_replay \
         sanctus_seal_resolver verba_nl_lex; do
    [[ -f "$BUILD_DIR/$o.iii.o" ]] && SE+=("$BUILD_DIR/$o.iii.o")
done
for o in resolver_hot resolver_unit resolver_unit_avx512 bench_helpers; do
    [[ -f "$BUILD_DIR/$o.o" ]] && SE+=("$BUILD_DIR/$o.o")
done

echo "=== fast: compile+link+run targeted tests ($TESTS) ==="
PASS=0; OTHER=0
for pfx in $TESTS; do
  for src in "$CORPUS_DIR"/${pfx}[0-9]_*.iii "$CORPUS_DIR"/${pfx}[0-9][0-9]_*.iii; do
    [[ -f "$src" ]] || continue
    base="$(basename "$src" .iii)"
    obj="$RUN_DIR/${base}.iii.o"; exe="$RUN_DIR/${base}.exe"; log="$RUN_DIR/${base}.fast.log"
    rm -f "$obj" "$exe"
    if ! "$IIIS" "$src" --compile-only --out "$obj" >"$log" 2>&1; then
        echo "  FAIL  $base : compile rc=$?"; OTHER=$((OTHER+1)); continue
    fi
    if ! gcc "$obj" -Wl,--whole-archive "${SE[@]}" -Wl,--no-whole-archive "$LIB" \
            -lws2_32 -lkernel32 -o "$exe" >>"$log" 2>&1; then
        echo "  FAIL  $base : link rc=$?"; OTHER=$((OTHER+1)); continue
    fi
    # stage in /tmp (OneDrive-watched-folder Defender exec heuristic; same as run_corpus.sh)
    cp "$exe" "/tmp/${base}.exe"
    "/tmp/${base}.exe"; ec=$?
    rm -f "/tmp/${base}.exe"
    if [[ $ec -eq 99 ]]; then
        echo "  PASS  $base : exit=99"; PASS=$((PASS+1))
    else
        echo "  ????  $base : exit=$ec (expected 99 for 84x/85x)"; OTHER=$((OTHER+1))
    fi
  done
done
echo "=== fast done: PASS=$PASS  OTHER/FAIL=$OTHER ==="
echo "(authoritative green = full build_stdlib.sh + run_corpus.sh)"