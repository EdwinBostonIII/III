#!/usr/bin/env bash
# verify_cone.sh -- THE CIRCULATION (reunification L10 addition, 2026-07-02).
#
# THE PROBLEM IT KILLS: the assurance topology was BATCH -- any change waited on a full corpus
# sweep (hours) although the dependency graph is fully written down (every KAT names its externs,
# every runner names its objects).  THE FIX: compute the exact dirty cone of a change-set and
# re-verify ONLY that, maintaining a live ledger of what is verified at which content-state.
# The full sweep demotes to a periodic audit; the DDC/twin-build sovereignty goodies are preserved
# and ISOLATED behind seal_route.sh (fire only when the compiler province changes).
#
# usage:
#   verify_cone.sh --plan <changed-file>...     print the cone (modules, KATs, owners); no runs
#   verify_cone.sh <changed-file>...            verify the cone; update the ledger
#   verify_cone.sh --check                      ledger staleness audit (hash mismatch = STALE)
#   verify_cone.sh --selftest                   the falsifier teeth (comparator + staleness + cone shape)
#
# Ledger: STDLIB/build/VERIFIED.tsv   rows: <kat>\t<dep-tuple-sha256>\t<PASS|WRONG>\t<utc>
# The dep tuple of a KAT = sha256 over (its own source hash + the hashes of every organ module in
# the change-cone that it externs) -- content-addressed verification, no timestamps trusted.
set -u
III="$(cd "$(dirname "$0")/../.." && pwd)"
SC="$III/STDLIB"; CORPUS="$SC/corpus"; ORG="$SC/iii"
IIIS="$III/COMPILED/iiis-2.exe"
BUILD="$SC/build/iii"; LIB="$BUILD/libiii_native.a"
RUN="$SC/build/cone"; mkdir -p "$RUN"
LEDGER="$SC/build/VERIFIED.tsv"; touch "$LEDGER"
RC_SH="$SC/scripts/run_corpus.sh"
SCRIPTS="$SC/scripts"

# The fixed side-effect object set, PARSED LIVE from run_corpus.sh (single source of truth).
side_objs() {
    awk '/^SIDE_EFFECT_NAMES=\(/{f=1;next} f&&/^\)/{exit} f{gsub(/^[ \t]+|[ \t]+$/,"");
         n=split($0,a," "); for(i=1;i<=n;i++) print a[i]}' "$RC_SH"
}
# EXPECTED exit code for a core-loop KAT, PARSED LIVE from run_corpus.sh's table.
expected_of() {
    grep -E "^\s*\[$1\]=[0-9]+" "$RC_SH" | head -1 | sed 's/.*=//'
}
# The owning family runner of a KAT (grep the runner run-lines), or "" for core-loop.
owner_of() {
    grep -l "run $1 \|run $1	" "$SCRIPTS"/run_*_kats.sh "$SCRIPTS"/run_xii_corpus.sh 2>/dev/null | head -1
}

# ── cone computation ────────────────────────────────────────────────────────────────────────────
declare -A CONE KATS
build_cone() {
    for f in "$@"; do
        case "$f" in *.iii) CONE["$(basename "$f")"]=1;; esac
    done
    local grow=1
    while [[ $grow -eq 1 ]]; do
        grow=0
        for m in "${!CONE[@]}"; do
            while IFS= read -r dep; do
                local b; b="$(basename "$dep")"
                [[ -z "${CONE[$b]+x}" ]] && { CONE["$b"]=1; grow=1; }
            done < <(grep -rl "from \"$m\"" "$ORG" --include="*.iii" 2>/dev/null)
        done
    done
    for m in "${!CONE[@]}"; do
        while IFS= read -r k; do
            KATS["$(basename "$k" .iii)"]=1
        done < <(grep -l "from \"$m\"" "$CORPUS"/[0-9]*_*.iii 2>/dev/null)
    done
}
dep_tuple() {  # sha256 over the KAT source + every cone module it externs
    local kat="$1"; local acc="$RUN/.tuple.$$"
    sha256sum "$CORPUS/$kat.iii" > "$acc" 2>/dev/null
    for m in "${!CONE[@]}"; do
        if grep -q "from \"$m\"" "$CORPUS/$kat.iii" 2>/dev/null; then
            find "$ORG" -name "$m" -exec sha256sum {} \; >> "$acc" 2>/dev/null
        fi
    done
    sort "$acc" | sha256sum | awk '{print $1}'; rm -f "$acc"
}
ledger_put() {  # kat, tuple, status
    grep -v "^$1	" "$LEDGER" > "$LEDGER.tmp" 2>/dev/null || true
    printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LEDGER.tmp"
    mv "$LEDGER.tmp" "$LEDGER"
}

