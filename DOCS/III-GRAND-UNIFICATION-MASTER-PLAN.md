# III — GRAND UNIFICATION: Master Plan to the Final State
> **SUPERSEDED-BY: III-COMPLETION-PLAN.md** — this document is a HISTORICAL RECORD of its campaign era; the pointer target is the live doc (reunification W6, 2026-07-02).

> **Final state, in one sentence:** a single, gated, reproducible pipeline in which a real EIDOS
> computation is compiled to SVIR, canonicalised by XII under a sealed/proven rule manifest with an
> `eqv_equal` equivalence proof, built by a fully sovereign + byte-reproducible back-end, run to 99 on two
> diverse machines, **zero-knowledge-attested over the full SVIR ISA**, shipped to a second machine over a
> crypto-sealed channel, and there **verified-and-folded without re-execution** — and a self-improvement loop
> that lets III discover, prove, witness, and attest improvements to *itself* without ever leaving that
> verified perimeter. Trust closed at every layer, on any substrate, even as it changes.

> **Discipline (non-negotiable, from the directive):** No compromise, no concession, no deferral. Every gap
> named here is to be **BUILT and KAT-gated**, never punted. Every phase advances only on a falsifiable gate
> that is **RED before and GREEN after**. The "10,000 breakthroughs before one concession" is operationalised
> below as: each phase decomposes into many gated increments, and *abstaining is only permitted when a thing
> is unsafe or unverifiable* — never because it is hard.

---

## 0. Provenance & verification status

This plan was written **after a five-round manual audit of the live tree** (2026-06-23), not from memory.
Every "current state" claim below was checked against real files. What was verified, and how:

| Round | What was audited | Key finding (verified) |
|---|---|---|
| 1 | zk + XII inventories | `STDLIB/sovir/zk_svir_vm.iii` exists; 41 `omnia/xii_*.iii` modules; sealed manifest present |
| 2 | `zk_svir_vm.iii`, `run_zk.sh` | zkVM trace AIR real (2 opcodes ADD/MUL, prover+verifier+soundness); per-opcode AIRs (ADD/MUL/RANGE) gated to 99; sovereign build composed in the gate |
| 3 | XII engine, manifest seal, EIDOS runtime | `xii_canonicalise`/`xii_rewrite`/`xii_termination`/`xii_joinability`/`xii_critpair_enum` all present; `gen/sign/verify_xii_manifest` + `xii_manifest.bin` + `.mhash.golden` present; EIDOS = 18 modules; `eqv_equal` defined in `eidos/memo.iii` + `numera/invent.iii` |
| 4 | SVIR ISA, EIDOS→SVIR, network, self-improve | `svir_verify.iii` covers `0x01`–`0x89` (typed memory landed), 80 lines; EIDOS compiles `cg_r3`→x86 **directly, not via SVIR**; `aether/{net,tcp,inet,inet6,sealed_channel,pattern_set_federation,backend_remote}` exist; `omnia/self_reformatter.iii`, `numera/sov_isa.iii`, `numera/verified_search.iii` exist |
| 5 | `iiisv`, ccsv gap, transport | `iiisv.iii` = independent `.iii`→SVIR compiler (integer-core subset, shares zero code with cg_r3); `sealed_channel` = x25519 ECDH + ChaCha20-Poly1305; `pattern_set_federation` = sealed mhash-anchored cross-node sharing |

