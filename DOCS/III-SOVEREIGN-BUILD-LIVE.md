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
- **Not yet:** `sovas` Tier-2 (VEX/EVEX/SHA-NI encoding). When it lands, the tail goes sovereign and gcc leaves the
  build entirely. This is the named Stage-3 of the toolchain doc.
- **Verification constraint:** this is a Windows/x86-64 host — only x86-64/PE artifacts can be *executed* here. A
  second OS/ISA backend (ELF/SysV, non-x86) is a later increment, validatable structurally but not runnable here.

---

## 4. The bridge to EIDOS (I1 — next)

The route decision (which encoder a module is reachable through) is a **capability/silicon** fact. Today it is read
from `sovas`'s exit code; the EIDOS endgame (this doc's whole point, and `eidos/anchor`'s "trust root on the
census-verified silicon") is to make **`eidos/anchor` + `eidos/compose` the LIVE CONSUMER** that decides the route
from the host's **silicon census** (`numera/cpufeat` — SHA-NI / AVX2 / AVX-512 presence) under a cost order — so:
- different silicon ⇒ different reachable encoder set ⇒ **different (still-correct) build plan**, and
- a census-driven implementation choice (e.g. SHA-NI vs software `sha256`) yields **materially different PEs that
  both run to 99** — proven across two profiles via `cpufeat_force_mask`.

That closes both open rungs at once: the toolchain doc's "trust root on silicon," and EIDOS's confessed
"SEVEN capabilities, ZERO live consumers." It is the first time a **real III binary-production operation** consumes
the host-adaptive planner.

---

## 5. Verify

```
bash STDLIB/sovtc/run_sovbuild.sh
#   (1) prog_sat   — FULLY sovereign (witness=0), runs 99
#   (2) prog_egraph — routed (witness tail present), runs 99
bash STDLIB/sovtc/run_fixpoint.sh   # assembler+linker still self-host byte-identical, no gcc/ld/gas
```
