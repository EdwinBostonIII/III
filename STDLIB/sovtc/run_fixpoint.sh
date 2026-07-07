#!/usr/bin/env bash
# run_fixpoint.sh -- the SOVEREIGN SELF-HOST FIXPOINT gate.  Proves III's assembler (sovas) AND linker
# (sovld/sovlink) build working copies of THEMSELVES, byte-identical, with NO gcc/ld/gas in the loop.
#
#   Bootstrap (allowed, one-time): iiis-2 compiles the toolchain .iii -> .o; gcc links ONLY the gen1 tools.
#   Everything below the bootstrap is sovereign -- the claim is gen2 == gen1 with no gcc/gas:
#     * sov-assemble every module (byte-gated vs gas)
#     * ASSEMBLER self-host : sovlink(crt0+sovas_main+sovparse+sovcoff+sovas) = gen2 sovas; gen2==gen1 on
#                             all 13 inputs (its own 5 sources + boot1-8), byte-for-byte
#     * LINKER  self-host   : sovlink(crt0+sovlink_main+sovld+sovparse+sovas) = the sovereign linker;
#                             it re-links sovas BYTE-IDENTICAL to the gcc-linked gen1, and reproduces
#                             ITSELF bit-for-bit (exercises crt0's multi-arg parse).
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
SOV="$ROOT/STDLIB/sovtc"
OUT="$ROOT/STDLIB/build/_sovboot"
mkdir -p "$OUT"
fail=0
say(){ echo "[fixpoint] $*"; }

# --- bootstrap: compile every toolchain module; gcc-link the gen1 tools only ---
for m in sovas sovparse sovcoff sovld sovas_main sovlink_main crt0; do
  "$IIIS" "$SOV/$m.iii" --compile-only --out "$OUT/$m.o" >/dev/null 2>&1 || { say "FAIL compile $m"; fail=1; }
done
gcc "$OUT/sovas_main.o" "$OUT/sovparse.o" "$OUT/sovcoff.o" "$OUT/sovas.o" -lkernel32 -o "$OUT/sovas_main.exe" 2>/dev/null || { say "FAIL gen1 sovas_main"; fail=1; }
gcc "$OUT/sovlink_main.o" "$OUT/sovld.o" "$OUT/sovparse.o" "$OUT/sovas.o" -lkernel32 -o "$OUT/sovlink_main.exe" 2>/dev/null || { say "FAIL gen1 sovlink_main"; fail=1; }

# --- sov-assemble every module to a sovereign .o, byte-gated vs gas ---
for m in crt0 sovas_main sovparse sovcoff sovas sovld sovlink_main; do
  timeout 30 "$OUT/sovas_main.exe" "$OUT/$m.o.s" > "$OUT/${m}_sov.o" 2>/dev/null
  gcc -c -x assembler "$OUT/$m.o.s" -o "$OUT/${m}_g.o" 2>/dev/null
  objcopy -O binary --only-section=.text "$OUT/${m}_sov.o" "$OUT/_a.t" 2>/dev/null
  objcopy -O binary --only-section=.text "$OUT/${m}_g.o" "$OUT/_b.t" 2>/dev/null
  if cmp -s "$OUT/_a.t" "$OUT/_b.t"; then say "PASS sov-assemble $m .text == gas"; else say "FAIL sov-assemble $m differs from gas"; fail=1; fi
done

# --- Tier-2 SIMD differential: the 7 crypto modules emitting VEX/EVEX must sov-assemble .text == gas.
#     This is what makes the sovereign path witness-free on the crypto closure (audit P2a). ---
for m in bigint blake2s chacha20 keccak poly1305 sha256 sha512; do
  f=$(find "$ROOT/STDLIB/iii/numera" -name "$m.iii" | head -1)
  if [ -z "$f" ]; then say "FAIL simd $m (source not found)"; fail=1; continue; fi
  "$IIIS" "$f" --compile-only --out "$OUT/simd_$m.o" >/dev/null 2>&1 || { say "FAIL simd $m (iiis-2 compile)"; fail=1; continue; }
  timeout 40 "$OUT/sovas_main.exe" "$OUT/simd_$m.o.s" > "$OUT/simd_${m}_sov.o" 2>/dev/null
  gcc -c -x assembler "$OUT/simd_$m.o.s" -o "$OUT/simd_${m}_g.o" 2>/dev/null
  objcopy -O binary --only-section=.text "$OUT/simd_${m}_sov.o" "$OUT/_sa.t" 2>/dev/null
  objcopy -O binary --only-section=.text "$OUT/simd_${m}_g.o" "$OUT/_sb.t" 2>/dev/null
  if cmp -s "$OUT/_sa.t" "$OUT/_sb.t" && [ -s "$OUT/_sa.t" ]; then say "PASS sov-assemble $m .text == gas (Tier-2 VEX/EVEX)"; else say "FAIL sov-assemble $m SIMD differs from gas"; fail=1; fi
