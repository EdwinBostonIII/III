# III — THE STANDING TOOLS: capabilities you can actually run

> A capability that can only be exercised by hand-writing a driver, a gate, and a build script for each
> input is not a capability — it is a demo with good manners. This document lists the tools III ships as
> **committed binaries that take real input and do the real thing**: no glue to write, no curated vectors,
> no operator in the loop. Each one is verified below on input it has never seen.

---

## `iii-prove` — prove two functions equal over ALL 2⁶⁴ inputs

```
iii-prove <a.iii> <fnA> <b.iii> <fnB>     prove fnA == fnB for EVERY input
iii-prove --list <file.iii>               list a file's provable functions
```

Build: `bash COMPILER/BOOT/build_iii_prove.sh` → `COMPILED/iii-prove`.
Source: `COMPILER/BOOT/prove_main.iii`.

This is III's disposer (`numera/ser_kinduct_sym::seq_equiv`, over `numera/bv_bits` → `numera/sat`) made
independently useful. Hand it **your** two source files and two function names. It links the compiler's own
front end (lex/ast/parse) and its own SVIR backend (`cg_svir`) *in-process* — no shelling out, no temp files,
no harness — lowers both functions, mitres their denotations, and decides:

| exit | verdict | meaning |
|---|---|---|
| 0 | **PROVEN** | equal for every input — a bit-blast UNSAT over the whole 2⁶⁴ space of each parameter. Not sampled. |
| 1 | **REFUTED** | they differ — and the **concrete counterexample is printed** |
| 2 | **UNDECIDED** | a body left the decided fragment, and the tool **says which and why** |
| 3–8 | usage / read / parse / emission / no-such-function / arity-mismatch |

**It never reports PROVEN unless it proved it.** Everything else — refutation, out-of-fragment, capacity,
solver poison — maps to REFUTED or UNDECIDED.

### The decided fragment
Straight-line ALU over parameters and constants; **constant** shift counts; structured `if/else`;
**early returns under any nesting** (path-conditioned, with totality *checked*); counter loops with constant
stride; constant-address byte memory; `DIV_U`/`REM_U` **by a constant power of two** (exactly a shift/mask).
Outside it, by design: variable shift counts, general division, calls, symbolic addresses. The general
64-bit divider bit-blasts into the multiplier wall this engine deliberately amputates — so it **abstains**
rather than approximate.

### Verified on code it had never seen
Two files of ordinary optimizations — the kind you would not merge without a proof (`STDLIB/build/mathesis/userA.iii`,
`userB.iii`):

| pair | verdict | why it is right |
|---|---|---|
| `swap32` | **PROVEN** | `(x>>32)\|(x<<32)` ≡ `(x<<32)\|(x>>32)` — OR commutes |
| `is_pow2` | **PROVEN** | `x&(x-1)==0` ≡ `x&(-x)==x` for x≠0 — a real theorem, not a coincidence |
| `pick` | **PROVEN** | the branchless mask-select really does equal the branchy one |
| `align8` | **PROVEN** | `((x+7)/8)*8` ≡ `(x+7) & ~7` — the alignment idiom, decided |
| `absdiff` | **REFUTED** | counterexample `a=0xFFFF…F, b=0x3FFF…F`: the "clever" version uses the **signed** sign-mask, giving `0x4000…0` where the unsigned original gives `0xC000…0`. **A real bug in a real optimization.** |
| `avg` | **REFUTED** | counterexample `a=b=0xFFFF…F`: the famous overflow-safe average is genuinely **not** `(a+b)/2` under wraparound — `0xFFFF…F` vs `0x7FFF…F` |

Every verdict is checkable by hand. Nothing here was curated for the tool.

### The soundness bug this tool found — and forced shut
Pointing the prover at ordinary user code immediately exposed a **false PROVEN** in the disposer itself.

