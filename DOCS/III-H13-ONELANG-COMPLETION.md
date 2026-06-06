# III · H13 "One Language" — Thorough Completion Ledger

**Mandate (operator, 2026-06-06):** complete H13 thoroughly — no deferrals, no
placeholders, no compromises, no skips, NIH. *Ascertain everything III is/should be
capable of, then — without rigging or extra scripts — use III alone to do it.*

**H13 (the invariant):** *"one language, provably; picked up by a stranger — the C tree
retires to `.iii`."* No C survives save the bootstrap trust root (+ the now-closed `cic.c`
carve-out). Today H13's **runtime** facet is in `.iii` (`numera/h13_charter.iii` — the one
`.iii` sha256 is FIPS-faithful, so the 14× C `sha256.c` were retirable), but its
**structural** facet lives in **bash** (`scripts/verify_sha256_dedup.sh`) and the
fact-extraction in **C** (`III-CARTOGRAPHER/carto.c`). That bash/C dependency *is* the
"rigging" the mandate forbids. **The honest, profound completion: III audits its own
one-language property, in `.iii`, by `III` — which first requires the missing organ
(directory enumeration) so III can see its own source tree.**

---

## §0 · The completion in four pillars

1. **The missing organ** — `aether/fs.iii` Phase-D: directory enumeration
   (`FindFirstFileA`/`FindNextFileA`/`FindClose`, kernel32, NIH, capability-gated) +
   `fs_mkdir`/`fs_rmdir`. Without it III literally cannot see its own tree.
2. **The self-audit, in III** — `sanctus/onelang.iii`: walk the tree, classify every
   `.c`/`.h` against a sealed bootstrap+harness allowlist, seal a `cad` verdict. Supersedes
   `verify_sha256_dedup.sh` and **generalizes** it (not just `sha256.c` — *all* non-bootstrap C).
3. **Constitutionalize** — wire the structural one-language clause into `h13_charter.iii`'s
   `run_charter`, so H13's *structural* half is checkable in `.iii`, not bash.
4. **Reach PURE** — proof-gated retirement (M24 falsifier discipline) of the dead C
   reference tree, so the only C that survives is the bootstrap trust root + harness.

End-state vocabulary: **ACCOUNTED** = every C file proven-classified (no UNPORTED-GAP).
**PURE** = only bootstrap + harness C remains (the thorough end-state, reached by retirement).

---

## §1 · The C census (91 `.c`, 43 `.h`, excl. `STDLIB/build/`, `.git/`, `.claude/`)

Verified facts: (a) `build_iiis0.sh` compiles **only** `COMPILER/BOOT/*.c`
(`find . -maxdepth 1`); the entire iiis chain + `build_stdlib.sh` never compile LEXICON/
GRAMMAR/CONSTANTS/FOUNDERS-ANCHOR. (b) No external build/test script references those dirs
(only `verify_sha256_dedup.sh`, in a comment). (c) **No `TYPES/` directory** — the `cic.c`
carve-out is **CLOSED**; `numera/ccl.iii` + `numera/typecheck.iii` are the `.iii` CIC kernel.

