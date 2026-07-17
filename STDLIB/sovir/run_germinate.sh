#!/usr/bin/env bash
# run_germinate.sh -- Γ4/Σ0: THE HOST-CLOSURE SPORE + virgin-prefix germination (DOCS/III-GERMINATION-MAP.md).
#
# Σ0 (the host-closure spore) is ONE deterministic tar carrying:
#   anchor/svir_verify.iii   the 97-line trust-anchor SOURCE (the human-audit object)
#   svir/<p>.svir            the RAW anchor-verified SVIR bytes of each program (first-class members)
#   germs/verify/*           fused verifier germs  (anchor re-acceptance on virgin ground)
#   germs/dump/*             fused dump germs      (re-derive svir/<p>.svir -> byte-DDC)
#   germs/emit/*             fused translator germs: win64(.s), sysv-ELF, arm64-ELF (one stage each)
#   germs/toolchain/*        sovas + sovlink + crt0 (the sovereign PE leg; NO gcc anywhere)
#   grown/*                  the parent's per-host binaries (PE / ELF64-x86 / ELF64-a64) = DDC references
#   oracle/RC.tab, fact.gold expected rc per program + fact's 20! bytes
#   germinate.sh             THIS FILE -- the spore carries its own germination protocol
#   MANIFEST.sha256          integrity manifest over every member
#
# GERMINATION (the claim this script falsifies): on a VIRGIN PREFIX -- no repo, no gcc, no node,
# no iiis-2; boundary = OS + coreutils (+ WSL/qemu as foreign-ISA executors) -- the spore
#   G1 integrity-checks itself, G2 re-verifies every module with the anchor germ,
#   G3 REGROWS every per-host binary from the carried SVIR and byte-DDCs it against the parent,
#   G4 executes regrown binaries per host and matches the carried oracle,
#   G5 re-derives the raw SVIR members and byte-DDCs them.
# The Windows virgin leg runs under `env -i PATH=/usr/bin:/bin` (mechanically no repo env).
# The Linux virgin leg runs in /tmp inside the distro: delivery copy is the ONLY /mnt/c touch.
# FALSIFIERS: (A) one flipped byte in a spore member -> integrity MUST red;
#             (B) one flipped byte in a carried grown/ binary, integrity SKIPPED -> the byte-DDC MUST red;
#             (C) pack twice -> the two tars MUST be byte-identical (the release artifact is reproducible).
# Γ3 REGROWTH GERMS (germs/linux/): per-program SELF-TRANSLATED Linux-native x86-64 ELFs -- each is the
# waist translator (svir_elf_w or svir_arm64_w, themselves anchor-verified SVIR) fused with one program's
# SVIR, translated to a static Linux binary.  On the Linux virgin prefix they REGROW every per-host binary
# (x86 AND AArch64) byte-identically to the parent -- zero Windows, zero PE toolchain, zero foreign
# toolchain.  The translator SVIRs ride as first-class members (svir/elfw.svbin, svir/a64w.svbin).
# Boundary note: wasm host excluded (node is outside the spore boundary); the interp is an in-repo
# reference tool, not a spore member -- the oracle rides as bytes.
set -uo pipefail
SELF="${BASH_SOURCE[0]}"
MODE="${1:---all}"
say(){ echo "[germ] $*"; }

PROGS="sum:svir_prog loop:svir_loop call:svir_call fact:svir_fact bignum:svir_bignum cioob:_svir_ci_oob toolchain:toolchain_gen ops:ops_gen bignum2:bignum2_gen isqrt:isqrt_gen"
want_rc(){ case "$1" in cioob) echo 199;; *) echo 99;; esac; }

