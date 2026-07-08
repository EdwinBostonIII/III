#!/usr/bin/env bash
# run_retarget.sh -- THE Γ3 RETARGETING-CLOSURE GATE (DOCS/III-GERMINATION-MAP.md, rung Γ3).
# The TRANSLATOR ITSELF is a waist object: svir_elf_w.iii (iiisv subset) -> SVIR -> anchor-verified ->
# composed with each program's SVIR as its data segment -> RUN ON A HOST ROUTE -> emits the program's
# static ELF64.  LAWS gated here, per program:
#   T1 anchor      : the composed (translator+program) module passes the 97-line anchor
#   T2 byte-match  : waist-route emission == native svir_elf.exe emission   (THE byte-match law)
#   T3 semantics   : the waist-emitted ELF executes on Linux with the oracle rc (and fact's bytes)
#   T4 fixpoint    : translator(translator+program) == native(translator+program)  -- self-translation:
#                    the ELF-of-the-translator (the LINUX-NATIVE REGROWTH GERM) minted two independent
#                    ways must be byte-identical; running THAT germ on Linux re-emits the program's ELF
#                    byte-identically with NO Windows and NO PE toolchain in the loop.
#   T5 teeth       : a flipped byte in the composed module's data segment must change/redden the output
# Chain (win64 leg): .iii -> iiisv -> iiis-2 -> svir_dump -> svir_compose -> svir_x86 -> sovas -> sovld -> PE run.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"
BOOT="$ROOT/STDLIB/build/_sovboot"; W="$ROOT/STDLIB/build/sovir"; SP="$ROOT/STDLIB/build/spore/S0"
WSL="/c/Windows/System32/wsl.exe"; WSLDIST="${WSLDIST:-Debian}"; WSLW="/mnt/c${W#/c}"
fail=0; say(){ echo "[retgt] $*"; }
PROGS="sum loop call fact bignum cioob toolchain ops bignum2 isqrt"
want_rc(){ case "$1" in cioob) echo 199;; *) echo 99;; esac; }

# ---- build the waist translator (fresh) --------------------------------------
"$IIIS" "$S/iiisv.iii" --compile-only --out "$W/iiisv.o" >/dev/null 2>&1 || { say "FAIL compile iiisv"; exit 1; }
rm -f "$W/iiisv.exe"; gcc "$W/iiisv.o" -o "$W/iiisv.exe" 2>/dev/null
"$W/iiisv.exe" "$S/svir_elf_w.iii" > "$W/elfw_gen.iii" 2>/dev/null
[ -s "$W/elfw_gen.iii" ] || { say "FAIL iiisv(svir_elf_w)"; exit 1; }
"$IIIS" "$W/elfw_gen.iii" --compile-only --out "$W/elfw_gen.o" >/dev/null 2>&1 || { say "FAIL compile elfw_gen"; exit 1; }
for m in svir_dump svir_compose svir_verify verify_main svir_elf svir_x86; do
  [ -s "$W/$m.o" ] || "$IIIS" "$S/$m.iii" --compile-only --out "$W/$m.o" >/dev/null 2>&1 || { say "FAIL compile $m"; exit 1; }
done
[ -s "$W/svir_compose.exe" ] || gcc "$W/svir_compose.o" -o "$W/svir_compose.exe" 2>/dev/null
gcc "$W/svir_dump.o" "$W/elfw_gen.o" -o "$W/sd_elfw.exe" 2>/dev/null
"$W/sd_elfw.exe" > "$W/elfw.svbin"
gcc "$W/verify_main.o" "$W/svir_verify.o" "$W/elfw_gen.o" -o "$W/v_elfw.exe" 2>/dev/null
"$W/v_elfw.exe" >/dev/null 2>&1; vrc=$?
if [ $vrc -eq 99 ]; then say "translator    : svir_elf_w = $(stat -c%s "$W/elfw.svbin") B of SVIR, ANCHOR-ACCEPTED (rc=99)"
else say "FAIL anchor(translator) rc=$vrc"; fail=1; fi

