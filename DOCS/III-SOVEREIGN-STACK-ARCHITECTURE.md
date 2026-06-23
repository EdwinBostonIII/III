# III Sovereign Stack — Architecture & Phase-1 Plan: the IR + Translator pivot

> **Pass:** `/architect` · `/writing-plans` · `/creative-solve` · advisor-disciplined (5 guardrails) · main-session (no subagents).
> **Date:** 2026-06-22. **Status:** ARCHITECTURE accepted; **Phase 1 LANDED** — `STDLIB/sovir/run_svir.sh` =
> ALL PASS: one hand-authored SVIR program (`svir_prog.iii`), two independent translators (`svir_x86.iii` →
> sovereign PE; `svir_wasm.iii` → `.wasm`), **both execute to 99 on this host** (x86-64 sovereign + WASM/node).
> **Phase 1b LANDED** too: the structured-control ops (`BLOCK`/`LOOP`/`BR`/`BR_IF`) + locals + `GE_S` now lower on
> BOTH translators, and a real **counted loop** (`svir_loop.iii`, sum 0..99 == 4950 → 99) runs to 99 on both
> machines (x86 through `sovas`'s branch relaxation, sovereign; WASM via node). `run_svir.sh` = 2 programs × 2
> translators, all 99. The SVIR v0 core (arithmetic + locals + structured control) is complete and dual-targeted.
> **Phase 2 LANDED**: SVIR **v1** = a multi-function module (`[func_count]` + per-func `[params][nresults][body_len]`)
> + the `CALL funcidx argcount` op. `svir_call.iii` (`main` calls a looping `helper(100)`) lowers on both
> translators — x86 via the **Win64 ABI** (args→`rcx/rdx/r8/r9`, 16-byte align + 32B shadow, an rsp-save slot so a
> call can't corrupt the live eval stack), WASM via its native multi-function `call`. `run_svir.sh` = **3 programs
> × 2 translators, all 99**. Function calls — the key primitive for real programs — work on both machines.
> **Phase 2b LANDED — a real RECURSIVE program + printed output (`svir_fact.iii`):** `fact_rec` (recursive) and
> `fact_iter` compute `20!`, cross-checked `== 2432902008176640000`; a **recursive** `print_dec` prints the
> 19-digit result. New ops `SREM`/`DROP`/`PRINT_CHAR` (x86: `WriteFile` via a `__putc` helper, raw bytes,
> kernel32-only; WASM: imported `env.putc`). The gate asserts the **differential**: x86 stdout == wasm stdout ==
> an independent golden 20!, byte-identical, both exit 99. Two bugs were caught *because* the backends disagreed:
> a `sovas` `andq $imm` encoding gap (crash) and a WASM `lt_s`/`gt_s` opcode swap. **Honest framing (advisor):**
> this proves **TOOLCHAIN** superiority (one IR → two architectures, verified-identical output, x86 zero external-
> toolchain trust, differential correctness) — NOT **PROGRAM** superiority (`20!` overflows i64 at `21!` like any
> `long long`). Program superiority = a never-overflowing arbitrary-precision factorial → needs **SVIR linear
> memory** (Phase 2c). Authoring tool: `svir_asm.mjs` (readable instruction lists → SVIR bytes).
> **For the worker:** Phase 1 (§7) is meticulous + gated. Phases 2–6 (§8) are a directional roadmap with honest
> caveats — NOT yet task-decomposed. Build Phase 1 before planning the rest. No subagents (III rule).

---

## 0. Thesis (no-compromise) — and the two boundaries that keep it honest

**III defines its own machine.** A **Sovereign IR (SVIR)** is the single source of truth. Every real computer —
x86-64/PE, x86-64/ELF, ARM64, RISC-V, **WASM** — is reduced to a **translator plugin** that lowers SVIR → that
host's native form. The IR is the *only* host-independent artifact; the translators are the *only* host-specific
surface, and the gate (the "password" = decode **+ crypto-attest**). Existing formats (PE, ELF, x86 encoding, the
gcc oracle) are **hurdles we encode/decode/verify — never gospel we obey.**

Two boundaries stated up front so no reader has to infer them:

- **This is sovereignty over PRODUCTION, not over EXECUTION.** III emits every byte of the artifact for any target.
  The **host still runs it** (the Windows PE loader; node's WASM engine; a Linux ELF loader). Owning *execution* —
  running beneath the OS — is the **KATABASIS** axis (Ring −1/−2), a *separate* program for which owning production
  is the precondition, not the act. Do not conflate them.
- **The chip ISA and the OS loader are the physics/host boundary.** x86-64 "down to the chip" is not a sovereignty
  failure — it is the substrate. Sovereignty is everything *above* the silicon. We do not fight the chip; we make
  the chip one *target* among many, mastered by the IR rather than mastering it.

**What is already true (not aspiration):** `sovas`/`sovld`/`jit_emit` (this session) **are translator #1's back
half** — a sovereign x86-64 emitter + PE linker, self-hosting, byte-gated, with one program built fully sovereign
incl. hardware crypto. The pivot below generalizes that one translator into N.

---

## 1. The pivot, located precisely in the code

Today (verified): `COMPILER/BOOT/cg_r3.iii` lowers **AST → x86-64 AT&T assembly text directly** —
`r3_emit_movabs_rax`, `r3_emit_load_slot` → `-N(%rbp),%rax`, `r3_emit_store_rax_slot` → `movq %rax,-N(%rbp)`.
**There is no internal IR** between sema and the `.s`. *That `%rax` baked into codegen is the ISA-lock.*

```
            TODAY (ISA-locked)                          SOVEREIGN STACK (the pivot)
        .iii ─cg_r3─► x86-64 .s ─► gcc/sovas ─► PE      .iii ─frontend─► SVIR ─┬─► x86-64 translator ─► PE/ELF
                                                                               ├─► WASM translator   ─► .wasm
                                                                               ├─► ARM64 translator  ─► Mach-O/ELF
                                                                               └─► RISC-V translator ─► ELF
                                                          each translator: decode(SVIR) → [attest] → emit native
```

"Another computer" stops being "rewrite `cg_r3` per ISA" and becomes "**add a translator** that consumes SVIR."
SVIR is a **new execution primitive** (cg_r3 has none) — a real gap to fill, not a parallel island.

---

## 2. Components

| Component | Responsibility | Status |
|---|---|---|
| **SVIR (the IR)** | a small, host-independent, content-addressable **stack machine** with **structured control flow**; the single source of truth | **NEW** (Phase 1 defines v0) |
| **x86-64 translator** | SVIR → x86-64 (Phase 1: SVIR → AT&T `.s` → existing `sovas`+`sovld` → PE) | back half EXISTS; lowering NEW |
| **WASM translator** | SVIR → `.wasm` binary; node runs it | **NEW** (Phase 1) |
| **ELF / ARM64 / RISC-V translators** | SVIR → those targets | later phases |
| **Attest layer** | the "password": verify a signature/attestation over the SVIR before a translator lowers it | later (Phase 3) |
| **Network delivery** | one-sided here→there: produce a remote's sovereign payload, ship it, collect the witness | later (Phase 4) |

---

## 3. SVIR v0 — the instruction set (designed for CLEAN LOWERING + CHEAP VERIFICATION, not weirdness)

> **Guardrail (advisor #2):** the "odd-byte / make the machine pretend" framing is honored as **crypto-attest on
> decode**, NOT as a deliberately non-native encoding. A weird encoding is pure cost (harder to lower, verify,
> debug) and buys **zero** security — secrecy/control comes from the signature, not the byte shape. So SVIR v0 is
> a *clean, regular, trivially-decodable* stream. The "password" is Phase 3's attestation, layered on this.

> **Guardrail (advisor #4):** WASM has **no arbitrary jumps** — only `block`/`loop`/`if` + `br`/`br_if` to an
> enclosing label (the relooper problem). So SVIR v0 control flow is **structured only** (no goto). This lowers
> 1:1 to WASM and trivially to x86 (label-per-construct).

**Machine model:** a stack machine. An operand **eval-stack**, plus **N i64 locals** (slot-indexed). One function
(`main`) for v0. `RETURN` yields an i64 = the process result (the success convention is **99**, matching every
other III gate).

**Encoding:** opcode = 1 byte, operands follow inline. Little-endian. (Regular and self-delimiting; a verifier is
a 30-line scan.)

| Op | Byte | Operands | Stack effect | WASM analog | x86 lowering (eval-stack on the native stack) |
|---|---|---|---|---|---|
| `NOP` | `0x00` | — | — | `nop` | — |
| `CONST_I64` | `0x01` | i64 LE (8B) | → push imm | `i64.const` | `movabsq $imm,%rax ; pushq %rax` |
| `LOCAL_GET` | `0x10` | u8 slot | → push local | `local.get` | `movq -8*(slot+1)(%rbp),%rax ; pushq %rax` |
| `LOCAL_SET` | `0x11` | u8 slot | pop → local | `local.set` | `popq %rax ; movq %rax,-8*(slot+1)(%rbp)` |
| `ADD` | `0x20` | — | a,b → a+b | `i64.add` | `popq %rcx ; popq %rax ; addq %rcx,%rax ; pushq %rax` |
| `SUB` | `0x21` | — | a,b → a−b | `i64.sub` | `… subq %rcx,%rax …` |
| `MUL` | `0x22` | — | a,b → a*b | `i64.mul` | `… imulq %rcx,%rax …` |
| `SDIV` | `0x23` | — | a,b → a/b | `i64.div_s` | `popq %rcx; popq %rax; cqto; idivq %rcx; pushq %rax` |
| `EQ` | `0x30` | — | a,b → (a==b) | `i64.eq` | `popq %rcx; popq %rax; cmpq %rcx,%rax; sete %al; movzbq %al,%rax; pushq %rax` |
| `LT_S` | `0x32` | — | a,b → (a<b) | `i64.lt_s` | `… setl %al …` |
| `BLOCK` | `0x40` | — | — | `block` | push a forward label `Lend_k`; `br d`→`Lend` of the d-th enclosing |
| `LOOP` | `0x41` | — | — | `loop` | emit a back label `Lhdr_k`; `br d`→`Lhdr` of the d-th enclosing |
| `IF` | `0x42` | — | pop cond | `if` | `popq %rax; testq %rax,%rax; jz Lelse_k` |
| `ELSE` | `0x43` | — | — | `else` | `jmp Lend_k ; Lelse_k:` |
| `END` | `0x44` | — | — | `end` | `Lend_k:` (and for IF without ELSE, `Lelse_k:` = `Lend_k:`) |
| `BR` | `0x50` | u8 depth | — | `br` | `jmp` to the depth-th enclosing construct's label |
| `BR_IF` | `0x51` | u8 depth | pop cond | `br_if` | `popq %rax; testq %rax,%rax; jnz <label>` |
| `RETURN` | `0x60` | — | pop → ret | `return` | `popq %rax ; <epilogue> ; ret` (x86 `main` returns %rax) |

This set computes **Σ(0..99)=4950** with a `LOOP`/`BR_IF` and returns **99** iff correct — the Phase-1 witness.
(`indep_toolchain.iii`'s Gauss check, re-expressed in SVIR, host-independent.)

---

## 4. Decision log (ADRs) — no-compromise, but honest

- **ADR-1 — SVIR is the source of truth; no host ISA is the master.** x86-64 becomes one target. *Consequence:*
  ISA-agnosticism is "add a translator," not "rewrite codegen." The chip is a target, not a ceiling.
- **ADR-2 — a translator is the only host-specific surface AND the gate.** Agnosticism and sovereignty are one
  mechanism (one owned chokepoint per host). *Consequence:* minimize per-translator surface; share SVIR + verifier.
- **ADR-3 — clean IR, crypto password.** SVIR is regular + cheaply verifiable. The "password" is a signature/
  attestation checked at decode (Phase 3), NOT encoding obscurity. *Rationale (advisor):* obscurity ≠ secrecy.
- **ADR-4 — the verification ladder, named honestly:**
  1. **byte-differential vs gcc-as** (today) — assembler supply-chain integrity. *Not* a Thompson defense.
  2. **from-spec encoder verifier** — an independent oracle that decodes our bytes against the ISA manual →
     **retires gcc as the definition of "correct."**
  3. **differential translator testing** — two translators agree on SVIR. Catches *translator* bugs. **NOT DDC**
     — a frontend/seed backdoor is *in* the SVIR; both translators reproduce it and agree. (Advisor-corrected.)
  4. **real Diverse Double-Compiling** — only an **independent `.iii`→SVIR frontend** OR a **hand-audited seed**
     earns the Thompson-defense claim (Phase 6). Until then we do not say "DDC."
- **ADR-5 — host toolchains are witnesses, never gospel, never trusted-path.** gcc/ld/node demoted as translators
  + the from-spec verifier mature.
- **ADR-6 — "another computer" starts one-sided + network-based.** III here *produces* the remote's sovereign
  payload and *delivers* it; the remote runs it; the witness returns. No requirement the remote be III.
- **ADR-7 — the seed is a known hurdle, not gospel.** `iiis-0` is gcc-built; the endgame (Phase 6) includes a path
  to a self-verified seed (a minimal hand-auditable SVIR decoder bootstraps the rest). The hardest, last rung.

---

## 5. Boundaries / non-goals for THIS document

- Phase 1 only is build-ready. It must **self-justify**: "one SVIR program, two machines, both run to 99 on this
  host" is worth shipping even if Phases 2–6 never happen.
- Not in scope: register allocation, optimization, a full type system in SVIR, ELF/ARM/RISC-V, the attest layer,
  the network layer, the cg_r3→SVIR retarget. All are later phases, explicitly deferred.

---

## 6. NON-FUNCTIONAL targets (adapted to this domain)

| Category | Requirement | Target | Measurement |
|---|---|---|---|
| Correctness | each translator's output runs to the SVIR's specified result | exit/return **99** | execute the artifact |
| Determinism | same SVIR bytes → same artifact bytes (per translator) | byte-identical across runs | re-run + `cmp` |
| Independence | the two Phase-1 lowerings share no code path | x86 `.s` path ⟂ WASM binary path | code review |
| Sovereignty | x86 path uses no gcc/ld | `sovas`+`sovld` only; PE imports kernel32 only | `objdump -p` |
| Verifiability | SVIR is decodable by a short independent scan | a < 60-line verifier accepts/rejects | the verifier KAT |

---

## 7. PHASE 1 — bite-sized, gated tasks (BUILD THIS)

**Goal:** one **hand-authored** SVIR program (independent of `cg_r3` and of x86 — advisor #3) is lowered by **two
independent translators** to two real artifacts that both execute to **99** on this host: x86-64 via the sovereign
toolchain, and WASM via `node`.

**Files:**
- Create `STDLIB/sovir/svir.md` — the SVIR v0 spec (the §3 table, frozen).
- Create `STDLIB/sovir/prog_sum.svir.hex` — the hand-authored SVIR program (sum 0..99 → 99), as hex bytes.
- Create `STDLIB/sovir/svir_x86.iii` — translator: SVIR bytes → x86-64 AT&T `.s`.
- Create `STDLIB/sovir/svir_x86_main.iii` — CLI driver (reads the `.svir` file, writes `.s` to stdout).
- Create `STDLIB/sovir/svir_wasm.iii` — translator: SVIR bytes → `.wasm` binary.
- Create `STDLIB/sovir/svir_wasm_main.iii` — CLI driver (reads `.svir`, writes `.wasm` to stdout).
- Create `STDLIB/sovir/run_wasm.mjs` — minimal node harness (instantiate `.wasm`, call `main`, `process.exit(rv)`).
- Create `STDLIB/sovir/run_svir.sh` — the gate: build both artifacts, run both, assert both = 99.

**Interfaces (so each task knows its neighbors' names):**
- SVIR reader (shared idea, duplicated per translator — they must stay independent): byte cursor over the program;
  ops per §3. Each translator OWNS its own reader (no shared module → genuine independence per advisor #3).
- `svir_x86`: exports `fn svir_to_asm(src:u64, len:u64, dst:u64, cap:u64) -> u64` (returns bytes written).
- `svir_wasm`: exports `fn svir_to_wasm(src:u64, len:u64, dst:u64, cap:u64) -> u64` (returns bytes written).

### Task 1 — Freeze SVIR v0 + hand-author the program

- [ ] **1.1** Write `STDLIB/sovir/svir.md` = the §3 table verbatim (the frozen opcode contract).
- [ ] **1.2** Hand-assemble `prog_sum` to bytes and write `STDLIB/sovir/prog_sum.svir.hex` (whitespace-separated
  hex). The program (acc=0,i=0; loop while i<100 {acc+=i; i+=1}; return acc==4950 ? 99 : 1):
  ```
  # locals: 0=acc 1=i ;  CONST 0;LOCAL_SET 0 ;  CONST 0;LOCAL_SET 1
  01 00 00 00 00 00 00 00 00  11 00      # acc=0
  01 00 00 00 00 00 00 00 00  11 01      # i=0
  40                                       # BLOCK (depth target for break)
    41                                     #   LOOP
      10 01  01 64 00 00 00 00 00 00 00  32   # i<100  (LOCAL_GET i; CONST 100; LT_S)
      50 01                                #     BR_IF? no -> we branch OUT when NOT <100:
      # invert: compute (i<100); if false break. Use: i<100 -> BR_IF continue-pattern.
  ```
  (The exact bytes are finalized in 1.3 against the translators; keep the program tiny — a counted loop only,
  structured, no goto.)
- [ ] **1.3** Write a < 60-line verifier check mentally / on paper: every opcode known, every `BR depth` within
  enclosing-construct count, stack never underflows. Record the expected final result = **99**.

### Task 2 — x86 translator (`svir_x86.iii`) → `.s`, built by the sovereign toolchain, runs to 99

- [ ] **2.1** Write `svir_x86.iii`: a byte-cursor over SVIR; for each op emit the §3 "x86 lowering" AT&T text into
  `dst`. Maintain a construct stack for labels (`BLOCK`/`LOOP`/`IF`/`END`, `BR`/`BR_IF` depth → label). Emit a
  Win64 `main` prologue/epilogue; `RETURN` → `popq %rax` + epilogue + `ret`. Eval-stack = the native stack.
- [ ] **2.2** Write `svir_x86_main.iii`: read argv[1] (the `.svir.hex`), parse hex → bytes, call `svir_to_asm`,
  write `.s` to stdout.
- [ ] **2.3** Build the translator itself with the sovereign toolchain and run it:
  Run: `iiis-2 svir_x86.iii --compile-only ... ; iiis-2 svir_x86_main.iii ... ; gcc-link the driver (bootstrap) ;
  driver prog_sum.svir.hex > prog_sum.s`
  Expected: a `.s` file with a `main`.
- [ ] **2.4** Assemble+link `prog_sum.s` **sovereignly** (`sovas`+`sovld`, no gcc) → `prog_sum.x86.exe`; run it.
  Run: `sovbuild-style: sovas_main prog_sum.s > prog_sum.o ; sovlink_main crt0 prog_sum.o > prog_sum.x86.exe ;
  ./prog_sum.x86.exe ; echo $?`
  Expected: **99**. And `objdump -p prog_sum.x86.exe | grep "DLL Name"` → `kernel32.dll` only.
- [ ] **2.5** Commit: `git add STDLIB/sovir/svir_x86*.iii STDLIB/sovir/svir.md STDLIB/sovir/prog_sum.svir.hex`.

### Task 3 — WASM translator (`svir_wasm.iii`) → `.wasm`, runs to 99 via node

- [ ] **3.1** Write `svir_wasm.iii`: its OWN byte-cursor over the SAME SVIR (independent of `svir_x86`). Emit a
  minimal valid `.wasm` module: magic `00 61 73 6d`, version `01 00 00 00`; a type section (`() -> i64`); a
  function section; an export section (`"main"`); a code section whose body is the §3 "WASM analog" opcodes
  (`i64.const`/`local.get`/`local.set`/`i64.add`/`block`/`loop`/`br_if`/`return` …) — near 1:1 with SVIR. Locals
  declared in the code-section preamble.
- [ ] **3.2** Write `svir_wasm_main.iii`: read argv[1], hex→bytes, `svir_to_wasm`, write `.wasm` to stdout (binary).
- [ ] **3.3** Write `run_wasm.mjs` (the WASM host = node's engine, analogous to the OS PE loader):
  ```js
  import { readFileSync } from 'node:fs';
  const bytes = readFileSync(process.argv[2]);
  const { instance } = await WebAssembly.instantiate(bytes);
  process.exit(Number(instance.exports.main()));
  ```
- [ ] **3.4** Build the translator (bootstrap-link is fine — it's a tool), produce the wasm, run it:
  Run: `driver prog_sum.svir.hex > prog_sum.wasm ; node run_wasm.mjs prog_sum.wasm ; echo $?`
  Expected: **99**.
- [ ] **3.5** Commit: `git add STDLIB/sovir/svir_wasm*.iii STDLIB/sovir/run_wasm.mjs`.

### Task 4 — The gate: one SVIR, two machines, both 99

- [ ] **4.1** Write `STDLIB/sovir/run_svir.sh`: from the SINGLE `prog_sum.svir.hex`, build+run the x86 path (assert
  99, kernel32-only) AND the WASM path (assert 99 via node). Print `ALL PASS` iff both.
- [ ] **4.2** Run it. Expected: `ALL PASS — one SVIR program, two independent translators, both execute to 99
  (x86-64 sovereign PE + WASM via node), on this host.`
- [ ] **4.3** Commit the gate + a short `DOCS/III-SOVEREIGN-STACK-ARCHITECTURE.md` update noting Phase 1 LANDED.

**Phase-1 done = the agnosticism thesis is executed-to-99 on this host, from one host-independent IR, with the x86
path fully sovereign.** No deferral, no structural-only hand-wave.

---

## 8. Roadmap (Phases 2–6 — directional, NOT yet task-decomposed)

- **Phase 2 — coverage to a real program.** Grow SVIR (calls, more types, memory/globals) until `prog_sat`-class
  logic lowers on both translators. Add the **from-spec encoder verifier** (ADR-4.2) → begin retiring the gcc
  oracle. Add **differential translator testing** (ADR-4.3) as a standing gate — named honestly, not "DDC."
- **Phase 3 — the attested password (ADR-3).** Sign SVIR (III's `mlkem`/`sha`); each translator verifies the
  attestation before lowering. The "password" becomes a key. Optional: an attested-translator manifest.
- **Phase 4 — one-sided network sovereignty (ADR-6).** III here produces a remote's payload (SVIR + the remote's
  translator, or a native image) and ships it over `ws2_32`/`aether/sealed_channel`; the remote runs it; the
  witness (exit 99 + signature) returns. First milestone: this→there, no remote cooperation.
- **Phase 5 — more machines + the retarget.** ELF/SysV translator (structural + CI execution), then ARM64/RISC-V.
  Retarget `cg_r3` to emit SVIR (retire the direct x86 `.s` path) so *all* of III is host-independent at the IR.
- **Phase 6 — real trust closure (ADR-4.4, ADR-7).** An independent `.iii`→SVIR frontend OR a hand-audited
  minimal seed → genuine Diverse Double-Compiling (the Thompson defense). Self-verified seed retires the gcc-built
  `iiis-0`. The deepest, last rung — *only here* do we earn the word "DDC."

---

## 9. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Scope creep — building Phases 2–6 before Phase 1 ships | months of plan, no executed brick | Phase 1 self-justifies; build it first, decompose the rest later |
| WASM structured-control mismatch (relooper) | WASM translator stalls | SVIR v0 control is structured-only (§3 guardrail); counted loop only in Phase 1 |
| Circular Phase-1 IR (lifted from x86) | "two machines agree" collapses to one | SVIR program **hand-authored**, independent of cg_r3 and x86 (advisor #3) |
| Re-skinning the trust over-claim at the IR layer | credibility with the architect | "DDC" reserved for an independent frontend/seed; translator agreement = "differential testing" only |
| Forcing `isub`/`ast-bin`/XII to dodge "island" | wrong primitive, friction | cg_r3 has NO execution IR (verified) → SVIR is a legitimate new primitive |
| node/JS as a dependency | "not sovereign" objection | node is the WASM *host* (like the OS PE loader runs the PE) — execution substrate, not III code; §0 boundary |
