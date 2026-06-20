export const meta = {
  name: 'iii-w35-oracle-discovery',
  description: 'W35: find corner-input correctness defects in the III numerics core via algebraic-law / round-trip oracles, overflow-before-use, and unenforced documented preconditions; adversarially refute each before reporting',
  phases: [
    { title: 'Find', detail: 'per-group law/oracle + fingerprint scan over numera' },
    { title: 'Refute', detail: 'adversarially try to kill each candidate (contract / vacuity / reachability)' },
  ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const CORPUS = ROOT + '\\STDLIB\\corpus'

// Concrete file partitions of the numera math/crypto core (highest-value oracle targets).
const GROUPS = [
  { key: 'asym_crypto', files: 'rsa.iii ec256.iii ec384.iii ecdsa_p256.iii ecdsa_p384.iii crypt_ed25519.iii ed_scalar_modl.iii x25519.iii fe25519.iii shamir.iii threshold_vault.iii' },
  { key: 'pq_crypto', files: 'mldsa.iii mlkem.iii slhdsa.iii pq_dispatch.iii pq_params.iii' },
  { key: 'bigint_field', files: 'bigint.iii bigint_div.iii bigint_karatsuba.iii barrett.iii modular.iii modular_mont.iii fp256.iii fp384.iii fn256.iii fn384.iii field.iii field_crystal.iii galois.iii gf_poly.iii scalar.iii crt.iii congruence.iii q128.iii q128_f64.iii' },
  { key: 'ntt_zk', files: 'ntt.iii ntt_bigint.iii ntt_ctx.iii ntt_fri_organ.iii zk_field.iii zk_air.iii zk_stark.iii zk_snark.iii merkle.iii reduced_product.iii' },
  { key: 'codes', files: 'rscode.iii rscode_ec.iii hamming_secded.iii gf_poly.iii bv_bits.iii bv_ring.iii bv_commons.iii hex.iii endian.iii elias.iii bitio.iii bitops.iii crc32.iii' },
  { key: 'dp_algo', files: 'coin_change.iii knapsack.iii lcs.iii lis.iii levenshtein.iii kmp.iii binary_search.iii segment_tree.iii fenwick.iii inversion_count.iii catalan.iii gray_code.iii sieve.iii fixed.iii fixed_extra.iii math_library.iii matrix_ring.iii checked.iii rms.iii uncertainty.iii' },
]

const FIND_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['file', 'fn', 'line', 'angle', 'law_or_fingerprint', 'corner_input', 'expected', 'actual_buggy', 'reachable_export', 'already_tested', 'confidence'],
        properties: {
          file: { type: 'string' },
          fn: { type: 'string', description: 'the @export function name' },
          line: { type: 'number' },
          angle: { type: 'string', enum: ['law_or_roundtrip', 'overflow_before_use', 'unenforced_precondition'] },
          law_or_fingerprint: { type: 'string', description: 'the concrete algebraic law (e.g. from_mont(to_mont(x))==x mod p) OR the exact buggy expression (e.g. cap*8 unchecked feeding alloc len)' },
          corner_input: { type: 'string', description: 'the specific input that triggers the defect: 0, 1, p-1, 2^k, a non-coprime pair, etc.' },
          expected: { type: 'string' },
          actual_buggy: { type: 'string', description: 'what the code actually does on that input' },
          reachable_export: { type: 'boolean', description: 'true only if an @export reaches this code path with attacker/caller-controllable input' },
          already_tested: { type: 'boolean', description: 'true if a corpus/*.iii already asserts this exact law on this corner input (you grepped corpus)' },
          confidence: { type: 'number', description: '0..1 that this is a REAL defect, not a contract/vacuity' },
        },
      },
    },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['is_real_defect', 'reason', 'refutation_attempted'],
  properties: {
    is_real_defect: { type: 'boolean' },
    reason: { type: 'string', description: 'why it survives or is refuted: cite the doc-comment / existing corpus / data domain' },
    refutation_attempted: { type: 'string', description: 'the concrete kill you tried (is it the documented contract? vacuous on empty? unreachable? already-tested?)' },
    proposed_teeth: { type: 'string', description: 'if real: the value-differential the falsifier KAT should assert (pre-fix vs post-fix return codes)' },
  },
}

