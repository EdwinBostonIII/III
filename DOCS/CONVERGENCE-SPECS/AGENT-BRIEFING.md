# III Convergence — Design Agent Briefing (READ IN FULL FIRST)

You are a **design agent** in a 25-way parallel convergence build of the III sovereign deterministic substrate. You own **exactly one `.iii` module**. Your job is **design + audit**, NOT implementation. You produce one spec document. You do not write into `STDLIB/`, do not edit any shared file, and do not run builds. Read-only on the tree **except** your own spec file.

---

## 0. What III is

III is a sovereign, deterministic systems language + substrate. Programs compile through a self-hosting `.iii` compiler (`COMPILED/iiis-0/1/2/3.exe`) to native code. Every computation is **bit-identical across runs**, witnessed (cryptographically chained), capability-mediated, and reversible by default. There is **no machine learning, no heuristics, no floating point in any bit-identical path, no third-party code**. The substrate hand-rolls everything on libc + its own BOOT headers.

Your module is one of ~68 not-yet-built modules from `C:\Users\Edwin Boston\Downloads\III_CONVERGENCE_GOSPEL.md` (the "gospel"). The gospel section for your module contains a **candidate `.iii` body** of unknown completeness — possibly complete, possibly partial, possibly a stub the user called "halfassed." **Your spec must judge it and close every gap.**

---

## 1. The Twenty Mandates (M1–M20) — every design must honor these

- **M1 NIH** — only libc + III BOOT headers. Hand-roll all algorithms. No third-party deps, ever.
- **M2 Pure Determinism** — identical inputs → bit-identical outputs, cross-run, cross-CPU.
- **M3 No Machine Learning** — never count-and-promote, observe-and-adapt, threshold-trigger, or learn from data. That is ML in disguise and is forbidden.
- **M4 No Heuristics** — decisions are exact/algebraic, never "good enough" guesses.
- **M5 No Bricking** — no operation can render the substrate unrecoverable; reversibility or refusal.
- **M6 Cryptographic Witness Continuity** — state transitions emit witness fragments that chain by hash.
- **M7 Ring Architecture Preserved** — respect the ring assignment in your gospel header (R3/R0/R−1/R−3).
- **M8 Capability-Mediated Access** — privileged actions require an explicit capability argument.
- **M9 Reversibility Default** — operations are reversible unless explicitly, capability-gated otherwise.
- **M10 Witness Reproducibility** — any OK witness must be recomputable byte-identically from recorded inputs.
- **M11 Curry-Howard Operationality** — proofs are programs; proof terms are first-class where the module deals in them.
- **M12 Synthesis Verifiability** — any synthesized artifact carries a checkable certificate.
- **M13 Reflection Boundedness** — self-reflection is bounded, governed, never includes itself unboundedly.
- **M14 Mathematical Library Discipline** — library entries carry dependency closure + provenance.
- **M15 Algebraic Determinism** — algebraic operations are total + deterministic over their bit width.
- **M16 Branch Ratifiability** — divergences are anchored + ratifiable.
- **M17 Memoization Sovereignty** — memo results are chain-verified, never blindly trusted.
- **M18 Theorem Carrier Discipline** — theorems travel with witnessed proof terms.
- **M19 Cost Lattice Boundedness** — every operation's cost is bounded under the cost lattice.
- **M20 Substrate Self-Reasoning Limit** — the substrate does not reason about itself beyond the governed boundary.

If your module's gospel body violates any mandate, **flag it** in your spec.

---

## 2. Murphy's Laws (W-laws) — the code-shape rules your API + skeleton MUST obey

- **W2** — at most **4 parameters** per function. More → pass an aggregate by pointer.
- **W13** — at most **20 named locals** per function.
- **W15** — **no recursion** in production code. Use explicit stacks (module-scope arrays).
- **W14** — **sentinel loop pattern; no `break`.** Loop on a condition that a flag/counter drives.
- **W9** — error codes are **negative `i32`**.
- **W10** — boolean returns are **`u8`** (0/1).
- **W11** — compare negative `i32` via **equality only** (`== / !=`), never ordering.
- **W4** — **mask `u32` ops** (`& 0xFFFFFFFFu32`) to avoid high-bit garbage.
- **W6 / W7** — arena scope = function scope; module-scope arenas have explicit lifecycle.
- **W8** — slot tables are **statically sized** (fixed module-scope arrays; justify the bound).
- **W12** — every public function returns a status (or a sentinel-typed value).
- **W1 / W3** — no global pointer escape; address-of-static taken only inside the defining file.
- **W5** — bit identity over abstraction: prefer the representation that is reproducible.
- **W16/W17** — witness fragments produced under reversibility; algebraic time advances monotonically.

