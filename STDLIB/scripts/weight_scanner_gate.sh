#!/usr/bin/env bash
# weight_scanner_gate.sh -- THE EXACT WEIGHT SCANNER: standalone R1-weight analysis tools.
#
# A campaign of executable tools that point exact arithmetic at real DeepSeek-R1 weight
# blocks: ggufinfo (header reader), kqcross (proves the dequant reader BIT-EXACT vs metabole
# before any rank is trusted), weightrank (router expert-rank over GF(p)), exprank (MoE
# expert maps), attnrank (attention low-rank / quantization-induced exact dependencies).
# They carry a `main`, not a *_selfprove -- their contract is: read real weights exactly and
# report; kqcross is the one with TEETH (it reddens on a single-bit reader deviation), so it
# is the campaign's verification anchor.
#
# This gate compiles all five FROM SOURCE (proves they build on the current compiler,
# clean-checkout-safe) and, when the Feast is present, runs kqcross and demands the reader
# prove bit-identical to metabole -- the foundation every rank result stands on. Feast-absent
# is fail-open (the readers link clean; the real check needs real weights), summit_gate's idiom.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/wscan"
CLO="$T/clo"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$CLO"
[ -x "$IIIS" ] || { echo "[wscan] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ]  || { echo "[wscan] no archive: $ARC"; exit 2; }

TOOLS="ggufinfo kqcross weightrank exprank attnrank"

declare -A SRC
while IFS= read -r f; do SRC[$(basename "$f" .iii)]="$f"; done < <(find "$ROOT/STDLIB/iii" "$ROOT/COMPILER/BOOT" -name '*.iii' -not -path '*/build/*')
closure() {
  local root="$1"; local -A seen=(); local -a q=("$root"); local cur dep src
  while [ ${#q[@]} -gt 0 ]; do
    cur="${q[0]}"; q=("${q[@]:1}"); [ -z "$cur" ] && continue
    [ -n "${seen[$cur]:-}" ] && continue; seen[$cur]=1
    src="${SRC[$cur]:-}"; [ -z "$src" ] && continue
    for dep in $(grep -oE 'from "[a-z_0-9]+\.iii"' "$src" 2>/dev/null | sed 's/from "//;s/\.iii"//' | sort -u); do
      [ -n "${seen[$dep]:-}" ] || q+=("$dep"); done
  done
  echo "${!seen[@]}"
}
compile_one() {
  local b="$1"
  local src="${SRC[$b]:-}"
  [ -z "$src" ] && return 0
  [ -f "$CLO/$b.o" ] && return 0
  for try in 1 2 3; do
    "$IIIS" "$src" --compile-only --out "$CLO/$b.o" > "$CLO/$b.log" 2>&1 && [ -f "$CLO/$b.o" ] && return 0
    sleep 1
  done
  echo "[wscan] COMPILE FAIL $b: $(tail -1 "$CLO/$b.log")"; return 1
}

# compile every tool + its closure; link each tool's own main target-first
for tool in $TOOLS; do
  clo=$(closure "$tool")
  for m in $clo; do compile_one "$m" || exit 3; done
  OBJS=("$CLO/$tool.o"); for m in $clo; do [ "$m" = "$tool" ] && continue; [ -f "$CLO/$m.o" ] && OBJS+=("$CLO/$m.o"); done
  gcc -o "$T/$tool.exe" "${OBJS[@]}" "$ARC" -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/$tool.link" 2>&1 \
    || { echo "[wscan] $tool: LINK FAIL"; grep -oE "undefined reference to .[a-z_0-9]+." "$T/$tool.link" | sort -u | head; exit 4; }
  echo "[wscan] $tool: builds + links clean"
done

# the verification anchor: kqcross proves the reader bit-exact on real R1 (Feast-gated)
if [ -d "$ROOT/Feast" ] && ls "$ROOT/Feast"/*.gguf >/dev/null 2>&1; then
  "$T/kqcross.exe" > "$T/kqcross.out" 2>&1; rc=$?
  [ "$rc" -eq 0 ] || { echo "[wscan] kqcross REFUSED rc=$rc"; tail -6 "$T/kqcross.out"; exit 5; }
  grep -q "BIT-IDENTICAL to metabole. kquant VERIFIED" "$T/kqcross.out" || { echo "[wscan] READER NOT BIT-EXACT"; tail -6 "$T/kqcross.out"; exit 5; }
  echo "[wscan] READER VERIFIED on real R1: $(grep -m1 'BIT-IDENTICAL' "$T/kqcross.out")"
  echo "[wscan] THE EXACT WEIGHT SCANNER STANDS -- 5 tools build; the dequant reader is bit-exact on real weights."
else
  echo "[wscan] Feast absent -- 5 tools build + link clean; the bit-exactness check skips (fail-open)."
fi
exit 0
