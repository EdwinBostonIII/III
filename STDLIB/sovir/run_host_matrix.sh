#!/usr/bin/env bash
# run_host_matrix.sh -- THE Γ2a HOST-CLOSURE GATE (DOCS/III-GERMINATION-MAP.md, rung Γ2a).
# One SVIR program set, EVERY host route, same observable behavior:
#   verify : svir_verify accepts each module                              (the 97-line anchor)
#   interp : svir_interp reference semantics                              (host: this win64 process)
#   win64  : svir_x86 -> sovas -> sovld -> PE, kernel32-only              (native host #1)
#   wasm   : svir_wasm -> node                                            (host #2, browser-class)
#   sysv   : svir_elf -> ONE-STAGE static ELF64, ZERO libc/imports        (native host #3: Linux, NEW)
# Programs: 5 hand-authored SVIR modules + 4 iiisv-compiled .iii programs (incl. the isqrt organ) +
# the OOB CALL_INDIRECT trap vehicle (negative tooth: every executor must TRAP=199, not complete=99).
# fact's stdout (20!) must be BYTE-IDENTICAL across interp, win64, sysv, and an independent node golden.
# FALSIFIERS wired in: (a) one perturbed ELF text byte -> the run must NOT return 99;
# (b) the Γ2 LAW: this rung adds ZERO lines to the anchor -- svir_verify.iii must be git-clean;
# (c) HOSTS.pin is DOWN-ONLY: every pinned host must run green here; a host that stops executing reddens.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; IND="$ROOT/STDLIB/independence"
BOOT="$ROOT/STDLIB/build/_sovboot"; W="$ROOT/STDLIB/build/sovir"; mkdir -p "$W"
WSL="/c/Windows/System32/wsl.exe"; WSLDIST="${WSLDIST:-Debian}"
WSLW="/mnt/c${W#/c}"
fail=0; say(){ echo "[hostmx] $*"; }

# ---- (b) THE Γ2 LAW: zero anchor growth ------------------------------------
if ! git -C "$ROOT" diff --quiet -- STDLIB/sovir/svir_verify.iii; then
  say "FAIL LAW: svir_verify.iii modified -- host closure must add ZERO anchor lines"; fail=1
else
  say "LAW anchor-zero-diff : svir_verify.iii untouched (hosts live BELOW the waist)"
fi

# ---- tools ------------------------------------------------------------------
for m in svir_x86 svir_wasm svir_elf svir_interp svir_verify verify_main iiisv; do
  [ -s "$W/$m.o" ] || "$IIIS" "$S/$m.iii" --compile-only --out "$W/$m.o" >/dev/null 2>&1 || { say "FAIL compile $m"; fail=1; }
done
[ -s "$W/iiisv.exe" ] || gcc "$W/iiisv.o" -o "$W/iiisv.exe" 2>/dev/null
[ -s "$BOOT/sovas_main.exe" ] && [ -s "$BOOT/sovlink_main.exe" ] && [ -s "$BOOT/crt0_sov.o" ] || bash "$S/run_svir.sh" >/dev/null 2>&1

# ---- host availability (down-only vs HOSTS.pin) ------------------------------
sysv_ok=1
MSYS_NO_PATHCONV=1 "$WSL" -d "$WSLDIST" -u root -e /bin/true >/dev/null 2>&1 || sysv_ok=0
node -e "process.exit(0)" >/dev/null 2>&1; wasm_ok=$((1-$?))
PIN="$S/HOSTS.pin"
if [ ! -f "$PIN" ]; then printf "win64\nsysv-elf\nwasm\ninterp\n" > "$PIN"; say "HOSTS.pin created: win64 sysv-elf wasm interp"; fi
while read -r h; do
  case "$h" in
    sysv-elf) [ $sysv_ok -eq 1 ] || { say "FAIL RATCHET: pinned host sysv-elf not executable here"; fail=1; } ;;
    wasm)     [ $wasm_ok -eq 1 ] || { say "FAIL RATCHET: pinned host wasm (node) not executable here"; fail=1; } ;;
  esac
done < "$PIN"

