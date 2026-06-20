export const meta = {
  name: 'iii-defect-discovery-w25-initorder',
  description: 'Use-before-init / cold-call + counter-overflow + cross-module arg-mismatch -- wrong RESULT, refuted',
  phases: [
    { title: 'Discover', detail: 'init-order / overflow / arg-mismatch deep reads, read-only' },
    { title: 'Verify', detail: 'confirm with a concrete cold/overflow input -> wrong output' },
  ],
}

const FOCUS = [
  'FOCUS: a fn that returns a WRONG RESULT (not a crash, not an OOB) for a reachable input.  Three classes:',
  '(1) USE-BEFORE-INIT / COLD-CALL: an @export reads a module global/table that is ONLY populated by a',
  '    SEPARATE init/setup function; called COLD (before init, or after a reset that did not re-populate),',
  '    it returns a wrong/zero/garbage value instead of a correct one OR a lazy-init.  EXEMPLAR: fe25519',
  '    fz_invert read FZ_PM2 (the ladder exponent) which was set only by fe25519_init -> wrong cold result;',
  '    fix = a lazy _fz_ensure_init guard.  Find @exports that depend on an init-only global with no lazy',
  '    guard and no documented "must call init first" that the corpus actually enforces.',
  '(2) COUNTER / SIZE OVERFLOW: a u32/u64 counter, length, or size accumulator that can WRAP for a reachable',
  '    input and then feeds a wrong length/count/offset (NOT an array index OOB -- a wrong VALUE).  EXEMPLAR:',
  '    bitw_bytelen computed (bits+7)/8 in u32 and wrapped.',
  '(3) CROSS-MODULE ARG MISMATCH: a caller passes a value the callee interprets as a DIFFERENT thing (a raw',
  '    number where a HANDLE is expected, bytes where an id is expected), yielding a wrong result.  EXEMPLAR:',
  '    gb_begin got a raw modulus where a bigint HANDLE was expected.',
  'A finding is REAL only with a CONCRETE reachable input + the WRONG output + the correct output.  NOT a',
  'crash/OOB (those axes are mined).  Trace any init/reset path before claiming cold-call (many modules',
  'lazy-init or the corpus always inits first).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        defect_class: { type: 'string' }, description: { type: 'string' },
        concrete_input: { type: 'string' }, wrong_output: { type: 'string' }, correct_output: { type: 'string' },
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
    real: { type: 'boolean' }, traced_result: { type: 'string' }, correct_result: { type: 'string' },
    fix: { type: 'string' }, refutation: { type: 'string' },
  },
  required: ['file', 'fn', 'line', 'real', 'refutation'],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'

const LENSES = [
  {
    key: 'use-before-init-numera',
    prompt: 'Lens: USE-BEFORE-INIT / cold-call (class 1) in ' + REPO + '/STDLIB/iii/numera/ + ' + REPO +
      '/STDLIB/iii/omnia/.  Find @exports that read a module global/table populated only by a separate init/' +
      'setup/build fn, with NO lazy-init guard, such that a COLD call (or a call after reset without re-init) ' +
      'returns a wrong value.  Look for: precomputed tables (twiddles, inverses, exponents, lookup tables), ' +
      '"_init"/"_setup"/"_build" fns that populate a global the @exports then read.  Trace whether the corpus ' +
      'always inits first AND whether there is a lazy guard.\n' + FOCUS,
  },
  {
    key: 'use-before-init-aether-sanctus',
    prompt: 'Lens: USE-BEFORE-INIT / cold-call (class 1) in ' + REPO + '/STDLIB/iii/aether/ + ' + REPO +
      '/STDLIB/iii/sanctus/ + ' + REPO + '/STDLIB/iii/forcefield/.  Same pattern: an @export reads an init-only ' +
      'global/table with no lazy guard -> wrong cold result.  Federation/seal/witness/forcefield modules often ' +
      'have an init that seeds keys/tables/roots.\n' + FOCUS,
  },
  {
    key: 'counter-size-overflow',
    prompt: 'Lens: COUNTER/SIZE OVERFLOW (class 2) across ' + REPO + '/STDLIB/iii/.  Find @export-reachable ' +
      'computations of a length/count/size/offset (NOT an array index) that can WRAP a u32/u64 for a reachable ' +
      'input -- (n+k)/d, n*stride, sum of counts, bit-to-byte (bits+7)/8, a running total -- and then the ' +
      'wrapped value is returned or used as a length/count.  EXEMPLAR: bitw_bytelen.  Read the function to ' +
      'confirm the wrap is reachable + observable as a wrong value.\n' + FOCUS,
  },
  {
    key: 'cross-module-arg-mismatch',
    prompt: 'Lens: CROSS-MODULE ARG MISMATCH (class 3) in ' + REPO + '/STDLIB/iii/.  Find an @export whose ' +
      'parameter is a HANDLE/slot-id/index but a real call site (corpus or another module) passes a RAW value ' +
      '(a literal number, a modulus, a byte count) -- or vice versa -- so the callee mis-interprets it and ' +
      'returns a wrong result.  EXEMPLAR: gb_begin expected a bigint HANDLE but got a raw prime.  Look for ' +
      'extern decls + their call sites where the argument TYPE/MEANING is suspicious.\n' + FOCUS,
  },
]

phase('Discover')
log('W25 init-order/overflow/arg-mismatch discovery: ' + LENSES.length + ' lenses')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III wrong-RESULT defect by HAND-TRACING the code on the concrete input (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nClass: ' + c.defect_class + '\n' +
  'Claim: ' + c.description + '\nConcrete input: ' + c.concrete_input + '\nClaimed wrong output: ' + c.wrong_output +
  '\nClaimed correct output: ' + c.correct_output + '\n\n' +
  'Open the file, read ' + c.fn + ' + its callees + the init/reset paths in full, and HAND-EXECUTE on the input. ' +
  'Mark REAL only if: (1) reachable via @export; (2) for cold-call: there is NO lazy-init guard AND the corpus ' +
  'does not always init first (trace it); (3) your hand-trace shows a WRONG value vs the correct one; (4) it is ' +
  'a genuine wrong-result, not a documented precondition the callers honor. Show your hand-trace + correct value + ' +
  'fix. If the code is correct (lazy-init exists, or init is always called, or no wrap), mark real=false + explain.\n' + FOCUS

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
log('W25 discovery complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
