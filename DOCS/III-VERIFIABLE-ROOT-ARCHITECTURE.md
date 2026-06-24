# III — From Sovereignty to a Verifiable Root

**The architecture that makes all three claims *literally* true, and the EIDOS end-goal they converge on.**

This document answers one question precisely: the quoted "linchpin" claim is currently **sovereignty-true, not
fully-true** (see `III-CCSV-SEED-GAP-MAP.md` §4 and the honest ladder in project canon). Here is the concrete,
phased engineering program that converts each claim from *sovereignty* to *verifiable mathematical proof* — and how
all three terminate in the stated end-goal: **the sovereign toolchain producing EIDOS's artifacts, and ZK-attesting
EIDOS computations.**

---

## 0. The distinction the claim blurs (and this architecture respects)

| property | question it answers | status today |
|---|---|---|
| **artifact-sovereignty** | is gcc in the *produced binary*? | **NO** — achieved (kernel32-only PEs via SVIR + sovas/sovld) |
| **layout-fidelity (§4)** | does ccsv lay out C bytes like real C? | **partial** — bit-exact values, not byte-identical layout |
| **seed-coverage** | can ccsv compile *all* of iiis-0? | **no** — easy tier + real crypto; core unbuilt |
| **bootstrap-trust (Thompson)** | could a backdoor ride in from the compiler that built the compiler? | **open** — ccsv is gcc-lineage |

The three claims map 1:1 onto the three open rows. Making them true = closing those three rows, in order, because
each is a prerequisite for the next: **layout-fidelity → seed-coverage → bootstrap-trust → EIDOS.**

---

## CLAIM 1 — "Cracks the type-size bottleneck" → make it true: **typed memory in SVIR**

**Today:** SVIR is an i64 stack machine with only `LOAD8/STORE8/LOAD64/STORE64`. So `int`/`uint32_t` storage is 8
bytes; `sizeof(int)=8`; struct layouts differ from C. Crypto is bit-exact *only because* it uses explicit widths +
masking and never serializes a struct. Byte-identity (the seed-DDC standard) is not met.

**The ideal (§4a), made concrete.** The SVIR *stack* stays i64 (operands are i64 — correct, and exactly how WASM's
i64 values work). Only **memory storage becomes width-typed**:

1. **SVIR ISA additions** (the one real ISA change): `LOAD16_U/LOAD16_S/LOAD32_U/LOAD32_S` and `STORE16/STORE32`.
   Net stack effect identical to existing (`LOADn`: net 0; `STOREn`: −2), so `svir_verify.iii` grows by 6 trivially
   correct lines and stays the 74-line auditable anchor.
2. **Translators.** `svir_wasm`: these are *native* wasm ops (`i64.load32_u`, `i64.store32`, …) — near-free.
   `svir_x86`: `movzwl/movzbl/movl` for loads, `mov %ax/%eax,(mem)` for stores — contained, the emitter already
   does width-0/width-3 stores.
3. **ccsv C ABI.** A real type-size table (`char`=1, `short`=2, `int`=4, `long`=8, `uint32_t`=4, …) **plus C
   alignment/padding rules** (align each field to its size; pad the struct to its largest member). `sizeof` returns
   true sizes; struct field offsets and array strides use true sizes; each memory access uses the typed op for its
   width. The recent `uint8_t[]`→stride-1 work is the *proof of the pattern*; this generalizes it to {1,2,4,8}.

**Why this is the crack, not a patch.** It makes ccsv a **real C compiler with a correct ABI**, not a subset. Once
`sizeof`/layout/serialization match the target ABI exactly, iiis-0's byte-emitting code compiles to byte-identical
behavior — the precondition for a byte-identical iiis-1. The crypto suite stays green (masking + typed stores agree).
**Risk:** alignment must match the exact ABI iiis-0 is built under (Win64/SysV) — well-specified, gatable by
differential `offsetof`/`sizeof` against gcc (now a *true* differential, no longer model-divergent).

**Done-definition:** a gated test where ccsv and gcc agree on `sizeof`, `offsetof`, and the *bytes* of a serialized
mixed-width struct — not just a hash value.

---

## CLAIM 2 — "Unlocks the seed DDC" → make it true: **compile the whole iiis-0**

