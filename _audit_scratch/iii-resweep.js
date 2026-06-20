export const meta = {
  name: 'iii-resweep',
  description: 'III whole-system 3-lens read-only audit re-sweep + refute-by-default verify (high-concurrency, ABI-calibrated)',
  whenToUse: 'Loop-until-dry production-readiness re-sweep of III .iii files; returns verified findings to fix in-session',
  phases: [
    { title: 'Discover+Verify', detail: '3 diverse lenses per file (read-only Explore) -> union -> refute-by-default verify; files fanned out to the 16-wide runtime cap (agents are cheap/in-process)' },
  ],
}

// args = { files: ["STDLIB/iii/...", ...], canary?: "path" }   (object OR JSON string both accepted)
// Read-only: every agent is Explore; NO Edit/Write. Findings are returned for in-session fixing.

let A = args
if (typeof A === 'string') { try { A = JSON.parse(A) } catch (e) { A = {} } }
if (!A || typeof A !== 'object') { A = {} }
const files = (A && A.files) ? A.files : []
const canary = (A && A.canary) ? A.canary : null

// ---- THE ABI CALIBRATION (probe-derived) -------------------------------------------------------
// An @export fn that writes/reads a FIXED size (a 32-byte hash, a 144-byte canonical serialization,
// a 24-byte packed record) to a caller pointer it NULL-CHECKS is the STANDARD C ABI (size is fixed by
// the fn's contract, like sha256(out)); the caller's duty to supply an adequate buffer is the ABI, NOT
// a defect. Flag OOB as REAL only when the caller controls HOW MUCH is accessed via an UNBOUNDED index
// or length parameter, OR when the pointer is dereferenced with NO null-check.
const ABI_RULE = `CALIBRATION (critical, avoids false positives): An @export fn that writes/reads a FIXED size (e.g. a 32-byte hash digest, a 144-byte canonical serialization, a 24-byte packed record) to a caller pointer that it NULL-CHECKS is following the STANDARD C ABI (the size is fixed by the function's contract, exactly like sha256(out)/keccak256(out)); the caller's obligation to pass an adequately-sized buffer is the ABI contract, NOT a defect. Do NOT report that as OOB. Report an OOB ONLY when (a) the caller controls HOW MUCH is accessed via an UNBOUNDED index/length parameter that a sibling fn would bound, or (b) the pointer is dereferenced with NO null-check, or (c) a fixed write/read exceeds a fixed-size MODULE buffer the fn itself owns.`

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['line', 'severity', 'klass', 'description'],
        properties: {
          line: { type: 'integer' },
          severity: { type: 'string', enum: ['CRIT', 'HIGH', 'MED', 'LOW'] },
          klass: { type: 'string', description: 'OOB | overflow | unchecked-return | null-deref | const-time-leak | soundness | placeholder | design | other' },
          description: { type: 'string', description: 'concrete, code-grounded; name the @export fn + the exact unguarded access + WHO controls the extent' },
        },
      },
    },
  },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false, required: ['isReal', 'fact'],
  properties: {
    isReal: { type: 'boolean' },
    fact: { type: 'string', description: 'the live-code FACT that proves real OR refutes' },
  },
}

