export const meta = {
  name: 'iii-defect-discovery-w28',
  description: 'Fresh axes round 2: double-free/UAF, TOCTOU, aliasing/overlap, error-swallow round 2',
  phases: [
    { title: 'Discover', detail: '4 fresh-axis deep reads, read-only' },
    { title: 'Verify', detail: 'confirm with a concrete input -> wrong result/OOB/corruption' },
  ],
}

const FOCUS = [
  'CONTEXT: accessor-bounds, byte-pointer, protocol-lifecycle, use-before-init, and (W24) integer-overflow-',
  'in-size-math are MINED on this tree (waves 10-24).  These are the NEXT fresh axes.  A finding is REAL',
  'only with: (1) an @export entry; (2) a CONCRETE input/sequence; (3) the WRONG observable (wrong value /',
  'OOB / double-free / corruption / swallowed failure) vs the correct one; (4) you TRACED the real code,',
  'not a name.  iiis facts: i32 ordering compiles UNSIGNED (`x<0i32` always false); u32 math wraps mod 2^32;',
  'a function-LOCAL `var [T;N]` indexed by a RUNTIME var segfaults (hoist to module scope); BIGINT handle',
  'table = 64 slots.  Many handle/slot pools FREE ASYNCHRONOUSLY BY DESIGN (a deferred-free primitive) --',
  'that is NOT a double-free; only a SYNCHRONOUS release-then-reuse-without-revalidate is.',
  '',
  'DO NOT REPORT (covered/known): any *_to_mont/_from_mont/_reduce/_inv cold-init (W22/W23); accessor OOB',
  'getters/setters with idx>=N guards (waves 10-20); bigint_new cap*8 overflow (W24 FIXED); es_verify_shard',
  '(deferred benign-read); the bigint 64-slot handle-exhaustion + the arena ABA witness (both documented).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        axis: { type: 'string', description: 'double-free | uaf | toctou | aliasing | error-swallow' },
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
    teeth_idea: { type: 'string' }, fix: { type: 'string' }, refutation: { type: 'string' },
  },
  required: ['file', 'fn', 'line', 'real', 'refutation'],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const ROOT = REPO + '/STDLIB/iii/'

const LENSES = [
  {
    key: 'double-free-uaf',
    prompt: 'Lens: DOUBLE-FREE / USE-AFTER-FREE on SYNCHRONOUS handle/slot pools in ' + ROOT + '.  Find an ' +
      '@export that releases a slot/handle (clears a LIVE flag, returns it to a freelist) and a path where the ' +
      'SAME handle can be released TWICE (no LIVE re-check on the release path), or USED after release (a getter/' +
      'op that reads BASE/LEN without re-checking LIVE).  Look at *_drop / *_free / *_release / *_close pairs vs ' +
      'their getters.  CRITICAL: many pools free ASYNCHRONOUSLY BY DESIGN (deferred-free) -- that is a contract, ' +
      'NOT a bug; only a SYNCHRONOUS double-release / use-after-release with observable corruption counts.  Trace ' +
      'a concrete release-release or release-use sequence.\n' + FOCUS,
  },
  {
    key: 'toctou',
    prompt: 'Lens: TOCTOU check-then-use index mismatch in ' + ROOT + '.  Find an @export that bounds-CHECKS one ' +
      'index/length and then USES a DIFFERENT (or recomputed, or caller-mutated-in-between) index for the actual ' +
      'load/store -- so the check guards the wrong quantity.  E.g. `if a < N { ... arr[b] }` (checks a, indexes ' +
      'b); or checks len then reads len+1; or validates a handle then dereferences a stale copy.  Trace the ' +
      'concrete index that passes the check but the OTHER index is OOB.\n' + FOCUS,
  },
  {
    key: 'aliasing-overlap',
    prompt: 'Lens: ALIASING / OVERLAP corruption in ' + ROOT + '.  Find an @export doing a byte/limb COPY or MOVE ' +
      '(a forward `while i<n { dst[i]=src[i] }`, a memcpy-like, an in-place shift) that PRODUCES WRONG output when ' +
      'src and dst OVERLAP (caller passes the same slot, or dst > src within one buffer) -- a forward copy that ' +
      'should be backward, or an op that reads a lane after it overwrote it.  Especially in-place big-number ' +
      'shifts, polynomial rotations, ring-buffer compaction.  Trace a concrete overlapping (src,dst) giving the ' +
      'wrong bytes.  (NOT a documented "must not alias" contract -- only an @export that CLAIMS to support it or ' +
      'is called aliased in-tree.)\n' + FOCUS,
  },
  {
    key: 'error-swallow2',
    prompt: 'Lens: ERROR-CODE SWALLOWING (round 2, AWAY from numera crypto) in ' + ROOT + 'aether/, ' + ROOT +
      'omnia/, ' + ROOT + 'sanctus/, ' + ROOT + 'memoria/, ' + ROOT + 'verba/.  Find an @export that calls a ' +
      'fallible internal fn (returns an i32 err / negative / 0-or-1 ok-flag) and IGNORES it -- returning success / ' +
      'a stale value when the inner op actually failed (alloc fail, full table, verify-fail, parse-fail, seq gap).  ' +
      'Especially commit/seal/append/admit @exports whose inner check can fail but the wrapper hard-returns ok.  ' +
      'Trace one concrete failing input and the wrongly-OK result.\n' + FOCUS,
  },
]

phase('Discover')
log('W28 fresh-axis-2 discovery: ' + LENSES.length + ' lenses (double-free/uaf / toctou / aliasing / error-swallow2)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III defect by HAND-TRACING the code (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nConcrete input: ' + c.concrete_input + '\nClaimed wrong: ' + c.wrong_output +
  '\nClaimed correct: ' + c.correct_output + '\n\n' +
  'Open the file, read ' + c.fn + ' and the fns it calls, hand-execute with the concrete input/sequence.  Mark ' +
  'REAL only if: (1) @export (or reachable -- name it); (2) the traced result is genuinely WRONG (NOT a ' +
  'documented contract, NOT a by-design async-free, NOT a caller-guaranteed precondition); (3) you can state a ' +
  'falsifier KAT that reddens pre-fix and passes post-fix -- prefer a VALUE/return differential; a crash-class ' +
  'teeth is OK ONLY for a memory-safety guard (and say so).  For double-free confirm the release path has NO ' +
  'LIVE re-check AND the pool is SYNCHRONOUS (not deferred-free).  For toctou show the checked vs used index ' +
  'concretely.  For aliasing show the overlapping (src,dst).  If by-design / caller-guaranteed / already guarded, ' +
  'mark real=false + explain.\n' + FOCUS

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
log('W28 fresh-axis-2 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
