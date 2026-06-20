export const meta = {
  name: 'iii-defect-discovery-w36',
  description: 'cad-inspired: default-zero-flag collides with valid-enum, cross-module-init r2, tree/merkle index',
  phases: [
    { title: 'Discover', detail: '3 lenses, read-only' },
    { title: 'Verify', detail: 'confirm + reachable-via-api + contract-check' },
  ],
}

const FOCUS = [
  'CONTEXT: W29 (cad) was a fresh-axis hit -- a module-global mode flag (CAD_ACTIVE) DEFAULTS to 0, which',
  'COINCIDES with a VALID enum value (CAD_SUITE_SHA256==0), so a cold/un-begun call passed the mode check it',
  'should have failed, then swallowed the backend`s uninit error -> a silently-wrong digest reported OK.  These',
  'lenses generalize that + adjacent veins.  A finding is REAL only with: (1) an @export entry; (2) a CONCRETE',
  'sequence REACHABLE via the public API (set reachable_via_api=true only then -- no fault-injecting private',
  'state); (3) the WRONG observable; (4) you TRACED it; (5) you NAMED any existing corpus test / in-tree',
  'caller (a contract test may make the behavior DELIBERATE); (6) a falsifier that reddens pre-fix / passes',
  'post-fix.  iiis: u32/u64 wrap mod 2^k; i32 ordering UNSIGNED.',
  '',
  'DO NOT REPORT (covered/declined): all wave 10-29 fixes (incl. cad payload/domain/final W29; governance',
  'complete; csl_lens; threshold_vault; the field modules; rms/sf_rou/temporal); es_reconstruct + tempaloc',
  'cluster (unreachable); option_u64_drop (idempotent); error-swallow trio + pattern + mldsa (NULL-precond);',
  'ident_copy (must-not-alias); nl_parse _np_pack_rhq (known, deferred-heavy-teeth).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        axis: { type: 'string', description: 'zero-flag-collision | cross-module-init | tree-index' },
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
    key: 'zero-flag-collision',
    prompt: 'Lens: DEFAULT-ZERO FLAG COLLIDES WITH A VALID ENUM across ' + ROOT + ' (the W29 cad pattern).  Find ' +
      'an @export that branches on a MODULE-GLOBAL mode/suite/type/state flag whose DEFAULT (BSS 0) EQUALS a ' +
      'VALID enum value -- so a COLD/un-configured call (before the *_set/_begin/_init that sets the flag) passes ' +
      'the flag-check as if validly configured, and acts on un-init backing state -> a wrong result reported as ' +
      'success.  Look for `const X_MODE_FOO : u32 = 0` + `var X_ACTIVE : u32 = 0` + `if X_ACTIVE == X_MODE_FOO`.  ' +
      'Confirm the cold call is reachable + produces a wrong observable.  (Distinguish from a flag whose 0 ' +
      'default is the documented "none/unset" that the code explicitly rejects.)\n' + FOCUS,
  },
  {
    key: 'cross-module-init',
    prompt: 'Lens: CROSS-MODULE INIT-ORDER (round 2) across ' + ROOT + ' OUTSIDE cad.iii (done).  Find an @export ' +
      'in module A that uses module B`s backend (a hash, a field, a table, an arena) which has an explicit non-' +
      'lazy *_init/_boot, but A neither calls it nor checks B is ready -- so a COLD A-first call (fresh process) ' +
      'reads B`s un-init state -> wrong value, AND A does not propagate any error B raises.  Especially modules ' +
      'that wrap sha256/keccak/a field/a registry.  Confirm B`s init is non-lazy + A-first is reachable + the ' +
      'result is wrong (not just an error).  Trace the cold cross-module sequence.\n' + FOCUS,
  },
  {
    key: 'tree-index',
    prompt: 'Lens: TREE / MERKLE / HEAP INDEX errors across ' + ROOT + '.  Find an @export over a binary tree, ' +
      'merkle tree, heap, or segment tree whose child/parent/sibling/leaf index arithmetic is WRONG at a ' +
      'boundary -- a leaf-to-node offset off by one, a `2*i` vs `2*i+1` child swap, a parent `(i-1)/2` when i can ' +
      'be 0 (underflow), a merkle proof that pairs the wrong sibling, a level/depth computed off by one, an odd-' +
      'leaf-count duplication handled wrong.  Hand-COMPUTE the index for a concrete small tree and show the wrong ' +
      'node/sibling.  (NOT a documented convention; a genuine wrong index/proof.)\n' + FOCUS,
  },
]

phase('Discover')
log('W36 discovery: ' + LENSES.length + ' lenses (zero-flag-collision / cross-module-init / tree-index)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III defect by HAND-TRACING the code (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nReachable sequence: ' + c.reachable_sequence + '\nConcrete input: ' +
  c.concrete_input + '\nClaimed wrong: ' + c.wrong_output + '\nClaimed correct: ' + c.correct_output +
  '\nNoted existing test/caller: ' + c.existing_test_or_caller + '\n\n' +
  'Open the file, read ' + c.fn + ' + its callees + the flag/backend/tree-index math.  Hand-execute the ' +
  'sequence (and hand-COMPUTE indices for tree-index).  Set reachable_via_api=true ONLY if reached by @export ' +
  'calls alone (no private-state fault injection).  Mark REAL only if: (1) @export; (2) reachable_via_api; (3) ' +
  'genuinely WRONG (not documented contract, not caller-guaranteed, not already guarded); (4) the fix does not ' +
  'break an existing contract test; (5) a falsifier reddens pre-fix / passes post-fix.  Fill contract_check + ' +
  'reachable_via_api.  BE SKEPTICAL of tree-index claims -- verify the arithmetic by hand on a 3-7 node tree.\n' + FOCUS

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
log('W36 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
