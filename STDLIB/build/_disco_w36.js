export const meta = {
  name: 'iii-w36-oracle-discovery-2',
  description: 'W36: extend the law/oracle discovery to the numera groups W35 did NOT cover (symmetric crypto, compiler-opt, proof-logic, deeper codes/misc) + a sharpened same-function-asymmetry lens (the rp_count fingerprint); adversarially refute each',
  phases: [
    { title: 'Find', detail: 'per-group oracle + asymmetry + overflow scan over the W35-uncovered numera' },
    { title: 'Refute', detail: 'adversarially kill each candidate before reporting' },
  ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const CORPUS = ROOT + '\\STDLIB\\corpus'

// Groups NOT covered by W35 (W35 did: asym crypto, pq, bigint/field, ntt/zk, codes-subset, dp/algo-subset).
const GROUPS = [
  { key: 'sym_crypto', files: 'aes.iii aes_gcm.iii aes_siv.iii chacha20.iii chacha20_poly1305.iii xchacha20_poly1305.iii poly1305.iii keccak.iii keccak_sponge.iii keccak256.iii sha256.iii sha256_dispatch.iii sha512.iii sha3_256.iii sha3_512.iii shake128.iii shake256.iii blake2s.iii hmac.iii hkdf.iii pbkdf2.iii drbg.iii crc32.iii murmur3.iii xoshiro.iii' },
  { key: 'compiler_opt_a', files: 'sccp.iii gvn.iii dce.iii ssa.iii reg_alloc.iii isel.iii liveness.iii dominators.iii loop_bounds_prover.iii loop_optimizer.iii loop_pipeline.iii list_schedule.iii branch_elim.iii branch_anchor.iii' },
  { key: 'compiler_opt_b', files: 'vectorizer.iii ring_opt.iii cost_calculus.iii cost_lattice.iii cost_lattice_synth.iii cost_lattice_unified.iii range_check.iii value_range_prover.iii widening.iii interval_lattice.iii sov_isa.iii sov_pipeline.iii microarch_model.iii reg_alloc.iii' },
  { key: 'proof_logic_a', files: 'smt.iii sat.iii sat_arith.iii sat_at_scale.iii bmc.iii kinduction.iii induct.iii congruence_closure.iii groebner.iii safety_prover.iii safety_type.iii value_range_prover.iii' },
  { key: 'proof_logic_b', files: 'egraph.iii egraph_stochastic.iii mcmc_egraph.iii relational_ematch.iii sep_logic.iii temporal_logic.iii proof_carrying.iii proof_replay.iii proof_term.iii theorem_carrier.iii theorem_commons.iii translation_validation.iii certified_morphism.iii curry_howard.iii' },
  { key: 'codes_misc', files: 'lzss.iii lzh.iii huffman.iii elias.iii hamming_secded.iii rscode.iii rscode_ec.iii galois.iii bv_ring.iii bv_commons.iii heaplet.iii fenwick.iii segment_tree.iii inversion_count.iii binary_search.iii kmp.iii lcs.iii lis.iii levenshtein.iii coin_change.iii knapsack.iii catalan.iii gray_code.iii sieve.iii collatz.iii goldbach.iii' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'line', 'angle', 'law_or_fingerprint', 'corner_input', 'expected', 'actual_buggy', 'reachable_export', 'already_tested', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
      angle: { type: 'string', enum: ['same_function_asymmetry', 'law_or_roundtrip', 'overflow_before_use', 'unenforced_precondition'] },
      law_or_fingerprint: { type: 'string', description: 'for asymmetry: name BOTH branches/modes -- the guarded one (cite line) and the parallel UNguarded one. else: the law or buggy expr.' },
      corner_input: { type: 'string' }, expected: { type: 'string' }, actual_buggy: { type: 'string' },
      reachable_export: { type: 'boolean' }, already_tested: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason', 'refutation_attempted'],
  properties: {
    is_real_defect: { type: 'boolean' },
    reason: { type: 'string' }, refutation_attempted: { type: 'string' },
    proposed_teeth: { type: 'string' },
  },
}

const FIND_PROMPT = (g) => `You are auditing the III self-hosted systems language numerics core for REAL corner-input correctness defects that produce a WRONG COMPUTED VALUE (not merely a missing defensive return code).
Read these files in ${NUMERA}: ${g.files}

Look for defects on these angles ONLY:

(0) same_function_asymmetry (HIGHEST PRIORITY -- this is the W35 fingerprint that found a real bug):
   a function that guards/clamps a condition in ONE branch / mode / loop, but a PARALLEL branch / mode / loop
   in the SAME function does NOT, so a corner input that the guarded path handles correctly is mishandled by
   the unguarded path -> wrong value or OOB.  Example just found: rp_count's RP_EVEN/RP_ODD modes collapse an
   empty interval [lo>hi] to 0 via an 'rlo>rhi' guard, but its RP_ANY mode computes (hi-lo)+1 unguarded and
   wraps to ~4.29e9.  You MUST cite BOTH the guarded branch (with line) and the unguarded parallel branch.

(A) law_or_roundtrip: a documented/required algebraic law or round-trip identity (encode/decode, compress/
   decompress, a+b==b+a, associativity, an inverse at the identity, idempotence) that BREAKS on a corner
   input: 0, 1, empty, max, an all-same input, a single element, a boundary length.

(B) overflow_before_use: a multiply/shift feeding an alloc LENGTH or array INDEX, unchecked, so a large arg
   wraps -> too-small alloc / wrapped index. (siblings of bigint cap*8 and temporal s*4096.)

(C) unenforced_precondition: a doc-stated precondition the code READS but does not ENFORCE, producing a wrong
   value (NOT just an OOB that needs a defensive guard) when a reachable caller violates it. SKIP power-of-2
   (already done in W30-34).

HARD GATES -- drop a candidate unless ALL hold:
 - reachable_export: a real @export carries caller-controllable input to the defect.
 - WRONG VALUE, not contract-only: the function must produce an incorrect COMPUTED result on the corner. If
   the only possible fix is adding a defensive 'return error' with no wrong-value differential, DROP -- that is
   hardening, not a defect (this is why fenwick-style OOB-on-out-of-domain candidates were correctly refuted).
 - NOT vacuous: a wrong result for an EMPTY/contradictory/sentinel premise (e.g. a 'for all x in {}' verdict)
   is vacuously correct -> DROP. A wrong COUNT/CARDINALITY of an empty set is NOT vacuous (it is a definite 0).
 - NOT the documented contract: grep ${CORPUS} for the fn name AND read its doc-comment. If the 'wrong'
   behavior is the PROMISED behavior, DROP. already_tested=true if a corpus test asserts the exact law/corner.
 - concrete: name the exact corner_input and exact expected-vs-actual.

Returning ZERO findings is a perfectly good honest answer -- most functions are correct and heavily KAT'd
(esp. symmetric crypto with FIPS vectors). Only report what you can defend with a specific input + specific
wrong output + (for asymmetry) the two named branches. Return JSON per schema.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))

const candidates = found.filter(Boolean).flat()
  .filter(f => f.reachable_export && !f.already_tested && f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) past self-gate (of ${found.filter(Boolean).flat().length} raw)`)

if (candidates.length === 0) {
  return { confirmed: [], note: 'no candidates survived the per-agent self-gate; the W36-uncovered numera groups appear law-clean on probed corners' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier. A prior agent claims a REAL corner-input WRONG-VALUE defect in the III numerics core. KILL it if you can.

CLAIM:
  file: ${NUMERA}\\${c.file}
  fn: ${c.fn}  (line ~${c.line})
  angle: ${c.angle}
  fingerprint/law: ${c.law_or_fingerprint}
  corner input: ${c.corner_input}
  expected: ${c.expected}
  claimed buggy actual: ${c.actual_buggy}

Read the ACTUAL source (and the fn's doc-comment); grep ${CORPUS} for the fn name. Try every kill:
 (1) Is the 'buggy' output the DOCUMENTED contract / a deliberate sentinel? Quote the doc.
 (2) CONTRACT-ONLY? Is the only fix a defensive 'return error' with NO wrong-COMPUTED-value differential? If
     the corner just reads adjacent BSS / returns a code but computes no incorrect arithmetic result, it is
     hardening not a defect -> REFUTE. (This is the fenwick-class kill.)
 (3) VACUOUS -- wrong only for an empty/contradictory premise that yields a vacuously-correct verdict?
     (But a wrong CARDINALITY of an empty set is a real defect, not vacuous.)
 (4) UNREACHABLE -- does every @export path clamp/validate before the defect?
 (5) ALREADY TESTED -- does a corpus test assert this exact law/corner?
 (6) For same_function_asymmetry: does the 'guarded' branch REALLY guard what the claim says, and is the
     'unguarded' branch REALLY reachable with the same corner? Verify both halves in source.

Default is_real_defect=FALSE unless it SURVIVES all. If real, give the exact value-differential teeth (pre-fix
return vs post-fix return) a falsifier KAT asserts. Cite the source line / doc text you relied on.`,
    { label: `refute:${c.file}:${c.fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))

const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log(`Refute complete: ${confirmed.length} confirmed of ${candidates.length}`)

return {
  confirmed: confirmed.map(c => ({
    file: c.file, fn: c.fn, line: c.line, angle: c.angle,
    law_or_fingerprint: c.law_or_fingerprint, corner_input: c.corner_input,
    expected: c.expected, actual_buggy: c.actual_buggy,
    proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason,
  })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
