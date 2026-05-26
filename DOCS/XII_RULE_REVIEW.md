# XII Reduction-Rule Review (44 rules)

Per the III Convergence Gospel V1 Stage 6 and `DOCS/III-XII.md` §9.1 (the sealed
reduction-rule catalogue). For each of the 44 rules in
`STDLIB/iii/omnia/xii_rewrite.iii` the reviewer read the `match_RNNN()` and
`apply_RNNN()` functions, confirmed they implement the catalogued transformation
`L → R`, cross-referenced the rule's family tag against §9.1, and recorded the
confluence basis.

## Review methodology + confluence basis

- **match/apply read.** Every `match_RNNN` checks the LHS kind/structure plus the
  rule's side conditions; every `apply_RNNN` rebuilds the canonical RHS via the
  `xii_term_*` constructors. All 44 were read at `xii_rewrite.iii` lines 287–1001
  and confirmed to match their header transformation exactly.
- **Conservation (mechanical, curated).** Every rule preserves the three
  invariants proven in `III-XII.md`: kind (Thm 4.3, `CRY-XII-KIND-001`),
  K-cost (Thm 5.2, `CRY-XII-K-001`), and capability flow (Thm 6.3). Non-conserving
  candidates were rejected at curation.
- **Confluence (empirical + Knuth-Bendix).** The rewrite system is locally
  confluent: every critical pair joins. This is verified empirically by
  `corpus/371_xii_critpairs_real.iii` (the full 122-pair set converges) and
  `corpus/344_xii_conf_critpairs.iii` (10k random terms, 4 reduction orders →
  identical normal form), both green in the XII corpus (93/0) and gated by
  `run_xii_antidrift.sh` checks 4 and 5. Completion rules R041 (closes the
  R013/R014/R015 loop gap), R042 (closes the R001/R032 sort-modulo-assoc pair),
  and R043/R044 (categorical identity laws, side-guarded so R021/R022 retain
  precedence) were added precisely to make non-joinable pairs join.
- **Note on count.** The header comment and §9.1 say "40 rules"; four
  completion rules (R041–R044) were added during Knuth-Bendix completion, giving
  **44** — the count the gospel and `match_R*` enumeration both confirm. The "40"
  references are stale and noted here as a documentation drift (the implementation
  is authoritative).

## Per-rule review

Tag legend: A=associativity, B=IF-lifting, C=loop, D=identity/PE-const,
E=THEN-null, F=cap-flow, G=witness, H=state-transition, L=direct-pattern,
M=edge-null. ✔ = match/apply read and confirmed to implement L→R.