The compiler lowers `if c { return b }  return a` to
`[LGET c][CONST 0][NE][IF][LGET b][RET][END][LGET a][RET]` — a `RET` **inside** an if-frame, with no `ELSE`.
`sd_denote`'s `RET` handler returned the top of stack **immediately**, so it denoted that entire body as
**`b` alone**: the condition and the `return a` path simply vanished. Consequences:

```
f(c) = if c { return 1 }  return 2
g(c) = if c { return 1 }  return 3
```
Both collapsed to the constant `1`, so `seq_equiv` called them **EQUAL**. They are not — at `c = 0` one is 2
and the other is 3. A false PROVEN is the one unrecoverable outcome the whole engine exists to prevent.

The corpus never hit it because every gate hand-writes SVIR bodies with a single trailing `RET`. **Only
pointing the capability at real code found it.** That is the entire argument for standing tools.

**Fixed** (`ser_kinduct_sym.iii`) by a path-condition accumulator: a `RET v` fires exactly where
`fire = PC & ¬RETSET`, contributing `RETV := mux(fire, v, RETV)`, `RETSET := RETSET ∨ fire`; after
`if c { … RET } END` the path condition becomes `PC ∧ ¬c`; and at end-of-body **totality is checked, not
assumed** — if `RETSET` is not provably 1, the body is refused rather than given an invented value.
The unconditional fast path is preserved node-for-node, so every straight-line and if/else-value body
(all 18 sealed mathesis theorems, every 2601/2613/2674/2675/2677/2678/2679 gate) denotes to the **identical**
circuit and keeps its exact verdict — verified: **27/27 mathesis gates green** after the fix.

Pinned forever by `corpus/2614_disposer_early_return`, which **reproduces the false PROVEN first**
(RED = 10) and only then proves the fix — so the bug can never return silently.

---

## `iii-crypto` — the post-quantum stack pointed at your files

```
iii-crypto keygen <level> <seed32> <pk> <sk>        ML-DSA (FIPS 204) keypair, deterministic in the seed
iii-crypto sign   <level> <sk> <file> <sig>         sign ANY file
iii-crypto verify <level> <pk> <file> <sig>         exit 0 = VALID, 4 = INVALID
iii-crypto seal   <key32> <nonce12> <file> <out>    ChaCha20-Poly1305 AEAD
iii-crypto open   <key32> <nonce12> <sealed> <out>  exit 0 = AUTHENTIC, 4 = FORGED (no plaintext written)
iii-crypto hash   <file>                            SHA-256
iii-crypto kem-keygen <set> <seed64> <ek> <dk>      ML-KEM (FIPS 203); set = 512 | 768 | 1024
iii-crypto kem-encaps <set> <ek> <coins32> <ct> <ss>   exit 4 = non-canonical ek REJECTED (sec 7.2)
iii-crypto kem-decaps <set> <dk> <ct> <ss>          FO implicit rejection: tampered ct DIVERGES the ss
iii-crypto slh-keygen <sset> <seed3n> <pk> <sk>     SLH-DSA (FIPS 205), both strict hash families
iii-crypto slh-sign   <sset> <sk> <file> <sig>      sset = shake-128s|192s|256s | sha2-128s|192s|256s
iii-crypto slh-verify <sset> <pk> <file> <sig>      exit 0 = VALID, 4 = INVALID
iii-crypto ed-keygen  <seed32> <pk>                 Ed25519 (RFC 8032); the seed IS the private key
iii-crypto ed-sign    <seed32> <file> <sig>         deterministic 64-byte signature
iii-crypto ed-verify  <pk> <file> <sig>             exit 0 = VALID, 4 = INVALID
iii-crypto siv-seal   <key32> <file> <out> [ad]     AES-SIV (RFC 5297): DETERMINISTIC, no nonce to misuse
iii-crypto siv-open   <key32> <sealed> <out> [ad]   exit 0 = AUTHENTIC, 4 = FORGED (AD authenticated too)
```

