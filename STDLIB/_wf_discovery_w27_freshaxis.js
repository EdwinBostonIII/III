export const meta = {
  name: 'iii-defect-discovery-w27-freshaxis',
  description: 'Fresh axes after init-order saturated: error-swallow, int-overflow sizing, off-by-one, signed-sentinel',
  phases: [
    { title: 'Discover', detail: '4 fresh-axis deep reads, read-only' },
    { title: 'Verify', detail: 'confirm with a concrete input -> wrong result/OOB' },
  ],
}

const FOCUS = [
  'CONTEXT: the accessor-bounds, byte-pointer, protocol-lifecycle, and use-before-init axes are MINED OUT',
  'on this tree (waves 10-23).  These are FRESH axes.  A finding is REAL only with: (1) an @export entry',
  'point; (2) a CONCRETE input; (3) the WRONG observable result (wrong value / OOB / swallowed failure) vs',
  'the correct one; (4) you TRACED the actual code, not pattern-matched a name.  Reject by-design contracts,',
  'lazy-init, and already-guarded paths.  iiis facts you MUST respect: i32 ordering compares (< <= > >=)',
  'compile UNSIGNED (so `x < 0i32` on an i32 is ALWAYS FALSE -- a negative sentinel check silently dead);',
  'i64 ordering is signed-correct; equality (==,!=) is fine for both.  u32*u32 and u32+u32 wrap mod 2^32.',
  '',
  'DO NOT REPORT (covered/known): any *_to_mont/_from_mont/_reduce/_inv cold-init (W22/W23 done); accessor',
  'OOB getters/setters with slot/idx >= N guards (waves 10-20 swept); es_verify_shard (deferred); the bigint',
  '64-slot handle-exhaustion (documented).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        axis: { type: 'string', description: 'error-swallow | int-overflow | off-by-one | signed-sentinel' },
        description: { type: 'string' },
        concrete_input: { type: 'string' }, wrong_output: { type: 'string' }, correct_output: { type: 'string' },
        is_export: { type: 'boolean' }, confidence: { type: 'number' },
      },
      required: ['file', 'fn', 'line', 'axis', 'description', 'concrete_input', 'wrong_output', 'correct_output', 'is_export', 'confidence'],
    } },
  },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
    real: { type: 'boolean' }, traced_result: { type: 'string' }, correct_result: { type: 'string' },
    teeth_idea: { type: 'string', description: 'how a falsifier KAT would redden pre-fix and pass post-fix' },
    fix: { type: 'string' }, refutation: { type: 'string' },
  },
  required: ['file', 'fn', 'line', 'real', 'refutation'],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const ROOT = REPO + '/STDLIB/iii/'

const LENSES = [
  {
    key: 'error-swallow',
    prompt: 'Lens: ERROR-CODE SWALLOWING in ' + ROOT + '.  Find an @export that CALLS a fallible internal fn ' +
      '(one that returns an i32 error code, a negative/sentinel value, or a 0/1 ok-flag) but IGNORES the result ' +
      'and returns success / a stale value regardless -- so a real failure (bad input, full table, verify-fail, ' +
      'overflow) is reported as OK.  Especially: a verify/seal/commit @export whose internal check can fail but ' +
      'the wrapper hard-returns 0i32/1u32.  Trace one concrete failing input and show the wrongly-OK result.\n' + FOCUS,
  },
  {
    key: 'int-overflow',
    prompt: 'Lens: INTEGER-OVERFLOW in SIZE/OFFSET math in ' + ROOT + '.  Find an @export that computes a byte ' +
      'size, slot offset, or capacity as a PRODUCT or SUM of caller-influenced u32/u64 (count * elem_size, ' +
      'len + header, idx * stride) where the arithmetic can WRAP before a bounds check or before it indexes / ' +
      'allocates -- so a large count wraps small, passes the check, then over-reads/over-writes.  u32*u32 wraps ' +
      'mod 2^32.  Trace a concrete count that wraps the product past a guard.  (NOT the already-swept idx>=N ' +
      'getters -- this is the SIZE arithmetic feeding them.)\n' + FOCUS,
  },
  {
    key: 'off-by-one',
    prompt: 'Lens: OFF-BY-ONE / inclusive-vs-exclusive bound in ' + ROOT + '.  Find an @export whose loop or ' +
      'bound check uses `<=` where `<` is meant (or `idx > N` where `idx >= N` is meant) against an array of ' +
      'size N -- touching index N (one past the end) or, conversely, skipping the last valid element.  Look at ' +
      'while-loop conditions `i <= n`, guards `if idx > LEN { reject }` (should be `>=`), and copy/fill ranges.  ' +
      'Trace the boundary index concretely and show the 1-past OOB or the dropped element.\n' + FOCUS,
  },
  {
    key: 'signed-sentinel',
    prompt: 'Lens: SIGNED-SENTINEL-vs-UNSIGNED-COMPARE in ' + ROOT + '.  iiis compiles i32 ordering UNSIGNED.  ' +
      'Find an @export (or an internal fn it calls) that stores a NEGATIVE sentinel / error in an i32 (e.g. ' +
      'return -1i32 for "not found", or a signed delta) and then a caller GUARDS with `x < 0i32` / `x <= 0i32` / ' +
      '`x >= 0i32` to detect it -- that ordering compiles UNSIGNED so the negative value (high bit set) compares ' +
      'as a HUGE positive: `x < 0i32` is always false, `x >= 0i32` always true -> the error path is DEAD and the ' +
      'sentinel is used as a real index/value.  Distinguish from == / != checks (those are fine).  Trace the ' +
      'concrete sentinel and the dead branch.\n' + FOCUS,
  },
]

phase('Discover')
log('W27 fresh-axis discovery: ' + LENSES.length + ' lenses (error-swallow / int-overflow / off-by-one / signed-sentinel)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III defect by HAND-TRACING the code (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nConcrete input: ' + c.concrete_input + '\nClaimed wrong output: ' + c.wrong_output +
  '\nClaimed correct output: ' + c.correct_output + '\n\n' +
  'Open the file, read ' + c.fn + ' and the fns it calls, and hand-execute with the concrete input.  Mark REAL ' +
  'only if: (1) @export (or reachable from one -- name the @export); (2) the traced result is genuinely WRONG ' +
  '(not a documented contract, not caller-guaranteed precondition); (3) you can state a falsifier KAT that ' +
  'reddens pre-fix and passes post-fix WITHOUT a wild OOB (use a gentle exactly-1-past probe detected via a ' +
  'return value, or a value-differential).  For int-overflow/off-by-one show the exact boundary arithmetic.  ' +
  'For signed-sentinel confirm the type is i32 (NOT i64/u32) and the compare is ordering (NOT ==/!=).  If it is ' +
  'a documented contract, caller-guaranteed, or already guarded, mark real=false + explain.\n' + FOCUS

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
const confirmed = flat.filter((v) => v.real === true)
log('W27 fresh-axis complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
