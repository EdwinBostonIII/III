export const meta = {
  name: 'iii-defect-discovery-w38',
  description: 'Untried axes: empty/single-element edge, modular/reduction boundary, saturating-vs-wrapping',
  phases: [
    { title: 'Discover', detail: '3 lenses, read-only' },
    { title: 'Verify', detail: 'confirm + reachable-via-api + contract-check + hand-compute' },
  ],
}

const FOCUS = [
  'CONTEXT: ~29 fixes over waves 10-30; the rate is now ~1 per 1.5 rounds (W36 hit merkle, W37 dry).  These',
  'are 3 untried LOGIC/edge axes that yield WRONG VALUES (clean value teeth).  A finding is REAL only with:',
  '(1) an @export entry; (2) a CONCRETE input REACHABLE via the public API (reachable_via_api=true only then);',
  '(3) the WRONG observable VALUE, HAND-COMPUTED; (4) you TRACED it; (5) you NAMED any existing corpus test /',
  'in-tree caller (a contract test may make it DELIBERATE); (6) a falsifier reddening pre-fix / passing post-',
  'fix.  BE SKEPTICAL -- hand-compute the correct value; reject mere conventions.  iiis: i32 ordering UNSIGNED;',
  'u32/u64 wrap mod 2^k.',
  '',
  'DO NOT REPORT (covered/declined): all wave 10-30 fixes (incl. cad W29, merkle W30, governance, csl_lens,',
  'threshold_vault, the field/Montgomery modules, rms/sf_rou/temporal, bigint); es_reconstruct + tempaloc',
  'cluster; option_u64_drop (idempotent); error-swallow trio + pattern + mldsa; ident_copy; nl_parse',
  '_np_pack_rhq (known, deferred).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        axis: { type: 'string', description: 'empty-single-edge | modular-boundary | saturate-vs-wrap' },
        description: { type: 'string' },
        concrete_input: { type: 'string' }, wrong_output: { type: 'string' }, correct_output: { type: 'string' },
        hand_computation: { type: 'string' },
        existing_test_or_caller: { type: 'string' }, is_export: { type: 'boolean' }, confidence: { type: 'number' },
      },
      required: ['file', 'fn', 'line', 'axis', 'description', 'concrete_input', 'wrong_output', 'correct_output', 'hand_computation', 'existing_test_or_caller', 'is_export', 'confidence'],
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
    key: 'empty-single-edge',
    prompt: 'Lens: EMPTY / SINGLE-ELEMENT edge mishandling across ' + ROOT + '.  Find an @export that mishandles ' +
      'n==0 or n==1 -- a reduce/fold that assumes >=1 element (returns garbage / reads index 0 of an empty set), ' +
      'a loop `while i < n - 1` that underflows when n==0 (n-1 wraps huge), a "compare adjacent" that needs >=2, ' +
      'a median/average of 0 elements, a "first/last" on empty, a tree/list op that assumes non-empty.  Hand-' +
      'COMPUTE the n==0 or n==1 result and show it is wrong (or OOB/wraps).  Confirm the empty/single input is ' +
      'reachable via the @export (not a guaranteed-nonempty precondition).\n' + FOCUS,
  },
  {
    key: 'modular-boundary',
    prompt: 'Lens: MODULAR / REDUCTION BOUNDARY value across ' + ROOT + ' (NOT the crypto algorithms themselves -- ' +
      'the reduction/normalization HELPERS).  Find an @export that reduces/normalizes/clamps a value and is WRONG ' +
      'exactly AT a boundary -- x == modulus returning modulus instead of 0, a `mod` that gives a result == the ' +
      'modulus, a clamp that is off by one at min/max, a canonicalize that leaves the max representative un-' +
      'reduced, a normalize that mishandles the exact-boundary input.  Hand-COMPUTE the boundary case and show ' +
      'the result is not the canonical one.  (Numera reduce/normalize/canon helpers; trit/q128/fixed-point.)\n' + FOCUS,
  },
  {
    key: 'saturate-vs-wrap',
    prompt: 'Lens: SATURATE-vs-WRAP mismatch across ' + ROOT + '.  Find an @export where a counter/accumulator/' +
      'index that should SATURATE (clamp at max) instead WRAPS (mod 2^k back to 0/small), or should WRAP but ' +
      'saturates -- a "increment but cap at N" that overflows past N, a refcount/seq/epoch that wraps to 0 ' +
      'destructively, a "remaining = budget - spent" that wraps when spent>budget, a position that wraps a ring ' +
      'wrongly.  Hand-COMPUTE the over-max case and show the wrong wrap/saturate.  Confirm the over-max input is ' +
      'reachable + the intent (saturate vs wrap) from the fn name/doc.\n' + FOCUS,
  },
]

phase('Discover')
log('W38 discovery: ' + LENSES.length + ' lenses (empty-single-edge / modular-boundary / saturate-vs-wrap)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III defect by HAND-TRACING + HAND-COMPUTING (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nConcrete input: ' + c.concrete_input + '\nClaimed wrong: ' + c.wrong_output +
  '\nClaimed correct: ' + c.correct_output + '\nHand computation: ' + c.hand_computation +
  '\nNoted existing test/caller: ' + c.existing_test_or_caller + '\n\n' +
  'Open the file, read ' + c.fn + ' + callees.  HAND-COMPUTE the correct value for the concrete edge input and ' +
  'compare to what the code returns.  Set reachable_via_api=true only if reached by @export calls.  Mark REAL ' +
  'only if: (1) @export; (2) reachable; (3) genuinely WRONG (contradicts the fn name/doc/KAT -- NOT a valid ' +
  'convention, NOT a guaranteed precondition); (4) the fix does not break an existing contract test; (5) a clean ' +
  'value-differential (or gentle) falsifier exists.  BE SKEPTICAL -- edge/boundary claims are often a verifier ' +
  'misreading the intended semantics; if the code matches its doc/KAT, real=false.  Fill contract_check.\n' + FOCUS

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
log('W38 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
