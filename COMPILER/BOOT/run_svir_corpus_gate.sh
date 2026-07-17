#!/usr/bin/env bash
# COMPILER/BOOT/run_svir_corpus_gate.sh — Θ2-FULL: THE COMMUTING SQUARE, CORPUS-WIDE.
#
# Route S (the production compiler's OWN SVIR backend) runs against route N
# (the production compiler's x86 backend) on EVERY non-negative corpus KAT:
#
#   route N : pinned iiis-2 (sema+cg_r3+emit) -> gcc link -> run -> rc
#   route S : pinned iiis-2 --emit-svir (lex+parse+cg_svir) -> gen_svir module
#             -> svir_interp (the SVIR reference executor) -> rc
#
# The two routes share lex+parse and FORK at codegen, so rc disagreement
# localizes a defect to exactly one backend (with route E = iii_eval as the
# third adjudicator via run_meaning.sh).  This is the rc-axis square: SVIR v1
# has no extern I/O yet, so KATs whose meaning includes OUTPUT still get their
# rc edge checked; the output axis stays two-route (N≡E) until the extern rung.
#
# CLASSES (census, mirrors run_meaning.sh's honesty discipline):
#   PASS         rc_S == rc_N
#   S_UNSUP      cg_svir REFUSED the program (named class= on stderr, rc=16)
#   S_TIMEOUT    interp exceeded budget (definitional executor, not a fast one)
#   S_DIVERGE    rc_S != rc_N               <- THE INSTRUMENT FIRING (exit 1)
#   S_DEFECT     emitter crash / emitted module fails to compile or link /
#                interp sentinel 198/199    <- backend must refuse, never break
#   NATIVE_*     native-side skip classes (cached, same keys as run_meaning.sh)
#
# FLOOR: every square_probes/sq*.iii must PASS (hard, exit 3).
# RATCHET: corpus PASS count is UP-ONLY vs svir_corpus_ratchet.txt (exit 4).
# Exit: 0 green | 1 diverge/defect | 2 env | 3 probe floor | 4 ratchet fall.
#
# Usage: run_svir_corpus_gate.sh [--theater]   (--theater: probes + DDC only,
#        plumbing smoke for the harness itself; no census/ratchet)
set -u
IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT_DIR="$SCRIPT_DIR"
CORPUS_DIR="$III_ROOT/STDLIB/corpus"
RUN_DIR="$III_ROOT/STDLIB/build/meaning/svirsweep"
CACHE_DIR="$III_ROOT/STDLIB/build/meaning/cache"      # SHARED with run_meaning.sh (native side)
mkdir -p "$RUN_DIR" "$CACHE_DIR"
LOG="$RUN_DIR/run_svir_corpus.log"
: > "$LOG"
RATCHET_FILE="$BOOT_DIR/svir_corpus_ratchet.txt"
THEATER=0
[[ "${1:-}" == "--theater" ]] && THEATER=1

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac
IIIS="${IIIS:-$III_ROOT/COMPILED/iiis-2${BIN_SUFFIX}}"
BUILD_DIR="$III_ROOT/STDLIB/build/iii"
LIB_ARCHIVE="$BUILD_DIR/libiii_native.a"
SOVIR="$III_ROOT/STDLIB/sovir"
S_TIMEOUT="${S_TIMEOUT:-120}"
[[ -x "$IIIS" ]]        || { echo "[sq-corpus] FATAL: no pinned iiis-2 at $IIIS"; exit 2; }
[[ -f "$LIB_ARCHIVE" ]] || { echo "[sq-corpus] FATAL: no stdlib archive"; exit 2; }

# cache keys: sealed identities, never timestamps (run_meaning.sh's law)
# seal authorship: III hashes III (mhash_lib; GNU is the veto-witness, never the author)
. "$SCRIPT_DIR/mhash_lib.sh"
IIIS_ID="$(cut -d' ' -f1 "$III_ROOT/COMPILED/iiis-2.exe.mhash" 2>/dev/null || mhash_file "$IIIS")"
LIB_ID="$(cut -d' ' -f1 "$BUILD_DIR/libiii_native.a.mhash" 2>/dev/null || mhash_file "$LIB_ARCHIVE")"
NKEY="${IIIS_ID:0:16}_${LIB_ID:0:16}"
SKEY="$(mhash_file "$SOVIR/svir_interp.iii" | cut -c1-8)"    # S verdicts re-measure when interp or compiler change

# force-linked side-effect set — MIRRORS run_meaning.sh / run_corpus.sh
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

