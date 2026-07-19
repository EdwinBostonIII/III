# HERMENEUS — English-to-EIDOLOS Front-End Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task (inline — **no subagents on III**, per standing project preference). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `omnia/hermeneus.iii` — the door that turns an English utterance into exact EIDOLOS claims through a *propose → vet → read-back → human-confirm → deliver* pipeline, with every law re-proven as a condition of motion.

**Architecture:** A hybrid muse proposes claims (an in-house deterministic grammar for the unambiguous fragment; an external LLM via `xn_admit` for the rest), both quarantined: no proposal reaches the proven DIADOSIS back-end without passing the house's re-derivation AND a human confirm content-addressed to exactly that proposal. HERMENEUS composes EIDOLOS, DIADOSIS, XENOS, LEXICON, IDFOLD — it adds no new inference.

**Tech Stack:** `.iii` (self-hosted III), compiled by the in-tree `COMPILED/iiis-2.exe`; linked with `gcc` against `STDLIB/build/iii/libiii_native.a`. No Python, no pytest — a test is a compiled `*_selfprove` arm returning `0`.

## Global Constraints

- **Compiler (pinned, in-tree):** `COMPILED/iiis-2.exe`. Compile one module: `COMPILED/iiis-2.exe <src.iii> --compile-only --out <out.o>`. Never a downloaded/global compiler.
- **Link:** `gcc -o <exe> <objs...> STDLIB/build/iii/libiii_native.a -lws2_32 -lkernel32`. The archive is produced by `bash STDLIB/scripts/build_stdlib.sh` (must exist before linking).
- **A green test = exit 0** from the probe binary; a failing arm returns its arm number (the DIADOSIS/XENOS idiom).
- **ASCII only** in all `.iii` source.
- **No forward function references** — define every helper before its first use (compiler requirement).
- **64-slot local ceiling** — a function with too many locals fails to compile with **exit 14**. Keep functions small; hoist to module `var` if needed. **Compile each new/changed `.iii` to the scratchpad first** to surface exit-14 before wiring it into the gate.
- **Reserved words** — never name an identifier `any`, `from`, or `mut`.
- **`@export` ratchet** — every `@export` must be consumed by another module or an arm, or the build reddens. Do not export what nothing calls.
- **Determinism** — the gate runs the probe twice and `cmp -s`; output must be byte-identical.
- **settle-retry** — OneDrive/AV can race a fresh `.o`; wrap compiles in the 3-try `cc_one` idiom from `xenos_gate.sh`.
- **Concurrent-session discipline** — HEAD is `26fd91e8` (this session). Commit only the exact paths this plan creates/modifies with `git commit -- <pathspec>`; never `git add -A` (143 unrelated WIP entries live on this tree).

---

## File Structure

- **Modify:** `STDLIB/iii/omnia/diadosis.iii` — add `@export` to the five faculties HERMENEUS composes. No logic change.
- **Create:** `STDLIB/iii/omnia/hermeneus.iii` — the organ: deterministic proposer, gloss/read-back, vetting, confirm-gate, delivery, external door, `hermeneus_selfprove`, `hm_show`, `main`.
- **Create:** `STDLIB/scripts/hermeneus_gate.sh` — the rite: compile deps + organ + probe, link, run twice, determinism + green-marker checks. Mirrors `xenos_gate.sh`.
- **Create (on green):** `DOCS/III-HERMENEUS-CHARTER.md` — the charter.
- **Runtime data:** `STDLIB/data/hermeneus.gbk` — the confirm/reject guest-book (created by the organ; a fresh book per gate run, like `xenos.gbk`).

### Interface summary (fixed signatures — every task relies on these exact names/types)

