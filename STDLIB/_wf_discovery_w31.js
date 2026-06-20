export const meta = {
  name: 'iii-defect-discovery-w31',
  description: 'Div-by-zero r3, input-length-trust, unsigned-underflow, resource-leak-on-error',
  phases: [
    { title: 'Discover', detail: '4 lenses, read-only' },
    { title: 'Verify', detail: 'confirm + contract-check + GENTLE teeth' },
  ],
}

const FOCUS = [
  'CONTEXT: the missing-input-validation vein keeps producing clean-teeth defects (W24-W27: bigint,',
  'threshold_vault, crt, rn_graph_root, rms, sf_rou, temporal_logic).  Keep mining it AND diversify.  A',
  'finding is REAL only with: (1) an @export entry; (2) a CONCRETE input; (3) the WRONG observable (crash /',
  'OOB / div-by-zero / wrong value / leaked handle); (4) you TRACED it; (5) you NAMED any existing corpus',
  'test or in-tree caller (a contract test may make a "missing" guard DELIBERATE -- option_u64_drop is',
  'idempotent BY DESIGN; do not re-flag it); (6) a GENTLE teeth (guard rejects at entry -> value differential)',
  'is preferred; crash-class OK for a memory-safety/div-by-zero guard.  iiis facts: u32/u64 wrap mod 2^k;',
  'i32 ordering UNSIGNED; div/mod by 0 traps; a function-LOCAL var[T;N] indexed by a RUNTIME var segfaults.',
  '',
  'DO NOT REPORT (covered): bigint_new/threshold_vault/crt/rn_graph_root/rms/sf_rou/temporal_logic (W24-27);',
  'es_reconstruct (validate-then-store, safe); option_u64_drop (idempotent by design); accessor idx>=N',
  'getters (10-20); error-swallow trio fed_seal/reach_emit/wh_compute_frag_id (deferred); ident_copy aliasing',
  '(must-not-alias, no aliased caller).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        axis: { type: 'string', description: 'div-by-zero | input-length-trust | unsigned-underflow | resource-leak' },
        description: { type: 'string' },
        concrete_input: { type: 'string' }, wrong_output: { type: 'string' }, correct_output: { type: 'string' },
        existing_test_or_caller: { type: 'string' }, gentle_teeth: { type: 'string' },
        is_export: { type: 'boolean' }, confidence: { type: 'number' },
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
    contract_check: { type: 'string' }, teeth_idea: { type: 'string' }, fix: { type: 'string' }, refutation: { type: 'string' },
  },
  required: ['file', 'fn', 'line', 'real', 'refutation'],
}

const REPO = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const ROOT = REPO + '/STDLIB/iii/'

const LENSES = [
  {
    key: 'div-by-zero-3',
    prompt: 'Lens: DIVISION / MODULO BY ZERO (round 3) across ' + ROOT + ' OUTSIDE crt.iii / rms.iii / ' +
      'ntt_fri_organ.iii (already fixed).  Find an @export (or a fn it calls) that divides/mods by a value that ' +
      'can be 0 -- a caller param, a stored global, a computed denominator (count, stride, modulus, table size, ' +
      'rate, mean=sum/n, gcd/euclid step, scale factor) -- with no `==0 -> reject/skip` guard.  Especially ' +
      'statistics (avg/variance/percentile), hashing/ring sizing (x % cap), scheduling (period/rate), fixed-' +
      'point scaling.  Trace the 0 denominator and the SIGFPE / wrong result.\n' + FOCUS,
  },
  {
    key: 'input-length-trust',
    prompt: 'Lens: TRUSTED INPUT LENGTH/COUNT in ' + ROOT + ' (deserialize/parse/decode/ingest).  Find an @export ' +
      'that reads a LENGTH or COUNT field FROM caller-supplied bytes / a header / a record and then uses it as a ' +
      'loop bound, copy size, or index into a FIXED buffer WITHOUT checking it against the buffer capacity or the ' +
      'remaining input -- so a malformed/oversized length over-reads or over-writes.  Especially *_parse / ' +
      '*_decode / *_deserialize / *_ingest / *_load / *_read_record / TLV / varint-length readers.  Trace a ' +
      'concrete oversized length and the OOB.\n' + FOCUS,
  },
  {
    key: 'unsigned-underflow',
    prompt: 'Lens: UNSIGNED UNDERFLOW driving size/index/loop in ' + ROOT + '.  Find an @export computing `a - b` ' +
      'on u32/u64 where b can exceed a (length - offset, end - start, remaining = cap - used, count - 1 when ' +
      'count can be 0, len - header_size when len < header_size) -> wraps to a huge value used as a size / loop ' +
      'bound / index -> OOB / huge alloc / runaway loop.  Trace concrete (a,b) with b>a and the wrap.  (NOT a ' +
      'subtraction proven b<=a by an earlier guard.)\n' + FOCUS,
  },
  {
    key: 'resource-leak',
    prompt: 'Lens: RESOURCE LEAK on an ERROR path in ' + ROOT + '.  Find an @export that ACQUIRES a finite ' +
      'resource (a handle/slot from a fixed pool -- bigint_new, *_alloc, *_open, region/arena, a LIVE-flag slot) ' +
      'and then on a LATER error path returns EARLY without RELEASING it -- so repeated failing calls EXHAUST the ' +
      'pool (a slow leak -> later legitimate allocs fail).  Confirm the pool is FINITE + synchronous (not a GC/' +
      'by-design-deferred pool) and the early-return skips the matching *_drop/_free/_release.  Trace the acquire ' +
      '-> error-return-without-release sequence and the pool slot that leaks.  GENTLE teeth: acquire-fail-in-a-' +
      'loop then assert a fresh acquire still succeeds (post-fix) vs returns INVALID (pre-fix, pool drained).\n' + FOCUS,
  },
]

phase('Discover')
log('W31 discovery: ' + LENSES.length + ' lenses (div-by-zero-3 / input-length-trust / unsigned-underflow / resource-leak)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III defect by HAND-TRACING the code (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nConcrete input: ' + c.concrete_input + '\nClaimed wrong: ' + c.wrong_output +
  '\nClaimed correct: ' + c.correct_output + '\nNoted existing test/caller: ' + c.existing_test_or_caller +
  '\nProposed gentle teeth: ' + c.gentle_teeth + '\n\n' +
  'Open the file, read ' + c.fn + ' + the fns it calls.  Hand-execute the concrete input.  CRITICAL: consider an ' +
  'EXISTING corpus test / in-tree caller -- a contract test may make the "missing" guard DELIBERATE (mark ' +
  'real=false if so).  Mark REAL only if: (1) @export (name it); (2) genuinely WRONG (not contract/caller-' +
  'guaranteed/already-guarded); (3) the fix does not break an existing contract test; (4) a falsifier reddens ' +
  'pre-fix / passes post-fix (say whether gentle or crash-class).  For div-by-zero confirm the divisor reaches 0.  ' +
  'For input-length-trust show the buffer cap vs the trusted length.  For underflow show b>a.  For resource-leak ' +
  'confirm the pool is FINITE + synchronous and the error path skips the release.  Fill contract_check.\n' + FOCUS

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
log('W31 complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
