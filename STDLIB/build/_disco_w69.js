export const meta = {
  name: 'iii-w69-syslayer-negcoverage',
  description: 'W69: negative-path-coverage discovery on the SYSTEMS-LAYER untrusted parsers (HTTP/JSON/INI/inet/URI) -- an @export parser that consumes untrusted network/config bytes and HAS a malformed-input rejection guard (returns an error on a bad request line / oversized header / invalid chunk size / malformed JSON token / bad IP octet) but whose rejection surface is NEVER driven by a corpus test (positive-parse only, grep-confirmed). Generalization of W62/63/65-68. Adversarial refute: a negative test already exists; unreachable; accepted by spec; teeth-less (guard removal does not change the observable result).',
  phases: [ { title: 'Find' }, { title: 'Refute' } ],
}

const ROOT = 'C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III'
const AETHER = ROOT + '\\STDLIB\\iii\\aether'
const VERBA = ROOT + '\\STDLIB\\iii\\verba'
const OMNIA = ROOT + '\\STDLIB\\iii\\omnia'
const CORPUS = ROOT + '\\STDLIB\\corpus'

const ALREADY = 'lzss/huffman/hex/leb128/lzh/mldsa + base64/base32/rscode/ed25519/rsa (all already negative-tested)'

const GROUPS = [
  { key: 'http_req',  dir: AETHER, files: 'http.iii http_server.iii', hint: 'request-line / method / version / header parse: reject a malformed request line, a missing/oversized header, a bad Content-Length, an invalid chunk size (hex), a header count overflow' },
  { key: 'http_resp', dir: AETHER, files: 'http_client.iii backend_remote.iii', hint: 'status-line / response parse: reject a malformed status code, a truncated response, a bad chunked-transfer encoding' },
  { key: 'inet',      dir: AETHER, files: 'inet.iii inet6.iii', hint: 'IPv4/IPv6 address parse: reject an octet > 255, too many/few octets, a non-digit, a bad :: in v6, a port out of range' },
  { key: 'json',      dir: VERBA,  files: 'json.iii', hint: 'JSON tokenizer/parser: reject a malformed number, an unterminated string, a bad escape, an unexpected token, nesting depth overflow' },
  { key: 'ini_uri',   dir: VERBA,  files: 'ini.iii uri.iii parse.iii', hint: 'INI section/key parse + URI scheme/host/path parse + numeric parse: reject a malformed line, a bad percent-encoding, an out-of-range integer' },
  { key: 'prespec',   dir: OMNIA,  files: 'prespec.iii', hint: 'spec/record parser: reject a malformed / out-of-bounds / wrong-magic record' },
]

const FIND_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['file', 'fn', 'guard_line', 'guard_cond', 'error_return', 'positive_kat', 'negative_test_grep', 'malformed_input', 'reachable_export', 'confidence'],
    properties: {
      file: { type: 'string' }, fn: { type: 'string', description: 'the @export parser' },
      guard_line: { type: 'number' }, guard_cond: { type: 'string', description: 'the malformed-input condition rejected (e.g. octet>255, content-length non-numeric, chunk-size bad hex, unterminated string)' },
      error_return: { type: 'string', description: 'the error value returned on rejection' },
      positive_kat: { type: 'string', description: 'the existing positive-parse test (corpus file + what it asserts)' },
      negative_test_grep: { type: 'string', description: 'WHAT you grepped in the corpus and the result -- MUST confirm NO test drives the error. Quote the grep + "none found" or cite the negative test.' },
      malformed_input: { type: 'string', description: 'a concrete craftable malformed input that trips the guard' },
      reachable_export: { type: 'boolean' }, confidence: { type: 'number' },
    },
  } } },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['is_real_gap', 'reason'],
  properties: { is_real_gap: { type: 'boolean' }, reason: { type: 'string' }, proposed_oracle: { type: 'string' }, proposed_teeth: { type: 'string' } },
}

