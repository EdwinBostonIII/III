# III-ERRORS.md — Unified Error-Code Namespace

**Document Identity:** ERRORS / Unified Error-Code Namespace
**Status:** **DERIVATIVE — NOT part of the R1 sealed set.** Reference document consolidating every error code from the 15 sealed specs and the Cluster K extensions. Updated on Catalyst-promoted error-code additions.
**Version:** 1.0 — 2026-05-03 (Wave 0.3)
**Sources:** All 15 R1-sealed specs at `Desktop/III/DOCS/`.
**Sibling derivative docs:** III-STDLIB.md, III-CONSTANTS.md, III-CRYPTO-AGILITY.md, III-FOUNDERS-ANCHOR.md.

---

## §0. Preamble — Why Unified

Across the 15 sealed specs, error codes appear with inconsistent prefixes — `LEX-*`, `PARSE-*`, `TYPE-*`, `MOD-*`, `RUNTIME-*`, `PANIC-*`, `TRINITY_*`, `ACC_*`, `SCBA_*`, `MOBIUS_*`, `CEILING_*`, `EPISTEMIC_*`, `WAAC_*`, `HEXAD_*`, `FED-*`, `CAT-*`, `SAN-*`, etc. Reading any individual spec, "C-LEX-1" and "C-1" both appear; the namespace is ambiguous.

This ledger consolidates **every error code** that the substrate may emit — at compile time, at link time, at runtime, or at audit time — into one unified namespace organized by:

1. **Phase** (compile / link / runtime / audit / federation).
2. **Subsystem** (lexer, parser, type system, SID, codegen, ring marshalling, witness chain, Trinity, Catalyst, federation, sanctum, etc.).
3. **Severity** (informational, warning, hard error, panic, compromise).

Every code carries: a unique identifier, the layer at which it is detected, the diagnostic message template, the operator-actionable recovery hint, and the source spec section.

---

## §1. Naming Convention

Codes follow the pattern `<PHASE>-<SUBSYSTEM>-<NNN>` where:

| Phase | Prefix | Detection point |
|-------|--------|-----------------|
| Compile-time / lexical | `LEX-` | Lexer (BOOT/lex.c) |
| Compile-time / parser | `PARSE-` | Parser (BOOT/parse.c) |
| Compile-time / type-system | `TYPE-` | Type-checker (BOOT/sema.c) |
| Compile-time / proof | `PROOF-` | Proof kernel (BOOT/proof.c) |
| Compile-time / SID | `SID-` | SID plan executor (BOOT/sid.c) |
| Compile-time / codegen | `CG-` | Codegen (BOOT/cg_*.c) |
| Compile-time / link | `LINK-` | Linker (BOOT/link.c) |
| Runtime / cycle dispatch | `RUN-` | Cycle dispatcher |
| Runtime / Trinity | `TRIN-` | Three-layer ceiling |
| Runtime / Catalyst | `CAT-` | Catalyst engine |
| Runtime / Sanctum | `SAN-` | Sealed-call dispatcher |
| Runtime / Federation | `FED-` | Federation transport |
| Runtime / Witness | `WIT-` | BCWL / chain emission |
| Runtime / Module | `MOD-` | Module loader / resolver |
| Runtime / Founder's Anchor | `FNDR-` | Anchor authority |
| Audit / Conformance | `CONF-` | Conformance verifier |
| Audit / Replay | `REPLAY-` | Witness replay tool |
| Panic | `PANIC-` | Unrecoverable substrate state |

Subsystem prefixes are 2–6 characters; numeric suffix is 3 digits.

Per-spec sub-criteria (renamed per STDLIB §19.2 to avoid collision with conformance C-1..C-30):

| Old (per-spec) | New (namespaced) |
|----------------|-------------------|
| C-LEX-1..N | `C-A1-1..N` |
| C-GRAM-1..N | `C-A2-1..N` |
| C-TYPE-1..N | `C-A3-1..N` |
| C-EFF-1..N | `C-A4-1..N` |
| C-CYC-1..N | `C-A5-1..N` |
| C-HEX-1..N | `C-A6-1..N` |
| C-PH-1..N | `C-A7-1..N` |
| C-SAN-1..N | `C-A8-1..N` |
| C-TRIN-1..N | `C-A9-1..N` |
| C-MOD-1..N | `C-A10-1..N` |
| C-CAT-1..N | `C-B1-1..N` |
| C-FED-1..N | `C-B2-1..N` |
| (CONFORMANCE itself) | `C-1..C-30` |
| C-ABI-1..N | `C-C1-1..N` |

---

