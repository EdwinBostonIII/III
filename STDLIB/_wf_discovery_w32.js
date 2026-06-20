export const meta = {
  name: 'iii-defect-discovery-w32',
  description: 'Fresh axes post-saturation: state-machine completeness, paired-validation asymmetry, inducible error-swallow',
  phases: [
    { title: 'Discover', detail: '3 fresh lenses, read-only' },
    { title: 'Verify', detail: 'confirm + contract-check + reachable teeth' },
  ],
}

const FOCUS = [
  'CONTEXT: the lens-based memory-safety/init/div-by-zero/overflow veins are SATURATING on this tree (waves',
  '10-27, ~25 real fixes; the last round W31 was all-declined -- the leaks it found were UNREACHABLE).  These',
  'are FRESH axes chosen to find REACHABLE defects with CLEAN teeth.  A finding is REAL only with: (1) an',
  '@export entry; (2) a CONCRETE input/sequence that is REACHABLE THROUGH THE PUBLIC API (no fault-injecting',
  'internal state -- that was W31s mistake); (3) the WRONG observable; (4) you TRACED it; (5) you NAMED any',
  'existing corpus test / in-tree caller (a contract test may make a "missing" guard DELIBERATE -- e.g.',
  'option_u64_drop is idempotent BY DESIGN); (6) a falsifier that reddens pre-fix / passes post-fix.',
  'CRUCIAL: prove the bad path is REACHABLE via @export calls alone -- if it needs corrupting a private',
  'global/table that no @export writes, it is unfalsifiable defensive code -> mark real=false.',
  '',
  'DO NOT REPORT (covered/declined): all wave 10-27 fixes; es_reconstruct + the tempaloc leak cluster',
  '(instant_now_sealed/deadline_at/deadline_in/region_create -- slot_of CANNOT fail after same-type alloc,',
  'UNREACHABLE); option_u64_drop (idempotent); error-swallow trio fed_seal/reach_emit/wh_compute_frag_id;',
  'ident_copy aliasing.',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        axis: { type: 'string', description: 'state-machine | paired-validation | inducible-error-swallow' },
        description: { type: 'string' },
        reachable_sequence: { type: 'string', description: 'the exact @export call sequence that reaches the bad path (no internal-state fault injection)' },
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
    key: 'state-machine',
    prompt: 'Lens: STATE-MACHINE COMPLETENESS in ' + ROOT + ' (the wave-21 governance_vote class).  Find an ' +
      '@export that performs a TRANSITION or a state-dependent ACTION (advance/commit/finalize/seal/close/open/' +
      'vote/promote/retire/admit/ack) WITHOUT checking the current state PERMITS it -- e.g. acting on a CLOSED/' +
      'FINALIZED/ABORTED/uninitialised entity, double-committing, voting after a decision, advancing past a ' +
      'terminal state, or accepting input in the wrong phase.  The defect must be REACHABLE by a sequence of ' +
      '@export calls (open -> close -> act-again).  Trace the concrete bad sequence and the wrong observable ' +
      '(an action that should be refused succeeds / returns OK).  Name the state flag + where peers check it.\n' + FOCUS,
  },
  {
    key: 'paired-validation',
    prompt: 'Lens: PAIRED-VALIDATION ASYMMETRY in ' + ROOT + '.  Find a pair of @exports operating on the SAME ' +
      'resource/index where ONE validates an argument and its PARTNER does NOT (a set guards the index but the ' +
      'get does not, or a write checks a length the read trusts, or an encode validates a field the decode ' +
      'accepts blindly) -- so the unguarded partner is reachable with the SAME bad argument the guarded one ' +
      'rejects, producing OOB/wrong output.  Distinguish from a DELIBERATE asymmetry (e.g. a fast internal ' +
      'path).  Trace the bad argument through the unguarded partner.  This is the sibling-gap pattern; confirm ' +
      'the guarded partner exists and the gap is reachable via @export.\n' + FOCUS,
  },
  {
    key: 'inducible-error-swallow',
    prompt: 'Lens: ERROR-SWALLOW with a CALLER-INDUCIBLE failure in ' + ROOT + '.  Find an @export that calls a ' +
      'fallible helper and IGNORES its error return, where the helper FAILS on a BAD INPUT the caller controls ' +
      '(a bad length, an out-of-range id, a malformed field, a capacity overflow) -- NOT on resource exhaustion ' +
      '(which is hard to induce).  So a malformed @export argument makes the helper fail, the wrapper swallows ' +
      'it, and returns OK / a stale value.  The KEY difference from the deferred error-swallow trio: the inner ' +
      'failure is triggered by a REACHABLE bad input, giving a GENTLE teeth (the @export returns OK pre-fix / ' +
      'the propagated error post-fix).  Trace the bad input -> helper-fails -> swallowed -> wrong-OK.\n' + FOCUS,
  },
]

phase('Discover')
log('W32 fresh-axis discovery: ' + LENSES.length + ' lenses (state-machine / paired-validation / inducible-error-swallow)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III defect by HAND-TRACING the code (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nReachable sequence: ' + c.reachable_sequence + '\nConcrete input: ' +
  c.concrete_input + '\nClaimed wrong: ' + c.wrong_output + '\nClaimed correct: ' + c.correct_output +
  '\nNoted existing test/caller: ' + c.existing_test_or_caller + '\n\n' +
  'Open the file, read ' + c.fn + ' + the fns it calls + any state flag/partner.  Hand-execute the sequence. ' +
  'Set reachable_via_api=true ONLY if the bad path is reached by @export calls ALONE (NOT by corrupting a ' +
  'private global/table no @export writes -- that is unfalsifiable, the W31 tempaloc mistake).  Mark REAL only ' +
  'if: (1) @export; (2) reachable_via_api; (3) genuinely WRONG (not a documented contract, not caller-' +
  'guaranteed, not already guarded); (4) the fix does not break an existing contract test; (5) a falsifier ' +
  'reddens pre-fix / passes post-fix.  If unreachable / by-design / contract-deliberate, real=false + explain.\n' + FOCUS

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
log('W32 complete: ' + confirmed.length + ' CONFIRMED (reachable) of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