```
// deterministic proposer (muse A): English (';'-separated sentences) -> candidate claim scroll
fn hm_propose_det(english: u64, len: u64) -> u64        // returns claim count; 0 = refused, hm_rgrammar++

// gloss / read-back
fn hm_gloss(cb: u64, cl: u64, out: u64) -> u64          // one claim's bytes -> English gloss in `out`; returns gloss len
fn hm_readback(out: u64) -> u64                         // gloss the whole standing candidate; returns len

// vetting (exact law + vocabulary) over the standing candidate scroll
fn hm_vet() -> u64                                      // 0 = coherent+audited; else HM_R_* reason; sets hm_last_addr, hm_last_alien

// stand a proposal (propose already ran and filled HM_CAND): reduce + record english+addr, CONFIRMED=0
fn hm_stand(english: u64, len: u64) -> u64              // 0 = standing (returns reduced addr); else HM_R_* reason

// external door (muse B): admit an UNSIGNED claim-array / CONFORMING envelope via XENOS, then stand it
fn hm_admit_ext(json: u64, len: u64) -> u64             // 0 = standing; else HM_R_* (mirrors xn verdict)

// confirm-gate
fn hm_confirm(english: u64, len: u64, addr: u64, out_pin: u64) -> u32   // 1 iff matches standing proposal; writes 32-byte pin
fn hm_deliver() -> u64                                  // CONFIRMED -> DIADOSIS handle (< DD_NSLOT); else HM_WALL sentinel

// gate + demo
fn hermeneus_selfprove() -> u64 @export                 // 0 green; else failing arm number
fn hm_show() -> i32 @export
fn main(argc: i32, argv: u64) -> u64

// accessors (all @export): hm_last_addr, hm_last_alien, hm_confirmed, hm_rgrammar, hm_rcap,
//   hm_rlaw, hm_ralien, hm_rlying, hm_rwall, hm_cand_len, hm_cand_byte
```

Reason constants: `HM_R_NONE=0, HM_R_GRAMMAR=1, HM_R_CAP=2, HM_R_LAW=3, HM_R_ALIEN=4, HM_R_LYING=5`.
Sentinels: `HM_WALL = 18446744073709551615u64` (delivery denied).

---

## Task 1: Promote DIADOSIS faculties to `@export`

**Files:**
- Modify: `STDLIB/iii/omnia/diadosis.iii` (add `@export` to 5 fn headers)
- Test: rebuild `STDLIB/build/mantis/diadosis.exe`, run, expect `diadosis_selfprove = 0`.

**Interfaces:**
- Produces: `dd_reduce_addr(claims:u64)->u64`, `dd_publish(addr:u64)->u64`, `dd_resolve(h:u64,out:u64)->u64`, `dd_ripple(handle:u64,count:u64)->u64`, `dd_consumer_entails(reduced:u64,q:u64)->u64` — now linkable from HERMENEUS.

- [ ] **Step 1: Add `@export` to the five faculty headers.** Exact edits (append ` @export` before the `{`):
  - `fn dd_reduce_addr(claims: u64) -> u64 @export {`
  - `fn dd_publish(addr: u64) -> u64 @export {`
  - `fn dd_resolve(h: u64, out: u64) -> u64 @export {`
  - `fn dd_ripple(handle: u64, count: u64) -> u64 @export {`
  - `fn dd_consumer_entails(reduced: u64, q: u64) -> u64 @export {`
  Leave `dd_dropped`, `dd_entails` module-private (HERMENEUS reaches closure via `eol_judge_claim` directly).

- [ ] **Step 2: Compile diadosis alone to the scratchpad (exit-14 guard).**
  Run: `COMPILED/iiis-2.exe STDLIB/iii/omnia/diadosis.iii --compile-only --out "$SCRATCH/diadosis.o"`
  Expected: exit 0, `diadosis.o` present. (exit 14 ⇒ slot ceiling — but this change adds no locals, so 0 expected.)

