# III Fragile-Remainder Port — Safeguards (worst outcome made impossible)

**Purpose.** The easy/mechanical 80% of the C→.iii/msvcrt port is done (7 gated
increments, linked C TUs 14→9, seal `3eff966d`). The remaining 9 linked TUs are
INTRICATE or FRAGILE. This document is the safeguard contract under which they get
done so that **the worst outcome is impossible.**

## 0. The worst outcomes, and why each is now IMPOSSIBLE (empirically proven 2026-05-26)

| Worst outcome | Safeguard | Proof on record |
|---|---|---|
| A botched conversion corrupts codegen and **ships silently** | the differential gate (`build_iiis2.sh --check-corpus`: iiis-1 C ≡ iiis-2 .iii, byte-identical .o on 57 programs) | a controlled 1-byte break in `iii_lex_read_u32_c` produced **corpus 0 passed / 57 FAILED, BUILD EXIT 5** — impossible to miss |
| A bad build **corrupts the golden seal** | reseal is a manual step that runs ONLY after the gate passes + fixpoint holds | the break build **died at the gate (exit 5) before any reseal** — golden `3eff966d` never touched |
| The **known-good baseline is lost** | every increment is committed; tag `iii-safepoint-T6.4-3eff966d`; recover with `git checkout <file>` or `git reset --hard <tag>` | restore + rebuild reproduced **byte-exact iiis-2 = iiis-3 = `3eff966d`** |
| The **bootstrap chain becomes unrecoverable** | frozen `COMPILED/iiis-0.exe`, `iiis-1.exe` + `COMPILER/BOOT/iiis-{0,1}.mhash` are all committed | verified tracked; iiis-2 always rebuildable from iiis-1 via `build_iiis2.sh` |

## 1. The one residual danger: VACUOUS gating

The differential gate only catches breaks in code the **Ring-3 `--compile-only`
corpus actually exercises.** For code it does NOT exercise, a wrong conversion
passes the gate GREEN while being silently broken. **For every vacuously-gated
piece, a standalone de-risk KAT validated against an independent reference is
MANDATORY — the green gate is not evidence.**

### Vacuous-gate map (which remaining pieces the gate canNOT catch)

