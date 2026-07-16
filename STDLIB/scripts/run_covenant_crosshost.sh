#!/usr/bin/env bash
# STDLIB/scripts/run_covenant_crosshost.sh -- THE AUTARKEIA Alpha-3 TAIL: core_H == core_win64 BY OBSERVATION.
#
# run_covenant.sh proved the covenant equation with core(T) host-invariant BY CONSTRUCTION (it omits the
# per-ISA TOOLS digests). This gate closes the tail: it turns that construction into a MEASUREMENT by
# re-deriving / re-folding the covenant core under genuinely different host conditions and OBSERVING the
# same bytes. Every faculty is III's own; the only outside element is a NEUTRAL SECOND OBSERVER
# (coreutils sha256sum on a different OS) whose sole job is to independently reproduce III's core and so
# make the invariance falsifiable rather than assumed.
#
#   OBS-1  RELOCATION (same OS, different ground): copy the committed tree to a DIFFERENT absolute path
#          under a distinct TMP/cwd, re-emit + re-show + re-fold there, and observe core is byte-equal.
#          Falsifies any hidden absolute-path / cwd / temp / timestamp leak into the sealed core.
#   OBS-2  SECOND OS: an INDEPENDENT re-implementation of iii-judge's fold (STDLIB/scripts/covenant_fold.sh,
#          POSIX sh + coreutils sha256sum + perl) runs on DEBIAN LINUX (WSL1, x86_64 Linux userland) over
#          the exact core lines and reproduces iii-judge's core byte-for-byte. A different OS + a different
#          SHA-256 implementation agreeing is the observation. Adversarial: one flipped byte -> different root.
#   OBS-3  TREE DIGEST CROSS-OS: a MATHESIS RECORD digest that III sealed on win64 is recomputed by Linux
#          sha256sum directly from the committed file bytes and must match -- a core INPUT observed on the
#          other host, not just the fold.
#
# Exit 0 = every observation holds ; 1 = a named red ; 2 = env (no compiler / no /dev/urandom).
# The Linux leg SKIPs (not fails) if no WSL Debian is present; OBS-1 still runs everywhere.
set -u
IFS=$'\n\t'
export LC_ALL=C
SD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SD/../.." && pwd)"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) X=".exe" ;;
    *)                                  X=""    ;;
esac
W="$ROOT/STDLIB/build/covenant_xh"; mkdir -p "$W"
say() { printf '%s\n' "$*"; }
FAIL=0
red() { say "RED  $*"; FAIL=1; }
grn() { say "PASS $*"; }

# ---- build the two tools this gate needs ----
say "[xhost] == build iii-testament + iii-judge =="
bash "$ROOT/COMPILER/BOOT/build_iii_testament.sh" --out "$W/iii-testament$X" >"$W/b_t.log" 2>&1 || { red "iii-testament build"; exit 1; }
bash "$ROOT/COMPILER/BOOT/build_iii_judge.sh"     --out "$W/iii-judge$X"     >"$W/b_j.log" 2>&1 || { red "iii-judge build"; exit 1; }
T="$W/iii-testament$X"; JU="$W/iii-judge$X"
grn "iii-testament + iii-judge built from source"

# ---- manifest + ephemeral key ----
MAN="$W/MANIFEST.txt"
( cd "$ROOT" && git ls-files -- \
    'COMPILER/BOOT/*.iii' 'COMPILER/BOOT/*.c' 'COMPILER/BOOT/*.h' 'COMPILER/BOOT/*.sh' \
    'STDLIB/iii/**/*.iii' 'STDLIB/sovir/*.iii' 'STDLIB/sovir/*.sh' \
    'STDLIB/corpus/*.iii' 'STDLIB/scripts/*.sh' 'DOCS/*.md' 'DOCS/*.log' 'DOCS/*.txt' \
    2>/dev/null | LC_ALL=C sort -u > "$MAN" )
NMAN=$(wc -l < "$MAN" | tr -d ' ')
[ "$NMAN" -gt 100 ] || { red "manifest too small ($NMAN)"; exit 1; }
head -c 96 /dev/urandom > "$W/seed.bin" 2>/dev/null || { say "[xhost] env: no /dev/urandom"; exit 2; }
"$T" keygen "$W/seed.bin" "$W/pk.bin" "$W/sk.bin" >/dev/null 2>&1 || { red "keygen"; exit 1; }
grn "manifest ($NMAN files) + ephemeral SLH-DSA key"

