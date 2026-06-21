# III — Authoring a Component Perfectly Into the System
### The complete procedure, anatomy, and capability surface for an inverse-substrate organ
> **Date:** 2026-06-20 · **Author pass:** /deep-think · /architect · advisor-reviewed
> **Grounded in:** `omnia/event_substrate.iii`, `omnia/isub.iii`, `corpus/1913_isub_cav.iii`,
> `scripts/build_stdlib.sh`, `scripts/run_corpus.sh` (read top-to-bottom, not recall).
> **Companion docs:** `III-EVENT-SUBSTRATE.md` · `III-DOME.md` · `III-INVERSE-LIBRARY.md` · `III-TRAJECTORY-AUDIT.md`.

---

## 0. WHAT "PERFECTLY" MEANS — the discipline, not the syntax

A component is **in the system perfectly** iff it satisfies, simultaneously, the **three acceptance
laws** and was *driven there* by the **control invariant**. Syntax is the easy 10%; these are the 90%.

### 0.1 The three acceptance laws (all three, or it is not in)
From `III-INVERSE-LIBRARY.md §1` — every prior failure held at most two of these:

| Law | Means | The failure if absent |
|-----|-------|-----------------------|
| **(A) Breadth / WIRED** | Registered in `build_stdlib.sh` `MODULES` **and** consumed by a real corpus KAT. | *Loose-organ / island* (`dome`/`logos` were unsealed, unwired). |
| **(B) Inverse FORM** | State is a **pure fold over ONE append-only, witnessed, reversible log**. No stored mutable state cell as the source of truth. | *Wrong form* — `logos.iii` mutated arrays, no event-log/witness/fold/rewind (the insidious one). |
| **(C) REALNESS** | The fold witnesses a **real execution** (a real `xii_rewrite`, a real `cad` sha256), survives adversarial refutation, is sealed. | *Toy-oracle* — `1903/1904/1905` folded hand-authored integers and typed the answer in; the "theorem" was **retracted**. |

The trap behind all of them (`§1` meta): **the fold does not compute the answer** — the real faculty
does; the fold *witnesses* it. So "prove `fold == faculty_answer`" is a near-tautology. The worth is the
**capability** (reversible provenance + time-travel + tamper-evidence over a real run), never the witness
as headline.

### 0.2 The control invariant (the backbone of this whole document)
`III-INVERSE-LIBRARY.md §8` — memorize this; the rest of the guide hangs off it:

```
read → RED-probe → implement-to-GREEN → adversarially refute → seal+wire → reseal+regress → commit
```

Two hard rules:
- **No `.iii` / `.sh` edit before the read + RED-probe for that unit.** (The CRASH-DEBUGGING-PROTOCOL
  spirit: all reading before any writing.)
- **No "done" before** refutation-survived **+** `FAIL = 0` **+** RUNNING-after (the exe still runs).

---

## 1. ANATOMY OF A COMPONENT — every part, and what it is for

A component is two files: the **organ** (`STDLIB/iii/<subsphere>/<name>.iii`) and at least one **KAT**
(`STDLIB/corpus/<NNNN>_<name>.iii`). The organ is the capability; the KAT is the proof.

### 1.1 The organ file, part by part (model: `omnia/event_substrate.iii`, `omnia/isub.iii`)

