# fn-ptr Increment 1 — pre-edit AUDIT (crash-protocol Phase 1/2, 2026-06-30)

**Target:** the seed verify floor's #1 feature-wall = **function pointers** (clears ~13 of the 39:
ast 10 = visitor cluster, +emit `iii_emit_audit`, +parse `witness_sink`/`pratt_trace`). Live floor re-measured = **39**.

## Soundness — INDEX-SPACE AGREEMENT (the named hazard), DISCHARGED by construction
- ccsv assigns a function's index by REGISTRATION ORDER: `rec_fn` (ccsv.iii:1448) does `FNO[FN]=name; FN++`;
  `fidx(name)` (ccsv.iii:186) returns that index; a direct `CALL` emits `eb(0x70) eb(fidx) eb(ac)` (ccsv.iii:826).
- ccsv EMITS functions in registration order: `while k<FN { cfn(k) }` (ccsv.iii:1982) → module position == fidx.
- svir_interp dispatches `exec_fn(i)` via `FN_OFF[i]` (svir_interp.iii:87), i = module position; a direct CALL
  reads its immediate → `exec_fn(fi)` (svir_interp.iii:115). **Every working direct call in the 25-suite already
  proves ccsv.fidx == module-position == interp.exec_fn index.**
- THEREFORE fn-name-as-value → `CONST(fidx(name))` [SAME `fidx()`] + `CALL_INDIRECT` (pop idx → `exec_fn`) dispatches
  to the IDENTICAL function a direct call would. iii_adversarial_verify: SURVIVES-high (unstated hypothesis =
  emission-order==registration-order → discharged @1982; builtin-as-value → guarded below; OOB → interp bounds-checks
  `fi<NFUNC`, svir_interp.iii:123).

## Encoding (matched to the Layer-1 KAT gen_svir_ci.iii): args first, INDEX on top, then `0x73 ac`.

## The two surgical edits (INC-1 = the producer + the consumer; NO typedef/field/backend change)
- A fn-ptr LOCAL/PARAM is ALREADY an 8-byte scalar slot (enum/forward-typedef-local path, fix #22 @ccsv.iii:1168;
  param path @1820) — its value is the index. So INC-1 needs only:
- **EDIT A (consumer, ccsv.iii:826-829 `(`-call block):** when `fidx(t)<0 && lidx(t)>=0` → `emit_lget(lidx);
  eb(0x73); eb(ac)` (args already emitted above @824). Additive: the prior fidx<0 path emitted nothing (underflow).
- **EDIT B (producer, ccsv.iii:918-922 bare-name rvalue):** add `else { if fidx(t)>=0 { econst(fidx) } }` AFTER the
  lidx(local) branch so locals/globals/enums shadow; only a registered USER fn name (fidx>=0) → CONST(index).
  GUARD: builtins (memcpy/…) have fidx<0 → unchanged (still the silent fallthrough, no regression).

## Gates (the falsifiers)
1. **Behavioral + INDEX-AGREEMENT KAT** `_fnptr1.c`: `typedef int (*binop_t)(int,int); add; sub;
   apply(binop_t f,int a,int b){return f(a,b);}  main: binop_t g=add; apply(g,10,4)==14 AND apply(sub,10,4)==6`.
   A SWAP of add/sub indices yields 6/14 → the KAT IS the index-agreement teeth. Gate via svir_verify=0 (structural)
   + svir_interp (runtime value) + sovereign-x86 + wasm + gcc all == the C answer (this is INC-1's all-4 standard;
   x86/wasm computed-call = INC-3, so if a backend can't run 0x73 yet, gate on svir_verify+interp+gcc and note it).
2. **OOB teeth:** gen_svir_ci_oob.iii already → interp returns sentinel not silent fn0.
3. **Floor:** run_seed_verify.sh — ast (10) must DROP (walk_post-class clears); total < 39.
4. **Regression:** run_ccsv.sh 25-suite all green (only pre-existing crosslang=NO red).
5. **Determinism/fixpoint:** ccsv output deterministic; (ccsv is not the self-host compiler, so iiis-2==iiis-3 is
   untouched — ccsv.iii is compiled BY iiis-2, gated by run_ccsv).

## NOT in INC-1 (scoped for INC-2/3, documented so it isn't lost)
- INC-2: field-indirect call `obj.field(args)`/`obj->field(args)` (emit audit_fn, parse witness/pratt, ast walk_state)
  + the fn-ptr-typedef FIELD sizing 4B→8B (ccsv.iii:1685 unrecognized-typedef-field defaults to 4B → struct-layout
  corruption for `iii_ast_visit_fn_t fn;`).
- INC-3: svir_x86 computed-call (dispatch over the fn-offset table) + wasm `call_indirect` + OOB TRAP (hard teeth).