| Piece | Corpus-exercised? | Gate verdict | Safeguard REQUIRED |
|---|---|---|---|
| lex_rt deref / mem ops, malloc | YES (every compile reads AST + allocs) | non-vacuous | gate suffices (proven) |
| emit (system/popen/file) | YES (emit runs gcc to make every .o) | non-vacuous | gate suffices (proven) |
| **PE** (`iii_cg_pe_iiis1`) | YES — corpus has `39-43/51-53_resolve_*`, `52_call_via_resolver` | non-vacuous | gate + a resolve()-narrowing KAT |
| **cg_r0 / cg_rm1 / cg_rm2** (Ring 0/-1/-2 codegen + their witness SHA) | **NO** — corpus is all Ring-3 | **VACUOUS** | **KAT MANDATORY** (FIPS-vector SHA KAT; per-ring emit KAT) |
| **lex_runtime SHA-256** | only if lex emits a witness on the `--compile-only` path — UNVERIFIED | **assume VACUOUS** | **KAT MANDATORY** (FIPS abc/56/112 vectors, like cgsha_mb_kat) |
| **lex stderr/stdout/signal/clock/exit/getenv** | **NO** (`--compile-only` doesn't hit verbose-timing / signal / process-exit paths) | **VACUOUS** | **KAT/link-test MANDATORY** (see §3) |
| **XII glue** (sema_xii, cg_r3_xii, adapters, xii_ldil, xii_lattice_loader) | UNVERIFIED — corpus may have no `@lattice`/XII input | **assume VACUOUS until proven** | grep corpus for XII annotations FIRST; if none, KAT each entry point + preserve the iiis-1/iiis-2 bit-identity invariant |

## 2. Mandatory per-increment protocol (do EVERY time)

1. **Read** the C exactly (byte-for-byte logic; record per-function semantics).
2. **De-risk KAT FIRST** — write a standalone `.iii` that links the real new module
   and validates it against an independent reference (FIPS vectors, `sha256sum`,
   a known round-trip). REQUIRED for any vacuously-gated piece (§1). Compile + link
   + run → must hit the pass sentinel (99) before integrating. (This already caught
   two real bugs: the local-array segfault and the NUL-termination trap.)
3. **Integrate** into the consumer `.iii`; delete the C surgically (anchor-based,
   gated `awk`/`sed` with a symbol-presence verification — never `git add -A`).
4. **Gate**: `build_iiis2.sh --check-corpus` → require **57/57**. (Proven to catch
   codegen-corrupting breaks: 0/57 on bad input.)
5. **Fixpoint**: `build_iiis3.sh` → require **iiis-2 ≡ iiis-3**; reseal
   `COMPILER/BOOT/iiis-{2,3}.mhash` ONLY now (gate already green).
6. **Commit** the increment (selective `git add` of the real files — source + the
   2 golden mhashes + the 6 COMPILED artifacts; never the CRLF `.exe.s` noise).
7. Periodic full corpus backstop (`run_corpus.sh`, expect FAIL=0).

**If the gate goes RED at step 4:** do NOT reseal, do NOT commit. `git checkout`
the touched file(s) (byte-exact restore — proven) and diagnose with a KAT before
retrying. The CRASH-protocol rule applies: read all evidence before re-editing.

## 3. Fragile-msvcrt-symbol discipline (lex OS membrane, xii_lattice)

`.iii` string literals are NOT NUL-terminated → all libc string args use
NUL-terminated byte-array vars (module array-literal init works). Beyond that, the
lex OS membrane has UNCERTAIN msvcrt symbol names — resolve each with a focused
link-test KAT BEFORE integration:
- `stderr`/`stdout` are `__acrt_iob_func(2)/(1)` macros, not symbols — extern
  `__acrt_iob_func`; verify vs `__iob_func` on this toolchain.
- `exit` path uses `_Exit` — verify `_Exit` vs `_exit`.
- `clock_ms` uses double float (`.iii` avoids float) — use integer
  `clock()*1000/CLOCKS_PER_SEC`; CLOCKS_PER_SEC=1000 on Windows so ≈ `clock()`.
- `signal` handler is a fn-pointer-as-u64 — confirm it passes through.
A wrong symbol fails at LINK (caught), but a focused KAT catches it cheaply and
proves behavior, not just resolution.

## 4. Recovery procedures (if anything goes wrong)

- **Bad uncommitted edit:** `git checkout COMPILER/BOOT/<file>` → rebuild. (Proven
  byte-exact.)
- **Need the whole verified-good state back:** `git reset --hard
  iii-safepoint-T6.4-3eff966d` → `build_iiis2.sh && build_iiis3.sh`. Reproduces
  `3eff966d`.
- **iiis-2/iiis-3 both bricked + git unavailable:** rebuild from the frozen seed —
  iiis-0 → `build_iiis1.sh` → iiis-1 → `build_iiis2.sh` (uses iiis-1). The seeds +
  their seals are committed.

## 5. Pre-commit checklist (tick all before committing a fragile increment)

- [ ] De-risk KAT written + passes (99) for any vacuously-gated piece.
- [ ] `--check-corpus` = 57/57 (and a flip-a-byte sanity that it would go RED).
- [ ] `build_iiis3.sh` fixpoint holds; golden resealed to the new hash.
- [ ] Selective `git add` (no `.exe.s`/`.log` CRLF noise, no `-A`).
- [ ] Memory updated (the increment + any new trap).
- [ ] If a NEW `.iii` TU: added to **both** `build_iiis2.sh` AND `build_iiis3.sh`
      PORTED_TUS (the T2 lesson — iiis-3 has its own list).

---
*The safeguards above are not theoretical: §0 was demonstrated end-to-end on
2026-05-26 (gate catches 0/57; reseal gated behind the gate; git restore byte-exact;
seeds committed). Under this contract, the fragile remainder can be executed with the
worst outcome — a silently-broken or unrecoverable compiler — made impossible.*