# ── the core-loop per-KAT recipe (mirrors run_corpus.sh: compile, whole-archive link with lock
#    retries, /tmp staging, timeout, EXPECTED compare) ───────────────────────────────────────────
run_core_kat() {
    local base="$1"; local exp; exp="$(expected_of "$base")"
    [[ -z "$exp" ]] && { echo "SKIP  $base : no EXPECTED entry (family or negative form)"; return 0; }
    local src="$CORPUS/$base.iii" obj="$RUN/$base.o" exe="$RUN/$base.exe" log="$RUN/$base.log"
    rm -f "$obj" "$exe" "$log"
    timeout 60 "$IIIS" "$src" --compile-only --out "$obj" >"$log" 2>&1 || { echo "FAIL  $base : compile"; return 1; }
    local sobjs=(); local se
    while IFS= read -r se; do [[ -f "$BUILD/$se" ]] && sobjs+=("$BUILD/$se"); done < <(side_objs)
    local rc=1 la
    for la in 1 2 3; do
        rm -f "$exe"
        gcc "$obj" -Wl,--whole-archive "${sobjs[@]}" -Wl,--no-whole-archive "$LIB" \
            -lws2_32 -lkernel32 -o "$exe" >>"$log" 2>&1
        rc=$?; [[ $rc -eq 0 && -f "$exe" ]] && break; sleep 1
    done
    [[ $rc -ne 0 ]] && { echo "FAIL  $base : link"; tail -3 "$log"; return 1; }
    local st="/tmp/cone_$$_$RANDOM.exe"; cp "$exe" "$st"
    timeout 600 "$st" >>"$log" 2>&1; local actual=$?; rm -f "$st"
    if [[ "$actual" == "$exp" ]]; then echo "PASS  $base : exit=$actual"; return 0
    else echo "WRONG $base : exit=$actual expected=$exp"; return 1; fi
}

# ── modes ───────────────────────────────────────────────────────────────────────────────────────
mode="verify"
case "${1:-}" in
    --plan) mode="plan"; shift;;
    --check) mode="check";;
    --selftest) mode="selftest";;
esac

if [[ "$mode" == "check" ]]; then
    stale=0
    while IFS=$'\t' read -r kat tuple status ts; do
        [[ -z "$kat" ]] && continue
        CONE=(); KATS=()
        declare -A CONE KATS
        # per-row cheap re-tuple: KAT source + its DIRECT organ externs
        acc="$RUN/.chk.$$"; sha256sum "$CORPUS/$kat.iii" > "$acc" 2>/dev/null
        while IFS= read -r m; do
            find "$ORG" -name "$m" -exec sha256sum {} \; >> "$acc" 2>/dev/null
        done < <(grep -oE 'from "[a-z0-9_]+\.iii"' "$CORPUS/$kat.iii" 2>/dev/null | sed 's/from "//; s/"//' | sort -u)
        live="$(sort "$acc" | sha256sum | awk '{print $1}')"; rm -f "$acc"
        if [[ "$live" != "$tuple" ]]; then echo "STALE $kat (content moved since $ts)"; stale=$((stale+1)); fi
    done < "$LEDGER"
    echo "[cone-check] stale=$stale"; exit $(( stale > 0 ? 1 : 0 ))
fi

