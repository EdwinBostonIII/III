#!/usr/bin/env bash
# seed_ddc.sh -- close the DDC SEED residual by Diverse Double-Compiling iiis-0 (see DOCS/SEED-DDC-ANALYSIS.md).
# GUARDED: refuses to run unless $CC2 is a genuinely INDEPENDENT C compiler (different backend from gcc), so it
# can NEVER produce a false green.  Build iiis-0 with gcc AND with $CC2, run the byte-equivalence-gated bootstrap
# to iiis-2 on each, and byte-compare.  Identical => a gcc-only Thompson backdoor would have diverged => absent.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
say(){ echo "[seed-ddc] $*"; }

# ---- the guard: $CC2 must be set AND independent of gcc (reject the GCC family) ----
CC2="${CC2:-}"
if [ -z "$CC2" ]; then
  say "REFUSED: \$CC2 is unset.  Set CC2 to an INDEPENDENT C compiler (clang/LLVM or tcc/TinyCC), not gcc/g++."
  say "This host has only GCC-family compilers (gcc, cc->gcc, g++) -- they share the GCC backend, so they cannot"
  say "diverse-double-compile the seed.  The seed residual stays OPEN until an independent compiler is present."
  exit 2
fi
base="$(basename "$CC2")"
case "$base" in
  gcc|gcc-*|g++|c++|cc) say "REFUSED: \$CC2='$CC2' is GCC-family (shares the backend with gcc) -- NOT independent."; exit 2;;
esac
# verify it identifies as a non-GCC compiler
if "$CC2" --version 2>/dev/null | grep -qiE "free software foundation|gcc"; then
  say "REFUSED: \$CC2='$CC2' reports as GCC.  Need clang/LLVM or tcc for genuine diversity."; exit 2
fi
say "independent compiler accepted: $CC2 ($("$CC2" --version 2>/dev/null | head -1))"

# ---- the DDC build: iiis-0 with each compiler, then the deterministic chain to iiis-2, then byte-compare ----
WB="$ROOT/STDLIB/build/_seedddc"; mkdir -p "$WB"
build_chain() { # $1=CC  $2=tag  -> emits $WB/iiis-2.$2
  local cc="$1" tag="$2"
  say "building iiis-0..iiis-2 with CC=$cc (tag $tag) ..."
  ( cd "$ROOT/COMPILER/BOOT" && CC="$cc" bash build_iiis0.sh >/dev/null 2>&1 \
    && bash build_iiis1.sh >/dev/null 2>&1 && bash build_iiis2.sh >/dev/null 2>&1 ) || { say "build failed (CC=$cc)"; return 1; }
  cp "$ROOT/COMPILED/iiis-2.exe" "$WB/iiis-2.$tag" 2>/dev/null || return 1
}
build_chain gcc   gcc  || { say "gcc chain failed"; exit 1; }
build_chain "$CC2" cc2  || { say "$CC2 chain failed"; exit 1; }

if cmp -s "$WB/iiis-2.gcc" "$WB/iiis-2.cc2"; then
  say "SEED DDC-CLOSED -- iiis-2 built from a gcc-seeded chain and a $CC2-seeded chain are BYTE-IDENTICAL.  A"
  say "Thompson backdoor present in gcc-but-not-$CC2 would have diverged the binary; its absence is witnessed."
  exit 0
else
  say "SEED DIVERGENCE -- the two iiis-2 binaries DIFFER.  Either a non-determinism in the build, or (the alarm"
  say "this test exists to raise) a seed-dependent divergence.  Investigate before trusting either binary."
  exit 1
fi