```iii
/* <ABSOLUTE PATH>
 *
 * III STDLIB - <subsphere>::<name>  --  <ONE-LINE THESIS>.
 *
 * <The ontology paragraph: WHAT this organ IS, in inverse-form terms — what is the EVENT,
 *  what is the FOLD, what is witnessed, what is reversible. State the Hexad, Ring, K, NIH.>
 */
module <subsphere>_<name>                         /* <-- path slash becomes underscore */

/* externs: every foreign symbol, by BASENAME of the defining .iii (not the subsphere path) */
extern @abi(c-msvc-x64) fn xc_begin() -> i32 from "exec_cert.iii"
extern @abi(c-msvc-x64) fn malloc(n: u64) -> *u8 from "msvcrt"

const CAP    : u32 = 512u32                        /* fixed capacities; no dynamic growth in the log */
const V_BELOW: u32 = 0u32

/* module-scope state ONLY — the append-only log + its memos (W4: NO fn-local `var` arrays) */
var LOG_VERB : [u32; 512]
var LOG_COUNT: u32 = 0u32
var ROOT     : [u8; 32]                            /* the frozen O(32) witness memo */

fn <name>_reset() -> i32 @export { LOG_COUNT = 0u32  return 0i32 }   /* genesis */

/* THE ONLY MUTATOR: the world grows only by appending a perceived event. */
fn <name>_emit(verb: u32, a: u32, b: u32) -> u64 @export {
    /* 1. GATE first (reject structurally-illegal input — name-in-verb-slot, out-of-range operand) */
    /* 2. append the uniform block + bump the logical tick                                        */
    /* 3. commit the content-address + fold it into the witness chain                             */
    return tick
}

/* PURE FOLDS (the read side): a fixed function of a prefix [0,upto). NEVER counting-to-adapt. */
fn <name>_view(upto: u32) -> u64 @export { /* fold ... */ return value }
```

The named parts and their contract:

| Part | Form | Contract / capability |
|------|------|-----------------------|
| **Header ontology** | block comment | Declares WHAT it IS (inverse-form), Hexad / Ring / K / NIH. Read by humans + the structural audits. |
| `module <subsphere>_<name>` | one line | The module identity. **Slash → underscore.** |
| **externs** | `extern @abi(c-msvc-x64) fn f(..) -> T from "<basename>.iii"` | Foreign organ calls, resolved through the archive symbol index. `from "msvcrt"` for libc (`malloc`/`free`). Basename only — *not* `omnia/exec_cert.iii`, just `exec_cert.iii`. |
| **`const`** | `const N : u32 = 512u32` | Module-LOCAL (two modules may share a const name and link cleanly). Capacities, verb codes, sentinels. |
| **module-scope `var`** | `var LOG : [u64; 256]` / `var C : u32 = 0u32` | The append-only log + memos. **MANDATORY at module scope** — a function-local `var [T;N]` indexed by a runtime/loop var segfaults (hoist to module scope; "W4"). |
| **the only mutator** | `fn ..._emit/perceive(..) @export` | The single writer. Gate → append → commit content-address → fold the witness chain. Append-only, **erase nothing**. |
| **pure folds** | `fn ..._view(upto) @export` | The read side (CQRS). A fixed pure function of a prefix — same history ⇒ same answer (replayable, reversible). |
| **`@export`** | suffix on `fn` | Makes the symbol visible to other modules + KATs. Omit it for a file-local helper (e.g. `isub_footprint` is internal). A **duplicate** `@export` symbol across modules is a link bomb the cartographer gate rejects. |
| **the witness** | `cad`/`exec_cert` sha256, or a poly rolling hash | The integrity check. For **security-grade** assurance it MUST be `cad` sha256 (collision-resistant); a multiply-add/FNV hash gives tamper-*detection* only, never *resistance*. |

### 1.2 The naming map — get one wrong and the link silently breaks
For an organ at path `STDLIB/iii/omnia/event_substrate.iii`:

```
file path            STDLIB/iii/omnia/event_substrate.iii
MODULES entry        "omnia/event_substrate"               (subsphere/leaf, slash)
module declaration   module omnia_event_substrate          (slash -> underscore)
compiled object      build/iii/omnia_event_substrate.iii.o (${mod//\//_}.iii.o)
extern reference      from "event_substrate.iii"            (leaf basename ONLY)
```

The object filename is namespaced by replacing `/` with `_` so two leaves with the same name
(`sanctus/resolver_replay` vs `omnia/resolver_replay`) don't overwrite each other and collide under
`--whole-archive`.

### 1.3 The iiis-2 language surface you actually use
- **Types:** `u8 u16 u32 u64 i32 i64`, raw pointers `*u8`, fixed arrays `[T; N]`.
- **Literals are typed:** `0u32`, `1u64`, `0i32`, `0xFFFFFFFFu32`, `14695981039346656037u64`. Array
  indices are typed too: `LOG[0u64]`, `IS_CAV[base + c]`.