# ---- providers ---------------------------------------------------------------
# hand-authored SVIR modules (label:module)
HAND="sum:svir_prog loop:svir_loop call:svir_call fact:svir_fact bignum:svir_bignum cioob:_svir_ci_oob"
# iiisv-compiled .iii programs (label:source)
GEN="toolchain:indep_toolchain ops:indep_ops bignum2:indep_bignum isqrt:indep_isqrt"
for pair in $HAND; do
  m="${pair#*:}"
  [ -s "$W/$m.o" ] || "$IIIS" "$S/$m.iii" --compile-only --out "$W/$m.o" >/dev/null 2>&1 || { say "FAIL compile $m"; fail=1; }
done
for pair in $GEN; do
  lbl="${pair%%:*}"; src="${pair#*:}"
  "$W/iiisv.exe" "$IND/$src.iii" > "$W/${lbl}_gen.iii" 2>/dev/null
  [ -s "$W/${lbl}_gen.iii" ] || { say "FAIL iiisv emit $lbl"; fail=1; continue; }
  "$IIIS" "$W/${lbl}_gen.iii" --compile-only --out "$W/${lbl}_gen.o" >/dev/null 2>&1 || { say "FAIL compile ${lbl}_gen"; fail=1; }
done

# ---- route runners (rc measured DIRECTLY, no pipes) ---------------------------
r_verify(){ local o="$1" l="$2"; rm -f "$W/mx_v_$l.exe"; gcc "$W/verify_main.o" "$W/svir_verify.o" "$o" -o "$W/mx_v_$l.exe" 2>/dev/null || return 250
  timeout 20 "$W/mx_v_$l.exe" >/dev/null 2>&1; return $?; }
r_interp(){ local o="$1" l="$2"; rm -f "$W/mx_i_$l.exe"; gcc "$W/svir_interp.o" "$o" -o "$W/mx_i_$l.exe" 2>/dev/null || return 250
  timeout 20 "$W/mx_i_$l.exe" > "$W/mx_$l.interp.out" 2>/dev/null; return $?; }
r_win64(){ local o="$1" l="$2"; rm -f "$W/mx_tx_$l.exe"; gcc "$W/svir_x86.o" "$o" -o "$W/mx_tx_$l.exe" 2>/dev/null || return 250
  "$W/mx_tx_$l.exe" > "$W/mx_$l.s" 2>/dev/null
  timeout 25 "$BOOT/sovas_main.exe" "$W/mx_$l.s" > "$W/mx_$l.o2" 2>/dev/null || return 251
  timeout 25 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/mx_$l.o2" > "$W/mx_$l.x86.exe" 2>/dev/null || return 252
  timeout 10 "$W/mx_$l.x86.exe" > "$W/mx_$l.win64.out" 2>/dev/null; return $?; }
r_wasm(){ local o="$1" l="$2"; rm -f "$W/mx_tw_$l.exe"; gcc "$W/svir_wasm.o" "$o" -o "$W/mx_tw_$l.exe" 2>/dev/null || return 250
  "$W/mx_tw_$l.exe" > "$W/mx_$l.wasm" 2>/dev/null
  timeout 20 node "$S/run_wasm.mjs" "$W/mx_$l.wasm" >/dev/null 2>&1; return $?; }
r_sysv(){ local o="$1" l="$2"; rm -f "$W/mx_te_$l.exe"; gcc "$W/svir_elf.o" "$o" -o "$W/mx_te_$l.exe" 2>/dev/null || return 250
  "$W/mx_te_$l.exe" > "$W/mx_$l.elf" 2>/dev/null
  MSYS_NO_PATHCONV=1 timeout 60 "$WSL" -d "$WSLDIST" -u root -e "$WSLW/mx_$l.elf" > "$W/mx_$l.sysv.out" 2>/dev/null; return $?; }

