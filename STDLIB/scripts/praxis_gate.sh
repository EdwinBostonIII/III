#!/usr/bin/env bash
# praxis_gate.sh -- THE MANDATE RITE, re-derived from clean objects every run.
#
# PRAXIS (omnia/praxis.iii) holds the witnessed trace: pinned events are read into EIDOLOS and sealed
# (the kept house, the Fold), and a claim stands ONLY if the trace determines it (eol_judge_claim = 1).
# The naked claim -- "done" with nothing witnessed -- is a DEFECT and is REFUSED; an unrelated pin buys
# nothing; the trace itself is tamper-evident (exec_cert incremental sha256: same stream = same seal,
# one perturbed byte = a different seal). The CLI carrier is the judgment seat the harness hooks call:
# argv[1] = the pinned trace (authored by the HOOK, never the agent), argv[2] = the claim.
# Exit 0 = green + byte-deterministic; non-zero = the failed stage (named by message).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/praxis"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$T"; cd "$ROOT"
[ -x "$IIIS" ] || { echo "[praxis_gate] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ] || { echo "[praxis_gate] no archive: $ARC"; exit 2; }

cc_one() {
    local src="$1" out="$2" try rc
    for try in 1 2 3; do
        "$IIIS" "$src" --compile-only --out "$out" > "$out.log" 2>&1; rc=$?
        [ "$rc" -eq 0 ] && [ -f "$out" ] && { [ "$try" -gt 1 ] && echo "[praxis_gate] settle-retry x$((try-1)) on $(basename "$src")"; return 0; }
        sleep 1
    done
    echo "[praxis_gate] COMPILE FAIL rc=$rc $(basename "$src")"; tail -6 "$out.log"; return 1
}

cc_one "$ROOT/STDLIB/iii/omnia/praxis.iii"      "$T/praxis.o"      || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/praxis_cli.iii"  "$T/praxis_cli.o"  || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/eidolos.iii"     "$T/eidolos.o"     || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/exec_cert.iii"   "$T/exec_cert.o"   || exit 2
cc_one "$ROOT/STDLIB/iii/omnia/isub.iii"        "$T/isub.o"        || exit 2   # eidolos calls newer isub_* than the archive
cc_one "$ROOT/STDLIB/iii/numera/idfold.iii"     "$T/idfold.o"      || exit 2   # the ONE identity seat eidolos folds through

# praxis_cli.o FIRST: eidolos carries its own main; under --allow-multiple-definition the first wins.
rc=1
for try in 1 2 3 4 5; do
    rm -f "$T/praxis_cli.exe"
    gcc -o "$T/praxis_cli.exe" "$T/praxis_cli.o" "$T/praxis.o" "$T/eidolos.o" "$T/exec_cert.o" "$T/isub.o" "$T/idfold.o" "$ARC" \
        -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/link.log" 2>&1; rc=$?
    [ "$rc" -eq 0 ] && [ -f "$T/praxis_cli.exe" ] && break
    sleep 1
done
[ "$rc" -eq 0 ] || { echo "[praxis_gate] LINK FAIL rc=$rc"; tail -6 "$T/link.log"; exit 2; }

# one full rite = selfprove + the earned case + the naked case, into one transcript
rite() {
    local out="$1" stg="$T/praxis_run.exe" rc
    cp "$T/praxis_cli.exe" "$stg"
    "$stg" > "$out" 2>&1; rc=$?
    [ "$rc" -eq 0 ] || { echo "[praxis_gate] SELF-REFUSED rc=$rc"; tail -8 "$out"; rm -f "$stg"; return 5; }
    "$stg" "[gate_green < exit_zero] [done < gate_green]" "[done < exit_zero]" >> "$out" 2>&1; rc=$?
    [ "$rc" -eq 0 ] || { echo "[praxis_gate] earned claim did not stand (rc=$rc)"; tail -4 "$out"; rm -f "$stg"; return 3; }
    "$stg" "[readme < prose]" "[done < exit_zero]" >> "$out" 2>&1; rc=$?
    [ "$rc" -eq 1 ] || { echo "[praxis_gate] naked claim was NOT refused (rc=$rc)"; tail -4 "$out"; rm -f "$stg"; return 4; }
    "$stg" "[edit_praxis_iii < sha_aaaa] [gate_green < exit_zero] [done < gate_green]" "[done < exit_zero]" >> "$out" 2>&1; rc=$?
    [ "$rc" -eq 0 ] || { echo "[praxis_gate] covered edit did not stand (rc=$rc)"; tail -4 "$out"; rm -f "$stg"; return 8; }
    "$stg" "[gate_green < exit_zero] [edit_praxis_iii < sha_aaaa] [done < gate_green]" "[done < exit_zero]" >> "$out" 2>&1; rc=$?
    [ "$rc" -eq 3 ] || { echo "[praxis_gate] STALE was NOT refused with 3 (rc=$rc)"; tail -4 "$out"; rm -f "$stg"; return 9; }
    rm -f "$stg"
    return 0
}

rite "$T/run1.txt" || exit $?
rite "$T/run2.txt" || exit $?
cmp -s "$T/run1.txt" "$T/run2.txt" || { echo "[praxis_gate] NONDETERMINISM"; diff "$T/run1.txt" "$T/run2.txt" | head; exit 6; }
grep -q "praxis_selfprove = 0" "$T/run1.txt" || { echo "[praxis_gate] selfprove not green"; tail -8 "$T/run1.txt"; exit 7; }
grep -q "STANDS" "$T/run1.txt" || { echo "[praxis_gate] no STANDS in transcript"; tail -8 "$T/run1.txt"; exit 7; }
grep -q "DEFECT" "$T/run1.txt" || { echo "[praxis_gate] no DEFECT in transcript"; tail -8 "$T/run1.txt"; exit 7; }
grep -q "STALE" "$T/run1.txt" || { echo "[praxis_gate] no STALE in transcript"; tail -8 "$T/run1.txt"; exit 7; }

echo "[praxis_gate] THE MANDATE IS GREEN -- the naked claim is a DEFECT, the earned claim stands, the trace is tamper-evident, byte-deterministic:"
cat "$T/run1.txt"
exit 0