function lens1(f) {
  return `Audit ONE III (.iii) file for PRODUCTION readiness, lens = COMPLETENESS+CORRECTNESS.
File: ${f}
Read the whole file. Find genuine defects: incomplete/placeholder logic that silently accepts; OOB where a caller-supplied INDEX/LENGTH (the access EXTENT) is unbounded but a sibling bounds it; integer overflow (addition-form that should be subtraction-form); unchecked extern/callee return codes that silently corrupt; null-deref of an @export pointer with NO null-check; soundness/false-accept in a gate/verify/proof. ${ABI_RULE}
For each REAL defect give line, severity, class, concrete description naming the fn + the exact access + who controls the extent. If clean, return empty findings.`
}
function lens2(f) {
  return `Audit ONE III (.iii) file, lens = III-COMPILER-TRAPS + SECURITY.
File: ${f}
Read the whole file. Check the documented iiis traps: a function-LOCAL var-array indexed by a runtime/loop var (must be module-global); modulo/divide right after a call (param-spill); i32 signed ordering compiled unsigned; a string literal passed to a libc string fn without a NUL terminator; a nonzero i64 literal immediately before '{'. Security: constant-time violation on a SECRET-dependent path (data branch or table index on a secret); non-libc/non-III dependency. ${ABI_RULE}
For each REAL issue give line, severity, class, concrete description. If clean, return empty findings.`
}
function lens3(f) {
  return `Audit ONE III (.iii) file, lens = DESIGN+CROSS-FILE-CONSISTENCY.
File: ${f}
Read the whole file. Find: a guard a SIBLING fn has but THIS fn is MISSING (esp. a missing null-check, or a caller-controlled index whose bound does not match the write-side cap); an unchecked validating-setter rc (rejects input but leaves the zeroed default and falsely returns OK); a dead/unreachable positive arm; a real API inconsistency; genuine bloat a leaner correct form removes. ${ABI_RULE}
For each REAL issue give line, severity, class, concrete description. If clean, return empty findings.`
}
function verifyPrompt(f, finding) {
  return `Refute-by-default verification of ONE audit finding in a III (.iii) file. Default isReal=false unless you can PROVE it real from the live code.
File: ${f}
Finding (line ${finding.line}, ${finding.severity} ${finding.klass}): ${finding.description}
Read the file around that line AND any sibling/caller it depends on. ${ABI_RULE}
A finding is a FALSE POSITIVE (isReal=false) if: it is the fixed-size-output ABI pattern above; the access is already guarded; it is internal-only with provably-bounded callers; by-design modular arithmetic; infallible-after-null-check delegation; ABI-compatible hygiene; or the RESOLVED iiis-2 W11 u64-division trap. It is REAL (isReal=true) only for a genuine defect reachable via @export/caller-controlled EXTENT (unbounded index/length), a MISSING null-check on a dereferenced @export pointer, a real overflow/soundness/const-time/unchecked-return bug. Return isReal + the exact live-code FACT that settles it.`
}

function dedupe(findings) {
  const seen = new Set(); const out = []
  for (const f of findings) { const k = `${f.line}|${(f.klass || '').toLowerCase()}`; if (seen.has(k)) continue; seen.add(k); out.push(f) }
  return out
}

const processFile = async (f, isCanary) => {
  const lensResults = await parallel([
    () => agent(lens1(f), { agentType: 'Explore', label: `L1:${f}`, phase: 'Discover+Verify', schema: FINDINGS_SCHEMA }),
    () => agent(lens2(f), { agentType: 'Explore', label: `L2:${f}`, phase: 'Discover+Verify', schema: FINDINGS_SCHEMA }),
    () => agent(lens3(f), { agentType: 'Explore', label: `L3:${f}`, phase: 'Discover+Verify', schema: FINDINGS_SCHEMA }),
  ])
  const union = dedupe(lensResults.filter(Boolean).flatMap(r => (r.findings || [])))
  if (isCanary) return { file: f, isCanary: true, found: union.length, findings: union }
  const confirmed = []
  for (const fnd of union) {
    const v = await agent(verifyPrompt(f, fnd), { agentType: 'Explore', label: `V:${f}:${fnd.line}`, phase: 'Discover+Verify', schema: VERDICT_SCHEMA })
    if (v && v.isReal) confirmed.push({ file: f, line: fnd.line, severity: fnd.severity, klass: fnd.klass, description: fnd.description, fact: v.fact })
  }
  return { file: f, isCanary: false, raw: union.length, confirmed }
}

phase('Discover+Verify')
log(`re-sweep: ${files.length} files + canary=${canary ? 'yes' : 'no'}, fanned out to the 16-wide cap`)

const all = (canary ? [{ f: canary, c: true }] : []).concat(files.map(f => ({ f, c: false })))
const fileResults = await parallel(all.map(x => () => processFile(x.f, x.c)))

const ok = fileResults.filter(Boolean)
const canaryHits = ok.filter(r => r.isCanary)
const confirmed = ok.filter(r => !r.isCanary).flatMap(r => r.confirmed || [])
log(`done: ${confirmed.length} confirmed across ${files.length} files; canary surfaced ${canaryHits.map(c => c.found).join(',') || 'n/a'}`)

return {
  swept: files.length,
  canary: canaryHits,
  confirmedCount: confirmed.length,
  confirmed,
}
