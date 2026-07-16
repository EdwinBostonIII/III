# III — THE AUTARKEIA MAP (Α) rev.2: trust that travels without the author

> **STATUS: Α0 + Α1 EXECUTED AND GATED (2026-07-16, the first sitting) — Α2–Α4 remain the ladder
> (located, not begun).** Measured at execution, every line observed command output:
> `STDLIB/scripts/run_testament.sh` **ALL GREEN exit 0** — both tools leaf-built from source; **gen-0
> emitted over the live tree** (33,524 B, 3,649 manifest files, tree root `41b449aa…`); RADICAL pins
> re-derived from the committed record (head `2a84e3b7…`, 195 rows, chain 5023); the FORGE chain
> **re-walked row by row** from committed bytes to the sealed head (`c28e85ac…`, 69 rows); Tier-1 AND
> full re-derivation green; the tamper battery each class its DISTINCT exit (body-byte→11,
> wrong-key→11, manifest→14, file-content→14; the generation/monotone classes 12/15 are
> covenant-owned and ALSO proven: self-parent→12, swapped-keypair→15, shrunk-tree monotone→15, plus a
> chained gen-1 GREEN with its parent); **two emissions reproduce the ENTIRE file byte-for-byte,
> signature included** (FIPS-205 deterministic signing); THE PIN MIGRATION PROVEN —
> the testament's RADICAL certificate equals bash's `sha256(head|rows|chain)` (`6acc138e…`): truth
> that lived as a bash string is now re-derivable from a signed spine, bash demoted to consumer.
> `iii-testament` + `iii-witness` are standing tools NINE and TEN under `run_standing_tools.sh`
> (deterministic-keygen KAT per FIPS-205; malformed input REFUSED exit 10; committed-testament Tier-1
> arm). The canonical generation-0 testament + public key are committed at `STDLIB/testament/`
> (seed/sk custody NEVER committed, `.gitignore`-pinned). Rev.2's own kill-switch (the
> adversarial-bash gate) belongs to Α2 and stands unfired.
>
> **Below is rev.2 as written (second deep-think pass, 2026-07-16), the plan-of-record for the ladder.**
> Rev.1 located the pursuit. Rev.2 grounds it in the tree's fullness: the rev.1 kill-switch
> (*"are the mathesis certificates statically checkable?"*) is **DISCHARGED by measurement** (§2),
> the external architectural review's three frictions (witness bootstrap, stamp-collecting,
> SLH-DSA payload) are answered with **III-native mechanisms**, not generic mitigations (§4, §6),
> and every rung now carries its lean implementation: exact formats, verbs, reuse, and the
> not-built list (§7). Lean means lean — nothing speculative, everything load-bearing — not small.
> Every number marked **[measured]** was produced against the live tree during this pass; claims
> from ledgers/memory are **[recorded]**.
> Companions: `III-UNIFICATION-LEVERAGE-MAP.md` (Λ), `III-GERMINATION-MAP.md` (Γ — prerequisite,
> subsumed), `III-MATHESIS-MAP.md` (Ξ — the certificate machinery Α generalizes).
>
> ΑΥΤΑΡΚΕΙΑ — Aristotle (EN 1097b): *that which taken alone makes a thing choiceworthy and
> lacking in nothing.*

---

## 0. The verdict in one paragraph

Λ made verification ambient; Γ detached existence from the substrate. Three absolutes remain, and they
are exactly the ask's four adjectives. **(1) Trust does not travel** — a stranger must re-run hours of
derivation on a prepared host; no portable proof object exists (`EXCHANGE/` glob = 0 hits **[measured]**);
III has not portable trust but *a highly exclusive re-enactment requirement*. **(2) The judge is
foreign** — **≥163 gate scripts** (68 STDLIB/scripts + 61 COMPILER/BOOT + 34 STDLIB/sovir **[measured]**)
compute every verdict with bash + coreutils; even the MATHESIS_CERT itself is minted by
`printf | sha256sum | cut` with its pins hardcoded as bash strings (`run_mathesis.sh:164–176`
**[measured]**). The Λ map's TCB names loader, CPU, node, gcc-witness — never bash. The software that
declares III correct is not III. **(3) Growth needs an AI** — outside the piloted mathesis domain, every
extension is authored in an AI conversation. **Α closes all three**: the system becomes its own
**witness** (one signed, chained, minutes-checkable TESTAMENT + a verifier whose trust root is the
already-audited SVIR waist), its own **judge** (verdict computation as sovereign .iii; bash demoted to
launcher with a proven-airtight layering, §4.Α2), its own **covenant** (evergreen as a cross-host,
cross-generation equation), and its own **author** (machine authorship under the NAMED-DEFICIT LAW,
provenance recorded). The terminal property — correctness *and continued growth* checkable by a
stranger, on any machine, in minutes, with no toolchain, no author, and no AI taken on faith — exists
nowhere else (§5).

