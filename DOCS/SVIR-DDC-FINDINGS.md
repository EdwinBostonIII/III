# SVIR DDC/Formalization — Task 1 Findings (verify-before-scope)

Date 2026-06-23. All foundations verified GREEN before scoping the build. Read-only; no organ assumed general
without reading its source/API.

## 1.1 — `zk_air` is a GENERAL AIR prover (confirmed by header AND public API)

`STDLIB/iii/numera/zk_air.iii` header: "the general AIR composition organ… Generalizes zk_stark's hard-wired
demo into a DATA-DRIVEN constraint system: W columns, a list of degree-≤2 transition constraints, and boundary
constraints — so the STARK can prove arbitrary low-degree constraint systems, not one toy recurrence."

Public API (data-driven — a caller supplies an arbitrary trace + constraints):
- `air_reset(w_cols, n_rows)` — declare a W×N trace.
- `air_set_trace(row, col, v)` / `air_get_trace(row, col)` — fill arbitrary trace cells.
- `air_add_term(con, coeff, var_a, var_b)` — add a degree-≤2 term to constraint `con` (var: 0=const1, 1..W=cur
  row col, W+1..2W=next row col).
- `air_set_alpha(con, a)` — Fiat-Shamir random combiner.
- `air_add_boundary(col, row, value)` — boundary constraints.
- `air_build_lde()` / `air_build_cp()` — low-degree extension + composition polynomial over the shared NTT.
- `air_constraints_hold()` / `air_cp_consistent_at(j)` / `air_set_open` / `air_combine_opened(w_cols)` — the FRI
  open/verify surface. Field GF(998244353), FRI, Merkle commitments, Fiat-Shamir, written soundness proof.

**Implication:** "ZK-prove SVIR execution" = arithmetize the SVIR ISA as an AIR (columns = VM state stack/locals/
pc; rows = steps; `air_add_term` = per-opcode degree-≤2 transition constraints; `air_add_boundary` = input/output
pins), then `air_build_*` + prove. APPLYING this general organ, not building a prover. The ZK phase-after (Part IV
of the plan) is reachable and bounded. Caveat retained: a constraint bug = an unsound proof → RED-prove the
negative (a wrong trace MUST be rejected by `air_constraints_hold`).

## 1.2 — `eidos/ripple` is a genuine fold log (not a sketch)

`STDLIB/iii/eidos/ripple.iii` (110 L) ENCAPSULATES (drives, does not reimplement) `ripple_field` (spatial
gradient) + `isub` (the content-addressed event bus). It exposes a real append-only event log:
`eidos_ripple_emit(<verb,a,b>)` appends; `eidos_ripple_count/event_verb/a/b` read it (the fold inputs);
`isub_cav_into` = `sha256(verb‖a‖b)` content-address per block; `eidos_ripple_witness_into` = a witness over the
whole log. Real content-addressed append-only log with a witness — the log-fold-state primitive, POC-scale but
genuine. (verbs: V_BELOW/V_REFLECT real directions, V_NONE = flat = no ripple, rejected.)

## 1.3 — `iiisv` output is DETERMINISTIC (DDC foundation sound)

`iiisv X.iii` run twice, `cmp` identical, for all three real programs:
- `indep_toolchain` : 1321 bytes, identical ×2.
- `indep_ops` : 893 bytes, identical ×2.
- `indep_bignum` : 2484 bytes, identical ×2.

Byte-stable → a second emitter (`iiisv2`) byte-comparing against `iiisv` is well-founded (Task 4/5).

## 1.4 — `iiisv`'s de-facto canonical lowering choices (inputs to Task 2's spec)

- **Function order:** `main` first (SVIR func 0 = the entry), then the remaining functions in source order.
- **Local slots:** params first (slots `0..params-1`, declaration order), then `let`s in declaration order.
- **Constants:** `CONST_I64 = 0x01` + 8-byte little-endian immediate.
- **`while c { b }`:** `BLOCK; LOOP; <c>; CONST 0; EQ; BR_IF 1; <b>; BR 0; END; END` (break when `c==0`).
- **`if c {t} else {e}`:** `<c>; IF; <t>; ELSE; <e>; END` (ELSE omitted when no else).
- **Module arrays:** `var d:[u8;N]` assigned a cumulative base offset in SVIR linear memory; `d[i]` →
  `<i>(; CONST base; ADD if base>0); LOAD8`; `d[i]=e` → `<i>(+base); <e>; STORE8`.
- **Module format:** `[u8 func_count]` then per-func `[u8 params][u8 nresults=1][u16 LE body_len][body]`.

## Verdict

All three pillars touched this task are real: ZK prover general (ZK phase viable), ripple a real fold (log-fold
viable), iiisv deterministic (DDC viable). Proceed to Task 2 (freeze the canonical SVIR v1 encoding) on this
basis. No TOY-TRAP: each fact was read from source/API or measured, not assumed.