say() { printf '%s\n' "$*" | tee -a "$LOG"; }

# ── the interp half of route S: compile ONCE per (compiler, interp) identity ─
INTERP_O="$RUN_DIR/svir_interp.${NKEY:0:16}.${SKEY}.o"
if [[ ! -f "$INTERP_O" ]]; then
    TW="/tmp/svirsweep_interp_$$"; mkdir -p "$TW"
    timeout 120 "$IIIS" "$SOVIR/svir_interp.iii" --compile-only --out "$TW/svir_interp.o" >>"$LOG" 2>&1 \
        || { echo "[sq-corpus] FATAL: svir_interp compile"; rm -rf "$TW"; exit 2; }
    cp "$TW/svir_interp.o" "$INTERP_O"; rm -rf "$TW"
fi

# ── route N: native rc, cache-first (EXACT run_meaning.sh key + discipline) ──
# ALL same-invocation read-back files live in /tmp (OneDrive stale-read law).
run_native() {  # $1 src -> RCN + CLASS_N ∈ {OK, NATIVE_CFAIL, NATIVE_LFAIL, NATIVE_TIMEOUT}
    local src="$1" base obj exe staged rc kat_id ck _la
    base="$(basename "$src" .iii)"
    obj="$RUN_DIR/${base}.o"
    exe="$RUN_DIR/${base}${BIN_SUFFIX}"
    CLASS_N="OK"; RCN=""
    kat_id="$(mhash_file "$src" | cut -c1-16)"
    ck="$CACHE_DIR/${base}.${NKEY}.${kat_id}"
    if [[ -f "$ck.lfail" ]]; then CLASS_N="NATIVE_LFAIL"; return; fi
    if [[ -f "$ck.ntime" ]]; then CLASS_N="NATIVE_TIMEOUT"; return; fi
    if [[ -f "$ck.rc" ]]; then RCN="$(cat "$ck.rc")"; return; fi
    rm -f "$obj"
    timeout 60 "$IIIS" "$src" --compile-only --out "$obj" >>"$LOG" 2>&1
    rc=$?
    if [[ $rc -ne 0 ]]; then CLASS_N="NATIVE_CFAIL"; return; fi
    rc=1
    for _la in 1 2 3 4 5; do
        rm -f "$exe"
        gcc "$obj" -Wl,--whole-archive "${SIDE_EFFECT_OBJS[@]}" -Wl,--no-whole-archive "$LIB_ARCHIVE" \
            -lws2_32 -lkernel32 -o "$exe" >>"$LOG" 2>&1
        rc=$?
        [[ $rc -eq 0 && -f "$exe" ]] && break
        sleep 1
    done
    if [[ $rc -ne 0 ]]; then CLASS_N="NATIVE_LFAIL"; : > "$ck.lfail"; return; fi
    staged="/tmp/sqc_n_$$_${RANDOM}${BIN_SUFFIX}"
    cp "$exe" "$staged"
    timeout 120 "$staged" >"/tmp/sqc_nat_$$.out" 2>>"$LOG"
    RCN=$?
    rm -f "$staged"
    if [[ $RCN -eq 124 ]]; then CLASS_N="NATIVE_TIMEOUT"; rm -f "/tmp/sqc_nat_$$.out"; : > "$ck.ntime"; return; fi
    cp "/tmp/sqc_nat_$$.out" "$ck.out"; rm -f "/tmp/sqc_nat_$$.out"
    printf '%s' "$RCN" > "$ck.rc"
}

