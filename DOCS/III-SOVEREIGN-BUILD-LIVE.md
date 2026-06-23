# III — Sovereign Build, LIVE: III produces its own running executables, no gcc/ld in the trusted path

> **Date:** 2026-06-22 · **Pass:** `/deep-think` · `/creative-solve` · advisor-disciplined · main-session (no subagents)
> **Status:** WORKING + GATED. Executed artifacts, not design. Verify with `STDLIB/sovtc/run_sovbuild.sh`.

This continues the Sovereign-Toolchain arc (`DOCS/III-SOVEREIGN-TOOLCHAIN.md`). That doc designed `sovas`
(native x86-64 assembler) + `sovld` (native PE32+ linker) and proved they **self-host** (assembler+linker build
byte-identical copies of themselves with no gcc/ld/gas — `run_fixpoint.sh`, re-verified PASS 2026-06-22). This
work answers the next question the user posed — *"make III (the independent one) executable, perfectly versatile
and agnostic, drilling down into the computer"* — by driving a **real, substantial III program all the way to a
running PE through III's own toolchain**, and by establishing the **per-module routing** that the EIDOS silicon
census will consume (I1).

---

## 0. The headline (executed, reproducible)

| Program | What it is | Build | Result |
|---|---|---|---|
| **`prog_sat`** | drives `numera/sat` — a real **805-line / 33-fn DPLL SAT solver** | **FULLY sovereign**: every module assembled by `sovas`, linked by `sovld`. **gcc/ld NOWHERE.** | PE32+ (imports **only `kernel32.dll`**) → OS runs it → **exit 99** |
| **`prog_smt`** | drives `omnia/smt` (6-module closure) | **routed**: 5 sovereign + 1 gcc-as witness (`sha256`), all linked by `sovld` | PE32+ → **exit 99** |
| **`prog_egraph`** | drives `omnia/egraph` (28-module closure) | **routed**: 25 sovereign + 3 gcc-as witness (`sha256`,`keccak`,`bigint`), `sovld`-linked | PE32+ → **exit 99** |
| **`prog_sha256ni`** | SHA-256("abc") via the **hardware SHA-NI core** (`sha256rnds2/msg1/msg2`+SSE) | **FULLY sovereign** after `sovas` Tier-2 (§6) — was routed, now `witness=0` | PE32+ (kernel32 only) → **exit 99** |

`prog_sat.sov.exe` was re-run standalone (`exit 99`) and import-audited (`objdump -p`): **`kernel32.dll` only** —
no `libgcc`, no `mingw`, no gcc CRT. The independent one is, literally, executable by III's own hand.

---

## 1. How we got here — verify-the-negative (the advisor's first move)

The question was whether the *full* sovereign path could build a **substantial, stdlib-linked** program (the
`sov_drivel*` drivers in `run_sovtc.sh` are hand-written toys). A probe (`build/_sovprobe/probe.sh`) built two
real programs both ways:

- `pm_trit → trit_selftest` (self-contained faculty): **fully sovereign → exit 99.** ✅
- `pm_cad → cad_selftest` (9-module crypto closure): `sovlink_main` **segfaulted**. ❌

Root-causing the segfault (no premature edits — read the crash path first) found **two real facts, not a linker
bug**:

1. **`sovas` correctly REFUSES Tier-2.** `sovas` on `sha256.o.s` (which carries an AVX-512 fast path:
   `vmovdqu/vpxord/vprold/vpaddd/…`) returns **exit 4** with a 20-byte stub — honoring the `test_unknown.iii`
   contract ("an unhandled mnemonic must fail loudly, never silently emit nothing"). The segfault was the *probe's*
   fault: it fed that 20-byte error stub to the linker, which OOB-read it.
2. **The real boundary is the routing predicate.** A module routes **sovereign iff `sovas` can encode it
   (Tier-1-only)**; a SIMD/SHA-NI module **must route to the gcc-as witness** because `sovas` Tier-2 (VEX/EVEX/
   SHA-NI) is not yet built. This is exactly the consequential, capability-true decision — not a one-bit toy.

A second defect surfaced and was fixed: the program's true dependency closure includes **non-`.iii` assembly
helpers** (`numera/cpufeat` → `iii_cpuid`/`iii_xgetbv`, defined in `COMPILER/BOOT/cpuid_helper.s`). The `.iii`
closure resolver missed them, so `sovld` import-thunked them into **bogus `msvcrt` imports** → routed PEs ran 127.
Including the helper object resolves them to real code → **99**. (`cpuid_helper.s` is the *only* such helper.)

---

## 2. The tool: `STDLIB/sovtc/sovbuild.sh` (per-module routed sovereign build)

```
sovbuild.sh <root.iii> [out.exe]
```
For each module in the program's `.iii` closure: `iiis-2 --compile-only` → `.o.s`, then ROUTE —
- **SOVEREIGN**: `sovas` assembles → COFF `.o`  (no gcc)
- **WITNESS**: if `sovas` refuses (Tier-2 mnemonic → nonzero exit), `gcc -c -x assembler` assembles **that one
  module** → COFF `.o`  (gcc-as, the declared witness — `DOCS/III-SOVEREIGN-TOOLCHAIN.md` ADR-4)
- plus the `cpuid_helper.s` object when `cpufeat` is in the closure.

**ALL objects link through `sovld` — gcc/ld are NEVER in the link path.** gcc only *assembles* the SIMD tail
`sovas` cannot yet encode, and leaves entirely once `sovas` Tier-2 lands. The per-module route is printed as a
**MANIFEST** — the consequential decision.

`sovld` was verified to link **gcc-assembled** objects alongside sovereign ones (mixed COFF), so the routed image
is one coherent PE.

