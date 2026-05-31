export const meta = {
  name: 'iii-at-scale-scan3-crypto-variant-consistency',
  description: 'Read-only fan-out pairing SIBLING crypto primitives (ECDSA curves, Ed/X, AES sizes, SHA sizes, PQ schemes, field decoders) to find a guard/reject/check one variant HAS but its sibling LACKS -- latent correctness/security gaps, like the P-384 [E-EC-3] gap just fixed',
  phases: [
    { title: 'Pair-scan', detail: 'one agent per sibling family, diff their guards' },
    { title: 'Verify', detail: 'adversarially confirm the missing guard is a real, exploitable-in-principle gap' },
  ],
}

const ROOT = 'C:/Users/Edwin Boston/OneDrive/Desktop/III'
// sibling FAMILIES: members SHOULD enforce identical safety post-conditions; a guard in one but not
// another is a latent gap (the proven member is the canonical pattern to copy).
const FAMILIES = [
  { name: 'ecdsa-curves',   files: 'STDLIB/iii/numera/ecdsa_p256.iii, ecdsa_p384.iii (+ ecdsa_p521.iii if present)', hint: 'r/s range [1,n-1], degenerate [E-EC-3], low-s malleability, point-on-curve, k!=0 -- which curve enforces which?' },
  { name: 'eddsa-montgomery', files: 'STDLIB/iii/numera/ed25519.iii, x25519.iii, fe25519.iii', hint: 'strict-s malleability, canonical point decode, small-order/identity rejection, non-canonical field element rejection' },
  { name: 'pq-sign',        files: 'STDLIB/iii/numera/mldsa.iii, slhdsa.iii (+ shared pq params/dispatch)', hint: 'signature-length guard, public-key/seed length guard, rejection-sampling bounds, hedged-vs-deterministic consistency' },
  { name: 'pq-kem',         files: 'STDLIB/iii/numera/mlkem.iii (+ pq dispatch/params)', hint: 'decaps implicit-reject (FO transform), ciphertext/key length guards, k-bound guards' },
  { name: 'aes-sizes',      files: 'STDLIB/iii/numera/aes.iii (+ aes_gcm / aes_siv if separate)', hint: 'AES-128/192/256 key-length guard, GCM tag/nonce length guard, AAD handling, decrypt tag-mismatch reject -- same across sizes?' },
  { name: 'hash-sizes',     files: 'STDLIB/iii/numera/sha256.iii, sha512.iii, sha3/keccak, blake2', hint: 'output-length/rate guards, sponge-squeeze bounds, padding -- consistent across the family?' },
  { name: 'aead-variants',  files: 'STDLIB/iii/numera/chacha20_poly1305.iii, xchacha20_poly1305.iii, aes_gcm, aes_siv', hint: 'tag-verify constant-time + reject-on-mismatch, nonce-length guard, max-length guard -- one missing a check a sibling has?' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['family', 'gaps'],
  properties: {
    family: { type: 'string' },
    gaps: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['guard', 'has', 'lacks', 'files', 'rationale', 'fix', 'est_value', 'risk'],
        properties: {
          guard: { type: 'string' },                 // the safety check (e.g. "degenerate r==0/s==0 reject")
          has: { type: 'string' },                    // the variant that HAS it (canonical)
          lacks: { type: 'string' },                  // the variant MISSING it
          files: { type: 'array', items: { type: 'string' } }, // file:line for both
          rationale: { type: 'string' },              // why the missing guard is a real gap (what bad output/accept it permits)
          fix: { type: 'string' },                    // mirror the canonical pattern + add the prove-the-negative KAT
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

phase('Pair-scan')
const scans = (await parallel(FAMILIES.map(f => () =>
  agent(
`Read-only CROSS-VARIANT consistency analysis of the crypto family "${f.name}" under ${ROOT}.
Members: ${f.files}. Safety-relevant checks to diff: ${f.hint}.
For EACH safety guard/rejection/length-check/canonicalization, determine which family members ENFORCE it
and which OMIT it. A guard present in one member but MISSING in a sibling is a latent correctness/security
gap (the enforcing member is the proven canonical pattern). For each gap, cite file:line for BOTH the
member that HAS the guard and the one that LACKS it, and explain concretely what bad output or wrongful
accept the missing guard permits (e.g. "sign can emit an (r,s) verify rejects", "decaps accepts a
malformed ciphertext", "verify accepts a non-canonical encoding -> malleability").
Also CHECK the corpus KATs: is the would-be reject path tested for the lacking member? (Usually not --
that's the prove-the-negative gap.)
Be SOURCE-GROUNDED (file:line) and CALIBRATED: a difference that is INTENTIONAL (e.g. a check that only
applies to one variant by spec, or a policy choice like BIP-62 low-s that FIPS does not mandate) is NOT a
gap -- say so. NEVER invent. Most of III's crypto is FIPS/RFC-faithful with heavy KAT coverage; a true
"all siblings consistent" is a valuable correct answer. Rank gaps by est_value (1-5; 5 = clear bug).`,
    { label: `pair:${f.name}`, phase: 'Pair-scan', schema: FIND_SCHEMA, agentType: 'Explore' }))))
  .filter(Boolean)

const all = scans.flatMap(s => (s && s.gaps) ? s.gaps.map(x => ({ ...x, family: s.family })) : [])
log(`${all.length} raw cross-variant gaps across ${scans.length} families`)

phase('Verify')
const top = all.filter(g => g.est_value >= 3).sort((a, b) => b.est_value - a.est_value).slice(0, 10)
if (top.length === 0) {
  log('No est_value>=3 cross-variant gaps -- the crypto suite is consistent across siblings (honest abstention).')
  return { confirmed: [], raw_count: all.length, scanned: scans.length, verdict: 'crypto-siblings-consistent' }
}
const verified = (await parallel(top.map(g => () =>
  agent(
`Adversarially VERIFY this crypto cross-variant gap. DEFAULT TO refuted (real=false) if uncertain.
Gap: ${JSON.stringify(g)}
Read the cited files for BOTH members under ${ROOT}. Confirm: (1) the canonical member REALLY enforces the
guard (cite the exact reject line); (2) the sibling REALLY omits it (show the code path that reaches output
WITHOUT the check); (3) the omission is a genuine correctness/security gap, NOT an intentional spec/policy
difference; (4) no existing KAT already covers the sibling's reject path (if one does, REFUTE). Return
{real, why (cite file:line for both members), blockers}. A false gap refuted here saves a wrong crypto edit.`,
    { label: `vfy3:${g.guard}`.slice(0, 40), phase: 'Verify', schema: VERDICT_SCHEMA, agentType: 'Explore' })
    .then(v => ({ ...g, verdict: v })))))
  .filter(Boolean)

const confirmed = verified.filter(v => v.verdict && v.verdict.real)
return { confirmed, raw_count: all.length, scanned: scans.length, verified: verified.length }
