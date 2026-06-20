export const meta = {
  name: 'iii-defect-discovery-w26-initorder2',
  description: 'Use-before-init round 2: precomputed-table cold reads + more field/curve to_mont gaps',
  phases: [
    { title: 'Discover', detail: 'precomputed-table + field/curve cold-call deep reads, read-only' },
    { title: 'Verify', detail: 'confirm with a concrete cold input -> wrong output' },
  ],
}

const FOCUS = [
  'FOCUS: USE-BEFORE-INIT -- an @export reads a module global/TABLE populated only by a separate init/',
  'build fn, with NO lazy-init guard, so a COLD call (before init, or fresh process) returns a WRONG value.',
  'W22 just fixed the Montgomery *_to_mont/_from_mont (read R^2 cold) + hotstuff (read HS_FAULT cold).  The',
  'EXEMPLAR PATTERN is a SIBLING GAP: some @exports in the module guard with *_init() / check an INITED',
  'flag, but a few peers FORGOT -- find the peers that forgot.  A finding is REAL only with a CONCRETE cold',
  'input + the WRONG output + the correct output, AND no lazy guard AND the corpus does not always init',
  'first.  TRACE the init/reset path before claiming cold-call (many modules lazy-init or always boot).',
  '',
  'DO NOT REPORT (already fixed/refuted): fp256/fn256/fp384/fn384 *_to_mont/_from_mont (W22 FIXED, now',
  'guarded), hotstuff hs_quorum_safety_verify/hs_verify_vote_count_bounds (W22 FIXED), fe25519 fz_invert',
  '(already guarded), bitw_bytelen (BIO_WPOS is buffer-bounded, no wrap), seal_resolver_byte (guarded line',
  '150), es_verify_shard (known, benign-valued OOB -- not init).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        defect_class: { type: 'string' }, description: { type: 'string' },
        init_fn: { type: 'string', description: 'the init/build fn that populates the global, and the guarded sibling that already calls it' },
        concrete_input: { type: 'string' }, wrong_output: { type: 'string' }, correct_output: { type: 'string' },
        is_export: { type: 'boolean' }, confidence: { type: 'number' },
      },
      required: ['file', 'fn', 'line', 'defect_class', 'description', 'init_fn', 'concrete_input', 'wrong_output', 'correct_output', 'is_export', 'confidence'],
    } },
  },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
    real: { type: 'boolean' }, traced_result: { type: 'string' }, correct_result: { type: 'string' },
    guarded_sibling: { type: 'string' }, fix: { type: 'string' }, refutation: { type: 'string' },
  },
  required: ['file', 'fn', 'line', 'real', 'refutation'],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'

const LENSES = [
  {
    key: 'precomputed-tables',
    prompt: 'Lens: PRECOMPUTED-TABLE cold reads in ' + REPO + '/STDLIB/iii/numera/.  Find @exports that read a ' +
      'precomputed lookup TABLE populated by a build/init fn -- GF(2^8) log/exp tables (galois.iii, rscode.iii, ' +
      'rscode_ec.iii, shamir.iii, erasure_store.iii), NTT twiddle factors (mldsa.iii), CRC tables (crc32.iii), ' +
      'AES sboxes/tables (aes*.iii), any *_TABLE / *_LOG / *_EXP / *_TWIDDLE / *_SBOX read by an @export with no ' +
      'lazy-init guard.  A cold call (table all-zero) returns a wrong value.  Confirm a guarded SIBLING exists ' +
      '(the build fn IS called by some other @export) and the cold @export forgot it.\n' + FOCUS,
  },
  {
    key: 'more-field-curve',
    prompt: 'Lens: MORE field/curve modules with the *_to_mont / *_inv init asymmetry in ' + REPO + '/STDLIB/iii/' +
      'numera/.  W22 fixed fp256/fn256/fp384/fn384.  Check OTHER prime-field / curve / scalar modules: any ' +
      'secp256k1, p224, p521, bls/bn curve, edwards/montgomery-curve, modular_mont.iii, q128.iii, barrett.iii, ' +
      'crt.iii -- do they have @export ops (to_mont, normalize, encode, reduce) that read an init-only constant ' +
      '(R^2, modulus, n-prime, a precomputed inverse) while a sibling op (inv) guards with *_init()?\n' + FOCUS,
  },
  {
    key: 'sibling-of-w22-fix',
    prompt: 'Lens: SIBLING-OF-RECENT-FIX for W22.  The W22 fix was *_to_mont/_from_mont (fp256/fn256/fp384/fn384) ' +
      '+ hotstuff.  (a) In those SAME modules, are there OTHER @exports reading the init-only R^2/modulus with no ' +
      'guard (e.g. a direct fp_mul_x / fp_add_x / fp_sub_x called cold, an encode/decode)?  (b) In hotstuff, are ' +
      'there OTHER @exports reading HS_* config without the HS_INITED check?  (c) Any module with an INITED flag ' +
      'where MOST @exports check it but one or two forgot.  Report confirmed cold-call gaps with a concrete input.\n' + FOCUS,
  },
]

phase('Discover')
log('W26 init-order-2 discovery: ' + LENSES.length + ' lenses (precomputed-tables + more-field-curve + sibling-of-w22)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III use-before-init defect by HAND-TRACING the code COLD (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nClass: ' + c.defect_class + '\n' +
  'Claim: ' + c.description + '\nInit fn / guarded sibling: ' + c.init_fn + '\nConcrete input: ' + c.concrete_input +
  '\nClaimed wrong (cold) output: ' + c.wrong_output + '\nClaimed correct output: ' + c.correct_output + '\n\n' +
  'Open the file, read ' + c.fn + ' + the init/build fn + a GUARDED sibling, and hand-execute COLD (the table/' +
  'global is BSS-zero).  Mark REAL only if: (1) @export; (2) it reads an init-only global/table with NO lazy ' +
  'guard; (3) a guarded sibling proves the init IS required (the module enforces init somewhere); (4) cold -> a ' +
  'WRONG value vs correct; (5) the corpus does not always init this module first in the SAME process before this ' +
  'call.  Show the cold hand-trace + the guarded sibling + the one-line fix (call the init fn at entry).  If the ' +
  'module lazy-inits, always boots, or the global is a compile-time constant, mark real=false + explain.\n' + FOCUS

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
log('W26 init-order-2 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