---

## 1. The gap, measured (2026-07-16)

| Fact | Value | How established |
|---|---|---|
| Portable proof object | **ABSENT** (`**/EXCHANGE/**` = 0 hits) | glob **[measured]** |
| Judge surface | **≥163** .sh gates (68 + 61 + 34 across scripts/BOOT/sovir) | globs **[measured]** |
| Verdict primitives | bash: `grep -q` pins, `cut -d'\|'`, `$rc == $want`, `FAIL=1` counters | run_evergreen.sh:37–60, run_standing_tools.sh:27–35, run_mathesis.sh:51–66 **[measured]** |
| Certificate minting | `sha256sum \| cut` in bash; pins hardcoded in-script | run_mathesis.sh:164–176, 203–208, 227–232 **[measured]** |
| Mathesis gate linker | **gcc** (fast-lane corpus convention) | run_mathesis.sh:57 **[measured]** |
| Named TCB in prior maps | loader, CPU, node, frozen gcc — **bash unnamed** | Λ-map §1 **[measured: read]** |
| Signature faculty | `numera/slhdsa.iii`: full WOTS+/FORS/XMSS/hypertree, SHA2 + SHAKE families, n=16/24/32 (cat 1/3/5); byte-FIPS-205, all six s-sets | source **[measured]**; conformance **[recorded]** |
| Quorum + transport | ML-DSA quorum federation LIVE (`run_federate_quorum.sh`, mathesis stage 2660); sealed_channel | run_mathesis.sh:159, sovir glob **[measured]** |
| Hash faculty | iii-crypto SHA-256 == FIPS-180 vector | run_standing_tools.sh:53–60 **[measured]** |
| Meaning-bearers | THREE: cg_r3-native, iii_eval, route V svir_event; oracle 105/151 | **[recorded]** |
| Trust-root candidates | svir_verify **97 ln** + svir_interp **277 ln** = 374-line auditable/reimplementable root | Γ-map §1 **[measured: read]** |
| Regrowth | spore Σ, 3 native ISAs, byte-DDC; bootstrap_from_clean 6/6 | **[recorded]** |
| Machine authorship | mathesis agenda/synth/pilot organs + autonomy corpus 2682; 8 pilot discoveries | globs **[measured]**; **[recorded]** |

Every organ Α needs exists sealed. What does not exist is the spine. Α is a weld, not an invention —
the house's highest-confidence move (leaf-tool elevation: eight precedents **[recorded]**).

---

## 2. THE KILL-SWITCH, DISCHARGED: the anatomy of a mathesis certificate [measured]

Rev.1 said: *if the certificates are run-receipts needing re-execution, Tier-1 falls apart — prove
static verifiability first.* Proven, by reading `run_mathesis.sh` end to end:

A campaign certificate has **two strata**:

1. **Static stratum — checkable with hashes alone.** Committed stream records (`MXS#`/`MXR`/`MXC`/`MFF`
   rows) are content-addressed hash chains over theorem statements; their heads are pinned
   (e.g. radical: `chain=5023 head=2a84e3b7…`, forge: `chain=69 head=c28e85ac…` **[measured]**), and
   each CERT is `sha256(head|counters…)` — e.g. `PSI_CERT = sha256("2483527537094825|…|f6d76f99…")`
   (run_mathesis.sh:357). **A witness can re-walk every chain and re-derive every CERT from committed
   bytes, no execution.** Tier-1 stands.
2. **Behavioral stratum — truth by re-derivation.** The corpus gates (2600–2718) re-prove the
   mathematics and exit 99. This is Tier-2 by construction, exactly the honest split.

