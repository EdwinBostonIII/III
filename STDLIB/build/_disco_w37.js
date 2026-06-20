export const meta = {
  name: 'iii-w37-differential-divergence',
  description: 'W37: hunt corner inputs where a module\'s FAST/abstract path diverges from its own REFERENCE/exhaustive path that is documented to agree (the loop_optimizer interval-vs-affine fingerprint). The reference path is the oracle -> self-validating, near-zero FP. Adversarially refute each.',
  phases: [
    { title: 'Find', detail: 'per-group fast-vs-reference divergence scan over dual-path modules' },
    { title: 'Refute', detail: 'adversarially kill each candidate before reporting' },
  ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const IIIDIR = ROOT + '\\STDLIB\\iii'
const CORPUS = ROOT + '\\STDLIB\\corpus'

// Modules that ship a fast/abstract path AND a reference/exhaustive/naive path documented to agree
// (or a closed-form vs a scan). Paths are relative to STDLIB\iii.
const GROUPS = [
  { key: 'closed_form_vs_scan', files: 'numera/binary_search.iii numera/kmp.iii numera/lis.iii numera/sieve.iii numera/catalan.iii numera/inversion_count.iii numera/segment_tree.iii numera/gray_code.iii numera/collatz.iii numera/goldbach.iii numera/lcs.iii numera/levenshtein.iii numera/coin_change.iii numera/knapsack.iii' },
  { key: 'bigint_field_ref', files: 'numera/barrett.iii numera/bigint_div.iii numera/bigint_karatsuba.iii numera/gf_poly.iii numera/modular_mont.iii numera/fp256.iii numera/fn256.iii numera/fp384.iii numera/fn384.iii numera/field.iii numera/ed_scalar_modl.iii numera/scalar.iii numera/crt.iii numera/galois.iii' },
  { key: 'analysis_fast_vs_exhaustive', files: 'numera/value_range_prover.iii numera/range_check.iii numera/sov_isa.iii numera/typecheck.iii numera/branch_elim.iii numera/ccl.iii numera/combinator.iii numera/cost_calculus.iii numera/interval_lattice.iii numera/widening.iii numera/ptr_provenance.iii numera/affine_check.iii' },
  { key: 'egraph_proof_ref', files: 'numera/egraph.iii numera/egraph_stochastic.iii numera/relational_ematch.iii numera/groebner.iii numera/congruence_closure.iii numera/smt.iii numera/sat.iii numera/translation_validation.iii numera/proof_replay.iii numera/congruence.iii numera/kleene_fixpoint.iii' },
  { key: 'crypto_dispatch_vs_scalar', files: 'numera/sha256_dispatch.iii numera/sha256_ni.iii numera/cad.iii numera/merkle.iii numera/mldsa.iii numera/pq_dispatch.iii numera/keccak_sponge.iii numera/math_library.iii numera/cpufeat.iii' },
  { key: 'higher_layer_differential', files: 'aether/triple_check.iii aether/memo_query.iii omnia/proof_resolve.iii omnia/resolver.iii omnia/xii_canonicalise.iii omnia/xii_conf_cert.iii forcefield/scythe_census.iii forcefield/pleroma.iii forcefield/cg_autocatalyst.iii sanctus/sovereign_witness.iii nous/nous_charter.iii' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fast_fn', 'ref_fn', 'line', 'invariant', 'corner_input', 'fast_value', 'ref_value', 'which_is_correct', 'reachable_export', 'already_tested', 'confidence'],
    properties: {
      file: { type: 'string', description: 'relative path under STDLIB/iii' },
      fast_fn: { type: 'string', description: 'the fast/abstract path @export' },
      ref_fn: { type: 'string', description: 'the reference/exhaustive/naive path @export (the ORACLE)' },
      line: { type: 'number' },
      invariant: { type: 'string', description: 'the documented agreement, quoting the doc-comment line that promises fast==ref' },
      corner_input: { type: 'string' },
      fast_value: { type: 'string', description: 'what the fast path returns on the corner' },
      ref_value: { type: 'string', description: 'what the reference path returns on the corner' },
      which_is_correct: { type: 'string', enum: ['ref', 'fast', 'unsure'], description: 'which value is mathematically correct (usually ref -- the exhaustive scan)' },
      reachable_export: { type: 'boolean' },
      already_tested: { type: 'boolean' },
      confidence: { type: 'number' },
    },
  } } },
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason', 'refutation_attempted'],
  properties: {
    is_real_defect: { type: 'boolean' }, reason: { type: 'string' },
    refutation_attempted: { type: 'string' }, proposed_teeth: { type: 'string' },
  },
}