- **Casts:** `(a & 0xFFu32) as u8`, `IS_FP[k] as u32`, `m as u64`.
- **Statements:** `let x : T = ...`, `let mut x : T = ...`, `while cond { }`, `if cond { } else { }`,
  `return v`. No `for`. Build loops with `while` + an explicit index.
- **Functions:** `fn f(p: T, q: T) -> R { }`; `@export` to publish; multi-line declarations are fine.
- **`main` in a KAT:** `fn main() -> u64 { ... return 99u64 }`. **The process exit code is 8-bit**
  (`code & 0xFF`) — keep every assertion code `< 256`.

### 1.4 The compiler-trap status (accurate — do not over-warn)
Per `~/.claude/CLAUDE.md`: the long historical `.iii` trap list (signed-ordering SIGSEGV, u32-store-width,
module-const-global, nested comments, local arrays, multi-line fns, em-dash comments) is **RESOLVED in the
mature self-hosted `iiis-2`** — "write `.iii` freely; the avoidance dance is no longer needed." The live
discipline is the inverse: **if a `.iii` change misbehaves, re-test the minimal pattern through `iiis-2`
*before* blaming the compiler** — at this maturity the bug is almost always in your code. The genuinely
live cautions are only:
- **Module-scope state (W4):** no function-local `var [T;N]` indexed by a runtime var — segfault. Hoist
  to module scope (you see this in every organ).
- **`replace_all` double-application** (an Edit-tool note, not a compiler bug): if `new_string` contains
  `old_string` as a substring, re-running doubles the prefix (`AETHER_AETHER_HTTP_OK`). Do related subs
  in one Edit, or write the file from scratch.
- **8-bit exit codes** (above): a `271u64` truncates to `15`.
- **Collision-free prefix:** pick a fresh `xxx_` symbol prefix and verify with `nm` against
  `libiii_native.a` **before** seal (`es_` was already taken by erasure-shard → renamed to `evt_`).

---

## 2. THE CONFIGURATION & ITS CAPABILITIES — what the parts can DO

This is the "everything its parts are capable of" half. The inverse form is what *unlocks* each
capability; they are all consequences of "EVENT primary, STATE = fold."

### 2.1 `omnia::event_substrate` — the single inverted fold
The atom: a perceived `(tick, observer, kind, priority, payload)` on an append-only log; state is a fold.

| Primitive | Capability |
|-----------|------------|
| `evt_perceive(observer,kind,priority,payload) -> tick` | The **only** mutator. The world grows only by perceiving. |
| `evt_maxprio / evt_winner / evt_maxprio_moves / evt_winner_moves / evt_observe_count` | **FINITE folds** over a prefix `[0,upto)` — a winner decided by *what recurs in the observed history*, not an instantaneous number. |
| `evt_witness(upto)` | Replayable digest: same history ⇒ same root; any change ⇒ changed root. |
| `evt_find_payload / evt_detect_cycle / evt_mark_cycle / evt_cycle_start` | **Lasso detection** — finds the first payload (game position / rewrite term) that *recurs*, setting the cycle `[first, here)`. Found, not assumed. |
| `evt_inf_maxprio / evt_inf_winner` | **INFINITARY fold** — the parity-acceptance condition over `stem·cycle^ω`: parity of the max priority *in the cycle* (transients drop out). This *is* the parity-game winner. |

**Capability headline:** deterministic, witnessed, reversible state derived purely from a history — and a
finite mechanism that decides an *infinitary* (eventually-periodic) acceptance condition.

### 2.2 `omnia::dome` — the society (four mutually-dependent twins)
Four event-primary twins on **one** witnessed history; remove any one and the loop cannot close.

| Twin | State-primary original | Inverse role |
|------|------------------------|--------------|
| **EYE** | cad / witness | perceives, gives identity + witness |
| **WAVE** | ripple / forcefield | emits the consequence-wave (butterfly carrier) |
| **ECHO** | nous (proposer) | folds the lesson-history to (re-)choose |
| **TIDE** | reversibility / snapshot | marks branch-points, **rewinds**, retains the abandoned branch |

