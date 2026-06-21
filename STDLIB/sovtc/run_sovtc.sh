#!/usr/bin/env bash
# STDLIB/sovtc/run_sovtc.sh — the SOVEREIGN-TOOLCHAIN self-test gate.
#
# The sovereign toolchain (sovas encoder + sovparse parser) is a META-TOOL with a special link requirement
# (its test exes link sovas.o + sovparse.o DIRECTLY on the line, not via the stdlib archive), so it is NOT a
# stdlib conformance test and does NOT live in STDLIB/corpus/ (which would FATAL run_corpus on a missing
# EXPECTED entry and contend for corpus numbers with other tracks).  This runner is its decoupled gate.
#
# Each test exits 99 on success.  Exit 0 = all toolchain tests pass.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
ARCH="$ROOT/STDLIB/build/iii/libiii_native.a"
SOVTC="$ROOT/STDLIB/sovtc"
OUT="$ROOT/STDLIB/build/sovtc"
mkdir -p "$OUT"

"$IIIS" "$SOVTC/sovas.iii"    --compile-only --out "$OUT/sovas.o"    || { echo "[sovtc] FATAL: sovas compile";    exit 2; }
"$IIIS" "$SOVTC/sovparse.iii" --compile-only --out "$OUT/sovparse.o" || { echo "[sovtc] FATAL: sovparse compile"; exit 2; }

fail=0
for t in test_encode test_spine test_reloc test_store test_lea test_unknown test_call test_cmp test_branch test_sibcall; do
    if ! "$IIIS" "$SOVTC/$t.iii" --compile-only --out "$OUT/$t.o" >/dev/null 2>&1; then echo "[sovtc] FAIL $t (compile)"; fail=1; continue; fi
    if ! gcc "$OUT/$t.o" "$OUT/sovas.o" "$OUT/sovparse.o" "$ARCH" -lws2_32 -lkernel32 -o "$OUT/$t.exe" >/dev/null 2>&1; then echo "[sovtc] FAIL $t (link)"; fail=1; continue; fi
    timeout 25 "$OUT/$t.exe" >/dev/null 2>&1; rc=$?
    if [[ $rc -eq 99 ]]; then echo "[sovtc] PASS $t (exit 99)"; else echo "[sovtc] FAIL $t (exit $rc)"; fail=1; fi
done

# ── COFF links-and-runs gate: sovcoff emits a real .o, gcc's ld links it, the OS runs it (expect 99) ──
if ! "$IIIS" "$SOVTC/sovcoff.iii"   --compile-only --out "$OUT/sovcoff.o"   >/dev/null 2>&1; then echo "[sovtc] FAIL coff (sovcoff compile)"; fail=1; fi
if ! "$IIIS" "$SOVTC/sov_drive.iii" --compile-only --out "$OUT/sov_drive.o" >/dev/null 2>&1; then echo "[sovtc] FAIL coff (driver compile)"; fail=1; fi
if gcc "$OUT/sov_drive.o" "$OUT/sovas.o" "$OUT/sovparse.o" "$OUT/sovcoff.o" "$ARCH" -lws2_32 -lkernel32 -o "$OUT/drive.exe" >/dev/null 2>&1; then
    timeout 25 "$OUT/drive.exe" > "$OUT/out.o" 2>/dev/null
    # stdout-cleanliness: out.o must START with the COFF magic 64 86 (AMD64 machine, LE) -- no leading runtime noise
    magic=$(od -An -tx1 -N2 "$OUT/out.o" 2>/dev/null | tr -d ' \n')
    if [[ "$magic" != "6486" ]]; then echo "[sovtc] FAIL coff (out.o magic=$magic, expected 6486 -- stdout not clean)"; fail=1; fi
    if gcc "$OUT/out.o" -o "$OUT/out.exe" >/dev/null 2>&1; then
        timeout 10 "$OUT/out.exe" >/dev/null 2>&1; rc=$?
        if [[ $rc -eq 99 ]]; then echo "[sovtc] PASS coff (sovereign .o links+runs, exit 99)"; else echo "[sovtc] FAIL coff (out.exe exit $rc)"; fail=1; fi
    else echo "[sovtc] FAIL coff (gcc could not link the sovereign .o)"; fail=1; fi
else echo "[sovtc] FAIL coff (driver link)"; fail=1; fi

if [[ $fail -eq 0 ]]; then echo "[sovtc] ALL PASS"; exit 0; fi
echo "[sovtc] FAILURES PRESENT"; exit 1
