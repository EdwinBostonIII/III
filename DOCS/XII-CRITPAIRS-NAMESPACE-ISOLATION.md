# Phase XII-τ part 2 — xii_critpairs Global-Namespace Isolation + run_corpus.sh Harness Hardening

Status: COMPLETE & FULLY VERIFIED. Closes the two residual
`link rc=1` corpus failures root-caused in Phase XII-τ part 1. Also
root-causes and fixes two pre-existing genuine harness defects in
`STDLIB/scripts/run_corpus.sh` surfaced during verification.

## 1. The defect (genuine — module-prefix discipline violation)

Under the corpus link line
`gcc <test>.o -Wl,--whole-archive libiii_native.a -Wl,--no-whole-archive`,
**every** member of `libiii_native.a` is force-linked into **every**
corpus test. `STDLIB/iii/omnia/xii_critpairs.iii` defined six generic
non-`@export` constructor helpers — `_make_null`, `_make_basis`,
`_make_compose`, `_make_then`, `_make_with`, `_make_under` — plus
`_apply`. Per iii symbol mangling, a module-scope non-`@export`
function emits a global linker symbol `L_<name>`, so xii_critpairs.iii
exported `L__make_compose` (etc.) into the **global** link namespace.

Corpus tests `265_return_kind_static.iii` and
`267_call_arg_cross_check.iii` legitimately define their *own*
`fn _make_compose()` test helper → `L__make_compose`. Force-linking
xii_critpairs.iii.o into them produced:

```
ld: libiii_native.a(omnia_xii_critpairs.iii.o):fake:(.text+0x99):
    multiple definition of 'L__make_compose';
    265_return_kind_static.o:fake:(.text+0x30): first defined here
```

This is exactly the CLAUDE.md "module-level symbol is global-scope"
trap, generalized from `const` to `fn`: a STDLIB module **must**
module-prefix its module-scope symbols. `_make_*`/`_apply` violated
that discipline. The `_cp_*` family (and `_cp_converges`) were already
namespaced (`_cp_` = critpairs) and compliant.

