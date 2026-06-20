export const meta = {
  name: 'iii-defect-discovery-w39',
  description: 'Sharpest remaining: documented-precondition-unenforced, sibling-function-disagreement, fast-vs-slow-path',
  phases: [
    { title: 'Discover', detail: '3 sharp lenses, read-only' },
    { title: 'Verify', detail: 'confirm + reachable-via-api + contract-check + hand-compute' },
  ],
}

const FOCUS = [
  'CONTEXT: the lens vein is heavily mined (~29 fixes, last rounds dry/borderline), but the "documented-but-',
  'unenforced precondition" axis JUST produced W30 (merkle_tree_build_u32: doc said "n a power of two", code',
  'silently built a wrong root for non-power-of-2 -> reject it).  These 3 lenses sharpen that consistency/',
  'contract vein.  A finding is REAL only with: (1) an @export entry; (2) a CONCRETE input REACHABLE via the',
  'public API (reachable_via_api=true only then -- no private-state fault injection); (3) the WRONG observable,',
  'HAND-COMPUTED; (4) you TRACED it; (5) you NAMED any existing corpus test / in-tree caller; (6) a falsifier',
  'reddening pre-fix / passing post-fix.  CRUCIAL: a wrong result for an EMPTY/VACUOUS premise is often',
  'VACUOUSLY CORRECT (not a bug) -- reject those (the W38 reduced_product lesson).  iiis: u32/u64 wrap mod 2^k.',
  '',
  'DO NOT REPORT (covered/declined): all wave 10-30 fixes (cad W29, merkle W30, governance, csl_lens,',
  'threshold_vault, the field modules, rms/sf_rou/temporal, bigint); es_reconstruct + tempaloc + reduced_',
  'product/sopt empty-range (unreachable/vacuous); option_u64_drop; error-swallow trio + pattern + mldsa;',
  'ident_copy; nl_parse _np_pack_rhq (deferred).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        axis: { type: 'string', description: 'doc-precondition | sibling-disagreement | fast-vs-slow' },
        description: { type: 'string' },
        reachable_sequence: { type: 'string' },
        concrete_input: { type: 'string' }, wrong_output: { type: 'string' }, correct_output: { type: 'string' },
        not_vacuous: { type: 'string', description: 'why the wrong result is a REAL value (not vacuously-correct for an empty/contradictory premise)' },
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
    prompt: 'Lens: DOCUMENTED-BUT-UNENFORCED PRECONDITION across ' + ROOT + ' (the W30 merkle pattern).  Find an ' +
      '@export whose DOC COMMENT states a precondition on an argument (a power of two, < some max, non-zero, ' +
      'sorted, normalized, in canonical form, a valid range) that the CODE does NOT check, and where VIOLATING ' +
      'it produces a WRONG (non-vacuous) result or OOB -- not just undefined.  Grep doc comments for "must", ' +
      '"assumes", "requires", "a power of two", "valid", "in [", "<= ", "caller ensures".  Confirm the violation ' +
      'is reachable via the @export + yields a concrete wrong value (hand-compute it).  The fix ENFORCES the ' +
      'documented precondition (reject), it does NOT extend the contract.\n' + FOCUS,
  },
  {
    key: 'sibling-disagreement',
    prompt: 'Lens: SIBLING-FUNCTION DISAGREEMENT across ' + ROOT + ' (the merkle build-vs-compute shape).  Find ' +
      'TWO @exports that should compute the SAME thing two ways (a builder vs a direct computer, an incremental ' +
      'vs a one-shot, a fast path vs a reference, an encode-then-hash vs a direct-hash) but DISAGREE for some ' +
      'reachable input -- producing different roots/digests/values for the same logical input.  Hand-COMPUTE the ' +
      'input through BOTH and show they differ.  This is a real correctness bug (one of them is wrong).  Confirm ' +
      'both are @export + the divergent input is reachable + NOT an out-of-contract input for one of them.\n' + FOCUS,
  },
  {
    key: 'fast-vs-slow',
    prompt: 'Lens: FAST-PATH vs SLOW-PATH / SPECIAL-CASE DIVERGENCE across ' + ROOT + '.  Find an @export with an ' +
      'optimized/special-cased branch (a power-of-2 shortcut, a small-n special case, an early-out, an SIMD/AVX ' +
      'vs scalar dispatch, a cached vs recomputed path) that returns a DIFFERENT result than the general path for ' +
      'some reachable input -- a shortcut taken when it should not be, an early-out that skips needed work, a ' +
      'special case off by one at its own boundary.  Hand-COMPUTE the boundary input through both paths and show ' +
      'the divergence.  (numera dispatch fns, the cg_r* backends, anything with `if n == ` / `if (x & ` shortcuts.)\n' + FOCUS,
  },
]

phase('Discover')
log('W39 discovery: ' + LENSES.length + ' lenses (doc-precondition / sibling-disagreement / fast-vs-slow)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III defect by HAND-TRACING + HAND-COMPUTING (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nReachable sequence: ' + c.reachable_sequence + '\nConcrete input: ' +
  c.concrete_input + '\nClaimed wrong: ' + c.wrong_output + '\nClaimed correct: ' + c.correct_output +
  '\nWhy not vacuous: ' + c.not_vacuous + '\nNoted existing test/caller: ' + c.existing_test_or_caller + '\n\n' +
  'Open the file, read ' + c.fn + ' (+ the sibling/general path).  HAND-COMPUTE the concrete input through the ' +
  'code.  Set reachable_via_api=true if reached by @export calls; set not_vacuous=true if the wrong result is a ' +
  'REAL value (NOT vacuously-correct for an empty/contradictory premise -- the W38 lesson).  Mark REAL only if: ' +
  '(1) @export; (2) reachable_via_api; (3) not_vacuous; (4) genuinely WRONG (contradicts the doc/name/sibling, ' +
  'NOT a valid convention or out-of-contract-for-this-fn input); (5) the fix does not break an existing contract ' +
  'test; (6) a falsifier reddens pre-fix / passes post-fix.  BE SKEPTICAL.  Fill contract_check.\n' + FOCUS

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
log('W39 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
