#!/usr/bin/env bash
# COMPILER/BOOT/run_meaning.sh — THE MEANING GATE v2 (Theta-1, THE LOADER)
#
# v1 (Theta-0) ran the extern-free theater (122).  v2 (Theta-1) runs the
# WHOLE corpus: multi-module KATs resolve their `extern … from "x.iii"`
# closures inside iii_eval (the loader, four-phase: load/collect/bind/run);
# the OS boundary is a small sanctioned builtin tier (msvcrt malloc/free/
# putchar + kernel32 VirtualAlloc/VirtualFree/Sleep); every other foreign
# extern is a POISON that errors only when CALLED (clean UNSUPPORTED,
# named per KAT — never PASS, never silent).
#
# Differential law per KAT, both routes observed through the same channel:
#   rc_N == rc_E                          (exit-code axis, as v1)
#   prog_out_N == prog_out_E              (output axis — NEW; putchar KATs
#                                          byte-compared modulo trailing
#                                          newlines, protocol lines stripped)
#
# Native-route CACHE: rc + stdout keyed on (iiis-2 mhash, archive mhash,
# KAT sha256).  The native route is deterministic under that key, so
# re-runs only pay the eval side.  rm -rf $RUN_DIR/cache to force cold.
#
# Sections: 1 selftest (teeth, incl. the OUT_DIVERGE arm)
#           2 probes  (hard floor; per-probe import closures are compiled
#                      and linked into the native route)
#           3 corpus  (up-only PASS ratchet; named frontier census)
#
# Exit: 0 green | 1 divergence | 2 env | 3 probe red | 4 ratchet | 5 selftest
set -u
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
III_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOT_DIR="$SCRIPT_DIR"
CORPUS_DIR="$III_ROOT/STDLIB/corpus"
RUN_DIR="$III_ROOT/STDLIB/build/meaning"
CACHE_DIR="$RUN_DIR/cache"
mkdir -p "$RUN_DIR" "$CACHE_DIR"
LOG="$RUN_DIR/run_meaning.log"
: > "$LOG"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

IIIS="${IIIS:-$III_ROOT/COMPILED/iiis-2${BIN_SUFFIX}}"
EVAL_BIN="${EVAL_BIN:-$III_ROOT/COMPILED/iii_eval${BIN_SUFFIX}}"
BUILD_DIR="$III_ROOT/STDLIB/build/iii"
LIB_ARCHIVE="$BUILD_DIR/libiii_native.a"
RATCHET_FILE="$BOOT_DIR/meaning_ratchet.txt"
EVAL_TIMEOUT="${EVAL_TIMEOUT:-60}"

[[ -x "$IIIS" ]]        || { echo "[meaning] FATAL: no pinned iiis-2 at $IIIS"; exit 2; }
[[ -f "$LIB_ARCHIVE" ]] || { echo "[meaning] FATAL: no stdlib archive"; exit 2; }
if [[ ! -x "$EVAL_BIN" ]]; then
    echo "[meaning] iii_eval missing -- building"
    bash "$BOOT_DIR/build_iii_eval.sh" || exit 2
fi

# cache key: sealed identities, never timestamps
# seal authorship: III hashes III (mhash_lib; GNU is the veto-witness, never the author)
. "$SCRIPT_DIR/mhash_lib.sh"
IIIS_ID="$(cut -d' ' -f1 "$III_ROOT/COMPILED/iiis-2.exe.mhash" 2>/dev/null || mhash_file "$IIIS")"
LIB_ID="$(cut -d' ' -f1 "$BUILD_DIR/libiii_native.a.mhash" 2>/dev/null || mhash_file "$LIB_ARCHIVE")"
NKEY="${IIIS_ID:0:16}_${LIB_ID:0:16}"
# eval-route cache: the eval binary IS the subject under test — its verdicts
# (raw out + rc, incl. timeouts) are deterministic per (binary, KAT).  The
# key is computed PER run_pair from the CURRENT $EVAL_BIN so the selftest's
# fake routes can never collide with the real binary's cache.

# force-linked side-effect set — MIRRORS run_corpus.sh
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