| Primitive | Capability |
|-----------|------------|
| `dome_emit(participant,kind,value,payload) -> tick` | The only mutator; append-only, never erased. |
| `dome_mark() -> bp` / `dome_rewind(bp)` | A branch-point and a rewind that **records the abandoned span and erases nothing** — branching, not truncation. |
| `dome_abandoned(i) / dome_provenance_count()` | The debug trail — which events are retained provenance of a failed branch. |
| `dome_active_max(p) / dome_active_parity(p)` | The **live fold** — skips abandoned branches. |
| `dome_recurred(p,payload,upto)` | The lasso: a consequence closing on itself. |
| `dome_live_kind_count(p,kind)` | Retained lessons that inform a re-choice. |
| `dome_witness()` | Root over **all** events, provenance included. |

**Capability headline — evasion-by-living:** choose the tempting move, *live* its consequence (the ripple
recurs), observe it is bad, **rewind**, re-choose from the retained lesson — keeping the failed branch as
witnessed provenance. A determinist (a `state→choice` function) structurally cannot: it never sees the
recurrence and cannot undo the commit. **NOT observational learning** — every fold is fixed; a re-choice
differs only because the lesson is now a recorded event the fold replays.

### 2.3 `omnia::isub` — the Content-Addressed metal bus (Ring -1 bedrock)
The uniform block `<verb ∈ {V_BELOW=0, V_REFLECT=1}, a, b>`. **No name/string field exists in the log.**

| Primitive | Capability |
|-----------|------------|
| `isub_legal_verb(v)` / the gate in `isub_emit` | **The name-gate, at the metal:** a name packed into the verb slot is a large integer (`> 1`) → structurally rejected (`return 0`, bus unchanged). "No named primitives" enforced, not by convention. |
| `isub_emit(verb,a,b) -> tick` | The only mutator: gate → append → **commit `CAV_i = sha256(footprint_i)`** as the block's identity → fold `ROOT = sha256(ROOT_prev ‖ CAV_i)`. |
| `isub_cav_into(verb,a,b,out)` | Pure helper — same hash the emit path commits; lets a caller verify *stored == computed*. |
| `isub_event_cav_into(i,out)` | Reads the **stored** identity bytes (does not recompute) — proving the CAV is constitutive. |
| `isub_witness_into(out)` | The `ROOT` — a transparency-log / Merkle chain over geometric content-addresses. |

**Capability headline:** identity **is** the hash of geometry (not a label); the witness **is** the chain
of identities (delete the CAV and the root cannot form); identical geometry → identical CAV → automatic
**recognize-and-merge** dedup. O(1)/event (two fixed-size sha256), O(32) memo.

### 2.4 The phased family — what composing these organs builds (`III-INVERSE-LIBRARY.md §4`)
Each is a real, sealed, KAT-green organ; together they are the Master-Logic library:

1. **`xii_isub` (Phase 1, KAT 1914)** — *encapsulate a real faculty.* Drives the **real** `xii_rewrite` to
   fixpoint, emits each firing as a `BELOW` step, recovers "current term" as a pure fold, and gives
   **time-travel** (`xii_isub_prefix`) the mutating form discards. The pattern for wrapping *any* faculty.
2. **`unravel` (Phase 2, KAT 1915)** — *prove geometry from the witness.* Strips a real trace to
   height/is_chain/has_lasso/bottom + synthesizes a verb (REDUCE/RECUR/IDENTITY/REFLECT) per transition —
   proving III's rewriting is a terminating strict descent, no black box surviving.
3. **`assimilate` (Phase 3, KAT 1916)** — *one executable web.* Shatters multiple logic systems to uniform
   blocks, merges by content-address (30 naive blocks → 18; zero redundancy); `assim_meet/join/complement`
   recovered from geometry compute every system's logic.
4. **`reverse_search` (Phase 4, KAT 1917)** — *the Dome's ECHO/TIDE over the web.* Evade-by-living on a real
   involution; records **anti-geometry** that **persists** → a later search past the same cliff climbs
   immediately (gets smarter; still not observational learning — the trap is a recorded fact replayed).
