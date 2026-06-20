export const meta = {
  name: 'iii-defect-discovery-w30',
  description: 'Store-then-validate corrupt-state, div-by-zero round 2, unsigned-underflow, capacity-overflow',
  phases: [
    { title: 'Discover', detail: '4 missing-guard deep reads, read-only' },
    { title: 'Verify', detail: 'confirm with a concrete input + a GENTLE teeth' },
  ],
}

const FOCUS = [
  'CONTEXT: the missing-input-validation vein keeps producing clean-teeth defects (W24 bigint, W25 threshold_',
  'vault, W26 crt + rn_graph_root).  The richest sub-pattern is STORE-THEN-VALIDATE: an @export writes a',
  'caller value into a MODULE GLOBAL *before* a validation/sub-op that can fail, so a FAILED call leaves the',
  'global in a corrupt/over-large state, and a LATER @export reads it as a loop bound / index / size -> OOB',
  'or wrong result (this is exactly how threshold_vault tv_seal stored kkey before shamir_split could fail,',
  'and tv_open then over-ran on it).  CONTRAST: a VALIDATE-THEN-STORE @export (es_encode checks k before',
  'storing ES_PN[1]) is SAFE -- the global can never hold a bad value, so its reader needs no guard (declined).',
  'A finding is REAL only with: (1) an @export entry; (2) a CONCRETE input/sequence; (3) the WRONG observable;',
  '(4) you TRACED it; (5) a GENTLE teeth (the failing call returns a DIFFERENT error code post-fix, or a',
  'follow-up read differs) is STRONGLY preferred over a crash-class one.  iiis facts: u32/u64 wrap mod 2^k;',
  'i32 ordering UNSIGNED; integer div/mod by 0 traps.',
  '',
  'BEFORE proposing a fix you MUST note any EXISTING corpus test or in-tree caller of the function (a contract',
  'test encodes INTENDED behavior -- a "missing" guard may be deliberate, e.g. option_u64_drop idempotent).',
  '',
  'DO NOT REPORT (covered): threshold_vault kkey (W25); crt_solve zero-modulus + rn_graph_root overflow (W26);',
  'bigint_new cap*8 (W24); es_reconstruct (validate-then-store, safe); option_u64_drop (idempotent BY DESIGN);',
  'accessor idx>=N getters (10-20); error-swallow trio fed_seal/reach_emit/wh_compute_frag_id (deferred).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        axis: { type: 'string', description: 'store-then-validate | div-by-zero | unsigned-underflow | capacity-overflow' },
        description: { type: 'string' },
        concrete_input: { type: 'string' }, wrong_output: { type: 'string' }, correct_output: { type: 'string' },
        existing_test_or_caller: { type: 'string', description: 'any corpus test / in-tree caller of this fn, and whether the missing guard looks deliberate' },
        gentle_teeth: { type: 'string' }, is_export: { type: 'boolean' }, confidence: { type: 'number' },
      },
      required: ['file', 'fn', 'line', 'axis', 'description', 'concrete_input', 'wrong_output', 'correct_output', 'existing_test_or_caller', 'gentle_teeth', 'is_export', 'confidence'],
    } },
  },
  required: ['candidates'],
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
    real: { type: 'boolean' }, traced_result: { type: 'string' }, correct_result: { type: 'string' },
    contract_check: { type: 'string', description: 'existing corpus test / caller contract -- does the fix violate it?' },
    teeth_idea: { type: 'string' }, fix: { type: 'string' }, refutation: { type: 'string' },
  },
  required: ['file', 'fn', 'line', 'real', 'refutation'],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const ROOT = REPO + '/STDLIB/iii/'