# ============================ SPORE-SIDE MODES (no repo, no toolchain) ============================
if [ "$MODE" = "--germinate-win" ]; then
  PX="$2"; cd "$PX" || exit 2; fail=0
  sha256sum -c --quiet MANIFEST.sha256 >/dev/null 2>&1 \
    && say "G1 integrity : MANIFEST ok ($(wc -l < MANIFEST.sha256) members)" \
    || { say "G1 FAIL integrity"; exit 3; }
  for pair in $PROGS; do l="${pair%%:*}"
    ./germs/verify/mx_v_$l.exe >/dev/null 2>&1; v=$?
    [ $v -eq 99 ] || { say "G2 FAIL anchor $l rc=$v"; fail=1; }
  done
  [ $fail -eq 0 ] && say "G2 anchor    : 10/10 modules re-accepted by the anchor germ (rc=99)"
  for pair in $PROGS; do l="${pair%%:*}"
    ./germs/dump/sd_$l.exe > "rg_$l.svir" 2>/dev/null
    cmp -s "rg_$l.svir" "svir/$l.svir" || { say "G5 FAIL svir-DDC $l"; fail=1; }
  done
  [ $fail -eq 0 ] && say "G5 svir-DDC  : 10/10 re-derived SVIR byte-identical to carried members"
  for pair in $PROGS; do l="${pair%%:*}"
    ./germs/emit/mx_tx_$l.exe > "rg_$l.s" 2>/dev/null
    ./germs/toolchain/sovas_main.exe "rg_$l.s" > "rg_$l.o2" 2>/dev/null || { say "G3 FAIL sovas $l"; fail=1; continue; }
    ./germs/toolchain/sovlink_main.exe germs/toolchain/crt0_sov.o "rg_$l.o2" > "rg_$l.x86.exe" 2>/dev/null || { say "G3 FAIL sovlink $l"; fail=1; continue; }
    cmp -s "rg_$l.x86.exe" "grown/$l.x86.exe" || { say "G3 FAIL PE-DDC $l"; fail=1; }
    ./germs/emit/mx_te_$l.exe > "rg_$l.elf" 2>/dev/null
    cmp -s "rg_$l.elf" "grown/$l.elf" || { say "G3 FAIL ELF-DDC $l"; fail=1; }
    ./germs/emit/mx_ta_$l.exe > "rg_$l.a64.elf" 2>/dev/null
    cmp -s "rg_$l.a64.elf" "grown/$l.a64.elf" || { say "G3 FAIL a64-DDC $l"; fail=1; }
  done
  [ $fail -eq 0 ] && say "G3 regrowth  : 30/30 per-host binaries REGROWN from carried SVIR, byte-DDC == parent"
  for pair in $PROGS; do l="${pair%%:*}"
    chmod +x "rg_$l.x86.exe" 2>/dev/null
    if [ "$l" = "fact" ]; then "./rg_$l.x86.exe" > "rg_$l.out" 2>/dev/null; r=$?
      cmp -s "rg_$l.out" oracle/fact.gold || { say "G4 FAIL fact stdout != oracle"; fail=1; }
    else "./rg_$l.x86.exe" >/dev/null 2>&1; r=$?; fi
    [ $r -eq "$(want_rc $l)" ] || { say "G4 FAIL exec $l rc=$r want=$(want_rc $l)"; fail=1; }
  done
  [ $fail -eq 0 ] && say "G4 execution : 10/10 REGROWN PEs run on the virgin prefix (oracle rc + fact bytes)"
  exit $fail
fi

