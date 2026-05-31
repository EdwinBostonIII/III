export const meta = {
  name: 'iii-at-scale-scan5-accessor-bounds',
  description: 'Read-only fan-out over III ACCESSORS/getters: a public function that indexes a backing array/buffer on an untrusted index/count/offset WITHOUT a bounds guard -> OOB (the csv_field_base class of bug)',
  phases: [
    { title: 'Scan', detail: 'one Explore agent per accessor-dense cluster, diff guarded vs unguarded getters' },
    { title: 'Verify', detail: 'adversarially confirm the OOB is reachable + a real bug, default-refute' },
  ],
}

const ROOT = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const CLUSTERS = [
  { name: 'collections', path: 'STDLIB/iii (vec/map/set/queue/pq/list/lru/span/builder)', hint: 'find span/vec/map/set/queue/pq/list/lru/builder accessors -- *_at / *_get / *_byte(i) / *_peek -- that index the backing store on a caller index WITHOUT checking i < len/cap' },
  { name: 'numera-accessors', path: 'STDLIB/iii/numera', hint: 'bigint limb access, field/fe byte access, q128/fixed/checked accessors, hex/leb decoders -- index/offset on untrusted input without bound' },
  { name: 'verba-glyph',  path: 'STDLIB/iii/verba', hint: 'glyph_vec/glyph_str/glyph_map/glyph_set/glyph_record accessors + base32/base64/hex/format/uri/json getters -- byte(i)/at(i) without bound' },
  { name: 'witness-obs',  path: 'STDLIB/iii', hint: 'witness_root_byte / observability log/metric/trace getters / attest/closure/seal byte(i) accessors -- index into a fixed buffer without i<N' },
  { name: 'sid-carto',    path: 'STDLIB/iii', hint: 'sid graph node/edge/visualize accessors + cartographer/atlas getters + crystal/modifier byte accessors -- node/edge index without bound' },
  { name: 'tempora-net',  path: 'STDLIB/iii (tempora + net/inet/http)', hint: 'calendar/instant/deadline field access + inet/http header/field getters by index -- untrusted index into a buffer/array' },
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
        required: ['symbol', 'files', 'rationale', 'guarded_sibling', 'fix', 'est_value', 'risk'],
        properties: {
          symbol: { type: 'string' },                  // the unguarded accessor
          files: { type: 'array', items: { type: 'string' } },  // file:line
          rationale: { type: 'string' },                // the exact OOB index it permits + which array
          guarded_sibling: { type: 'string' },          // a sibling accessor that DOES bound-check (the pattern to mirror), or "none"
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
`Read-only analysis of III ACCESSORS in "${c.name}" (${c.hint}) under ${ROOT}.
Find PUBLIC (@export) accessor/getter functions that index a backing array/buffer/slot on a CALLER-
SUPPLIED index/count/offset WITHOUT validating it against the bound -- exactly the class of bug just
fixed in verba/csv.iii (csv_field_base indexed a 524288-element array on untrusted row,col with no
guard -> OOB read, while its sibling csv_field_count DID guard). For each, cite file:line, name the
exact OOB index a caller can pass, the array it overruns, and a GUARDED SIBLING accessor whose pattern
the fix should mirror (or "none"). Read the corpus KAT: is the OOB path tested? (usually not.)
Be SOURCE-GROUNDED and CALIBRATED: many accessors ARE guarded or are guaranteed in-bounds by a typed
caller / a fixed-size loop -- those are NOT bugs, say so. An accessor whose index is bounded by the
TYPE (e.g. a u8 row into a >=256 array) or already guarded is fine. NEVER invent; "all accessors bound
their index" is a valuable correct answer. Rank by est_value (1-5; 5 = clear reachable OOB).`,
    { label: `s5:${c.name}`, phase: 'Scan', schema: FIND_SCHEMA, agentType: 'Explore' }))))
  .filter(Boolean)

const all = scans.flatMap(s => (s && s.findings) ? s.findings.map(x => ({ ...x, cluster: s.cluster })) : [])
log(`${all.length} raw accessor findings across ${scans.length} clusters`)

phase('Verify')
const top = all.filter(f => f.est_value >= 3).sort((a, b) => b.est_value - a.est_value).slice(0, 12)
if (top.length === 0) {
  log('No est_value>=3 unguarded accessors -- III accessors bound their indices (honest abstention).')
  return { confirmed: [], raw_count: all.length, scanned: scans.length, verdict: 'accessors-bounded' }
}
const verified = (await parallel(top.map(f => () =>
  agent(
`Adversarially VERIFY this III accessor OOB. DEFAULT TO refuted (real=false) if uncertain.
Finding: ${JSON.stringify(f)}
Read the cited files + the corpus KAT under ${ROOT}. Confirm: (1) the accessor is PUBLIC and reachable
with an attacker/caller-chosen index; (2) NO guard (in the function or an unavoidable caller path) bounds
that index before the array access -> a concrete OOB read/write; (3) it is NOT guaranteed in-bounds by
the parameter TYPE, a fixed-size loop, or an existing guard (if it is, REFUTE); (4) a bounds-guard fix
mirrors a sibling + preserves valid behavior. Return {real, why (cite file:line), blockers}.`,
    { label: `v5:${f.symbol}`.slice(0, 40), phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
    .then(v => ({ ...f, verdict: v })))))
  .filter(Boolean)

const confirmed = verified.filter(v => v.verdict && v.verdict.real)
return { confirmed, raw_count: all.length, scanned: scans.length, verified: verified.length }