# helper: run a composed module through the win64 waist route -> stdout bytes to $2
waist_emit(){ # $1=composed .o  $2=out  $3=tag
  gcc "$W/svir_x86.o" "$1" -o "$W/tx_$3.exe" 2>/dev/null || return 250
  "$W/tx_$3.exe" > "$W/tx_$3.s" 2>/dev/null
  "$BOOT/sovas_main.exe" "$W/tx_$3.s" > "$W/tx_$3.o2" 2>/dev/null || return 251
  "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/tx_$3.o2" > "$W/tx_$3.pe.exe" 2>/dev/null || return 252
  chmod +x "$W/tx_$3.pe.exe" 2>/dev/null
  "$W/tx_$3.pe.exe" > "$2" 2>/dev/null; return $?
}

for l in $PROGS; do
  [ -s "$SP/svir/$l.svir" ] || { say "FAIL missing $SP/svir/$l.svir (run run_germinate.sh --pack)"; fail=1; continue; }
  "$W/svir_compose.exe" "$W/elfw.svbin" "$SP/svir/$l.svir" > "$W/comp_$l.iii" 2>/dev/null
  "$IIIS" "$W/comp_$l.iii" --compile-only --out "$W/comp_$l.o" >/dev/null 2>&1 || { say "FAIL compile comp_$l"; fail=1; continue; }
  gcc "$W/verify_main.o" "$W/svir_verify.o" "$W/comp_$l.o" -o "$W/v_comp_$l.exe" 2>/dev/null
  "$W/v_comp_$l.exe" >/dev/null 2>&1; arc=$?
  waist_emit "$W/comp_$l.o" "$W/rg_$l.elf" "c$l"; wrc=$?
  "$W/mx_te_$l.exe" > "$W/native_$l.elf" 2>/dev/null
  verdict="ok"
  [ $arc -eq 99 ] || verdict="RED(anchor=$arc)"
  [ $wrc -eq 99 ] || verdict="RED(run=$wrc)"
  cmp -s "$W/rg_$l.elf" "$W/native_$l.elf" || verdict="RED(byte-match)"
  [ "$verdict" = "ok" ] || fail=1
  say "$(printf '%-10s anchor=%-3s run=%-3s byte-match=%s' "$l" "$arc" "$wrc" "$verdict")"
done

# ---- T3: waist-emitted ELFs execute on Linux with oracle rc -------------------
for l in sum fact cioob isqrt; do
  MSYS_NO_PATHCONV=1 timeout 60 "$WSL" -d "$WSLDIST" -u root -e "$WSLW/rg_$l.elf" > "$W/rg_$l.out" 2>/dev/null; xrc=$?
  wr=$(want_rc $l)
  if [ $xrc -eq "$wr" ]; then say "T3 exec $l    : rc=$xrc (oracle)"; else say "FAIL T3 $l rc=$xrc want=$wr"; fail=1; fi
done
node -e 'let f=1n;for(let i=1n;i<=20n;i++)f*=i;process.stdout.write(f.toString()+"\n")' > "$W/gold20.out" 2>/dev/null
cmp -s "$W/rg_fact.out" "$W/gold20.out" && say "T3 fact bytes : == golden 20!" || { say "FAIL T3 fact bytes"; fail=1; }

# ---- T4: SELF-TRANSLATION FIXPOINT + the Linux-native regrowth germ ------------
# native path : svir_elf.exe(comp_sum)          -> germ_native.elf
# waist path  : translator(translator+comp_sum) -> germ_waist.elf   (the translator translating ITSELF)
gcc "$W/svir_dump.o" "$W/comp_sum.o" -o "$W/sd_comp_sum.exe" 2>/dev/null
"$W/sd_comp_sum.exe" > "$W/comp_sum.svbin"
gcc "$W/svir_elf.o" "$W/comp_sum.o" -o "$W/te_comp_sum.exe" 2>/dev/null
"$W/te_comp_sum.exe" > "$W/germ_native.elf" 2>/dev/null
"$W/svir_compose.exe" "$W/elfw.svbin" "$W/comp_sum.svbin" > "$W/comp2_sum.iii" 2>/dev/null
"$IIIS" "$W/comp2_sum.iii" --compile-only --out "$W/comp2_sum.o" >/dev/null 2>&1
waist_emit "$W/comp2_sum.o" "$W/germ_waist.elf" "self"; src=$?
if cmp -s "$W/germ_native.elf" "$W/germ_waist.elf"; then say "T4 FIXPOINT   : translator(translator+sum) == native(translator+sum)  [$(stat -c%s "$W/germ_waist.elf") B, run=$src]"
else say "FAIL T4 fixpoint: self-translation differs from native"; fail=1; fi
MSYS_NO_PATHCONV=1 timeout 60 "$WSL" -d "$WSLDIST" -u root -e "$WSLW/germ_waist.elf" > "$W/germ_regrown_sum.elf" 2>/dev/null; grc=$?
if [ $grc -eq 99 ] && cmp -s "$W/germ_regrown_sum.elf" "$W/native_sum.elf"; then
  say "T4 LINUX GERM : the self-translated germ RAN ON LINUX and re-emitted sum's ELF byte-identically (no Windows, no PE toolchain in the loop)"
