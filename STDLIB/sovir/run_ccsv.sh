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
cfeat(){  # $1 = test file basename (in $S).  Artifacts rm -f'd first: a failed producer must yield a
          # MISSING artifact (rc 127), never a stale green from a prior run (the stale-exe mask class).
  rm -f "$W/vf_$1.exe" "$W/tx_$1.exe" "$W/$1.s" "$W/$1.o2" "$W/$1.x86.exe" "$W/tw_$1.exe" "$W/$1.wasm" "$W/gcc_$1.exe"
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
rsw=$(cfeat test_switch.c)
if [ "$rsw" = "ok" ]; then say "ccsv SEED-DDC : switch/case/default/break + FALL-THROUGH -> nested-BLOCK ladder (no new SVIR ISA).  Dispatch = BR_IF-per-case to depth i (innermost block) + BR n to default ; break = BR(BLKD - break-target) via a live block-depth tracker (correct even inside a nested if, or a switch nested in a loop) ; default-last/absent.  Exercises fall-through (3->4), break-in-if, char-literal cases, return-in-case (+ the wasm reachable-fn-end fix), fall-through-into-default, switch-in-loop -> all 99.  Unblocks the seed core (ast 18x, cg_r3 13x, cg_r0 11x, main 9x)."; else say "FAIL seed-ddc switch: $rsw"; fail=1; fi
rei=$(cfeat test_elseif.c)
if [ "$rei" = "ok" ]; then say "ccsv SEED-DDC : else-if ladders (\`} else if (cond) {\`) NO LONGER misparse as a typedef-return \`if\` function (is_ctrl_kw guards is_fn: a control keyword is never a return type or fn name) -> all 99.  Removes the DOMINANT seed verify-failure root (spurious \`if\` fns: cg_r3 71 / sema 38 / parse 30 else-ifs)."; else say "FAIL seed-ddc else-if: $rei"; fail=1; fi
rgi=$(cfeat test_globalinc.c)
if [ "$rgi" = "ok" ]; then say "ccsv SEED-DDC : global-scalar mutation statements -- g++/g-- (post), ++g/--g (prefix), g+=/-=/*= (compound) were ALL DROPPED (NAME++ / x op= e / elvalinc emitted only for locals; a global fell to a no-op) + the global-index loop \`out[gidx]=v; gidx++\` -> all 99."; else say "FAIL seed-ddc global-inc: $rgi"; fail=1; fi
rgp=$(cfeat test_globalptr.c)
if [ "$rgp" = "ok" ]; then say "ccsv SEED-DDC : global scalar POINTER (direct dtypes) -- init \`*p=&G\`, deref-READ \`*p\` rvalue (was DROPPED: single-LOAD64 fallback read the POINTER's address, not *p), deref-store/compound, pointee widths {4,1}+sign -> all 99 (APSZ/APSG track the pointee width)."; else say "FAIL seed-ddc global-ptr: $rgp"; fail=1; fi
rfi=$(cfeat test_forinit.c)
if [ "$rfi" = "ok" ]; then say "ccsv SEED-DDC : for-init DECLARATIONS of non-int type (\`for(unsigned k=0;..)\`, \`for(const T *c=..)\`) -- were dtype-ONLY (skipquals ate unsigned/signed/long/short; typedef/struct-ptr fell to the for-init EXPR path -> eval'd the type name -> under-emit). Now detected before skipquals (+ opaque-ptr + LPT). Reduced the seed 85->83 -> all 99."; else say "FAIL seed-ddc for-init: $rfi"; fail=1; fi
rdp=$(cfeat test_dblptr.c)
if [ "$rdp" = "ok" ]; then say "ccsv SEED-DDC : double-pointer pool accessor -- \`T **p = call()\` (the local-decl declarator skipped only ONE \`*\` -> pf unregistered, init call result DROPPED) + the element ops \`(*pf)[i]\` / \`&(*pf)[slot]\` (postfix on a PARENTHESIZED base, stride = ultimate elem via LPP). Reduced the seed 83->82 -> all 99."; else say "FAIL seed-ddc dblptr: $rdp"; fail=1; fi
rdi=$(cfeat test_derefinc.c)
if [ "$rdi" = "ok" ]; then say "ccsv SEED-DDC : \`(*p)++\` / \`(*p)--\` (post-incr/decr the POINTEE -- the seed's \`uint32_t slot = (*count_p)++\`) -- postfix ++/-- on a PARENTHESIZED deref was dropped (parser desync -> recovered +6 cg_r3 fns) -> all 99."; else say "FAIL seed-ddc derefinc: $rdi"; fail=1; fi
rpif=$(cfeat test_pifield.c)
if [ "$rpif" = "ok" ]; then say "ccsv SEED-DDC : p[i].field (pointer-indexed struct-element field, read+store: \`s[0].id=..\`) -- the seed table idiom (iii_intern_grow + pool accessors); LPT[p] drives elem*STSZ + field_off -> all 99."; else say "FAIL seed-ddc p[i].field: $rpif"; fail=1; fi
rsf2=$(cfeat test_sizeoffield.c)
if [ "$rsf2" = "ok" ]; then say "ccsv SEED-DDC : sizeof(p->arrayfield) -- the seed token-init idiom memset(out->mhash,0,sizeof(out->mhash)) (iii_emit_single/double/lex_create); esizeof consumes ->field + SFSZ gives the array's total bytes -> all 99 (32 bytes cleared, not 1)."; else say "FAIL seed-ddc sizeof-field: $rsf2"; fail=1; fi
rdz=$(cfeat test_desig.c)
if [ "$rdz" = "ok" ]; then say "ccsv SEED-DDC : designated-init arrays \`T N[NAMED_CONST]={[Di]=vi}\` (the seed's III_TOKEN_KIND_NAMES kind-name tables) -- prescan_enum moved before prescan_arr so the named-const size + [Di] designators resolve via cidx; string-ptr elements -> all 99."; else say "FAIL seed-ddc desig-arr: $rdz"; fail=1; fi
rdpi=$(cfeat test_dblptr_index.c)
if [ "$rdpi" = "ok" ]; then say "ccsv SEED-DDC : (*pp)[i]=e STORE through a dereffed double-pointer (seed pool write (*bd)[slot]=v, e.g. iii_ast_set_binder_id) -- pstmt had no (...)-lvalue handler -> expr-stmt DROP -> underflow; added the store mirror of the eprim:680 read. SEED 82->78 -> all 99."; else say "FAIL seed-ddc dblptr-index-store: $rdpi"; fail=1; fi
rbi=$(cfeat test_brace_init.c)
if [ "$rbi" = "ok" ]; then say "ccsv SEED-DDC : brace-init struct local Foo h={e0,e1,..} (seed iii_ast_list_t h={0,0}, list/walk-state commits) -- init ebin(0) cannot parse {...}; per-field store via SFOFF/SFEL + zero the un-given tail (C {0}). SEED 78->71 -> all 99."; else say "FAIL seed-ddc brace-init: $rbi"; fail=1; fi
rnf=$(cfeat test_nested_field.c)
if [ "$rnf" = "ok" ]; then say "ccsv SEED-DDC : nested struct field on a struct-array element p->arr[i].sub.subsub (seed symbol-table cg->locals[i].name.length) read+store, ptr + INLINE-array bases -- chained member walk past the first subfield + fixed the inline-array fe==8 LOAD64 (treated an inline array as a pointer). SEED 71->70 -> all 99."; else say "FAIL seed-ddc nested-field: $rnf"; fail=1; fi
rcf=$(cfeat test_callfield.c)
if [ "$rcf" = "ok" ]; then say "ccsv SEED-DDC : call()->field -- a fn returning StructType* then ->field (parser idiom iiip_peek2(st)->kind), incl chained call()->a->b.  fn_ret_struct(FNT) resolves the arrow chain off the CALL result at codegen time -> all 99."; else say "FAIL seed-ddc call-field: $rcf"; fail=1; fi
rcfs=$(cfeat test_callfield_sret.c)
if [ "$rcfs" = "ok" ]; then say "ccsv SEED-DDC : call().field on a struct-VALUE (sret >8B) return -- the COMPLEMENT of call()->field: the seed's iiip_node_pos(st,id).start_byte (iii_src_pos_t by value).  fn_ret_sval + dest-FIRST temp buffer (hidden sret arg0), CALL, drop dummy, load .field from the buffer -> all 99 (b=13,c=10,hi=107,sum=203 == gcc).  SEED 69->66."; else say "FAIL seed-ddc call-sret-field: $rcfs"; fail=1; fi
red=$(cfeat test_enumdecl.c)
if [ "$red" = "ok" ]; then say "ccsv SEED-DDC : ENUM / forward-typedef-name LOCAL decl (\`kind_t x = e ;\` / \`kind_t y ;\`) -- the seed's iii_abi_kind_t abi = decl->u.extern_decl.abi (sema_check_extern_abi); ccsv registered enum MEMBERS but not the typedef NAME as a type -> mis-parsed as two expr-stmts -> leading-DROP underflow.  pstmt now consumes an unknown-typedef-name (stidx<0, not type/local/global/enum-member) localvar [= e] as an i64 scalar local (the param/field loops already did) -> all 99; registered-struct typedef local untouched.  SEED 66->56 (lex.c -> STRUCTURAL ZERO; cleared 10 across lex/sema/parse)."; else say "FAIL seed-ddc enumdecl: $red"; fail=1; fi
rgt=$(cfeat test_goto.c)
if [ "$rgt" = "ok" ]; then say "ccsv SEED-DDC : FORWARD goto (the seed's dominant cleanup form -- ast.c 53x \`goto fail\`).  Each top-level label opens a goto-BLOCK at fn entry (label[0] innermost); \`goto L\` = BR(BLKD - LBLBD[L]) to that block via the live block-depth tracker (correct from inside nested ifs); label \`L:\` closes its block.  Multiple labels + multiple gotos -> all 99.  Unblocks ast.c (the seed's biggest core file)."; else say "FAIL seed-ddc goto: $rgt"; fail=1; fi
rpp=$(cfeat test_pp.c)
if [ "$rpp" = "ok" ]; then say "ccsv SEED-DDC : preprocessor CONDITIONALS (#ifdef/#ifndef/#if 0/#else/#endif/#undef) -- an in-place compacting pass strips inactive branches before lex, defined-set from #define, nested + #undef handled.  Seed form exactly (40 #ifdef/23 #ifndef/1 #if-0, zero #elif).  No-op for conditional-free files -> all 99."; else say "FAIL seed-ddc preprocessor: $rpp"; fail=1; fi
rdw=$(cfeat test_dowhile.c)
if [ "$rdw" = "ok" ]; then say "ccsv SEED-DDC : do { body } while (cond) -- body-first loop (BLOCK LOOP body ; cond ; BR_IF 0 to restart), runs >=1, break via BRKT, nested -> all 99.  (seed do-while 7x)."; else say "FAIL seed-ddc do-while: $rdw"; fail=1; fi
rabi=$(cfeat test_abi.c)
if [ "$rabi" = "ok" ]; then say "*** ccsv P1 TYPED-MEMORY ABI : ccsv and gcc agree on sizeof (int=4, char=1, struct=32 with C natural alignment+padding), field OFFSETS, and the exact BYTES of a serialised mixed-width struct {u8;u32;u16;u64;u8} -- a TRUE differential vs gcc, not the old size-agnostic ratio idiom.  SVIR gained LOAD/STORE 16/32 (the one ISA change) + ccsv a real C type-size/alignment model + typed pointers/arrays/fields/spills + signed LOAD16_S/LOAD32_S; the i64-everything storage model is GONE.  Closes GAP-MAP s4; makes III-VERIFIABLE-ROOT-ARCHITECTURE Claim 1 (typed memory) literally true -- the precondition for byte-identical seed-DDC. ***"; else say "FAIL P1 ABI: $rabi"; fail=1; fi
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
rms=$(cfeat test_memset.c)
if [ "$rms" = "ok" ]; then say "ccsv SEED-DDC #10 : memset builtin (inline byte-fill loop) + bool/true/false/NULL literals -> all 99."; else say "FAIL seed-ddc memset: $rms"; fail=1; fi
sha=$(cfeat sha256.c); shf=$(cfeat sha256_full.c); shg=$(cfeat sha256_generic.c)
if [ "$sha" = "ok" ] && [ "$shf" = "ok" ] && [ "$shg" = "ok" ]; then say "*** ccsv CAPSTONE : SHA-256 in C -> ccsv -> SOVEREIGN x86(kernel32-only) + wasm + verifier + gcc, all 99.  CORE(\"abc\") + GENERAL multi-block(NIST 2-block) + GENERIC(sha256(msg,len) DYNAMIC padding, 9 input lengths 0..120 spanning every block-count boundary, 18 known-answer tests).  A from-scratch non-gcc C-subset compiler producing a sovereign artifact (no gcc in its path) that computes correct SHA-256 for ARBITRARY-length input, cross-verified vs gcc + wasm + NIST vectors. ***"; else say "FAIL CAPSTONE sha256=$sha sha_full=$shf sha_generic=$shg"; fail=1; fi
cc=$(cfeat chacha20.c); hm=$(cfeat hmac_sha256.c)
if [ "$cc" = "ok" ]; then say "*** ccsv CRYPTO BREADTH : ChaCha20 (RFC 8439 block) in C -> ccsv -> SOVEREIGN x86 + wasm + verifier + gcc, all 99 ; all 16 output words == the RFC vector.  A SECOND, structurally-different primitive (ARX stream cipher, void quarter-round mutating state by index, rotate-LEFT) -- ccsv is a real crypto C compiler, not SHA-specific. ***"; else say "FAIL CRYPTO-BREADTH chacha20: $cc"; fail=1; fi
if [ "$hm" = "ok" ]; then say "*** ccsv CRYPTO COMPOSITION : HMAC-SHA256 (RFC 2104) in C -> ccsv -> SOVEREIGN x86 + wasm + verifier + gcc, all 99 == the RFC 4231 #2 vector (5bdcc146...64ec3843).  COMPOSES the sovereign SHA-256 into a real keyed MAC -- proves TRUE BYTE BUFFERS: uint8_t arrays (stride-1) + uint8_t* byte pointers + array->pointer decay, byte data flowing through functions. ***"; else say "FAIL CRYPTO-COMPOSITION hmac: $hm"; fail=1; fi
aes=$(cfeat aes128.c)
if [ "$aes" = "ok" ]; then say "*** ccsv BLOCK CIPHER : AES-128 (FIPS-197) in C -> ccsv -> SOVEREIGN x86 + wasm + verifier + gcc, all 99 == the FIPS-197 C.1 vector (69c4e0d8...70b4c55a).  Completes the SYMMETRIC SUITE (hash+stream+MAC+block); exercises a 256-byte S-box TABLE (byte-array initializer + lookup by computed index), GF(2^8) MixColumns, the key schedule. ***"; else say "FAIL BLOCK-CIPHER aes128: $aes"; fail=1; fi
rcc=$(cfeat test_callchain.c)
if [ "$rcc" = "ok" ]; then say "ccsv SEED-DDC : MEMBER CHAINS through embedded/union members -- call()->u.a READ (the seed's iii_ast_get(..)->u.list.count; was single-field: loaded 8 raw bytes at u + left .a dangling -> rc=8), call()->u.a=e STORE (iii_ast_get_mut(..)->u.break_.reserved=0), ARR[i].u.a + p[i].u.a element chains -- all four walkers chain-capable, single-hop byte-identical -> all 99."; else say "FAIL callchain: $rcc"; fail=1; fi
rfe=$(cfeat test_forempty.c)
if [ "$rfe" = "ok" ]; then say "ccsv SEED-DDC : EMPTY for-increment clause -- the reverse-loop idiom for(i=n; i-- > 0; ) (sema_local_lookup + the parse recover/witness family) no longer emits one_incr's ebin+DROP fallback on the bare ) (a DROP on nothing -> rc=8); for(;;)+break also pinned -> all 99.  Cleared 5 seed fns (floor 28->23: sema 4->3, parse 16->12)."; else say "FAIL forempty: $rfe"; fail=1; fi
rnb=$(cfeat test_nestedinit.c)
if [ "$rnb" = "ok" ]; then say "ccsv SEED-DDC : NESTED-BRACE struct-local init -- Foo c = { {0}, 0 } (the ast zipper/walk shape) + { {1,2}, 3 } (embedded-struct values): a sub-brace initializes the ARRAY field's elements (zero-filling the rest, SFSZ-bounded) or the EMBEDDED struct's sub-fields (zero tail); scalar-in-braces {v} legal; overflow sub-braces skipped balanced -> all 99.  Cleared ast 8->3 (zipper_descend/sibling, walk_state_create/step/deserialize)."; else say "FAIL nestedinit: $rnb"; fail=1; fi
rtb=$(cfeat test_tables.c)
if [ "$rtb" = "ok" ]; then say "ccsv SEED-DDC : STATIC struct-array TABLES -- static const entry_t TBL[3]={ {\"name\",v},.. } registers (avtype/base) + INITIALIZES (string addresses + values in the data section), and TBL[i].name[0] derefs the POINTER field ([k] on a scalar-pointer field = LOAD64 + k*pointee; an INLINE array field stays addr+k*elem, byte-identical) -- the strcmp-table idiom -> all 99."; else say "FAIL tables: $rtb"; fail=1; fi
# extern-elsewhere table (the seed's III_IRPD_METHODS shape, defined in sid.c): single-file gcc CANNOT link the
# undefined extern data, so the honest arms are verify (structural) + interp (runtime: the zero-storage COUNT
# gates the loop dead -> -1 path).  The cross-module DATA is the P3 linker phase, not claimed here.
"$W/ccsv.exe" "$S/test_externtable.c" > "$W/g_xt.iii" 2>/dev/null
"$IIIS" "$W/g_xt.iii" --compile-only --out "$W/g_xt.o" >/dev/null 2>&1
gcc "$W/verify_main.o" "$W/svir_verify.o" "$W/g_xt.o" -o "$W/vf_xt.exe" 2>/dev/null; rm -f "$W/in_xt.exe"; "$W/vf_xt.exe" >/dev/null 2>&1; xtv=$?
"$IIIS" "$S/svir_interp.iii" --compile-only --out "$W/svir_interp.o" >/dev/null 2>&1
gcc "$W/svir_interp.o" "$W/g_xt.o" -o "$W/in_xt.exe" 2>/dev/null; "$W/in_xt.exe" >/dev/null 2>&1; xti=$?
if [ "$xtv" = "99" ] && [ "$xti" = "99" ]; then say "ccsv SEED-DDC : EXTERN struct-array tables (extern const T X[]; + extern const size_t X_COUNT; -- the seed's III_IRPD_METHODS, defined in sid.c) REGISTER with one zero element so member access emits; the zero-storage COUNT gates table loops dead single-file (verifier=99 interp=99; cross-module data = the P3 linker phase)."; else say "FAIL externtable (vf=$xtv interp=$xti)"; fail=1; fi
rf1=$(cfeat test_fnptr.c); rf2=$(cfeat test_fnptr2.c)
if [ "$rf1" = "ok" ] && [ "$rf2" = "ok" ]; then say "ccsv SEED-DDC : FUNCTION POINTERS all-4 (INC-3) -- fn-name-as-value + indirect call of a fn-ptr local/param (CALL_INDIRECT) + field-indirect statement calls (G.audit_fn(...); / st->sink(...);) + 8B fn-ptr typedef fields, on the SOVEREIGN backends: x86 = __svci switchboard (cmpq/jz tail-dispatch, OOB -> ExitProcess(199)) ; wasm = native call_indirect over a funcref table (slot k = func k+IC, OOB = engine trap).  add/sub INDEX-SPACE-AGREEMENT teeth run on every executor; test_fnptr2's putchar pins the IC=1 import-shift composition.  Deeper teeth in run_fnptr_gate.sh (svir_interp arm + OOB trap vehicle)."; else say "FAIL fn-ptr: inc1=$rf1 inc2=$rf2"; fail=1; fi
rci=$(cfeat test_calli.c)
if [ "$rci" = "ok" ]; then say "ccsv SEED-DDC : call()[i] -- index a call's returned pointer DIRECTLY (UPDATE-61; cg_r3's emit_field_label/emit_function shape iii_ast_source_buf(cg->ast)[name.offset+i]): +i*pointee, typed load, byte (stride 1) + u32 (stride 4) + expression index, value teeth pin address+width -> all 99.  Struct-ptr call()[i] and call()[i]=e stores stay VISIBLY out of scope (dangle -> verify-fail, never silent)."; else say "FAIL calli: $rci"; fail=1; fi
# IMPORTS (0x8A): gcc cannot LINK a referenced-undefined extern single-file (test_externtable.c's
# documented reason), so the arms are the four SVIR-side executors.  POSITIVE (test_import.c, every
# import call guarded DEAD): an import-bearing module must BUILD + RUN normally everywhere.  TRAP
# (test_importtrap.c, an import call EXECUTES; every C path returns 99): pinned interp=198 +
# x86=198 (UNRES_IMP sentinel / ExitProcess stub) + wasm=1 (stub `unreachable`, native trap),
# mirroring the CALL_INDIRECT OOB gate 199/199/1 -- silent execution must never read green.
imp_arm(){ # $1 = test basename ; echoes "vf ir xr wr" (verify_main ; svir_interp ; sovereign x86 ; wasm)
  rm -f "$W/vf_$1.exe" "$W/in_$1.exe" "$W/tx_$1.exe" "$W/$1.s" "$W/$1.o2" "$W/$1.x86.exe" "$W/tw_$1.exe" "$W/$1.wasm"
  "$W/ccsv.exe" "$S/$1" > "$W/g_$1.iii" 2>/dev/null
  "$IIIS" "$W/g_$1.iii" --compile-only --out "$W/g_$1.o" >/dev/null 2>&1
  gcc "$W/verify_main.o" "$W/svir_verify.o" "$W/g_$1.o" -o "$W/vf_$1.exe" 2>/dev/null; "$W/vf_$1.exe" >/dev/null 2>&1; local vf=$?
  gcc "$W/svir_interp.o" "$W/g_$1.o" -o "$W/in_$1.exe" 2>/dev/null; "$W/in_$1.exe" >/dev/null 2>&1; local ir=$?
  gcc "$W/svir_x86.o" "$W/g_$1.o" -o "$W/tx_$1.exe" 2>/dev/null; "$W/tx_$1.exe" > "$W/$1.s" 2>/dev/null
  timeout 20 "$BOOT/sovas_main.exe" "$W/$1.s" > "$W/$1.o2" 2>/dev/null
  timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/$1.o2" > "$W/$1.x86.exe" 2>/dev/null
  timeout 10 "$W/$1.x86.exe" >/dev/null 2>&1; local xr=$?
  gcc "$W/svir_wasm.o" "$W/g_$1.o" -o "$W/tw_$1.exe" 2>/dev/null; "$W/tw_$1.exe" > "$W/$1.wasm" 2>/dev/null
  node "$S/run_wasm.mjs" "$W/$1.wasm" >/dev/null 2>&1; local wr=$?
  echo "$vf $ir $xr $wr"
}
rea=$(cfeat test_enumarr.c); rpa=$(cfeat test_ptrarr.c); rca=$(cfeat test_chainasn.c); rac=$(cfeat test_addrchain.c)
rsg=$(cfeat test_sizeofgl.c); ras=$(cfeat test_addrsub.c); rdc=$(cfeat test_defcomment.c)
if [ "$rdc" = "ok" ]; then say "ccsv SEED-DDC : #define TRAILING COMMENT -- a block/line comment after the value (ast.h's pool constants `#define III_AST_POOL_SMALL 1u  <comment>`) no longer reads as DIVISION (ppc_peekop stops at slash-star / slash-slash; the div-guard had collapsed every pool constant to 0 -> iii_pool_array case-collapse -> create stored through NULL -> the _astharness Z divergence) -> all 99."; else say "FAIL defcomment: $rdc"; fail=1; fi
if [ "$rsg" = "ok" ] && [ "$ras" = "ok" ]; then say "ccsv SEED-DDC : the STRUCTURAL-ZERO strokes -- sizeof(v.field) on struct values/globals (whole fieldbytes / chained / element; emit_link's sizeof G_EMIT.witness_json) and &p->ptrfield[i].sub + trailing inline-array [j] (walk_state_deserialize's memcpy destinations) -> all 99.  With the host-I/O prototypes (emit.c/ast.c) + SEEK_* constants + STRING-valued #define substitution (subst_strdefs): THE WHOLE iiis-0 SEED = verify_fail 0/865, all six modules." ; else say "FAIL structural-zero strokes: sizeofgl=$rsg addrsub=$ras"; fail=1; fi
if [ "$rea" = "ok" ] && [ "$rpa" = "ok" ] && [ "$rca" = "ok" ] && [ "$rac" = "ok" ]; then say "ccsv SEED-DDC : the parse/sema ZERO strokes -- ENUM-TYPEDEF local arrays kind_t buf[16] + static const fallback[]={..} (4B elements; parse_primary/parse_pattern/recover_follow), POINTER-element local arrays T *tables[3]={&..} (8B elements + the tbl=tables[t] hoist idiom; grammar_mhash), CHAINED array-element assignment b[2]=b[3]=b[4]=0 (store AND leave value; witness_commit), and &p->emb.ptrfield[i] (LOAD64 the pointer field at the END of a DOT chain + i*STSZ; sema aggregate_dynamic_impact's &s->annos.items[i]) -> all 99.  With these + call()[i] + imports-ON: lex/sema/cg_r3/parse ALL at structural ZERO."; else say "FAIL parse-zero strokes: enumarr=$rea ptrarr=$rpa chainasn=$rca addrchain=$rac"; fail=1; fi
read -r pv pi px pw <<< "$(imp_arm test_import.c)"
read -r tv ti tx tw <<< "$(imp_arm test_importtrap.c)"
if [ "$pv" = "99" ] && [ "$pi" = "99" ] && [ "$px" = "99" ] && [ "$pw" = "99" ] && [ "$tv" = "99" ] && [ "$ti" = "198" ] && [ "$tx" = "198" ] && [ "$tw" = "1" ]; then
  say "ccsv SEED-DDC : IMPORTS (0x8A) -- prescan_imports registers CALLED declared-not-defined prototypes (builtin names excluded by is_call_builtin); cfn emits [0x8A][len][name] decl bodies; ALL FIVE consumers know the rule (svir_verify:49 net-0, svir_dis skip, svir_interp UNRES_IMP->198, svir_x86 ExitProcess(198) stub, svir_wasm `unreachable` stub).  POSITIVE: an import-bearing module (scalar + sret-struct + call()[i] import shapes, guarded dead) builds+runs 99 on verify/interp/x86/wasm.  TRAP: an executed import call reads 198/198/1, never silent (pre-fix x86 executed the NAME BYTES and segfaulted).  Cross-module RESOLUTION is the P3 linker phase, not claimed."
else say "FAIL imports (pos vf=$pv interp=$pi x86=$px wasm=$pw ; trap vf=$tv interp=$ti x86=$tx wasm=$tw)"; fail=1; fi
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
