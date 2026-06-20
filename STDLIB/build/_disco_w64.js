export const meta = {
  name: 'iii-w64-negcoverage-gap',
  description: 'W64: find an untrusted-input @export decoder/parser/verifier whose ENTIRE rejection surface is UNTESTED -- it HAS a malformed-input guard (returns an error code on bad input) but the only corpus test is positive/roundtrip and grep confirms NO negative test drives any error return. Generalization of W62 (lzss) / W63 (huffman). Confirmed = a real reject guard + a positive-only KAT + zero negative test (grepped) + a craftable malformed input. Adversarial refute: a negative test ALREADY exists (the agent missed it); the guard is unreachable; the malformed input is actually accepted by spec; the fn is not @export.',
  phases: [ { title: 'Find' }, { title: 'Refute' } ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const NUMERA = ROOT + '\\STDLIB\\iii\\numera'
const VERBA = ROOT + '\\STDLIB\\iii\\verba'
const OMNIA = ROOT + '\\STDLIB\\iii\\omnia'
const MEMORIA = ROOT + '\\STDLIB\\iii\\memoria'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const ALREADY_COVERED = 'lzss_decompress (1546), huff_decode (1547), base64_decode/base64url_decode (1051), base32_decode (1052/949)'

const GROUPS = [
  { key: 'crypto_verify', dir: NUMERA, files: 'ecdsa_p256.iii ecdsa_p384.iii ed25519.iii crypt_ed25519.iii rsa.iii x25519.iii', hint: 'a signature/MAC VERIFY that must REJECT a forged/corrupt signature; a point/scalar DECODE that must reject a non-canonical or off-curve encoding' },
  { key: 'pq_decode',     dir: NUMERA, files: 'mlkem.iii mldsa.iii pq_params.iii kyber_encaps.iii', hint: 'a public-key / ciphertext / signature DECODE that must reject a malformed (wrong-length / out-of-range coefficient) encoding; a verify that rejects a bad signature' },
  { key: 'ecc_codes',     dir: NUMERA, files: 'rscode.iii rscode_ec.iii hamming_secded.iii crc32.iii shamir.iii erasure_store.iii', hint: 'a decode that must FAIL when errors exceed the correction bound (return a fail sentinel); a CRC/checksum verify that rejects a corrupted block' },
  { key: 'deserialize',   dir: OMNIA,  files: 'sovval.iii cas_blob.iii prespec.iii', hint: 'a deserializer / blob-parser that must reject a malformed / out-of-bounds / wrong-magic record' },
  { key: 'verba_rest',    dir: VERBA,  files: 'leb128.iii utf8.iii hex.iii json.iii string.iii', hint: 'leb128 overflow/truncation (returns 0), utf8 invalid continuation/overlong, hex odd-length/bad-nibble, json malformed token' },
  { key: 'compress_io',   dir: NUMERA, files: 'lzh.iii bitio.iii cas_blob.iii', hint: 'lzh_decompress empty/mode-0/huff-reject guards (NOTE lzss+huffman already covered); bitio reader bounds' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'guard_line', 'guard_cond', 'error_return', 'positive_kat', 'negative_test_grep', 'malformed_input', 'reachable_export', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string', description: 'the @export decoder/parser/verifier' },
      guard_line: { type: 'number' }, guard_cond: { type: 'string', description: 'the malformed-input condition the guard rejects (e.g. cl>64, off>outp, d==0xFF invalid char, errors>t)' },
      error_return: { type: 'string', description: 'the error value returned on rejection (e.g. -1 / HF_E_DEC / RSE_FAIL / 0)' },
      positive_kat: { type: 'string', description: 'the existing positive/roundtrip test (corpus file + what it asserts) -- the fn IS tested positively' },
      negative_test_grep: { type: 'string', description: 'WHAT you grepped in the corpus and the result -- you MUST confirm NO test feeds malformed input and asserts the error. Quote the grep + "none found" or cite the negative test if one exists.' },
      malformed_input: { type: 'string', description: 'a concrete craftable malformed input that trips the guard (the bytes/values)' },
      reachable_export: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_gap', 'reason'],
  properties: { is_real_gap: { type: 'boolean' }, reason: { type: 'string' }, proposed_oracle: { type: 'string' }, proposed_teeth: { type: 'string' } },
}

const FIND_PROMPT = (g) => 'You are auditing the III stdlib for a TOTAL NEGATIVE-COVERAGE GAP: an untrusted-input @export\n' +
'decoder/parser/verifier that HAS a malformed-input rejection guard (returns an error code on bad input) but\n' +
'whose rejection surface is NEVER exercised by a corpus test -- the only test is positive/roundtrip.\n' +
'This is the W62/W63 idiom (lzss/huffman decoders were roundtrip-only, so their off>outp / cl>64 guards were\n' +
'untested).  ALREADY COVERED, do NOT re-report: ' + ALREADY_COVERED + '.\n\n' +
'Focus: ' + g.hint + '\n' +
'Read these files in ' + (g.dir === VERBA ? 'STDLIB/iii/verba' : (g.dir === OMNIA ? 'STDLIB/iii/omnia' : (g.dir === MEMORIA ? 'STDLIB/iii/memoria' : 'STDLIB/iii/numera'))) + ': ' + g.files + '\n\n' +
'For each @export that consumes UNTRUSTED bytes/values and can REJECT malformed input:\n' +
' 1. Identify its rejection guard(s): the line + condition + the error value returned (e.g. return -1 / HF_E_DEC / RSE_FAIL / 0-on-invalid).\n' +
' 2. Identify its POSITIVE test (the roundtrip/KAT in the corpus or the module KAT) -- confirm the fn IS exercised on valid input.\n' +
' 3. CRITICAL -- grep ' + CORPUS + ' for any NEGATIVE test: a test that feeds MALFORMED input and asserts the error return. Quote your grep + result. If a negative test EXISTS, this is NOT a gap (drop it).\n' +
' 4. Give a concrete craftable malformed input that trips the guard.\n\n' +
'HARD GATES -- drop unless ALL hold:\n' +
' - a REAL rejection guard exists (cite the line + error return);\n' +
' - the fn has a POSITIVE test but NO negative test (you grepped the corpus + the module KAT and found none driving the error);\n' +
' - a concrete craftable malformed input;\n' +
' - reachable @export.\n\n' +
'The #1 false positive is MISSING an existing negative test -- grep thoroughly (the error-constant name, the fn name, "reject", "malformed", "bad", "invalid").  Many decoders ALREADY have a *_reject / *_validation corpus test.  Only report confidence>=0.6 when you have CONFIRMED no negative test exists.  ZERO findings is an honest answer if every decoder is already negative-tested.  Return JSON.'

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: 'find:' + g.key, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const all = found.filter(Boolean).flat()
const candidates = all.filter(f => f.confidence >= 0.6 && f.reachable_export === true)
log('Find complete: ' + candidates.length + ' candidate gap(s) (of ' + all.length + ' raw)')
if (candidates.length === 0) {
  return { confirmed: [], note: 'no untrusted-input @export with a totally untested rejection surface survived the self-gate; the decoders are either negative-tested already or lack a reject path' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent('Adversarial verifier for a claimed TOTAL NEGATIVE-COVERAGE GAP in the III stdlib.\n\n' +
'CLAIM: ' + c.file + ' fn=' + c.fn + ' has an UNTESTED rejection guard.\n' +
'  guard (line ~' + c.guard_line + '): ' + c.guard_cond + ' -> returns ' + c.error_return + '\n' +
'  positive test: ' + c.positive_kat + '\n' +
'  negative-test grep claim: ' + c.negative_test_grep + '\n' +
'  malformed input: ' + c.malformed_input + '\n\n' +
'Read the source + GREP ' + CORPUS + ' EXHAUSTIVELY. Kills (REFUTE if ANY holds):\n' +
' (1) a NEGATIVE test ALREADY exists -- grep the corpus for the error-constant name, the fn name, "reject",\n' +
'     "validation", "malformed", "bad", "invalid", and READ any *_reject / *_validation / *_edges test that\n' +
'     touches this fn. If one feeds malformed input and asserts the error, REFUTE (this is the #1 kill).\n' +
' (2) the guard is unreachable / dead, or the fn is not actually @export-reachable on untrusted input.\n' +
' (3) the "malformed" input is actually ACCEPTED by the spec (not a real rejection) or the craft does NOT\n' +
'     trip the guard (trace the decode by hand).\n' +
' (4) the error path is already covered as a side effect of an existing test.\n' +
'Default is_real_gap=FALSE unless it SURVIVES. For a CONFIRMED gap: give the exact oracle (the malformed input\n' +
'bytes + the asserted error return) and the teeth (remove/disable the guard -> the new oracle reddens while the\n' +
'positive KAT stays green). Cite the source guard line + the corpus grep result proving no negative test exists.',
    { label: 'refute:' + c.file + ':' + c.fn, phase: 'Refute', schema: VERDICT_SCHEMA })
    .then(v => ({ ...c, verdict: v }))
))
const confirmed = judged.filter(Boolean).filter(j => j.verdict && j.verdict.is_real_gap)
log('Refute complete: ' + confirmed.length + ' confirmed of ' + candidates.length)
return {
  confirmed: confirmed.map(c => ({ file: c.file, fn: c.fn, guard_line: c.guard_line, guard_cond: c.guard_cond,
    error_return: c.error_return, positive_kat: c.positive_kat, malformed_input: c.malformed_input,
    proposed_oracle: c.verdict.proposed_oracle, proposed_teeth: c.verdict.proposed_teeth, reason: c.verdict.reason })),
  refuted: judged.filter(Boolean).filter(j => !(j.verdict && j.verdict.is_real_gap))
    .map(c => ({ file: c.file, fn: c.fn, why: c.verdict ? c.verdict.reason : 'null' })),
}
