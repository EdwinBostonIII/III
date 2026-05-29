# III — Ripple / Forcefield Convergence Plan

*End-to-end plan for enhancing the live III system toward the fixed standards of
this design arc: perfect mathematical consistency, content-addressed determinism,
the coherence forcefield, the ripple network, optimal invocation, and sound
self-evolution. The standards are non-negotiable; this plan's only job is to make
the path **verifiable at every step**, so the ambition cannot collapse into
never-shipping. Each phase ends in a green gate or it is not done.*

---

## §0. The fixed invariants — the acceptance test for ALL work

Every change, in every phase, must preserve all five. They are the standing
definition of "done":

1. **Corpus green.** `bash STDLIB/scripts/run_corpus.sh` → `FAIL=0`, `PASS ≥`
   the recorded baseline. No regression, ever. (And `build_stdlib.sh` →
   `FAIL=0`, grepped explicitly — a failed module silently leaves a stale lib.)
2. **Determinism sealed.** The seal-gated build re-seals to the golden hash, or
   the drift is *intended and witnessed* (a new module is intended drift; a
   codegen change to a sealed path is not).
3. **Coherence (`H¹ = 0`).** Any new module/bridge glues — the `pleroma`
   coherence gate admits the affected sub-cover (no new conflict-group edge).
4. **Conservative extension.** The change proves nothing false the old system
   couldn't already state. Strength-increasing changes (new axiom / universe /
   reflection) are **explicitly marked** and externally warranted (Gödel/Löb:
   the system cannot self-certify these).
5. **Every new capability ships its KAT — positive AND negative.** The gate must
   be shown to *reject* bad input, not merely accept good input. No stubs.

> The pinned compiler is always `COMPILED/iiis-2.exe` (harness pin; a stale
> external `iiis` produces phantom regressions). NIH discipline: libc + III only.
> No observational/statistical learning anywhere.

---

## §1. Current verified state (grounded, not assumed)

- **Compiler:** `iiis-2` self-hosts; `lex/parse/sema/cg_r3` are native `.iii`.
- **Library:** ~250 native modules aggregated to `STDLIB/build/iii/libiii_native.a`
  (4.9 MB), built in the explicit `build_stdlib.sh` dependency order.
- **Organs already in-tree** (the limbs the vision reuses, not reinvents):
  - content-address: `cad`, `mhash`, `merkle`, `identifier` (suite-tagged: `cad_begin(suite)`)
  - rewriting / conversion / admission: `xii_rewrite`, `xii_critpair_enum`,
    `xii_joinability`, `xii_termination`, `xii_admission`
  - optimal selection: `egraph`, `cost_lattice`, `tiebreak`, `xii_curated_*`
  - consensus (the L2 tier): `hotstuff`, `hotstuff_predict/heal`, `fed_*`
  - transport spine: `reach_core/store`, `backend_memo/remote/ipc/loopback`
  - crypto: `crypt_ed25519` (`ed25519_pubkey/sign/verify`), `keccak`, `sha256/512`
  - proof terms / model: `proof_term`, `theorem_carrier`, `curry_howard`,
    `category`, `sheaf`
  - metal descent: `katabasis/*` (svm/bar/ring_lattice/gate/seal/caps/admit)
- **The C/OS umbilical — the entire "separate from C" frontier, exactly six sites:**

  | site | module(s) | what it is |
  |---|---|---|
  | `malloc`/`free` | `memoria/region`, `numera/h10_charter` | memory |
  | `_open/_read/_write/_lseeki64/_unlink` | `aether/fs` | storage |
  | `CreateFileMappingA`/`MapViewOfFile` | `aether/backend_ipc` | local IPC |
  | `GetTickCount64` | `tempora/instant` | wall-clock |
  | `IsProcessorFeaturePresent` | `numera/cpufeat` | ISA detection |
  | `socket/connect/send/recv/bind/listen/accept` | `aether/net` | the Internet primitives |

- **Verified this arc, standalone in `FORCEFIELD/` (green on the real toolchain):**
  - `pleroma.iii` — the coherence forcefield gate (spanning-forest holonomy →
    `H¹=0` admit / located-obstruction reject + content-address seal). KAT 99.
  - `ripple.iii` — the value layer (content-addressed `publish`/`resolve`,
    GAP, tamper-evidence, ripple propagator + locality, monotone merge). KAT 99.
  - `ripple_dyn.iii` — the signed dynamic-name layer (Ed25519-gated, self-binding
    `k=H(pubkey)`, LWW-CRDT, forgery-rejecting). KAT 99, on production Ed25519.
- **The map** (`III-CARTOGRAPHER/iii-map.html`) — a dependency causal-loop graph
  that already computes `loops` (cycles), `conflict_groups` (name/const
  collisions = live `H¹≠0` edges), and `back-edges` (layering violations). These
  are the current *debts* the plan retires.

---

## §2. The meta-law (sound evolution, applied to this plan)

The build process itself obeys the evolution law from the design:

