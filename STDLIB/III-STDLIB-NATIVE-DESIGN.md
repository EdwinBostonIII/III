---
III-STDLIB-NATIVE-DESIGN.md
Document-ID: R1.D1 (proposed)  Pass: 0
Author: Edwin Boston
Closes-the-gap-with: III-STDLIB.md (Refinement Pass v2 — C-inventory only)
Companion specs: III-SANCTUM (R1.A8), III-CYCLES (R1.B*), III-EFFECTS,
                 III-CONFORMANCE.md (C-1..C-30), III-LEXICON (47 kw),
                 III-MODIFIERS (19 modifiers), III-PROVENANCE
Mandate alignment: M1..M21 + bootstrap gates + crash-debugging protocol
---

# III STDLIB — THE LAST STANDARD LIBRARY

> The previous fifty-five years of programming languages produced standard
> libraries.  III's standard library is not one of them.  It is the
> ontological floor of computation made tractable: the smallest stable set
> of forms that, taken together, **are** what computation can be in a
> machine that refuses to lie.

This document is the architectural specification for the native `.iii`
standard library, replacing the historical assumption that III is a C-style
language with a thin runtime.  It is the spec the compiler must converge
on, the corpus must validate against, the mandates govern, and Sanctum
admits.

---

## 0. Why Existing Standard Libraries Are Compromises

A standard library is the contact patch between a language's promise and a
program's reality.  Every famous one violates its own promise:

| Lang        | Promise                | Compromise (in stdlib)                                                              |
|-------------|------------------------|-------------------------------------------------------------------------------------|
| C89/C99     | "portable assembly"    | `errno` ambient, `gets()` shipped, `strtok` mutates; UB everywhere; no bounds       |
| C++ STL     | "zero-cost abstraction" | ABI churn, exception cost, allocator monkey-patching, header-only template hell    |
| Rust std    | "fearless safety"      | `unsafe` opens the door for everything below; lifetime soup leaks to API surface    |
| Go          | "simple"               | runtime-mandatory GC; slice aliasing; `interface{}` escape hatch                   |
| Python      | "batteries included"   | inconsistent module API; runtime types; GIL; deterministic builds impossible       |
| JVM         | "write once"           | NPE always possible; checked-exception rot; classloader tower                       |
| Haskell     | "purity"               | `unsafePerformIO` and `IORef` ambient; monad-transformer cake                       |
| Zig         | "modern systems"       | manual allocator threading; capability-less; no provenance; no sealing              |
| OCaml       | "ML-pragmatic"         | unverified IO; GC mandatory; no effect tracking until 5.x                          |
| Idris/Agda  | "totality"             | not systems-grade; runtime ad-hoc; no machine-code seal                             |

Every line above is a known wound.  III's stdlib **closes** the wounds
explicitly, not as a retrofit but as a foundational invariant.  The design
question for III is not "which compromise do we accept?" but "**which
invariant do we insist on?**"

We insist on seven.

---

## 1. The Seven Foundational Axioms

These are the load-bearing invariants.  Every stdlib module is justified
against these; a module that cannot be justified is rejected.  The Greek
letters are the citation handles used throughout the spec.

### Axiom α — Provenance Closure
> Every value `v` carries a witness `w` such that `v ≡ derive(w)`.  Forging
> a value is a type error.

No value exists without a derivation.  A `u32` knows where it was minted.
A `string` knows which buffer produced its bytes.  A `result<T,E>` knows
which call yielded it.  Witnesses are **not** logs — they are first-class
values that the compiler can demand, propagate, hash, and seal.

Concrete: every stdlib type has a paired `*_witness_t` derivable in O(1)
from the value plus a sanctum frame id.  See §6.

### Axiom β — Sealed Effects
> Every observable effect crosses a Sanctum boundary.  No ambient I/O, no
> ambient allocation, no ambient time.

Functions declare effects in their type via `@effects(…)`.  The compiler
refuses to call effectful functions from `@pure` contexts.  Effect lists
are subsets of the existing 17 **SE kinds** already named in
`STDLIB/include/iii/stdlib.h` — meaning effect tracking is not a new
ontology, it is the *promotion* of an ontology III already commits to.

Concrete: `aether::write(cap: write_cap, bytes: span<u8>) -> result<u64, io_err> @effects(SE_IO_WRITE, SE_SEAL_BOUNDARY)`.

### Axiom γ — Total Termination
> Every stdlib function terminates.  Loops carry decreasing variants.
> Recursion is bounded by an explicit decreasing measure.  Allocations are
> sized.  Termination is **checked**, not assumed.

Concrete: every loop in stdlib carries a `@variant(expr)` tag the compiler
verifies strictly decreases.  Non-decreasing → compile-time rejection.
Recursion uses `@bounded(N)` or `@measure(expr)`.  This raises III to
totality status — which no other systems language has reached.

### Axiom δ — K-Chain Integrity
> Every call has a confidence value `K(call) ∈ [0,1]`.  The default floor
> is `K_floor = 0.85`.  Operations propagate K multiplicatively.  A chain
> that drops below floor either traps to Trinity for re-admission or
> compile-time-fails.

K-values are **already** in III's ontology (the user's M15 directive
mentions K ≥ 0.85 explicitly).  The stdlib is the first place they
manifest as machine-checkable types.

Concrete: every stdlib function is annotated `@k(value)`.  Composition
multiplies; the compiler propagates and checks.

### Axiom ε — Convergence Witness
> Function entry and exit emit convergence points — hashes of relevant
> execution state.  Out-of-order or missing convergences are detected.

Already proven in the deployed `iiis-sanctum`: `convergence pt =
0xb39fde3c649a6a70`.  We promote that idiom to first-class stdlib API.
Every stdlib function emits an entry/exit convergence; the runtime
maintains a stack and traps on imbalance.

### Axiom ζ — Hexad Closure
> Every type belongs to one of six canonical kinds (the **Hexad**).  No
> "any" type.  No `interface{}`.  No `void*` escape hatch.

The Hexad already gates III at compile time.  We extend it to stdlib:
every exported type is `@hexad(K)` where `K` is one of the six.  Types
that cannot be classified are rejected.  See §11 for the six kinds.

### Axiom η — Capability Authority
> No ambient authority.  Every operation that touches the outside world
> requires a capability obtained by attenuation from `env_cap`, the only
> root.

The only way to get a `write_cap` is to attenuate one from a `fs_cap`,
which attenuates from `env_cap`.  Capabilities are unforgeable, single-use
or multi-use as typed, transferable, attenuable, and **revocable via
Phantom NVRAM (PFS)**.

Concrete: `fn main(env: env_cap) -> i32` is the **only** legal main
signature.  There is no other entry point that grants authority.

---

## 2. Architecture Pattern — The Hexad-Crowned Sphere

The stdlib is structured as **six spheres + one crown**, mapped to the
Hexad and the Sanctum respectively.  This is not aesthetic.  It is
load-bearing: the six spheres correspond exactly to the six Hexad kinds,
and the crown corresponds exactly to the Sanctum surface.

```
                      ┌─────────────────────────┐
                      │       SANCTUS           │  ← Crown
                      │   (Sanctum-bound API)   │     R1.A8 / Ring -2
                      │  seal · witness · kchain│
                      │  · mandate · attest     │
                      └────────────┬────────────┘
                                   │
       ┌───────────┬───────────────┼───────────────┬───────────┐
       │           │               │               │           │
   ╔═══▼═══╗   ╔═══▼═══╗       ╔═══▼═══╗       ╔═══▼═══╗   ╔═══▼═══╗
   ║MEMORIA║   ║ VERBA ║       ║AETHER ║       ║NUMERA ║   ║TEMPORA║
   ║       ║   ║       ║       ║       ║       ║       ║   ║       ║
   ║memory ║   ║ words ║       ║boundary║      ║numbers║   ║ time  ║
   ╚═══════╝   ╚═══════╝       ╚═══════╝       ╚═══════╝   ╚═══════╝
       │           │               │               │           │
       └───────────┴───────────────┼───────────────┴───────────┘
                                   │
                              ╔════▼═════╗
                              ║  OMNIA   ║
                              ║          ║
                              ║composition║
                              ╚══════════╝
                          (option · result · vec ·
                           map · iter · fold)
```

The diagram embodies the six-fold Hexad: MEMORIA, VERBA, AETHER, NUMERA,
TEMPORA, OMNIA.  SANCTUS sits above — it is where the lower spheres
*pierce* into Ring -2 when needed.  All effects upward are sealed; all
calls downward are pure or attenuated.

### Sphere ↔ Hexad mapping (load-bearing)

| Sphere   | Hexad kind       | Domain                 | Ring level  | Sanctum seal slot used |
|----------|------------------|------------------------|-------------|------------------------|
| MEMORIA  | `kind_substance` | crystallised memory    | R0 / R-1    | (none, pure)           |
| VERBA    | `kind_form`      | semantic words         | R0          | (none, pure)           |
| AETHER   | `kind_passage`   | boundary crossing      | R-1 / R-2   | slot 2 (PFS_SET) when capability persists |
| NUMERA   | `kind_essence`   | computational atoms    | R0          | slot 4 (CRCC_KEY_EXPORT) for crypto       |
| TEMPORA  | `kind_motion`    | sealed measurement     | R-2         | slot 6 (CHRONOS_SET_EPOCH)                |
| OMNIA    | `kind_compose`   | composition primitives | R0          | (none, pure)           |
| SANCTUS  | `kind_origin`    | meta / sealing surface | R-2         | all 9 functional slots                    |

