# III — Disposition Execution Package (adversarially verified, seal-safe)
> **SUPERSEDED-BY: III-PERFECTION-LEDGER.md** — this document is a HISTORICAL RECORD of its campaign era; the pointer target is the live doc (reunification W6, 2026-07-02).

**Provenance:** workflow `worshphmy` (`iii-arch-verify`), 2026-05-28 — 18 read-only `Explore`
agents (4 inventory · 13 adversarial verifiers · 1 synthesizer), prove-the-negative against the
live tree. This document **corrects** `DOCS/III-DISPOSITION-AUDIT.md`: the audit was an advisory
read and several of its headline recs describe a tree state that does not exist. Only claims that
**survived refutation** are scheduled here.

## Verdict ruler — the seal model (verified from the build scripts, not assumed)

- Active compiler = `COMPILED/iiis-2.exe` (+ `iiis-3.exe`). `build_iiis2.sh`/`build_iiis3.sh`
  compile `COMPILER/BOOT/*.c` (minus `PORTED_TUS`) + ported `.iii` via `iiis-0`, then **statically
  link** `STDLIB/build/iii/libiii_native.a`. A static `.a` link pulls only *referenced* members.
- **`GOLDEN_SAFE`** — file `iiis-2` never compiles (legacy C trees; non-`MODULES` files). Delete/move
  drifts *nothing*.
- **`LIBNATIVE_RESEAL`** — a `MODULES` (`libiii_native.a`) module that the *compiler does not
  reference*. Rename/move/de-register drifts only `libiii_native.a.mhash`; `iiis-2/3.exe` unchanged.
- **`COMPILER_RESEAL`** — a compiler-referenced module. Changing it may drift the golden compiler.
- **The gate (always let it decide):** `build_stdlib.sh` → `build_iiis2.sh` → `build_iiis3.sh` →
  compare `COMPILED/iiis-2.exe.mhash` & `iiis-3.exe.mhash` to committed golden. Match = neutral;
  drift = compiler-referenced = needs a witnessed reseal.
- **Governance:** every structural edit gets a `§S.N`-style entry here (pre-conditions, files,
  gate, proof transcript, rotating mhash) before it executes — mirrors `DOCS/CONVERGENCE-AUDIT.md`.

## Verdict table

| Claim | Verdict | Seal | Disposition |
|---|---|---|---|
| C1 FORCEFIELD/ dup | **REFUTE** | GOLDEN_SAFE | Phantom — directory does not exist. NO-OP. |
| C2 dead C trees | CONFIRM_SAFE | GOLDEN_SAFE | Delete `CYCLES/src`,`HEXAD/src`,`TRINITY/src`,`CRYPTO-AGILITY/src` (verify existence). |
| C3 10 dead C headers | CONFIRM_SAFE | GOLDEN_SAFE | Files do not exist — NO-OP. |
| C4 SANDBOX/OBSERVABILITY C + 2 tools | CONFIRM_SAFE | GOLDEN_SAFE | Delete (verify existence). |
| C5 4 dead `.iii` leaves | **MIXED** | LIBNATIVE_RESEAL | `svm_const`,`tp_dispatch_consts` already absent; `pattern_form`,`transform_form` are LIVE+corpus (NOT dead). |
| C6 archive ~215 C | CONFIRM_SAFE | GOLDEN_SAFE | Real, but **blocked** by CONSTANTS/GRAMMAR→`libiii_lex.a` re-point. |
| C7 aether L11 gap | CONFIRM_SAFE | LIBNATIVE_RESEAL | All 17 have corpus; `reversibility_audit` has prod callers. WIRE_IN, do NOT gate-out. |
| C8 Reach/fed gap | **REFUTE** (corpus) | LIBNATIVE_RESEAL | All 13 have corpus; sound clusters awaiting consumers. WIRE_IN. |
| C8b omnia R&D gap | **MIXED** | LIBNATIVE_RESEAL | ~5-6 true orphans (`hotstuff_predict/heal`,`dynamic_record/impact`,`reach_core/oracle`); rest tested. |
| C9 consolidations | **MIXED** | LIBNATIVE_RESEAL | `glyph_*`→2-3 ✓, `xii_curated_*`→1 ✓, hex-merge ✗ REFUTED. |
| C10 aggressive reorg | **NEEDS_PREP** | MIXED | No grounded proposal found; cycles load-bearing. REFUTE break/reorg. |
| C11 false positives | CONFIRM_SAFE | GOLDEN_SAFE | cpufeat/ripple/resolver_replay all genuinely distinct; `bv_kernel` does not exist. |
| C12 updates | CONFIRM_SAFE | MIXED | `mig1` DONE; `arena_safe`/`region_safe` quarantine-ready; mig3/4/6 implemented; mig2/7 design-only. |

## REFUTED — explicitly do NOT do

