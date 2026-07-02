# III Findings Wave W2700 — ultracode discovery fan-out (wf_5a3bdce4-199)
> **STATUS: HISTORICAL RECORD** — crash forensics / closed findings of their era; the fixes are landed and gated (reunification W6).

A 16-lens read-only discovery Workflow (54 agents, 4.0M subagent tokens) swept every III subsystem
for production-readiness defects across classes: crypto false-accept, PQ param-validation, bigint
overflow, untrusted-stream OOB, prover soundness, consensus, capability, protocol OOB, XII codegen,
forcefield, parsers, seal integrity, hypervisor boxes. Each raw finding was adversarially re-verified
(default real=false), then re-verified again in the main session and KAT-proven before any fix.

Status: [x] fixed+KAT, [A] advisor-gated (tests pin current behavior), [~] set aside (out-of-domain).

## Confirmed (5)

- [x] **numera.lzss:111** (sev4) — lzss_decompress match branch read TWO bytes (b0=ip[inp],
  b1=ip[inp+1]) under a ONE-byte guard (`inp < in_len`); a stream ending in a match control bit +
  one byte read ip[in_len] OOB. FIXED: reject when `(inp+1) >= in_len` before reading b1. KAT 1610
  (round-trip + truncated-match→-1) EXIT=99.

- [x] **aether.cap_forge cf_publish_slot:286** (sev3) — published EVERY fragment with
  CFORGE_OPID_FORGE, even deforge fragments (revtag=DEFORGE), so the witness log carried deforge
  fragments under the forge opid (CFORGE_OPID_DEFORGE was a dead constant). Mislabels audit
  attribution + the content-addressed frag id. FIXED: select CFORGE_OPID_DEFORGE when
  revtag==CFORGE_REVTAG_DEFORGE. KAT 1611 (forge A, restrict-child B, deforge A → B's deforge-frag
  opid differs from a forge-frag opid; needs wh_init) EXIT=99.

- [x] **aether.idoc idoc_validate:222** (sev3) — idoc_validate HAS idoc_len and is the function meant
  to BE the structural gate, but only called babel_wire_verify_crc, never babel_wire_verify_len. A
  buffer whose declared length didn't cover its header-claimed payload passed, and the payload walk
  (and idoc_resolve_facet) read OOB. The exact sibling of the W2616 babel_wire fix, in the gate
  itself. FIXED: gate idoc_validate on babel_wire_verify_len. KAT 1612 EXIT=99.

- [C] **aether.fed_eclipse_alarm:142** (sev5->sev2, CONCLUDED not-a-defect) -- the alarm returns 0
  (no alarm) when FECL_REFERENCE_SET==0, so fed_admit_planetary_gate_status grants ECLIPSE_OK by
  default. Adversarial re-analysis (advisor) shows a fail-closed flip is a FUNCTIONAL REGRESSION,
  not a fix: the ONLY caller of fed_eclipse_set_reference_fingerprint is unit-test 161 -- no
  production/genesis path sets the reference -- so fail-closed => ECLIPSE_OK never set =>
  fed_admit_eligible never reaches 0x07 => fed_admit_to_planetary always returns E_GATE => the
  planetary tier is permanently DEAD. Rewriting 386/1435/1441 to call the setter first would make
  the tests green while real admission stays broken (a regression-masking test). Severity is also
  overstated: this is the ADMITTING node's own eclipse self-detection (defense-in-depth), not an
  attacker-admission bypass -- PoW/sybil-sig/score/QC all still gate. The deliberate `return 0u8`
  + the three pinning tests make this a TESTED opt-in posture. The genuinely-complete fix is a
  FEATURE (derive the eclipse reference from the genesis/founding peer-set at bootstrap and wire it
  into the admission path, THEN require it) with a design input not derivable from the code -- its
  own future gated wave, not a boolean flip. Left unchanged by design.

- [~] **numera.sieve_trial:62** (sev3, conf 0.5) — `while (d*d) <= n` wraps u32 at d=65536, so for the
  ~131k primes in [4294836225, 2^32-1] the loop runs astronomically long (DoS). Out-of-intended-domain
  (module documented SIEVE_N=50; only caller iterates n<50; the sibling sieve_is_prime is guarded).
  A u64-widening `(d as u64)*(d as u64) <= (n as u64)` is byte-identical for valid n and would close
  it; set aside as low-priority UB-hygiene, not a reachable correctness defect.

## Method note
The workflow's strongest hit was idoc_validate — the gate that was *supposed* to call verify_len but
didn't. The adversarial-verify phase correctly down-graded sieve (its example value was composite)
and flagged fed_eclipse's test-pinning. One verify agent died on a socket error (ntt_ct_forward_tabled,
unverified — not included). Implementation + KAT + gating all in the main session per discipline.
