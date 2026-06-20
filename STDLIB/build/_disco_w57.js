export const meta = {
  name: 'iii-w57-shared-global-clobber',
  description: 'W57: a function writes a MODULE-GLOBAL result buffer, then makes a CROSS-MODULE call that (transitively) CLOBBERS that same global (or a shared one), then reads the now-stale global -> a corrupted result.  The reentrancy / shared-scratch-clobber class (cad was flagged non-reentrant).  Over modules with global result buffers + interleaved cross-module calls.  Adversarial refute (captured-into-local-first? callee does not touch the global? unreachable interleave?).',
  phases: [ { title: 'Find' }, { title: 'Refute' } ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const OMNIA = ROOT + '\\STDLIB\\iii\\omnia'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'lattice_compose', dir: NUMERA, files: 'interval_lattice.iii reduced_product.iii loop_optimizer.iii affine_check.iii widening.iii cost_lattice.iii cost_lattice_unified.iii bce.iii value_range_prover.iii' },
  { key: 'field_mont', dir: NUMERA, files: 'fp256.iii fn256.iii fp384.iii fn384.iii modular_mont.iii barrett.iii ec256.iii ec384.iii fe25519.iii ed_scalar_modl.iii' },
  { key: 'bigint_ntt', dir: NUMERA, files: 'bigint.iii bigint_div.iii ntt.iii ntt_bigint.iii ntt_ctx.iii ntt_fri_organ.iii gf_poly.iii rscode.iii rscode_ec.iii' },
  { key: 'hash_state', dir: NUMERA, files: 'sha256_dispatch.iii cad.iii hmac.iii hkdf.iii pbkdf2.iii keccak_sponge.iii merkle.iii drbg.iii' },
  { key: 'category_cert', dir: NUMERA, files: 'category.iii costed_cat.iii certified_morphism.iii proof_term.iii theorem_carrier.iii translation_validation.iii matrix_ring.iii bv_ring.iii' },
  { key: 'omnia_compose', dir: OMNIA, files: 'xii_canonicalise.iii xii_lower_compose.iii xii_rewrite.iii resolver.iii unify.iii transform.iii sov_morphism.iii proof_resolve.iii' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'line', 'global_buf', 'write_then_call_then_read', 'clobbering_callee', 'wrong_observable', 'reachable_export', 'has_kat', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
      global_buf: { type: 'string', description: 'the module-global result buffer (e.g. IL_LO/IL_HI, MM_T, the fp256 slot pool, CAL_LAST_*)' },
      write_then_call_then_read: { type: 'string', description: 'the line sequence: A writes global G, then CALLS cross-module B, then READS G -- without capturing G into a local first' },
      clobbering_callee: { type: 'string', description: 'the cross-module callee B that (transitively) writes the same global G (name the path)' },
      wrong_observable: { type: 'string', description: 'the corrupted value A returns because it read B`s clobber instead of its own write' },
      reachable_export: { type: 'boolean' }, has_kat: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason'],
  properties: { is_real_defect: { type: 'boolean' }, reason: { type: 'string' }, proposed_teeth: { type: 'string' } },
}

const FIND_PROMPT = (g) => `You are auditing the III stdlib for SHARED-GLOBAL-BUFFER REENTRANCY bugs.  Many modules compute a result into a MODULE-GLOBAL buffer (e.g. interval_lattice IL_LO/IL_HI, the Montgomery MM_T scratch, the fp256 Montgomery slot pool, NTT_W, CAL_LAST_*, RP_LO/RP_HI) then read it back via a getter.  The BUG: a function writes global G, then makes a CROSS-MODULE (or recursive) call B BEFORE reading G, and B (transitively) WRITES THE SAME G -> the function reads B's clobber, returning a corrupted result.
Read these files in ${g.dir === OMNIA ? 'STDLIB/iii/omnia' : NUMERA}: ${g.files}

For each function: find the dangerous interleave -- WRITE a module-global result buffer G, then CALL a function
that touches G (a cross-module call, or a helper that calls back into the G-writing API), then READ G -- WITHOUT
having captured G into a LOCAL first.  Trace whether the callee (transitively) writes G.
 - The SAFE pattern (do NOT report): write G, immediately read G into a LOCAL, THEN call other things.  Or the
   callee provably never touches G.
 - The BUG pattern: il_X(...) ; <call that does il_Y(...)> ; il_lo()  -> il_lo() now returns il_Y's result.
   Or: a slot-pool op writes slot S, calls a cross-module fn that also uses slot S, then reads slot S.

HARD GATES -- drop unless ALL hold:
 - a CONCRETE write-G / call-B / read-G interleave where B provably (transitively) writes G (name the path).
 - the function does NOT capture G into a local before the call (if it does, no bug -> DROP).
 - reachable from an @export with a sequence that triggers it.
 - a WRONG OBSERVABLE: the function returns the clobbered (wrong) value.  Trace it.
 - NOT already correct: many modules write G then read it into a local IMMEDIATELY (the disciplined pattern) ->
   those are safe, DROP.

This tree is meticulous and usually captures the global into a local right after writing it.  The bug, if any,
is a rare interleave.  ZERO findings is honest.  Only report an interleave you traced (write G, call B that
writes G, read G).  Return JSON.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const candidates = found.filter(Boolean).flat().filter(f => f.reachable_export && f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) (of ${found.filter(Boolean).flat().length} raw)`)
if (candidates.length === 0) {
  return { confirmed: [], note: 'no shared-global reentrancy bug survived the self-gate; functions capture the global into a local before any interleaved call' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier for a claimed SHARED-GLOBAL REENTRANCY bug in the III stdlib.

CLAIM: ${c.file} ${c.fn} (line ~${c.line}) global=${c.global_buf}
  interleave: ${c.write_then_call_then_read}
  clobbering callee: ${c.clobbering_callee}
  wrong observable: ${c.wrong_observable}

Read the source of BOTH the function and the callee + grep ${CORPUS}.  Trace the interleave line by line.  Kills:
 (1) CAPTURED FIRST: does the function read the global into a LOCAL immediately after writing it, before the
     call?  If the value is captured before the clobber, no bug -> REFUTE.
 (2) CALLEE DOES NOT TOUCH G: trace the callee (and its transitive calls); if it never writes the global G,
     REFUTE.  (A different global, or a slot the function does not rely on, is not a clobber.)
 (3) UNREACHABLE INTERLEAVE: can an @export sequence actually produce write-G / call-B / read-G with B clobbering?
     If the order cannot occur, REFUTE.
 (4) ALREADY-TESTED / mis-read.
Default is_real_defect=FALSE unless it SURVIVES all.  If real, give the teeth (the @export sequence that returns
the clobbered value, vs the correct value), pre-fix vs post-fix, and the fix (capture into a local before the
call).  Cite both source fns + line numbers.`,
    { label: `refute:${c.file}:${c.fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))
const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log(`Refute complete: ${confirmed.length} confirmed of ${candidates.length}`)
return {
  confirmed: confirmed.map(c => ({ file: c.file, fn: c.fn, line: c.line, global_buf: c.global_buf,
    write_then_call_then_read: c.write_then_call_then_read, clobbering_callee: c.clobbering_callee,
    wrong_observable: c.wrong_observable, proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
