#!/usr/bin/env bash
# omnia_selfprove_gate.sh -- THE STANDALONE-ORGAN SELF-PROOF SWEEP.
#
# A set of omnia/aether organs each carry their OWN self-derivation (a *_selfprove that
# proves the organ against the current living body and reddens under drift).  They have no
# dedicated gate script.  This gate proves them AS A SET: for each organ it resolves the
# exact transitive .iii dependency closure, compiles it, links the organ's selfprove
# target-first (so its own symbols win under --allow-multiple-definition), runs it TWICE,
# and demands 0 both times, byte-identical.  The engines each selfprove exercises are the
# organ's real primitives -- nothing is stubbed.
#
# Feast-dependent organs (their selfprove needs real R1 weights) run their OWN main when
# the Feast is present, checked by its self-test line, and SKIP (fail-open) when it is not
# -- the same idiom summit_gate uses.
#
# Clean-checkout-safe: everything but the tracked native archive is compiled from source
# (the closure pulls in arena/bigint/sqrt_sum_sign/... itself; no dependence on prebuilt
# build/kinesis objects).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
IIIS="${1:-$ROOT/COMPILED/iiis-2.exe}"
T="$ROOT/STDLIB/build/omnia_sp"
CLO="$T/clo"
ARC="$ROOT/STDLIB/build/iii/libiii_native.a"
mkdir -p "$CLO"
[ -x "$IIIS" ] || { echo "[omnia_sp] no compiler: $IIIS"; exit 2; }
[ -f "$ARC" ]  || { echo "[omnia_sp] no archive: $ARC"; exit 2; }

# organ -> selfprove export (pure: linked with a driver that calls it)
PURE_ORGANS="anamnesis aporia axioma gfp kanon kquant leimma paratheke phos rhoe router_krisis symphysis symploke syrroe zonos zonos_walk zygos"
declare -A SP=(
  [anamnesis]=anamnesis_selfprove [aporia]=aporia_selfprove [axioma]=axioma_selfprove
  [gfp]=gfp_selfprove [kanon]=kanon_selfprove [kquant]=kquant_selfprove [leimma]=leimma_selfprove
  [paratheke]=paratheke_selfprove
  [phos]=phos_selfprove [rhoe]=rhoe_selfprove [router_krisis]=rk_selfprove [symphysis]=symphysis_selfprove
  [symploke]=symploke_selfprove [syrroe]=syrroe_selfprove [zonos]=zn_selfprove [zonos_walk]=zw_selfprove
  [zygos]=zygos_selfprove )
# Feast-dependent: run the organ's own main, check its self-test line (skip if no Feast)
FEAST_ORGANS="circuit"
declare -A FEAST_CHECK=( [circuit]="FOUND 1 non-trivial circuit, both primes agree" )

declare -A SRC
while IFS= read -r f; do SRC[$(basename "$f" .iii)]="$f"; done < <(find "$ROOT/STDLIB/iii" "$ROOT/COMPILER/BOOT" -name '*.iii' -not -path '*/build/*')