This binding is **architecturally normative** — it is the spec the
compiler enforces.  Modules outside this taxonomy are rejected at the
mandate gate (M3 — Architecture Layer Coherence).

---

## 3. SPHERE I — MEMORIA: Memory as Crystallised Intention

> "Memory is not a resource you allocate.  It is a region you receive,
> shape, and return."

### 3.1 Submodules

```
memoria.region        — capability-gated heap regions (no malloc, ever)
memoria.cell          — typed memory cells with provenance
memoria.span          — bounds-checked views over cells
memoria.arena         — bump-allocator with witness
memoria.pool          — fixed-size object pool
memoria.guard         — write-once / read-many sealed cells
memoria.sealed_alloc  — Sanctum-mediated allocation (slot-2 persistent)
```

### 3.2 The Region — primary primitive

A *region* is a contiguous, capability-gated, lifetime-tracked block.  It
is the *only* way to get heap memory.  No `malloc`, no `new`, no global
allocator.  Regions are **linear**: created once, used freely, dropped
once, and the drop is what releases the underlying bytes.

```iii
@hexad(substance) @ring(R0)
struct region_t {
    base       : u64,          /* base address (witnessable)            */
    capacity   : u64,          /* total bytes                            */
    used       : u64,          /* bump cursor                            */
    provenance : u64,          /* origin mhash (32-byte hash truncated)  */
    cap        : alloc_cap,    /* the capability that minted this        */
    sealed     : u8,           /* 1 ⇔ no further mutation permitted      */
}

@effects(SE_ALLOC) @k(0.99)
fn region_create(cap: alloc_cap, bytes: u64) -> result<region_t, alloc_err>

@effects(SE_ALLOC) @k(0.99) @linear(r)
fn region_alloc(r: region_t, n: u64, align: u64) -> result<(region_t, span<u8>), alloc_err>

@effects(SE_SEAL) @linear(r) @k(1.00)
fn region_seal(r: region_t) -> region_t          /* idempotent          */

@effects(SE_FREE) @linear(r) @k(1.00)
fn region_release(r: region_t) -> ()             /* consumes r          */
```

The `@linear(r)` modifier (new, proposed in this design) tells the
compiler `r` is consumed by the call.  Subsequent uses are compile errors.
This is how we ensure no use-after-free **without** lifetime variables
leaking to the API surface.

### 3.3 The Cell — typed pointer with provenance

A `cell<T>` is a typed handle into a region.  It carries enough metadata
that a stranger reading the value can reconstruct: which region, which
offset, which type, what was the K of the call that produced this cell.

```iii
@hexad(substance) @ring(R0)
struct cell_T {                  /* T is monomorphised via @specialize  */
    region_id  : u64,            /* truncated provenance                 */
    offset     : u64,            /* byte offset within region            */
    type_id    : u64,            /* SHA-256[0..8] of canonical type repr  */
    k          : u32,            /* K-value × 1_000_000_000 (fixed-point) */
}

@pure @k(1.00)
fn cell_witness(c: cell_T) -> witness_t          /* §6                  */

@effects(SE_LOAD) @k(0.99)
fn cell_load_T(c: cell_T) -> result<T, mem_err>

@effects(SE_STORE) @k(0.99)
fn cell_store_T(c: cell_T, v: T) -> result<(), mem_err>
```

Crucially, `cell_T` does not carry a raw pointer.  Pointer reconstruction
goes through the region table, which is itself capability-gated.  An
attacker who steals a `cell_T` value gets nothing: the region table
refuses to dereference without the matching `alloc_cap`.

### 3.4 The Span — bounds-checked view

A `span<T>` is a bounded view over contiguous cells of `T`.  Indexing is
bounds-checked at compile time when the index is constant, and at runtime
otherwise.  Out-of-bounds is a typed error, never UB.

```iii
@hexad(substance)
struct span_T {
    base : cell_T,
    len  : u64,
}

@pure @k(1.00)
fn span_len_T(s: span_T) -> u64

@effects(SE_LOAD) @k(0.99) @bounded(s.len)
fn span_at_T(s: span_T, i: u64) -> result<T, bounds_err>
```

### 3.5 The Sealed Allocation — Sanctum-bound persistence

For values that must survive a process restart (PFS-style), allocation
goes through Sanctum slot 2 (`III_SEAL_PFS_VAR_SET`).  This is the *only*
path to persistent state.  Application code never touches PFS directly —
it goes through `memoria::sealed_alloc::persist`:

```iii
@effects(SE_SEAL, SE_PERSIST) @k(0.95) @sealed(slot=2)
fn sealed_persist(cap: persist_cap, key: rune_string, bytes: span<u8>)
    -> result<persist_handle, sanctum_err>
```

The capability `persist_cap` is itself attenuated from `env_cap` and is
revocable.  Revocation marks the PFS entry `denied` — slot 3
(`III_SEAL_PFS_DENY_QUOTE`).  This is how we close the loop on Axiom η:
every persistent byte has a mintable revocation receipt.

### 3.6 No-malloc invariant — the compiler check

The compiler refuses any extern declaration of a heap allocator outside
`memoria/`.  `extern @abi(c-msvc-x64) fn malloc(...)` declared elsewhere
is a hard error.  The only legal allocator surface is the one this sphere
exposes.  This satisfies M4 (NIH) and M11 (anti-bloat).

---

## 4. SPHERE II — VERBA: Words as Semantic Units

> "A string is not a sequence of bytes.  It is the smallest computable
> unit of meaning that can survive normalisation."

### 4.1 Submodules

```
verba.rune        — UTF-32 codepoint with normalisation
verba.string      — immutable rune-sequence with witness
verba.builder     — linear-typed mutable builder (consumed once)
verba.parse       — total parsers with grammar witness
verba.format      — sealed format strings (no injection possible)
verba.normalise   — NFC / NFD / NFKC / NFKD canonicalisation
verba.collation   — culturally-neutral total ordering
verba.search      — Boyer-Moore-Galil search with witness
verba.regex       — derivative-based regex (proven total)
```

### 4.2 The Rune

```iii
@hexad(form) @ring(R0)
struct rune_t {
    cp    : u32,              /* Unicode scalar value, 0..0x10FFFF       */
    cls   : u8,               /* general category                         */
    norm  : u8,               /* NFC class                                */
}

@pure @k(1.00)
fn rune_is_assigned(r: rune_t) -> bool
fn rune_combining_class(r: rune_t) -> u8
fn rune_to_lower(r: rune_t) -> rune_t        /* full Unicode case fold  */
```

Rune is a 6-byte struct.  All 1.1M assigned codepoints fit.  Normalisation
classes are intrinsic, not table-lookup.  This makes `rune_eq_normalised`
a pure machine-code comparison.

### 4.3 The String

A `string` is **always** valid UTF-8 in storage but exposes a *rune view*
for iteration.  The bytes are immutable.  Witness is mandatory.

```iii
@hexad(form)
struct string_t {
    bytes      : span<u8>,        /* immutable, always valid UTF-8       */
    rune_count : u64,
    nfc        : u8,              /* 1 ⇔ already in NFC                  */
    witness    : witness_t,       /* who minted these bytes              */
}

@pure @k(1.00) fn string_byte_len(s: string_t) -> u64
@pure @k(1.00) fn string_rune_count(s: string_t) -> u64

@effects(SE_LOAD) @k(0.99) @bounded(s.rune_count)
fn string_rune_at(s: string_t, i: u64) -> result<rune_t, bounds_err>

@effects(SE_NORM) @k(0.99)
fn string_to_nfc(cap: arena_cap, s: string_t) -> result<string_t, norm_err>

@pure @k(0.99)
fn string_eq_canonical(a: string_t, b: string_t) -> bool
```

`string_eq_canonical` is the equality every other language gets wrong —
NFC-normalised, full case-folded, locale-neutral, deterministic across
rebuilds.  In III, this is the **default** equality.  Byte equality is
available as `string_eq_bytes` and warns at compile time unless
`@modifier(byte_eq)` is set.

### 4.4 The Builder — linear mutability

You cannot mutate strings.  But you can *build* new ones via a linear
builder.  The builder consumes itself on `seal`:

```iii
@hexad(form) @linear
struct builder_t {
    arena   : arena_cap,
    chunks  : span<chunk_t>,
    n       : u64,
}

@effects(SE_ALLOC)
fn builder_new(cap: arena_cap, hint: u64) -> result<builder_t, alloc_err>

@linear(b) @effects(SE_ALLOC)
fn builder_push_string(b: builder_t, s: string_t) -> result<builder_t, alloc_err>

@linear(b) @effects(SE_ALLOC)
fn builder_push_rune(b: builder_t, r: rune_t) -> result<builder_t, alloc_err>

@linear(b) @effects(SE_SEAL)
fn builder_seal(b: builder_t) -> result<string_t, alloc_err>
```

After `builder_seal(b)`, the variable `b` is unusable.  The compiler
guarantees no aliasing, no double-seal, no use-after-seal.

### 4.5 Sealed Format Strings — no injection, ever

`printf` is a class of CVE.  III's stdlib eliminates the class by making
format strings **sealed at compile time**:

