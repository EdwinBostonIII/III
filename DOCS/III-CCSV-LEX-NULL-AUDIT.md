# III — ccsv/lex.c RUNTIME-NULL Root-Cause Audit (Φ1/R1)

**Symptom (committed `df7ef796`):** the full `lex.c`, compiled by `ccsv→SVIR→svir_interp`, returns
**NULL from `iii_lex_create`** (`_lexharness.c` prints `N`); gcc-built returns the correct stream mhash
`4bddb768…`. A **structurally-clean** module (lex.c = seed verify floor 0) does not run → a ccsv *codegen*
bug the structural floor cannot see (`svir_verify` is a no-underflow check only).

**Instrument state (this session):** `run_seed_verify.sh` re-armed — its positive/negative hand controls
(`_ve_goodmod.iii`/`_ve_badmod.iii`) were untracked and lost in the 2026-07-01 reorg; restored byte-exact
from `004e1baa:library/sovir/`. Live floor re-confirmed **34/488** (`lex 0 · sema 5 · emit 3 · ast 8 ·
cg_r3 2 · parse 16`).

---

## ⚠ RECONCILIATION (2026-07-01) — this NULL was ALREADY fixed; the fix was lost in the reorg
`memory/project_iii_ccsv_lex_null.md` records that on **2026-06-30** this exact NULL was root-caused (via
the rigorous method: instrument the **interpreter**, not the program — the interp trace *observed*
`iii_lex_create`'s calloc SUCCEEDING, `st=1048592`, then `st` READ from spill as 0) to a **spill /
`emit_lset` bug** (`prescan_addrof` spuriously marks `st` &-taken from `&st->field`; struct-ptr decl-init
used raw `eu8(0x11)` not spill-aware `emit_lset` at ccsv:1131/1149), and that **8 ccsv bugs were fixed →
lex.c byte-parity with gcc, mhash `4bddb768…`.**

**Those 8 fixes are ABSENT from master@df7ef796 and PRESENT in `004e1baa` (reorg-backup):** master ccsv.iii
= 2000 lines, `SFPSZ|DIV_U|SFPSG`=0; `004e1baa:library/sovir/ccsv.iii` = 2075 lines, markers=8, `emit_lset`
22 vs 20. They are **uncommitted work lost in the 2026-07-01 reorg-rewind** — same failure mode as the
`_ve_goodmod/_ve_badmod` instrument controls.

**Correction to Phase 2 below:** my black-box exit-code probe pinned "`sizeof(*st)` → calloc NULL", but
`if(!st)` fires for TWO reasons (calloc returns NULL **or** `st` written-but-read-as-0), which the probe
does not split — the documented "split your exit codes" lesson. The prior **observer-method** evidence
(calloc observed to succeed) says the real root is the **spill read mismatch**, not `sizeof`. My mechanism
is **UNDERDETERMINED / likely wrong**; the Phase-2 *site* (create:1405/1404, reproduced NULL on master) is
correct, the *mechanism* is superseded by the recovered diagnosis.

**THE MOVE: recover the 8 fixes from `004e1baa`, re-verify via the gates, re-land + COMMIT (so they can't be
lost again) — do NOT re-derive.** See "Recovery plan" at end.

## Phase 1 — EVIDENCE (failure path, fully read; no `.iii`/`.py` edits)

Harness order (`_lexharness.c:18`): `st = iii_lex_create(src,n,"t.iii"); if(!st){print 'N'}`. The NULL
returns **before** any tokenizing → the bug is in `create`'s own compiled code, not in scan/hash.

`iii_lex_create` (`lex.c:1400–1447`) has exactly **two** NULL exits:
- **1405** `if(!st) return NULL;` — outer `calloc(1,sizeof(*st))`. **Excluded:** commit isolated
  `calloc(1,…)=Y`, `sizeof(iii_lex_state_t)=464==gcc`.
- **1433** `if(iii_intern_init(&st->intern)!=0){ free(st); return NULL; }` — **the live path.**

Between 1405 and 1431 `create` only does scalar field stores + `iii_sha256_init(&st->stream_sha)` (1430).
`iii_sha256_init` (`lex.c:98–104`) writes only `h[0..7]`, `total_bits`, `buf_used` **within** `iii_sha256_t`
(`{uint32_t h[8]; uint64_t total_bits; uint8_t buf[64]; size_t buf_used;}`, gcc 112B) — no overflow into the
adjacent `intern` field **iff** ccsv sizes `uint32_t[8]` as 32 (gap-map §4 records ccsv sizing `uint32_t[8]`
as **64**, a divergence to check).

`iii_intern_init` (`lex.c:266–273`) — the sole source of the nonzero:
```c
t->cap = 1024u; t->count = 0u; t->next_id = 1u;
t->slots = (iii_intern_slot_t *)calloc(t->cap, sizeof(iii_intern_slot_t));
return t->slots ? 0 : -1;
```
`iii_intern_slot_t` = `{uint32_t start_byte; uint32_t length; uint64_t hash; uint32_t id;}` (gcc 24B; ccsv
i64-model would be 32B).

### `b[8]` const-data hypothesis — REFUTED for THIS NULL
The commit's candidate (`iii_sha256_update_u64`'s local `uint8_t b[8]`, `lex.c:170`) is only reached from
`iii_token_mhash` (`lex.c:1490`), which runs during `iii_lex_next`/`stream_mhash` — **after** the harness's
NULL check. It cannot cause `create` to return NULL. (It remains a real, separate suspect for the *mhash*
divergence once `create` is fixed.)