# ---- the core extractor (host-invariant show subset, folded by iii-judge) ----
core_lines() {   # <dat> <out-lines-file>
    "$T" show "$1" > "$W/show_tmp.txt" 2>&1 || return 1
    grep -E '^(TREE|SEED|BEARER|RECORD|CERT) ' "$W/show_tmp.txt" > "$2"
}

# ===========================================================================================
say "[xhost] == derivation WIN64 (the reference host) =="
( cd "$ROOT" && "$T" emit . "$MAN" "$W/sk.bin" "$W/pk.bin" "$W/win.dat" none none ) >"$W/e_win.log" 2>&1 || { red "emit win64"; exit 1; }
core_lines "$W/win.dat" "$W/core_win.txt" || { red "show win64"; exit 1; }
CW="$("$JU" fold "$W/core_win.txt" 2>/dev/null | grep -o 'root=[0-9a-f]*' | sed 's/root=//')"
[ -n "$CW" ] || { red "win64 core empty"; exit 1; }
grn "win64 core = $CW"

# ===========================================================================================
# OBS-1: RELOCATION -- copy the tree to a DIFFERENT absolute path, re-derive under a distinct TMP/cwd.
say "[xhost] == OBS-1: relocation invariance (different absolute path + cwd + TMP) =="
REL="$W/relocated_host"; rm -rf "$REL"; mkdir -p "$REL" "$W/reltmp"
( cd "$ROOT" && tar -cf - -T "$MAN" ) | ( cd "$REL" && tar -xf - ) 2>/dev/null || { red "relocate copy"; }
# emit also reads the (host-specific) tool binaries for the TOOLS lines (excluded from core); relocate them too
mkdir -p "$REL/COMPILED"
for tb in iii-prove iii-crypto iii-exact iii-typecheck iii_eval iii-events iii-intent iii-hexad; do
    [ -f "$ROOT/COMPILED/$tb$X" ] && cp "$ROOT/COMPILED/$tb$X" "$REL/COMPILED/$tb$X"
done
if [ -d "$REL/STDLIB" ]; then
    RELABS="$(cd "$REL" && pwd)"
    [ "$RELABS" != "$ROOT" ] && grn "relocated tree at a genuinely different path ($RELABS)" || red "relocation path not distinct"
    # re-emit from INSIDE the relocated root, with a distinct TMPDIR/TEMP/TMP and cwd
    ( cd "$REL" && TMPDIR="$W/reltmp" TEMP="$W/reltmp" TMP="$W/reltmp" \
        "$T" emit . "$MAN" "$W/sk.bin" "$W/pk.bin" "$W/rel.dat" none none ) >"$W/e_rel.log" 2>&1 || red "emit relocated"
    if [ -f "$W/rel.dat" ]; then
        core_lines "$W/rel.dat" "$W/core_rel.txt" || red "show relocated"
        CR2="$("$JU" fold "$W/core_rel.txt" 2>/dev/null | grep -o 'root=[0-9a-f]*' | sed 's/root=//')"
        if cmp -s "$W/core_win.txt" "$W/core_rel.txt"; then grn "OBS-1: core lines BYTE-IDENTICAL across relocation"; else red "OBS-1: core lines differ under relocation"; fi
        if [ -n "$CR2" ] && [ "$CR2" = "$CW" ]; then grn "OBS-1: relocated core == win64 core OBSERVED ($CR2)"; else red "OBS-1: relocated core=$CR2 != win64=$CW"; fi
        # non-vacuity strengthener: the FULL signed bodies must ALSO be byte-identical (nothing host-specific leaked at all)
        if cmp -s "$W/win.dat" "$W/rel.dat"; then grn "OBS-1: the entire signed testament is byte-identical across hosts (zero path/env/time leak)"; else red "OBS-1: full testament diverged under relocation"; fi
    fi
else red "relocation copy incomplete"; fi

# ===========================================================================================
# OBS-2: SECOND OS -- reproduce the fold on Debian Linux with an independent implementation.
say "[xhost] == OBS-2: second-OS reproduction (Debian Linux, independent sha256sum) =="
# first, self-check the independent implementation against iii-judge ON THIS host (must match before we trust it)
CW_WI="$(bash "$ROOT/STDLIB/scripts/covenant_fold.sh" "$W/core_win.txt" 2>/dev/null)"
if [ "$CW_WI" = "$CW" ]; then grn "independent fold validated against iii-judge on win64 ($CW_WI)"; else red "independent fold != iii-judge on win64 (impl bug: $CW_WI)"; fi