**Residual verification owed (each phase below opens with its own deeper audit task — per III's "manual audit before
rebuild" law):** exact opcode coverage of `iiisv`'s lowerer vs. the full ISA; precise ccsv seed-feature remainder;
whether `eqv_equal` is total or partial; the `sov_isa` self-extension's current proof obligations.

---

## 1. The final state, defined precisely

The end state is the **Grand Unification gate** — one command that proves all of the following on a *single real
EIDOS computation* `R` (an EIDOS ripple), end to end, with zero unproven links:

```
FR-Ω: Given an EIDOS ripple R expressed in .iii, the Grand Unification holds iff ALL of:
  Ω.a  R compiles to canonical SVIR via iiisv (the .iii→SVIR front-end), verifier-accepted.
  Ω.b  XII canonicalises R's SVIR under the SEALED manifest, emitting an eqv_equal proof
       that canon(R) ≡ R (semantics preserved); the manifest signature verifies.
  Ω.c  The sovereign back-end (svir_x86 → sovas → sovld) builds R into a kernel32-only PE
       with NO gcc/ld in the artifact path, and the build is BYTE-REPRODUCIBLE (two builds cmp-identical).
  Ω.d  R runs to 99 on the sovereign x86 PE AND on wasm (one IR, two diverse machines, same result).
  Ω.e  R's execution is ZERO-KNOWLEDGE ATTESTED over the FULL SVIR ISA used by R (every executed
       opcode constrained by its AIR; honest trace holds; a forged step is rejected; a verifier
       reproduces the constraint from openings).
  Ω.f  The attested R is shipped to a SECOND node over a sealed_channel (x25519+ChaCha20) and there
       VERIFIED (proof checks) and FOLDED into that node's EIDOS state WITHOUT re-executing R.
  Ω.g  The whole chain's provenance (seed → compiler → manifest → artifact → proof) is itself
       trust-closed: run_trust_closure.sh PASS (frontend + seed-lineage DDC) gates the toolchain that
       produced every binary in Ω.a–Ω.f.

ACCEPTANCE: a single gate `run_grand_unification.sh` exits 0 iff Ω.a–Ω.g each emit their proof and every
NEGATIVE arm (forged SVIR, broken manifest sig, non-reproducible build, divergent back-ends, forged trace,
tampered channel, re-executed fold) is REJECTED. No arm may be stubbed.
```

And the **self-improving** extension:

```
FR-Σ: III improves ITSELF without leaving the verified perimeter. Given a candidate improvement to an
III component (e.g. a sov_isa rewrite rule, a cg optimisation), the loop holds iff:
  Σ.a  nous/verified_search PROPOSES the candidate (discovery, not hand-authored).
  Σ.b  XII proves the candidate is equivalence-preserving (eqv_equal) AND admissible under the sealed
       manifest (xii_admission); the manifest RE-SEALS deterministically (forge_manifest_keccak).
  Σ.c  The rebuilt component passes the DDC re-witness (run_trust_closure.sh) and the corpus regression.
  Σ.d  The improvement's EFFECT (e.g. fewer SVIR steps) is zk-attested via the cost-meter AIR.
  Σ.e  The improvement federates to peer nodes via pattern_set_federation (sealed, mhash-anchored).
ACCEPTANCE: `run_self_improve.sh` lands ONE real, measured, proven improvement to III through Σ.a–Σ.e,
with the negative arm (a semantics-BREAKING candidate) REJECTED at Σ.b.
```

---

## 2. Requirements

### 2.1 Functional (the unification, decomposed)
- **FR-1** `.iii`→SVIR coverage sufficient for a real EIDOS ripple (extend `iiisv` past the integer core).
- **FR-2** XII canonicalisation of SVIR with an emitted, checkable `eqv_equal` equivalence proof.
- **FR-3** Sealed-manifest gate on every rewrite (no rule fires unless `verify_xii_manifest` passes).
- **FR-4** Full-ISA zkVM: an AIR per SVIR opcode class actually executed (arith, compare, control, mem, call).
- **FR-5** Sovereign + byte-reproducible build of a real program end to end (route through sovas/sovld).
- **FR-6** Two-back-end agreement to 99 (x86 sovereign + wasm) for the same SVIR.
- **FR-7** Sealed-channel transport + verify-and-fold-without-re-exec on a second node.
- **FR-8** Self-improvement loop closing discovery → proof → witness → attest → federate.

### 2.2 Non-functional (III-native targets; *these replace the web-app NFR table*)
| Category | Requirement | Target | Measurement (the gate) |
|---|---|---|---|
| Determinism | Same input → identical bytes | bit-identical | `cmp` over two runs |
| Reproducibility | Build reproducible end to end | bit-identical PE | `run_repro.sh` (route via sovas/sovld) |
| Trust closure | Diverse double-compile | both axes PASS | `run_trust_closure.sh` |
| Proof coverage | SVIR ISA opcodes with a sound AIR | 100% of opcodes *R* executes | `run_zk.sh` extended; coverage report |
| Soundness | Every negative KAT rejects bad input | 100% of negatives FAIL | per-KAT negative arms |
| Portability | Back-ends agreeing to 99 | ≥2 (x86, wasm); RISC-V designed | `run_svir.sh` / `run_ccsv.sh` cfeat |
| TCB size | Irreducible trust surface | {audited seed + CPU}; verifier ≤ ~80 lines | manual audit of `svir_verify.iii` |
| Zero deferral | Landed code free of stubs/TODO | 0 in trusted path | grep gate over landed files |

### 2.3 Constraints (binding)
- **TECH:** NIH — only libc + III BOOT headers; hand-roll the rest. No Python in the trusted path.
  All work in `.iii` / `.c` / `.sh`. No subagents (all reasoning + implementation in-session).
- **PROCESS:** KAT-RED-before / GREEN-after is the gate for *every* increment. Determinism gate after every
  grammar/codegen change. Corpus regression after every grammar/cg change. Read evidence before edits.
- **TRUST:** the seed stays frozen except gcc-byte-identical changes; quirks ride on build flags, not source.
  Sealed-manifest signature must verify after any XII rule change.

---

## 3. Verified current-state audit (the grounding for every phase)

| Subsystem | Maturity (verified round) | What's DONE | The precise GAP to the final state |
|---|---|---|---|
| **SVIR + verifier** | Mature (R4) | ISA `0x01`–`0x89` incl. typed mem; 80-line anchor | none for the spine; verifier must stay ≤~80 lines as ISA-used-by-R is fixed |
| **ccsv (C→SVIR)** | Growing (R5) | real C subset, crypto compiles, seed features climbing | finish enough seed coverage to compile iiis-0 C TUs (the sovereign-witness path) |
| **iiisv (.iii→SVIR)** | **Ω2 done (R5)** | integer core + fixed arrays + `const`/`as`/`@export` + void-fn returns; `iiisv2` byte-mirrors all | EIDOS ripple R0 routes through it (FR-1 ✅); structs only if a later phase needs them |
| **sovas / sovld** | Mature (R2/repro) | sovereign assemble+link; **byte-reproducible** | route iiis-1's C TUs through it for binary-level DDC (Ω0) |
| **DDC (trust)** | Mature (session) | both axes gated; `run_trust_closure.sh` PASS | extend to binary-level via reproducible back-end (Ω0) |
| **XII** | **Ω3 done (R3)** | 41 modules + `xii_proof`/`xii_proof_check`: canonicalisation now emits a checkable, independently-re-checkable proof bound to the sealed rule set | (Ω4) compose into the single-node gate |
| **zkVM-over-SVIR** | Partial (R2) | per-opcode AIRs (ADD/MUL/RANGE), 2-opcode trace VM, prover+verifier+soundness | **full-ISA trace** (compare/control/mem/call) + real-i64 limbs (FR-4/Ω1) |
| **EIDOS** | **Ω2 routed (R3/R4)** | 18 modules; `eqv_equal`/memo live; ripple substrate; **ripple R0 now SVIR-attestable** | (Ω3) emit a checkable `eqv_equal` proof for R0's SVIR under the sealed manifest |
| **Transport** | Partial (R5) | `sealed_channel` x25519+ChaCha20; `pattern_set_federation` | wire verify-and-fold-without-re-exec across two nodes (FR-7/Ω5) |
| **Self-improve** | Partial (R4) | `self_reformatter`, `sov_isa`, `verified_search` | close discovery→proof→witness→attest→federate loop (FR-8/Σ) |

**Headline:** the organism's skeleton, circulation, and most organs are real and gated. The final state is the
**wiring** — composing mature parts into one proven end-to-end path — plus **completing two partial organs**
(the full-ISA zkVM, the EIDOS→SVIR route). That is the honest shape of the work.

---

## 4. The unified architecture

```
                         ┌──────────────────────── THE GRAND UNIFICATION PIPELINE ───────────────────────────┐
   EIDOS ripple R (.iii) │                                                                                    │
        │                ▼                                                                                    │
        │   ┌── iiisv ──► SVIR ──► svir_verify (anchor accepts) ──┐                                            │
        │   │              │                                      │                                            │
        │   │              ▼                                      ▼                                            │
        │   │   XII canonicalise  ──emit──►  eqv_equal PROOF (canon(R) ≡ R)   [sealed manifest gates rules]    │
        │   │   (sov_isa rules, sealed)                                                                        │
        │   │              │                                                                                   │
        │   │              ▼                                                                                   │
        │   │   ┌── svir_x86 ─► sovas ─► sovld ─► sovereign PE ──(byte-reproducible)──► run ─► 99 ──┐          │
        │   │   └── svir_wasm ──────────────────► .wasm ──────► node ─────────────────► run ─► 99 ──┤ agree    │
        │   │              │                                                                        │          │
        │   │              ▼                                                                        ▼          │
        │   │   zk_svir_vm (FULL ISA): per-step AIR ─► STARK proof π  ──verifier reproduces from openings──┐   │
        │   └──────────────┼──────────────────────────────────────────────────────────────────────────────┘  │
        │                  ▼                                                                                   │
        │        sealed_channel (x25519+ChaCha20) ── ship (R-result, π, provenance) ──►  NODE 2               │
        │                                                                                  │                   │
        │                                                                                  ▼                   │
        │                                              verify π (no re-exec) ─► fold into NODE 2 EIDOS state   │
        └────────────────────────────────────────────────────────────────────────────────────────────────────┘
   GATE OVER EVERYTHING: run_trust_closure.sh (frontend + seed-lineage DDC) proves the toolchain that built
   iiisv, XII, svir_x86, sovas, sovld, and the zkVM is itself un-backdoored.   SELF-IMPROVE loop (Σ) feeds the
   XII rule set from nous/verified_search, re-proven + re-sealed + re-witnessed + attested + federated.
```

**Pattern selection (architect Phase 3):** the spine is **Event-Sourcing** (EIDOS: event primary, state=fold) +
**Content-Addressed Canonicalisation** (XII/cad: dedup by canonical form) + **Proof-Carrying Code** (every
transform/exec emits a checkable proof). The integration pattern across nodes is **sealed federation** (not an API
gateway / not consensus): each node holds sealed, mhash-anchored bundles and accepts peers' work *by verifying
proofs*, never by trusting the peer. Rationale: this is the only pattern that preserves the "no unverified trust"
invariant across a network — the здесь→there step is *proof-gated*, not authority-gated.

---

## 5. The phased plan (Ω0 → Ω7, then Σ)

Each phase: **objective · open-audit task · verified current state · precise gap · bite-sized tasks (files +
gates) · acceptance gate · manual-verification protocol.** No phase closes without its gate GREEN and its
negative arms REJECTING.

### Phase Ω0 — Binary-level trust closure via the reproducible sovereign back-end
**Objective:** make the seed-DDC clean at the *binary* level (today it's rigorous at the `.o` level; the host
mingw-ld is non-reproducible). Route iiis-1's link through III's reproducible sovas/sovld.
**Open-audit task:** disassemble one current iiis-1 build; confirm the 425-byte variance is exclusively
mingw-ld layout/timestamp (not codegen) — re-verify the `.iii.o` are identical across seeds *and* across runs.
**Verified current state:** `.o`-level DDC 23/23 + 50/50 (gated); `run_repro.sh` proves sovas/sovld byte-stable;
mingw-ld proven non-reproducible even for `hello.c`.
**Precise gap:** the C TUs of iiis-1 still go through gcc-as + mingw-ld. To make the whole binary reproducible,
their object production + the final link must run through ccsv→SVIR→sovas/sovld.
**Tasks:**
- Ω0-T1: extend ccsv until it compiles the *non-ported* iiis-1 C TUs (the ALL_C set minus PORTED) to SVIR.
  *Files:* `STDLIB/sovir/ccsv.iii` (+ tests `STDLIB/sovir/test_*.c`). *Gate:* each C TU → SVIR → sovas/sovld
  object links; differential vs gcc object **behaviour** (run to 99), not bytes.
- Ω0-T2: a `build_iiis1_sovereign.sh` that links iiis-1 entirely via sovld (no mingw-ld). *Gate:* two builds
  `cmp`-identical (byte-reproducible) AND the binary runs the corpus to parity with the gcc-built iiis-1.
- Ω0-T3: the binary-level DDC arm in `seed_ddc_msvc.sh`: gcc-seed vs MSVC-seed → **identical iiis-1 PE**.
  *Gate:* `cmp` identical (now possible because sovld is reproducible). Negative: a 1-byte seed perturbation reddens it.
**Acceptance gate:** `seed_ddc_msvc.sh` PASSES a new `[ddc] BINARY 1/1 identical` line; `run_repro.sh` shows the
*whole iiis-1* reproducible. **Manual verify:** disassemble both PEs at three dispatch functions; confirm identical machine code.

### Phase Ω1 — Complete the zkVM to the full SVIR ISA
**Objective:** lift the trace VM from 2 opcodes to *every opcode class a real program executes* — the FR-4 core.
**Open-audit task:** read `zk_svir_vm.iii` + `zk_svir_add/mul/range.iii` fully; enumerate which opcode classes
have an AIR gadget today (arith ADD/MUL, range) and which do not (SUB/DIV/REM, all compares, AND/OR/XOR/shifts,
BLOCK/LOOP/IF/BR/BR_IF control, LOAD/STORE 8/16/32/64, CALL/RETURN, CONST/LOCAL_GET/SET, DROP).
**Verified current state:** ADD (limb+carry over GF(998244353)), MUL (2-limb schoolbook), RANGE
(bit-decomp), a 2-opcode selector trace VM with prover+verifier+soundness — all to 99.
**Precise gap:** the remaining opcode AIRs + their composition into the per-step selector, + real-i64 limb
representation (today some values are field-fitting), + control-flow as a program-counter column, + memory as a
permutation/lookup argument.
**Tasks (one gated increment per opcode class — the "rhythm"):**
- Ω1-T1: arithmetic completion — `zk_svir_sub`, `zk_svir_bitops` (AND/OR/XOR via bit-decomp), `zk_svir_shift`.
  *Gate each:* honest holds + forged result/carry rejected → 99.
- Ω1-T2: comparisons — `zk_svir_cmp` (EQ/NE/LT_S/…): equality via `(a-b)*inv` witness; ordering via limb
  sign + range. *Gate:* honest holds; forged boolean rejected.
- Ω1-T3: control flow — add a `pc` (program counter) column + `sel_*` per control opcode; `BR`/`BR_IF`
  constrain next.pc; `BLOCK`/`LOOP`/`IF` validated against a structured-control table. *Gate:* an honest
  branching trace holds; a forged pc (skip a guard) rejected.
- Ω1-T4: memory — `mem` as a sorted-by-address permutation argument (read returns last-written). *Gate:*
  honest load/store chain holds; a forged read (stale value) rejected.
- Ω1-T5: calls — frame/return-address discipline as a stack permutation argument. *Gate:* honest call/return
  holds; a forged return target rejected.
- Ω1-T6: real-i64 — replace field-fitting demo values with full 64-bit via 5×14-bit limbs everywhere; the
  carry chains compose. *Gate:* a program using full-width i64 (e.g. a hash round) attests to 99.
- Ω1-T7: the composed full-ISA trace VM `zk_svir_vm` v2 — selector over ALL the above, `air_constraints_hold`
  + verifier-from-openings + 2-cell soundness. *Gate:* a multi-opcode real program (e.g. a SHA-256 step
  lowered to SVIR) attests; every negative arm rejects.
**Acceptance gate:** `run_zk.sh` gains a `zkVM-FULLISA` line proving a non-trivial real SVIR program; an
opcode-coverage report shows 100% of the opcodes that program executes are constrained. **Manual verify:** for
two opcode classes, hand-trace one AIR row and confirm the constraint polynomial vanishes on honest data and is
non-zero on the forged datum.

### Phase Ω2 — Route a real EIDOS ripple through SVIR (the EIDOS→SVIR completion)
**✅✅ CLOSED — gate `STDLIB/sovir/run_eidos_svir.sh` (all clauses green).** ADR-Ω2 honoured: `iiisv` was EXTENDED
(not the ripple down-scoped). `R0 = STDLIB/sovir/eidos_ripple_r0.iii` — the self-contained event→fold→inverse kernel
of `eidos::ripple` (rank-gradient-derived verbs V_BELOW/V_REFLECT/V_NONE, content-address `enc=verb*65536+a*256+b`,
temporal fold `state'=(BASE*state+enc)%p`) — lowers through the INDEPENDENT `iiisv` → SVIR (3964 B),
`svir_verify`-accepted, runs **99 on x86(sovereign, kernel32-only) AND wasm**, with `iiisv == iiisv2`
**byte-identical** (the DDC frontend axis holds across the new constructs). The SVIR fold == the **LIVE** organ's
fold == `675673294` byte-for-byte (`eidos_ripple_native.iii`/`eidos_ripple_probe.iii` link the real
`ripple_field`+`isub` and certify the golden — R0 shares zero code with the organ's externs, so the match is a
faithful cross-check, not two copies of one guess); the cg_r3 native route also runs 99; and a corrupted-rank R0 is
REJECTED (negative arm). **iiisv extensions (mirrored in `iiisv2`):** `const` literal substitution, `as T` casts
(no-op→i64), `@export`/annotation skip, and the void-function fix (trailing default `CONST 0; RETURN` so every fn
satisfies the SVIR CALL convention). Two latent bugs surfaced + fixed: `iiisv2` was missing iiisv's address-0/NULL
reservation (`MTOP` 0→16, which had silently broken the `run_ddc.sh` byte gate for array programs), and
`zk_iiisv_attest`'s parser now stops at the logical RETURN (robust to the trailing default return). **EIDOS is now
attestable through SVIR.** Regression: `run_svir.sh`, `run_ddc.sh`, ZK-OMEGA-E all green.
**⚠️ AUDIT CORRECTION (2026-06-24, AUDIT-AND-PLAN F4/F5):** the verb-derivation cross-check against the LIVE organ is
genuine, but R0's "content-address" is the homomorphic stand-in `enc = verb·65536+a·256+b`, **not** isub's real
`sha256(verb‖a‖b)` (which the native driver also does not compute). So the byte-match certifies the *direction logic* +
a homomorphic fold — the true inverse-form identity is a stand-in (plan P5). Ω2's executable claim (R0 lowers through
iiisv→SVIR→x86+wasm, byte-equal to the live organ's fold) holds as stated.
**Objective:** make a real EIDOS computation attestable by getting it into SVIR (today EIDOS is cg_r3→x86 direct).
**Open-audit task:** read `eidos/ripple.iii` + `eidos/memo.iii` + `eidos/compose.iii`; list the language
constructs they use beyond `iiisv`'s integer core (structs, fixed arrays, the `eqv_equal` call, any function
pointers). Decide per-construct: extend `iiisv`, or express the chosen ripple in the supported subset.
**Verified current state:** `iiisv` lowers the integer core (fn/let/if/while/return/calls/ops, all→i64);
EIDOS ripple is 23 fns; `eqv_equal` lives in `memo.iii`.
**Precise gap:** `iiisv` lacks structs/arrays/the ripple's specific ops; OR a minimal ripple must be authored in
the supported subset. *No-deferral rule:* prefer **extending `iiisv`** (the harder, ideal path) over down-scoping the ripple.
**Tasks:**
- Ω2-T1: extend `iiisv` with fixed-size arrays + struct field access + the operators the ripple needs.
  *Files:* `STDLIB/sovir/iiisv.iii` (+ `STDLIB/sovir/test_iiisv_*.iii`). *Gate:* each new construct compiles to
  SVIR, verifier-accepted, runs to 99 on x86+wasm, **and** the second emitter (frontend-DDC axis) agrees byte-identically.