So Tier-1 attests: *the records are intact, chained, correctly bound, signed, and none has been
altered since sealing.* Tier-2 attests: *the records are true.* Both claims stated, neither inflated.

**The rev.2 consequence — the pin migration.** The pins that make the static stratum checkable
currently live as strings inside a bash script. Their correct home is the testament's MATHESIS
section; the script then *checks against* the testament instead of embedding truth. This deletes
scattered truth (lean) and is what makes the static stratum portable (the point).

---

## 3. Candidates, Meadows-ranked (unchanged from rev.1, compressed)

Tune-parameters < consumer-surface < capstone-weld < Λ-completion < zk-generalization (nearest
external prior art — weakest novelty) < cross-repo horizon < **⟨THE PICK⟩ Α**: Γ transcended the
*substrate* boundary; Α transcends the **author/observer boundary** — the last one the system treats
as fixed. Γ answers *"can III exist anywhere?"*; Α answers *"can III be believed — and continue
becoming — anywhere, by anyone, with nobody's word taken for anything?"*

---

## 4. The Α program rev.2 — lean implementation, no compromise

### Α0 — THE SPINE: `testament.dat` + the pin migration
**Format (the whole spec — one page, fixed layout, integers u64 LE, digests raw SHA-256 32 B):**

    "IIITSTMT" 8B | version u64
    GEN:  parent-testament digest 32B | generation index u64
    KEY:  param id u64 (SLH-DSA-SHA2-256s) | public key 64B
    SECTIONS: count u64; each: tag 8B ASCII | payload_len u64 | payload
    SIG:  SLH-DSA-SHA2-256s (29,792 B) over sha256(everything above)

Sections REQUIRED from generation 1: `TREE` (manifest digest + Merkle root over **raw bytes** of
manifest-listed committed files, sorted by path bytes), `SEED` (iiis-0 digests + DDC twin digests),
`BEARER` (three-route corpus agreement receipts: ids, counts, receipt-table digest), `MATHESIS`
(per campaign: stream-record digest, chain head, CERT value — **the migrated pins**), `SPORE`
(Σ member digests per ISA), `TOOLS` (standing-tool digests + smoke receipts), `EXEC` (route V
`--cert` receipts root). PRESENT-IF-SEALED: `ZK` (existing zk-audit receipts), `FED` (ML-DSA quorum
record), `JUDGE` (required after Α2). **Monotone law:** tags are never removed; per-tag counters
never decrease. Payloads are digests and counters only — a testament carries facts, never prose.
Size: signature-dominated, ~35 KB total.

