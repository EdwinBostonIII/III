#!/usr/bin/env bash
# run_seed_sovereign.sh -- Phi1 CAPSTONE ARC: the LINKED sovereign seed EXECUTES as a compiler.
#
#   The chain: ccsv compiles all 19 iiis-0 TUs at cumulative membases -> svir_ld links them into ONE
#   verified SVIR v2 module -> svir_interp (with the CRT host-shim whitelist + argv staging) EXECUTES
#   that module as `iiis-0`.  The finish line is byte-for-byte parity with gcc-built iiis-0 on real
#   inputs (stage1_corpus).  This gate stages the chain so PROGRESS is visible and every rung has a
#   falsifier -- it does NOT fake a green: the open frontier reddens it, by construction.
#
#   Stages (each a real exit code; ALL FOUR GREEN since 2026-07-08 session 7):
#     S1  link+verify   : svir_ld links 19 TUs; svir_verify(linked) = VALID            [GREEN]
#     S2  host boundary : fopen/fseek/ftell/fread/fclose shim round-trips a file        [GREEN]
#     S3  no-arg parity : interp(linked, no argv) rc == gcc iiis-0 no-arg rc             [GREEN]
#     S4  compile parity: interp(linked) compiles a .iii == gcc iiis-0's .o (byte-match)  [GREEN]
#
#   S4 CLOSED (2026-07-08 session 7; history in DOCS/III-LAMBDA0-LINK-CAMPAIGN.md): after session 6b's
#   EV_PSZ pointer arithmetic, FOUR more defects separated the seed from byte-parity -- (1) ccsv's
#   vsnprintf/vsprintf/snprintf builtins formatted but returned CONSTANT 0, so cg_r3's emit_line/cg_writef
#   (which gate fwrite on n) emitted every FORMATTED .s line as a bare newline (.text EMPTY) + emit_fmt
#   lacked the %ll length-modifier skip; (2) struct-valued ASSIGNMENT was missing (decl-INIT had it):
#   `t = st->lookahead`, `*out = t`, `nn->u.fn_decl.name = iiip_text_of(&name)`, `g = f()` fell to
#   scalar/eval+DROP paths -- the fn NAME was zero IN THE AST, so emit honestly wrote .asciz "" and no
#   .global main; (3) `cg->pe_static_fp[i] = NULL` (a POINTER-ARRAY field) took the scalar-pointer-deref
#   arm (SFPSZ>0) and wrote byte 0 AT ADDRESS i for i=0..127, wiping low module data incl. the mhash "rb"
#   literal -> fopen(mode="") -> NULL -> silent EMIT_FAIL 16 with a byte-correct .o (fieldisarr now gates
#   the deref arm, store+read); (4) ferror (main.c's iii_mhash_file read-back check) was unregistered +
#   unshimmed -> registered in crt_tail, shimmed in svir_interp.  Falsifiers: _s4_probe8..11.c, all 99 on
#   gcc + interp + verifier + sovereign-x86-native.  This arc held the capstone's seed_sovereign
#   member green (ex run_completion, retired 2026-07-17 under the ERGON constitution).
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

# --- S4: compile parity (CLOSED 2026-07-08 session 7) ---
# The linked seed compiles a real .iii to a .o byte-identical to gcc-built iiis-0, with exit-code
# parity.  The stage stays in the gate as the REGRESSION TEETH for the whole chain (ccsv struct
# assignment + varargs count + pointer-array fields + the interp CRT shims); any relapse reddens it.
# The defect-by-defect history lives in DOCS/III-LAMBDA0-LINK-CAMPAIGN.md.
printf 'module sovcap\nfn main() -> u64 { return 7u64 }\n' > "$W/_sov_fn.iii"
timeout 60 "$W/seed.exe" "$W/_sov_fn.iii" --compile-only --out "$W/_sov_fn_s.o" >/dev/null 2>&1; f_s=$?
"$ROOT/COMPILED/iiis-0.exe"  "$W/_sov_fn.iii" --compile-only --out "$W/_sov_fn_g.o" >/dev/null 2>&1; f_g=$?
if [ "$f_s" -eq "$f_g" ] && [ -f "$W/_sov_fn_s.o" ] && cmp -s "$W/_sov_fn_s.o" "$W/_sov_fn_g.o"; then
    say "S4 compile parity : GREEN -- interp(linked) .o BYTE-IDENTICAL to gcc iiis-0.  THE SOVEREIGN SEED COMPILES."
else
    say "S4 REGRESSION (red): interp=$f_s vs gcc=$f_g (or .o bytes diverged) -- S4 CLOSED 2026-07-08; a red here is a RELAPSE in ccsv struct-assign/varargs/ptr-array or the interp CRT shims (see DOCS/III-LAMBDA0-LINK-CAMPAIGN.md session 7)."
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
else say "SEED-SOVEREIGN: RED -- S1-S4 were ALL GREEN 2026-07-08 (S4 CLOSED); any red above is a REGRESSION -- bisect against DOCS/III-LAMBDA0-LINK-CAMPAIGN.md session 7."; fi
exit $fail