# ── route S: emit -> compile emitted module -> link interp -> run ───────────
# S cache: verdicts keyed by (compiler, interp, KAT) — settled-read law: the
# whole per-KAT theater lives in /tmp; only cache rows land on OneDrive.
run_svir() {  # $1 src -> RCS + CLASS_S ∈ {OK, S_UNSUP, S_TIMEOUT, S_DEFECT} + SNOTE
    local src="$1" base kat_id sk W rc _la
    base="$(basename "$src" .iii)"
    CLASS_S="OK"; RCS=""; SNOTE=""
    kat_id="$(mhash_file "$src" | cut -c1-16)"
    sk="$CACHE_DIR/${base}.S${NKEY:0:16}.${SKEY}.${kat_id}"
    if [[ -f "$sk.class" ]]; then
        CLASS_S="$(cat "$sk.class")"; RCS="$(cat "$sk.rcs" 2>/dev/null)"; SNOTE="$(cat "$sk.note" 2>/dev/null)"
        return
    fi
    W="/tmp/svirsweep_$$_${RANDOM}"; mkdir -p "$W"
    timeout 60 "$IIIS" "$src" --emit-svir --out "$W/gen_svir.iii" >/dev/null 2>"$W/emit.err"
    rc=$?
    if [[ $rc -ne 0 ]]; then
        SNOTE="$(grep -o 'svir-unsup class=[a-z0-9_-]* kind=[0-9]*' "$W/emit.err" | head -1)"
        if [[ -n "$SNOTE" && $rc -eq 16 ]]; then CLASS_S="S_UNSUP"; else CLASS_S="S_DEFECT"; SNOTE="emit rc=$rc ${SNOTE:-no-class}"; fi
        printf '%s' "$CLASS_S" > "$sk.class"; printf '%s' "$SNOTE" > "$sk.note"; rm -rf "$W"; return
    fi
    if [[ ! -s "$W/gen_svir.iii" ]]; then
        CLASS_S="S_DEFECT"; SNOTE="emit rc=0 but empty module"
        printf '%s' "$CLASS_S" > "$sk.class"; printf '%s' "$SNOTE" > "$sk.note"; rm -rf "$W"; return
    fi
    ( cd "$W" && timeout 120 "$IIIS" gen_svir.iii --compile-only --out gen_svir.o >>"$LOG" 2>&1 )
    if [[ $? -ne 0 ]]; then
        CLASS_S="S_DEFECT"; SNOTE="emitted module failed to compile"
        printf '%s' "$CLASS_S" > "$sk.class"; printf '%s' "$SNOTE" > "$sk.note"; rm -rf "$W"; return
    fi
    rc=1
    for _la in 1 2 3; do
        rm -f "$W/route_s${BIN_SUFFIX}"
        gcc "$INTERP_O" "$W/gen_svir.o" "$LIB_ARCHIVE" -lws2_32 -lkernel32 -o "$W/route_s${BIN_SUFFIX}" >>"$LOG" 2>&1
        rc=$?
        [[ $rc -eq 0 && -f "$W/route_s${BIN_SUFFIX}" ]] && break
        sleep 1
    done
    if [[ $rc -ne 0 ]]; then
        CLASS_S="S_DEFECT"; SNOTE="route-S link failed"
        printf '%s' "$CLASS_S" > "$sk.class"; printf '%s' "$SNOTE" > "$sk.note"; rm -rf "$W"; return
    fi
    timeout "$S_TIMEOUT" "$W/route_s${BIN_SUFFIX}" >/dev/null 2>&1
    RCS=$?
    if [[ $RCS -eq 124 ]]; then CLASS_S="S_TIMEOUT"
    elif [[ $RCS -eq 198 || $RCS -eq 199 ]]; then CLASS_S="S_DEFECT"; SNOTE="interp sentinel $RCS (unresolved import / OOB indirect) — emitter must refuse instead"
    fi
    printf '%s' "$CLASS_S" > "$sk.class"; printf '%s' "${RCS:-}" > "$sk.rcs"; printf '%s' "${SNOTE:-}" > "$sk.note"
    rm -rf "$W"
}

# ── FLOOR: the square-probe theater (every probe must PASS on the rc axis) ──
say "[sq-corpus] == floor: square probes (route S = cg_svir) =="
PFAIL=0; PN=0
for src in "$BOOT_DIR"/square_probes/sq*.iii; do
    [[ -f "$src" ]] || continue
    PN=$((PN + 1)); base="$(basename "$src" .iii)"
    run_native "$src"
    if [[ "$CLASS_N" != "OK" ]]; then say "RED   floor $base native=$CLASS_N"; PFAIL=$((PFAIL+1)); continue; fi
    run_svir "$src"
    if [[ "$CLASS_S" != "OK" ]]; then say "RED   floor $base $CLASS_S ${SNOTE:-}"; PFAIL=$((PFAIL+1)); continue; fi
    if [[ "$RCS" == "$RCN" ]]; then say "PASS  floor $base rc=$RCN (N=S)"
    else say "RED   floor $base SPLIT rcN=$RCN rcS=$RCS"; PFAIL=$((PFAIL+1)); fi
done
[[ $PN -eq 0 ]] && { echo "[sq-corpus] FATAL: no probes"; exit 2; }
if [[ $PFAIL -ne 0 ]]; then say "[sq-corpus] PROBE FLOOR RED: $PFAIL/$PN"; exit 3; fi
say "[sq-corpus] probe floor GREEN: $PN/$PN"