---

## 3. The `.iii` COMPILER TRAP CATALOG — violating these causes SILENT CORRUPTION or SIGSEGV

These are confirmed, painful, recurring `iiis-0` bugs. Your spec's API + skeleton must be trap-free, and you must list which traps your module is exposed to.

1. **Multi-line `fn` declarations are forbidden.** The entire `fn name(params) -> ret @attr {` prefix MUST be on a single line. Wrapping it either fails to parse OR (worse) **silently emits wrong codegen** with params bound to wrong stack offsets — producing output that is "close but wrong" (e.g., a hash off by one byte). **Every function signature is single-line.**
2. **Module-level `const` is linker-global.** Every `const NAME : T = V` at module scope emits a global symbol `L_NAME` even without `@export`. **Two modules cannot both declare `OK` / `BUF_LEN` / `MAX`.** → **Prefix every module-level constant with your assigned PREFIX** (e.g., `SAT_OK`, `SAT_MAX_VARS`). Grep the existing `STDLIB/` to confirm your prefix does not already collide.
3. **Signed-integer ordering compares SIGSEGV.** `if x >= 0i64` / `<` / `<=` / `>` on `i64`/`i32` crash iiis-0 codegen. **Use `== / !=` against a sentinel only.** (e.g., compare to `-1i64`, not `< 0`).
4. **`u32`-in-`u64`-slot garbage.** u32 locals aren't zero-extended in their 8-byte slot. Reading `as u64` then doing pointer math → wild address → SIGSEGV. **Mask `(x as u64) & 0xFFFFFFFFu64` before any pointer arithmetic.**
5. **`u32` pointer store width.** Writing `p[0] = v_u32` through a `*u32` may emit an 8-byte `movq`, clobbering the adjacent slot. **Store byte-by-byte through `*u8`** when the value came from a u32 local.
6. **Nested `/* */` block comments are unsupported** — the first `*/` ends the comment. Never nest. Use `//` or `(...)`.
7. **Local `var` array declarations are unsupported.** `var foo : [u8; 32]` parses only at **module scope**. Declare scratch buffers at module scope with a unique (prefixed) name. (Not reentrant — acceptable for serialized hashing/crypto; note it if your module needs reentrancy.)
8. **`} else {` must be on one line.** `}\nelse {` is a parse error.
9. **Em-dash `—` (U+2014) in a `/* */` comment terminates the comment early** → following text lexed as code → spurious "unresolved identifier" errors. **Use ASCII `--` in all comments.**
10. **`let mut x = 0u32` as a checkpoint-flag misbehaves** — prefer an early-return pattern over a mutated flag where possible.
11. **`a % b` after a function call can return the quotient / a stale divisor** (param-spill family). For power-of-two moduli use a byte-mask (`& (D-1)`); otherwise reduce explicitly. Flag any modulo-after-call in your algorithm.
12. **`@specialize *T` indexed `p[i]` stride defaults to 8 bytes** for a type-param `T`. If your module is generic over element width, assert byte layout / force a representative grow in the KAT.

---

## 3.5 KNOWN SYSTEMIC GOSPEL DEFECTS (confirmed Batches 1–2 — correct + flag any you touch)

The gospel's candidate bodies share recurring extern/API errors against the REALIZED substrate. **Always read the real provider file to confirm a dependency's exact signature before declaring an extern** — the gospel's externs are unreliable.