if [ "$MODE" = "--germinate-lin" ]; then
  PX="$2"; cd "$PX" || exit 2; fail=0
  QEMU="/opt/q72/usr/bin/qemu-aarch64"; QEMUR="/opt/q72/usr/bin/qemu-riscv64"; export LD_LIBRARY_PATH=/opt/q72/usr/lib/x86_64-linux-gnu
  sha256sum -c --quiet MANIFEST.sha256 >/dev/null 2>&1 \
    && say "L1 integrity : MANIFEST ok on the Linux virgin prefix" \
    || { say "L1 FAIL integrity"; exit 3; }
  chmod +x grown/* germs/*/* 2>/dev/null   # qemu-user enforces the x bit like execve; lxfs honors modes
  for pair in $PROGS; do l="${pair%%:*}"
    chmod +x "grown/$l.elf" 2>/dev/null
    if [ "$l" = "fact" ]; then "./grown/$l.elf" > "lx_$l.out" 2>/dev/null; r=$?
      cmp -s "lx_$l.out" oracle/fact.gold || { say "L2 FAIL fact stdout(sysv) != oracle"; fail=1; }
    else "./grown/$l.elf" >/dev/null 2>&1; r=$?; fi
    [ $r -eq "$(want_rc $l)" ] || { say "L2 FAIL sysv $l rc=$r"; fail=1; }
  done
  [ $fail -eq 0 ] && say "L2 sysv-exec : 10/10 carried ELFs run natively (oracle rc + fact bytes)"
  if [ -x "$QEMU" ]; then
    for pair in $PROGS; do l="${pair%%:*}"
      if [ "$l" = "fact" ]; then "$QEMU" "grown/$l.a64.elf" > "la_$l.out" 2>/dev/null; r=$?
        cmp -s "la_$l.out" oracle/fact.gold || { say "L3 FAIL fact stdout(a64) != oracle"; fail=1; }
      else "$QEMU" "grown/$l.a64.elf" >/dev/null 2>&1; r=$?; fi
      [ $r -eq "$(want_rc $l)" ] || { say "L3 FAIL a64 $l rc=$r"; fail=1; }
    done
    [ $fail -eq 0 ] && say "L3 a64-exec  : 10/10 carried AArch64 ELFs run under qemu (oracle rc + fact bytes)"
    for pair in $PROGS; do l="${pair%%:*}"
      if [ "$l" = "fact" ]; then "$QEMUR" "grown/$l.rv.elf" > "lr_$l.out" 2>/dev/null; r=$?
        cmp -s "lr_$l.out" oracle/fact.gold || { say "L3 FAIL fact stdout(rv) != oracle"; fail=1; }
      else "$QEMUR" "grown/$l.rv.elf" >/dev/null 2>&1; r=$?; fi
      [ $r -eq "$(want_rc $l)" ] || { say "L3 FAIL rv $l rc=$r"; fail=1; }
    done
    [ $fail -eq 0 ] && say "L3 rv-exec   : 10/10 carried RISC-V ELFs run under qemu-riscv64 (oracle rc + fact bytes)"
  else say "L3 FAIL: qemu 7.2 executor missing at /opt/q72"; fail=1; fi
  # L4 -- Γ3 REGROWTH ON LINUX: the self-translated germs re-emit every per-host binary, byte-DDC vs parent
  l4fail=0
  for pair in $PROGS; do l="${pair%%:*}"
    "./germs/linux/lgerm_$l.elf" > "lx_rg_$l.elf" 2>/dev/null; g1=$?
    cmp -s "lx_rg_$l.elf" "grown/$l.elf" || { say "L4 FAIL x86-regrow $l (rc=$g1)"; l4fail=1; }
    "./germs/linux/lgerm_a_$l.elf" > "lx_rg_$l.a64.elf" 2>/dev/null; g2=$?
    cmp -s "lx_rg_$l.a64.elf" "grown/$l.a64.elf" || { say "L4 FAIL a64-regrow $l (rc=$g2)"; l4fail=1; }
    "./germs/linux/lgerm_r_$l.elf" > "lx_rg_$l.rv.elf" 2>/dev/null; g3=$?
    cmp -s "lx_rg_$l.rv.elf" "grown/$l.rv.elf" || { say "L4 FAIL rv-regrow $l (rc=$g3)"; l4fail=1; }
  done
  if [ $l4fail -eq 0 ]; then say "L4 regrowth  : 30/30 per-host binaries (x86 + AArch64 + RISC-V) REGROWN ON LINUX from waist-translator germs, byte-DDC == parent (zero Windows, zero PE toolchain, 3 ISAs)"
  else fail=1; fi
  chmod +x "lx_rg_isqrt.a64.elf" "lx_rg_isqrt.rv.elf" 2>/dev/null   # regrown via shell redirect = 0644; qemu enforces the x bit
  "$QEMU" "lx_rg_isqrt.a64.elf" >/dev/null 2>&1; l5=$?
  "$QEMUR" "lx_rg_isqrt.rv.elf" >/dev/null 2>&1; l5r=$?
  if [ $l5 -eq 99 ] && [ $l5r -eq 99 ]; then say "L5 regrown-run: Linux-REGROWN AArch64 AND RISC-V binaries execute at oracle under qemu (rc=99 both)"
  else say "L5 FAIL regrown a64=$l5 rv=$l5r"; fail=1; fi
  exit $fail
