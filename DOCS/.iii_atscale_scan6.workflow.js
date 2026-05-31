export const meta = {
  name: 'iii-at-scale-scan6-index-overflow',
  description: 'Read-only fan-out over III for INTEGER-OVERFLOW in an index/size/offset computed BEFORE a bounds check -- idx*stride or base+len wraps u32/u64 so a subsequent guard (off<N) passes on a wrapped value -> OOB. The deeper sibling of scan-5 (a guarded accessor defeated by a pre-guard overflow).',
  phases: [
    { title: 'Scan', detail: 'one Explore agent per arithmetic-on-untrusted-index cluster; find mul/add into an offset/size that can wrap before the check' },
    { title: 'Verify', detail: 'adversarially confirm the wrap is reachable AND defeats a real guard (not type-bounded / not already wide enough), default-refute' },
  ],
}

const ROOT = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
const CLUSTERS = [
  { name: 'collections-stride', path: 'STDLIB/iii (vec/map/set/pq/lru/span/builder/xii_chd)', hint: 'index*element_stride or slot*width feeding an array offset -- find where idx*STRIDE is computed in u32/u64 and can wrap before (or without) a bound; the xii_chd off=idx*16 overflow class' },
  { name: 'numera-size',  path: 'STDLIB/iii/numera', hint: 'bigint limb_count*4, field byte_len, q128/fixed shift/scale, hex/leb decoded-length -- a length/size product or sum that can wrap a u32 before an allocation or a copy bound' },
  { name: 'verba-len',    path: 'STDLIB/iii/verba', hint: 'glyph offset = cp_index*width, base32/64 (n*8/5 or n*4/3) decoded-size, json/format buffer index = field*reclen -- a decode-size or offset product that wraps before the destination bound check' },
  { name: 'region-arena', path: 'STDLIB/iii', hint: 'arena/region/span: ptr = base + idx*size, used+req size sum, capacity*elem -- an offset/extent sum that wraps u64 (or u32-truncates) so the in-bounds check passes on a wrapped extent' },
  { name: 'witness-merkle', path: 'STDLIB/iii', hint: 'witness fragment offset = frag_idx*frag_size, merkle node index = 2*i+1, seal/attest buffer offset -- a tree/fragment index product that can wrap before indexing the fixed buffer' },
  { name: 'tempora-net-frame', path: 'STDLIB/iii (tempora + net/inet/http)', hint: 'http/inet header offset = field_idx*field_size, frame length = base+declared_len, calendar day-of-year*secs -- a length/offset sum from a (possibly attacker-declared) count that wraps before the buffer bound' },
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
        required: ['symbol', 'files', 'overflow_expr', 'wrap_input', 'defeats_guard', 'fix', 'est_value', 'risk'],
        properties: {
          symbol: { type: 'string' },                 // the function
          files: { type: 'array', items: { type: 'string' } },  // file:line of the arithmetic
          overflow_expr: { type: 'string' },           // the exact expr that wraps, e.g. "off = idx * 16u32"
          wrap_input: { type: 'string' },              // the caller-supplied value + the value that triggers wrap
          defeats_guard: { type: 'string' },           // which later bound check the wrap passes through (or "none/no-guard")
          fix: { type: 'string' },                     // widen to u64 / check before multiply / clamp the input
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
`Read-only analysis of III for INTEGER-OVERFLOW-IN-INDEX bugs in "${c.name}" (${c.hint}) under ${ROOT}.
Find PUBLIC (@export) or reachable functions where an array INDEX / buffer OFFSET / allocation SIZE is
computed by a MULTIPLY or ADD on a CALLER-influenced value, and that product/sum can WRAP (u32 or u64)
BEFORE the value is used -- so that a later bounds check (e.g. off < N) passes on the WRAPPED value, or
there is no check at all. This is the deeper sibling of the just-fixed accessor-bounds class: in
xii_chd_bucket_at, off = bucket_idx*16 wrapped on bucket_idx=0xFFFFFFFF (-> 0xFFFFFFF0) and indexed a
2304-element array. We just bounded the INPUT; this scan hunts the cases where the INPUT looks bounded
but the PRODUCT overflows, or where the guard is on the wrong (post-wrap) quantity.
For each: cite file:line of the arithmetic, the exact overflowing expression, the caller value that triggers
the wrap, and WHICH later guard the wrap defeats (or "no-guard").
Be SOURCE-GROUNDED and CALIBRATED: an index whose factors are TYPE-bounded so the product cannot exceed the
type (e.g. u8*16 < 4096 in a u32) is NOT a bug -- say so. An expression already done in u64 with both
factors < 2^32 cannot wrap -- NOT a bug. A guard placed BEFORE the multiply (check idx<DIM then idx*16) is
SAFE -- NOT a bug. NEVER invent; "all index arithmetic is type-bounded or pre-checked" is a valuable correct
answer. Rank by est_value (1-5; 5 = a reachable wrap that defeats a real guard / has no guard).`,
    { label: `s6:${c.name}`, phase: 'Scan', schema: FIND_SCHEMA, agentType: 'Explore' }))))
  .filter(Boolean)

const all = scans.flatMap(s => (s && s.findings) ? s.findings.map(x => ({ ...x, cluster: s.cluster })) : [])
log(`${all.length} raw index-overflow findings across ${scans.length} clusters`)

phase('Verify')
const top = all.filter(f => f.est_value >= 3).sort((a, b) => b.est_value - a.est_value).slice(0, 12)
if (top.length === 0) {
  log('No est_value>=3 reachable index overflows -- III index arithmetic is type-bounded / pre-checked (honest abstention).')
  return { confirmed: [], raw_count: all.length, scanned: scans.length, verdict: 'index-arith-bounded' }
}
const verified = (await parallel(top.map(f => () =>
  agent(
`Adversarially VERIFY this III index-overflow finding. DEFAULT TO refuted (real=false) if uncertain.
Finding: ${JSON.stringify(f)}
Read the cited files + the corpus KAT under ${ROOT}. Confirm ALL of: (1) the arithmetic is reachable with a
caller/attacker-influenced operand; (2) the product/sum GENUINELY wraps the type used (show the exact value:
the operand, the type width, the wrapped result); (3) the wrapped value is then used as an array index /
buffer offset / alloc size WITHOUT a guard that would catch it (a guard placed BEFORE the multiply, or on the
original input such that the product cannot exceed bounds, REFUTES this); (4) the factors are NOT type-bounded
to keep the product in range. If the product cannot actually exceed the array bound for ANY input of the
declared types, REFUTE. Return {real, why (cite file:line + the concrete wrap arithmetic), blockers}.`,
    { label: `v6:${f.symbol}`.slice(0, 40), phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
    .then(v => ({ ...f, verdict: v })))))
  .filter(Boolean)

const confirmed = verified.filter(v => v.verdict && v.verdict.real)
return { confirmed, raw_count: all.length, scanned: scans.length, verified: verified.length }
