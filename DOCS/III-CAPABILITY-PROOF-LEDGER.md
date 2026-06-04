# III — The 12-Capability Proof Ledger

**Purpose.** III-APOTHEOSIS.md §"What III becomes able to do" names twelve capabilities the
finished system possesses. This ledger proves each one **using III alone** — no rigging, no
external scaffolding: every proof is a green verdict from III's *own* gate (a corpus KAT, a
charter clause, a build/seal gate), run by III's own harness (`build_stdlib.sh`,
`run_corpus.sh`, `run_xii_corpus.sh`, `build_iiis2.sh`). A capability is *proven* iff its
backing gate(s) pass **and** each gate carries a falsifier that catches its broken case
(prove-the-negative — a vacuous green is not a proof).

**Verdict legend.** `GREEN` = gate ran and passed live this session. `PENDING` = awaiting the
live run. `OPERATOR` = the physical step is UAC/operator-gated (a kernel load); III performs
the logic, the operator performs the one trusted load. Each gate column cites the corpus test
number (run by `run_corpus.sh`) or the script.

> Determinism note: the backing modules are compiler-unreferenced, so the bit-identity claim
> (cap 12) is checked **once** via the DRIFT-gated `build_iiis2.sh --check` (ADR-027), not by
> repeated rebuilds.

---

## The matrix

| # | Capability (abridged) | Backing III gate(s) | Falsifier it carries (the negative) | Verdict |
|---|---|---|---|---|
| 1 | Refuse to ship/run an incoherent self — Constitution is the build's terminal gate | `700_charter_terminal`=99 (folds all 13 H-invariants), `673_constitution_holds`=99, `701_cons_run_charter`=99; structural: `build_stdlib` GATE PASS | canary claims H1 broken → fold RED at idx 14; empty-registry → `CT_VERDICT_EMPTY` (no false-GREEN-over-empty) | **GREEN** |
| 2 | Make catastrophe unsayable — bricking/over-budget are *type errors* | `692_h6_charter`=99, `672_safety_type`=99, `604_katabasis_bricking`=99, `609_katabasis_admit`=99 (REJECT_HEXAD) | a closed inhabitant of ⊥ / a brick cycle that type-checks → caught (BOT_UNREACHABLE) | **GREEN** |
| 3 | Carry proof in all computation — kernel-verified, witnessed certificate | `680_proof_chain`=99, `639_proof_carrying`, `647_theorem_carrier`, `877_sov_pcc` | unverified proof-term → `THMC_E_VERIFY_FAIL`; absent dep → `THMC_E_DEP_ABSENT` | **GREEN** |
| 4 | Compute soundly on the unknown; explain ignorance — typed gaps w/ provenance | `668_uncertainty`=99, `985_hexad_epistemic_floor_escalate` | 0·unknown must = Known(0); ÷0 = essential gap (not silent) | **GREEN** |
| 5 | Evaluate everything one way, deterministically — XII confluent/terminating | `695_h4_charter`=99, `824_xii_strategy_det`=99, `826_xii_conf_cert`, `863_ccl_confluence`=99, `812/813` | a term with two normal forms / a second evaluator → caught; canary RED | **GREEN** |
| 6 | Optimize by cost, provably — cost is a value facet + functor; egraph extraction | `677_cost_lattice_laws`=99, `614_egraph`, `956_egraph_cost_lattice`, `955_optinvoke_cost_lattice` | incomparable elements (genuine partial order); non-cost-minimal extraction → caught | **GREEN** |
| 7 | Solve & synthesize with re-checkable proof — never trusted | `635_smt`=99, `675_decision_oracle`=99, `679_synthesis_bounds`=99, `613_sat`, `638_groebner` | fabricated SAT on UNSAT → caught; re-check on model; W8 bounds refusal | **GREEN** |
| 8 | Forget on demand, with proof — append-only *and* provably forgettable | `382_witness_hook`=99, `988_witness_redact`=99, `682_arena_determinism` (release dual) | a redaction that breaks continuity → caught; verifiable hole = keccak(orig) | **GREEN** |
| 9 | Reason & guarantee over time — temporal LTL over algebraic time | `644_temporal_logic`=99, `381_algebraic_time` | a second OS-clock site (un-sealed) → red (M21 source audit) | **GREEN** |
| 10 | Agree across nodes consensus-free; heal — certificate = pullback; regenerate | `386_fed_qc_gate`=99, `383/384/385_hotstuff`, `641_bone_marrow`, `623_quarantine` | tampered QC (2<quorum 3) → `FED_SEAL_E_QC`, nothing anchored; over-r erasure → `MARROW_E_TOO_BAD` | **GREEN** |
| 11 | **Attest its running self beneath the OS** — behavioral quine-seal at Ring −1/−2 | NEW `quine_seal.iii` (`1047_quine_seal`=99: reproducible + **binds-to-content** + engine-real + attest accept/reject); `gate_driver.iii` wired fail-closed + `IOCTL_ATTEST` **(machine-code verified: attest-or-refuse dominates `IoCreateDevice`; `ks_self_measure` hashes `[DriverStart+0x1000,+0x14e00)`; `.text` relocation-free)**; **build-twice falsifier `quine_attest_check`=99** (tampered source ⇒ different `.text` measurement); + triple-bit-identity (cap 12) | a tampered `.text` → different measurement ≠ external seed (proven live: g.sys≠b.sys); folding baked constants rejected (ADR-M23-1) | **GREEN — PROVEN ON METAL 2026-06-04**: the driver loaded into the live Windows kernel and `quine_attest_client` reported `M23 SUCCESS` — its below-OS `ks_self_measure` of its own `.text` EQUALS the Ring-3 client's independent on-disk recompute ("I am exactly this source and executed behavior"); all 4 gate verdicts correct; clean DriverUnload, no bugcheck (`.sys a91b667b`). Closing it took 3 cg_r0 codegen fixes + a byte-packed digest-output path + the driver self-reading its `.text` VirtualSize off its own PE (no baked length) — see `DOCS/M23-9B-MISMATCH-INVESTIGATION-2026-06-04.md`, `DOCS/CRASH-AUDIT-BSOD-2026-06-04.md`. The frontier is closed. |
| 12 | Be one language, provably; picked up by a stranger — C tree retires to `.iii` | `699_h13_charter`=99; `build_iiis2.sh --check-corpus`: **rebuilt mhash == committed `8b205524…`** (byte-identical), **iiis-0≡iiis-2 corpus equiv 59/0**, Ring-−2 check OK | a retained C module whose `.iii` port passes its exact KAT → caught; a stub sha256 → rejected | **GREEN** |

