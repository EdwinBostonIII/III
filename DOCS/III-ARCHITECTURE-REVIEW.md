# III — Architecture Review (production-readiness pass)

*Applying the /architect discipline to III's actual domain (a self-hosting NIH compiler + below-OS
substrate), not the generic web-app template. Source-grounded. The central question: is the three-backend
**element-model seam** an architecturally sound design or a structural liability, and what would make the
seam-class defect **impossible-by-construction** rather than **found-by-audit**?*

## 1. Executive summary

III is a self-hosting compiler (C seed `iiis-0` → `iiis-1` → `iiis-2`, gated by stage1 byte-identity) with
**three codegen backends** that deliberately differ in their **element model**:

| Backend | Ring | Element model | `[u8;N]` | `*u8` stride | Rationale |
|---|---|---|---|---|---|
| `cg_r3` | R3 (user) | **byte-packed** | N bytes | 1 | C-ABI compat + memory density |
| `cg_r0` | R0 (kernel) | **8-byte-uniform** | N·8 bytes | 8 | codegen simplicity (every value a u64 slot; no sub-word load/store) → correctness-first in the kernel |
| `cg_rm1/rm2` | R-1/-2 (sanctum) | 8-byte-uniform (via `emit_sanctum.iii`) | N·8 | 8 | same as cg_r0 |

This divergence is the **single largest recurring defect source**: 10+ defects across 3 audit rounds this
session were the *same shape* — **identical `.iii` source that compiles correctly under one backend's layout
and silently corrupts under another's**. The divergence itself is *sound* (each model is internally
consistent and individually metal-proven). The **liability is structural**: the shared stdlib is written
**once** but compiled under **all three** models, and the prevention is currently **reactive (by audit)**,
not **proactive (by construction)**.

**Verdict: sound trade-off, structurally under-gated.** Recommendation §4 closes the gap without
abandoning the per-backend optimization.

## 2. The seam class — taxonomy (source-grounded)

Two distinct sub-classes, both "same source, divergent backend":

**(A) Element-model seam** — byte-packed vs 8-byte-uniform layout:
- `keccak256.iii` `KK256_STATE [u64;25]` was sized 200 B (cg_r3) but `keccak.iii` drives it via `*u8` over
  byte-offsets 0..199 = 200 *slots* = 1600 B under cg_r0 → `keccak_state_zero` OOB-wrote 1400 B → SIGSEGV.
- `xii_term_mhash` composed `(p + base) as *u8` (byte arithmetic) with element-indexed feed → mixed units.
- `census.iii` / `cad` hashed a byte-packed `[u64;N]` buffer via the plain `sha256_oneshot`, whose `*u8`
  loop strides by 8 under cg_r0 → over-read + wrong digest.
- **Antipattern (the invariant being violated):** *never compose raw byte-math (`ptr + n`) with element
  indexing (`[k]`); never read/write byte-packed data with a `*u8` element index under cg_r0.*

**(B) Signedness seam** — signed vs unsigned codegen for the same operator:
- `cg_r0.iii` + `emit_sanctum.iii` emitted **signed** `setl/setle/setg/setge` for **unsigned u64** ordering
  → wrong for any u64 with bit 63 set.
- `cg_r3.iii` `r3_emit_cast_extend` **zero**-extended a **signed** narrowing cast (`x as i8`), diverging
  from the sign-extending load/return paths.
- **Invariant being violated:** *codegen signedness must derive from the operand TYPE, identically across
  backends.* Each backend re-implemented this independently (`r0_expr_is_u64`, `sv_ord_is_unsigned`,
  `r3_either_is_signed`) — divergence was inevitable.

## 3. Why by-audit is the wrong equilibrium

The audits found these by *ad-hoc* cg_r0-vs-cg_r3 differentials. That works but is **O(human attention)**:
each defect required a человек to (a) suspect the seam, (b) hand-write a differential probe, (c) run it.
A latent bug in an unexercised path (e.g. the cg_r0 signed-u64 ordering — no kernel code hits bit-63 u64
ordering *today*) survives indefinitely until someone audits that exact path. **The defect rate will track
audit effort, not code correctness** — unacceptable for production.

The existing gates (`cg_r0_crypto_gate.sh`, `cg_r0_width_gate.sh`) are the **right primitive** (automated
cg_r0-vs-cg_r3 differential) but cover only **crypto vectors** and **u32 width** — a thin slice of the seam
surface. They are the seed of the solution, not the solution.

## 4. Recommendations — making the seam impossible-by-construction