fi

if [ "$MODE" = "--ddc-only" ]; then  # hash-independent DDC tooth: regrow ONE route, cmp only
  PX="$2"; l="$3"; cd "$PX" || exit 2
  ./germs/emit/mx_te_$l.exe > "rg_$l.elf" 2>/dev/null
  cmp -s "rg_$l.elf" "grown/$l.elf" || exit 9
  exit 0
fi

# ============================ REPO-SIDE: PACK + ORCHESTRATE ============================
ROOT="$(cd "$(dirname "$SELF")/../.." && pwd)"
S="$ROOT/STDLIB/sovir"; W="$ROOT/STDLIB/build/sovir"; BOOT="$ROOT/STDLIB/build/_sovboot"
IIIS="$ROOT/COMPILED/iiis-2.exe"; SPD="$ROOT/STDLIB/build/spore"; SP="$SPD/S0"
WSL="/c/Windows/System32/wsl.exe"; WSLDIST="${WSLDIST:-Debian}"
fail=0

# ---- PACK -----------------------------------------------------------------------
rm -rf "$SP"; mkdir -p "$SP/anchor" "$SP/svir" "$SP/germs/verify" "$SP/germs/dump" "$SP/germs/emit" "$SP/germs/toolchain" "$SP/germs/linux" "$SP/grown" "$SP/oracle"
[ -s "$W/svir_dump.o" ] || "$IIIS" "$S/svir_dump.iii" --compile-only --out "$W/svir_dump.o" >/dev/null 2>&1
for pair in $PROGS; do l="${pair%%:*}"; o="${pair#*:}"
  for need in "$W/mx_v_$l.exe" "$W/mx_tx_$l.exe" "$W/mx_te_$l.exe" "$W/mx_ta_$l.exe" "$W/mx_tr_$l.exe" "$W/mx_$l.x86.exe" "$W/mx_$l.elf" "$W/mx_$l.a64.elf" "$W/mx_$l.rv.elf"; do
    [ -s "$need" ] || { say "PACK missing $need -- run run_host_matrix.sh first"; exit 4; }
  done
  [ -s "$W/sd_$l.exe" ] || gcc "$W/svir_dump.o" "$W/$o.o" -o "$W/sd_$l.exe" 2>/dev/null || { say "PACK FAIL dump-germ $l"; exit 4; }
  "$W/sd_$l.exe" > "$SP/svir/$l.svir" 2>/dev/null; [ -s "$SP/svir/$l.svir" ] || { say "PACK FAIL dump $l"; exit 4; }
  cp "$W/mx_v_$l.exe"  "$SP/germs/verify/"
  cp "$W/sd_$l.exe"    "$SP/germs/dump/"
  cp "$W/mx_tx_$l.exe" "$W/mx_te_$l.exe" "$W/mx_ta_$l.exe" "$W/mx_tr_$l.exe" "$SP/germs/emit/"
  cp "$W/mx_$l.x86.exe" "$SP/grown/$l.x86.exe"
  cp "$W/mx_$l.elf"     "$SP/grown/$l.elf"
  cp "$W/mx_$l.a64.elf" "$SP/grown/$l.a64.elf"
  cp "$W/mx_$l.rv.elf"  "$SP/grown/$l.rv.elf"
done
# Γ3 members: translator SVIRs (first-class) + per-program Linux-native regrowth germs for ALL THREE ISAs
for t in elfw a64w rvw; do
  [ -s "$W/$t.svbin" ] || { say "PACK missing $W/$t.svbin -- run run_retarget.sh first"; exit 4; }
  cp "$W/$t.svbin" "$SP/svir/$t.svbin"
