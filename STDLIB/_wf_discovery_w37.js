export const meta = {
  name: 'iii-defect-discovery-w37',
  description: 'Round-trip non-bijection, length-prefix/framing mismatch, cross-module-init r3',
  phases: [
    { title: 'Discover', detail: '3 lenses, read-only' },
    { title: 'Verify', detail: 'confirm + reachable-via-api + contract-check' },
  ],
}

const FOCUS = [
  'CONTEXT: fresh axes keep hitting after dry rounds (W29 cad cross-module-init, W30 merkle tree-index).  A',
  'finding is REAL only with: (1) an @export entry; (2) a CONCRETE input/sequence REACHABLE via the public API',
  '(set reachable_via_api=true only then -- no fault-injecting private state); (3) the WRONG observable; (4) you',
  'TRACED/hand-computed it; (5) you NAMED any existing corpus test / in-tree caller (a contract test may make',
  'the behavior DELIBERATE -- option_u64_drop idempotent, build power-of-2-only); (6) a falsifier reddening',
  'pre-fix / passing post-fix.  iiis: u32/u64 wrap mod 2^k; i32 ordering UNSIGNED; a string literal has NO',
  'trailing NUL.',
  '',
  'DO NOT REPORT (covered/declined): all wave 10-30 fixes (cad W29, merkle_tree_build_u32 W30, governance,',
  'csl_lens, threshold_vault, the field modules, rms/sf_rou/temporal, bigint); es_reconstruct + tempaloc',
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
        axis: { type: 'string', description: 'round-trip | length-prefix | cross-module-init' },
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
    key: 'round-trip',
    prompt: 'Lens: SERIALIZATION ROUND-TRIP NON-BIJECTION across ' + ROOT + '.  Find an @export ENCODE/decode (or ' +
      'pack/unpack, serialize/deserialize, to_bytes/from_bytes, write/read) PAIR where decode(encode(x)) != x ' +
      'for some reachable x -- a field dropped or mis-ordered, a sign/width lost, an endianness flip between the ' +
      'two sides, a base64/hex/varint mis-round-trip, a length not preserved.  Hand-COMPUTE a concrete x, its ' +
      'encoding, and the decoded result, and show they differ.  Especially base64url/hex/varint/leb128, fixed-' +
      'record pack/unpack, and the numera field *_to_bytes/_from_bytes.  Confirm BOTH sides are @export + the x ' +
      'is reachable.\n' + FOCUS,
  },
  {
    key: 'length-prefix',
    prompt: 'Lens: LENGTH-PREFIX / FRAMING MISMATCH across ' + ROOT + '.  Find an @export that writes a length/' +
      'count/size HEADER that does NOT match the actual payload it emits (off by the header size, double-counted, ' +
      'in the wrong units -- bytes vs elements, or omitting a terminator), OR a reader that trusts a length field ' +
      'inconsistent with the real frame -- so a writer/reader pair disagree on where a record ends, or a consumer ' +
      'reads too few/many bytes.  Especially TLV, framed messages, builders that emit a count then the items, ' +
      'wire formats.  Trace the concrete frame and the length/payload mismatch.\n' + FOCUS,
  },
  {
    key: 'cross-module-init',
    prompt: 'Lens: CROSS-MODULE INIT-ORDER (round 3) across ' + ROOT + ' OUTSIDE cad.iii (done W29).  Find an ' +
      '@export in module A that uses module B`s backend (hash/field/table/registry/arena) with an explicit non-' +
      'lazy *_init, but A neither calls it nor ensures B is ready, NOR propagates B`s error -- so a COLD A-first ' +
      'call (fresh process) reads B`s un-init state -> a WRONG value reported as success.  The cad pattern: look ' +
      'for a wrapper that selects a backend by a default-0 flag and calls it without an init-guard.  Confirm B`s ' +
      'init is non-lazy, A-first is reachable, and the result is wrong (not merely an error).  Trace the cold ' +
      'sequence.\n' + FOCUS,
  },
]

phase('Discover')
log('W37 discovery: ' + LENSES.length + ' lenses (round-trip / length-prefix / cross-module-init)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III defect by HAND-TRACING/HAND-COMPUTING (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nReachable sequence: ' + c.reachable_sequence + '\nConcrete input: ' +
  c.concrete_input + '\nClaimed wrong: ' + c.wrong_output + '\nClaimed correct: ' + c.correct_output +
  '\nNoted existing test/caller: ' + c.existing_test_or_caller + '\n\n' +
  'Open the file, read ' + c.fn + ' + its partner/callees.  Hand-execute (for round-trip, actually encode then ' +
  'decode a concrete x by hand).  Set reachable_via_api=true ONLY if reached by @export calls alone.  Mark REAL ' +
  'only if: (1) @export; (2) reachable_via_api; (3) genuinely WRONG (not a documented contract/convention, not ' +
  'caller-guaranteed, not already guarded); (4) the fix does not break an existing contract test; (5) a ' +
  'falsifier reddens pre-fix / passes post-fix.  BE SKEPTICAL: round-trip/length claims are often a verifier ' +
  'mis-reading the format -- verify the exact byte layout.  Fill contract_check + reachable_via_api.\n' + FOCUS

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
log('W37 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
