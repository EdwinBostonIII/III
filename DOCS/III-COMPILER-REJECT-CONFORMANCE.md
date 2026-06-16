# III Compiler-Rejection Conformance Gate (W3300)

## The gap

Every gate III ships exercises the compiler on programs that **compile and run**:
`run_corpus.sh` requires each test to produce its EXPECTED exit code, the
`build_stdlib.sh` module build requires every module to compile, the
`build_iiis2.sh --check-corpus` seal gate requires byte-equivalence of *compiled*
output. Nothing asserted the inverse: that the self-hosting front-end still
**rejects** malformed input. A regression that made `sema`/`parse` silently
*swallow* a diagnostic and accept a bad program would pass every existing check —
the compiler's entire rejection/diagnostic surface was un-gated.

## The gate

- **`STDLIB/corpus_reject/`** — deliberately-malformed `.iii` fixtures, each a
  program the compiler MUST reject. Isolated from every tree-walking gate:
  `build_stdlib` compiles only `STDLIB/iii/` + its explicit `MODULES=()` list;
  `affine_audit_gate.sh` scans only `STDLIB/iii` + `COMPILER/BOOT`; `run_corpus.sh`
  runs only its explicit EXPECTED list. So the malformed fixtures cannot break
  any other gate.
- **`STDLIB/scripts/reject_conformance.sh`** — compiles each fixture with the
  pinned `iiis-2` and asserts a **non-zero exit AND no object emitted**. Exit
  0 = all rejected; 4 = a fixture was ACCEPTED (the regression); 3 = no fixtures.
  Runnable standalone (`bash STDLIB/scripts/reject_conformance.sh [iiis-path]`).
- **Wired into `build_stdlib.sh`** alongside the drift-check gates (right before
  the Sovereign Forge closure gate), exit 2 on failure — so the reject path is
  now a build-stopping invariant.

### Teeth (proven, not assumed)
A deliberately-VALID program (`return 99u64`) planted in `corpus_reject/` makes
the gate exit 4 with `FAIL: ... COMPILED (rc=0) -- the compiler must REJECT it`;
removing it restores exit 0. Both arms verified before wiring.

## The 5 confirmed reject classes (the fixtures)

| fixture | malformation | iiis-2 verdict |
|---|---|---|
| `r01_unresolved_ident` | bare undefined identifier in `return` | REJECT rc=12 `sema TYPE-IDENT-001` |
| `r04_unknown_fn_call`  | call to an undefined function | REJECT rc=12 |
| `r05_bad_token`        | stray `@@@` token (lexer) | REJECT rc=11 |
| `r07_undeclared_assign`| assignment to an undeclared variable | REJECT rc=12 |
| `r08_dup_fn`           | two `fn f()` definitions in one module | REJECT rc=12 |

Covers both the lexer (r05) and sema (r01/r04/r07/r08) rejection layers.

## Compiler-LENIENCY observations (recorded, deliberately NOT fixed)

While building the fixture set, four malformed programs were found that `iiis-2`
currently **ACCEPTS** (rc=0, object emitted) where a strict front-end would
reject them:

1. **Missing closing brace** — `fn main() -> u64 { return 0u64` with no `}` at EOF.
2. **Undefined type annotation** — `let x : NoSuchType = 0u64` (the annotation is
   not validated against known types; the value's type is taken).
3. **Arity mismatch** — calling a 2-arg `fn` with 1 argument.
4. **Call of a non-function value** — `let x : u64 = 5u64  x(1u64)`.

**Classification:** low-severity *robustness* gaps, **not correctness/security
defects**. No *valid* program exhibits any of them, so the compiler never
mis-compiles real code on their account — they are only "should have been a
nicer error." The fix in each case is a **stricter front-end** (parse: require
the closing brace; sema: validate type-annotation names, check call arity, check
callee is a function). That touches the **load-bearing self-hosting `parse.iii` /
`sema.iii`** — a change there risks the iiis-0→iiis-1→iiis-2 bootstrap and the
`build_iiis2 --check-corpus` byte-equivalence seal, and a too-strict rule could
**reject valid stdlib code** (e.g. if any module legitimately relies on lenient
arity or annotation handling). Per the standing fragile-port discipline
(`DOCS/III-FRAGILE-PORT-SAFEGUARDS.md`) and the evidence-backed "risk >> reward
on load-bearing code" judgment, these are left as a **documented future
dedicated wave** (front-end strictness hardening, done with the full bootstrap +
seal + corpus gates and a check that no valid module regresses), not a
marathon-tail edit. Recording them here is the no-deferral-honest verdict: the
gap is named, scoped, and its fix-risk assessed — not silently dropped.

## How to extend

Add a malformed `.iii` to `STDLIB/corpus_reject/`, confirm `iiis-2 --compile-only`
rejects it (non-zero, no `.o`), and the gate picks it up automatically. If a
future front-end strictness wave fixes one of the four leniency cases above, move
its repro from "observation" to a new fixture — the gate then guards the new
rejection permanently.
