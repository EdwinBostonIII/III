#!/usr/bin/env bash
# run_ccsv.sh -- the non-gcc C compiler FOUNDATION (ccsv): compile C's integer core to a SOVEREIGN x86 PE (no
# gcc in the artifact path), mini-DDC it against gcc's build of the same C, and show the cross-language byte-DDC
# (ccsv(test.c) == iiisv(indep_toolchain.iii) -- same algorithm, two languages, identical canonical SVIR).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; BOOT="$ROOT/STDLIB/build/_sovboot"; W="$ROOT/STDLIB/build/sovir"
fail=0; say(){ echo "[ccsv] $*"; }
"$IIIS" "$S/ccsv.iii"    --compile-only --out "$W/ccsv.o"    >/dev/null 2>&1 || { say "FAIL compile ccsv"; fail=1; }
"$IIIS" "$S/iiisv.iii"   --compile-only --out "$W/iiisv.o"   >/dev/null 2>&1
"$IIIS" "$S/svir_x86.iii" --compile-only --out "$W/svir_x86.o" >/dev/null 2>&1
gcc "$W/ccsv.o"  -o "$W/ccsv.exe"  2>/dev/null
gcc "$W/iiisv.o" -o "$W/iiisv.exe" 2>/dev/null
# ccsv: real C -> SVIR -> sovereign x86
"$W/ccsv.exe" "$S/test.c" > "$W/gen_csvir.iii" 2>/dev/null
"$IIIS" "$W/gen_csvir.iii" --compile-only --out "$W/gen_csvir.o" >/dev/null 2>&1 || { say "FAIL ccsv output"; fail=1; }
gcc "$W/svir_x86.o" "$W/gen_csvir.o" -o "$W/tx_c.exe" 2>/dev/null; "$W/tx_c.exe" > "$W/c.s" 2>/dev/null
timeout 20 "$BOOT/sovas_main.exe" "$W/c.s" > "$W/c.o2" 2>/dev/null
timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/c.o2" > "$W/c.x86.exe" 2>/dev/null
timeout 10 "$W/c.x86.exe" >/dev/null 2>&1; cv=$?
k=$(objdump -p "$W/c.x86.exe" 2>/dev/null | grep -ic "DLL Name")
# mini-DDC: gcc build of the same C
gcc "$S/test.c" -o "$W/c_gcc.exe" 2>/dev/null; "$W/c_gcc.exe" >/dev/null 2>&1; gv=$?
# cross-language byte-DDC: ccsv(C) vs iiisv(.iii) for the same algorithm
"$W/iiisv.exe" "$ROOT/STDLIB/independence/indep_toolchain.iii" > "$W/_ii.iii" 2>/dev/null
xl="NO"; cmp -s "$W/gen_csvir.iii" "$W/_ii.iii" && xl="YES"
if [ $cv -eq 99 ] && [ $gv -eq 99 ] && [ "$k" = "1" ] && [ "$xl" = "YES" ]; then
  say "ccsv NON-GCC C COMPILER : real C -> SVIR -> x86(sovereign,kernel32-only)=$cv ; mini-DDC gcc=$gv agree ; cross-language byte-DDC ccsv(C)==iiisv(.iii)=$xl.  Foundation for seed-DDC; full iiis-0 C = the long road."
else say "FAIL: ccsv=$cv gcc=$gv dlls=$k crosslang=$xl"; fail=1; fi

