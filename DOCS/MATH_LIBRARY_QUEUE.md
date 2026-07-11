# Math Library Queue

Accumulating theorem queue for admission to the substrate's mathematical
library at a later (V2) phase. Each entry records a theorem identifier (the
SHA-256/Keccak-256 of its canonical statement), the statement, and the
discharging tactic. Append-only.

Stages append as they prove things:
- §4 (crypto stack): KAT correctness theorems (each KAT vector that passes is a
  proven instance — e.g. "Ed25519 sign/verify round-trips RFC 8032 §7.1",
  "ML-DSA keygen matches FIPS 204 reference", "AES-SIV matches RFC 5297 §A.1",
  "ECDSA-P256/P384 sign→verify accepts and tamper rejects").
- Stage 6 (XII ceremony): the rule-confluence theorems for the rewrite rules.
- Stage 8 (type system): CIC kernel type-judgement theorems.

A later stage seals this file (as `MATH_LIBRARY_QUEUE_V1_SEALED.md`) for V2
consumption; until then it is open.

## Format

Each entry is a subsection `### <theorem_id>` with the canonical statement in a
fenced block and the discharging tactic on the final line.

## Entries

(The math-library admission tactic is now DEFINED — `numera/mathesis_admit.iii`
(PROVEN ∧ NOVEL ∧ USEFUL ∧ WITNESSED, corpus/2600) per `DOCS/III-MATHESIS-MAP.md`
§6 — and the first machine-discovered entry is sealed below.  The §4 crypto KATs
(corpus 198–209) remain candidate entries for formalization through the same
door; forward reference #10 in `DOCS/FORWARD_REFERENCES.md`.)

### fc729f523ba4c70193b71e25f8ac0ea8fc1c6c0e33855a71482bcd7d6a48237b

MATHESIS-THEOREM-0001 — the first theorem III discovered about its own
compilation, proved against its own disposer, and folded back into its own
compiler (Ξ0 seed cycle, `DOCS/III-MATHESIS-MAP.md` §7).

```
∀ x, c1, c2 ∈ ℤ/2^64 :   (x & c1) & c2  ≡  x & (c1 & c2)

canonical descriptor (numera/mathesis_admit.iii layout, hashed to the id above):
  { MX01, family=0x25 (AND), pattern=const-chain(1), replacement=single-fold(1),
    width=64, signedness=unsigned(0), range=full-domain(0,0) }
```

- **Discharging tactic:** symbolic-schema route — ONE `seq_equiv` call
  (`numera/ser_kinduct_sym.iii:607`) with the constants as bv parameters, PROVEN
  (1) over all 2^64 assignments of x, c1, c2; second engine (R1 dual): the
  bit-local truth table (AND is bit-independent — 2^3 cases are a complete
  proof).  Gate: `corpus/2601_mathesis_dispose` (with the R4 false-identity
  `a+b ≡ a|b` REFUTED first, the width-64 tooth `(x<<32)>>32 ≢ x` REFUTED, and
  SEQ_TOP honest-abstain arms).
- **Discovery (measure-first):** the opcode-synchronous census
  (`numera/mathesis_measure.iii`, gate `corpus/2602`) over 55 route-S-emitted
  real modules: 349 fns, 27,134 ops, 0 unwalkable — **78 live AND-const-chain
  windows** (every other candidate class 0); stage1 surface: 0 (the R6 no-fire
  condition, measured).
- **Assimilation:** emission-time fold at cg_svir's `eb(0x25)` choke point
  (`COMPILER/BOOT/cg_svir.iii` `e_and_chain_fold`, dual event-history +
  byte-shape eligibility).  Measured on `sq08_mixed`: **494→484 bytes,
  126→124 ops, windows 1→0**; commuting square N≡E≡S held (rc=92); A1 iiisv2
  parity held (6/6); golden `sq08_mixed` resealed (the sanctioned
  emission-law-change class, `COMPILER/BOOT/svir_backend_goldens.txt`).
- **Witness chain:** genesis
  `2aaed09140f0f69fea23e0f5529c64534981f15e79beb7bc9ae34248e630f676` →
  head `88dbee1673702995acc78466476f406af1b90e92940330f7e311f7286d47df58`
  (= Keccak-256(genesis ‖ theorem_id), `mx_chain_step`).  Replay gate:
  `corpus/2603_mathesis_seal` — the descriptor re-hashes to this id, tampering
  breaks it, the chain re-derives this head.

### XII rewrite-rule confluence theorems (V1 Stage 6)

Reviewed in `DOCS/XII_RULE_REVIEW.md` (all 44 match/apply read + confirmed).
**Shared canonical form** for `XII_RULE_<n>_CONFLUENT`, n = 001..044:
- **Antecedent type:** `t : XiiTerm` such that `match_R<n>(t) = 1` (the rule's LHS pattern + side conditions hold).
- **Consequent type:** `canon_equiv(apply_R<n>(t), t)` ∧ `hk(apply)=hk(t)` ∧ `K(apply)=K(t)` ∧ `cap(apply)=cap(t)` — the rewrite is a canonical-equivalence-preserving, kind/K/cap-conserving reduction.
- **Discharging tactic:** local-confluence by critical-pair join (`corpus/371_xii_critpairs_real`, all 122 pairs converge; `corpus/344` 10k random terms × 4 orders) + conservation Theorems 4.3 (`CRY-XII-KIND-001`) / 5.2 (`CRY-XII-K-001`) / 6.3.
- **Witness chain segment:** `STDLIB/iii/omnia/xii_rewrite.iii::{match_R<n>, apply_R<n>}` + the XII corpus seal (93/0) + `run_xii_antidrift.sh` checks 4–5.

| Theorem | Reduction (L → R) |
|---------|-------------------|
| XII_RULE_001_CONFLUENT | F.COMPOSE(F.COMPOSE(a,b),c) → F.COMPOSE(a,F.COMPOSE(b,c)) |
| XII_RULE_002_CONFLUENT | F.THEN(F.THEN(a,b),c) → F.THEN(a,F.THEN(b,c)) |
| XII_RULE_003_CONFLUENT | F.WITH(F.WITH(a,b),c) → F.WITH(a,F.WITH(b,c)) |
| XII_RULE_004_CONFLUENT | F.UNDER(a,F.UNDER(b,c)) → F.UNDER(F.UNDER(a,b),c) |
| XII_RULE_005_CONFLUENT | F.IF(p,THEN(a,t),THEN(a,e)) → THEN(a,F.IF(p,t,e)) |
| XII_RULE_006_CONFLUENT | F.IF(p,THEN(t,a),THEN(e,a)) → THEN(F.IF(p,t,e),a) |
| XII_RULE_007_CONFLUENT | F.IF(p,COMPOSE(a,t),COMPOSE(a,e)) → COMPOSE(a,F.IF(p,t,e)) |
| XII_RULE_008_CONFLUENT | F.IF(p,COMPOSE(t,a),COMPOSE(e,a)) → COMPOSE(F.IF(p,t,e),a) |
| XII_RULE_009_CONFLUENT | F.IF(p,WITH(a,t),WITH(a,e)) → WITH(a,F.IF(p,t,e)) |
| XII_RULE_010_CONFLUENT | F.IF(p,WITH(t,a),WITH(e,a)) → WITH(F.IF(p,t,e),a) |
| XII_RULE_011_CONFLUENT | F.IF(p,UNDER(a,t),UNDER(a,e)) → UNDER(a,F.IF(p,t,e)) |
| XII_RULE_012_CONFLUENT | F.IF(p,UNDER(t,a),UNDER(e,a)) → UNDER(F.IF(p,t,e),a) |
| XII_RULE_013_CONFLUENT | F.LOOP(b,1) → b |
| XII_RULE_014_CONFLUENT | F.LOOP(F.LOOP(b,n),m) → F.LOOP(b,n*m) |
| XII_RULE_015_CONFLUENT | F.LOOP(COMPOSE(a,b),n) → COMPOSE(LOOP(a,n),LOOP(b,n)) |
| XII_RULE_016_CONFLUENT | F.WITH(K06_NULL,a) → a |
| XII_RULE_017_CONFLUENT | F.COMPOSE(a,K06_NULL) → a |
| XII_RULE_018_CONFLUENT | F.IF(p,t,e) [pe_const(p)=TRUE] → t |
| XII_RULE_019_CONFLUENT | F.IF(p,t,e) [pe_const(p)=FALSE] → e |
| XII_RULE_020_CONFLUENT | F.UNDER(K10_GRANT_NOOP,a) → a |
| XII_RULE_021_CONFLUENT | F.THEN(K12_NULL,a) → a |
| XII_RULE_022_CONFLUENT | F.THEN(a,K12_NULL) → a |
| XII_RULE_023_CONFLUENT | COMPOSE(K10_GRANT(p,c1),K10_GRANT(p,c2)) → K10_GRANT(p,c1∪c2) |
| XII_RULE_024_CONFLUENT | THEN(K17_LIFT(r1,r2),K17_LIFT(r2,r3)) → K17_LIFT(r1,r3) |
| XII_RULE_025_CONFLUENT | K17_LIFT(r,r) → K17_LIFT_TRIVIAL |
| XII_RULE_026_CONFLUENT | F.THEN(K06_NULL,K07_SEAL(a)) → K07_SEAL(a) |
| XII_RULE_027_CONFLUENT | COMPOSE(K07_SEAL(a),K08_PROVE(a)) → K07_SEAL(a) |
| XII_RULE_028_CONFLUENT | COMPOSE(K05_ACT(s,t1),K05_ACT(s,t2)) → K05_ACT(s,commute_compose(t1,t2)) |
| XII_RULE_029_CONFLUENT | THEN(K05_ACT(s,t1),K05_ACT(s,t2)) → K05_ACT(s,compose_table(t1,t2)) |
| XII_RULE_030_CONFLUENT | F.IF(p,t,t) → t [cap(p)=0] |
| XII_RULE_031_CONFLUENT | THEN(K04_MEAN(a,b),K04_MEAN(b,c)) → K04_MEAN(a,c) |
| XII_RULE_032_CONFLUENT | COMPOSE(K01_FORM(f1),K01_FORM(f2)) [f1>f2] → swap |
| XII_RULE_033_CONFLUENT | COMPOSE(K09_QUERY(t),K09_QUERY(t)) → K09_QUERY(t) |
| XII_RULE_034_CONFLUENT | COMPOSE(K18_REFLECT(s),K18_REFLECT(s)) → K18_REFLECT(s) |
| XII_RULE_035_CONFLUENT | THEN(K11_GOVERN(p),K11_GOVERN(p)) → K11_GOVERN(p) |
| XII_RULE_036_CONFLUENT | F.WITH(a,K06_NULL) → K06_NULL |
| XII_RULE_037_CONFLUENT | F.COMPOSE(K06_NULL,a) → a |
| XII_RULE_038_CONFLUENT | F.COMPOSE(K06_NULL,K06_NULL) → K06_NULL |
| XII_RULE_039_CONFLUENT | F.UNDER(a,K06_NULL) → K06_NULL |
| XII_RULE_040_CONFLUENT | F.IF(p,K06_NULL,K06_NULL) → K06_NULL [cap(p)=0] |
| XII_RULE_041_CONFLUENT | F.LOOP(K06_NULL,n) → K06_NULL (KB-completion: R013/14/15 gap) |
| XII_RULE_042_CONFLUENT | COMPOSE(FORM f1,COMPOSE(FORM f2,z)) [f1>f2] → COMPOSE(FORM f2,COMPOSE(FORM f1,z)) (KB: R001/R032 pair) |
| XII_RULE_043_CONFLUENT | F.THEN(LIFT_TRIVIAL,b) → b (categorical id; guard b≠K12_NULL) |
| XII_RULE_044_CONFLUENT | F.THEN(a,LIFT_TRIVIAL) → a (categorical id; guard a≠K12_NULL) |

These 44 founding theorems seed V2 Phase Sixteen's mathematical-library genesis
(processed in canonical order alongside the §4 crypto-KAT theorems and the V1
Stage 8 CIC kernel type-judgement theorems).