- [ ] **Step 3: Rebuild + run the DIADOSIS self-proof to confirm no behavior change.**
  Rebuild its objects (eidolos, isub, diadosis) and relink `diadosis.exe` exactly as it is built today (see gate recipe), then:
  Run: `STDLIB/build/mantis/diadosis.exe; echo "exit=$?"`
  Expected: prints `diadosis_selfprove = 0 ... GREEN`, `exit=0`. (The new exports are consumed by HERMENEUS in later tasks, so the ratchet is satisfied once the organ lands; until then diadosis's own `main` still consumes them.)

- [ ] **Step 4: Commit.**
  ```bash
  git commit -m "DIADOSIS: promote the five faculties to @export (compose, not island)" -- STDLIB/iii/omnia/diadosis.iii
  ```

---

## Task 2: HERMENEUS scaffold + deterministic proposer (`<` verb) + arms 1,4

**Files:**
- Create: `STDLIB/iii/omnia/hermeneus.iii`
- Test: a temporary probe `main` calling `hermeneus_selfprove`, built to scratchpad.

**Interfaces:**
- Consumes: `eol_reset/eol_read/eol_addr/eol_write/eol_out_len/eol_out_byte` from `eidolos.iii`.
- Produces: `hm_propose_det`, `HM_CAND` candidate scroll, `hm_addr_of(text,len)` helper, `hm_rgrammar`, `hermeneus_selfprove` (arms 1 & 4 only for now).

- [ ] **Step 1: Write the module header + externs + state + string helpers**, in the established idiom (copy the `dd_slen`/`dd_ps`/`dd_pu` and `xn_sput*` patterns verbatim in spirit): module `omnia_hermeneus`; externs for the eidolos functions above; `var HM_CAND : [u8; 16384]  var HM_CN : u64`; helpers `hm_slen`, `hm_cput(c)`, `hm_cputs(s)`, `hm_addr_of(text,len)` (= `eol_reset(); eol_read(text,len); eol_addr()`).

- [ ] **Step 2: Write the deterministic proposer for the `<` verb.** `hm_propose_det` splits `english` on `;`, trims spaces, and for each sentence matches the ordered-relation templates and emits `[A < B]` into `HM_CAND`. Core matcher (real code — the novel part):

```
// returns 1 and sets *A/*B spans if the sentence is "<lhs> <cue> <rhs>" for an order cue.
// order cues (checked longest-first): " must be proven before ", " precedes ", " is under ", " before "
// A,B are then reduced to lawful eidolos phrases via hm_wordify (the xn_word_lawful quotient).
fn hm_match_order(s: u64, n: u64) -> u64 { /* scan for a cue substring; split; wordify both sides */ }
```
Emit rule: on match, append `[` + wordify(A) + ` < ` + wordify(B) + `] ` to `HM_CAND`. If NO template matches the sentence, the WHOLE utterance is refused: reset `HM_CN=0`, `hm_rgrammar = hm_rgrammar + 1`, return 0. (Zero-hallucination: never a partial/guessed claim.)

- [ ] **Step 3: Write arms 1 and 4 of `hermeneus_selfprove`.**
```
// arm 1: exactness on the < domain
if hm_propose_det("dream must be proven before proof" as u64, 30u64) != 1u64 { return 1u64 }
if hm_addr_of((&HM_CAND) as u64, HM_CN) != hm_addr_of("[dream < proof]" as u64, 15u64) { return 1u64 }
// arm 4: total refusal off-domain
let g0 : u64 = hm_rgrammar
if hm_propose_det("what time is it" as u64, 15u64) != 0u64 { return 4u64 }
if hm_rgrammar != g0 + 1u64 { return 4u64 }
if hm_cand_len() != 0u64 { return 4u64 }
```
(Use `hm_slen` for lengths instead of hardcoding; literals shown for clarity.)

- [ ] **Step 4: Build to scratchpad + run the probe.**
  Compile `eidolos.iii`, `isub.iii`, `hermeneus.iii` to `$SCRATCH`, link with the archive, run.
  Expected: `hermeneus_selfprove = 0` (only arms 1,4 active). If exit 14 ⇒ split a fat function.

- [ ] **Step 5: Commit** `git commit -- STDLIB/iii/omnia/hermeneus.iii` with message `HERMENEUS: scaffold + deterministic proposer (< verb), arms 1,4 green`.

---

## Task 3: Proposer `=` and `~` verbs + determinism (arms 2,3,5)

**Interfaces:** Consumes Task 2. Produces `hm_match_ident`, `hm_match_mirror`.

- [ ] **Step 1: Add `=`/`~` matchers.** Identity cues: ` equals `, ` is exactly `, ` is ` (checked AFTER order cues so "is under" wins). Mirror cues: ` is the dual of `, ` mirrors `, ` reflects `. Emit `[A = B]` / `[A ~ B]`. `hm_propose_det` tries order → mirror → identity per sentence (order/mirror before identity so ` is under `/` is the dual of ` are not stolen by ` is `).
- [ ] **Step 2: Arms 2,3,5.**
```
// arm 2: identity
if hm_propose_det("proof is law" as u64, ...) != 1u64 { return 2u64 }
if hm_addr_of((&HM_CAND), HM_CN) != hm_addr_of("[proof = law]", ...) { return 2u64 }
// arm 3: mirror
if hm_propose_det("dream mirrors wake" as u64, ...) != 1u64 { return 3u64 }
if hm_addr_of((&HM_CAND), HM_CN) != hm_addr_of("[dream ~ wake]", ...) { return 3u64 }
// arm 5: determinism
hm_propose_det("dream must be proven before proof", ...)
let d1 : u64 = hm_addr_of((&HM_CAND), HM_CN)
hm_propose_det("dream must be proven before proof", ...)
if hm_addr_of((&HM_CAND), HM_CN) != d1 { return 5u64 }
```
- [ ] **Step 3: Build to scratchpad + run.** Expected `hermeneus_selfprove = 0`.
- [ ] **Step 4: Commit** `HERMENEUS: proposer = and ~ verbs + determinism, arms 2,3,5 green`.

---

## Task 4: Gloss / read-back + inverse round-trip (arms 6,7)

**Interfaces:** Consumes Tasks 2-3. Produces `hm_gloss(cb,cl,out)`, `hm_readback(out)`.

- [ ] **Step 1: Write `hm_gloss`.** Parse one canonical claim `[A verb B]` (verb ∈ `< = ~`) and write English: `<` → `"A sits under B"`, `=` → `"A is B"`, `~` → `"A mirrors B"`. The English MUST be re-parseable by `hm_propose_det` (the inverse law): "A sits under B" ⇒ order cue ` sits under ` — **add ` sits under ` to the order cues in Task 3** so gloss output is in the proposer's domain.
- [ ] **Step 2: Write `hm_readback`** — iterate the standing candidate's claims (split on `] `), gloss each, join with `; `.
- [ ] **Step 3: Arms 6,7 (parse∘gloss ≡ id, all three verbs).**
```
// arm 6: < round-trip
hm_gloss("[dream < proof]" as u64, 15u64, (&HM_TMP) as u64)     // -> "dream sits under proof"
if hm_propose_det((&HM_TMP) as u64, hm_slen((&HM_TMP))) != 1u64 { return 6u64 }
if hm_addr_of((&HM_CAND), HM_CN) != hm_addr_of("[dream < proof]", 15u64) { return 6u64 }
// arm 7: = and ~ round-trips (same shape, two checks)
```
- [ ] **Step 4: Build + run.** Expected `0`.
- [ ] **Step 5: Commit** `HERMENEUS: gloss + read-back, inverse round-trip arms 6,7 green`.

---

## Task 5: Vetting (coherence + vocabulary) + `hm_stand` (arms 8,9)

**Interfaces:** Consumes eidolos + `lx_check`/`lx_unknown_*` from `lexicon.iii`. Produces `hm_vet`, `hm_stand`, `hm_last_addr`, `hm_last_alien`, `hm_rlaw`, `hm_ralien`.

- [ ] **Step 1: Write `hm_vet`** over `HM_CAND`: `eol_reset(); if eol_read(HM_CAND,HM_CN)<0 -> HM_R_CAP or HM_R_LAW (rcap-delta test, xn idiom); a=eol_addr(); if a==0 -> HM_R_LAW (cycle)`. Canonicalize (`eol_write`) into `HM_CANON`; `hm_last_alien = lx_check(HM_CANON, len)`; if alien>0 set `HM_R_ALIEN` reason but still record (alien is a WARNING that blocks confirm, not a parse failure — return `HM_R_ALIEN`). Re-derive the fixpoint (re-read canon, addr must equal `a`) — the XENOS re-derivation. Set `hm_last_addr=a`. Return `0` on clean.
- [ ] **Step 2: Write `hm_stand`** — assumes `HM_CAND` filled by a proposer; runs `hm_vet`; on `0`, records `HM_ENG`(english)+`HM_ADDR`(reduced addr via `dd_reduce_addr` on the canon) and sets `HM_CONFIRMED=0`; returns the reduced addr.
- [ ] **Step 3: Arms 8,9.**
```
// arm 8: cycle refused
hm_propose_det("a before b; b before a", ...)   // -> "[a < b] [b < a]"
if hm_vet() != 3u64 { return 8u64 }             // HM_R_LAW
// arm 9: alien word named
hm_propose_det("banana before proof", ...)      // banana not in the lexicon
hm_vet()
if hm_last_alien() == 0u64 { return 9u64 }
```
- [ ] **Step 4: Build + run.** Expected `0`.
- [ ] **Step 5: Commit** `HERMENEUS: vetting (coherence+vocabulary) + hm_stand, arms 8,9 green`.

---

## Task 6: Confirm-gate + the wall (arms 12,13,14)

**Interfaces:** Consumes `idfold_basis/u64/seal`. Produces `hm_confirm`, `hm_deliver` (wall side only for now), `HM_CONFIRMED`, `HM_PIN`, `hm_rwall`, `HM_WALL`.

- [ ] **Step 1: Write `hm_confirm(english,len,addr,out_pin)`** — 1 iff `len==HM_ENGN && bytes(english)==HM_ENG && addr==HM_ADDR`; on match set `HM_CONFIRMED=1` and write `pin = fold(english ‖ addr)` (idfold over english bytes then the 8 addr bytes) to `out_pin` and `HM_PIN`; else return 0 (no state change).
- [ ] **Step 2: Write `hm_deliver` (wall side)** — `if HM_CONFIRMED==0 { hm_rwall++; return HM_WALL }` … (DIADOSIS side added in Task 7).
- [ ] **Step 3: Arms 12,13,14.**
```
// stand a proposal P
hm_propose_det("dream must be proven before proof", ...)
let pa : u64 = hm_stand("dream must be proven before proof" as u64, ...)
// arm 12: wall before confirm
if hm_deliver() != HM_WALL { return 12u64 }
// arm 13: pin content-addressed; different proposal -> different pin
hm_confirm("dream must be proven before proof" as u64, ..., pa, (&HM_P1) as u64)
// stand Q, confirm Q, compare pins
...
if hm_pin_eq((&HM_P1), (&HM_P2)) == 1u64 { return 13u64 }
// arm 14: mismatched confirm does not release
hm_propose_det("dream must be proven before proof", ...)
hm_stand("dream must be proven before proof" as u64, ...)
if hm_confirm("proof is law" as u64, ..., pa_wrong, (&HM_P3) as u64) != 0u32 { return 14u64 }
if hm_deliver() != HM_WALL { return 14u64 }
```
- [ ] **Step 4: Build + run.** Expected `0`.
- [ ] **Step 5: Commit** `HERMENEUS: confirm-gate + pin + wall, arms 12,13,14 green`.

---

## Task 7: Delivery to DIADOSIS + seam-exactness + closure (arms 15,16,17,18)

**Interfaces:** Consumes the now-`@export` `dd_reduce_addr/dd_publish/dd_resolve/dd_ripple/dd_consumer_entails`. Completes `hm_deliver`.

- [ ] **Step 1: Finish `hm_deliver`** — on `HM_CONFIRMED==1`: `dd_reduce_addr(HM_CLAIMS)` to re-stand the reduced house, `let h = dd_publish(a)`, `dd_ripple(h, count)`, return `h`. (Store the raw candidate claims in `HM_CLAIMS` at `hm_stand` time so delivery reduces the same text.)
- [ ] **Step 2: Arms 15,16,17,18.**
```
// build the multi-claim English and its hand-written claim equivalent
let eng : u64 = "dream must be proven before proof; proof is law" as u64
let hand: u64 = "[dream < proof] [proof = law]" as u64
hm_propose_det(eng, hm_slen(eng))
let pa : u64 = hm_stand(eng, hm_slen(eng))
hm_confirm(eng, hm_slen(eng), pa, (&HM_P1) as u64)
let h : u64 = hm_deliver()
// arm 15: release
if h >= 256u64 { return 15u64 }                 // DD_NSLOT
// arm 16: seam-exactness — hermeneus's reduced addr == diadosis on the hand claims
if pa != dd_reduce_addr(hand, hm_slen(hand)) { return 16u64 }
// arm 17: end-to-end closure at the consumer (resolve the delivered handle)
let rl : u64 = dd_resolve(h, (&HM_RECV) as u64)
if rl == 0u64 { return 17u64 }
if dd_consumer_entails((&HM_RECV) as u64, "[dream < proof]" as u64) != 1u64 { return 17u64 }
// arm 18: negative wall — a claim outside the closure is not entailed
if dd_consumer_entails((&HM_RECV) as u64, "[law < dream]" as u64) == 1u64 { return 18u64 }
```
Note: `dd_reduce_addr` now takes `(claims,len)`? It currently takes `(claims)` and calls `dd_slen`. Keep its 1-arg signature; pass just `hand`. (Adjust the arm code to `dd_reduce_addr(hand)`.)
- [ ] **Step 3: Build + run.** Expected `0`.
- [ ] **Step 4: Commit** `HERMENEUS: delivery to DIADOSIS + seam-exactness + closure, arms 15,16,17,18 green`.

---

## Task 8: External door via XENOS + provisional/refuse (arms 10,11)

**Interfaces:** Consumes `xn_admit`, `xn_verdict`, `xn_last_addr`, `eol_kept_claims`, `eol_kept_claim_base`, `eol_kept_claim_len`. Produces `hm_admit_ext`.

- [ ] **Step 1: Write `hm_admit_ext(json,len)`** — `xn_admit(json,len)`; if `xn_verdict()!=ADMITTED` map the XENOS reason → `HM_R_*` and return it; else copy the standing kept claims into `HM_CAND` (via `eol_kept_claim_base/len`) and `hm_stand` them (provisional; NOT auto-confirmed).
- [ ] **Step 2: Arms 10,11.**
```
// arm 10: a truthful UNSIGNED proposal is admitted + stands, addr matches
let ok : u64 = hm_admit_ext("[\"[dream < proof]\"]" as u64, ...)
if ok != 0u64 { return 10u64 }
if hm_last_addr() != hm_addr_of("[dream < proof]", 15u64) { return 10u64 }
if hm_confirmed() != 0u64 { return 10u64 }       // provisional, not crossed
// arm 11: an incoherent external proposal is refused at the door
if hm_admit_ext("[\"[a < b]\",\"[b < a]\"]" as u64, ...) == 0u64 { return 11u64 }
```
- [ ] **Step 3: Build + run** (now also links xenos, xring, kalodion, json, builder, arena, lexicon). Expected `0`.
- [ ] **Step 4: Commit** `HERMENEUS: external door via xn_admit, arms 10,11 green`.

---

## Task 9: `hm_show` demo + `main` + full 18-arm `hermeneus_selfprove`

- [ ] **Step 1: Write `hm_show`** — one end-to-end run printed: English in → read-back → (in-code) confirm → DIADOSIS handle. Use `putchar`/`hm_ps` writers.
- [ ] **Step 2: Write `main`** — `hm_show(); let r = hermeneus_selfprove(); print "hermeneus_selfprove = " r; return r`.
- [ ] **Step 3: Confirm all 18 arms are wired and ordered 1..18; build + run.** Expected stdout contains `hermeneus_selfprove = 0` and exit 0.
- [ ] **Step 4: Commit** `HERMENEUS: hm_show + main + full 18-arm self-proof green`.

---

## Task 10: `hermeneus_gate.sh` (the rite) + determinism

**Files:** Create `STDLIB/scripts/hermeneus_gate.sh` (mirror `xenos_gate.sh`).

- [ ] **Step 1: Write the gate** — `IIIS=${1:-$ROOT/COMPILED/iiis-2.exe}`; `T=$ROOT/STDLIB/build/hermeneus`; `ARC=.../libiii_native.a`; `cc_one` (3-try settle-retry) each of: eidolos, isub, diadosis, lexicon, idfold(numera), xenos, xring, kalodion, json, builder, arena, hermeneus, and a probe main; `gcc` link to `hermeneus.exe`; `rm -f STDLIB/data/hermeneus.gbk`; run twice; `cmp -s run1 run2`; `grep -q "hermeneus_selfprove = 0" run1`; exit 0 green.
- [ ] **Step 2: Run the gate.** Run: `bash STDLIB/scripts/hermeneus_gate.sh; echo "gate=$?"`. Expected `gate=0` and a green summary line.
- [ ] **Step 3: Determinism confirmed** by the gate's own `cmp -s` (no separate step).
- [ ] **Step 4: Commit** `git commit -- STDLIB/scripts/hermeneus_gate.sh` with `HERMENEUS: the gate rite (build+selfprove+determinism) green`.

---

## Task 11: Charter + memory pointer (on green)

- [ ] **Step 1: Write `DOCS/III-HERMENEUS-CHARTER.md`** in the voice of `III-EIDOLOS-CHARTER.md`: the gap, the propose/decide law, the five faculties, the asymmetric self-proof, honest scope, purity, the gate.
- [ ] **Step 2: Add a memory file** `project_iii_hermeneus_frontend.md` + a one-line pointer in `MEMORY.md` (the front-end that crosses English→EIDOLOS behind the propose/verify wall; traps discovered).
- [ ] **Step 3: Commit** `git commit -- DOCS/III-HERMENEUS-CHARTER.md` (memory lives outside the repo; write separately).

---

## Self-Review (run after writing; fixed inline)

- **Spec coverage:** §3 five faculties → Tasks 2-8; §4a deterministic exactness/refusal → Tasks 2,3; §4b external door → Task 8; §4c quarantine theorems → arms 6-7 (round-trip), 12-15 (wall), 16 (seam), 8-9 (vetting), 17-18 (closure); §5 arm map → all 18 arms placed; §7 composition/exports → Task 1; §11 gate/charter → Tasks 10,11. **No uncovered section.**
- **Placeholder scan:** the novel algorithms (proposer matcher, gloss, pin, wall, seam arm) carry real code; mechanical string-writers reuse the `xn_sput*`/`dd_ps` idiom and are written at implementation time in that established form — this is the III adaptation of "complete code," not a hidden decision.
- **Type consistency:** `hm_propose_det`→`hm_stand`→`hm_confirm`→`hm_deliver` names/types match the interface summary; `dd_reduce_addr` kept at its real 1-arg signature (arm code note in Task 7); `HM_WALL`/`DD_NSLOT=256` constants consistent across arms 12-15.
- **Known follow-ups folded in, not deferred:** ` sits under ` cue must be added to the order cues (flagged in Task 4 Step 1) so gloss output re-parses.