# program-output extraction from raw eval stdout: strip protocol lines and
# the OK-marker text; comparison is trailing-newline-insensitive AND
# CR-insensitive on BOTH sides (named softnesses: msys sed strips \r from
# lines it touches — asymmetric handling manufactured 2 false OUT_DIVERGEs
# on 2488/2489, ledgered; tr -d '\r' on both sides restores symmetry).
ev_prog_out() {  # $1 raw -> $2 program bytes (normalized)
    sed -e 's/III_EVAL_OK ret=0x[0-9a-f]*//' \
        -e '/^III_EVAL_\(FAIL\|PARSE_FAIL\|READ_FAIL\|USAGE\)/d' "$1" | tr -d '\r' > "$2.t"
    printf '%s' "$(cat "$2.t")" > "$2"
    rm -f "$2.t"
}
norm_out() {  # $1 file -> $2 normalized
    tr -d '\r' < "$1" > "$2.t"
    printf '%s' "$(cat "$2.t")" > "$2"
    rm -f "$2.t"
}

PROBE_EXTRA_OBJS=()

# ── run one file through both routes ────────────────────────────────────────
# CLASS ∈ {PASS, DIVERGE, OUT_DIVERGE, EVAL_UNSUPPORTED, EVAL_TIMEOUT,
#          NATIVE_CFAIL, NATIVE_LFAIL, NATIVE_TIMEOUT}
run_pair() {
    local src="$1" base obj exe staged rc kat_id ck
    base="$(basename "$src" .iii)"
    obj="$RUN_DIR/${base}.o"
    exe="$RUN_DIR/${base}${BIN_SUFFIX}"
    CLASS="" ; RCN="" ; RCE="" ; EVOUT="" ; OUTNOTE=""
    kat_id="$(mhash_file "$src" | cut -c1-16)"
    ck="$CACHE_DIR/${base}.${NKEY}.${kat_id}"
    # ALL same-invocation read-back files live in /tmp: OneDrive serves STALE
    # reads on rapidly-rewritten files (measured 1/40 on .ev_out — the
    # read-side sibling of the staged-exec trap).  The cache dir stays on
    # OneDrive because its reads are settled (written whole runs earlier).
    NAT_OUT="/tmp/meaning_nat_$$.out"
    if [[ -f "$ck.lfail" ]]; then
        # cached link-verdict: this KAT's native needs objects OUTSIDE the
        # archive link universe (the dedicated-runner families) — a named
        # skip, re-probed only when compiler/archive/KAT change (the key).
        CLASS="NATIVE_LFAIL"; RCN=1; return
    fi
    if [[ -f "$ck.ntime" ]]; then
        CLASS="NATIVE_TIMEOUT"; RCN=124; return
    fi
    if [[ ! -f "$ck.rc" ]]; then
        rm -f "$obj"
        timeout 60 "$IIIS" "$src" --compile-only --out "$obj" >>"$LOG" 2>&1
        rc=$?
        if [[ $rc -ne 0 ]]; then CLASS="NATIVE_CFAIL"; RCN=$rc; return; fi
        rc=1
        local _la
        for _la in 1 2 3 4 5; do
            rm -f "$exe"
            gcc "$obj" -Wl,--whole-archive "${SIDE_EFFECT_OBJS[@]}" ${PROBE_EXTRA_OBJS[@]+"${PROBE_EXTRA_OBJS[@]}"} -Wl,--no-whole-archive "$LIB_ARCHIVE" \
                -lws2_32 -lkernel32 -o "$exe" >>"$LOG" 2>&1
            rc=$?
            [[ $rc -eq 0 && -f "$exe" ]] && break
            sleep 1
        done
        if [[ $rc -ne 0 ]]; then CLASS="NATIVE_LFAIL"; RCN=$rc; : > "$ck.lfail"; return; fi
        staged="/tmp/meaning_$$_${RANDOM}${BIN_SUFFIX}"
        cp "$exe" "$staged"
        timeout 120 "$staged" >"$NAT_OUT" 2>>"$LOG"
        RCN=$?
        rm -f "$staged"
        if [[ $RCN -eq 124 ]]; then CLASS="NATIVE_TIMEOUT"; rm -f "$NAT_OUT"; : > "$ck.ntime"; return; fi
        cp "$NAT_OUT" "$ck.out"
        printf '%s' "$RCN" > "$ck.rc"
        # RCN already live — never read back the just-written cache file
    else
        # cache-hot: the cache file is SETTLED (written a prior run/warmer);
        # copy to /tmp so the same-invocation reads below stay off OneDrive.
        cp "$ck.out" "$NAT_OUT" 2>/dev/null || : > "$NAT_OUT"
        RCN="$(cat "$ck.rc")"
    fi
    EVRAW="/tmp/meaning_ev_$$.out"
    local ekey_now
    ekey_now="$(mhash_file "$EVAL_BIN" | cut -c1-16)"
    ek="$CACHE_DIR/${base}.E${ekey_now}.${kat_id}"
    if [[ -f "$ek.etime" ]]; then CLASS="EVAL_TIMEOUT"; return; fi
    if [[ -f "$ek.rce" ]]; then
        RCE="$(cat "$ek.rce")"
        cp "$ek.out" "$EVRAW" 2>/dev/null || : > "$EVRAW"
    else
        timeout "$EVAL_TIMEOUT" "$EVAL_BIN" "$src" >"$EVRAW" 2>>"$LOG"
        RCE=$?
        if [[ $RCE -eq 124 ]]; then CLASS="EVAL_TIMEOUT"; : > "$ek.etime"; return; fi
        cp "$EVRAW" "$ek.out"
        printf '%s' "$RCE" > "$ek.rce"
    fi
    EVOUT="$(tail -c 300 "$EVRAW" | tr -d '\0' | tail -1)"
    case "$(cat "$EVRAW")" in
        *III_EVAL_OK*)
            if [[ "$RCN" != "$RCE" ]]; then CLASS="DIVERGE"; return; fi
            ev_prog_out "$EVRAW" "/tmp/meaning_evp_$$.out"
            norm_out "$NAT_OUT" "/tmp/meaning_natp_$$.out"
            if ! cmp -s "/tmp/meaning_natp_$$.out" "/tmp/meaning_evp_$$.out"; then
                CLASS="OUT_DIVERGE"
                OUTNOTE="native=$(wc -c < "/tmp/meaning_natp_$$.out")B eval=$(wc -c < "/tmp/meaning_evp_$$.out")B"
                return
            fi
            CLASS="PASS"
            ;;
        *III_EVAL_FAIL*)  CLASS="EVAL_UNSUPPORTED" ;;
        *)                CLASS="EVAL_UNSUPPORTED"; EVOUT="(no marker) $EVOUT" ;;
    esac
}

