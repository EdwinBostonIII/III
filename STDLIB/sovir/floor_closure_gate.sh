#!/usr/bin/env bash
# floor_closure_gate.sh -- enforces INVARIANT I1 of DOCS/III-UNIFIED-ARCHITECTURE.md:
#
#   The sovereign TRUST FLOOR (the SVIR anchor + backends + the sovereign compile path)
#   imports ONLY libc (msvcrt) or another floor member.  No edge may reach UP from the
#   floor into the production body (R3 compiler / R5 faculties / R6 apps).  A single
#   outward import is a trust-floor breach: the floor would no longer be auditable in
#   isolation, and the sovereignty claim would rest on un-audited outer code.
#
# This is the hard, MEASURED invariant of the architecture (green as of 2026-07-06).
# No Python (project law L4): grep + POSIX shell only.  No .iii is sealed by this file
# (seal_sources.sh seals STDLIB/iii/** only), so this gate is additive and seal-neutral.
#
# Usage:
#   bash floor_closure_gate.sh              # check the live floor -> PASS(0)/FAIL(1)
#   bash floor_closure_gate.sh --selftest   # prove the teeth (both arms) -> PASS(0)/FAIL(1)
#
# Teeth: append `from "bigint.iii"` to any floor member -> this reddens (exit 1).

set -u
SD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SD/../.." && pwd)"

# The floor membership IS the floor definition.  Extend DELIBERATELY, never incidentally
# -- adding a member here is an architectural act (it widens what "sovereign floor" means).
FLOOR_FILES="
STDLIB/sovir/svir_verify.iii
STDLIB/sovir/svir_prog.iii
STDLIB/sovir/svir_x86.iii
STDLIB/sovir/svir_wasm.iii
STDLIB/sovir/svir_interp.iii
STDLIB/sovir/svir_dis.iii
STDLIB/sovir/ccsv.iii
STDLIB/sovir/iiisv.iii
STDLIB/sovir/iiisv2.iii
STDLIB/sovtc/sovas.iii
STDLIB/sovtc/sovparse.iii
STDLIB/sovtc/sovcoff.iii
STDLIB/sovtc/sovld.iii
"

# Permitted import targets = libc shim + a generated floor artifact + every floor basename.
#  - msvcrt   : the irreducible libc floor (malloc/free/syscalls) -- part of R0's honest TCB
#  - gen_svir : a GENERATED SVIR module (absent statically; svir_interp/svir_dis compile
#               against it at gate time) -- within-floor by construction
ALLOW="msvcrt gen_svir"
for f in $FLOOR_FILES; do ALLOW="$ALLOW $(basename "$f" .iii)"; done

# target_allowed <import-target> -> prints "1" if inside the floor, "0" otherwise
target_allowed() {
    local base; base="$(basename "$1" .iii)"
    local a
    for a in $ALLOW; do [ "$base" = "$a" ] && { echo 1; return; }; done
    echo 0
}

if [ "${1:-}" = "--selftest" ]; then
    # Two-path teeth (project law: prove POSITIVE and NEGATIVE arms, non-tautologically):
    # distinct inputs must drive distinct verdicts, or the gate proves nothing.
    fails=0
    for good in msvcrt svir_prog.iii gen_svir sovld.iii; do
        [ "$(target_allowed "$good")" = "1" ] || { echo "SELFTEST FAIL: '$good' should be ALLOWED"; fails=$((fails+1)); }
    done
    for bad in bigint.iii cg_r3.iii keccak.iii xii_canonicalise.iii; do
        [ "$(target_allowed "$bad")" = "0" ] || { echo "SELFTEST FAIL: '$bad' should be a BREACH"; fails=$((fails+1)); }
    done
    if [ "$fails" -eq 0 ]; then echo "SELFTEST: PASS (4 floor targets admitted, 4 body targets rejected)"; exit 0
    else echo "SELFTEST: FAIL ($fails)"; exit 1; fi
fi

cd "$ROOT" || exit 2
breach=0; present=0
for f in $FLOOR_FILES; do
    if [ ! -f "$f" ]; then echo "MISSING floor member: $f"; breach=$((breach+1)); continue; fi
    present=$((present+1))
    # every `from "X"` edge in this floor member
    while IFS= read -r t; do
        [ -z "$t" ] && continue
        if [ "$(target_allowed "$t")" = "0" ]; then
            echo "BREACH: $(basename "$f") imports \"$t\" -- OUTSIDE the trust floor (I1 violated)"
            breach=$((breach+1))
        fi
    done < <(grep -oE 'from "[^"]+"' "$f" | sed 's/from "//;s/"//')
done

echo "floor members checked: $present ; breaches: $breach"
if [ "$breach" -eq 0 ]; then echo "FLOOR CLOSURE: PASS (I1 holds -- the sovereign floor is audit-closed)"; exit 0
else echo "FLOOR CLOSURE: FAIL (I1 breached -- an outward import reaches into the body)"; exit 1; fi