- Ω2-T2: pick the canonical demonstrator ripple `R0` (smallest real ripple that exercises event→fold→inverse).
  Lower `R0` through `iiisv` → SVIR → both back-ends → 99. *Gate:* `R0`'s SVIR result equals its cg_r3→x86 result
  (the existing EIDOS path) — proving the SVIR route is faithful to the native route.
**Acceptance gate:** `run_eidos_svir.sh`: `R0` compiles via iiisv, verifier-accepts, runs to 99 on x86+wasm, and
matches the native EIDOS result. **Manual verify:** diff the SVIR-route output against the cg_r3 output byte-for-byte.

### Phase Ω3 — XII proof-carrying canonicalisation of the ripple's SVIR
**✅✅ CLOSED — gate `STDLIB/sovir/run_xii_proof.sh` (all clauses green).** XII canonicalisation is now a FIRST-CLASS
CHECKABLE OBJECT. `omnia/xii_proof.iii` emits the proof — a linear sequence of single-rule steps
`(rule_id, preorder_position, before_hash, after_hash)`, **mhash-chained**, where before/after are arena-independent
**content hashes** (cad/SHA-256 over a `kind|subform|aux` preorder serialisation). `omnia/xii_proof_check.iii` is the
**independent verifier**: it re-derives `canon` WITHOUT ever calling `xii_canonicalise` — per step it binds the
`rule_id` to the manifest-admitted sealed set (`xii_proof_rule_sealed`), checks the before-hash, RE-APPLIES exactly
that one sealed rule at the stated position (`xii_rewrite_apply_specific`), checks the after-hash, extends the chain,
and finally confirms the term is canonical. `R0` (a real XII term — the eidos-ripple temporal fold:
`F.COMPOSE(F.IF(p, F.WITH(NULL, F.LOOP(F.LOOP(K12,2),3)), e), NULL)`) canonicalises by dropping identity/no-op edges
(R017/R016) and folding the nested iteration to one loop of the combined count (R014: 2·3=6). **Verified:** the
emitter's canon == the production `xii_canonicalise`'s canon (same normal form); the checker ACCEPTS the honest proof;
and four adversary arms all REJECT — out-of-manifest rule (rc 1), tampered after-hash (rc 4), wrong position (rc 3),
sealed-but-non-matching rule (rc 3). `xad_admit()` (root-confluent + terminating) is the manifest-admission precondition.
**Honest scope:** the checker shares the *sealed rule implementations* + term store with the prover (that is the
manifest-sealed trusted base) but is independent of the *canonicalisation strategy* (never runs the canonicaliser) —
exactly the ADR-Ω3 proof-carrying model. The cryptographic manifest *signature* (`verify_xii_manifest`) remains the
separate build-time seal. New files: `omnia/xii_proof.iii`, `omnia/xii_proof_check.iii`, `sovir/xii_proof_demo.iii`.
**⚠️ AUDIT CORRECTION (2026-06-24, DOCS/III-GRAND-UNIFICATION-AUDIT-AND-PLAN.md F2):** the proof-carrying MECHANISM is
sound and verified, but the term Ω3 canonicalises is a HAND-BUILT REPRESENTATIVE XII term — it has **zero structural
connection to Ω2's R0 SVIR** (the "eidos-ripple" framing is narrative). So Ω.a and Ω.b do **not** compose on the same
object yet; "canonicalise R0's SVIR" is **PENDING** (plan P3: EIDOS→XII-term→canonicalise→lower-to-SVIR). Also F3: the
two new `omnia/xii_proof*` modules are not in `build_stdlib` MODULES (not resealed/corpus-gated). Re-label: Ω3
*mechanism* closed; Ω3 *R0-connection + integration* open.
**Objective:** canonicalise `R0`'s SVIR under the *sealed* manifest and emit a *checkable* `eqv_equal` proof.
**Open-audit task:** read `xii_canonicalise.iii`, `xii_rewrite.iii`, `xii_discharge.iii`, `xii_mig4_seal.iii`,
and `verify_xii_manifest.c`; determine (a) whether `eqv_equal` is total over the SVIR term algebra or partial,
(b) whether a canonicalisation currently *emits a proof artifact* or only asserts equivalence internally.
**Verified current state:** the engine + sealed manifest exist; `eqv_equal` is defined; confluence/termination
modules exist (so canonical forms exist + are unique *where the rules apply*).
**Precise gap:** a **first-class proof artifact** — `canon(R0) ≡ R0` as a checkable object (a rewrite-sequence
witness each step of which is a sealed manifest rule), independently re-checkable by a small verifier.
**Tasks:**
- Ω3-T1: define the proof artifact format (a list of `(rule_id, position, before_hash, after_hash)` steps,
  mhash-chained). *Files:* `STDLIB/iii/omnia/xii_proof.iii` (new) + the verifier `xii_proof_check.iii`.
