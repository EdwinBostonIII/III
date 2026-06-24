#!/usr/bin/env bash
# run_eidos_svir.sh -- Phase Omega2 GATE: route a REAL EIDOS ripple through SVIR (the EIDOS->SVIR completion, FR-1).
#
# Today EIDOS compiles cg_r3 -> x86 DIRECTLY, never through SVIR, so a ripple is not attestable by the SVIR/zk path.
# This gate closes that: the canonical demonstrator ripple R0 (eidos_ripple_r0.iii) -- the self-contained
# event->fold->inverse kernel of eidos::ripple -- is lowered by the INDEPENDENT iiisv (.iii->SVIR) front-end and run
# on BOTH back-ends, and its result is cross-checked BYTE-FOR-BYTE against the LIVE eidos::ripple organ.
#
# ADR-Omega2 (no concession): R0 uses real .iii surface constructs (const, `as` casts, @export, fixed arrays) that
# the integer-core iiisv did NOT accept -- iiisv was EXTENDED for them (mirrored in iiisv2 so the DDC axis still
# converges byte-identically), rather than down-scoping the ripple to a toy.
#
# Acceptance (all must hold, exit 99 each unless noted):
#   N  NATIVE  : the LIVE organ (real rf_rank verbs + isub log) folds the canonical geometry == GOLDEN  -> certifies GOLDEN is real
#   V  VERIFY  : iiisv's SVIR for R0 passes the auditable svir_verify
#   D  DDC     : iiisv and iiisv2 emit BYTE-IDENTICAL SVIR for R0 (frontend diversity holds across the new constructs)
#   X  x86     : R0's SVIR runs to 99 on the sovereign x86 back-end (sovas+sovld, kernel32-only)
#   W  wasm    : R0's SVIR runs to 99 on wasm (node)
#   C  cg_r3   : R0 compiled by the MAINLINE cg_r3 -> sovereign x86 also runs to 99 (SVIR route faithful to native route)
#   F  FOLD    : the live organ's printed fold == R0's GOLDEN constant == the canonical value (byte-for-byte)
#   !  NEG-ARM : a R0 with ONE rank entry corrupted -> SVIR -> x86 does NOT return 99 (the gate discriminates)
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; BOOT="$ROOT/STDLIB/build/_sovboot"
W="$ROOT/STDLIB/build/sovir"; LIB="$ROOT/STDLIB/build/iii/libiii_native.a"; mkdir -p "$W" "$BOOT"
fail=0; say(){ echo "[eidos-svir] $*"; }
R0="$S/eidos_ripple_r0.iii"
CANON=675673294   # the canonical fold; also the GOLDEN constant baked into R0 and eidos_ripple_native.iii

# ---- tools ----
for m in svir_x86 svir_wasm iiisv iiisv2 svir_verify verify_main; do
  "$IIIS" "$S/$m.iii" --compile-only --out "$W/$m.o" >/dev/null 2>&1 || { say "FAIL compile tool $m"; fail=1; }
done
gcc "$W/iiisv.o"  -o "$W/iiisv.exe"  2>/dev/null || { say "FAIL link iiisv";  fail=1; }
gcc "$W/iiisv2.o" -o "$W/iiisv2.exe" 2>/dev/null || { say "FAIL link iiisv2"; fail=1; }
[ -s "$BOOT/sovas_main.exe" ] && [ -s "$BOOT/sovlink_main.exe" ] && [ -s "$BOOT/crt0_sov.o" ] || { bash "$S/run_svir.sh" >/dev/null 2>&1; }

x86run(){ local geno="$1" lbl="$2"
  gcc "$W/svir_x86.o" "$geno" -o "$W/tx_$lbl.exe" 2>/dev/null || { echo 200; return; }
  "$W/tx_$lbl.exe" > "$W/$lbl.s" 2>/dev/null
  timeout 25 "$BOOT/sovas_main.exe" "$W/$lbl.s" > "$W/$lbl.o2" 2>/dev/null || { echo 201; return; }
  timeout 25 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/$lbl.o2" > "$W/$lbl.x86.exe" 2>/dev/null || { echo 202; return; }
  timeout 10 "$W/$lbl.x86.exe" >/dev/null 2>&1; echo $?; }
wasmrun(){ local geno="$1" lbl="$2"
  gcc "$W/svir_wasm.o" "$geno" -o "$W/tw_$lbl.exe" 2>/dev/null || { echo 200; return; }
  "$W/tw_$lbl.exe" > "$W/$lbl.wasm" 2>/dev/null
  node "$S/run_wasm.mjs" "$W/$lbl.wasm" >/dev/null 2>&1; echo $?; }

