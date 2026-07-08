#!/usr/bin/env bash
# run_seed_link.sh -- Lambda-0 WHOLE-SEED LINK gate: 19 iiis-0 TUs -> ONE verified SVIR v2 module.
#
#   Per TU (main.c FIRST = global fn 0, then build_iiis0's sort order): ccsv compiles at a cumulative
#   MEMBASE (statics relocate at compile time -> one flat memory, addresses correct by construction),
#   emitting the module (vmap mode: + //V const-site + //D data-slot fn-index manifests), the dbg
#   names listing (the def symtab; its MTOP header chains the next base), and the raw container bytes
#   (svir_dump).  svir_ld then links: defs by position, imports by name (ambiguity = hard error),
#   CRT-boundary names dedup into a LOUD import tail, CALL/CALL2 index remap, //V + //D fn-ptr
#   index-space rewrites, data concatenation at membases.
#
#   Exit gates:
#     G1  svir_verify(linked) == 99 via verify_main   (the 82->97-line anchor accepts the WHOLE SEED)
#     G2  statics ceiling: final MTOP < 917504         (below the fixed VA_BUF/shadow layout)
#     G3  interp(linked, no argv) == 198               (execution reaches a CRT-boundary import and
#         dies LOUDLY -- the documented pre-shim contract; host-shim rung upgrades this to rc parity
#         with gcc iiis-0)
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; SEED="$ROOT/COMPILER/BOOT"
W="$ROOT/STDLIB/build/sovlink"; mkdir -p "$W"
fail=0; say(){ echo "[seed-link] $*"; }

# --- tools ---
for m in ccsv svir_dump svir_ld svir_verify verify_main svir_interp; do
  "$IIIS" "$S/$m.iii" --compile-only --out "$W/$m.o" >/dev/null 2>&1 || { say "FAIL compile $m.iii"; exit 1; }
done
gcc "$W/ccsv.o" -o "$W/ccsv.exe" 2>/dev/null || { say "FAIL link ccsv"; exit 1; }
gcc "$W/svir_ld.o" -o "$W/svir_ld.exe" 2>/dev/null || { say "FAIL link svir_ld"; exit 1; }

TUS="main acc ast ceiling cg_r0 cg_r3 cg_rm1 cg_rm2 emit hexad_check iii_cg_pe_iiis1 jit_emit lex link parse proof sema sid witness_alloc"

# --- per-TU extraction at cumulative membases ---
BASE=0
: > "$W/link.rsp"
for m in $TUS; do
  "$W/ccsv.exe" "$SEED/$m.c" $BASE vmap > "$W/full_$m.txt" 2>/dev/null
  grep -v '^//' "$W/full_$m.txt" > "$W/gen_$m.iii"
  grep '^//'  "$W/full_$m.txt" > "$W/$m.vmap" || true
  "$W/ccsv.exe" "$SEED/$m.c" $BASE dbg > "$W/$m.names" 2>/dev/null
  NEXT=$(head -1 "$W/$m.names" | grep -oE 'MTOP=[0-9]+' | cut -d= -f2)
  [ -n "$NEXT" ] || { say "FAIL: no MTOP from $m.c dbg"; exit 1; }
  "$IIIS" "$W/gen_$m.iii" --compile-only --out "$W/gen_$m.o" >/dev/null 2>&1 || { say "FAIL iiis-2 on gen_$m.iii"; exit 1; }
  rm -f "$W/dump_$m.exe" "$W/$m.svbin"
  gcc "$W/svir_dump.o" "$W/gen_$m.o" -o "$W/dump_$m.exe" 2>/dev/null
  "$W/dump_$m.exe" > "$W/$m.svbin" 2>/dev/null
  [ -s "$W/$m.svbin" ] || { say "FAIL: empty svbin for $m"; exit 1; }
  echo "$m.svbin $m.names $m.vmap $BASE" >> "$W/link.rsp"
  say "TU $m.c: base=$BASE next=$NEXT svbin=$(wc -c < "$W/$m.svbin")B vmap=$(wc -l < "$W/$m.vmap")"
  BASE=$NEXT
done

# --- G2: statics ceiling ---
if [ "$BASE" -lt 917504 ]; then say "G2 statics ceiling: total=$BASE < 917504 OK"
else say "G2 FAIL: statics total=$BASE overruns the fixed layout"; fail=1; fi

# --- the LINK ---
( cd "$W" && ./svir_ld.exe link.rsp > linked_gen.iii ) ; ldrc=$?
if [ $ldrc -ne 0 ]; then say "G-link FAIL: svir_ld rc=$ldrc"; sed -n '1,3p' "$W/linked_gen.iii"; exit 1; fi
say "linked module: $(head -2 "$W/linked_gen.iii" | tail -1 | grep -oE '\[u8; [0-9]+\]') ($(wc -c < "$W/linked_gen.iii") B text)"

"$IIIS" "$W/linked_gen.iii" --compile-only --out "$W/linked.o" >/dev/null 2>&1 || { say "FAIL iiis-2 on linked_gen.iii"; exit 1; }

# --- G1: the anchor accepts the whole seed ---
rm -f "$W/vf_linked.exe"
gcc "$W/verify_main.o" "$W/svir_verify.o" "$W/linked.o" -o "$W/vf_linked.exe" 2>/dev/null
"$W/vf_linked.exe" >/dev/null 2>&1; vrc=$?
if [ "$vrc" -eq 99 ]; then say "G1 svir_verify(WHOLE SEED) : rc=99 VALID"
else say "G1 FAIL: svir_verify rc=$vrc (expect 99)"; fail=1; fi

# --- G3: no-arg EXIT-CODE PARITY with gcc-built iiis-0 ---
# The no-arg path (argc<2 -> usage -> exit) crosses NO resolved import: undeclared stdio calls are
# compile-time no-ops (stderr text drops; the CODE is the contract here).  A future path that hits a
# REAL unresolved import dies 198 (loud) and reddens this parity until the host-shim rung lands.
rm -f "$W/in_linked.exe"
gcc "$W/svir_interp.o" "$W/linked.o" -o "$W/in_linked.exe" 2>/dev/null
timeout 30 "$W/in_linked.exe" >/dev/null 2>&1; irc=$?
"$ROOT/COMPILED/iiis-0.exe" >/dev/null 2>&1; grc=$?
if [ "$irc" -eq "$grc" ]; then say "G3 no-arg PARITY : interp(linked)=$irc == gcc iiis-0=$grc (the linked seed takes the same usage path to the same exit code)"
else say "G3 FAIL: interp rc=$irc != gcc iiis-0 rc=$grc"; fail=1; fi

if [ $fail -eq 0 ]; then say "SEED-LINK GREEN -- 19 TUs, ONE v2 module, anchor-verified; fn-ptr manifests applied; statics fit the shared layout."; fi
exit $fail