WSL="/c/Windows/System32/wsl.exe"
LINUX_OK=0
if [ -x "$WSL" ] && "$WSL" -d Debian -e sh -c 'command -v sha256sum >/dev/null && command -v perl >/dev/null' >/dev/null 2>&1; then LINUX_OK=1; fi
if [ "$LINUX_OK" -eq 1 ]; then
    # LF copies (the committed script may carry CRLF via .gitattributes; Linux bash needs LF)
    tr -d '\r' < "$ROOT/STDLIB/scripts/covenant_fold.sh" > "$W/fold_lf.sh"
    tr -d '\r' < "$W/core_win.txt" > "$W/core_win_lf.txt"
    # translate win path -> /mnt/c path for WSL1
    winpath_to_mnt() { printf '/mnt/%s' "$(printf '%s' "$1" | sed -e 's#^\([A-Za-z]\):#\L\1#' -e 's#\\#/#g')"; }
    MFOLD="$(winpath_to_mnt "$(cygpath -w "$W/fold_lf.sh" 2>/dev/null || echo "$W/fold_lf.sh")")"
    MCORE="$(winpath_to_mnt "$(cygpath -w "$W/core_win_lf.txt" 2>/dev/null || echo "$W/core_win_lf.txt")")"
    CL="$(MSYS2_ARG_CONV_EXCL='*' "$WSL" -d Debian -e bash "$MFOLD" "$MCORE" 2>/dev/null | tr -d '\r\0')"
    if [ -n "$CL" ] && [ "$CL" = "$CW" ]; then
        grn "OBS-2: DEBIAN LINUX independently reproduces the covenant core BYTE-FOR-BYTE ($CL)"
    else red "OBS-2: Linux core=$CL != win64=$CW"; fi
    # adversarial: one flipped byte on the Linux side must change the root
    printf 'TAMPER %s\n' "$(cat "$W/core_win_lf.txt")" > "$W/core_bad_lf.txt"
    MBAD="$(winpath_to_mnt "$(cygpath -w "$W/core_bad_lf.txt" 2>/dev/null || echo "$W/core_bad_lf.txt")")"
    CLB="$(MSYS2_ARG_CONV_EXCL='*' "$WSL" -d Debian -e bash "$MFOLD" "$MBAD" 2>/dev/null | tr -d '\r\0')"
    [ -n "$CLB" ] && [ "$CLB" != "$CW" ] && grn "OBS-2 adversarial: a tampered core folds to a DIFFERENT root on Linux" || red "OBS-2 adversarial: tampered core matched ($CLB)"

    # OBS-3: a tree-derived core INPUT recomputed on Linux from the committed bytes
    say "[xhost] == OBS-3: a sealed MATHESIS digest recomputed by Linux sha256sum =="
    REC_LINE="$(grep -m1 '^RECORD ' "$W/show_tmp2.txt" 2>/dev/null)"
    # re-show win to a stable file for parsing (show_tmp.txt was overwritten by relocated show)
    "$T" show "$W/win.dat" > "$W/show_win.txt" 2>&1
    REC_PATH="$(grep -m1 '^RECORD ' "$W/show_win.txt" | awk '{print $2}')"
    REC_DIG="$(grep -m1 '^RECORD ' "$W/show_win.txt" | sed -n 's/.* dig=\([0-9a-f]\{64\}\).*/\1/p')"
    if [ -n "$REC_PATH" ] && [ -n "$REC_DIG" ] && [ -f "$ROOT/$REC_PATH" ]; then
        MREC="$(winpath_to_mnt "$(cygpath -w "$ROOT/$REC_PATH" 2>/dev/null || echo "$ROOT/$REC_PATH")")"
        LDIG="$(MSYS2_ARG_CONV_EXCL='*' "$WSL" -d Debian -e sha256sum "$MREC" 2>/dev/null | cut -d' ' -f1 | tr -d '\r\0')"
        if [ "$LDIG" = "$REC_DIG" ]; then grn "OBS-3: Linux sha256sum($REC_PATH) == the digest III sealed on win64 ($REC_DIG)"; else red "OBS-3: Linux=$LDIG sealed=$REC_DIG"; fi
    else say "SKIP OBS-3: no parsable RECORD digest"; fi
else
    say "SKIP OBS-2/3: no WSL Debian Linux executor present (OBS-1 relocation still proves path/env invariance)"
fi

say ""
if [ "$FAIL" -eq 0 ]; then
    say "[xhost] ALL GREEN -- AUTARKEIA Alpha-3 TAIL: core_H == core_win64 BY OBSERVATION."
    say "[xhost] covenant core (observed invariant) = $CW"
    exit 0
else
    say "[xhost] RED -- a cross-host observation failed above."
    exit 1
fi
