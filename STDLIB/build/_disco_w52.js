export const meta = {
  name: 'iii-w52-errorswallow-nonnumera',
  description: 'W52: rotate the error-state/error-swallow axis (cad W29, elias W51) to the NON-numera subsystems -- the densest cross-module-fallible-call surface (aether net/backends, omnia resolver/dispatch/transpilers, sanctus fs/seal, forcefield ripple, verba emit). A function with a real -> i32 error channel calls a fallible dependency, DISCARDS its return, and reports SUCCESS -> a silent wrong/partial result. Adversarial refute.',
  phases: [ { title: 'Find' }, { title: 'Refute' } ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const IIIDIR = ROOT + '\\STDLIB\\iii'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'aether_net', files: 'aether/http.iii aether/http_server.iii aether/http_client.iii aether/tcp.iii aether/net.iii aether/backend_ipc.iii aether/backend_loopback.iii aether/backend_remote.iii aether/sealed_channel.iii aether/idoc.iii aether/babel_wire.iii aether/manifest.iii' },
  { key: 'aether_fed', files: 'aether/fed_admit.iii aether/fed_seal.iii aether/fed_genesis.iii aether/cap_handshake.iii aether/cap_forge.iii aether/node_identity.iii aether/witness_compactor.iii aether/reach_store.iii aether/snapshot_lattice.iii aether/fs.iii' },
  { key: 'omnia_resolver', files: 'omnia/resolver.iii omnia/resolver_memo.iii omnia/prespec.iii omnia/proof_resolve.iii omnia/proof_ripple.iii omnia/codegen_dispatch.iii omnia/transform.iii omnia/unify.iii omnia/sandbox_exec.iii omnia/sandbox_ctor.iii omnia/self_reformatter.iii' },
  { key: 'omnia_tp', files: 'omnia/tp_babel_json_cbor.iii omnia/tp_babel_cbor_json.iii omnia/tp_iii_to_c99.iii omnia/tp_c99hdr_to_iii.iii omnia/tp_iii_to_ast_bin.iii omnia/tp_ast_bin_to_iii.iii omnia/tp_x86_assemble.iii omnia/tp_pe_hex.iii omnia/tp_asm_to_pe.iii omnia/babel.iii' },
  { key: 'sanctus_seal', files: 'sanctus/seal_resolver.iii sanctus/mhash.iii sanctus/kchain.iii sanctus/attest.iii sanctus/witness.iii sanctus/closure.iii sanctus/promote.iii sanctus/demote.iii sanctus/catalyst.iii sanctus/genesis.iii sanctus/resolver_replay.iii' },
  { key: 'forcefield_verba', files: 'forcefield/ripple_journal.iii forcefield/ripple_extract.iii forcefield/ripple_synthesizer.iii forcefield/pleroma.iii forcefield/cg_autocatalyst.iii forcefield/commit_gate.iii verba/builder.iii verba/json.iii verba/csv.iii verba/glyph_record.iii verba/hip.iii' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'line', 'fallible_callee', 'how_it_can_fail', 'why_swallowed', 'trigger_input', 'wrong_observable', 'reachable_export', 'has_kat', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string' }, line: { type: 'number' },
      fallible_callee: { type: 'string', description: 'the fallible fn whose error return is discarded (it returns i32/error and CAN fail)' },
      how_it_can_fail: { type: 'string', description: 'the concrete failure mode of the callee (overflow, full table, uninit backend, OS error, bad input) and that it is REACHABLE' },
      why_swallowed: { type: 'string', description: 'the caller discards the return + hardcodes success / continues' },
      trigger_input: { type: 'string' }, wrong_observable: { type: 'string', description: 'the silent wrong result (false success, partial output, corrupt state) observable via @export' },
      reachable_export: { type: 'boolean' }, has_kat: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason'],
  properties: { is_real_defect: { type: 'boolean' }, reason: { type: 'string' }, proposed_teeth: { type: 'string' } },
}

const FIND_PROMPT = (g) => `You are auditing the III stdlib for the ERROR-SWALLOW defect class (cad W29: swallowed a sha256-backend failure -> silently-wrong digest; elias W51: swallowed a bitio overflow -> silently-truncated codeword).  The shape: a function with a REAL error channel (returns i32/error code) calls a FALLIBLE dependency, DISCARDS its return, and reports SUCCESS (or continues) -> a SILENT wrong/partial result.
Read these files under ${IIIDIR}: ${g.files}

For each function: find calls to a FALLIBLE callee (one that returns i32/an error code AND can actually fail on
a reachable input -- e.g. a buffer/handle/table-full overflow, an uninitialized backend, an OS error, a bad
sub-input).  Check whether the caller:
 - DISCARDS the return (statement-level call, not checked) AND reports success / continues as if it worked, OR
 - checks it but then OVERRIDES with a hardcoded success.
The defect requires the callee's failure to be REACHABLE and to produce a SILENT wrong OBSERVABLE (false
success code, partial/corrupt output, wrong digest/state) -- not a crash (memory-safety is separate).

HARD GATES -- drop unless ALL hold:
 - the callee CAN fail on a REACHABLE input (name the failure mode + how to trigger it).  If the callee never
   fails in practice (its precondition is always met by construction), DROP.
 - the caller REPORTS SUCCESS / continues despite the failure (the swallow).  If it propagates / aborts, DROP.
 - a SILENT WRONG OBSERVABLE via an @export (false success, corrupt output).  If the failure is harmless
   (the partial result is still correct, or a later step re-checks), DROP.
 - reachable from an @export.

Many III functions propagate errors correctly or call infallible-by-construction helpers.  ZERO findings is
honest.  Only report a swallow you traced: the fallible callee + its reachable failure + the caller's success
report + the wrong observable.  Return JSON.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const candidates = found.filter(Boolean).flat().filter(f => f.reachable_export && f.confidence >= 0.5)
log(`Find complete: ${candidates.length} candidate(s) (of ${found.filter(Boolean).flat().length} raw)`)
if (candidates.length === 0) {
  return { confirmed: [], note: 'no error-swallow defect survived the self-gate; the non-numera subsystems propagate errors or call infallible-by-construction helpers' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier for a claimed ERROR-SWALLOW defect (cad W29 / elias W51 class) in the III stdlib.

CLAIM: ${IIIDIR}\\${c.file} ${c.fn} (line ~${c.line})
  fallible callee: ${c.fallible_callee} -- fails via: ${c.how_it_can_fail}
  swallow: ${c.why_swallowed}
  trigger: ${c.trigger_input} -> wrong observable: ${c.wrong_observable}

Read the source + grep ${CORPUS} for the fn.  Kills:
 (1) CALLEE INFALLIBLE-IN-PRACTICE: trace the callee's failure precondition -- is it ALWAYS met by construction
     at this call site (validated upstream, a fixed-size that always fits, a backend always init'd first)?  If
     it cannot fail HERE, REFUTE.
 (2) ACTUALLY PROPAGATED: does the caller in fact check/propagate/abort (maybe indirectly via a flag or a later
     guard)?  If the error is not really swallowed, REFUTE.
 (3) HARMLESS: is the post-failure observable actually still CORRECT, or re-validated by a downstream gate
     before use?  If no silent wrong result reaches an @export consumer, REFUTE.
 (4) UNREACHABLE / out-of-contract / already-tested / mis-read.
Default is_real_defect=FALSE unless it SURVIVES all.  If real, give the value-differential teeth (the @export
call that triggers the callee failure, returning false-success pre-fix vs the propagated error post-fix), and
how to construct the reachable failure.  Cite source lines + KAT.`,
    { label: `refute:${c.file}:${c.fn}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))
const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log(`Refute complete: ${confirmed.length} confirmed of ${candidates.length}`)
return {
  confirmed: confirmed.map(c => ({ file: c.file, fn: c.fn, line: c.line, fallible_callee: c.fallible_callee,
    how_it_can_fail: c.how_it_can_fail, trigger_input: c.trigger_input, wrong_observable: c.wrong_observable,
    proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
