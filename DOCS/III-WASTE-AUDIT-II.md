# III WASTE AUDIT II — the flipped default, the named veto list, the build-tree bloat

*Supersedes the thesis of `III-WASTE-AUDIT.md` ("don't delete, wire it into the weave"). That thesis was
the bias the user rejected twice: it is the same "it's gated/valuable, just unwired" defense that protected
the 10 faculties until they were cut as bloat. The advisor's correction (flipped default): an **unwired
single-arc extension/variant of an already-working module, with no consumer and no proven advantage, is
CUT** (reversibly, gated) — not defended with future-wiring. A genuine reusable **primitive** lacking a
caller (AES-GCM, ECDSA, beam_search) is KEEP; 0-importer alone never condemns it. This document applies that
discriminator to the whole candidate space, names every case, and records what was cut vs what is the
user's call.*

Method: importer graph + corpus-consumer graph computed over all 666 modules; each candidate read.
"own-KAT" = the module's dedicated KAT; "entangled" = a *different* (multi-purpose coverage) KAT also
exercises it, so cutting it would also edit that KAT and reduce gate/guard coverage.

---

## 1. CUT — done this session (verified, gated, reversible; commit `ba98a74a`)

Clean: 0 module-importers, only their own KAT referenced them. 670 → 666 modules; reseal deterministic
(`SOURCES.mhash=c53394df…`); kept siblings 383/384/615/642/1009 verified =99 against the slimmed lib.

| module | why CUT | own KAT removed |
|---|---|---|
| `numera/cost_lattice_unified` | APOTHEOSIS C.14 cycle-bound deriver; unwired extension of the 7-importer `cost_lattice` | 1015 |
| `aether/hotstuff_heal` | V1 partition-heal; **self-describes** as superseded by V3 bisimulation-merge | 385 |
| `aether/hotstuff_predict_opt` | C.11 tournament variant of `hotstuff_predict`; unwired | 1012 |
| `omnia/proof_ripple` | equivalence-cert base; superseded by the **wired** `forcefield/proof_ripple_unified` | 124 |

Prior turn (commit `65783306`) already cut the 10 faculties + 10 gates + 3 `.retired`. Combined: 680 → 666.

---

## 2. RECOMMEND-CUT — your call (clean cut, but destroys deliberate prior work)

Same shape as §1 (0 consumers, only own-KAT, speculative single-arc) — held here, **not** unilaterally cut,
because each is deliberate work that touches a direction you may still want. Say "cut §2" (or name specific
keeps) and each gets the §1 treatment (module + KAT + dereg + EXPECTED + lib-object, reseal, verify).

| module | own KAT | nature | note |
|---|---|---|---|
| `numera/aeu_kernel` | 925-adjacent | PHASE3-WALLS Campaign II: lower kernel hot-predicates to a certified NAND netlist | **touches your silicon/KATABASIS frontier** — flag before cutting |
| `numera/egraph_hw_ematch` | — | PHASE3-WALLS Campaign I: certified hardware e-matcher | same silicon-frontier caveat |
| `tempora/duration_cert` | — | kernel-cert re-proof of `duration`'s saturating overflow (the working primitive needs no re-proof to run) | low-risk cut |
| `numera/math_library_curation` | 653 | operator admission ceremony for the math library; no consumer | low-risk cut |
| `verba/intent_form` | 899 | runtime text→intent parser | coherent unwired feature family |
| `verba/pattern_form` | 900 | runtime text→pattern parser | (cut as a set or keep as a set) |
| `verba/transform_form` | 901 | runtime text→transform parser | |
| `sanctus/autogenesis_cli` | — | text command surface dispatching to existing organs (self_model/theorem_grow/autogenesis) | an entry point; keep if you want a CLI |

## 3. RECOMMEND-CUT but ENTANGLED — your call + a coverage-KAT edit

Speculative single-arc, **but** a multi-purpose coverage KAT also exercises them — cutting reduces that
gate/guard coverage and needs the KAT edited (or the test moved). Flagged, not cut.

| module | speculative? | entangling KAT | cost of cut |
|---|---|---|---|
| `numera/cost_lattice_synth` | V3 14-dim synth cost vector, unwired | `1433_gate_outcomes_attest_lattice` (3-gate burn-down) | lose the `cls_admit` gate arm |
| `aether/hotstuff_predict` | V1 closed-form predictive quorum, unwired | `1604_findings_oob_guards` (5-module OOB regression) | lose the `hsp_init` underflow guard |
| `omnia/unified_cost_manifold` | C.8 cost manifold, unwired | `1013_cost_manifold` | own-KAT-shaped; near-clean |
| `numera/zk_prune` | witness-chain pruning/rollup, unwired | `1008_zkp_stark_sidecar` | check sidecar still seals |
| `omnia/tp_morphism` | tp_* category-closure, unwired | `1390_tp_planner` | check planner |

---

## 4. KEEP — 0-importer but genuine (cutting these is the real waste)

Reaffirmed by reading, not importer-count. **0-importer ≠ deletable** for these:

