# III — The Conjecture Faculty + Capability Self-Proof (session evidence)

**Date:** 2026-06-04 · **Active compiler:** `COMPILED/iiis-2.exe` (self-hosted) · **Build:**
`build_stdlib` GATE PASS **464/0**. This records what this campaign built and proved, all by III
alone — every proof a `.iii` program compiled by `iiis-2` (itself written in III) and linked only
against `libiii_native.a` + libc. No rigging; no external harness does III's work.

---

## 1. The Conjecture faculty (`nous/nous_conjecture*`) — the "leap beyond enumeration"

Built on the finding that proposal creates capability only over an **open** space (see §2). Five
genuine conjecture modes, each a propose→**dispose**→admit loop where the disposer is **statistic-blind**
(Atlas Ax D3) — no ML, no observation:

| Module | Mode | Disposer (what makes it sound) | KAT |
|---|---|---|---|
| `nous_conjecture` (incr 1) | ground critical-pair **completion** | conjecture the completing rule; admit iff joinability restored + no cycle (reachability acyclicity — *valid here* because symbols are atomic, no subterms) | `1102`=99 |
| `nous_conjecture` (incr 2) | **iterated** completion (bounded Knuth–Bendix) | iterate until confluent or bound; never a false CONFLUENT | `1103`=99 |
| `nous_conjecture_term` (incr 3) | **structured-term** completion (root + **subterm** critical pairs) | a **reduction order** μ (weight, context-closed): admit iff the whole rule set is μ-decreasing → terminating under subterm rewriting | `1104`=99 |
| `nous_conjecture_gen` (incr 4) | **generalization** | conjecture a universal; verify it **exhaustively** over the bounded domain (decision procedure); refute overgeneralization with a counterexample | `1105`=99 |
| `nous_conjecture_lemma` (incr 5) | **lemma / equation discovery** | a candidate equation is valid iff its sides are **joinable** (congruence closure); discovers non-obvious `a=b` and the congruence lemma `f(a,d)=f(b,d)` | `1106`=99 |

Every KAT is **non-vacuous** (a deliberate assert/logic break reddens with the predicted code) and
the faculty is sound **module-by-module**: ground = atomic-carrier reachability (verified against
code); term = reduction order; gen = exhaustive decision; lemma = read-only joinability + a guarded
`nr_add`. The full conjecture set is gate-green in the corpus (`1102`–`1106` all 99).

## 2. The two impossibility theorems + a caught soundness bug (the deepest results)

- **A learned *reorder* proposer is provably vacuous.** Over the closed, confluent XII rule set,
  reordering is metric-invariant: the reorderable rules are LHS-disjoint, and the gap-rate metric is
  e-graph-governed, not policy-governed. Empirical confirmation: the 3-way `nous` differential gate is
  **GREEN, 53/53**. (`DOCS/III-ORGAN-A-PROPOSER-LEARNING-FINDING.md`.) The authorized "ML proposer"
  optimizes a constant — so conjecture (open-space proposal) was built instead, which *honors* the
  no-statistical-learning rule rather than crossing it.
- **The live XII rule set is already Knuth–Bendix-complete** (`xii_admission` ADMITs it), so real-XII
  completion is vacuous too — hence increment 3 is honestly a standalone demonstration.
- **A real termination-soundness bug was caught by adversarial math-verification and fixed.** The
  increment-3 termination guard first used a reachability cycle-check, which is **unsound under subterm
  rewriting** (a leaf-rule `l→r` induces the edge family `f(l,q)→f(r,q)`, invisible to a leaf-only
  reach): with `f(0,9)→f(1,9)` present, conjecturing `1→0` was wrongly admitted, giving the loop
  `f(0,9)→f(1,9)→f(0,9)`. Fixed with the reduction order μ; the counterexample is locked in as a
  mechanism-isolated regression (KAT 1104 case D + the `nr_add` depth-1 guard, case G). A green test
  over a latent unsoundness — exactly what the adversarial pass exists to catch.

## 3. Capability self-proof (III alone, no rigging)