**Today:** ccsv clears the small/medium tier and real crypto (`ceiling.c`'s full SHA API, unmodified). The compiler
core (`parse.c`, `cg_r3.c`, `ast.c`, `sema.c`, `lex.c` — ~14K lines) needs constructs ccsv lacks. This is the **long
but fully-enumerated** road (the gap map is the map). The three hard features, with their architecture:

- **`switch`/`case`** → lower to a `BLOCK`-per-case ladder with `BR` (structured-control jump table); if-cascade as
  the always-correct fallback. MED.
- **function pointers** → add `CALL_INDIRECT` to SVIR + a function-address table; a fn-ptr *value* is a table index;
  calling it is `CALL_INDIRECT` (native in wasm; an indirect `call` on x86). HIGH but bounded — this is the gate for
  `ast.c`/`parse.c`/`cg_r3.c`.
- **`goto`/labels** (concentrated in `ast.c`) → SVIR has only structured control, so use the **big-switch relooper**:
  transform a function with gotos into `loop { switch(state){ case L0:…; state=Lk; continue; … } }`. Every label is
  a state; every goto sets state + continues. This *always* works (it is the textbook unstructured→structured
  transform) and needs no new ISA. MED, mechanical.
- plus `do-while`, global scalars, comma-in-`for`, a real **preprocessor** (object + function macros, `#if/#ifdef`,
  multi-file `#include`), and a **float decision** (SVIR is integer-only; iiis-0's float surface is tiny — audit
  whether it is essential or excisable before committing to f64-in-SVIR + software-float, which is the heavy option).

**Why CLAIM 1 must come first:** the core *is* a compiler — it serializes object bytes, computes offsets, packs
structures. Without correct layout (Claim 1), ccsv-built iiis-0 would mis-emit. With it, each feature above is a
single gated, differential-checked increment, exactly like the ten already landed this session.

**Done-definition:** `ccsv` compiles every `COMPILER/BOOT/*.c` and the produced `iiis-1` passes `stage1_corpus`.

---

## CLAIM 3 — "Defeats Thompson / closes the root" → make it true: **multi-witness DDC + a hand-audited seed**

This is the claim that was most overstated, and the one with the most interesting architecture. ccsv **alone** can
never defeat Thompson: `ccsv.iii` is compiled by `iiis-2` ← `iiis-1` ← `iiis-0` ← **gcc**. A self-perpetuating
bootstrap backdoor could ride that lineage into ccsv. DDC (Wheeler) requires CC2 to be **independent**, not trusted.
Three layers make it true, weakest-to-strongest:

1. **Independent-lineage witnesses (the standard DDC).** Compile `iiis-0` with **clang** (LLVM lineage, independent
   of gcc) and **tcc** (independent) as CC2: `CC2(iiis-0)=s1`; `s1(iiis-0)=s2`; assert `s2 ≡ reference iiis-2`
   byte-for-byte. If clang-built and tcc-built and gcc-built stages all agree, an attacker must have backdoored
   *all three* lineages *identically* — implausible. This is real DDC and needs only that clang/tcc be present in
   the host (the memory's "GCC-family only" residual is exactly this missing piece).
2. **The sovereign witness (ccsv's true role).** ccsv joins as a **third, structurally-diverse** CC2 — a different
   *frontend and IR* (C→SVIR) than iiis's (.iii→x86 via `cg_r3`). Even gcc-seeded, its independent *code* widens
   the diversity: a source-level backdoor in `cg_r3` is not in ccsv. ccsv is the *sovereignty* witness; clang/tcc
   are the *lineage* witnesses; together they triangulate.
3. **The hand-audited root (the deepest defeat).** The strongest Thompson defeat shrinks the trusted base to code a
   human can read. III already has the anchor: **`svir_verify.iii` — 74 lines, "the whole system's trust anchor."**
   The architecture: a minimal `SVIR→x86` emitter + the verifier, both hand-auditable and assemblable by an
   independent/hand-checked assembler, form a **root that depends on no vendor compiler**. Bootstrapping ccsv/iiis
   up from *that* root rests trust only on (hand-audited seed + the CPU).

**`seed_ddc.sh` target shape:** `for CC2 in clang tcc ccsv: s1=CC2(iiis-0); s2=s1(iiis-0); assert s2==reference`.
Claim 1 is a **hard prerequisite** — byte-identity is impossible while layouts diverge.

**The irreducible residual (state it, always).** Even after all three layers, the **CPU/microcode and the OS loader
remain trusted** — you cannot DDC the silicon. The achievable end state is the *smallest practical TCB*:
`{hand-audited SVIR seed} + {CPU}`. That is the honest ceiling of "closing the root," and it is a real, strong
result — just not "trust nothing."

---

## THE END-GOAL — sovereign toolchain → EIDOS artifacts → ZK-attested EIDOS

The three fronts converge here. EIDOS (the event-substrate / unified-ripple / verb-geometry composer) is written in
`.iii`. The end-goal in one pipeline:

```
  EIDOS (.iii)  ──iiis (sovereign frontend)──▶  SVIR (sovereign IR, typed memory)
        │                                              │
        │                                       sovas + sovld
        │                                              ▼
        │                                   EIDOS artifact  (kernel32-only, NO gcc)      ◀── artifact-sovereignty ✔ (Claim 1 makes the C parts ABI-true)
        │
        └── compiled by a toolchain that is DDC-verified (clang+tcc+ccsv, audited seed)  ◀── bootstrap-trust (Claim 2→3)
                                                       │
                                       zk_svir_vm  (a zkVM over the SVIR ISA)
                                                       ▼
                                  STARK proof that EIDOS's SVIR trace ran correctly        ◀── ZK-attested EIDOS computations
```

**Two concrete build-outs realize the end-goal:**

- **Sovereign artifacts (near):** EIDOS already compiles `.iii → SVIR → x86 PE` via the sovereign build; with Claim
  1, any C-shaped pieces gain a true ABI. "The sovereign toolchain produces EIDOS's artifacts" becomes literally
  true once the toolchain itself is DDC-verified (Claim 3) — *sovereign artifacts built by a trust-closed toolchain.*
- **ZK-attested EIDOS (far):** today `zk_air` attests a field-recurrence trace, not general programs. The unlock is
  **`zk_svir_vm`** — one AIR constraint set per SVIR opcode, so *any* SVIR program (hence any EIDOS computation that
  compiled to SVIR) yields a STARK proof of correct execution. EIDOS's content-addressing already gives integrity of
  *data*; the SVIR zkVM adds integrity of *computation*. Together: **a self-verifying substrate** — sovereign in
  production, trust-closed in bootstrap, and zero-knowledge-provable in execution. That is "verifiable mathematical
  proof" of the whole stack, end to end.

**Why this is greater than the sum of parts (the §0 synthesis):** typed-memory SVIR (Claim 1) is simultaneously (a)
the ABI that makes ccsv a real C compiler, (b) the layout fidelity that makes byte-identical DDC possible, and (c)
the *same* stable ISA the zkVM constrains. One ISA decision pays off in all three fronts and the capstone. That is
the architecture choosing itself.

---

## Phased roadmap (each phase = gated, differential-checked, no half-done step)

| phase | deliverable | unlocks |
|---|---|---|
| **P1** | typed memory in SVIR (LOAD/STORE 16/32) + ccsv C ABI (sizes + alignment) | Claim 1 *true* (byte-identical structs vs gcc) |
| **P2** | gap-map core features: switch, fn-ptr (`CALL_INDIRECT`), goto-relooper, preprocessor, float-decision | ccsv compiles whole `COMPILER/BOOT/*.c` |
| **P3** | ccsv-built `iiis-1` passes `stage1_corpus` | Claim 2 *true* (sovereign self-build) |
| **P4** | `seed_ddc.sh` with clang+tcc+ccsv witnesses, all `s2 ≡ reference` | Claim 3 *true* (multi-witness DDC) |
| **P5** | hand-audited SVIR seed (verifier + minimal emitter) as the independent root | smallest-TCB Thompson defeat |
| **P6** | EIDOS built by the trust-closed sovereign toolchain | "sovereign toolchain produces EIDOS artifacts" *true* |
| **P7** | `zk_svir_vm` (AIR per SVIR opcode) attesting an EIDOS computation | "ZK-attested EIDOS" *true* — the end-goal |

**Immediate next step (P1, start now):** typed memory in SVIR + ccsv's real type-size/alignment model — the single
decision that pays into Claim 1, Claim 2's correctness, real DDC byte-identity, and the zkVM's stable ISA at once.

---

## Honest ledger (so nothing is half-claimed)

- **True today:** artifact-sovereignty; ccsv compiles real, complex, byte-sensitive iiis-0 crypto correctly through
  a gcc-free artifact path.
- **Made true by P1–P3:** Claims 1 and 2 (layout fidelity + whole-seed coverage + sovereign self-build).
- **Made true by P4–P5:** Claim 3 (real DDC via independent witnesses; smallest-TCB root via the audited seed).
- **The end-goal by P6–P7:** sovereign+trust-closed EIDOS artifacts, then ZK-attested EIDOS execution.
- **Never claimable:** trusting *nothing* — the CPU and loader are the irreducible TCB. The win is shrinking trust
  to {audited seed + silicon}, and proving everything above it.