```iii
let s : string_t = verba::fmt!("hello, ${name} on ${host}", name=u, host=h)
```

The `fmt!` macro:
1. Lexes the format string at compile time.
2. Validates that every `${var}` has a matching keyword arg of compatible
   type.
3. Emits direct calls to `builder_push_*` — *no runtime format string
   parsing*.

Result: format-string injection is **structurally impossible**.  No
`%n`-style write primitive.  No escape needed because there is no parser
at runtime.

### 4.6 Total Parsers — derivative-based regex

Regex engines are infamous for catastrophic backtracking.  III's regex is
**Brzozowski derivative-based**, total by construction, linear in input
length, and emits a *grammar witness* — a hash of the canonical regex
form, sealed with the parse result.

```iii
@hexad(form)
struct regex_t {
    canonical : string_t,    /* canonical AST form, hashable             */
    witness   : witness_t,
}

@pure @k(1.00)
fn regex_compile(s: string_t) -> result<regex_t, regex_err>

@pure @k(0.99) @bounded(input.byte_len)
fn regex_match(r: regex_t, input: string_t) -> result<match_t, no_match>
```

The `@bounded(input.byte_len)` annotation tells the compiler the function
runs in O(input.len × |r.canonical|) — provably linear.  Catastrophic
backtracking is structurally impossible.

---

## 5. SPHERE III — AETHER: Boundaries Between Worlds

> "I/O is not a function call.  It is a sealed crossing between an inside
> and an outside, and both sides know it happened."

### 5.1 Submodules

```
aether.capability  — capabilities are first-class values
aether.handle      — abstract resource (file/socket/pipe) with linearity
aether.read        — capability-gated, effect-tracked
aether.write       — capability-gated, effect-tracked
aether.fs          — filesystem ops, attenuated from env_cap
aether.net         — network ops, attenuated from env_cap
aether.proc        — process ops (exec, env, args)
aether.boundary    — Sanctum-sealed crossing primitives
aether.witness     — every IO op produces an audit trail
```

### 5.2 Capability Algebra

```iii
@hexad(passage) @ring(R-1)
struct cap_t {
    cap_id      : u64,           /* unforgeable, monotonic               */
    rights      : u64,           /* bitmask of allowed ops               */
    revocation  : u64,           /* PFS key for revocation receipt        */
    parent      : u64,           /* parent cap_id, 0 = env                 */
    expires     : tempora::instant_t,
    witness     : witness_t,
}

/* Attenuation: derive a cap with fewer rights, same/earlier expiry */
@pure @k(0.99)
fn cap_attenuate(parent: cap_t, mask: u64, until: tempora::instant_t)
    -> result<cap_t, cap_err>

/* Revoke via Sanctum slot 3 */
@effects(SE_SEAL, SE_REVOKE) @sealed(slot=3) @k(0.95)
fn cap_revoke(authority: cap_t, target_id: u64) -> result<(), sanctum_err>

/* Verify at use site (compiler-injected at every IO call) */
@pure @k(1.00)
fn cap_verify(c: cap_t, op: u64, now: tempora::instant_t) -> bool
```

The capability lattice is **the** authority model.  There is no
`O_CREAT`-flag-style ad-hoc; each verb is a separate cap right bit, each
attenuation is a typed reduction.  The PFS revocation receipt makes
revocation **observable** — a third party verifying a signed quote knows
which caps existed at which epoch.

### 5.3 Handles — linear resources

