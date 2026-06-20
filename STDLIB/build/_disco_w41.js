export const meta = {
  name: 'iii-w41-crypto-coverage-audit',
  description: 'W41: audit every security-critical crypto primitive for a DEFINING-PROPERTY / published-vector coverage gap (the EC-group-laws / x25519-DH pattern). Return prioritized gaps with the canonical RFC/FIPS/NIST vector to fill each. Adversarially confirm each gap is REAL (not already covered).',
  phases: [
    { title: 'Audit', detail: 'per-group crypto coverage-gap scan vs corpus' },
    { title: 'Confirm', detail: 'verify each claimed gap is genuinely uncovered' },
  ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const GROUPS = [
  { key: 'kdf', files: 'hkdf.iii hmac.iii pbkdf2.iii drbg.iii', note: 'RFC5869 (HKDF), RFC4231 (HMAC-SHA), RFC6070 (PBKDF2-SHA1), NIST SP800-90A (DRBG) known-answer vectors; the DEFINING property is exact output bytes for a published (IKM,salt,info)/(key,msg)/(pw,salt,iters) input.' },
  { key: 'aead_stream', files: 'chacha20.iii chacha20_poly1305.iii xchacha20_poly1305.iii poly1305.iii aes.iii aes_gcm.iii aes_siv.iii', note: 'RFC8439 (chacha20-poly1305), RFC7539, RFC5297 (AES-SIV), NIST GCM test vectors, RFC7905. Defining props: KAT ciphertext/tag for a published key/nonce/aad/pt; SECURITY negatives: tamper-tag-reject, AAD-tamper-reject, truncated-input.' },
  { key: 'sig', files: 'ecdsa_p256.iii ecdsa_p384.iii crypt_ed25519.iii ed_scalar_modl.iii rsa.iii', note: 'RFC6979 (deterministic ECDSA), FIPS186 CAVP, RFC8032 (ed25519), RFC8017 (RSA-PSS). Defining: a published (msg,key)->sig KAT; negatives: generic 1-bit sig tamper -> reject, low-S/malleability, zero r/s.' },
  { key: 'hash_xof', files: 'sha256.iii sha512.iii sha3_256.iii sha3_512.iii shake128.iii shake256.iii keccak256.iii blake2s.iii crc32.iii murmur3.iii', note: 'FIPS180/202 (SHA2/SHA3), the empty-string digest, a multi-block (>1 block) message, the SHAKE XOF arbitrary-length output. Defining: exact digest for the empty string AND a >block-size message.' },
  { key: 'pq', files: 'mlkem.iii mldsa.iii slhdsa.iii pq_dispatch.iii pq_params.iii', note: 'FIPS203/204/205 ACVP known-answer (keygen-from-seed -> exact pk/sk/ct/sig bytes). Defining: a deterministic seed -> published key/ciphertext/signature KAT (beyond the existing self-consistent roundtrip+tamper).' },
]

const AUDIT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['gaps'],
  properties: { gaps: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['primitive', 'fn', 'gap_kind', 'defining_property', 'existing_coverage', 'is_real_gap', 'vector_source', 'fillability', 'priority'],
    properties: {
      primitive: { type: 'string', description: 'e.g. hkdf_sha256, aes_siv_open, mlkem_keygen' },
      fn: { type: 'string', description: 'the @export function whose defining property is unasserted' },
      gap_kind: { type: 'string', enum: ['no_published_vector', 'no_defining_property', 'no_security_negative', 'partial_vector'] },
      defining_property: { type: 'string', description: 'the security/correctness property currently unasserted (e.g. "HKDF output == RFC5869 A.1 OKM", "AES-SIV open rejects a tampered tag")' },
      existing_coverage: { type: 'string', description: 'the corpus tests that DO cover this primitive + what they assert (you grepped corpus)' },
      is_real_gap: { type: 'boolean', description: 'true only if NO existing corpus test asserts this defining property' },
      vector_source: { type: 'string', description: 'the authoritative source for the fill vector: RFC#/section, FIPS#, NIST CAVP/ACVP, with the exact input if you know it' },
      fillability: { type: 'string', enum: ['self_contained_constant', 'needs_keygen_seed', 'expensive', 'unclear'], description: 'how hard to write the KAT' },
      priority: { type: 'number', description: '0..1 -- security-criticality x gap-realness x fillability' },
    },
  } } },
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['confirmed_real', 'reason'],
  properties: {
    confirmed_real: { type: 'boolean', description: 'true iff NO existing corpus test already asserts this defining property' },
    reason: { type: 'string', description: 'cite the corpus test(s) you checked and what they do/dont assert' },
    fill_recipe: { type: 'string', description: 'if real: the exact published input + expected output bytes (or RFC section) and the @export call sequence a KAT would use' },
  },
}