## §2. Compile-Time / Lexical (`LEX-*`)

### §2.1 Encoding (`LEX-ENC-*`)

| Code | Message | Recovery |
|------|---------|----------|
| LEX-ENC-001 | BOM forbidden — III source is BOM-less UTF-8 | Strip the leading EF BB BF |
| LEX-ENC-002 | CR forbidden — III source is LF-only | Convert CRLF / CR to LF |
| LEX-ENC-003 | Trailing whitespace at line N | Strip trailing whitespace |
| LEX-ENC-004 | Non-canonical extension | Rename to `.III` |
| LEX-ENC-005 | Source exceeds 16 MiB limit — split into modules | Split source |
| LEX-ENC-006 | Invalid UTF-8 | Re-encode as valid UTF-8 |
| LEX-ENC-007 | Forbidden control codepoint at byte offset N | Remove the control codepoint |
| LEX-ENC-008 | Raw forbidden codepoint inside string literal | Use `\xHH` or `\u{...}` escape |

### §2.2 Identifier (`LEX-ID-*`)

| Code | Message | Recovery |
|------|---------|----------|
| LEX-ID-001 | Keyword used as identifier | Choose a non-keyword name |
| LEX-ID-002 | Identifier exceeds 256-codepoint limit | Shorten the name |
| LEX-ID-003 | Reserved double-underscore identifier | Drop the `__` prefix |
| LEX-ID-004 | Wildcard cannot be bound | Choose a name (not `_`) |
| LEX-ID-005 | Reserved Catalyst slot name | Choose a different name |

### §2.3 Integer / Q14 Literal (`LEX-INT-*`, `LEX-Q14-*`)

| Code | Message | Recovery |
|------|---------|----------|
| LEX-INT-001 | Underscore immediately after radix prefix | Remove `_` after `0x`/`0b`/`0o` |
| LEX-INT-002 | Underscore at start of integer literal | Remove leading `_` |
| LEX-INT-003 | Underscore immediately before suffix | Remove `_` before suffix |
| LEX-INT-004 | Literal exceeds suffix range | Choose larger suffix or smaller value |
| LEX-Q14-001 | Q14 literal exceeds range [-2.0, 1.99993896484375] | Use a representable value |

### §2.4 String Literal (`LEX-STR-*`)

| Code | Message | Recovery |
|------|---------|----------|
| LEX-STR-001 | Unescaped newline in string literal | Use `\n` escape |
| LEX-STR-002 | Odd-length hex string | Add a hex digit or remove the trailing one |
| LEX-STR-003 | Invalid escape sequence | Use a valid escape |
| LEX-STR-004 | Unterminated string literal | Add closing `"` |

### §2.5 Operator / Punctuator (`LEX-OP-*`, `LEX-PUNCT-*`)

| Code | Message | Recovery |
|------|---------|----------|
| LEX-OP-001 | Non-canonical operator codepoint | Use the NFC-canonical form |
| LEX-PUNCT-001 | Reserved character `$` in user source | Remove `$` (compiler-internal only) |
| LEX-PUNCT-002 | Reserved character — slot pending Catalyst promotion | Avoid `^` / `~` / `'` / backtick |

### §2.6 Comment / Whitespace (`LEX-CMT-*`, `LEX-WS-*`)

| Code | Message | Recovery |
|------|---------|----------|
| LEX-CMT-001 | Unterminated block comment | Add closing `*/` |
| LEX-CMT-002 | Dangling doc comment | Attach to a following item |
| LEX-WS-001 | Forbidden whitespace codepoint | Use only space / tab / LF |

---

## §3. Compile-Time / Parser (`PARSE-*`)

| Code | Message | Recovery |
|------|---------|----------|
| PARSE-CYCLE-001 | Irreversible cycle cannot have explicit inverse | Remove `inverse {}` block on `@irreversible` cycle |
| PARSE-MOB-001 | Candidate hexad outside reachable set | Adjust hexad pillars to admissible form |
| PARSE-IRPD-001 | Raw privileged write outside IRPD | Wrap in `irpd.<method>(...)` |
| PARSE-IRPD-002 | Raw privileged instruction detected (defense-in-depth) | Use IRPD method |
| PARSE-EXPR-002 | Chained comparisons | Use explicit parentheses |
| PARSE-EXPR-003 | Chained phase cross | Use explicit grouping `((v ⟴ R0) ⟴ R-1)` |
| PARSE-DOC-001 | Dangling doc comment | Attach to following item |
| PARSE-EXTERN-001 | extern in privileged-ring module | Move extern block to `@ring(R0, R3)` module |
| PARSE-SEAL-001 | seal_id out of range | Use seal_id ∈ {0..9} |

