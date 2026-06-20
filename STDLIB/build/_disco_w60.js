export const meta = {
  name: 'iii-w60-aliasing-overlap',
  description: 'W60: an @export primitive taking 2+ same-typed pointers/handles/array-slots where a caller passing the SAME storage for both (in-place out==a, or src==dst overlap) gives a WRONG result because the body overwrites a destination cell before it finishes reading the aliased source cell (schoolbook mul into an aliased output; forward memcpy with overlap; in-place reversal). Confirmed = a REAL in-place caller (or a documented in-place contract) + a demonstrable read-after-overwrite. Adversarial refute: copies to temp first / fresh-handle functional / write-only / no aliasing caller and distinctness guarded.',
  phases: [ { title: 'Find' }, { title: 'Refute' } ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const OMNIA = ROOT + '\\STDLIB\\iii\\omnia'
const VERBA = ROOT + '\\STDLIB\\iii\\verba'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'bigint',    dir: NUMERA, files: 'bigint.iii bigint_mont.iii bigint_div.iii ntt_bigint.iii rsa.iii' },
  { key: 'field256',  dir: NUMERA, files: 'fp256.iii fn256.iii fp384.iii fn384.iii fe25519.iii' },
  { key: 'ec_poly',   dir: NUMERA, files: 'ec_p256.iii ed25519.iii mlkem.iii mldsa.iii ntt.iii ntt_ctx.iii poly1305.iii' },
  { key: 'memory',    dir: OMNIA,  files: 'span.iii arena.iii builder.iii vec.iii region.iii ring_buffer.iii' },
  { key: 'matrix',    dir: NUMERA, files: 'matrix_ring.iii bv_ring.iii gf_poly.iii rscode.iii rscode_ec.iii' },
  { key: 'codec',     dir: VERBA,  files: 'base64.iii base32.iii hex.iii leb128.iii utf8.iii string.iii' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'line', 'alias_params', 'alias_scenario', 'corruption_mechanism', 'alias_safe', 'real_inplace_caller', 'reachable_export', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
      alias_params: { type: 'string', description: 'which two params can refer to the SAME storage (e.g. out & a, dst & src)' },
      alias_scenario: { type: 'string', description: 'the concrete in-place call that aliases (e.g. bigint_mul(r, r, b); span_copy(buf+1, buf, n))' },
      corruption_mechanism: { type: 'string', description: 'the loop/line where dest[i] is written and an aliased source[j] is later read AFTER being overwritten, giving a wrong result. Cite the source line.' },
      alias_safe: { type: 'boolean', description: 'TRUE if the fn copies inputs to a temp / allocates a fresh result handle / is otherwise in-place safe (then it is NOT a defect)' },
      real_inplace_caller: { type: 'string', description: 'a concrete caller SITE (file:fn) that aliases, OR "contract documents in-place", OR "none found" if no aliasing caller exists' },
      reachable_export: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason'],
  properties: { is_real_defect: { type: 'boolean' }, reason: { type: 'string' }, proposed_fix: { type: 'string' }, proposed_teeth: { type: 'string' } },
}

const FIND_PROMPT = (g) => 'You are auditing the III stdlib for ALIASING / IN-PLACE OVERLAP defects.\n' +
'A primitive f(dst, a, b, ...) is alias-UNSAFE when a caller passing the SAME storage for the destination and a source (in-place: out==a, or src==dst with overlap) yields a WRONG result, because the body overwrites a destination cell BEFORE it finishes reading the aliased source cell.\n' +
'Canonical unsafe shapes:\n' +
' - schoolbook multiply / squaring writing limbs into an output that aliases an input (out[i+j] += a[i]*b[j] clobbers a/b if out==a);\n' +
' - forward byte/element copy dst[i]=src[i] for i in 0..n when dst and src ranges OVERLAP and dst>src (classic memcpy-vs-memmove);\n' +
' - in-place reversal / permutation dst[i]=src[N-1-i] with dst==src corrupting the second half;\n' +
' - any out param used as scratch while an aliased input is still needed.\n\n' +
'Read these files in ' + (g.dir === OMNIA ? 'STDLIB/iii/omnia' : (g.dir === VERBA ? 'STDLIB/iii/verba' : 'STDLIB/iii/numera')) + ': ' + g.files + '\n\n' +
'For each @export (or reachable) fn taking 2+ same-typed pointers/handles/array-offsets:\n' +
' 1. Decide whether a caller CAN legitimately alias the destination with a source (in-place is idiomatic for field/bigint arithmetic: a = a*a, x = x+y).\n' +
' 2. If yes, trace the body: is there a destination write followed by an aliased-source read that NEEDS the pre-write value? State the exact loop + line (corruption_mechanism).\n' +
' 3. Decide alias_safe: does it FIRST copy inputs to a temp/local, allocate a FRESH result handle (functional style), or only WRITE the destination (never read an aliased source after writing)? If so alias_safe=TRUE (NOT a defect).\n' +
' 4. Find a REAL in-place caller: grep the repo for a call site that passes the same storage for dst and a source, OR a doc/comment that says in-place is supported. Record file:fn. If none and the contract forbids aliasing, real_inplace_caller="none found".\n\n' +
'HARD GATES -- drop unless ALL hold:\n' +
' - a CONCRETE alias scenario (the exact two params + the in-place call form);\n' +
' - a demonstrable read-after-overwrite that changes the result (cite the source line);\n' +
' - alias_safe=FALSE (it does NOT copy to temp / fresh handle);\n' +
' - the fn feeds a reachable @export.\n\n' +
'Most primitives are EITHER functional (fresh result handle) OR copy inputs first OR are never aliased by any caller. A real aliasing defect is RARE. Report alias_safe=TRUE cases too (so the judge can confirm), but only report alias_safe=FALSE with confidence>=0.5 as candidate defects. Re-read the body carefully before claiming a read-after-overwrite -- do NOT guess. Return JSON.'

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: 'find:' + g.key, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const all = found.filter(Boolean).flat()
const candidates = all.filter(f => f.confidence >= 0.5 && f.alias_safe === false && f.reachable_export === true && f.real_inplace_caller && f.real_inplace_caller !== 'none found')
log('Find complete: ' + candidates.length + ' candidate(s) with a real aliasing caller (of ' + all.length + ' raw; ' + all.filter(f=>f.alias_safe===false).length + ' alias-unsafe, ' + all.filter(f=>f.alias_safe===true).length + ' alias-safe)')
if (candidates.length === 0) {
  return { confirmed: [], note: 'no alias-unsafe primitive with a real in-place caller survived the self-gate; the multi-pointer primitives are functional / copy-first / never aliased', alias_unsafe_no_caller: all.filter(f => f.alias_safe === false).map(f => ({ file: f.file, fn: f.fn, why_no_defect: f.real_inplace_caller })) }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent('Adversarial verifier for a claimed ALIASING / IN-PLACE OVERLAP defect in the III stdlib.\n\n' +
'CLAIM: ' + c.file + ' fn=' + c.fn + ' (line ~' + c.line + ')\n' +
'  alias params: ' + c.alias_params + '\n' +
'  in-place scenario: ' + c.alias_scenario + '\n' +
'  corruption: ' + c.corruption_mechanism + '\n' +
'  claimed real in-place caller: ' + c.real_inplace_caller + '\n\n' +
'Read the source + grep the repo (callers) + ' + CORPUS + '. Kills (REFUTE if ANY holds):\n' +
' (1) the fn copies the aliased input to a temp/local array BEFORE overwriting the destination (alias-safe) -- re-read the prologue;\n' +
' (2) it allocates a FRESH result handle / writes a distinct output buffer (functional, no in-place);\n' +
' (3) the destination is WRITE-ONLY of values not re-read from the aliased source after the write (no read-after-overwrite);\n' +
' (4) the claimed in-place caller does NOT actually alias (the two args are distinct storage / distinct handles) -- verify the call site;\n' +
' (5) the corruption read actually uses the post-write value harmlessly (the recomputed value equals the original) -- prove by hand;\n' +
' (6) unreachable / not an @export path.\n' +
'Default is_real_defect=FALSE unless it SURVIVES every kill. For a CONFIRMED defect: give the exact fix (copy-to-temp, or document+guard distinctness, or operate back-to-front) and the teeth (a falsifier that calls the fn with ALIASED args and gets the WRONG answer pre-fix, the RIGHT answer post-fix, vs the same fn with DISTINCT args as the oracle). Cite source lines.',
    { label: 'refute:' + c.file + ':' + c.fn, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))
const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log('Refute complete: ' + confirmed.length + ' confirmed of ' + candidates.length)
return {
  confirmed: confirmed.map(c => ({ file: c.file, fn: c.fn, line: c.line, alias_params: c.alias_params,
    alias_scenario: c.alias_scenario, corruption_mechanism: c.corruption_mechanism,
    real_inplace_caller: c.real_inplace_caller, proposed_fix: c.verdict.proposed_fix,
    proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