# ── DDC independence set: in-theater smoke (byte-canonicity lives in
#    run_svir_backend_gate.sh; here they are square rows like any other) ─────
if [[ $THEATER -eq 1 ]]; then
    say "[sq-corpus] == theater: DDC independence set =="
    for name in indep_toolchain indep_ops indep_bignum; do
        src="$III_ROOT/STDLIB/independence/$name.iii"
        [[ -f "$src" ]] || continue
        run_native "$src"
        [[ "$CLASS_N" != "OK" ]] && { say "note  $name native=$CLASS_N (dedicated-runner family)"; continue; }
        run_svir "$src"
        if [[ "$CLASS_S" == "OK" && "$RCS" == "$RCN" ]]; then say "PASS  theater $name rc=$RCN (N=S)"
        else say "RED   theater $name classS=$CLASS_S rcN=${RCN:-} rcS=${RCS:-} ${SNOTE:-}"; fi
    done
    say "[sq-corpus] theater smoke complete (no census/ratchet in --theater)"
    exit 0
fi

# ═══ THE CORPUS SWEEP (all non-negative KATs; up-only ratchet) ═══════════════
say "[sq-corpus] == corpus (rc-axis square: N=S per KAT) =="
PASS=0; DIV=0; UNSUP=0; STMO=0; SDEF=0; NSKIP=0; TOTAL=0
declare -A UNSUP_BY
DIVLIST=(); DEFLIST=()
for src in "$CORPUS_DIR"/[0-9]*_*.iii; do
    [[ -f "$src" ]] || continue
    base="$(basename "$src" .iii)"
    case "$base" in *_neg_*|*_neg) continue ;; esac
    TOTAL=$((TOTAL + 1))
    run_native "$src"
    if [[ "$CLASS_N" != "OK" ]]; then NSKIP=$((NSKIP+1)); say "SKIP  $base native=$CLASS_N"; continue; fi
    run_svir "$src"
    case "$CLASS_S" in
        OK)
            if [[ "$RCS" == "$RCN" ]]; then
                PASS=$((PASS + 1)); say "PASS  $base rc=$RCN"
            else
                DIV=$((DIV + 1)); DIVLIST+=("$base rcN=$RCN rcS=$RCS")
                say "S_DIVERGE $base rcN=$RCN rcS=$RCS   <- THE INSTRUMENT FIRED"
            fi ;;
        S_UNSUP)
            UNSUP=$((UNSUP + 1))
            key="${SNOTE:-unknown}"
            UNSUP_BY["$key"]=$(( ${UNSUP_BY["$key"]:-0} + 1 ))
            say "UNSUP $base $SNOTE" ;;
        S_TIMEOUT)
            STMO=$((STMO + 1)); say "STIME $base (interp > ${S_TIMEOUT}s; reference executor, not a fast one)" ;;
        S_DEFECT)
            SDEF=$((SDEF + 1)); DEFLIST+=("$base $SNOTE")
            say "S_DEFECT $base $SNOTE" ;;
    esac
done

say "[sq-corpus] census: total=$TOTAL pass=$PASS diverge=$DIV unsup=$UNSUP s-timeout=$STMO s-defect=$SDEF native-skip=$NSKIP"
say "[sq-corpus] S-frontier census (the named burn-down list):"
for k in "${!UNSUP_BY[@]}"; do printf '  %s -> %s\n' "$k" "${UNSUP_BY[$k]}"; done | LC_ALL=C sort | tee -a "$LOG"

if [[ $((DIV + SDEF)) -ne 0 ]]; then
    say "[sq-corpus] RED (adjudicate per Θ4 — a split names its backend):"
    for d in ${DIVLIST[@]+"${DIVLIST[@]}"}; do say "  SPLIT  $d"; done
    for d in ${DEFLIST[@]+"${DEFLIST[@]}"}; do say "  DEFECT $d"; done
    exit 1
fi

RATCHET=0
[[ -f "$RATCHET_FILE" ]] && RATCHET="$(tr -dc '0-9' < "$RATCHET_FILE")"
RATCHET="${RATCHET:-0}"
if [[ $PASS -lt $RATCHET ]]; then
    say "[sq-corpus] RATCHET RED: pass=$PASS < pinned=$RATCHET"
    exit 4
fi
if [[ $PASS -gt $RATCHET ]]; then
    say "[sq-corpus] ratchet can rise: pass=$PASS > pinned=$RATCHET (raise svir_corpus_ratchet.txt)"
fi
say "[sq-corpus] GREEN: floor $PN/$PN, corpus $PASS/$TOTAL rc-square, 0 divergence, ratchet=$RATCHET"
exit 0
