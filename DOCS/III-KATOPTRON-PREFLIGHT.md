# III-KATOPTRON — THE PRE-FLIGHT LANDED, AND WHAT IT CAUGHT

*Status: LANDED + GATED, 2026-07-20. Every number below is measured and carries
the command that re-derives it. The headline finding was produced by the organ
on its first real run over the tree, not by inspection.*

Follows `DOCS/III-SYNERGIA-ORGAN-LEVERAGE.md`, which ranked *"katoptron's
pre-flight in the build path"* the single most practically valuable placement in
the set. Two of that document's claims about katoptron did not survive contact
and are corrected in §1; the placement itself was right, and §3 is what it found.

---

## 0. THE HEADLINE — iiis-2 CANNOT COMPILE THE SOURCE THAT PRODUCED IT

`COMPILER/BOOT/cg_r3.iii` stands at **1025 top-level declarations**. The sema
declaration table is **1024** (`sema.iii:292`, `const SEMA_DECL_CAP : u32 = 1024u32`,
backed by `[u32; 1024]` arrays). One over.

```sh
COMPILED/iiis-1.exe cg_r3.iii --compile-only --out /tmp/a.o   # rc=0
COMPILED/iiis-2.exe cg_r3.iii --compile-only --out /tmp/b.o   # rc=12
                                       # sema error OOM at 4270:1 (hexad=0)
```

**`build_iiis3.sh` is therefore broken.** Line 56 sets `IIIS0_BIN="$OUT_DIR/iiis-2"`
and its `PORTED_TUS` includes `cg_r3` — stage 3 recompiles `cg_r3.iii` with
`iiis-2`, which is exactly the operation that OOMs. The self-hosting fixpoint
does not currently close.

### Causation, isolated at the boundary

Not inferred — the two adjacent commits differ by one declaration at the cap:

| `cg_r3.iii` | decls | `iiis-2 --compile-only` |
|---|---|---|
| `98de97e4` (07-17) | 1024 | **rc=0** |
| `cf1e546c` (07-18) | 1025 | **rc=12 sema OOM** |

### The approach to the wall was monotonic and unwatched

```sh
for c in $(git log --format=%h -8 -- COMPILER/BOOT/cg_r3.iii); do
  git show "$c:COMPILER/BOOT/cg_r3.iii" > /tmp/cg_$c.iii
  STDLIB/build/katoptron/katoptron.exe meter /tmp/cg_$c.iii | awk '/top decls/{print $3}'
done
```

1006 → 1009 → 1012 → 1017 → 1021 → **1024** → **1025**, over twelve days.
`98de97e4` parked the compiler at *exactly* the cap with zero headroom; the next
commit spent one. That commit is titled *"THE SIGNED FOLD … through the WHOLE
rite at **net-zero decl cost**"* — the author was tracking the decl budget and
believed the change spent none. Nothing measured it, so nothing contradicted them.

**This is the argument for the pre-flight, and it is not hypothetical.** A
two-day-old break in the tree's central self-hosting claim, in a tracked and
committed file, sitting undetected because the only organ that measures the
quantity had zero production consumers.

---

## 1. TWO SYNERGIA CLAIMS THAT DID NOT SURVIVE

**`katoptron`'s production in-degree is 0, not 1.** The audit's `grep -rl` ran on
the *organ name* and matched prose: `zetesis.iii:5,9,91` merely mention katoptron
in header comments ("mirrors before paying (katoptron)"). There is no `kt_*` call
in zetesis. This is that document's own trap — *grep for the capability, not the
symbol prefix* — firing on itself.

**The pre-flight could not do what it was said to do.** SYNERGIA promised it
"turns every future silent exit-14 into a named refusal **with a line number**."
`kt_meter` retained no line and no name: `KT_MSLOTS` was one max over the whole
file, `KT_SIGP` jumped `pos` past multi-line signatures without counting the
newlines it skipped, and there was no file reader and no CLI face. The organ
could say *"some fn in this file has 71 slots."* Closing that gap is §2.

---

## 2. THE SCOPE LAW — THE METER WAS COUNTING THE WRONG THING

The first honest run indicted `metabole.iii` at **68 slots, WOULD BREACH** — a
file that compiles green. The ceiling constant was never wrong; the **counting
model** was. Measured directly against `iiis-2`:

| corpus | decls written | max live | compiler |
|---|---|---|---|
| 64 flat `let` | 64 | 64 | **rc=0** |
| 65 flat `let` | 65 | 65 | **rc=14** (silent) |
| 69 in two disjoint scopes | 69 | 35 | **rc=0** |
| `mb_arm376` (depths 1,2,3,4,7) | 68 | 31 | **rc=0** |

The codegen allocates by **maximum simultaneously-live slots** and reuses the
slots of a scope that has died. A syntactic sum overcounts every nested function.
`kt_meter` now carries a per-depth scope stack (`KT_SCOPE`), raises `maxs` as each
decl *opens*, and releases a scope's slots when its brace closes. `metabole.iii`
now reads **31 slots at line 5658, CLEAR** — agreeing with the compiler that
accepts it.

Had the pre-flight been wired into the build path as SYNERGIA proposed, its first
act would have been to false-refuse `metabole.iii`.

---

## 3. WHAT LANDED

- **`omnia/katoptron.iii`** (+88/−9) — line attribution (`KT_MWLINE`, `kt_nl`
  crossing jumped signatures), the scope-aware live-slot model, and the new
  export `kt_m_worst_line()`. Arms **E** (line attribution across a multi-line
  signature; drop `kt_nl` and it reads 4 instead of 7) and **F** (the scope law,
  69 written / 35 live / CLEAR) cover it — RATCHET-DELTA-ZERO satisfied.
- **`omnia/katoptron_cli.iii`** (new) — the face the organ never had:
  `prove` / `meter <file>` / `preflight <file>...`. Every verb self-proves first
  and refuses to judge over a broken law (exit 9). A file larger than the 1 MiB
  window is **refused with its verdict withheld**, never metered short.
- **`scripts/katoptron_gate.sh`** (new) — `bash STDLIB/scripts/katoptron_gate.sh` → exit 0.

### The gate's teeth are a differential, not a pin

A stored expectation ("the ceiling is 64") tests only what its author foresaw and
can be edited toward. The gate instead generates corpora spanning the boundary and
asks the **live compiler** for the answer key every run, demanding the mirror
agree — at the exact boundary and on the nested case. Verified 11/11 including
64-clear / 65-refused / 69-nested-clear. If `SEMA_DECL_CAP` is ever raised or the
ceiling moves, the gate follows without being told.

It also refuses to pass a **vacuous** census: the first version reported
"0 would breach" because `xargs` split this tree's path on the space in
"Edwin Boston", producing 2232 unreadable fragments and zero findings — which
reads identically to a clean tree. Unreadable sources are now exit 8, not an
all-clear.

---

## 4. A SEVERITY CLAIM I MADE AND THEN HAD TO WITHDRAW

On finding that `iiis-1` (frozen 07-15, *pre*-wall) compiles the 1025-decl
`cg_r3.iii` while emitting **zero** bytes of diagnostics, I wrote that the
shipped `iiis-2.exe` "was built from a cg_r3 that lost a declaration" —
implying the compiler in use might be corrupt. That was an overclaim, and the
artifact refutes it:

```sh
nm cg_r3_from_iiis1.o | grep iii_cg_r3_emit    # T iii_cg_r3_emit  -- present
cmp cg_r3_from_iiis1.o cg_r3_from_lifted.o     # BYTE-IDENTICAL
```

The `.o` produced by the compiler that **silently dropped** the declaration and
the `.o` produced by the fixed compiler that **kept** it are byte-for-byte the
same. The decl table is a sema-side *name-resolution* structure; it does not
gate emission. The dropped row was the last decl, referenced only from outside
the module, so nothing needed to resolve it by name.

The shipped binary is sound. What survives is narrower and was always the real
defect: **`iiis-2` could not compile `cg_r3.iii`, so `build_iiis3.sh` could not
close the fixpoint.** That the drop was harmless is luck — the next declaration
added to `cg_r3` would be dropped just as silently by the frozen `iiis-1`.

---

## 5. THE FIX — `SEMA_DECL_CAP` 1024 → 2048, VERIFIED SURGICAL

`build_iiis3.sh` is **exercised, not latent**: `bootstrap_from_clean.sh:178`
runs it as stage 6 ("iiis-2 rebuilds itself; byte-identical binary"), and
`basal_census_gate.sh`, `production_gate.sh`, `nomos_seal.sh`, both `_theta`
chains and both seraphyte drivers invoke it. That satisfies the restraint law's
one exception — *a real failure on an exercised path earns an in-place fix.*