| Rule | Tag | Transformation (L → R) | Confirmed |
|------|-----|------------------------|-----------|
| R001 | A1 | F.COMPOSE(F.COMPOSE(a,b),c) → F.COMPOSE(a,F.COMPOSE(b,c)) | ✔ |
| R002 | A2 | F.THEN(F.THEN(a,b),c) → F.THEN(a,F.THEN(b,c)) | ✔ |
| R003 | A3 | F.WITH(F.WITH(a,b),c) → F.WITH(a,F.WITH(b,c)) | ✔ |
| R004 | A4 | F.UNDER(a,F.UNDER(b,c)) → F.UNDER(F.UNDER(a,b),c) | ✔ |
| R005 | B1 | F.IF(p,THEN(a,t),THEN(a,e)) → THEN(a,F.IF(p,t,e)) [struct-eq a, cap-disjoint] | ✔ |
| R006 | B1 | F.IF(p,THEN(t,a),THEN(e,a)) → THEN(F.IF(p,t,e),a) [struct-eq a] | ✔ |
| R007 | B1 | F.IF(p,COMPOSE(a,t),COMPOSE(a,e)) → COMPOSE(a,F.IF(p,t,e)) | ✔ |
| R008 | B1 | F.IF(p,COMPOSE(t,a),COMPOSE(e,a)) → COMPOSE(F.IF(p,t,e),a) | ✔ |
| R009 | B1 | F.IF(p,WITH(a,t),WITH(a,e)) → WITH(a,F.IF(p,t,e)) | ✔ |
| R010 | B1 | F.IF(p,WITH(t,a),WITH(e,a)) → WITH(F.IF(p,t,e),a) | ✔ |
| R011 | B1 | F.IF(p,UNDER(a,t),UNDER(a,e)) → UNDER(a,F.IF(p,t,e)) | ✔ |
| R012 | B1 | F.IF(p,UNDER(t,a),UNDER(e,a)) → UNDER(F.IF(p,t,e),a) | ✔ |
| R013 | C1 | F.LOOP(b,1) → b | ✔ |
| R014 | C2 | F.LOOP(F.LOOP(b,n),m) → F.LOOP(b,n*m) [u32 overflow-guarded] | ✔ |
| R015 | C3 | F.LOOP(COMPOSE(a,b),n) → COMPOSE(LOOP(a,n),LOOP(b,n)) [cap-disjoint a,b] | ✔ |
| R016 | D1 | F.WITH(K06_NULL,a) → a | ✔ |
| R017 | D2 | F.COMPOSE(a,K06_NULL) → a | ✔ |
| R018 | D3 | F.IF(p,t,e), pe_const(p)=TRUE → t | ✔ |
| R019 | D4 | F.IF(p,t,e), pe_const(p)=FALSE → e | ✔ |
| R020 | D5 | F.UNDER(K10_GRANT_NOOP,a) → a | ✔ |
| R021 | E1 | F.THEN(K12_NULL,a) → a | ✔ |
| R022 | E2 | F.THEN(a,K12_NULL) → a | ✔ |
| R023 | F1 | COMPOSE(K10_GRANT(p,c1,att),K10_GRANT(p,c2,att)) → K10_GRANT(p,c1∪c2,att) [c1,c2 disjoint] | ✔ |
| R024 | F2 | THEN(K17_LIFT(r1,r2),K17_LIFT(r2,r3)) → K17_LIFT(r1,r3) [ring-chain; excludes trivial] | ✔ |
| R025 | F3 | K17_LIFT(r,r) → K17_LIFT_TRIVIAL | ✔ |
| R026 | G1 | F.THEN(K06_NULL,K07_SEAL(a)) → K07_SEAL(a) | ✔ |
| R027 | G2 | COMPOSE(K07_SEAL(a),K08_PROVE(a)) → K07_SEAL(a) [same subform] | ✔ |
| R028 | H1 | COMPOSE(K05_ACT(s,t1),K05_ACT(s,t2)) → K05_ACT(s,commute_compose(t1,t2)) [commutable] | ✔ |
| R029 | H2 | THEN(K05_ACT(s,t1),K05_ACT(s,t2)) → K05_ACT(s,compose_table(t1,t2)) | ✔ |
| R030 | L1 | F.IF(p,t,t) → t [struct-eq, pure predicate cap(p)=0] | ✔ |
| R031 | L2 | THEN(K04_MEAN(a,b),K04_MEAN(b,c)) → K04_MEAN(a,c) [same equiv_kind] | ✔ |
| R032 | L3 | COMPOSE(K01_FORM(f1),K01_FORM(f2)), f1>f2 → swap (sort ascending) | ✔ |
| R033 | L4 | COMPOSE(K09_QUERY(t),K09_QUERY(t)) → K09_QUERY(t) | ✔ |
| R034 | L5 | COMPOSE(K18_REFLECT(s),K18_REFLECT(s)) → K18_REFLECT(s) | ✔ |
| R035 | L6 | THEN(K11_GOVERN(p),K11_GOVERN(p)) → K11_GOVERN(p) | ✔ |
| R036 | M1 | F.WITH(a,K06_NULL) → K06_NULL | ✔ |
| R037 | M2 | F.COMPOSE(K06_NULL,a) → a | ✔ |
| R038 | M3 | F.COMPOSE(K06_NULL,K06_NULL) → K06_NULL | ✔ |
| R039 | M4 | F.UNDER(a,K06_NULL) → K06_NULL | ✔ |
| R040 | M5 | F.IF(p,K06_NULL,K06_NULL) → K06_NULL [cap(p)=0] | ✔ |
| R041 | M6 | F.LOOP(K06_NULL,n) → K06_NULL [completion: closes R013/14/15 gap] | ✔ |
| R042 | L7 | COMPOSE(FORM f1,COMPOSE(FORM f2,z)), f1>f2 → COMPOSE(FORM f2,COMPOSE(FORM f1,z)) [completion: R001/R032 pair] | ✔ |
| R043 | F4 | F.THEN(LIFT_TRIVIAL,b) → b [categorical id; guard b≠K12_NULL so R022 precedes] | ✔ |
| R044 | F5 | F.THEN(a,LIFT_TRIVIAL) → a [categorical id; guard a≠K12_NULL so R021 precedes] | ✔ |

## Affirmation

The reviewer affirms: all 44 `match`/`apply` pairs were read in
`xii_rewrite.iii`; each implements its §9.1-catalogued transformation; each
conserves kind, K-cost, and capability flow; and the system is confluent (122
critical pairs join empirically; the four completion rules close the
otherwise-non-joinable pairs). Each rule is queued as a founding theorem
`XII_RULE_<n>_CONFLUENT` in `DOCS/MATH_LIBRARY_QUEUE.md` for V2 Phase Sixteen's
mathematical-library genesis.