### Candidate roots for the 1433 NULL (each discriminated by `_intern_probe.c`)
1. **`sizeof(iii_intern_slot_t)` miscompiled** → 0 or absurd → `calloc(1024, esz)` returns NULL. (sizeof of
   a mixed-width struct; `next_id` is `uint32_t` beside `uint64_t hash` — padding/packing model.) → probe rc **10/11**.
2. **`calloc(1024, esz)` returns NULL with sane args** — arg-passing (2-arg width) or interp calloc. → rc **12**.
3. **Field write/read mismatch on `t->cap`/`t->slots`** through `&st->intern` (offset of `intern` after the
   `stream_sha` block; depends on `uint32_t[8]` sizing) → `t->cap` read absurd → `calloc(absurd,…)` NULL, or
   `t->slots` read back wrong. → rc **13/14/15**.
4. **`t->slots ? 0 : -1` ternary miscompiled** → returns -1 despite valid slots. → rc **13** (with slots ok).

## Phase 2 — VERIFY IN BINARY (COMPLETE — root pinned)
Three probes, each run gcc (reference) vs `ccsv→SVIR→svir_interp`:

| probe | what it isolates | gcc | ccsv→interp | verdict |
|---|---|---|---|---|
| `STDLIB/build/sovir/_intern_probe.c` | isolated `intern_init` (seed types, `sizeof(TYPE)`, 2-arg `calloc`, ternary, field r/w) | 99 | **99** | EXCLUDES candidates 1,2,4 + isolated-3 |
| `COMPILER/BOOT/_create_probe.c` (`#include "lex.c"`, REAL types) | create's exact sequence | 99 | **12** | PINS create:1405 `calloc(1,sizeof(*st))` → NULL; `sizeof(iii_lex_state_t)` (type) sane (no 20/21); emit 196 756 B ⇒ faithful |
| `COMPILER/BOOT/_create_probe2.c` | the identical calloc, preceded by one `sizeof(*p)` of the same type | 99 | **99** | ISOLATES the sole delta = the deref-sizeof → confirms `sizeof(*st)` resolution is the variable |

### VERIFIED ROOT CAUSE
`iii_lex_create` (`lex.c:1404`) does `iii_lex_state_t *st = calloc(1, sizeof(*st))`. **ccsv miscompiles
`sizeof(*st)`** — the deref-sizeof of the pointer being declared in its own initializer — to a
**calloc-failing size** (0/garbage, not the correct 464). `calloc` returns NULL → create returns NULL at
1405. The intern_init path (1433), the `b[8]` const-data buffer, the 2-arg calloc mechanics, and
`sizeof(TYPE)` are all **excluded in binary**. Adversarially robust: probe #3 runs the *identical* calloc
line and returns 99 — the only difference is a preceding deref-sizeof of the same type.