1. **Delete `FORCEFIELD/`** — does not exist; lowercase `forcefield/` is canonical/live (caller: `sov_isa.iii`→`rn_store_init`).
2. **Delete the 10 "dead headers"** — do not exist (no-op).
3. **De-register `pattern_form`/`transform_form` as dead** — live `MODULES`+corpus; not orphans.
4. **Break `typecheck↔ccl` or `temporal_logic↔constitution`** — intentional, load-bearing, link-resolved.
5. **Re-home substrate / split numera+omnia / merge katabasis** — no grounded proposal; seal-risky churn.
6. **GATE_OUT the orchestration-gap gospel** — *rejected on the no-shrink-the-gospel principle.* These
   modules are sound + corpus-tested; WIRE_IN as real consumers are built, never fake callers.
7. **Merge `tp_raw_hex`/`tp_iii_hex`/`tp_pe_hex`** — `tp_raw_hex` is the real impl; distinct contracts.

## CONFIRMED execution plan (ordered by safety; each gated + corpus-green)

**P1 — `GOLDEN_SAFE` dead-C deletion** (cannot drift any mhash). Delete only files confirmed to
exist + confirmed iiis-2-unreferenced: `CYCLES/src`, `HEXAD/src`, `TRINITY/src`, `CRYPTO-AGILITY/src`,
`SANDBOX`/`OBSERVABILITY` C, `gen_ast_offsets.c`, `gen_anchor_seed.c`. Gate must show golden MATCH.

**P2 — `LIBNATIVE_RESEAL` provable lean-up** (the real debloat): consolidate 16 `verba/glyph_*` →
2-3 parametric modules + 8 `omnia/xii_curated_*` → 1 registration module. Behavior-identical, fewer
modules. Gate: `libiii_native.a.mhash` drifts (witnessed); `iiis-2/3.exe` MATCH golden; corpus FAIL=0.

**P3 — Archive ~215 reference C** to `REFERENCE/`. **Prereq:** re-point CONSTANTS/GRAMMAR SHA-256 off
`libiii_lex.a` first; verify subsystem conformance gate green after. `GOLDEN_SAFE` for iiis-2.

**P4 — Self-governance gate** (the crown): **ALREADY EXISTS + VERIFIED (2026-05-29).** A mature
external tool `III-CARTOGRAPHER/cartographer.py` (stdlib-only python; out-of-tree *by design* →
zero seal impact) scans the live tree — Tarjan-SCC dependency cycles, duplicate `@export` symbols,
the full systems map + snapshot history — and its `--gate` is wired into `build_stdlib.sh` (soft
pre-compile gate at the MODULES boundary). Verified by **prove-the-negative**: clean tree → GATE
PASS (exit 0); a planted dup-`@export` `ident_eq` → GATE FAIL (exit 1, located `EXPORT-COLLISION`);
reverted → PASS. `gate_allow.json` allowlists the 2 intentional cycles (`ccl↔typecheck`,
`constitution↔temporal_logic`) + the benign Ring-0 `cpufeat_has_avx512f` override, each with a
documented rationale. *My in-tree bash reimplementation was redundant (no SCC) and was removed.*
Open consideration for the user: the gate is **out-of-tree + soft-skips if python is absent** — a
deliberate graceful-degradation, but it means a bare `git clone` of III alone lacks its own gate.
A future no-compromise option is to port it fully in-tree (bash/`.iii`, hard). Not pursued now
(would duplicate actively-maintained working tooling).

**P5 — WIRE_IN (not gate-out) the gospel**, per-module, only where a genuine consumer exists; verify
the few true orphans (`hotstuff_predict/heal`,`dynamic_record/impact`,`reach_core/oracle`) for a real
path or leave as sealed tested gospel. `quarantine arena_safe/region_safe` if confirmed shelved.

## Open decisions — resolutions (per user standards: no-compromise, full gospel scale)

- **pattern_form/transform_form corpus fate:** KEEP (they are live+tested; "dead leaf" was refuted). No action.
- **Orchestration-gap corpus:** PRESERVE all (no gate-out, no corpus deletion). WIRE_IN over time.
- **`reversibility_audit`:** verify `h9_charter` is live (it is a charter terminal); if live, WIRE_IN/keep.
- **`cic.c` C trust-root doctrine:** KEEP as sealed C trust-root reference (retiring it removes a
  verification anchor; `numera/typecheck.iii` complements, not replaces, the H13 kernel).

## Verified baseline (2026-05-28, post-cleanup, pre-improvement) — drift references

The current uncommitted tree builds GREEN and sits at a true bootstrap fixed point. Every edit
hereafter is measured against these:

