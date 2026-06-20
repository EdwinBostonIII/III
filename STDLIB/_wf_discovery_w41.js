export const meta = {
  name: 'iii-defect-discovery-w41',
  description: 'Writer/reader bounds asymmetry (bitr_get pattern), cross-module-init, documented-precondition r3',
  phases: [
    { title: 'Discover', detail: '3 lenses, read-only' },
    { title: 'Verify', detail: 'confirm + reachable + not-vacuous + contract-check' },
  ],
}

const FOCUS = [
  'CONTEXT: the documented-precondition + bitmask-modulo veins were RICH (W30 merkle, W31 ad_aligned/vz_covers,',
  'W32 ad_loop_aligned_scan + bitr_get).  bitr_get was a WRITER/READER ASYMMETRY: the writer bitw guards',
  '`byte >= cap` but the reader bitr_get did NOT -> OOB read.  These lenses hunt that + adjacent veins.  A',
  'finding is REAL only with: (1) an @export entry; (2) a CONCRETE input REACHABLE via the public API',
  '(reachable_via_api=true only then); (3) the WRONG observable (OOB / wrong value), REAL not vacuous; (4) you',
  'TRACED it; (5) you NAMED any existing corpus test / in-tree caller; (6) a falsifier reddening pre-fix /',
  'passing post-fix.  BE SKEPTICAL.  iiis: u32/u64 wrap mod 2^k; i32 ordering UNSIGNED.',
  '',
  'DO NOT REPORT (covered/declined): all wave 10-32 fixes (merkle, ad_aligned/vz_covers/ad_loop_aligned_scan,',
  'bitr_get, cad, governance, csl_lens, threshold_vault, the field modules, rms/sf_rou/temporal, bigint);',
  'es_reconstruct + tempaloc + reduced_product/sopt (unreachable/vacuous); option_u64_drop; error-swallow trio',
  '+ pattern + mldsa; ident_copy; nl_parse + ntt pow2 + rscode rs_decode_apply (deferred); the swept power-of-2',
  'preconditions (ripple/ripple_dyn enforce; egraph/memo_lattice/distress_witness fixed pow2 consts).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        axis: { type: 'string', description: 'writer-reader-asymmetry | cross-module-init | doc-precondition' },
        description: { type: 'string' },
        reachable_sequence: { type: 'string' },
        concrete_input: { type: 'string' }, wrong_output: { type: 'string' }, correct_output: { type: 'string' },
        not_vacuous: { type: 'string' }, guarded_partner: { type: 'string', description: 'for asymmetry: the partner @export that DOES have the guard this one lacks' },
        existing_test_or_caller: { type: 'string' }, is_export: { type: 'boolean' }, confidence: { type: 'number' },
      },
      required: ['file', 'fn', 'line', 'axis', 'description', 'reachable_sequence', 'concrete_input', 'wrong_output', 'correct_output', 'not_vacuous', 'guarded_partner', 'existing_test_or_caller', 'is_export', 'confidence'],
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
    key: 'writer-reader-asymmetry',
    prompt: 'Lens: WRITER/READER (or SET/GET, PUSH/POP, ENCODE/DECODE) BOUNDS ASYMMETRY across ' + ROOT + ' (the ' +
      'bitr_get pattern).  Find a PAIR of @exports on the same buffer/pool/stream where ONE side (usually the ' +
      'writer/setter/push) VALIDATES a bound (idx < N, byte < cap, count <= max, pos in range) but its PARTNER ' +
      '(the reader/getter/pop/decoder) does NOT -- so the partner can be driven past the bound and OOB-reads or ' +
      'returns garbage.  Name BOTH functions + the guard one has and the other lacks.  Trace a concrete sequence ' +
      '(write/set within bounds, then read/get past the bound) that OOBs.  Confirm the guarded partner exists ' +
      '(this is the asymmetry, not a both-unguarded case already covered by the accessor-bounds waves).\n' + FOCUS,
  },
  {
    key: 'cross-module-init',
    prompt: 'Lens: CROSS-MODULE INIT-ORDER (round 4) across ' + ROOT + ' OUTSIDE cad.iii.  Find an @export in ' +
      'module A that uses module B`s backend (hash/field/table/registry) with an explicit non-lazy *_init but A ' +
      'neither calls it nor checks B is ready NOR propagates B`s error -- a COLD A-first call (fresh process) ' +
      'reads B`s un-init state -> a WRONG value reported as success (the cad pattern: a wrapper selecting a ' +
      'backend by a default-0 flag, calling it without an init-guard, swallowing the backend`s uninit error).  ' +
      'Confirm B`s init is non-lazy + A-first is reachable + the result is WRONG (not merely an error).\n' + FOCUS,
  },
  {
    key: 'doc-precondition',
    prompt: 'Lens: DOCUMENTED-BUT-UNENFORCED PRECONDITION (round 3, NON power-of-2) across ' + ROOT + '.  Find an ' +
      '@export whose doc states a precondition the code does NOT check, where violating it gives a WRONG (non-' +
      'vacuous) result -- "must be SORTED" (binary search/merge/dedup), "NORMALIZED/canonical/reduced", "len <= ' +
      'cap", "in [a,b]", "non-empty", "coprime/invertible", "monotone", "no duplicates".  Grep doc comments for ' +
      '"must"/"assumes"/"requires"/"caller ensures"/"sorted"/"normalized"/"canonical".  Hand-COMPUTE the ' +
      'violation`s wrong result.  The fix ENFORCES the precondition (reject) or matches the documented semantics.\n' + FOCUS,
  },
]

phase('Discover')
log('W41 discovery: ' + LENSES.length + ' lenses (writer-reader-asymmetry / cross-module-init / doc-precondition)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III defect by HAND-TRACING (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nReachable sequence: ' + c.reachable_sequence + '\nConcrete input: ' +
  c.concrete_input + '\nClaimed wrong: ' + c.wrong_output + '\nGuarded partner: ' + c.guarded_partner +
  '\nWhy not vacuous: ' + c.not_vacuous + '\nNoted existing test/caller: ' + c.existing_test_or_caller + '\n\n' +
  'Open the file, read ' + c.fn + ' + its guarded partner / backend.  Hand-execute the sequence.  Set ' +
  'reachable_via_api=true if reached by @export calls; not_vacuous=true if the wrong result is a REAL value.  ' +
  'Mark REAL only if: (1) @export; (2) reachable_via_api; (3) not_vacuous; (4) genuinely WRONG (not a ' +
  'documented contract/convention, not caller-guaranteed, not already guarded); (5) for asymmetry, the partner ' +
  'REALLY has the guard this one lacks; (6) a falsifier reddens pre-fix / passes post-fix.  BE SKEPTICAL.  Fill ' +
  'contract_check.\n' + FOCUS

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
log('W41 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