else say "FAIL T4 linux-germ rc=$grc"; fail=1; fi

# ---- A64: the AArch64 toolchain as a waist object (Γ3 × Γ2c, cross-ISA) --------
"$W/iiisv.exe" "$S/svir_arm64_w.iii" > "$W/a64w_gen.iii" 2>/dev/null
"$IIIS" "$W/a64w_gen.iii" --compile-only --out "$W/a64w_gen.o" >/dev/null 2>&1 || { say "FAIL compile a64w_gen"; fail=1; }
gcc "$W/svir_dump.o" "$W/a64w_gen.o" -o "$W/sd_a64w.exe" 2>/dev/null
"$W/sd_a64w.exe" > "$W/a64w.svbin"
gcc "$W/verify_main.o" "$W/svir_verify.o" "$W/a64w_gen.o" -o "$W/v_a64w.exe" 2>/dev/null
"$W/v_a64w.exe" >/dev/null 2>&1; a64v=$?
if [ $a64v -eq 99 ]; then say "a64 translator: svir_arm64_w = $(stat -c%s "$W/a64w.svbin") B of SVIR, ANCHOR-ACCEPTED"
else say "FAIL anchor(a64w) rc=$a64v"; fail=1; fi
for l in $PROGS; do
  "$W/svir_compose.exe" "$W/a64w.svbin" "$SP/svir/$l.svir" > "$W/compa_$l.iii" 2>/dev/null
  "$IIIS" "$W/compa_$l.iii" --compile-only --out "$W/compa_$l.o" >/dev/null 2>&1 || { say "FAIL compile compa_$l"; fail=1; continue; }
  gcc "$W/verify_main.o" "$W/svir_verify.o" "$W/compa_$l.o" -o "$W/v_compa_$l.exe" 2>/dev/null
  "$W/v_compa_$l.exe" >/dev/null 2>&1; aarc=$?
  waist_emit "$W/compa_$l.o" "$W/rga_$l.a64.elf" "a$l"; awrc=$?
  "$W/mx_ta_$l.exe" > "$W/native_$l.a64.elf" 2>/dev/null
  averdict="ok"
  [ $aarc -eq 99 ] || averdict="RED(anchor=$aarc)"
  [ $awrc -eq 99 ] || averdict="RED(run=$awrc)"
  cmp -s "$W/rga_$l.a64.elf" "$W/native_$l.a64.elf" || averdict="RED(byte-match)"
  [ "$averdict" = "ok" ] || fail=1
  say "$(printf 'a64:%-8s anchor=%-3s run=%-3s byte-match=%s' "$l" "$aarc" "$awrc" "$averdict")"
done
QEMU72='export LD_LIBRARY_PATH=/opt/q72/usr/lib/x86_64-linux-gnu; /opt/q72/usr/bin/qemu-aarch64'
for l in isqrt cioob; do
  MSYS_NO_PATHCONV=1 timeout 60 "$WSL" -d "$WSLDIST" -u root -e sh -c "$QEMU72 '$WSLW/rga_$l.a64.elf'" >/dev/null 2>&1; qrc=$?
  wr=$(want_rc $l)
  if [ $qrc -eq "$wr" ]; then say "A64 exec $l : rc=$qrc (oracle, qemu)"; else say "FAIL A64 exec $l rc=$qrc want=$wr"; fail=1; fi