A handle is a linear value.  Closing it consumes it.  Forgetting it is a
compile error (the compiler's escape analysis tracks handle linearity).

```iii
@hexad(passage) @linear @ring(R-1)
struct handle_t {
    kind        : u8,           /* 1=file, 2=socket, 3=pipe, ...        */
    fd          : u64,           /* OS-level handle (opaque)             */
    cap         : cap_t,
    expires     : tempora::instant_t,
    witness     : witness_t,
}

@effects(SE_IO_OPEN) @k(0.95)
fn fs_open(cap: fs_cap, path: string_t, mode: u64)
    -> result<handle_t, io_err>

@effects(SE_IO_READ) @linear(h) @k(0.95)
fn read(h: handle_t, dst: span<u8>) -> result<(handle_t, u64), io_err>

@effects(SE_IO_CLOSE) @linear(h) @k(1.00)
fn close(h: handle_t) -> result<(), io_err>
```

The `@linear(h)` tag on `read` is structural: every read returns a *new*
handle.  This makes handle state unambiguous — there is no shared mutable
file descriptor.  Each read transitions the handle to a new state, and
the old handle name is consumed.

This is identical in spirit to Rust's `&mut T` discipline but expressed
without lifetimes, because we never hand out references — we hand out
new values.

### 5.4 Sealed Boundaries

Some IO crosses Ring -2: persistent secrets, key export, attestation
quotes.  Those go through Sanctum:

```iii
@effects(SE_SEAL, SE_CRYPTO) @sealed(slot=4) @k(0.95)
fn crcc_export_key(authority: kms_cap, cycle_root: u64)
    -> result<key_t, sanctum_err>
```

The `@sealed(slot=4)` modifier:
1. Tells the compiler this fn must be invoked through `iii_sanctum_call`.
2. Refuses inlining (the body is a pure trampoline call).
3. Emits a runtime check that the Sanctum runtime is initialised.
4. Records the call in the sanctum frame stack for later attestation.

### 5.5 Witness Trail

Every IO op emits a `witness_event_t` to a per-process append-only
witness log.  The log is itself capability-gated and rotates via Phoenix
bookmarks (slot 8).  An auditor can replay the log to verify that every
byte read, every byte written, every cap attenuation, every cap
revocation occurred in causal order.

```iii
@hexad(passage)
struct witness_event_t {
    seq       : u64,             /* monotonic per process                */
    when      : tempora::instant_t,
    cap_id    : u64,
    op        : u64,
    bytes     : u64,
    target    : u64,             /* truncated mhash of target identity   */
    cause     : u64,             /* prior event seq (causality link)     */
    sig       : u8[32],          /* HMAC-SHA256 with sealed CRCC key     */
}

@pure @k(1.00)
fn witness_chain_verify(events: span<witness_event_t>, root: u8[32])
    -> bool
```

This is what makes III's IO surface *attestable*.  Other languages' IO is
a black box; III's IO comes with a receipt.

---

## 6. SPHERE IV — NUMERA: Numbers as Computational Essences

> "There is no `int`.  There is `i32`, `u64`, `q128`, `bigint`, `Fp`.
> Each is an essence with its own laws.  Mixing them without thought is
> a category error."

### 6.1 Submodules

```
numera.scalar       — i32/i64/u32/u64 with overflow semantics declared
numera.q128         — 128-bit rational with explicit (num, den) form
numera.bigint       — arbitrary-precision integers (NIH-mandated)
numera.field        — finite-field arithmetic (Fp, F2^n)
numera.crypt        — sealed cryptographic primitives
numera.modular      — modular arithmetic with explicit modulus type
numera.fixed        — fixed-point arithmetic for time/rates
numera.checked      — overflow-checked variants of every op
```

Note: **no float**.  III does not include IEEE-754 floats in stdlib.  This
is deliberate (M21 dialect rule).  Decimal/rate computation uses `q128`;
fixed-point uses `numera.fixed`; signal/DSP code uses bigint with
explicit precision.  This eliminates the entire class of float-related
non-determinism.

### 6.2 Q128 — exact rational

```iii
@hexad(essence)
struct q128_t {
    num : i128,                  /* signed numerator                     */
    den : u128,                  /* unsigned denominator, > 0 invariant  */
    /* invariant: gcd(|num|, den) == 1 (canonical form)                  */
}

@pure @k(1.00)
fn q128_add(a: q128_t, b: q128_t) -> q128_t
fn q128_mul(a: q128_t, b: q128_t) -> q128_t
fn q128_div(a: q128_t, b: q128_t) -> result<q128_t, divbyzero>
fn q128_eq(a: q128_t, b: q128_t) -> bool
fn q128_cmp(a: q128_t, b: q128_t) -> ordering_t
```

Q128 covers ~2^127 / ~2^127 — enough for any rational computation that
fits in a quantum of memory.  Overflow is a typed error (`q128_overflow`)
not UB.  This is the rational regime; for irrationals, use bigint
algebraic numbers.

### 6.3 Bigint — NIH arbitrary precision

```iii
@hexad(essence)
struct bigint_t {
    sign     : i8,
    limbs    : span<u64>,        /* little-endian, normalised (top != 0) */
    arena    : arena_cap,        /* lifetime-bound to arena              */
    witness  : witness_t,
}

@effects(SE_ALLOC) @k(0.99)
fn bigint_from_str(cap: arena_cap, s: string_t)
    -> result<bigint_t, parse_err>

@effects(SE_ALLOC) @k(0.99)
fn bigint_add(cap: arena_cap, a: bigint_t, b: bigint_t)
    -> result<bigint_t, alloc_err>

@effects(SE_ALLOC) @k(0.99)
fn bigint_modpow(cap: arena_cap, base: bigint_t, exp: bigint_t,
                 modulus: bigint_t) -> result<bigint_t, math_err>
```

All algorithms hand-rolled (M4 NIH).  Addition is schoolbook,
multiplication switches to Karatsuba above 64 limbs, then Toom-3 above
256, then Schönhage–Strassen via NTT above 4096.  The choice point is
a `@specialize` site: the compiler can pin the chosen algorithm at
build time.

### 6.4 Sealed Cryptography

Cryptographic primitives that touch keys go through Sanctum.  The stdlib
exposes only primitives that DO NOT touch keys (hashes, public-side
verify) directly; key-touching ops require Sanctum slot 4.

```iii
/* Direct (no Sanctum) — pure functions of inputs */
@pure @k(1.00) fn sha256(input: span<u8>) -> u8[32]
@pure @k(1.00) fn sha3_256(input: span<u8>) -> u8[32]
@pure @k(1.00) fn blake3(input: span<u8>) -> u8[32]
@pure @k(1.00) fn hmac_sha256(key_pub: span<u8>, msg: span<u8>) -> u8[32]
@pure @k(1.00) fn ed25519_verify(pub_key: u8[32], msg: span<u8>,
                                  sig: u8[64]) -> bool

/* Sealed — touches sealed keys, must go through slot 4 */
@effects(SE_SEAL, SE_CRYPTO) @sealed(slot=4) @k(0.95)
fn ed25519_sign_sealed(authority: signing_cap, msg: span<u8>)
    -> result<u8[64], sanctum_err>
```

This split is the key insight: **public-side verification needs no
authority, no sealing, no capability**.  Private-side signing needs all
three.  Most languages bundle them; III separates them at the type level.

### 6.5 Finite Fields

For ZK pruning and crypto algebra:

```iii
@hexad(essence)
struct fp_t {                        /* element of Fp                   */
    val      : bigint_t,
    modulus  : *const bigint_t,      /* pointer to shared modulus       */
}

@pure @k(1.00)
fn fp_add(a: fp_t, b: fp_t) -> result<fp_t, field_err>
fn fp_mul(a: fp_t, b: fp_t) -> result<fp_t, field_err>
fn fp_inv(a: fp_t) -> result<fp_t, field_err>     /* Fermat / extended  */
fn fp_pow(a: fp_t, n: bigint_t) -> result<fp_t, field_err>
```

This unlocks the ZK-PRUNING subsystem to be written *in* III rather than
escaping to C.

---

## 7. SPHERE V — TEMPORA: Sealed Time

> "Time is not measured.  Time is witnessed.  An unsealed timestamp is
> as forgeable as a sentence in a language without grammar."

### 7.1 Submodules

```
tempora.instant     — sealed monotonic instant
tempora.duration    — typed duration
tempora.deadline    — first-class deadlines
tempora.witness     — every time read is sealed
tempora.cycle       — Trinity sealed-cycle integration
tempora.calendar    — civil time, with explicit timezone capability
tempora.epoch       — epoch arithmetic (Sanctum-bound)
```

### 7.2 The Instant — sealed

```iii
@hexad(motion) @ring(R-2)
struct instant_t {
    /* Monotonic counter from Sanctum runtime - cannot regress           */
    mono     : u64,
    /* Epoch the instant was minted in (slot 6)                          */
    epoch    : u64,
    /* HMAC of (mono, epoch, cap_id) under sealed CRCC sub-key            */
    seal     : u8[16],          /* truncated to 128 bits                  */
}

@effects(SE_SEAL, SE_TIME) @sealed(slot=6) @k(0.95)
fn now_sealed(cap: time_cap) -> result<instant_t, sanctum_err>

@pure @k(1.00)
fn instant_verify(i: instant_t, current_epoch: u64) -> bool

@pure @k(1.00)
fn instant_diff(later: instant_t, earlier: instant_t)
    -> result<duration_t, time_err>
```

`now_sealed` is the **only** way to obtain the current time.  The result
is a sealed token that any verifier can check (`instant_verify`).  An
attacker who fabricates a time value cannot forge the seal without the
CRCC sub-key.

This makes III the first language where **timestamps cannot lie**.

### 7.3 Duration — typed

```iii
@hexad(motion)
struct duration_t {
    nanos    : i128,             /* signed nanoseconds                   */
    /* witness recoverable from the two instants that produced this     */
}

@pure @k(1.00)
fn duration_add(a: duration_t, b: duration_t) -> result<duration_t, overflow>
fn duration_to_seconds_q128(d: duration_t) -> q128_t
```

### 7.4 Deadline — first class

A *deadline* is an instant + a payload.  Operations carry deadlines.  The
runtime traps when a deadline is exceeded — no silent timeout.

```iii
@hexad(motion)
struct deadline_t {
    expires  : instant_t,
    on_late  : late_action_t,    /* TRAP / ABORT / RETURN_ERR             */
}

@effects(SE_TIME) @k(0.99)
fn deadline_check(d: deadline_t, now: instant_t) -> result<(), deadline_err>
```

### 7.5 Trinity Cycle Integration

Trinity uses sealed cycles.  Each cycle has a Sanctum-tracked epoch.
`tempora.cycle` exposes the cycle as a typed value:

```iii
@hexad(motion) @ring(R-2)
struct trinity_cycle_t {
    cycle_id     : u64,
    epoch        : u64,
    convergence  : u64,          /* §epoch convergence point             */
    layer        : u8,           /* 1, 2, or 3                           */
}

@effects(SE_SEAL) @sealed(slot=6) @k(1.00)
fn cycle_advance(cap: epoch_cap) -> result<trinity_cycle_t, sanctum_err>
```

This is the integration point that makes III's time model directly
attestable in DRTM quotes.

---

## 8. SPHERE VI — OMNIA: Composition over Collections

> "There are not 100 collection types.  There are 6 composition
> primitives, and the rest are projections."

### 8.1 Submodules

```
omnia.option    — null-safe optional with witness
omnia.result    — error-as-value with provenance (crystallised errors)
omnia.either    — sum type, sealed
omnia.vec       — bounded growable array with proof
omnia.map       — hash map with cryptographic integrity
omnia.set       — sets via map<T, ()>
omnia.queue     — bounded FIFO with arrival witness
omnia.pq        — priority queue (binary heap) with key witness
omnia.iter      — total iterators (no infinite iterators)
omnia.fold      — sealed accumulation
omnia.zip       — bounded zipping (proves length-equal)
```

### 8.2 Option — null-safe

```iii
@hexad(compose)
@discriminated(tag, 0=none, 1=some)
union option_T {
    none : (),
    some : T,
}

@pure @k(1.00)
fn option_unwrap_or_T(o: option_T, default: T) -> T

@pure @k(1.00)
fn option_map_T_U(o: option_T, f: fn_T_U) -> option_U
```

Note: III has no closures (M21 dialect), so `option_map_T_U` takes a
*function pointer* `fn_T_U`, not a closure.  Functor laws still hold
because function pointers are total.  The compiler verifies the function
pointer's signature at the call site.

### 8.3 Result — crystallised error

The error half is a **crystal** — it cannot be forged or have its
provenance erased:

```iii
@hexad(compose)
@discriminated(tag, 0=ok, 1=err)
union result_T_E {
    ok  : T,
    err : crystal_E,             /* §9                                   */
}
```

A `crystal_E` carries: error code, source span where minted, witness of
the call chain, K-value at error site, and an HMAC over the above.  The
auditor can verify that a returned error was actually minted at the
claimed site by the claimed call.

### 8.4 Vec — bounded growable

```iii
@hexad(compose) @linear
struct vec_T {
    arena    : arena_cap,        /* lifetime owner                       */
    data     : span<T>,
    len      : u64,
    cap      : u64,
    max      : u64,              /* hard cap; growth above traps          */
    witness  : witness_t,
}

@effects(SE_ALLOC) @k(0.99)
fn vec_new_T(cap: arena_cap, max: u64) -> result<vec_T, alloc_err>

@effects(SE_ALLOC) @linear(v) @k(0.99)
fn vec_push_T(v: vec_T, x: T) -> result<vec_T, alloc_err>

@pure @bounded(v.len) @k(1.00)
fn vec_at_T(v: vec_T, i: u64) -> result<T, bounds_err>
```

Note `@max`: every `vec` declares its hard upper bound at construction.
This makes denial-of-service via unbounded allocation **structurally
impossible**.

### 8.5 Map — cryptographically integrity-checked

```iii
@hexad(compose) @linear
struct map_K_V {
    arena      : arena_cap,
    buckets    : span<bucket_K_V>,
    len        : u64,
    salt       : u64,            /* keyed-hash defence vs flooding       */
    integrity  : u8[16],         /* MAC over current state               */
    witness    : witness_t,
}
```

The keyed-hash salt is per-map, derived from the arena id + a fresh
`witness`.  This prevents the entire class of hash-flooding attacks
without requiring the user to know about it.

The `integrity` field is updated on every mutation.  An attacker who
swaps a map's bytes in memory must forge the MAC — which requires the
sealed key only Sanctum holds.

### 8.6 Total Iterators

Every iterator declares a bound:

```iii
@hexad(compose)
struct iter_T_N {                /* bound N is a const-generic          */
    state    : u64,
    next     : fn_iter_step_T,
    bound    : u64,              /* invariant: ≤ N                       */
}

@pure @bounded(N) @k(1.00)
fn iter_next_T_N(it: iter_T_N) -> option_T_iter_T_N
```

The `@bounded(N)` pushes the iteration limit to the type level.  The
compiler refuses to construct an unbounded iterator.  This eliminates
the entire class of "iterator that runs forever" bugs.

---

## 9. THE CROWN — SANCTUS: The Meta-Sphere

> "When the lower spheres need to pierce Ring -2, they call here.  This
> is the only sphere that knows the Sanctum's true name."

### 9.1 Submodules

```
sanctus.seal       — direct access to Trinity sealing
sanctus.witness    — witness manipulation
sanctus.kchain     — K-value tracking and propagation
sanctus.mandate    — runtime mandate checking (M1..M21)
sanctus.attest     — attestation primitives (DRTM quotes, etc.)
sanctus.mhash      — domain-separated SHA-256 (already in witness_alloc.iii)
sanctus.epoch      — epoch read / advance (slot 6)
sanctus.compile    — invoke slot 9 from inside III itself
```

### 9.2 The Witness API

A witness is a 64-byte sealed token:

```iii
@hexad(origin) @ring(R-2)
struct witness_t {
    /* 64 bytes total, deterministically derivable from the value       */
    derivation_mhash : u8[32],   /* hash of the call tree producing v    */
    cap_id           : u64,      /* authority under which v was minted   */
    epoch            : u64,
    convergence      : u64,
    k_fixed          : u64,      /* K × 1e18 (exact)                     */
    seal             : u8[8],    /* HMAC truncated                       */
}

@pure @k(1.00)
fn witness_compose(a: witness_t, b: witness_t) -> witness_t

@pure @k(1.00)
fn witness_verify(w: witness_t, current_epoch: u64) -> bool

@effects(SE_SEAL) @sealed(slot=4) @k(1.00)
fn witness_mint(authority: witness_cap, mhash: u8[32], k: q128_t)
    -> result<witness_t, sanctum_err>
```

`witness_compose` follows the algebra: `compose(a, b)` represents
"first a, then b".  The `derivation_mhash` becomes
`SHA256(a.derivation_mhash || b.derivation_mhash || "compose")`.  This is
**associative** but **not commutative** — which is correct because
causality has direction.

### 9.3 K-Chain Tracking

```iii
@hexad(origin)
struct kchain_t {
    floor      : u32,            /* K_floor × 1_000_000_000              */
    current    : u32,            /* current K product, fixed-point        */
    underflow  : u8,             /* 1 ⇔ chain has dropped below floor    */
    re_admits  : u32,            /* count of Trinity re-admissions       */
}

@pure @k(1.00)
fn kchain_compose(c: kchain_t, k_call: q128_t) -> kchain_t

@effects(SE_SEAL) @sealed(slot=1) @k(1.00)
fn kchain_re_admit(authority: trinity_cap, c: kchain_t)
    -> result<kchain_t, sanctum_err>
```

When a call's K product drops below floor, the runtime traps to Trinity
admission (slot 1, `III_SEAL_DRTM_RELAUNCH`).  After re-admission the
chain restarts at K=1.  This is the **only** mechanism by which a chain
can recover.  Otherwise the entire dependent computation is poisoned.

### 9.4 Mandate Checking — runtime gate

The 21 mandates have semantic meaning the compiler can partially check.
Some require runtime checks; those go here:

```iii
@pure @k(1.00)
fn mandate_check_k_chain(c: kchain_t) -> bool       /* M1                */

@effects(SE_LOAD) @k(1.00)
fn mandate_check_axiom_compliance() -> bool         /* M2                */

@effects(SE_LOAD) @k(1.00)
fn mandate_check_no_stubs(mod_root: ast_node) -> bool   /* M11           */
```

A program can call these to self-attest.  The compiler embeds the same
checks at `iiis-2` build time.

### 9.5 Attestation

```iii
@hexad(origin)
struct attestation_t {
    drtm_quote    : drtm_quote_t,        /* 312 bytes per spec §4         */
    closure_root  : u8[32],              /* compiler closure mhash        */
    federation    : federation_tier_t,
    cycle         : trinity_cycle_t,
    sig           : u8[64],              /* Ed25519 over the above        */
}

@effects(SE_SEAL, SE_CRYPTO) @sealed(slot=1) @k(1.00)
fn attest_self(cap: attest_cap) -> result<attestation_t, sanctum_err>
```

This is the *system's* answer to "who am I, and how do you know?"  The
caller hands back a 312-byte quote signed by the silicon fingerprint
plus all relevant root hashes.  This is the substrate of III's
sovereign-web identity.

---

## 10. CROSS-CUTTING — THE TYPE SYSTEM EXTENSIONS

The above modules require the language to understand a small set of new
*modifiers* and *type forms*.  These extensions are minimal and fit the
existing 19-modifier ontology.

### 10.1 New modifiers (proposed additions to the 19)

| Modifier             | Purpose                                                                                                         |
|----------------------|-----------------------------------------------------------------------------------------------------------------|
| `@linear`            | Marks a struct or argument as linear (consumed once).                                                            |
| `@linear(name)`      | Marks a specific argument as linear when applied to a fn.                                                        |
| `@k(value)`          | Declares the K-value of a function (default 0.99).                                                               |
| `@effects(SE_*)`     | Declares the SE-kind effect set.  Caller's effect set must be ⊇.                                                 |
| `@sealed(slot=N)`    | Declares this fn must be invoked through Sanctum slot N.                                                          |
| `@bounded(expr)`     | Declares the iteration / recursion bound for totality checking.                                                  |
| `@variant(expr)`     | Declares the loop variant for totality checking.                                                                 |
| `@measure(expr)`     | Declares the recursion measure for totality checking.                                                            |
| `@hexad(kind)`       | Asserts the value belongs to a specific Hexad kind.                                                              |
| `@discriminated(...)` | Declares a tagged union with explicit tag values.                                                                 |
| `@specialize(K=T)`    | Compile-time monomorphisation (replaces parametric polymorphism).                                                |
| `@pure`              | Asserts no effects (subset of `@effects()`).                                                                     |
| `@inline_disabled`   | Refuses inlining (used for sealed boundaries).                                                                   |
| `@witness_required`  | Declares this fn produces a witness; callers must propagate.                                                     |
| `@cap(name)`         | Declares this argument is a capability of given name.                                                            |

This brings the modifier count from 19 to ~34.  This is a deliberate
language evolution gated by mandate review; each modifier earns its
place by closing a class of failure mode.

### 10.2 Monomorphisation via `@specialize`

The dialect rule is "no generics."  But the stdlib genuinely needs
parametric types (`vec_T`, `option_T`, `cell_T`).  The resolution: there
are **no generic functions at runtime**.  Every parametric form is
*explicitly* specialised at build time.

```iii
@specialize(T = u8)
@specialize(T = u32)
@specialize(T = u64)
@specialize(T = string_t)
@specialize(T = rune_t)
struct vec_T { ... }
```

The compiler emits one concrete struct + one concrete set of fns per
specialisation.  At call sites, the *concrete* name is used:

```iii
let v : vec_u32 = omnia::vec_new_u32(cap, 1024)
```

This is **not** runtime polymorphism, **not** vtable dispatch, **not**
template instantiation in the C++ sense.  It is simple textual
specialisation, like Ada generics, with explicit instantiation per type.

This satisfies M21 (no generics) by interpretation: there is no
parametric polymorphism *at runtime*.  Compile-time specialisation is a
separate, explicit, mandate-reviewed feature.

### 10.3 Effect Inference

Effect annotations propagate.  A function with no `@effects(...)`
annotation defaults to `@pure` for stdlib (strict).  For user code, the
default is `@effects(infer)` — the compiler infers the union of all
called functions' effects and writes them into the signature.

The user can **tighten** but never **loosen**: `@pure` declared but
inferred to include `SE_IO_READ` is a compile error.

---

## 11. THE HEXAD — Formal Definition

The Hexad is mentioned across III but never formally enumerated in the
existing public spec.  This design fixes the kinds:

| #  | Name             | Symbol     | Domain                                       | Sphere    |
|----|------------------|-----------|----------------------------------------------|-----------|
| 1  | `kind_substance` | □         | crystallised state, memory, persistent forms | MEMORIA   |
| 2  | `kind_form`      | ◇         | linguistic / textual / semantic              | VERBA     |
| 3  | `kind_passage`   | ⊳         | crossings, IO, capabilities                  | AETHER    |
| 4  | `kind_essence`   | ●         | computational atoms, numbers                 | NUMERA    |
| 5  | `kind_motion`    | ↻         | time, change, deadlines                      | TEMPORA   |
| 6  | `kind_compose`   | ⊕         | composition, collections, control flow       | OMNIA     |
| 7* | `kind_origin`    | ✶         | meta, sealing, attestation (the Crown)       | SANCTUS   |

The "+1" (kind_origin) is the seventh — but it sits **above** the Hexad,
not within it.  No user-defined type may claim `kind_origin`; only stdlib
types under SANCTUS hold it.  This is the architectural reason there are
six spheres + one crown rather than seven equal spheres.

This taxonomy is **closed**: every type fits in exactly one bucket.  A
type that doesn't fit is rejected.  This is M3 (Architecture Layer
Coherence) made operational.

