# III Compiler — Class 2 (pure-logic) Port Blueprint → zero `.c` in the build tree

**Status:** design, ready to execute next session. No code changes made writing this.
**Author context:** follows the completed compiler **data-model port** (AST + sema + emit
byte-helpers, 1,821 lines, sealed at iiis-2≡iiis-3 = `7a09a75b…`, differential 57/57, corpus 465/0).
**North star (user-confirmed):** a fully sovereign compiler with **zero `.c` files in the build
tree**. Both Class 1 (the libc↔OS membrane) and Class 2 (pure logic) get ported. Proving `.iii`
can carry the `msvcrt` bindings *without a C wrapper* is part of the "perfect" standard — the
runtime libc dependency staying is accepted and expected.

---

## 0. Ground truth — the 14 C TUs still linked into `iiis-2`

`build_iiis2.sh` compiles every `COMPILER/BOOT/*.c` **except** the 18 `PORTED_TUS` and the
`gen_*`/`sign_*`/`verify_*` build-time tools (those are never linked — they do **not** count toward
"zero `.c` in the build tree"). What remains, by class and size:

| # | File | Lines | Class | What it actually contains |
|---|------|------:|-------|---------------------------|
| 1 | `cg_rm2_accessors.c` | 40 | **Membrane** | `fwrite` + `strlen` only |
| 2 | `iiis1_link_stubs.c` | 89 | **Shim** | `#ifndef IIIS_XII_ENABLED` no-op XII stubs — **compiles to an empty object in iiis-2** (build sets `-DIIIS_XII_ENABLED`); exists only for the iiis-1 bit-identity link |
| 3 | `sema_xii.c` | 106 | Class 2 (XII) | XII semantic glue |
| 4 | `emit_accessors.c` | 135 | **Membrane** | `putenv`,`system`,`popen`,`fopen`,`malloc`,`free` |
| 5 | `cg_rm1_accessors.c` | 163 | Class 2 SHA **+ membrane** | streaming SHA-256 (snapshot-final) + `fwrite`/`strlen` |
| 6 | `iii_cg_pe_iiis1.c` | 180 | Class 2 (PE) | depth-bounded **recursive** AST classifier + composition-table dep |
| 7 | `cg_r3_accessors.c` | 189 | Class 2 SHA+tables **+ membrane** | SHA-256 (struct, `u64` bitlen) + op-table(41) + vol-reg-table(34) + `fwrite` |
| 8 | `xii_ldil.c` | 227 | Class 2 (XII) | XII lattice deferred-inline — machine-code patching |
| 9 | `cg_r3_xii.c` | 249 | Class 2 (XII) | XII R3 codegen (`r3_pe_canonicalise`/`r3_compute_circ`/`r3_pe_lattice_emit`) |
| 10 | `cg_r0_accessors.c` | 259 | Class 2 SHA+tables **+ membrane** | SHA-256 (hi/lo bit-counter) + IRP_MJ(28)+IRQL(24+4) tables + `fwrite` |
| 11 | `xii_lattice_loader.c` | 322 | **Membrane** | XII lattice file load (`fopen`/`fread`) |
| 12 | `lex_runtime.c` | 334 | **Mixed** | `malloc`/`free` (membrane) **+** `read/write_u8/u32/u64` deref primitives (Class 2-trivial, load-bearing) |
| 13 | `sema_xii_adapter.c` | 410 | Class 2 (XII) | XII annotation-query ABI |
| 14 | `cg_r3_xii_adapter.c` | 475 | Class 2 (XII) | XII codegen adapter (largest single TU) |

**Class 2 logic to port:** the SHA (×3 rings), the two table sets, the PE classifier, the XII glue
(items 3/8/9/13/14 ≈ 1,467 lines), and `lex_runtime`'s deref primitives.
**Class 1 membrane (zero-`.c` finisher):** items 1, 4, 11, the `malloc`/`free` of 12, and the
`fwrite`/`strlen` left in 5/7/10 after their SHA+tables leave.

---

## 1. The two facts that govern every step

### 1a. The differential-corpus falsifier (the safety net — same as the data-model port)
`build_iiis2.sh --check-corpus` compiles all 57 `stage1_corpus` programs with **iiis-1 (C
accessors)** *and* **iiis-2 (`.iii` accessors)** and asserts **byte-identical `.o`** for every one.
Any divergence — a wrong SHA witness digest, a mis-encoded table value, a PE that narrows
differently — produces a byte-different `.o` and turns the gate **RED**. This is exactly the gate
that proved the data model. Per-increment cadence is unchanged from that port (§2).

