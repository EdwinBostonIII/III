export const meta = {
  name: 'iii-defect-discovery-w40',
  description: 'Other documented preconditions (sorted/normalized/range), unit-mismatch (bytes/elements/bits), sibling-disagreement',
  phases: [
    { title: 'Discover', detail: '3 lenses, read-only' },
    { title: 'Verify', detail: 'confirm + reachable + not-vacuous + contract-check' },
  ],
}

const FOCUS = [
  'CONTEXT: the documented-precondition vein is productive (W30 merkle, W31 ad_aligned + vz_covers -- all',
  '"power-of-two" preconditions unenforced).  The power-of-2/bitmask sub-vein is now EXHAUSTED.  These lenses',
  'rotate to OTHER documented preconditions + a unit axis.  A finding is REAL only with: (1) an @export entry;',
  '(2) a CONCRETE input REACHABLE via the public API (reachable_via_api=true only then); (3) the WRONG',
  'observable VALUE, HAND-COMPUTED, that is REAL not vacuous (not vacuously-correct for an empty/contradictory',
  'premise -- the W38 reduced_product lesson); (4) you TRACED it; (5) you NAMED any existing corpus test /',
  'in-tree caller (may make it DELIBERATE); (6) a falsifier reddening pre-fix / passing post-fix.  BE',
  'SKEPTICAL.  iiis: u32/u64 wrap mod 2^k; i32 ordering UNSIGNED.',
  '',
  'DO NOT REPORT (covered/declined): all wave 10-31 fixes (merkle W30, ad_aligned + vz_covers W31, cad W29,',
  'governance, csl_lens, threshold_vault, the field modules, rms/sf_rou/temporal, bigint); es_reconstruct +',
  'tempaloc + reduced_product/sopt (unreachable/vacuous); option_u64_drop; error-swallow trio + pattern +',
  'mldsa; ident_copy; nl_parse _np_pack_rhq + ntt power-of-2 (deferred); the other power-of-2 preconditions',
  '(ripple/ripple_dyn ENFORCE it; distress_witness/ripple_journal/egraph/memo_lattice use fixed pow2 consts).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        axis: { type: 'string', description: 'doc-precondition | unit-mismatch | sibling-disagreement' },
        description: { type: 'string' },
        reachable_sequence: { type: 'string' },
        concrete_input: { type: 'string' }, wrong_output: { type: 'string' }, correct_output: { type: 'string' },
        not_vacuous: { type: 'string' },
        existing_test_or_caller: { type: 'string' }, is_export: { type: 'boolean' }, confidence: { type: 'number' },
      },
      required: ['file', 'fn', 'line', 'axis', 'description', 'reachable_sequence', 'concrete_input', 'wrong_output', 'correct_output', 'not_vacuous', 'existing_test_or_caller', 'is_export', 'confidence'],
    } },
  },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
    real: { type: 'boolean' }, reachable_via_api: { type: 'boolean' }, not_vacuous: { type: 'boolean' },
    traced_result: { type: 'string' }, correct_result: { type: 'string' },
    contract_check: { type: 'string' }, teeth_idea: { type: 'string' }, fix: { type: 'string' }, refutation: { type: 'string' },
  },
  required: ['file', 'fn', 'line', 'real', 'reachable_via_api', 'not_vacuous', 'refutation'],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const ROOT = REPO + '/STDLIB/iii/'

const LENSES = [
  {
    key: 'doc-precondition',
    prompt: 'Lens: DOCUMENTED-BUT-UNENFORCED PRECONDITION (NON power-of-2 -- that sub-vein is done) across ' + ROOT +
      '.  Find an @export whose doc comment states a precondition the code does NOT check, where violating it ' +
      'gives a WRONG (non-vacuous) result -- "must be SORTED" (a binary search / merge / dedup that assumes ' +
      'sorted input), "must be NORMALIZED / canonical / reduced" (an op that assumes its input is already ' +
      'canonical), "must be < N" / "in [a,b]" / "len <= cap", "assumes non-empty", "must be coprime/invertible".  ' +
      'Grep doc comments for "must", "assumes", "requires", "caller ensures", "sorted", "normalized", "canonical", ' +
      '"reduced", "in range".  Hand-COMPUTE the violation`s wrong result.  The fix ENFORCES the precondition.\n' + FOCUS,
  },
  {
    key: 'unit-mismatch',
    prompt: 'Lens: UNIT MISMATCH (bytes vs elements vs bits) across ' + ROOT + '.  Find an @export that confuses ' +
      'two units -- a length in BYTES used as a count of ELEMENTS (or vice versa), a bit-count used as a byte-' +
      'count, an index scaled by the wrong element size, a `* 4` / `* 8` / `>> 3` applied once too many or too ' +
      'few, a buffer sized in one unit indexed in another.  So a call processes the wrong number of items or ' +
      'indexes the wrong offset.  Hand-COMPUTE the concrete size/offset and show it is in the wrong unit (e.g. ' +
      'copies n bytes when it should copy n*4, or loops n elements over an n-byte buffer).  Confirm reachable.\n' + FOCUS,
  },
  {
    key: 'sibling-disagreement',
    prompt: 'Lens: SIBLING-FUNCTION DISAGREEMENT across ' + ROOT + ' (the merkle build-vs-compute shape, on FRESH ' +
      'modules).  Find TWO @exports that should compute the SAME thing two ways (incremental vs one-shot, a ' +
      'fast/special path vs a reference, encode-then-X vs direct-X, a u32 variant vs a u64/bytes variant of the ' +
      'same operation) but DISAGREE for some reachable input -- different digests/roots/values for the same ' +
      'logical input.  Hand-COMPUTE the input through BOTH and show they differ; one is wrong.  Confirm both are ' +
      '@export, the input is reachable + in-contract for both.\n' + FOCUS,
  },
]

phase('Discover')
log('W40 discovery: ' + LENSES.length + ' lenses (doc-precondition / unit-mismatch / sibling-disagreement)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III defect by HAND-TRACING + HAND-COMPUTING (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nReachable sequence: ' + c.reachable_sequence + '\nConcrete input: ' +
  c.concrete_input + '\nClaimed wrong: ' + c.wrong_output + '\nClaimed correct: ' + c.correct_output +
  '\nWhy not vacuous: ' + c.not_vacuous + '\nNoted existing test/caller: ' + c.existing_test_or_caller + '\n\n' +
  'Open the file, read ' + c.fn + ' (+ sibling/general path for sibling-disagreement).  HAND-COMPUTE the input ' +
  'through the code.  Set reachable_via_api=true if reached by @export calls; not_vacuous=true if the wrong ' +
  'result is a REAL value (not vacuously-correct for an empty premise).  Mark REAL only if: (1) @export; (2) ' +
  'reachable_via_api; (3) not_vacuous; (4) genuinely WRONG (contradicts the doc/name/sibling, NOT a valid ' +
  'convention/out-of-contract input); (5) the fix does not break an existing contract test; (6) a falsifier ' +
  'reddens pre-fix / passes post-fix.  BE SKEPTICAL.  Fill contract_check.\n' + FOCUS

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
const confirmed = flat.filter((v) => v.real === true && v.reachable_via_api === true && v.not_vacuous === true)
log('W40 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