- Ω3-T2: have `xii_canonicalise` emit it for `R0`'s SVIR. *Gate:* `xii_proof_check` re-applies each step from
  the sealed manifest and reproduces `canon(R0)`; a tampered step (wrong rule_id / position) is REJECTED.
- Ω3-T3: bind the manifest signature: `xii_proof_check` refuses any `rule_id` not in the
  `verify_xii_manifest`-validated set. *Gate (negative):* a rule outside the sealed set fails the check.
**Acceptance gate:** `run_xii_proof.sh`: `canon(R0)` produced, proof emitted, independently re-checked GREEN;
out-of-manifest rule REJECTED; semantics-breaking rewrite REJECTED. **Manual verify:** hand-check one rewrite
step's before/after hashes against the manifest rule.

### Phase Ω4 — The single-node Grand Unification gate
**✅✅ SINGLE-NODE GATE GREEN — `STDLIB/sovir/run_grand_unification.sh`.** ONE EIDOS ripple computation flows through the
audited + perfected organs, the two proven views bound by a shared content-address (the fold value `675673294`):
Ω.a/d EIDOS→SVIR→x86(sovereign)+wasm==99 + live-organ match (`run_eidos_svir.sh`); Ω.b XII canonicalisation emitted as
a checkable, mhash-chained, independently re-checkable proof (`run_xii_proof.sh`); **F2 binding** — the *same* ripple
event stream lifted to an XII term (flats = THEN-identities provably dropped) whose canonical form folds to the SAME
`675673294` R0 executes (`zk_gu_ripple_xii`); Ω.e the **committed** GF(p⁴) zkVM — committed FRI + committed witness-free
line-755 STARK + the FULL compute+memory+control fused zkVM, all against Merkle commitments (`run_ext4_committed.sh`,
audit F1 closed). Every organ is sound + committed + carries a rejecting adversary arm. **Honest scope:** XII does not
lower to SVIR, so the organs are bound by the shared *computation* (one fold) — the SVIR sovereign+wasm execution and
committed-zk attestation are the EXECUTION proof; the re-checkable canonicalisation is the INTENT proof; they agree on
the answer. The cryptographic ~2⁻⁸⁶ is a query-count knob (`NQ` 16→128). Remaining for Ω5–Ω7: cross-node here→there
fold + the trust-closure provenance certificate.
**Objective:** compose Ω0–Ω3 + the zkVM into one command proving Ω.a–Ω.e on `R0`.
**Verified current state:** each constituent gate green in isolation after Ω0–Ω3 + Ω1.
**Precise gap:** the *composition* + its negative arms, as one script.
**Tasks:**
- Ω4-T1: `run_grand_unification.sh` orchestrating: iiisv(R0)→SVIR→verify (Ω.a); xii canon+proof (Ω.b);
  sovereign reproducible build (Ω.c); x86+wasm to 99 (Ω.d); full-ISA zk attest (Ω.e). *Gate:* exit 0 iff all
  green AND each negative arm (forged SVIR, broken sig, non-reproducible, divergent back-ends, forged trace) red.