# arbitrary-precision: ccsv compiles a C bignum (100! via global array + putchar) -> sovereign x86 -> the 158
# digits, matching the golden AND (content) gcc.  ccsv now handles global arrays, array index, output, and skips
# #preprocessor lines.
"$W/ccsv.exe" "$S/test_bignum.c" > "$W/gen_bnc.iii" 2>/dev/null
"$IIIS" "$W/gen_bnc.iii" --compile-only --out "$W/gen_bnc.o" >/dev/null 2>&1
gcc "$W/svir_x86.o" "$W/gen_bnc.o" -o "$W/tx_bnc.exe" 2>/dev/null; "$W/tx_bnc.exe" > "$W/bnc.s" 2>/dev/null
timeout 20 "$BOOT/sovas_main.exe" "$W/bnc.s" > "$W/bnc.o2" 2>/dev/null
timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/bnc.o2" > "$W/bnc.x86.exe" 2>/dev/null
timeout 10 "$W/bnc.x86.exe" > "$W/out_ccsv.txt" 2>/dev/null; bv=$?
node -e 'let f=1n;for(let i=1n;i<=100n;i++)f*=i;console.log(f.toString())' > "$W/out_gold.txt" 2>/dev/null
gcc "$S/test_bignum.c" -o "$W/bnc_gcc.exe" 2>/dev/null; "$W/bnc_gcc.exe" 2>/dev/null | tr -d '\r' > "$W/out_gcc.txt"
gold="NO"; cmp -s "$W/out_ccsv.txt" "$W/out_gold.txt" && gold="YES"
gccm="NO"; cmp -s "$W/out_ccsv.txt" "$W/out_gcc.txt" && gccm="YES"
if [ $bv -eq 99 ] && [ "$gold" = "YES" ] && [ "$gccm" = "YES" ]; then
  say "ccsv ARBITRARY-PRECISION : C bignum (global array + putchar) -> sovereign x86 prints 100! (158 digits) == golden(node)=$gold == gcc(content)=$gccm -> 99.  ccsv grew: global arrays, indexing, output, #-line skip."
else say "FAIL bignum: exit=$bv golden=$gold gcc=$gccm"; fail=1; fi