# compile a PROBE's same-dir .iii import closure; fills PROBE_EXTRA_OBJS
probe_closure() {  # $1 = probe src
    PROBE_EXTRA_OBJS=()
    local src="$1" dir imp iobj
    dir="$(dirname "$src")"
    for imp in $(grep -oE 'from "[^"]+\.iii"' "$src" 2>/dev/null | sed 's/from "//; s/"//' | sort -u); do
        if [[ -f "$dir/$imp" ]]; then
            iobj="$RUN_DIR/probe_$(basename "$imp" .iii).o"
            rm -f "$iobj"
            timeout 60 "$IIIS" "$dir/$imp" --compile-only --out "$iobj" >>"$LOG" 2>&1 && PROBE_EXTRA_OBJS+=("$iobj")
        fi
    done
}

# ═══ 1. SELF-TEST (comparator teeth, two-path) ══════════════════════════════
say "[meaning] == selftest =="
ST_DIR="$RUN_DIR/selftest"
mkdir -p "$ST_DIR"
# (a) agreement -> PASS
cat > "$ST_DIR/st_agree.iii" <<'IIEOF'
module st_agree
fn main() -> u64 { return 42u64 }
IIEOF
run_pair "$ST_DIR/st_agree.iii"
if [[ "$CLASS" != "PASS" ]]; then say "[meaning] SELFTEST RED: agree-case classified $CLASS (rcN=$RCN rcE=$RCE)"; exit 5; fi
# (b) rc mismatch through a FAKE eval route -> DIVERGE
cat > "$ST_DIR/fake_eval.sh" <<'SHEOF'
#!/usr/bin/env bash
echo "III_EVAL_OK ret=0x000000000000002b"
exit 43
SHEOF
chmod +x "$ST_DIR/fake_eval.sh"
EVAL_BIN_REAL="$EVAL_BIN"
EVAL_BIN="$ST_DIR/fake_eval.sh"
run_pair "$ST_DIR/st_agree.iii"
EVAL_BIN="$EVAL_BIN_REAL"
if [[ "$CLASS" != "DIVERGE" ]]; then say "[meaning] SELFTEST RED: fake-route mismatch classified $CLASS (want DIVERGE)"; exit 5; fi
# (c) unsupported construct -> never PASS
cat > "$ST_DIR/st_unsup.iii" <<'IIEOF'
module st_unsup
fn pick(x: u64) -> u64 {
    match x { 0 => { return 1u64 } _ => { return 2u64 } }
}
fn main() -> u64 { return pick(0u64) + 98u64 }
IIEOF
run_pair "$ST_DIR/st_unsup.iii"
if [[ "$CLASS" == "PASS" ]]; then say "[meaning] SELFTEST RED: unsupported construct classified PASS"; exit 5; fi
ST_UNSUP_CLASS="$CLASS"
# (d) OUTPUT divergence with EQUAL rc -> OUT_DIVERGE (the new axis has teeth)
cat > "$ST_DIR/st_out.iii" <<'IIEOF'
module st_out
extern @abi(c-msvc-x64) fn putchar(c: u32) -> u32 from "msvcrt"
fn main() -> u64 {
    putchar(65u32)
    putchar(10u32)
    putchar(66u32)
    putchar(10u32)
    return 7u64
}
IIEOF
cat > "$ST_DIR/fake_eval_out.sh" <<'SHEOF'
#!/usr/bin/env bash
printf 'A\nX\n'
echo "III_EVAL_OK ret=0x0000000000000007"
exit 7
SHEOF
chmod +x "$ST_DIR/fake_eval_out.sh"
EVAL_BIN="$ST_DIR/fake_eval_out.sh"
run_pair "$ST_DIR/st_out.iii"
EVAL_BIN="$EVAL_BIN_REAL"
if [[ "$CLASS" != "OUT_DIVERGE" ]]; then say "[meaning] SELFTEST RED: output-mismatch arm classified $CLASS (want OUT_DIVERGE)"; exit 5; fi
# (d2) and the REAL route must agree on the same program -> PASS
run_pair "$ST_DIR/st_out.iii"
if [[ "$CLASS" != "PASS" ]]; then say "[meaning] SELFTEST RED: real-route putchar case classified $CLASS (rcN=$RCN rcE=$RCE $OUTNOTE)"; exit 5; fi
say "[meaning] selftest OK (agree=PASS, rc-teeth live, unsup=$ST_UNSUP_CLASS, output-teeth live)"

