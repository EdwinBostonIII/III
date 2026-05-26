# Module 6 — the Witness & Commons: file-by-file lean implementation plan

## Gate cleared

Written only because **Module 5 (the Sovereign Value) is verified fully + perfectly**: build
`PASS=356 FAIL=0`, `669_sovval=99` re-confirmed on metal against the live lib, full gate
`b29jhg0nx` exit 0 (`FAIL=0`), and M5 is purely additive (no existing module touched → no
regression possible). No placeholder/deferral/flaw.

## Context

**Why this change.** Module 6 of `DOCS/III-APOTHEOSIS.md` is **The Witness & Commons** — the
append-only provenance spine. It is **already built and well-falsified**: `aether/witness_hook.iii`
(380 lines, K=0.99, the FULL 1M-fragment / ~1 GiB-BSS gospel capacity) carries a comprehensive
`wh_selftest` (publish, payload round-trip, frag-id determinism + distinctness, accessors,
revoke, epoch-close, resolution) and `219_witness_chain` exercises the chain; `numera/algebraic_time.iii`
has `at_selftest`. **The two M6 gaps (the apotheosis Final):** *(1)* `frag_id` is computed by
hashing **directly with keccak256** (3 sites: `wh_compute_frag_id` streaming, `wh_epoch_close`
streaming, `wh_append_resolution` oneshot) — not through the one content-address primitive
`cad`/M1 (now built); *(2)* there is no **provable forgetting** — `wh_revoke` soft-marks a
fragment (epoch-close skips it) but the payload bytes remain; a fragment cannot be redacted to
leave a *verifiable hole*.

**Intended outcome.** Route all witness hashing through `cad`/M1 (byte-identical — the spine is
now content-addressed by the one primitive) and add `wh_redact` (forget the payload, keep the
fragment + a `cad`-commitment to what was there, frag-id and chain root unchanged → a verifiable
hole). The M6 Final falsifier becomes executable: a recomputed frag-id ≠ its stored id, a broken
chain link, or a redaction that leaves no verifiable hole → red.

## ADR-1 — Route the 3 keccak sites through `cad` (byte-identical; the spine joins the one address)

- **Decision.** Replace, in `witness_hook.iii`:
  - `wh_compute_frag_id`: `keccak256_init` → `cad_begin(CAD_SUITE_KECCAK256)`; each
    `keccak256_update` → `cad_payload`; `keccak256_final` → `cad_final`.
  - `wh_epoch_close`: same streaming substitution.
  - `wh_append_resolution`: `keccak256_oneshot` → `cad_oneshot(CAD_SUITE_KECCAK256, …)`.