done
# ---- A6: THE CROSS-ISA GERM -- an x86-64 Linux ELF that regrows AArch64 binaries
gcc "$W/svir_dump.o" "$W/compa_sum.o" -o "$W/sd_compa_sum.exe" 2>/dev/null
"$W/sd_compa_sum.exe" > "$W/compa_sum.svbin"
gcc "$W/svir_elf.o" "$W/compa_sum.o" -o "$W/te_compa_sum.exe" 2>/dev/null
"$W/te_compa_sum.exe" > "$W/xgerm_native.elf" 2>/dev/null
"$W/svir_compose.exe" "$W/elfw.svbin" "$W/compa_sum.svbin" > "$W/comp2a_sum.iii" 2>/dev/null
"$IIIS" "$W/comp2a_sum.iii" --compile-only --out "$W/comp2a_sum.o" >/dev/null 2>&1
waist_emit "$W/comp2a_sum.o" "$W/xgerm_waist.elf" "xself"; xsrc=$?
if cmp -s "$W/xgerm_native.elf" "$W/xgerm_waist.elf"; then say "A6 X-FIXPOINT : elf_w(elf-of-(a64w+sum)) == native  [$(stat -c%s "$W/xgerm_waist.elf") B]"
else say "FAIL A6 x-fixpoint"; fail=1; fi
MSYS_NO_PATHCONV=1 timeout 60 "$WSL" -d "$WSLDIST" -u root -e "$WSLW/xgerm_waist.elf" > "$W/xregrown_sum.a64.elf" 2>/dev/null; xgrc=$?
cmp -s "$W/xregrown_sum.a64.elf" "$W/native_sum.a64.elf" && xdd=ok || xdd=RED
MSYS_NO_PATHCONV=1 timeout 60 "$WSL" -d "$WSLDIST" -u root -e sh -c "$QEMU72 '$WSLW/xregrown_sum.a64.elf'" >/dev/null 2>&1; xrun=$?
if [ $xgrc -eq 99 ] && [ "$xdd" = "ok" ] && [ $xrun -eq 99 ]; then
  say "A6 CROSS GERM : x86-64 Linux germ REGREW sum's AArch64 ELF byte-identically ON LINUX; the regrown binary runs at oracle under qemu (rc=99).  Toolchain-for-ISA-B carried as SVIR, regrown on ISA-A."
else say "FAIL A6 cross-germ (emit=$xgrc ddc=$xdd run=$xrun)"; fail=1; fi

# ---- RV: the RISC-V toolchain as a waist object (Γ3 × Γ2d, THIRD ISA) ----------
"$W/iiisv.exe" "$S/svir_riscv_w.iii" > "$W/rv_w_gen.iii" 2>/dev/null
"$IIIS" "$W/rv_w_gen.iii" --compile-only --out "$W/rv_w_gen.o" >/dev/null 2>&1 || { say "FAIL compile rv_w_gen"; fail=1; }
gcc "$W/svir_dump.o" "$W/rv_w_gen.o" -o "$W/sd_rvw.exe" 2>/dev/null
"$W/sd_rvw.exe" > "$W/rvw.svbin"
gcc "$W/verify_main.o" "$W/svir_verify.o" "$W/rv_w_gen.o" -o "$W/v_rvw.exe" 2>/dev/null
"$W/v_rvw.exe" >/dev/null 2>&1; rvv=$?
if [ $rvv -eq 99 ]; then say "rv translator : svir_riscv_w = $(stat -c%s "$W/rvw.svbin") B of SVIR, ANCHOR-ACCEPTED"
else say "FAIL anchor(rvw) rc=$rvv"; fail=1; fi
for l in $PROGS; do
  "$W/svir_compose.exe" "$W/rvw.svbin" "$SP/svir/$l.svir" > "$W/compr_$l.iii" 2>/dev/null
  "$IIIS" "$W/compr_$l.iii" --compile-only --out "$W/compr_$l.o" >/dev/null 2>&1 || { say "FAIL compile compr_$l"; fail=1; continue; }
  gcc "$W/verify_main.o" "$W/svir_verify.o" "$W/compr_$l.o" -o "$W/v_compr_$l.exe" 2>/dev/null
  "$W/v_compr_$l.exe" >/dev/null 2>&1; rrarc=$?
  waist_emit "$W/compr_$l.o" "$W/rgr_$l.rv.elf" "r$l"; rrwrc=$?
  "$W/mx_tr_$l.exe" > "$W/native_$l.rv.elf" 2>/dev/null
  rverdict="ok"
  [ $rrarc -eq 99 ] || rverdict="RED(anchor=$rrarc)"
  [ $rrwrc -eq 99 ] || rverdict="RED(run=$rrwrc)"
  cmp -s "$W/rgr_$l.rv.elf" "$W/native_$l.rv.elf" || rverdict="RED(byte-match)"
  [ "$rverdict" = "ok" ] || fail=1
  say "$(printf 'rv:%-9s anchor=%-3s run=%-3s byte-match=%s' "$l" "$rrarc" "$rrwrc" "$rverdict")"