const FIND_PROMPT = (g) => `You are auditing the III self-hosted systems language numerics core for REAL corner-input correctness defects.
Read these files in ${NUMERA}: ${g.files}

For each @export function, look for defects on THREE angles ONLY (skip everything else):

(A) law_or_roundtrip: a documented or mathematically-required algebraic law / round-trip identity that BREAKS on a corner input. Examples: from_mont(to_mont(x))!=x at x=p-1; decode(encode(v))!=v at v=0 or v=max; add commutativity a+b!=b+a under a wrap bug; (a*b)%p wrong at a=b=p-1; an inverse fn returning a wrong value at the group identity. The law must be one the function PROMISES (by doc or by name). Corner inputs to probe: 0, 1, p-1, 2^k-1, max-u32/u64, a non-coprime pair (for crt/inverse), an unnormalized limb.

(B) overflow_before_use: an integer multiply or left-shift whose result feeds an allocation LENGTH or an array INDEX, with no prior bound check, so a large (but in-range-for-the-type-argument) input wraps -> a too-small alloc or a wrapped index -> OOB/wrong. This is the sibling pattern of two confirmed fixes: bigint 'cap*8' and temporal 's*4096'. Find the EXACT expression and the @export that reaches it.

(C) unenforced_precondition: a doc-comment states a precondition (a numeric range, coprimality, non-zero, sorted, normalized, power-of-two ALREADY DONE so skip pow2) that the code READS but does not ENFORCE, producing a wrong value or OOB when violated by a reachable caller.

HARD GATES — a candidate is INVALID and must be dropped unless ALL hold:
 - reachable_export: a real @export carries caller-controllable input to the defect. If it's an internal helper only ever called with safe args, DROP.
 - NOT vacuous: a wrong result for an EMPTY / contradictory / sentinel premise (e.g. hi(0,odd)=0 empty-set sentinel) is vacuously correct -> DROP.
 - NOT the documented contract: grep ${CORPUS} for the fn name AND read the fn's own doc-comment. If the "wrong" behavior is the PROMISED behavior (e.g. idempotent-drop returns 1 by contract), DROP. Set already_tested=true if a corpus test already asserts the exact law on the exact corner.
 - concrete: you must name the exact corner_input and the exact expected-vs-actual. No vague "might overflow".

Be skeptical and precise. Returning ZERO findings for your group is a perfectly good, honest answer — most functions are correct. Only report what you can defend with a specific input and a specific wrong output. Return JSON per the schema.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))

const candidates = found.filter(Boolean).flat()
  .filter(f => f.reachable_export && !f.already_tested && f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) past the self-gate (of ${found.filter(Boolean).flat().length} raw)`)

if (candidates.length === 0) {
  return { candidates: [], confirmed: [], note: 'no candidates survived the per-agent self-gate; numerics core appears law-clean on the probed corners' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`You are an adversarial verifier. A prior agent claims this is a REAL corner-input defect in the III numerics core. Your job is to KILL it if you can.

CLAIM:
  file: ${NUMERA}\\${c.file}
  fn: ${c.fn}  (line ~${c.line})
  angle: ${c.angle}
  law/fingerprint: ${c.law_or_fingerprint}
  corner input: ${c.corner_input}
  expected: ${c.expected}
  claimed buggy actual: ${c.actual_buggy}

Read the ACTUAL source at that file (and the fn's doc-comment), and grep ${CORPUS} for the fn name. Try every refutation:
 (1) Is the "buggy" output actually the DOCUMENTED contract / a deliberate sentinel? Read the doc-comment verbatim.
 (2) Is it VACUOUS — wrong only for an empty/contradictory/sentinel premise that no real caller supplies meaningfully?
 (3) Is it UNREACHABLE — does every @export path clamp/validate the input before it reaches this code?
 (4) Is it ALREADY TESTED — does a corpus test already assert this exact law on this exact corner?
 (5) Does the claimed law even HOLD mathematically? (e.g. the function may not promise commutativity at all.)

Default to is_real_defect=FALSE unless the defect SURVIVES all five. If real, give the exact value-differential teeth (pre-fix return vs post-fix return) a falsifier KAT would assert. Be honest and concrete — cite the source line or doc text you relied on.`,
    { label: `refute:${c.file}:${c.fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))

const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log(`Refute complete: ${confirmed.length} confirmed of ${candidates.length} candidates`)

return {
  confirmed: confirmed.map(c => ({
    file: c.file, fn: c.fn, line: c.line, angle: c.angle,
    law_or_fingerprint: c.law_or_fingerprint, corner_input: c.corner_input,
    expected: c.expected, actual_buggy: c.actual_buggy,
    proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason,
  })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null verdict' })),
}
