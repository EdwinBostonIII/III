export const meta = {
  name: 'iii-defect-discovery-w22-correctness',
  description: 'Deep correctness/contract audit of complex algorithms (not bounds) -- concrete wrong-output required',
  phases: [
    { title: 'Discover', detail: 'deep-read specific algorithm families for logic errors, read-only' },
    { title: 'Verify', detail: 'confirm each with a concrete input -> provably-wrong output' },
  ],
}

const FOCUS = [
  'FOCUS: this is a CORRECTNESS/CONTRACT audit, NOT a memory-safety/bounds audit (the @export accessor-',
  'bounds axis is already saturated -- do NOT report missing index guards).  Hunt for LOGIC errors that',
  'produce a WRONG RESULT for some reachable input: off-by-one in a loop/recurrence, a missing/incorrect',
  'final reduction or conditional subtract, a lost carry/borrow at the top limb, a wrong base case, an',
  'overflow that corrupts a value (not just an index), a contract the doc states but the code violates',
  '(like resolver_memo FIFO: "update keeps seq" but the code bumped it), a rewrite/fold that does NOT',
  'preserve semantics.  A finding is REAL only if you can name a SPECIFIC concrete input and the WRONG',
  'output it produces AND the correct expected output (computed independently).  Speculative "might be',
  'wrong" is NOT a finding.  Prefer bugs the existing KAT misses (shallow happy-path tests).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        defect_class: { type: 'string' }, description: { type: 'string' },
        concrete_input: { type: 'string', description: 'a specific reachable input' },
        wrong_output: { type: 'string', description: 'what the code produces' },
        correct_output: { type: 'string', description: 'the correct value, computed independently' },
        is_export: { type: 'boolean' }, confidence: { type: 'number' },
      },
      required: ['file', 'fn', 'line', 'defect_class', 'description', 'concrete_input', 'wrong_output', 'correct_output', 'is_export', 'confidence'],
    } },
  },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
    real: { type: 'boolean', description: 'true ONLY if you traced the code by hand on the concrete input and confirmed it produces the wrong output' },
    traced_result: { type: 'string', description: 'your hand-trace of the code on the concrete input -> the actual value it computes' },
    correct_result: { type: 'string' }, fix: { type: 'string' }, refutation: { type: 'string' },
  },
  required: ['file', 'fn', 'line', 'real', 'refutation'],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'

const LENSES = [
  {
    key: 'modular-arithmetic',
    prompt: 'Deep-read the MODULAR ARITHMETIC cores in ' + REPO + '/STDLIB/iii/numera/: modular_mont.iii ' +
      '(Montgomery reduction -- is the FINAL conditional subtract correct + sufficient for the full input ' +
      'range? a single subtract fails if the intermediate can reach 2*N), barrett.iii (Barrett reduction -- ' +
      'the estimate q and the at-most-2 correction subtracts), crt.iii (CRT reconstruction), and the modular ' +
      'ops in bigint.iii (mont_mul_bigint, modpow, modctx).  Verify reduction is correct for inputs NEAR the ' +
      'modulus and at the top of the range.\n' + FOCUS,
  },
  {
    key: 'bignum-carry',
    prompt: 'Deep-read the BIGNUM core in ' + REPO + '/STDLIB/iii/numera/bigint.iii: add/sub (carry/borrow ' +
      'propagation -- is the carry out of the TOP limb handled? is borrow correct when a<b?), mul (schoolbook ' +
      'partial-product accumulation + carry), shift left/right (bit spill across limbs), compare (length + ' +
      'limb order).  Also numera/scalar.iii 128-bit and numera/fixed.iii.  Find a concrete operand pair that ' +
      'produces a wrong sum/product/shift.\n' + FOCUS,
  },
  {
    key: 'crypto-final-reduction',
    prompt: 'Deep-read the field/curve/hash FINALIZATION in ' + REPO + '/STDLIB/iii/numera/: fe25519.iii ' +
      '(fz_freeze canonical reduction -- does it fully reduce a value in [P, 2P)? the carry chain), ' +
      'ed25519/the point ops (encode/decode canonicality), sha256/keccak/sha512 finalizers (padding length, ' +
      'the final block, big-endian length encoding), poly1305/the MAC reductions.  Find a concrete input whose ' +
      'digest/encoding is wrong vs the known-answer.\n' + FOCUS,
  },
  {
    key: 'rewrite-semantics',
    prompt: 'Deep-read the REWRITE/FOLD rules in ' + REPO + '/STDLIB/iii/ (omnia/xii_*, omnia/sov_*, ' +
      'numera/egraph.iii rules, the cost_lattice/strength-reduction folds in the compiler cg_r3): for each ' +
      'rewrite rule (a -> b), verify b is SEMANTICALLY EQUAL to a for ALL inputs (the classic bug: a fold ' +
      'correct for unsigned but applied to signed, or a strength-reduction valid only for power-of-two, or a ' +
      'simplification that drops an overflow/edge case).  Find a rule + a concrete input where the rewrite ' +
      'changes the result.\n' + FOCUS,
  },
  {
    key: 'recurrence-offbyone',
    prompt: 'Deep-read RECURRENCE / DP / TRANSFORM loops in ' + REPO + '/STDLIB/iii/numera/: ntt/fft (mldsa.iii ' +
      'NTT butterflies -- twiddle indices, bit-reversal, the inverse scaling), the LTL evaluator in ' +
      'temporal_logic.iii (the until/globally/eventually backward recurrences -- base case at len-1, the ' +
      'q+1 reads), reed-solomon rscode/rscode_ec (syndrome + error-locator), huffman/lzss (already partly ' +
      'audited -- focus on the canonical-code assignment + the decode tie-breaks).  Find a concrete input ' +
      'where an off-by-one or wrong base case yields the wrong result.\n' + FOCUS,
  },
]

phase('Discover')
log('W22 correctness discovery: ' + LENSES.length + ' deep-read lenses (modular/bignum/crypto/rewrite/recurrence)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III CORRECTNESS defect by HAND-TRACING the code on the concrete input (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nClass: ' + c.defect_class + '\n' +
  'Claim: ' + c.description + '\nConcrete input: ' + c.concrete_input + '\nClaimed wrong output: ' + c.wrong_output +
  '\nClaimed correct output: ' + c.correct_output + '\n\n' +
  'Open the file, read ' + c.fn + ' (and its callees) in full, and HAND-EXECUTE the code step by step on the ' +
  'concrete input. Mark REAL only if: (1) the input is reachable through an @export or a real call path; ' +
  '(2) your hand-trace shows the code computes a value DIFFERENT from the independently-correct answer; ' +
  '(3) it is a genuine LOGIC error, not a documented approximation/domain restriction. Show your hand-trace ' +
  '(the actual computed value) and the correct value. If the code is actually CORRECT (your trace matches the ' +
  'correct answer), mark real=false and explain where the claim went wrong.\n' + FOCUS

const perLens = await pipeline(
  LENSES,
  (lens) => agent(lens.prompt, { label: 'discover:' + lens.key, phase: 'Discover', schema: FINDINGS_SCHEMA, agentType: 'Explore' }),
  (found, lens) => {
    const cands = (found && found.candidates) ? found.candidates : []
    log('lens ' + lens.key + ': ' + cands.length + ' candidate(s)')
    return parallel(cands.map((c) => () =>
      agent(refutePrompt(c), { label: 'verify:' + c.fn, phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
    ))
  }
)

const flat = perLens.flat().filter(Boolean)
const confirmed = flat.filter((v) => v.real === true)
log('W22 correctness discovery complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