**R1 (now, highest value) — DUAL-BACKEND CONFORMANCE GATE.** Generalize the width/crypto gates into a
single `cg_seam_gate.sh` that, for a corpus of **seam-sensitive idioms**, compiles each under cg_r3 AND
cg_r0 (and cg_rm2 where ABI-expressible), runs a canonical KAT under each, and asserts **byte-identical
observable output**. Idiom families (each a known past defect): (1) byte-packed `[u64;N]` buffer → hash;
(2) `[u8;N]` array write/read all N (the keccak-state sizing class); (3) `*u8` vs `(p as *u64)[q]` element
access; (4) u64/i64/u32 ordering compares straddling bit-63/bit-31; (5) signed/unsigned narrowing casts.
This converts the seam class from *found-by-audit* to *reddened-in-CI*. It reuses the proven differential
methodology and the existing harness — **implementable immediately**, no language change. *(This review's
concrete follow-through; see §6.)*

**R2 (medium-term) — UNIFY SIGNEDNESS RESOLUTION.** The three per-backend signedness queries
(`r0_expr_is_u64`, `sv_ord_is_unsigned`, `r3_either_is_signed`) should be **one** shared resolver over the
sema-typed AST, consumed by all backends. A single source of truth makes the signedness sub-class
impossible-by-divergence (you cannot fix it in one backend and forget another — which is exactly how
`emit_sanctum` lagged `cg_r0` by a full audit round).

**R3 (long-term, the ideal) — TYPED ELEMENT-MODEL IN SEMA.** Distinguish a **byte-offset pointer** from an
**element pointer** in the type system, so that composing `ptr + n` (byte) with `[k]` (element) is a
**compile-time type error**, not a silent runtime corruption. This makes sub-class (A)
impossible-by-construction at the language level. Larger change (sema + a pointer-kind lattice); defer until
R1 has bounded the bleeding and the cost/benefit is measured against R1's residual.

## 5. Other structural findings — what is already sound (keep)

- **Bootstrap trust anchor (iiis-0→1→2 + stage1 byte-identity)**: sound. The frozen-seed design (the C seed
  `cg_r3.c` may evolve while the committed `iiis-0` binary stays frozen, *gated by stage1 byte-identity*) is
  a correct, standard self-hosting pattern — confirmed this session: the cast-extend sign fix changed
  `cg_r3.iii`+`cg_r3.c` yet stage1 (no signed narrowing casts) stayed 59/0, so no re-root was forced.
- **Forge/seal cascade (content-addressed reseal)**: sound. Strengthening a descent citizen's KAT moves its
  seal; `forge_check.sh` reddens until the sovereign ledger is re-sealed — exactly the integrity property
  you want. (Exercised this session: census fix → seal `8a508388` → descent root `35b5471d`.)
- **Determinism reseal (DRIFT-driven, gate-decides)**: sound. "Let the gate, not the a-priori argument,
  decide whether the seed moves" prevented an unnecessary trust-anchor re-root this session.
- **The de-vacuuming discipline** (a gate must FAIL on a known-bad input — `cg_r0_width_gate` and
  `check_rm2.sh` were both vacuous and were fixed to discriminate): sound; should be a **standing rule** for
  every new gate (R1's gate must itself be prove-the-negative'd).

## 6. Risk register + roadmap

| Risk | Impact | Likelihood (pre-R1) | Mitigation |
|---|---|---|---|
| Latent element-model seam in an unexercised stdlib path | Silent wrong result / kernel SIGSEGV | Medium (10+ found; tail unknown) | **R1** conformance gate |
| Signedness fix lands in one backend, not the others | Wrong ordering/cast in a lagging backend | Medium (happened: emit_sanctum lagged cg_r0) | **R2** shared resolver |
| New backend added later re-introduces the seam | Reopens the whole class | Low now, High if a 4th backend lands | **R3** typed element-model |
| A new gate is itself vacuous | False green | Medium (2 found vacuous this session) | Standing prove-the-negative rule |

**Roadmap:** R1 (this session — see the seam-gate follow-through) → R2 (next: refactor the three signedness
queries to one) → R3 (scoped after R1 quantifies the residual seam surface).

## 7. ADR-style decision