5. **`master_logic` (Phase 5, KAT 1918)** — *subsume a named primitive.* Takes real `logic6` as a black
   box, derives the order from `l6_and` (no logic as gospel), proves the web's verbs reproduce it over all
   values, and `ml_named_is_redundant` is the **sovereign in-III gate** that certifies a name is provably a
   geometric fold — the rigorous justification for deprecation-by-attrition.

### 2.5 The four structural/trajectory audits (`III-INVERSE-LIBRARY.md §9`)
For a substrate whose value is geometry/provenance/density, a destination KAT is insufficient. These four
prove the *assimilation* succeeded (all EXIT 99 vs the sealed archive):
- **1919 Topographic Collapse** — BLOAT 30 blocks vs DENSITY 18 = 12 duplicates vaporized.
- **1920 Nameless Shadow Race** — a compound over all 216 triples, `f_legacy` (named) vs `f_nameless`
  (only `assim_*`), bit-identical; namelessness is *structural* (zero `l6_*` calls).
- **1921 Universal Isomorphism** — De Morgan + involution hold across every domain *and cross-domain* via
  the same verbs (a law proven in System A *is* the proof in System Z).
- **1922 Evasion of the Void** — the diamond has no self-complementary point (a real residual gap); the
  web bridges to Kleene's middle `6` cross-domain. Teeth: naive iteration still loops.

### 2.6 The Trajectory Audit — how an inverse component is *assured* (`III-TRAJECTORY-AUDIT.md`)
For inverse-form modules, assert the **geometry of execution**, not `exit == 42`:

| TA | Asserts |
|----|---------|
| **A. Provenance** | the system BLED — identified a catastrophe, rewound, abandoned a branch. |
| **B. Shadow Race** | same volatile stream to BOTH twins; the **asymmetry of survival** (A FATAL, B ALIVE), never a numeric equality. |
| **C. Lasso Resonance** | the topology: a consequence closed on itself AND the lived outcome differs from the immediate temptation. |
| **Divergence Signature** | the witnessed evasion **differs from the classical deterministic witness** AND is **backed by provenance** — a proven evasion the determinist could not find. |

And the honest security split (`§3`): tamper-**DETECTION** holds for any avalanching witness (incl. a
multiply-add/FNV hash); adversarial **RESISTANCE** (no forgeable colliding history) holds **only** with a
collision-resistant witness — III's real **`cad` sha256**, never FNV. *Calling an FNV witness "secure" is
the over-claim that got §3 retracted.*

---

## 3. THE PROCEDURE — the control invariant, fully mechanized

### Step 1 — READ (no edits yet)
Read every file in the change's blast radius **completely**: the organ you'll add, the organs it externs,
the KAT model closest to yours, and the two scripts. Confirm the symbol prefix is collision-free
(`nm build/iii/libiii_native.a | grep <prefix>` must be empty).

### Step 2 — RED-probe (write the KAT FIRST; prove it fails the right way)
Author `STDLIB/corpus/<NNNN>_<name>.iii` (template in §5.2) **before** the organ, or against a
deliberately-broken organ. It must compile and **fail at the exact assertion** that proves the capability
is absent — a negative you can point to. (Never accept an auto-generated stub; prove the guard *fails* on
bad input, not just passes on good.)

### Step 3 — implement-to-GREEN
Write the organ (template in §5.1). Inverse form (B): a single append-only log + pure folds. Realness (C):
the fold witnesses a **real** execution — never hand-authored integers with the answer typed in. Drive the
KAT to `EXIT 99`.