---

## §4. Compile-Time / Type System (`TYPE-*`)

### §4.1 Hexad-related

| Code | Message | Recovery |
|------|---------|----------|
| TYPE-HEXAD-001 | Hexad outside reachable set | Compose admissible hexad |
| TYPE-HEXAD-002 | Composed hexad outside reachable set | Adjust constituent cycles |

### §4.2 Modifier conflicts

| Code | Message | Recovery |
|------|---------|----------|
| TYPE-MOD-001 | `@pure` ∧ `@sanctum_only` | Drop one |
| TYPE-MOD-002 | `@witness_elide` without `@pure` | Add `@pure` or remove `@witness_elide` |
| TYPE-MOD-003 | `@chronos_bypass` without operator-cap | Acquire operator cap |
| TYPE-MOD-004 | `@irreversible` ∧ `@pure` | Choose one |
| TYPE-MOD-005 | `@candidate_for_promotion` outside `mobius_candidate` | Move to mobius_candidate decl |
| TYPE-MOD-006 | `@epoch_bridge` on a fn with no cross-epoch params | Remove `@epoch_bridge` or add cross-epoch param |

### §4.3 Ring / phase

| Code | Message | Recovery |
|------|---------|----------|
| TYPE-RING-001 | No marshalling constructor for ring transition | Use a permitted ring traversal path (R3 → R0 → R-1 → R-2) |

### §4.4 Linear capability

| Code | Message | Recovery |
|------|---------|----------|
| TYPE-LIN-001 | Capability used twice | Use cap exactly once |
| TYPE-LIN-002 | Unbalanced capability use | Balance acquire / release |
| TYPE-LIN-003 | Glyph-drift on capability parameter | Re-acquire with current glyph |

### §4.5 Sanctum

| Code | Message | Recovery |
|------|---------|----------|
| TYPE-SAN-001 | Sanctum method called outside sanctum frame | Wrap in `sanctum_enter \|frame\| { ... }` |
| TYPE-SEAL-002 | seal_id collision | Choose unused seal_id |

### §4.6 SID

| Code | Message | Recovery |
|------|---------|----------|
| TYPE-SID-001 | Unknown IRPD method | Use one of the 17 SE-kind methods |
| TYPE-SID-002 | Prior-value capture failed | Ensure read-side IRPD method exists |
| TYPE-SID-003 | Inverse-record construction failed | Check cycle's IRPD calls |
| TYPE-SID-004 | Inverse does not round-trip | Mark `@irreversible` or fix the body |
| TYPE-SID-005 | Inverse Reduction emission failed | (compiler bug — report) |

### §4.7 Cycle / Witness

| Code | Message | Recovery |
|------|---------|----------|
| TYPE-CYCLE-001 | Cycle table full / collision | Choose unused step_kind |
| TYPE-CYCLE-002 | Descriptor emission failed | (compiler bug — report) |
| TYPE-CYCLE-003 | Reduction emission failed | (compiler bug — report) |
| TYPE-CYCLE-004 | Ring-binding failed | Ensure all phase lowerings constructible |
| TYPE-CYCLE-005 | Return to type-checker failed | (compiler bug — report) |
| TYPE-WIT-001 | Witness chain threading failed | (compiler bug — report) |
| TYPE-WIT-002 | step_kind allocation failed | Reserve unused step_kind |

### §4.8 PIP / SRPA / OBSERVATORY

| Code | Message | Recovery |
|------|---------|----------|
| TYPE-PIP-001 | PIP classification failed | Re-classify inverse blob |
| TYPE-SRPA-001 | Specialization hint failed | Remove `@hot_path` or fix body |
| TYPE-OBS-001 | OBSERVATORY registration failed | Ensure schema declaration valid |

### §4.9 Möbius / Trinity / Ceiling

| Code | Message | Recovery |
|------|---------|----------|
| TYPE-MOB-001 | Insufficient coherence | Raise `@mobius_coherence` floor or restructure |
| TYPE-TRIN-001 | Trinity predicates undischargeable | Adjust Trinity context |
| TYPE-CEIL-001 | Post-state outside constitutional manifest | Constrain post-state |
| TYPE-CEIL-002 | Manifest contribution failed | (compiler bug — report) |

### §4.10 Plan / Federation / Epoch / Glyph / Epistemic / Ghost / Inverse / WAAC