| Artifact | mhash | Gate evidence |
|---|---|---|
| `iiis-2.exe` | `840a528e1bc4874d1e86ba414527a5c23b7adf52727ac202bfee710358f6b3b8` | iiis-0 vs iiis-2 byte-identity 59/0 |
| `iiis-3.exe` | `840a528e1bc4874d1e86ba414527a5c23b7adf52727ac202bfee710358f6b3b8` | iiis-2 vs iiis-3 59/0 — **iiis-2 ≡ iiis-3 fixed point** |
| `libiii_native.a` | `c45f1d3fb24dfd69adf16aad578e0e45c6eb6384dd691cab7467aba790daa2cd` | build_stdlib **419 PASS / 0 FAIL** |

Rule: a `GOLDEN_SAFE` edit leaves all three unchanged; a `LIBNATIVE_RESEAL` edit changes only
`libiii_native.a` (iiis-2/3 stay `840a528e…`); a change that moves iiis-2/3 off `840a528e…` is a
`COMPILER_RESEAL` and must be witnessed + intended.

## RESOLVED — full corpus GREEN at a new verified fixed point (2026-05-29)

The full *behavioral* corpus (not just compilation) exposed **6 pre-existing failures**; both root
causes fixed + verified end-to-end:

- **Cause A — u64-division codegen** (`890_sat_arith`, `893_u64_div`). `cg_r3.iii` emitted signed
  `cqto;idivq` for ALL division → unsigned u64 `÷`/`%` of a high-bit value was read as negative. FIX:
  branch DIV/MOD on the already-computed `signed` (`r3_either_is_signed`) — unsigned →
  `xorl %edx,%edx; divq` (new `R3_STR_DIVU`/`R3_STR_DIVUMOD`); signed path unchanged. `COMPILER_RESEAL`.
- **Cause B — bench link** (`237/242/243/244`). (1) `forcefield/{pleroma,ripple_dyn}` both defined
  non-`@export` `fn malloc`/`fn free` → global `L_malloc`/`L_free` collision under `--whole-archive`
  → renamed `pl_*`/`dn_*`. (2) `run_bench_corpus.sh` used a **blanket** `--whole-archive` (the lone
  runner the CONVERGENCE selective-fix missed) → force-linked the gospel-scale ~1GB BSS →
  `IMAGE_REL_AMD64_REL32` overflow → switched to the selective side-effect-set pattern.

**New golden (fully converged; `build_iiis2 --check` + `build_iiis3 --check` both 59/0):**

| Artifact | mhash (was) | mhash (now) |
|---|---|---|
| `iiis-1 ≡ iiis-2 ≡ iiis-3` | `4e138415…fa85` | `196b0c5f5159329b2e419aecb561ee57980d62bcc892ea84f260559bcdfaa990` |
| `libiii_native.a` | `9776af67…b684124` | `13fa921e7da475a42ae06a64eaca5a181e26a4033ade7c41d60834e6273f2092` |

Corpus: STDLIB **652/0**, bench **7/0**, stage-1 **59/0** → **ALL CORPORA PASSED**.

**This reseal (2026-05-31, the Evolution baseline).** The `.iii`-only compiler-source enhancements moved
the codegen fixed point: `cg_r3` `r3_reserve_slot` (bounds the unchecked `R3_G_LOCAL_COUNT` bumps that
could overrun the 64-slot frame — clean compile-fail at the cap instead of memory corruption), `cg_rm2`
`RM2_CHBUF` (a dedicated 1-byte scratch so `cg_emit_ch` can never alias `RM2_NUMBUF[0]`), the `sid`
rewrite, and the PE emitter. Convergence was the **textbook two-step heal** of a codegen bug-fix:
`4e138415` (old) → `7aded1aa` (transitional — the *old* compiler emits the *new* source, still carrying
the old `CHBUF` aliasing emission) → `196b0c5f` (stable — the new compiler re-emits itself; verified
`iiis-2 == iiis-3 == iiis-4`). The **joint compiler/lib fixed point** holds: the final compiler rebuilds
`libiii_native.a` byte-identically to `13fa921e`. Golden re-pinned in the three Ripple executors
(`ripple_apply` / `pcc_synthesize` / `ripple_extract`). **Environmental note:** relinking the live
`COMPILED/iiis-2.exe` in-place intermittently fails under OneDrive/Defender file-lock (`ld returned 1`,
no undefined refs) — `rm` the output first so `ld` writes a fresh inode; this is the root cause of the
sporadic single-test corpus link flakes (they re-run green).

**Bootstrap finding (pre-existing, non-blocking):** `build_iiis1` (from-iiis-0 bootstrap) is broken —
iiis-0 can no longer compile post-port `parse.iii` (`iii_lex_*_c` undefined). The reseal correctly
uses the frozen iiis-1 seed; from-absolute-scratch bootstrap has drifted past iiis-0 (future
seed-refresh candidate).

**Seal-ledger TODO (do at commit):** record golden `4e138415…` + lib `258b3579…` in
`DOCS/MHASH-LEDGER.md` and a `CONVERGENCE-AUDIT.md §S.N` entry.