const LENSES = [
  {
    key: 'store-then-validate',
    prompt: 'Lens: STORE-THEN-VALIDATE corrupt-state in ' + ROOT + ' (the threshold_vault tv_seal class).  Find ' +
      'an @export that writes a CALLER value into a MODULE GLOBAL (a *_PN/*_CFG/*_N/*_LEN/*_COUNT/params array, ' +
      'a stored capacity, a head/limit) BEFORE a later validation or sub-call that can FAIL and return early -- ' +
      'so a failed call PERSISTS the unvalidated value, and a SEPARATE @export (open/decode/reconstruct/iterate/' +
      'finalize) later reads it as a loop bound / index / size and over-runs or mis-computes.  Confirm the order ' +
      '(store at line X, the failing check at line Y > X) and name the reader.  Trace the seal-fails-then-read ' +
      'sequence.  GENTLE teeth: the failing call should return a DIFFERENT error code once the validation moves ' +
      'BEFORE the store.\n' + FOCUS,
  },
  {
    key: 'div-by-zero-2',
    prompt: 'Lens: DIVISION / MODULO BY ZERO (round 2) across ' + ROOT + ' OUTSIDE crt.iii.  Find an @export (or ' +
      'a fn it calls) that divides or mods by a value that can be 0 -- a caller param, a stored global, a ' +
      'computed denominator (count, stride, modulus, hash-table size, gcd step, rate, average = sum/n) -- with ' +
      'no `== 0 -> reject/skip` guard.  Especially average/mean/rate/ratio @exports (sum / count where count ' +
      'can be 0), hash/ring sizing (x % cap where cap can be 0), modular inverse / gcd helpers.  Trace the 0 ' +
      'denominator and the SIGFPE / wrong result.\n' + FOCUS,
  },
  {
    key: 'unsigned-underflow',
    prompt: 'Lens: UNSIGNED UNDERFLOW driving size/index/loop in ' + ROOT + '.  Find an @export computing `a - b` ' +
      'on u32/u64 where b can exceed a (length - offset, end - start, remaining = cap - used, count - 1 when ' +
      'count can be 0, a decremented head/tail) -- the result wraps to a huge value then used as a size, loop ' +
      'bound, or index -> OOB / huge alloc / runaway loop.  Trace concrete (a,b) with b>a and the wrap.  (NOT a ' +
      'subtraction proven b<=a by an earlier guard.)\n' + FOCUS,
  },
  {
    key: 'capacity-overflow',
    prompt: 'Lens: CAPACITY OVERFLOW on append/push/enqueue in ' + ROOT + '.  Find an @export that appends to a ' +
      'fixed-size buffer/pool (ring, builder, stack, outbox, freelist, journal, trace) incrementing a head/count ' +
      'with NO `count >= CAP -> reject` check before the write, or with the WRONG comparison (`>` vs `>=`, or ' +
      'checking AFTER the write) -- so repeated appends write past the buffer or wrap destructively.  Especially ' +
      '*_push/_append/_add/_emit/_enqueue/_record/_log.  Trace the overflowing append and the OOB write / lost ' +
      'or clobbered element.\n' + FOCUS,
  },
]

phase('Discover')
log('W30 missing-validation-2 discovery: ' + LENSES.length + ' lenses')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III defect by HAND-TRACING the code (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nConcrete input: ' + c.concrete_input + '\nClaimed wrong: ' + c.wrong_output +
  '\nClaimed correct: ' + c.correct_output + '\nNoted existing test/caller: ' + c.existing_test_or_caller +
  '\nProposed gentle teeth: ' + c.gentle_teeth + '\n\n' +
  'Open the file, read ' + c.fn + ' + the fns it calls + the global reader (for store-then-validate).  Hand-' +
  'execute the concrete input/sequence.  CRITICAL: grep/think about an EXISTING corpus test or in-tree caller -- ' +
  'a contract test (often *_prov/_path/_kat) may make the "missing" guard DELIBERATE (e.g. option_u64_drop is ' +
  'idempotent by design); if so, mark real=false.  Mark REAL only if: (1) @export (name it); (2) genuinely WRONG ' +
  '(not a documented contract, not caller-guaranteed, not already guarded); (3) the fix does NOT break an ' +
  'existing contract test; (4) a falsifier KAT reddens pre-fix / passes post-fix (assess whether the gentle ' +
  'teeth works or it must be crash-class).  For store-then-validate confirm store-line < fail-line AND name the ' +
  'reader that over-runs.  Fill contract_check with the existing test/caller you considered.\n' + FOCUS

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
log('W30 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