- **Why byte-identical.** `cad_begin(KECCAK)` *is* `keccak256_init`; `cad_payload(p,len)` *is*
  `keccak256_update(p,len)` (the `0x00` separator is added only by `cad_domain`, which is NOT
  used here); `cad_final` *is* `keccak256_final`; `cad_oneshot(KECCAK,…)` *is* `keccak256_oneshot`.
  So every `frag_id`, the epoch root, and the resolution commitment are **unchanged** → `wh_selftest`
  + `219_witness_chain` + the witness consumers stay green. (Same behavior-preserving discipline
  as M1's `content_addr`/`mhash` fold.)
- **Reentrancy.** `cad`'s Crown is non-reentrant (one `CAD_ACTIVE`), but each witness hash is a
  complete `begin→…→final` session with no nesting → safe. Keep the direct `keccak256` externs
  only if still referenced after the substitution (audit; likely droppable).

## ADR-2 — Provable forgetting: `wh_redact` leaves a verifiable hole; policy is M20

- **Decision.** Add `wh_redact(idx)`: zero the fragment's payload bytes in `WH_PAYLOAD_BUF`, set
  a new `WH_REDACTED[idx]=1`, and store `cad_oneshot(KECCAK, original_payload)` in a new
  `WH_REDACT_COMMIT[idx]` (32 bytes) **before** zeroing. The stored `WH_FRAG_ID[idx]` is **left
  intact** (it was computed at publish) → the chain root and every prev-link are unchanged
  (no broken link). The payload content is gone (`wh_get_payload` returns the zeroed hole), but
  the commitment proves what was there. Add `wh_is_redacted(idx)->u8` and
  `wh_redaction_commit(idx, out)->i32`.
- **Verifiable hole.** The hole is verifiable two ways: the fragment still hashes into the chain
  root by its preserved `frag_id` (membership intact), and `wh_redaction_commit(idx)` equals
  `cad(original_payload)` (a non-recoverable proof of the redacted content).
- **Out of scope (M20):** *who* may redact and *under what Constitution clause* — the redaction
  **policy/governance** is M20's Constitution-gated scope. M6 provides only the **mechanism** +
  its verifiable-hole falsifier. (Same MECHANISM-here / POLICY-in-owning-module split as M2→M7,
  M3→M9, M5's boundary lift.)

---

## Files (create / modify)

| Action | File | What |
|--------|------|------|
| **MODIFY** | `STDLIB/iii/aether/witness_hook.iii` | add `cad` externs; route the 3 keccak sites through `cad`; add `WH_REDACTED`/`WH_REDACT_COMMIT` + `wh_redact`/`wh_is_redacted`/`wh_redaction_commit`; extend `wh_selftest` with the redaction checks (codes 16–2x) |
| **CREATE** | `STDLIB/corpus/NNN_witness_redact.iii` | corpus wrapper (`extern wh_selftest; main → it`) **iff** no corpus test already invokes `wh_selftest` (Step 0 decides; else the extended `wh_selftest` rides the existing test) |
| **MODIFY** | `STDLIB/scripts/run_corpus.sh` | add `[NNN_witness_redact]=99` iff a new wrapper is created |

(`witness_hook` is already in `build_stdlib` MODULES — no MODULES change. `cad` precedes it.)

## Step 0 — Pre-flight (read-only)
0.1 Prefix check: `grep -n "WH_REDACT\|wh_redact\|cad_begin\|cad_payload" STDLIB/iii/aether/witness_hook.iii` — confirm free.
0.2 Confirm a corpus test invokes `wh_selftest`: `grep -rn "wh_selftest" STDLIB/corpus` + read `219_witness_chain.iii`. If `wh_selftest` is already wrapped, extend it (no new corpus number). If not, create `NNN_witness_redact` (next free, ≥670).
0.3 Confirm `cad`'s exact streaming signatures: `cad_begin(suite:u32)->i32`, `cad_payload(payload:u64,payload_len:u64)->i32`, `cad_final(out_32:u64)->i32`, `cad_oneshot(suite:u32,msg:*u8,len:u64,out:*u8)->i32`. **Note the ABI:** `cad_payload`/`cad_final` take `u64` (address), `cad_oneshot` takes `*u8`/`*u8` — match `witness_hook`'s existing pointer forms exactly.
0.4 Confirm the witness corpus link path (the BSS-wall handling: witness_hook has ~1 GiB BSS, so its corpus test uses the harness's selective `--whole-archive`/staging). Note how `219_witness_chain` is linked + run, to reproduce for the gate.
0.5 Baseline: corpus `PASS=390`, the witness test green.

## Step 1 — MODIFY `witness_hook.iii` : route hashing through `cad` (byte-identical)
1a. Add externs (after the keccak externs):
```
extern @abi(c-msvc-x64) fn cad_begin(suite: u32) -> i32 from "cad.iii"
extern @abi(c-msvc-x64) fn cad_payload(payload: u64, payload_len: u64) -> i32 from "cad.iii"
extern @abi(c-msvc-x64) fn cad_final(out_32: u64) -> i32 from "cad.iii"
extern @abi(c-msvc-x64) fn cad_oneshot(suite: u32, msg: *u8, len: u64, out: *u8) -> i32 from "cad.iii"
const WH_SUITE_KECCAK : u32 = 1u32   /* cad CAD_SUITE_KECCAK256 */
```
1b. `wh_compute_frag_id`: `keccak256_init()` → `cad_begin(WH_SUITE_KECCAK)`; each
`keccak256_update(p, n)` → `cad_payload(p as u64, n)`; `keccak256_final(out_id)` →
`cad_final(out_id as u64)`. (Pointers→u64 for the cad ABI.)
1c. `wh_epoch_close`: same substitution.
1d. `wh_append_resolution`: `keccak256_oneshot(payload as u64, plen as u64, (&WH_OUT_TMP as u64))`
→ `cad_oneshot(WH_SUITE_KECCAK, payload, plen as u64, (&WH_OUT_TMP as u64) as *u8)`.
1e. Remove the now-unused direct `keccak256_*` externs **iff** Step-1 audit shows zero remaining
direct uses (else keep). Compile-only-validate.

## Step 2 — MODIFY `witness_hook.iii` : provable forgetting
2a. State: `var WH_REDACTED : [u8; 1048576]` and `var WH_REDACT_COMMIT : [u64; 4194304]` (1M*32);
zero `WH_REDACTED` in `wh_init` (loop or rely on zero-init); selftest scratch as needed.
2b. `wh_redact(idx: u64) -> i32 @export`:
```
if idx >= WH_NEXT_IDX { return WH_E_BAD_IDX }
let pl : u64 = WH_PAYLOAD_LEN[idx] as u64
let src : *u8 = ((&WH_PAYLOAD_BUF as u64) + WH_PAYLOAD_OFFSET[idx]) as *u8
let com : *u8 = ((&WH_REDACT_COMMIT as u64) + idx * 32u64) as *u8
cad_oneshot(WH_SUITE_KECCAK, src, pl, com)   /* commit BEFORE forgetting */
let mut i : u64 = 0u64
while i < pl { src[i] = 0u8  i = i + 1u64 }   /* forget the content */
WH_PAYLOAD_LEN[idx] = 0u32                     /* the hole */
WH_REDACTED[idx] = 1u8
return WH_OK
```
(The stored `WH_FRAG_ID[idx]` is untouched → chain root + prev-links unchanged.)
2c. `wh_is_redacted(idx)->u8` (bad idx → 0); `wh_redaction_commit(idx, out:*u8)->i32`
(`ident_copy` from `WH_REDACT_COMMIT[idx]`).
**Trap audit:** single-line fn; module-scope arrays; equality-only; W2 (≤4 params); the
`(&ARR as u64)+off` element-address idiom (the file's existing pattern); no recursion.

## Step 3 — Extend `wh_selftest` with the redaction falsifier (codes 16–2x)
After the existing checks (return 99 moves down): publish a fragment with a known payload P;
save its `frag_id` (via `wh_get_frag_id`); `wh_redact(idx)`; assert
- `wh_is_redacted(idx)==1` (code 16);
- `wh_get_payload(idx,…)` returns the hole (`out_len==0`, bytes zeroed) (code 17);
- `wh_get_frag_id(idx,…)` is **unchanged** vs the saved id (chain integrity — code 18);
- `wh_redaction_commit(idx,…)` equals `cad_oneshot(KECCAK, P)` (the verifiable hole — code 19);
- a **non-redacted** sibling fragment's payload is still intact (no over-redaction — code 20);
- `wh_epoch_close` still succeeds after redaction (chain still closes — code 21).
`return 99u64`.

## Step 4 — corpus wiring (per Step 0.2): extend the existing `wh_selftest` test, or create
`NNN_witness_redact` + register `[NNN_witness_redact]=99`.

## Step 5 — Verify
1. compile-only `witness_hook.iii`. 2. `build_stdlib` → `FAIL=0`, `aether/witness_hook` OK.
3. run the witness corpus test (the `wh_selftest` wrapper) on metal via the harness's BSS-wall
link path → `99`. 4. run `219_witness_chain` → still `99` (byte-identity proof: frag-ids
unchanged by the cad-routing). 5. full `run_corpus` → `FAIL=0`, no regression, `PASS` = baseline
(+1 iff a new wrapper). 6. manual hand-check: the 3 cad substitutions are byte-identical
(cad_payload=keccak update, no separator); `wh_redact` commits before zeroing; frag_id untouched.

**Single falsifier:** `wh_selftest`≠99 (a frag-id changed by the routing, a redaction that leaves
the payload or breaks the frag-id/chain, or a missing/ wrong commitment), or `219_witness_chain`
flips → red, diagnose.

## Standards checklist
NIH (libc + cad.iii + keccak256/identifier/algebraic_time, all in-tree); determinism (no float,
equality-only, the witness is already deterministic); W2 (`wh_redact`/getters ≤4 params), W8
(bounded 1M arrays — full gospel capacity retained, NO down-scaling), W14, W15 (no recursion);
K=0.99 (the witness's gospel K). Apotheosis M6: `frag_id` now content-addressed by the one
primitive (cad/M1); provable forgetting with a verifiable hole is the executable M6 Final
falsifier. Redaction POLICY = M20; the SovVal witness facet's chain integration = M5/M16 hook.

## Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| A cad substitution not byte-identical (e.g. accidental `cad_domain` separator) | every frag-id changes → chain breaks | use `cad_payload` only (no `cad_domain`); 219 + wh_selftest frag-id checks are the byte-identity gate |
| `wh_redact` zeros before committing | the verifiable hole is lost | commit (`cad_oneshot`) BEFORE the zero loop — explicit ordering in 2b |
| redaction perturbs the stored frag_id | broken chain link | `WH_FRAG_ID[idx]` is never rewritten by `wh_redact`; selftest code 18 asserts it |
| witness_hook BSS wall breaks the corpus link | can't run the gate | reuse the exact `219_witness_chain` harness link path (Step 0.4) |
| `WH_REDACT_COMMIT[u64;4194304]` (1 GiB) busts the 2 GiB code-model reach | link fail | witness already uses [u64;N] byte-packing; total BSS still < 2 GiB — verify the build links (it did at 1 GiB ANTE + 64 MiB payload); if tight, store commit in the freed payload region instead |

## Roadmap
1. Steps 0–1: route through cad → gate (`wh_selftest` + `219` stay `99` — byte-identity).
2. Steps 2–4: add `wh_redact` + extend the falsifier → gate (redaction codes 16–21 green).
3. Step 5: full `run_corpus` `FAIL=0`. Redaction POLICY lands with **M20**.
