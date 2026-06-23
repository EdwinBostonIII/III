#!/usr/bin/env bash
# run_zk.sh -- ZK-ATTESTED EXECUTION gate.  ONE field recurrence x_{i+1}=(x_i^2+c) mod p (p=998244353,c=7,x_0=3),
# proven two ways that must agree:
#   (A) ZK-ATTESTED: zk_svir_exec drives III's general zk_air STARK organ -> the honest trace's AIR holds + CP
#       consistent, AND a TAMPERED trace is rejected (air_constraints_hold==0).  Exit 99.
#   (B) SOVEREIGN-RUN: the SAME recurrence (indep_recur.iii) -> iiisv -> SVIR -> x86(sovereign)+wasm -> x_7==
#       254673617 -> 99 ; cg_r3 differential -> 99.
# The provable-execution pillar fused to the sovereign-execution layer.  Honest scope: attests a field
# recurrence's trace (zkVM over arbitrary SVIR bytecode + i64-limb arithmetization is the larger goal de-risked).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; BOOT="$ROOT/STDLIB/build/_sovboot"
W="$ROOT/STDLIB/build/sovir"; LIB="$ROOT/STDLIB/build/iii/libiii_native.a"; mkdir -p "$W"
fail=0; say(){ echo "[zk] $*"; }
for m in svir_x86 svir_wasm iiisv zk_svir_exec zk_svir_add; do "$IIIS" "$S/$m.iii" --compile-only --out "$W/$m.o" >/dev/null 2>&1 || { say "FAIL compile $m"; fail=1; }; done
gcc "$W/iiisv.o" -o "$W/iiisv.exe" 2>/dev/null

# (0) zkVM FOUNDATION: the SVIR 64-bit ADD opcode arithmetized over the 30-bit field via 14-bit limbs + carry chain.
gcc "$W/zk_svir_add.o" "$LIB" -lkernel32 -o "$W/zk_svir_add.exe" 2>/dev/null
timeout 30 "$W/zk_svir_add.exe" >/dev/null 2>&1; arc=$?
if [ $arc -eq 99 ]; then say "zkVM-ADD : SVIR i64 ADD arithmetized over GF(998244353) via 14-bit limb decomposition + carry-chain AIR (zk_air) ; honest trace holds + forged result AND forged carry both rejected -> 99"
else say "FAIL zkVM-ADD: zk_svir_add=$arc (1=satisfaction 2/3=cp 4=result-tamper 5=carry-tamper 6=re-verify)"; fail=1; fi

# (A) ZK-attested.  zk_air (with the additive air_lde_at accessor) is in libiii_native.a; link the archive.
gcc "$W/zk_svir_exec.o" "$LIB" -lkernel32 -o "$W/zk_svir_exec.exe" 2>/dev/null
timeout 30 "$W/zk_svir_exec.exe" >/dev/null 2>&1; zrc=$?
if [ $zrc -eq 99 ]; then say "ZK-ATTESTED : zk_air arithmetizes the trace; PROVER satisfaction (air_constraints_hold + CP consistent) + VERIFIER reproduces the constraint from openings (air_combine_opened) + 2-cell soundness negative (forged trace rejected) -> 99"
else say "FAIL zk: zk_svir_exec=$zrc (1=satisfaction 2/3=cp 6=verifier-bridge 4/7=tamper-NOT-rejected 5=re-verify)"; fail=1; fi

# (B) sovereign-run of the SAME recurrence
"$W/iiisv.exe" "$ROOT/STDLIB/independence/indep_recur.iii" > "$W/gen_rec.iii" 2>/dev/null
"$IIIS" "$W/gen_rec.iii" --compile-only --out "$W/gen_rec.o" >/dev/null 2>&1
gcc "$W/svir_x86.o" "$W/gen_rec.o" -o "$W/tx_rec.exe" 2>/dev/null; "$W/tx_rec.exe" > "$W/rec.s" 2>/dev/null
timeout 20 "$BOOT/sovas_main.exe" "$W/rec.s" > "$W/rec.o2" 2>/dev/null
timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/rec.o2" > "$W/rec.x86.exe" 2>/dev/null
timeout 10 "$W/rec.x86.exe" >/dev/null 2>&1; xrc=$?
k=$(objdump -p "$W/rec.x86.exe" 2>/dev/null | grep -ic "DLL Name")
gcc "$W/svir_wasm.o" "$W/gen_rec.o" -o "$W/tw_rec.exe" 2>/dev/null; "$W/tw_rec.exe" > "$W/rec.wasm" 2>/dev/null
node "$S/run_wasm.mjs" "$W/rec.wasm" >/dev/null 2>&1; wrc=$?
"$IIIS" "$ROOT/STDLIB/independence/indep_recur.iii" --compile-only --out "$W/rec_cg.o" >/dev/null 2>&1
timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/rec_cg.o" > "$W/rec_cg.exe" 2>/dev/null
timeout 10 "$W/rec_cg.exe" >/dev/null 2>&1; crc=$?
if [ $xrc -eq 99 ] && [ $wrc -eq 99 ] && [ $crc -eq 99 ] && [ "$k" = "1" ]; then say "SOVEREIGN-RUN : same recurrence -> iiisv -> SVIR -> x86(sovereign)=99 wasm=99 ; cg_r3=99 (x_7==254673617)"
else say "FAIL sovereign: x86=$xrc wasm=$wrc cg_r3=$crc dlls=$k"; fail=1; fi

if [ $fail -eq 0 ]; then
  say "ZK-ATTESTED EXECUTION -- one recurrence, ZK-proven by III's general zk_air (tampered trace rejected) AND sovereign-run via the SVIR toolchain (x86+wasm, cg_r3-agreed), agreeing on x_7=254673617."
fi
exit $fail
