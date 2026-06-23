# SVIR — DDC Frontend-Closure + Integer-Language Formalization: Conceptualization, Audit, Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans (inline; **no subagents on III**).
> Steps use `- [ ]`. Process: main-session, gate-driven, commit per task.
> **Date:** 2026-06-23. Conceptualization + audit are the primary deliverable; the plan is the culmination.

---

## Part I — Conceptualization (honest, three tiers, no hype)

**The core, stated plainly.** SVIR — the deterministic integer stack machine built this session — is a **spine**. III has, independently and over a long arc, grown an unusual concentration of exactly the organs a *high-assurance execution substrate* needs (ZK proving, content-addressed log/fold, reversibility, a bare-metal seam). None are yet fused with SVIR. The vision is that fusion: **a verifiable integer-execution substrate for the narrow domain where trusting an opaque third-party compiler is an existential threat** (root-key facilities, high-value ledgers, life-critical state machines). It is *useless* for general computing (no floating point, no objects, manual memory) — that is the deliberate trade, not a defect.

**Why integer-only is the correct identity (a real engineering reason, not a slogan).** Cryptography, hashing, ZK, and ledger state-transitions are exact integer math. Floating-point is hardware-dependent and **non-deterministic across architectures**. An integer-only SVIR yields **bit-identical state on x86 / WASM / (RISC-V)** — which is the precondition for both *ZK-provable* execution and *cross-architecture reproducible* execution. That same property is why SVIR can't run a browser and can be a trust anchor.

**The four properties — tiered by what is actually true today:**

| Tier | Property | Status |
|---|---|---|
| **Real + verifiable here** | SVIR as a deterministic **integer language**; **DDC frontend-closure** (two emitters converge byte-identically); **log-fold state** over `ripple`/`merkle` | buildable now |
| **Real organs, fusion unbuilt** | **ZK proof-of-execution** — `zk_air` is a *general* STARK prover (verified, see audit); the work is arithmetizing the SVIR ISA. **Reversibility/snapshot** self-heal | reachable, delicate |
| **Horizon (NOT a roadmap, NOT buildable/verifiable here)** | sovereign silicon (FPGA/ASIC native stack machine); ZK-rollup throughput; multi-generational self-healing; **Ring-(−1) "melt into any host"** — III's own *open core*, the hardest unsolved part | where it points |

I deliberately do not adopt the pasted exploration's vocabulary ("military-grade," "cryptographically bulletproof," "the most secure calculator"). That register is precisely what this architecture is built to reject: the value is *humanly auditable certainty*, and claims must be gated, not asserted.

---

## Part II — Audit: what III already has (maturity-tiered)

Every pillar of the vision already has a III component. **Caveat carried throughout: "organ exists" ≠ "organ is general." Each fusion must be RED-proven against a real oracle, never a toy.**

| Pillar | III component(s) | Maturity (audited) |
|---|---|---|
| Deterministic integer machine | **SVIR + `iiisv`** (this session) | **REAL, gated** (5 programs ×2 arches; real `.iii` via independent compiler) |
| DDC frontend | `iiisv` (1 emitter). `cg_r3` emits **x86, not SVIR** — cannot byte-match SVIR | **1 of 2 emitters**; canonical encoding not yet frozen |
| **ZK proof-of-execution** | **`numera/zk_air.iii` — the *general* AIR organ** (W columns, data-driven degree-≤2 transition + boundary constraints, FRI low-degree test, Merkle commit, Fiat-Shamir, written soundness proof, GF(998244353)); `zk_stark`, `zk_snark`, `proof_stark`, `zk_field`, `merkle`, `ntt`, `ntt_fri_organ`, `aether/cap_zkp` | **REAL + GENERAL prover** (header + API confirm data-driven, not a fixed circuit); SVIR-ISA arithmetization **not built** |
| Functional log-fold state | `eidos/ripple.iii` (inverse-event fold-over-history, ~110 L), `ripple_journal`, `merkle`, `constants_ledger`, `eidos/isub` (content-addressed) | **REAL organs, POC-scale**; not fused to SVIR |
| Reversibility / self-heal | `vbd_reversible_rollback`, `snapshot_lattice`, `reversible_iso`, `xii_lattice_replay` (avx2/arm/riscv deterministic replay) | **REAL**; not fused to SVIR |
| Bare-metal seam | `katabasis/`: `cpu_census`, `pci_enum`, `vmexit`, `svm_layout`, `descent_proof` (~49 L), `bricking` (~68 L), `crystal_cap` ("identity crystal"), `ring_lattice` | **REAL organs; descent = OPEN CORE** (hardest, not buildable-here) |
| Safe-write-in-guest | `omnia/sandbox_{ctor,exec,quota}`, `aether/sealed_box`, `numera/taint_analysis` | **REAL** |
| Multi-arch codegen | `xii_emit_gen` (avx2 / arm / **riscv** targets) | **REAL** (a separate codegen path from the SVIR translators) |