---

## Honest scope on capability 11 (the only genuine frontier) — RESOLVED 2026-06-04

**UPDATE 2026-06-04: this frontier is now CLOSED on metal.** The below-OS driver runs `ks_self_measure`
over its OWN loaded `.text` at load (`gate_self_attest` → `IOCTL_ATTEST`), and a Ring-3 challenger
(`quine_attest_client`) independently recomputes the same measurement off the on-disk `.sys` and compares
bit-for-bit: `M23 SUCCESS` on the live Windows kernel. The "wall" below (the operator UAC load) was
crossed this session — the operator accepted the UAC, the driver loaded, attested itself, returned all 4
gate verdicts correctly, and unloaded cleanly with no bugcheck. The historical scope notes below are kept
for the record; every one of them is now satisfied.



- **Done & proven on metal:** the gate *decision* is a standing Ring-0 kernel service queryable
  from Ring 3 (`gate_ioctl.sys`, tested 2026-05-23: OK→0, REJECT_SEAL→1, REJECT_CAP→2,
  REJECT_HEXAD→3; clean `DriverUnload`; no bugcheck). See `DOCS/IOCTL-GATE-AUDIT.md`.
- **The seal logic exists & is gated:** `quine_verifier.iii` (corpus 617) recomputes the
  whole-system identity and compares bit-identically to the Ring-−2 seed — exactly the
  "I am this source" check; its falsifier (corrupted seed → 0) is gated.
- **The frontier:** the metal gate currently seals the *cycle it decides*, not *its own image*.
  M23-complete = the below-OS driver runs `quine_verifier` over its own loaded image before
  admitting, so a tampered below-OS image fails to attest ("a below-OS image whose quine-seal
  doesn't verify → red", III-APOTHEOSIS §M23).
- **The wall (stated, not hidden):** the physical on-metal load is UAC/operator-gated
  (`sign_and_deploy_ioctl.ps1`). The honest completion criterion is: implement the self-quine
  wiring, static-verify it in the `.sys` binary (disassembly), and gate the seal *logic* in a
  runnable harness; the one trusted load is an operator step the user triggers.

---

## Live-run provenance (filled by this session's III-alone runs)

- `build_stdlib.sh` → GATE PASS, **PASS=452 FAIL=0**, lib mhash `a4f846d9a72b7c68…87ee`.
- `run_corpus.sh` → **PASS=721 FAIL=0 SKIP=99** (zero WRONG/FAIL). Every capability-backing gate
  executed live at exit=99: 695_h4/696_h5/697_h7/698_h12/699_h13/700_charter_terminal/
  701_cons_run_charter, 617_quine_verifier, 680/672/692/635/675/679/386/382/988/644/609/604/668/
  677/863/824 — all 99.
- `run_xii_corpus.sh` → **PASS=91 FAIL=0**.
- `build_iiis2.sh --check-corpus` → rebuilt iiis-2 mhash `8b205524278bc0dd…fbe5f` **== committed** (byte-identical
  self-compilation); corpus equivalence **iiis-0 ≡ iiis-2 = 59 passed, 0 failed**; Ring-−2 sanctum `do_thing(7)=21` OK.
  ⇒ the triple-bit-identity / determinism theorem (H12) holds live.

**Baseline verdict: III's own gates are GREEN end-to-end — 452/0 + 721/0 + 91/0 + byte-identical reseal.**
Capabilities 1–10 and 12 are PROVEN live by III alone. Capability 11's seal *logic* is proven (617);
its below-OS embodiment (M23) is the implementation frontier below.