done
QEMU72R='export LD_LIBRARY_PATH=/opt/q72/usr/lib/x86_64-linux-gnu; /opt/q72/usr/bin/qemu-riscv64'
for l in isqrt cioob; do
  MSYS_NO_PATHCONV=1 timeout 60 "$WSL" -d "$WSLDIST" -u root -e sh -c "$QEMU72R '$WSLW/rgr_$l.rv.elf'" >/dev/null 2>&1; qrc=$?
  wr=$(want_rc $l)
  if [ $qrc -eq "$wr" ]; then say "RV exec $l  : rc=$qrc (oracle, qemu-riscv64)"; else say "FAIL RV exec $l rc=$qrc want=$wr"; fail=1; fi
done
# cross-ISA germ #2: an x86-64 Linux ELF that regrows RISC-V binaries on Linux
gcc "$W/svir_dump.o" "$W/compr_sum.o" -o "$W/sd_compr_sum.exe" 2>/dev/null
"$W/sd_compr_sum.exe" > "$W/compr_sum.svbin"
gcc "$W/svir_elf.o" "$W/compr_sum.o" -o "$W/te_compr_sum.exe" 2>/dev/null
"$W/te_compr_sum.exe" > "$W/rgerm_native.elf" 2>/dev/null
"$W/svir_compose.exe" "$W/elfw.svbin" "$W/compr_sum.svbin" > "$W/comp2r_sum.iii" 2>/dev/null
"$IIIS" "$W/comp2r_sum.iii" --compile-only --out "$W/comp2r_sum.o" >/dev/null 2>&1
waist_emit "$W/comp2r_sum.o" "$W/rgerm_waist.elf" "rself"; rgsrc=$?
if cmp -s "$W/rgerm_native.elf" "$W/rgerm_waist.elf"; then say "RV6 X-FIXPOINT: elf_w(elf-of-(rvw+sum)) == native  [$(stat -c%s "$W/rgerm_waist.elf") B]"
else say "FAIL RV6 x-fixpoint"; fail=1; fi
MSYS_NO_PATHCONV=1 timeout 60 "$WSL" -d "$WSLDIST" -u root -e "$WSLW/rgerm_waist.elf" > "$W/rxregrown_sum.rv.elf" 2>/dev/null; rxgrc=$?
cmp -s "$W/rxregrown_sum.rv.elf" "$W/native_sum.rv.elf" && rxdd=ok || rxdd=RED
MSYS_NO_PATHCONV=1 timeout 60 "$WSL" -d "$WSLDIST" -u root -e sh -c "$QEMU72R '$WSLW/rxregrown_sum.rv.elf'" >/dev/null 2>&1; rxrun=$?
if [ $rxgrc -eq 99 ] && [ "$rxdd" = "ok" ] && [ $rxrun -eq 99 ]; then
  say "RV6 CROSS GERM: x86-64 Linux germ REGREW sum's RISC-V ELF byte-identically ON LINUX; regrown binary runs at oracle under qemu-riscv64 (rc=99).  A THIRD ISA's toolchain carried as SVIR, regrown on x86-64."
else say "FAIL RV6 cross-germ (emit=$rxgrc ddc=$rxdd run=$rxrun)"; fail=1; fi