In-session fast-verify (the env's full build flakes — see §4.4):
```bash
IIIS=../COMPILED/iiis-2.exe
"$IIIS" iii/omnia/<name>.iii        --compile-only --out build/iii/omnia_<name>.iii.o
"$IIIS" corpus/<NNNN>_<name>.iii    --compile-only --out build/corpus/<NNNN>.o
ar d  build/iii/libiii_native.a omnia_<name>.iii.o 2>/dev/null   # drop any stale member
ar qcD build/iii/libiii_native.a build/iii/omnia_<name>.iii.o
ar sD build/iii/libiii_native.a
gcc build/corpus/<NNNN>.o -Wl,--whole-archive build/iii/libiii_native.a -Wl,--no-whole-archive \
    -lws2_32 -lkernel32 -o build/corpus/<NNNN>.exe
timeout 25 ./build/corpus/<NNNN>.exe ; echo "exit=$?"     # want 99
```

### Step 4 — adversarially refute (teeth — `/math-olympiad` discipline)
Build a **variant with the defense disabled** (e.g. rewind → no-op; name-gate removed) and prove the same
KAT now **fails at exactly the evasion assertion**. This proves the mechanism is load-bearing — not luck,
not a dominating alternative. *No teeth, no claim.* (`1913` does this: name-gate disabled → EXIT 11.)

### Step 5 — seal + wire
- **Wire (law A):** add the `MODULES` entry in `build_stdlib.sh` and the `EXPECTED` entry in
  `run_corpus.sh` (§4.1, §4.2). An organ in neither is an island; a conformance KAT with no `EXPECTED`
  entry makes `run_corpus.sh` **hard-error (exit 3)**.
- **Seal:** aggregate into `libiii_native.a` (full build, or the surgical `ar` path of §4.4).

### Step 6 — reseal + regress
Re-run the corpus (or the targeted consumer set) and confirm **no regression** — your new green KAT plus
every consumer of any organ you touched still `= 99`. Capture `PASS/FAIL` + `mhash`.

### Step 7 — commit
Only after refutation-survived + `FAIL = 0` + the exe still RUNs. Commit message ends with the
`Co-Authored-By` trailer. Branch first if on `main`.

---

## 4. EXACT SEAL & GATE MECHANICS

### 4.1 Register the organ in `build_stdlib.sh` `MODULES`
`MODULES` is an ordered bash array of `"subsphere/leaf"` in **dependency order**. A new inverse-substrate
organ is **compiler-unreferenced** (nothing in the compiler's own link closure calls it; only KATs do), so
**append it at the END** with a comment block — exactly as `isub`/`xii_isub`/… are:

```bash
    # <name>: <one-line role>.  <what it externs / what KAT consumes it> --
    # BSS-neutral, compiler-unreferenced.  <DOCS pointer>.
    "omnia/<name>"
```

**Why the end:** appending preserves the **BSS layout** of every pre-existing module (some crypto modules
have latent layout sensitivities). "Compiler-unreferenced → LIBNATIVE" means it lives only in the static
archive, linked into KATs, never into the compiler binary.

### 4.2 Register the KAT in `run_corpus.sh` `EXPECTED`
```bash
declare -A EXPECTED=(
    [<NNNN>_<name>]=99
    ...
)
```
- Numbering: **1900s** = inverse-substrate family. `280–372` is the **XII corpus** (owned by
  `run_xii_corpus.sh` — do not double-judge). `237/242/243/244/990/991/992` are **benches** (owned by
  `run_bench_corpus.sh`). A normal conformance KAT must be outside those ranges and carry an `EXPECTED`
  entry. Missing entry ⇒ `FATAL exit 3`.
- `*_neg_*` / `*_neg` names are classified by compile rc (non-zero = correctly rejected = PASS); they carry
  no `EXPECTED` entry.

### 4.3 The compile → aggregate → mhash pipeline (what `build_stdlib.sh` does)
1. **Pre-compile gate gauntlet** (read-only, zero seal impact): composition / SVM-layout / cycle-family /
   census / bar-layout / vmexit / ring-lattice drift checks; reject-conformance; **Forge closure meta-gate
   (`forge_check.sh`)**; trusted-base seal; **cartographer architectural gate** (no new dependency cycle,
   no duplicate `@export` — intentional exceptions in `III-CARTOGRAPHER/gate_allow.json`).
2. **Per-module compile:** `"$IIIS" "$src" --compile-only --out "$obj"` with `IIIS` pinned to the in-tree
   `COMPILED/iiis-2.exe` (auto-picking a stale external `iiis` is a determinism violation). Output:
   `build/iii/<underscored>.iii.o`. `FAIL` counts failures; a non-zero `FAIL` **aborts the aggregate**
   (so a broken module can leave a *stale* `.a` — always grep `FAIL = 0`).
3. **Aggregate (deterministic):** delete the `.a` fresh, then
   `printf '%s\0' "${OBJS[@]}" | xargs -0 ar qcD libiii_native.a` then `ar sD libiii_native.a`
   (`q`=quick-append, `c`=create, `D`=deterministic zeroed headers, `s`=build index). **Member order =
   `MODULES` order**, which is what makes the archive byte-deterministic.
4. **mhash:** `sha256sum libiii_native.a > libiii_native.a.mhash` — the seal fingerprint.

### 4.4 The honest reseal caveat (no green-washing)
The **canonical** determinism reseal is a clean full `build_stdlib.sh`, but in this environment it **hangs
at `forge_check`** (a known env issue — the seal itself is intact; gens pass standalone). So a new organ is
**functionally sealed via surgical `ar`** (delete-old-member + add + reindex; verify exactly one member
with `ar t`). A clean full rebuild re-aggregates in `MODULES` order — a **byte-different member order**, so
the surgical archive's `mhash` is *not* the canonical full-rebuild's. **State this explicitly** when
reporting a seal; do not present the surgical hash as the canonical one. The canonical reseal is a stated
pending step, run at a clean-build moment.

### 4.5 The corpus link line (what `run_corpus.sh` does per KAT)
```
"$IIIS" "$src" --compile-only --out "$obj"                       # compile the KAT
gcc "$obj" -Wl,--whole-archive "${SIDE_EFFECT_OBJS[@]}" \        # force-link registration-only modules
           -Wl,--no-whole-archive "$LIB_ARCHIVE" \               # normal-link the rest (pull dep closure)
           -lws2_32 -lkernel32 -o "$exe"
cp "$exe" /tmp/run_$$_$RANDOM ; /tmp/...                          # stage to /tmp (Defender path policy)
actual=$? ; [[ "$actual" == "${EXPECTED[$base]}" ]] && PASS
```
**Selective `--whole-archive`** is deliberate: blanket force-linking pulled `witness_hook`'s ~1.38 GiB BSS
into every exe and blew the loadable-image limit. Only side-effect/registration-only modules are
force-linked; everything else (your organ included) enters an exe **only if that exe references it** — so a
KAT must `extern` every organ symbol it uses (the dependency closure is what gets linked).

---

## 5. TEMPLATES (copy-ready skeletons)

### 5.1 Organ skeleton — an inverse-form fold over a witnessed log
```iii
/* C:\...\STDLIB\iii\omnia\foo.iii
 *
 * III STDLIB - omnia::foo  --  <one-line thesis>.  The EVENT is primary; STATE is a pure FOLD over an
 * append-only witnessed log; reversibility = a prefix query; the witness = a tamper-evident chain.
 * Ring R0.  K 1.00 (pure functions of one log).  NIH: libc only, zero externs beyond the sealed witness.
 */
module omnia_foo

extern @abi(c-msvc-x64) fn xc_begin() -> i32 from "exec_cert.iii"
extern @abi(c-msvc-x64) fn xc_event_byte(b: u32) -> i32 from "exec_cert.iii"
extern @abi(c-msvc-x64) fn xc_seal(out_32: *u8) -> i32 from "exec_cert.iii"

const FOO_CAP : u32 = 256u32

var FOO_A    : [u64; 256]
var FOO_B    : [u64; 256]
var FOO_COUNT: u32 = 0u32
var FOO_CLOCK: u64 = 0u64

fn foo_reset() -> i32 @export { FOO_COUNT = 0u32  FOO_CLOCK = 0u64  return 0i32 }

/* THE ONLY MUTATOR — gate first, then append. */
fn foo_emit(a: u64, b: u64) -> u64 @export {
    if FOO_COUNT >= FOO_CAP { return 0u64 }            /* bounded log */
    let i : u32 = FOO_COUNT
    let t : u64 = FOO_CLOCK + 1u64
    FOO_A[i] = a   FOO_B[i] = b
    FOO_COUNT = i + 1u32   FOO_CLOCK = t
    return t
}

fn foo_count() -> u32 @export { return FOO_COUNT }

/* PURE FOLD over a prefix [0,upto). */
fn foo_view(upto: u32) -> u64 @export {
    let mut acc : u64 = 0u64
    let mut i : u32 = 0u32
    while i < upto {
        if i < FOO_COUNT { acc = acc + FOO_A[i] }      /* replace with the real fold law */
        i = i + 1u32
    }
    return acc
}
```

### 5.2 KAT skeleton — RED-probe + GREEN + teeth (model: `1913_isub_cav.iii`)
```iii
/* <NNNN>_foo.iii -- prove omnia::foo's capability with teeth.
 *   code 11 RED-PROBE : an illegal input was accepted (the gate did not fire)   -> FAIL
 *   code 12 GREEN     : a legal event was rejected
 *   code 13 FOLD      : the read-side fold != the witnessed truth
 *   code 14 REVERSIBLE: a prefix re-derivation of the past disagrees
 * exit 99 = capability proven.
 */
module mNNNN

extern @abi(c-msvc-x64) fn foo_reset() -> i32 from "foo.iii"
extern @abi(c-msvc-x64) fn foo_emit(a: u64, b: u64) -> u64 from "foo.iii"
extern @abi(c-msvc-x64) fn foo_count() -> u32 from "foo.iii"
extern @abi(c-msvc-x64) fn foo_view(upto: u32) -> u64 from "foo.iii"

fn main() -> u64 {
    foo_reset()

    /* RED-PROBE: the bounded/gated negative must be rejected (assert the guard FIRES). */
    /* ... drive the illegal case; `return 11u64` if it was wrongly accepted ... */

    /* GREEN: legal events accepted; the fold equals the witnessed truth. */
    if foo_emit(3u64, 7u64) == 0u64 { return 12u64 }
    if foo_emit(4u64, 1u64) == 0u64 { return 12u64 }
    if foo_count() != 2u32 { return 12u64 }
    if foo_view(2u32) != 7u64 { return 13u64 }              /* 3 + 4 */

    /* REVERSIBLE: a prefix re-derives the past. */
    if foo_view(1u32) != 3u64 { return 14u64 }

    return 99u64
}
```
The **teeth** are a second file (`<NNNN+δ>_foo_teeth` or a disabled-gate variant) proving the *same* KAT
fails at the exact assertion when the defense is removed.

---

## 6. THE GO / NO-GO CHECKLIST (paste into a TaskList)

- [ ] **Read** the organ + its externs + the closest KAT model + both scripts; nothing edited yet.
- [ ] Symbol **prefix collision-free** (`nm libiii_native.a` empty for the prefix).
- [ ] **RED-probe KAT compiles and fails at the right assertion** (capability provably absent first).
- [ ] Organ is **inverse-form** (B): one append-only log + pure folds; module-scope state (W4).
- [ ] Fold witnesses a **real execution** (C): no hand-authored integers, no answer typed in.
- [ ] KAT drives **EXIT 99** (in-session fast-verify, `timeout 25`).
- [ ] **Teeth**: a defense-disabled variant fails at exactly the evasion assertion.
- [ ] For an inverse component: KAT asserts **geometry of execution** (provenance / shadow-race /
      lasso / Divergence Signature), not only a destination code.
- [ ] Security claim (if any) uses **`cad` sha256**, not FNV (resistance, not just detection).
- [ ] **Wired (A):** `MODULES` entry (appended last, BSS-neutral, LIBNATIVE comment) **and** `EXPECTED`
      entry. No island; no missing-EXPECTED hard-error.
- [ ] **Sealed**: aggregated into `libiii_native.a`; `mhash` captured; **canonical vs surgical seal
      stated honestly**.
- [ ] **No regression**: new KAT + all touched-organ consumers still `= 99`; `FAIL = 0`.
- [ ] Exe still **RUNs** after. Only now: **commit**.

---

*If a `.iii` change misbehaves, re-test the minimal pattern through `iiis-2` before re-adding a trap to the
list — at this maturity the bug is far more likely in your code than in the compiler.*
