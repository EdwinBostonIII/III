export const meta = {
  name: 'iii-w49-spec-precision',
  description: 'W49: two genuinely-untried correctness axes -- (A) spec-conformance completeness (an @export doc promises behavior the code only partially implements), (B) numerical precision loss (a fixed-point/rational/q128 op loses bits where the contract implies exactness: divide-before-multiply, intermediate truncation, wrong rounding). Adversarially refute (doc stale not code? precision loss intended/documented? unreachable?).',
  phases: [
    { title: 'Find', detail: 'per-group spec-completeness + precision scan' },
    { title: 'Refute', detail: 'adversarially verify the divergence is a real code defect' },
  ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'fixed_rational', files: 'fixed.iii fixed_extra.iii q128.iii q128_f64.iii rms.iii uncertainty.iii cost_lattice.iii cost_calculus.iii interval_lattice.iii widening.iii' },
  { key: 'modular_field', files: 'modular.iii modular_mont.iii barrett.iii fp256.iii fn256.iii fp384.iii fn384.iii field.iii galois.iii gf_poly.iii crt.iii congruence.iii scalar.iii ed_scalar_modl.iii' },
  { key: 'bigint_ntt', files: 'bigint.iii bigint_div.iii bigint_karatsuba.iii ntt.iii ntt_bigint.iii ntt_fri_organ.iii reduced_product.iii range_check.iii value_range_prover.iii' },
  { key: 'dp_combinatorial', files: 'coin_change.iii knapsack.iii lcs.iii lis.iii levenshtein.iii catalan.iii inversion_count.iii sieve.iii collatz.iii goldbach.iii binary_search.iii segment_tree.iii fenwick.iii' },
  { key: 'proof_analysis', files: 'sccp.iii gvn.iii value_range_prover.iii loop_bounds_prover.iii safety_prover.iii smt.iii sat_arith.iii kinduction.iii induct.iii translation_validation.iii cost_lattice_unified.iii microarch_model.iii' },
  { key: 'codes_signal', files: 'rscode.iii rscode_ec.iii hamming_secded.iii crc32.iii matrix_ring.iii bv_ring.iii ring_opt.iii elias.iii bitio.iii bitops.iii' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'line', 'axis', 'doc_promise', 'code_actual', 'divergence_input', 'wrong_result', 'correct_result', 'reachable_export', 'has_kat', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
      axis: { type: 'string', enum: ['spec_incomplete', 'precision_loss', 'doc_vs_code'] },
      doc_promise: { type: 'string', description: 'quote the doc-comment text that promises the behavior/exactness' },
      code_actual: { type: 'string', description: 'what the code actually does that falls short' },
      divergence_input: { type: 'string', description: 'a concrete input where doc-promise != code-actual' },
      wrong_result: { type: 'string' }, correct_result: { type: 'string' },
      reachable_export: { type: 'boolean' }, has_kat: { type: 'boolean', description: 'is there a corpus KAT for this fn' },
      confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason'],
  properties: { is_real_defect: { type: 'boolean' }, reason: { type: 'string' }, proposed_teeth: { type: 'string' } },
}

const FIND_PROMPT = (g) => `You are auditing the III stdlib for two correctness axes (NOT corner-input crashes -- those are already swept):
Read these files in ${NUMERA}: ${g.files}

(A) spec_incomplete: an @export's DOC-COMMENT promises behavior the code only PARTIALLY implements -- it
   handles N documented cases but only does N-1, ignores a documented mode/flag, a documented parameter is read
   but not actually used, a documented range is not fully covered.  The doc says it does X; the code does less.
(B) precision_loss: a fixed-point / rational / modular / q128 computation LOSES PRECISION where the doc or the
   operation's contract implies EXACTNESS -- a divide-before-multiply that should be multiply-before-divide, an
   intermediate truncation that discards bits the result needs, a wrong rounding direction, a fixed-point op
   that drops the fractional part it documents keeping.  Give the concrete input where the result is wrong.
(C) doc_vs_code: the doc describes behavior X but the code clearly does a DIFFERENT Y (a real divergence -- one
   of them is wrong).  (Distinct from a stale numeric CONSTANT in a comment; this is a BEHAVIOR divergence.)

HARD GATES -- drop unless ALL hold:
 - a CONCRETE divergence input where the documented/exact result != the code's result (name both values).
 - reachable from an @export.
 - the DOC is the authority (for spec_incomplete/precision): if the doc is vague/aspirational and the code is a
   reasonable complete implementation, DROP.  If the "precision loss" is within a documented tolerance or the
   op is documented-approximate, DROP.
 - NOT already correct: trace the actual arithmetic; if the code IS exact / DOES implement the full spec, DROP.

This tree is meticulous (specs in DOCS/CONVERGENCE-SPECS, exact-arithmetic discipline, "no down-scale").  Most
code fully implements its spec exactly.  ZERO findings is an honest likely answer.  Only report a divergence
you traced by hand with the doc text + the concrete wrong-vs-correct values.  Return JSON.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const candidates = found.filter(Boolean).flat().filter(f => f.reachable_export && f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) (of ${found.filter(Boolean).flat().length} raw)`)
if (candidates.length === 0) {
  return { confirmed: [], note: 'no spec/precision divergence survived the self-gate; the numeric/math code fully implements its specs exactly' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier for a claimed SPEC-INCOMPLETENESS or PRECISION-LOSS defect in the III stdlib.

CLAIM: ${NUMERA}\\${c.file} ${c.fn} (line ~${c.line}) axis=${c.axis}
  doc promise: ${c.doc_promise}
  code actual: ${c.code_actual}
  divergence input: ${c.divergence_input} -> wrong ${c.wrong_result} vs correct ${c.correct_result}

Read the source + the doc-comment verbatim + grep ${CORPUS} for the fn.  Kills:
 (1) DOC STALE not code: is the code actually correct and the DOC vague/aspirational/wrong?  If the code is a
     complete correct impl and the doc just reads loosely, REFUTE (no code defect).
 (2) PRECISION INTENDED: is the "loss" within a documented tolerance, or is the op documented-approximate /
     fixed-width by design?  Trace whether the result is actually wrong for a REAL input or only in theory.
 (3) ALREADY EXACT / mis-read: re-derive the arithmetic by hand; if the code IS exact or DOES implement the
     full documented behavior, REFUTE.
 (4) UNREACHABLE / vacuous / already-tested.
 (5) the divergence input is out-of-domain (the doc scopes it out).

Default is_real_defect=FALSE unless it SURVIVES all.  If real, give the value-differential teeth a falsifier
KAT would assert (doc-correct result vs the code's wrong result).  Cite the doc text + source lines you traced.`,
    { label: `refute:${c.file}:${c.fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))
const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log(`Refute complete: ${confirmed.length} confirmed of ${candidates.length}`)
return {
  confirmed: confirmed.map(c => ({ file: c.file, fn: c.fn, line: c.line, axis: c.axis,
    doc_promise: c.doc_promise, code_actual: c.code_actual, divergence_input: c.divergence_input,
    wrong_result: c.wrong_result, correct_result: c.correct_result,
    proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
