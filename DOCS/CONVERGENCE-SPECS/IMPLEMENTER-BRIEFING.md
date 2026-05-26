# III Convergence — Implementer (Writer) Briefing (READ IN FULL FIRST)

You are a **Phase-2 implementer** in a parallel module build. You own **exactly one `.iii` module**. You **write only your own new file**; you do **not** edit any existing/shared file, do **not** modify build scripts, and do **not** run the shared build. You MAY run `iiis --compile-only` on your own file to self-check. This is what makes 25-way parallelism collision-free: distinct new files + unique const prefixes + no shared-build mutation.

---

## 0. Inputs (in priority order)

1. **YOUR DESIGN SPEC — AUTHORITATIVE:** `C:\Users\Edwin Boston\OneDrive\Desktop\III\DOCS\CONVERGENCE-SPECS\<name>.spec.md`. It is the contract. Implement its **Public API verbatim** (dependents link against those exact single-line signatures), its **Constant Namespace** (your assigned PREFIX on every module-level const), its **Data Structures**, its **Algorithm** (per fn), and close **every item in its Gap/Fix list**. Implement its **KAT Vectors** in the embedded selftest.
2. **`DOCS/CONVERGENCE-SPECS/AGENT-BRIEFING.md` §1–§3.5** — the M1–M20 mandates, Murphy's Laws, the 12 `.iii` compiler traps, and the 8 systemic gospel defects. All binding. (You do not need to re-derive them; the spec already applied them — but you must not re-introduce them.)
3. **Exemplar built modules** (named in your dispatch) — copy the house `.iii` idiom exactly.
4. **The gospel section** (reference only) — its candidate `.iii` body has the defects your spec already corrected. Do **not** copy it blindly; the spec supersedes it.

---

## 1. Output — exactly two things, both NEW files you create

1. **The module:** `STDLIB/iii/<path>.iii` (e.g. `STDLIB/iii/numera/sat.iii`). The complete module: header comment, `module <name>`, corrected `extern` declarations (per the spec's Dependencies §), prefixed consts, module-scope data, and every public fn with a real body implementing the Algorithm. No stubs, no `// TODO`, no placeholder returns (M-discipline: no placeholders, prove the negative case).
2. **An embedded self-test** inside that same module: `fn <prefix>_selftest() -> u64 @export` that runs the spec's KAT vectors and returns **`99u64` on full pass**, or a distinct small non-99 code at each failed check (so a failure is diagnosable). This mirrors every built module (`wh_selftest`, etc.). Where the spec or a mandate requires proving a gate REJECTS bad input, include a **negative-case** assertion (prove it fails, not just that the happy path passes).

The main session (not you) wires your module into `build_stdlib.sh` (MODULES list), adds a corpus test that calls `<prefix>_selftest`, and adds its `EXPECTED=99` entry, during serial integration. **Do not touch `build_stdlib.sh` or `run_corpus.sh`.**

---

## 2. Self-check (required before you report)

Run a compile-only check on your module (externs to not-yet-built deps are fine — they resolve at link, not compile):

```
"C:/Users/Edwin Boston/OneDrive/Desktop/III/COMPILED/iiis-2.exe" "C:/Users/Edwin Boston/OneDrive/Desktop/III/STDLIB/iii/<path>.iii" --compile-only --out "/tmp/<name>.o"
```

A clean exit (rc 0) means it parses + compiles (this is what catches the silent-corruption traps — multi-line `fn`, em-dash, local `var` arrays, etc.). If it errors, read the message, fix, repeat. **Do not report success until compile-only is clean.** (You cannot link/run — that needs the full stdlib; the main session does link + KAT + the determinism gate during integration.)

---

## 3. Hard rules (non-negotiable — these are why parallel writing is safe)

- **Distinct new file only.** Your module file does not exist yet; create it. Never edit an existing file. Never edit another module. Never edit build scripts.
- **Unique PREFIX on EVERY module-level const** (and module-scope `var`) — your assigned prefix (Trap 2: consts are linker-global). Grep `STDLIB/` to confirm zero collision before finalizing.
- **Single-line `fn` signatures** (Trap 1 — multi-line silently miscompiles).
- **No local `var` arrays** — module scope only (Trap 7). **No recursion** (W15 — explicit module-scope stacks). **No `break`** — sentinel-flag loops (W14). **≤4 params** (W2 — aggregate by `*u8`). **≤20 locals** (W13).
- **Signed integer compares via `== / !=` only** (Trap 3 — `< <= > >=` on i32/i64 SIGSEGV). **Mask `(x as u64) & 0xFFFFFFFFu64` before pointer math on u32** (Trap 4). **Byte-store through `*u8`** for u32-origin values (Trap 5). **`} else {` on one line** (Trap 8). **ASCII `--` not `—` in comments** (Trap 9). **No nested `/* */`** (Trap 6).
- **Use the CORRECTED externs** (per spec Dependencies + AGENT-BRIEFING §3.5): `keccak256_oneshot`/streaming from `"keccak256.iii"` (never `keccak.iii`); witness emission via `wh_publish` from `"witness_hook.iii"` (never `ws_emit_fragment`); `cons_find -> u32` sentinel `0xFFFFFFFFu32`; the real `algebraic_time` symbol (`at_advance`/`at_current`, never `at_now`); `cap_verify_rights(id,required)` (never `cap_verify`); the real `ed25519_sign(seed,pk,msg,msg_len,sig)`/`ed25519_verify(pubkey,msg,msg_len,sig)` order. **Always confirm an extern's exact signature against its real provider file before declaring it.**
- **Determinism/NIH:** pure, bit-identical, integer-only (no float in any output-bearing path), libc + III only. No ML, no heuristics, no observational learning.

---

## 4. Report (terse)

When done, report exactly: (a) compile-only result (CLEAN / errors fixed), (b) the module file path + public-fn count vs the spec's, (c) any deviation from the spec + why, (d) externs to not-yet-built deps (so the integrator confirms wave order).

---

## 5. ADDITIONAL TRAPS — discovered in Wave 1 (avoid these from the start)

These compile-clean-but-fail or hard-parse-error patterns were hit by Wave-1 writers; they are NOT in AGENT-BRIEFING §3 yet:

13. **Parser block-nesting depth limit (~7).** A function body plus ~6 nested `if`/`while` levels is the maximum; deeper nesting raises `RECURSION_LIMIT` / a parse error. **Decompose any deep algorithm into flat private helpers** that share per-call state via uniquely-prefixed module-scope context vars (the same serialized-state idiom used for scratch buffers). Keep each function's nesting shallow. (Hit by galois `bm_decode`/`lagrange_eval`, egraph `rebuild`/`extract`.)
14. **`var` is a reserved keyword** — it cannot be a parameter or local identifier. Rename (e.g. `vr`). A parameter's *name* is not part of the C-ABI (only its type, position, and the function name/arity/return are), so renaming a parameter — even one a spec/extern declared as `var` — is safe and does not break linkage. (Hit by sat's `sat_value(var: u32)`.)
15. **Null-pointer cast in parentheses as a direct call argument** — `f((0u64 as *u8), ...)` raises "ambiguous parenthesised expression". **Bind it to a typed local first:** `let nullp : *u8 = 0u64 as *u8` then pass `nullp`. (Hit by curry_howard.)
16. **Leading-paren literal expression** as an RHS/arg — e.g. `(0u32 << 1u32) | 1u32` — raises "ambiguous parenthesised expression after partial hexad". Avoid a leading `(` on a literal expression; compute it in a helper or restructure so the expression does not start with `(`. (Hit by egraph.)
17. **A literal `*/` inside a `/* */` comment's PROSE** (e.g. writing `GF128_MUL_*/POW_*` or `gfp_*/bigint` in a comment) terminates the block comment early — Trap 6 generalized beyond nesting. **Never write the two-character sequence `*/` inside comment prose;** reword (e.g. `MUL / POW`). (Hit by galois.)