Build: `bash COMPILER/BOOT/build_iii_crypto.sh` → `COMPILED/iii-crypto`.
Source: `STDLIB/iii/aether/crypto_cli.iii`. `<level>` is the FIPS 204 security category `2 | 3 | 5`
(= ML-DSA-44 / -65 / -87).

The sovereign FIPS/ACVP-conformant stack (KAT-gated in the corpus) pointed at arbitrary files. Verified on
fresh input — a message and random seeds minutes old, at level 2:

| arm | observed |
|---|---|
| `keygen` | pk 1312 B, sk 2560 B — the FIPS 204 ML-DSA-44 sizes — deterministic in the seed |
| `sign` → `verify` | 2420-byte signature (the ML-DSA-44 size); `VALID`, exit 0 |
| ONE signature byte flipped (proven by `cmp`) | `INVALID`, exit 4 |
| verify under a different public key | `INVALID`, exit 4 |
| ONE message byte changed | `INVALID`, exit 4 |
| `seal` → `open` | `AUTHENTIC`, exit 0 — opened bytes identical to the input |
| ONE sealed byte flipped (proven by `cmp`) | `INVALID: authentication FAILED … (no plaintext was written)`, exit 4 — and the output file is not created |
| `hash` | agrees byte-for-byte with `sovhash`, GNU `sha256sum`, and Microsoft `certutil` on the same file |

A verifier that can only say yes is not a verifier: every reject arm above is a measured exit 4.

### The full-stack verbs, verified on fresh input (keys/seeds minutes old)

| arm | observed |
|---|---|
| ML-KEM 512/768/1024 roundtrip | ek 800/1184/1568 B, dk 1632/2400/3168 B, ct 768/1088/1568 B — the FIPS 203 sizes; encaps↔decaps shared secrets byte-identical (`cmp`), keygen deterministic in the seed |
| ONE ct byte flipped (proven by `cmp`) | decaps exits 0 but the secret silently DIVERGES — the Fujisaki-Okamoto implicit rejection, proven by comparing ss files |
| wrong dk | secret diverges |
| non-canonical ek (coefficient ≥ q) | encaps `INVALID … sec 7.2 modulus check`, exit 4 |
| SLH-DSA shake-128s + sha2-128s | keygen (pk 2n / sk 4n, deterministic) → 7856-byte signature → `VALID` exit 0; sizes 48/96 (192s) and 64/128 (256s) exact |
| SLH tampered sig / wrong pk | `INVALID`, exit 4 |
| SLH cross-family | a SHAKE-family signature does NOT verify under SHA2 — the two strict FIPS 205 families are disjoint through this tool, measured |
| Ed25519 sign → verify | 64-byte deterministic signature, `VALID` exit 0; same seed+message → identical signature (`cmp`) |
| Ed25519 tampered sig / wrong key / tampered message | `INVALID`, exit 4 — all three |
| AES-SIV seal → open | roundtrip byte-identical; same key+plaintext+AD → IDENTICAL sealed bytes (`cmp`) — RFC 5297's determinism, the property that makes nonce misuse impossible |
| AES-SIV one byte flipped / wrong AD / missing AD | `INVALID … no plaintext was written`, exit 4 — the AD is authenticated |

---

## `iii-exact` — the exact sign of Σ aᵢ√bᵢ, on your own terms

```
iii-exact "<a1> <b1> <a2> <b2> ..."      sign(a1*sqrt(b1) + a2*sqrt(b2) + ...), decided EXACTLY
iii-exact --cmp "<terms A>" "<terms B>"  decide whether (sum A) <, =, or > (sum B), EXACTLY
iii-exact --denest <a> <b> <d>           is a + b*sqrt(d) a PERFECT SQUARE in Q(sqrt(d))?
```