| Code | Message | Recovery |
|------|---------|----------|
| TYPE-PLAN-001 | Plan anchor missing or invalid | Add `@plan_anchor(IDENT)` |
| TYPE-FED-001 | Federation tier mismatch | Adjust `@tier` / `@replicates` |
| TYPE-EPOCH-001 | Cycle epoch newer than current | Use `@epoch(current)` or older |
| TYPE-EPI-001 | Uncertainty classification failed | Provide explicit `Uncertainty<...>` type |
| TYPE-GHOST-001 | Ghost metadata failed | Drop `@witness_elide` or add `@pure` |
| TYPE-INV-001 | Replay plan emission failed | (compiler bug — report) |
| TYPE-WAAC-001 | waac violation | Restructure to respect waac constraint |

### §4.11 Holes / Universe / Narrative

| Code | Message | Recovery |
|------|---------|----------|
| TYPE-HOLE-001 | Hole could not be inferred | Add explicit type annotation |
| TYPE-NAR-001 | Multiple narrative declarations | Keep one per module |
| TYPE-EXTERN-001 | extern call from privileged ring | Move extern call to R0 / R3 |
| TYPE-IRPD-001 | Unknown IRPD method | Use one of the 17 SE-kind methods |

---

## §5. Compile-Time / Proof Kernel (`PROOF-*`)

| Code | Message | Recovery |
|------|---------|----------|
| PROOF-UNIV-001 | Universe inconsistency | Restructure types to respect predicativity |
| PROOF-POSITIVITY-001 | Positivity check failed for inductive type | Reorder constructor arguments |
| PROOF-CONV-001 | Conversion check failed (judgmental equality) | Adjust types for definitional equality |
| PROOF-NORM-001 | β/δ/η/ι reduction did not normalize | (proof has non-terminating reduction — likely kernel bug or invalid term) |
| PROOF-CERT-001 | Proof certificate verification failed | Re-derive certificate; check kernel version |
| PROOF-CERT-002 | Proof certificate's `closure_root` mismatch | Re-derive against current R1 |
| PROOF-EXT-001 | Native ternary extension reduction failed | (kernel bug — report) |

---

## §6. Compile-Time / Codegen / Link (`CG-*`, `LINK-*`)

| Code | Message | Recovery |
|------|---------|----------|
| CG-EMIT-001 | Codegen failure for ring R | Check ring's marshalling constructors |
| CG-PHASE-001 | Phase-polymorphic synthesis failed | Provide explicit `metal @ring(R) {}` blocks |
| CG-LEGACY-001 | Legacy codegen failure (Wave 5) | Check legacy lifter inputs |
| LINK-CLOSURE-001 | Closure-pin mismatch on import | Update `@closure(...)` pin or restore module |
| LINK-MANIFEST-001 | Manifest signature verification failed | Re-sign with operator key |
| LINK-CYCLE-TABLE-001 | Cycle-table contribution conflict | Resolve step_kind collision |

---

## §7. Runtime — Module Resolution (`MOD-*`, `RUN-*`)

| Code | Message | Recovery |
|------|---------|----------|
| MOD-RES-001 | Closure mismatch on import resolution | Update `@closure(...)` pin |
| MOD-RES-002 | No matching module in OBSERVATORY | Pull from federation or synthesize via Catalyst |
| MOD-PROMOTE-REJECT | Module promotion rejected (high-risk) | Operator review |
| RUN-CYCLE-001 | Unknown cycle mhash | Verify cycle is registered |
| RUN-DISPATCH-001 | Dispatch to slot 0 (INVALID) | (substrate-correctness bug — emits SANCTUM_INVALID_REJECT witness) |

---

## §8. Runtime — Trinity (`TRIN-*`)

Per the §19.2-renamed namespace from STDLIB:

| Code | Layer | Message | Recovery |
|------|-------|---------|----------|
| TRIN-L1-SCBA-REJECT | 1 | Post-state not in pre-approved set | Escalate to L2/L3 |
| TRIN-L2-ACC-REJECT | 2 | Composed delta violates current state | Rollback wavefront |
| TRIN-L2-WAAC-VIOLATION | 2 | Wavefront-as-Capability constraint violated | Rollback to last waac commit |
| TRIN-L3-INTENT-REJECT | 3 | Operator consent missing or expired | Re-authenticate |
| TRIN-L3-CAP-REJECT | 3 | Insufficient or drifted capability | Re-acquire cap |
| TRIN-L3-CAUSALITY-REJECT | 3 | Audit head too far behind or compromised | Force audit replay |
| TRIN-L3-SANCTUM-REJECT | 3 | Sanctum frame inactive or invalid | Re-enter sanctum |
| TRIN-L3-MOBIUS-FAIL | 3 | Post-state drops manifold coherence below floor | Reject + propose safer alternative |
| TRIN-L3-CEILING-VIOLATION | 3 | Post-state outside constitutional manifest | Hard reject + emit compromise quote |
| TRIN-L3-EPISTEMIC | 3 | Uncertainty below 0.85q threshold | Escalate + invoke `reflect(uncertainty)` |
| TRIN-ALL-HEXAD-UNREP | All | Safety hexad outside reachable set | Compile-time error (untypable) |

