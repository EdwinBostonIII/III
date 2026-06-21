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

# ── COFF links-and-runs gates: sovcoff emits a real .o, gcc's ld links it, the OS runs it (expect 99) ──
# drive  = text-only object (.text + main).   drive2 = reloc/data object (.text + .data + REL32 -> .data).
"$IIIS" "$SOVTC/sovcoff.iii" --compile-only --out "$OUT/sovcoff.o" >/dev/null 2>&1 || { echo "[sovtc] FAIL coff (sovcoff compile)"; fail=1; }
for d in sov_drive:drive:text-only sov_drive2:drive2:reloc-data sov_drive3:drive3:extern-call sov_drive4:drive4:rodata sov_drive5:drive5:bss sov_drive6:drive6:longname; do
    SRC="${d%%:*}"; rest="${d#*:}"; EXE="${rest%%:*}"; LBL="${rest#*:}"
    if ! "$IIIS" "$SOVTC/$SRC.iii" --compile-only --out "$OUT/$SRC.o" >/dev/null 2>&1; then echo "[sovtc] FAIL coff/$LBL ($SRC compile)"; fail=1; continue; fi
    if ! gcc "$OUT/$SRC.o" "$OUT/sovas.o" "$OUT/sovparse.o" "$OUT/sovcoff.o" "$ARCH" -lws2_32 -lkernel32 -o "$OUT/$EXE.exe" >/dev/null 2>&1; then echo "[sovtc] FAIL coff/$LBL (driver link)"; fail=1; continue; fi
    timeout 25 "$OUT/$EXE.exe" > "$OUT/$EXE.o" 2>/dev/null
    magic=$(od -An -tx1 -N2 "$OUT/$EXE.o" 2>/dev/null | tr -d ' \n')   # stdout-clean: must start with COFF magic 64 86
    if [[ "$magic" != "6486" ]]; then echo "[sovtc] FAIL coff/$LBL ($EXE.o magic=$magic != 6486, stdout not clean)"; fail=1; continue; fi
    if ! gcc "$OUT/$EXE.o" -o "$OUT/$EXE-run.exe" >/dev/null 2>&1; then echo "[sovtc] FAIL coff/$LBL (gcc could not link the sovereign .o)"; fail=1; continue; fi
    timeout 10 "$OUT/$EXE-run.exe" >/dev/null 2>&1; rc=$?
    if [[ $rc -eq 99 ]]; then echo "[sovtc] PASS coff/$LBL (sovereign .o links+runs, exit 99)"; else echo "[sovtc] FAIL coff/$LBL (exit $rc)"; fail=1; fi
done

# ── S2 sovld gate: sovld lays out a PE32+ executable (NO gcc, NO ld); the OS loads + runs it (expect 99) ──
"$IIIS" "$SOVTC/sovld.iii"      --compile-only --out "$OUT/sovld.o"      >/dev/null 2>&1 || { echo "[sovtc] FAIL ld (sovld compile)"; fail=1; }
if "$IIIS" "$SOVTC/sov_drivel.iii" --compile-only --out "$OUT/sov_drivel.o" >/dev/null 2>&1 && \
   gcc "$OUT/sov_drivel.o" "$OUT/sovas.o" "$OUT/sovparse.o" "$OUT/sovld.o" "$ARCH" -lws2_32 -lkernel32 -o "$OUT/drivel.exe" >/dev/null 2>&1; then
    timeout 25 "$OUT/drivel.exe" > "$OUT/sov.exe" 2>/dev/null
    pemagic=$(od -An -tx1 -N2 "$OUT/sov.exe" 2>/dev/null | tr -d ' \n')   # must be a PE (MZ = 4d5a)
    if [[ "$pemagic" != "4d5a" ]]; then echo "[sovtc] FAIL ld (sov.exe magic=$pemagic != 4d5a)"; fail=1; fi
    timeout 10 "$OUT/sov.exe" >/dev/null 2>&1; rc=$?
    if [[ $rc -eq 99 ]]; then echo "[sovtc] PASS ld (sovereign PE32+ -- no gcc/ld -- loads+runs, exit 99)"; else echo "[sovtc] FAIL ld (sov.exe exit $rc)"; fail=1; fi
else echo "[sovtc] FAIL ld (driver build)"; fail=1; fi

if [[ $fail -eq 0 ]]; then echo "[sovtc] ALL PASS"; exit 0; fi
echo "[sovtc] FAILURES PRESENT"; exit 1
