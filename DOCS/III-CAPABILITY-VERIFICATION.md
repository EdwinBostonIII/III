# III — Capability Verification, Atlas & Ripple Map

**A source-grounded, execution-verified account of what III is and what it can actually do.**

Author: in-session verification pass (2026-05-30). Every claim below carries a verification tag and, where it is a capability, a file-by-file role list and an execution chronology (entry → exit, with `file:line` at each hop), its proof obligation (which KAT pins it), and its limits *with the specific mechanistic reason*.

This document is built in three parts, in the order requested:

- **Part I–III** — the *verified capability ledger*: the abilities established as real, deep-dived file-by-file with chronology, limits, and the **measured** truth of every performance claim.
- **Part IV** *(appended after the discovery pass)* — *every bit of written capability* found by going through the system file-by-file: the small, the broken, the forgotten, the under-sold.
- **Part V** *(appended last)* — the *inter-file relational (ripple) emergent capabilities*: what the system can do that no single file contains.

---

## Part 0 — Methodology & verification legend

Nothing here is taken on faith from a prose claim. Each line is tagged by **how** it was established:

| Tag | Meaning |
|-----|---------|
| `⟦RAN⟧` | Verified by **executing it this session** — a count, a build, a benchmark, the byte-identity gate. The reproducing command is given. |
| `⟦SRC⟧` | Verified by **reading the source** (file:line cited). The code exists and does what is claimed. |
| `⟦MEAS⟧` | Has a **benchmark number measured this session** (cycle counts, ratio). |
| `⟦HIST⟧` | **Asserted from project history**, not reproducible in a read-only/from-source audit (e.g. "ran on bare metal in Ring-0"). Believed true; flagged because *this pass cannot re-derive it*. |
| `⟦OVERSTATED⟧` | A claim whose **magnitude the measurement does not support** — the capability is real, the number was not. |

**How the headline counts were obtained this session** (all `⟦RAN⟧`):

- **Byte-identity reseal — `59/0`**: ran `iiis-1.exe` and `iiis-2.exe` over all 59 `COMPILER/BOOT/stage1_corpus/*.iii`, compared the emitted `.o` byte-for-byte → 59/59 identical.
- **Stdlib build — `431/0`**: `bash STDLIB/scripts/build_stdlib.sh` → `BUILD_RC=0`; the 10 subsystem dirs hold exactly `134+125+51+49+23+14+13+12+5+5 = 431` `.iii` modules, plus 26 in `COMPILER/BOOT`.
- **Conformance corpus — `619/0`**: `bash STDLIB/scripts/run_corpus.sh` → `PASS=619 FAIL=0 SKIP=99`. (`SKIP` = the XII band 280–372, delegated to `run_xii_corpus.sh`, plus the 7 perf benchmarks delegated to `run_bench_corpus.sh`.)
- **Speedup numbers**: built, linked and ran benchmarks `990/991/992` directly (cycle counts below).

> **Honesty note carried throughout:** the system is *real and substantial*. The only soft spots this pass found are (a) two performance **magnitudes** that were over-stated in prose, now corrected with measurements, and (b) one production crypto path that *was* measurably a **pessimization** against the system's own current alternative (RSA Montgomery — **since fixed and reversed**, §III.16). These are stated plainly where they occur — they are the most valuable part of an honest capability map.

---

## Part I — The verified capability ledger (claim-by-claim adjudication)