---

## §9. Runtime — Catalyst (`CAT-*`)

| Code | Message | Recovery |
|------|---------|----------|
| CAT-GATE-001 | Gate 1 (saturation) not met | Wait for OBSERVATORY accumulator to saturate |
| CAT-GATE-002 | Gate 2 (Möbius coherence < floor) | Restructure candidate to preserve coherence |
| CAT-GATE-003 | Gate 3 (Trinity undischarged) | Provide intent/cap/causality/sanctum-state |
| CAT-GATE-004 | Gate 4 (Ceiling violation) | Constrain post-state |
| CAT-GATE-005 | Gate 5 (Hexad inadmissible) | Restructure pillars |
| CAT-GATE-006 | Gate 6 (Codegen validation failed) | Fix candidate body |
| CAT-GATE-007 | Gate 7 (Ring-gating: high-risk + low-benefit) | Operator review |
| CAT-GATE-008 | Gate 8 (Deployment flag UNSAFE_REJECTED) | Address structural failure |
| CAT-RATE-001 | Promotion rate cap exceeded — deferred to next tick | (informational; will retry) |
| CAT-PHASE-RATE-001 | Phase-promotion rate cap exceeded — deferred | (informational) |
| CAT-MOD-RATE-001 | Module-fusion rate cap exceeded — deferred | (informational) |
| CAT-PROMOTE-REVOKED | Promotion revoked by operator override | (informational) |

---

## §10. Runtime — Sanctum (`SAN-*`)

| Code | Message | Recovery |
|------|---------|----------|
| SAN-INVALID-DISPATCH | Attempt to dispatch to sealed slot 0 | (substrate bug — emits SANCTUM_INVALID_REJECT witness; auto-unwound) |
| SAN-TRINITY-REJECT | Trinity rejected sealed call | (per TRIN-L3-* codes) |
| SAN-FRAME-INVALID | Per-CPU sanctum frame inactive or corrupted | Re-enter via fresh `sanctum_enter` |
| SAN-PKRU-MISMATCH | PKRU rewrite failed | (hardware-level; substrate panics PANIC-PKRU-001) |
| SAN-DRTM-CHAIN-001 | DRTM quote chain verification failed at epoch N | Force audit replay or DRTM relaunch |

---

## §11. Runtime — Federation (`FED-*`)

| Code | Message | Recovery |
|------|---------|----------|
| FED-OUTBOUND-REJECT-TIER0 | Tier-0 message refused federation outbound | (informational; transient) |
| FED-OUTBOUND-TIER-MISMATCH | Cross-tier message refused without `amend.apply` | Adjust tier or invoke amend.apply |
| FED-QUORUM-FAIL | Quorum signature collection insufficient | Retry with more peers |
| FED-PEER-VERIFY-001 | Peer's DRTM quote chain verification failed | Excommunicate peer (federation-quorum-revocation) |
| FED-PEER-DISCOVERY-001 | Witness-tagged broadcast packet from non-conformant peer | (informational; ignored) |
| FED-AH-VERIFY-001 | RFC-4302 AH trailer signature mismatch on inbound | Drop packet |
| FED-IOMMU-IOPT-001 | IOMMU IOPT not configured for adapter BDF | Operator must enable per-adapter |

---

## §12. Runtime — Witness Chain (`WIT-*`)

| Code | Message | Recovery |
|------|---------|----------|
| WIT-HMAC-001 | HMAC-SHA-256 signature mismatch on chain replay | Re-derive sub-key or escalate to operator |
| WIT-BLAKE3-001 | BLAKE3 hash mismatch on witness body | Witness corruption — emit compromise quote |
| WIT-CHAIN-001 | Predecessor mhash does not link | Force chain replay from last known-good anchor |
| WIT-BCWL-001 | BCWL Bloom false-positive — secondary lookup needed | (operational; transparent) |
| WIT-EPOCH-001 | Witness epoch newer than current epoch | (informational; epoch-aware verification) |

---

## §13. Audit / Conformance (`CONF-*`, `REPLAY-*`)

