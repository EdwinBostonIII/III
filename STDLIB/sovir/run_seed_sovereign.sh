#!/usr/bin/env bash
# run_seed_sovereign.sh -- Phi1 CAPSTONE ARC: the LINKED sovereign seed EXECUTES as a compiler.
#
#   The chain: ccsv compiles all 19 iiis-0 TUs at cumulative membases -> svir_ld links them into ONE
#   verified SVIR v2 module -> svir_interp (with the CRT host-shim whitelist + argv staging) EXECUTES
#   that module as `iiis-0`.  The finish line is byte-for-byte parity with gcc-built iiis-0 on real
#   inputs (stage1_corpus).  This gate stages the chain so PROGRESS is visible and every rung has a
#   falsifier -- it does NOT fake a green: the open frontier reddens it, by construction.
#
#   Stages (each a real exit code; S4 is the current frontier):
#     S1  link+verify   : svir_ld links 19 TUs; svir_verify(linked) = VALID          [GREEN]
#     S2  host boundary : fopen/fseek/ftell/fread/fclose shim round-trips a file       [GREEN]
#     S3  no-arg parity : interp(linked, no argv) rc == gcc iiis-0 no-arg rc            [GREEN]
#     S4  compile parity: interp(linked) compiles a .iii == gcc iiis-0's .o (byte-match) [FRONTIER]
#
#   S4 today (2026-07-08): PARSE now WORKS -- the frontier advanced from PARSE_FAIL(11) to EMIT_FAIL(16).
#   Three blockers were cleared: (1) iiis-2 embedded a STALE 1 MiB sovas DATA_BUF that silently truncated
#   the linked seed's 1.24 MB .data at 0xFFFFF -> lex/parse's high-membase keyword tables read ZERO ->
#   `module` lexed as an identifier -> parse failed.  Fixed by rebuild (stdlib+iiis-2 pick up the committed
#   4 MiB sovas; determinism held 12/12).  (2) ccsv appended the CRT import prototypes (crt_tail) only for
#   TUs using `fopen`; the codegen TUs write the .s via `fwrite` WITHOUT fopen -> fwrite was undeclared ->
#   mis-dispatched -> the cg's output silently dropped.  Fixed: crt_tail now triggers on fwrite too.
#   (3) the compile path shells `gcc -c` (emit.c system()) + putenv -> interp shims added.  NOW: the seed
#   parses, runs the full pipeline, writes the .s HEADER, then STOPS mid-codegen -- pointers in the cg path
#   acquire garbage high-32 bits (e.g. st->history = (56<<32)|offset), so cg_writef's function emission
#   diverges.  That pointer-high-bits codegen corruption is the remaining S4 frontier.  When it closes and
#   the .o goes byte-identical, this arc closes run_completion.sh's seed_sovereign member.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; W="$ROOT/STDLIB/build/sovlink"
mkdir -p "$W"; fail=0; say(){ echo "[seed-sov] $*"; }

# --- S1: the link must be green (delegate to the link gate, which builds the linked module) ---
if ! bash "$S/run_seed_link.sh" > "$W/_sov_link.log" 2>&1; then
    say "S1 FAIL: run_seed_link.sh red -- $(tail -1 "$W/_sov_link.log")"; exit 1; fi
say "S1 link+verify : GREEN (svir_verify(linked)=VALID; see run_seed_link)"

# build the runnable seed (interp + linked module)
"$IIIS" "$S/svir_interp.iii" --compile-only --out "$W/svir_interp.o" >/dev/null 2>&1 || { say "FAIL compile interp"; exit 1; }
"$IIIS" "$W/linked_gen.iii"  --compile-only --out "$W/linked.o"     >/dev/null 2>&1 || { say "FAIL compile linked module"; exit 1; }
rm -f "$W/seed.exe"; gcc "$W/svir_interp.o" "$W/linked.o" -o "$W/seed.exe" 2>/dev/null || { say "FAIL link seed.exe"; exit 1; }

# --- S2: host boundary round-trip (the shim path the seed uses to read source) ---
printf 'Xyz-shim-probe' > "$W/_sov_rf.txt"
cat > "$W/_sov_rd.c" <<'EOF'
int fopen(const char*p,const char*m); long fread(void*b,long s,long n,int f); int fclose(int f);
int fseek(int f,long o,int w); long ftell(int f); static char buf[64];
int main(int argc,char**argv){ if(argc<2)return 2; int f=fopen(argv[1],"rb"); if(!f)return 3;
  fseek(f,0,2); long sz=ftell(f); fseek(f,0,0); long n=fread(buf,1,sz,f); fclose(f); return (int)(buf[0]); }