# ---- N: NATIVE organ certifies GOLDEN ----
"$IIIS" "$S/eidos_ripple_native.iii" --compile-only --out "$W/erip_native.o" >/dev/null 2>&1 || { say "FAIL compile native"; fail=1; }
gcc "$W/erip_native.o" "$LIB" -lkernel32 -o "$W/erip_native.exe" 2>/dev/null || { say "FAIL link native"; fail=1; }
NF=$(timeout 30 "$W/erip_native.exe" 2>/dev/null | head -1); nrc=${PIPESTATUS[0]}

# ---- D: R0 -> SVIR by both emitters, byte-identical ----
"$W/iiisv.exe"  "$R0" > "$W/gen_r0_A.iii" 2>/dev/null
"$W/iiisv2.exe" "$R0" > "$W/gen_r0_B.iii" 2>/dev/null
ddc=1; cmp -s "$W/gen_r0_A.iii" "$W/gen_r0_B.iii" || ddc=0
cp "$W/gen_r0_A.iii" "$W/gen_r0.iii"

# ---- V: verifier accepts the SVIR ----
"$IIIS" "$W/gen_r0.iii" --compile-only --out "$W/gen_r0.o" >/dev/null 2>&1 || { say "FAIL compile gen_r0"; fail=1; }
gcc "$W/verify_main.o" "$W/svir_verify.o" "$W/gen_r0.o" -o "$W/r0_vfy.exe" 2>/dev/null
timeout 10 "$W/r0_vfy.exe" >/dev/null 2>&1; vrc=$?

# ---- X / W: R0's SVIR runs to 99 on both back-ends ----
xrc=$(x86run "$W/gen_r0.o" r0); wrc=$(wasmrun "$W/gen_r0.o" r0)
k=$(objdump -p "$W/r0.x86.exe" 2>/dev/null | grep -ic "DLL Name")
k32=$(objdump -p "$W/r0.x86.exe" 2>/dev/null | grep -i "DLL Name" | grep -ic kernel32)

# ---- C: R0 by mainline cg_r3 -> sovereign x86 (the existing native route) ----
"$IIIS" "$R0" --compile-only --out "$W/r0_cg.o" >/dev/null 2>&1 || { say "FAIL compile R0 cg_r3"; fail=1; }
timeout 25 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/r0_cg.o" > "$W/r0_cg.exe" 2>/dev/null
timeout 10 "$W/r0_cg.exe" >/dev/null 2>&1; cgrc=$?

# ---- F: fold cross-check (byte-for-byte): live organ == R0 GOLDEN == canonical ----
GR0=$(grep -E 'const GOLDEN' "$R0" | grep -oE '= *[0-9]+' | grep -oE '[0-9]+' | head -1)
foldok=0; [ "$NF" = "$CANON" ] && [ "$GR0" = "$CANON" ] && foldok=1

# ---- !: NEGATIVE ARM -- a faithless R0 (one rank corrupted) must NOT pass ----
sed 's/RANK\[1\] = 1u8/RANK[1] = 9u8/' "$R0" > "$W/r0_bad.iii"
"$W/iiisv.exe" "$W/r0_bad.iii" > "$W/gen_bad.iii" 2>/dev/null
"$IIIS" "$W/gen_bad.iii" --compile-only --out "$W/gen_bad.o" >/dev/null 2>&1
badrc=$(x86run "$W/gen_bad.o" rbad)
neg=0; [ "$badrc" != "99" ] && neg=1

# ---- verdict ----
if [ $nrc -eq 99 ] && [ $vrc -eq 99 ] && [ "$ddc" = "1" ] && [ "$xrc" = "99" ] && [ "$wrc" = "99" ] \
   && [ $cgrc -eq 99 ] && [ "$k" = "1" ] && [ "$k32" = "1" ] && [ "$foldok" = "1" ] && [ "$neg" = "1" ]; then
  say "EIDOS->SVIR : the REAL eidos::ripple kernel R0 (event->fold->inverse: rank-derived verbs, content-address enc=verb*65536+a*256+b, temporal fold state'=(BASE*state+enc)%p) lowered by the INDEPENDENT iiisv -> SVIR ($(wc -c < "$W/gen_r0.iii") B), svir_verify-accepted, runs 99 on x86(sovereign,kernel32-only) AND wasm; iiisv==iiisv2 BYTE-IDENTICAL (DDC frontend axis holds across the new const/as/@export/array constructs); cg_r3 native route also 99; and the SVIR fold == the LIVE organ's fold == $CANON byte-for-byte (rf_rank+isub, real). A corrupted-rank R0 is REJECTED (x86 rc=$badrc!=99). EIDOS is now attestable through SVIR -- Omega2 CLOSED (extended iiisv, did NOT down-scope the ripple)."
else
  say "FAIL eidos->svir: native=$nrc verify=$vrc ddc=$ddc x86=$xrc wasm=$wrc cg_r3=$cgrc dlls=$k k32=$k32 foldok=$foldok(NF=$NF GR0=$GR0 CANON=$CANON) neg=$neg(badrc=$badrc)"; fail=1
fi
exit $fail
