export const meta = {
  name: 'iii-w61-unsigned-sub-underflow',
  description: 'W61: an @export-reachable fn computes an UNSIGNED subtraction (a-b, len-off, end-start, cap-used, n-1 with n possibly 0) where the subtrahend can EXCEED the minuend for some REACHABLE input, wrapping to ~2^N, which then feeds a loop bound (while i < a-b), an allocation/copy/fill SIZE, an array INDEX, or defeats a (a-b) < size capacity check. The down-wrap twin of the overflow-in-verdict vein. Confirmed = a concrete reachable b>a + the wrapped value used dangerously + no guard. Adversarial refute: a prior check / structural invariant guarantees a>=b; the wrap is masked/clamped; the value is discarded; intended ring arithmetic.',
  phases: [ { title: 'Find' }, { title: 'Refute' } ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const OMNIA = ROOT + '\\STDLIB\\iii\\omnia'
const VERBA = ROOT + '\\STDLIB\\iii\\verba'
const MEMORIA = ROOT + '\\STDLIB\\iii\\memoria'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'codec',     dir: VERBA,   files: 'base64.iii base32.iii hex.iii leb128.iii utf8.iii string.iii json.iii' },
  { key: 'compress',  dir: NUMERA,  files: 'lzh.iii lzss.iii huffman.iii rscode.iii rscode_ec.iii bitio.iii' },
  { key: 'buffer',    dir: OMNIA,   files: 'span.iii builder.iii vec.iii ring_buffer.iii arena.iii region.iii' },
  { key: 'memoria',   dir: MEMORIA, files: 'span.iii heaplet.iii arena.iii' },
  { key: 'parse',     dir: VERBA,   files: 'lexer.iii parser.iii token.iii scan.iii' },
  { key: 'range',     dir: NUMERA,  files: 'interval_lattice.iii segment_tree.iii bv_bits.iii liveness.iii affine_check.iii loop_optimizer.iii' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'line', 'expr', 'minuend_src', 'subtrahend_src', 'reachable_bgta', 'wrapped_use', 'has_guard', 'reachable_export', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
      expr: { type: 'string', description: 'the unsigned subtraction expression (e.g. len - off, end - start, n - 1u32, cap - used)' },
      minuend_src: { type: 'string', description: 'where the minuend (a) comes from + its possible range' },
      subtrahend_src: { type: 'string', description: 'where the subtrahend (b) comes from + how it can EXCEED a for a reachable input' },
      reachable_bgta: { type: 'string', description: 'the CONCRETE reachable input that makes b > a (e.g. off=len for an empty/at-end buffer; a 0-length token; a count param of 0)' },
      wrapped_use: { type: 'string', enum: ['loop_bound', 'alloc_size', 'copy_fill_size', 'array_index', 'capacity_compare', 'other'] },
      has_guard: { type: 'boolean', description: 'is there an existing if b>a / if a<b / a>=b precondition before the subtraction?' },
      reachable_export: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason'],
  properties: { is_real_defect: { type: 'boolean' }, reason: { type: 'string' }, proposed_fix: { type: 'string' }, proposed_teeth: { type: 'string' } },
}

const FIND_PROMPT = (g) => 'You are auditing the III stdlib for UNSIGNED SUBTRACTION UNDERFLOW that produces a catastrophic value.\n' +
'In III, u32/u64 subtraction WRAPS: a - b with b > a yields a near-2^N value. The defect: such a wrapped value then feeds something dangerous:\n' +
' - a loop bound: while i < (a - b) { ... } iterates ~2^N times;\n' +
' - an allocation / copy / fill SIZE: alloc(a - b) or a memcpy length;\n' +
' - an array INDEX or offset: buf[a - b] or base + (a - b);\n' +
' - a capacity COMPARE: (a - b) < size passes wrongly because the huge value is NOT < size (or the inverse, (a-b) >= size).\n' +
'Common shapes: len - off (off can reach len, or exceed it for an at-end / empty buffer); end - start (start > end on a reversed/empty range); cap - used (used > cap after a miscount); n - 1 with n possibly 0; remaining = total - consumed (consumed > total).\n\n' +
'Read these files in ' + (g.dir === OMNIA ? 'STDLIB/iii/omnia' : (g.dir === VERBA ? 'STDLIB/iii/verba' : (g.dir === MEMORIA ? 'STDLIB/iii/memoria' : 'STDLIB/iii/numera'))) + ': ' + g.files + '\n\n' +
'For each @export (or reachable) fn:\n' +
' 1. Find every unsigned subtraction a - b (also a - b - c, len - 1, end - start).\n' +
' 2. Trace the minuend a and subtrahend b: can b EXCEED a for some REACHABLE input? Give the concrete input (an empty buffer, an at-end offset, a 0 count, a reversed range, a miscounted used). If a >= b is GUARANTEED by a prior check or a structural invariant (e.g. the loop only runs while off < len; b was just bounds-checked < a), it is NOT a defect.\n' +
' 3. Check the wrapped value is USED dangerously (loop bound / alloc / copy size / index / capacity compare). A wrapped value that is discarded or re-checked is harmless.\n' +
' 4. Check has_guard: is there an if b>a / if a<b / a>=b precondition before the subtraction?\n\n' +
'HARD GATES -- drop unless ALL hold:\n' +
' - a CONCRETE reachable input where b > a (state it; do NOT claim underflow if a>=b is structurally guaranteed -- trace the callers / the enclosing loop condition);\n' +
' - the wrapped value feeds a dangerous use (loop/alloc/copy/index/compare);\n' +
' - has_guard = false;\n' +
' - reachable @export.\n\n' +
'Most subtractions are guarded by an enclosing while (off < len) or a prior bounds-check, so a >= b holds -- those are NOT defects. A real reachable underflow is RARE. Re-read the enclosing control flow before claiming b>a is reachable -- the #1 false positive is missing the loop/if that guarantees a>=b. Only report has_guard=false with confidence>=0.55. Return JSON.'

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: 'find:' + g.key, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const all = found.filter(Boolean).flat()
const candidates = all.filter(f => f.confidence >= 0.55 && f.has_guard === false && f.reachable_export === true)
log('Find complete: ' + candidates.length + ' candidate(s) (of ' + all.length + ' raw; ' + all.filter(f=>f.has_guard===false).length + ' unguarded)')
if (candidates.length === 0) {
  return { confirmed: [], note: 'no reachable unsigned-subtraction underflow with a dangerous use and no guard survived the self-gate; the length arithmetic is guarded by enclosing loop/precondition invariants' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent('Adversarial verifier for a claimed UNSIGNED SUBTRACTION UNDERFLOW defect in the III stdlib.\n\n' +
'CLAIM: ' + c.file + ' fn=' + c.fn + ' (line ~' + c.line + ')\n' +
'  expr: ' + c.expr + '\n' +
'  minuend (a): ' + c.minuend_src + '\n' +
'  subtrahend (b): ' + c.subtrahend_src + '\n' +
'  reachable b>a: ' + c.reachable_bgta + '\n' +
'  wrapped value used as: ' + c.wrapped_use + '\n\n' +
'Read the source + trace callers + the enclosing control flow + grep ' + CORPUS + '. Kills (REFUTE if ANY holds):\n' +
' (1) a PRIOR check or the ENCLOSING loop/if guarantees a >= b (e.g. while (off < len) before len-off; an if (a < b) return earlier; b was just verified < a). Re-read the control flow around the line -- this is the #1 false positive.\n' +
' (2) a STRUCTURAL invariant guarantees a >= b for all reachable inputs (cap is always >= used by construction; end is always >= start because it is start + nonneg).\n' +
' (3) the wrapped value is masked / clamped / re-checked before the dangerous use, or is actually discarded.\n' +
' (4) the input that makes b>a is NOT reachable through any @export caller (the @export validates it first).\n' +
' (5) the subtraction is intended ring/modular arithmetic (the wrap is the spec).\n' +
' (6) unreachable / not an @export path.\n' +
'Be rigorous: to CONFIRM, you must exhibit a concrete @export call + arguments that reaches the line with b>a AND drives the dangerous use. Default is_real_defect=FALSE unless it SURVIVES. For a CONFIRMED defect: give the exact guard fix (if b>a return error / clamp) and the teeth (a falsifier that calls the @export with the b>a input and gets a catastrophic loop/alloc/index/wrong-compare pre-fix, a clean error post-fix). Cite source lines + the reaching call path.',
    { label: 'refute:' + c.file + ':' + c.fn, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))
const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log('Refute complete: ' + confirmed.length + ' confirmed of ' + candidates.length)
return {
  confirmed: confirmed.map(c => ({ file: c.file, fn: c.fn, line: c.line, expr: c.expr,
    reachable_bgta: c.reachable_bgta, wrapped_use: c.wrapped_use,
    proposed_fix: c.verdict.proposed_fix, proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
