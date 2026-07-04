# Subsystem Test Gate Specification

> **Current state (2026-07-04).** The R1 C subsystem provinces this spec inventories
> (TYPES/HEXAD/LEXICON/…) were amputated in the C→.iii port era — their directories no
> longer exist, so clause (c) is satisfied by honest emptiness (the gate prints the
> amputation instead of a vacuous 0/0, and still executes any exe that reappears). The
> `.iii` corpora are the successors. The driver moved to `STDLIB/scripts/run_all_corpora.sh`;
> the gate's stale root path was fixed the same day (its exit-127 had been mislabeled
> "127 failed tests" — the gate had never actually judged the corpora before then).
> The inventory below is retained as the historical V1 record.

Authority for the V1→V2 transition gate: no V2 phase begins until every V1
subsystem passes its threshold. Grounded in the **real** subsystem test exes
(`<SUBSYS>/build/iii_<name>_test.exe`) and the existing driver
`run_all_corpora.sh`. The gate ritual is implemented as the wrapper script
`STDLIB/scripts/subsystem_test_gate.sh` (forward-reference #28), written alongside
this spec.

## Gate discipline

The gate exits zero iff (a) the deterministic stdlib build reports `BIT-IDENTICAL`,
(b) the `.iii` corpus reports `FAIL = 0`, and (c) every subsystem test exe in the
inventory exits zero (or its README threshold is met). It exits non-zero with a
diagnostic naming the first failing subsystem otherwise.

## Subsystem inventory + thresholds

| Subsystem | Location | Corpus | Threshold |
|-----------|----------|--------|-----------|
| Compiler | `COMPILER/BOOT/` | stage1 corpus + determinism | `BIT-IDENTICAL`, every test passes |
| STDLIB | `STDLIB/iii/` | `STDLIB/scripts/run_corpus.sh` | `FAIL = 0`; `SEAL.mhash` stable across rebuilds |
| TYPES kernel | `TYPES/src/cic.c` | `TYPES/build/iii_types_test.exe` | every test passes |
| HEXAD | `HEXAD/src/hexad_algebra.c` (canonical, see HEXAD_COMPOSE_AUTHORITY.md) | `HEXAD/build/iii_hexad_test.exe` | every test incl. pillar-position |
| SOVEREIGN-WEB | `SOVEREIGN-WEB/src/sovereign_web.c` | `SOVEREIGN-WEB/build/iii_*_test.exe` | every test; +4-node HotStuff when fwd-ref #12 impl lands |
| Witness chain | `STDLIB/iii/sanctus/witness.iii` | witness corpus | every test; +recompute test when fwd-ref #26 lands |
| Federation | `STDLIB/iii/aether/fed_*.iii`, `federated_sheaf.iii` | `FEDERATION/build/iii_federation_test.exe` | every test; +HotStuff per #12 |
| Crypto | `STDLIB/iii/numera/` (see CRYPTO_PRIMITIVE_INVENTORY.md) | per-primitive KAT corpus (198–209) | every KAT byte-equal; **RSA modexp (#1/#2) is gating WIP — excluded until discharged** |
| R1 subsystems | `<DIR>/build/iii_*_test.exe` (ABI, CATALYST, CONFORMANCE, CONSTANTS, CRYPTO-AGILITY, CYCLES, EFFECTS, ERRORS, GENESIS-VECTOR, GHOST-CODE, GRAMMAR, INTEGRATION, LEGACY-INGESTION, LEXICON, MODULES, PHASES, SANCTUM, TRINITY, …) | each exe | exit 0 |

The pass *count* per subsystem is the count at the gate's first run (recorded in
`CONVERGENCE-AUDIT.md`), not a hardcoded target — the gate asserts "≥ recorded
threshold," so regressions fail it while progress does not.

## Gate ritual

`bash STDLIB/scripts/subsystem_test_gate.sh`:
1. runs the deterministic stdlib build; refuses to proceed unless it confirms determinism;
2. runs `STDLIB/scripts/run_corpus.sh` and parses `FAIL =`;
3. runs each subsystem test exe (via `run_all_corpora.sh` where it already drives them) and collects exit codes;
4. exits 0 iff all green; else non-zero naming the failing subsystem.

## Order rationale

Committed at Stage 9 because no V2 phase begins without it: the gate is what makes
the V1→V2 transition meaningful — every V2 phase then begins from a known,
measured threshold rather than substrate state of unknown quality.
