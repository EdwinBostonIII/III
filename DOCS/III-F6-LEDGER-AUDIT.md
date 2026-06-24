# III F6 — Broad-Ledger Adversarial Audit (the wider sweep)

**Date:** 2026-06-24. **Method:** a Workflow fanned 11 high-profile "COMPLETE/PROVEN/MEASURED" ledger claims through
read-only adversarial auditors (default-to-refuted, file:line evidence), each finding then independently re-checked by
a second refuting reviewer. The same lens that found F1–F10 in the Grand-Unification arc, turned on the rest of the
ledger. This is the F6 the GU audit-and-plan named as owed.

## Verdicts

| Claim | Verdict | Sev | One-line |
|---|---|---|---|
| **zk-base-field** | ✅ CONFIRMED | — | `air_stark_verify` is genuinely Merkle-committed (reads only roots + opened values, recomputes constraint via `air_combine_opened`); malicious-prover arms reject. Honestly capped STRUCTURAL ~2⁻¹¹ in `run_zk.sh:207`. |
| **cad-contentaddress** | ✅ CONFIRMED | — | `cad` is a real FIPS-180-4 SHA-256 / Keccak-256 commitment with re-derive-and-compare verification; negative arms flip input and assert digest differs. Understatement, not overclaim. |
| **affine-audit** | ⚠️ GAP → **FIXED** | med (soundness) | A module-GLOBAL loop counter mutated by a callee **by name** passed all three establishment guards → **false PROVEN**. Fixed (see below). |
| **crypto-speedup** | OVERCLAIMED | med | The one-liner "Montgomery ~2.4x SLOWER" is **stale and reversed** — the landed allocation-free CIOS REDC made it ~2.5× FASTER (bench 991 gates the faster *direction*; both primary docs say FASTER). "Knuth multiplication" mislabels **division** (bench 990 = `bigint_div_qr`). Magnitudes (177–258×, 2.5×) are correctness-/direction-gated but **magnitude-advisory** dev-host ratios, not enforced. |
| **xii-confluence** | OVERCLAIMED → **SURPASSED** (discharge) | med | The headline "any redex order → same NF" stays calibrated to "deterministic by a fixed bottom-up strategy" (the engine's own `xjn_gate()==0`/20-non-joins refutes global confluence; ARCH §10 disclaims it). But the audit's concrete defect — the route-R discharge was an **unconditional assignment** (`xdc_route_classify(assoc, 1u8, 0u8)`, `BOUNDARY` structurally unreachable = tautology) — is **fixed by making it a genuine per-pair verification:** `xjn_route_r_holds` now computes, per pair, `struct_eq(canonicalise(unreduced witness), inner-first NF)` — confirming `xii_canonicalise` actually reduces the inner redex first, so the divergent outer-first reduct is non-normal-reachable; `xdc_route_of` reads this computed verdict as `is_subterm`, so **BOUNDARY is now reachable** (a pair that failed inner-first → `rv=0` → BOUNDARY → selftest reddens). Verified: all 20 residuals compute route-R, BOUNDARY=0, KAT 825 + 1484 rc=99 against the rebuilt lib. The "empty boundary discharged, not claimed" is now true — *computed*, not asserted. |
| **sovereign-optimizer** | OVERCLAIMED → **SURPASSED** (proof→emit bound) | med | Was: "proof-carrying" had **no mechanical proof→emit binding** — the BV64 kernel proof (`sov_isa.iii:2603-2618`) is genuine but lives in a corpus/1207 sandbox and never inspects the emitter (binding = a prose comment); the Path-C table+certifier (`III-OPTIMIZER-PATH-C.md`) was **unbuilt** (no `cg_opt_rules.*`). **Built it:** `forcefield/cg_opt_rules.iii` is the single-source SR table (factor 2^k → `shl $k`); `cor_certify_all` proves **per rule** both the **width-invariance guard** (`factor == 1<<k` exactly — the soundness contribution) and the **CIC BV64 kernel proof** (`tc_check` of `x<<k == x*2^k mod 2^64`), with a **prove-the-negative** arm (`cor_rejects_unsound`: non-pow2 + off-by-one rejected). The **drift gate** `scripts/cg_optrules_bind_gate.sh` reads this same table and asserts cg_r3's **actual machine code** matches — every tabled `2^k` → `shl $k` (objdump-verified, k=1..63), non-pow2 → `imul` (teeth). Gate **EXIT 0**, corpus **2002**=99. So the *binding* now exists mechanically (kernel proof ↔ width guard ↔ real emission, one source) — the gate reddens if cg_r3 ever diverges from the certified table. **Honest residual:** this binds-by-verification; the deeper migration (cg_r3 itself becoming *table-driven*, reading `cg_opt_rules` instead of its own hardcoded peephole) is the next step — but the proof no longer fails to inspect the emitter. The separate "byte-MATCHES" phrasing stays calibrated (the fold emits *fewer* bytes by design). |
| **apotheosis-invariants** | OVERCLAIMED | **high** | "All 13 Harmony Invariants hold / VERIFIED COMPLETE" overstates "**13 per-organ unit tests pass on hardcoded witnesses + each fold is falsifiable by a synthetic canary**". `charter_terminal` re-runs each organ's own `h{N}_selftest`; it performs no systemwide audit (no scan that every boundary is a SovVal / no second evaluator / no real-tree C scan). The doc's **own** consistency-audit lists **7 structural halves as unbuilt migrations**; each `h{N}_charter` docstring concedes its structural half is "a property a runtime clause cannot see." Green corpus-700 ≠ the systemwide invariants. |
| **ccsv-cseed** | OVERCLAIMED | **high** | "Compiles the C seed subset through P3" overstates. **No gate ever feeds the real iiis-0 BOOT frontend** (`cg_r3/ast/parse/sema/lex/emit/main.c`, ~15.3k lines) to ccsv — the gate runs curated feature tests + standalone crypto + one extracted SHA leaf. Per the dev's own notes ccsv reaches only fn ~9-15 of each (files have 67-185 fns), the **dominant blocker (struct-array tables `T[i].field`) is OPEN/reverted**, and **"P3" (the cross-module linker) is unbuilt**. The substrate is genuine; the defect is SCOPE/LABEL. (The ccsv worker is concurrently active on the code.) |
| **conjecture-faculty** | OVERCLAIMED | med | The propose→dispose→admit mechanism is **real and sound** (μ reduction-order termination, exhaustive bounded decision, congruence-closure joinability) but operates only over **toy, test-constructed carriers** (32 ground symbols / depth-1 f-terms / 5 hardcoded predicates), is wired to **no live consumer**, and the doc itself concedes completion vs III's live XII rule set is **vacuous** (XII already Knuth-Bendix-complete). The §2 flagship "mechanism-isolated regression" (case D) is over-determined (rejection is seed-driven, not candidate-driven). "Non-trivial conjectures (a real capability)" oversells a sound-but-inert standalone demonstration. **[CALIBRATED 2026-06-24]** the doc was already honest (it concedes BOTH vacuity theorems in §2); added a head-of-doc F6 calibration that (a) reads "a real capability" precisely as a sound-but-inert standalone demonstration over toy carriers wired to no live consumer (live-XII = vacuous), and (b) records the case-D over-determination (seed-driven, not candidate-driven). A genuine SURPASS would need a *non-vacuous* live consumer (an open problem outside KB-complete XII) — large + speculative, so calibrated, not faked. |
| **authentic-capability** | OVERCLAIMED | **high** | 7 of the demonstrated capabilities use genuinely independent verifiers (sha256sum, Python hashlib/cryptography, RFC/Ethereum vectors) and hold. But the **capstone** (cap-11, billed "PROVEN ON METAL, confirmed by the Windows kernel itself") has **zero retained on-metal evidence**: its cited artifact `m23_deploy_log.txt` is **absent from the tree**, the three "proven" `.sys` hashes are mutually inconsistent and live only in prose, the one surviving investigation artifact records the live run **FAILING (exit 7)**, and the only in-repo gate (corpus/1047 → `ks_selftest`) is a **user-mode self-graded KAT** comparing to an embedded FIPS constant + a self-computed seed. The live Ring-0 adversary arm is never exercised. |
| **build-repro** | OVERCLAIMED → **SURPASSED** | med | Was: `run_repro.sh` only re-ran the back-end on one cached `.s` (near-tautology); the front-end was never re-compared. **Fixed by making it true:** the gate now runs the FULL front-end (ccsv→iiis-2→svir_x86) TWICE from scratch and diffs **every stage** — proven BYTE-IDENTICAL at the ccsv `.iii`, iiis-2 `.o`, and svir_x86 `.s` (sha `3f123ea8…`), AND the sovas/sovld PE byte-identical (runs 99). So the full III pipeline is genuinely byte-reproducible; the lone residual is the host gcc-LINKED iiis-1 (PE-link variance at scale, `SVIR-DDC-RESIDUAL.md`) — measured to the HOST, not III. Gate EXIT 0. |
| production-readiness | MOSTLY-HONEST (calibrate) | low | Re-audited (the first run's verify hit a 500). The doc is **largely honest + evidence-backed** — real gates (`build_stdlib` PASS=456, `run_corpus` PASS=769, `run_xii_corpus` PASS=92, `subsystem_test_gate`), and it *honestly scopes* the risky parts: cg_r0 driver "loading NOT attempted", Live-OS bluepill (I5) "DESIGNED, deliberately NOT executed", driver "operator-gated, NOT done automatically", and it documents finding+fixing a real latent NULL-deref. **Two residuals:** (a) its "proven on metal" Ring-0/Ring-1 lines (64-65) inherit the **authentic-capability metal residual** (operator-machine narrative, not a retained CI artifact); (b) the gate numbers are a 2026-06-03 snapshot now stale (`build_stdlib` is PASS=698, lib mhash changed). Not a strong overclaim — calibrate the metal lines + refresh the numbers. **[CALIBRATED 2026-06-24]** the two "proven on metal" rows now carry an explicit *retained-evidence residual* (operator-attested on one machine, no in-tree kernel-load transcript; the in-tree re-runnable proof stops at Ring-3 user mode), and the Evidence block carries a snapshot caveat (the 2026-06-03 counts are a growing floor — `build_stdlib` ≈ 698 in the F6 sweep — and the lib mhash reseals with the affine + cg_r0 + xii fixes; load-bearing invariant FAIL=0 holds across the change). |

## The one real soundness defect — FIXED (affine-audit)

`COMPILER/BOOT/affine_audit.iii`'s establishment guards (`aa_count_writes==1` ∧ `aa_last_stmt_writes` ∧
`aa_addr_taken==0`) are sound for a **function-local** loop counter (its only external-mutation path is `&i`, caught by
G3) but **not** for a **module-global** counter, which a callee can mutate **by name** — and `aa_count_writes` scores a
bare call as 0 writes, so the guards pass while the callee drives the counter past N before an access → a **false
PROVEN** (the audit's one forbidden outcome). Counterexample: `var G; fn bump(){G=G+5} fn f(){ while G<16 { bump();
A[G]; G=G+1 } }` → old audit PROVED `A[G]` in-bounds; runtime `G` reaches 17 → OOB.

**Fix:** added `aa_counter_extern_safe(body)` — a local (`STMT_LET`/`PARAM`) counter keeps the existing guards; a
module-global (`VAR_DECL`) counter is establishment-sound only if `aa_has_call(body)==0` (no callee can run mid-loop to
mutate it by name). Added the `s_global_callee_mutate` trap to `affine_audit_sound.iii` (must ABSTAIN; was a false
PROVEN), and tightened `affine_audit_gate.sh`'s soundness-probe assertion to the exact tally `P=1 A=6 R=0` so a
false-PROVEN regression (P=2) reddens. Codegen-independent (`--affine-audit` is a separate mode), so the corpus
byte-equivalence is unaffected.

## F11 — cg_r0 (Ring-0 backend) emitted >4th (stack-passed) parameters as undefined globals. **[FIXED + binary-verified 2026-06-24]**

**RESOLUTION:** fixed at `cg_r0.iii` — the function prologue now registers a frame slot for EVERY parameter and,
for params 5+ (Win64 stack args), copies the arg from the caller frame into its slot:
`movq 48+8*(i-4)(%rbp), %rax ; movq %rax, -slot(%rbp)`. Added the `R0_STR_RBP_CM_RAX` constant. **Binary-verified**
on `weave_blocks_r0.o` (the 10-param `wvb_arx_mix`): `nm` shows NO leaked `L_p_x/y/r0/r1`; `objdump -dr` shows
`mov 0x30(%rbp),%rax; mov %rax,-0x30(%rbp)` … at offsets 0x30/0x38/0x40/0x48/0x50 = 48+8·(i-4) exactly. **Gated:**
the cg_r0 crypto gate now `GATE PASS` (sha256/keccak/cad reproduce their FIPS vectors through the Ring-0 backend),
cg_r0 width gate `PASS=11`, corpus equivalence `59/0` (Ring-3 codegen byte-identical — the fix is Ring-0-only),
`build_iiis2 --check-corpus` exits 0. The original two-layer diagnosis follows:

Surfaced by rebuilding iiis-2 (the affine fix forced a clean `build_iiis2`, which runs `cg_r0_crypto_gate.sh`). The
gate was RED on BOTH the old and new iiis-2 (so **not** caused by the affine change). Two layers:

1. **Gate dependency (FIXED):** `sha256`/`keccak` were refactored to extern `wvb_maj32`/`wvb_rotl64` from
   `numera/weave_blocks.iii`, but the cg_r0 gate's probe `deps` lists were never updated, so `weave_blocks_r0.o` was
   never compiled/linked → `undefined reference to L_p_wvb_maj32 / L_p_wvb_rotl64`. Fixed: added `weave_blocks.iii` to
   the 5 crypto probes' deps in `cg_r0_crypto_gate.sh`.

2. **cg_r0 codegen defect (the real bug, ROOT-CAUSED, owed):** with `weave_blocks` now linked, it fails to link
   *itself* — `weave_blocks_r0.o` references `undefined L_p_x / L_p_r0 / L_p_r1 / L_p_y`. These are the **stack-passed
   parameters** of `wvb_arx_mix(va,vb,vc,vd, x,y, r0,r1,r2,r3)` — a **10-parameter** function. The Win64 ABI passes
   params 1-4 in registers (rcx/rdx/r8/r9) and 5+ on the stack; **cg_r0 emits a reference to each stack param as an
   undefined GLOBAL symbol `L_p_<name>` instead of loading it from the caller's stack frame.** So the Ring-0 backend
   cannot correctly compile any function with >4 parameters. This is the parameter-handling defect class the
   CRASH-DEBUGGING-PROTOCOL flags. **Exact root cause: `cg_r0.iii:1283` — `if pc > 4u32 { pmax = 4u32 }`** caps the
   prologue's param→frame-slot spill at the 4 register params (rcx/rdx/r8/r9); params 5+ (Win64 stack args, at
   `[rbp + 48 + 8*(i-4)]` after saved-rbp + return-addr + 32-byte shadow) are **never given a frame slot**, so the
   body's reference to such a param resolves to the global path and emits `L_p_<name>`. **Fix approach:** in the
   prologue (cg_r0.iii ~1278-1286), for `pi` in `[4, pc)` load the stack arg from the caller frame and store it to the
   param's local slot (so every param has a slot), *or* teach the param-ref codegen (`r0_emit_param_sal` /
   the IDENT path) to emit a `[rbp+offset]` load for `pi>=4`. Must follow the protocol (read the whole frame/param
   path, audit before edit, disassemble-verify the fixed `.o` reproduces the FIPS vector) — a focused backend pass,
   not a tail-of-session edit. Until then the cg_r0 Ring-0 crypto gate stays RED and `build_iiis2 --check-corpus` exits
   5 *after* a clean corpus (59/0) + install — i.e. the produced iiis-2 is valid for Ring-3 (the only regression is the
   pre-existing Ring-0 crypto path).

## Disposition of the OVERCLAIMED set

These are **claim/reality mismatches**, not broken code (every audited mechanism is itself sound — the *prose* and the
compressed MEMORY one-liners overstate scope or are stale). The fix is **honesty**: calibrate each claim to what the
code does. The corrections are applied to the live MEMORY ledger one-liners (this turn). Two carry a feasible
code-strengthening beyond re-wording (xii-confluence: a genuine per-pair BOUNDARY verification in `xdc_route_of`;
build-repro: run the full front-end twice + diff the host) — logged here as the surpass path, distinct from the unbuilt
large items (apotheosis 7 migrations, ccsv seed compilation, Path-C optimizer binding) whose honest fix is the
calibrated claim until they are built.