# ═══ 2. THE MOUTH (Θ4): REPL transcript KAT ═════════════════════════════════
if [[ -f "$BOOT_DIR/meaning_repl.rexp" ]]; then
    if ! bash "$BOOT_DIR/run_repl_kat.sh"; then
        say "[meaning] REPL TRANSCRIPT RED (Θ4 mouth drift)"
        exit 3
    fi
    say "[meaning] repl transcript GREEN"
fi

# ═══ 2. PROBES (hard floor: every probe must PASS) ══════════════════════════
say "[meaning] == probes =="
PROBE_FAIL=0
PROBE_N=0
for src in "$BOOT_DIR"/meaning_probes/p*.iii; do
    [[ -f "$src" ]] || continue
    PROBE_N=$((PROBE_N + 1))
    probe_closure "$src"
    run_pair "$src"
    PROBE_EXTRA_OBJS=()
    if [[ "$CLASS" == "PASS" ]]; then
        say "PASS  probe $(basename "$src") rc=$RCN"
    else
        say "RED   probe $(basename "$src") class=$CLASS rcN=${RCN:-} rcE=${RCE:-} ev=${EVOUT:-} ${OUTNOTE:-}"
        PROBE_FAIL=$((PROBE_FAIL + 1))
    fi
done
if [[ $PROBE_FAIL -ne 0 ]]; then say "[meaning] PROBE FLOOR RED: $PROBE_FAIL/$PROBE_N"; exit 3; fi
say "[meaning] probe floor GREEN: $PROBE_N/$PROBE_N"

