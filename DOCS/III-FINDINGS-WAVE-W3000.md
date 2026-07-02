# III Findings Wave W3000 — fresh-slice coverage strengthening
> **STATUS: HISTORICAL RECORD** — crash forensics / closed findings of their era; the fixes are landed and gated (reunification W6).

A coverage-strengthening Workflow (37 agents) swept prover falsifier arms, math laws, develop-up
hypervisor boxes, determinism/confluence, compiler error-paths, and memoria/tempora. Verdict on the
defect axis: **0 latent defects** across the wave -- the bug/perf/coverage-defect veins are mined to
the floor (W2800 yielded 1 micro-opt, W3000 yields 0 defects). All 12 confirmed findings are
defense-in-depth (pinning already-correct guards so a FUTURE regression is caught).

## Landed (highest-value, self-contained)
- [x] aether.flow_firewall capacity exhaustion -- after FF_CAP=64 nodes, ff_relay/ff_input fail
  CLOSED (FF_NONE) without corrupting the graph (ff_box_safe verdict preserved). KAT 1620.
- [x] memoria.span.span_u8_load -- idx>=len and null base return the 0x100 OOB sentinel. KAT 1620.
- [x] tempora.rfc3339.rfc3339_format -- year>9999 rejected (emitter writes exactly 4 year digits;
  W78 covered the PARSER, this pins the FORMATTER). KAT 1621.

## Documented lower-priority (defense-in-depth, heavier setup or already-implied)
- numera.field fp_add/fp_mul ring distributivity -- verifier rated "mathematically implied" by the
  point-KATs that already pin each op's reduction; marginal.
- [x] forcefield.ripple rn_merge commutativity (merge(A<-B) == merge(B<-A): same count + identical
  resolved content for every value-address -- CALM/sheaf-gluing order-independence). KAT 1622.
- sema.iii compiler error-paths (SEMA_E_IDENT_UNRESOLVED / HEXAD_MISSING / RING_MISSING / DECL_DUP) --
  need a compiler-REJECTION test harness (compile a bad program, assert diagnostic) that the standard
  runnable-KAT corpus does not provide; a real future coverage axis if that harness is added.
- tempora.instant.instant_seal_byte / deadline_in saturation / memoria.span generic load -- already-
  guarded accessor bounds; lower marginal value.

## Note
The remaining substantive enhancement is the fed_eclipse genesis-reference FEATURE (derive the
eclipse reference from the founding peer-set at bootstrap, then require it) -- a consensus-core +
sealed-gate-outcome-test change with a security-design input, warranting a dedicated gated wave
rather than a marathon-tail rush (advisor-concurred). See III-FINDINGS-WAVE-W2700.md.