**The genuinely exciting, true finding:** III did not need to import any of this. It grew its own ZK stack (general STARK + pairing fields), its own reversible/log substrate, its own bare-metal census/seal seam — and the new SVIR/`iiisv` spine is what they can fuse onto. The standout is `zk_air`: a *general* prover means "prove SVIR execution" is **applying** existing III machinery, not building a prover from scratch.

---

## Part III — The Plan (the user's explicit next phase)

The user named it: *"introduce a separate DDC iii-svir emitter and formalize SVIR as a full integer language."* That is the bounded, verifiable-here phase. **Goal:** close **frontend** trust diversity for SVIR and pin its semantics.

**Architecture:** Freeze SVIR v1 as a **canonical, byte-exact encoding** (exactly one valid lowering per source construct). Build a **small, human-auditable SVIR verifier**. Build a **second, implementation-independent `.iii`→SVIR emitter** targeting the same canonical form. Gate: same `.iii` corpus → `iiisv` → SVIR_A; → `iiisv2` → SVIR_B; **byte-identical**, both verifier-accepted, both run to 99 on x86+WASM.

**Tech Stack:** `.iii` (iiis-2), the SVIR v1 module format, the existing `svir_x86`/`svir_wasm` translators, `run_svir.sh`-style gates.

### Global Constraints
- NIH: libc + III only. No subagents (main session). Commit per task. Honest residual stated in the same breath as every claim.
- **DDC scope is FRONTEND-only.** Both emitters' binaries still descend from the gcc-built `iiis-0` seed → this does **not** close the seed. Genuine diversity also needs independent *authorship/tooling*; two emitters by the same author is a *mechanism* demonstration. Both residuals are named, not hidden.

---

### Task 1: Verify the foundations (read before scoping — advisor mandate)

**Files:** Create `DOCS/SVIR-DDC-FINDINGS.md`.

- [ ] **1.1** Re-read `STDLIB/iii/numera/zk_air.iii` in full; record the public API (`air_compile(W,N,...)`, constraint-term encoding, `air_build_lde`, `air_build_cp`, proof/verify entry points) and whether a caller can supply an arbitrary trace+constraint list. (Front-matter already confirms *general*; record the exact signatures for the ZK phase-after.)
- [ ] **1.2** Read `STDLIB/iii/eidos/ripple.iii` fully; record whether it is a genuine `fold(rule, init, log)` over a content-addressed log or a sketch. One paragraph, honest.
- [ ] **1.3** Determinism check: run `iiisv` on `indep_toolchain.iii` twice; `cmp` the two SVIR outputs. Expected: byte-identical (deterministic). Run: `iiisv indep_toolchain.iii > a; iiisv indep_toolchain.iii > b; cmp a b`. If they differ, the encoding isn't yet deterministic — fix before Task 2.
- [ ] **1.4** Enumerate `iiisv`'s de-facto lowering choices (the inputs to the canonical spec): function order (`main` first, then source order), local slot allocation (params then `let`s, declaration order), constant encoding (8-byte LE), `while` lowering (`BLOCK;LOOP;cond;CONST 0;EQ;BR_IF 1;body;BR 0;END;END`), `if/else`, array base allocation (cumulative). Write them down verbatim.
- [ ] **1.5** Commit the findings note.

---

### Task 2: Freeze the canonical SVIR v1 encoding spec (formalize the integer language)

**Files:** Create `DOCS/SVIR-V1-CANONICAL.md`.

- [ ] **2.1** Write the **module format** (verbatim from the working code): `[u8 func_count]` then per function `[u8 params][u8 nresults][u16 LE body_len][body]`; func 0 is the entry; locals `0..params-1` are parameters.
- [ ] **2.2** Write the **op table** (every opcode + operands + stack effect): `CONST_I64 0x01(+8 LE)`, `LOCAL_GET 0x10(+u8)`, `LOCAL_SET 0x11(+u8)`, `ADD 0x20`…`SHR_U 0x29`, `EQ 0x30`…`GT 0x35`, `BLOCK 0x40`/`LOOP 0x41`/`IF 0x42`/`ELSE 0x43`/`END 0x44`, `BR 0x50(+u8)`/`BR_IF 0x51(+u8)`, `RETURN 0x60`, `CALL 0x70(+u8 funcidx +u8 argcount)`, `PRINT_CHAR 0x71`, `DROP 0x72`, `LOAD8 0x80`, `STORE8 0x81`.
- [ ] **2.3** Write the **canonicality rules** (the choices that make the encoding *unique* per source — from Task 1.4): function ordering, slot allocation order, constant width, the exact `while`/`if`/array lowerings, memory base assignment. State: "an emitter is canonical iff, for any accepted `.iii`, it emits these exact bytes."
- [ ] **2.4** Write the **integer-language identity** section: i64-only; deterministic; the FP-non-determinism rationale; the explicit non-goals (no FP/objects/general memory model). One honest page.
- [ ] **2.5** Commit the spec.

---

### Task 3: The auditable SVIR verifier (the trust anchor)

**Files:** Create `STDLIB/sovir/svir_verify.iii`, `STDLIB/sovir/prog_bad.svir.hex` (malformed fixtures).

