export const meta = {
  name: 'iii-w54-lattice-laws',
  description: 'W54: a documented LATTICE/ALGEBRAIC law (monotonicity, idempotence f(f(x))=f(x), commutativity, associativity, absorption, join/meet duality) that FAILS on an adversarial input -- the W35/W49 method applied to the order-theoretic + canonicalization ops. Adversarial refute (law scoped out? holds on the real domain? KAT covers it?).',
  phases: [ { title: 'Find' }, { title: 'Refute' } ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const OMNIA = ROOT + '\\STDLIB\\iii\\omnia'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'lattices', dir: NUMERA, files: 'interval_lattice.iii widening.iii cost_lattice.iii cost_lattice_unified.iii memo_lattice.iii reduced_product.iii sep_logic.iii csl.iii interval_lattice.iii' },
  { key: 'fixpoint_closure', dir: NUMERA, files: 'kleene_fixpoint.iii congruence_closure.iii congruence.iii omega_engine.iii sccp.iii gvn.iii widening.iii' },
  { key: 'category_cost', dir: NUMERA, files: 'category.iii costed_cat.iii certified_morphism.iii cost_calculus.iii unified_cost_manifold.iii pareto_frontier.iii optimality_cert.iii' },
  { key: 'ring_algebra', dir: NUMERA, files: 'bv_ring.iii matrix_ring.iii ring_opt.iii galois.iii gf_poly.iii trit.iii q128.iii' },
  { key: 'collections', dir: OMNIA, files: 'map.iii set.iii list.iii lru.iii fold.iii hexad_algebra.iii hexad_mobius.iii hexad_lattice.iii memo_lattice.iii' },
  { key: 'xii_canon', dir: OMNIA, files: 'xii_canonicalise.iii xii_joinability.iii xii_lattice.iii xii_cost_monotone.iii xii_rule_overlap.iii xii_termination.iii' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'line', 'law', 'doc_claim', 'counterexample', 'lhs', 'rhs', 'witness_in_module', 'reachable_export', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
      law: { type: 'string', enum: ['monotonicity', 'idempotence', 'commutativity', 'associativity', 'absorption', 'duality', 'order_consistency'] },
      doc_claim: { type: 'string', description: 'quote the doc/KAT text asserting the law' },
      counterexample: { type: 'string', description: 'the concrete reachable input(s) where the law fails' },
      lhs: { type: 'string', description: 'the value of one side (e.g. f(f(x)) / a join b)' },
      rhs: { type: 'string', description: 'the value of the other side (e.g. f(x) / b join a) -- DIFFERENT, proving the violation' },
      witness_in_module: { type: 'string', description: 'a module witness/KAT that would disagree; name it or NONE' },
      reachable_export: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason'],
  properties: { is_real_defect: { type: 'boolean' }, reason: { type: 'string' }, proposed_teeth: { type: 'string' } },
}

const FIND_PROMPT = (g) => `You are auditing the III stdlib for LATTICE / ALGEBRAIC LAW VIOLATIONS -- a documented order-theoretic or algebraic property that FAILS on a reachable adversarial input.  (Recent finds in this family: rp_count empty-interval wrap W35; interval_lattice overflow-unsoundness W49.)
Read these files ${g.dir === OMNIA ? 'under STDLIB/iii/omnia' : 'in ' + NUMERA}: ${g.files}

Laws to check (where the doc/KAT CLAIMS them):
 - monotonicity: a<=b => f(a)<=f(b) (join/widen/cost-accumulate/refine).  An OVERFLOW or special-case can break it.
 - idempotence: f(f(x)) == f(x) (canonicalize/normalize/join-with-self/dedup).  Find x where f(f(x)) != f(x).
 - commutativity: a*b == b*a (join/meet/merge/compose).  Find a,b where they differ (a tie-break/order artifact).
 - associativity: (a*b)*c == a*(b*c) (join/meet/compose/cost-accumulate).
 - absorption: a join (a meet b) == a ; a meet (a join b) == a.
 - duality / order_consistency: a<=b  <=>  (a join b)==b  <=>  (a meet b)==a.  Find a,b where these disagree.

HARD GATES -- drop unless ALL hold:
 - a CONCRETE reachable input where LHS != RHS (give both values).  Trace the arithmetic by hand.
 - the doc/KAT genuinely CLAIMS the law (quote it).  If the op is not claimed to have the law, DROP.
 - reachable from an @export; the counterexample is in-domain (not a sentinel/empty the doc scopes out -- but a
   wrong result for a DEFINITE input IS a violation).
 - NOT already correct: re-derive both sides; if they are equal, DROP.  (Overflow/wraparound that BREAKS the law
   on a reachable input IS a real violation; wraparound that is the INTENDED ring semantics is NOT.)
 - STRONGEST: a module witness/KAT that asserts the law but only on tame inputs -- name it.

This tree is meticulous; most laws hold + are KAT'd (often the KAT drives the law on sampled inputs).  ZERO
findings is honest.  Only report a violation you traced with both concrete values.  Return JSON.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const candidates = found.filter(Boolean).flat().filter(f => f.reachable_export && f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) (of ${found.filter(Boolean).flat().length} raw)`)
if (candidates.length === 0) {
  return { confirmed: [], note: 'no lattice/algebraic law violation survived the self-gate; the order-theoretic + canon ops uphold their laws (or scope them)' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier for a claimed LATTICE/ALGEBRAIC LAW VIOLATION in the III stdlib.

CLAIM: ${c.file} ${c.fn} (line ~${c.line}) law=${c.law}
  doc claim: ${c.doc_claim}
  counterexample: ${c.counterexample} -> LHS ${c.lhs} vs RHS ${c.rhs}
  witness: ${c.witness_in_module}

Read the source + the KAT + grep ${CORPUS} for the fn.  Kills:
 (1) LAW ACTUALLY HOLDS: re-derive BOTH sides by hand on the input.  If LHS==RHS, REFUTE (claim mis-traced).
 (2) NOT CLAIMED / SCOPED: does the doc actually claim this law for this op, on this input?  If the op is not
     claimed associative/idempotent/etc., or the input is scoped out, REFUTE.
 (3) INTENDED WRAPAROUND: is the "violation" just the op's defined modular/ring semantics (Z/2^64, Z/256)?  If
     wraparound IS the contract, REFUTE.
 (4) UNREACHABLE / out-of-contract / already-tested.
Default is_real_defect=FALSE unless it SURVIVES all.  If real, give the teeth (the @export law-check that
returns the wrong result, pre-fix vs post-fix).  Cite source + the two re-derived values.`,
    { label: `refute:${c.file}:${c.fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))
const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log(`Refute complete: ${confirmed.length} confirmed of ${candidates.length}`)
return {
  confirmed: confirmed.map(c => ({ file: c.file, fn: c.fn, line: c.line, law: c.law, doc_claim: c.doc_claim,
    counterexample: c.counterexample, lhs: c.lhs, rhs: c.rhs, witness_in_module: c.witness_in_module,
    proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
