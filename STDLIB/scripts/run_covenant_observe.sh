#!/usr/bin/env bash
# STDLIB/scripts/run_covenant_observe.sh -- AUTARKEIA Alpha-3 TAIL (III-ONLY, NIH): core_H by OBSERVATION.
#
# `iii-ergon autarkeia` (ex run_covenant.sh, retired 2026-07-17) proves the covenant EQUATION and that
# core(T) is host-invariant BY CONSTRUCTION.  This
# gate closes the honest tail it names: turning core_H == core_win64 from by-construction into by-
# OBSERVATION -- using III and ONLY III.  No foreign hasher, no second OS, no coreutils sha256sum, no perl,
# no WSL/qemu/node.  The independent observer is built entirely from III's own faculties:
#
#   [primitive]  indep_sha256.iii -- a SECOND, from-scratch III SHA-256 (FIPS 180-4) that shares ZERO code
#                with the cad suite (the hasher behind iii-judge fold).  Self-checks the three FIPS test
#                vectors and returns 99, on BOTH substrates below.
#   [substrate]  the SAME organ is run two independent ways:
#                  (native) the mainline iiis-2 backend -> gcc,
#                  (interp) lowered by the INDEPENDENT iiisv (.iii -> SVIR) front-end and executed under
#                           svir_interp reference semantics -- an executor that shares no code with the
#                           native codegen.  Two executions, disjoint code paths.
#   [observer]   covobs_tail.iii (III EMITS III) reads the LIVE covenant core rows + the cad-computed root
#                CA and, appended to indep_covenant_obs_head.iii, forms an organ that recomputes iii-judge's
#                Merkle fold  ROOT_k = SHA-256(ROOT_(k-1) || row_k)  with the independent primitive and
#                returns 99 iff its root is bit-exact to CA.  Built + run on BOTH substrates.
#   [adversary]  the same observer with a single-nibble-tampered CA must be REFUSED (non-99) on BOTH.
#
# 99 native AND 99 interp for the observer = the covenant core reproduced by an algorithm-independent
# hasher on a substrate-independent executor.  core_H is no longer trusted by construction alone: it is
# OBSERVED, twice over, by III.  Exit 0 = the tail holds ; 1 = a named red ; 2 = env.
set -u
IFS=$'\n\t'
export LC_ALL=C
SD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SD/../.." && pwd)"
case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) X=".exe" ;;
    *)                                  X=""    ;;
esac
IIIS="$ROOT/COMPILED/iiis-2$X"
W="$ROOT/STDLIB/build/covenant_obs"; mkdir -p "$W"
say() { printf '%s\n' "$*"; }
FAIL=0
red() { say "RED  $*"; FAIL=1; }
grn() { say "PASS $*"; }

[ -x "$IIIS" ] || { say "[obs] env: no $IIIS"; exit 2; }

# ---------------------------------------------------------------------------------------------------
# 0. build the III toolchain leaves this gate needs, all from source (no committed .o trusted).
# ---------------------------------------------------------------------------------------------------
say "[obs] == build iii-testament + iii-judge + covobs_tail + iiisv + svir_interp (from source) =="
bash "$ROOT/COMPILER/BOOT/build_iii_testament.sh" --out "$W/iii-testament$X" >"$W/b_t.log" 2>&1 || { red "iii-testament build"; exit 1; }
bash "$ROOT/COMPILER/BOOT/build_iii_judge.sh"     --out "$W/iii-judge$X"     >"$W/b_j.log" 2>&1 || { red "iii-judge build"; exit 1; }
T="$W/iii-testament$X"; JU="$W/iii-judge$X"
"$IIIS" "$ROOT/STDLIB/iii/aether/covobs_tail.iii" --compile-only --out "$W/covobs_tail.o" >"$W/b_g.log" 2>&1 \
    && gcc "$W/covobs_tail.o" -o "$W/covobs_tail$X" -lkernel32 >>"$W/b_g.log" 2>&1 || { red "covobs_tail build"; exit 1; }