> ★ Insight ─────────────────────────────────────
> The witness SHA is *embedded in the emitted object*. So "is my native SHA correct?" is not a
> separate question — it **is** the byte-equivalence check. The gate cannot pass unless the `.iii`
> SHA produces the identical digest the C SHA produced. The crypto is self-falsifying here.
> ─────────────────────────────────────────────────

**Step 0 for SHA/tables — prove the gate actually covers the path.** Before relying on this,
confirm `stage1_corpus` *exercises* the cg_* witness-SHA and table-lookup paths under
`--compile-only`. Compile one corpus program both ways, confirm the witness bytes are present and
that perturbing a table entry / SHA constant turns the gate RED. **If the path is not covered, add
KAT corpus programs that force it** (a Ring-0 driver stub that emits an `IRP_MJ_*`/`IRQL`/opcode
slice and a D9 witness) — never trust an unexercised gate. (memory: *prove the negative case*.)

### 1b. The W3 address-of-global quirk (shapes the SHA design)
In iiis-2, `&GLOBAL[0] as u64` does **not** yield a real address (documented in
`numera/sha256.iii`, which works around it with `sha256_finalize_internal()` +
`sha256_digest_byte(i)`). Consequence: **a shared `sha_compress(state_ptr)` over a *global* state
buffer is impossible.** Any SHA design must either (a) operate on its own module-singleton globals
directly (no address-taking), or (b) use `@specialize` to clone state, or (c) take a *real runtime
pointer* (heap/arena, not a global). Update/snapshot **out**-pointers are fine — they are the
caller's real buffers, not globals.

---

## 2. The proven gated cadence (reuse verbatim per increment)

Each increment is one symbol-group moved from a `.c` file to `.iii`:

1. **Read** the C source for the group (offsets / table data / algorithm) — no edits yet.
2. **Write** the native `.iii` (identical exported symbol name + ABI signature) in its host module.
3. **Dual-compile** the host `.iii` with iiis-1 **and** iiis-2; diff the `.o` (must be identical for
   the compiler-internal modules) — or rely on the corpus gate where the symbol is consumer-side.
4. **`sed`-delete** the ported group from the `.c` (or delete the file if now empty).
5. **`build_iiis2.sh --check-corpus`** → require **57/57**.
6. **`build_iiis3.sh`** → require **iiis-2 ≡ iiis-3** fixpoint; **reseal**
   `COMPILER/BOOT/iiis-{2,3}.mhash`.
7. **`git commit`** the increment.
8. Periodic **full corpus** (`STDLIB/scripts/run_corpus.sh`) → require **465/0** (or current
   baseline + any added KATs).

Standing discipline: **manual line-by-line audit before each rebuild** (memory:
*audit_before_rebuild* — no rebuild-fail-fix loops); pin the **in-tree** compiler (never an
autodiscovered stale binary); do **all** work in the main session (no subagents on III).

---

## 3. TARGET 1 — `cg_*` tables  (the first, easiest win)

