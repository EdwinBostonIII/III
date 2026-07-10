#!/usr/bin/env bash
# Parallel NATIVE-cache pre-warmer for run_meaning.sh v2 — fills the exact
# ck.rc / ck.out artifacts the gate expects (same key: iiis mhash + archive
# mhash + KAT sha), 8 workers sliced by index modulo.  Read-only wrt gate.
set -u
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CORPUS_DIR="$III_ROOT/STDLIB/corpus"
RUN_DIR="$III_ROOT/STDLIB/build/meaning"
CACHE_DIR="$RUN_DIR/cache"
mkdir -p "$CACHE_DIR"
BIN_SUFFIX=".exe"
IIIS="$III_ROOT/COMPILED/iiis-2$BIN_SUFFIX"
BUILD_DIR="$III_ROOT/STDLIB/build/iii"
LIB_ARCHIVE="$BUILD_DIR/libiii_native.a"
IIIS_ID="$(cut -d' ' -f1 "$III_ROOT/COMPILED/iiis-2.exe.mhash")"
LIB_ID="$(cut -d' ' -f1 "$BUILD_DIR/libiii_native.a.mhash")"
NKEY="${IIIS_ID:0:16}_${LIB_ID:0:16}"
SIDE_EFFECT_NAMES=(
    omnia_resolution_init.iii.o omnia_resolution_meta_dispatch.iii.o
    omnia_proof_ripple_resolution.iii.o omnia_resolver.iii.o
    omnia_resolver_memo.iii.o omnia_resolver_replay.iii.o
    omnia_codegen_patterns.iii.o omnia_transform_patterns.iii.o
    omnia_xii_curated_payloads.iii.o omnia_hw_offload.iii.o
    aether_pattern_set_federation.iii.o sanctus_calculus_v1.iii.o
    sanctus_resolver_replay.iii.o sanctus_seal_resolver.iii.o
    verba_nl_lex.iii.o resolver_hot.o resolver_unit.o
    resolver_unit_avx512.o bench_helpers.o
)
SIDE_EFFECT_OBJS=()
for _se in "${SIDE_EFFECT_NAMES[@]}"; do
    [[ -f "$BUILD_DIR/$_se" ]] && SIDE_EFFECT_OBJS+=("$BUILD_DIR/$_se")
done
worker() {
    local wid="$1" nw="$2" idx=0
    local src base obj exe staged rc kat_id ck _la
    for src in "$CORPUS_DIR"/[0-9]*_*.iii; do
        [[ -f "$src" ]] || continue
        base="$(basename "$src" .iii)"
        case "$base" in *_neg_*|*_neg) continue ;; esac
        idx=$((idx + 1))
        [[ $((idx % nw)) -ne $wid ]] && continue
        kat_id="$(sha256sum "$src" | cut -c1-16)"
        ck="$CACHE_DIR/${base}.${NKEY}.${kat_id}"
        [[ -f "$ck.rc" ]] && continue
        obj="$RUN_DIR/w${wid}_${base}.o"
        exe="$RUN_DIR/w${wid}_${base}${BIN_SUFFIX}"
        rm -f "$obj"
        timeout 60 "$IIIS" "$src" --compile-only --out "$obj" >/dev/null 2>&1 || { echo "CFAIL $base"; continue; }
        rc=1
        for _la in 1 2 3 4 5; do
            rm -f "$exe"
            gcc "$obj" -Wl,--whole-archive "${SIDE_EFFECT_OBJS[@]}" -Wl,--no-whole-archive "$LIB_ARCHIVE" \
                -lws2_32 -lkernel32 -o "$exe" >/dev/null 2>&1
            rc=$?
            [[ $rc -eq 0 && -f "$exe" ]] && break
            sleep 1
        done
        [[ $rc -ne 0 ]] && { echo "LFAIL $base"; continue; }
        staged="/tmp/warm_${wid}_$$${BIN_SUFFIX}"
        cp "$exe" "$staged"
        timeout 120 "$staged" >"$ck.out.tmp" 2>/dev/null
        rc=$?
        rm -f "$staged" "$obj" "$exe"
        [[ $rc -eq 124 ]] && { echo "NTIME $base"; rm -f "$ck.out.tmp"; continue; }
        mv "$ck.out.tmp" "$ck.out"
        printf '%s' "$rc" > "$ck.rc"
        echo "WARM $base rc=$rc"
    done
    echo "WORKER $wid DONE"
}
NW=8
for w in $(seq 0 $((NW-1))); do worker "$w" "$NW" & done
wait
echo "ALL WORKERS DONE"