const FIND_PROMPT = (g) => 'You are auditing the III stdlib SYSTEMS-LAYER parsers for a TOTAL NEGATIVE-COVERAGE GAP: an @export\n' +
'parser that consumes UNTRUSTED bytes (network request/response, config file, address, JSON) and HAS a\n' +
'malformed-input rejection guard (returns an error code on bad input) but whose rejection surface is NEVER\n' +
'exercised by a corpus test -- the only test is positive-parse.  This is the W62/W63/W65-68 idiom.\n' +
'ALREADY COVERED, do NOT re-report: ' + ALREADY + '.\n\n' +
'Focus: ' + g.hint + '\n' +
'Read these files in ' + (g.dir === AETHER ? 'STDLIB/iii/aether' : (g.dir === OMNIA ? 'STDLIB/iii/omnia' : 'STDLIB/iii/verba')) + ': ' + g.files + '\n\n' +
'For each @export parser that can REJECT malformed input:\n' +
' 1. Identify its rejection guard(s): line + condition + the error value returned.\n' +
' 2. Identify its POSITIVE test (the corpus parse test) -- confirm the fn IS exercised on valid input.\n' +
' 3. CRITICAL -- grep ' + CORPUS + ' for any NEGATIVE test (feeds malformed input, asserts the error). Quote the grep + result. If one EXISTS, drop it.\n' +
' 4. Give a concrete craftable malformed input that trips the guard.\n\n' +
'HARD GATES -- drop unless ALL hold: a REAL guard (line + error return); a POSITIVE test but NO negative\n' +
'test (grepped the error const, the fn name, "reject"/"bad"/"invalid"/"malformed"/"_neg"); a craftable\n' +
'malformed input; reachable @export.\n\n' +
'The #1 false positive is MISSING an existing negative test, and the #2 is a TEETH-LESS guard (removing it\n' +
'does not change the observable result because a downstream check catches the same input).  Grep thoroughly\n' +
'and hand-trace the malformed input to confirm the guard is the SOLE thing that rejects it.  Many HTTP/JSON\n' +
'parsers DO have *_neg / malformed tests already.  ZERO findings is an honest answer.  Only report\n' +
'confidence>=0.6 when you CONFIRMED no negative test exists.  Return JSON.'

phase('Find')
const found = await parallel(GROUPS.map(g => () =>
  agent(FIND_PROMPT(g), { label: 'find:' + g.key, phase: 'Find', schema: FIND_SCHEMA, agentType: 'Explore' })
    .then(r => (r && r.findings ? r.findings.map(f => ({ ...f, group: g.key })) : []))
))
const all = found.filter(Boolean).flat()
const candidates = all.filter(f => f.confidence >= 0.6 && f.reachable_export === true)
log('Find complete: ' + candidates.length + ' candidate gap(s) (of ' + all.length + ' raw)')
if (candidates.length === 0) {
  return { confirmed: [], note: 'no systems-layer parser with a totally untested rejection surface survived the self-gate; the HTTP/JSON/inet/INI/URI parsers are either negative-tested already or lack a teeth-bearing reject path' }
}

phase('Refute')
const judged = await parallel(candidates.map(c => () =>
  agent('Adversarial verifier for a claimed TOTAL NEGATIVE-COVERAGE GAP in a III systems-layer parser.\n\n' +
'CLAIM: ' + c.file + ' fn=' + c.fn + ' has an UNTESTED rejection guard.\n' +
'  guard (line ~' + c.guard_line + '): ' + c.guard_cond + ' -> returns ' + c.error_return + '\n' +
'  positive test: ' + c.positive_kat + '\n' +
'  negative-test grep claim: ' + c.negative_test_grep + '\n' +
'  malformed input: ' + c.malformed_input + '\n\n' +
'Read the source + GREP ' + CORPUS + ' EXHAUSTIVELY. Kills (REFUTE if ANY holds):\n' +
' (1) a NEGATIVE test ALREADY exists -- grep the error const, the fn name, "neg"/"reject"/"bad"/"invalid"/\n' +
'     "malformed", and READ any matching test. If one drives the error, REFUTE (the #1 kill).\n' +
' (2) the guard is unreachable / the fn is not @export-reachable on untrusted input.\n' +
' (3) the "malformed" input is ACCEPTED by spec, or the craft does NOT trip the guard (hand-trace the parse).\n' +
' (4) TEETH-LESS: removing the guard does NOT change the observable result -- a DOWNSTREAM check rejects the\n' +
'     same input, so an oracle built on it passes with AND without the guard (tautological). Hand-trace what\n' +
'     happens with the guard removed; if the parse still returns the same error/result, REFUTE.\n' +
'Default is_real_gap=FALSE unless it SURVIVES. For a CONFIRMED gap: give the exact oracle (malformed bytes +\n' +
'asserted error) and the teeth (remove the guard -> the oracle reddens while the positive parse stays green).\n' +
'Cite the source guard line + the corpus grep proving no negative test + the hand-trace showing teeth.',
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