# C feature tiers: compile a .c via ccsv -> SVIR -> sovereign x86 + wasm, verifier-accepted, gcc-agreed (all 99).
cfeat(){  # $1 = test file basename (in $S)
  "$W/ccsv.exe" "$S/$1" > "$W/g_$1.iii" 2>/dev/null
  "$IIIS" "$W/g_$1.iii" --compile-only --out "$W/g_$1.o" >/dev/null 2>&1
  gcc "$W/verify_main.o" "$W/svir_verify.o" "$W/g_$1.o" -o "$W/vf_$1.exe" 2>/dev/null; "$W/vf_$1.exe" >/dev/null 2>&1; local vf=$?
  gcc "$W/svir_x86.o" "$W/g_$1.o" -o "$W/tx_$1.exe" 2>/dev/null; "$W/tx_$1.exe" > "$W/$1.s" 2>/dev/null
  timeout 20 "$BOOT/sovas_main.exe" "$W/$1.s" > "$W/$1.o2" 2>/dev/null
  timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/$1.o2" > "$W/$1.x86.exe" 2>/dev/null
  timeout 10 "$W/$1.x86.exe" >/dev/null 2>&1; local x=$?
  gcc "$W/svir_wasm.o" "$W/g_$1.o" -o "$W/tw_$1.exe" 2>/dev/null; "$W/tw_$1.exe" > "$W/$1.wasm" 2>/dev/null
  node "$S/run_wasm.mjs" "$W/$1.wasm" >/dev/null 2>&1; local w=$?
  gcc "$S/$1" -o "$W/gcc_$1.exe" 2>/dev/null; "$W/gcc_$1.exe" >/dev/null 2>&1; local gc=$?
  if [ $vf -eq 99 ] && [ $x -eq 99 ] && [ $w -eq 99 ] && [ $gc -eq 99 ]; then echo "ok"; else echo "FAIL($1 vf=$vf x86=$x wasm=$w gcc=$gc)"; fi
}
rp=$(cfeat test_ptr.c); rs=$(cfeat test_struct.c); rt=$(cfeat test_td.c); re=$(cfeat test_enum.c); ri=$(cfeat main_inc.c); rn=$(cfeat main_nest.c); rr=$(cfeat test_real.c); rw=$(cfeat test_width.c); ra=$(cfeat test_arrinit.c)
rtn=$(cfeat test_ternary.c)
if [ "$rtn" = "ok" ]; then say "ccsv SEED-DDC #1 : ternary ?: (cond?a:b, nested, right-assoc; temp-local lowering keeps the IF void -> x86+wasm+verifier all correct) -> all 99.  First iiis-0 worklist gap closed (ternary: ast.c 55x, sema.c 51x, cg_r3.c 43x)."; else say "FAIL seed-ddc ternary: $rtn"; fail=1; fi
rsz=$(cfeat test_sizeof.c)
if [ "$rsz" = "ok" ]; then say "ccsv SEED-DDC #2 : sizeof (type/typedef/struct/array/array-elem/var; ccsv-consistent sizes).  Gated via SIZE-AGNOSTIC idioms (sizeof(arr)/sizeof(arr[0])=length, sizeof(struct)/sizeof(int)=field-count) that match gcc despite ccsv's i64 model (see GAP-MAP s4) -> all 99.  sizeof pervasive in the seed (ast 47x, emit 30x, parse 29x)."; else say "FAIL seed-ddc sizeof: $rsz"; fail=1; fi
rsa=$(cfeat test_structarr.c)
if [ "$rsa" = "ok" ]; then say "ccsv SEED-DDC #3 : ARRAY STRUCT FIELDS (struct { uint32_t h[8]; uint8_t buf[16]; ... }) -- field byte-size now NUM*elem (reg_type), accessed v.field[i] AND ptr->field[i], cell (8) AND byte (1) elements, load AND store -> all 99.  Unblocks ceiling.c's SHA context (the medium seed file)."; else say "FAIL seed-ddc structarr: $rsa"; fail=1; fi
rct=$(cfeat test_cast.c)
if [ "$rct" = "ok" ]; then say "ccsv SEED-DDC #4 : C casts (type)expr -- i64-noop except NARROWING ((uint8_t)x -> AND 0xFF, (uint32_t)x -> AND 0xFFFFFFFF), pointer casts (no-op), the ceiling.c idiom ((uint32_t)byte<<24).  Cast-vs-paren disambiguation via is_type_start -> all 99."; else say "FAIL seed-ddc cast: $rct"; fail=1; fi
rcp=$(cfeat test_compound.c); rc2=$(cfeat test_compound2.c)
if [ "$rcp" = "ok" ] && [ "$rc2" = "ok" ]; then say "ccsv SEED-DDC #5 : compound assignment (FULL: local x op=e + struct field c->n+=, struct ARRAY field c->h[i]+=a, array elem arr[i]*=, byte array buf[i]|=, pointer p[i]+=) -- emit_av(esz,mask) unifies all 5 store handlers (addr-temp so the lvalue addr is computed once) -> all 99.  Clears ceiling.c's SHA accumulation (c->h[i]+=)."; else say "FAIL seed-ddc compound: local=$rcp field=$rc2"; fail=1; fi
rmc=$(cfeat test_memcpy.c)
if [ "$rmc" = "ok" ]; then say "ccsv SEED-DDC #6 : memcpy builtin (inline byte-copy BLOCK/LOOP -- no libc on the sovereign target) + STRUCT-ARRAY-FIELD DECAY (bare c->buf / v.buf -> &field[0] = ptr+foff, not a load) -> all 99.  Clears ceiling.c's cl_sha_update (memcpy(c->buf+c->buflen, p, take))."; else say "FAIL seed-ddc memcpy: $rmc"; fail=1; fi
rmd=$(cfeat test_multidecl.c)
if [ "$rmd" = "ok" ]; then say "ccsv SEED-DDC #7 : multi-declaration (T a[=e], *p, b[N], c=e ;) -- the int/char decl handler now loops over comma-separated declarators (per-name *, [N] array, = init) -> all 99.  Clears ceiling.c's cl_sha_block (uint32_t a=c->h[0],b=...,h=c->h[7])."; else say "FAIL seed-ddc multidecl: $rmd"; fail=1; fi
rsf=$(cfeat test_seedfeat.c)
if [ "$rsf" = "ok" ]; then say "ccsv SEED-DDC #8 : array PARAMS (T name[N] -> pointer decay) + BRACELESS bodies (for/if/while single stmt, pbody) + SPURIOUS-ARRAY FIX (prescan_arr skips struct bodies + param lists via brace/paren depth, so a local var or param sharing a struct-field name no longer collides with a phantom global array) -> all 99."; else say "FAIL seed-ddc seedfeat: $rsf"; fail=1; fi
rcl=$(cfeat ceiling_sha_core.c)
if [ "$rcl" = "ok" ]; then say "*** ccsv SEED-DDC MILESTONE : REAL iiis-0 seed code -- ceiling.c's UNMODIFIED SHA-256 core (cl_sha_t + CL_K[64] + cl_rotr + cl_sha_init + cl_sha_block, lines 23-69) -> ccsv -> SOVEREIGN x86 + wasm + verifier + gcc, all 99 == SHA-256(\"abc\")=ba7816bf...f20015ad.  The FIRST actual COMPILER/BOOT/*.c file's code compiled correctly through the sovereign path. ***"; else say "FAIL seed-ddc ceiling: $rcl"; fail=1; fi
ral=$(cfeat test_addrlocal.c)
if [ "$ral" = "ok" ]; then say "ccsv SEED-DDC #9 : ADDRESSABLE SCALAR LOCALS (&x of a local) -- per-fn pre-pass marks &-taken names; those locals SPILL to memory (LMEM); reads via emit_lget (LOAD), writes via emit_lset (STORE), &x -> the addr; modify-through-pointer correct.  Byte-identical for non-spilled code (no regression).  Unblocks ceiling.c's cl_sha_final (&pad/&zero/&lenbe)."; else say "FAIL seed-ddc addrlocal: $ral"; fail=1; fi
rcf=$(cfeat ceiling_sha_full.c)
if [ "$rcf" = "ok" ]; then say "*** ccsv SEED-DDC MILESTONE++ : the FULL ceiling.c SHA-256 API (cl_sha_init + cl_sha_update + cl_sha_final, lines 23-96 UNMODIFIED -- &pad/&zero addressable locals, memcpy, field compounds, void* param, casts, braceless bodies) driven init/update/final on \"abc\" -> ccsv -> SOVEREIGN x86 + wasm + verifier + gcc, all 99 == ba7816bf...f20015ad.  A COMPLETE real iiis-0 crypto API through the sovereign path. ***"; else say "FAIL seed-ddc ceiling-full: $rcf"; fail=1; fi
sha=$(cfeat sha256.c); shf=$(cfeat sha256_full.c); shg=$(cfeat sha256_generic.c)
if [ "$sha" = "ok" ] && [ "$shf" = "ok" ] && [ "$shg" = "ok" ]; then say "*** ccsv CAPSTONE : SHA-256 in C -> ccsv -> SOVEREIGN x86(kernel32-only) + wasm + verifier + gcc, all 99.  CORE(\"abc\") + GENERAL multi-block(NIST 2-block) + GENERIC(sha256(msg,len) DYNAMIC padding, 9 input lengths 0..120 spanning every block-count boundary, 18 known-answer tests).  A from-scratch non-gcc C-subset compiler producing a sovereign artifact (no gcc in its path) that computes correct SHA-256 for ARBITRARY-length input, cross-verified vs gcc + wasm + NIST vectors. ***"; else say "FAIL CAPSTONE sha256=$sha sha_full=$shf sha_generic=$shg"; fail=1; fi
cc=$(cfeat chacha20.c); hm=$(cfeat hmac_sha256.c)
if [ "$cc" = "ok" ]; then say "*** ccsv CRYPTO BREADTH : ChaCha20 (RFC 8439 block) in C -> ccsv -> SOVEREIGN x86 + wasm + verifier + gcc, all 99 ; all 16 output words == the RFC vector.  A SECOND, structurally-different primitive (ARX stream cipher, void quarter-round mutating state by index, rotate-LEFT) -- ccsv is a real crypto C compiler, not SHA-specific. ***"; else say "FAIL CRYPTO-BREADTH chacha20: $cc"; fail=1; fi
if [ "$hm" = "ok" ]; then say "*** ccsv CRYPTO COMPOSITION : HMAC-SHA256 (RFC 2104) in C -> ccsv -> SOVEREIGN x86 + wasm + verifier + gcc, all 99 == the RFC 4231 #2 vector (5bdcc146...64ec3843).  COMPOSES the sovereign SHA-256 into a real keyed MAC -- proves TRUE BYTE BUFFERS: uint8_t arrays (stride-1) + uint8_t* byte pointers + array->pointer decay, byte data flowing through functions. ***"; else say "FAIL CRYPTO-COMPOSITION hmac: $hm"; fail=1; fi
aes=$(cfeat aes128.c)
if [ "$aes" = "ok" ]; then say "*** ccsv BLOCK CIPHER : AES-128 (FIPS-197) in C -> ccsv -> SOVEREIGN x86 + wasm + verifier + gcc, all 99 == the FIPS-197 C.1 vector (69c4e0d8...70b4c55a).  Completes the SYMMETRIC SUITE (hash+stream+MAC+block); exercises a 256-byte S-box TABLE (byte-array initializer + lookup by computed index), GF(2^8) MixColumns, the key schedule. ***"; else say "FAIL BLOCK-CIPHER aes128: $aes"; fail=1; fi
if [ "$rp" = "ok" ] && [ "$rs" = "ok" ] && [ "$rt" = "ok" ] && [ "$re" = "ok" ] && [ "$ri" = "ok" ] && [ "$rn" = "ok" ] && [ "$rr" = "ok" ] && [ "$rw" = "ok" ] && [ "$ra" = "ok" ]; then
  say "ccsv C TIERS : arrays+char+pointers + structs + typedef/union/p->f + enum/#define/typedef-ptr + #include + nested/diamond include-once + HEX/for/++/--/static/const/unsigned/stdint (test_real, from real iiis-0 gaps) -> sovereign x86 + wasm + verifier + gcc, all 99."