GEN="$W/covobs_tail$X"
"$IIIS" "$ROOT/STDLIB/sovir/iiisv.iii"       --compile-only --out "$W/iiisv.o"       >"$W/b_iv.log" 2>&1 \
    && gcc "$W/iiisv.o" -o "$W/iiisv$X" >>"$W/b_iv.log" 2>&1 || { red "iiisv build"; exit 1; }
IIISV="$W/iiisv$X"
"$IIIS" "$ROOT/STDLIB/sovir/svir_interp.iii" --compile-only --out "$W/svir_interp.o" >"$W/b_si.log" 2>&1 || { red "svir_interp build"; exit 1; }
grn "toolchain built"

# native + interp runners for a zero-import organ -> exit code
run_native() {   # <src.iii> <tag>  -> echoes rc
    local src="$1" tag="$2"
    "$IIIS" "$src" --compile-only --out "$W/${tag}_n.o" >>"$W/compile.log" 2>&1 || { echo 255; return; }
    gcc "$W/${tag}_n.o" -o "$W/${tag}_n$X" -lkernel32 >>"$W/compile.log" 2>&1 || { echo 254; return; }
    "$W/${tag}_n$X" >/dev/null 2>&1; echo $?
}
run_interp() {   # <src.iii> <tag>  -> echoes rc
    local src="$1" tag="$2"
    "$IIISV" "$src" > "$W/${tag}_gen.iii" 2>>"$W/compile.log" || { echo 253; return; }
    "$IIIS" "$W/${tag}_gen.iii" --compile-only --out "$W/${tag}_gen.o" >>"$W/compile.log" 2>&1 || { echo 252; return; }
    gcc "$W/svir_interp.o" "$W/${tag}_gen.o" -o "$W/${tag}_i$X" >>"$W/compile.log" 2>&1 || { echo 251; return; }
    "$W/${tag}_i$X" >/dev/null 2>&1; echo $?
}

# ---------------------------------------------------------------------------------------------------
# 1. the independent PRIMITIVE is a correct SHA-256 on BOTH substrates (FIPS vectors, self-checked).
# ---------------------------------------------------------------------------------------------------
say "[obs] == primitive: indep_sha256 (from-scratch, cad-independent) on native AND interp =="
KN=$(run_native "$ROOT/STDLIB/independence/indep_sha256.iii" kat)
KI=$(run_interp "$ROOT/STDLIB/independence/indep_sha256.iii" kat)
[ "$KN" = "99" ] && grn "indep_sha256 native: FIPS vectors (empty, abc, 56-byte) bit-exact (99)" || red "indep_sha256 native rc=$KN"
[ "$KI" = "99" ] && grn "indep_sha256 interp: same vectors under svir_interp reference semantics (99)" || red "indep_sha256 interp rc=$KI"

# ---------------------------------------------------------------------------------------------------
# 2. produce the LIVE covenant core + CA (cad's Merkle fold root) exactly as run_covenant.sh does.
# ---------------------------------------------------------------------------------------------------
say "[obs] == emit a live testament; derive core rows + CA (cad fold) =="
MAN="$W/MANIFEST.txt"
( cd "$ROOT" && git ls-files -- \
    'COMPILER/BOOT/*.iii' 'COMPILER/BOOT/*.c' 'COMPILER/BOOT/*.h' 'COMPILER/BOOT/*.sh' \
    'STDLIB/iii/**/*.iii' 'STDLIB/sovir/*.iii' 'STDLIB/sovir/*.sh' \
    'STDLIB/corpus/*.iii' 'STDLIB/scripts/*.sh' 'DOCS/*.md' 'DOCS/*.log' 'DOCS/*.txt' \
    2>/dev/null | LC_ALL=C sort -u > "$MAN" )
