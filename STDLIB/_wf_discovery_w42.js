export const meta = {
  name: 'iii-defect-discovery-w42',
  description: 'Genuinely fresh: shared-global-buffer reentrancy, sign-extension (i8/i16), copy-length fence-post',
  phases: [
    { title: 'Discover', detail: '3 fresh lenses, read-only' },
    { title: 'Verify', detail: 'confirm + reachable + not-vacuous + contract-check' },
  ],
}

const FOCUS = [
  'CONTEXT: ~33 fixes over waves 10-32; the documented-precondition/bitmask/asymmetry veins are now mined',
  '(W41 dry).  These 3 axes are GENUINELY UNTRIED.  A finding is REAL only with: (1) an @export entry; (2) a',
  'CONCRETE input/sequence REACHABLE via the public API (reachable_via_api=true only then); (3) the WRONG',
  'observable VALUE, REAL not vacuous; (4) you TRACED it; (5) you NAMED any existing corpus test / in-tree',
  'caller; (6) a falsifier reddening pre-fix / passing post-fix.  BE SKEPTICAL.  iiis: u32/u64 wrap mod 2^k;',
  'i32 ordering UNSIGNED; `as u8`/`& 0xFF` truncate to 8 bits; a string literal has NO trailing NUL.',
  '',
  'DO NOT REPORT (covered/declined): all wave 10-32 fixes; es_reconstruct + tempaloc + reduced_product/sopt',
  '(unreachable/vacuous); option_u64_drop; error-swallow trio + pattern + mldsa; ident_copy; nl_parse (16-bit',
  'design, NOT a bug) + rscode (caller-protocol) + ntt pow2 (complex) -- all declined/deferred.',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        axis: { type: 'string', description: 'shared-buffer-reentrancy | sign-extension | copy-length-fencepost' },
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
    key: 'shared-buffer-reentrancy',
    prompt: 'Lens: SHARED-GLOBAL-BUFFER REENTRANCY across ' + ROOT + '.  Find an @export that uses a MODULE-GLOBAL ' +
      'scratch/state buffer (a *_BUF / *_TMP / *_SCRATCH / *_STATE / a streaming hash/cipher context) and, while ' +
      'mid-use, CALLS ANOTHER @export (directly or transitively) that ALSO uses the SAME global buffer/context -- ' +
      'so the inner call CLOBBERS the outer`s in-progress state -> wrong result.  Especially: a streaming hash ' +
      '(cad/mhash/sha/keccak single global context) used by a fn that itself hashes mid-stream; a shared cipher ' +
      'state; a global "current" pointer reused nested.  Trace the outer-uses-BUF -> calls inner -> inner-clobbers' +
      '-BUF -> outer-reads-corrupted sequence.  (cad/mhash are documented "non-reentrant" -- find a caller that ' +
      'VIOLATES that by nesting.)\n' + FOCUS,
  },
  {
    key: 'sign-extension',
    prompt: 'Lens: SIGN-EXTENSION / NARROW-SIGNED across ' + ROOT + '.  Find an @export that stores a value in an ' +
      'i8/i16 (or casts through one) and then sign-extends it WRONG -- a byte 0x80..0xFF read as a NEGATIVE i8 ' +
      'when it should be an unsigned 128..255 (or vice versa), a delta/offset that goes negative and is mis-' +
      'extended, an `as i8`/`as i16` that flips a high-bit value`s sign, a signed compare on a value that should ' +
      'be unsigned (recall i32 ordering is UNSIGNED in iiis -- a NEGATIVE i32 used in `<`/`>` is treated huge).  ' +
      'Hand-COMPUTE a concrete high-bit value and show the wrong sign/magnitude.  Confirm reachable.\n' + FOCUS,
  },
  {
    key: 'copy-length-fencepost',
    prompt: 'Lens: COPY/FILL LENGTH FENCE-POST across ' + ROOT + '.  Find an @export doing a byte/element COPY or ' +
      'FILL where the LENGTH is off by one -- a `while i <= n` copy that writes n+1 elements, a `while i < n-1` ' +
      'that copies one too few, a memcpy-like with len that double-counts a header or omits a terminator, a ' +
      'fill that clears len-1 or len+1 bytes, a "copy up to and including" vs "exclusive" confusion.  This is a ' +
      'LENGTH/COUNT fence-post (writes/reads the wrong NUMBER of items), distinct from an index OOB.  Hand-COMPUTE ' +
      'the byte count and show it is off by one (over-writes 1 past, or leaves 1 stale/uncopied).  Confirm ' +
      'reachable + the wrong count is observable.\n' + FOCUS,
  },
]

phase('Discover')
log('W42 discovery: ' + LENSES.length + ' lenses (shared-buffer-reentrancy / sign-extension / copy-length-fencepost)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III defect by HAND-TRACING (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nReachable sequence: ' + c.reachable_sequence + '\nConcrete input: ' +
  c.concrete_input + '\nClaimed wrong: ' + c.wrong_output + '\nWhy not vacuous: ' + c.not_vacuous +
  '\nNoted existing test/caller: ' + c.existing_test_or_caller + '\n\n' +
  'Open the file, read ' + c.fn + ' + callees.  Hand-execute / hand-compute the sequence.  Set reachable_via_api' +
  '=true if reached by @export calls; not_vacuous=true if the wrong result is a REAL value.  Mark REAL only if: ' +
  '(1) @export; (2) reachable_via_api; (3) not_vacuous; (4) genuinely WRONG (not a documented contract, not ' +
  'caller-guaranteed, not already guarded); (5) for reentrancy, the SAME global buffer is really clobbered by a ' +
  'nested @export call reachable in-tree; (6) a falsifier reddens pre-fix / passes post-fix.  BE SKEPTICAL -- ' +
  'reentrancy/sign claims are often a misread; verify the exact buffer + the exact cast.  Fill contract_check.\n' + FOCUS

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
log('W42 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