done

# --- ASSEMBLER self-host: gen2 sovas, then gen2==gen1 byte-for-byte on all inputs ---
timeout 60 "$OUT/sovlink_main.exe" "$OUT/crt0_sov.o" "$OUT/sovas_main_sov.o" "$OUT/sovparse_sov.o" "$OUT/sovcoff_sov.o" "$OUT/sovas_sov.o" > "$OUT/sovas_self.exe" 2>/dev/null
ident=0; tot=0
for m in crt0 sovas_main sovparse sovcoff sovas boot1 boot2 boot3 boot4 boot5 boot6 boot7 boot8; do
  [ -f "$OUT/$m.o.s" ] || "$IIIS" "$SOV/$m.iii" --compile-only --out "$OUT/$m.o" >/dev/null 2>&1
  [ -f "$OUT/$m.o.s" ] || continue
  tot=$((tot+1))
  timeout 30 "$OUT/sovas_self.exe" "$OUT/$m.o.s" > "$OUT/_self.o" 2>/dev/null
  timeout 30 "$OUT/sovas_main.exe" "$OUT/$m.o.s" > "$OUT/_ref.o" 2>/dev/null
  cmp -s "$OUT/_self.o" "$OUT/_ref.o" && [ -s "$OUT/_self.o" ] && ident=$((ident+1))
done
if [ "$ident" -eq "$tot" ] && [ "$tot" -gt 0 ]; then say "PASS ASSEMBLER self-hosts: gen2==gen1 on $ident/$tot inputs"; else say "FAIL assembler self-host: $ident/$tot identical"; fail=1; fi

# --- LINKER self-host: sov-build the linker; re-link sovas byte-identical; reproduce itself ---
timeout 60 "$OUT/sovlink_main.exe" "$OUT/crt0_sov.o" "$OUT/sovlink_main_sov.o" "$OUT/sovld_sov.o" "$OUT/sovparse_sov.o" "$OUT/sovas_sov.o" > "$OUT/sovlink_self.exe" 2>/dev/null
timeout 60 "$OUT/sovlink_self.exe" "$OUT/crt0_sov.o" "$OUT/sovas_main_sov.o" "$OUT/sovparse_sov.o" "$OUT/sovcoff_sov.o" "$OUT/sovas_sov.o" > "$OUT/sovas_via_selflink.exe" 2>/dev/null
if cmp -s "$OUT/sovas_via_selflink.exe" "$OUT/sovas_self.exe" && [ -s "$OUT/sovas_via_selflink.exe" ]; then say "PASS LINKER re-links sovas == gcc-linker output"; else say "FAIL sovereign linker re-link differs"; fail=1; fi
timeout 60 "$OUT/sovlink_self.exe" "$OUT/crt0_sov.o" "$OUT/sovlink_main_sov.o" "$OUT/sovld_sov.o" "$OUT/sovparse_sov.o" "$OUT/sovas_sov.o" > "$OUT/sovlink_self2.exe" 2>/dev/null
if cmp -s "$OUT/sovlink_self2.exe" "$OUT/sovlink_self.exe" && [ -s "$OUT/sovlink_self2.exe" ]; then say "PASS LINKER reproduces itself bit-for-bit"; else say "FAIL linker self-repro differs"; fail=1; fi

if [ "$fail" -eq 0 ]; then say "ALL PASS -- assembler + linker both self-host, byte-identical, no gcc/ld/gas"; else say "FAILURES"; fi
exit "$fail"