Build: `bash COMPILER/BOOT/build_iii_exact.sh` → `COMPILED/iii-exact`.
Source: `STDLIB/iii/aether/exact_cli.iii` (composes `aether/sqrt_sum_sign` + `aether/kfield` +
`aether/exact_denest` over the bigint arena). Sign modes print `-1 / 0 / +1`; exit `1` = NEGATIVE,
`0` = EXACTLY ZERO, `2` = POSITIVE, `3` = usage/parse error. `--denest` exits `0` = perfect square
(root printed), `4` = genuine extension, `5` = out-of-envelope abstain, `6` = internal refuse (the
tool re-squares the root IN-PROCESS and will not print one it did not re-verify).
No floating point anywhere in any decision.

Verified on fresh input:

| input | verdict | why it is right |
|---|---|---|
| `"1 123456790 1 123456788 -2 123456789"` | `-1`, exit 1 | √(N+1)+√(N−1)−2√N < 0 by strict concavity; true value ≈ −1.8·10⁻¹³, ~20× below one ulp of the operands — **a double computes literally `0` for this sum (measured)** |
| `"2 123456789 -1 123456790 -1 123456788"` | `+1`, exit 2 | the mirror sum — the verdict flips with it |
| `"1 8 1 18 -1 50"` | `0`, exit 0 | 2√2 + 3√2 − 5√2: a TRUE zero, certified — not "smaller than a tolerance" |
| `--cmp "7 11" "1 539"` | `0`, exit 0 | 7√11 = √539 exactly (539 = 49·11) |
| `"1"` | exit 3 | odd term count → the parse error is named, never guessed around |
| `--denest 23 8 7` | exit 0 | `√(23 + 8√7) = 4 + 1·√7` — the root re-squared exactly in-process before the claim prints |
| `--denest 22 -12 2` | exit 0 | principal root `-2 + 3√2` (= 3√2 − 2): sign-normalized exactly, no floating point |
| `--denest 9 6 2` | exit 4 | THE norm trap: N = 9 = 3², yet 9+6√2 is NOT a square — the norm alone is never trusted |
| `--denest 100 2000000 2` | exit 5 | outside the proven i64 envelope (`\|a\|<2³⁰, \|b\|<2²⁰, 0<d<2²⁰`) → ABSTAIN |
| `"1x 2"` | exit 3 | trailing garbage in a number is an ERROR — measured fast, never a hang |

---

## `iii-typecheck` — the dependent-type kernel, on your terms

```
iii-typecheck <term-file>                      infer the term's type, or refuse
iii-typecheck --check <term-file> <type-file>  check term : type (bidirectional)
```

Build: `bash COMPILER/BOOT/build_iii_typecheck.sh` → `COMPILED/iii-typecheck`.
Source: `STDLIB/iii/aether/typecheck_cli.iii` over the UNCHANGED kernel `numera/typecheck`
(lambda-Pi + predicative universes U0:U1:…, Σ, Bool, Id/J, Nat/iter/natrec, Unit, Empty, Sum,
W-types; conversion by the directed CCL oracle). The CLI is an untrusted S-expression front end
over the kernel's own constructors and serializer — the de Bruijn criterion survives: a parse
error is the TOOL's verdict (exit 3, position printed); only the kernel says WELL-TYPED.
Grammar in `--help`; binders are de Bruijn (`(var 0)` innermost). Exit `0` = well-typed/checked,
`4` = the kernel REFUSED, `3` = parse, `2` = file. QTT quantities and the BV64/LEK/REACH
certification nodes remain kernel-internal programmatic surfaces with their own gates.

Verified on fresh input:

| input | observed |
|---|---|
| `(lam (sort 0) (lam (var 0) (var 0)))` | `WELL-TYPED : (pi (sort 0) (pi (var 0) (var 1)))` — the polymorphic identity's DEPENDENT type, with the codomain variable correctly de Bruijn-lifted to `(var 1)` by the kernel |
| `(refl true)` | `(id bool true true)` |
| `(iter zero (lam nat (succ (var 0))) (succ (succ zero)))` | `nat` |
| `(app true false)` / `(var 0)` bare / `(inl true)` bare | `ILL-TYPED`, exit 4 — wrong application, out-of-scope variable, and an unannotated checkable form all refused |
| `(ann (inl true) (sum bool nat))` | `(sum bool nat)` — the bidirectional door: annotate, or use `--check` |
| `--check (inl true) : (sum bool nat)` | `CHECKED`, exit 0 |
| `--check (sort 0) : (sort 0)` | **`REJECTED`, exit 4 — Girard's paradox arm: a kernel that accepted `U0 : U0` would prove False** |
| `--check (sort 0) : (sort 5)` | `CHECKED`, exit 0 — predicative cumulativity, measured |
| `--check (sort 0) : true` | `REJECTED: the supplied 'type' is a term, but its type is not a universe`, exit 4 |
| `(succ` / `(frob 1)` / `true junk` | parse errors at the exact byte offset, exit 3 — never the kernel's verdict |

---

## `iii_eval` — the definitional evaluator / REPL

```
iii_eval <file.iii>      evaluate a module through the meaning-bearer
iii_eval --repl          interactive
```
Build: `bash COMPILER/BOOT/build_iii_eval.sh` → `COMPILED/iii_eval`.
The independent meaning-witness: it runs a program by *definition*, not by compiled code, and the standing
`run_meaning.sh` differential holds the two against each other on the whole corpus.

## `iiis-2` — the self-hosted compiler

```
iiis-2 <file.iii> --compile-only --out <file.o>    compile
iiis-2 --link <objs...> --out <prog>               link (no gcc in the trusted path)
iiis-2 <file.iii> --emit-svir --out <gen.iii>      emit the verifiable IR
```
Takes any `.iii`. Compiles itself (the DDC fixpoint: `iiis-2` ≡ `iiis-3`, byte-identical).

## `sovhash` — the sovereign content-address

```
sovhash <file>     plain FIPS 180-4 SHA-256 of the file's bytes
```
Minted on demand by the seal library (`COMPILER/BOOT/mhash_lib.sh`) from `STDLIB/iii/aether/sovhash.iii`
into `COMPILED/_sovhash/sovhash.exe` — one `iiis-2` compile + link. Streams any file of any size and agrees
byte-for-byte with GNU `sha256sum`, Microsoft `certutil`, and `iii-crypto hash` — independent authorships,
so a lie in one is exposed by the others.

## `run_mathesis.sh --standing` — the discovery engine

One command. No LLM, no operator anywhere in its process tree (gated: `corpus/2682`). It measures its own
compilation, synthesizes candidate theorems from the *whole declared space*, proves or refuses each, seals
what survives into a replayable content-addressed library, and folds the useful ones back into the compiler.

---

## The honest frontier (what is still library-locked)

Named, not hidden. These are real capabilities with real KAT coverage that **do not yet have a standing CLI**,
and therefore do not yet meet the bar this document sets:

- **The exact-arithmetic engine beyond Σaᵢ√bᵢ sign and rank-1 denesting**: bounded-rank algebraic
  numbers (`algnum`) and Sturm exact root isolation decide exactly — but still only from inside a linked
  program. `iii-exact` (above) is the surface to extend.
- **Kernel-internal judgment surfaces**: QTT quantity checking (`tc_qtt_ok`) and the BV64/LEK/REACH
  certification nodes are programmatic-only (own corpus gates); `iii-typecheck` (above) is the surface
  to extend if a file-facing form is ever warranted.

(ML-KEM, SLH-DSA, Ed25519, AES-SIV, rank-1 denesting, and the CIC core all left this list on
2026-07-12 — each now a verb on a standing tool above, proven on both arms.)

Each is a tool of the same shape as `iii-prove`: link the library, take real input, print a real verdict.