**Lean decisions, named:** raw-byte hashing, no LF normalization (CRLF sources exist in-tree
**[recorded]** — normalizing would lie about the tree); the file list is a **committed manifest**
(itself in TREE scope) with an advisory drift gate against `git ls-files`, walked by aether fs —
never bash `find`; **XII term encoding NOT used** for the container — a 1-page fixed layout beats
importing a term algebra for a manifest (XII stays where it earns: INTENT≡EXECUTION on computations).
Generator: `iii-testament emit|show` — the tenth standing tool, built by the eight-precedent
leaf-tool pattern; its first fusion consumes artifacts that exist today (§1 rows). Lineage note:
`run_trust_certificate.sh` (the GU's one-computation provenance cert **[measured: exists]**) is the
proven micro-form — Α0 is that certificate generalized from one computation to the organism.
*Exit gate:* two emissions on an unchanged tree → byte-identical unsigned body; every section
re-derives from its source artifact; `iii-witness verify` (Α1) green on the first real testament.
*Falsifier:* any one-byte perturbation of any contributing artifact → emit refuses or verify reddens.

### Α1 — THE WITNESS: minutes, zero toolchain, five-layer trust root
`iii-witness verify testament.dat [--tree ROOT --manifest M] [--parent PREV]` — checks format,
signature (SLH-DSA verify = pure hash walks — deliberately the stranger-cheap direction), generation
link, section self-consistency, **static-stratum re-derivation** (re-walk every mathesis chain from
committed records; recompute every CERT), and with `--tree`, the Merkle root. Distinct exit code per
tamper class (8-bit discipline **[recorded]**): 0 green; 10 format; 11 signature; 12 generation;
13 chain/CERT; 14 tree root; 15 monotone-law breach.

**The bootstrap paradox, answered in layers (deepest first — the review's friction #1):**
1. **The SVIR trust root (the III answer).** The witness ships twice from one source: native
   `iii-witness` (convenience) and `witness.svir`, an anchor-verified v2 SVIR module. A stranger's
   root is then **374 auditable lines** — svir_verify (97) + svir_interp (277) **[measured]** — or,
   stronger, *their own* interpreter written in an afternoon from the SVIR spec in any language.
   The verifier is not a binary you trust; it is a spec small enough to reimplement independently.
   No other system can make this move; it is the waist cashing out for strangers.
2. **DDC cross-lineage byte-identity** of the native witness (reuse `run_ddc.sh`/`seed_ddc.sh`).
3. **Three-bearer agreement** on a witness-KAT (native ≡ eval ≡ route V).
4. **Previous-generation pinning** — witness digest sealed in the *next* testament (the fixed-point
   dodge, stated not discovered).
5. **External anchoring, zero new infra:** the witness digest + testament head go into each seal
   commit's message — the repo's own git history is the public replication ledger; every clone
   carries it; a stranger checks the binary with OS-native sha256 before first use (the review's
   mitigation, adopted as layer 0 of the protocol, not the load-bearing layer).

*Exit gate:* the stranger protocol on a bare host — copy witness + testament + repo; exit 0 in
minutes; each tamper class produces its distinct red; the SVIR route reproduces the native verdict.
*Falsifier:* any tamper class passing Tier-1, or SVIR/native verdict divergence.

### Α2 — THE JUDGE: sovereign verdicts with an airtight layering
> **STATUS: EXECUTED.** `iii-judge` is built (`COMPILER/BOOT/build_iii_judge.sh` →
> `COMPILED/iii-judge.exe`; source `STDLIB/iii/aether/judge_cli.iii`, composing
> `aether/stoma_proc` for the OS spawn + `numera/cad` for digests — no island). All four verbs
> ship and are gated as standing tool 11 in `STDLIB/scripts/run_standing_tools.sh` under the
> adversarial-launcher trial below (full-width rc capture, forged-PASS-text ignored, ratchet
> break, fold sensitivity — all GREEN). The verbs are realized positionally
> (`run <want_rc> <cmdline>`, `hash <file> [expected_hex]`, `pin <ledger> <key> <value> up|down`,
> `fold <receipts>`) rather than with `--flag` syntax. The cross-generation digest anchor named
> below is Α3 and remains future.

`iii-judge` — one tool, four verbs, consumed by the ≥163 scripts (which keep orchestration and lose
authority):

    run  --want N --receipt R -- prog args…   # CreateProcess/Wait/GetExitCodeProcess: rc travels
                                              # OS→judge; hashes the exe before spawn into R
    hash --want D --receipt R -- path         # iii-crypto digest compare
    pin  --ledger L --name K --value V        # monotone ratchet arithmetic (up-only/down-only)
    fold --dir RECEIPTS --root OUT            # chained fixed-binary rows -> Merkle root -> JUDGE

**Why a complicit launcher cannot forge a green (the layering, stated precisely):**
- **rc-sovereignty:** every exit code flows OS→iii-judge directly; bash never sees or sets a verdict.
- **artifact-sovereignty:** every binary is digest-bound (judge hashes what it spawns; sections bind
  what was built); a stub-swap changes a digest.
- **coverage-sovereignty:** `iii-testament emit` compares receipt counts against section-declared
  expected counts (corpus size, tool count, stage list); a skipped check is a missing receipt is a
  monotone-law red. Text logs (`PASS`/`GREEN` lines) become human decoration — emit never reads them.
- **the anchor for expected digests:** under an unchanged TREE root, artifact digests must equal the
  parent generation's (the covenant equation, Α3); under a changed tree, the DDC twin lineage must
  byte-match. A forger must therefore subvert the toolchain, both DDC lineages, and the parent
  testament **simultaneously** — and Tier-2 re-derivation still catches that. Residual named in §6.

*Exit gate:* **the adversarial-bash gate** — a deliberately complicit launcher (forged PASS text,
doctored rc capture, stub binaries, skipped stages, fabricated receipt rows) cannot yield a signed
green testament; each forgery class reddens at judge, emit, or witness — never at a grep.
*Falsifier:* any forged green surviving to a signed testament.

### Α3 — THE COVENANT: evergreen as an equation; trust compounds across hosts
Every green run emits testament(n) chained to testament(n−1); the monotone law is enforced by
iii-judge `pin`. Define `core(T)` = TREE root ∥ SEED digests ∥ MATHESIS heads ∥ BEARER receipts
(host-invariant by construction); TOOLS digests are per-ISA and recorded per host. Cross-host:
germinate on host H (Γ machinery unchanged), re-derive, emit testament_H; the covenant gate asserts
`core(testament_H) == core(testament_win64)`. Transport and multi-party endorsement reuse what is
sealed: `sealed_channel` + the **live ML-DSA quorum** (`run_federate_quorum.sh`, stage 2660
**[measured]**) — a quorum of hosts co-signs the FED section; no new protocol is invented. Every
new host's receipt folds back as a DDC lineage row: Γ's R3 loop ("diversity is fuel") extended past
the repo boundary into **R4 — exported trust returns as verification strength.**
*Exit gate:* a 2-host covenant (win64 + one Γ host) with byte-equal cores across one generation step,
FED co-signed.
*Falsifier:* any core divergence across hosts; any monotone decrease across generations.

### Α4 — THE AUTHOR: machine growth under THE NAMED-DEFICIT LAW
The stamp-collecting risk (the review's friction #2) is not answered with a heuristic but with a
**structural law**:

> **THE NAMED-DEFICIT LAW.** No agenda item exists unless it cites a deficit already *named* in the
> testament: a refusal-class counter, a named-unreached spelling, a coverage pin, an emission-refusal
> class. A seal is admitted only if it **strictly decreases its named counter** or extends a census
> with **two agreeing routes**. Novelty is adjudicated by the eidolon organ (verdict `novelty=NONE`
> ⇒ reject **[recorded: the adjudication machinery exists]**). Per-cycle admission cap. Provenance
> recorded per seal: MACHINE / HUMAN / AI.

The agenda is therefore the *complement of the sealed surface* — and that complement is finite and
already named today: 8,130 capacity-refused spellings (why=1), 4 named-unreached, emission-refusal
classes 7 + 29 + 10 **[recorded]**. `x+0=x` permuted across 64-bit space cites no named deficit and
cannot enter. The organs exist: agenda/synth/pilot/frontier **[measured]**; the pilot's 8 discoveries
are the precedent. Every machine-authored delta lands only through the full gate chain and appears in
the next testament with `provenance=MACHINE`.
*Exit gate:* N≥3 consecutive autonomous cycles, zero human/AI edits, each cycle's testament green,
each cycle strictly shrinking at least one named counter.
*Falsifier:* a cycle needing a hand edit (counter resets — honest accounting); a seal admitted
without a named deficit; ratchet/cap breach.

---

## 5. What "no other system" cashes out to (the pentagon, unchanged and checkable)

| Property | CompCert | Wheeler-DDC | repro-builds | Lean/mathlib | RISC Zero/SP1 | **III + Α** |
|---|---|---|---|---|---|---|
| Self-hosting fixpoint | — (Coq/OCaml) | — | — | — (C++ kernel) | — (LLVM/Rust) | **sealed** [recorded] |
| Multi-bearer verified semantics | proof-once | one-shot | bytes only | proofs only | per-exec | **sealed** [recorded] |
| Substrate-independent regrowth | — | — | partial | — | — | **sealed (Γ)** [recorded] |
| Compact portable self-witness | — | — | — | — | per-program | **Α adds** |
| Machine-provenance self-extension | — | — | — | — | — | **piloted → Α welds** |

Each column's occupants are real and respected; none holds the row set. The unified object is new.

---

## 6. Named limits and risks (the cost, or it is not a decision)

- **Key custody is not mathematics.** A signature binds a chain to a keypair, not to virtue. The
  claim is tamper-evidence + continuity, never identity PKI.
- **SLH-DSA-SHA2-256s pinned (cat 5): pk 64 B, sig 29,792 B** (the review's friction #3). Signing is
  once-per-green (minutes-class, acceptable); verify is hash-walks (the stranger's side, cheap);
  length-prefixed sections make the blob structurally boring. The "f" (fast-sign/large-sig) sets are
  deliberately not used.
- **The residual forgery bound (from Α2's layering):** a green is forgeable only by simultaneously
  subverting the toolchain, both DDC lineages, and the parent testament — and Tier-2 germination
  still exposes it. Stated as the bound; never claimed as zero.
- **The witness fixed-point** — dodged by previous-generation pinning; stated in the spec.
- **Bash remains as launcher.** Launcher ≠ judge; the adversarial-bash gate is the teeth. The ≥163
  scripts are not rewritten (lean) — they are demoted (their greps become decoration; the pin
  migration and judge verbs are staged per-gate, covenant-ratcheted, no big-bang).
- **Testament determinism:** raw bytes, sorted paths, wall-clock-free, manifest-scoped — every known
  environment trap (CRLF, OneDrive dehydration, ordering) named in the format decision **[recorded]**.
- **Α4 breadth** stays the speculative end — staged last; a stalled author organ leaves Α0–Α3 intact.
- **What Α does NOT claim:** zk beyond Λ4's honest scope (ZK section carries existing audit receipts
  only); no verification of CPU/loader/physics; self-signing ≠ third-party endorsement — the FED
  quorum is endorsement *machinery*, not endorsement.

---

## 7. The lean ledger (what is built, what is reused, what is refused)

| | Items |
|---|---|
| **New binaries (3 + 1 form)** | `iii-testament` (emit/show), `iii-witness` (native + `witness.svir` anchor-verified form from the same source), `iii-judge` (run/hash/pin/fold) |
| **New formats (2, ~1 page each)** | testament layout (§4.Α0); receipt row `{tag, want, got, exe-digest, prev-digest}` |
| **New gates (2)** | `run_testament.sh` (emit + witness green, generation step); `adversarial_bash_gate.sh` (the forgery battery) |
| **Staged edits** | pin migration out of run_mathesis.sh into MATHESIS section; per-gate judge-verb adoption (covenant-ratcheted, no big-bang) |
| **Reused sealed organs** | slhdsa.iii (sign/verify); iii-crypto SHA-256; svir_verify + svir_interp (the 374-line trust root); DDC lineages (`run_ddc.sh`, `seed_ddc.sh`); Γ spore + host matrix; mathesis chains/streams/pins; `iii-events --cert` receipts; `run_trust_certificate.sh` (micro-form lineage); `sealed_channel` + ML-DSA quorum (`run_federate_quorum.sh`); eidolon novelty adjudication; the ratchet idiom; the leaf-tool build pattern (8 precedents) |
| **Explicitly NOT built** | no blockchain, no network protocol, no PKI; no new hash or signature scheme; no XII container encoding; no new interpreter (svir_interp is the reference); no zk expansion; no bash rewrite; no LF normalization; no prose in the testament |

---

## 8. Confidence + first sitting

**Calibrated confidence:** HIGH on the gap analysis and the certificate anatomy (§1–§2 measured
today). HIGH on novelty (§5 checkable). MEDIUM-HIGH on Α0–Α2 cost (leaf-tool pattern ×8; the only
new engineering shape is the judge's process-spawn verb, and aether/stoma already own that Win32
cluster **[recorded]**). MEDIUM on Α4 breadth beyond the piloted domain.

**Kill-switch rev.2 (the rev.1 one is discharged):** if the adversarial-bash gate finds a forgery
class the Α2 layering cannot redden **without** re-deriving the behavioral stratum at emit time,
STOP — re-scope Tier-1's attestation sentence before shipping any testament; the pentagon's fourth
vertex must be honest or it is marketing.

**First sitting, in order:** (1) freeze the two 1-page formats; (2) `iii-testament emit` fusing
today's artifacts (chains, pins, digests, receipts); (3) `iii-witness verify` static stratum + the
tamper battery; (4) the pin migration for ONE campaign (radical: head `2a84e3b7…`) as the pattern;
(5) the stranger protocol on a bare host. Everything after is the ladder.

**The one-sentence answer:** *move the pins out of bash and into a signed spine, put the verdicts
into sovereign hands, give the stranger a 374-line trust root instead of a nine-hour re-enactment,
and bind the machine's own future authorship to named deficits — then III is the first system whose
correctness and whose growth are both checkable by anyone, anywhere, in minutes, on nobody's word.*
