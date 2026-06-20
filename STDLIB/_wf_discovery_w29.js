export const meta = {
  name: 'iii-defect-discovery-w29',
  description: 'Missing-input-validation vein: div/mod-by-zero, unchecked count->loop/index, unsigned-underflow, capacity-overflow',
  phases: [
    { title: 'Discover', detail: '4 missing-guard deep reads, read-only' },
    { title: 'Verify', detail: 'confirm with a concrete input -> crash/OOB/wrong, and a GENTLE teeth' },
  ],
}

const FOCUS = [
  'CONTEXT: the cleanest-teeth vein on this tree is MISSING INPUT VALIDATION on a caller-supplied count /',
  'size / divisor that then drives memory access or arithmetic (W24 bigint cap*8 overflow, W25 threshold_',
  'vault kkey-> tv_open OOB loop both landed this way).  The IDEAL find: an @export stores or uses a caller',
  'value as a loop bound / index / divisor / allocation size with NO range or nonzero check, and a SIBLING',
  'or analogous param IS checked (a validation gap).  A finding is REAL only with: (1) an @export entry;',
  '(2) a CONCRETE input; (3) the WRONG observable (crash / OOB / div-by-zero / wrong value); (4) you TRACED',
  'the code; (5) a GENTLE falsifier idea -- prefer proving the guard REJECTS the bad input at the entry',
  '(a value differential, e.g. returns an error code) over triggering the unsafe code (a crash-class teeth',
  'is OK for a memory-safety guard but say so).  iiis facts: u32/u64 math wraps mod 2^k; i32 ordering is',
  'UNSIGNED; integer DIV/MOD by 0 traps (SIGFPE/crash).',
  '',
  'DO NOT REPORT (covered): bigint_new cap*8 (W24); threshold_vault kkey (W25); option_u64_drop (W25);',
  'accessor OOB idx>=N getters (waves 10-20); *_to_mont/reduce cold-init (W22/23); es_verify_shard',
  '(deferred); the error-swallow trio fed_seal/reach_emit/wh_compute_frag_id (known, hard-teeth, queued).',
].join('\n')

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    candidates: { type: 'array', items: {
      type: 'object', additionalProperties: false,
      properties: {
        file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
        axis: { type: 'string', description: 'div-by-zero | count-loop | unsigned-underflow | capacity-overflow' },
        description: { type: 'string' },
        concrete_input: { type: 'string' }, wrong_output: { type: 'string' }, correct_output: { type: 'string' },
        gentle_teeth: { type: 'string', description: 'how the guard rejects the bad input at entry with a value differential (preferred), or why it must be crash-class' },
        is_export: { type: 'boolean' }, confidence: { type: 'number' },
      },
      required: ['file', 'fn', 'line', 'axis', 'description', 'concrete_input', 'wrong_output', 'correct_output', 'gentle_teeth', 'is_export', 'confidence'],
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
    key: 'div-by-zero',
    prompt: 'Lens: DIVISION / MODULO BY ZERO in ' + ROOT + '.  Find an @export (or a fn it calls) that divides ' +
      'or takes modulo by a CALLER-SUPPLIED value (a count, stride, modulus, denominator, base) with NO prior ' +
      '`== 0 -> reject` check -- so a 0 argument traps (SIGFPE) or yields a wrong result.  Look at `/`, `%`, and ' +
      'div/mod helper calls where the divisor came from a parameter or a caller-set global.  Trace the concrete ' +
      '0 input and the crash/wrong result.  (NOT a divisor that is a compile-time nonzero constant or proven > 0 ' +
      'by an earlier guard.)\n' + FOCUS,
  },
  {
    key: 'count-loop',
    prompt: 'Lens: UNCHECKED COUNT/LENGTH driving a loop or index in ' + ROOT + ' (the threshold_vault class, ' +
      'elsewhere).  Find an @export that takes (or reads from a global) a count / length / n that bounds a ' +
      '`while i < n` loop writing/reading a FIXED-size buffer, with NO `n > CAP -> reject` check -- so a large n ' +
      'over-runs the buffer.  Especially split/encode/gather/reconstruct/serialize @exports with a share-count, ' +
      'shard-count, element-count, or field-count param.  Confirm a sibling count IS checked (a validation gap) ' +
      'and trace the concrete over-large n and the OOB.\n' + FOCUS,
  },
  {
    key: 'unsigned-underflow',
    prompt: 'Lens: UNSIGNED UNDERFLOW driving size/index in ' + ROOT + '.  Find an @export computing `a - b` on ' +
      'u32/u64 where b can exceed a (a length minus an offset, end minus start, remaining = total - used, a ' +
      'decrement of a counter that can be 0) -- the result wraps to a huge value then used as a size, loop bound, ' +
      'or index -> OOB / huge alloc / runaway loop.  Trace the concrete (a,b) with b>a and the wrapped result.  ' +
      '(NOT a subtraction proven b<=a by an earlier guard.)\n' + FOCUS,
  },
  {
    key: 'capacity-overflow',
    prompt: 'Lens: CAPACITY OVERFLOW on append/push in ' + ROOT + '.  Find an @export that APPENDS/PUSHES to a ' +
      'fixed-size buffer/pool (a ring, a builder, a stack, an outbox, a freelist) incrementing a head/count, ' +
      'with NO `count >= CAP -> reject/refuse` check before the write -- so repeated appends write past the ' +
      'buffer or wrap the index destructively.  Especially *_push / *_append / *_add / *_emit / *_enqueue ' +
      'whose capacity check is missing or uses the wrong comparison (`>` vs `>=`).  Trace the append that ' +
      'overflows and the OOB write or lost element.\n' + FOCUS,
  },
]

phase('Discover')
log('W29 missing-validation discovery: ' + LENSES.length + ' lenses (div-by-zero / count-loop / unsigned-underflow / capacity-overflow)')

const refutePrompt = (c) =>
  'CONFIRM or REFUTE this III defect by HAND-TRACING the code (read-only; no build).\n\n' +
  'File: ' + c.file + '\nFunction: ' + c.fn + ' (line ~' + c.line + ')\nAxis: ' + c.axis + '\n' +
  'Claim: ' + c.description + '\nConcrete input: ' + c.concrete_input + '\nClaimed wrong: ' + c.wrong_output +
  '\nClaimed correct: ' + c.correct_output + '\nProposed gentle teeth: ' + c.gentle_teeth + '\n\n' +
  'Open the file, read ' + c.fn + ' and the fns it calls, hand-execute with the concrete input.  Mark REAL only ' +
  'if: (1) @export (or reachable -- name it); (2) the traced result is genuinely WRONG (NOT a documented ' +
  'contract, NOT caller-guaranteed, NOT already guarded by an earlier check); (3) you can state a falsifier KAT ' +
  'that reddens pre-fix and passes post-fix -- ASSESS whether the proposed gentle teeth (guard rejects the bad ' +
  'input at entry -> value differential) actually works, or whether it must be crash-class.  For div-by-zero ' +
  'confirm the divisor is genuinely reachable as 0.  For count-loop / capacity confirm the buffer size and the ' +
  'missing check.  For underflow confirm b can exceed a.  If guarded / by-design / caller-guaranteed, mark ' +
  'real=false + explain.\n' + FOCUS

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
log('W29 missing-validation complete: ' + confirmed.length + ' CONFIRMED of ' + flat.length + ' examined')
return { confirmed: confirmed, examined: flat.length }
