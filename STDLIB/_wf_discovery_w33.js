export const meta = {
  name: 'iii-defect-discovery-w33',
  description: 'Rotate the productive W32 axes: state-machine-2, paired-validation-2, inducible-error-swallow (non-NULL)',
  phases: [
    { title: 'Discover', detail: '3 lenses on fresh module sets, read-only' },
    { title: 'Verify', detail: 'confirm + reachable-via-api + contract-check' },
  ],
}

const FOCUS = [
  'CONTEXT: W32 proved the bug supply is NOT exhausted -- rotating to state-machine / paired-validation lenses',
  'found 3 reachable defects (governance_drop ACCEPTED-gate W28, csl_lens count-bound W28) after W31 dried.',
  'Re-run those PRODUCTIVE axes on DIFFERENT modules.  A finding is REAL only with: (1) an @export entry;',
  '(2) a CONCRETE input/sequence REACHABLE THROUGH THE PUBLIC API (no fault-injecting private state -- set',
  'reachable_via_api=true only then); (3) the WRONG observable; (4) you TRACED it; (5) you NAMED any existing',
  'corpus test / in-tree caller (a contract test may make a "missing" guard DELIBERATE -- option_u64_drop is',
  'idempotent BY DESIGN, do not re-flag); (6) a falsifier that reddens pre-fix / passes post-fix.',
  '',
  'DO NOT REPORT (covered/declined): all wave 10-28 fixes (governance_vote W21 + governance_drop W28; csl',
  'accessors W19 + csl_lens W28; threshold_vault/crt/rn_graph_root/bigint/rms/sf_rou/temporal); es_reconstruct',
  '+ tempaloc leak cluster (UNREACHABLE); option_u64_drop (idempotent); error-swallow trio + pattern_template_',
  'set_id + mldsa (NULL-precondition / hard-teeth); ident_copy (must-not-alias).',
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
    key: 'state-machine-2',
    prompt: 'Lens: STATE-MACHINE COMPLETENESS across ' + ROOT + ' OUTSIDE governance.iii (already done).  Find an ' +
      '@export that performs a state-dependent action WITHOUT checking the current state permits it -- a session/' +
      'channel/connection/transaction/lock/stream/epoch/round lifecycle (open/begin/accept/commit/abort/close/' +
      'seal/finalize/advance/rotate), where acting on a closed/finalized/aborted/uninitialised entity, double-' +
      'committing, or advancing past a terminal state SUCCEEDS when it should be refused.  Especially aether ' +
      '(consensus/federation/witness), forcefield, sanctus.  The bad path must be REACHABLE by @export calls ' +
      '(begin -> close -> act-again).  Name the state flag + where PEERS check it (the sibling-gap).\n' + FOCUS,
  },
  {
    key: 'paired-validation-2',
    prompt: 'Lens: PAIRED-VALIDATION ASYMMETRY across ' + ROOT + ' OUTSIDE csl.iii (already done).  Find a pair of ' +
      '@exports on the SAME resource where ONE validates an arg (count/index/length/id) and its PARTNER does NOT ' +
      '-- a setter guards but the lens/iterate/finalize reads the stored count unguarded; an encode validates a ' +
      'field the decode trusts; a push checks capacity the pop/peek does not; a write bounds an index the read ' +
      'trusts.  The unguarded partner must be reachable with the SAME bad arg the guarded one rejects -> OOB / ' +
      'wrong output.  Confirm the guarded partner exists and the gap is reachable via @export.  This is the ' +
      'sibling-gap; many modules store a count via one @export and consume it via another.\n' + FOCUS,
  },
  {
    key: 'inducible-error-swallow',
    prompt: 'Lens: ERROR-SWALLOW with a NON-NULL caller-inducible failure across ' + ROOT + '.  Find an @export ' +
      'that calls a fallible helper and IGNORES its error return, where the helper fails on a BAD-but-NON-NULL ' +
      'input the caller controls -- an out-of-range id/index, a length over a cap, a bad type tag, a count that ' +
      'fails an internal check (NOT a NULL pointer -- that is a precondition we decline, and NOT resource ' +
      'exhaustion -- too hard to induce).  So a malformed (non-NULL) @export argument makes the helper return an ' +
      'error, the wrapper swallows it, and returns OK / a stale value.  GENTLE teeth: @export returns OK pre-fix ' +
      '/ the propagated error post-fix.  Trace the bad-but-valid-pointer input -> helper-fails -> swallowed.\n' + FOCUS,
  },
]

phase('Discover')
log('W33 discovery: ' + LENSES.length + ' lenses (state-machine-2 / paired-validation-2 / inducible-error-swallow)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III defect by HAND-TRACING the code (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nReachable sequence: ' + c.reachable_sequence + '\nConcrete input: ' +
  c.concrete_input + '\nClaimed wrong: ' + c.wrong_output + '\nClaimed correct: ' + c.correct_output +
  '\nNoted existing test/caller: ' + c.existing_test_or_caller + '\n\n' +
  'Open the file, read ' + c.fn + ' + its callees + any state flag/partner.  Hand-execute the sequence.  Set ' +
  'reachable_via_api=true ONLY if the bad path is reached by @export calls ALONE (NOT by corrupting private ' +
  'state no @export writes -- the W31 tempaloc mistake).  Mark REAL only if: (1) @export; (2) reachable_via_api; ' +
  '(3) genuinely WRONG (not a documented contract, not caller-guaranteed, not already guarded); (4) the fix does ' +
  'not break an existing contract test; (5) a falsifier reddens pre-fix / passes post-fix.  For state-machine ' +
  'name the state flag + the peer that checks it.  For paired-validation name the guarded partner.  For error-' +
  'swallow confirm the inducing input is NON-NULL + reachable.  Fill contract_check + reachable_via_api.\n' + FOCUS

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
log('W33 complete: ' + confirmed.length + ' CONFIRMED (reachable) of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