| Bucket | Files | Disposition |
| --- | --- | --- |
| **A · keep-bootstrap** (the irreducible trust root) | `COMPILER/BOOT/*.c` (29) + `COMPILER/BOOT/*.h` (21) + `COMPILER/SANCTUM_WRAP/iiis_sanctum_compile.c` | KEEP — every self-hosting language has one C seed; this is it. Per apotheosis M24 "keep the trust roots: COMPILER/BOOT." |
| **B · harness / tooling / deploy** (not part of the III artifact) | all `*/tests/test_*.c` (LEXICON 11, GRAMMAR 11, CONSTANTS 1, FOUNDERS-ANCHOR 1, INTEGRATION 1, STDLIB 1); all `*/tools/iii_*_tool.c` (3); `KATABASIS-DEPLOY/src/{floor,gate}_client.c` (metal-test IOCTL clients); `_audit_scratch/rm2_driver.c` (scratch) | OUT OF SCOPE — doctrinally like `III-CARTOGRAPHER` and `verify_reach_remote` ("test harness only, not part of the III artifact"). |
| **C · dead-reference, proven superseder** (RETIRE) | `LEXICON/src/*.c` (12) → `COMPILER/BOOT/lex.iii`+`lex_rt.iii`; `GRAMMAR/src/*.c` (13) → `COMPILER/BOOT/parse.iii`+`ast.iii`; their `include/`, `src/*.h`, `build/Makefile`,`build/build.sh` | RETIRE (Phase 4) — proof-gated: `.iii` superseder is the live compiler's lexer/parser; C is build-excluded. |
| **D · to-adjudicate** (consumer/port investigation, Phase 4) | `CONSTANTS/src/{constants_api,constants_table}.c` (R1.D2 constitutional-constants ledger); `FOUNDERS-ANCHOR/src/founders_anchor.c` (R-3 structural-veto governance) | INVESTIGATE — consumed by the `.iii` artifact? has/needs an `.iii` path? UNPORTED-GAP → port (no skips); standalone reference → harness receipt. NOT deleted blindly. |

**cic.c carve-out:** CLOSED and banked — a real slice of H13 already done.

---

## §2 · The self-audit census (III auditing its OWN tree, by III)

`onelang_gate` (the `.iii` supersession of `verify_sha256_dedup.sh`) run from the repo root,
2026-06-06, wrote this census to `./onelang_census.txt` and exited with the verdict:

```
onelang  files=134 boot=51 harn=8 dead=68 gap=7 dirs=84 overflow=0 verdict=2
```

Cross-checked against ground-truth `find`: `files=134` and `dirs=84` match **exactly**. The
verdict is **VIOLATION** because `gap=7` (and `dead=68` keeps it from PURE). The 7 GAP files
(the honest one-language holes) are:

| GAP file | disposition (M24: port-then-retire, never retire-without-superseder) |
| --- | --- |
| `CONSTANTS/src/constants_api.c`, `constants_table.c`, `include/iii/constants.h`, `constants_internal.h` | **PORT** → `numera/constants.iii` (R1.D2 ledger); byte-equiv KAT; retire C |
| `FOUNDERS-ANCHOR/src/founders_anchor.c`, `include/iii/founders_anchor.h` | **PORT** the runtime veto (Ed25519 — `crypt_ed25519.iii` exists) → `.iii`; KAT; retire C. §6 Shamir custody classified by runtime-vs-ceremony. |
| `STDLIB/include/iii/stdlib.h` | harness-class C-ABI header (consumed only by `test_stdlib.c`) — fold/retire with the test |

`dead=68` = the LEXICON+GRAMMAR subtrees (proven superseders `lex.iii`/`parse.iii` are the LIVE
compiler's lexer/parser; build-excluded) → **RETIRE**. Convergence target: `gap=0, dead=0` → PURE.

## §3 · Progress log

- **2026-06-06 · Phase 0 DONE** — classification; handle/capability/fs models read; `WIN32_FIND_DATAA`
  layout verified (`dwFileAttributes`@0, `cFileName`@44, `FILE_ATTRIBUTE_DIRECTORY=0x10`, 320B).
- **2026-06-06 · Phase 1 DONE** — `aether/fs.iii` Phase-D directory enumeration
  (`fs_dir_open/read/close` + `name`/`name_len`/`is_dir` + `fs_mkdir`/`fs_rmdir`); corpus **1124**=99.
  Fixed a latent **handle-table leak** (the dead `handle_drop` reaper was never called; `fs_close`/
  `fs_dir_close` now free the slot — the walk exhausted the 64-slot table at the 65th directory).
- **2026-06-06 · Phase 2 DONE** — `sanctus/onelang.iii` (explicit work-stack walk, one-active-search
  discipline, 4-bucket classify, cad-sealed census); corpus **1125**=99 (PURE/ACCOUNTED/VIOLATION +
  injected-GAP falsifier + reproducible seal). `onelang_gate` ran on the real tree (census above).
  Regression: 37/38/687/1124/1125 all =99 after the handle fix.