if [[ "$mode" == "selftest" ]]; then
    fails=0
    # (1) CONE SHAPE: refract.iii's cone must contain its own gates and must NOT contain an
    #     unrelated organ's gate -- the cone is a cone, not the whole corpus.
    CONE=(); KATS=(); declare -A CONE KATS
    build_cone "STDLIB/iii/aether/refract.iii"
    [[ -n "${KATS[2178_refract]+x}" ]] || { echo "SELFTEST-FAIL: 2178 not in refract cone"; fails=$((fails+1)); }
    [[ -z "${KATS[1290_dijkstra]+x}" ]] || { echo "SELFTEST-FAIL: dijkstra leaked into refract cone"; fails=$((fails+1)); }
    n=${#KATS[@]}; total=$(ls "$CORPUS"/[0-9]*_*.iii | wc -l)
    [[ "$n" -lt $(( total / 4 )) ]] || { echo "SELFTEST-FAIL: cone ($n) not sharp vs total ($total)"; fails=$((fails+1)); }
    echo "selftest cone: refract -> ${#CONE[@]} modules, $n KATs (sharp vs $total)"
    # (2) COMPARATOR TEETH: a real tiny KAT judged against a deliberately WRONG expectation must
    #     report WRONG (proves the harness cannot rubber-stamp).
    src_pick="$(grep -E '^\s*\[1903_event_rewind\]=99' "$RC_SH" >/dev/null && echo 1903_event_rewind)"
    if [[ -n "$src_pick" && -f "$CORPUS/$src_pick.iii" ]]; then
        expected_of() { echo 7; }   # the lie
        r="$(run_core_kat "$src_pick" || true)"
        case "$r" in *WRONG*) echo "selftest comparator: teeth confirmed ($src_pick real exit vs lie=7)";;
                     *) echo "SELFTEST-FAIL: comparator accepted a wrong expectation: $r"; fails=$((fails+1));; esac
        expected_of() { grep -E "^\s*\[$1\]=[0-9]+" "$RC_SH" | head -1 | sed 's/.*=//'; }
    else
        echo "SELFTEST-FAIL: comparator fixture 1903_event_rewind unavailable"; fails=$((fails+1))
    fi
    # (3) STALENESS TEETH: a forged ledger row must be flagged STALE by --check.
    printf 'zz_forged_kat\t%s\tPASS\t2020-01-01T00:00:00Z\n' "deadbeef" >> "$LEDGER"
    if "$0" --check | grep -q "STALE zz_forged_kat"; then echo "selftest staleness: teeth confirmed"
    else echo "SELFTEST-FAIL: forged ledger row not flagged"; fails=$((fails+1)); fi
    grep -v "^zz_forged_kat	" "$LEDGER" > "$LEDGER.tmp" && mv "$LEDGER.tmp" "$LEDGER"
    echo "[cone-selftest] fails=$fails"; exit $(( fails > 0 ? 1 : 0 ))
fi

# plan / verify
[[ $# -lt 1 ]] && { echo "usage: verify_cone.sh [--plan|--check|--selftest] <changed-file>..."; exit 2; }
build_cone "$@"
echo "[cone] modules: ${#CONE[@]} -> ${!CONE[*]}"
echo "[cone] KATs: ${#KATS[@]}"
declare -A FAMS
for k in "${!KATS[@]}"; do
    own="$(owner_of "$k")"
    if [[ -n "$own" ]]; then FAMS["$own"]=1; echo "  $k -> $(basename "$own")"
    else echo "  $k -> core-loop"; fi
done
[[ "$mode" == "plan" ]] && exit 0

fail=0
for f in "${!FAMS[@]}"; do
    echo "[cone] family: $(basename "$f")"
    bash "$f" > "$RUN/$(basename "$f").log" 2>&1 || { echo "FAIL  family $(basename "$f")"; tail -4 "$RUN/$(basename "$f").log"; fail=$((fail+1)); }
done
for k in "${!KATS[@]}"; do
    [[ -n "$(owner_of "$k")" ]] && { ledger_put "$k" "$(dep_tuple "$k")" "PASS-family"; continue; }
    if run_core_kat "$k"; then ledger_put "$k" "$(dep_tuple "$k")" "PASS"
    else ledger_put "$k" "$(dep_tuple "$k")" "WRONG"; fail=$((fail+1)); fi
done
echo "[cone] verify done: failures=$fail"
exit $(( fail > 0 ? 1 : 0 ))