Lifted in `sema.iii`, as one coupled set:

| | was | now | why |
|---|---|---|---|
| `SEMA_DECL_CAP` | 1024 | 2048 | the wall cg_r3 crossed |
| 4 decl SoA columns | `[u32;1024]` | `[u32;2048]` | must match the cap |
| `SEMA_DECL_IDX` | `[u32;2048]` | `[u32;4096]` | holds load ≤ 0.5, **the invariant that makes probing terminate** |
| `SEMA_ANNO_CAP` + 7 columns | 1024 | 2048 | anno rows ≤ decl rows; raising DECL alone would open a *new* overflow |

`SEMA_BUILTIN_BUF : [u8; 1024]` is an unrelated byte buffer and was left alone.
`sema.iii`'s own decl count is unchanged at 411 (array sizes, not new decls), so
the frozen `iiis-1` still compiles it — the bootstrap precondition, verified rc=0.

### Verification (built to a scratchpad path; `COMPILED/iiis-2.exe` untouched)

- **The break closes.** Lifted iiis-2 on `cg_r3.iii` → **rc=0** (shipped → rc=12).
- **Stage-3 compile phase**, all 33 `PORTED_TUS`: shipped fails 1 (`cg_r3`),
  lifted fails **0**; the 32 both compiled are **byte-identical**.
- **Wide differential**, all 739 `omnia`+`aether`+`numera` sources: 0 failures
  either way, **739 byte-identical, 0 differing**.
- `--reproducibility-check` on the lifted binary: **PASSED**.

**772 sources compiled by both compilers; 771 byte-identical; one that only the
fixed compiler can build; zero regressions.** The change is provably minimal —
it removes a false refusal and alters no emission anywhere else.

---

## 6. THE LAST PIN, CLOSED — THE DECL WALL IS NOW DIFFERENTIAL TOO

The gate derived the **slot ceiling** from the live compiler, but its corpora only
varied `let`-count, so the **decl wall** stayed a bare constant: `katoptron_cli.iii`
carries `KM_WALL = 1024`, `sema.iii` carries `SEMA_DECL_CAP`, and *nothing
structural kept those equal*. That is precisely how cg_r3 crossed 1024 unnoticed —
a constant drifting from reality with no one measuring.

The gate now generates decl corpora straddling the cap (1000/1100/2000/2100) and
demands agreement in **both** directions. Proven to bite:

| gate run against | compiler cap | result |
|---|---|---|
| shipped `iiis-2` | 1024 | **rc=0 GREEN** — pin matches |
| lifted `iiis-2` | 2048 | **rc=7** — `decl1100`, `decl2000`: *compiler accepts, katoptron refuses* |

So promoting the lifted binary will fail this gate until `KM_WALL` is raised to
match. The pin can no longer drift silently in either direction. *(This was the
intermediate state; §7b raises `KM_WALL` to 2048, fixes an off-by-one the coarse
corpora missed, and moves the differential to the exact 2048/2049 boundary.)*

*(Second reserved-word trap of the session: the first corpus used `fn use()` —
`use` is reserved, like `from`. It surfaced as a parse error masquerading as a
wall disagreement, which would have made the differential test the wrong thing.)*

---

## 7. THE THREE FOLLOW-ONS — RESOLVED (user-authorized 2026-07-20)

### 7a. iiis-2 PROMOTED + THE FIXPOINT CLOSED  ✓

The reseal was done through the canonical scripts, in place, with backups and the
tree's own gates as arbiter:

- `build_iiis2.sh --check-corpus` rebuilt `COMPILED/iiis-2.exe` from frozen iiis-1
  + lifted sema → **`4a0cb36d…`**, corpus **60/0**, Ring-2 + both cg_r0 gates green,
  and **byte-identical to the earlier scratchpad build** (deterministic).
- `build_iiis3.sh --check-corpus` built iiis-3 from the new iiis-2 → **iiis-3 ==
  iiis-2 byte-for-byte** (`4a0cb36d…`), corpus **60/0**. **The self-host fixpoint
  cf1e546c broke is closed.**
- Golden pins re-sealed to the closing value: `BOOT/iiis-2.mhash` and
  `BOOT/iiis-3.mhash` `4050a33d…` → `4a0cb36d…`. (They were *stale* — both pinned
  `4050a33d` while the committed binary was `d1b664c2`; the full bootstrap had not
  closed since before cf1e546c. The reseal makes pins == live == fixpoint, which
  **restores** the standard rather than breaking it.)