NMAN=$(wc -l < "$MAN" | tr -d ' ')
[ "$NMAN" -gt 100 ] || { red "manifest too small ($NMAN)"; exit 1; }
head -c 96 /dev/urandom > "$W/seed.bin" 2>/dev/null || { say "[obs] env: no /dev/urandom"; exit 2; }
"$T" keygen "$W/seed.bin" "$W/pk.bin" "$W/sk.bin" >/dev/null 2>&1 || { red "keygen"; exit 1; }
( cd "$ROOT" && "$T" emit . "$MAN" "$W/sk.bin" "$W/pk.bin" "$W/gen0.dat" none none ) >"$W/e0.log" 2>&1 || { red "emit gen0"; exit 1; }
"$T" show "$W/gen0.dat" > "$W/show_A.txt" 2>&1 || { red "show"; exit 1; }
grep -E '^(TREE|SEED|BEARER|RECORD|CERT) ' "$W/show_A.txt" > "$W/core_A.txt"
NROWS=$(grep -c . "$W/core_A.txt")
[ "$NROWS" -ge 5 ] || { red "core suspiciously small ($NROWS rows)"; exit 1; }
CA="$("$JU" fold "$W/core_A.txt" 2>/dev/null | grep -o 'root=[0-9a-f]*' | sed 's/root=//')"
[ "${#CA}" -eq 64 ] || { red "CA not 64 hex ('$CA')"; exit 1; }
grn "core: $NROWS host-invariant rows; CA (cad fold) = $CA"

# ---------------------------------------------------------------------------------------------------
# 3. the OBSERVER (III emits III): recompute CA with the independent primitive, on BOTH substrates.
# ---------------------------------------------------------------------------------------------------
say "[obs] == observer: covobs_tail (III emits III) recomputes CA, native AND interp =="
cp "$ROOT/STDLIB/independence/indep_covenant_obs_head.iii" "$W/obs.iii"
"$GEN" "$W/core_A.txt" "$CA" >> "$W/obs.iii" 2>"$W/gen.log" || { red "covobs_tail emit"; exit 1; }
ON=$(run_native "$W/obs.iii" obs)
OI=$(run_interp "$W/obs.iii" obs)
[ "$ON" = "99" ] && grn "observer native: independent SHA-256 reproduced CA bit-exact (99)" || red "observer native rc=$ON"
[ "$OI" = "99" ] && grn "observer interp: SAME root under svir_interp -- core_H by OBSERVATION (99)" || red "observer interp rc=$OI"

# ---------------------------------------------------------------------------------------------------
# 4. ADVERSARY: a single-nibble-tampered CA must be REFUSED on BOTH substrates.
# ---------------------------------------------------------------------------------------------------
say "[obs] == adversary: a tampered CA must be refused on both substrates =="
last="${CA:63:1}"
case "$last" in
    f|F) nx=0 ;;
    9)   nx=a ;;
    *)   nx=$(printf '%x' $(( 16#$last + 1 )) ) ;;
esac
BAD="${CA:0:63}$nx"
cp "$ROOT/STDLIB/independence/indep_covenant_obs_head.iii" "$W/obsbad.iii"
"$GEN" "$W/core_A.txt" "$BAD" >> "$W/obsbad.iii" 2>>"$W/gen.log" || { red "covobs_tail emit (bad)"; exit 1; }
BN=$(run_native "$W/obsbad.iii" obsbad)
BI=$(run_interp "$W/obsbad.iii" obsbad)
[ "$BN" != "99" ] && grn "adversary native: tampered CA refused (rc=$BN)" || red "adversary native ACCEPTED tampered CA"
[ "$BI" != "99" ] && grn "adversary interp: tampered CA refused (rc=$BI)" || red "adversary interp ACCEPTED tampered CA"

say ""
if [ "$FAIL" -eq 0 ]; then
    say "[obs] ALL GREEN -- AUTARKEIA Alpha-3 tail: core_H reproduced by an algorithm-independent hasher"
    say "[obs] on a substrate-independent executor.  core_H = $CA  (by OBSERVATION, III-only)."
    exit 0
else
    say "[obs] RED -- a check failed above."
    exit 1
fi
