export const meta = {
  name: 'iii-w59-table-correctness',
  description: 'W59: a hardcoded LOOKUP TABLE (S-box, GF(256) log/exp, CRC table, NTT zeta, round constants, codec alphabet) with a WRONG entry that the spot-vector KATs do not exercise -- found by checking each entry against the table generating identity / spec (a SELF-CONSISTENCY oracle that exercises ALL entries: sbox[invsbox[x]]==x, exp[log[x]]==x, table[i]==gen(i)). Also flags tables with NO all-entries verification (a wrong entry could hide). Adversarial refute (entry actually correct vs the spec? table fully covered already?).',
  phases: [ { title: 'Find' }, { title: 'Refute' } ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const VERBA = ROOT + '\\STDLIB\\iii\\verba'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'aes_gf', dir: NUMERA, files: 'aes.iii aes_gcm.iii aes_siv.iii galois.iii gf_poly.iii' },
  { key: 'ecc_gf256', dir: NUMERA, files: 'rscode.iii rscode_ec.iii hamming_secded.iii' },
  { key: 'ntt_zeta', dir: NUMERA, files: 'ntt.iii ntt_bigint.iii ntt_ctx.iii mldsa.iii mlkem.iii pq_params.iii' },
  { key: 'hash_const', dir: NUMERA, files: 'sha256.iii sha512.iii sha3_256.iii sha3_512.iii keccak.iii keccak256.iii blake2s.iii shake128.iii shake256.iii' },
  { key: 'codec_alpha', dir: VERBA, files: 'base64.iii base32.iii hex.iii leb128.iii' },
  { key: 'misc_const', dir: NUMERA, files: 'crc32.iii murmur3.iii xoshiro.iii constants.iii poly1305.iii chacha20.iii drbg.iii' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'table', 'line', 'kind', 'generating_identity', 'suspect_entry', 'spec_value', 'all_entries_verified', 'has_kat', 'confidence'],
    properties: {
      file: { type: 'string' }, table: { type: 'string', description: 'the hardcoded table (e.g. AES_SBOX, GF_EXP/GF_LOG, MLDSA_ZETA, K[64], BASE64_ALPHA)' }, line: { type: 'number' },
      kind: { type: 'string', enum: ['wrong_entry', 'no_full_coverage'] },
      generating_identity: { type: 'string', description: 'the identity every entry must satisfy (sbox[invsbox[x]]==x; exp[log[x]]==x; zeta[i]==root^bitrev(i) mod q; K[i]==frac(cbrt(prime_i)); crc_table[i]==crc8(i))' },
      suspect_entry: { type: 'string', description: 'for wrong_entry: the index + value that VIOLATES the identity (give the bad value + the index). for no_full_coverage: the table that has no all-entries check.' },
      spec_value: { type: 'string', description: 'for wrong_entry: the CORRECT value per the spec/identity' },
      all_entries_verified: { type: 'boolean', description: 'is there a corpus/KAT check that exercises EVERY entry (not just spot bytes)?' },
      has_kat: { type: 'boolean' },
      reachable_export: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_defect', 'reason'],
  properties: { is_real_defect: { type: 'boolean' }, reason: { type: 'string' }, proposed_teeth: { type: 'string' } },
}

const FIND_PROMPT = (g) => `You are auditing the III stdlib for HARDCODED LOOKUP TABLE correctness.  A table (S-box, GF(256) log/exp, NTT zeta/twiddle, CRC table, hash round constants, codec alphabet) can have a WRONG ENTRY that the spot-vector KATs never exercise (e.g. AES encrypting 2 blocks hits ~30 of 256 S-box entries; a wrong entry at an untouched index passes).
Read these files in ${g.dir === VERBA ? 'STDLIB/iii/verba' : NUMERA}: ${g.files}

For each hardcoded table:
 1. State the GENERATING IDENTITY every entry must satisfy:
    - S-box / inv-S-box: sbox[invsbox[x]] == x for all x; sbox[0]==0x63, etc.
    - GF(256) log/exp: exp[log[x]]==x (x!=0); log[exp[i]]==i; exp[i+1]==xtime-or-gen*exp[i].
    - NTT zeta/twiddle: zeta[i] == root^bitrev_k(i) mod q (Kyber root 17 / Dilithium 1753).
    - hash round constants: K[i] == frac bits of cbrt/sqrt of the i-th prime (SHA2); keccak RC per the LFSR.
    - codec alphabet: the exact RFC4648 base64/base32 alphabet string + padding char.
    - CRC table: table[i] == CRC of the single byte i under the polynomial.
 2. CHECK a sample of entries (especially at indices the spot-KATs are unlikely to hit -- mid-table, the last
    entry, indices whose value differs by one bit from a neighbour) against the identity.  Report any entry that
    VIOLATES the identity (kind=wrong_entry) with the bad value and the correct spec value.
 3. CHECK whether the corpus has an ALL-ENTRIES self-consistency oracle (a loop over every index asserting the
    identity).  If not, report the table (kind=no_full_coverage) -- a wrong entry could hide there.

HARD GATES -- drop unless ALL hold:
 - for wrong_entry: a CONCRETE index whose stored value violates the identity, with the correct value derived
   from the spec.  Re-derive carefully -- do NOT claim a wrong entry unless you computed the spec value.
 - for no_full_coverage: the table genuinely has no all-entries check (you grepped the corpus + the module KAT).
 - reachable: the table feeds a reachable @export.

Most tables are correct + exercised by FIPS/RFC KATs.  A wrong entry is RARE (the KATs usually catch it).  ZERO
wrong_entry findings is the likely honest answer; no_full_coverage findings (tables lacking an all-entries
oracle) are the more common, lower-severity result.  Only report what you verified against the spec.  Return JSON.`

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: `find:${g.key}`, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const all = found.filter(Boolean).flat()
const candidates = all.filter(f => f.confidence >= 0.5 && (f.kind === 'wrong_entry' || (f.kind === 'no_full_coverage' && f.confidence >= 0.6)))
log(`Find complete: ${candidates.length} candidate(s) (${all.filter(f=>f.kind==='wrong_entry').length} wrong-entry, ${all.filter(f=>f.kind==='no_full_coverage').length} no-coverage; of ${all.length} raw)`)
if (candidates.length === 0) {
  return { confirmed: [], note: 'no wrong table entry and no high-value coverage gap survived the self-gate; the lookup tables are correct + exercised' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent(`Adversarial verifier for a claimed TABLE-CORRECTNESS issue in the III stdlib.

CLAIM: ${c.file} table=${c.table} (line ~${c.line}) kind=${c.kind}
  generating identity: ${c.generating_identity}
  suspect: ${c.suspect_entry}  spec value: ${c.spec_value}
  all-entries verified already: ${c.all_entries_verified}

Read the source + grep ${CORPUS}.  Kills:
 (1) for wrong_entry: re-derive the SPEC value for that index BY HAND from the generating identity.  If the
     stored value MATCHES the spec (the claim mis-computed), REFUTE.  Be rigorous: compute the GF inverse / the
     bitrev / the round constant exactly.
 (2) for no_full_coverage: is there actually an all-entries oracle (a KAT loop over every index, or a
     differential vs a generated table, or the table is DERIVED at runtime not hardcoded)?  If covered, REFUTE.
 (3) the table is computed/derived at boot (not a hardcoded literal) -> a wrong literal cannot exist, REFUTE.
 (4) unreachable / not actually a table feeding an @export.
Default is_real_defect=FALSE unless it SURVIVES.  For a CONFIRMED wrong_entry: give the exact fix (index ->
correct value) + the teeth (a self-consistency KAT that fails pre-fix).  For a CONFIRMED no_full_coverage worth
filling: give the all-entries self-consistency KAT to add (the identity loop).  Cite source lines + spec.`,
    { label: `refute:${c.file}:${c.table}`, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))
const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_defect)
log(`Refute complete: ${confirmed.length} confirmed of ${candidates.length}`)
return {
  confirmed: confirmed.map(c => ({ file: c.file, table: c.table, line: c.line, kind: c.kind,
    generating_identity: c.generating_identity, suspect_entry: c.suspect_entry, spec_value: c.spec_value,
    proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_defect))
    .map(c => ({ file: c.file, table: c.table, why: c.verdict ? c.verdict.reason : 'null' })),
}
