export const meta = {
  name: 'iii-defect-discovery-w34',
  description: 'Genuinely new axes: comparison-direction, fence-post boundary, accumulator-init identity',
  phases: [
    { title: 'Discover', detail: '3 new lenses, read-only' },
    { title: 'Verify', detail: 'confirm + reachable + contract-check + clean teeth' },
  ],
}

const FOCUS = [
  'CONTEXT: the memory-safety/init/validation/state-machine lens veins are mostly mined (waves 10-28).  These',
  'are GENUINELY NEW axes -- LOGIC errors that produce a WRONG VALUE (not a crash/OOB), with a clean value',
  'teeth.  A finding is REAL only with: (1) an @export entry; (2) a CONCRETE input REACHABLE via the public API;',
  '(3) the WRONG observable VALUE vs the correct one (computed by hand); (4) you TRACED the code; (5) you NAMED',
  'any existing corpus test / in-tree caller (a contract test may make the behavior DELIBERATE); (6) a falsifier',
  'that reddens pre-fix / passes post-fix.  These are SUBTLE -- be skeptical, hand-COMPUTE the correct value,',
  'and reject anything that is merely a different-but-valid convention.  iiis facts: i32 ordering compiles',
  'UNSIGNED (a known trap -- `x<0i32` always false); u32/u64 wrap mod 2^k.',
  '',
  'DO NOT REPORT (covered): all wave 10-28 fixes; the declined set (es_reconstruct, tempaloc cluster, option_',
  'u64_drop idempotent, error-swallow trio, pattern_template_set_id, mldsa, ident_copy).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        axis: { type: 'string', description: 'comparison-direction | fence-post | accumulator-init' },
        description: { type: 'string' },
        concrete_input: { type: 'string' }, wrong_output: { type: 'string' }, correct_output: { type: 'string' },
        hand_computation: { type: 'string', description: 'the by-hand computation showing the correct value differs from what the code returns' },
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
    key: 'comparison-direction',
    prompt: 'Lens: COMPARISON-DIRECTION / WRONG-EXTREMUM across ' + ROOT + '.  Find an @export that selects a ' +
      'min/max/best/worst, sorts, or picks by a comparison, using the WRONG direction -- a max() that keeps the ' +
      'smaller, a `<` where `>` is meant, a sort ascending where descending is required, a "closest" that picks ' +
      'farthest, a tie-break the wrong way, or argmin/argmax returning the wrong index.  Hand-COMPUTE the ' +
      'correct extremum for a concrete small input and show the code returns the other one.  Be skeptical of ' +
      'mere convention (both directions valid) -- only a result that contradicts the fn name / doc / its KAT.\n' + FOCUS,
  },
  {
    key: 'fence-post',
    prompt: 'Lens: FENCE-POST / INCLUSIVE-EXCLUSIVE boundary (LOGIC, not array-OOB) across ' + ROOT + '.  Find an ' +
      '@export whose threshold/range/count logic is off by one at the ENDPOINT -- a `>` where `>=` is meant (or ' +
      'vice versa) in a quorum/threshold/deadline/limit check, a range [a,b) treated as [a,b] (or vice versa), a ' +
      'binary-search hi/lo that misses the last element, a percentile/median index off by one, a "fits if size ' +
      '<= cap" written `< cap`, a timeout fired one tick early/late.  Hand-COMPUTE the boundary case and show ' +
      'the wrong accept/reject or wrong index.  (NOT a memory OOB -- a LOGICAL boundary that yields a wrong ' +
      'decision/value.)\n' + FOCUS,
  },
  {
    key: 'accumulator-init',
    prompt: 'Lens: ACCUMULATOR / FOLD INIT-IDENTITY across ' + ROOT + '.  Find an @export that folds/reduces a ' +
      'sequence with a WRONG initial value -- a max initialized to 0 (so an all-smaller or all-negative input ' +
      'returns 0), a min initialized to 0 or a too-small constant, an AND-reduce init to 0 (always 0), an OR/sum ' +
      'init to a nonzero, a product init to 0, a gcd/lcm seeded wrong, a "first match" sentinel that collides ' +
      'with a valid value, a running-best not updated on the first element.  Hand-COMPUTE the fold for a ' +
      'concrete input that exposes the bad identity and show the wrong result.  Confirm the identity is reachable ' +
      '(the sequence can contain values that break the wrong init).\n' + FOCUS,
  },
]

phase('Discover')
log('W34 new-axis discovery: ' + LENSES.length + ' lenses (comparison-direction / fence-post / accumulator-init)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III LOGIC defect by HAND-TRACING + HAND-COMPUTING (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nConcrete input: ' + c.concrete_input + '\nClaimed wrong: ' + c.wrong_output +
  '\nClaimed correct: ' + c.correct_output + '\nHand computation: ' + c.hand_computation +
  '\nNoted existing test/caller: ' + c.existing_test_or_caller + '\n\n' +
  'Open the file, read ' + c.fn + ' + its callees.  HAND-COMPUTE the correct value for the concrete input and ' +
  'compare to what the code returns.  Set reachable_via_api=true only if reached by @export calls.  Mark REAL ' +
  'only if: (1) @export; (2) reachable; (3) the result is genuinely WRONG (contradicts the fn name/doc/KAT -- ' +
  'NOT a valid alternative convention, NOT caller-guaranteed); (4) the fix does not break an existing contract ' +
  'test; (5) a clean value-differential falsifier exists.  BE SKEPTICAL: logic-error claims are often the ' +
  'verifier misreading the intent -- if the code matches its doc/KAT, mark real=false.  Fill contract_check.\n' + FOCUS

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
log('W34 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
