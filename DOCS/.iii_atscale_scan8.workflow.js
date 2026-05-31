export const meta = {
  name: 'iii-at-scale-scan8-lifecycle',
  description: 'Read-only fan-out over III for RESOURCE-LIFECYCLE / TEMPORAL-SAFETY violations -- a handle/arena/region/builder/slot USED AFTER release (use-after-drop), DOUBLE-released, or USED BEFORE init. The temporal dual of scans 5/6/7 (spatial bounds / value wrap / dropped failure).',
  phases: [
    { title: 'Scan', detail: 'one Explore agent per lifecycle-dense cluster; find a resource consumed outside its live window' },
    { title: 'Verify', detail: 'adversarially confirm the temporal violation is reachable + a real defect, default-refute' },
  ],
}

const ROOT = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const CLUSTERS = [
  { name: 'handle-pools', path: 'STDLIB/iii (arena/region/bigint/lru/builder/handle tables)', hint: 'a slot/handle table where a handle is USED AFTER *_drop/*_release zeroed its slot (LIVE=0 but a stale handle still indexes it), a DOUBLE-drop corrupts the free list, or a slot is reused while an old handle still points at it (ABA). The bigint 64-slot pool + builder/lru/arena tables are the prime suspects.' },
  { name: 'sanctus-witness', path: 'STDLIB/iii/sanctus (legacy_artifact, sovereign_witness, attest, closure, seal, mhash, xii_*)', hint: 'the NEW Sovereign Witness modules + the seal/attest chain: a legacy_artifact used after la_drop, a sealed-then-mutated artifact, a witness digest read from a dropped artifact, a cad streaming context (cad_begin/payload/final) left half-open or interleaved across two callers.' },
  { name: 'forcefield-engine', path: 'STDLIB/iii/forcefield', hint: 'the self-enhancement engine resources: a cai table (ripple_metric/ripple_loop) read before cai_clear, ripple state reused across runs without reset, a commit_gate/integrity verdict cached across a state change, an optinvoke selection over a stale candidate set.' },
  { name: 'os-membrane', path: 'STDLIB/iii (fs/net/inet/http/io)', hint: 'an fd/socket/file handle USED AFTER close, a buffer freed-then-read, an http/inet parse state reused across requests, a connection handle double-closed.' },
  { name: 'numera-arena', path: 'STDLIB/iii/numera', hint: 'bigint/field/ecdsa/rsa arena lifecycle: a bigint handle used after bigint_drop_arena/arena_drop, an arena reset while live bigints reference it, a field/montgomery scratch reused across operations without re-init, an ecdsa context used after its arena was dropped.' },
  { name: 'verba-tempora', path: 'STDLIB/iii/verba + STDLIB/iii/tempora', hint: 'builder used after builder_drop/seal (push to a sealed builder), glyph/json/csv parse state reused, a sealed builder base pointer read after the arena moved (builder_grow realloc invalidates an old base pointer a caller cached), instant/deadline reused after reset.' },
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
        required: ['symbol', 'files', 'lifecycle', 'use_site', 'consequence', 'fix', 'est_value', 'risk'],
        properties: {
          symbol: { type: 'string' },                  // the resource + the function
          files: { type: 'array', items: { type: 'string' } },  // file:line of BOTH the release/init AND the use
          lifecycle: { type: 'string' },                // the release/init op + the window it defines
          use_site: { type: 'string' },                 // where the resource is used outside that window
          consequence: { type: 'string' },              // the concrete wrong outcome
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
`Read-only analysis of III for RESOURCE-LIFECYCLE / TEMPORAL-SAFETY bugs in "${c.name}" (${c.hint}) under ${ROOT}.
Find a resource (handle/slot/arena/region/builder/fd/scratch) that is CONSUMED OUTSIDE ITS LIVE WINDOW:
used after the op that RELEASES it (use-after-drop), DOUBLE-released, or used BEFORE the op that INITS it.
For each: cite file:line of BOTH the release/init AND the offending use, name the exact window, and the
concrete wrong outcome (stale-slot read, free-list corruption, ABA reuse, invalidated cached pointer).
Be SOURCE-GROUNDED and CALIBRATED: a handle whose validity is RE-CHECKED at the use (slot_of returns the
sentinel for a dropped handle), a resource that is single-owner and never aliased, or an op order the type
system / a guard enforces -- those are NOT bugs, say so. The bigint-handle table returning a degenerate
slot on a stale handle is value-INDEPENDENT and worth flagging; a builder_grow realloc invalidating a
cached base pointer is a classic. NEVER invent; "all resources are used within their live window / re-checked
at use" is a valuable correct answer. Rank by est_value (1-5; 5 = a reachable use-outside-window with a
concrete wrong outcome).`,
    { label: `s8:${c.name}`, phase: 'Scan', schema: FIND_SCHEMA, agentType: 'Explore' }))))
  .filter(Boolean)

const all = scans.flatMap(s => (s && s.findings) ? s.findings.map(x => ({ ...x, cluster: s.cluster })) : [])
log(`${all.length} raw lifecycle findings across ${scans.length} clusters`)

phase('Verify')
const top = all.filter(f => f.est_value >= 3).sort((a, b) => b.est_value - a.est_value).slice(0, 12)
if (top.length === 0) {
  log('No est_value>=3 lifecycle violations -- III resources are used within their live window / re-checked at use (honest abstention).')
  return { confirmed: [], raw_count: all.length, scanned: scans.length, verdict: 'lifecycle-clean' }
}
const verified = (await parallel(top.map(f => () =>
  agent(
`Adversarially VERIFY this III lifecycle/temporal-safety finding. DEFAULT TO refuted (real=false) if uncertain.
Finding: ${JSON.stringify(f)}
Read the cited files + the corpus KAT under ${ROOT}. Confirm ALL of: (1) the resource is genuinely RELEASED
(or not-yet-INITed) at a point reachable before the cited use; (2) the use actually CONSUMES it (reads its
slot / derefs it / mutates it) WITHOUT a re-validation that would catch the released/uninit state; (3) a
concrete wrong outcome follows (stale read, free-list/ABA corruption, invalid pointer); (4) NO guard
(slot_of re-checking LIVE, single-owner invariant, enforced op order) makes the use safe -- if there is one,
REFUTE. Distinguish a real use-outside-window from a handle that is harmlessly re-validated at every use.
Return {real, why (cite file:line of BOTH the release/init AND the use), blockers}.`,
    { label: `v8:${f.symbol}`.slice(0, 40), phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
    .then(v => ({ ...f, verdict: v })))))
  .filter(Boolean)

const confirmed = verified.filter(v => v.verdict && v.verdict.real)
return { confirmed, raw_count: all.length, scanned: scans.length, verified: verified.length }
