export const meta = {
  name: 'iii-at-scale-scan7-unchecked-failure',
  description: 'Read-only fan-out over III for IGNORED FAILURE/SENTINEL RETURNS -- a call whose error/exhaustion/NULL return is used as if it succeeded (handle-table exhausted -> degenerate slot used as valid; alloc returns 0 -> dereferenced; a write/verify that returned an error code whose value is then ignored). The dual of scans 5/6 (bad input) -- here a real FAILURE SIGNAL is dropped.',
  phases: [
    { title: 'Scan', detail: 'one Explore agent per failure-return-dense cluster; find a sentinel/error return consumed without a check' },
    { title: 'Verify', detail: 'adversarially confirm the unchecked return is a real reachable failure used as success, default-refute' },
  ],
}

const ROOT = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const CLUSTERS = [
  { name: 'handle-tables', path: 'STDLIB/iii (bigint/arena/region/lru/handle pools)', hint: 'a *_new / *_alloc / *_acquire that returns a SENTINEL on exhaustion (0, 0xFFFFFFFF, a degenerate slot) -- find callers that use the returned handle WITHOUT checking the sentinel, then index a pool with it (the bigint 64-slot-exhaustion class: bigint_new returns a zero-reading degenerate slot)' },
  { name: 'numera-returns', path: 'STDLIB/iii/numera', hint: 'bigint/field/ecdsa/rsa ops returning an i32/u8 status (0=ok / nonzero=err, or 1=ok/0=fail) whose return value is DISCARDED by the caller -> proceeds on a failed modinv/sqrt/decode; also alloc/handle returns used unchecked' },
  { name: 'verba-parse',  path: 'STDLIB/iii/verba', hint: 'json/csv/base32/64/hex/utf8 decoders returning an error code or a 0/sentinel length that a caller ignores -> uses an unfilled/partial buffer as if parsed; a *_get returning a not-found sentinel consumed as a valid index' },
  { name: 'os-membrane', path: 'STDLIB/iii (io/fs/net/os wrappers)', hint: 'a libc/syscall wrapper (fopen/fread/fwrite/malloc/recv/send) whose NULL/short-count/-1 return is not checked before the result is used -- NIH wrappers that drop the C error contract' },
  { name: 'forcefield-engine', path: 'STDLIB/iii/forcefield', hint: 'the self-enhancement engine itself: ripple_metric/commit_gate/integrity/optinvoke/pcc returning a verdict/error whose value is assumed-ok by the next stage -> a gate that FAILED treated as PASSED (the worst case: the engine trusting its own unchecked failure)' },
  { name: 'sanctus-witness', path: 'STDLIB/iii (sanctus + aether witness/seal)', hint: 'attest/closure/seal/witness_hook/quarantine ops returning a status whose failure is dropped -> a seal that did not actually seal, a witness publish that silently failed, treated as success' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['cluster', 'findings'],
  properties: {
    cluster: { type: 'string' },
    findings: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['symbol', 'files', 'sentinel', 'caller_site', 'consequence', 'fix', 'est_value', 'risk'],
        properties: {
          symbol: { type: 'string' },                  // the function whose failure return is dropped
          files: { type: 'array', items: { type: 'string' } },  // file:line of the call + the unchecked use
          sentinel: { type: 'string' },                 // the exact failure value (0 / 0xFFFFFFFF / err code) + when it occurs
          caller_site: { type: 'string' },              // where the return is consumed without a check
          consequence: { type: 'string' },              // what wrong thing happens when the dropped failure is used
          fix: { type: 'string' },
          est_value: { type: 'integer', minimum: 1, maximum: 5 },
          risk: { type: 'string' },
        },
      },
    },
  },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['real', 'why', 'blockers'],
  properties: { real: { type: 'boolean' }, why: { type: 'string' }, blockers: { type: 'string' } },
}

phase('Scan')
const scans = (await parallel(CLUSTERS.map(c => () =>
  agent(
`Read-only analysis of III for IGNORED FAILURE/SENTINEL RETURNS in "${c.name}" (${c.hint}) under ${ROOT}.
Find a function that returns a FAILURE SIGNAL -- a sentinel handle (0, 0xFFFFFFFF, a degenerate slot), a
NULL pointer, a short/zero count, or an error STATUS CODE -- where a REACHABLE caller CONSUMES the return
as if it succeeded (no check), and that leads to a concrete wrong outcome (OOB index with a sentinel handle,
deref of NULL, use of an unfilled buffer, a gate that FAILED treated as PASSED). The canonical III example:
a handle-table *_new returns a degenerate slot on exhaustion and the caller indexes the pool with it,
producing a value-INDEPENDENT failure that looks like an arithmetic bug.
For each: cite file:line of BOTH the failing call AND the unchecked use, name the exact sentinel + the
condition that produces it, and the consequence.
Be SOURCE-GROUNDED and CALIBRATED: a return that IS checked (the caller branches on it), a function that
cannot fail in practice (its precondition is established by a prior check), or a status deliberately ignored
because the next op re-validates -- those are NOT bugs, say so. NEVER invent; "all failure returns are
checked or the callers re-validate" is a valuable correct answer. Rank by est_value (1-5; 5 = a reachable
dropped failure with a concrete wrong outcome).`,
    { label: `s7:${c.name}`, phase: 'Scan', schema: FIND_SCHEMA, agentType: 'Explore' }))))
  .filter(Boolean)

const all = scans.flatMap(s => (s && s.findings) ? s.findings.map(x => ({ ...x, cluster: s.cluster })) : [])
log(`${all.length} raw unchecked-failure findings across ${scans.length} clusters`)

phase('Verify')
const top = all.filter(f => f.est_value >= 3).sort((a, b) => b.est_value - a.est_value).slice(0, 12)
if (top.length === 0) {
  log('No est_value>=3 dropped failures -- III callers check their failure returns / re-validate (honest abstention).')
  return { confirmed: [], raw_count: all.length, scanned: scans.length, verdict: 'failures-checked' }
}
const verified = (await parallel(top.map(f => () =>
  agent(
`Adversarially VERIFY this III dropped-failure finding. DEFAULT TO refuted (real=false) if uncertain.
Finding: ${JSON.stringify(f)}
Read the cited files + the corpus KAT under ${ROOT}. Confirm ALL of: (1) the function genuinely RETURNS a
failure signal under a REACHABLE condition (show it); (2) the cited caller CONSUMES the return WITHOUT a
check (no branch on the sentinel/error before the use); (3) the use produces a concrete wrong outcome (OOB,
NULL-deref, partial-buffer-as-valid, failed-gate-as-passed); (4) NO later re-validation or established
precondition makes the drop safe (if there is one, REFUTE). Distinguish a genuine dropped failure from a
status deliberately ignored because correctness is re-established downstream. Return {real, why (cite
file:line of BOTH sites), blockers}.`,
    { label: `v7:${f.symbol}`.slice(0, 40), phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
    .then(v => ({ ...f, verdict: v })))))
  .filter(Boolean)

const confirmed = verified.filter(v => v.verdict && v.verdict.real)
return { confirmed, raw_count: all.length, scanned: scans.length, verified: verified.length }