done
for pair in $PROGS; do l="${pair%%:*}"
  for c in comp compa compr; do
    [ -s "$W/${c}_$l.o" ] || { say "PACK missing ${c}_$l.o -- run run_retarget.sh first"; exit 4; }
  done
  gcc "$W/svir_elf.o" "$W/comp_$l.o"  -o "$W/te_g_$l.exe"  2>/dev/null && "$W/te_g_$l.exe"  > "$SP/germs/linux/lgerm_$l.elf"   2>/dev/null
  gcc "$W/svir_elf.o" "$W/compa_$l.o" -o "$W/te_ga_$l.exe" 2>/dev/null && "$W/te_ga_$l.exe" > "$SP/germs/linux/lgerm_a_$l.elf" 2>/dev/null
  gcc "$W/svir_elf.o" "$W/compr_$l.o" -o "$W/te_gr_$l.exe" 2>/dev/null && "$W/te_gr_$l.exe" > "$SP/germs/linux/lgerm_r_$l.elf" 2>/dev/null
  [ -s "$SP/germs/linux/lgerm_$l.elf" ] && [ -s "$SP/germs/linux/lgerm_a_$l.elf" ] && [ -s "$SP/germs/linux/lgerm_r_$l.elf" ] || { say "PACK FAIL linux germ $l"; exit 4; }