---

## 3. The honest boundary (no over-claim)

- **Fully sovereign today:** any program whose entire closure is Tier-1 (no SIMD/SHA-NI/wide-mul). `prog_sat`,
  `cost_lattice` qualify. gcc/ld absent.
- **Routed today:** programs whose closure includes the SIMD/wide-mul tail (`sha256`/`keccak`/`bigint`). The tail
  is gcc-**assembled**; everything else sovereign; `sovld` links all. gcc is a per-module *assembler* witness only.
- **Tier-2 STARTED (§6):** `sovas` now encodes the **legacy SSE/SHA-NI** set (`movdqu`,`paddd`,`pshufd`,`palignr`,
  `pshufb`,`pblendw`,`sha256rnds2/msg1/msg2`) byte-identical to gcc-as, so `sha256_ni` flips **fully sovereign**.
  Remaining: **AVX-512 (EVEX)** for `sha256`(software fast path)/`keccak`/`bigint`. When that lands the whole crypto
  tail goes sovereign and gcc leaves the build entirely (the toolchain doc's Stage-3).
- **Verification constraint:** this is a Windows/x86-64 host — only x86-64/PE artifacts can be *executed* here. A
  second OS/ISA backend (ELF/SysV, non-x86) is a later increment, validatable structurally but not runnable here.

---

## 4. Why an EIDOS-census "route planner" is NOT the next step (the honest finding)

The tempting I1 was: make `eidos/anchor`+`compose` the LIVE CONSUMER deciding the per-module route from the silicon
census, with a `cpufeat_force_mask` KAT proving "different silicon ⇒ different, still-correct PE." **It cannot be
built honestly, and here is why** (investigated, not assumed):

- **`sovtc`'s correctness invariant is byte-identity with gcc-as (toolchain-doc ADR-1).** For any module `sovas`
  *can* encode, sovas-output ≡ gcc-as-output, byte-for-byte. So routing a module via `sovas` vs gcc-as yields an
  **identical** PE — the route choice is *never* materially different. That is correctness, not a demo.
- **The route is a per-module boolean** ("can `sovas` encode this?"), not a shortest-path problem. No cost order
  should ever pick gcc-as over `sovas` for an encodable module (`sovas` is strictly better: sovereign *and*
  byte-identical). Wiring `compose`/Bellman-Ford into a boolean is a planner-shaped toy.
- **Impl-selection is runtime-dispatched** (`sha256` picks scalar/AVX-512 via `cpufeat` *inside* the binary;
  `sha256_dispatch` links *both*). The build never specializes, so no census-driven byte difference exists to show.

The directive's real content — "agnostic to the computer" — is therefore **not** a census wrapper; it is **removing
gcc from the build entirely by finishing `sovas`** (§6). (An optional honest *bow* remains: `anchor` could expose
"which instruction-tier the sovereign assembler encodes here" as a census capability and `sovbuild` query it — but
its only honest proof is "sovereignty count changes with the census," not different bytes. It is a lookup over a
boolean; the assembler is the work.)

---

## 5. Tier-2: the SSE/SHA-NI encoder — the real "agnostic" increment (LANDED, byte-identical)

The honest hard deliverable: widen what `sovas` encodes so a currently-routed program goes **fully sovereign**.
First bite (smallest infra risk — *legacy* encoding, not the AVX-512 EVEX ocean): the 9 SSE/SHA-NI mnemonics of
`numera/sha256_ni` (a self-contained, single-witness module). Landed in `sovas`/`sovparse`:

- **Encoders** (`sovas.iii`): `sov_sse_0f/0f_ib/0f38/0f3a_ib` (reg-reg `66/F3 0F[38/3A]` + imm8) and the `movdqu`
  family (`F3 0F 6F` load / `7F` store, full base/disp/SIB/`%rip`-reloc addressing). Convention `modrm reg=DEST,
  rm=SRC`; **conditional W0 REX** (emitted only for xmm8+), legacy prefix before REX — matching gas exactly.
- **Parser** (`sovparse.iii`): `%xmm`/`%ymm`/`%zmm` register parsing; a 3-operand reader (`pshufd`/`palignr`/
  `pblendw` imm forms and `sha256rnds2`'s implicit `%xmm0`); `MN[16]` so `sha256msg1`/`sha256msg2` are
  disambiguable by `MN[9]`. **Plus a real pre-existing bug fix**: `hexv`/`sp_num` only accepted *lowercase* hex —
  hand-written `$0xB1` parsed as `0` and desynced the cursor; uppercase `A–F` now handled.
- **Gate = byte-identity (ADR-1):** `sovas`'s `sha256_ni.text` == gcc-as's, byte-for-byte (5776 bytes).
- **Result:** `prog_sha256ni` flips `witness=1 → witness=0`, **fully sovereign**, runs to 99. No fixpoint regression.

Remaining Tier-2: AVX-512 **EVEX** (the 4-byte `0x62` prefix) for `sha256`(sw)/`keccak`/`bigint`. Monotone —
each mnemonic byte-matches gcc-as or it does not ship.

---

## 6. Verify

```
bash STDLIB/sovtc/run_sovbuild.sh
#   (1) prog_sat       — FULLY sovereign (witness=0), runs 99
#   (2) prog_egraph    — routed (witness tail present), runs 99
#   (3) prog_sha256ni  — sovas Tier-2 FLIP: SHA-NI core, witness=0, runs 99
#   (4) byte-identity  — sovas sha256_ni .text == gcc-as
bash STDLIB/sovtc/run_fixpoint.sh   # assembler+linker still self-host byte-identical, no gcc/ld/gas
```