- `basal_census_gate.sh` (the BASAL LAW ratchet) → **GREEN**.

A severity claim withdrawn honestly (§4) got its final proof here: the `.o` the
silently-dropping frozen iiis-1 produced for cg_r3 is **byte-identical** to the one
the fixed compiler produces. The shipped binary was always sound; the defect was
only that the fixpoint could not close.

### 7b. `preflight` WIRED INTO `build_stdlib.sh`  ✓

Added as a source-scanning gate in the same **fail-open idiom** as the seven drift
gates above it: it runs `katoptron preflight` over `STDLIB/iii` before compiling,
naming any file that would breach a wall (turning the slot ceiling's silent exit-14
into a named file:line), and **skips cleanly when `katoptron.exe` does not exist
yet** — which on a from-clean build it cannot, since it links the archive this
script produces. Verified four ways: syntax OK; the real tree passes (302+ files
CLEAR, 0 breaches — the build proceeds); a synthetic 2049-decl file is **REFUSED
and named**; a missing binary **skips**. `KATOPTRON_PREFLIGHT=0` overrides.

Not run end-to-end here, deliberately: `STDLIB/build/iii/libiii_native.a` is a
**tracked** file and a full `build_stdlib` would rebuild it, baking the five
concurrent-WIP organs into a tracked binary — the clobber
`feedback_concurrent_session_same_tree` forbids. The gate is proven in isolation;
the end-to-end run belongs to whoever lands the WIP.

An off-by-one in my own meter surfaced and was fixed here: the decl wall used `>=`
where the ceiling correctly uses `>`. Empirically the compiler accepts *exactly*
`SEMA_DECL_CAP` decls (metered 2048 compiles, 2049 OOMs), so `count > wall` is
right and `>=` would false-refuse a file with exactly `wall` decls (which
`cg_r3.iii@98de97e4` was). Fixed, `KM_WALL` lifted 1024 → 2048, arm D rewritten to
test the **exact** boundary, and the gate's decl differential moved to straddle
2048/2049 — so the razor's edge is now covered, not just gross mismatch.

### 7c. The `iiis-1` reseal from `iiis-0` — NOT DONE, and why (a second, independent break)

Task 2 as literally stated is blocked by a break that has nothing to do with the
decl cap:

- **`iiis-0` cannot parse `cg_r3.iii`.** Its parser trips `RECURSION_LIMIT` at the
  ~8-deep nested-`if` guard chains in cg_r3 (measured: the frozen seed's real
  nesting limit is **7** — 7 deep compiles, 8 trips; iiis-2 handles all). This is a
  behavioral quirk of the *frozen seed binary*, **pre-existing since ≤ 07-17**
  (it fails on the 07-17 cg_r3 too), and entirely independent of `SEMA_DECL_CAP`.
- **The core purpose is already met.** Task 2 wanted a correct self-hosting
  compiler carrying the 2048 cap whose fixpoint closes — **§7a delivers exactly
  that.** The frozen iiis-1's only impurity is the silent drop, and that is proven
  byte-harmless (the `.o` is byte-identical either way).
- **Forcing it would be a workaround on load-bearing code.** The only ways through
  are (a) flatten cg_r3's 5 guard-chains to `&&` — contorting the *codegen* to fit
  a *frozen-seed* quirk, the fix-the-symptom anti-pattern, plus a full chain
  re-reseal — or (b) re-seed iiis-0 (basal-law territory). And neither reaches the
  end goal: `bootstrap_from_clean` **stage 5** (seed↔self-host identity on
  `48_m22_audit`) is **independently red** — pre-existing, proven *byte-neutral to
  this reseal* (old iiis-2 and new iiis-2 emit it identically) — so the full
  from-clean gate would stay red regardless.

Left for an explicit, separate decision. The restraint law is decisive: a
load-bearing codegen edit for a latent, proven-harmless gain that does not even
close the gate it targets is negative-EV.

---

*Composes: katoptron (the mirror), klisi (the substrate it confirms against),
eidolos (the scroll at arm 324, where `[preflight < compile]` was already sealed
before any of this ran). Touches none of the five organs under concurrent
uncommitted WIP, and does not touch `cg_r3.iii`.*
