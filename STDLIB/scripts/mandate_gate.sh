#!/usr/bin/env bash
# mandate_gate.sh -- TIER 3 RITE: a candidate mandate is measured on the repo's OWN record and
# enters law only through the live governance machine.
#
# Instances are derived LIVE (census law -- no stored expectations): BAD = targets of Revert
# commits (claims machine-contradicted by the repo's own record), GOOD = recent claim-commits
# never reverted, balanced. The baseline predicate P0 ("claims a state, carries no gate/corpus
# evidence in the same commit") is scored, its verdict bitstring ASSAYED through the compiled
# DOKIMASIA engine (an inadmissible predicate cannot be adopted no matter its score), and the
# verdict adjudicated through mandate_adopt_cli: cleared -> SEALED via governance; not cleared ->
# REFUSED with nothing proposed. BOTH driver branches are exercised every run. A candidate that
# fails separation being refused is a LAWFUL GREEN outcome -- the gate is green when the
# machinery works and speaks truth. Exit 0 = green + byte-deterministic.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/mandate"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
DK="$ROOT/STDLIB/build/ontos/dokimasia_cli.exe"
mkdir -p "$T"; cd "$ROOT"
[ -x "$IIIS" ] || { echo "[mandate_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[mandate_gate] no archive: $ARC"; exit 2; }
[ -x "$DK" ] || { echo "[mandate_gate] no dokimasia engine -- run ontos_gate.sh first"; exit 2; }

cc_one() {
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1; rc=$?
        [ "$rc" -eq 0 ] && [ -f "$out" ] && { [ "$try" -gt 1 ] && echo "[mandate_gate] settle-retry x$((try-1)) on $(basename "$src")"; return 0; }
        sleep 1
    done
    echo "[mandate_gate] COMPILE FAIL rc=$rc $(basename "$src")"; tail -6 "$out.log"; return 1
}

cc_one "$ROOT/STDLIB/iii/omnia/mandate_adopt_cli.iii" "$T/mandate_adopt_cli.o" || exit 2
rc=1
for try in 1 2 3 4 5; do
    rm -f "$T/mandate_adopt_cli.exe"
    gcc -o "$T/mandate_adopt_cli.exe" "$T/mandate_adopt_cli.o" "$ARC" \
        -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/link.log" 2>&1; rc=$?
    [ "$rc" -eq 0 ] && [ -f "$T/mandate_adopt_cli.exe" ] && break
    sleep 1
done
[ "$rc" -eq 0 ] || { echo "[mandate_gate] LINK FAIL rc=$rc"; tail -6 "$T/link.log"; exit 3; }
MA="$T/mandate_adopt_cli.exe"