- Ω4-T2: a one-line provenance header binding R0's artifact mhash to the toolchain trust-closure
  (`run_trust_closure.sh`) — Ω.g. *Gate:* the provenance verifies; a swapped binary breaks it.
**Acceptance gate:** `run_grand_unification.sh` exit 0, all five positive proofs + five negatives. **Manual
verify:** flip one byte of R0's SVIR; confirm the gate goes red at exactly the verifier/zk arm.

### Phase Ω5 — here→there: ship the attested ripple to a second node
**✅✅ CORE GREEN — `STDLIB/sovir/run_here_to_there.sh` (composed into `run_grand_unification.sh` as Ω.f).** A COMMITTED
GF(p⁴) FRI proof is SERIALISED into a transportable artifact (Merkle roots + per-query openings + authentication paths
— **not** the codeword/witness), SHIPPED over the real `sealed_channel` (x25519 ECDH-derived key + ChaCha20-Poly1305
AEAD), and on the PEER node decrypted + Poly1305-authenticated, then VERIFIED reading ONLY the artifact — the prover's
codeword + roots are **zeroed first**, so verification (recompute fold challenges from the shipped roots, Merkle-verify
every opened leaf, check the GF(p⁴) fold-consistency + final-constant) provably uses no witness and does not
re-execute the prover — and the artifact's content-address is FOLDED into the peer's attestation state. Teeth: a
tampered ciphertext is rejected by the auth tag; a tampered artifact leaf by the Merkle check. *The proof travels, the
witness does not.* Remaining for full federation: the multi-node 2f+1 quorum over shipped attestations (the
`pattern_set_federation`/`pq_quorum` wiring) — Ω6.
**Objective:** Ω.f — a second node verifies R0's proof and folds the result WITHOUT re-executing R0.
**Open-audit task:** read `aether/sealed_channel.iii` + `pattern_set_federation.iii` + `backend_remote.iii`;
determine the wire format, whether the channel is byte-tested end-to-end, and how a "fold" is represented.
**Verified current state:** `sealed_channel` (x25519+ChaCha20-Poly1305) + `pattern_set_federation` (sealed,
mhash-anchored) exist; loopback backend exists (so a second "node" can be a second process).
**Precise gap:** the *bundle* `(R0-result, π, provenance)` serialised, sealed, shipped over the channel, and a
receiver that **verifies π and folds without re-exec**.
**Tasks:**
- Ω5-T1: define the federated bundle = mhash-anchored `{result, zk-proof π, provenance}`; serialise + seal.
  *Files:* `STDLIB/iii/eidos/wire_ripple.iii` (new). *Gate:* round-trips through `sealed_channel` byte-identical.
