export const meta = {
  name: 'iii-w50-soundness-claims',
  description: 'W50: mine the productive W49 axis -- a module DOCUMENTS a soundness/completeness/exactness/termination property the code does NOT fully uphold (the interval_lattice overflow-unsoundness pattern). Over the proof/verification/zk/lattice/category modules not yet probed on this axis. Adversarially refute (claim scoped out? code actually upholds it? unreachable?).',
  phases: [ { title: 'Find' }, { title: 'Refute' } ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'lattice_domain', files: 'sep_logic.iii omega_engine.iii congruence_closure.iii congruence.iii kleene_fixpoint.iii memo_lattice.iii interval_lattice.iii widening.iii reduced_product.iii cost_lattice.iii cost_lattice_unified.iii' },
  { key: 'proof_verify', files: 'proof_term.iii proof_carrying.iii proof_replay.iii theorem_carrier.iii theorem_commons.iii safety_prover.iii safety_type.iii translation_validation.iii curry_howard.iii quine_verifier.iii optimality_cert.iii' },
  { key: 'induction_model', files: 'induct.iii kinduction.iii bmc.iii smt.iii sat.iii sat_arith.iii sat_at_scale.iii loop_bounds_prover.iii value_range_prover.iii conjecture_refute.iii' },
  { key: 'zk', files: 'zk_air.iii zk_stark.iii zk_snark.iii zk_field.iii zk_prune.iii zk_stark_seal.iii ntt_fri_organ.iii merkle.iii' },
  { key: 'category_morph', files: 'category.iii costed_cat.iii certified_morphism.iii sheaf.iii combinator.iii groebner.iii galois.iii gf_poly.iii' },
  { key: 'xii_rewrite', files: ROOT + '\\STDLIB\\iii\\omnia\\xii_termination.iii ' + ROOT + '\\STDLIB\\iii\\omnia\\xii_joinability.iii ' + ROOT + '\\STDLIB\\iii\\omnia\\xii_conf_cert.iii ' + ROOT + '\\STDLIB\\iii\\omnia\\xii_critpair_enum.iii ' + ROOT + '\\STDLIB\\iii\\omnia\\xii_cost_monotone.iii ' + ROOT + '\\STDLIB\\iii\\omnia\\xii_canonicalise.iii', absolute: true },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'line', 'property', 'doc_claim', 'violation_input', 'why_violated', 'witness_in_module', 'reachable_export', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
      property: { type: 'string', enum: ['soundness', 'completeness', 'exactness', 'termination', 'monotonicity', 'idempotence'] },
      doc_claim: { type: 'string', description: 'quote the doc text asserting the property' },
      violation_input: { type: 'string', description: 'a concrete reachable input where the property FAILS' },
      why_violated: { type: 'string', description: 'the concrete mechanism (e.g. overflow wraps the bound; a case is unhandled; a recursion has no decreasing measure)' },
      witness_in_module: { type: 'string', description: 'does the module ship its OWN witness/checker that would reject this (like il_add_sound)? name it or NONE' },
      reachable_export: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason'],
  properties: { is_real_defect: { type: 'boolean' }, reason: { type: 'string' }, proposed_teeth: { type: 'string' } },
}

const FIND_PROMPT = (g) => `You are auditing the III stdlib for the W49 pattern: a module DOCUMENTS a formal property (SOUNDNESS / COMPLETENESS / EXACTNESS / TERMINATION / MONOTONICITY / IDEMPOTENCE) that the code does NOT fully uphold on a reachable input.  (The W49 find: interval_lattice claimed its transfer functions SOUND but raw-u32 overflow inverted the interval, which the module's own il_add_sound witness rejects.)
Read these files (${g.absolute ? 'absolute paths' : 'in ' + NUMERA}): ${g.files}

For each module: read the doc-comment's FORMAL CLAIMS (the "Verified (..._kat): ..." block, "SOUND", "exact",
"terminates", "contains every", "monotone", "idempotent").  Then check whether the CODE actually upholds the
claim on every REACHABLE input -- especially:
 - OVERFLOW/wraparound breaking a soundness/exactness claim (the interval_lattice pattern).
 - an UNHANDLED case breaking a completeness claim (handles N-1 of N documented cases).
 - a recursion/iteration with NO decreasing measure breaking a termination claim (or a fuel/cap that silently
   truncates and returns a WRONG verdict instead of "unknown").
 - a non-monotone/non-idempotent op where the doc claims it.

HARD GATES -- drop unless ALL hold:
 - a CONCRETE reachable input where the property FAILS, with the exact mechanism.
 - the doc genuinely CLAIMS the property (quote it).  If the doc is careful/scoped (e.g. "for n a power of two",
   "assuming no overflow", a documented fuel-bound that returns UNKNOWN not a wrong verdict), DROP.
 - reachable from an @export.
 - BONUS: if the module ships its OWN witness/checker (like il_add_sound) that would reject the violating
   input, that is the strongest signal -- name it.

This tree is meticulous and most claims are carefully scoped + upheld.  ZERO findings is honest.  Only report a
violation you traced by hand with the doc quote + the concrete failing input + mechanism.  Return JSON.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const candidates = found.filter(Boolean).flat().filter(f => f.reachable_export && f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) (of ${found.filter(Boolean).flat().length} raw)`)
if (candidates.length === 0) {
  return { confirmed: [], note: 'no documented-property violation survived the self-gate; the proof/verify/zk/lattice modules uphold their formal claims (or scope them carefully)' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier for a claimed DOCUMENTED-PROPERTY VIOLATION (soundness/completeness/exactness/termination) in the III stdlib.

CLAIM: ${c.file} ${c.fn} (line ~${c.line}) property=${c.property}
  doc claim: ${c.doc_claim}
  violation input: ${c.violation_input}
  why violated: ${c.why_violated}
  module's own witness: ${c.witness_in_module}

Read the source + the doc verbatim + grep ${CORPUS} for the fn.  Kills:
 (1) DOC SCOPED: does the doc actually SCOPE OUT this input (a precondition "for n power of two", "assuming no
     overflow", "fuel-bounded -> returns UNKNOWN")?  If the violating input is out-of-contract, REFUTE.
 (2) CODE UPHOLDS IT: re-derive by hand; does the code actually handle this case (a guard, a saturate-to-TOP, a
     widen-to-inf, an overflow check)?  If upheld, REFUTE.
 (3) the "violation" returns a SAFE/conservative answer (UNKNOWN, refuse, TOP) not a WRONG one -> that is sound
     degradation, not a defect.  REFUTE.
 (4) UNREACHABLE / vacuous / already-tested.
Default is_real_defect=FALSE unless it SURVIVES all.  If real, give the value-differential teeth a falsifier
would assert (the property-violating observable, pre-fix vs post-fix).  Cite the doc + source lines.`,
    { label: `refute:${c.file}:${c.fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))
const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log(`Refute complete: ${confirmed.length} confirmed of ${candidates.length}`)
return {
  confirmed: confirmed.map(c => ({ file: c.file, fn: c.fn, line: c.line, property: c.property,
    doc_claim: c.doc_claim, violation_input: c.violation_input, why_violated: c.why_violated,
    witness_in_module: c.witness_in_module, proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