### Mechanism (as far as read; no edits)
`esizeof` (`ccsv.iii:377`): `sizeof(*ptr)` (380–382) leaves `sz` at its default **8** (379) unless
`lpt(C)≥0` (→`STSZ[LPT[lidx]]`) or `lidx(C)≥0` (→`LPSZ`). `lpt`(235)=`LPT[lidx]`, `lidx`(203)=local-table
search. Since the emitted size *fails* calloc (not 8), `st` resolves via `lidx`/`lpt` to a slot whose
`LPT`/`LPSZ` is not yet valid **at the parse point of `st`'s own initializer** → degenerate size. The
priming (probe #3) shows a prior deref-sizeof of the type makes the later one correct.

**CONFIRMED:** site (create:1405), construct (`sizeof(*st)` self-declared deref), binary reproduction, fix
locus (`esizeof` ↔ local-decl metadata ordering). **OPEN (Phase-3 step 1):** the exact emitted value +
why the prior deref primes it — confirm by instrumenting `esizeof` to print `sz` for `sizeof(*st)`.

## Phase 3 — FIX (next session; edits `ccsv.iii`)
NOT this session (crash-protocol: touch `ccsv.iii` only in a focused session). Candidate fixes: (a) the
local-declaration handler registers `st` + sets `LPT`/`LPSZ` **before** parsing its initializer; or (b)
`esizeof` resolves the pointee type from the declared type when `lidx`/`lpt` metadata is not yet set.
**Gate:** `_create_probe.c` rc 12→99 under ccsv→interp, then lex.c `_lexharness` ccsv mhash == gcc
`4bddb768…`, then `run_seed_verify` floor unchanged + `run_ccsv` green (no regression). These probes are the
durable Phase-3 KATs.

## RECOVERY — EXECUTED + VERIFIED (2026-07-01; working tree, NOT yet committed)
Recovered the coherent set `004e1baa:library/sovir/` → `STDLIB/sovir/` (git-show byte-exact): `ccsv.iii`
(2000→2075 L, the 8 fixes), `svir_interp.iii`(+1), `svir_verify.iii`(+1), `svir_x86.iii`(+2),
`svir_wasm.iii`(+2) — the DIV_U/REM_U ISA extension recovered **coherently with its emitter** (recovering
ccsv alone would have emitted opcodes the master interp can't decode). De-risk: `004e1baa` descends from
df7ef796 (ancestor ✓); ccsv.iii delta additive (master-only lines are the pre-fix predecessors;
`CALL_INDIRECT` 3=3 → fn-ptr INC-1/2 intact).

**GATES (re-run on current master with recovered sources):**
- **PARITY (the real gate) — MATCH:** `_lexharness` ccsv→interp mhash == gcc mhash = `4bddb768…54b`,
  byte-identical (trailing `BW:/N=64` = interp's known const-data-watch false-positive on mutable globals).
  **The lex.c NULL is FIXED; lex.c tokenizes identically to gcc.**
- **FLOOR — 34** (lex 0·sema 5·emit 3·ast 8·cg_r3 2·parse 16); 3 controls green; no structural regression.
- **run_ccsv — EXIT 0:** SHA-256 / HMAC-SHA256 (RFC 4231) / AES-128 (FIPS-197) sovereign capstones + tiers
  all-99.
- **run_ddc — was PRE-EXISTING RED, orthogonal to the lex fix:** the failing `cmp` compares `iiisv` vs
  `iiisv2` on `indep_*` — none of which the lex recovery touched (git status confirms). master↔`004e1baa`:
  `iiisv2.iii` differs by **14 lines** (iiisv + indep_* identical) → the DDC byte-closure fix lived in
  `iiisv2.iii` and was **lost in the same rewind**. Recovered `iiisv2.iii` (279L) → **run_ddc
FRONTEND-CLOSED** (iiisv==iiisv2 byte-identical: toolchain 1321B / ops 893B / bignum 2819B; verifier OK;
x86(sovereign)+wasm=99). **ALL FOUR GATES GREEN.**

## THE REORG-LOSS IS A PATTERN (broader than lex) — breadth is the user's call
The 2026-07-01 rewind to df7ef796 dropped a SET of uncommitted session work (`004e1baa` ⊇ df7ef796):
- **CLEAR verified-fix losses (gate-un-redding) — RECOVERED:** `ccsv.iii`+DIV_U/REM_U ISA (lex parity),
  `iiisv2.iii` (DDC closure), `_ve_goodmod/_ve_badmod` controls (seed-verify instrument).
- **AMBIGUOUS (differ master↔004e1baa; may be "event-build roadmap" WIP per the backup commit msg, NOT
  verified fixes) — NOT auto-recovered, need adjudication:** `eidos_ripple_native.iii`(14),
  `eidos_ripple_probe.iii`(14), `xii_proof_demo.iii`(28), `zk_eidos_ripple.iii`(14), `zk_gu_ripple_xii.iii`(24).

**COMMIT (recommended, pending user go):** land the CLEAR recovered set (ccsv+ISA+iiisv2+controls+this
audit) so it can't be lost a THIRD time (root failure mode = verified work left uncommitted). Target
`master` (all recent history is there; env names `main` as repo-main — confirm). Adjudicate the 5 ambiguous
files separately (fix vs roadmap-WIP).  **→ COMMITTED `e46cedb7` (surgical, concurrent WIP untouched).**

## PHASE 4 — RUNTIME-DIFFERENTIAL GATE (built, verified, committed)
`STDLIB/sovir/run_seed_runtime.sh` — the institutional fix for this session's lesson (structural floor ≠
runtime-correct). Per seed module with a behavioral harness, asserts `ccsv→SVIR→svir_interp` stream-mhash ==
`gcc` stream-mhash. Today: lex.c (via `COMPILER/BOOT/_lexharness.c`); extensible via a MODULES table (no stub rows).
- **POSITIVE:** `lex : ccsv==gcc mhash=4bddb768…` → RUNTIME-CORRECT; `GATE_EXIT=0`.
- **TEETH (falsifier):** rebuilds the pre-recovery `df7ef796` ccsv → `[<NULL/none>] != gcc` → the gate reddens
  on the real bug. Red-demo: the broken ccsv as the one-under-test → `GATE RED (rc1)`.
- **Conscience (you invoked math-conscience):** `iii_math_rigor` = PROVEN-IN-CODE (calibrated to the harness
  input x₀ — NOT all-lex, NOT the other 5 modules); `iii_adversarial_verify` = SURVIVES-high (empty-collusion
  edge closed by the `-n "$cg"` guard, gate:52); `iii_check_discharge` = DISCHARGED (teeth @ gate:58);
  `iii_proof_obligations` contract met (DETERMINISM/BINARY N/A — compiler-unreferenced gate, no codegen change).
- **SCOPE (honest, not a placeholder):** proves lex.c runtime on x₀; sema/emit/ast/cg_r3/parse await behavioral
  harnesses (several gated on the shadow-stack / struct-by-value rework) — add a MODULES row when one lands.