18. **`u64 / u64` and `u64 % u64` compile as SIGNED `idivq`** (verified at machine-code level: iiis-2 emits `cqto; idivq`). For any dividend/divisor where bit 63 can be set, the quotient/remainder is WRONG (signed semantics: e.g. `0xFFFF…FE / 0xFFFF…FF` returns `2` instead of `0`). This is a SILENT miscompile — `--compile-only` does NOT catch it (it compiles fine; the result is just wrong at runtime). **Never use `/` or `%` on u64 values that may have bit 63 set.** Use a divide-free method (32×32 partial products for a 64×64→128 overflow check; shift for power-of-two division; subtract-loop or bigint for true wide division), or prove both operands are < 2^63 first. (Found in cost_lattice's overflow detector; affects any ratio/simplex/modular path on wide values.)

19. **iiis reserves 8 BYTES PER ARRAY ELEMENT (the u64-slot model), regardless of declared type.** `[u8; N]` reserves **8N** bytes; `[u32; N]` reserves **8N** bytes — NOT N or 4N. So a large byte/u32 buffer bloats your module's `.bss` 8×/2×. This matters because the WHOLE stdlib links into one binary whose total `.bss` must stay under the **~2 GiB small-code-model RIP-relative limit** (witness_hook alone is ~1.4 GiB of it); blowing it gives `relocation truncated to fit: IMAGE_REL_AMD64_REL32 against .bss` and **every** corpus test fails to link. **For any buffer larger than ~1 MB, use the frugal idiom:** declare `var X : [u64; (bytes+7)/8]` and access via byte pointer `((&X as u64) + off) as *u8` (the `witness_hook.iii` pattern — EXACT capacity, 1/8 the BSS). **Never write `[u8; big]` directly.** `--compile-only` does NOT catch this (it's a link-time/aggregate failure); keep your declared capacity at the spec and represent it frugally.

Run your `iiis --compile-only` self-check (§2) — it catches the parse/codegen traps (1, 6–17). Traps 3, 4, 18, 19 are SILENT at compile time (wrong runtime result, or a link-time aggregate failure) — your embedded KAT (run by the integrator) gates 3/4/18; trap 19 you avoid by construction (frugal `[u64;]` for big buffers). Make your KAT vectors exercise the high-bit / signed-edge cases. Fix and re-run until clean before reporting.