| Code | Message | Recovery |
|------|---------|----------|
| CONF-VERIFIER-001 | Verifier mhash mismatch — wrong verifier | Re-pin verifier closure root |
| CONF-R1-MISMATCH | Observed R1 differs from canonical | Fix sealed-spec drift |
| CONF-CRITERION-FAIL-N | Conformance criterion C-N failed | Address per-criterion remediation |
| REPLAY-CHAIN-001 | Chain replay terminated before reaching epoch 0 | Insufficient witness retention |
| REPLAY-DECOMMIT-001 | ZK-rollup decommitment witness missing | Retain decommitment witnesses for the segment |

---

## §14. Founder's Anchor (`FNDR-*`) — NEW for Cluster K item 178

| Code | Message | Recovery |
|------|---------|----------|
| FNDR-VETO-001 | Founder's Anchor vetoed Tier-3 amendment | Operator revoke veto by re-signing or accept rejection |
| FNDR-COSIGN-MISSING | Tier-3 amendment missing required Founder's Anchor cosignature | Add cosignature |
| FNDR-COSIGN-INVALID | Founder's Anchor cosignature invalid | Re-sign with current Anchor key |
| FNDR-ANCHOR-REMOVAL-ATTEMPT | Term attempts to remove Founder's Anchor — untypable | (compile-time hard reject; emits witness) |
| FNDR-DRTM-001 | Founder's Anchor unilateral DRTM-relaunch invoked | (informational; substrate-wide DRTM commenced) |
| FNDR-DENY-001 | Founder's Anchor unilateral pfs_deny_quote invoked | (informational; peer excommunicated) |
| FNDR-RESTORE-001 | Founder's Anchor restoring rate caps | (informational; Catalyst rate-cap restoration) |
| FNDR-SHAMIR-001 | Shamir Secret Sharing reconstruction failed (insufficient shares) | Provide K-of-N shares |
| FNDR-SHAMIR-002 | Shamir share verification failed | Replace corrupted share |

---

## §15. Cryptographic Agility (`CRYPTO-*`) — NEW for Cluster K item 176

| Code | Message | Recovery |
|------|---------|----------|
| CRYPTO-SUITE-001 | Unknown crypto_suite_id | Activate registered suite |
| CRYPTO-SUITE-002 | Active suite swap requires Founder's Anchor cosignature | Cosign the swap amendment |
| CRYPTO-SUITE-003 | Hybrid mode requires both pre-quantum and post-quantum signatures | Provide both signatures |
| CRYPTO-KYBER-001 | Kyber-1024 KEM decapsulation failed | Re-derive shared secret |
| CRYPTO-DILITHIUM-001 | Dilithium-5 signature verification failed | Re-sign |
| CRYPTO-SPHINCS-001 | SPHINCS+ signature verification failed | Re-sign |
| CRYPTO-VDF-001 | VDF squaring count below required | Wait for VDF computation to complete |
| CRYPTO-HKDF-001 | HKDF-derived sub-key mismatch | Re-derive with current epoch |

---

## §16. ZK-Rollup (`ZK-*`) — NEW for Cluster K item 175

| Code | Message | Recovery |
|------|---------|----------|
| ZK-ROLLUP-001 | ZK proof construction failed for segment | Reduce segment size |
| ZK-ROLLUP-002 | ZK proof verification failed | Re-prove with current suite |
| ZK-ROLLUP-003 | Decommitment witness missing for segment N | Retain witness; replay impossible without it |
| ZK-ROLLUP-004 | Compaction threshold not yet reached | (informational; defer) |

---

## §17. Genesis Vector (`GENESIS-*`) — NEW for Cluster K item 177

| Code | Message | Recovery |
|------|---------|----------|
| GENESIS-INSTALL-001 | Installer signature verification failed against operator cert | Re-sign installer with valid cert |
| GENESIS-DRTM-SLIDE-001 | Software-only DRTM slide failed | Check host-OS hypervisor support |
| GENESIS-LEGACY-DISGUISE-001 | Legacy-disguise wrapper rejected by host OS Defender / SELinux | Re-issue with newer signing cert chain |
| GENESIS-SECURE-BOOT-001 | UEFI Secure Boot rejected installer | Use legitimate driver-signing channel |

---

## §18. Panic Codes (`PANIC-*`)

Substrate-fatal; emits compromise witness, then unrecoverable bugcheck.