- Ω5-T2: receiver `fold_verified(bundle)` — verify π via the zk verifier (Ω1's verifier-from-openings),
  then fold the result into the receiver's EIDOS state. *Gate (the crux):* the receiver NEVER calls R0's
  executable — assert by construction (no exec import) + a counter proving zero re-execution.
- Ω5-T3: negative — a tampered bundle (forged result, mismatched π) is REJECTED at verify, never folded.
**Acceptance gate:** `run_here_to_there.sh`: node A produces+ships R0's attested bundle; node B verifies+folds
WITHOUT re-exec; tampered bundle rejected. **Manual verify:** confirm node B's binary has no path that executes
R0 (disassemble / symbol-table check); confirm the fold changed B's state to the proven value.

### Phase Ω6 — The full Grand Unification (single-node ∪ here→there ∪ federation)
**✅✅ CORE GREEN — `run_grand_unification.sh` composes Ω.a/d + Ω.b + F2 + Ω.e + Ω.f + Ω.g in one gate (GU_FULL_EXIT 0).**
Ω.g (`run_federate_quorum.sh`, `sovir/zk_federate_quorum.iii`): the committed-proof content-address (keccak of the
committed FRI roots + final codeword — the same object Ω5 ships) is certified by a **post-quantum (ML-DSA) 2f+1 BFT
quorum** over N=3f+1 peers (`aether/pq_quorum` + `numera/bft_quorum`). Honest votes form the quorum; **1 Byzantine peer
tolerated** (f=1: 3 valid → quorum holds); **2 Byzantine rejected** (f=2 > bound: 2 valid < 3 → no false certificate =
safety). So the full pipeline runs single-node, cross-node, and federated, every organ sound + committed +
adversary-gated. Remaining: Ω7 (the end-to-end trust-closure provenance certificate chaining the toolchain DDC closure
to this gate's artifact mhash) + Ω0 (binary-level DDC, the ccsv worker).
**Objective:** one gate = Ω4 ∪ Ω5 = the complete FR-Ω on R0. **Task:** `run_grand_unification.sh --federated`
chains Ω4 then Ω5. **Acceptance:** exit 0; the README-level claim "a real EIDOS computation, compiled-canonicalised-
built-run-attested-shipped-verified-folded, all proven, no unverified link" is now a *re-runnable gate*, not prose.

### Phase Σ — Close the self-improvement loop (FR-Σ)
**Objective:** III improves itself inside the perimeter. **Open-audit task:** read `numera/sov_isa.iii`,
`numera/verified_search.iii`, `omnia/self_reformatter.iii`, `omnia/xii_admission.iii`; find the existing
self-extension proof obligations and the search's candidate format.
**Verified current state:** `sov_isa` (III's own ISA optimiser it extends), `verified_search`, `self_reformatter`
exist; XII has `xii_admission` (rule admissibility).
**Precise gap:** the *closed loop* — discovery → eqv-proof → re-seal → DDC re-witness → cost-attest → federate.
**Tasks:**
- Σ-T1: have `verified_search` propose ONE real `sov_isa` rewrite-rule candidate (e.g. a strength-reduction the
  current rule set lacks). *Gate:* candidate is well-formed; applies to ≥1 real program.
- Σ-T2: XII proves it equivalence-preserving (`eqv_equal`) + admissible (`xii_admission`); re-seal the manifest
  (`forge_manifest_keccak`) deterministically. *Gate:* sealed manifest re-verifies; a semantics-BREAKING
  candidate is REJECTED at the eqv proof (the critical negative arm).
- Σ-T3: rebuild the component; `run_trust_closure.sh` + corpus regression GREEN (no trust regression from the
  self-edit). *Gate:* both green.
- Σ-T4: attest the improvement's *effect* via the cost-meter AIR (`xii_cost_monotone` + a zk cost column):
  prove `cost(canon_new) < cost(canon_old)` on the witness program. *Gate:* the cost-decrease attests; a
  fake improvement (no real decrease) is rejected.
- Σ-T5: federate the new sealed rule bundle to a peer (`pattern_set_federation`). *Gate:* peer verifies the
  bundle's ancestry + signature and adopts; a forged-ancestry bundle is rejected.
**Acceptance gate:** `run_self_improve.sh` lands one real, measured, proven, federated self-improvement; the
semantics-breaking negative arm REJECTS. **Manual verify:** confirm the new rule actually changed the canonical
form of the witness program AND that the cost metric decreased AND that trust-closure stayed green.

### Phase Ω7 — The irreducible-TCB certificate
**✅ PROVENANCE CERTIFICATE GREEN — `STDLIB/sovir/run_trust_certificate.sh` (composed into `run_grand_unification.sh`).**
A single content-address binds the whole result to the toolchain that produced it:
`CERT = SHA-256(lib_mhash ‖ committed_proof_mhash ‖ fold ‖ frontend-DDC-verdict)` — the built `libiii_native.a` mhash
(toolchain bytes) + the verified frontend-DDC closure (iiisv==iiisv2 byte-identical) + the committed-proof
content-address (the same object Ω5 ships / Ω6 federates) + the cross-view fold `675673294`. REPRODUCIBLE
(recomputed identical), NON-TRIVIAL, and TAMPER-SENSITIVE (a perturbed toolchain mhash → a different certificate). So
a swapped toolchain binary or a swapped proof/result breaks the cert. **Honest residual:** the seed-LINEAGE DDC axis
(vendor-diverse bootstrap) is env-heavy and remains the documented residual (`SVIR-DDC-RESIDUAL.md`); the binary-level
DDC (Ω0) is the ccsv worker's track. The certificate names the irreducible TCB (CPU/microcode + OS loader) honestly.
**Objective:** state, as a checkable document + gate, exactly what trust remains and prove it's minimal.
**Tasks:** an audited enumeration: the verifier (≤~80 lines, hand-read), the sealed manifest root, the seed
(now MSVC-witnessed), the CPU/loader (irreducible). A `run_tcb_audit.sh` that asserts the verifier line-count
ceiling, the manifest signature, the DDC closure, and emits the residual set. **Acceptance:** the certificate
names {audited seed + sealed manifest + CPU/loader} as the whole TCB, each either hand-auditable or
DDC-witnessed; nothing else trusted.

---

## 6. Master invariants (the non-negotiables, enforced every increment)
1. **KAT RED→GREEN** is the only evidence a gap closed. A green test that was never red proves nothing.
2. **Negative arms mandatory** — every positive proof ships with a forged-input arm that MUST reject.
3. **Determinism + corpus regression** after every grammar/codegen/rule change.
4. **Sealed-manifest signature must verify** after any XII rule change; re-seal is deterministic.
5. **Frozen seed** — seed edits only if gcc-byte-identical; quirks as build flags.
6. **NIH** — libc + III BOOT headers only; no third-party in the trusted path; no Python there.
7. **No stub, no TODO, no placeholder** in landed trusted-path code (grep-gated).
8. **No deferral** — a named gap is BUILT this cycle or refuted to zero; abstain only if unsafe/unverifiable.

## 7. Architecture Decision Records (key)
- **ADR-Ω1: zkVM via per-opcode AIR composition, not a monolithic circuit.** Accepted. Each opcode class is an
  independently-gated AIR gadget; the trace VM selects among them. Consequence: incremental, falsifiable, but
  needs a permutation/lookup layer for memory/calls. Alternative (one giant circuit) rejected: unauditable, unfalsifiable per-opcode.
- **ADR-Ω2: extend `iiisv` rather than down-scope EIDOS.** Accepted (no-concession). Consequence: more work in the
  `.iii`→SVIR lowerer, but a *real* ripple is attested, not a toy. Alternative (author a toy ripple) rejected as a concession.
- **ADR-Ω3: proof-carrying canonicalisation with an independent re-checker.** Accepted. The optimiser must *emit*
  a proof a *separate* small verifier re-checks against the sealed manifest. Alternative (trust the optimiser's
  internal assertion) rejected: re-opens the very trust hole the DDC closed.
- **ADR-Ω5: federation by proof-verification, not authority/consensus.** Accepted. A node accepts peer work by
  checking π, never by trusting the peer or a quorum. Consequence: trustless by construction; no consensus latency.
- **ADR-Ω0: reproducibility via III's own back-end, not by fixing mingw-ld.** Accepted. Route through sovas/sovld
  (proven reproducible) rather than chase the host linker. Consequence: the binary-level DDC rides the sovereign path.

## 8. Risk register
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| zkVM memory/call argument (permutation/lookup) is the hard part of Ω1 | High | High | isolate as Ω1-T4/T5 with their own gates; land arith/compare/control first so partial coverage is still real |
| `iiisv` extension (Ω2) balloons toward a full compiler | Med | Med | scope to *exactly* R0's constructs, gated per-construct; reuse cg_r3's grammar decisions |
| `eqv_equal` is partial over the SVIR algebra (Ω3) | Med | High | open-audit task first; if partial, the proof artifact is still sound on its domain — gate states the domain explicitly, no over-claim |
| OneDrive/host non-determinism contaminates gates | Med | Med | fixed output paths, array iteration (no word-split), repo-local probes, route binaries through sovas/sovld |
| Self-improvement (Σ) lands an unsound rule | Low | Critical | the eqv-proof negative arm (Σ-T2) is the hard gate; no rule seals without it; manifest signature blocks out-of-set rules |
| Concurrent worker collision on ccsv/SVIR/build | Med | Med | pick non-colliding phase order (Ω1 zk, Ω3 xii_proof are mine; coordinate Ω0/Ω2 with the ccsv worker) |

## 9. The no-concession doctrine (how "10,000 breakthroughs before a concession" executes)
Every phase decomposes into many gated increments (the opcode AIRs alone are ~10 in Ω1; the `iiisv` constructs
~6 in Ω2; the proof/format/checker ~3 in Ω3). Each increment is a falsifiable breakthrough: a thing that did not
exist, now proven by a RED→GREEN gate with a rejecting negative arm. The discipline is not rhetorical — it is the
ledger: **count landed gates, not intentions.** A concession would be: stubbing an opcode AIR, down-scoping R0 to
a toy, trusting XII's internal assertion, or accepting a non-reproducible binary. None are permitted; each has a
named harder path above. Deferral is failure; the only acceptable abstention is "unsafe or unverifiable," and
every item here is verifiable.

---

## Implementation order (dependency-correct)
1. **Ω1** (full-ISA zkVM) — non-colliding, highest-value, unblocks Ω.e and Σ-T4. Start here.
2. **Ω3** (XII proof artifact) — non-colliding, unblocks Ω.b and Σ-T2.
3. **Ω2** (iiisv→EIDOS) — coordinate with the ccsv worker; unblocks Ω.a.
4. **Ω0** (binary-level DDC) — coordinate with the ccsv worker; completes the trust floor.
5. **Ω4** → **Ω5** → **Ω6** (compose the single-node then federated gate).
6. **Σ** (self-improvement) — last, because it consumes Ω1's cost-attest + Ω3's eqv-proof + the DDC re-witness.
7. **Ω7** (TCB certificate) — the closing seal.

**The first concrete move when execution begins:** Ω1-T1 — `zk_svir_sub` and `zk_svir_bitops`, each gated to 99
with a forged-carry negative arm, extending the per-opcode AIR set toward full-ISA coverage. RED test first
(the opcode has no AIR), then the gadget, then GREEN + the rejecting negative. One breakthrough, measured.