**Interfaces:** Produces `fn svir_verify(src:u64, len:u64) -> u64` → 0 if valid, else a nonzero error code.

- [ ] **3.1** Write `svir_verify.iii`: parse the module header; for each function walk the body checking — every opcode known; every operand in range (slot < locals, funcidx < func_count, argcount sane, `BR depth` < open-construct count); structured control balanced (`BLOCK/LOOP/IF` open, `END` close, none dangling); a conservative stack-depth model never goes negative and `RETURN`/end leaves exactly one value. Keep it small and auditable (target ≤ ~120 lines; the "humanly auditable verifier" — honest that it's >60 but small).
- [ ] **3.2** Gate (accept): `svir_verify` returns 0 on the `iiisv` outputs of `indep_toolchain`, `indep_ops`, `indep_bignum`, and the 5 hand-SVIR demos. Run via a small `prog_verify_main.iii` driver.
- [ ] **3.3** Gate (reject): mutate each accepted module (bad opcode; out-of-range slot; unbalanced `END`; `BR` past depth) → `svir_verify` returns nonzero for every mutation. **Prove the negative** (do not accept "it passes valid input" as sufficient).
- [ ] **3.4** Commit verifier + fixtures + the accept/reject gate.

---

### Task 4: `iiisv2` — the second, implementation-independent emitter

**Files:** Create `STDLIB/sovir/iiisv2.iii`.

**Interfaces:** Same CLI as `iiisv` (reads argv[1] `.iii`, emits the canonical SVIR module). Must satisfy `DOCS/SVIR-V1-CANONICAL.md` byte-for-byte.

- [ ] **4.1** Implement a **deliberately different** internal strategy from `iiisv` (which is single-pass, hand-rolled precedence-climbing): e.g., a **two-pass** design — build an explicit token+node array, then a separate lowering walk; or a **table-driven** operator parse. Same canonical output. (Honest: same author → *mechanism* diversity, not social diversity; recorded in the residual doc.)
- [ ] **4.2** Compile-check `iiisv2` (iiis-2 rc 0); build the tool.
- [ ] **4.3** Per-program byte check: `iiisv indep_toolchain.iii > a.svir; iiisv2 indep_toolchain.iii > b.svir; cmp a.svir b.svir` → identical. Repeat for `indep_ops`, `indep_bignum`. Fix divergences (they reveal under-specified canonicality in Task 2 — tighten the spec, not a hack).
- [ ] **4.4** Commit `iiisv2`.

---

### Task 5: The DDC gate + honest residual

**Files:** Create `STDLIB/sovir/run_ddc.sh`; create `DOCS/SVIR-DDC-RESIDUAL.md`.

- [ ] **5.1** `run_ddc.sh`: for each program in `{indep_toolchain, indep_ops, indep_bignum}` — `iiisv → SVIR_A`, `iiisv2 → SVIR_B`; assert `cmp -s SVIR_A SVIR_B` (byte-identical); assert `svir_verify` accepts both; assert both lower (via `svir_x86`+sovereign toolchain, and `svir_wasm`+node) and run to 99. Print `DDC FRONTEND-CLOSED` iff all hold.
- [ ] **5.2** Run it; expected `ALL PASS`.
- [ ] **5.3** Write `SVIR-DDC-RESIDUAL.md`: this closes **frontend** diversity (a backdoor in one emitter, absent from the other, reddens the `cmp`); it does **NOT** close the **seed** (both emitter binaries descend from gcc-`iiis-0`), and the author-diversity is the *mechanism* not the social guarantee. Genuine Thompson-defense needs an audited seed and/or independent authorship — named as the remaining work.
- [ ] **5.4** Commit the gate + residual; update `DOCS/III-SOVEREIGN-STACK-ARCHITECTURE.md`.

---

## Part IV — The phase after (named, de-risked by the audit)

**ZK-attested SVIR execution.** Because `zk_air` is a *general* AIR prover (Task 1.1 confirmed), the next phase is reachable: arithmetize a **subset** of the SVIR ISA as an AIR (columns = VM state: stack/locals/pc; rows = steps; transition constraints = per-opcode degree-≤2 relations), build the execution trace for a small SVIR program, prove it with `zk_air`/`zk_stark`, and verify the STARK. Deliverable: *"a sovereign-compiled integer program whose execution is ZK-proven by III's own STARK; tamper the trace → the proof fails."* Delicate (a constraint bug = an unsound proof — RED-prove the negative: a wrong trace must be rejected), bounded (a subset first), and verifiable here. This is the "provable execution" pillar — the property that turns the substrate into a trust anchor.

## Risks
| Risk | Mitigation |
|---|---|
| Treating a POC organ as general (TOY-TRAP) | Task 1 verifies before scoping; maturity tiers stated; RED-prove every fusion |
| `iiisv2` byte-diverges from `iiisv` | Divergences expose under-specified canonicality → tighten the spec (Task 2), never a hack |
| Over-claiming DDC | Residual doc (Task 5.3) names frontend-only + seed + author-diversity limits |
| Verifier accepts malformed input | Task 3.3 proves the negative on mutations |