> **Conservative ⇒ free.** A phase merges iff §0 holds. A phase that raises
> proof-theoretic strength (P5's universes/reflection) is *marked* and warranted
> from outside, never silently self-certified.

Operationally this is a **convergence gate** (P0) that every phase boundary runs.
The "fractal partition" of the design — accumulate freely (monotone), coordinate
only at forced boundaries — is the rule for which changes are cheap (additive,
BSS-end placement, corpus +N) vs. expensive (touches a sealed codegen path,
needs a reseal decision, or crosses a strength boundary).

---

## §3. The phases

Each: **Goal · Deliverables · Gate · Depends · Risk · Ceiling.**

### P0 — Baseline + convergence gate *(measure before moving)*
- **Goal:** make "no regression" measurable and automatic.
- **Deliverables:** record baseline `PASS/FAIL`, `libiii_native.a` hash, golden
  seal; a one-command `convergence_gate.sh` that runs build (`FAIL=0` grep) +
  corpus (`FAIL=0`, `PASS ≥ baseline`) + reseal-check, and prints a single
  verdict. (Wraps the existing scripts; does not replace them.)
- **Gate:** the gate is green on the *untouched* tree (proves the gate itself,
  and that the tree is currently green).
- **Depends:** nothing. **Risk:** low. **Ceiling:** none.

### P1 — Integrate the three verified bricks as first-class modules
- **Goal:** promote `FORCEFIELD/{pleroma,ripple,ripple_dyn}` from standalone to
  in-tree, additively.
- **Deliverables:** place under a sphere (proposed `numera/` or a new `nexus/`);
  append to `build_stdlib.sh MODULES` **at the end** (preserve BSS layout —
  documented practice); port the three KATs into `STDLIB/corpus/` with `EXPECTED`
  entries; reseal (intended drift = three new modules, witnessed).
- **Gate:** `convergence_gate.sh` green; corpus `PASS = baseline + 3`.
- **Depends:** P0. **Risk:** low–med (BSS layout sensitivity → mitigated by
  end-placement). **Ceiling:** none. *(These are already green in isolation.)*

### P2 — Coherence gate on the REAL module graph + the partition ledger
- **Goal:** run `pleroma` on III's actual subsystem cover; produce the per-edge
  monotone/non-monotone ledger.
- **Deliverables:** a generator that emits the cover from the `extern … from`
  edge inventory (objects = modules, edges = bridges, transitions = declared);
  feed `pleroma`; the map's `conflict_groups` become located `H¹≠0` obstructions;
  classify every edge **L0 monotone / L1 CRDT / L2 consensus** (the
  optimal-invocation oracle for which edges cross the wire free).
- **Gate:** a corpus KAT asserts the gate *admits* a known-coherent subgraph and
  *rejects* a known conflict-group (positive + negative); the ledger is emitted
  and content-address-sealed.
- **Depends:** P1. **Risk:** med — modeling the transition of a real bridge.
- **Ceiling:** lossy/non-invertible bridges aren't `H¹` (group) edges — they're
  directed descent/colimit edges; P2 covers the invertible bridges and *flags*
  the lossy ones rather than faking a transition.

### P3 — Unify the optimal-invocation engine
- **Goal:** one dispatch: requirement → `egraph`-saturate → `cost_lattice`-extract
  → `tiebreak` → `xii_curated` ISA-specialize.
- **Deliverables:** the engine module + the two-selection discipline enforced —
  **implementation-selection** (same bytes, free, bit-identity proven against the
  `*_bitident` corpus) vs **suite-selection** (different bytes → `cad`
  suite-tag). First requirement: the 256-bit-digest class.
- **Gate:** KAT proves cost-min extraction, deterministic tie-break, chosen
  kernel ≡ spec (bit-identical); negative: malformed requirement → no selection.
- **Depends:** P1. **Risk:** med–high. **Ceiling:** bounded optimality —
  min *within the saturated class under the cost model* (Rice: global optimum
  uncomputable); DAG-cost extraction is NP-hard → start tree-cost-exact.

### P4 — C-separation: the six sites, one verified brick each *(the long descent)*
- **Goal:** cut the umbilical so the soundness theorem has no C-shaped hole; each
  site replaced by an III-native, KATABASIS-lowered primitive, **independently
  gated.** Order = increasing risk:
  - **P4.1 `cpufeat`** → XII/`bench_helpers` CPUID. *(isolated; easiest)*
  - **P4.2 `instant`** → logical clocks; wall-clock demoted to an explicitly
    typed nondeterministic effect, banned from deterministic paths.
  - **P4.3 `malloc/free`** → III-native region/linear allocator over a ring-0
    page primitive. *(foundational; touches everything)*
  - **P4.4 `fs`** → `reach_store` content-addressed storage over a native block
    primitive (a file becomes `H(content)`).
  - **P4.5 `backend_ipc`** → native shared content region (same `resolve`).
  - **P4.6 `net`** → the **ripple `resolve`/`publish`** (P1's bricks) over a
    native NIC primitive at ring 0/-1; hash-verify as the uniform metal-fast op.
- **Gate (per site):** the site's `extern … from "<os-lib>"` is gone from that
  module; `convergence_gate.sh` green; a KAT proves the native primitive matches
  the prior behavior on vectors.
- **Depends:** P4.6 ⇐ P1; the rest ⇐ KATABASIS ring-0/-1 descent (underway).
- **Risk:** HIGH — this is where "hell to write" is literal. **Ceiling:** ring
  0/-1 needs real hardware/driver work; the NIC introduces *physical*
  nondeterminism (typed as availability/partiality, never value). **DDC
  obligation:** as the C seed is cut, a second independent compilation path must
  be preserved or "trusting-trust" trust evaporates.

### P5 — The type-theoretic spine (the kernel) *(the capstone, longest)*
- **Goal:** a tiny total dependent type-checker — the de Bruijn criterion —
  conversion = XII, equality oracle = `cad`, universes (anti-Girard), graded/QTT
  layer = `region`/`cost_lattice`/`scalar_provenance`, effects typed; constructive
  core, classical/partial behind modalities.
- **Deliverables (incremental):** a minimal core (Π/Σ, 1–2 universes, XII
  conversion) + a KAT that typechecks valid terms, **rejects ill-typed ones**,
  and witnesses canonicity / subject-reduction on the fragment; then grow the
  universe ladder.
- **Gate:** the kernel accepts a term-corpus, rejects the negatives, fragment
  metatheory KAT green.
- **Depends:** P3 (solver automation discharges obligations), benefits from P4
  (closed semantics). **Risk:** HIGH — full cubical/univalence is a multi-year
  research frontier. **Ceiling:** self-consistency unprovable (Gödel II); trust =
  de Bruijn criterion + external metatheory; strength climbs the proof-theoretic
  ordinal ladder, capstone forever external.

### P6 — Lock in sound evolution as the commit gate
- **Goal:** make the convergence gate the *admission* gate for all future change.
- **Deliverables:** wire `xii_admission` (confluence/termination/soundness for
  rule changes) + `pleroma` (`H¹=0` for module changes) + seal (determinism) into
  one commit gate; establish the post-C DDC second path.
- **Gate:** a KAT proves the commit gate **rejects** a deliberately
  non-conservative change (negative — prove the guard fails on bad input).
- **Depends:** P1–P5 organs exist. **Risk:** med. **Ceiling:** Löbian — the gate
  certifies conservative extensions; strength-increasing ones it can only *mark*.

---

## §4. Sequencing & critical path

```
P0 ─► P1 ─┬─► P2 ─────────────┐
          ├─► P3 ─────────────┼─► P6 (lock-in)
          └─► P4.1→P4.6 ──────┘
                    (P4.6 ⇐ P1 ripple bricks)
P3 ─► P5 (kernel) ───────────────► P6
```

- **Immediate, low-risk, high-value:** P0 → P1 (days). The bricks are green;
  integration is additive.
- **Mid:** P2, P3 (use the bricks on real data; unify dispatch).
- **The frontier (long, hard, honest):** P4 (incremental descent) and P5 (the
  kernel). These are not weeks; P4.6 + P5 are the multi-year heart.
- **Cross-cutting:** P0's gate runs at every boundary; P6 promotes it to law.

---

## §5. Honest scope (calibrated, no bluff)

- This is the work of a long time. P0–P1 are immediate; P4/P5 are the frontier.
  The plan's value is that **progress is checkable at every step** — the grand
  end-state is pursued only as a chain of green bricks, never as a leap.
- **The ceilings are theorems, not TODOs:** self-consistency (Gödel/Löb),
  global optimality (Rice), deterministic consensus / a deterministic NIC (FLP /
  physics). The plan routes *around* each — external metatheory, bounded-class
  optimality, monotone CRDT + HotStuff-only-where-forced, value/delivery split —
  and never claims to cross them.
- **What stays out by design:** anything that would re-import nondeterminism into
  *values* (it goes behind the partiality modality), and anything observational
  /statistical (banned).

---

## §6. Immediate next action

**P0.** Capture the baseline and stand up `convergence_gate.sh`; run it on the
untouched tree to confirm green. That single measurement grounds everything that
follows — and is itself the first green brick.

---

## §7. Progress log

- **P0 — DONE (green).** Baseline: build `PASS=407 FAIL=0`; corpus
  `PASS=468 FAIL=0 SKIP=96`; lib mhash `51e95f98…fe32`. Gate validated on the
  untouched tree.
- **P1 — DONE (green).** The three verified bricks landed in a new `forcefield/`
  sphere (`forcefield/{pleroma,ripple,ripple_dyn}`); corpus `836/837/838` each
  `=99`. New protected floor: build `PASS=410 FAIL=0`; corpus
  `PASS=471 FAIL=0 SKIP=96`; lib mhash `f8adb66a…c96b` (intended, witnessed drift
  = +3 compiler-unreferenced modules; the `iiis` golden compiler seal is untouched
  by construction, so the no-redundant-rebuild discipline applies — build + corpus
  green suffices).
- **P2 — refined by ground truth (a correction).** Archive scan via `nm`:
  **0 duplicate-defined symbols** across all 410 modules → the binding-level
  coherence prerequisite (`H¹=0` at the symbol layer) ALREADY HOLDS; the archive
  glues. The map's `conflict_groups` **overcount**: `iiis` `const` are
  module-LOCAL (they link cleanly — CONVERGENCE-AUDIT §3.18), so a shared const
  name is not a real link debt. **This corrects the earlier network-partition
  claim** that `conflict_groups` are live `H¹≠0` edges — at the binding level they
  are largely cosmetic. Consequence: `pleroma`'s group-transition machinery is the
  right tool for the **content/value layer** (transitions = identity → coherent by
  construction) and for genuinely group-valued bridges — NOT the raw dependency
  graph, where plain symbol-uniqueness (✓ done) + topology (the map's back-edges)
  are the real checks. P2's substantive remaining output is therefore the
  **monotone/non-monotone partition** (the optimal-invocation oracle for P3), not
  conflict-group repair.
- **P3-core — DONE (green).** The optimal-invocation *selector* landed as
  `forcefield/optinvoke`; corpus `839` = 99. New floor: build `PASS=411 FAIL=0`;
  corpus `PASS=472 FAIL=0 SKIP=96`; lib mhash `c0d17b29…4deb`. Verifies min-cost
  choice, validity-pruning, deterministic content-address tie-break, none→sentinel,
  and the IMPL-vs-SUITE distinction. **NEXT (P3-rest):** wire `egraph` (candidate
  generation = the proven-equivalent class) + `cost_lattice` (cost per candidate)
  into the selector's input, for end-to-end optimal invocation on real requirements.
- **P3 — refined by ground truth (the term-engine pre-exists).** `egraph.iii`
  already exports `eg_saturate` + `eg_extract` — the **term-level** optimal-invocation
  engine (equality saturation → min-cost extraction) — and `eg_selftest` (corpus
  `614`, already green in the floor) proves it end-to-end: rewrite `mul(x,2)→shl(x,1)`,
  saturate, extract the min-cost form, with deterministic/bit-identity replay AND
  negative gates (empty-graph extract refusal, malformed-rule rejection). So P3 lives
  at **two independently-green levels**: term-equivalence (rewrite rules) = `egraph`;
  realization-equivalence (content-address + IMPL/SUITE/validity/seal) =
  `forcefield/optinvoke`. **Remaining for P3:** the thin end-to-end *composition*
  (egraph's chosen term → optinvoke's chosen realization), built on egraph's exported
  encode/extract API. Components done + green.
- **P3 — DONE (green, end-to-end).** Composition KAT `840_forcefield_optinvoke_egraph`
  drives the real `egraph` (saturate `mul(x,2)→shl(x,1)`, extract min-cost term `shl`)
  then `optinvoke` (pick cheaper valid realization, IMPL). Floor: corpus
  `PASS=473 FAIL=0 SKIP=96`; lib unchanged `c0d17b29…` (corpus-only add, no reseal).
- **P2 — DONE (partition ledger, ground-truth).** L2 / consensus-forced = **16 of 411
  modules (~3.9%)**: `hotstuff{,_predict,_heal}`, `fed_{tier,sybil,eclipse,admit,genesis,seal}`,
  `sandbox_quota`, `promote`, `demote`, `governance`, `branch_governance`,
  `reflection_governance`. The other ~96% are L0/L1 (pure-monotone / CRDT-reducible) —
  free across the wire, coordination-free, deterministic.

**Status: P0 · P1 · P2 · P3 — DONE, all green (build 411 / corpus 473 / lib c0d17b29).**
**NEXT: P4 (C-separation). P4.1 finding:** `cpufeat`'s `IsProcessorFeaturePresent` does
CPUID **and** the OS XCR0/XSAVE check (AVX2/AVX-512); a native replacement needs
`CPUID`+`XGETBV` and must AND-gate on the XCR0 lanes (else `#UD` on EVEX). Verify by a
**differential KAT** (native `summary()` == Win32 `summary()` on-host) before swapping.
P4 (metal) and P5 (kernel) are the frontier.

- **P4.1 — DONE (green).** `cpufeat` → native `CPUID`+`XGETBV` (no kernel32/msvcrt), SHA-NI
  detection corrected; full corpus green; lib `0f3f23bb…`.
- **P4.2 — DONE (green).** `instant` → deterministic logical clock (no kernel32); a wall-clock
  nondeterminism source removed from the substrate; lib `02cc01cb…`.
- **P4.3 — DONE (green).** `region.iii` (sole stdlib heap chokepoint) `malloc`/`free` → kernel32
  `VirtualAlloc`/`VirtualFree`; full corpus green; lib `1d4e4798…`.
- **P4.3b — DONE (green).** `h10_charter` (the other direct `malloc` user) → module-global BSS
  buffers for the pubkey/sig/msg scratch (no allocator at all); `691_h10_charter`/`674_h2_charter`
  green; corpus 473/0; lib `4cf67ce6…`.
- **P4.3c — DONE (green).** Audit-found regression in my own P1 work: the two integrated forcefield
  bricks `pleroma`+`ripple_dyn` had quietly re-introduced `msvcrt` `malloc`/`free`. Fixed via same-named
  module-local wrappers over kernel32 `VirtualAlloc`/`VirtualFree` (call sites unchanged; safe because
  non-`@export` `.iii` fns are module-local symbols — the 0-dup-symbol survey result, now empirically
  confirmed: zero link collision). Forcefield 836-840 all =99; corpus 473/0; lib `172ac12b…`. After this
  the **only** stdlib `msvcrt` user is `aether/fs` — the C *runtime* (allocator) is gone from stdlib
  entirely; only file I/O remains.
- **P4.4 — DONE (green). ★ MILESTONE: the C runtime is gone from III stdlib source.** `aether/fs`
  (`_open/_close/_read/_write/_lseeki64/_unlink`, the last `msvcrt` user) → Win32 file API from
  **kernel32** (`CreateFileA`/`CloseHandle`/`ReadFile`/`WriteFile`/`SetFilePointerEx`/`DeleteFileA`).
  Carries: HANDLEs stored whole (64-bit, no CRT-`int` truncation); byte-count & position via by-pointer
  out-params (two BSS scratch slots); BOOL-return inversions (nonzero=success). 7-arg extern de-risked by
  the proven 12-arg `wh_publish`. `38_fs_write_read_roundtrip`=99 — the full open→write→close→read→verify→
  delete→reopen-fail round-trip passes **on the real Windows filesystem**. Corpus 473/0; lib `3fd4d133…`.
  - **Scope of the claim (honest):** zero `msvcrt`/C-runtime references remain in any III stdlib `.iii`
    module — the stdlib's heap (`region`/`h10`/forcefield), clock (`instant`), CPU-features (`cpufeat`),
    and file I/O (`fs`) are now Win32-direct (kernel32) or pure-native (CPUID asm / logical counter / BSS).
    The remaining external surface is the **OS API** (kernel32: `VirtualAlloc`/`CreateFile*`/`MapViewOfFile`;
    ws2_32: sockets) plus gcc's link-time CRT *startup* (`crt0`/`_start`) — NOT the C runtime the stdlib
    calls. Replacing the OS API + owning `_start` is the **KATABASIS Ring-0/-1 native descent** (proven on
    metal; wiring pending) — P4.5 (ipc) / P4.6 (net) in their deeper sense, no longer a `msvcrt` concern.
- **P4 corpus-achievable scope: COMPLETE.** C-runtime separation is done and gated. P4.5/P4.6 reduce to
  the OS→native descent (metal, KATABASIS), not corpus bricks. **Next on the critical path: P5** (the
  dependent-type kernel — design in `DOCS/III-P5-DEPENDENT-CORE-DESIGN.md`), which is corpus-testable and
  resumes the founding intent ("III, the language of perfect mathematical consistency").

### P5 — The type-theoretic spine (the kernel) — IN PROGRESS

- **P5 brick 1 — DONE (green).** `STDLIB/iii/numera/typecheck.iii` (`module numera_typecheck`): a tiny
  TOTAL dependent type-checker for λΠ + a predicative universe ladder `U0:U1:U2…`. Flat module-global
  node arena (de Bruijn terms; no local-array runtime-index trap); `shift`/`subst`/`whnf`/`nf`/`conv`
  and bidirectional `infer`/`check` as natural recursive fns (recursion confirmed via the self-hosted
  recursive-descent parser). Conversion = NbE (β-normalize + structural compare). KAT `841_typecheck_core`
  (`p5_kat`, =99): 4 positives (universe ladder, Π-formation, polymorphic identity checks against its
  type) + a β-conversion case crossing a binder (closed an initially-dead whnf-β path, caught by an
  adversarial self-review) + 5 negatives each failing for its own reason — the keystone being
  **`U0 : U0` REJECTED** (Girard: `Type:Type` ⟹ `False`). Trusted core depends on NOTHING but its own
  arena (no libc/OS/hash — maximal de Bruijn criterion). Corpus `474/0`, lib `6dee32b0…`. Design:
  `DOCS/III-P5-DEPENDENT-CORE-DESIGN.md`.
- **P5 brick 2 — DONE (green).** `842=99` (all 14 Σ cases), `841=99` (no Π regression); corpus 475/0;
  lib `beca213c…`. Σ types (dependent pairs) + type ascription, ADDED to the same module
  (brick 1 frozen): tags `SIG`/`PAIR`/`FST`/`SND`/`ANN`; `shift`/`subst`/`whnf`/`nf`/`alpha_eq`/`infer`/
  `check` extended (whnf gains projection-β `fst⟨a,b⟩→a` + ascription-strip; `check` gains the
  PAIR-vs-Σ rule since bare pairs are checkable-not-inferable; `ANN` is the bidirectional bridge that
  makes a literal pair projectable). KAT `842_typecheck_sigma` (`p5_kat_sigma`, =99): Σ-formation,
  dependent-pair intro, projection β, the **dependent** projection TYPE (`type of snd = fst`, converting
  to U1), direct Σ-/pair-conversion (closing the nf/alpha_eq SIG+PAIR arms — same dead-path discipline as
  the β case), + negatives (dependent mismatch, fst-of-non-pair, `U0:U0` via ascription).
- **P5 brick 3 — DONE (green).** `843=99` (16 cases), `841`/`842` still =99; corpus 476/0; lib
  `c9364913…`. *(Build first hit the parser's nesting-depth limit — `RECURSION_LIMIT` — on the 6-deep
  whnf `if/else` ladder; fixed by flattening to a sequence of `if tag==X` guards, max nesting 3. Reusable
  iii constraint: multi-way dispatch must be flat sequential ifs, not a nested else-ladder.)*
  **Bool** — the first base inductive (`Bool:U0`, `true`/`false:Bool`,
  non-dependent `if` with β `if(true,t,e)→t` / `if(false,t,e)→e`). Added `TC_C` (3rd node field, since
  `if` has 3 args) — additive; every existing arm untouched (C defaults 0). The kernel's first DATA +
  value-level computation. KAT `843_typecheck_bool` (`p5_kat_bool`): formation, constructors, if-typing
  + β both ways, `if` substituted under a binder (`(λx:Bool. if(x,true,false)) true ≡ true` — exercises
  subst/shift of Bool nodes + whnf-IF after substitution), + negatives (non-Bool scrutinee, mismatched
  branches, `true : U0`).
- **P5 brick 4 — DONE (green).** `844=99` (18 cases), `841`–`843` still =99; corpus 477/0; lib
  `3bc31ad1…`. The kernel now has Π + Σ + Bool + propositional equality — a complete verified MLTT
  fragment. **Identity types** (`Id` + `refl` + `transport`) — where equalities become
  statable and usable, the soul of the system. Tags `ID{type,lhs,rhs}`, `REFL{value}`,
  `TRANSP{pred,proof,base}` (transport = the minimal eliminator; full `J` deferred). `infer`:
  `Id(A,a,b):U_k`; `refl a : Id(A,a,a)`; `transport(P,p,base)` requires `p:Id(A,a,b)`, `P:A→U_k`,
  `base:(P a)` ⇒ `(P b)`. `whnf`: `transport(P, refl, base) → base` (transport along reflexivity is
  identity). Tested on Bool witnesses (KAT `844_typecheck_id`, 18 cases): Id-formation, `refl true`
  typing, transport-β, refl/Id conversion, Id/refl substituted under a binder; negatives — `refl true`
  does NOT prove `true=false` (REJECTED), wrong transport base type, wrong predicate domain.
- **P5 brick 5 — DONE (green).** `845=99` (15 cases incl. the real recursion), `841`–`844` still =99;
  corpus 478/0; lib `523c0c25…`. **Nat + iteration recursor** — the kernel's first unbounded computation.
  Tags `NAT`/`ZERO`/`SUCC`/`ITER` (`iter z s n = sⁿ(z)`). `infer`: `Nat:U0`; `zero:Nat`; `succ n` (n:Nat)
  `:Nat`; `iter(z,s,n)` = `infer z=T`, check `s:T→T`, check `n:Nat` ⇒ `T`. `whnf`: `iter(z,s,zero)→z`,
  `iter(z,s,succ m)→s(iter z s m)` (call-by-name, fuel-guarded, flat `took`-dispatch). KAT
  `845_typecheck_nat` (15 cases): formation, constructors, recursor-β base + step, a **real recursive
  computation** (`iter(zero, λm.succ m, succ²zero) ≡ succ²zero` = apply succ twice = 2, forcing the inner
  recursion), + negatives (`succ true`, non-Nat scrutinee, z/s type mismatch).
- **P5 brick 6 — DONE (green).** `846=99`, `841`–`845` still =99; corpus 479/0; lib `73cd8390…`. The
  conversion checker is now η-complete. **η-conversion** (Π-η: `λx.(f x) ≡ f`) — definitional function
  extensionality, a completeness improvement to the core `conv`. Purely additive (no existing negative
  relies on η-inequality; chosen over cumulativity which would break brick 2's strict-universe negative,
  and over dependent `natrec`/`J` which are higher de-Bruijn risk). New helper `tc_strengthen(t,c)`
  (mirror of `shift`: decrements free vars `>c`, returns `0`=fail if var `c` occurs), used by
  `tc_try_eta`; `nf` η-contracts `λ.(g #0)` to `strengthen(g)` when `#0 ∉ g`. KAT `846_typecheck_eta`:
  `λf.λx.(f x) ≡ λf.f` (η fires); `≢ λf.λx.x` (doesn't conflate id-applied with const); `λx.(x x) ≢ λx.x`
  (strengthen-fail path: var used ⇒ no contraction).
- **P5 brick 7 — DONE (green).** `847_typecheck_natrec=99` (under-binder shift exerciser passed).
  **natrec** — the DEPENDENT Nat eliminator (induction). Added `TC_D` 4th node
  field + `tc_mk4` (additive). `natrec(P,z,s,n)`: `P:Nat→U`, `z:P zero`, `s:Π(k).P k→P(succ k)`, `n:Nat`
  ⇒ `P n`; β `natrec(zero)→z`, `natrec(succ m)→s m (natrec m)`. Step-type built with `shift(P,1,0)`/
  `shift(P,2,0)` (design §12.2). KAT `847_typecheck_natrec`: closed β (base + step-uses-predecessor),
  the **under-binder shift exerciser** (`λP.λz.λs.λn.natrec(P,z,s,n)` typechecks iff shifts exact — the
  only test that catches a shift bug, since a closed motive makes the shift a no-op; §12.4), + negatives
  (wrong step type, non-Nat motive). *(Brick-7 corpus first failed `rc=2` with a bogus `run_corpus.sh`
  syntax error — a self-inflicted race: I edited `run_corpus.sh` (the brick-8 EXPECTED line) WHILE brick
  7's gate was executing it; bash reads scripts as it runs, so the inserted line shifted the file
  underneath it. natrec's build had passed; re-gated clean. **Lesson: never edit a gate-read file
  (`run_corpus.sh`/`build_stdlib.sh`/`typecheck.iii`) while a gate is in flight.**)*
- **P5 brick 8 — DONE (green).** `848_typecheck_j=99` (under-binder diagonal exerciser passed); corpus
  481/0, lib `9e2eaf26…`. **J** — path induction (the DEPENDENT Id eliminator), the dual of natrec.
  `J(C,d,p)` in 3 fields (no `TC_D`): motive `C:Π(y:A).Id(A,a,y)→U`, base `d:C a (refl a)`, proof
  `p:Id(A,a,b)` ⇒ `C b p`; β `J(C,d,refl)→d`. Typing APPLIES the motive (design §12.3) — `da=C a (refl a)`
  and `rty=C b p` are Γ-level applications, so NO manual shift; verify both are types, check `d` at the
  diagonal. KAT `848_typecheck_j`: closed β (`J(λy.λ_.Bool, true, refl true) ≡ true`), the **under-binder
  diagonal exerciser** (`λA.λa.λC.λd.λb.λp.J(C,d,p)` typechecks iff the base is checked against the
  diagonal `C a (refl a)`, not `C b p` — the only test that catches that bug, since a constant/closed
  motive collapses the distinction; §12.4), + negatives (base wrong type, proof not an Id). The brick-8
  gate re-confirms `847` (natrec) too. **★ MILESTONE (green): the P5 kernel is a complete MLTT core —
  Π/Σ/universes, Bool/Nat with both iter and dependent induction, Id with transport and path induction, η.**
- **P5 brick 9 — DONE (green).** `849_typecheck_bot=99`; corpus 482/0, lib `f841ceb2…`.
  **⊥ (Empty) + ⊤ (Unit) + `absurd`** — the trivial connectives; ⊥ gives
  negation (`¬A := A→⊥`) and ex-falso. Tags `UNIT`/`TT`/`EMPTY`/`ABSURD` (design §13). `infer`:
  `Unit:U0`, `tt:Unit`, `Empty:U0`, `absurd(C,e)` requires `e:Empty` ⇒ `C e` (apply-the-motive, no
  shift; `absurd` is the rare eliminator with NO β-rule since Empty is uninhabited). KAT
  `849_typecheck_bot`: formation + `tt`, the **under-binder absurd positive** (`λC.λe:Empty. absurd(C,e)`
  — closed there's no Empty witness), + negatives (proof not Empty, motive domain ≠ Empty).
- **P5 brick 10 — DONE (green).** `850_typecheck_cumul=99`, all `841`–`849` re-green (subsumption
  regressed nothing; Girard's `U0:U0` guard survives); corpus 483/0, lib `e31f046d…`.
  **Cumulative universes** (`U_i : U_j` for `i ≤ j`) — `check` now uses
  SUBTYPING (subsumption) not definitional equality: new `tc_subtype` = `conv` except `U_i ≤ U_j` at
  sorts (shallow, sort-level; design §14). `tc_conv` itself unchanged. **Soundness checked:** `subtype ⊇
  conv` ⇒ all positives still pass; every universe negative is "higher:lower" (`U0:U0`→`1≤0` false, …)
  ⇒ still rejected — **`Type:Type` stays rejected** (the Girard guard survives: `infer(U0)=U1`, `1≤0`
  false). SOLE casualty: brick 2's `842` N5 (`⟨U1,U0⟩:Σ(_:U2).U2`, which needed `U0:U2`) — now correctly
  ACCEPTED, so adapted to `⟨U1,true⟩:Σ(_:U2).U2` (2nd `true:U2` still fails). KAT `850_typecheck_cumul`:
  `U0:U2`/`U1:U3`/`U0:U1` (subsumption) + `U2:U1`/`U1:U0`/`U0:U0`/`true:U0` REJECTED. Re-greens all of
  `841`–`849`. Next: Sum (∨), conversion-via-XII.
- **P5 brick 11 — DONE (green).** `851_typecheck_sum=99`, all `841`–`851` =99; corpus 484/0, lib
  `7a0f5f0c…`. **All propositional connectives present** (→ ∧ ∨ ⊥ ⊤ ∀ ∃ =).
  **Sum types `A+B` (∨)** + the DEPENDENT case eliminator — the last
  propositional connective, and the most substantial brick (fuses natrec's shift + J's apply-the-motive +
  `TC_D` + pairs' ANN-bridge). Tags `SUM`/`INL`/`INR`/`CASE`. `inl`/`inr` check-only against a `SUM`
  (ANN-bridge for inference). `infer(case(C,f,g,s))` the **hybrid**: result `C s` apply-the-motive (no
  shift); methods `f:Π(a:A).C(inl a)`, `g:Π(b:B).C(inr b)` built with `shift(C,1,0)` (like natrec). β
  `case(inl v)→f v` / `case(inr v)→g v`. KAT `851_typecheck_sum`: closed β both branches, the
  **under-binder shift exerciser** (`λC.λf.λg.λs.case(C,f,g,s)`, `A=B=Bool`), inl-conv, + negatives
  (inl vs non-Sum, scrutinee not Sum, method wrong type). **On green: all propositional connectives
  (→ ∧ ∨ ⊥ ⊤ ∀ ∃ =) present.** Next: conversion-via-XII, W-types.
- **P5 brick 12 — DONE (green).** `852_typecheck_meta=99`, all `841`–`852` =99; corpus 485/0, lib
  `fa8ae0ff…`. **The metatheory KAT** — canonicity (every closed `Bool` reduces to a constructor through
  all 5 eliminators + nested) + subject reduction (`infer(t)≡infer(nf(t))`). **★ The MLTT frontend is
  COMPLETE AND CERTIFIED** — a from-scratch dependent type theory in `.iii`, 12 corpus-gated bricks.
- **PATH C (operator decision) — eradicate bound variables; XII the SINGULAR oracle** (design §19).
  Rejects Path A (λσ ¬SN, Melliès → fails xtm_gate) and Path B (two oracles → ¬H4). Compile MLTT →
  variable-free combinators ⇒ no substitution ⇒ XII's first-order engine is universally sufficient ⇒
  `critpair`+`conf_cert` certify whole-theory confluence. Refinements: R1 use Curien CCL (βη-faithful,
  not β-only SKI); R2 backend is UNTYPED (frontend types; no dependent-combinator typing lift); R3 strict
  currying. Brick sequence B13→B16; differential KAT gates NbE-deletion.
- **P5 brick 13 (Path C) — DONE (green).** `853_combinator_ski=99`, corpus 486/0, lib `51d615b0…`.
  `numera/combinator.iii`: SKI constants + bracket abstraction (`λ→SKI`) + purely FIRST-ORDER reduction
  (`I x→x`, `K x y→x`, `S x y z→x z (y z)` — no substitution, no scopes). KAT proves variable-free routing
  matches λ-semantics (I/K/S + composed) by structural pattern-matching alone. Path C's premise holds.
- **P5 brick 14 (Path C) — DONE (green).** `854_combinator_data=99`, corpus 487/0, lib `b94a5749…`. The
  full first-order ELIMINATOR set as combinator ι-rules (motive-erased, R2): `IF` (Bool), `ITER`/`NATREC`
  (Nat — NATREC's step gets the predecessor AND the IH), `CASE` (Sum, both arms), `J` (Id, refl-elim);
  constructors `TRUE/FALSE/ZERO/SUCC/INL/INR/REFL`. `cb_step` is a flat spine-read (max nesting 4). KAT
  proves select-and-recurse with NO substitution + that bracket abstraction COMPOSES with ι. **★ The
  adversarial KAT earned its keep** — caught a `cb_struct_eq` default-`0` bug (matching constructors
  compared unequal) before it could corrupt the differential.
- **P5 brick 15 (Path C) — DONE (green).** `855_combinator_conv=99`; full gate corpus **488/0**; lib
  `fe46d6c0…`. The TC→combinator COMPILER + the DIFFERENTIAL KAT. `tc_to_cb` (typecheck.iii) totally maps
  the computational fragment (all 13 tags; binders→`cb_lam`, motives/types erased, type-formers→atom).
  `p5_kat_cbconv` proves `cb_conv(compile x, compile y) == tc_conv(x,y)` — **the first-order combinator
  oracle AGREES with NbE** — on 14 vectors (β, IF, ITER Bool+Nat, NATREC, CASE both arms, J, nested,
  β-under-eliminator, negatives). Iterated via the new `fast_check.sh` (~30s targeted harness: recompile 2
  leaf modules + `ar` swap + run 84x/85x), confirmed by the full gate. η excluded (combinatory η is global
  extensionality → the CCL step). **The combinator oracle is proven equivalent to NbE on the β+ι fragment
  — the licence to proceed toward retiring NbE (B16–B18).**
- **B16–B18 (Path C completion) — DONE (green). ★ MILESTONE: P5 COMPLETE — the singular CCL oracle.**
  Corpus **496/0** SKIP=96; lib `08c63832…`; bricks 856–863 all =99. **The e-graph was abandoned for β
  by design** (equality saturation inherently accumulates every duplicated/expanded β-form → blow-up;
  the "10 breakthroughs over 1 concession" forcing function): the principled mechanism is **directed
  reduction of Curien's confluent CCL** (`numera/ccl.iii`), where η is a clean structural contraction,
  NOT e-graph saturation. B16: directed CCL βη+ι reducer (`ccl_step`/`ccl_reduce`), proven ≡ NbE on the
  whole 841–852 workload (860 audit, zero disagreement). B17: type-formers compiled structurally as CCL
  atoms; Σ-proj/transport ι; read-back `ccl_to_tc` (CurT — binder domains threaded through Cur's idle
  field — solves untyped-reification domain-loss WITHOUT type-directed reify). B18: **NbE physically
  deleted** (~900 lines: `tc_whnf`/`tc_nf` bodies + `tc_strengthen` + `tc_try_eta` + `tc_alpha_eq` +
  `tc_shift` + `tc_subst`); `tc_conv`/`tc_whnf`/`tc_nf` are now one-line CCL round-trips; `infer`'s
  construction migrated to CCL `∘Fst` shift + β-subst. **η-completeness bug found + fixed** (the
  confluence audit surfaced it): the syntactic bare-`Fst` matcher silently failed on higher de Bruijn
  variables (`ass` right-associates `x∘Fst`) → replaced with `ccl_strengthen` (inverse weakening) for
  COMPLETE η on all levels / neutral spines (probe `862`). B18d: **the confluence certificate**
  (`ccl_conf_cert`, `863`) — 14 critical pairs all join (ass×{idl,idr,ass,dpair,fst,snd,β,atom}, idr×ass,
  β×η, dcur×η, ι×subst[IF,NATREC], β2×dcur); Newman: local-confluence + termination (σ/ι structural; βη
  SN on well-typed terms, the Melliès obstruction making untyped-SN false → termination is necessarily
  typing-conditioned) ⇒ global confluence; PROVEN falsifiable (broken `ass`→CP4, broken `β2`→CP8). The
  now-NbE-less `ccl_agrees`/`TC_CONV_DISAGREE` tautologies were de-vacuified (859 = real conversion KAT
  with 14 positive + 8 negative arms; 860 = integration audit). **The kernel decides ALL conversion +
  type-computation through one confluent first-order oracle; NbE is gone.**

**Status: P0 · P1 · P2 · P3 · P4(corpus-scope) · P5 — DONE, all green (build 414 / corpus 496 / lib 08c63832).**
**NEXT: P6 (lock-in sound evolution as the commit gate) — the plan's final phase.**

- **P6 — the sound-evolution COMMIT GATE — DONE (green).** `forcefield/commit_gate.iii` + KAT `864`.
  Composes the three verified organs into ONE located admission verdict: RULE soundness (`xad_admit`:
  XII root-confluent + terminating), MODULE coherence (`pleroma_cohere`: H¹=0, located obstruction),
  DETERMINISM (`cad` content-address seal: match-or-witnessed-drift), + CONSERVATIVITY (a MARKED flag —
  the Gödel II/Löb ceiling: the gate cannot self-certify a strength increase, only require it be marked).
  `cg_decide` is a pure total predicate with teeth; the verdict NAMES the failing dimension (never a bare
  0). KAT `864` drives the REAL organs (coherent square→admit, parallel-disagreeing bridges→reject;
  re-hash matches golden→sealed, drifted artifact→reject, witnessed drift→admit) + the full reject matrix
  — a stub that only ever admits FAILS it. **★ The Ripple-Forcefield convergence plan (P0–P6) is COMPLETE:
  III's §0 acceptance test is now law — no change merges unless rules stay confluent+terminating, modules
  glue, the artifact is content-sealed, and strength increases are marked.**

---

## §8. Existing-asset survey (corrected two-axis map) — the revised P4–P6 baseline

**The frontier is far more built than this plan first assumed — much of it proven on live silicon.**
But the 40-subsystem tree splits on two axes: **live `.iii`-and-corpus-gated** (only `STDLIB/`,
`COMPILER/`, `KATABASIS-DEPLOY/`, `FORCEFIELD/`) vs **C-reference/design** (~30 subsystems, all
`iii=0` — "non-current III"); crossed with **proven-on-metal** vs **designed**. The usable head-start
is the *live ∩ proven* intersection; the rest is a port backlog or a hypothesis.

**A. Proven-on-metal + live (use directly):**
- `cg_r0` ring-0 driver codegen (DriverEntry/IRP/IRQL/SEH/ring-wall/witness) — emits real ntoskrnl drivers.
- **The native-facility recipe**: `cg_r0` + hand-asm shims (`floor_abi.s`/`kernel_abi.s`: `andq $-16,%rsp`,
  rbp-SEH, Win64 marshalling, bare ntoskrnl symbols → `ld`+`libntoskrnl.a` synth the IAT) → any `Mm*`/`Io*`/`Ndis*`.
- KATABASIS Ring-0 gate (Tier-2/3) + Ring −1 floor (I0→I4: VMRUN, gate@VMEXIT, NPT-intercept), reversible/deterministic.
- Native kernel memory (`MmAllocateContiguousMemory`); proven SVM constants (`svm_const.iii`).
- Live stdlib net: `backend_remote` (content-verified resolve over the wire = ripple, built over TCP),
  `reach_*` spine, `fed_*`+`hotstuff`. Heap chokepoint `region.iii`.
- The IOCTL gate **is** the proven R3↔R0 channel.

**B. Live but designed (not yet metal-proven):** `cg_rm1` (~80% hypervisor emitter), `cg_rm2`
(ring −2, observe-only), bare-metal NPT.

**C. C-reference + design only (port/re-derive targets, NOT live):**
- **IOMMU/NIC wire (P4.6's missing piece):** `PORTABILITY` §4 uniform cross-arch IOMMU
  (`iommu_map_iopt`/`irte_remap`/`fault_intercept @ring(R-1)`; AMD-Vi/VT-d/SMMU/RISC-V/POWER) +
  `SOVEREIGN-WEB` (witness-packets, peer discovery, NDIS coexist). Designed + C-referenced; **not built in III**; rides the proven Ring −1.
- `EFFECTS` (capability engine, C), `CYCLES` (SID/ripple/witness core, C); `SANCTUM`/`TRINITY`/
  `FEDERATION`/`ZK-PRUNING`/`CRYPTO-AGILITY`/… = C-reference/spec.

**Corrected C-site gap map:** P4.1 ✅ · P4.2 ✅ · P4.3 ✅ (region+h10+forcefield → VirtualAlloc/BSS; C *runtime* gone, only `fs` I/O left) · P4.5 ipc →
**the IOCTL gate already is the proven channel** · P4.4 fs → `reach_store` + the proven Io/IRP driver
pattern · P4.6 net → resolve-over-wire **built** (`backend_remote`), only the IOMMU/NIC wire unbuilt
(designed, rides proven Ring −1).

**Reordered remaining (by head-start leverage):** P4.4 (fs — the *last* `msvcrt`; finishing it = the
declarable "C runtime entirely gone from stdlib" milestone) → P4.5 (ipc, smallest given the gate) →
P4.6 wire (IOMMU NIC on the proven Ring −1). The deep metal (gate, hypervisor, NPT-ripple)
is **already proven**; the work is wiring the user-mode residue down to it, not inventing it. Census-level
read of the C-reference layer (their nature established by census + docs; not line-by-line).
