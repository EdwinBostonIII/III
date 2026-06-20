export const meta = {
  name: 'iii-defect-discovery-w35',
  description: 'Un-tried axes: stale-buffer-reuse, cross-module init-order, narrow-int (u8/u16) truncation in length/count',
  phases: [
    { title: 'Discover', detail: '3 fresh lenses, read-only' },
    { title: 'Verify', detail: 'confirm + reachable + contract-check + clean teeth' },
  ],
}

const FOCUS = [
  'CONTEXT: ~22 lens axes mined over waves 10-28 (~27 fixes).  The last rounds (W31/W33/W34) were dry, but',
  'W32 (a fresh axis) still found 2 -- so the supply is thinning, NOT gone.  These are 3 GENUINELY UN-TRIED',
  'axes.  A finding is REAL only with: (1) an @export entry; (2) a CONCRETE input/sequence REACHABLE via the',
  'public API (set reachable_via_api=true only then -- no fault-injecting private state, the W31 mistake);',
  '(3) the WRONG observable; (4) you TRACED it; (5) you NAMED any existing corpus test / in-tree caller (a',
  'contract test may make the behavior DELIBERATE); (6) a falsifier that reddens pre-fix / passes post-fix.',
  '',
  'DO NOT REPORT (covered/declined): all wave 10-28 fixes; the declined set (es_reconstruct, tempaloc cluster,',
  'option_u64_drop idempotent, error-swallow trio, pattern_template_set_id, mldsa NULL, ident_copy must-not-',
  'alias).  governance state machine is now COMPLETE (every state-changer gates GOV_STATUS) -- do not re-flag.',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        axis: { type: 'string', description: 'stale-buffer | cross-module-init | narrow-int-truncation' },
        description: { type: 'string' },
        reachable_sequence: { type: 'string' },
        concrete_input: { type: 'string' }, wrong_output: { type: 'string' }, correct_output: { type: 'string' },
        existing_test_or_caller: { type: 'string' }, is_export: { type: 'boolean' }, confidence: { type: 'number' },
      },
      required: ['file', 'fn', 'line', 'axis', 'description', 'reachable_sequence', 'concrete_input', 'wrong_output', 'correct_output', 'existing_test_or_caller', 'is_export', 'confidence'],
    } },
  },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
    real: { type: 'boolean' }, reachable_via_api: { type: 'boolean' },
    traced_result: { type: 'string' }, correct_result: { type: 'string' },
    contract_check: { type: 'string' }, teeth_idea: { type: 'string' }, fix: { type: 'string' }, refutation: { type: 'string' },
  },
  required: ['file', 'fn', 'line', 'real', 'reachable_via_api', 'refutation'],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const ROOT = REPO + '/STDLIB/iii/'

const LENSES = [
  {
    key: 'stale-buffer',
    prompt: 'Lens: STALE SHARED-BUFFER REUSE across ' + ROOT + '.  Find an @export that writes a RESULT into a ' +
      'MODULE-GLOBAL scratch/output buffer (a *_OUT / *_BUF / *_TMP / *_SCRATCH / a fixed result array) but only ' +
      'PARTIALLY fills it on some input (a short input, an early return, a smaller count than last call), leaving ' +
      'STALE bytes from a PREVIOUS call in the unwritten tail -- and then returns/exposes the whole buffer, so a ' +
      'second call with a SHORTER input leaks the first call`s trailing data into the result.  Reachable: call A ' +
      '(long) then call B (short) via @export, read B`s output, see A`s stale tail.  Trace the two-call sequence ' +
      'and the leaked bytes.  (NOT a buffer that is fully cleared/overwritten each call.)\n' + FOCUS,
  },
  {
    key: 'cross-module-init',
    prompt: 'Lens: CROSS-MODULE INIT-ORDER across ' + ROOT + ' (the use-before-init class, but ACROSS modules).  ' +
      'Find an @export in module A that depends on module B being initialised (B has an explicit *_init/_boot ' +
      'that populates a B-global) but A neither calls B`s init NOR is guaranteed B was booted -- so a COLD call ' +
      'to A (fresh process, A called before any B-booting @export) reads B`s un-init state and returns a WRONG ' +
      'value.  Distinguish from same-module use-before-init (W22/W23, done) -- this is A-reads-B-uninit.  Confirm ' +
      'B`s init is NOT lazy and A has no guard, and that a cold A-first call is reachable.  Trace the cold ' +
      'cross-module sequence and the wrong value.\n' + FOCUS,
  },
  {
    key: 'narrow-int-truncation',
    prompt: 'Lens: NARROW-INT (u8/u16) TRUNCATION in a length/count/index across ' + ROOT + '.  Find an @export ' +
      'that stores or passes a length/count/index/id through a u8 or u16 (or masks with & 0xFF / & 0xFFFF) where ' +
      'the real value can EXCEED 255 / 65535 -- so the high bits are LOST and a large value wraps to a small one, ' +
      'used as a loop bound, size, or slot -> wrong result / under-copy / wrong slot.  Especially length fields ' +
      'packed into a byte, counts cast `as u8`, indices masked to 8/16 bits.  Trace a concrete value > the narrow ' +
      'max and the truncated result.  (iiis: `x as u8` keeps the low 8 bits; `& 0xFFu64` masks to 8 bits.)\n' + FOCUS,
  },
]

phase('Discover')
log('W35 discovery: ' + LENSES.length + ' lenses (stale-buffer / cross-module-init / narrow-int-truncation)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III defect by HAND-TRACING the code (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nReachable sequence: ' + c.reachable_sequence + '\nConcrete input: ' +
  c.concrete_input + '\nClaimed wrong: ' + c.wrong_output + '\nClaimed correct: ' + c.correct_output +
  '\nNoted existing test/caller: ' + c.existing_test_or_caller + '\n\n' +
  'Open the file, read ' + c.fn + ' + callees + the buffer/global/init it depends on.  Hand-execute the ' +
  'sequence.  Set reachable_via_api=true ONLY if reached by @export calls alone.  Mark REAL only if: (1) ' +
  '@export; (2) reachable_via_api; (3) genuinely WRONG (not a documented contract, not caller-guaranteed, not ' +
  'already cleared/guarded); (4) the fix does not break an existing contract test; (5) a falsifier reddens pre-' +
  'fix / passes post-fix.  For stale-buffer confirm the tail is NOT cleared + the two-call leak is observable.  ' +
  'For cross-module-init confirm B`s init is non-lazy + A-first is cold-wrong.  For truncation confirm the ' +
  'value can exceed the narrow max + is reachable.  Fill contract_check + reachable_via_api.\n' + FOCUS

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
const confirmed = flat.filter((v) => v.real === true && v.reachable_via_api === true)
log('W35 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
