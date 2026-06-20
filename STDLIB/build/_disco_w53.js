export const meta = {
  name: 'iii-w53-verdict-soundness',
  description: 'W53: a prover/analysis @export returns a FALSE-POSITIVE verdict (SAFE/PROVEN/EQUIVALENT/IN-BOUNDS when the property is actually FALSE) on a crafted reachable input -- the highest-value soundness hole. Mechanisms: overflow (the interval_lattice class), an unhandled case, a boundary off-by-one, a fuel-cap returning a definite verdict instead of UNKNOWN. Over the analysis/prover modules. Adversarial refute.',
  phases: [ { title: 'Find' }, { title: 'Refute' } ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'range_bounds', files: 'value_range_prover.iii loop_bounds_prover.iii range_check.iii affine_check.iii loop_optimizer.iii vectorizer.iii widening.iii interval_lattice.iii' },
  { key: 'dataflow', files: 'sccp.iii gvn.iii dce.iii liveness.iii dominators.iii ssa.iii reg_alloc.iii isel.iii list_schedule.iii' },
  { key: 'model_check', files: 'bmc.iii kinduction.iii induct.iii smt.iii sat.iii sat_arith.iii sat_at_scale.iii conjecture_refute.iii' },
  { key: 'safety_equiv', files: 'safety_prover.iii safety_type.iii translation_validation.iii proof_carrying.iii optimality_cert.iii cost_lattice.iii cost_lattice_unified.iii' },
  { key: 'congruence_rewrite', files: 'congruence_closure.iii congruence.iii egraph.iii relational_ematch.iii groebner.iii kleene_fixpoint.iii sep_logic.iii' },
  { key: 'taint_provenance', files: 'taint_analysis.iii scalar_provenance.iii ptr_provenance.iii reduced_product.iii uncertainty.iii branch_elim.iii sccp.iii' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'line', 'verdict_fn', 'false_positive_input', 'verdict_claims', 'actual_truth', 'mechanism', 'witness_in_module', 'reachable_export', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
      verdict_fn: { type: 'string', description: 'the @export that returns the verdict (SAFE/PROVEN/EQUIV/IN-BOUNDS/1)' },
      false_positive_input: { type: 'string', description: 'a concrete reachable input where the verdict is a FALSE POSITIVE' },
      verdict_claims: { type: 'string', description: 'what the verdict says (e.g. "SAFE / in-bounds / equivalent / 1")' },
      actual_truth: { type: 'string', description: 'why the property is actually FALSE for that input' },
      mechanism: { type: 'string', enum: ['overflow', 'unhandled_case', 'boundary_offbyone', 'fuel_cap_wrong_verdict', 'unsound_transfer'] },
      witness_in_module: { type: 'string', description: 'a module witness/reference (exhaustive scan, naive ref) that would DISAGREE; name it or NONE' },
      reachable_export: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason'],
  properties: { is_real_defect: { type: 'boolean' }, reason: { type: 'string' }, proposed_teeth: { type: 'string' } },
}

const FIND_PROMPT = (g) => `You are auditing the III stdlib for FALSE-POSITIVE VERDICTS -- a prover/analysis @export that returns SAFE / PROVEN / EQUIVALENT / IN-BOUNDS / 1 when the property is ACTUALLY FALSE on a crafted reachable input.  This is the highest-value soundness hole (e.g. the W49 interval_lattice find: il_add claimed soundness but overflow inverted the interval, so a consumer could prove a false in-bounds).
Read these files in ${NUMERA}: ${g.files}

For each @export that returns a VERDICT (a yes/no safety/equivalence/bound/proof result), find a concrete
reachable input where the verdict is a FALSE POSITIVE (claims true when false), via:
 - overflow (an unsound transfer / a bound that wraps -- the interval_lattice class).
 - an unhandled_case the verdict logic skips (defaults to SAFE/EQUIV).
 - a boundary_offbyone (the exact extremal value mis-verdicted).
 - a fuel_cap that returns a DEFINITE verdict (SAFE/UNSAT) instead of UNKNOWN when the bound is hit (claiming
   proof it did not complete).
 - an unsound_transfer (a join/meet/widen/compose that does not over-approximate).

HARD GATES -- drop unless ALL hold:
 - a CONCRETE reachable input where the verdict is provably WRONG (claims true, property false).  State both.
 - reachable from an @export with caller-controllable input.
 - the FALSE-POSITIVE direction (unsound: claims SAFE when UNSAFE).  An over-conservative UNKNOWN/UNSAFE-when-
   safe is INCOMPLETENESS, not a soundness hole -- lower priority, report only if the doc claims completeness.
 - STRONGEST signal: a module witness (exhaustive scan / naive reference) that DISAGREES with the verdict on
   the input -- name it.
 - NOT already correct: trace by hand; if the verdict logic handles the case (a guard, an overflow check, a
   widen-to-top, returns UNKNOWN on fuel-out), DROP.

This tree is meticulous; provers are mostly sound + carefully scoped (fuel-out returns UNKNOWN, overflow
saturates, the witness agrees).  ZERO findings is honest.  Only report a false-positive you traced with the
concrete input + why the property is false + (ideally) the disagreeing witness.  Return JSON.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const candidates = found.filter(Boolean).flat().filter(f => f.reachable_export && f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) (of ${found.filter(Boolean).flat().length} raw)`)
if (candidates.length === 0) {
  return { confirmed: [], note: 'no false-positive verdict survived the self-gate; provers are sound + carefully scoped' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier for a claimed FALSE-POSITIVE VERDICT (unsound prover) in the III stdlib.

CLAIM: ${NUMERA}\\${c.file} ${c.fn} (line ~${c.line}) verdict_fn=${c.verdict_fn}
  false-positive input: ${c.false_positive_input}
  verdict claims: ${c.verdict_claims} ; actual truth: ${c.actual_truth}
  mechanism: ${c.mechanism} ; module witness that disagrees: ${c.witness_in_module}

Read the source + the witness/KAT + grep ${CORPUS} for the fn.  Kills:
 (1) VERDICT ACTUALLY CORRECT: re-derive the property by hand on the input.  If the verdict is TRUE (property
     really holds), REFUTE.  Trace the actual truth carefully (do not assume the claim's math).
 (2) HANDLED: does the code guard the mechanism (overflow check, widen-to-top, fuel-out -> UNKNOWN, the case
     handled)?  If so, REFUTE.
 (3) INPUT OUT-OF-CONTRACT / UNREACHABLE: is the false-positive input outside the documented domain or not
     constructible via any @export?  REFUTE.
 (4) WITNESS AGREES: does the named module witness actually AGREE with the verdict (so no real disagreement)?
     Re-run the witness logic by hand.  If it agrees, REFUTE.
 (5) over-conservative (UNKNOWN/UNSAFE-when-safe) = incompleteness not unsoundness -> not a soundness defect.
Default is_real_defect=FALSE unless it SURVIVES all.  If real, give the value-differential teeth (the @export
verdict call returning the false TRUE, vs the witness/correct answer), pre-fix vs post-fix.  Cite source + witness.`,
    { label: `refute:${c.file}:${c.fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))
const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log(`Refute complete: ${confirmed.length} confirmed of ${candidates.length}`)
return {
  confirmed: confirmed.map(c => ({ file: c.file, fn: c.fn, line: c.line, verdict_fn: c.verdict_fn,
    false_positive_input: c.false_positive_input, verdict_claims: c.verdict_claims, actual_truth: c.actual_truth,
    mechanism: c.mechanism, witness_in_module: c.witness_in_module,
    proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