**Gates (each is III compiling + running its own programs):**
- `build_stdlib` GATE PASS **464/0** (cartographer + Forge closure meta-gates green).
- `run_corpus` **PASS=780, FAIL=0**, SKIP=100 — the stdlib conformance surface.
- `run_xii_corpus` **PASS=92, FAIL=0** — XII rewrite calculus (rewriting, canonicalisation,
  joinability, termination, confluence).
- `run_bench_corpus` **PASS=7, CORRECTNESS-FAIL=0** — Knuth div, Montgomery modpow, fe25519, AEAD/resolver.
- `forge_check` GREEN (sub-closure `bf18bbf0…`) + `forge_manifest_keccak` GREEN (manifest root
  `c5d46fbd…`) — the sovereign forge closure, byte-for-byte at the 2026-06-03 checkpoint.
- `verify_nous_differential` GREEN 53/53.

**Capability-exercise sweep** — III *performing* representative capabilities (fresh iiis-2 compile +
`libiii_native` link + run), showing the produced result:

| Capability | Program | Result |
|---|---|---|
| SHA-256("abc") | `02_sha256_kat_abc` | exit `186` (correct digest byte) |
| AES-128 (FIPS-197) | `60_aes128_fips197_kat` | exit `105` |
| ChaCha20-Poly1305 AEAD (RFC 8439) | `72_…aead_rfc8439` | OK |
| Ed25519 sign+verify (RFC 8032) | `59_ed25519_rfc8032_test1` | OK |
| ML-KEM PQ KEM roundtrip | `199_mlkem_roundtrip` | OK |
| SLH-DSA / SPHINCS+ (FIPS-205) | `770_slhdsa_shake_fips205` | OK |
| HotStuff BFT → COMMIT | `383_hotstuff` | OK |
| Sealed channel (X25519+AEAD) | `210_sealed_channel_handshake` | OK |
| `ai_resolve` NL→intent | `246_ai_resolve` | OK |
| Conjecture completion | `1104_conjecture_term` | OK |

**Comprehensive cross-domain sweep (augmenting the 10 above):** a further **33** programs —
hashing (SHA-256-empty `227`, SHA3-256, Keccak `231`, BLAKE2s `80`, HMAC `176`, CRC32 `203`),
KDF (HKDF `60`, PBKDF2 `85`), symmetric (AES-256 `142`, ChaCha20 `16`, Poly1305 `168`, AES-GCM),
asymmetric+PQ (X25519 `195`, RSA-PSS, ML-DSA), bignum+fields (bigint mul/div, Montgomery, NTT),
data structures (map/pq/LRU), text (base64/JSON/regex), networking (HTTP/federation), witness
(chain-verify/redaction), Katabasis descent (svm-hexad/admit), conjecture (gen/lemma) — **33/33 OK,
0 mismatch/fail**. Combined with the 10 above: **43 capabilities exercised across all 13 domains,
III alone, every result vector-correct.**

## 4. Honest boundary (no green-wash)

The byte-exact **bootstrap-determinism seal** is *not* certified this session, and deliberately so:
the working tree is **mid-reseal** (81 modified `COMPILER/BOOT/` + `COMPILED/` files — the operator's
in-flight compiler reseal). The self-hosting *capability* is proven (the entire 780-test corpus + the
464-module stdlib are `iiis-2` output). But running `build_iiis`/reseal to certify byte-determinism
would clobber the operator's in-progress work on the trust root (crash-protocol territory; the reseal's
intent is the operator's, not inferable here). It is left untouched and flagged, not papered over.

## 5. Commit ledger (this campaign; all clean-staged — mid-reseal WIP left unstaged)

- `890a90d` — Organs C (Witnessed Sense) + E (Forked Walk).
- `a7cb368` — Conjecture incr 1–2 + the organ-A vacuity finding.
- `8e9586e` — Conjecture incr 3 (structured-term completion).
- `6f5b428` — Conjecture incr 4–5 (generalization + lemma discovery).
- `e7130d4` — incr-3 soundness fix (reduction order; reachability guard was unsound).
- `99a31a2` — hardening (`nr_add` depth-1 guard + mechanism-isolated regression).

*Sister docs: III-BEYOND-DETERMINISM-CONTEMPLATION.md, III-ORGAN-{A,C,E}-*.md.*