# ---- the matrix ---------------------------------------------------------------
run_row(){ # $1=label $2=object $3=expected-rc
  local l="$1" o="$2" want="$3"
  r_verify "$o" "$l"; local v=$?
  r_interp "$o" "$l"; local ir=$?
  r_win64  "$o" "$l"; local xr=$?
  r_wasm   "$o" "$l"; local wr=$?
  r_sysv   "$o" "$l"; local sr=$?
  local verdict="ok"
  [ $v -eq 99 ] || verdict="RED(verify=$v)"
  if [ "$l" = "cioob" ]; then
    # negative tooth: every real executor must TRAP (199), never complete (99); wasm traps natively (!=99, !=0)
    [ $ir -eq 199 ] || verdict="RED(interp=$ir)"
    [ $xr -eq 199 ] || verdict="RED(win64=$xr)"
    [ $sr -eq 199 ] || verdict="RED(sysv=$sr)"
    if [ $wr -eq 99 ] || [ $wr -eq 0 ]; then verdict="RED(wasm=$wr)"; fi
  else
    [ $ir -eq "$want" ] || verdict="RED(interp=$ir)"
    [ $xr -eq "$want" ] || verdict="RED(win64=$xr)"
    [ $wr -eq "$want" ] || verdict="RED(wasm=$wr)"
    [ $sr -eq "$want" ] || verdict="RED(sysv=$sr)"
  fi
  [ "$verdict" = "ok" ] || fail=1
  say "$(printf '%-10s verify=%-3s interp=%-3s win64=%-3s wasm=%-3s sysv=%-3s  %s' "$l" "$v" "$ir" "$xr" "$wr" "$sr" "$verdict")"
}

for pair in $HAND; do lbl="${pair%%:*}"; m="${pair#*:}"; run_row "$lbl" "$W/$m.o" 99; done
for pair in $GEN;  do lbl="${pair%%:*}";                run_row "$lbl" "$W/${lbl}_gen.o" 99; done

# ---- fact stdout: cross-host BYTE differential vs independent golden -----------
# The two SHIPPED host binaries emit RAW bytes (win64=kernel32 WriteFile, sysv=write(2) syscall) and must be
# STRICTLY byte-identical to the golden.  The interp is the gcc-compiled REFERENCE tool whose msvcrt putchar
# runs in Windows console TEXT mode (LF->CRLF); it is not a shipped host, so its row is compared CR-normalized
# (the digit stream must still match exactly -- only the line terminator representation is text-mode).
node -e 'let f=1n;for(let i=1n;i<=20n;i++)f*=i;process.stdout.write(f.toString()+"\n")' > "$W/mx_fact.gold.out" 2>/dev/null
for pairing in "win64:$W/mx_fact.win64.out" "sysv:$W/mx_fact.sysv.out"; do
  nm="${pairing%%:*}"; f="${pairing#*:}"
  if cmp -s "$W/mx_fact.gold.out" "$f"; then say "fact stdout $nm == golden 20! (byte-identical, raw host bytes)"
  else say "FAIL fact stdout $nm != golden"; fail=1; fi
done
tr -d '\r' < "$W/mx_fact.interp.out" > "$W/mx_fact.interp.norm" 2>/dev/null
if cmp -s "$W/mx_fact.gold.out" "$W/mx_fact.interp.norm"; then say "fact stdout interp == golden 20! (digit-identical; CRLF text-mode normalized)"
else say "FAIL fact stdout interp != golden (digits differ)"; fail=1; fi

# ---- (a) FALSIFIER: one perturbed ELF text byte must not run to 99 -------------
cp "$W/mx_sum.elf" "$W/mx_sum_perturb.elf"
printf '\x90' | dd of="$W/mx_sum_perturb.elf" bs=1 seek=200 count=1 conv=notrunc 2>/dev/null
MSYS_NO_PATHCONV=1 timeout 60 "$WSL" -d "$WSLDIST" -u root -e "$WSLW/mx_sum_perturb.elf" >/dev/null 2>&1; prc=$?
if [ $prc -eq 99 ]; then say "FAIL FALSIFIER: perturbed ELF still returns 99 (no teeth)"; fail=1
else say "FALSIFIER perturbed-ELF-byte -> rc=$prc != 99 (teeth confirmed)"; fi

if [ $fail -eq 0 ]; then
  say "HOST MATRIX GREEN -- one SVIR program set, FOUR execution hosts (win64-native, sysv-elf-native, wasm, interp) + the anchor, same behavior everywhere; fact stdout byte-identical cross-host; OOB trap uniform (199); ELF route is ONE sovereign stage with ZERO imports and ZERO anchor growth.  Γ2a: the host set grew {win64,wasm} -> {win64,wasm,sysv-elf}."
fi
exit $fail