1. **keccak:** `extern keccak256_init/update/final from "keccak.iii"` is WRONG → those live in `keccak256.iii`. Prefer `keccak256_oneshot(in:*u8, len:u64, out_32:*u8) -> i32`. (`keccak.iii` exports only f1600/absorb/squeeze.)
2. **witness emit:** `extern ws_emit_fragment from "witness_spine.iii"` does NOT exist. The real, BUILT emit primitive is `wh_publish(producer:*u8, opid:*u8, in_commit:*u8, out_commit:*u8, revtag:u8, phase:u8, pillar:u16, antecedents:*u8, n_ante:u32, payload:*u8, payload_len:u32, out_frag_id:*u8) -> u64` in `aether/witness_hook.iii`. Route fragment emission through it.
3. **constitution lookup:** `cons_find` real signature is `-> u32` with absence sentinel `0xFFFFFFFFu32` (slot 0 is a VALID clause). Gate with `== / != 0xFFFFFFFFu32`, never `!= 0i32`.
4. **algebraic time:** `at_now` does NOT exist. The built `numera/algebraic_time.iii` provides the monotonic clock under a different name (`at_current` / `at_advance`) — read it and use the real symbol.
5. **capability check:** `cap_verify` does NOT exist. The built `aether/capability.iii` models caps as `u64` ids carrying a `u64` rights bitmask; use the real rights-check (`cap_verify_rights(id:u64, required:u64) -> u8`) and the real right-bit constants. Read the file.
6. **witness_hook accessors:** modules needing fragment fields (producer/opid/pillar/out_commit/at_time/revoked) require getters that the built `witness_hook.iii` does not yet export. The data exists in its arrays; Phase 2 adds the trivial getters. Declare the externs you need and list them in your Gap/Fix list.
7. **ed25519 signing:** `ed25519_sign` real signature is `ed25519_sign(seed:*u8, pk:*u8, msg:*u8, msg_len:u64, sig:*u8) -> u8` — it takes a 32-byte SEED (not a 64-byte private key), 5 params. The gospel's ed25519 externs are wrong in file/signature/return/order. Read `numera/crypt_ed25519.iii` for the exact sign/verify/derive surface; W2-clean callers fold `seed‖pub` into one `*u8`.

---

## 4. Your deliverable — write to `DOCS/CONVERGENCE-SPECS/<module_basename>.spec.md`

(`<module_basename>` = the file name without dir/extension, e.g. `sat`, `cg_pure`, `algebraic_consensus`.)

Use **exactly** these sections:

```
# <NN> <path> — Implementation Spec

## Verdict
COMPLETE | PARTIAL | STUB — one line on the state of the gospel's candidate .iii body.

## Purpose
2–4 sentences: what this module IS (ontology), its Hexad kind, Ring, K-vector (from the gospel header).

## Public API
Every public fn as a SINGLE-LINE .iii signature, exactly as it must appear, e.g.:
  fn sat_solve(cnf: *u8, n_clauses: u32, out_model: *u8) -> i32 @export
Note return-status convention (W9/W12) per fn.

## Constant Namespace
PREFIX = <YOUR_PREFIX>_  . List every module-level const (name : type = value). Confirm (grep result) no collision with existing STDLIB symbols.

## Data Structures
Every module-scope array/buffer: name, type, fixed size, and the bound justification (W8). No local var arrays (Trap 7).

## Dependencies (externs)
Each `extern @abi(c-msvc-x64) fn ... from "<module>.iii"` you rely on, with the providing module's NN. Mark any dependency that is itself not-yet-built (so the wave scheduler can order you).

## Algorithm
Per public fn: the exact deterministic algorithm, step by step. NIH (M1) — name the hand-rolled method. No ML/heuristics (M3/M4). State how determinism (M2) and bit-identity (W5) hold. No recursion (W15) — describe the explicit-stack form.

## KAT Vectors (>= 3)
Concrete input -> expected output triples that a self-test will check byte-for-byte. These become the Phase-2 acceptance gate. For crypto/hashing, cite the standard test vector.

## Trap Exposure
Which of the 12 traps (Section 3) this module touches, and the exact avoidance for each.

## Gap / Fix List
If PARTIAL/STUB: every missing piece + every mandate/law/trap violation in the gospel body, each with the fix. If COMPLETE: state what you verified.

## Implementation Skeleton
The .iii module scaffold: `module <name>`, externs, consts, module-scope data, and fn signatures with `// TODO: body per Algorithm §` comments. SINGLE-LINE signatures. NO full fn bodies (Phase 2 writes those). This must be paste-ready structurally.
```

---

## 5. Process (do in order)

1. Read this briefing fully (done).
2. `grep` your exact module header in the gospel (`C:\Users\Edwin Boston\Downloads\III_CONVERGENCE_GOSPEL.md`) and read your **entire** module section — prose intro **and** the candidate `.iii` body.
3. Read **1–2 named exemplar built modules** (given in your dispatch) for `.iii` idiom + house style.
4. `grep` `STDLIB/` for your assigned const PREFIX to confirm no collision; adjust if needed and note it.
5. Audit the candidate body against §1 mandates, §2 laws, §3 traps. Realize the **maximal** intent of the gospel spec (M-level ambition, "regardless of pragmatism") — do not down-scale.
6. Write your spec doc per §4. Be exhaustive and exact. Return a 3-line summary (Verdict, # public fns, # not-yet-built deps).

**Do not** implement the `.iii` into STDLIB. **Do not** edit shared files. **Do not** run the build. Your spec is the contract Phase 2 implements against.