const FIND_PROMPT = (g) => `You are auditing the III self-hosted systems language for DIFFERENTIAL DIVERGENCE: a module ships a FAST/abstract path and a REFERENCE/exhaustive/naive path (or a closed-form and a scan) that its doc-comment promises AGREE, but they DIVERGE on some corner input. The reference path is the ORACLE, so a divergence is a self-certified WRONG VALUE in the fast path (occasionally in the reference path).
Read these files under ${IIIDIR}: ${g.files}

For EACH module:
 1. Identify the fast/abstract @export and the reference/exhaustive @export that are documented to agree. Quote
    the doc line that promises the agreement (e.g. "the closed-form max matches the exhaustive scan", "both
    analyses must agree", "equals the naive prefix", "the fast dispatch is bit-identical to the scalar ref").
 2. Probe CORNER inputs for fast != ref: 0, 1, empty (n=0), single element, all-same, max value, a boundary
    length, an unnormalized input, the additive/multiplicative identity. The recent real bug: loop_optimizer's
    interval path returned UNSAFE(0) for an empty loop while the affine reference returned SAFE(1).
 3. Report the corner, BOTH values, and which is correct (usually the exhaustive ref).

HARD GATES -- drop unless ALL hold:
 - reachable_export: BOTH paths (or a wrapper) are @export with caller-controllable input.
 - REAL DIVERGENCE with a WRONG VALUE: the two paths genuinely return different values on the corner AND one is
   mathematically wrong. Not "they return different sentinels that both encode the same meaning". Trace the
   actual arithmetic by hand.
 - NOT vacuous: a divergence only on an empty/contradictory premise that makes BOTH answers meaningless is
   vacuous. But a wrong COUNT/BOUND/VERDICT for an empty input (where the right answer is a definite 0/safe/etc,
   as the reference proves) is a REAL defect.
 - NOT the documented contract: read the doc; if the corner is explicitly out-of-domain for BOTH paths and
   neither promises anything, drop. already_tested=true if a corpus test asserts fast==ref on this corner.
 - concrete: name the exact corner and both exact values.

Most dual-path modules are CORRECT and their KATs check agreement on sampled inputs -- the bug, if any, is at
an UNSAMPLED corner (n=0, max, single element). Returning ZERO findings is a good honest answer. Only report a
divergence you traced by hand with both concrete values. Return JSON per schema.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))

const candidates = found.filter(Boolean).flat()
  .filter(f => f.reachable_export && !f.already_tested && f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) past self-gate (of ${found.filter(Boolean).flat().length} raw)`)

if (candidates.length === 0) {
  return { confirmed: [], note: 'no divergence survived the per-agent self-gate; the dual-path modules agree on the probed corners' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier. A prior agent claims a module's FAST path diverges from its own REFERENCE path on a corner input -- a self-certified wrong value. KILL it if you can.

CLAIM:
  file: ${IIIDIR}\\${c.file}
  fast: ${c.fast_fn}   reference (oracle): ${c.ref_fn}   (line ~${c.line})
  documented invariant: ${c.invariant}
  corner input: ${c.corner_input}
  fast returns: ${c.fast_value}   reference returns: ${c.ref_value}   claimed-correct: ${c.which_is_correct}

Read the ACTUAL source for BOTH functions and trace the arithmetic by hand on the corner. grep ${CORPUS} for both fn names. Try every kill:
 (1) Do the two paths REALLY return different values on this corner? Re-derive both by hand from the source. If
     they actually agree (the claim mis-traced), REFUTE.
 (2) Is the 'divergence' just two sentinels encoding the same meaning (e.g. both mean 'empty')? REFUTE.
 (3) Is the claimed-correct value actually correct? Verify the math independently. If the REFERENCE is the one
     that is wrong (or both are by-design), reconsider -- still possibly a defect but re-aim the teeth.
 (4) VACUOUS -- corner is an empty/contradictory premise making both answers meaningless? (A definite
     count/bound/verdict for an empty input is NOT vacuous.)
 (5) UNREACHABLE -- does every @export path validate the corner before the divergence?
 (6) DOCUMENTED out-of-domain / ALREADY TESTED?

Default is_real_defect=FALSE unless it SURVIVES all. If real, give the exact value-differential teeth (the
@export call, pre-fix vs post-fix return) a falsifier KAT asserts, using the reference path as the oracle. Cite
the source lines you traced.`,
    { label: `refute:${c.file}:${c.fast_fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))

const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log(`Refute complete: ${confirmed.length} confirmed of ${candidates.length}`)

return {
  confirmed: confirmed.map(c => ({
    file: c.file, fast_fn: c.fast_fn, ref_fn: c.ref_fn, line: c.line, invariant: c.invariant,
    corner_input: c.corner_input, fast_value: c.fast_value, ref_value: c.ref_value,
    which_is_correct: c.which_is_correct, proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason,
  })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, fast_fn: c.fast_fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