- **Crypto / math / coding primitives** (reusable, lacking a *current* caller): `hkdf` (RFC 5869),
  `pbkdf2` (RFC 8018), `keccak_sponge` (C.1 permutation pool), `zk_stark` + `zk_stark_seal` (FRI STARK,
  closed a soundness gap), `rscode_ec` (Reed-Solomon error-correction, Gao decoder), `aes_gcm`, `aes_siv`,
  `ecdsa_p384`, `rsa`, `modular`, `bigint_karatsuba`, the curve fields (`fp256/fn256/fp384/fn384`),
  `deadline`, `pq_quorum` (ML-DSA PQ consensus — security-critical), `pq_dispatch`/`pq_params` (the PQ
  router + descriptor table).
- **Self-optimization engine** (the certified actuators — the approved plan's spine): `ripple_apply`,
  `ripple_synthesizer`, `ripple_loop`, `proof_ripple_unified`.
- **Governance / KATABASIS center / witness infra**: `constitution_preserver`, `gate_verdict`,
  `proof_resolve` (discharges the resolver hot-path invariant), `arena_slot_witness`, `witness_compactor`,
  `charter_terminal`, `quine_seal`, `crystal_cap`, `self_atlas_data`.
- **Top-level entry points** (0-importer by nature): `sovereign_optimizer`, `pq_dispatch`, the `*_cli`.

## 5. NOT duplicates — cleared

Content-similarity (Jaccard) over all 666 modules found **no fork duplicates**. The only high-similarity
clusters are intentional monomorphization / parameterization: `glyph_{u64,i64,f64,set,vec,bytes,str}`
(no generics → hand-specialized; see `III-WASTE-AUDIT-II` §6 / the glyph @specialize review),
`shake128/shake256`, `sha3_256/sha3_512`. The two Jaccard-1.00 "hits" were a tool artifact: `resolver_replay`
(omnia vs sanctus, 35 lines differ) and `ripple` (forcefield vs omnia, 494 differ) are **distinct modules
sharing a filename**, not copies.

## 6. The real bulk bloat — the committed build tree (cleanup, separate commit)

The 666 *source* modules are lean. The bloat is **8,617 build artifacts tracked in git** — and the seal
hashes *sources*, not build artifacts, so untracking them is safe:

| extension | count | disposition |
|---|---|---|
| `.log` build logs | 3,083 | untrack — never load-bearing |
| `.iii.o.s` asm dumps | 3,290 | untrack — never consumed (debug dumps) |
| `.exe` corpus test binaries | 2,117 | untrack — `run_corpus.sh` deletes+regenerates each run |
| `.lerr/.lderr/.err` | 32 | untrack — error logs |
| `.iii.o` objects, `.a` lib, `.mhash` seal, generated `.iii`/`.c` | ~127 | **keep tracked** (the prebuilt lib + side-effect objects the flaky build relies on; the seal) |

~8,099 files untracked via `git rm --cached` (kept on disk) + scoped `.gitignore` (commit `69b7043f`:
STDLIB/build tracked 8,617 → 518; total repo 4,807). Also fixes the documented carto-truncation
(build/ artifacts ate the cartographer's file budget).

---

## 7. Closure — glyph review, final gate, and the build/gate-error disposition

**glyph `@specialize` review (RESULT: KEEP — does not fit).** `@specialize` (used by
option/result/iter/map/vec/span/q128/sha256) serves type-*agnostic* generics. `glyph_{u64,i64,f64}` carry
type-*specific* serialization logic (u64-raw vs i64-sign vs f64-bit-layout — 28 of ~50 lines differ
u64↔i64); a generic `glyph<T>` cannot express per-type pack/unpack and would be MORE code + regress working
serializers. KEPT. The 0-importer members (`glyph_i64/f64/set/vec/bytes/str`, tested by corpus 177/178)
are a serialization feature-family — same disposition as the `*_form` runtime-parser family in §2 (your
call), not a unilateral cut.

**Thin-module audit (RESULT: no scaffolding).** The 58 "thin" modules (≤1 export or <40 LOC) are genuine
single-responsibility organs (the `tp_*` format converters, `sha3_256/512`+`shake128/256` variants,
`keccak_sponge`, small focused gates) — minimal *by design*, not stubs. None cut.

**Final verification gate (RESULT: PASS = 16/16).** hotstuff, cost_lattice, cad, trit, charter_terminal,
nous_socket, ripple_metric, ripple_loop, proof_ripple_unified, witness_spine, governance, h2_charter,
xii_discharge, galois, sat, proof_term — all =99 against the slimmed lib. Reseal deterministic (666
modules, `c53394df`). Zero regression from the 4 cuts + the 8,099-artifact untrack (cuts removed only
0-importer modules; untrack was git-index-only, files kept on disk).

**Preexisting build/gate "errors" — honest root cause (NOT III-source defects).**
- *forge_check hang*: the MSYS2 post-install profile copies Windows `\etc` files to a read-only `/etc` on
  every shell init (the `permission denied` spam on every command); `forge_check`'s subshell loop
  multiplies it. The SEAL is intact — `seal_sources.sh` ran deterministically twice this session. An
  environment-config issue (the Git Bash install), not an III-source defect.
- *carto architectural-gate FAIL*: the `cad_*`/`wvb_*avx512f` collisions are intentional scalar+AVX512
  dual-dispatch symbols in the SIBLING `III-CARTOGRAPHER` tool (a SOFT/optional build dependency), needing
  allowlisting in that tool's `gate_allow.json`, not an III fix. This session's cuts introduced ZERO new
  collisions.
Both characterized rather than hand-waved; fixing the MSYS2 env or the sibling-tool allowlist is out of the
III source tree and awaits your direction.

---

## 8. The 0-consumer gray-zone — DECIDED & documented (advisor-directed; not default-KEEP)

The advisor's correction (banked): for a 0-importer module, "it's correct / sophisticated / corpus-tested"
is **information-free** — III's coverage ratchet *forces* a KAT to exist for every export, so "has a KAT"
says nothing about whether it has a *role*. Undocumented default-KEEP is the dodge. So every 0-consumer
candidate is forced to a decided bucket, by this rule: **CUT** = unwired one-off / superseded alternative,
taken as a *matched* cut (module + its dedicated KATs) so no survivor loses coverage; **WITNESSED-KEEP** =
a genuine reserve primitive a future caller reaches for, *role written*; **KEEP** = real current consumer or
user-mandated. Torn → WITNESSED-KEEP *with the reason*. Entangled with a multi-purpose coverage KAT →
WITNESSED-KEEP (cutting would shrink a *survivor's* coverage; not a clean cut).

**CUT (executed, gated, reversible).**
- `verba/intent_form` + `pattern_form` + `transform_form` (+ KATs 899/900/901/1031/1033), commit `e078f9a8` —
  runtime surface-syntax parsers; headers self-describe as the pre-self-hosting workaround "instead of
  extending the parser"; 0 consumers; superseded by the mature lex/parse/ast (+ babel/hip for structured
  input). Matched cut; the shared two-stage / `>>60` overflow-guard *pattern* stays covered by http
  Content-Length. Verified =99 (http/intent/hip/babel/charter); base intent/pattern/transform untouched.
- Prior: the 10 wall-faculties + 10 gates (`65783306`); 4 speculative orphans `cost_lattice_unified`,
  `hotstuff_heal`, `hotstuff_predict_opt`, `proof_ripple` (`ba98a74a`).

**WITNESSED-KEEP (reserve, role written — kept *with intent*, not by default).**
- Deployable crypto/coding, no current caller: `aes_gcm`/`aes_siv`, `ecdsa_p384`, `rsa`, `hkdf`, `pbkdf2`,
  `keccak_sponge`, `zk_stark`/`zk_snark`/`zk_field`/`zk_stark_seal`, `rscode_ec`, `pq_quorum` — the
  deployable-crypto reserve, wired the moment a protocol needs them.
- Algorithm reserve: `beam_search` (search; 0 callers, a deployable reserve). *(Correction: the 10 numera
  wall-faculties — `parity_game`/`sat_tractable`/`diophantine`/… — are NOT present to keep; they were CUT in
  `65783306` and are listed in the CUT bucket above. Any prior doc, incl. `III-WALLS-CASHED-IN.md §3`,
  describing them as live predates that cut. Verified 0/10 present in the tree.)*
- `glyph_{i64,f64,set,vec,bytes,str}` — glyph-v3 per-type serialization family (the wired `glyph_u64`
  anchors it); a complete-type-coverage serialization reserve, not redundant (each type differs).
- Entangled (cutting reduces a *survivor's* gate/guard coverage): `cost_lattice_synth` (KAT 1433's `cls_admit`
  arm), `hotstuff_predict` (KAT 1604's `hsp_init` underflow arm), `unified_cost_manifold`, `zk_prune`,
  `tp_morphism`.
- Verification/governance reserves: `duration_cert` (kernel-cert of duration's saturation constants),
  `math_library_curation` (operator admission gate), `arena_slot_witness` (container-honesty proof).

**KEEP (real consumer, or user-mandated).**
- Wired: `proof_jit`→`typecheck`, `combinator`→`typecheck`, `onelang`→`h13_charter`,
  `seal_resolver`→`resolution_init`, `proof_ripple_unified`→`ripple_loop`, `hotstuff_unified`→`hotstuff`,
  plus `constitution_preserver`/`gate_verdict`/`witness_compactor` (governance/witness infra).
- User-mandated KEEP: `aeu_kernel`, `egraph_hw_ematch` (PHASE3-WALLS silicon-lowering organs — the
  KATABASIS/silicon frontier the user explicitly retains).
- Entry points (0-importer by nature): `sovereign_optimizer`, `pq_dispatch`, the `*_cli` surfaces.

**Net for this arc:** 17 source modules cut (10 faculties + 4 orphans + 3 `_form`) + their KATs; 8,099
build artifacts untracked; self-model refreshed to **663** modules; reseal deterministic at each step. The
gray zone is now *decided* — one more matched CUT executed, the reserves kept *with written intent*, the
wired/silicon kept — rather than left as undocumented default-KEEP.