const AUDIT_PROMPT = (g) => `You are auditing the III crypto stdlib for DEFINING-PROPERTY / published-vector COVERAGE GAPS. Recent wins filled real gaps: EC group laws (1535/1536) and X25519 RFC7748 DH agreement (1537) -- defining properties that the existing single-vector KATs left unasserted.
Read these crypto modules in ${NUMERA}: ${g.files}
Context for this group: ${g.note}

For each @export primitive, determine its DEFINING correctness/security property and whether the corpus ASSERTS it:
 1. List the @export entry points (keygen / derive / encrypt / decrypt / sign / verify / hash / squeeze).
 2. For each, state the DEFINING property -- the published known-answer vector (exact output bytes for a
    published input) AND/OR the security-critical negative (tamper -> reject, malleability -> reject).
 3. grep ${CORPUS} for the fn name and read the matching tests. Determine EXACTLY what they assert.
 4. A GAP exists only if NO corpus test asserts the defining property on an authoritative published vector.

Report ONLY real gaps (is_real_gap=true). Prefer gaps that are (a) security-critical, (b) fillable with a
SELF-CONTAINED published constant (RFC/FIPS test vector with exact bytes), (c) genuinely unasserted. For each,
give the authoritative vector_source (RFC#/section, FIPS#, with the exact published input/output if you know
it -- e.g. RFC5869 Appendix A.1 HKDF-SHA256: IKM=0x0b*22, salt=0x000102...0c, info=0xf0f1...f9, L=42, OKM=
0x3cb25f25...87c34). Do NOT invent vectors; if you are unsure of the exact bytes, set fillability=unclear and
name the RFC section so it can be looked up.

Most primitives ARE covered (FIPS/RFC vectors are common in this corpus). Returning few/zero gaps is honest.
Return JSON per schema.`

phase('Audit')
const audited = await parallel(GROUPS.map(g => () =>
  agent(AUDIT_PROMPT(g), { label: `audit:${g.key}`, phase: 'Audit', schema: AUDIT_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.gaps ? r.gaps.map(x => ({ ...x, group: g.key })) : []))
))

const gaps = audited.filter(Boolean).flat()
  .filter(x => x.is_real_gap && x.priority >= 0.5 && x.fillability !== 'unclear' && x.fillability !== 'expensive')
log(`Audit complete: ${gaps.length} candidate gap(s) past self-gate (of ${audited.filter(Boolean).flat().length} raw)`)

if (gaps.length === 0) {
  return { confirmed: [], note: 'no fillable defining-property gap survived the self-gate; crypto coverage appears complete on the probed vectors' }
}

phase('Confirm')
const judged = await parallel(gaps.map(c => () =>
  agent(`Verify a claimed crypto COVERAGE GAP is genuinely uncovered before a KAT is written for it.

CLAIM:
  primitive: ${c.primitive}   fn: ${c.fn}   gap_kind: ${c.gap_kind}
  defining property (allegedly unasserted): ${c.defining_property}
  claimed existing coverage: ${c.existing_coverage}
  vector source: ${c.vector_source}

grep ${CORPUS} thoroughly for the fn name AND the primitive name AND related helpers; READ every matching test.
Determine if ANY existing corpus test already asserts this exact defining property (a published-vector KAT or
the named security negative). If one does -> confirmed_real=FALSE (already covered, do not duplicate). If none
does -> confirmed_real=TRUE, and provide the fill_recipe: the exact published input + expected output bytes (or
the precise RFC/FIPS section to look them up) and the @export call sequence the KAT would use. Be precise about
byte order (LE vs BE) and the exact published vector. Do NOT invent bytes -- if you cannot state them
authoritatively, give the exact RFC section + table so they can be transcribed from the spec.`,
    { label: `confirm:${c.primitive}`, phase: 'Confirm', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))

const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.confirmed_real)
log(`Confirm complete: ${confirmed.length} real gap(s) of ${gaps.length}`)

return {
  confirmed: confirmed.map(c => ({
    primitive: c.primitive, fn: c.fn, gap_kind: c.gap_kind, defining_property: c.defining_property,
    vector_source: c.vector_source, fillability: c.fillability, priority: c.priority,
    fill_recipe: c.verdict.fill_recipe, reason: c.verdict.reason,
  })).sort((a, b) => b.priority - a.priority),
  not_real: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.confirmed_real))
    .map(c => ({ primitive: c.primitive, why: c.verdict ? c.verdict.reason : 'null' })),
}