---

## 12. WITNESS ARCHITECTURE — Deep Dive

Witnesses are the load-bearing innovation.  No other systems language
has them as a first-class artifact.  This section specifies their
algebra.

### 12.1 The Three Laws

**Law 1 (closure):** Every value `v: T` produced by stdlib has an
associated `w: witness_t` recoverable in O(1).

**Law 2 (composition):** For `c = f(a, b)`, `witness(c) =
compose(witness(a), witness(b), site(f))` where `compose` is associative.

**Law 3 (verifiability):** For any witness `w` and current epoch `e`,
`witness_verify(w, e) ∈ {true, false}` is decidable in O(1).

### 12.2 Witness Storage

Witnesses are NOT inlined into every value (that would explode size).
Instead, they live in a per-arena *witness chain*:

```
arena   →   chain_root (32-byte mhash)
            ↓
         ┌──┴──┐
         │  w₁ │  derivation: f₁(...)
         ├─────┤
         │  w₂ │  derivation: f₂(w₁, ...)
         ├─────┤
         │  w₃ │  derivation: f₃(w₂, ...)
         └─────┘
```

Each value `v` carries only an 8-byte chain index.  The chain itself is
append-only and sealable.  At process exit, the chain root can be
attested (via slot 1 DRTM relaunch) and survives in the Sanctum frame
list.