# ═══ 3. CORPUS (the WHOLE theater, up-only ratchet) ═════════════════════════
say "[meaning] == corpus (all non-negative KATs; loader + builtin tier live) =="
PASS=0; DIV=0; ODIV=0; UNSUP=0; ETMO=0; SKIP=0; TOTAL=0
declare -A UNSUP_BY
DIVLIST=()
for src in "$CORPUS_DIR"/[0-9]*_*.iii; do
    [[ -f "$src" ]] || continue
    base="$(basename "$src" .iii)"
    case "$base" in *_neg_*|*_neg) continue ;; esac
    TOTAL=$((TOTAL + 1))
    run_pair "$src"
    case "$CLASS" in
        PASS)
            PASS=$((PASS + 1))
            say "PASS  $base rc=$RCN"
            ;;
        DIVERGE)
            DIV=$((DIV + 1))
            DIVLIST+=("$base rcN=$RCN rcE=$RCE $EVOUT")
            say "DIVERGE $base rcN=$RCN rcE=$RCE ev=$EVOUT"
            ;;
        OUT_DIVERGE)
            ODIV=$((ODIV + 1))
            DIVLIST+=("$base OUTPUT $OUTNOTE")
            say "OUT_DIVERGE $base rc=$RCN $OUTNOTE"
            ;;
        EVAL_UNSUPPORTED)
            UNSUP=$((UNSUP + 1))
            key="$(printf '%s' "$EVOUT" | grep -o 'code=[0-9]* .*kind=[0-9]*' | head -1)"
            UNSUP_BY["${key:-unknown}"]=$(( ${UNSUP_BY["${key:-unknown}"]:-0} + 1 ))
            say "UNSUP $base $EVOUT"
            ;;
        EVAL_TIMEOUT)
            ETMO=$((ETMO + 1))
            say "ETIME $base (tree-walker > ${EVAL_TIMEOUT}s; definitional object, not a fast one)"
            ;;
        *)
            SKIP=$((SKIP + 1))
            say "SKIP  $base class=$CLASS rcN=${RCN:-}"
            ;;
    esac
done

say "[meaning] corpus: total=$TOTAL pass=$PASS diverge=$DIV out-diverge=$ODIV unsupported=$UNSUP eval-timeout=$ETMO native-skip=$SKIP"
say "[meaning] unsupported census (the named frontier):"
for k in "${!UNSUP_BY[@]}"; do printf '  %s -> %s\n' "$k" "${UNSUP_BY[$k]}"; done | LC_ALL=C sort | tee -a "$LOG"

if [[ $((DIV + ODIV)) -ne 0 ]]; then
    say "[meaning] DIVERGENCE RED (the instrument fired -- adjudicate per Theta-4):"
    for d in "${DIVLIST[@]}"; do say "  $d"; done
    exit 1
fi

RATCHET=0
[[ -f "$RATCHET_FILE" ]] && RATCHET="$(tr -dc '0-9' < "$RATCHET_FILE")"
RATCHET="${RATCHET:-0}"
if [[ $PASS -lt $RATCHET ]]; then
    say "[meaning] RATCHET RED: pass=$PASS < pinned=$RATCHET"
    exit 4
fi
if [[ $PASS -gt $RATCHET ]]; then
    say "[meaning] ratchet can rise: pass=$PASS > pinned=$RATCHET (raise meaning_ratchet.txt)"
fi
say "[meaning] GREEN: probes $PROBE_N/$PROBE_N, corpus $PASS/$TOTAL pass, 0 divergence, ratchet=$RATCHET"
exit 0