closure() {  # echo the transitive .iii closure of $1 (basenames)
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
compile_one() {  # basename -> $CLO/base.o (cached); returns 1 only on a real compile error
  local b="$1"
  local src="${SRC[$b]:-}"
  [ -z "$src" ] && return 0                       # provided by the archive (e.g. cg_*_rules baked in)
  [ -f "$CLO/$b.o" ] && return 0
  for try in 1 2 3; do
    "$IIIS" "$src" --compile-only --out "$CLO/$b.o" > "$CLO/$b.log" 2>&1 && [ -f "$CLO/$b.o" ] && return 0
    sleep 1
  done
  echo "[omnia_sp] COMPILE FAIL $b: $(tail -1 "$CLO/$b.log")"; return 1
}

FAIL=0
for org in $PURE_ORGANS; do
  fn="${SP[$org]}"
  clo=$(closure "$org")
  for m in $clo; do compile_one "$m" || FAIL=1; done
  [ "$FAIL" -eq 1 ] && { echo "[omnia_sp] $org: closure did not compile"; exit 3; }
  drv="$T/drv_$org.iii"
  printf 'module drv_%s\nextern @abi(c-msvc-x64) fn %s() -> u64 from "x.iii"\nfn main(argc: i32, argv: u64) -> u64 { let _a:i32=argc let _v:u64=argv return %s() }\n' "$org" "$fn" "$fn" > "$drv"
  compile_one_drv() { "$IIIS" "$drv" --compile-only --out "$T/drv_$org.o" > "$T/drv_$org.clog" 2>&1; }
  compile_one_drv || { echo "[omnia_sp] $org: driver compile fail"; exit 3; }
  OBJS=("$T/drv_$org.o"); for m in $clo; do [ -f "$CLO/$m.o" ] && OBJS+=("$CLO/$m.o"); done
  rc=1
  for try in 1 2 3; do
    rm -f "$T/sp_$org.exe"
    gcc -o "$T/sp_$org.exe" "${OBJS[@]}" "$ARC" -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/sp_$org.link" 2>&1; rc=$?
    [ "$rc" -eq 0 ] && [ -f "$T/sp_$org.exe" ] && break
    sleep 1
  done
  [ "$rc" -eq 0 ] || { echo "[omnia_sp] $org: LINK FAIL"; grep -oE "undefined reference to .[a-z_0-9]+." "$T/sp_$org.link" | sort -u | head; exit 4; }
  "$T/sp_$org.exe" > "$T/sp_${org}_1.out" 2>&1; r1=$?
  "$T/sp_$org.exe" > "$T/sp_${org}_2.out" 2>&1; r2=$?
  if [ "$r1" -ne 0 ] || [ "$r2" -ne 0 ]; then echo "[omnia_sp] $org: $fn REFUSED (rc1=$r1 rc2=$r2)"; exit 5; fi
  cmp -s "$T/sp_${org}_1.out" "$T/sp_${org}_2.out" || { echo "[omnia_sp] $org: NONDETERMINISM"; exit 6; }
  echo "[omnia_sp] $org: $fn = 0  (green, byte-deterministic)"
done

# Feast-dependent organs: run the organ's own main when the Feast is on the table.
for org in $FEAST_ORGANS; do
  clo=$(closure "$org")
  for m in $clo; do compile_one "$m" || { echo "[omnia_sp] $org closure fail"; exit 3; }; done
  # target-first so the organ's OWN main wins under --allow-multiple-definition
  OBJS=("$CLO/$org.o"); for m in $clo; do [ "$m" = "$org" ] && continue; [ -f "$CLO/$m.o" ] && OBJS+=("$CLO/$m.o"); done
  gcc -o "$T/${org}_main.exe" "${OBJS[@]}" "$ARC" -lws2_32 -lkernel32 -Wl,--allow-multiple-definition > "$T/${org}_main.link" 2>&1 \
    || { echo "[omnia_sp] $org: main LINK FAIL"; grep -oE "undefined reference to .[a-z_0-9]+." "$T/${org}_main.link" | sort -u | head; exit 4; }
  if [ -d "$ROOT/Feast" ] && ls "$ROOT/Feast"/*.gguf >/dev/null 2>&1; then
    "$T/${org}_main.exe" > "$T/${org}_main.out" 2>&1; rc=$?
    [ "$rc" -eq 0 ] || { echo "[omnia_sp] $org: main REFUSED rc=$rc"; tail -4 "$T/${org}_main.out"; exit 5; }
    grep -q "${FEAST_CHECK[$org]}" "$T/${org}_main.out" || { echo "[omnia_sp] $org: self-test line absent"; tail -4 "$T/${org}_main.out"; exit 5; }
    echo "[omnia_sp] $org: main green on real R1 -- $(grep -m1 "${FEAST_CHECK[$org]}" "$T/${org}_main.out")"
  else
    echo "[omnia_sp] $org: links clean; Feast absent -> self-proof skipped (fail-open)"
  fi
done

echo "[omnia_sp] THE STANDALONE ORGANS SELF-PROVE -- $(echo $PURE_ORGANS | wc -w) pure green + byte-deterministic; $(echo $FEAST_ORGANS | wc -w) Feast-gated."
exit 0