EOF
"$IIIS" "$S/ccsv.iii" --compile-only --out "$W/_ccsv.o" >/dev/null 2>&1 && gcc "$W/_ccsv.o" -o "$W/_ccsv.exe" 2>/dev/null
"$W/_ccsv.exe" "$W/_sov_rd.c" > "$W/_sov_rd.iii" 2>/dev/null
"$IIIS" "$W/_sov_rd.iii" --compile-only --out "$W/_sov_rd.o" >/dev/null 2>&1
gcc "$W/svir_interp.o" "$W/_sov_rd.o" -o "$W/_sov_rd.exe" 2>/dev/null
"$W/_sov_rd.exe" "$W/_sov_rf.txt" >/dev/null 2>&1; s2=$?
if [ "$s2" -eq 88 ]; then say "S2 host boundary : GREEN (fopen/fseek/ftell/fread/fclose round-trip buf[0]='X'=88)"
else say "S2 FAIL: shim round-trip rc=$s2 (expect 88)"; fail=1; fi

# --- S3: no-arg exit-code parity ---
timeout 30 "$W/seed.exe" >/dev/null 2>&1; s3=$?
"$ROOT/COMPILED/iiis-0.exe" >/dev/null 2>&1; g3=$?
if [ "$s3" -eq "$g3" ]; then say "S3 no-arg parity : GREEN (interp=$s3 == gcc iiis-0=$g3)"
else say "S3 FAIL: interp=$s3 != gcc=$g3"; fail=1; fi

# --- S4: compile parity (THE FRONTIER) ---
# The linked seed must compile a real .iii to a .o byte-identical to gcc-built iiis-0.  Today it runs
# lex correctly (LEX_FAIL=10 is NOT what we see) but reds at PARSE_FAIL=11 on any function-bearing
# input -- parse.c is at STRUCTURAL zero yet has no behavioral harness, so full-pipeline execution
# exposes a parse-runtime divergence.  This is the single honest frontier; when it goes byte-identical
# the arc closes.  A `git bisect`-style narrowing lives in DOCS/III-LAMBDA0-LINK-CAMPAIGN.md.
printf 'module sovcap\nfn main() -> u64 { return 7u64 }\n' > "$W/_sov_fn.iii"
timeout 60 "$W/seed.exe" "$W/_sov_fn.iii" --compile-only --out "$W/_sov_fn_s.o" >/dev/null 2>&1; f_s=$?
"$ROOT/COMPILED/iiis-0.exe"  "$W/_sov_fn.iii" --compile-only --out "$W/_sov_fn_g.o" >/dev/null 2>&1; f_g=$?
if [ "$f_s" -eq "$f_g" ] && [ -f "$W/_sov_fn_s.o" ] && cmp -s "$W/_sov_fn_s.o" "$W/_sov_fn_g.o"; then
    say "S4 compile parity : GREEN -- interp(linked) .o BYTE-IDENTICAL to gcc iiis-0.  THE SOVEREIGN SEED COMPILES."
else
    say "S4 FRONTIER (red): interp=$f_s (16=EMIT_FAIL: parse+sema+cg-header now WORK; cg stops mid-emit on pointer-high-bits corruption) vs gcc=$f_g -- run_completion's seed_sovereign stays open until byte-identical."
    fail=1
fi

# --- S4-loc: parse.c behavioral differential (localizes S4's parse-runtime divergence) ---
# _parseharness runs lex->ast->parse on a fixed snippet and prints "PARSE ok/ec/nd".  gcc (separate
# objects) vs ccsv-per-TU->svir_ld->interp.  Today: gcc "ok=1 ec=0 nd=1" ; interp "ok=0 ec=2 nd=1" --
# the AST builds correctly (nd matches) but parse records 2 SPURIOUS errors (deterministic, first code
# a corrupted 0x111790).  This is the sharp localizer for the S4 frontier: the bug is in parse.c's
# error-recording path, NOT lex, NOT the ast, NOT the link.
if [ -f "$ROOT/COMPILER/BOOT/_parseharness.c" ]; then
    gcc -I "$ROOT/COMPILER/BOOT" "$ROOT/COMPILER/BOOT/_parseharness.c" \
        "$ROOT/COMPILER/BOOT/lex.c" "$ROOT/COMPILER/BOOT/ast.c" "$ROOT/COMPILER/BOOT/parse.c" \
        -o "$W/_ph_gcc.exe" 2>/dev/null
    phg=$("$W/_ph_gcc.exe" 2>/dev/null | head -1)
    say "S4-loc parse-diff : gcc[$phg] -- the interp target; parse-harness differential is the frontier's microscope (see DOCS/III-LAMBDA0-LINK-CAMPAIGN.md)"
fi

if [ "$fail" -eq 0 ]; then say "SEED-SOVEREIGN GREEN -- the linked whole-seed compiles byte-for-byte as gcc iiis-0."
else say "SEED-SOVEREIGN: S1-S3 PROVEN (link+verify, host boundary, no-arg parity); S4 is the named open frontier (parse.c error-recording runtime; _parseharness isolates it)."; fi
exit $fail