### 12.3 Witness as the new GC

Note what this implicitly gives us: the witness chain *is* a structural
form of garbage collection — anything whose witness is unreachable from
the chain root is dead.  A future stdlib version can offer
`memoria::compact` that walks the chain and physically reclaims regions
whose witnesses are unreferenced.

This is a GC without a GC pause, without a runtime, without barriers,
without writes-tracking — because the only path to memory is through a
witness, and witnesses are explicit.  *Provenance-derived garbage
collection.*  No other language has this.

---

## 13. CAPABILITY SYSTEM — The `env_cap` Tree

There is exactly one root capability: `env_cap`.  Every other capability
is derived by attenuation.

```
env_cap (root, given to main(env: env_cap))
├── alloc_cap          (allow heap allocation)
│   └── arena_cap     (allow allocation in a specific arena)
├── fs_cap            (filesystem authority)
│   ├── read_cap     (specific path, read-only)
│   └── write_cap    (specific path, write)
├── net_cap           (network authority)
│   └── dial_cap     (specific host, dial)
├── time_cap          (time read; sealed via slot 6)
├── persist_cap       (PFS read/write; sealed via slot 2/3)
├── attest_cap        (DRTM quote production; sealed via slot 1)
├── crypto_cap        (CRCC key export; sealed via slot 4)
└── chronos_cap       (epoch advance; sealed via slot 6)
```

Every program declares which leaves of this tree it requires; the
runtime grants them at startup based on a manifest hashed into the
binary's mhash.  An attacker who tries to invoke a sealed function
without the matching cap gets a Trinity rejection at admit time.

This is **stronger than Linux capabilities**, **stronger than seL4**,
**stronger than Fuchsia handles** because the capability is a *value*
inside the type system, not an opaque kernel handle.  The compiler can
see it, attenuate it, reject misuse statically.

---

## 14. CONCURRENCY MODEL — Causally-Ordered Sealed Calls

III's stdlib does not include traditional threads, mutexes, or async
runtimes.  Concurrency is structured around **causality witnesses** —
each operation carries a `cause` that points to the prior op it depends
on.  Operations with no cause-relation can run in parallel.

```iii
@hexad(motion)
struct causality_t {
    seq        : u64,
    cause      : u64,                    /* prior op seq                 */
    convergence: u64,
    witness    : witness_t,
}
```

The Trinity admission check already includes `causality_witness[16]` —
this is the substrate.  The stdlib exposes:

- `omnia::par_map_T_U` — runs `f: fn_T_U` over a vec, returning a vec.
  Operations are independent (no cause-relation between elements), so
  they may run in any order or in parallel.  The result has a witness
  that records the parallelism schedule.
- `aether::concurrent_io` — runs IO ops with explicit cause-tracking.
  Two ops with no cause-relation may execute in any order.  The witness
  chain records the actual execution order.

There are no mutexes because there is no shared mutable state — every
mutation produces a new value (the linear discipline).  There is no
deadlock because there are no locks.  There is no data race because there
is no aliased mutability.

This is a **deterministic by default** concurrency model.  Replaying the
same program with the same inputs produces the same witness chain.  A
non-deterministic schedule is rejected: it would produce a different
chain root, which would not match the closure attestation, which the
runtime checks at exit.

---

## 15. ERROR MODEL — Crystallised Errors

III has no exceptions.  Errors are values.  But values can lie:
attackers can substitute bytes.  The stdlib's answer is **crystallised
errors** — errors that carry their derivation:

```iii
@hexad(form) @crystal
struct crystal_E {
    code         : E,                /* the error code                   */
    site         : source_span_t,    /* file/line/col where minted        */
    cap_id       : u64,              /* authority context                 */
    cause        : u64,              /* prior witness seq                 */
    k            : q128_t,           /* K at error site                   */
    msg_witness  : witness_t,        /* hash of the human-readable msg   */
    sig          : u8[16],           /* HMAC truncated                    */
}
```

The `@crystal` modifier (new) tells the compiler:
1. The struct is immutable after construction.
2. The constructor must be a `@sealed(slot=4)` function (HMAC requires
   the sealed CRCC sub-key).
3. Field access is read-only at the API surface.

A crystal cannot be forged in user code because the `sig` field requires
the sealed key.  An attacker who fabricates a fake error fails the
`crystal_verify` check.  This means error logs become **attestable**:
every error in the system can be traced back to the call that minted it.

---

## 16. IMPLEMENTATION ROADMAP

### Phase A — Foundations (8 weeks)

A1. `@specialize`, `@linear`, `@k`, `@effects` modifiers in compiler.
A2. `STDLIB/iii/memoria/region.iii` — region, cell, span (no Sanctum yet).
A3. `STDLIB/iii/verba/string.iii` — string, rune (no normalisation yet).
A4. `STDLIB/iii/verba/builder.iii` — linear builder.
A5. `STDLIB/iii/numera/scalar.iii` — wrapping/checked scalar ops.
A6. `STDLIB/iii/omnia/option.iii`, `omnia/result.iii` (no crystals yet).
A7. Conformance corpus for Phase A: 25 tests under `STDLIB/corpus/`.
A8. Re-bootstrap: `iiis-3.exe` rebuilt using stdlib for compiler internals.

**Gate:** corpus 25/25 byte-equivalent across stages; mhash unchanged
for compiler closure (no regression in `iiis-2/iiis-3`).

### Phase B — Composition (6 weeks)

B1. `@hexad`, `@bounded`, `@variant` totality checking in compiler.
B2. `omnia/vec.iii`, `omnia/map.iii`, `omnia/set.iii`, `omnia/iter.iii`.
B3. `numera/q128.iii`, `numera/bigint.iii`.
B4. `verba/parse.iii` (derivative regex), `verba/format.iii` (sealed fmt).
B5. Conformance corpus extension: 25 → 60 tests.

**Gate:** all 60 tests pass; totality checker rejects 10 known-bad
cases; bigint round-trips equal C reference impl.

### Phase C — Sealed Surface (8 weeks)

C1. `@sealed(slot=N)`, `@cap(name)`, `@witness_required` in compiler.
C2. `aether/capability.iii`, `aether/handle.iii`, `aether/fs.iii`.
C3. `tempora/instant.iii`, `tempora/cycle.iii` — Sanctum-bound.
C4. `sanctus/witness.iii`, `sanctus/seal.iii` — Crown.
C5. PFS-backed capability revocation via slot 3.
C6. Conformance corpus extension: 60 → 100 tests, 30 of which are
    sealed-call sweeps.

**Gate:** every sealed-call test passes through `iiis-sanctum`; every
witness chain is verifiable; capability revocation observable in PFS.

### Phase D — Crystallisation (4 weeks)

D1. `@crystal` modifier, crystal_E type.
D2. All stdlib errors converted to crystals.
D3. `sanctus/mandate.iii` runtime mandate checks.
D4. `sanctus/attest.iii` self-attestation.
D5. Phoenix bookmark integration for stdlib state checkpoint.

**Gate:** every error returned by stdlib is a verifiable crystal;
`attest_self` produces a valid 312-byte DRTM quote.

### Phase E — Compiler Retrofit (10 weeks)

E1. Compiler ports (`cg_r3`, `lex`, etc.) migrate from C externs to
    stdlib calls.
E2. Hand-rolled SHA-256 in `witness_alloc.iii` replaced by
    `numera::sha256` import.
E3. AST byte-buffer accessors replaced by `memoria::span` + `cell`.
E4. Linear types let the compiler eliminate the `iii_ast_load_u8` C
    helper entirely.
E5. Re-bootstrap to `iiis-4.exe`; `mhash(iiis-4) == mhash(iiis-3)`.

**Gate:** `iiis-4` is byte-equal to `iiis-3` on every conformance
program AND `iiis-4` is fully self-hosted with **no C externs from
stdlib**.  The C `_impl.c` files become testable references rather than
load-bearing.

### Phase F — Real Programs (ongoing)

F1. JSON parser written in stdlib only (~1000 lines).
F2. SHA-3 reference (already pure-stdlib via numera::crypt).
F3. Tiny HTTP/1.1 server through aether::net + verba::parse.
F4. The CONFORMANCE corpus *itself* rewritten in III.
F5. SANCTUM/TRINITY/HEXAD subsystems re-expressed through stdlib.

**Gate:** A third party can write a real program in III with no C
extern.  III crosses from "interesting bootstrap" to "general-purpose."

---

## 17. CONFORMANCE CORPUS DESIGN