| Code | Message | Severity |
|------|---------|----------|
| PANIC-GLYPH-DRIFT | Capability glyph identity drifted at runtime | HIGH |
| PANIC-IRPD-RAW | Raw privileged instruction encountered at runtime (defense-in-depth) | HIGH |
| PANIC-PKRU-001 | PKRU rewrite returned unexpected value | HIGH |
| PANIC-WITNESS-CHAIN-BROKEN | Predecessor mhash chain reached invalid state | HIGH |
| PANIC-HEXAD-UNREACHABLE | Runtime saw hexad outside `xii_asym_reach6` | HIGH (substrate-correctness bug) |
| PANIC-FOUNDERS-ANCHOR-CORRUPTION | Founder's Anchor key corruption detected | CATASTROPHIC |
| PANIC-DRTM-CEREMONY-FAIL | DRTM relaunch ceremony failed mid-flight | CATASTROPHIC |
| PANIC-PROOF-KERNEL-001 | Proof kernel internal error | HIGH (kernel bug) |

---

## §19. Per-Spec Conformance Criteria (Renamed Namespace)

The renaming proposed in STDLIB §19.2 is now formal:

| Spec | Old prefix | New prefix |
|------|-----------|-------------|
| A1 LEXICON | C-LEX-* | `C-A1-*` |
| A2 GRAMMAR | C-GRAM-* | `C-A2-*` |
| A3 TYPES | C-TYPE-* | `C-A3-*` |
| A4 EFFECTS | C-EFF-* | `C-A4-*` |
| A5 CYCLES | C-CYC-* | `C-A5-*` |
| A6 HEXAD | C-HEX-* | `C-A6-*` |
| A7 PHASES | C-PH-* | `C-A7-*` |
| A8 SANCTUM | C-SAN-* | `C-A8-*` |
| A9 TRINITY | C-TRIN-* | `C-A9-*` |
| A10 MODULES | C-MOD-* | `C-A10-*` |
| B1 CATALYST | C-CAT-* | `C-B1-*` |
| B2 FEDERATION | C-FED-* | `C-B2-*` |
| C1 ABI | C-ABI-* | `C-C1-*` |

The substrate-wide acceptance set `C-1..C-30` remains in its CONFORMANCE.md numbering. Per-spec criteria *aggregate* into the top-level set; the per-spec namespace is now disambiguated.

---

## §20. Final Statement

This ledger consolidates every error code emitted by every layer of the substrate. The naming is now uniform: `<PHASE>-<SUBSYSTEM>-<NNN>`. The per-spec sub-criteria are namespaced (`C-A1-*`, `C-A2-*`, ..., `C-IDX-*`) to disambiguate from the 30 substrate-wide acceptance criteria.

Three classes of code:

1. **Recoverable** (most LEX-*, PARSE-*, TYPE-*, MOD-*, FED-*) — operator can fix and retry.
2. **Compromise-emitting** (TRIN-L3-CEILING-VIOLATION, certain SAN-*) — substrate emits compromise quote and continues.
3. **PANIC-*** — substrate-fatal; bugcheck.

The Founder's Anchor codes (FNDR-*) and Cryptographic Agility codes (CRYPTO-*) are new — added in Wave 0 to cover the Cluster K survival surface. ZK-Rollup (ZK-*) and Genesis Vector (GENESIS-*) codes are added now but the corresponding subsystems land in Wave 2 and Wave 10 respectively.

*Wave 0.3 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03.*

---

## §N. XII — eXtreme Intent Intermediate (Wave 11; per `DOCS/III-XII.md`)

XII introduces five new code subsystems: `CANON-*` (canonicalisation), `MANIFEST-*` (manifest integrity), `DET-*` (determinism replay), `CT-*` (constant-time obligations), `LDIL-*` (link-time inlining), `SML-*` (software measured launch), `ATM-*` (anti-tamper membrane). All XII codes use the `XII-` phase prefix per the §1 naming convention.

### §N.1 Canonicalisation (`XII-CANON-*`)

| Code | Severity | Message | Recovery |
|------|----------|---------|----------|
| XII-CANON-001 | E | term failed to canonicalise within MPO weight bound | impossible per Theorem 9.4; indicates Manifest tamper — rebuild from sealed Manifest |
| XII-CANON-002 | E | canonical form misses Horizon Set AND register-chain fallback failed | curation gap; submit governance proposal to add pattern to Horizon |
| XII-CANON-003 | E | `@fusion_budget` constraint violated (depth > budget, or budget > @k_max) | raise `@fusion_budget` (up to `@k_max`) or refactor to reduce depth |
| XII-CANON-004 | E | unknown / illegal `@deployment_target` value | use one of: `x86_avx512`, `x86_avx2`, `x86_scalar_ct`, `arm64_neon`, `arm64_sve2`, `riscv64_v`, `embedded_safe`, `auto` |
| XII-CANON-005 | W | Horizon Set miss; fell back to register chain | informational; performance may be 10–15% below Horizon-matched path |
| XII-CANON-099 | E | guard cell hit at canonical form (forbidden hexad × operator combination) | restructure function to avoid bricking-equivalent composition |