**Keep the three-backend element-model divergence** (do NOT unify the models — the per-backend optimization
is real: cg_r0's 8-byte-uniform is what makes kernel codegen simple enough to be metal-proven). **Instead,
gate the seam** (R1) and **unify the signedness resolver** (R2). The divergence is sound; the *absence of a
construction-time seam barrier* was the liability, and R1 supplies it.

## 8. Known-items register — deliberately-separated tasks (NOT skipped)

These are confirmed defects that **touch a self-host / metal / load-bearing path and are latent** (no
exercised-path crash/wrong-result today). Triage discipline (proven the hard way this session — a
"provably-safe" cast-extend correctness edit to a self-host path reddened the corpus): only round-1-class
(real crash / wrong result on an exercised path) earns an in-place fix; self-host + latent gets recorded
here with its verified fix and a *separate* deliberately-gated task. This is sequencing, not skipping.

| # | Site | Defect (confirmed by compile-and-run) | Verified fix | Why separate |
|---|---|---|---|---|
| K1 | `cg_r3.iii:817` `r3_local_lookup` | same-name local **shadowing** miscompiles: cg's slot resolver scans oldest-first + always-appends while sema's binder (which drives load WIDTH) scans newest-first → loads the OUTER slot with the INNER width (repro `let x:u64=0x12E; let x:u8=9; x` → 46, neither 9 nor 302). | ARM 1: `r3_local_lookup` scan **newest-first** (provably safe — a unique name has one slot, so only the shadow case changes, 46→9). OR ARM 2: sema rejects same-scope dup (`s_walk_stmt_let`, extend the module-scope `SEMA_E_DECL_DUP`). | Self-host (cg_r3). Latent: the 465-module tree + bootstrap never live-shadow a differing-width local (corpus/self-host green). Needs reseal + full-corpus + own decision on whether III permits shadowing. |
| K2 | `lex_rt.iii:178` `iii_lex_getenv_sde_c` | i64 overflow guard off-by-one at floor(i64max/10): `if v > 922337203685477580` lets the boundary through, then `v*10+d` wraps **negative** for d≥8 instead of the documented reject-with-0. | `if v > 922337203685477580i64 \|\| (v == 922337203685477580i64 && (ch-48u32) > 7u32) { return 0i64 }` (remainder-aware; `>=` would false-reject valid epochs up to i64max). | Self-host (lex_rt is a BOOT file → reseal). Latent: only a 19-digit `SOURCE_DATE_EPOCH` (~year 2.9e11) triggers it; never occurs in practice. |
| K3 | `cg_r0.iii:877` EXPR_CAST | cg_r0's cast is a pure pass-through ("8-byte-uniform narrows nowhere") so a **narrowing cast whose value exceeds the target width** does not truncate: `456 as u8` = 456 (cg_r3 = 200). | Add a cg_r0 cast-extend that truncates to match cg_r3's u64-uniform zero-extend (movzbq/movzwq/movl by target width). | **Metal-proven kernel backend** — alters the `.sys`, needs its own metal re-prove. Latent: the kernel hashes via byte-indexing, not width-exceeding casts. |
| K4 | `cg_r3.iii` cast-extend chain/slot asymmetry | a narrowing cast zero-extends (u64-uniform Stage-1) while the typed-slot load sign-extends → `x as i8 as i64` (chain) ≠ `let y:i8=x as i8; y as i64` (slot) for negative values. | Sign-rigor is a *future stage* needing a coordinated `as i32`→`as u32` audit of the compiler spine (the compiler self-hosts on the zero-extend at its bit-31 `as i32` sites — a point sign-extend edit reddened corpus 1113/1114 and was reverted). | Load-bearing self-host. Documented in `cg_r3.iii` r3_emit_cast_extend. |
| K5 | `STDLIB/iii/numera/sov_isa.iii` (+ corpus 1113/1114) | **CLOSED (2026-06-04).** The "Path C" dependent-type proof kernel sr-schema tower is now GENUINELY KERNEL-PROVEN. The reducer block (DEFECT-2) was fixed in `ccl.iii::ccl_eta_contract` (it no longer eta-contracts `lam x.(C x) -> C` when head `C` is a data constructor/eliminator, tag `>= CCL_TRUE`), so the closed succ-step survives `tc_shift_k` and the mandatory `tc_natrec` induction over a symbolic var closes. The old "blocked-witness" functions (which asserted a now-absent defect) were removed; replaced by `sov_l1_proven_witness` + `sov_l6_proven_witness`. | **DONE.** 1113 proves the foundation (mul_one + ap_succ + L1 `add_left_zero`); 1114 proves L6 mul-over-double distributivity via the additive Peano tower (`sov_tw_*`: add_succ_left, add_assoc, add_comm, ap_add_l/r, add_left_comm, MLD; L6 == MLD(x,m,m) since `double(v)==add(v,v)` definitionally). Built as a shared-node DAG (`sov_l6_build_tower`) to stay within `TC_CAP`. Every positive is `tc_check==1`, every negative control `tc_check==0`; un-quarantined into the always-run corpus (788/0, lib `db71fbf9`). | **Completed** — the multi-hour dependent-type-kernel proof tower is genuine and kernel-accepted, not green-washed. A single `tc_check(L6)` transitively verifies the entire tower. Extended further (2026-06-04d): the **strength-reduction schema** `mul(x, 2^k) == double^k(x)` is now kernel-proven for a SYMBOLIC k (corpus 1115, `sov_sr_strength_kat`) — the proof-carrying-optimization headline. Required raising the kernel arena `TC_CAP` 16384→131072 (sound capacity-only; outside `tc_to_ccl`, trusted-base seal unmoved). |


R2 (unify the signedness resolver) and R1 (the seam gate, `cg_seam_gate.sh`, landed) from §4 also belong to
the forward queue. None of these is a regression introduced this session; the established system is at its
known-good baseline (iiis-1 `46550704` / iiis-2 `0b9e4c13`, byte-exact to pre-session, corpus green on the
tracked suite, all gates green, kernel metal-proven).