The compiler has 30 conformance programs under
`COMPILER/BOOT/stage1_corpus/`.  The stdlib gets its own at
`STDLIB/corpus/`, structured by sphere:

```
STDLIB/corpus/
├── memoria/
│   ├── 01_region_create_drop.iii
│   ├── 02_region_alloc_align.iii
│   ├── 03_region_seal_idempotent.iii
│   ├── 04_cell_load_store.iii
│   ├── 05_span_bounds_check.iii
│   └── 06_arena_overflow.iii
├── verba/
│   ├── 10_string_byte_len.iii
│   ├── 11_string_nfc_canonical.iii
│   ├── 12_builder_seal_consumes.iii   ← linear discipline test
│   ├── 13_format_no_injection.iii
│   ├── 14_regex_no_backtrack.iii
│   └── 15_parse_grammar_witness.iii
├── aether/
│   ├── 20_cap_attenuate.iii
│   ├── 21_cap_revoke.iii
│   ├── 22_handle_linear.iii
│   ├── 23_witness_log_chain.iii
│   └── 24_sealed_boundary_slot4.iii
├── numera/
│   ├── 30_q128_canonical.iii
│   ├── 31_bigint_modpow.iii
│   ├── 32_sha256_known_vector.iii
│   ├── 33_ed25519_verify.iii
│   └── 34_fp_inverse.iii
├── tempora/
│   ├── 40_instant_monotonic.iii
│   ├── 41_instant_seal_verify.iii
│   ├── 42_deadline_trap.iii
│   └── 43_cycle_advance_slot6.iii
├── omnia/
│   ├── 50_option_unwrap.iii
│   ├── 51_result_crystal.iii
│   ├── 52_vec_max_bound.iii
│   ├── 53_map_keyed_hash.iii
│   ├── 54_iter_total_bound.iii
│   └── 55_par_map_witness.iii
├── sanctus/
│   ├── 60_witness_compose_assoc.iii
│   ├── 61_kchain_underflow_readmit.iii
│   ├── 62_attest_self_drtm.iii
│   └── 63_mandate_runtime_check.iii
└── integration/
    ├── 70_json_parse_valid.iii
    ├── 71_sha3_kat.iii
    ├── 72_http_get_localhost.iii    ← uses aether::net
    └── 73_witness_chain_replay.iii
```

Each test follows the Hexad-respect rules and produces a **byte-equal**
output across stages.  The corpus itself becomes a witness of stdlib
correctness.

---

## 18. ARCHITECTURE DECISION RECORDS

### ADR-001 — Hexad-Crowned Sphere over flat module list

**Status:** Accepted

