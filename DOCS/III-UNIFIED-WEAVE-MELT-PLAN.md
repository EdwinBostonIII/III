# The Unified Weave — Melt Plan & `@inline` Keystone
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

The weave: ONE mathematical woven structure, the common denominator of every former III primitive,
until the borrowed names (ChaCha, Blake2, Montgomery, …) are obsolete. Bit-identity is the correctness
mandate; the perfection is the *structure* — one substrate, proven equivalences, no redundancy.

## Status (committed, gate-green)
- **Substrate** `numera/weave_blocks` (e61f52c2): `wvb_arx_mix` (ChaCha QR ≡ Blake2 G, one block), `wvb_rotl32`/
  `wvb_rotl64` (the universal rotation; rotr ≡ rotl(w−n), proven). Routed + byte-verified (FIPS/RFC + scalar-vs-AVX
  bit-identity): chacha20, blake2s, sha256, sha512, keccak.
- **Repository-level weave** `numera/weave_interfile`: #1 inter-file don't-care annihilation (278723ad);
  #2 polymorphic superposition (1762); #4 zero-loss composition / ARX-block bijection (99449aa2).

## The weave's irreducible vocabulary (the atoms everything reduces to)
AND, OR, XOR, NOT (Boolean floor, NAND-complete) · SHL, SHR · **ROTATE** (`wvb_rotl32/64` — done) ·
ADD, SUB mod 2^w · MUL mod 2^w (wide = 64×64→128 schoolbook; FOUR byte-identical copies:
fix_mul=fx48_mul=q128_mul=bigint_mul_u64) · **MOD** (ONE atom, THREE proven-equal algorithms — Montgomery REDC /
Barrett / Knuth-D, already KAT 1347; a modulus-form DISPATCHER, not a Montgomery monoculture; caveat: Montgomery
yields x·R⁻¹, a representation) · GF(2)[x] carryless multiply-reduce (different algebra; gf8 0x1B, gf128 0x87) ·
CONDITIONAL-SUBTRACT / SELECT (mux — SHA-Ch IS a bitwise mux, proven).

## Prioritized first melt targets (byte-identical achievable)
1. **SHA-2 Ch/Maj** — `(e&f)^(~e&g)` and `(a&b)^(a&c)^(b&c)` are BYTE-IDENTICAL across sha256(u32, :234/239) and
   sha512(u64, :261/264). Extract `wvb_ch32/maj32` + `wvb_ch64/maj64` (width-pair, NOT a generic @specialize that
   risks drift). The PROOF half is already in primweb (pw_sha_ch_is_mux, pw_sha_maj_absorbs, optforms). Σ/σ →
   parameterized rot-triples over `wvb_rotl32/64`. Adopting the cheaper optforms is a SEPARATE bytes-changing step.
2. **SipHash / xoshiro / murmur** rotl32/64 duplicate `wvb_rotl` — route them. (lane structure stays per-cipher.)
3. **AES gf8 multiply** — the lone clean GF(2^8) dup. HOIST AES's masked constant-time `aes_gmul` (:84) as canonical;
   AES + galois route through it. CRITICAL: do NOT dedup AES into galois's *branchy* `gf8_mul` (that regresses
   constant-time). Differential-KAT upgrades galois to constant-time. GF(2^128): galois.gf128_mul ≡ GHASH ≡ siv_dbl
   under the reflection/byte-order isomorphism — one mul + x-double core, reduction-constant parameterized.
4. **zk_field.zkf_mul** (:269) — the LONE un-consolidated inline CIOS (byte-for-byte the fn384 shape). Route onto
   `mont_cios_run`; UPGRADES zk_field to constant-time (its `zkf_csub_p` has a data-dependent borrow branch). NOT a
   special-prime fold (BLS12-381 p is a general prime). Montgomery is OTHERWISE already melted (fp256/fn256/fp384/
   fn384/RSA all route through `mont_cios_run` via the raw-buffer bridge).

Notes: keccak χ shares the bv-PROOF substrate with SHA-Ch (both 3-input AND-NOT-XOR) but is a DIFFERENT Boolean
function — not a byte-identical shared op-sequence. CRC32 GF(2)[x] division = conceptual-link only, leave standalone.

## The `@inline` keystone (the linchpin for zero-overhead single-source)
A perfect weave needs atoms that are single-source AND zero-overhead. Routing a tiny atom through a runtime call
costs more than the op; the proof-level "prove both sites are the same atom, leave both inline" leaves SOURCE
redundancy. Only compile-time expansion (`@inline`) gives both. It also retroactively perfects the rotation routing.

**Bootstrap regime (the fact that makes it safe):** `build_iiis2.sh --check-corpus` asserts iiis-0 (C-seed `cg_r3.c`)
and iiis-2 (`cg_r3.iii`) emit byte-identical `.o` for every program in `COMPILER/BOOT/stage1_corpus/` (59 fixed basic
programs — none use `@inline`). So an **ADDITIVE** `@inline` (a program *without* it emits byte-identically) keeps
stage1_corpus green; only weave files (compiled by iiis-2) get inlining; the compiler itself never uses `@inline`,
so iiis-2 == iiis-3 self-fixpoint holds and no C-mirror is needed.

**Scope (non-negotiable):** single-`return`-expression LEAF functions ONLY (exactly the weave atoms — wvb_rotl32/64,
wvb_andn, wvb_ch, …). NOT a general inliner (no control flow / multi-stmt / recursion).

**Mechanism:** at a CALL to an `@inline` callee — instead of `callq` — evaluate each arg ONCE into a fresh local
temp (`r3_local_add` + store), bind the callee's params to those temps, emit the callee's body return-expr
(`iii_ast_fn_body` → the return-stmt's expr; param refs resolve to the temps via `r3_local_lookup`), leave the
result in rax exactly as the call would. Sema: recognize the `inline` modifier (sema.iii ~1760, the modifier-name
recognition near 1211) + validate it's a single-return leaf.

**Sites:** sema.iii modifier recognition (~1211, ~1760); cg_r3.iii call-expr emit handler + `iii_ast_fn_param_count/
at`, `iii_ast_fn_body`, `r3_local_lookup/add`, `r3_emit_store_rax_slot`. Safepoint: `iii-safepoint-weave-preinline-99449aa2`.

**Verification (crash-protocol mandate — do not skip):** (1) prove in ISOLATION first — one throwaway `@inline` fn +
one KAT, then DISASSEMBLE and confirm the `callq` is GONE, the inlined ops present, result byte-identical;
(2) `--check-corpus` must stay GREEN (additive proven); (3) the bootstrap/determinism gate is the ARBITER — if it
reddens, STOP, do not paper over; (4) confirm via `microarch_model` the inlined emit is actually cheaper than the
call. Only then roll `@inline` through the weave atoms (and route SHA-Ch/Maj, the rotl dups, AES gf8, zk_field).