# ---- W: Γ2b leg -- the SAME translator modules on the WASM route (third independent host) ----
# One translator SVIR, three executing substrates (PE-native, wasm-under-node, and via T4 Linux-native):
# stdout bytes must be IDENTICAL everywhere.  node's harness writes putc bytes raw to fd 1.
wfail=0
for l in sum fact isqrt; do
  gcc "$W/svir_wasm.o" "$W/comp_$l.o" -o "$W/tw_c$l.exe" 2>/dev/null || { wfail=1; continue; }
  "$W/tw_c$l.exe" > "$W/comp_$l.wasm" 2>/dev/null
  timeout 30 node "$S/run_wasm.mjs" "$W/comp_$l.wasm" > "$W/rgw_$l.elf" 2>/dev/null
  cmp -s "$W/rgw_$l.elf" "$W/native_$l.elf" || { say "FAIL W byte-match(x86) $l"; wfail=1; }
  gcc "$W/svir_wasm.o" "$W/compa_$l.o" -o "$W/tw_ca$l.exe" 2>/dev/null || { wfail=1; continue; }
  "$W/tw_ca$l.exe" > "$W/compa_$l.wasm" 2>/dev/null
  timeout 30 node "$S/run_wasm.mjs" "$W/compa_$l.wasm" > "$W/rgw_$l.a64.elf" 2>/dev/null
  cmp -s "$W/rgw_$l.a64.elf" "$W/native_$l.a64.elf" || { say "FAIL W byte-match(a64) $l"; wfail=1; }
  gcc "$W/svir_wasm.o" "$W/compr_$l.o" -o "$W/tw_cr$l.exe" 2>/dev/null || { wfail=1; continue; }
  "$W/tw_cr$l.exe" > "$W/compr_$l.wasm" 2>/dev/null
  timeout 30 node "$S/run_wasm.mjs" "$W/compr_$l.wasm" > "$W/rgw_$l.rv.elf" 2>/dev/null
  cmp -s "$W/rgw_$l.rv.elf" "$W/native_$l.rv.elf" || { say "FAIL W byte-match(rv) $l"; wfail=1; }
done
if [ $wfail -eq 0 ]; then say "W WASM ROUTE  : all THREE translator ISAs emitted IDENTICAL bytes under node (x86+a64+rv targets, 3 programs) -- one waist object, three independent executing substrates"
else fail=1; fi

# ---- T5: teeth -- flip one data byte in a composed module ----------------------
"$W/svir_compose.exe" "$W/elfw.svbin" "$SP/svir/sum.svir" > "$W/comp_p.iii" 2>/dev/null
# flip one program byte inside the .iii wrapper is brittle; flip the .svir input instead and recompose
cp "$SP/svir/sum.svir" "$W/sum_p.svir"
printf '\x07' | dd of="$W/sum_p.svir" bs=1 seek=9 count=1 conv=notrunc 2>/dev/null
"$W/svir_compose.exe" "$W/elfw.svbin" "$W/sum_p.svir" > "$W/comp_p.iii" 2>/dev/null
"$IIIS" "$W/comp_p.iii" --compile-only --out "$W/comp_p.o" >/dev/null 2>&1
waist_emit "$W/comp_p.o" "$W/rg_p.elf" "pert"; prc=$?
if cmp -s "$W/rg_p.elf" "$W/rg_sum.elf"; then say "FAIL T5: perturbed input produced identical output (no teeth)"; fail=1
else say "T5 TEETH      : one flipped input byte -> different/red emission (rc=$prc)"; fi

if [ $fail -eq 0 ]; then
  say "RETARGETING CLOSURE GREEN -- ALL THREE translators (SVIR->ELF64 for x86-64, AArch64, AND RV64IM) are anchor-verified waist objects: 30/30 composed modules anchor-accepted with waist emission BYTE-IDENTICAL to the native emitters; emitted binaries run at oracle on Linux + both qemu ISAs; all three ISAs emit identical bytes on the wasm route too; the elf translator SELF-TRANSLATES to a byte-exact fixpoint; and TWO cross-ISA germs (x86-64 Linux ELFs) regrow AArch64 AND RISC-V binaries byte-identically ON LINUX -- zero Windows, zero PE toolchain, zero foreign toolchain.  Γ3: a host's entire retargeting capability (any of 3 ISAs) travels as ~12-13 KB of anchor-verified SVIR."
fi
exit $fail