| # | Claim | Verdict | Evidence |
|---|-------|---------|----------|
| 1 | Self-hosting; `lex/parse/sema/cg_*` are all `.iii` | **TRUE** `⟦SRC⟧` | `build_iiis2.sh` `PORTED_TUS` lists 25 TUs incl. `lex,parse,sema,cg_r0,cg_r3,cg_rm1,cg_rm2,sid` |
| 2 | Byte-exact reseal, "corpus-equivalence 59/0" | **TRUE** `⟦RAN⟧` | ran `iiis-1` vs `iiis-2` on 59 stage1 programs → 59/59 byte-identical `.o` |
| 3 | `build 431/0` | **TRUE** `⟦RAN⟧` | `BUILD_RC=0`; subsystem file counts sum to exactly 431 |
| 4 | `corpus 619/0` | **TRUE** `⟦RAN⟧` | `PASS=619 FAIL=0 SKIP=99` (benches `990/991/992` correctly delegated, not double-counted) |
| 5 | Shared Montgomery NTT (four hand-rolled → one organ) | **TRUE** `⟦SRC⟧` | `ntt.iii:155,191` shared cores; `mlkem.iii:33,93` + `mldsa.iii:35,106` delegate; `ntt.iii:5` names the 4 prior copies |
| 6 | X25519 fixed 8-limb `fe25519`, no per-call arena | **TRUE** `⟦SRC⟧` | `fe25519.iii:1-40` "allocation-free", 8×u64 radix-2³²; zero arena calls |
| 7 | RSA-PSS Montgomery modexp, no per-step division | **TRUE (but see #16)** `⟦SRC⟧` | `rsa.iii:388` routes odd modulus to Montgomery `bigint_modpow_mont` |
| 8 | Knuth Algorithm-D division | **TRUE** `⟦SRC⟧` | `bigint_div.iii`: D1 `kd_normalize:210`, D3 `kd_qhat:243`, D4 `kd_mulsub:273`, D6 `kd_addback:307`, D2/D7 `kd_divloop:324` |
| 9 | Constitution: 11-opcode admissibility VM | **TRUE** `⟦SRC⟧` | `constitution.iii:79-89` — exactly 11 opcodes `COP_TRUE…COP_HAS_ANTE`, `cons_eval_predicate` |
| 10 | Commit-gate refuses self-edits when the prover is down | **TRUE** `⟦SRC⟧` | `commit_gate.iii:68` `cg_decide` 5-dim; `CG_REJECT_KERNEL` (≈:109) guards the prover; corpus 864 |
| 11 | zk-STARK FRI prover **and** verifier + Merkle | **TRUE** `⟦SRC⟧` | `zk_stark.iii` `st_prove:359`, `st_verify:448`, Merkle `:171/184/199` (538 lines, not a stub) |
| 12 | Cartographer gate (no dup-export, no un-allowlisted cycle) | **TRUE, but SOFT/external** `⟦SRC⟧` | `build_stdlib.sh:238-253` → `III-CARTOGRAPHER/cartographer.py --gate`; Python, sibling tree, **skipped if absent** — a deviation from the otherwise-NIH framing |
| 13 | ML-KEM/ML-DSA/SLH-DSA keygen·encaps·decaps·sign·verify | **TRUE** `⟦SRC⟧` | `mlkem.iii:607/626/647`, `mldsa.iii:791/892/1056`, `slhdsa.iii:599/616/672` (SLH-DSA is a SPHINCS+ *variant* -- SHA2/SHAKE hybrid, not strict FIPS-205; see IV.1) |
| 14 | ECDSA-P256 (and P384) | **TRUE** `⟦SRC⟧` | `ecdsa_p256.iii:44/51/181`; `ecdsa_p384.iii:43/49/98` |
| 15 | **Knuth-D ~64× faster** than bit-serial | **TRUE — and conservative** `⟦MEAS⟧` | measured **177×–258×** (256→1024-bit); see Part III |
| 16 | **RSA Montgomery modpow "far faster"** | **TRUE (after fix)** `⟦MEAS⟧` | *was* ~2.4× slower (per-limb-alloc REDC); the recommended fix LANDED (CIOS REDC, `bigint_div.iii:571`) and **reversed it → Montgomery now 2.3–2.6× faster**. See §III.16 |
| 17 | **X25519 field mul ~1000× faster** | **OVERSTATED** `⟦MEAS⟧` | measured **~6.9×** vs the *current* generic bigint field path; the "~1000×" was vs a now-deleted arena path that cannot be timed. See Part III |
| 18 | "Proven on metal (Ring-0, Tier-2, no BSOD)" | **PLAUSIBLE, not re-derivable here** `⟦HIST⟧` | a runtime/kernel event; nothing in a read-only source audit can reproduce it. Believed from history; flagged as unverifiable this pass |

**Bottom line of Part I:** 15 of 18 claims are true as stated; one (RSA) *was a measured pessimization, since fixed and reversed*; two performance magnitudes were over-stated and are corrected with measurements; one ("metal") is a historical assertion this pass cannot reproduce. The substrate is genuine throughout — no capability checked turned out to be a stub.

---

## Part II — Capability deep-dives (file-by-file, with execution chronology)

Each section gives: **what it is**, the **files and their roles**, the **chronology** (the actual call path from public entry to result), the **proof obligation** (which KAT would go red if it broke), and **limits + why**.

### II.1 — The self-hosting compiler & the byte-identity reseal `⟦RAN⟧`

**What it is.** `iiis-2.exe` compiles `.iii` source to x86-64 PE objects/executables — *and compiles its own source*. The lexer, parser, semantic analyzer and the four code generators are themselves `.iii`.

**Files & roles** (`COMPILER/BOOT/`):
- `lex.iii` — byte stream → tokens (depth-counting block-comment skip; OS membrane for stderr/clock/exit).
- `parse.iii` — tokens → AST (`ast.iii` defines the node forms).
- `sema.iii` — name resolution, type/effect checking, `@specialize` monomorphization, attribute checking (`@constant_time`, `@crystal`, …).
- `cg_r3.iii` — the main Ring-3 code generator (the one resealed this session, with `cg_rm2.iii` and `sid.iii`).
- `cg_r0.iii` — Ring-0 codegen (kernel-import primitive `r0_emit_sym_run`, PascalCase routing) for the katabasis descent.
- `cg_rm1.iii`, `cg_rm2.iii` — alternate machine targets.
- `sid.iii` — module dependency / seal-id graph used by the seal chain.
- `acc.iii`, `ceiling.iii`, `cg_r3_xii*.iii` — accumulator, resource ceilings, XII-lowering adapters.

**Chronology — building the compiler with itself, and proving it didn't drift:**
1. `build_iiis0.sh` compiles the C seed → `iiis-0` (frozen).
2. `iiis-0` compiles the 25 `.iii` compiler TUs → `iiis-1` (`build_iiis1.sh`).
3. `iiis-1` compiles the *same* 25 TUs → `iiis-2` (`build_iiis2.sh`, `PORTED_TUS` line ~65).
4. **The fixed-point gate** (`build_iiis2.sh --check-corpus`, ≈:229-258): for each `stage1_corpus/*.iii`, compile through **both** `iiis-1` and `iiis-2` and assert the two `.o` files are **byte-identical**. A compiler that changed its own output fails here.
5. **Verified this session** `⟦RAN⟧`: 59 stage1 programs, `PASS=59 FAIL=0`, all byte-identical.

**Proof obligation.** The byte-identity gate is the proof — if a `cg_*` change altered emission, the golden mismatch reddens the build. The frozen `iiis-0`/`iiis-1` seeds are committed so the chain is reproducible from C.

**Limits + why.**
- The reseal is **DRIFT-driven**: the golden hash is the *bare* hash; a compiler-*unreferenced* symbol rename does not drift `iiis-1/2` (so not every edit moves the seal — by design, ADR-027).
- `iiis-0` (the C seed) may still carry the historical `.iii` traps; it is used *only* to bootstrap `iiis-1`, and that hop is byte-gated on `stage1_corpus`, so any divergence reddens `build_iiis2 --check-corpus`. The mature `iiis-2` does **not** reproduce the iiis-0-era traps (re-tested 2026-05-26).

### II.2 — Determinism, the seal & the witness chain `⟦SRC⟧`

**What it is.** Byte-reproducible builds with a content-address seal and a build-provenance witness.

**Files & roles.** `numera/cad.iii` (content-address collapse — the `cad`/`mhash` organ), `numera/merkle.iii` (Merkle commitments), `numera/witness_spine.iii` (witness structure), `sanctus/*` (sealing/trusted-base), `COMPILED/iiis-2.exe.mhash` + `COMPILED/iiis-2.exe.witness.json` (the emitted seal + provenance record).

**Chronology.** Build sets `LC_ALL=C/TZ=UTC0/SOURCE_DATE_EPOCH=0/CCACHE_DISABLE=1` → compiler emits deterministic objects → `cad`/`mhash` content-addresses the binary → `mhash` written beside the exe → `witness.json` records the ported-TU list + hash. On rebuild, the seal-gated `build_iiisN.sh` recomputes and compares; the gate (not a human) decides whether the golden moved.

**Limits + why.** `witness.json` is a *modest build-provenance record* (ported-TU list + mhash), not a full cryptographic transcript of every compilation step — the phrase "witness chain" should be read as **seal + provenance**, not a per-instruction proof log. The strong guarantee is the **byte-identity fixed-point** (II.1), which is what actually catches drift.

### II.3 — Post-quantum cryptography (FIPS 203 / 204) + the shared NTT organ `⟦SRC⟧`

**What it is.** ML-KEM (Kyber) KEM, ML-DSA (Dilithium) signatures, SLH-DSA (SPHINCS+) — all KAT-gated — sharing **one** Montgomery-reduced NTT.

**Files & roles** (`numera/`): `mlkem.iii` (KEM), `mldsa.iii` (lattice signatures), `slhdsa.iii` (hash-based signatures), `pq_dispatch.iii` (parameter-set routing), `ntt.iii` (the shared forward/inverse NTT cores), `ntt_bigint.iii` (NTT-multiply for huge integers), `modular_mont.iii` (Montgomery reduction primitives).

**Chronology — ML-KEM encapsulation** (`iii_mlkem_encaps`, `mlkem.iii:626`):
1. Entry `iii_mlkem_encaps(k, pk, coins, ct, ss)`.
2. Hash `pk`/derive shared randomness via SHA3/SHAKE (`keccak.iii`/`shake*.iii`).
3. Sample matrix **A** and noise in the NTT domain.
4. **Delegate the transform** to the shared organ: `ntt_ct_forward_tabled` (`ntt.iii:155`) and `ntt_gs_inverse_tabled` (`ntt.iii:191`), parameterized by `q = 3329` and ML-KEM's zeta table (`mlkem.iii:33-34` extern, `:93-97` call).
5. Pointwise-multiply, inverse-NTT, compress → ciphertext `ct` + shared secret `ss`.

The same organ serves ML-DSA with `q = 8380417` (`mldsa.iii:35,106`). `ntt.iii:5` names the four prior copies (mlkem, mldsa, zk_stark, entropy_monitor) this organ replaced — this is the single most load-bearing de-duplication in the crypto tree (see Part V ripples).

**Proof obligation.** Corpus **199** (ML-KEM keygen·encaps·decaps), **198** (ML-DSA sign·verify), SLH-DSA KAT — known-answer tests against the FIPS vectors; a wrong NTT reddens all of them at once.

**Limits + why.** The NTT cores are **tabled** (precomputed zeta tables per modulus), so adding a third lattice modulus means adding a table, not a code path — but the cores assume the modulus admits a length-256 NTT (true for Kyber/Dilithium; not a general-modulus transform). Performance is correctness-first scalar Montgomery, not a hand-vectorized AVX-512 NTT.

### II.4 — Classical crypto: X25519, Ed25519, RSA-PSS, ECDSA `⟦SRC⟧`

**Files & roles** (`numera/`): `x25519.iii` (RFC 7748 scalar mult, public entry `x25519:137`, marked `@crystal @side_channel_resistant @constant_time`), `fe25519.iii` (the fixed 8-limb GF(2²⁵⁵−19) field — `fz_mul:95`, `fz_add:149`, `fz_invert:262`, `ed_scalar_mul_base:318`), `crypt_ed25519.iii` (RFC 8032 — `ed25519_pubkey:166`, `ed25519_sign:201`, `ed25519_verify:253`), `rsa.iii` (RSA-PSS — `rsa_keygen:472`, `rsa_pss_selftest:330`, Montgomery `rsa_modexp:388`), `ecdsa_p256.iii`/`ecdsa_p384.iii` (sign/verify) over `ec256/fp256/fn256` (and 384) field/curve files.

**Chronology — X25519 ECDH** (`x25519`, `x25519.iii:137`):
1. Entry `x25519(out, scalar, u_in)`; clamp scalar.
2. Montgomery-ladder over the curve, each step using the **fixed-limb field** (`fz_mul/fz_add/fz_sub` on 8×u64 module buffers — *no* arena allocation per multiply, `fe25519.iii:1-40`).
3. Final `fz_invert` (Fermat) + `fz_freeze` → canonical 32-byte `out`.

**Chronology — Ed25519 sign** (`ed25519_sign`, `crypt_ed25519.iii:201`): SHA-512 expand seed → scalar; `ed_scalar_mul_base` (`fe25519.iii:318`) for `R`; SHA-512 the transcript → `k`; `s = r + k·a mod L`; encode `(R,s)`.

**Proof obligation.** Corpus **73** (X25519 RFC 7748), **59/74/75** (Ed25519 RFC 8032 vectors 1–3), **193–197** (Ed25519 family), **373** (RSA-PSS), **913** (ECDSA-P256), **183** (X25519/Ed25519 field bit-identity vs bigint).

**Limits + why.**
- The X25519/Ed25519 field is *fixed* to 2²⁵⁵−19 (8 limbs, radix 2³²) — fast and allocation-free, but **not a general field**; other curves use the separate `fp256/fp384` bigint-backed fields, which are slower.
- RSA modexp's Montgomery routing is a **measured pessimization** against the current Knuth schoolbook — see Part III.16. The signature is *correct* (corpus 373 passes); it is just not the fast path it was described as.

### II.5 — Hashes, MACs, AEAD, KDFs, RNG `⟦SRC⟧`

**Files & roles** (`numera/`): `sha256.iii`+`sha256_dispatch.iii` (scalar + AVX-512, bit-identity-gated), `sha512.iii`, `sha3_256.iii`/`sha3_512.iii`/`shake128.iii`/`shake256.iii` over `keccak.iii` (`keccak_f1600:270`, `keccak_absorb:364`, `keccak_squeeze:411`) and `keccak256.iii` (`keccak256_oneshot:37`), `blake2s.iii`, `poly1305.iii` (`poly1305_set_key:86`, `_update:355`, `_finalize:367`, all `@constant_time`), `hmac.iii`, `hkdf.iii`, `pbkdf2.iii`, `chacha20.iii`/`chacha20_poly1305.iii`/`xchacha20_poly1305.iii`, `aes.iii`/`aes_gcm.iii`/`aes_siv.iii`, `drbg.iii`, `xoshiro.iii`, `entropy_monitor.iii`, `crc32.iii`, `murmur3.iii`.

**Chronology — SHA-256 (dispatched):** `sha256_dispatch` reads CPU features (`cpufeat.iii`) → picks AVX-512 schedule or scalar → both paths are **bit-identity-gated** against each other (corpus 184). AEAD (e.g. ChaCha20-Poly1305) chains the stream cipher and the `@constant_time` Poly1305 MAC.

**Proof obligation.** Corpus 02/15 (SHA-256 KAT abc/empty), 55/56 (SHA-512), 155–158/168/169 (SHA-3/SHAKE/Keccak), 71/72 (Poly1305 / ChaCha20-Poly1305 RFC 8439), 60–69 (AES/AES-GCM FIPS-197/NIST), 79 (HMAC RFC 4231), 81 (HKDF RFC 5869), 86 (PBKDF2 RFC 7914), 83 (BLAKE2s), 84 (xoshiro determinism), 82 (CRC32), 88 (murmur3), 180/181/184 (scalar↔AVX-512 bit-identity).

**Limits + why.** The AVX-512 paths require **AVX-512DQ** (not just F) because `_big_mul8_avx512` uses `vpmullq` — on F-only hosts the dispatch correctly falls back to scalar (`bigint.iii:570-572`), else `#UD`. RNG is deterministic DRBG/xoshiro for reproducibility, *not* an OS entropy source.

### II.6 — Bigint arithmetic: multiply dispatch, Knuth-D division, Montgomery `⟦SRC⟧`

**Files & roles** (`numera/`): `bigint.iii` (core; schoolbook `bigint_mul:646`, scalar `bigint_mul_u64:579`, AVX-512 `_big_mul8_avx512:530` gated at `:570`), `bigint_karatsuba.iii` (Karatsuba split), `ntt_bigint.iii` (NTT-multiply for huge operands), `bigint_div.iii` (Knuth Algorithm D + retained bit-serial oracle + Montgomery REDC), `modular.iii`/`modular_mont.iii`.

**Chronology — multiply dispatch:** `bigint_mul` picks by operand width — small → schoolbook (optionally `_big_mul8_avx512` when AVX-512DQ present and `BIG_VEC_FORCE` allows) → mid → Karatsuba → huge → NTT-multiply. **Chronology — division:** `bigint_div_qr` → D1 normalize (`kd_normalize:210`) → D2/D7 loop (`kd_divloop:324`) → per digit D3 q̂ estimate with two-place correction (`kd_qhat:243`) → D4 multiply-subtract (`kd_mulsub:273`) → D6 add-back on borrow (`kd_addback:307`).

**Proof obligation.** Corpus 33 (mul-add), 47/48 (div u64 / div_qr), 143 (Karatsuba), 182 (mul scalar↔AVX-512 bit-identity), 757 (Knuth vs bit-serial differential), 722–725 (NTT / NTT-convolve / NTT-bigint / large-route), 990/991 (the speedup benches).

**Limits + why (critical).** The retained `bigint_div_qr_bitserial` is the **oracle** the fast path is proven against — it is *kept on purpose*, not dead code. The Montgomery REDC in this file is correct but allocation-heavy (Part III.16). A **function-LOCAL `var [T;N]` indexed by a runtime var segfaults** in `iiis` — so the Knuth scratch is module-global raw-limb arrays (this is *why* Knuth is allocation-free and fast; it is a compiler-trap-driven design choice, not incidental).

### II.7 — Zero-knowledge: the FRI-based zk-STARK `⟦SRC⟧`

**Files & roles** (`numera/`): `zk_stark.iii` (prover+verifier+Merkle+Fiat-Shamir, 538 lines), `zk_field.iii` (STARK field), `zk_prune.iii`, `zk_snark.iii`.

**Chronology — prove/verify:** `st_prove` (`zk_stark.iii:359`) → build execution trace → Merkle-commit (`st_merkle_build:171`) → FRI fold/commit rounds → Fiat-Shamir challenges from the transcript → open queried positions (`st_merkle_open:184`). `st_verify` (`:448`) re-derives the Fiat-Shamir challenges, checks Merkle openings (`st_merkle_verify:199`) and the FRI low-degree relations.

**Proof obligation.** Corpus **376** (zk-STARK prove→verify round trip, NIH, no external SNARK lib).

**Limits + why.** It is an **NIH FRI-STARK** (Merkle + Fiat-Shamir), not a pairing-based zk-SNARK with a trusted setup — soundness rests on the hash (collision-resistance) and the FRI parameters, and proof size is logarithmic, not constant. Field and query-count are fixed by the module, not a general circuit DSL.

### II.8 — Math / logic / verification substrate `⟦SRC⟧`

**Files & roles** (`numera/`): `theorem_carrier.iii`/`proof_carrying.iii`/`proof_term.iii`/`curry_howard.iii` (proof carriers), `computation_graph.iii` (bisimulation — *no equivalence claim without a witness*), `congruence.iii` (congruence-closure union-find), `egraph.iii` (e-graph: `eg_find:364`, `eg_union:434`, e-match `eg_find_cand:761`), `temporal_logic.iii` (LTL bounded model checking), `constitution.iii` (the 11-opcode admissibility VM, `:79-89`) + `constitution_preserver.iii`, `commit_gate.iii` (`cg_decide:68`, 5-dimension), `induct.iii` (sample→∀ inductive bridge), `sat.iii`/`sat_arith.iii`/`sat_at_scale.iii`/`smt.iii`, `category.iii`/`sheaf.iii`/`groebner.iii`, `quine_verifier.iii`, `typecheck.iii`/`ccl.iii`, `symbolic_regression.iii`.

**Chronology — the commit gate refusing a self-edit:** `cg_decide` evaluates 5 dimensions; the **KERNEL** dimension checks the prover underwriting every other verdict — if it is REJECTED, `cg_decide` returns `CG_REJECT_KERNEL` (a distinct code naming the failing dimension, `commit_gate.iii:30,109`). Corpus **864** exercises every reject arm. **Chronology — the constitution VM:** clauses are ratified, then an admissibility predicate is compiled to ≤11-opcode bytecode (`COP_TRUE…COP_HAS_ANTE`) and run on a small stack machine by `cons_eval_predicate`.

**Proof obligation.** Corpus 644 (LTL/temporal), 864 (commit-gate reject arms), the constitution corpus, plus the e-graph/congruence/bisimulation KATs. The discipline (memory): *confluence/two-path tests must drive different rules on each side* — same-term-twice is not a test.

**Limits + why.** LTL is **bounded** model checking (a finite unrolling depth) — it refutes within the bound, it does not prove unbounded liveness. The constitution VM is an **admissibility** predicate evaluator (11 opcodes), deliberately small — it is a gatekeeper, not a general logic.

### II.9 — The Ripple Calculus `⟦SRC⟧`

**What it is.** The system measures its own module graph (noise / load-bearing / duplication) and computes a sound refactoring plan.

**Files & roles**: `omnia/ripple.iii`, `omnia/ripple_field.iii`, `omnia/proof_ripple.iii`+`proof_ripple_resolution.iii`, `numera/ripple_metric` & `ripple_search` (the certified-monotone metric 𝒱 and the real argmax M-search — recent G2/G3 enhancements), `forcefield/*` (the ripple optimizer), `tp_ripple_dot.iii`/`tp_ripple_md.iii` (emit the graph as DOT/MD). The dependency spine is `sid` (`101_sid_direct_graph`, `102_sid_transitive_closure`, `103_sid_visualize_utf8`).

**Chronology.** `sid` builds the direct dependency graph → transitive closure → the ripple metric scores each module (noise/load-bearing/duplication) → `ripple_search` computes an argmax refactor target → a plan is emitted (DOT/MD). **O(N)** now (recent enhancement).

**Proof obligation.** Corpus 101–103 (sid), 119/120 (ripple analyze/execute), 124 (proof-ripple witness), 755/756/942/964/966 (ripple grouping / corpus-verify / merkle domain-sep / extract-audit purity).

**Limits + why.** The metric 𝒱 is **certified-monotone and non-gameable** (G2) — but it scores *structure* (the dependency/duplication graph), not runtime behavior; it tells you what to refactor, not what is slow. (This is precisely why the *performance* claims needed separate benchmarks — the ripple metric cannot see cycle counts.)

### II.10 — Microarchitecture, HDL, physical-cost `⟦SRC⟧`

**Files & roles** (`numera/`): `microarch_model.iii` (explicit hazard/port/ROB pipeline — `ROB_CAP=224`, `EXEC_PORTS=10`, `PORT_MASK[4096]`), `hdl.iii` (combinator→gate-netlist lowering, sequential circuits/DFlipFlop), `cost_lattice.iii`/`cost_lattice_synth.iii`/`cost_calculus.iii` (gate-delay + wire-capacitance physical cost), `aeu.iii` (hardware Axiom Enforcement Unit), `sov_isa.iii`/`sov_pipeline.iii` (the sovereign ISA + pipeline).

**Chronology.** HDL: combinator graph → certified gate-netlist (`hdl.iii`) → E-graph selects the fewest-gate equivalent (the SX3 netlist optimizer) → physical cost computed on the cost lattice (gate delay + wire C) → microarch model simulates ROB/port issue. Corpus 952 (ROB saturation), 963 (ISA cost gradient), plus the HW/SX corpus.

**Limits + why.** This is a **model** (analytic ROB/port simulation + analytic gate cost), not a cycle-accurate RTL simulator or a real synthesis flow — it reasons about microarchitecture and silicon cost, it does not tape out.

### II.11 — Systems & the "sovereign" layer `⟦SRC⟧`

**Files & roles**: `numera/cad.iii` + `omnia/caindex.iii` (content-address index), `memoria/*` (arena/region allocators), `omnia/bound.iii` (bounds-contract organ), `aether/http_server.iii`+`http_client.iii`+`tcp/net/inet` (HTTP server & client), `aether/*` (base32, format, async, IPC), `omnia/{list,map,set,vec,queue,lru,option,result,either,fold,iter,zip}.iii` (containers).

**Chronology — HTTP request:** `http_server` accepts on a `tcp`/`net` socket → parses request line + headers (corpus 57/58/64) → routes → `http_send_response` (corpus 65). The content-address index (`caindex`) keys artifacts by their `cad`/`mhash` so identical content collapses to one entry.

**Proof obligation.** Corpus 36 (capability attenuate/revoke), 37/38 (handle/fs round-trip), 51 (sockaddr), 57/58/64/65 (HTTP), 92 (base32), 121–123 (arena/region reset, stress), 705/710/711/713 (bound/base32/format/inet sealed builders), 720 (caindex).

**Limits + why.** The HTTP stack is a **parser + server/client over the III net layer**, NIH (libc + III BOOT headers only, no third-party deps) — it is for the substrate's own use, not a hardened public-internet server (no TLS termination in the HTTP layer itself; crypto is a separate organ).

### II.12 — The XII term-rewriting system `⟦SRC⟧`

**Files & roles** (`omnia/xii_*.iii`, ~40 files): `xii_term.iii`/`xii_rewrite.iii` (terms + rule application), `xii_rule_verify.iii`/`xii_rule_overlap.iii`/`xii_critpair_enum.iii`/`xii_joinability.iii`/`xii_conf_cert.iii` (critical-pair / confluence certification), `xii_termination.iii` (termination), `xii_lower_*.iii` (the lowering pipeline: compose/decide/iterate/program/then/under/with), `xii_admission.iii` (rule admission), `xii_curated_*.iii` (curated rule payloads incl. crypto/RISC-V).

**Chronology.** A rule set is admitted (`xii_admission`) → critical pairs enumerated (`xii_critpair_enum`) → joinability checked → a confluence certificate emitted (`xii_conf_cert`) → termination proven → the lowering pipeline rewrites terms to a canonical/normal form. **Caution (memory):** XII `apply_one` mutates the term in place and returns the same ref — firing is detected via `xii_rewrite_last_rule_fired()`, not `next == cur`.

**Proof obligation.** The XII corpus band 280–372 (delegated to `run_xii_corpus.sh`), plus 904/937/939/950 (curate / crypto-chokepoint / confluence-falsifier / emit-gen catalog).

**Limits + why.** Confluence/termination are **certified per admitted rule set**, not globally decidable — the system proves *these* rules confluent/terminating, it does not solve the (undecidable) general problem. The XII band is `SKIP`-delegated from the conformance corpus, so it has its own runner and is not in the `619` count (this is bookkeeping, not a gap).

### II.13 — The katabasis / CHARIOT descent (III beneath Windows) `⟦SRC⟧` / `⟦HIST⟧`

**Files & roles** (`katabasis/`, 14 files): the Ring lattice, gate-admission (`katabasis_gate_admit` computing seal+cap+hexad+SID → verdict), capability verification, the VMEXIT set, the Census Crystal, the nine cycle families, the exhaustive bricking theorem. Codegen support: `cg_r0.iii` (Ring-0 emission, kernel-import primitive `r0_emit_sym_run`).

**Chronology.** A descent request → `katabasis_gate_admit` computes the content-address seal, verifies the capability, types the hexad, checks the SID → emits a verdict (admit/brick). The six descent data tables (svm/cycle_family/census/bar/vmexit/ring_lattice) are `.def` single-source + `--check` drift-gated + content-address sealed.

**Proof obligation.** Corpus 390–395, 600–609 (15 katabasis KATs), 601/603 (ring lattice / census).

**Limits + why.** The gate-decision substrate and data tables are **`⟦SRC⟧` real and KAT-gated**. The claim that it *ran in Ring-0 on metal (Tier-2, Win32 err 50, no BSOD)* is `⟦HIST⟧` — a runtime kernel event recorded in project history that a source audit cannot reproduce. The **R3 IOCTL gate** (wiring `cg_r0`'s kernel-import primitive to a live `ntoskrnl` link) is noted in history as the *next* step — i.e. not all of the descent is wired to a live driver yet.

### II.14 — The defining property: nothing ships unproven `⟦RAN⟧` + `⟦SRC⟧`

**What it is.** Every capability above is backed by a **falsifier-first** KAT — negative arms included (a guard must *reject* bad input, not merely accept good input).

**The gate stack** (all run by `build_stdlib.sh` / `run_corpus.sh`):
- **Determinism gate** — byte-identity reseal (II.1).
- **Conformance corpus** — `619/0`, with negative tests that must *fail to compile* and KATs that assert specific non-trivial exit codes (e.g. `02_sha256_kat_abc`=186, `73_x25519`=195).
- **Forge-closure / trusted-base seals** (`sanctus/*`).
- **Cartographer architectural-invariant gate** — no duplicate `@export`, no un-allowlisted cycle (`build_stdlib.sh:238`; SOFT/external — II Part I #12).
- **Per-`.def` drift gates** — generated tables byte-matched against their single source (proven to catch hand-edits).

**Limits + why.** The discipline is real, but two honest caveats: (a) the cartographer gate is a **soft/external Python** dependency (skipped if absent), and (b) a *passing* KAT proves the positive path; negative arms must be *separately* present — the project's own rule is **"prove the negative case,"** because a negative-only KAT can hide a dead positive path that returns a tested negative's code. The corpus enforces both arms where it has been made to.

---

## Part III — Speedup claims, **measured** (`⟦MEAS⟧`)

All three magnitudes from the original summary were unmeasured prose. They are now benchmarked. Method: each bench times the **new** and the **old/alternative** path on the **same operands, same host, same run**, and reports the **cycle ratio** — a clock-invariant quantity (both paths scale with TSC frequency), gated on bit-identical results so the comparison cannot cheat. Benches live at `STDLIB/corpus/990,991,992` and are owned by `run_bench_corpus.sh` (correctness = hard fail; timing = advisory).

### III.15 — Knuth Algorithm-D division: **VERIFIED, and conservative** ✅

`990_bench_knuth_div.iii` — `bigint_div_qr` (Knuth-D) vs the retained `bigint_div_qr_bitserial` oracle, gated on `q·b + r == a` and identical `(q,r)`:

| operand size | Knuth (cyc) | bit-serial (cyc) | **ratio** |
|---|---|---|---|
| 256 / 128-bit | 3 375 | 599 525 | **177×** |
| 512 / 256-bit | 6 425 | 1 437 750 | **224×** |
| 1024 / 512-bit | 16 200 | 4 179 650 | **258×** |

The "~64×" source comment is **true and conservative** — the real ratio is 177–258× and *grows with size* (Knuth is O(m·n) quotient digits; bit-serial is O(bits) shift-subtract). Exit 99 (faster at every size). **Why so fast:** Knuth runs allocation-free on module-global raw-limb arrays; bit-serial does one shift-subtract per bit.

### III.16 — RSA Montgomery modpow: **was a measured pessimization — now FIXED and reversed** ✅ *(highest-value finding, and its resolution)*

> **⟳ UPDATE (2026-05-30, later same day — the recommendation below LANDED).** The allocation-free fix was implemented: `mont_mul_bigint` (`bigint_div.iii:571`) is now **radix-2³² CIOS** (Coarsely Integrated Operand Scanning) on fixed module-global scratch (`MM_N/MM_A/MM_B/MM_T`) — **zero per-limb-step allocation**, exactly one output bigint. Re-measuring `991` on the current build **reverses the result**: Montgomery is now **2.3–2.6× FASTER** than schoolbook+Knuth (521-bit 2.28×, 1279-bit 2.46×, 2203-bit 2.48×; exit 99). The measurement below is the *historical* record that drove the fix; the shipped RSA path is now correct **and** the fast path.

`991_bench_montgomery_modpow.iii` — the **shipped** RSA path (`bigint_modpow`, which routes an odd modulus → `bigint_modpow_mont`, `rsa.iii:388`) vs a reconstructed schoolbook square-and-multiply whose per-step reduction uses the **fast Knuth divider**. Gated on bit-identical results at every size (both impls agreed → exit 99):

| modulus | Montgomery (cyc) | schoolbook+Knuth (cyc) | ratio (school/mont) |
|---|---|---|---|
| 521-bit | 9 074 000 | 3 818 500 | **0.42×** |
| 1279-bit | 42 590 600 | 16 387 700 | **0.38×** |
| 2203-bit | 126 200 100 | 47 155 100 | **0.37×** |

**Montgomery is ~2.4–2.7× *slower* than schoolbook-with-Knuth.** The claim "far faster than bit-serial" is *technically true vs bit-serial* — but bit-serial is itself ~250× slower than Knuth (III.15), so against the system's **current** best reduction (Knuth division), the Montgomery rewrite is a pessimization.

**Root cause (`bigint_div.iii:556-567`, documented in the bench header):** `mont_mul_bigint`'s REDC performs **three fresh bigint allocations per limb-step** (`bigint_mul_u64` + `bigint_add` + `bigint_shr_bits`) — ~3k heap-handle allocs per multiply — while Knuth division runs allocation-free on fixed raw-limb arrays. Montgomery's asymptotic "no division" win is swamped by per-limb allocation overhead.

**Recommendation (NOT implemented here — `.iii` trap territory needing the full read-before-write protocol):** either (a) route odd moduli to schoolbook-with-Knuth (drop the Montgomery path for RSA-sized operands), or (b) make REDC allocation-free on raw-limb arrays the way Knuth already is. Correctness is not at risk either way — corpus 373 and bench 991's bit-identity gate both hold.

### III.17 — X25519 fixed-limb field multiply: **OVERSTATED magnitude, real speedup ~6.9×** ⚠️

`992_bench_fe25519_mul.iii` — `fz_mul` (fixed 8-limb GF(2²⁵⁵−19), allocation-free) vs a generic arbitrary-precision field multiply (`bigint_mul` + `bigint_mod p`, using the Knuth divider). Gated on identical `a·b mod (2²⁵⁵−19)` (exit 99):

| | fz_mul (cyc) | generic bigint (cyc) | **ratio** |
|---|---|---|---|
| GF(2²⁵⁵−19) mul | 1 800 | 12 350 | **6.9×** |

The "~1000× / µs-vs-ms" figure referred to the **old per-call-arena bigint field path that `fe25519` replaced** — that path is *deleted*, so it cannot be timed today. Against the **current** best generic bigint field mul, the specialized fixed-limb field is **~6.9×** faster. The historical 1000× (vs arena-per-op) is plausible but *unfalsifiable now*; the honest, measurable number is ~6.9×.

**Why:** `fz_mul` does 64 partial products into fixed module buffers with deferred carry/freeze (freeze only at the end); the generic path allocates and runs a full Knuth division for the reduction.

### Part III summary

| claim | prose magnitude | **measured** | verdict |
|---|---|---|---|
| Knuth-D division | ~64× | **177–258×** vs bit-serial | ✅ verified, conservative |
| RSA Montgomery modpow | "far faster" | **2.3–2.6× faster** vs Knuth-schoolbook *(after CIOS-REDC fix; was 0.4×)* | ✅ pessimization found → fixed → reversed |
| X25519 field mul | ~1000× | **~6.9×** vs current generic bigint | ⚠️ real but far smaller; 1000× baseline is gone |

The pattern: the **algorithmic** improvements are all real and correct (bit-identity-gated); two of the three **magnitudes** were over-stated, and one direction (RSA) measured backwards against the system's own current alternative — which is exactly why the bench mattered: the measurement drove the CIOS-REDC fix that **reversed it (now 2.3–2.6× faster)**. This is the kind of thing only measurement — not a source read — can catch.

---

*Parts IV (file-by-file capability discovery) and V (inter-file ripple/emergent capabilities) are appended below as those passes complete.*

---

## Part IV — Every written capability (the file-by-file discovery pass)

This part answers the second request: *go through the system file-by-file and find every bit of written capability — the small, the broken, the huge-and-forgotten.*

### IV.0 — How this pass was done

A read-only fan-out of **17 `Explore` agents** (one per subsystem slice; the two large subsystems `numera` and `omnia` split thematically, `memoria`+`tempora` merged into one slice) plus a **completeness critic** -- **18 agents total** -- each tasked not merely to inventory but to **hunt anomalies** against the formal Atlas. Cost: ~2.06 M agent tokens, 656 tool-uses, ~16 min. **All 17 discovery slices returned**; the 18th agent is the critic (nothing was lost). **Discipline:** the agents produce *leads*; the main session produces *verified facts* — every load-bearing finding below (especially the "broken" ones) was re-checked against source by the main session before it entered this document.

**Yield:** **398 capabilities** catalogued and **255 anomalies**, distributed:

| kind | count | meaning |
|---|---|---|
| undocumented | 63 | real capability in code, absent from the formal Atlas |
| other | 65 | buffer bounds, compiler-trap workarounds, fragile patterns |
| no-corpus-test | 49 | exists, covered transitively, no isolated KAT |
| undersold | 31 | more capable than its header/Atlas implies |
| dead-export | 23 | `@export` referenced only inside its own file |
| broken | 17 | flagged broken/fragile/contradictory — **adjudicated below** |
| stub-todo | 7 | scaffolding or stale spec comments |

### IV.1 — Verification corrections (what I re-checked myself before trusting it)

The single most important result of this pass is a **caution about its own method**: an agent reasoning with C/Rust intuition systematically *over-reports* "broken" against III's grammar. I verified every "broken" finding:

- **Three "missing-semicolon syntax errors" are FALSE POSITIVES.** `quality_q7.iii:70` (`{ hit = 0u8  k = patlen }`), `quality_q7.iii:84` (`{ g_resolver_lint_violation = 1u8  return 0u8 }`), and `xii_mig4_seal.iii:115` (`{ _xms_walk(...)  return 0i32 }`) were flagged as broken. **III is a separator-free language** — whitespace/newline separates statements, semicolons are not required. I compiled all three files standalone: **`RC=0`**, and they are members of the `431/0` green build. The agents misread valid III as broken C.
- **`prespec.iii … from "_unused.iii"` "broken" is the link convention, not a bug.** There is no `_unused.iii`; it is the "forward-declare, resolve-at-link" placeholder origin for 256 prototypes that resolve from `libiii_native.a` at link time (the build is green). It is a *fragility* (no signature source-of-truth — Part V) but it is not broken.
- **Net verdict on the 17 "broken": ZERO represent an actually-failing capability in the green build.** They resolve to:
  1. **~4 false positives** (the 3 separator misreads + the `_unused` convention).
  2. **Documented buffer-bound limits**, each carrying an audit tag: `aes_siv.iii:208` (`[E2-SIV-1]` — `SIV_TBUF[65536]` overruns if `pt_len > 65536`), `drbg.iii:108/134` (`[D-DRBG-1]` — `DRBG_IN[1024]` overruns if `data_len > 959`; `DRBG_SEED[768]` if `elen+nlen+plen > 768`). These are *known, bounded* limits, not silent bugs.
  3. **Documented compiler-trap workarounds**: `cost_lattice.iii:33` records that `iiis-2` miscompiles a `u64 /` as a signed `idivq` (silently dropping an overflow case), so the module uses a *divide-free* overflow detector (`cl_mul_ovf`) — a workaround for a compiler bug, correct as written.
  4. **Fragile-but-correct patterns**: `http.iii:108` masks a slot with `& 0xFF` (correct *only because* the max is 64, a power of two — would break if raised); `regex.iii:352` can overflow `REGEX_NODES` and return `RX_INVALID_IDX` (a guard exists; audit `MATH-1`).
  5. **Stale/orphaned comments**: `sat_at_scale.iii:34` calls `sat.iii` "NOT-YET-BUILT" while `sats_solve` (line 616) fully drives the working `sat_*` API; `resolver_replay.iii:47` cites a now-removed dead check; `sov_isa.iii:212` references a stub that is already gone.

- **The most consequential *real* findings** (verified, not failures but genuine documentation/contract gaps):
  - **Output-parameter ABI, un-annotated** — `iii_mldsa_sign` (`mldsa.iii:1041`) and `iii_slhdsa_sign` (`slhdsa.iii:665`) take `siglen` declared as input `u64` but use it as an **output pointer** (`let slp : *u8 = siglen as *u8`, writing 8 bytes of signature length). C-idiomatic, correct, but the signature type lies about direction.
  - **SLH-DSA is a SPHINCS+ *variant*, not strict FIPS-205** (SHA2/SHAKE hybrid) — an honest scoping caveat the headline "FIPS 205" elides.
  - **`resolver.iii` Phase C.5 hot-fast-path (505–509) is a shortcut that the 11-step resolve() contract explicitly forbids** ("no step 12; no shortcut path") — the implementation contradicts its own frozen spec (a correctness-neutral optimization that violates a stated invariant).
  - **`nous_completion.iii:49` `[CUT-11]`** — the completion certificate tag was once 4 bytes (verdict only), making every cert identical regardless of `(n_pairs, budget)` — i.e. **vacuous**; it is now 9 bytes binding all three. The fix is in; the comment marks where a vacuous-proof bug lived (a `prove-the-negative` lesson realized).

With that adjudication established, the full inventory and the raw anomaly catalog follow. Treat every `file:line` as a checkable claim; treat "broken" as "flagged, then adjudicated above."


### IV.2 - The capability inventory (398 capabilities, by subsystem)

*Discovered by the read-only fan-out; each entry's `file:line` is independently checkable. Format: `Capability - entry - what it does`.*

> **Tier note (read before citing a single line).** Unlike Parts I-III (each self-verified by the main session), the entries in IV.2/IV.3 are **agent-reported leads -- checkable, but not all checked**. The one bucket the main session fully audited (the 17 "broken") was ~24% false positives (see IV.1, where III's separator-free grammar tripped the auditors). The main session additionally spot-checked high-value entries -- AES-192 (`aes.iii:195`), the resolver Phase-C.5 contract bypass (`resolver.iii:505`), egraph Reed-Solomon/Merkle self-heal (`egraph.iii:29`), the `net_set_addr_d` dead-export -- and **all held**. Still: treat an individual line as a **lead to verify**, not a proven fact.


#### Post-Quantum Crypto + NTT  *(`numera-pqc-ntt`, 11 capabilities)*

- **ML-KEM (FIPS 203) Key Encapsulation** - `mlkem.iii:607` - Three-level ML-KEM (Kyber) KEM with iii_mlkem_keygen/encaps/decaps supporting k=2/3/4
- **ML-DSA (FIPS 204) Digital Signature** - `mldsa.iii:791` - Three-level ML-DSA (Dilithium) signature scheme with iii_mldsa_keygen/sign/verify at levels 2/3/5
- **SLH-DSA Hash-Based Signature** - `slhdsa.iii:599` - Hash-based signature (SPHINCS+ variant, non-FIPS-205 due to SHA2/SHAKE hybrid) with three security levels
- **Post-Quantum Suite Dispatcher** - `pq_dispatch.iii:50` - Unified dispatcher routing FIPS suite IDs (0x0100/0x0110/0x0120 families) to ML-KEM/ML-DSA/SLH-DSA
- **Modulus-Parameterized NTT** - `ntt.iii:100` - Generic radix-2 DIT/DIF NTT over any NTT-friendly prime, shared by Kyber/Dilithium/bigint multiply
- **Tabled NTT (FIPS COMBINE-1)** - `ntt.iii:155` - Cooley-Tukey forward & Gentleman-Sande inverse using Montgomery-reduced pre-computed zeta tables
- **Big-Integer Multiplication via NTT** - `ntt_bigint.iii:160` - O(n log n) FFT multiply using 2-prime Garner CRT over u32 digit arrays (fixes D-KARA-1 slot exhaustion)
- **Montgomery Modular Multiplication** - `modular_mont.iii:95` - REDC-based mont_mul_u32/mont_pow_u32 for u32-bounded moduli with carryless u64 arithmetic
- **Generic Modular Arithmetic** - `modular.iii:18` - Fallback mod-add/sub/mul/pow for arbitrary moduli (u32 and u64 variants) with no primality requirement
- **NTT Convolution (Cyclic Polynomial Multiply)** - `ntt.iii:280` - Forward-pointwise-inverse pipeline for acyclic polynomial products in GF(q)
- **NTT Composition Table Wrappers** - `pq_dispatch.iii:99` - Four-argument (c4) composition ABI adapters for post-quantum keygen/sign/verify/encaps/decaps

#### Classical Crypto (RSA/ECDSA/Ed25519/X25519)  *(`numera-classical-ecc`, 16 capabilities)*

- **RSA-PSS signatures (RSASSA-PSS, RFC 8017)** - `rsa.iii:815` - Full-stack RSA-3072/4096 with EMSA-PSS encoding, SHA-256, constant-time Montgomery modexp (u32 CIOS)
- **RSA key generation (Miller-Rabin, seed-based)** - `rsa.iii:472` - Probabilistic primality test (12 fixed bases) with arena-based bigint path
- **ECDSA P-256 (NIST, RFC 6979 deterministic)** - `ecdsa_p256.iii:44` - Full keygen, sign, verify over curve order with constant-time scalar multiplication
- **ECDSA P-384 (NIST, mirrored P-256)** - `ecdsa_p384.iii:43` - 48-byte field elements (fp384/fn384) with same RCB complete addition formula
- **Ed25519 signatures (RFC 8032)** - `crypt_ed25519.iii:166` - Public key derivation from seed; delegates point ops to fe25519 (bigint scalars only)
- **X25519 ECDH (RFC 7748, Montgomery ladder)** - `x25519.iii:100` - Constant-time branchless cswap; 255-bit scalar multiplication on GF(2^255-19)
- **GF(p256) constant-time arithmetic (P-256 field)** - `fp256.iii:27` - 8x u32 Montgomery CIOS limbs; R^2 computed at init via 256 constant-time doublings
- **GF(p384) constant-time arithmetic (P-384 field)** - `fp384.iii:22` - 12x u32 limbs; same masked-conditional-sub design as fp256
- **Scalar field GF(n) for P-256 (fn256)** - `fn256.iii:24` - ECDSA scalar ops: r, s, u1, u2 modulo the curve order; computed n'[0] (not 1)
- **Scalar field GF(n) for P-384 (fn384)** - `fn384.iii:227` - 48-byte scalars for P-384 ECDSA with same Montgomery design
- **P-256 elliptic curve (Weierstrass, RCB complete add)** - `ec256.iii:38` - Projective coords (X:Y:Z), Renes-Costello-Batina exception-free formula
- **P-384 elliptic curve (RCB mirrored from P-256)** - `ec384.iii:142` - Double-and-add-always scalar mul with constant-time branching
- **GF(2^255-19) field (Ed25519/X25519)** - `fe25519.iii:60` - 8x u64 limbs (radix 2^32), complete add formula (add-2008-hwcd-3), ~1000x faster than bigint
- **Generic field arithmetic Fp (bigint-based)** - `field.iii:38` - Add, sub, mul, pow, Fermat inversion (assumes prime modulus)
- **Galois field GF(2^8), GF(2^128), GF(p)** - `galois.iii:91` - Russian-peasant multiply, Fermat inversion, Berlekamp-Massey LFSR, Lagrange interpolation
- **Field inversion with error crystals (provenance)** - `field_crystal.iii:83` - Wraps fp_inv_fermat; mints error crystals on failure (zero or tiny p)

#### Symmetric / Hash / AEAD / KDF / RNG  *(`numera-symmetric-hash`, 26 capabilities)*

- **AES-128/192/256 block cipher** - `aes.iii:252` - FIPS 197 AES with key expansion (128/192/256-bit), encrypt/decrypt block; hand-rolled S-box computation, GF(2^8) multiplication, no external dependency
- **AES-GCM authenticated encryption (128-bit/256-bit)** - `aes_gcm.iii:406` - NIST SP 800-38D GCM mode with GHASH over GF(2^128); scalar baseline + optional PCLMULQDQ (AVX-NI) dispatch; 96-bit nonce
- **AES-SIV deterministic AEAD** - `aes_siv.iii:207` - RFC 5297 AES-SIV-CMAC-256 (32-byte key split); S2V-based IV derivation, CTR encryption; bounded plaintext (<=65536 bytes)
- **ChaCha20 stream cipher** - `chacha20.iii:329` - RFC 8439 ChaCha20: 32-byte key, 12-byte nonce, 32-bit counter, 64-byte blocks; scalar/AVX-512/AVX2 dispatch
- **HChaCha20 subkey derivation** - `chacha20.iii:126` - RFC draft XChaCha20: 20-round quarter-round on key+nonce16, outputs words 0..3 and 12..15 (no final add)
- **ChaCha20-Poly1305 AEAD** - `chacha20_poly1305.iii:88` - RFC 8439 authenticated encryption: ChaCha20(counter=0) -> Poly1305 OTK, ChaCha20(counter>=1) -> CTR encryption, Poly1305 MAC
- **XChaCha20-Poly1305 extended-nonce AEAD** - `xchacha20_poly1305.iii:41` - draft-irtf-cfrg-xchacha: HChaCha20(nonce[0:16]) -> subkey, ChaCha20-Poly1305(subkey, nonce[16:24])
- **SHA-256 hash** - `sha256.iii:259` - FIPS 180-4 SHA-256: streaming init/update/final, one-shot; scalar baseline + optional AVX-512 message-schedule sigma0 (4-wide); unmasked u32 ops (cg_r3 fix)
- **SHA-256 dispatch layer** - `sha256_dispatch.iii:66` - Runtime dispatch to SHA-256 implementation with perf-impact crystal annotation; currently all paths are software
- **SHA-512 hash** - `sha512.iii:286` - FIPS 180-4 SHA-512: streaming, 80-round compression, 64-bit words; scalar + optional AVX-512 4-wide message-schedule dispatch
- **SHA3-256 sponge hash** - `sha3_256.iii:29` - FIPS 202 SHA3-256 (rate 136, capacity 64, dom-sep 0x06) over keccak-f[1600]
- **SHA3-512 sponge hash** - `sha3_512.iii:28` - FIPS 202 SHA3-512 (rate 72, capacity 128, dom-sep 0x06) over keccak-f[1600]
- **SHAKE128 XOF** - `shake128.iii:28` - FIPS 202 SHAKE128 (rate 168, capacity 32, dom-sep 0x1F) variable-output XOF
- **SHAKE256 XOF** - `shake256.iii:26` - FIPS 202 SHAKE256 (rate 136, capacity 64, dom-sep 0x1F) variable-output XOF
- **Keccak-f[1600] permutation** - `keccak.iii:270` - FIPS 202 permutation: 24 rounds, 25-lane state; scalar reference + optional AVX-512 chi step (vpternlogq); bit-reversal indexing
- **Keccak-256 incremental hashing** - `keccak256.iii:48` - Incremental streaming Keccak-256 with block-oriented absorption (W3.10 enhancement); one-shot and streaming init/update/final
- **BLAKE2s hash** - `blake2s.iii:434` - RFC 7693 BLAKE2s: streaming, 10-round compression, variable output (1-32 bytes); scalar/AVX-512/AVX2 dispatch
- **Poly1305 one-time MAC** - `poly1305.iii:86` - RFC 8439 Poly1305 in GF(2^130-5): radix-2^26 (5 limbs), clamped key r, finalized with pad s; scalar/AVX-512 multiply dispatch
- **HMAC-SHA256 and HMAC-SHA512** - `hmac.iii:123` - RFC 2104 HMAC over SHA-256 (64-byte block) and SHA-512 (128-byte block); key normalization and ipad/opad construction
- **HKDF key derivation** - `hkdf.iii:54` - RFC 5869 HKDF: extract(salt, IKM) -> PRK via HMAC-SHA256; expand(info, len) -> OKM with iterative HMAC
- **PBKDF2-SHA256 password derivation** - `pbkdf2.iii:68` - RFC 8018 PBKDF2: derives key from password+salt over configurable iteration count via HMAC-SHA256
- **HMAC-DRBG (SP 800-90A)** - `drbg.iii:133` - NIST SP 800-90A deterministic RNG: instantiate/reseed/generate over HMAC-SHA512; hardware entropy via RDRAND/RDSEED fallback
- **IEEE CRC-32 checksum** - `crc32.iii:64` - Reflected CRC-32 (poly 0xEDB88320); slice-by-8 table optimization (8x256 entries); init 0xFFFFFFFF, XOR-out 0xFFFFFFFF
- **MurmurHash3 32-bit hash** - `murmur3.iii:27` - Non-cryptographic hash (Austin Appleby): 4-byte blocks + tail, finalization via fmix32; suitable for hash tables
- **xoshiro256** PRNG** - `xoshiro.iii:52` - Blackman & Vigna 2018 xoshiro256: 256-bit state, period 2^256-1; jump (2^128) and long_jump (2^192) for parallel substreams
- **Entropy spectral monitor (NTT-based)** - `entropy_monitor.iii:131` - Deterministic timing spectral analyzer: 64-sample circular buffer per path, radix-2 NTT over GF(998244353), baseline distance metric, keccak256 witnesses

#### Bigint & Scalar Arithmetic  *(`numera-bigint-arith`, 16 capabilities)*

- **bigint: arbitrary-precision unsigned integer with AVX-512 SIMD multiply** - `STDLIB/iii/numera/bigint.iii:113` - Slot-table arena bigints (64 limbs max, u64 LE limbs) with schoolbook O(n?) multiply dispatching to scalar/AVX-512 hybrid per-limb code; force_path() allows testing.
- **bigint_div: Knuth Algorithm D base-2^32 half-limb long division + Montgomery mod** - `STDLIB/iii/numera/bigint_div.iii:421` - Full division/modulo (Knuth D ~64x faster than bitserial oracle 757); Montgomery modpow for odd modulus (no per-step division); even modulus falls back to schoolbook.
- **bigint_karatsuba: Karatsuba O(n^1.585) multiply with NTT fallback** - `STDLIB/iii/numera/bigint_karatsuba.iii:106` - Recursive Karatsuba threshold 32 limbs; above KARA_NTT_THRESHOLD (2048) routes to bigint_mul_ntt to avoid slot-table exhaustion (D-KARA-1/3); falls back to schoolbook on OOM.
- **scalar: wrapping/saturating/overflow-detecting u32/u64 arithmetic** - `STDLIB/iii/numera/scalar.iii:38` - All combinations of add/sub/mul in wrapping/saturating/overflow modes; min/max/clamp; bitops (popcount/clz/ctz/byteswap/rotl/rotr).
- **scalar_provenance: overflow detection with crystal minting** - `STDLIB/iii/numera/scalar_provenance.iii:118` - Wrappers on scalar overflow predicates; on overflow mint a crystal whose error_code encodes (signedness, op_kind) and site_hash binds (op, a, b) for provenance tracking.
- **fixed: Q32.32 fixed-point unsigned (32 int + 32 frac bits)** - `STDLIB/iii/numera/fixed.iii:19` - Exact integer, truncating fractional arithmetic; add/sub/mul/div with 128-bit intermediate via 64x64 schoolbook split; eq/lt comparisons.
- **fixed_extra: Q16.16, Q24.8, Q48.16 fixed-point variants** - `STDLIB/iii/numera/fixed_extra.iii:36` - Three monomorphic unsigned widths (each saturation-bounded at format max); fx16/fx24/fx48 arithmetic (add/sub/mul/div) with pre-shift guards to prevent overflow-before-check.
- **q128: unsigned 128-bit integer (hi/lo pair slot table, 64 slots)** - `STDLIB/iii/numera/q128.iii:47` - Q128 value container (two u64 limbs); add/sub/mul (mod 2^128), shift_left/right, cmp/eq accessors.
- **q128_to_f64: Q128 to IEEE 754 binary64 with rounding crystal** - `STDLIB/iii/numera/q128_f64.iii:113` - Convert 128-bit unsigned to f64 bits (round-to-nearest, ties-to-even); record rounding direction; optionally mint a crystal encoding direction (0/?1 -> u32 values).
- **bitops: bit manipulation primitives** - `STDLIB/iii/numera/bitops.iii:31` - popcount32/64, clz32/64, ctz32/64, rotl/rotr32/64, log2_floor64, next_pow2_64, reverse32 -- all branchless/verified.
- **bv_ring: polynomial-normal-form bitvector decision for Z/2^64** - `STDLIB/iii/numera/bv_ring.iii:36` - u64-sound proof-carrying decision for {var, const, +, -, *, <<} equality over machine-word ring; conservative (soundness gate for optimizer rewrites).
- **endian: byte-order load/store conversions** - `STDLIB/iii/numera/endian.iii:30` - 6x endian_load/store variants for u16/u32/u64 in LE/BE; 2x bswap functions (32/64); all explicit masking, no intrinsic calls.
- **hex: hexadecimal encoding/decoding** - `STDLIB/iii/numera/hex.iii:19` - Encode n bytes -> 2n lower-case hex chars; decode 2n hex chars (case-insensitive) -> n bytes; error codes for bad char/length.
- **checked: overflow-checked u32/u64 arithmetic (option encoding)** - `STDLIB/iii/numera/checked.iii:24` - u32 checked_*: option_u32 encoding (low bit = some/none, payload shifted). u64 checked_*: slot-table indirection (64 slots) with unwrap_or/drop.
- **checked_crystal: overflow checking with crystal witness** - `STDLIB/iii/numera/checked_crystal.iii:124` - Parallel to checked.iii but on overflow mint a crystal recording the operation and site; includes last_error() diagnostic state.
- **uncertainty: T20 total uncertain arithmetic with provenance DAG** - `STDLIB/iii/numera/uncertainty.iii:59` - Typed gaps (unknown values) with WHY and WHAT causality; total+sound+precise ops (0*gap=0 holds); derive gaps form a DAG walkable to roots; content-addressed.

#### Logic / Proof / Verification  *(`numera-logic-verify`, 25 capabilities)*

- **Boolean satisfiability solving (CDCL)** - `STDLIB/iii/numera/sat.iii:115` - Deterministic conflict-driven clause learning SAT solver with 1UIP, two-watched literals, fixed decision order; no randomness, no restarts.
- **Verified SAT at scale** - `STDLIB/iii/numera/sat_at_scale.iii:147` - Wraps untrusted SAT oracle with independent verification: checks SAT model against all clauses, or re-derives UNSAT refutation; only verifier verdict trusted.
- **Saturating fixed-width arithmetic** - `STDLIB/iii/numera/sat_arith.iii:35` - Deterministic u32/u64 operations that clamp on overflow/underflow; popcount and min/max helpers for resolver activation-score arithmetic.
- **SMT solver (LIA + BV + Nelson-Oppen combination)** - `STDLIB/iii/numera/smt.iii:395` - DPLL(T) with exact-rational simplex for linear integer arithmetic, bit-blasting for fixed-width bitvectors, iterated equality exchange over shared variables.
- **E-graph equality saturation** - `STDLIB/iii/numera/egraph.iii:313` - Bounded congruence-closed e-graph with deterministic saturation, min-cost extraction; Merkle integrity via Keccak sealing and Reed-Solomon self-heal (GF(2^8)).
- **Cross-module congruence closure** - `STDLIB/iii/numera/congruence.iii:41` - Global union-find over 32-byte content-addresses of functions; automatic dedup on identical address, certified merge only with kernel proof; cost-minimal representative per class.
- **Constitutional clause ratification** - `STDLIB/iii/numera/constitution.iii:66` - Ratifies constitutional clauses with LTL formulas, admissibility predicates (11-opcode stack machine), dependencies, and algebraic-time effective epochs; publishes witness fragments.
- **Temporal logic model checking (LTL)** - `STDLIB/iii/numera/temporal_logic.iii:113` - 12-node LTL (ATOM, NOT, AND, OR, IMPL, X, G, F, U, O, H, S) evaluated on witness chains via non-recursive fixpoint table (arena post-order), finite-trace semantics.
- **Proof term verification** - `STDLIB/iii/numera/proof_term.iii:100` - First-class proof-term substrate with 11 inference rules (AXIOM, MODUS_PONENS, GENERALIZATION, INDUCTION_BASE/STEP, SUBSTITUTION, LIBRARY_CITE, REFLEXIVITY, SYMMETRY, TRANSITIVITY, CASE_ANALYSIS); serialized conclusion replay verification.
- **Curry-Howard program-proof correspondence** - `STDLIB/iii/numera/curry_howard.iii:1` - Bidirectional translation between programs and proofs; verify correspondence by re-executing program-proof pair on both sides; emit witness fragments for isomorphic changes.
- **Symbolic regression (exact bounded search)** - `STDLIB/iii/numera/symbolic_regression.iii:50` - Closed-form expression synthesis via exhaustive canonical enumeration over operator/terminal alphabet, evaluated in Q32.32 signed fixed-point; first exact fit wins (no ML, no float, deterministic).
- **Gr?bner basis computation (Buchberger)** - `STDLIB/iii/numera/groebner.iii:1` - Canonical ideal bases over F_p with S-polynomial reduction, multivariate division, Criterion 1 (coprime leading monomials), inter-reduction to unique monic basis.
- **Dependent type checking (CIC kernel)** - `STDLIB/iii/numera/typecheck.iii:145` - Predicative ??? with de Bruijn indices, no substitution via combinators (ccl) or beta-normalization, decidable conversion; rejects U0:U0 (Girard paradox); 84 public operations.
- **Categorical combinators (CCL conversion)** - `STDLIB/iii/numera/ccl.iii:1` - Directed rewrite algebra (composition, pairing, currying, application) realizing ?+?+? reduction without substitution; normal-form comparison for convertibility.
- **Categorical limits (finite categories)** - `STDLIB/iii/numera/category.iii:1` - Finite categories with pullback, pushout, coequalizer; content-addressed composition ensures unique composites; 20 public operations for object/morphism manipulation.
- **Sheaf gluing (finite site model checking)** - `STDLIB/iii/numera/sheaf.iii:1` - Presheaves on open-cover bases with matching-family gluing via equalizer; registration gate prevents vacuous agreement on unregistered overlaps; 13 public operations.
- **Inductive universal lift (natrec certification)** - `STDLIB/iii/numera/induct.iii:23` - Lifts sample property to proven universal over ? via kernel natrec: type-checks base + step; false universals rejected (no well-typed step ? 0).
- **Quine self-verifier (reflection)** - `STDLIB/iii/numera/quine_verifier.iii:1` - Realizes partial self-verification over reflection constraints; guards against self-reference via forbidden-module checks; budgets and capability gates on reflect operations.
- **Reflection governance (proposal queue)** - `STDLIB/iii/numera/reflection_governance.iii:1` - Dequeues reflection proposals, enqueues synthesis/clause suggestions; FIFO bounded by capacity constraint F-RFLC-2 (4096 bytes per proposal).
- **Reflection constraints (self-bounded reflection)** - `STDLIB/iii/numera/reflection_constrained.iii:147` - Bounded self-reflection with forbidden-set enforcement (self, governance, preserver); constructs machine-checked proofs about other modules; AXIOM inference only.
- **Proof-carrying code (PCC gate)** - `STDLIB/iii/numera/proof_carrying.iii:1` - Admits programs only when accompanied by kernel-checked proofs of specification compliance; 13 public operations for proof/program handling and verification.
- **Safety type system** - `STDLIB/iii/numera/safety_type.iii:1` - Type-level safety constraints enforced at admission; 4 public operations for safety classification and checking.
- **Computation graph analysis** - `STDLIB/iii/numera/computation_graph.iii:1` - DAG representation of operation dependencies; 9 public operations for graph construction and traversal used by optimization and cost analysis.
- **Theorem carrier (proof obligations)** - `STDLIB/iii/numera/theorem_carrier.iii:1` - Carries proof obligations through code transformations; 10 public operations ensuring theorems remain proven across compilation/optimization steps.
- **Constitution preserver (invariant maintenance)** - `STDLIB/iii/numera/constitution_preserver.iii:1` - Maintains constitutional invariants during evolution; 8 public operations for invariant checking and enforcement.

#### Silicon / HDL / zk-STARK / Charters  *(`numera-silicon-zk-misc`, 31 capabilities)*

- **AEU (Axiom Enforcement Unit) silicon verification** - `aeu.iii:45` - Parallel combinational hardware verifier for III axioms (well-formed hexad, reachability), certified against hdl with exhaustive truth tables
- **HDL gate/netlisting to silicon** - `hdl.iii:73` - Deterministic lowering of boolean/trit combinators to hardware gates with exhaustive equivalence certification (binary 2^n, ternary 3^n truth tables)
- **Cost lattice ordering over 6D microarch vectors** - `cost_lattice.iii:62` - Immutable partial-order lattice on (latency, throughput, regpressure, icache, dcache, energy) with divide-free overflow detection and seeded standard orders
- **Cost calculus (operation costing)** - `cost_calculus.iii:237` - Per-opcode cost vector evaluation with witnessed deduction paths; feeds cost_lattice for optimization
- **Microarchitecture timing simulator** - `microarch_model.iii:262` - Deterministic in-order issue, out-of-order complete pipeline with hazard/port/ROB modeling; bit-identical cross-run
- **SOV ISA descent (proof-carrying optimization)** - `sov_isa.iii:359` - Minimum-cost realization extraction over proven-equal e-class under sound algebraic rules (mul(x,2)==shl(x,1), add(x,0)==x, etc); kernel-disposed
- **Sovereign pipeline (kernel-composed faculties)** - `sov_pipeline.iii:70` - Single execution path through all five kernel faculties (conversion, induction, superposition, proof-carrying optimization, rule admission); each kernel-disposed
- **Synthesis specification (cost-budgeted search)** - `synthesis_spec.iii:214` - Candidate specification with 8D cost-vector budget, verifier module+function reference, content-addressed emit/propose/ratify
- **Combinators (SKI-calculus reduction)** - `combinator.iii:52` - Typed combinatory logic arena (S, K, I, app, lambda, atoms); deterministic reduction to normal form
- **Reversible computation (transaction-like undo)** - `reversible.iii:230` - Slot-based transaction log with undo callbacks, nested checkpoints, and rollback; recovers from failed operations
- **Reversible invoke (undo callback dispatch)** - `rev_invoke.iii:45` - Invokes registered undo functions with captured quad-word arguments to reverse side effects
- **Memo lattice (memoization with chain membership)** - `memo_lattice.iii:216` - Key-based memoization with staleness tracking and revalidation; chain membership proof for witnessed values
- **Merkle tree proof/verification** - `merkle.iii:90` - Merkle root computation, proof generation/verification with leaf size and index packing
- **Content-addressed digest (CAD) suite** - `cad.iii:53` - Keyed domain-separated streaming hash with structured addresses (compute, compose, branch) and constant-time equality
- **Trit (Kleene ternary logic) algebra** - `trit.iii:38` - De Morgan algebra over {-, 0, +} with operations (not, and, or, sum, mul, sub) and weight function (asymmetric risk)
- **Identifier (32-byte CAD-based opaque keys)** - `identifier.iii:27` - Zero/equality/comparison/encoding of structured identifiers (u64, pairs, sequences) with content-addressing
- **Math library (carrier-based mathematical objects)** - `math_library.iii:128` - Admit/cite/refine mathematical carrier types (fields, groups, rings) with curator-capability gating
- **Math library curation (refinement workflow)** - `math_library_curation.iii:128` - Propose/finalize/cancel carrier refinements with capability-gated state machine (pending->ratified->live)
- **Algebraic time (monotone integral clock)** - `algebraic_time.iii:17` - Deterministic time counter with advance, current, comparison, and distance operations; no wall-clock
- **Branch anchor (bisimulation-witnessed merge)** - `branch_anchor.iii:268` - Parallel branch construction/retirement with proposal/verification/commit for content-addressed merges
- **Charter terminal (constitutional gate)** - `charter_terminal.iii:99` - Runs constitutional clauses (each with verify/falsify arms); GREEN if all pass, RED with failing index
- **Tiebreak (deterministic argmin/argmax by identity)** - `tiebreak.iii:51` - Minimum/maximum selection with identity-based tiebreak; comparisons on (u64 value, identifier) pairs
- **ZK field arithmetic (BLS12-381 pairing-friendly)** - `zk_field.iii:409` - Prime field Fp, extension fields Fp2/Fp6/Fp12, G1/G2 curve points, and optimal ate pairing; self-tests only, no algorithmic exports
- **ZK prune (rollup witness pruning)** - `zk_prune.iii:276` - KAT-only; rollup-specific witness compression under STARK constraints
- **ZK SNARK (Groth16 circuit satisfiability)** - `zk_snark.iii:193` - Polynomial commitment and Groth16 proof system; self-tests only
- **ZK STARK (FRI+Merkle + NTT-based STARK)** - `zk_stark.iii:110` - NTT over Fp (p=998244353), LDE, FRI, and STARK MDS matrix; self-tests only
- **Witness spine (fragment chain DAG)** - `witness_spine.iii:134` - Registers/chains proof fragments by producer/operation/pillar; epoch closure with Merkle root and replay verification
- **XII LDIL (Layered Deterministic Intermediate Language)** - `xii_ldil.iii:138` - SSA IR builder over struct-of-arrays with 29 opcodes, blocks, PHI nodes, refinement slots, and deterministic typecheck
- **XII NOP tables (target-specific fill)** - `xii_nop_tables.iii:25` - Per-target NOP encoding fill (x86, ARM64, RISC-V, Cortex-M) with greedy multi-byte packing
- **XII subforms (DSL parsing/lowering)** - `xii_subforms.iii:138` - Domain-specific language form manipulation; parses and lowers structured notations
- **H1 Charter (Sovereign Value boundary admission)** - `h1_charter.iii:78` - Constitutional clause: verifies boundary admits well-formed sovereigns (reachable hexad, in-budget cost); falsifies non-sovereigns

#### XII Term-Rewriting  *(`omnia-xii`, 32 capabilities)*

- **Term algebra and representation** - `xii_term.iii:100+` - 32-byte term nodes (24 kinds: K01-K18 basis, 6 fusion ops F.COMPOSE/FTHEN/WITH/UNDER/IF/LOOP, 6 trit ops) in arena allocation; getters/setters for kind/subform/children/aux/weight
- **Canonicalisation via rewrite** - `xii_canonicalise.iii:122` - xii_canonicalise(t) reduces to normal form using fixed cascade of 40 rules (R001-R040) + 5 trit rules (R041-R045); deterministic normaliser via bottom-up leftmost-innermost strategy
- **Rewrite rule engine** - `xii_rewrite.iii:139+` - 45 match/apply rule pairs (40 algebraic + 5 trit) covering associativity, lifting, identity, partial-evaluation, folds; nous proposer socket for reorderable subset; commute/compose tables for K05_ACT
- **Basis kernel properties** - `xii_basis.iii:84+` - K-cost, hexad, cap-class, mpo-weight lookup per kind; is_origin/is_motion/is_essence/is_fusion_op predicates; per-term accessors
- **Confluence certificate (critical-pair overlap detection)** - `xii_rule_overlap.iii + xii_critpair_enum.iii:38` - 117 critical pairs enumerated structurally; cpe_contains/cpe_kind_at/cpe_si_at/cpe_sj_at/cpe_pos_at accessors; rehash/reprove verification modes
- **Root confluence gate** - `xii_joinability.iii:+` - xjn_gate_root verifies root overlaps all join (deterministic normal form via fixed cascade); 35 subterm non-joins tolerated (unreachable via bottom-up)
- **Termination proof via MPO measure** - `xii_termination.iii:+` - xtm_gate: lexicographic triple (weight, size, mis-nesting) strictly decreases; SN(rewrite) proven by polynomial interpretation
- **Admission predicate (operational)** - `xii_admission.iii:52` - xad_admit: root-confluent AND terminating; xad_root_confluent/xad_terminating gates; xad_decide(rc,sn) junction logic; xad_globally_confluent=0 (honest non-claim)
- **Semantic rule verification (trit fragment)** - `xii_rule_verify.iii:88` - xrv_verify: independent Kleene spec vs live engine (NOT, AND, OR, SUM, MUL); arms 1-19 cover semantics + operational teeth + nested reduction + admission composition
- **Rule pattern descriptors (mig4 Step 1)** - `xii_rule_patterns.iii:+` - Declarative 45-rule LHS patterns (root kind + child-kind constraints); structural over-approximation for critical-pair enumeration; sound faithfulness gate
- **Lowering: composition operator (FCOMPOSE)** - `xii_lower_compose.iii:+` - xlc_compose(a,b): creates FCOMPOSE fusion; tests associativity, identity absorption, null-form collapse (R037)
- **Lowering: selection operator (FIF)** - `xii_lower_decide.iii:+` - xld_if(p,t,e): creates FIF fusion; tests branch-lift (R007), equal-branch fold (R030), branch-merge equivalence
- **Lowering: iteration operator (FLOOP)** - `xii_lower_iterate.iii:+` - xli_loop(body, n): creates FLOOP fusion; tests count-multiply nesting, loop-distribution (R015), count-one elimination
- **Lowering: sequential operator (FTHEN)** - `xii_lower_then.iii:+` - xlt_then(a,b): creates FTHEN fusion; tests composition interop, null-fold, identity on K12_THEN basis
- **Lowering: environment operator (FWITH)** - `xii_lower_with.iii:+` - xlw_with(a,b): creates FWITH fusion; tests pairing, environment-merge, K13_WITH basis neutrality
- **Lowering: scope operator (FUNDER)** - `xii_lower_under.iii:+` - xlu_under(a,b): creates FUNDER fusion; tests nesting, scope-transition, K14_UNDER basis load-bearing
- **Interoperability demo (mig4 Step 9)** - `xii_lower_program.iii:64` - xlp_eval: proves decision-in-sequence, decision-in-iteration, iteration-in-decision, grand mix (loop/decision/compose firing R030+R015)
- **Strategy determinism (H12 consumable)** - `xii_strategy_det.iii:51` - xsd_strategy_is_deterministic: canonicalise two independent copies yield identical NF; cascade priority never load-bearing (root overlaps all join)
- **Conjunction hash table (mig4 pivot)** - `xii_chd.iii:41+` - xii_chd_construct: perfect minimal hash collision-free table; xii_chd_lookup_split, bucket accessors; xii_chd_verify_collision_free certification
- **Circuit feasibility (K/cap/hexad compat)** - `xii_circ.iii:56+` - xii_circ_encode: (target, hw_mask, k_bucket, cap_class, hexad, fusion_budget) -> circuit opaque; 13 predicates (p01-p13) gate feasibility; xii_circ_feasible/xii_circ_count_feasible
- **Horizon field emission** - `xii_horizon.iii:+` - Horizon tables indexed by {target, opcode}; emit K/hexad/cap-aware payloads; reach bitmap tracks productive horizons
- **Horizon reach bitmap** - `xii_horizon_reach.iii:32` - xii_horizon_reach_bit(id): query productive horizon; xii_horizon_reach_productive_count: count live horizons
- **Kernel emission (ISA fragments)** - `xii_kernel_emit.iii:252` - xii_kernel_emit_fragment(kind, target, out): dispatch per-(kernel, ISA-target) 24x7=168 sealed byte-sequences for x86/arm64/riscv/cortex-m; fragment_count=168
- **Curated payloads (root-confluent sets)** - `xii_curated_payloads.iii:61` - xii_curated_payloads_register_all: seal proven rule sets (payload=rule set) grouped by origin; 3 payload families
- **Curated embedded (Cortex-M target)** - `xii_curated_embedded.iii:46` - xii_curated_embedded_register_all: low-memory/low-latency rule subsets for embedded/microcontroller deployment
- **Curated extended (extended algebra)** - `xii_curated_extended.iii:169` - xii_curated_extended_register_all: optional rule extensions (not in core XII); gated by admission, not bundled
- **Curated RISC-V (RISC-V target)** - `xii_curated_riscv.iii:44` - xii_curated_riscv_register_all: RISC-V-optimized rule subsets (fixed-width encoding constraints)
- **K-compose savings table (Delta-K)** - `xii_savings.iii:109` - xii_savings_get(a,b): 24x24 symmetric table of idempotent/pairwise K savings; xii_savings_symmetry_check, xii_savings_positive_check
- **Discharge grades and routes** - `xii_discharge.iii:44` - xdc_grade(k): rule k's grade (0-5); xdc_route_of(k): emission route (standard/special); xdc_proof_of(k): proof reference
- **Fusion verification (cross-domain)** - `xii_fusion_verify.iii:67` - xfv_verify: proves 6-operator interop (FCOMPOSE, FTHEN, FWITH, FUNDER, FIF, FLOOP) collapses under one canonicalisation
- **Confluence certificate (tier-1 architecture)** - `xii_conf_cert.iii:122+` - xcc_rule_mhash: SHA-256(rule bodies); xcc_verify: fast hash path; xcc_reprove: deep re-run path; xcc_reorderable(a,b): confluence gate; xcc_selftest
- **Terminal mig4 gate and seal** - `xii_mig4_seal.iii:169` - xms_run_terminal: folds 13 mig4 stages (xrp/xro/cpe/xjn/xtm/xad/xlc/xld/xli/xlp/xlt/xlw/xlu) into one verdict; xms_seal_digest: deterministic canonical-battery fingerprint

#### Resolver / Crystal / Hexad / Ripple  *(`omnia-resolver-crystal`, 36 capabilities)*

- **resolve() - PRIMARY RESOLUTION PRIMITIVE** - `resolver.iii:502` - Main resolution engine: 11-step winner selection via score, tiebreak, K-composition, binding digest, and witness emission. Phase C.5 hot fast path with memo-based bypass of enumeration/tiebreak (step 3-5,8-10) on cache hit.
- **resolver_score() - PATTERN SCORING** - `resolver.iii:270` - Multi-factor score computation: specialisation bump, hexad alignment (exact +100M, near +50M, far -200M), ring alignment (exact +100M, lower-ok +50M, higher -1000M), guarantee matching, K-depth bonus (capped), arena affinity, compose-intent
- **hexad_adjacent() - HEXAD TOPOLOGY PREDICATE** - `resolver.iii:238` - Tests adjacency in hexad transition graph: Form?Compose, Compose?Origin, Substance?Essence, Essence?Motion, Passage?Compose. Used in resolver_score for hexad mismatch penalties.
- **pr_less_than_cr() - RING ORDERING PREDICATE** - `resolver.iii:252` - Tests pattern ring ? context ring: RM2&lt;RM1&lt;R0&lt;R3. Used in resolver_score to reward matching or allow downward-compatible patterns.
- **tiebreak() - TIE RESOLUTION AUTHORITY** - `resolver.iii:390` - Delegates to sanctus/tiebreak.iii::tb_compare_pair for module-mhash lexicographic comparison when best_score == next_score. Returns 1=first-wins, 2=second-wins, 0=ambiguous-error.
- **resolve_fail() - FAILURE PATH ENVELOPE** - `resolver.iii:422` - Common failure handler for all E_RESOLVE_* errors. Computes domain-separated mhash (TAMPER/AMBIG/KUF/NOMATCH/CAP_DENIED), mints error crystal, appends witness, returns tagged error payload.
- **reflect() - META-OBSERVATION PRIMITIVE** - `resolver.iii:872` - Intent Calculus v1.0 PRIMITIVE_REFLECT (id=18): exposes last resolution state for governance introspection. Scopes: K_COST(0), DEPTH(1), PATTERN_ID(2), CHAIN_BITMAP(3), BEST_SCORE(4).
- **resolver_last_event() - RESOLUTION EVENT EMISSION** - `resolver.iii:902` - Emits 64-byte struct: intent_id, pattern_id, best_score, k_now, dispatch_fp, depth, reserved. Used by observability layers to inspect last winning binding.
- **resolver_fast_path_hits() - DIAGNOSTIC COUNTER** - `resolver.iii:202` - Returns count of hot-path memo hits (Phase C.5 optimization). Unproven exports that fire when pattern_set/intent/ctx_digest match memo entry (skips Steps 3-5,8-10).
- **resolver_memo - FNV-1a CONTENT-ADDRESSED CACHE** - `resolver_memo.iii:99` - 4096-slot O(1) hashed open-addressing cache keyed by FNV-1a64(set_id ^ intent_id*? ^ ctx_digest[0:8]). FIFO eviction. Stores (pattern_id, dispatch_fp, seq). No recompute on hit (witness already audited at cold time).
- **crystal_mint() - ERROR CRYSTAL FORGING** - `crystal.iii:199` - Allocates slot from 256-entry pool, stores (error_code, site_hash, cap_id, cause_seq, k=1.0), computes HMAC-SHA256 over domain//all-fields//per-process-key. Returns id=CRYSTAL_ID_BASE+slot.
- **crystal_verify() - INTEGRITY CHECK** - `crystal.iii:297` - Recomputes MAC from current fields and per-process key, compares constant-time to stored. Returns 1=OK, 0=tampered. Restores saved MAC on mismatch to prevent side-channel observation.
- **crystal_edges_* - CAUSAL GRAPH STORAGE** - `crystal_edges.iii:64` - 4-member edge array per crystal slot. Append-only vector for tracking dependent crystals. Supports init, add, count, at-index, aggregate-k. Lives in separate module to preserve crystal.iii BSS layout.
- **hexad_algebra - ASYMMETRIC TERNARY ALGEBRA** - `hexad_algebra.iii:45` - 6-trit packing/unpacking (base-3 LE into u16 [0..728]). Compose: AND on pillars 0-3, OR on 4-5. Element-wise add/sub/mul/neg/active-neg. iii_hexad_pillar accessor (no @export; internal).
- **hexad_reach - REACHABILITY BITMAP (144 ADMITTED)** - `hexad_reach.iii:78` - 729-bit lazy-initialized reachability predicate. Encodes admission constraints: all-positive reachable except PFS-capsule (324) and BRICK (0). Used by dynamic promotion gate and governance admission checks.
- **hexad_dynamic - CATALYST-GATED RUNTIME PROMOTION** - `hexad_dynamic.iii:69` - Promotes non-admitted hexads to admitted under trinity/ceiling/codegen gates. Refuses already-admitted (returns -4). Mutates hexad_reach bitmap on success. Counts total promotions.
- **hexad_epistemic - CONFIDENCE &amp; QUESTION TRACKING** - `hexad_epistemic.iii:23` - Stores hexad, confidence (ppm 0-1e6), open-question count, domain-tag (32b). Combine: hexad via compose, confidences multiply, questions add, domains OR. Escalates when confidence &lt;50%.
- **hexad_mobius - BIDIRECTIONAL INVOLUTIVE PAIRS** - `hexad_mobius.iii:27` - Forward hexad + inverse (via active-neg). Validates: inverse==active_neg(fwd) and fwd==active_neg(inv). Roundtrip: active band cancels under sum. Floor-ppm admission gate (must be >=floor).
- **hexad_pfs - PLATFORM-FIRMWARE-SECURITY BRICKING** - `hexad_pfs.iii:39` - Maps 6 PFS ops (capsule_update->324, smram_write->243, ..., lfi_inject->512) to packed hexads. Reverse lookup: hexad->op. Human-readable name ("capsule_update", etc.).
- **ripple - CHANGE PROPAGATION PIPELINE** - `ripple.iii:1` - 5-stage witness pipeline: ripple_change_new (describe SOT change) -> ripple_analyze (sid transitive closure) -> ripple_execute (reseal dependents, strict/fast) -> ripple_verify (witness chain healthy) -> ripple_commit (atomically update clo
- **ripple_field - FIELD-LEVEL CHANGE TRACKING** - `ripple_field.iii:1` - Tracks changes to individual record fields and emits fine-grained dependency analysis. Integrates with ripple 5-stage pipeline for granular impact assessment.
- **call_context - L0 IMPLICIT PROVENANCE** - `call_context.iii:155` - 512-entry 96-byte call-context pool. Stores: ctx_id, provenance_root (witness[0:32]), kchain_id, k_at_entry, cap_id, caller_pattern_id, hexad_kind, ring, depth (u16 in high 48 bits), arena_id. Digest via mhash(CCTX_DIG // all-96-bytes).
- **mini_crystal - L1 LIGHTWEIGHT CRYSTALS** - `mini_crystal.iii:133` - 64-entry fast error pool (L1 cache between L0 context and L2 full crystals). Stores 8b hash of (value_addr, parent_pattern_id, kchain_state). Promotes to full crystal on demand.
- **pattern_table - REGISTRY ACCESSOR SUITE** - `pattern_table.iii:72` - 4096-entry registry view: table_get(idx), id, module_mhash_byte[0:32], arity, binding_kind[0:32], predicate_fn, unify_fn, dispatch_fn, activation_base, guarantees_provided/required, hexad_kind, ring, k_value, specialisation_of, effects_mask
- **prespec - COMPOSITION PRE-SPECIALIZATION CACHE** - `prespec.iii:69` - 2048-entry cache for composition_hash -> (dispatch_fp, packed_meta=intent_prim/hexad_bag/k_val, fallback_pid). Register_compositions() populates from cg_r3 partial-evaluator. Lookup O(1) by content-address.
- **codegen_dispatch - DEFAULT PATTERN DISPATCHER** - `codegen_dispatch.iii:14` - cg_dispatch_default: stub returning NOMATCH error. Patterns that fail predicate/unify route through this or custom dispatch wrappers.
- **codegen_patterns - REGISTRY BOOTSTRAP** - `codegen_patterns.iii:71` - codegen_register_all(): initializes all meta-patterns (PRIMITIVE_COMPOSE slot 5) and user patterns from prespec. Runs once at startup, sealed after completion.
- **ai_resolve - TEXT-TO-RESOLUTION BRIDGE** - `ai_resolve.iii:69` - Transcodes plain-text intent to intent struct (class, goal_kind, hexad, guarantees, etc.), invokes resolve() in a fresh context, returns result or error with wrapped payload.
- **resolution_init - META-PATTERN INITIALIZATION** - `resolution_init.iii:1` - Sets up 16 meta-patterns: COMPOSE, REFLECT, and 14 others via pattern_register. Seals registry to prevent late admissions. Called once during boot.
- **resolution_meta_dispatch - META-PATTERN DISPATCHERS** - `resolution_meta_dispatch.iii:15` - meta_dispatch_unreachable: always returns E_RESOLVE_NOMATCH. mp_default_or_fail_dispatch: stub. Address-of-fn exported from separate module to produce proper extern symbols (iiis-0 L-label quirk).
- **resolver_replay - WITNESS CHAIN AUDIT REPLAYER** - `resolver_replay.iii:41` - resolver_replay_check_chain(): 3-layer verification (witness_verify_chain, pattern_registry_is_sealed, sanctus_resolver_replay_check_chain per-entry mhash recompute). Returns 1 on full agreement, 0 on any layer failure.
- **spec_probe - PATTERN COMPATIBILITY TESTER** - `spec_probe.iii:1` - Probes whether a (pattern, intent) pair satisfies predicates, unify constraints, and specialisation conditions. Used by resolution search to filter candidates before scoring.
- **dynamic_record - DYNAMIC RESOLUTION AUDIT LOG** - `dynamic_record.iii:57` - 512-entry log of observed dynamic resolution outcomes (pattern_id, mode flag). Lookup by id, clear on demand, count total. Supports governance feedback loops.
- **dynamic_impact - PERFORMANCE/UX DELTA TRACKING** - `dynamic_impact.iii:49` - Per-pattern perf_bp (baseline points) and ux_bp deltas. Aggregate signed i64 sums (reported as u64 bit-pattern). Split accessors for hi/lo 32-bit reads. Used for policy evaluation.
- **proof_ripple - RIPPLE EVENT WITNESSING** - `proof_ripple.iii:1` - Witnesses each ripple stage transition with cryptographic commitments. Integrates with witness chain for full audit trail of change propagation.
- **proof_ripple_resolution - RESOLUTION BINDING PROOFS** - `proof_ripple_resolution.iii:1` - Emits zero-knowledge-style proofs for resolution outcomes (binding digest, score computation, K-composition success). Feeds ripple witness chain.

#### Transpilers / Containers / Governance  *(`omnia-transform-containers`, 33 capabilities)*

- **Async task runtime with FSM (READY/BLOCKED/COMPLETE/CANCEL)** - `STDLIB/iii/omnia/async.iii:100` - Cooperative async scheduler exposing task-state primitives: spawn, await, select, next_ready; NIH-faithful design with 4-state variant FSM
- **List container (singly-linked, arena-backed)** - `STDLIB/iii/omnia/list.iii:54` - Push/pop front/back, random access O(i), capacity-bounded via arena_alloc8
- **Map container (u32->u32 hash table)** - `STDLIB/iii/omnia/map.iii:282` - Put/get/remove with integrity witness via content-address seal
- **Set container (u64 hashset, slot-table backed)** - `STDLIB/iii/omnia/set.iii:1` - Insert/remove/contains with 32-instance ceiling
- **Vector container (u64 array, arena-allocated)** - `STDLIB/iii/omnia/vec.iii:1` - Push/pop, random access, with capacity scaling
- **Queue container (FIFO, bounded)** - `STDLIB/iii/omnia/queue.iii:1` - Enqueue/dequeue/peek with ring-buffer backing
- **Option<T> monad (Some/None)** - `STDLIB/iii/omnia/option.iii:1` - Unwrap, map, is_some, is_none for u64 payloads
- **Result<T,E> monad (Ok/Err)** - `STDLIB/iii/omnia/result.iii:1` - is_ok, is_err, unwrap_or for discriminated union
- **Either<L,R> sum type** - `STDLIB/iii/omnia/either.iii:1` - Pattern match, is_left, is_right
- **LRU cache eviction** - `STDLIB/iii/omnia/lru.iii:1` - Insert/access/evict with recency tracking
- **Fold/reduce over containers** - `STDLIB/iii/omnia/fold.iii:1` - Left/right folds with accumulator threading
- **Iterator protocol** - `STDLIB/iii/omnia/iter.iii:1` - next/has_next abstraction; stateful iteration
- **Zip container pairing** - `STDLIB/iii/omnia/zip.iii:1` - Parallel traversal of two sequences
- **Priority queue (min-heap)** - `STDLIB/iii/omnia/pq.iii:1` - Insert/extract_min with heapify
- **Governance loop (sealed intent evolution)** - `STDLIB/iii/omnia/governance.iii:155` - Multi-stage proposal->sandbox->prove->vote->seal with 2/3 quorum
- **Sandbox constructor & lifetime** - `STDLIB/iii/omnia/sandbox_ctor.iii:1` - Create isolated execution context with cap/mem quotas
- **Sandbox execution & messaging** - `STDLIB/iii/omnia/sandbox_exec.iii:1` - Run code within quota bounds; cross-sandbox IPC
- **Sandbox quota tracking (append-only memory+CPU)** - `STDLIB/iii/omnia/sandbox_quota.iii:50` - Record alloc/cpu; conservative accounting (no release)
- **Observation log (ring buffer events)** - `STDLIB/iii/omnia/obs_log.iii:46` - 256-slot append-only ring; structured (kind/level/crystal/msg_hash)
- **Observation metric (time-series aggregation)** - `STDLIB/iii/omnia/obs_metric.iii:1` - Histogram/percentile tracking for performance signals
- **Observation trace (execution path recording)** - `STDLIB/iii/omnia/obs_trace.iii:1` - Call stack unwinding; path-ID witness hashing
- **Observatory (meta-observer coordination)** - `STDLIB/iii/omnia/obs_observatory.iii:1` - Multiplexes log/metric/trace subscriptions; [audit K-OBSO-1]
- **JIT fusion (rule-based peephole)** - `STDLIB/iii/omnia/jit_fuse.iii:1` - Runtime rewrite matching + cost reduction; verified by proof_ripple
- **JIT swap (runtime reordering)** - `STDLIB/iii/omnia/jit_swap.iii:1` - Instruction scheduling within proof-driven constraints
- **Hardware offload protocol** - `STDLIB/iii/omnia/hw_offload.iii:1` - Dispatch to accelerators (crypto/FFT/SAT); capability-gated
- **Layered seal (multi-ring compartmentalization)** - `STDLIB/iii/omnia/layered_seal.iii:1` - Per-ring digest stacking; Ring-1 ? Ring-2 ? ... isolation
- **Self-reformatter (AST->source round-trip)** - `STDLIB/iii/omnia/self_reformatter.iii:1` - Pretty-print III with canonical spacing; preserves semantics
- **Sovereign value lattice (T-val metric)** - `STDLIB/iii/omnia/sovval.iii:1` - good/noise/sep counts->value; non-gameable by relabeling
- **Unification with occurs-check (Robinson)** - `STDLIB/iii/omnia/unify.iii:68` - Term/var/const/struct/cap/hexad kinds; UNIFY_MAX_DEPTH=64 [audit unify-1]
- **Transform routing (X->Y format conversions)** - `STDLIB/iii/omnia/transform.iii:62` - 24 transpilers (III?Babel?C99?ASM?PE); pattern-set resolution
- **Prespec registry (composition function pointers)** - `STDLIB/iii/omnia/prespec.iii:117` - Pack/lookup/dispatch 130+ precompiled intent handlers; K-value weighting
- **Babel ingestion bridge (external->III forms)** - `STDLIB/iii/omnia/babel.iii:97` - CBOR/JSON/text parsing; enveloped with mhash; version-gated
- **Babel intent (crystal serialization across module boundaries)** - `STDLIB/iii/omnia/babel_intent.iii:91` - Send/receive intent objects with provenance chains

#### Aether (HTTP / Net / Consensus / Federation)  *(`aether`, 28 capabilities)*

- **TCP connection wrapper** - `tcp.iii:84` - Linear-resource socket wrapper over net_tcp_connect with @linear @crystal modifiers for ripple-execute hot-swap safety.
- **HTTP response parser** - `http_client.iii:629` - RFC 7230 HTTP/1.1 response parser supporting Transfer-Encoding:chunked, Content-Length, and rest-of-buffer framing.
- **IPv4 dotted-quad parser** - `inet.iii:62` - Parse 'a.b.c.d' format to u32 network-order IP with out-of-band error state (INET_LAST_ERROR).
- **TCP send with sovereign boundary** - `net.iii:165` - Capability-gated TCP send marking buf @sovereign_value to allow echo/proxy use cases.
- **TCP recv with sovereign taint** - `net.iii:179` - Capability-gated TCP recv filling buf @sovereign_value @sovereign_out with untrusted external bytes.
- **Capability bootstrap** - `capability.iii:107` - One-shot init of root capability (CAP_ENV_ROOT=1) with all rights including ENV bit (0x8000...).
- **Capability attenuation** - `capability.iii:121` - Create child cap with parent.rights AND mask, enforcing expiry inheritance (child <= parent lifespan).
- **Capability rights verification** - `capability.iii:148` - Verify cap has required rights and check revocation chain (walks parent_id tree).
- **Capability revocation** - `capability.iii:181` - Revoke target cap only if authority dominates it in parent chain (HC-1 discipline).
- **Resource handle allocation** - `handle.iii:62` - Allocate opaque handle slot binding OS fd, capability id, and resource kind (file/socket/pipe/proc).
- **Handle verification** - `handle.iii:107` - Verify handle is open and capability admits required rights in single call.
- **Reflection right query** - `capability.iii:220` - Return canonical reflection right (CAP_RIGHT_AMEND) per RIPPLE-13 unified governance.
- **File open with modes** - `fs.iii:101` - Capability-gated file open: FS_MODE_READ/WRITE/APPEND via Win32 CreateFileA.
- **File read source boundary** - `fs.iii:153` - Read from file handle marking buf @sovereign_value @sovereign_out (untrusted data from disk).
- **File write sink boundary** - `fs.iii:165` - Write to file handle from buf @sovereign_value (sovereign data flowing outward to OS).
- **File seek by offset** - `fs.iii:175` - Seek to offset with whence (SET/CUR/END) via Win32 SetFilePointerEx.
- **HTTP request parser** - `http_server.iii:591` - Symmetric to http_parse_response; parses METHOD TARGET HTTP/1.1 request line and headers.
- **HTTP status line builder** - `http_server.iii:156` - Emit 'HTTP/1.1 NNN reason\r\n' into builder.
- **HTTP header case-insensitive lookup** - `http_server.iii:393` - Find request header by name (case-insensitive) returning index or -1.
- **Request/response body accessors** - `http_client.iii:676` - Retrieve body base and length from parsed HTTP response (handles chunked decode).
- **x25519 sealed channel init** - `sealed_channel.iii:98` - x25519 ECDH + SHA-256 derivation of symmetric key and session_id from peer pubkey and secret.
- **ChaCha20-Poly1305 encryption** - `sealed_channel.iii:150` - Encrypt plaintext to ciphertext+tag in place using derived key and monotonic tx_nonce.
- **Session ID byte query** - `sealed_channel.iii:137` - Diagnostic: read per-channel session_id for peer verification.
- **Cross-tier seal anchoring** - `fed_seal.iii:112` - Append-only chain of closure-root anchors: Host->Cluster->Region->Sovereign->Planetary.
- **QC-gated tier anchor** - `fed_seal.iii:83` - Anchor with HotStuff quorum certificate verification (bounds n_sigs to prevent uint32 wrap).
- **Crystal HTTP header format** - `http.iii:75` - Format X-Crystal-HTTP: <32-byte hex closure_root> response header for substrate verification.
- **Manifest provenance attach** - `manifest.iii` - 144-byte provenance manifest binding artifact hash to witness chain via opid.
- **Babel wire serialization** - `babel_wire.iii:103` - Wire format with seal_id, cap_ref, intent_id, ctx_digest, facet mask, and CRC.

#### Verba (Language / String / Text)  *(`verba`, 30 capabilities)*

- **UTF-8 codec (rune validation, encode/decode)** - `STDLIB/iii/verba/rune.iii:121` - Full UTF-8 single-codepoint encode/decode with surrogate rejection and overlong validation; validates Unicode range and writes codepoint as 4-byte LE.
- **UTF-8 string operations** - `STDLIB/iii/verba/string.iii:31` - Rune count, byte equality, lexicographic comparison, prefix/suffix/contains tests, FNV-1a hashing; naive O(nm) substring search.
- **Glyph V3 format (192-byte canonical encoding)** - `STDLIB/iii/verba/glyph_core.iii:56` - SHA256-sealed integrity format: 4B form_id + 4B len + 152B payload + 32B SHA256; validates on isolation. Family: u8/u32/u64/i64/f64/str/bytes/vec/map/set/enum/record/crystal/witness/proof.
- **Intent Calculus (18-primitive typed intent objects)** - `STDLIB/iii/verba/intent.iii:134` - 192-byte intent slots: goal_kind(u8), partial_args[16](u64), mask/guarantees flags, hexad_kind. Supports FORM/BIND/CONVEY/MEAN/ACT/COMPOSE/SEAL/PROVE/QUERY/GRANT/GOVERN/THEN/WITH/UNDER/IF/LOOP/LIFT/REFLECT.
- **JSON RFC 8259 parser (integer-only, bounded)** - `STDLIB/iii/verba/json.iii:102` - Pure III recursive-descent parser: null/bool/int/string/array/object. Integers only (no float/exp). Strings with \\n\\t\\r\\b\\f\\/ escape. Bounded depth=64, slots=2048, O(n).
- **Regex (Brzozowski derivative, linear)** - `STDLIB/iii/verba/regex.iii:332` - Byte-sequence regex via algebraic derivative reduction: atoms (. or byte), postfix *, infix /. No catastrophic backtracking. Linear in input length.
- **Markup (HTML tokenizer, pure)** - `STDLIB/iii/verba/markup.iii:361` - HTML5 subset tokenizer: raw text (script/style), attributes (quoted/unquoted/valueless), comments. Token stream (kind, off, len) into caller buffer. Bounded, no tree-build.
- **Timing-safe byte comparison** - `STDLIB/iii/verba/timing_safe.iii:18` - Constant-time XOR-accumulation equality check for cryptographic use (MACs, hashes); never early-exits.
- **Base64/Base32 codec** - `STDLIB/iii/verba/base64.iii:22` - Base64 standard + URL-safe variant; Base32 Crockford with I/L/O/U exclusion (ULIDs). Encode to builder, decode with validation.
- **Parser primitives (cursor-based)** - `STDLIB/iii/verba/parse.iii:28` - Low-level byte/decimal/hex/alpha parsing. Packed result (bit 63=success, bits 0..62=new_pos). Supports stateful decimal/literal via module vars.
- **Pattern matching (Intent AST)** - `STDLIB/iii/verba/pattern.iii:1` - Converts Intent into pattern trees for matching. Supports wildcards, typed slots, recursive patterns.
- **Normalisation (ASCII case-folding)** - `STDLIB/iii/verba/normalise_ascii.iii:40` - ASCII lower/upper case conversion, case-insensitive equality and prefix match. Bytes outside A-Z/a-z compare strictly.
- **CSV parser** - `STDLIB/iii/verba/csv.iii:1` - RFC 4180 parser: quoted/unquoted fields, embedded quotes, line/field counts. Audit flags for quote-at-EOF edge case.
- **Path canonicalisation** - `STDLIB/iii/verba/path.iii:1` - Normalise / and \ separators, collapse ., handle .. (kept if it would escape root). Audit flag on relative .. preservation.
- **URI parsing and encoding** - `STDLIB/iii/verba/uri.iii:1` - Split URI into scheme/host/port/path/query/fragment. Percent-encoding for reserved chars.
- **Semantic versioning (SemVer)** - `STDLIB/iii/verba/semver.iii:1` - Parse X.Y.Z(-prerelease)(+metadata). Comparison with pre-release precedence (?11.4). Audit flags on pre-release snapshot and comparison logic.
- **ULID generation and formatting** - `STDLIB/iii/verba/ulid.iii:22` - Generate 128-bit ULID: 48-bit BE timestamp + 80-bit randomness. Format to 26-char Crockford base32.
- **UUID parsing** - `STDLIB/iii/verba/uuid.iii:1` - Parse UUID from canonical and compact formats. Validate hex digits and dash placement.
- **LEB128 varint codec** - `STDLIB/iii/verba/leb128.iii:1` - Little-endian base-128 encode/decode for u32/u64. Single byte per 7 bits; stop on MSB=0.
- **HTML escape/unescape** - `STDLIB/iii/verba/html_escape.iii:1` - Named entity encoding (&lt; &gt; &amp; &quot; &#39;) and numeric entity decoding.
- **String builder (buffer management)** - `STDLIB/iii/verba/builder.iii:1` - Growable buffer for incremental string/bytes construction. Push byte/bytes/rune. Capacity, length, drop.
- **Format functions (decimal, hex, char)** - `STDLIB/iii/verba/format.iii:1` - Format u32/u64 as decimal/hex into builder. Padded u32 output. ASCII char output.
- **Glob pattern matching (shell-style)** - `STDLIB/iii/verba/glob.iii:94` - Star (any-run), question (one-char), [chars] class. Iterative backtracking; no nesting limit.
- **HIP (Intent Calculus natural-language pipeline)** - `STDLIB/iii/verba/hip.iii:29` - 6-stage NL pipeline: lex (nl_lex) -> parse (nl_parse) -> project -> complete -> resonate -> disambiguate. Output: UNIQUE/AMBIGUOUS/NO_MATCH.
- **INI file parser** - `STDLIB/iii/verba/ini.iii:1` - Key=value format. Entry count tracking per section; audit flag on unbounded index overflow.
- **Natural language lexer and parser (nl_lex, nl_parse)** - `STDLIB/iii/verba/nl_lex.iii:1` - Sealed 636-word lexicon (verbs, articles, prepositions). Token types. nl_parse recognises sentence fragments (role-tagged AST).
- **AST Intent (abstract syntax tree for intent)** - `STDLIB/iii/verba/ast_intent.iii:1` - Template-based intent AST: fields, arrays, values. Factory and accessor functions.
- **Intent Form (intent serialisation/codec)** - `STDLIB/iii/verba/intent_form.iii:1` - Encode/decode intent to/from canonical form.
- **Transform Form (intent transformation)** - `STDLIB/iii/verba/transform_form.iii:1` - Rewrite intents under semantic-preserving rules.
- **Pattern Form (pattern matching on intent)** - `STDLIB/iii/verba/pattern_form.iii:1` - Compile patterns for matching intents.

#### Sanctus (Sealing / Security / Trusted-base)  *(`sanctus`, 24 capabilities)*

- **Self-attestation with nonce binding** - `STDLIB/iii/sanctus/attest.iii:40` - SHA-256-based attestation binding witness root, closure mhash, env_cap, and caller nonce; constant-time equality for attestations.
- **Append-only witness chain with cryptographic linking** - `STDLIB/iii/sanctus/witness.iii:121` - Track sealed events with mhash+cap+epoch; chain root verifiable via replay; ripple and resolution witness types.
- **Closure-root storage and verification** - `STDLIB/iii/sanctus/closure.iii:27` - Store and verify stdlib closure root; compute closure+resolver combined mhash for M22 gating.
- **8-gate catalyst for vocabulary promotion** - `STDLIB/iii/sanctus/catalyst.iii:98` - Hypothesis registration + per-gate firing (Static, Dynamic, KChain, Witness, Ripple, DualUse, Conservative, Unique).
- **Intent Calculus v1 irreducibility proof** - `STDLIB/iii/sanctus/irreducibility_proof.iii:202` - 19 primitives proven irreducible via structural + operational distinction; full 324-pair matrix falsifiable.
- **19-primitive metadata calculus** - `STDLIB/iii/sanctus/calculus_v1.iii:157` - Boot-time metadata init: hexad, K-cost, arg_mask, ring_min per primitive; root mhash deterministic across builds.
- **Quality gates Q1..Q7 determinism audit** - `STDLIB/iii/sanctus/quality.iii:280` - 7 quality predicates: corpus pass, determinism, golden-mhash, witness growth, K-floor, seal continuity, resolution determinism.
- **Q7 Resolution Determinism gate with lint** - `STDLIB/iii/sanctus/quality_q7.iii:102` - Forbids f64/f32/rdtsc/rdrand/srand/clock in resolver source; checks replay byte-equal, registry sealed, seal_resolver verified.
- **Resolved event witness replay verification** - `STDLIB/iii/sanctus/resolver_replay.iii:27` - Per-entry mhash non-zero check + chain root byte-stable recomputation (Q7-c specific gate).
- **K-value chain tracking with floor enforcement** - `STDLIB/iii/sanctus/kchain.iii:32` - Fixed-point K composition (x1e9 scale); floor preservation; readmit counter; liveness tracking.
- **Mandate runtime audit (M1, M5, M9, M10, M14, M15, M22)** - `STDLIB/iii/sanctus/mandate.iii:93` - 7 runtime mandate checks: K-chain integrity, code working, cross-file harmony, mhash match, K-floor, resolution determinism.
- **Mandate M22 Resolution Determinism gating** - `STDLIB/iii/sanctus/mandate_m22.iii:26` - M22 green iff Q7 pass + pattern registry sealed + closure absorbs SEAL_RESOLVER.mhash.
- **Vocabulary promotion pipeline (8-gate seal)** - `STDLIB/iii/sanctus/promote.iii:62` - Register hypotheses passing catalyst gates; 64-slot active vocabulary; toggle demote integration.
- **Vocabulary demotion ledger with audit trail** - `STDLIB/iii/sanctus/demote.iii:41` - Record demotions with reason hash + seq number; 256-slot append-only ledger.
- **Substrate genesis vector and distance tracking** - `STDLIB/iii/sanctus/genesis.iii:39` - Store genesis root; track seal-step distance; advance current root deterministically.
- **Domain-separated SHA-256 (mhash) wrapper** - `STDLIB/iii/sanctus/mhash.iii:67` - Thin Crown-suite delegation to cad.iii; streaming API with domain prefix + payload + final.
- **SEAL_RESOLVER coefficient table and domain strings** - `STDLIB/iii/sanctus/seal_resolver.iii:127` - 33 coefficient bytes + 67 pattern slots + 5 domain strings; refreeze corrects 900M/700M typos (ADR-RES-009-A).
- **Software Measured Launch (6-step boot verification)** - `STDLIB/iii/sanctus/xii_sml.iii:46` - Verify manifest mhash, Founders-Anchor Ed25519 sig, and all Lattice cells against audit records.
- **Anti-Tamper Membrane round-robin integrity check** - `STDLIB/iii/sanctus/xii_atm.iii:73` - Tick at 1024-op cadence; sample one Lattice cell round-robin; abort on tamper.
- **PFK-ANCHOR-INVARIANT XII validation (7 sub-checks)** - `STDLIB/iii/sanctus/anchor_xii.iii:131` - Verify no bricking, GOVERN admit, 24 crypto hot-paths, MPHF collision-free, R1 root, 8 CT classes, ?K positive.
- **Anti-drift full suite (manifest + cells + reach6 + confluence + critpairs + MPHF** - `STDLIB/iii/sanctus/xii_antidrift.iii:246` - 8 + 1 checks (+ ?K symmetry): empirical confluence (2 paths per term), structural route-S proof via Newman.
- **Trinity admission ceremony curation (12 ceremonies ?1..?12)** - `STDLIB/iii/sanctus/xii_curate.iii:77` - Issue 114-byte certs (ceremony_id, crystals, timestamp, signature); finalize with W4.2 duplicate rejection.
- **Day-zero XII registration orchestration** - `STDLIB/iii/sanctus/xii_register_all.iii:43` - Single idempotent entry point: horizon init + savings init + rewrite reset + 4 curated-catalog registrations.
- **Coefficient table decode and test falsifier** - `STDLIB/iii/sanctus/seal_resolver.iii:161` - Decode u64 LE from frozen byte array; flip-byte-for-test hook proves seal binds coefficients.

#### Katabasis (Descent Gate)  *(`katabasis`, 14 capabilities)*

- **Ring lattice transition validation** - `ring_lattice.iii:44` - Validates lawful CPU privilege-ring transitions (R3->R0->R-1 lattice); returns legal constructor or NONE for illegal skips/ascents.
- **Gate decision pipeline (5-check)** - `gate.iii:36` - Computes seal/cap/hexad/SID verdicts over a sealed cycle term, short-circuits on first failure (plan 4.2 order).
- **Capability rights verification** - `caps.iii:49` - Gate checks if a capability authorizes a descent cycle's required family right (9 families x distinct rights allocation).
- **Cycle admission decision (hexad layer)** - `cycle_admit.iii:46` - Routes cycle family to admissibility predicate (read-only/positive auto-admit; WRITE_NEG/DESCEND_NEG pass hexad/reachability check).
- **Cycle family taxonomy** - `cycle_family.iii:62` - Classifies 9 descent families (F1-F9) by safety class (READ_ONLY/WRITE_NEG/DESCEND_NEG/POSITIVE/OBSERVE/GOVERNANCE) and SID inverse kind.
- **Cycle term construction & inspection** - `cycle_term.iii:41` - Reads/builds XII term cycles as FUNDER(ACT,GRANT); extracts family/target/action/cap from term kernel (position-independent).
- **Cycle content-address seal (SHA-256)** - `seal.iii:34` - Domain-separated SHA-256 over canonical cycle record (48-byte: family/target-kind/action/target/cap); position-independent integrity check.
- **Gate verdict pipeline (6 steps)** - `gate_verdict.iii:38` - Maps gate step to verdict; short-circuit bitmask decide(); verdict_is_ok() predicate for OK/reject branches.
- **Fully autonomous gate admission** - `admit.iii:28` - Computes all 5 gate checks from term + claimed seal (seal_verify, cap_check, hexad/SID checks); returns verdict without external inputs.
- **VMEXIT taxonomy (6 modeled exits)** - `vmexit.iii:46` - Classifies CPUID/MSR/NPF/VMMCALL/SMI/INVALID as intercepted; unmodeled exits fail-closed; maps to handling discipline & SID inverse kind.
- **AMD-SVM region hexad typing (8 regions)** - `svm_layout.iii:49` - Classifies 256 KB SVM offsets into regions (VMCB/HSAVE/NPT/GUEST/ML_STATE/SHARED/HV_STATE/DIAG); per-offset structural hexad masks critical writes.
- **GPU BAR physical-address typing** - `bar_layout.iii:47` - Classifies physical addresses: BAR0 (MMIO), BAR1 (VRAM), BAR3 (RAMIN) reachable; all else unrepresentable (hexad 324 = BRICK).
- **Bricking impossibility proof (exhaustive)** - `bricking.iii:32` - Exhaustively verifies T1: no action composes with BRICK hexad to stay reachable; T2: SAFE target preserves action admissibility (729-action space).
- **Census crystal (silicon facts vector)** - `census.iii:24` - Idempotent initialization + per-fact drift check of 16 verified hardware facts; content-addressed SHA-256 crystal identity.

#### Forcefield (Ripple Optimizer)  *(`forcefield`, 19 capabilities)*

- **Content-addressed ripple network (publish/resolve/merge)** - `ripple.iii:183` - Deterministic Merkle-DAG with domain-separated SHA256 hashing, dedup via content-addressing, tamper-evidence, and CALM monotone merge (Ax W3.17)
- **Ripple recomputation and propagation** - `ripple.iii:240` - rn_ripple recomputes all computed cells from sources via DAG fixpoint, propagating changes holographically to dependents only (LOCALITY)
- **Graph-level capability metric (value function)** - `ripple_metric.iii:226` - rm_value computes J = offset + good_edges - noise_edges - separation via deterministic structural counts (non-gameable, unriggable, T-val)
- **Per-edge and per-pair predicates for refactoring** - `ripple_metric.iii:93` - rm_is_noise/rm_cut_valid/rm_cut_improves and rm_unifiable/rm_merge_valid/rm_merge_improves encode the hard constraints (good complexity protected, intent preserved)
- **Capability-equality grouping and separation counting** - `ripple_metric.iii:188` - rm_sep O(N) groups via caindex (W3.1), counts unifiable pairs incrementally (C(m,2) per group), replaces old O(N?) scan
- **Value-maximal frontier selection with tiebreak** - `ripple_search.iii:49` - rs_strict_best returns argmax if strictly dominates incumbent (s??s?), else NONE (certified s??M abstention, least-index tiebreak deterministic)
- **Certified-unification decider with intent gate** - `ripple_unify.iii:42` - ru_certify_unify routes through intent gate (rm_unifiable) first, then congruence's faithfulness gate (proof required); no intent-override even on kernel-proven equality
- **Sound closed loop with kernel gate** - `ripple_loop.iii:62` - rl_run O(N) bucketing via caindex; hoisted cg_decide check (if kernel_ok=0, no move admitted); merged separation converges to local optimum
- **Certified noise-cut decider** - `ripple_cut.iii:24` - rc_certify_cut ensures cut is commit_gate-admissible AND capability-preserving (good complexity protected) AND improves (genuine noise)
- **Topological extraction with 4-condition decider** - `ripple_extract.iii:124` - rx_certify_extract permits write IFF C1-C4 hold: capability-conservation (cgr_contains read-only, no intern), MDL boundary, acyclic insertion, H10 anti-thrashing
- **Pure purity audit for rx_export_in_g (RIPPLE-4/A-RX-1)** - `ripple_extract.iii:153` - rx_audit_purity_kat falsifies that cgr_contains is read-only (never interns audited address), history-independent, rejects hallucinated exports even at capacity
- **Signed dynamic-name layer (CRDT register with Ed25519)** - `ripple_dyn.iii:166` - dn_apply enforces key-binding (H(pubkey)==k) and signature-verification (Ed25519), joins updates by LWW (t, value_addr); merge is order-independent + idempotent
- **Unified integrity predicate (?)** - `integrity.iii:31` - phi_check combines commit_gate admission + axiom validity (aeu); phi_nv falsifier ledger proves every dimension rejects bad and admits good (non-vacuous)
- **Bilateral certification for actions and abstentions** - `commit_gate.iii:139` - cg_cert_action (? admits + ?J>0 + proof checks) and cg_cert_abstain (frontier searched + no dominated move) are distinct from unverified verdicts
- **Sound-evolution commit gate (5 dimensions)** - `commit_gate.iii:68` - cg_decide: rule-sound (xii_admission), module-coherent (pleroma H?=0), determinism-sealed (cad), conservative (flag), kernel-sound (sov_pipeline); LOCATED reject codes
- **Sheaf coherence check (pleroma) with holographic root** - `pleroma.iii:40` - pleroma_cohere verifies flat S_deg-connection gluing (?ech 1-cocycle H?=0); any non-gluing edge is located; computes domain-separated root digest
- **Proof-carrying code (PCC) via kernel typecheck** - `pcc_gate.iii:36` - pcc_admit routes proof to tc_check (kernel verdict); if P:S checks, code is guaranteed to satisfy spec under all states; flawed proof -> code destroyed
- **Optimal-invocation selector with cost and validity** - `optinvoke.iii:98` - oi_select min-cost valid candidate (tiebreak by lex-min content-address); oi_selection_kind distinguishes IMPL (same output) from SUITE (different outputs)
- **Domain-separated optinvoke seal (A-OI-2)** - `optinvoke.iii:171` - oi_seal hashes candidate table with fixed domain tag, preventing cross-context second-preimage aliasing with bare mhash

#### Nous (Proposer)  *(`nous`, 28 capabilities)*

- **Cost linearization (total order over partial order lattice)** - `nous_costlin.iii:35` - Declares canonical lexicographic total order over 6-dimensional cost lattice with content-address tiebreak; versioned so choice is auditable.
- **Bounded cost scalar projection for e-graph extraction** - `nous_costlin.iii:76` - Packs 6 cost facets into 60-bit scalar (10 bits each, most-significant-first) for e-graph DP, faithful to lexicographic order for bounded costs.
- **Cost vector comparison** - `nous_costlin.iii:42` - Exact lexicographic comparison of full-width u64 cost tuples; -1/0/1 verdict (precedes/equal/follows).
- **Content-address tiebreaker** - `nous_costlin.iii:58` - Lexicographic comparison of 32-byte content-addresses when cost vectors are equal, producing strict total order.
- **Term feature extraction (kind, depth, size)** - `nous_features.iii:36` - Integer-only feature extraction for context terms: kind (XII type), depth (tree height), size (node count); bounded recursion; xii_term-only (no canonicalise cycle).
- **Faculty sealing (weights as first-class value)** - `nous_value.iii:60` - Content-addresses proposer weights deterministically; versioned to pin policy-ruleset pairing; cost-bound guardrails per-call.
- **Confluence-safe deterministic integer policy** - `nous_policy.iii:103` - Kind-aware BLOCK reorder: trit rules first for trit kinds (25-29), else cascade order R038,R040,R001-R044 (priority preserved by differential gate).
- **Advisory kind-affinity scoring** - `nous_policy.iii:82` - Lexicographic-order-faithful metric favoring trit rules for trit kinds, structural rules for fusions; for future trained reorder (not currently used for ordering).
- **Universal proposer socket (ranked rule dispatch)** - `nous_socket.iii:110` - Pluggable ranker dispatch with 3 modes: cascade (byte-identical), ascending probe (permuted-keystone), policy (phase 3+); cost-gated engagement; kill switch.
- **Cost-gated engagement (proposer avoidance on hot path)** - `nous_socket.iii:68` - Lets fixed cascade run for basis kernels (<=17) and bare trit values; engages proposer only at branch kinds.
- **Search Trichotomy closure** - `nous_search.iii:120` - Classifies any budgeted search into SATURATED/GAP/REFUTED; keystone property enforced: budget-hit is NEVER SATURATED (caught by nous_classify).
- **Sealed budget (deterministic, wall-clock rejected)** - `nous_search.iii:136` - Content-addressed budget tuple (kind, steps, cost_cap); wall-clock rejected at construction; tampering detectable via seal re-verification.
- **Reproducibility keys (split by outcome)** - `nous_search.iii:157` - Canonical key omits nous weights (certified commons survives retrains); GAP key includes weights-addr, budget, tiebreak (version-pinned for replay).
- **E-graph search driver (saturate/extract/classify)** - `nous_search.iii:188` - Drives egraph to saturation within budget; classifies by saturation AND answerability; witnesses GAP outcomes via unc_gap_root.
- **Evaluation-regime closure with gap fallback** - `nous_search.iii:219` - Canonicalises term; on step-cap GAP returns semantically-equal partial reduction (sound to use, never error); flags gapped status.
- **Constitutional amendment (self-falsifying verification)** - `nous_charter.iii:76` - Verify arm checks trichotomy earns its verdicts; falsify arm rejects every escape (budget-hit never certified, wall-clock refused); canary proves gate is real.
- **Confluence completion (Knuth-Bendix-style)** - `nous_completion.iii:66` - Runs all critical pairs under budget; SATURATED only if ALL pairs join; GAP if unchecked pairs remain (partial completion never masquerades as proven).
- **Convergence certificate sealing** - `nous_completion.iii:91` - On completion SATURATED, seals non-zero cad cert binding (n_pairs, budget, verdict) to prevent vacuous identical certs across families.
- **Cumulative certified commons (idempotent deposit, re-verified lookup)** - `nous_commons.iii:131` - CERTIFIED/REFUTED: idempotent by key; GAP: append-only versioned frontiers; lookup re-verifies content certificate (tampered entries refused).
- **Gap resumption (from frontier without restart)** - `nous_commons.iii:168` - Re-runs completion from stored frontier with more budget; on reaching CERTIFIED promotes entry in place (outcome + cert updated).
- **Training harness (sealed weights load, poison wall, gap-rate dial)** - `nous_train.iii:55` - Admits weights only if sealed+content-addressed (unsealed/zero rejected); poison wall admits commons entries only if kernel-checked certified.
- **Gap rate metric (deployment dial)** - `nous_train.iii:84` - GAP fraction in permille; dividend bounded (bit-63 unreachable), u64 divide correct; falls as policy strengthens; correctness invariant across it.
- **Synthesis Tetrachotomy (correctness vs optimality)** - `nous_synth.iii:56` - Splits trichotomy: CANONICAL (correct+optimal), PROVISIONAL (correct, optimality deferred), GAP/REFUTED; soundness floor enforces kernel-checked proofs.
- **Bounded synthesis over hexad universe** - `nous_synth.iii:103` - REAL synthesis over 729 realisable hexad types (M9 safety judge proof-carrying floor); reachable->CANONICAL, bottom->REFUTED, malformed/no-budget->GAP.
- **Federation wall (default-deny for provisional)** - `nous_synth.iii:69` - Only CANONICAL crosses federation boundary; PROVISIONAL requires oracle-pin in gap context; canonical context rejects PROVISIONAL (C-12 default-deny).
- **Behavioral dedup key (normal-form keying)** - `nous_behavioral_key.iii:127` - Content-addresses XII normal form (post-canonicalise) to catch behaviorally-equal terms with syntactic differences (AND(a,b) vs AND(b,a) collapse).
- **Syntactic dedup key (raw term keying)** - `nous_behavioral_key.iii:117` - Content-addresses raw term structure (no canonicalise) for comparison; differs for operand-reordered forms; demonstrates why syntactic keying admits duplicates.
- **Explicit-stack term serialization (canonical encoding)** - `nous_behavioral_key.iii:87` - Bounded preorder walk (no recursion) emits presence/kind/subform/aux per node, pushes all 3 child slots; over-budget returns error, never partial key.

#### Memoria (Memory) + Tempora (Time)  *(`memoria-tempora`, 10 capabilities)*

- **Bump-allocated arena over capability-gated region** - `memoria/arena.iii:25` - Create and manage a linear bump arena with reset/used/remaining tracking; arena_new, arena_drop, arena_reset, arena_alloc with 8/1-byte alignment helpers
- **Region-level heap allocation** - `memoria/region.iii:51` - Allocate bounded regions backed by VirtualAlloc; region_create, region_alloc, region_release with overflow-safe offset calculation and sealing
- **Arena/region safe reset with external clear function** - `memoria/arena_safe.iii:27` - Register external cleanup function per arena/region; arena_reset_safe enforces clear_done flag before reset to prevent stale references
- **Bounds-checked byte spans** - `memoria/span.iii:22` - Load/store/fill/find/copy/compare on u8 spans with out-of-bounds error codes; span_u8_load returns 0x100 sentinel on OOB
- **Parameterized generic element spans** - `memoria/span.iii:110` - Specialize span operations over u16/u32/u64/i8/i16/i32/i64; span__load/store/fill/find with element-wise indexing
- **Deterministic logical instant with sealed verification** - `tempora/instant.iii:115` - Monotonic logical clock via strictly-increasing counter; instant_now_sealed produces verifiable instant with sha256(tick//epoch//cap) seal
- **First-class deadline with late-action routing** - `tempora/deadline.iii:55` - Create deadline from instant or delta; deadline_check/remaining compare against current tick with RETURN_ERR/TRAP/ABORT actions
- **Duration arithmetic with saturation** - `tempora/duration.iii:34` - Convert between nanos/micros/millis/seconds/minutes/hours; add/sub/mul/div with saturation at DUR_MAX on overflow
- **Gregorian calendar round-trip conversion** - `tempora/calendar.iii:38` - Civil-to-unix and unix-to-civil via Howard Hinnant's algorithms; handles leap years, proleptic across i64 range; stores y/m/d/h/m/s in CAL_LAST_*
- **RFC 3339 / ISO 8601 datetime formatting** - `tempora/rfc3339.iii:46` - Format unix_seconds to 20-byte YYYY-MM-DDTHH:MM:SSZ string; parse RFC3339 string back to unix seconds; rejects years > 9999

#### COMPILER/BOOT (Self-hosting compiler)  *(`compiler-boot`, 19 capabilities)*

- **Lexical Analysis & Tokenization** - `lex.iii:420` - Full lex pipeline: create/destroy/next/peek with FNV-1a-64 interning, SHA-256 stream/arena hashing, keyword registration, location tracking, token history, logical positioning.
- **Recursive-Descent LL(1) Parsing** - `parse.iii:100` - Production-based parser state machine with error recovery, breadcrumb LIFO, dedup, witness SHA-256 context, Pratt operator precedence, 512-depth limit.
- **AST Construction & Merkle DAG** - `ast.iii:4` - Four-pool Merkle DAG with open-addressed hash-cons, position side-table, list/string/annotation arenas, resumable walk-state, canonical serializer, diff.
- **Semantic Analysis & Type Checking** - `sema.iii:1932` - Type annotation, hexad (6-trinary) validation, cycle/struct registry, field slot mapping, ring-mask inference, lookup tables.
- **Side-Effect Inverse Derivation (SID)** - `sid.iii:36` - Irreversibility detection, SE kind tracking (MSR/CR/NPT/VMCB/IOMMU/AVIC/MSRPM/IOPM/PKRU/XCR0/CAP/PAGE/DPC/NMI), replay bitmap, call sequencing.
- **Ring-3 Code Generation (x64 Assembly)** - `cg_r3.iii:12` - MS x64 calling convention, function prologue/epilogue, label dedup (4096-entry), 64-entry locals, witness tracking, ring-3-specific wall checks.
- **Ring-0 Code Generation** - `cg_r0.iii:1` - Kernel-mode x64 codegen: CR0 guard, MSR writes, NPT entry management, VMCB field access.
- **RM1/RM2 Ring Modes** - `cg_rm1.iii:1` - Real-mode and V86-mode restricted code generation with segment register management, call-gate access.
- **Hexad Validation & Admission** - `hexad_check.iii:1` - 6-trinary (?/0/+) constraint satisfaction, reach/bricking semantics, composition rules, admitted predicate.
- **Access Control Ledger (ACC)** - `acc.iii:56` - State-indexed admission bits, admit/deny vectors, seal, audit hook placeholder, bitmap SHA-256.
- **Consistency Ceiling** - `ceiling.iii:23` - Membership bitmap for proof-theoretic strength gates, sealed once decision made, prevents self-certification of proof-raising mutations.
- **SHA-256 Hashing (FIPS-180-4)** - `cg_sha.iii:1` - Byte-equivalent C reference, cube-root-of-prime constants, 64-round permutation, witness tracking.
- **Module Linking & Symbol Resolution** - `link.iii:1` - Import verification, external symbol resolution, closure checking, link-time witness sealing.
- **Emission to PE/ELF/Raw Binary** - `emit.iii:1` - PE header generation, section layout, relocation, assembly-to-object bridging via MSVC cl.exe/ld.exe, witness JSON serialization.
- **Witness Allocation & Proof Recording** - `witness_alloc.iii:1` - Record-per-proof storage, hashmap dedup, witness sealing, content-addressed certification blocks.
- **JIT Emission & Dynamic Ripple** - `jit_emit.iii:1` - 80 exports covering dynamic function dispatch, lattice stepping, ripple_execute_native stub generation.
- **XII Adapter (Extended Instruction Interface)** - `xii_ldil.iii:1` - Lowering of XII pseudo-opcodes to x64, sema/cg_r3 adapter layer for specialized instructions.
- **Proof-Theoretic Certification** - `proof.iii:1` - Certificate structure, witness trail validation, cone reasoning, refutation evidence.
- **Main Orchestrator & CLI** - `main.iii:1` - Pipeline driver: lex->parse->ast->sema->sid->walloc->cg_<ring>->link->emit->mhash, ring auto-detect, error reporting (text/JSON), deterministic exit codes.


### IV.3 - The anomaly catalog (255 findings, by kind)


#### **Broken / fragile / contradictory** - adjudicated in IV.1; several are false positives (III is separator-free) or documented limits, not failures  *(17)*

- `aes_siv.iii:208` *(numera-symmetric-hash)* - Audit comment [audit E2-SIV-1] notes plaintext buffer materialization overrun risk when pt_len > 65536; siv_s2v uses SIV_TBUF[65536]
- `drbg.iii:108` *(numera-symmetric-hash)* - Audit comment [audit D-DRBG-1] flags drbg_update(data_len) overrun when data_len > 959; DRBG_IN[1024] buffer written at ip[65..65+data_len)
- `drbg.iii:134` *(numera-symmetric-hash)* - Audit comment [audit D-DRBG-1] tracks instantiate buffer constraint: elen+nlen+plen <= 768 into DRBG_SEED[768]
- `STDLIB/iii/numera/bigint.iii:572` *(numera-bigint-arith)* - Condition at line 572 checks cpufeat_has_avx512dq() ONLY if cpufeat_has_avx512f() returns true, but comment says AVX-512DQ is needed for vpmullq. If a host has F but not DQ, the code falls through to scalar (correct outcome), but the code structure does not match the comment's implication. The gate 
- `STDLIB/iii/numera/sat_at_scale.iii:34` *(numera-logic-verify)* - Header comment claims NOT-YET-BUILT but sats_solve (line 616) fully invokes the sat_* API and returns SAT/UNSAT verdicts; certificate generation (refutation re-derivation) is operational; the "NOT-YET-BUILT" note is contradicted by working code (inconsistent documentation state).
- `cost_lattice.iii:33` *(numera-silicon-zk-misc)* - File explicitly documents that iiis-2 miscompiles u64 `/` as signed `idivq`, silently MISSING overflow when 0xFFFF..FE / 0xFFFF..FF returns 2 instead of 0. The divide-free overflow detector (cl_mul_ovf) is a workaround, not a fix. This is a compiler bug, not a code bug, but it makes division-based o
- `xii_mig4_seal.iii:115` *(omnia-xii)* - Line 115 has syntax error/incomplete: '_xms_walk(xii_term_get_child_a(t))  return 0i32' -- missing newline/semicolon between statement and return. Should be '_xms_walk(...) ; return 0i32' or on separate lines. This is a missing control-flow separator that may cause parser issues.
- `STDLIB/iii/omnia/resolver_replay.iii:47` *(omnia-resolver-crystal)* - Layer 3 comment cites removed dead check: "prior `if witness_count() < 0u32` guard, which was DEAD (a u32 is never negative)". Confirms an earlier audit caught but comment is itself now orphaned; the NEW per-entry check is delegated to sanctus/resolver_replay.iii (external). Testability unclear.
- `STDLIB/iii/omnia/prespec.iii:1753` *(omnia-transform-containers)* - extern decl for sha256_oneshot/sha512_oneshot/blake2s_oneshot/sha3_256_oneshot from non-existent module '_unused.iii'; functions are referenced at lines 210,216,222,228 but module does not exist in codebase
- `http.iii:108` *(aether)* - Slot masking uses bitwise AND (& 0xFFu64) instead of modulo; only correct because AETHER_HTTP_RESP_MAX_FOR_CRYSTAL=64 (power of 2). Fragile if max ever increases.
- `STDLIB/iii/verba/regex.iii:352` *(verba)* - rx_derivative can overflow the REGEX_NODES pool and return RX_INVALID_IDX; rx_node_kind then reads OOB. Guard exists but audit flags MATH-1.
- `STDLIB/iii/sanctus/quality_q7.iii:70` *(sanctus)* - Missing semicolon between two statements: 'hit = 0u8  k = patlen' should be 'hit = 0u8; k = patlen'. Syntax error in _q7_contains loop body.
- `STDLIB/iii/sanctus/quality_q7.iii:84` *(sanctus)* - Missing semicolon between two statements: 'g_resolver_lint_violation = 1u8  return 0u8' should be separate. Syntax error in quality_run_resolver_lint early return.
- `nous_completion.iii:49` *(nous)* - [CUT-11 unfixed] NOUS_CMP_TAG was originally 4 bytes (verdict only), causing every cert to be identical regardless of (n_pairs, budget); now 9 bytes binding all three, but the comment flagging the fix signals the unfixed code produced vacuous certs.
- `STDLIB/iii/tempora/deadline.iii:74` *(memoria-tempora)* - deadline_in divides delta_nanos by 1e6 assuming millisecond ticks (line 75), but instant_tick() returns a dimensionless logical monotonic counter, not wall-clock or ms. The comment references GetTickCount64 (wall-clock) but instant module is fully deterministic algebraic time. Arithmetic semantics d
- `cg_r3.iii:418` *(compiler-boot)* - @dynamic ripple-stub asm sequence (4-line stub at line 420-421) emits a 50-byte comment 'III_DYNAMIC_RIPPLE_STUB (lattice Step 0022)' but the ripple_execute_native function that this calls is never defined or exported in cg_r3.iii; it is external. If jit_emit.iii fails to provide this stub at link t
- `iii_cg_pe_iiis1.iii:1` *(compiler-boot)* - 5 exports (iii_cg_pe_classify_intent, iii_cg_pe_name_len, iii_cg_pe_name_byte, etc.) are declared as external references in cg_r3.iii (line 110-112) but iii_cg_pe_iiis1.iii is a stage-1 C reference file, not bootstrapped. If iiis-1 is not linked, cg_r3.iii will fail to emit code for PE narrowing (re

#### **Stub / TODO / stale-spec** - scaffolding or stale comments  *(7)*

- `sha256_dispatch.iii:67` *(numera-symmetric-hash)* - SHA-NI branch (cpufeat_has_sha) is scaffolding: dispatch surface exists but SHA256RNDS2/SHA256MSG1/SHA256MSG2 inline-asm path not yet implemented; all paths route to software
- `STDLIB/iii/numera/sat_at_scale.iii:49` *(numera-logic-verify)* - Comment marks sat.iii as NOT-YET-BUILT dependency but extern declarations (sat_init, sat_add_clause, sat_solve, sat_value, sat_n_conflicts) are fully implemented in sat.iii and invoked by sats_solve; this is stale documentation (Gap/Fix addressed in practice but header not updated).
- `sov_isa.iii:212` *(numera-silicon-zk-misc)* - Comment '* no longer a hand-stubbed all-ones vector. The throughput dimension is converted' refers to historical stub; the stub itself is gone but the note lingers
- `STDLIB/iii/omnia/unify.iii:46` *(omnia-transform-containers)* - UNIFY_MAX_DEPTH raised from 16 to 64 with note 'was 16 -- too shallow; legitimate nested unifications hit the cap' [audit unify-1]; suggests the constant may require further tuning or has known capacity issues
- `inet.iii:31` *(aether)* - INET_PARSE_OFF module variable used as workaround for W2's 4-arg cap limit; prevents reentrant parsing. Comment 'Trap 7' documents this as known limitation but no path to fix.
- `STDLIB/iii/sanctus/anchor_xii.iii:99` *(sanctus)* - anchor_check_r1_root takes manifest_r1 pointer but comment admits 'true verification needs r1_root' and just accepts (returns XA_ACCEPT unconditionally if bytes match). Incomplete validation.
- `lex.iii:173` *(compiler-boot)* - Comment '"DRT-LEX-001: the prior stub OMITTED these three, which mis-numbered every MOD_* below by 3"' indicates this is a stub that corrected a prior implementation error; the lex.iii module codifies the corrected numbering

#### **Candidate dead exports** - `@export` referenced only within their own file (cleanup signal, not bugs)  *(23)*

- `ecdsa_p256.iii:153` *(numera-classical-ecc)* - iii_ecdsa_p256_verify (non-exported) exists; only iii_ecdsa_p256_verify_x is exported (line 181 wrapper). Dead internal fn unless called from non-corpus context.
- `ecdsa_p384.iii:72` *(numera-classical-ecc)* - iii_ecdsa_p384_verify (non-exported) exists; only iii_ecdsa_p384_verify_x is exported (line 98 wrapper). Mirrors p256 but inconsistent visibility.
- `STDLIB/iii/numera/curry_howard.iii:1` *(numera-logic-verify)* - ch_program_to_proof and ch_emit_proof_from_program are exported but never referenced outside curry_howard.iii; used only internally or by KAT, not by any other module in the tree.
- `STDLIB/iii/omnia/resolver.iii:422` *(omnia-resolver-crystal)* - resolve_fail() is @export but never called from outside resolver.iii. Called only internally by resolve() (lines 513-728) on all error paths. No corpus tests invoke it directly; failure testing routes through resolve().
- `STDLIB/iii/omnia/resolver.iii:252` *(omnia-resolver-crystal)* - pr_less_than_cr() is @export but used ONLY in resolver_score() (lines 306, 309) within the same file. Not referenced in corpus, governance, or other omnia modules. Public export unnecessary.
- `STDLIB/iii/omnia/async.iii:319` *(omnia-transform-containers)* - async_select exported; no references in corpus or other stdlib modules (checked async_select grep across entire tree)
- `net.iii:105` *(aether)* - net_set_addr_d (@export) is defined but never called anywhere in codebase or corpus; appears superseded by net_pack_sockaddr_ipv4.
- `STDLIB/iii/verba/base64.iii:36` *(verba)* - base64url_encode: no corpus tests or external references
- `STDLIB/iii/verba/builder.iii:38` *(verba)* - builder_capacity, builder_push_bytes, builder_push_rune: unused in corpus
- `STDLIB/iii/verba/csv.iii:75` *(verba)* - csv_drop: no references
- `STDLIB/iii/verba/format.iii:1` *(verba)* - format_char_ascii, format_decimal_u32_padded, format_decimal_u64, format_hex_u32_upper, format_hex_u64: 6 dead format functions
- `STDLIB/iii/verba/glyph_bytes.iii:31` *(verba)* - glyph_bytes_form_id, glyph_bytes_validate: Glyph V3 form type, no tests
- `STDLIB/iii/verba/glyph_*.iii:1` *(verba)* - All 11 glyph_*_form_id and 11 glyph_*_validate functions (crystal/enum/f64/i64/map/proof/record/recursive/set/str/u32/u64/u8/vec/witness) have zero corpus tests
- `ripple_metric.iii:156` *(forcefield)* - rm_node_key exported but 0 corpus references; externally used per W3.1 comment (ripple_loop/ripple_metric group key writer), so marked as documented but unreferenced in tests
- `ripple_dyn.iii:160` *(forcefield)* - dn_count exported but 0 corpus references; likely symmetric export to dn_init/dn_apply/dn_merge but not tested
- `ripple_extract.iii:73` *(forcefield)* - rx_reaches exported but 0 corpus references; internal helper for C3 acyclic-insertion check, called only by rx_acyclic_insert; no external call sites
- `ripple_unify.iii:55` *(forcefield)* - ru_survivor_cost exported but 0 corpus references; returns cgr_rep_cost (the min-cost surviving representative), declared in header but never called externally
- `nous_charter.iii:151` *(nous)* - nous_ch_verdict exported but never called outside the module; only nous_ch_run_charter uses the internal NOUS_CH_VERDICT buffer.
- `STDLIB/iii/memoria/region.iii:112` *(memoria-tempora)* - region_is_sealed exported but never referenced outside its own file; not used in any corpus test or other module
- `acc.iii:480` *(compiler-boot)* - iii_acc_admit_index, iii_acc_admit_state, iii_acc_admit_vector, iii_acc_admitted, iii_acc_bitmap_fingerprint, iii_acc_bitmap_sha, iii_acc_canonical_bytes, iii_acc_compose_admitted, iii_acc_count_admitted, iii_acc_deny_index, iii_acc_index_to_state, iii_acc_is_admitted_index, iii_acc_is_sealed, iii_a
- `ceiling.iii:254` *(compiler-boot)* - iii_ceil_admitted_kind, iii_ceil_bitmap_mhash, iii_ceil_canonical_bytes, iii_ceil_count_admitted, iii_ceil_deny_kind, iii_ceil_is_sealed, iii_ceil_seal (7 exports): same pattern as acc.iii -- ceiling ledger primitives exported for C harness but not exercised in .iii bootstrap
- `emit.iii:1` *(compiler-boot)* - iii_emit_free_c, iii_emit_get_argv_mhash, iii_emit_get_env_mhash, iii_emit_get_gcc_version_mhash, iii_emit_get_ld_version_mhash, iii_emit_get_output_mhash, iii_emit_get_witness_json, iii_emit_is_sealed, iii_emit_popen_first_line_c, iii_emit_popen_grep_c, iii_emit_putenv_c, iii_emit_read_file_c, iii_
- `ast.iii:1` *(compiler-boot)* - iii_ast_alloc_binder_id, iii_ast_annotation_count, iii_ast_checkpoint, iii_ast_debug_dump, iii_ast_deserialize, iii_ast_deserialize_buf, iii_ast_diff, iii_ast_expr_int_hi, iii_ast_extern_param_at, iii_ast_extern_param_count, iii_ast_get_annotation, iii_ast_get_error_node, iii_ast_get_error_text, and

#### **No dedicated corpus test** - covered transitively, not in isolation  *(49)*

- `ntt.iii:70` *(numera-pqc-ntt)* - ntt_set, ntt_get, ntt_set_b (buffer I/O) have no direct corpus tests; only used internally by NTT consumers
- `ntt.iii:100` *(numera-pqc-ntt)* - ntt_forward_at, ntt_inverse_at (generic DIT/DIF cores) have no direct tests; only called via tabled Cooley-Tukey variants
- `ntt.iii:155` *(numera-pqc-ntt)* - ntt_ct_forward_tabled, ntt_gs_inverse_tabled (FIPS tabled cores) indirectly tested via mlkem/mldsa but not in isolation
- `rsa.iii:222` *(numera-classical-ecc)* - rsa_dbg, rsa_debug_mod1, rsa_debug_sigser, rsa_debug_bigint_rt, rsa_debug_real, rsa_debug_path (12 debug/test exports) - NOT called in corpus 373. Internal instrumentation for keygen audit only.
- `ecdsa_p256.iii:135` *(numera-classical-ecc)* - iii_ecdsa_p256_sig_range_ok, iii_ecdsa_p256_sig_inrange (signature validation helpers) - corpus 208 does NOT call them; verify does internal range check.
- `aes_siv.iii:207` *(numera-symmetric-hash)* - aes_siv_encrypt/decrypt exported but no corpus test found searching for aes_siv_* patterns in STDLIB/corpus/
- `xchacha20_poly1305.iii:41` *(numera-symmetric-hash)* - xchacha20_poly1305_seal/open exported but no corpus test found (xc_setup and xc_ variants in corpus search)
- `STDLIB/iii/numera/q128.iii:135` *(numera-bigint-arith)* - q128_sub (subtraction) exported but tested only via 144_q128_to_f64.iii; no dedicated corpus test for this public operation.
- `STDLIB/iii/numera/q128.iii:175` *(numera-bigint-arith)* - q128_mul (multiplication) exported but has no corpus test (tested only indirectly via conversions).
- `STDLIB/iii/numera/q128.iii:213` *(numera-bigint-arith)* - q128_shr_bits (shift right) exported but not tested in corpus.
- `STDLIB/iii/numera/q128.iii:101` *(numera-bigint-arith)* - q128_cmp (three-way comparison) exported but no dedicated corpus test (only q128_eq tested at 144).
- `STDLIB/iii/numera/bv_ring.iii:125` *(numera-bigint-arith)* - bv_sub (polynomial subtraction) exported but not referenced in any corpus test.
- `STDLIB/iii/numera/bv_ring.iii:145` *(numera-bigint-arith)* - bv_mul (polynomial multiplication) exported but no corpus test.
- `STDLIB/iii/numera/fixed_extra.iii:124` *(numera-bigint-arith)* - fx24_div (Q24.8 division) exported but not tested in corpus; all fx24_* have no test coverage.
- `STDLIB/iii/numera/curry_howard.iii:1` *(numera-logic-verify)* - Public exports (ch_program_to_proof, ch_proof_to_program, ch_verify_correspondence, ch_emit_program_from_proof, ch_emit_proof_from_program) have no references in corpus (719 tests); only ch_proof_to_program appears as extern in proof_term.iii; Curry-Howard infrastructure tested indirectly via proof_
- `STDLIB/iii/numera/groebner.iii:1` *(numera-logic-verify)* - Public operations (gb_init, gb_begin, gb_new_poly, gb_drop_poly, gb_append_term, gb_normalize, gb_lead_exp, gb_lead_coeff, gb_make_monic, gb_reduce, gb_spoly, gb_autoreduce, gb_buchberger) have no direct corpus references (only self-test via gb_selftest in [?638]).
- `xii_nop_tables.iii:131` *(numera-silicon-zk-misc)* - xii_nop_unit_size(target) exported but only corpus/892_xii_nop_tables.iii references it via extern; no direct call site visible in test
- `xii_kernel_emit.iii:252` *(omnia-xii)* - xii_kernel_emit_fragment(kind, target, out) exported at line 252 dispatches 168 kernel-target byte sequences (24 kinds x 7 ISA targets). No corpus test exercises this function or verifies correctness of the emitted fragments vs. their expected semantics. Tests should cover at least one fragment per 
- `xii_kernel_emit.iii:373` *(omnia-xii)* - xii_kernel_emit_fragment_count() at line 373 is a trivial constant return (168). No test verifies this count against the actual dispatch table entries or that it matches 24x7.
- `STDLIB/iii/omnia/resolver.iii:238` *(omnia-resolver-crystal)* - hexad_adjacent() is @export and used by self_reformatter.iii, but has NO direct corpus test. Tested indirectly via resolver_score in corpus 242/233/235/211 but no isolated unit test verifies the 9 adjacency pairs (Form?Compose, etc.).
- `STDLIB/iii/omnia/crystal_edges.iii:64` *(omnia-resolver-crystal)* - crystal_edges_add() is @export with no isolated test. Tested only as side-effect of corpus 105 (modifier_crystal_edges_baseline) which exercises the full integration. No unit test for the 4-member vector append logic.
- `STDLIB/iii/omnia/pq.iii:1` *(omnia-transform-containers)* - Priority queue container: no matching 'pq_' prefix tests found in STDLIB/corpus; heap operations unverified by corpus
- `STDLIB/iii/omnia/hw_offload.iii:1` *(omnia-transform-containers)* - Hardware offload protocol: no matching 'hw_offload_' or 'offload_' tests in corpus; accelerator dispatch unverified
- `STDLIB/iii/omnia/caindex.iii:1` *(omnia-transform-containers)* - caindex module mentioned in scope but no tests for content-addressed indexing found; capability unverified
- `STDLIB/iii/omnia/layered_seal.iii:1` *(omnia-transform-containers)* - Layered seal (multi-ring compartmentalization): no matching 'seal_' or 'layer_' tests in corpus; ring stacking unverified
- `net.iii:69` *(aether)* - net_init (@export) called in only 1 corpus test (387_net_server_loopback.iii); no dedicated validation. Header comments (lines 71-75) document a LATENT BUG: 'the prior lazy auto-init assumption was false...the client path was never corpus-tested so this was latent'.
- `tcp.iii:135` *(aether)* - tcp_is_live (@export) has minimal documentation (''), appears in only corpus/905_tcp.iii; unclear why it exists as diagnostic vs integration with send/recv.
- `STDLIB/iii/verba/transform_form.iii:1` *(verba)* - Intent transformation module: 4 exports, no corpus tests found.
- `STDLIB/iii/verba/intent_form.iii:1` *(verba)* - Intent serialization: 1 export, 14 corpus references suggest partial coverage.
- `STDLIB/iii/verba/normalise.iii:1` *(verba)* - normalise module: 2 exports, 4 corpus references. Unicode normalization deferred; ASCII only in Phase D.
- `STDLIB/iii/verba/leb128.iii:1` *(verba)* - leb128 (varint codec): 3 exports, 1 corpus test. Low coverage.
- `STDLIB/iii/sanctus/closure.iii:102` *(sanctus)* - closure_compute_with_resolver: combines closure root with SEAL_RESOLVER mhash but no dedicated corpus test found (verified via M22 gate tests indirectly).
- `STDLIB/iii/sanctus/demote.iii:41` *(sanctus)* - demote_record and demotion ledger functions tested only indirectly via promote lifecycle; no standalone demote corpus test.
- `STDLIB/iii/sanctus/genesis.iii:91` *(sanctus)* - genesis_clear: explicit reset function exported but no corpus test explicitly exercises it (only init/advance tested).
- `svm_layout.iii:80` *(katabasis)* - katabasis_svm_write_admissible (line 80) exported but appears only in tests 390 (svm_hexad) which tests the function indirectly via katabasis_svm_cycle_admissible; no direct dedicated test.
- `bar_layout.iii:71` *(katabasis)* - katabasis_bar_write_admissible (line 71) exported but only tested indirectly via bar_cycle_admissible in test 394; no standalone test.
- `nous_features.iii:84` *(nous)* - nous_features_selftest is @export but was invoked only internally (corpus/804 calls it from nous_policy test). Integrated at corpus/889_nous_features.iii (mended post-architecture).
- `STDLIB/iii/memoria/span.iii:110` *(memoria-tempora)* - span__load, span__store, span__fill, span__find generic functions have no corpus tests; only u8 variants tested in 04_span_load_store.iii
- `STDLIB/iii/tempora/duration.iii:86` *(memoria-tempora)* - duration_mul_u32 with saturation overflow checking (clever division verification at line 93-94) has no corpus test
- `STDLIB/iii/tempora/duration.iii:98` *(memoria-tempora)* - duration_div_u32 function has no corpus test
- `STDLIB/iii/tempora/instant.iii:135` *(memoria-tempora)* - instant_epoch (returns per-instant process epoch value) is not tested in corpus
- `STDLIB/iii/tempora/instant.iii:141` *(memoria-tempora)* - instant_seal_byte (read individual 16-byte seal with 0x100 OOB sentinel) tested indirectly via instant_verify in 39_instant_now_seal_verify.iii, never independently
- `STDLIB/iii/tempora/instant.iii:188` *(memoria-tempora)* - instant_diff_ticks (compute tick difference between two instants) has no corpus test
- `STDLIB/iii/memoria/region.iii:106` *(memoria-tempora)* - region_base (get base pointer of region) exported, used in corpus 682_arena_determinism.iii but not generally tested
- `STDLIB/iii/memoria/region.iii:112` *(memoria-tempora)* - region_is_sealed (check if region has been sealed) is exported but never called anywhere in codebase
- `STDLIB/iii/memoria/region.iii:140` *(memoria-tempora)* - region_seal (prevent further allocations in region) exported, used in corpus 682_arena_determinism.iii but not generally tested
- `STDLIB/iii/memoria/region.iii:179` *(memoria-tempora)* - region_count_live (count active regions) is tested in 03_region_create_alloc_release.iii but only that one test
- `acc.iii:56` *(compiler-boot)* - No STDLIB/corpus/*.iii test exercises iii_acc_* functions; access-control ledger is tested implicitly via ceiling/hexad tests, not directly
- `ceiling.iii:254` *(compiler-boot)* - No explicit corpus test for iii_ceil_* functions; ceiling is exercised indirectly in pipeline tests but never in isolation

#### **In code, absent from the formal Atlas**  *(63)*

- `mldsa.iii:1041` *(numera-pqc-ntt)* - iii_mldsa_sign uses siglen parameter as output pointer: `let slp : *u8 = siglen as *u8` writes 8 bytes of signature length. Function header at line 892 declares it as input u64, not pointer.
- `slhdsa.iii:665` *(numera-pqc-ntt)* - iii_slhdsa_sign uses siglen parameter as output pointer: `let slp : *u8 = siglen as *u8` writes 8 bytes of signature length. Function header at line 616 declares it as input u64, not pointer.
- `STDLIB/iii/numera` *(numera-pqc-ntt)* - Entire post-quantum subsystem (mlkem, mldsa, slhdsa, pq_dispatch, ntt, ntt_bigint, modular_mont) is absent from DOCS/III-INTERIOR-LOGIC-ATLAS.md. Atlas has zero references to FIPS 203/204/205, ML-KEM, ML-DSA, or SLH-DSA.
- `field_crystal.iii:83` *(numera-classical-ecc)* - fp_inv_with_crystal and fp_inv_failure_crystal_for NOT mentioned in Atlas. Part of Lattice Plan Step 0027 (provenance-bearing wrappers); tested in 7 corpus files but missing from DOCS.
- `sha256.iii:350` *(numera-symmetric-hash)* - sha256_update_byte(b: u32) exported but not mentioned in module docstring (Phase A scope lists only init/update/final one-shot)
- `sha256.iii:366` *(numera-symmetric-hash)* - sha256_finalize_internal() exported without documentation; used as internal hook for cross-module consumers avoiding W3 pointer constraints
- `sha256.iii:399` *(numera-symmetric-hash)* - sha256_digest_byte(i: u32) exported byte-readback helper; undocumented by-index digest access
- `sha512.iii:339` *(numera-symmetric-hash)* - sha512_update_byte(b: u32) exported single-byte streaming input; not in docstring
- `sha512.iii:352` *(numera-symmetric-hash)* - sha512_finalize_internal() exported; internal-use W3 bypass hook, undocumented
- `sha512.iii:417` *(numera-symmetric-hash)* - sha512_digest_byte(i: u32) exported byte-readback; undocumented
- `aes_gcm.iii:340` *(numera-symmetric-hash)* - gcm_force_path(p: u32) exported dispatch override; no docstring (RITCHIE ?3.5 KAT bit-identity testing)
- `chacha20.iii:325` *(numera-symmetric-hash)* - cc20_force_path(p: u32) exported dispatch override; undocumented (0=auto, 1=scalar, 2=avx512, 3=avx2)
- `sha256.iii:188` *(numera-symmetric-hash)* - sha256_sched_force(p: u32) exported dispatch override; undocumented (AVX-512 message-schedule path selection)
- `sha512.iii:213` *(numera-symmetric-hash)* - sha512_sched_force(p: u32) exported dispatch override; undocumented (AVX-512 message-schedule)
- `blake2s.iii:394` *(numera-symmetric-hash)* - b2s_force_path(p: u32) exported dispatch override; no docstring
- `poly1305.iii:238` *(numera-symmetric-hash)* - poly1305_force_path(p: u32) exported dispatch override; undocumented (0=auto, 1=scalar, 2=avx512)
- `keccak.iii:268` *(numera-symmetric-hash)* - keccak_chi_force_path(p: u32) exported dispatch override; undocumented (controls chi step path selection)
- `STDLIB/iii/numera/bigint.iii:571` *(numera-bigint-arith)* - bigint_force_path(p) exported function allows caller to override AVX-512 auto-detection for testing; this capability is NOT documented in the module header -- impacts KAT reproducibility.
- `STDLIB/iii/numera/sat_at_scale.iii:34` *(numera-logic-verify)* - NOT-YET-BUILT dependency on numera::sat (Module 15) declared in header; spec Gap/Fix #1,#6 noted but sat_at_scale is fully built and operational (sats_solve is implemented and working).
- `STDLIB/iii/numera/reflection_constrained.iii:20` *(numera-logic-verify)* - Spec declares proof_term as NOT-YET-BUILT but it is BUILT; actual pt_add_inference differs from spec: takes *u8 packed aggregate (44-byte header + <=512-byte conclusion) not 6 scalars; axiom-construction arm (pt_alloc -> pt_add_inference(AXIOM, pc=0, ...) -> pt_finalize -> pt_verify) is production c
- `cost_lattice.iii:218` *(numera-silicon-zk-misc)* - cl_register_order_q() performs rational (numerator/denominator) weight ordering but is unmentioned in Atlas. Uses CL_Q_TMP scratch and CL_Q_W for integer conversion.
- `sov_isa.iii:82` *(numera-silicon-zk-misc)* - tc_shape_sig() (from typecheck) called at line 82 as 'Integration C: sound conversion pre-filter (WHNF shape signature + Kleene trit)' but not documented in T23/Atlas
- `sov_isa.iii:88` *(numera-silicon-zk-misc)* - xad_decide() (xii_admission rule-admission) integrated but Atlas does not explain its relationship to sov_admit_rule gate disposition
- `xii_admission.iii:74` *(omnia-xii)* - xad_globally_confluent() exported at line 74 returns 0u8 (false) with header comment 'the engine does NOT pretend global confluence -- it has residual subterm non-joins; admission certifies DETERMINISTIC NORMALISATION'. This is a documented capability (non-confluent but deterministic via strategy), 
- `xii_savings.iii:169` *(omnia-xii)* - xii_savings_k_of(kind) exported at line 169 duplicates K-cost lookup already exposed in xii_basis.iii. Header comment says 'Internal: K-cost lookup (avoids extern to xii_basis for module independence during init)' -- this is an implementation detail (to avoid circular init), but exports it as a publ
- `STDLIB/iii/omnia/resolver.iii:211` *(omnia-resolver-crystal)* - _res_ctx_digest_cached() implements Phase C.5 SHA-256 caching (32-byte cache keyed by ctx pointer). Not mentioned in Atlas; critical for &lt;500-cycle hot-path guarantee. Cache invalidation relies on caller never mutating *ctx during resolve().
- `STDLIB/iii/omnia/resolver.iii:540` *(omnia-resolver-crystal)* - Phase C.3 Memoization (lines 541-556): content-addressed key via memo_key(set_id, intent_id, ctx_digest); FIFO eviction on hit skips Steps 3-5,8-10 but STILL computes kchain_compose (K-cost) and dispatch on every invocation. Not documented in Atlas.
- `STDLIB/iii/omnia/resolver.iii:590` *(omnia-resolver-crystal)* - RES_FAST_PATH_HITS counter (line 200, incremented line 590) is a diagnostic-only side-channel. No governance feedback uses it; corpus 242 (bench_resolver) reads it for validation but never gates decisions on it. Purpose unclear beyond debugging.
- `STDLIB/iii/omnia/hexad.iii:42` *(omnia-resolver-crystal)* - iii_hexad_selftest() is a full 6-pillar integration test (algebra, pfs, reach, epistemic, mobius, dynamic) but NOT mentioned in Atlas sections on individual hexad modules. Serves as de facto specification of pillar interaction contracts.
- `STDLIB/iii/omnia/crystal.iii:66` *(omnia-resolver-crystal)* - crystal_init_key() derives MAC sub-key from SHA-256 of fixed domain "III_CRYSTAL_KEY_v0" + zero seed. Comment (line 58-62) notes removal of GetTickCount64 for determinism (M21 invariant) but no Atlas section documents this seeding strategy or its security properties.
- `STDLIB/iii/omnia/call_context.iii:249` *(omnia-resolver-crystal)* - call_context_l0_provenance_hash() (lines 249+) computes 8-byte hash over canonical L0 fields (caller_pattern_id, kchain_id, depth). Used by reflect() to upgrade L0->L1 on demand. Not exposed as @export; function body incomplete in provided range.
- `STDLIB/iii/omnia/crystal.iii:109` *(omnia-transform-containers)* - ID-band collision logic [audit FC-COLLIDE-1] for crystal_id_slot_of; no corresponding Atlas entry or proof that band separation is maintained across mutations
- `STDLIB/iii/omnia/obs_observatory.iii:50` *(omnia-transform-containers)* - Observatory subscription multiplexing [audit K-OBSO-1]; multiplexer design not documented in Atlas or in module header comments
- `sealed_channel.iii:98` *(aether)* - sc_handshake_init implements full x25519+SHA-256 key derivation and session_id derivation, but header (lines 1-24) does not mention the session_id or deterministic replay-rejection via nonce tracking.
- `http_client.iii:412` *(aether)* - http_response_header_find_ci uses explicit u64 masking (line 419) with iiis-0 mitigation comment but no public note on the bug it guards against.
- `STDLIB/iii/verba/rune.iii:19` *(verba)* - rune_is_valid: Atlas does not mention UTF-32 validity check (rejects surrogate range U+D800..U+DFFF). Capability is complete and isolated.
- `STDLIB/iii/verba/string.iii:159` *(verba)* - str_hash_fnv1a: FNV-1a 64-bit string hashing is not mentioned in Atlas. Capability is pure and deterministic.
- `STDLIB/iii/verba/json.iii:1` *(verba)* - Full RFC 8259 JSON parser in pure III (no external libs). Atlas does not describe JSON subsystem at all.
- `STDLIB/iii/verba/markup.iii:361` *(verba)* - HTML5-subset tokenizer (raw text, comments, attributes). Pure, bounded, deterministic. Not mentioned in Atlas.
- `STDLIB/iii/verba/regex.iii:332` *(verba)* - Brzozowski derivative regex engine. Linear-time matching via algebraic reduction. No backtracking. Atlas does not describe.
- `STDLIB/iii/verba/pattern.iii:1` *(verba)* - Intent pattern matching (wildcards, typed slots, recursive patterns). Atlas does not mention.
- `STDLIB/iii/verba/hip.iii:29` *(verba)* - HIP (Human Intent Projection) 6-stage NL pipeline: lex -> parse -> project -> complete -> resonate -> disambiguate. Produces unique/ambiguous/no-match intents. Atlas does not describe.
- `STDLIB/iii/verba/nl_lex.iii:1` *(verba)* - Sealed 636-word lexicon for NL (verbs, nouns, articles, preps, etc). Sealed against intent calculus v1.0. Atlas does not describe.
- `STDLIB/iii/verba/nl_parse.iii:1` *(verba)* - Natural language parser: sentence fragments, role-tagged AST. Imperative/declarative/interrogative kinds. Not in Atlas.
- `STDLIB/iii/verba/ast_intent.iii:1` *(verba)* - Template-based intent AST: field accessors, array operations. Paired with intent.iii. Not in Atlas.
- `STDLIB/iii/sanctus/witness.iii:253` *(sanctus)* - witness_append_ripple: ripple event witness registration with WITNESS_RIPPLE_CAP_BASE (0xFFFFFF00) marker -- not mentioned in Atlas.
- `STDLIB/iii/sanctus/witness.iii:269` *(sanctus)* - witness_append_resolution: resolution witness with intent_id packing in high 32 bits of k_fixed (FROZEN SPEC ?3.2) -- not in Atlas.
- `ripple.iii:208` *(forcefield)* - rn_recompute (internal, non-exported) implements DAG recomputation fixpoint with domain-aware hashing and frame-based categorization (leaf vs node); wrapped by exported rn_ripple but its iteration-count return (<=ncells+1 passes) is undocumented
- `ripple_extract.iii:60` *(forcefield)* - rx_dep_reset exported but header (lines 1-21) mentions only C1-C4 conditions; reset is a graph-building helper for C3 acyclic-insertion (rx_add_dep / rx_reaches)
- `ripple_metric.iii:134` *(forcefield)* - rm_write_key (internal, non-exported) encodes (cap//iclass//zeros) 32-byte key for grouping; single-source for rm_sep and ripple_loop rl_run, but function definition and contract are not in Atlas
- `nous_behavioral_key.iii:1` *(nous)* - nous_behavioral_key.iii is missing from the Atlas table (?6, line 132-147); not listed among the 11 modules though it's a full Phase 5+ capability (dedup key for morphism registries).
- `STDLIB/iii/tempora/instant.iii:115` *(memoria-tempora)* - Module implements T33 algebraic time (deterministic logical counter with sealed verification) per Atlas line 917-923, but instantiation (instant_now_sealed, instant_verify, instant_epoch, instant_seal_byte, instant_diff_ticks, instant_drop) is not cited in Glossary at line 1001 or elsewhere
- `STDLIB/iii/memoria/span.iii:110` *(memoria-tempora)* - Four @specialize generic functions (span__load, span__store, span__fill, span__find) over u16/u32/u64/i8/i16/i32/i64 are real capabilities for bounds-checked element-wise span access but not mentioned in Atlas
- `STDLIB/iii/memoria/arena_safe.iii:27` *(memoria-tempora)* - Module implements external cleanup function registration (arena_register_clear_fn, arena_clear_fn_addr, arena_reset_safe with clear_done assertion) per lattice plan Step 0017, not cited in Atlas
- `STDLIB/iii/memoria/region_safe.iii:22` *(memoria-tempora)* - Companion module to region (lattice plan Step 0018) with region_register_clear_fn, region_clear_fn_addr, region_reset_safe discipline, not cited in Atlas
- `STDLIB/iii/tempora/calendar.iii:38` *(memoria-tempora)* - Implements civil calendar conversions via Howard Hinnant's algorithms (no lookup tables, exact for proleptic Gregorian) supporting T33 algebraic time, but not mentioned in Atlas Glossary
- `STDLIB/iii/tempora/rfc3339.iii:46` *(memoria-tempora)* - RFC 3339 / ISO 8601 formatting and parsing (YYYY-MM-DDTHH:MM:SSZ, 20 bytes) with year-range validation is not cited in Atlas; complements calendar module
- `jit_emit.iii:1` *(compiler-boot)* - 80 exports for JIT emission, lattice stepping, and dynamic ripple execution are present but the Atlas (INTERIOR-LOGIC-ATLAS.md) contains no T-series theory for this facility. Lattice stepping and ripple-execute_native are undocumented architectural features.
- `proof.iii:1` *(compiler-boot)* - 9 exports for proof certification and witness trail validation lack corresponding theoretical framework in Atlas; proof cone reasoning and refutation structure are implicit in the code but not formally specified
- `witness_alloc.iii:1` *(compiler-boot)* - Witness allocation and sealing is described in main.iii pipeline but the formal theory of witness certification (content-addressed blocks, dedup, certificate structure) is missing from Atlas
- `xii_ldil.iii:1` *(compiler-boot)* - Extended Instruction Interface (XII) lowering adapter is undocumented; no Atlas entry for XII pseudo-opcodes or their x64 realization strategy
- `hexad_check.iii:1` *(compiler-boot)* - 20 exports for hexad validation (reach/bricking/composition/admitted checks) are present but the theoretical framework (T19: K3^6 lattice, reach/bricking semantics, monoid properties) is sketched in the Atlas but the constraint-solving algorithm (hexad_compose_packed, hexad_packed_admitted) has no f
- `lex_rt.iii:1` *(compiler-boot)* - 34 exports providing file I/O, memory, and environment wrappers around libc are undocumented; these are the bridge to C runtime but have no entry in the formal model.

#### **More capable than the header/Atlas implies**  *(31)*

- `ntt.iii:1` *(numera-pqc-ntt)* - NTT is far more capable than crypto-only: comment at line 7 notes it serves 'four hand-rolled copies' (mlkem q=3329, mldsa q=8380417, zk_stark + entropy_monitor both q=998244353) via single parameterized core, unifying all NTT-friendly primes
- `pq_dispatch.iii:1` *(numera-pqc-ntt)* - Dispatcher exports both direct multi-arg functions (iii_pq_keygen...) AND composition table wrappers (pq_keygen_c4...) with different ABIs, but header/comments do not explain the dual interface or when to use which
- `crypt_ed25519.iii:191` *(numera-classical-ecc)* - ed25519_keypair_from_seed exported but not documented in header; libsodium-convention 64-byte expanded key (seed//pubkey) - more complete than typical single-pk keygen.
- `aes.iii:269` *(numera-symmetric-hash)* - aes192_set_key(key: *u8) implemented (AES-192: Nk=6, 24-byte key, 12 rounds, 208-byte schedule) but module header claims AES-128 and AES-256 only (no mention of AES-192)
- `aes_gcm.iii:412` *(numera-symmetric-hash)* - aes_gcm_init_256 exported (256-bit key variant) but public API docs only list aes_gcm_init (128-bit); AES-256-GCM capability not advertised
- `entropy_monitor.iii:131` *(numera-symmetric-hash)* - entropy_selftest() provides 25 KAT assertions (M8 cap gate, witness determinism, spectral algebra) but module docstring only lists 8 public functions without selftest mention
- `STDLIB/iii/numera/bigint_div.iii:421` *(numera-bigint-arith)* - bigint_div_qr function comment (W3.9) documents only division; the same module also exports mont_nprime64, mont_mul_bigint, mont_to_form_bigint, mont_from_form_bigint, bigint_modpow_mont -- full Montgomery arithmetic suite not documented in header.
- `STDLIB/iii/numera/bitops.iii:16` *(numera-bigint-arith)* - Header comment omits bitops_log2_floor64 and bitops_next_pow2_64 from the public API list, though both are @export and tested (corpus 999).
- `STDLIB/iii/numera/fixed.iii:1` *(numera-bigint-arith)* - Module comment states 'Phase C addition' for signed Q31.32, but fixed_extra already provides Q16.16, Q24.8, Q48.16 variants -- suggests scoping was revisited without updating this note.
- `STDLIB/iii/numera/egraph.iii:1` *(numera-logic-verify)* - E-graph includes sophisticated Merkle integrity via Keccak sealing (SEAL_DIG, SEAL_BUF) and Reed-Solomon error correction over GF(2^8) (EG_RS_ALPHA, parity generation) for node-symbol stream self-healing, but module header does not document the A2 integration; capability only mentioned in inline com
- `STDLIB/iii/numera/smt.iii:1` *(numera-logic-verify)* - SMT solver implements branch-and-bound search with explicit DFS stack (W15 recursion elimination), canonical tableau transformation, and Bland's anti-cycling rule for exact-rational simplex, but header summary is sparse; no mention of B&B depth=4096, simplex tableau 1280x1600, or Nelson-Oppen fixed-
- `STDLIB/iii/numera/temporal_logic.iii:1` *(numera-logic-verify)* - Temporal logic supports 12 operators but also embeds orchestration of constitutional predicates: tl_eval_atom (lines 200+) invokes cons_eval_predicate to marshal fragment fields into cons_op_view, creating a two-module verification loop; this inter-module feedback is not mentioned in the header.
- `synthesis_spec.iii:214` *(numera-silicon-zk-misc)* - ss_init() + ss_alloc() + ss_canonical_encode() implements FULL specification DAG serialization with domain separation and content-addressing, but module header only describes it as 'cost-budgeted search' without mentioning the canonical form / DAG structure
- `branch_anchor.iii:268` *(numera-silicon-zk-misc)* - ba_init() + ba_construct() + ba_merge_propose() + ba_verify_bisimulation() + ba_merge_commit() implements a full content-addressed bisimulation witness protocol with proposal/verification/commit lifecycle, but module header describes it only as 'branch + merge' without the witness protocol detail
- `memo_lattice.iii:216` *(numera-silicon-zk-misc)* - Supports chain-membership proof generation (ml_admit with chain_id output) and chain equality checking (ml_slot_chain_eq), but module header only describes 'memoization with staleness' without mentioning the chain witness protocol
- `xii_rewrite.iii:57` *(omnia-xii)* - Comment states 'nous proposer socket (Phase 0)' -- the nous_rank, nous_should_engage, nous_active externs (lines 79-81) enable dynamic rule reordering by a statistical proposer, but the Atlas and module header do not document this degree of freedom. Proposer can reorder WITHIN the confluence-certifi
- `xii_rule_patterns.iii:39` *(omnia-xii)* - Header states 'Turns the 49 hand-coded matchers into DATA' but comment at line 71 reveals 'route-S: R001-R004 RETIRED -- associativity is structural at xii_term.make_fusion2, so the 4 associativity rules are gone'. This means the rule set is now 45 (not 49), and associativity is enforced at term con
- `STDLIB/iii/omnia/resolver.iii:502` *(omnia-resolver-crystal)* - resolve() contract ?5.1-11 advertises 11 numbered steps but actually implements 12 logical gates: (0) hot-fast-path, (1) validate, (1b) depth-gate, (2) ctx-digest-cached, (3-5) enumerate/tiebreak (cold), (6-6a) K-compose+capability-gate, (7-10) dispatch+binding-digest+witness, (11) return. Contract 
- `STDLIB/iii/omnia/hexad_reach.iii:102` *(omnia-resolver-crystal)* - iii_hexad_internal_set_bit() and iii_hexad_internal_get_bit() (@export lines 102, 109) are exclusively used by hexad_dynamic for monotone-only reachability mutations. No other caller. Exported as 'internal' hooks but public API surface suggests external use; misleading naming.
- `STDLIB/iii/omnia/crystal.iii:199` *(omnia-resolver-crystal)* - crystal_mint() initializes k_fixed to 1.0 (1000000000u64) but the file comment (line 19) documents it as a per-instance tunable via crystal_set_k(). Atlas describes crystal structure but not the two-phase (mint + set-k) initialization dance required to customize K.
- `STDLIB/iii/omnia/governance.iii:255` *(omnia-transform-containers)* - voter_cap parameter recorded for 'cap-confinement audit' but documented as 'not used yet'; capability checking may be incomplete
- `STDLIB/iii/verba/markup.iii:150` *(verba)* - Missing return statement after MK_OVF=1u8 assignment (line 150: 'MK_OVF=1u8 return 0i32'). Code flow relies on parser error recovery.
- `STDLIB/iii/sanctus/quality_q7.iii:59` *(sanctus)* - _q7_contains substring search is O(n*m) and does mismatch recovery correctly, but comment says '1u8 iff pattern occurs' without noting the performance/safety implications of a full linear scan.
- `bricking.iii:32` *(katabasis)* - katabasis_bricking_count_reachable_to_brick() exhaustively proves the bricking theorem (T1: 0 actions compose with BRICK to reachable) but header comment only says 'the count' -- the mathematical significance (structural impossibility proof) is undersold.
- `ripple_metric.iii:42` *(forcefield)* - Comment states 'module-graph headroom (III ~420 modules)' and 'edge headroom (III ~835 ripples)' but RM_MAXN=4096 and RM_MAXE=16384 are 10x+ larger than actual usage. No explanation of headroom rationale or scaling strategy in header
- `ripple_loop.iii:48` *(forcefield)* - Header says 'monotone + terminating' and cites well-founded measure (separation down -> J up) but does NOT document the W3.1 optimization that reduces O(passes*N?) to O(N) via grouping. Old slow algorithm and correctness proof are unstated
- `nous_costlin.iii:76` *(nous)* - nous_cost_scalar is presented as a bounded projection for e-graph extraction, but its faithful lex-order guarantee (facet0 dominates lower facets even when saturated) is a stronger claim than typical bounded hashing; Atlas calls it a 'proxy' (less precise term).
- `nous_search.iii:188` *(nous)* - nous_search_egraph is documented as an e-graph client (narrowest scope), but is the ONLY implementation of the search regime closure; the generic dispatch nous_search_run admits future SAT/SMT/Groebner clients via kind-tag (design-ahead for M19), underselling the genericity architecture.
- `nous_synth.iii:26` *(nous)* - The comment 'now does REAL bounded synthesis' (line 26) and lines 140-159 perform exhaustive hexad iteration (all 729 types) at SELFTEST time, demonstrating real synthesis correctness; but the Atlas (line 147, M15) calls synthesis a 'design-ahead' suggesting future work, not current reality.
- `STDLIB/iii/tempora/duration.iii:86` *(memoria-tempora)* - duration_mul_u32 performs sophisticated saturation via post-multiplication division verification (line 93-94) to detect overflow without trusting the multiply result, but header comment describes it only generically
- `cg_r3.iii:1` *(compiler-boot)* - The Atlas claims cg_r3 supports only Ring-3 (user-mode) code generation, but cg_r3.iii exports iii_cg_r3_emit_module which is used in main.iii for all ring choices (R3, R0, RM1, RM2) via ring auto-detect. The Atlas should clarify that cg_r3 is the primary emitter for Stage 0 and that R0/RM1/RM2 are 

#### **Other notable** - buffer bounds, compiler-trap workarounds, fragile patterns  *(65)*

- `modular_mont.iii:72` *(numera-pqc-ntt)* - Carryless u64 add pattern in mont_redc: `if low < t { carry = 1u64 }` recovers lost 2^64 bit from wrapping addition. Audit D-MONT-1 comment notes this fixes silent truncation in prior form.
- `ntt_bigint.iii:18` *(numera-pqc-ntt)* - Comment explicitly documents that two NTT primes are 'leaner AND fully exercised' vs three, noting a third prime would be 'dead, untestable path' (k2=0 for realistic sizes). Design choice justified by asymptotic coverage analysis.
- `rsa.iii:376` *(numera-classical-ecc)* - Compiler-trap workaround: bare 1u64<<off (line 376) avoided; instead computed as `bitval = 1u64 << off` in two statements to work around partial-hexad misparse. Documented in DOCS/CRASH-AUDIT.md sec.6.
- `rsa.iii:388` *(numera-classical-ecc)* - Montgomery modexp (rsa_modexp) delegates to fp256/fp384 pattern but sized for RSA-4096 (128 u32 limbs). Proven == bigint_modpow in corpus 373.
- `fp384.iii:72` *(numera-classical-ecc)* - Branch-free borrow encoding (fq_csub_p): conditional subtract masked, NOT conditional-jump. Audited for constant-time posture.
- `fe25519.iii:18` *(numera-classical-ecc)* - All module vars FZ_-prefixed to avoid symbol collision with corpus tests under whole-archive link. Undocumented pattern but documented in inline comment.
- `entropy_monitor.iii:69` *(numera-symmetric-hash)* - Large BSS buffers: ENTROPY_BUF[16384] (256 slots x 64 u64) + ENTROPY_BASELINE[16384] totals 256 KB for spectral buffering; non-reentrant by design (Trap 7)
- `poly1305.iii:70` *(numera-symmetric-hash)* - Pre-computed column vectors POLY_COLS[40] for AVX-512 multiply (W0.7/COMBINE-1 organ); stored for every key set (re-computation per init)
- `crc32.iii:24` *(numera-symmetric-hash)* - Slice-by-8 CRC table [D-CRC-1] consumes 2048 u32 slots (8 KB); trades memory for ~8x throughput improvement via parallel byte processing
- `STDLIB/iii/numera/bigint_div.iii:475` *(numera-bigint-arith)* - Explicit bigint_drop call with audit tag [D-DIV-3] on OOM path in bitserial division -- this is defensive but indicates a history of allocation-tracking bugs in recursive bigint operations.
- `STDLIB/iii/numera/fixed_extra.iii:39` *(numera-bigint-arith)* - Audit tag [D-FX-2] documents a pre-shift overflow guard for fx16_from_int to prevent i<<16 wrap for i>=2^48 -- indicates a past silent-corruption bug caught via testing.
- `STDLIB/iii/numera/fixed_extra.iii:170` *(numera-bigint-arith)* - Audit tag [D-FX-1] documents fx48_mul saturation logic (only saturate when hi >= 2^16, not on partial products). Old code over-saturated ~99.9% of valid operands -- a design correction with documented reasoning.
- `STDLIB/iii/numera/sat_arith.iii:36` *(numera-logic-verify)* - sat_add_u64 delegates to scalar_u64_add_sat (COMBINE-11 comment): "single-pass (was check-then-recompute)"; indicates prior performance trap (double-op-evaluation) that was fixed; refactored externs show careful optimization against iii trap patterns.
- `STDLIB/iii/numera/congruence.iii:83` *(numera-logic-verify)* - cgr_contains (RIPPLE-4 / A-RX-1 audit function): explicitly read-only, does NOT insert, with history-independence guarantee; rejects fresh address even at capacity--a pure membership query designed for audits that must never mutate the interned set.
- `STDLIB/iii/numera/constitution.iii:54` *(numera-logic-verify)* - Constitution module lists mig6 LTL-fold externs (tl_init, tl_alloc_formula, tl_append_atom, tl_append_unary_temp, tl_set_root, tl_holds_on_segment) that form a feedback loop with temporal_logic.iii: constitution predicates ARE LTL atoms evaluated by the model checker.
- `STDLIB/iii/numera/proof_term.iii:17` *(numera-logic-verify)* - Header reconciliation notes (lines 13-26) explicitly document spec vs realization gaps: KAT externs differ (pt_add_inference is single *u8 arg, not 6 scalars), witness path uses aether/witness_hook (not phantom ws_emit_fragment), hoisting per Trap 7, byte-wise LE access (Trap 4/5).
- `STDLIB/iii/numera/typecheck.iii:1` *(numera-logic-verify)* - Type checker implements both Path C (combinator backend via cb_*) and Path C (CCL reducer via ccl_*) for conversion: tc_to_cb/cb_conv and tc_to_ccl/ccl_conv both tested; differential KAT (p5_kat_cbconv) verifies equivalence on computational fragment; dual backends enable fallback/verification.
- `cost_lattice.iii:56` *(numera-silicon-zk-misc)* - Module-scope variable CL_SEED (lines 56-58) is reused across multiple cl_register_order calls during cl_init(). This is a Trap 7 fix (module-scope staging). Unusual pattern but documented and intentional.
- `microarch_model.iii:98` *(numera-silicon-zk-misc)* - UARCH_DOMAIN8 buffer materializes the domain hash constant 0x55415243485F4D31 into LE bytes instead of passing the raw u64. Comment at line 92-97 explains this is required because mhash_domain expects a byte address, not dereferenced integer. Fragile pattern but documented.
- `hdl.iii:38` *(numera-silicon-zk-misc)* - Gate count HG_MAXG = 4096 (line 38) but allocation methods (hdl_add_in, hdl_add) return 0xFFFFFFFFu32 (-1) on overflow. This sentinel is checked in aeu.iii line 59 (if andn == 0xFFFFFFFFu32), making the overflow implicit. Safe but non-standard error handling.
- `xii_ldil.iii:195` *(numera-silicon-zk-misc)* - Block instruction indexing uses formula `((block_u64 & mask) * 256u64) + ((n_u64) & mask)` for 2D array access into LDIL_B_INSTRS (line 195). This assumes max 256 instructions per block (line 82 LDIL_MAX_BLK_INSTRS). Safe due to assertion but unusual zero-overflow pattern.
- `xii_rewrite.iii:135` *(omnia-xii)* - XRW_COMMUTE_TABLE and XRW_COMPOSE_TABLE (lines 135-136) are large 8KiB + 64KiB module-scope mutable tables for K05_ACT commutativity/composition tracking. No documented initialization or sealing mechanism; tables are populated by xii_rewrite_commute_set() (not shown in export list), creating a mutab
- `xii_horizon.iii:1` *(omnia-xii)* - Module imports 'xii_emit_gen', which does not appear in the file list. Either the file is missing from the audit scope or there is a naming mismatch. Horizon payload generation likely depends on emit_gen for ISA-specific lowering, but the relationship is not documented.
- `xii_lower_compose.iii:1` *(omnia-xii)* - Lowering modules (xii_lower_*.iii) export xlc_compose, xld_if, xli_loop, xlt_then, xlw_with, xlu_under but do not export the underlying 'lower' transformation functions themselves (only the lifted/test versions). The actual lowering logic (syntactic program ? XII term) is not directly consumable; it
- `STDLIB/iii/omnia/resolver.iii:6` *(omnia-resolver-crystal)* - Contract specifies "11 numbered steps in resolve(); no step 12; no shortcut path." However, Phase C.5 hot-fast-path (lines 505-509) IS a shortcut that bypasses entire resolve() and returns early. Comment contradicts implementation (either steps renamed post-contract or shortcut added without contrac
- `STDLIB/iii/omnia/resolver_memo.iii:49` *(omnia-resolver-crystal)* - Memo key switched from SHA-256 (~10-25k cycles per memo_key) to FNV-1a 64 (~250 cycles) for Phase C.5 hot-path. Mandate 7 asserts 'still content-addressed by sealed input' but this is technically weaker: FNV-1a lacks cryptographic collision resistance. Trade-off acknowledged but not in Atlas.
- `STDLIB/iii/omnia/mini_crystal.iii:133` *(omnia-resolver-crystal)* - mini_crystal_mint() stores 8-byte hash of (value, parent_pattern_id, kchain_state) but the hash function/implementation is not shown in provided excerpt. Basis for L1->L2 promotion threshold unclear; no documented formula.
- `STDLIB/iii/omnia/ripple.iii:1` *(omnia-resolver-crystal)* - Ripple pipeline mandates 5 stages (change_new -> analyze -> execute -> verify -> commit) and Phase D K-fixed derivation, but no corpus test exercises full 5-stage pipeline. Corpus 838/837 (forcefield_ripple) test only partial stages; full-pipeline determinism untested.
- `STDLIB/iii/omnia/tp_iii_to_asm.iii:114` *(omnia-transform-containers)* - Off-by-one guard 'off + 2u64 > dst_cap' permits off==dst_cap; boundary annotation [audit tp_asm-1] suggests potential fragility in suffix-byte handling at exact capacity
- `STDLIB/iii/omnia/xii_horizon.iii:650` *(omnia-transform-containers)* - _s_m_audit() function: constant name encoding 'M_AUDIT_FOR' suggests audit machinery; presence and purpose not explained in comments
- `fs.iii:175` *(aether)* - fs_seek checks FS_RIGHT_READ permission but performs pointer repositioning (not reading). Semantic mismatch: seeking is neither read nor write but is gated on read permission.
- `net.iii:83` *(aether)* - net_build_sockaddr_ipv4 (internal, no @export) is defined but never called within the module; appears to be dead code or API stub from earlier design.
- `STDLIB/iii/verba/hip.iii:123` *(verba)* - Compiler workaround: iiis-0 bug; address-of-global emits load-value not load-address. Uses byte arrays for all global ptrs (e.g. HIP_TOKEN_COUNT_BUF [u8;4]).
- `STDLIB/iii/verba/hip.iii:143` *(verba)* - Compiler workaround: u32-Pointer Store Width trap. Byte-wise read/write via *u8 to avoid spill into adjacent slots.
- `STDLIB/iii/verba/json.iii:30` *(verba)* - Extensive codegen discipline documented: W1 (u32 mask), W2 (<=4 params), W3 (no &GLOBAL[0]), W4/W9 (no reserved words), W5 (no underscore in hex), W6 (no empty if{}), W7 (split parens), W12 (i32 ==only).
- `STDLIB/iii/verba/csv.iii:1` *(verba)* - audit H-CSV-1/2: Edge case flag for quote-at-end-of-buffer condition.
- `STDLIB/iii/verba/glyph_bytes.iii:32` *(verba)* - audit gv-bytes: Payload length read from untrusted glyph header; source region only 152 bytes. Guard ensures n <= 152.
- `STDLIB/iii/verba/glyph_map.iii:60` *(verba)* - audit gv-map: Payload length from untrusted header; pair region is payload[12..151]=140 bytes.
- `STDLIB/iii/verba/glyph_record.iii:87` *(verba)* - audit gv-rec: Count from untrusted header; field table holds at most GV3_REC_MAX_FIELDS (currently 32).
- `STDLIB/iii/verba/glyph_set.iii:53` *(verba)* - audit gv-set: Payload length from untrusted header; element region 152 bytes.
- `STDLIB/iii/verba/glyph_str.iii:29` *(verba)* - audit gv-str: Payload length from untrusted glyph header; source region 152 bytes.
- `STDLIB/iii/verba/glyph_vec.iii:66` *(verba)* - audit gv-vec: Payload length from untrusted header; element region is buffer[16..160)=144 bytes.
- `STDLIB/iii/verba/ini.iii:104` *(verba)* - audit H-INI-1: Entry index unbounded (ini_index = idx*INI_ENTRY_MAX + i); if i >= INI_ENTRY_MAX, spills into next section's table region. Guard rejects.
- `STDLIB/iii/verba/json.iii:237` *(verba)* - audit H-JSON-1: Integer overflow at i64 boundary. 10*lim+d where lim=2^63-8, d>=8 overflows i64 max (2^63-1). Detect via flag.
- `STDLIB/iii/verba/json.iii:73` *(verba)* - audit H-JSON-2: Depth-indexed scratch arrays: ARRAY_SCRATCH[64*256], OBJECT_SCRATCH[64*512]. Nested depth doesn't clobber parent scope.
- `STDLIB/iii/verba/nl_lex.iii:1` *(verba)* - audit H-NL-1: Lexer sense can be stale if already returned. Edge case in token stream lifecycle.
- `STDLIB/iii/verba/nl_lex.iii:450` *(verba)* - Sealed 636-word lexicon with hash registrations for (verb/noun/article/prep/etc). Example: 'audit' (336 VERB), 'auditor' (619 NOUN).
- `STDLIB/iii/verba/path.iii:1` *(verba)* - audit H-PATH-1: Relative '..' that cannot pop (e.g. leading '../') is KEPT so relative paths survive normalization.
- `STDLIB/iii/verba/semver.iii:1` *(verba)* - audit H-SEMVER-1/2: Pre-release field comparison (dot-by-dot via ?11.4). Snapshot a's pre-release span BEFORE parsing b (which clobbers module state).
- `STDLIB/iii/sanctus/xii_curate.iii:84` *(sanctus)* - W4.2 (ENHANCE-17): ceremony_id duplicate rejection via XII_CURATE_SEEN bitmask (lines 84-85) defends against repeat ceremony issues but shifts burden to caller for correct ceremony_id sequence.
- `STDLIB/iii/sanctus/seal_resolver.iii:46` *(sanctus)* - W5.3 (KEEP-1) REFREEZE: 6 coefficient rows corrected for transcription drift (900M rows byte[1]=0x35 vs 0xE9; 700M row). Seal recomputed; corpus 951 is KAT falsifier.
- `STDLIB/iii/sanctus/irreducibility_proof.iii:202` *(sanctus)* - W4.2 (ENHANCE-17): proof_pair now REJECTS structurally-identical, non-operational pairs (returns PROOF_REDUCIBLE). Previously always returned OK. Requires calculus initialized.
- `STDLIB/iii/sanctus/mandate.iii:49` *(sanctus)* - W4.2 (ENHANCE-17): mandate_check_m1 now explicitly rejects dead/unknown kchain (nonzero id + not-live). Previously dead chains were silently treated as satisfied.
- `census.iii:67` *(katabasis)* - RIPPLE-11/KEEP-2 pre-fix documented: fact_matches(idx >= count) now returns 0 instead of masked-zero spurious match; prevents phantom index from masquerading as in-spec (W5.1 correctness).
- `svm_layout.iii:3` *(katabasis)* - ADR-004 brick defense: WriteMetal cycles to hypervisor-critical SVM offsets (VMCB/HSAVE/NPT/HV_STATE/DIAG) are UNREPRESENTABLE by construction (hexad 324 = structural NEG), not merely guarded.
- `bar_layout.iii:3` *(katabasis)* - FR-7 containment: physical writes proven confined to GPU BARs (BAR0/1/3) by hexad composition, not userspace allowlist alone; any other target is unrepresentable.
- `cycle_term.iii:7` *(katabasis)* - Position-independent seal: cycle content is hashed from canonical fields (family/target-kind/action/target/cap), NOT arena node bytes; structurally-equal cycles seal identically regardless of arena position.
- `ripple_extract.iii:62` *(forcefield)* - Bounds-check audit A-RX-3: rx_add_dep validates a,b < RX_MAXN (1024) before storing in RX_EFROM/RX_ETO; subsequent rx_reaches assumes n<=RX_MAXN and uses RX_VIS/RX_STK[n] indexing. Audit comment explicit but no dynamic bounds-check inside rx_reaches loop
- `ripple_extract.iii:166` *(forcefield)* - rx_audit_purity_kat (purity falsifier for RIPPLE-4/A-RX-1) runs 99 deterministic checks that cgr_contains is read-only and rejects hallucinated exports even at ring capacity; extensively verified but marked as a separate audit harness, not production code
- `commit_gate.iii:96` *(forcefield)* - Audit A-CG-1: cg_seal_ok on NULL/bad content returns nonzero but CG_DIGEST not written; caller must guarantee well-formed content or false-positive sealed can occur. No NULL-check in gate; reliance on caller contract
- `ripple_loop.iii:65` *(forcefield)* - cg_decide(1,1,1,1,kernel_ok) hoisted outside loop (W3.1 optimization); if kernel_ok=0 on entry, loop merges NOTHING (correct by design but non-obvious control flow: kernel fault silences entire refactoring)
- `ripple_metric.iii:138` *(forcefield)* - rm_write_key loop initializes all 32 bytes to 0, then overwrites bytes 0-11 (cap LE + iclass LE); trailing 20 bytes left as padding (inert by caindex hashing spec, deterministic)
- `nous_value.iii:34` *(nous)* - [CUT-10] NOUS_VAL_COST_BOUND=2401 clamped from mislabeled '49*49 selection sort' to '49 linear block-reorder'; comment now correctly identifies the bounded cost as selection over <=49 rules.
- `nous_commons.iii:30` *(nous)* - MAX_ENTRIES=256 global cap; at scale (millions of searches), the frontier can spill to secondary storage; no documented overflow strategy or versioning for multi-process concurrent resume (C-13 mentions versioning but implementation is serial).
- `main.iii:1` *(compiler-boot)* - Orchestrator implements byte-identical SHA-256 (FIPS-180-4) inline rather than calling lex_runtime.c; this duplicates logic already in ceiling.iii. No deduplication of SHA infrastructure across modules -- a maintenance burden if FIPS changes.

### IV.4 — Capability families the original summary never mentioned (the completeness critic's catch)

The fan-out's slices inventoried only ~30% of modules; the **completeness critic** surfaced whole families absent from *both* the original claim *and* the formal Atlas. I verified each exists in code:

1. **Distributed BFT consensus + federation (`aether/`, ~15 files).** `hotstuff.iii` — "deterministic HotStuff BFT" (`hs_init:89`, `hs_set_keypair:129`; Byzantine-safety enforced by an `mhash` vote-block match), with `hotstuff_heal.iii` (self-healing) and `hotstuff_predict.iii` (predictive view-change). A six-file federation layer: `fed_admit` (tiered admission gates), `fed_sybil` (proof-of-work Sybil resistance), `fed_eclipse` (eclipse-attack defense), `fed_tier`, `fed_genesis` (genesis descent), `fed_seal` (seal anchor). KAT-gated by corpus **159–165**. **This is a production distributed-consensus stack the headline summary never claimed.**

2. **Ring-0/-1 on-metal kernel deploy (`KATABASIS-DEPLOY/src/`).** The actual driver: `gate_floor.iii`, `gate_driver.iii`, `gate_resident.iii`, `cpufeat_kernel.iii`, `test_ntimport.iii`, plus hand-asm shims `floor_abi.s`, `kernel_abi.s`, `witness_kernel.s`. This is where the `⟦HIST⟧` "proven on metal, Ring-0" of Part II.13 actually lives — the resident gate that executes in kernel mode. (STDLIB `katabasis/` is the *decision substrate*; this tree is its *deployment*.)

3. **Hardware realization (`R2-GENESIS/silicon/resolver_unit.v`).** A **484-line Verilog RTL** implementation of the `resolver.iii` resolution primitive — a silicon realization of a software organ (marked PRESERVED-ARTIFACT; incomplete — the score reduction picks slot 0 rather than a tournament max-of-8). The III→silicon bridge made physical.

These three are the literal answer to *"huge and somehow missed or forgotten."*

The critic also flagged **capability families with zero isolated corpus tests** (covered only transitively, if at all): `pq.iii` (priority queue), `hw_offload.iii` (hardware-acceleration protocol), `caindex.iii` (content-addressed indexing), `layered_seal.iii` (multi-ring compartmentalization); and **retired code still in the tree**: `xii_critpairs.iii.retired`.

The **single biggest documentation gap** it found: the formal Atlas has **zero** references to post-quantum crypto (FIPS 203/204/205), classical crypto, distributed consensus (HotStuff), the federation tier, or ring-transition/memory-safety semantics — the entire *cryptographic and distributed* half of the system is real-in-code but unmapped-in-theory.

### IV.5 — The honest scale

- **3484 `@export` functions** across `STDLIB/iii`, against **719 corpus tests**: most exports are exercised *transitively* via higher-level KATs, not by a dedicated isolated test. The coverage is deep at the *capability* level, sparse at the *individual-export* level.
- **The no-stub discipline holds**: across the whole tree, only **2 `unimplemented` + 1 `todo`** markers; the 7 "stub-todo" findings are mostly stale comments, not unimplemented code.
- **Module census beyond the 431 audited stdlib modules**: the live, buildable, conformance-gated system is `431` stdlib + `26` BOOT; `KATABASIS-DEPLOY` (~6 kernel modules + asm), `R2-GENESIS` (Verilog), and the CHARIOT trees are real but sit *outside* the `619` corpus.

---

## Part V — Inter-file relational (ripple) emergent capabilities

This part answers the third request: *scout the inter-file relational ripples — the capabilities that emerge from how files compose, that no single file contains.* III is uniquely suited to the question because it carries a **native theory of it**: the **Ripple Calculus** (`DOCS/III-RIPPLE-OPTIMIZER-ARCHITECTURE.md`), which formalizes `C − (A+B) = x` — the capability of a composition *minus* the sum of its parts. Positive `x` is **unification** (emergent capability); negative `x` is **noise/separation**. I extracted the empirical composition graph read-only — **2707 cross-file `extern … from` edges** — and read it through that calculus.

### V.1 — Method (read-only, using the system's own lens)

III's own ripple machinery is `ripple_extract.sh` (the *Topological Extraction Executor* — it physically relocates proven-shared logic into a new organ and gates-or-reverts) and the `sid` dependency-graph corpus (101–103). The executor **mutates** the tree, so for *documentation* I used only the read side: harvest every `extern @abi(...) fn … from "X.iii"` edge → **fan-in** (how many files depend on X = how shared X's capability is) and **fan-out** (how many organs a file fuses = how composite its capability is).

### V.2 — Emergent *organs* (high fan-in: one file whose capability ripples through dozens)

| organ | fan-in | the emergent capability it anchors |
|---|---|---|
| `xii_term` | 157 | the term substrate every rewriting/confluence/lowering file shares |
| `identifier` | 144 | interning/identity — the name-identity fabric under compiler + stdlib |
| `witness_hook` | 133 | the witness/proof-hook organ (gospel-scale BSS) — proof attaches here |
| `glyph_core` | 117 | glyph/encoding core — the text-form substrate |
| `mhash` | 100 | the content-address hash — *the* seal primitive |
| `bigint` | 97 | arbitrary precision under all big-number crypto |
| `cad` | 96 | content-address collapse — identity-by-content |
| `sha256` | 70 | the hash under seals, KDFs, signatures |
| `ast` / `typecheck` | 69 / 57 | the compiler spine every codegen path needs |
| `capability` / `crystal` / `constitution` | 56 / 32 / 22 | the admission / governance fabric |
| `arena` | 52 | the allocation substrate under everything |
| `keccak` / `keccak256` | 36 / 25 | SHA-3/Keccak under PQ + Keccak-256 hashing |
| `trit` | 20 | the ternary-Kleene organ (recently de-duplicated; now shared) |

**The defining emergent organ — the seal/witness chain.** No single file *is* "the seal." It emerges from `cad(96) → mhash(100) → merkle → witness_hook(133)`, hash-backed by `sha256(70)` + `keccak(36)`, and *closed* by the compiler's byte-identity fixed-point (Part II.1). Collectively **300+ consumers** depend on this chain; it is the system's identity-and-integrity capability, owned by no one file — the highest-`x` unification in the tree.

**The shared NTT organ** (`ntt.iii`) is the cleanest measured `x`: one parameterized core serves **four** independent primes — `q=3329` (ML-KEM), `q=8380417` (ML-DSA), `q=998244353` (zk-STARK **and** entropy_monitor). The `numera-pqc-ntt` slice confirmed it replaced four hand-rolled copies: one organ, four consumers, one proof surface — `C − (A+B+C+D) > 0` by construction.

### V.3 — Emergent *composers* (high fan-out: one file fusing many organs into a capability)

| composer | fan-out | the capability it composes from parts |
|---|---|---|
| `prespec` | 256 | the partial-evaluator prototype hub (via the `_unused` link convention) |
| `resolver` | 52 | the resolution pipeline = resolver + memo + replay + crystal + ripple + hexad |
| `typecheck` | 49 | name/type/effect resolution fusing `ast` + `sema` |
| `sov_isa` | 37 | the sovereign ISA fusing cost / lattice / combinator organs |
| `rsa` | 27 | RSA-PSS = `bigint` + Montgomery + `sha256` + PSS-padding |
| `xii_conf_cert` | 25 | a confluence certificate from term + rewrite + overlap + joinability |
| `crypt_ed25519` | 21 | Ed25519 = `fe25519` + `sha512` |

A composer's capability is *literally* emergent: `rsa` is nothing without the four organs it fuses; `crypt_ed25519` **is** the composition `fe25519 ∘ sha512`. "RSA-PSS", "Ed25519", "the resolution engine" from the original summary are all *ripple* capabilities — they live in the edges, not the nodes.

### V.4 — The apex emergent capability: the system measures its own emergence

The most important ripple is **self-referential**. III contains the Ripple Calculus *as a runnable organ* (`omnia/ripple.iii`, `forcefield/*`, `numera/ripple_metric` + `ripple_search`). It computes the very `C − (A+B)` graph above on *itself*, scores each module (noise / load-bearing / duplication) with a **certified-monotone, non-gameable** metric 𝒱 (enhancement G2), finds the argmax extraction target via a real M-search (G3), and — through `ripple_extract.sh` — *acts* on it: relocating shared logic into a new organ and **gating the post-state green or atomically reverting**. Every applied ripple is a theorem (propose freely; the kernel decides). The `trit` de-duplication (Module 2) and the four-copies→one NTT unification are *outputs* of this loop.

Its honest limit (from `III-RIPPLE-OPTIMIZER-ARCHITECTURE.md` §0, verified): "optimal" means **local-optimal under proven-sound moves, over the decidable fragment, with honest abstention everywhere else** — *not* a global optimum (which specializes to undecidable / NP-hard problems). The system can soundly improve its own emergent structure; it cannot claim to have perfected it. That calibrated honesty is itself the defining property carried through this entire document.

### V.5 — The one ripple worth fixing (the fragility the graph exposes)

The `_unused.iii` convention (V.3; `prespec`, 256 edges) is the graph's structural fragility: 256 prototypes declared against a non-existent source-of-record. The edges link green, but there is **no signature source-of-truth** — if a real organ's signature drifts, the `_unused` prototype will not catch it (resolution is by symbol *name* at link, not by *signature*). This is the inter-file analogue of the `mldsa`/`slhdsa` output-parameter ABI gap (IV.1): correct today, untyped against drift. The sound fix is exactly what the Ripple Calculus prescribes — replace the placeholder origin with the real `from "<organ>.iii"`, making each edge load-bearing and signature-checked. (Recommended, not applied — `.iii` edit territory under the read-before-write protocol.)

---

*End of capability verification, atlas & ripple map.*
*Parts I–III — the claim verified and the speedups measured. Part IV — every written capability, file-by-file, with the "broken" bucket adjudicated to **zero real failures** and three whole capability families (BFT consensus, the Ring-0 kernel deploy, the Verilog RTL) recovered from obscurity. Part V — the capabilities that live in the 2707 edges between the files, anchored by the seal chain and the shared NTT organ, and governed by the system's own Ripple Calculus.*
