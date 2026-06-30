# fn-ptr Increment 2 — pre-edit AUDIT (2026-06-30)

**Scope (CORRECTED by decode, not the stale memory):** INC-2 = field-indirect calls. The decode REFUTED "clears the
rest of the ast cluster": `struct iii_ast_walk_state` has NO fn-ptr field, and the 8 remaining ast fns
(zipper_*, walk_state_*, diff_recurse, serialize/deserialize_buf) are struct-by-value/buffer, NOT fn-ptr. The REAL
INC-2 targets are the **3 field-callbacks**: emit `iii_emit_audit` (`G_EMIT.audit_fn(...)` DOT-on-global) + parse
`iiip_witness_sink_emit` (`st->witness_sink(...)` ARROW) + `iiip_parse_expr_prec` (`st->pratt_trace(...)` ARROW).
Expected: seed floor **37 → 34**.

## INC-2a — field-indirect call lowering (THE FLOOR-MOVER)
A fn-ptr field holds a fn-index (8-byte int). `obj->field(args)` / `obj.field(args)`:
- **ARROW** (ccsv.iii ~877, insert at block top): if `C+2` is `(` and `lpt(t)>=0` → it's a field-call. Emit the args
  FIRST, then load the field value with its registered width (`emit_lget(lidx(t)); +fieldoff; eload(fieldelem,sign)`
  = the index), then `CALL_INDIRECT ac`. `return`.
- **DOT** (ccsv.iii ~851, insert at block top): if `C+2` is `(` and `avtype(t)>=0` → field-call. Args first, then
  `emit_vbase(t, fieldoff); eload(fieldelem,sign)` (the field value; emit_vbase handles a global G_EMIT or a
  struct-value base), then `CALL_INDIRECT ac`. `return`.
- **Load the field with its REGISTERED width** (not hard LOAD64): a fn-index is small (<256/module) so even a 4B-sized
  field yields the correct index — the CALL works regardless of the 2b sizing fix. (LOAD64 of a 4B field would read 4
  garbage high bytes → a huge index → OOB. So eload(fieldelem) is the correct, sizing-independent choice.)
- **Soundness:** identical index space as INC-1 (discharged @1480-1482/1982): the field value is a fidx (stored by a
  fn-name→CONST(fidx) field-store, or by an external setter); CALL_INDIRECT → exec_fn(idx). The interp bounds-checks OOB.

## INC-2b — fn-ptr-typedef FIELD sizing 4B→8B (runtime correctness)
reg_fields:1685-1687 sizes a `TypedefName field;` (no `*`) as 4B (enum default). A fn-ptr typedef field
(`iii_emit_audit_fn audit_fn;`) must be 8B, else the AFTER-field (`audit_user`, `witness_sink_ctx`, `pratt_trace_ctx`)
is mis-offset → the call's later args are wrong (runtime, invisible to the structural floor — the INC-1 Edit-A class).
Fix: register fn-ptr typedefs `typedef RET (*NAME)(params);` in the prescan (a FPTD table); reg_fields sizes an
FPTD-typed field 8B. Enum typedefs stay 4B (not in FPTD) → no regression.

## Gates (falsifiers)
- KAT `test_fnptr2.c`: ARROW `b->fn(10,4)` + DOT-on-global `G.fn(20,5)` + add/sub index-agreement teeth + an
  after-field (`b->tag`) to exercise 2b layout → 99 iff call + dispatch + layout all correct. svir_verify=0 +
  svir_interp=99 + gcc=99 (3-oracle, NOT all-4 — x86/wasm computed-call is INC-3). Add to run_fnptr_gate.sh.
- Floor: run_seed_verify 37→34 (emit_audit + witness_sink + pratt_trace clear).
- Regression: run_ccsv 25-suite EXIT=0. Determinism byte-identical. Revert-teeth: revert 2a → the 3 fns fail back +
  KAT verify-fails; revert 2b → KAT runs-wrong on the after-field (interp≠99) but floor stays.