else say "FAIL tiers: ptr=$rp struct=$rs td=$rt enum=$re include=$ri nest=$rn real=$rr"; fail=1; fi

# string literals: char *s = "..."; s[i] -> sovereign x86 prints the string == gcc's output (content); exit 99.
"$W/ccsv.exe" "$S/test_str.c" > "$W/gen_str.iii" 2>/dev/null
"$IIIS" "$W/gen_str.iii" --compile-only --out "$W/gen_str.o" >/dev/null 2>&1
gcc "$W/svir_x86.o" "$W/gen_str.o" -o "$W/tx_str.exe" 2>/dev/null; "$W/tx_str.exe" > "$W/str.s" 2>/dev/null
timeout 20 "$BOOT/sovas_main.exe" "$W/str.s" > "$W/str.o2" 2>/dev/null
timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/str.o2" > "$W/str.x86.exe" 2>/dev/null
timeout 10 "$W/str.x86.exe" > "$W/out_str.txt" 2>/dev/null; sv=$?
gcc "$S/test_str.c" -o "$W/str_gcc.exe" 2>/dev/null; "$W/str_gcc.exe" > "$W/_sg.txt" 2>/dev/null; sg=$?; tr -d '\r' < "$W/_sg.txt" > "$W/out_str_gcc.txt"
scon="NO"; cmp -s "$W/out_str.txt" "$W/out_str_gcc.txt" && scon="YES"
if [ $sv -eq 99 ] && [ $sg -eq 99 ] && [ "$scon" = "YES" ]; then
  say "ccsv STRING LITERALS : char *s=\"...\"; s[i] -> sovereign x86 prints [$(cat "$W/out_str.txt" | tr -d '\n')] == gcc(content)=$scon -> 99.  BYTE-PACKED via a SVIR DATA SECTION (real C layout, initialised memory) + char* stride-1 LOAD8."
else say "FAIL string: sovereign=$sv gcc=$sg content=$scon"; fail=1; fi
exit $fail