### §N.2 Manifest Integrity (`XII-MANIFEST-*`)

| Code | Severity | Message | Recovery |
|------|----------|---------|----------|
| XII-MANIFEST-001 | F | Manifest mhash mismatch against embedded golden | Manifest tampered; re-fetch sealed `xii_manifest.bin` from federation |
| XII-MANIFEST-002 | F | Lattice mhash mismatch | Lattice tampered; re-fetch sealed `xii_lattice.bin` |
| XII-MANIFEST-003 | F | MPHF tables mhash mismatch | MPHF tampered; re-fetch sealed `xii_pm_*` tables |
| XII-MANIFEST-004 | F | reach6 bitmap mhash mismatch | bitmap tampered; re-fetch sealed `xii_horizon_reach.iii` |
| XII-MANIFEST-005 | F | Trinity admit cert invalid | curation incomplete; re-execute Ω1..Ω12 |
| XII-MANIFEST-006 | F | Founders-Anchor veto returned | curation violated `PFK-ANCHOR-INVARIANT`; address veto-cause crystal and re-iterate |

### §N.3 Determinism (`XII-DET-*`)

| Code | Severity | Message | Recovery |
|------|----------|---------|----------|
| XII-DET-001 | F | Manifest replay produced different bytes | build environment leaked non-determinism (clock, hostname, locale, etc.); fix `LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0` |
| XII-DET-002 | F | Lattice replay produced different bytes | as above |

### §N.4 Constant-Time (`XII-CT-*`)

| Code | Severity | Message | Recovery |
|------|----------|---------|----------|
| XII-CT-001 | E | CT witness mismatch in emitted bytes | disassembly contains a forbidden instruction sequence (per §26.6 grammar for `ct_kind`); rebuild with corrected target template |
| XII-CT-002 | E | CT class value out of range (must be 0..8) | curation error; the `ct_kind` byte must be one of the 9 sealed classes |

### §N.5 Link-Time Lattice Inliner (`XII-LDIL-*`)

| Code | Severity | Message | Recovery |
|------|----------|---------|----------|
| XII-LDIL-001 | E | Disassembly audit mismatch: inlined bytes ≠ sealed Horizon cell payload | LDIL tamper; rebuild from sealed Lattice |
| XII-LDIL-002 | E | Cell mhash mismatch during LDIL inlining | Lattice cell tampered between Manifest seal and LDIL load |
| XII-LDIL-003 | E | Cell oversize (payload > placeholder `expected_size`) | curation error; resize placeholder reservation in `cg_r3_pe_lattice_emit` or split pattern |
| XII-LDIL-004 | E | `.iii_xii_calls` section corrupt (entry size ≠ 24 bytes) | iiis-1/cg_r3 emission bug; rebuild with patched compiler |

### §N.6 Software Measured Launch (`XII-SML-*`)

| Code | Severity | Message | Recovery |
|------|----------|---------|----------|
| XII-SML-001 | F | `mmap` of self binary failed | OS-level failure; check ulimit/MAP_PRIVATE support |
| XII-SML-002 | F | `.iii_manifest` section not found in binary | binary missing XII manifest; not an XII-compiled artifact |
| XII-SML-003 | F | Manifest mhash mismatch at startup | binary tampered post-link; re-fetch from federation |
| XII-SML-004 | F | Founders-Anchor Ed25519 signature invalid | Manifest signature does not match anchor_pubkey; binary rejected |
| XII-SML-005 | F | LDIL audit log mhash mismatch | inlining log tampered |
| XII-SML-006 | F | inlined Lattice cell mhash mismatch | `.text` cell tampered post-link |

### §N.7 Anti-Tamper Membrane (`XII-ATM-*`)

| Code | Severity | Message | Recovery |
|------|----------|---------|----------|
| XII-ATM-001 | F | Manifest tamper detected at runtime (1/1024 cadence check) | rowhammer-class or debugger-injected modification; binary aborts |
| XII-ATM-002 | F | inlined Lattice cell tamper detected at runtime | as above |

### §N.8 Severity Legend (XII)

- **F** = Fatal (binary refuses to start or aborts via `sml_abort` / `atm_panic`).
- **E** = Error (compile-time abort; `rc != 0`).
- **W** = Warning (compile continues; informational).

---

*Wave 11 (XII) deliverable. Sealed against `xii_manifest.mhash` at Phase XII-ζ:Ω12.*