The five tables are pure data + slice-equality lookups by source-buffer slice. They have **no W3
issue** (they read the caller's source pointer, write nothing global) and a **clean host**: the
lookup functions are currently `extern`-ed *into* the already-native `cg_r0.iii` / `cg_r3.iii`, so
the native definitions go **directly into those TUs** (delete the extern, add the body, delete from
the `.c`).

**Symbols to move (exact, stable contract):**
- → `cg_r0.iii`: `iii_cg_r0_irp_mj_lookup_c(addr,len)→i32` (IRP_MJ, 28),
  `iii_cg_r0_api_min_irql_c(addr,len)→i32` (kernel-API→IRQL, 24),
  `iii_cg_r0_irql_sym_c(addr,len)→i32` (4 inline).
- → `cg_r3.iii`: `iii_cg_r3_op_known_c(addr,len)→i32` (41 mnemonics, membership),
  `iii_cg_r3_is_volatile_c(addr,len)→i32` (34 registers, membership).

**`.iii` form (the #16 byte-helper idiom, already proven):** one `slice_eq` helper —
```
fn cgtab_slice_eq(p: u64, len: u64, lit: *u8, litlen: u64) -> u32 { /* len==litlen then byte compare via iii_lex_read_u8_at_c */ }
```
then a `when`/`if` cascade per table: `if cgtab_slice_eq(p,len,"IRP_MJ_CREATE" as *u8, 13u64)==1u32 { return 0i32 }` … trailing `return -1i32`. String literals give addressable, **non-NUL-terminated** bytes — compare by **known length** (never `strlen`). ~130 entries total: verbose but mechanical and **bloat-justified** (irreducible WDK/ISA data; matches the existing inline-cascade idiom of `iii_cg_r0_irql_sym_c`).

**Steps:** (1) §1a Step-0 coverage check; (2) port the 3 r0 tables → gate; (3) port the 2 r3 tables
→ gate; (4) each reseals + commits per §2. **Falsifier:** corpus 57/57 + any forced-path KAT stays
green; flip one table value → must go RED (proves the gate guards it).
**Outcome:** `cg_r0_accessors.c` and `cg_r3_accessors.c` shrink to **SHA + `fwrite`** only.

---

## 4. TARGET 2 — `cg_*` SHA-256 (snapshot-final)  (the intricate core)

Three rings carry a streaming SHA-256 used as the **D9 witness** over the emitted `.text`, with a
**snapshot-final**: digest the stream *without destroying it* so emission can continue.
- `cg_r0`/`cg_rm1`: file-static globals, **hi/lo 32-bit** bit-counter, snapshot via save/restore.
- `cg_r3`: a `struct {state[8]; u64 bitlen; buf[64]; buflen}`, snapshot via struct-copy.
- All three compute **identical** SHA-256; only state shape + counter representation differ.

`STDLIB/iii/numera/sha256.iii` **already** implements the full algorithm natively (`sha256_init`/
`update`/`final`/`oneshot` + the W3 workarounds `finalize_internal`/`digest_byte`) — but it is a
**single module-singleton**, its `final` **destroys** the sponge, and it has **no snapshot**. Its
own header names the intended mechanism for multiple contexts: *"per-arena state via `@specialize`."*

### ADR-CLASS2-SHA — how to get 3 independent snapshot-capable contexts under W3

| Option | Idea | Pro | Con | Verdict |
|--------|------|-----|-----|---------|
| **A — `@specialize`** | `@specialize` the sha256 module 3× (r0/r3/rm1), add a `snapshot` fn | leanest; **the header's intended design**; one source of truth | needs `@specialize` to clone **module state** (it specializes type-params today — `*T`; state-cloning unproven) | **try first** |
| **B — per-ring native module** | `cg_witness_sha_{r0,r3,rm1}.iii`, each its own `var` state + `init/update/snapshot`, compress reads its own globals directly | W3-safe; behavior-preserving; no address-taking | ~100 lines × 3 ≈ near-duplicate SHA (anti-bloat tension) | **fallback** |
| **C — shared singleton + snapshot** | reuse one sha256 singleton, add `sha256_snapshot(out)` (save→pad→write→restore) | most code reuse | assumes **only one SHA stream live at a time**; C kept them separate deliberately | only if A fails **and** B's duplication is judged unacceptable, **and** the "single live stream" claim is *proven* (grep the codegen path for any interleaved stdlib-sha use) |

**Recommendation:** Step 0 — write a 2-context `@specialize` probe (two specialized sha contexts,
hash two different streams, assert independent digests + a known FIPS vector). If `@specialize`
clones state → **Option A** (leanest, matches the header's plan). If not → **Option B** (accept the
duplication as irreducible-given-W3; factor the K-table init + the 64-round core into the smallest
shareable shape the dialect allows without address-taking).

**Snapshot semantics (must be byte-exact):** append `0x80`, pad, append the **big-endian 64-bit bit
length**, run one final compress into a *copy* of the state, emit 8 big-endian words to the caller's
`out32` (a **real** pointer — W3-safe), then **restore** the live state. Note r0/rm1 store the
counter as hi/lo `u32` pair but emit the same 64-bit BE length as r3's `u64` — the `.iii` may use a
single `u64` so long as the emitted padding bytes are identical.

**Falsifier:** the differential corpus (§1a) — the witness digest is in the `.o`. Plus a standalone
KAT: feed the FIPS `"abc"` vector through update+snapshot, assert
`ba7816bf…f20015ad`, then continue + snapshot again to prove the stream survived.
**Outcome:** `cg_r0/r3/rm1_accessors.c` reduced to **`fwrite`(+`strlen`)** = pure membrane.

---

## 5. TARGET 3 — `iii_cg_pe_iiis1.c` partial evaluator (180 lines)

Detects `resolve(set, intent_form(LIT), ctx)` callsites and rewrites them to a direct
`leaq <dispatch_fn>(%rip)` load (bit-identical to what `cg_r3.c` emits). Two enablers are **already
done**: the AST-walk uses `iii_ast_get` / `iii_ast_list_at` / `iii_ast_node_binder_id` — all native
in `ast.iii` now. Two real items remain:

1. **The composition table.** The PE consults `III_COMPOSITION_TABLE`, generated from
   `iii_compositions.def` (`SEQ_IDX PRIMITIVE HEXAD K LITERAL FN_NAME`) into `iii_compositions.h`.
   The **runtime** side (`STDLIB/iii/omnia/prespec.iii`) already carries this table as an
   auto-generated `.iii` block. **Lean path: extend `gen_compositions.sh` to also emit a `.iii`
   table the compiler PE links against** — single source of truth (`.def`) preserved; the build
   already verifies generated artifacts match the `.def` each iiis-0 build.
2. **Recursion.** `classify_intent_bounded ↔ fn_returns_static_intent` is depth-bounded mutual
   recursion. iiis **supports** (mutual) recursion — proven in `CONVERGENCE-AUDIT §2.2.18`
   (`fwd_test(4)=10`) — so it **ports directly**. *If* W15-style iteration is preferred for compiler
   TUs, de-recurse to an explicit depth-tagged worklist; that is a **style choice, not a correctness
   blocker.**

Host: a new `cg_pe.iii` PORTED_TU (or fold into `cg_r3.iii`). Falsifier: the differential corpus —
any PE narrowing divergence changes the emitted `leaq`, flipping a byte in the `.o`.

---

## 6. TARGET 4 — the XII glue (≈1,467 lines, the largest + most intricate)

`sema_xii.c`(106) · `cg_r3_xii.c`(249) · `xii_ldil.c`(227) · `sema_xii_adapter.c`(410) ·
`cg_r3_xii_adapter.c`(475). This is the adapter ABI between the **`.iii` XII stdlib modules** and the
compiler (annotation queries, R3 XII codegen, lattice deferred-inline machine-code patching).
**Requires its own read-first pass** (do not start blind): inventory every exported symbol and its
`.iii` consumer, map the `g_xii_current_ast` / `xii_*_current_sema_state` globals, and understand
`xii_ldil`'s byte-patching of the emitted `.text`.

Bootstrap subtlety to preserve: `iiis1_link_stubs.c` provides **no-op** XII symbols for the iiis-1
link (XII OFF) and is `#ifdef`-compiled to **empty** in iiis-2. The triple bit-identity invariant
(iiis-0 = iiis-1 = iiis-2 for every non-`@lattice` input) rests on
`sema_xii_anno_has_in_ast()` returning 0 in iiis-1 so the `cg_r3.iii` gate falls through to the
legacy emitter. **When the XII glue goes native + unconditional, re-establish this invariant
explicitly** (e.g., a build-flag-driven `xii_enabled()` that the gate consults) or the iiis-1
intermediate diverges. Defer this target until Targets 1–3 are sealed.

---

## 7. `lex_runtime.c` deref primitives (load-bearing, trivial)

`iii_lex_read_u8_at_c` / `write_u8_at_c` / `read_u32_c` / `write_u32_c` / `read_u64_c` /
`write_u64_c` are **pure native deref/poke at `addr+off`** on the caller's **real** runtime pointers
(malloc'd buffers — *not* globals, so W3-clear). They are the **keystone** primitive (proven
byte-identical in iiis-1 and iiis-2 during the data-model port) and **load-bearing**: nearly every
ported TU `extern`s them from `lex_runtime`. Porting = define them natively (e.g.,
`let p = (addr+off) as *u8; return p[0] as u32`).
**The one constraint is hosting:** the defining `.iii` must *not* itself `extern` them (def+extern
clash) — `ast.iii` and others consume them, so they cannot host. **Create a dedicated leaf
`lex_rt.iii` PORTED_TU**; all consumers resolve by name. The `malloc`/`free` in this file stay
membrane (§8).

---

## 8. CLASS 1 — the membrane → `msvcrt` externs (the zero-`.c` finisher)

The user's explicit goal: prove `.iii` carries these bindings with **no C wrapper** (runtime libc
dependency unchanged and accepted). Convert each wrapper to a direct
`extern @abi(c-msvc-x64) fn <libc> (...) from "msvcrt"` call in `.iii`:

- `emit_accessors.c`: `putenv`, `system`, `popen`/`fgets`/`pclose`, `fopen`/`fwrite`/`fclose`,
  `fopen`/`fseek`/`ftell`/`fread`, `malloc`/`free`.
- `lex_runtime.c` `malloc`/`free` (→ `calloc`/`free`); `xii_lattice_loader.c` `fopen`/`fread`.
- residual `fwrite`/`strlen` in `cg_r0/r3/rm1/rm2_accessors.c` (after their logic leaves).

**Care points:** keep the LLP64 invariant (every `.iii u64` ↔ 64-bit at the boundary — never
`unsigned long`); preserve the determinism semantics each wrapper encodes (e.g.,
`emit`'s forced-env D1..D6, `popen_first_line`'s drain-rest, `read_file`'s `+1` NUL slot); verify
each `msvcrt` symbol resolves on the MSYS toolchain. Falsifier: corpus 57/57 + full corpus + the
fixpoint reseal — and a build with **`ALL_C` empty** (the literal zero-`.c` proof). `gen_*`/`sign_*`/
`verify_*` may remain as out-of-build tools or be ported separately; they are not in the linked set.

---

## 9. Roadmap (each step independently gate-able + reversible)

1. **Target 1 — tables** (cg_r0 ×3, then cg_r3 ×2). *Smallest, no W3, clean host. Start here.*
2. **Target 2 — SHA** (Step-0 `@specialize` probe → Option A or B; r0/rm1 share the hi/lo shape, r3 the struct shape).
3. **Target 3 — PE** (`gen_compositions.sh` emits a `.iii` table; port the classifier).
4. **`lex_rt.iii`** — the deref primitives (trivial, but reseal carefully — load-bearing).
5. **Target 4 — XII glue** (dedicated read-first pass; preserve the iiis-1/iiis-2 XII-symbol invariant).
6. **Class 1 — membrane → `msvcrt`** (emit, lex/xii I/O, residual fwrite/strlen) → build with `ALL_C` empty = **zero `.c`**.

After each: differential 57/57 → fixpoint reseal → commit; periodic full corpus.

---

## 10. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| `@specialize` cannot clone module state | Option A dead → fall to B | Step-0 probe **before** committing to A; B is W3-safe and ready |
| `stage1_corpus` doesn't exercise cg_* SHA/tables under `--compile-only` | green gate proves nothing | §1a Step-0 coverage check; add forced-path KATs; flip-a-byte → must go RED |
| Snapshot padding byte-differs from C (hi/lo vs u64 length) | witness digest wrong → `.o` differs | emit the identical BE-64 length bytes; KAT the FIPS `"abc"` + continue-after-snapshot |
| W3: accidental address-of-global in SHA/PE | wrong runtime address, silent corruption | never `&GLOBAL`; operate on own module globals or real caller pointers; `digest_byte`-style readout |
| `lex_rt.iii` host clashes (def+extern) | link failure | dedicated leaf module that defines, never externs, the primitives |
| XII glue breaks the iiis-1 bit-identity invariant | iiis-1 ≠ iiis-2, fixpoint lost | explicit `xii_enabled()` gate replacing the `#ifdef` short-circuit; defer until 1–3 sealed |
| Module-scope `var` name collision (global `L_NAME`) | link error (seen with `EMIT_HEX_TMP`) | unique prefixes per module (`R0SHA_*`, `R3SHA_*`, `CGTAB_*`); the link gate catches it pre-brick |

---

## 11. Standards checklist (tick before any increment is "done")

- **NIH:** libc + III headers only; `msvcrt` externs are libc, not third-party. ✓ by design.
- **Determinism:** no float; equality/bitwise only on the hashed path; `when` (monomorphic, no
  fn-pointer) dispatch; no statistical/observational logic. Reseal is DRIFT-driven (let the gate decide).
- **W-laws / traps:** W3 (no address-of-global — §1b); param-spill (copy params to locals before any
  call); single-line `fn`; no nested `/* */` or em-dash/`*/` in comments; module-var prefix uniqueness;
  no `select()` with side effects (use `when`).
- **Falsifier present every step:** differential 57/57 **plus** a forced-path KAT (never trust an
  unexercised gate); flip-a-byte negative proves the gate guards the new code.
- **Process:** manual audit before rebuild; pin in-tree compiler; no subagents on III; fixpoint
  reseal + commit per increment.

---

*End state:* `build_iiis2.sh` links **zero `.c`** (`ALL_C` empty); the self-hosting compiler is
fully sovereign in `.iii`, every increment proven byte-identical through the differential gate and
the iiis-2≡iiis-3 fixpoint.