rite() {
    local out="$1" rc
    : > "$out"
    "$MA" >> "$out" 2>&1; rc=$?
    [ "$rc" -eq 0 ] || { echo "[mandate_gate] driver selfprove RED rc=$rc"; tail -3 "$out"; return 3; }
    "$MA" 0 >> "$out" 2>&1; rc=$?
    [ "$rc" -eq 1 ] || { echo "[mandate_gate] refusal branch broken (rc=$rc, want 1)"; return 4; }

    local bad=() good=()
    local rh tgt subj gh skip b ch f
    # BAD rule 1: targets of true git-Revert commits (claims contradicted by an explicit revert).
    while IFS= read -r rh; do
        tgt="$(git log --format="%b" -1 "$rh" | grep -oE "This reverts commit [0-9a-f]{7,40}" | grep -oE "[0-9a-f]{7,40}" | head -1)"
        if [ -z "$tgt" ]; then
            subj="$(git log --format="%s" -1 "$rh" | sed -E 's/^Revert "(.*)"$/\1/')"
            tgt="$(git log --all --format="%H|%s" | grep -F "|$subj" | grep -v "^$rh" | head -1 | cut -d"|" -f1)"
        fi
        [ -n "$tgt" ] && bad+=("$tgt")
    done < <(git log --all --format="%H|%s" | grep -E "\|Revert \"" | cut -d"|" -f1)
    # BAD rule 2: THE TRUTH-PASS PRIORS -- this history records corrections as truth/honesty
    # passes, not reverts. For each correction commit, the immediately-prior toucher of each
    # corrected file is a machine-identified overclaim carrier: the repo's own record concedes
    # the claim (the same corroboration chain the collaborator-gate rounds validated, mechanized).
    while IFS= read -r ch; do
        while IFS= read -r f; do
            tgt="$(git log --format="%H" -1 "$ch^" -- "$f" 2>/dev/null | head -1)"
            [ -n "$tgt" ] && bad+=("$tgt")
        done < <(git show --name-only --format= "$ch" 2>/dev/null | head -4)
    done < <(git log --all --format="%H|%s" | grep -iE "\|.*(truth pass|truth-pass|overclaim|honesty pass)" | cut -d"|" -f1)
    # dedup preserving derivation order, cap at 4 (probe economy; the table names what was kept)
    local uniq=() u seen
    for u in "${bad[@]}"; do
        seen=0
        for b in "${uniq[@]}"; do
            if [ "$u" = "$b" ]; then seen=1; fi
        done
        if [ "$seen" -eq 0 ]; then uniq+=("$u"); fi
    done
    bad=("${uniq[@]:0:4}")
    local nbad=${#bad[@]}
    if [ "$nbad" -lt 2 ]; then
        echo "[mandate_gate] NAMED DEFICIT: only $nbad machine-contradicted instances; below 2+2 the rig refuses to adjudicate."
        return 5
    fi
    while IFS= read -r gh; do
        skip=0
        for b in "${bad[@]}"; do
            if [ "$gh" = "$b" ]; then skip=1; fi
        done
        if [ "$skip" -eq 0 ]; then good+=("$gh"); fi
        if [ "${#good[@]}" -ge "$nbad" ]; then break; fi
    done < <(git log -400 --format="%H|%s" | grep -iE "\|.*(GREEN|VERIFIED|COMPLETE)" | grep -vE "\|Revert" | cut -d"|" -f1)
    if [ "${#good[@]}" -ne "$nbad" ]; then
        echo "[mandate_gate] NAMED DEFICIT: could not draw $nbad clean claim-commits"
        return 5
    fi

    local bits="" correct=0 n i c claims evid v h
    echo "--- probe table (hash verdict :: subject; P0 = claims-state-without-gate-evidence; first $nbad labeled BAD) ---" >> "$out"
    for h in "${bad[@]}" "${good[@]}"; do
        subj="$(git log --format="%s" -1 "$h" 2>/dev/null | head -c 60)"
        claims=0
        if printf '%s' "$subj" | grep -qiE "GREEN|VERIFIED|COMPLETE|DONE|SEALED|FIXED|MERGED|LANDED"; then claims=1; fi
        evid=0
        if git show --name-only --format="" "$h" 2>/dev/null | grep -qE "_gate\.sh$|STDLIB/corpus/"; then evid=1; fi
        v=1
        if [ "$claims" -eq 1 ] && [ "$evid" -eq 0 ]; then v=0; fi
        bits="$bits$v"
        echo "  $h $v :: $subj" >> "$out"
    done
    i=0
    for h in "${bad[@]}"; do
        c="${bits:$i:1}"
        if [ "$c" = "0" ]; then correct=$((correct+1)); fi
        i=$((i+1))
    done
    for h in "${good[@]}"; do
        c="${bits:$i:1}"
        if [ "$c" = "1" ]; then correct=$((correct+1)); fi
        i=$((i+1))
    done
    n=$((nbad * 2))
    echo "P0 verdicts: $bits  separation: $correct/$n (threshold 3/4)" >> "$out"

    "$DK" "$bits" >> "$out" 2>&1; local dkrc=$?
    local cleared=0
    if [ "$dkrc" -eq 0 ] && [ $((correct * 4)) -ge $((3 * n)) ]; then cleared=1; fi
    echo "assay_rc=$dkrc cleared=$cleared" >> "$out"

    if [ "$cleared" -eq 1 ]; then
        "$MA" 1 >> "$out" 2>&1; rc=$?
        [ "$rc" -eq 0 ] || { echo "[mandate_gate] cleared candidate failed adoption rc=$rc"; tail -3 "$out"; return 6; }
    else
        "$MA" 0 >> "$out" 2>&1; rc=$?
        [ "$rc" -eq 1 ] || { echo "[mandate_gate] uncleared candidate was not refused rc=$rc"; return 6; }
    fi
    echo "MANDATE RITE GREEN: instances derived live, predicate assayed, verdict adjudicated honestly." >> "$out"
    return 0
}

rite "$T/run1.txt" || exit $?
rite "$T/run2.txt" || exit $?
cmp -s "$T/run1.txt" "$T/run2.txt" || { echo "[mandate_gate] NONDETERMINISM"; diff "$T/run1.txt" "$T/run2.txt" | head; exit 7; }
grep -q "MANDATE RITE GREEN" "$T/run1.txt" || { echo "[mandate_gate] not green"; tail "$T/run1.txt"; exit 8; }

echo "[mandate_gate] TIER 3 GREEN -- measured on the repo's own record, adjudicated by the live machine, byte-deterministic:"
cat "$T/run1.txt"
exit 0
