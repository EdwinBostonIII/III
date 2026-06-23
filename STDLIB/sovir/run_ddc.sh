#!/usr/bin/env bash
# run_ddc.sh -- the DDC frontend-closure gate.  Two implementation-independent .iii->SVIR emitters (iiisv =
# recursive precedence-climbing; iiisv2 = explicit shunting-yard) must converge BYTE-IDENTICALLY on the
# canonical SVIR v1 encoding (DOCS/SVIR-V1-CANONICAL.md) for real III source; both outputs must pass the
# auditable verifier; and the (shared) result must still lower + run to 99 on x86(sovereign) + WASM.
# A backdoor in one emitter, absent from the other, reddens the cmp.  RESIDUAL (DOCS/SVIR-DDC-RESIDUAL.md):
# closes FRONTEND diversity only -- the gcc-iiis-0 seed + author-diversity remain.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; BOOT="$ROOT/STDLIB/build/_sovboot"
W="$ROOT/STDLIB/build/sovir"; mkdir -p "$W" "$BOOT"
fail=0; say(){ echo "[ddc] $*"; }

# tools
for m in svir_x86 svir_wasm iiisv iiisv2 svir_verify verify_main; do
  "$IIIS" "$S/$m.iii" --compile-only --out "$W/$m.o" >/dev/null 2>&1 || { say "FAIL compile $m"; fail=1; }
done
gcc "$W/iiisv.o"  -o "$W/iiisv.exe"  2>/dev/null
gcc "$W/iiisv2.o" -o "$W/iiisv2.exe" 2>/dev/null
[ -s "$BOOT/sovas_main.exe" ] && [ -s "$BOOT/sovlink_main.exe" ] && [ -s "$BOOT/crt0_sov.o" ] || { bash "$S/run_svir.sh" >/dev/null 2>&1; }

for p in indep_toolchain indep_ops indep_bignum; do
  src="$ROOT/STDLIB/independence/$p.iii"
  "$W/iiisv.exe"  "$src" > "$W/${p}_A.iii" 2>/dev/null
  "$W/iiisv2.exe" "$src" > "$W/${p}_B.iii" 2>/dev/null
  if ! cmp -s "$W/${p}_A.iii" "$W/${p}_B.iii"; then say "FAIL $p: iiisv != iiisv2 (frontend diverged)"; fail=1; continue; fi
  # verifier accepts the (identical) module
  "$IIIS" "$W/${p}_A.iii" --compile-only --out "$W/${p}_gen.o" >/dev/null 2>&1
  gcc "$W/verify_main.o" "$W/svir_verify.o" "$W/${p}_gen.o" -o "$W/${p}_vfy.exe" 2>/dev/null
  "$W/${p}_vfy.exe" >/dev/null 2>&1; vrc=$?
  # x86 (sovereign) + wasm still run to 99
  gcc "$W/svir_x86.o"  "$W/${p}_gen.o" -o "$W/${p}_tx.exe" 2>/dev/null; "$W/${p}_tx.exe" > "$W/${p}.s" 2>/dev/null
  timeout 25 "$BOOT/sovas_main.exe" "$W/${p}.s" > "$W/${p}.o2" 2>/dev/null
  timeout 25 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/${p}.o2" > "$W/${p}.x86.exe" 2>/dev/null
  timeout 10 "$W/${p}.x86.exe" >/dev/null 2>&1; xrc=$?
  k=$(objdump -p "$W/${p}.x86.exe" 2>/dev/null | grep -ic "DLL Name")
  gcc "$W/svir_wasm.o" "$W/${p}_gen.o" -o "$W/${p}_tw.exe" 2>/dev/null; "$W/${p}_tw.exe" > "$W/${p}.wasm" 2>/dev/null
  node "$S/run_wasm.mjs" "$W/${p}.wasm" >/dev/null 2>&1; wrc=$?
  if [ $vrc -eq 99 ] && [ $xrc -eq 99 ] && [ $wrc -eq 99 ] && [ "$k" = "1" ]; then
    say "$p : iiisv==iiisv2 byte-identical ($(wc -c < "$W/${p}_A.iii") B) ; verifier OK ; x86(sovereign)=99 wasm=99"
  else say "FAIL $p: verify=$vrc x86=$xrc wasm=$wrc dlls=$k"; fail=1; fi
done

if [ $fail -eq 0 ]; then
  say "DDC FRONTEND-CLOSED -- two implementation-independent emitters (precedence-climbing vs shunting-yard) emit BYTE-IDENTICAL canonical SVIR for all real programs, verifier-accepted, still x86(sovereign)+wasm == 99.  RESIDUAL: seed (gcc-iiis-0) + author-diversity NOT closed (see SVIR-DDC-RESIDUAL.md)."
fi
exit $fail