Full-symbol enumeration proved `_make_compose` was the *sole* actual
collision (xii_critpairs.iii defines no `main`/`_make_form`/
`_consume_compose`), but per Standard 3 ("fix ALL preexisting, even if
harder; no workaround to skip") + the CRASH-PROTOCOL ("fix ALL, not
just the first suspect"), the *entire* generic helper family was
prefixed — the un-collided names are the same latent discipline
violation.

## 2. The fix (deterministic 13-step substring-safe rename)

All seven helpers → `_xcp_*` (`xcp` = xii-critpairs, consistent with
the file's existing `_cp_` convention):

- `_make_null/_make_then/_make_with/_make_under/_make_compose` are
  **substring-unique** → direct `replace_all`.
- `_make_basis` ⊂ `xii_term_make_basis` (47 occ) and
  `_apply` ⊂ `xii_rewrite_apply_one` (1) / `xii_rewrite_apply_specific`
  (2) — a blanket `replace_all` would corrupt the wrapped externs (the
  documented substring trap). Handled via **deterministic
  placeholder-swap**: protect extern → rename helper → restore extern
  (`xii_term_make_basis`→`Z9XTMBZ9`→…; `xii_rewrite_apply_*`→`Z9XRA*Z9`
  →…). The "harder" path, taken — not skipped.

Public `@export` contract (`xii_critpairs_verify_class/verify_all/
pair_count/actual_count`, `_cp_ext_run_idx`) is unchanged — none
contain `_make_*`/`_apply` — so corpus 344/371 (which link the
`xii_critpairs_*` externs) are unaffected.

### Verification (no assertion without evidence)

| Gate | Result |
|---|---|
| Externs conserved | `xii_term_make_basis`=47, `xii_rewrite_apply_one`=1, `xii_rewrite_apply_specific`=2 (exact pre-edit counts) |
| Placeholder residue | 0 / 0 / 0 |
| Substring corruption | none (`xii_term_xcp*`/`xii_rewrite_xcp*` absent) |
| Helpers migrated | 7/7 at original line numbers 70/74/78/82/86/90/117; `_cp_converges` untouched |
| Triple bit-identity | `xii_critpairs.iii.o` = `d403dd9b…` × {iiis-0,iiis-1,iiis-2} |
| build_stdlib.sh | PASS=246 **FAIL=0** |
| **The defect** | 265 & 267: `link rc=1` → **PASS exit=99**; `nm`: `L__make_compose` eliminated, `L__xcp_make_compose` present |
| Determinism | VP-4 iiis-0 golden MATCH (no reseal — STDLIB-only change); iiis-1/2.exe MATCH; libiii_native.a self-seal regenerated & consistent |
| run_corpus.sh | PASS=258 FAIL=0 SKIP=94 |
| run_xii_corpus.sh | PASS=93 FAIL=0 |

`258 = 256 (pre-τ-pt2 baseline) + 2 repaired`. Zero genuine failures,
zero regression.

## 3. Two pre-existing run_corpus.sh harness defects (root-caused, fixed)

Verification surfaced a 256→236 PASS drop. Per
`feedback_no_recurring_anomaly_handwave` this was root-caused, not
dismissed:

**(A) Stale-compiler determinism violation.** `run_corpus.sh`
auto-discovered `$IIIS` from PATH / `C:\Program Files\III\bin\iiis.exe`
— a **May-10 build predating the iiis-2 grammar**, which rejects
Path-A grammar tests (250_multiline_fn, …, 271) at parse with
rc=11/12, masquerading as ~20 regressions. Its sibling harnesses
(`build_stdlib.sh`, `run_xii_corpus.sh:9`) pin
`COMPILED/iiis-2.exe`. Fix: default `IIIS` to the in-tree
`COMPILED/iiis-2$BIN_SUFFIX` (explicit `IIIS=` override still wins;
PATH/Program-Files only as last-resort fallback), and **print the
resolved compiler** so a wrong one is never silent again.

**(B) EXPECTED-coverage miscount.** The `EXPECTED` table ends at
`272_cross_fn_pe`; the greedy `[0-9][0-9][0-9]_*` glob also enumerates
the XII corpus `280..372` (owned/validated by `run_xii_corpus.sh`,
which has its own EXPECTED incl. `299_bit_identity_probe=11` from
Phase σ). Those 94 tests were auto-classified `WRONG expected=?` →
FAIL — a phantom double-count. Fix: **delegate** the `280..372` range
to its owner via a new `SKIP` bucket, and make a *missing* conformance
EXPECTED entry a **hard FATAL** (not a silent `expected=?`) so a new
conformance test cannot quietly miscount — the Phase-σ EXPECTED-table
discipline, generalized and enforced.

Result with both fixes (no `IIIS` env): `iiis = COMPILED/iiis-2.exe`,
PASS=258 FAIL=0 SKIP=94, no FATAL.

## 4. ADR

- **Decision:** STDLIB modules MUST module-prefix every module-scope
  symbol (functions included, not only `const`). Generic helper names
  in a force-linked archive member are a latent global-namespace
  collision and a discipline violation regardless of whether a current
  consumer collides.
- **Decision:** Conformance harnesses MUST pin the in-tree production
  compiler and echo it. Compiler autodiscovery from the environment is
  a determinism violation (silent wrong-compiler measurement).
- **Decision:** Every test a conformance runner *owns* must carry a
  deterministic EXPECTED exit code; a missing entry is a hard error,
  never a silent pass/fail. Ranges owned by another runner are
  delegated (SKIP), not re-judged.
- **Consequence:** the `_make_*`/`_apply` rename changes
  `xii_critpairs.iii.o` symbol names (and thus `libiii_native.a`
  content + its regenerated self-seal) but preserves per-module
  triple-bit-identity and the `@export` ABI; no frozen golden is
  violated; no compiler binary changes.
- **Alternatives rejected:** (i) rename only `_make_compose` (the one
  demonstrated collision) — violates "fix ALL, even if harder";
  (ii) exclude xii_critpairs.iii from the archive — breaks corpus
  344/371 which need its `@export`s; (iii) `--no-whole-archive` — would
  drop side-effecting global initialisers other tests rely on.
