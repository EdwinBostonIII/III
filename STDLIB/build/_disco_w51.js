export const meta = {
  name: 'iii-w51-errorstate-boundary',
  description: 'W51: two fresh axes -- (A) error-state-consistency (a state-mutating @export errors mid-operation leaving its module globals / output buffer HALF-written, so a subsequent @export read sees inconsistent/garbage data); (B) boundary-exactness (a documented bound -- correct exactly-t errors, optimal at exact capacity, exact at the limb/word boundary -- that fails AT the boundary). Adversarial refute.',
  phases: [ { title: 'Find' }, { title: 'Refute' } ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'codes_ecc', files: 'rscode.iii rscode_ec.iii hamming_secded.iii gf_poly.iii crc32.iii galois.iii' },
  { key: 'dp_optimal', files: 'coin_change.iii knapsack.iii lcs.iii lis.iii levenshtein.iii catalan.iii inversion_count.iii segment_tree.iii fenwick.iii' },
  { key: 'bigint_arith', files: 'bigint.iii bigint_div.iii bigint_karatsuba.iii barrett.iii modular.iii modular_mont.iii crt.iii scalar.iii' },
  { key: 'field_boundary', files: 'fp256.iii fn256.iii fp384.iii fn384.iii field.iii ed_scalar_modl.iii q128.iii fixed.iii fixed_extra.iii' },
  { key: 'state_mutating', files: 'interval_lattice.iii reduced_product.iii matrix_ring.iii bv_bits.iii bv_ring.iii temporal_logic.iii heaplet.iii ntt.iii ntt_ctx.iii' },
  { key: 'compress_struct', files: 'huffman.iii lzss.iii lzh.iii elias.iii bitio.iii builder.iii merkle.iii' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'line', 'axis', 'mechanism', 'trigger_input', 'wrong_observable', 'correct_observable', 'reachable_export', 'has_kat', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
      axis: { type: 'string', enum: ['error_state_halfwritten', 'boundary_exactness'] },
      mechanism: { type: 'string', description: 'error_state: which globals/output bytes are written before the error return, and how a later @export read exposes them. boundary: the exact boundary value where the documented bound fails.' },
      trigger_input: { type: 'string', description: 'the concrete reachable input' },
      wrong_observable: { type: 'string', description: 'what a subsequent @export read / the result returns (the wrong value)' },
      correct_observable: { type: 'string' },
      reachable_export: { type: 'boolean' }, has_kat: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason'],
  properties: { is_real_defect: { type: 'boolean' }, reason: { type: 'string' }, proposed_teeth: { type: 'string' } },
}

const FIND_PROMPT = (g) => `You are auditing the III stdlib for two fresh correctness axes:
Read these files in ${NUMERA}: ${g.files}

(A) error_state_halfwritten: a state-mutating @export (writes module-level var globals or a caller output
   buffer INCREMENTALLY) hits an error path AFTER partially writing, and RETURNS an error code -- but leaves the
   globals/buffer in a HALF-updated state.  A subsequent @export read (a getter, or the next op that reads those
   globals) then sees INCONSISTENT/STALE/garbage data instead of either the old consistent state or a clean
   error sentinel.  The defect is observable: read-after-failed-op returns wrong data.  (Distinct from a clean
   "compute-then-commit" or "validate-first" function.)
(B) boundary_exactness: a DOCUMENTED bound that fails exactly AT its boundary -- "corrects up to t errors" but
   miscorrects at exactly t; "optimal for capacity C" but wrong at exactly C; "exact for k-limb" but loses a bit
   at exactly k limbs; an inclusive-vs-exclusive off-by-one at the documented max.  Name the exact boundary
   value and the wrong-vs-correct result there.

HARD GATES -- drop unless ALL hold:
 - a CONCRETE reachable input/boundary with the exact wrong-vs-correct OBSERVABLE (via an @export).
 - reachable from an @export with caller-controllable input.
 - NOT already correct: trace by hand.  If the function validates-first (writes nothing on error) or
   commits-atomically, the error-state axis does NOT apply -> DROP.  If the boundary is handled (the bound is
   inclusive and the code uses <=, the t-error case is corrected), DROP.
 - NOT a clean error sentinel: returning a documented error code with UNCHANGED globals is correct, not a defect.

Most III functions validate-first or compute-into-temps-then-commit, and bounds are carefully inclusive.  ZERO
findings is honest.  Only report a half-state or boundary-failure you traced with the concrete observable.  Return JSON.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const candidates = found.filter(Boolean).flat().filter(f => f.reachable_export && f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) (of ${found.filter(Boolean).flat().length} raw)`)
if (candidates.length === 0) {
  return { confirmed: [], note: 'no error-state or boundary-exactness defect survived the self-gate; functions validate-first / commit-atomically and bounds are inclusive' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier for a claimed ERROR-STATE-HALFWRITTEN or BOUNDARY-EXACTNESS defect in the III stdlib.

CLAIM: ${c.file} ${c.fn} (line ~${c.line}) axis=${c.axis}
  mechanism: ${c.mechanism}
  trigger: ${c.trigger_input} -> wrong ${c.wrong_observable} vs correct ${c.correct_observable}

Read the source + grep ${CORPUS} for the fn.  Kills:
 (1) VALIDATE-FIRST: does the fn check all error conditions BEFORE writing any global/buffer?  If it writes
     nothing on the error path (or commits only at the end), the half-state cannot occur -> REFUTE.
 (2) CLEAN SENTINEL: does the error path leave globals UNCHANGED (old consistent state) or set a clear error
     marker?  A read-after-error seeing the OLD value (not garbage) is correct -> REFUTE.
 (3) BOUNDARY HANDLED: re-derive at the exact boundary; if the code's <= / >= / +1 handles it correctly,
     REFUTE.  Off-by-one claims must be traced to the actual comparison operator.
 (4) UNREACHABLE / out-of-contract / already-tested / mis-read.
Default is_real_defect=FALSE unless it SURVIVES all.  If real, give the value-differential teeth (the @export
read sequence that exposes the half-state, or the boundary KAT) pre-fix vs post-fix.  Cite source lines + KAT.`,
    { label: `refute:${c.file}:${c.fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))
const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log(`Refute complete: ${confirmed.length} confirmed of ${candidates.length}`)
return {
  confirmed: confirmed.map(c => ({ file: c.file, fn: c.fn, line: c.line, axis: c.axis, mechanism: c.mechanism,
    trigger_input: c.trigger_input, wrong_observable: c.wrong_observable, correct_observable: c.correct_observable,
    proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
