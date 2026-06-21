# III — Sovereign Toolchain: a native `.iii → PE` assembler + linker, gcc demoted to differential witness
### Remove gcc/ld from the trusted path as a parallel verified track, gated by byte-level differential against gcc
> **Date:** 2026-06-21 · **Author pass:** /architect · /deep-think · /math-olympiad (adversarial, native) · advisor-disciplined
> **Status:** ARCHITECTURE / DESIGN (option B). Grounded in the VERIFIED surface (the real cg_r3 output of 695 modules,
> the real link requirements), not generic assembler theory. Marks EXISTS / NEW / SCOPE crisply.
> **Trust posture (the endgame):** the trust root is the census-verified **silicon** + a **byte-differential-gated**
> native toolchain; **gcc/ld are kept as a differential witness, not deleted** (per the user's three conditions).
> **Decisive correction this design rests on:** the `tp_*` organs are format-transform DEMOS (source-embed,
> `.byte`-undump, minimal-PE-skeleton), NOT a working assembler/linker; `emit.c` shells `gcc -c -x assembler`
> (assemble) + `gcc`/`ld` (link). So this is a real BUILD of two components, not a wiring of existing pieces.

---

## 0. THE GOAL, MADE FALSIFIABLE

Today: `module.iii → iiis-2/cg_r3 → .s (gas) → [gcc -c -x assembler] → .o → [gcc/ld] → PE`. gcc is the **assembler AND
the linker**. EIDOS's anchor wants the trust root on the silicon; this removes gcc/ld from the *trusted* path while
keeping them as a *witness*. Success metric (gated, not prose):

> **For all 695 stdlib modules + the corpus KATs, the sovereign path produces a binary BEHAVIORALLY IDENTICAL to the
> gcc path — and at the object level, byte-identical `.text`.** When that holds across the whole corpus, the native
> path is provably correct against the reference and may be promoted to default; gcc remains as the witness whose
> disagreement reddens the build.

---

## 1. THE VERIFIED SURFACE (the spec the assembler must hit, exactly)

Enumerated from the real `.iii.o.s` of all 695 modules — this is the *entire* input language, not an estimate.

### 1.1 Directives (17 distinct; the assembler must honor these and only these)
`.section · .global · .text · .ascii · .asciz · .quad · .byte · .zero · .long · .file · .att_syntax`
plus the Windows-x64 SEH unwind set `.seh_proc/.seh_endproc/.seh_pushreg/.seh_setframe/.seh_stackalloc/.seh_endprologue`.
**SEH is functionally OPTIONAL** for a runnable binary (it builds `.pdata`/`.xdata` for exception unwinding only) — so
Tier-1 treats `.seh_*` as **no-ops** (assemble the prologue instructions, skip the unwind tables); Tier-2 adds real
`.pdata`/`.xdata`. This removes ~half the directive complexity from the critical path.

### 1.2 Instruction set — TIER 1 (the integer core: >99% of all instructions)
~38 mnemonics, by frequency: `popq pushq movq movabsq movl movzbq addq subq callq leaq testq jz cmpq movslq
sete movb setne jmp setb andq shlq shrq imulq setae seta negq xorl divq xorq setbe movzwq setle idivq setl
movswq movsbq movw notq orq`. Operand forms `cg_r3` actually emits: register↔register, immediate, **rip-relative**
(`L_sym(%rip)`), displacement(`n(%reg)`), and absolute-load (`movabsq $imm64`). This is a **closed, encodable set** —
REX prefix + ModRM + SIB + disp32 + imm. No exotic addressing.

### 1.3 Instruction set — TIER 2 (the SIMD/crypto tail: <1%, but load-bearing in sha256/blake2/weave-SIMD)
~30 mnemonics: AVX2/AVX-512 (`vpaddd vmovdqu vpshufd vpxord vpslld vpsrld vpor vmovdqu64 vpaddq vprold vpermq
vpmuludq vpxor vpand …`) + SSE (`movdqu paddd pshufd pxor palignr`) + **SHA-NI** (`sha256rnds2 sha256msg1
sha256msg2`). These need **VEX/EVEX** prefix encoding (harder) and are **separable** — deferred to Tier-2, those
modules stay gcc-built (and gcc-witnessed) until it lands.

### 1.4 The link requirements (the linker spec, verified)
- **Sections:** `.text` (code), `.rodata` (`.ascii/.asciz/.quad/.byte`), `.data`, `.bss` (`.zero`).
- **Relocations: exactly TWO** — REL32 (rip-relative data + `callq`/`jmp` to a symbol) and ADDR64 (`.quad sym` data ptr).
- **Imports (IAT), bounded:** kernel32 (`VirtualAlloc VirtualFree WriteFile ReadFile CreateFileA CreateFileMappingA
  MapViewOfFile CloseHandle GetStdHandle GetLastError SetFilePointerEx FindFirstFileA FindNextFileA FindClose
  CreateDirectoryA RemoveDirectoryA DeleteFileA` + `ExitProcess`), ws2_32 (`socket bind listen accept connect send
  recv closesocket htons` …), msvcrt (`malloc free`). ~35 imports across 3 DLLs.
- **Runtime: `-nostdlib -ffreestanding`** (emit.c) — **no gcc crt**. III provides its own `_start` (Win64 startup:
  reserve shadow space, align RSP, `call main`, `ExitProcess(rax)`). So the linker sets the PE entry to `_start`; no
  C runtime to reproduce. *(Verify in Stage 2: confirm whether a III `_start` exists or must be authored as a tiny
  freestanding stub — either way it is ~15 instructions.)*
- **Target:** PE32+ (x64): DOS stub · `PE\0\0` · COFF header · optional header (PE32+) · section table · `.idata`
  import directory · sections. Deterministic (zero timestamps, fixed image base) — to match the determinism `emit.c`
  already pins (`--build-id=none`, `-frandom-seed`, `-ffile-prefix-map`).

---

## 2. COMPONENTS (all NEW `.iii`; nothing wraps the demos)

| Component | Responsibility | Input → Output |
|-----------|----------------|----------------|
| **`sovas` — the assembler** | encode gas (AT&T) mnemonics → x86-64 machine code; emit a COFF object (sections + symbols + relocations) | `.s` → `.o` (COFF) |
| **`sovld` — the linker + PE emitter** | parse COFF objects, resolve symbols, lay out sections at RVAs, apply REL32/ADDR64 relocs, build the IAT, set entry `_start`, emit PE32+ | `.o…` → `.exe` (PE) |
| **`sovrt` — the freestanding entry** | the `_start` Win64 startup stub (call main, ExitProcess) — author only if III has none | — |
| **`sovdiff` — the differential harness** | the correctness spine: build every module/KAT BOTH ways and gate equivalence (§4) | gate |

`cg_r3` is **unchanged** (it already emits the `.s`; the native track consumes it). `emit.c`'s witness layer
(D8–D14: argv/env/gcc+ld version mhashes, golden-bytes gate, audit) is **unchanged** — it becomes the *witness side*
of the differential. The EIDOS session's files are untouched (this is a separate track).

```
                       cg_r3 (.iii → .s)   [EXISTS, shared, untouched]
                              │
            ┌─────────────────┴─────────────────┐
   sovas (.s → COFF .o)  [NEW]          gcc -c -x assembler (.s → .o)  [WITNESS]
            │                                    │
   sovld (.o… → PE)      [NEW]          gcc/ld (.o… → PE)              [WITNESS]
            └─────────────────┬─────────────────┘
                       sovdiff  ── byte-identical .text? same exit code? ──► GATE
```

---

## 3. THE 2×2 DIFFERENTIAL MATRIX (the math-olympiad correctness spine)

Because the assembler and linker are separable, gate each **independently** against the reference, so a bug is
**localized**, not just detected. For each module/KAT, build the four combinations and require agreement:

| | gcc `as` | **sovas** |
|---|---|---|
| **gcc/ld** | the reference (current) | tests the ASSEMBLER alone (sovas `.o` → gcc-ld → exe) |
| **sovld** | tests the LINKER alone (gcc `.o` → sovld → exe) | the full sovereign path |

- **Assembler gate (strongest):** `sovas`'s `.o` `.text` bytes **== gcc `as`'s `.o` `.text` bytes**, per module, all 695.
  Byte-identical machine code against the reference assembler = the assembler is *provably* correct on real input.
- **Linker gate:** `gcc-as + sovld` and `gcc-as + gcc-ld` exes produce the **same exit code** on every corpus KAT;
  the loadable image is structurally valid (it runs). Isolates linker bugs from assembler bugs.
- **Full path:** `sovas + sovld` agrees with the reference on every KAT.

This matrix is Wheeler-DDC applied to the toolchain: each half verified against an independent reference. **A wrong
encoding byte cannot ship — it reddens the `.text` diff.** That is what makes a sovereign assembler *production-safe*
(the user's condition a/b) rather than a CRASH-PROTOCOL liability.

---

## 4. STAGING (each stage its own gated increment; gcc the witness throughout)

- **Stage 0 — the golden reference + harness (`sovdiff`).** Extract gcc-`as`'s per-module `.o` `.text` as the golden
  corpus; build the diff tooling. *Gate:* the harness reproduces gcc's `.text` hashes deterministically. (Low-risk; no
  encoding yet — it just pins the reference everything else is gated against.)
- **Stage 1 — `sovas` Tier-1.** Encode the ~38 integer mnemonics + addressing forms + REL32/ADDR64 relocs; emit COFF.
  *Gate:* `sovas.o.text == gcc.o.text` for **every non-SIMD module** (the majority). Per-instruction, byte-exact.
- **Stage 2 — `sovld`.** COFF parse, symbol resolution, section layout, reloc apply, IAT (kernel32/ws2_32/msvcrt),
  `_start` entry, PE32+ emit. *Gate:* `gcc-as + sovld` and `sovas + sovld` exes exit-code-match gcc on every Tier-1 KAT.
- **Stage 3 — `sovas` Tier-2 (SIMD/SHA-NI + real SEH).** VEX/EVEX encoding + `.pdata`/`.xdata`. *Gate:* `.text`-identical
  on the crypto/SIMD modules. Now **all 695** build sovereign.
- **Stage 4 — promote.** Native path becomes default in a *new* build track; gcc retained as the **differential
  witness** wired into the build: every artifact is diffed native-vs-gcc, and **disagreement reddens the build**
  (the user's condition b, now a standing gate). The Composer (pure `.iii`) is unaffected — it verifies identically
  regardless of which toolchain built the test exe (condition c).

Each stage commits independently, KAT-gated, gcc-witnessed. No big-bang swap.

---

## 5. DECISION LOG (ADRs)

- **ADR-1 — `.text` byte-identity is the assembler's correctness definition.** Not "it runs" — *it encodes exactly as
  the reference assembler does*, per instruction, on all 695 modules. *Rationale:* the strongest, cheapest gate; turns
  "trust my encoder" into a proof. *Consequence:* every Tier-1 mnemonic is validated against real gcc output.
- **ADR-2 — Separable assembler + linker, verified by the 2×2 matrix.** *Rationale:* localizes bugs (a crashing exe
  could be either half); the matrix isolates them. *Consequence:* `sovas` emits COFF `.o` (not fused asm→PE) so its
  output is independently diffable and feedable to gcc-ld.
- **ADR-3 — SEH and SIMD are Tier-2.** *Rationale:* SEH is optional for running; SIMD is <1% and needs VEX/EVEX.
  Deferring them lets Tier-1 cover the majority fast, with those modules gcc-witnessed meanwhile. *Consequence:* a
  useful sovereign path exists after Stage 2, before the hard encoding lands.
- **ADR-4 — gcc demoted to witness, never deleted.** *Rationale:* the user's condition + Trusting-Trust (an auditable
  reference is the strongest correctness check). *Consequence:* the differential is a *standing* build gate, not a
  one-time migration; gcc's `emit.c` witness layer (D8–D14) stays.
- **ADR-5 — `cg_r3` and `emit.c` untouched; EIDOS files untouched.** *Rationale:* additive parallel track; no
  regression risk to the working path or the concurrent EIDOS build. *Consequence:* new `sov*` modules + a new build
  script only.

---

## 6. RISKS

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **Encoding bug → crashing binary** (the CRASH-PROTOCOL class) | a wrong byte BSODs/crashes | ADR-1: `.text` byte-identity vs gcc per module — a wrong byte reddens the diff *before* the binary ever runs |
| **PE/IAT subtlety → ENOEXEC / won't load** | linker stage stalls | Stage 2 isolated by the 2×2 matrix (gcc-as + sovld) so the linker is tested against known-good objects; structural PE validated by *loading* it |
| **SIMD VEX/EVEX encoding is genuinely hard** | Tier-2 slips | ADR-3: Tier-2 is separable; the toolchain is *useful and sovereign for the majority* after Stage 2; crypto modules stay gcc-witnessed until Tier-2 gates green |
| **Determinism drift (timestamps, padding) breaks byte-identity** | false diffs | mirror `emit.c`'s pins (zero timestamp, fixed image base, no build-id); compare `.text` *content*, not whole-`.o` (symbol-table order differs) |
| **Scope creep into a "real GAS"** | months lost | the surface is CLOSED (§1, the actual 695-module output) — encode *exactly* that set, nothing more; new cg_r3 output would redden the diff and flag the gap |
| **Clobbering the concurrent EIDOS build** | merge pain | separate files + a separate build script; never touch build_stdlib.sh/run_corpus.sh/libiii_native.a that EIDOS edits |

---

## 7. EFFORT (honest)

A real assembler + PE linker is **multi-session**, not one turn — but each session lands a *gated* increment:
Stage 0 (harness, ~1) · Stage 1 (`sovas` Tier-1, the big one, ~3–4, but gated per-mnemonic so progress is monotone
and provable) · Stage 2 (`sovld`, ~2–3) · Stage 3 (Tier-2 SIMD/SEH, ~1–2) · Stage 4 (promote + standing gate, ~1).
The byte-differential makes every step **verifiable against the reference**, so "careful" is structural: nothing
ships that doesn't byte-match gcc. The payoff: gcc/ld leave the trusted path (kept as witness), the trust root is the
silicon + a proven encoder — exactly the EIDOS-anchor endgame.

---

## 8. ONE-PARAGRAPH SUMMARY

`cg_r3` already emits a **closed** instruction surface (38 integer mnemonics + 11 directives for >99%; a separable
~30-mnemonic SIMD/SHA-NI tail) over **two** relocation types into a **no-crt** runtime with a bounded **~35-entry IAT**.
So the sovereign toolchain is two real but **bounded** `.iii` builds — `sovas` (gas → COFF) and `sovld` (COFF → PE32+) —
plugged in **parallel** to the untouched gcc path, with `cg_r3` shared. The correctness spine is a **2×2 differential
matrix**: `sovas`'s `.text` must be **byte-identical** to gcc-`as`'s per module across all 695, and every cross of
{sovas,gcc-as}×{sovld,gcc-ld} must exit-code-match gcc on the corpus — so a wrong byte **cannot ship**, it reddens the
diff. Staged (harness → Tier-1 assembler → linker → Tier-2 SIMD → promote), each gated, **gcc kept as the differential
witness, never deleted**. The result: gcc/ld out of the trusted path, the trust root on the census-verified silicon,
C interoperability retained as a *choice* — the EIDOS-anchor endgame, made falsifiable.