**Context:** Most stdlibs are flat module trees (Go's `os`, `io`, `net`)
or hierarchical by accident (Rust's `std::collections::HashMap`).
Neither models *why* a module exists.

**Decision:** Six spheres + Crown, mapped to Hexad kinds.  Every module
justifies itself by the Hexad kind it serves.

**Consequences:**
- `+` Module taxonomy becomes a load-bearing semantic structure, not
  filesystem accident.
- `+` New modules must justify Hexad placement; rejection criterion is
  explicit.
- `−` Slightly longer fully-qualified names (`memoria::region::create`
  vs `mem.create`).
- `−` Six is a hard limit; a seventh sphere would require a
  constitutional amendment (M2).

### ADR-002 — `@specialize` over runtime parametric polymorphism

**Status:** Accepted

**Context:** M21 forbids generics.  But stdlib needs `vec_T`, `option_T`.

**Decision:** Compile-time monomorphisation via `@specialize(T = ...)`.
No runtime polymorphism, no vtables.

**Consequences:**
- `+` Mandate-compatible.
- `+` Zero runtime cost (no dynamic dispatch).
- `+` Each specialisation is an independent symbol — IR-level
  optimisation works without virtual call indirection.
- `−` Code size grows with the cross-product of types × operations.
  Mitigated by compiler dead-code elimination.
- `−` Specialisation must be explicit; the user cannot write a generic
  function that "just works" for any T.

### ADR-003 — Witnesses first-class

**Status:** Accepted

**Context:** Provenance is M21's PROVENANCE keyword category but no
language has made witnesses *values*.  Most languages relegate provenance
to logs (which can be edited/lost).

**Decision:** Witness is a value.  Compiler can demand witness propagation
via `@witness_required`.  Witness chain is the substrate.

**Consequences:**
- `+` Closes the entire class of "lost provenance" failures.
- `+` Enables provenance-derived GC (§12.3) — a genuine novelty.
- `+` Auditors can replay arbitrary computation.
- `−` 8-byte overhead per stdlib value (the chain index).  Acceptable.
- `−` Witness chain itself must be persisted carefully (slot 8 Phoenix
  bookmark on rotation).

### ADR-004 — No GC, no exceptions, no threads (in stdlib)

**Status:** Accepted

**Context:** These three abstractions are the most expensive bugs in
existing languages.  GC pause vs determinism.  Exceptions vs error
handling clarity.  Thread races vs shared-state correctness.

**Decision:** Reject all three at the stdlib level.  Use linearity for
memory, results for errors, causality witnesses for concurrency.

**Consequences:**
- `+` Determinism is structurally enforced.
- `+` No GC pause possible.
- `+` No exception-safety tax on every function.
- `+` No data races possible.
- `−` Steeper learning curve for users coming from GC languages.
  Mitigated by stdlib examples and the witness-derived auto-collect
  facility (§12.3).
- `−` `omnia::par_map` is bounded — no fire-and-forget tasks.
  Acceptable because fire-and-forget is the usual source of bugs.

### ADR-005 — Provenance bytes (memory layout)

**Status:** Accepted

**Context:** Memory is currently unwitnessed.  Two values that "look
the same" might come from different regions.

**Decision:** Every cell carries `region_id`, `offset`, `type_id`.
Reconstruction goes through the region table.  Pointers are not handed
to user code.

**Consequences:**
- `+` Use-after-free is detectable (region_id mismatch).
- `+` Type confusion is detectable (type_id mismatch).
- `+` Memory dump becomes self-describing.
- `−` Cell is 24 bytes vs 8 for a raw pointer.
- `−` Indirection through region table adds 1 cache-line miss in worst
  case.  Hot paths can use spans, which inline the lookup.

### ADR-006 — Capability via `@cap` modifier

**Status:** Accepted

**Context:** Ambient authority is the source of every privilege
escalation in every language.

**Decision:** No ambient.  `env_cap` is the only root.  All authority
attenuates.

**Consequences:**
- `+` Closes ambient-authority class entirely.
- `+` Capability revocation observable via PFS slot 3.
- `+` Programs declare what they need, runtime grants exactly that.
- `−` Every `main` must take `env_cap`.  Existing programs require
  porting.  Mitigated by an `iiis --auto-cap` mode for legacy code.

### ADR-007 — Total functions only (in stdlib)

**Status:** Accepted

**Context:** Partial functions are the source of mysterious infinite
loops and unbounded recursion.

**Decision:** Stdlib functions are total.  Every loop has `@variant`,
every recursion has `@measure`, every iteration has `@bounded`.

**Consequences:**
- `+` No infinite loop in stdlib.
- `+` Termination is checkable in CI.
- `−` Some algorithms (Knuth-Morris-Pratt failure function) need
  cleverer variants than naïve `i--`.  Acceptable; the stdlib gets
  written carefully once.
- `−` User code is *not* required to be total; it can call stdlib
  freely.  The total surface is just the stdlib floor.

### ADR-008 — Crystallised errors

**Status:** Accepted

**Context:** Errors as values is good (Rust `Result`).  But values can
be substituted in memory; the logged error might not be the actual
error.

**Decision:** Errors are crystals — sealed by Sanctum slot 4 at mint
time.  Forging an error fails verification.

**Consequences:**
- `+` Error logs become attestable.  Audit trail is real, not
  fictional.
- `+` Closes the "log injection" class (attacker writes a fake error to
  hide a real one).
- `−` Error mint cost is non-trivial (HMAC).  Mitigated by reserving
  crystals for error paths only — happy paths return non-crystal `T`.

---

## 19. RISKS & MITIGATIONS

| #   | Risk                                                                             | Impact                                                       | Mitigation                                                                                                                                                                |
|-----|----------------------------------------------------------------------------------|--------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| R1  | Compiler complexity blows up adding 15+ new modifiers.                            | Bootstrap mhash drift.                                       | Add modifiers one at a time, each gated by 30-test corpus + `iiis-2 == iiis-3` check before next.                                                                          |
| R2  | `@specialize` causes code explosion.                                              | Binary size > available memory at link time.                 | Per-spec dead-code elimination; explicit specialisation list per type (no transitive auto-spec).                                                                            |
| R3  | Witness chain memory pressure on long-running programs.                           | OOM after weeks of uptime.                                   | Phoenix bookmark rotation (slot 8) every N events; old witnesses sealed and archived to PFS.                                                                                |
| R4  | Capability tree becomes a usability disaster (every fn signature 5 caps long).    | Users escape to `extern @abi(c-msvc-x64)` to avoid caps.      | Tier the caps: most fns take `arena_cap` only, and use module-private cap factories that themselves require larger caps just once at startup.                              |
| R5  | Sanctum slot 4 (CRCC sub-key) becomes a bottleneck for crystal minting.          | Per-error latency spike.                                      | Predictive specialisation (slot specialise) for the crystal mint path.  Already supported by `iii_sanctum_specialize`.                                                       |
| R6  | Linear typing requires re-binding (`let v = vec_push(v, x)`) — verbose.           | Code-readability cost.                                       | Compiler sugar: `v.push(x)` desugars to the rebind-pattern.  Sugar verified to lower to the same IR.                                                                          |
| R7  | Total-termination checker has false positives.                                   | Stdlib developer can't compile correct code.                 | Escape modifier `@trust_me_total` (mandate-reviewed; documented uses only).  Used in stdlib at most 5 sites, each justified in code comments.                                |
| R8  | Crystallised error mint requires an arena cap for every error path.              | Error path cap-threading is annoying.                        | A reserved `error_arena_cap` is automatically passed to every fn with a `result<*, *>` return type by the compiler, attenuated from `env_cap`.                              |
| R9  | "No floats" forces Q128 / fixed-point everywhere.                                 | Game dev / DSP work hard.                                    | Acceptable.  Game dev is not III's target audience; Q128 covers any rate computation; bigint covers any precision need; Fp covers crypto.                                  |
| R10 | Existing C-extern call sites in compiler can't migrate without breaking mhash.    | Phase E re-bootstrap fails.                                  | Migrate one TU at a time, per-TU mhash equivalence check before advancing.  The compiler determinism gate already enforces this discipline.                                  |

---

## 20. SUCCESS CRITERIA

The stdlib is "complete" when **all** of these hold simultaneously:

1. **Self-hosting compiler uses stdlib.** The compiler imports
   `numera::sha256` instead of inlining FIPS 180-4.  `cg_r3.iii` uses
   `memoria::span` instead of raw byte arrays.  `lex.iii` uses
   `verba::string` instead of byte buffers.

2. **Bootstrap fixed point preserved.** `mhash(iiis-3) == mhash(iiis-4)`
   after stdlib retrofit.

3. **Conformance corpus 100/100.** All 100 stdlib tests byte-identical
   across stages.

4. **Sealed-call sweep clean.** All sealed-API tests pass through
   `iiis-sanctum` with valid Trinity admission.

5. **One non-trivial real program.** A JSON parser written entirely in
   stdlib (no C externs) handling RFC 8259 valid input.  ~1000 lines.

6. **Witness chain attestable.** A program's full witness chain at exit
   is verifiable by an external auditor with only the closure root and
   the public Sanctum quote chain.

7. **Mandate compliance.**  All 21 mandates pass against the stdlib
   itself.  M2 (axiom compliance), M3 (architecture coherence), M11
   (anti-bloat), M14 (cross-file harmony), M20 (working code) are the
   load-bearing checks.

When all seven criteria hold, III graduates from "self-hosted compiler"
to "general-purpose programming language with the strongest invariants
ever shipped in a stdlib."  Other languages can copy individual
features.  No other language can copy the *combination*.

That combination is what makes III the last language.

---

## 21. APPENDIX A — Example Program (end-to-end)

A program reading a UTF-8 JSON file, parsing it, computing the SHA-256
of one of its fields, and writing the result back — all in stdlib, no C
externs, full witness chain.

```iii
module example_pipeline

import memoria
import verba
import aether
import numera
import omnia

fn main(env: env_cap) -> i32 @export {
    /* Attenuate root capability into specific authorities. */
    let alloc  : alloc_cap  = aether::cap_attenuate_to_alloc(env)
    let fs     : fs_cap     = aether::cap_attenuate_to_fs(env, "./data/")
    let stdout : write_cap  = aether::cap_attenuate_to_stdout(env)

    /* Allocate working arena with bounded size. */
    let arena  : arena_cap  = memoria::arena::new(alloc, 1u64 << 20u64)
                            |> result::unwrap_or_die

    /* Open the input file (linear handle). */
    let r_cap  : read_cap   = aether::fs::read_cap(fs, "input.json")
    let h      : handle_t   = aether::fs_open(r_cap, AETHER_MODE_READ)
                            |> result::unwrap_or_die

    /* Read into a vec_u8 (bounded at 16 MiB). */
    let buf    : vec_u8     = omnia::vec_new_u8(arena, 16u64 << 20u64)
                            |> result::unwrap_or_die
    let (h, n) : (handle_t, u64) = aether::read_to_vec(h, buf)
                            |> result::unwrap_or_die

    /* Decode UTF-8 bytes as string (validates and produces witness). */
    let s      : string_t   = verba::string_from_utf8(arena, omnia::vec_as_span_u8(buf))
                            |> result::unwrap_or_die

    /* Parse JSON.  Returns a json_value_t (an OMNIA composition). */
    let j      : json_value_t = verba::parse::json(arena, s)
                            |> result::unwrap_or_die

    /* Look up field "name" — total, bounded by document depth. */
    let name_field : string_t = verba::parse::json_field(j, "name")
                            |> result::unwrap_or_die

    /* SHA-256 over the field's bytes — pure, no Sanctum needed. */
    let digest : u8[32] = numera::sha256(verba::string_as_bytes(name_field))

    /* Format the digest as a hex string via sealed format. */
    let out_s  : string_t = verba::fmt!("name-sha256: ${hex}\n",
                                         hex = numera::hex_lower(arena, digest))

    /* Write to stdout (capability-gated, sealed).            */
    aether::write_string(stdout, out_s) |> result::unwrap_or_die

    /* Close handle (linear consume). */
    let _ = aether::close(h) |> result::unwrap_or_die

    return 0i32
}
```

Every line in this program:
- Goes through a capability (no ambient authority).
- Carries a witness (recoverable in O(1) at any call site).
- Is total (every loop has a variant; the SHA-256 inner loop is
  bounded by message length).
- Has a declared K-value (the chain product is checkable).
- Has effects in its type (no surprise IO).
- Cannot leak memory (linear arena, dropped at return).
- Cannot deadlock (no locks).
- Cannot race (no shared mutability).
- Is fully attestable (witness chain root signs the execution).

This is what computation looks like when it refuses to lie.

---

## 22. APPENDIX B — Module Manifest (R1.D1)

The complete module list, sealed for R1.D1.  Adding or removing a
module requires a header bump and a constitutional amendment (M2).

```
STDLIB/iii/
├── memoria/
│   ├── region.iii
│   ├── cell.iii
│   ├── span.iii
│   ├── arena.iii
│   ├── pool.iii
│   ├── guard.iii
│   └── sealed_alloc.iii
├── verba/
│   ├── rune.iii
│   ├── string.iii
│   ├── builder.iii
│   ├── parse.iii
│   ├── format.iii
│   ├── normalise.iii
│   ├── collation.iii
│   ├── search.iii
│   └── regex.iii
├── aether/
│   ├── capability.iii
│   ├── handle.iii
│   ├── read.iii
│   ├── write.iii
│   ├── fs.iii
│   ├── net.iii
│   ├── proc.iii
│   ├── boundary.iii
│   └── witness_log.iii
├── numera/
│   ├── scalar.iii
│   ├── q128.iii
│   ├── bigint.iii
│   ├── field.iii
│   ├── crypt.iii
│   ├── modular.iii
│   ├── fixed.iii
│   └── checked.iii
├── tempora/
│   ├── instant.iii
│   ├── duration.iii
│   ├── deadline.iii
│   ├── witness.iii
│   ├── cycle.iii
│   ├── calendar.iii
│   └── epoch.iii
├── omnia/
│   ├── option.iii
│   ├── result.iii
│   ├── either.iii
│   ├── vec.iii
│   ├── map.iii
│   ├── set.iii
│   ├── queue.iii
│   ├── pq.iii
│   ├── iter.iii
│   ├── fold.iii
│   └── zip.iii
└── sanctus/
    ├── seal.iii
    ├── witness.iii
    ├── kchain.iii
    ├── mandate.iii
    ├── attest.iii
    ├── mhash.iii
    ├── epoch.iii
    └── compile.iii
```

Total: **47 native `.iii` modules**.  This number aligns deliberately
with the existing **47 keywords** in III (a coincidence, but a pleasing
one — the language has 47 reserved tokens, and 47 stdlib modules.  The
two sets do not overlap.)

---

## 23. APPENDIX C — Closure Identity

This document, when sealed, becomes spec slot **R1.D1**.  Its mhash will
be added to the III closure root alongside R1.A8 (Sanctum), R1.B*
(Cycles), and the rest.  The Phase A deliverable includes:

```
STDLIB/iii/SEAL.mhash         — sha256 of the entire STDLIB/iii/ tree
STDLIB/iii/CLOSURE.mhash      — sha256 of (this doc || tree mhash)
```

The closure mhash is what the compiler embeds at build time.  Any
deviation between the embedded value and the recomputed value at
attestation time is a constitutional violation — the binary refuses to
admit Sanctum calls until reconciliation.

---

*Document seal: this document is `R1.D1.draft.0`.  Promotion to
`R1.D1.sealed` requires:*
1. *Phase A implementation passing all 25 corpus tests.*
2. *Mandate review against M1..M21 by the user.*
3. *Compiler closure mhash recomputed with R1.D1 included.*
4. *Single signed quote (DRTM slot 1) attesting the new closure root.*

*Until then, this document is a working spec and may be refined.  The
discipline is the same as compiler ports: edit at the source, verify at
the gate, advance only on green.*

— end of III-STDLIB-NATIVE-DESIGN.md —