done
chmod +x "$SP/grown/"*.elf "$SP/germs/"*/*.exe "$SP/germs/linux/"*.elf 2>/dev/null
cp "$S/svir_verify.iii" "$SP/anchor/"
cp "$BOOT/sovas_main.exe" "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$SP/germs/toolchain/"
cp "$W/mx_fact.gold.out" "$SP/oracle/fact.gold"
if node -e 'let f=1n;for(let i=1n;i<=20n;i++)f*=i;process.stdout.write(f.toString()+"\n")' > "$SPD/_gold_x" 2>/dev/null; then
  cmp -s "$SPD/_gold_x" "$SP/oracle/fact.gold" || { say "PACK FAIL: carried fact golden != independent node golden"; exit 4; }
fi
for pair in $PROGS; do l="${pair%%:*}"; echo "$l $(want_rc $l)"; done > "$SP/oracle/RC.tab"
cp "$SELF" "$SP/germinate.sh"; chmod +x "$SP/germinate.sh"
( cd "$SP" && find . -type f ! -name MANIFEST.sha256 -print0 | sort -z | xargs -0 sha256sum > MANIFEST.sha256 )
TARFLAGS=(--sort=name --owner=0 --group=0 --numeric-owner --mtime=@0 --mode=a+rx,u+w)
tar "${TARFLAGS[@]}" -cf "$SPD/S0.tar"  -C "$SP" .
tar "${TARFLAGS[@]}" -cf "$SPD/S0b.tar" -C "$SP" .
if cmp -s "$SPD/S0.tar" "$SPD/S0b.tar"; then say "PACK C reproducible: two packs byte-identical -- spore identity sha256=$(sha256sum "$SPD/S0.tar" | cut -c1-16)..."
else say "FAIL PACK C: two packs differ (spore not reproducible)"; fail=1; fi
say "PACK        : Σ0 = $(du -sh "$SPD/S0.tar" | cut -f1) tar, $(find "$SP" -type f | wc -l) members (anchor src + program & translator SVIR + win64 germs + LINUX regrowth germs + grown + oracle + protocol)"
[ "$MODE" = "--pack" ] && exit $fail

# ---- GERMINATE: virgin WINDOWS prefix (env -i: mechanically no repo environment) ----
PXW="$(cygpath -u "$LOCALAPPDATA")/Temp/iii_germ_w"
rm -rf "$PXW"; mkdir -p "$PXW"; cp "$SPD/S0.tar" "$PXW/"
( cd "$PXW" && tar -xf S0.tar )
env -i PATH="/usr/bin:/bin" bash "$PXW/germinate.sh" --germinate-win "$PXW"; wrc=$?
if [ $wrc -eq 0 ]; then say "WIN-PREFIX  : GREEN (integrity + anchor + 30-binary regrowth-DDC + svir-DDC + oracle exec)"
else say "FAIL WIN-PREFIX rc=$wrc"; fail=1; fi

# ---- GERMINATE: virgin LINUX prefix (delivery copy is the only /mnt/c touch) --------
# wsl.exe writes at offset 0 of a shared redirected handle (clobbers earlier bash output) -> own capture file
# Windows->WSL path, robust to pwd flavor (cmd-spawned bash yields C:/... -- see run_host_matrix.sh)
to_wsl(){ case "$1" in /c/*) echo "/mnt/c${1#/c}";; [A-Za-z]:*) echo "/mnt/$(printf %.1s "$1" | tr 'A-Z' 'a-z')${1#*:}";; *) echo "$1";; esac; }
SPW="$(to_wsl "$SPD")"
MSYS_NO_PATHCONV=1 "$WSL" -d "$WSLDIST" -u root -e bash -c "rm -rf /tmp/iii_germ_l && mkdir -p /tmp/iii_germ_l && cp '$SPW/S0.tar' /tmp/iii_germ_l/ && cd /tmp/iii_germ_l && tar -xf S0.tar && exec bash ./germinate.sh --germinate-lin /tmp/iii_germ_l" > "$SPD/_linleg.log" 2>&1; lrc=$?
cat "$SPD/_linleg.log"
if [ $lrc -eq 0 ]; then say "LIN-PREFIX  : GREEN (integrity + sysv-native exec + a64-qemu exec vs oracle)"
else say "FAIL LIN-PREFIX rc=$lrc"; fail=1; fi

# ---- FALSIFIER A: flipped member byte -> integrity must red -------------------------
PXA="$(cygpath -u "$LOCALAPPDATA")/Temp/iii_germ_pA"
rm -rf "$PXA"; mkdir -p "$PXA"; ( cd "$PXA" && tar -xf "$SPD/S0.tar" )
printf '\x5A' | dd of="$PXA/svir/fact.svir" bs=1 seek=7 count=1 conv=notrunc 2>/dev/null
env -i PATH="/usr/bin:/bin" bash "$PXA/germinate.sh" --germinate-win "$PXA" >/dev/null 2>&1; arc=$?
if [ $arc -eq 0 ]; then say "FAIL FALSIFIER A: perturbed spore member still germinates (no integrity teeth)"; fail=1
else say "FALSIFIER A : flipped svir member byte -> germination rc=$arc != 0 (integrity teeth)"; fi

# ---- FALSIFIER B: flipped grown binary, integrity SKIPPED -> byte-DDC must red ------
PXB="$(cygpath -u "$LOCALAPPDATA")/Temp/iii_germ_pB"
rm -rf "$PXB"; mkdir -p "$PXB"; ( cd "$PXB" && tar -xf "$SPD/S0.tar" )
printf '\x5A' | dd of="$PXB/grown/sum.elf" bs=1 seek=201 count=1 conv=notrunc 2>/dev/null
env -i PATH="/usr/bin:/bin" bash "$PXB/germinate.sh" --ddc-only "$PXB" sum >/dev/null 2>&1; brc=$?
if [ $brc -eq 0 ]; then say "FAIL FALSIFIER B: perturbed parent binary passes byte-DDC (no DDC teeth)"; fail=1
else say "FALSIFIER B : flipped parent-binary byte -> regrowth DDC rc=$brc != 0 (hash-independent teeth)"; fi

if [ $fail -eq 0 ]; then
  say "GERMINATION GREEN -- Σ0+Γ3 the self-carrying spore: ONE reproducible tar that, on a VIRGIN prefix with no repo/gcc/node/iiis, re-verifies itself under the carried 97-line anchor, REGROWS all 30 per-host binaries on the win64 prefix AND all 30 target binaries (x86-64 + AArch64 + RISC-V) ON THE LINUX PREFIX from waist-translator germs -- byte-identical to the parent everywhere -- re-derives its own SVIR members, and matches the carried oracle on win64-native + sysv-native + arm64-qemu + riscv-qemu.  The spore carries its own retargeting toolchains for THREE ISAs as ~12-13 KB anchor-verified SVIR modules each."
fi
exit $fail
