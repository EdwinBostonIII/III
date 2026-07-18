# III-HOLOS — THE ORGANISM: the engine fleet, one body

STATUS: LANDED 2026-07-17 (the diet 2c35861e → the holos 0c88de81 → the
dissolution, this arc).  The directive: *"I need these engines dismantled,
their skills and presence kept and enhanced, and their perpetual dynamic
activation, coordination, combination and behavior as the result of
system-wide mutually beneficial cohesive small processes that amount to their
invocation in the right way in the proper circumstance."*

## §1 What dissolved

Thirty standalone engines — thirty binaries in `COMPILED/`, thirty
`build_iii_*.sh` scripts, each an on/off process dragging its own copy of the
whole archive (up to **1.78 GiB SizeOfImage each**) — became **cells of one
organism**: `COMPILED/iii`.

    iii                      THE FACE: every skill's standing, dues, vitality (0.1s)
    iii <skill> [args...]    any engine's whole surface, one seat down
    iii due | earn N | law   drift, proof-earning, the organism's laws

The thirty skills: agon author closure crypto doxa eidolos ergon eval events
exact friction hexad intent judge kardia line manifold motion plane proofcarry
prove pulse soma space substrate testament typecheck witness worldline xeno.
Every face TU survives (its `fn main` became an exported `<skill>_enter`; the
organism shifts `argv` one seat), so each engine's CLI presence is preserved
byte-for-byte one level down.

## §2 The model (the kardia law, lifted to the engines themselves)

`katabasis/holos.iii` gives each skill exactly what kardia gave each corpus
claim:

    (name, class, probe, face, dep-closure, REACH-PIN, standing, liveness)

- **The reach-pin** = mhash fold of the BODY (pinned iiis-2 ⊕ committed
  archive) ⊕ the skill's face TU ⊕ its fresh-organ closure — the same lists
  its retired build script compiled, carried into the holos manifest so the
  dissolution loses no knowledge.
- **The ledger** (event-primary): append-only `STDLIB/build/holos/holos.log`,
  `H1|skill|pin16|exit|mode|seq`, state = last-wins-by-seq fold per mode
  class; malformed lines COUNTED and refused.
- **THE MODE LAW** (the monotone law's sibling): a WORK record — any real
  invocation's autobiography — never displaces PROOF standing.  `iii prove`
  answering REFUTED (exit 1) is an *answer*, not a wound.
- **STANDING**: PROVEN (exit-0 self-derivation on exactly this body) | STALE
  (the body drifted since) | UNPROVEN | RED (a live wound).  **DUE ⇔ drift.**
- **VITALITY** refuses over any RED — the organism will not call itself
  healthy over a known wound.
- **Classes**: 26 P-skills carry cheap self-derivations (their own `prove`
  verbs / law-fixed probes; `iii earn` converts dues).  4 U-skills
  (author/eval/testament/witness) are counted apart — their laws run at every
  real invocation (the exit-9 refusal pattern) and their deep verification is
  owned by named seats (ergon autarkeia/exec, the kardia cells, the event
  corpus three-way oracle).
- **Seven holos law arms** run at EVERY invocation before any skill moves
  (registration injectivity, last-wins fold, the mode law, due-on-drift,
  malformed teeth, well-formed fold, vitality refusal); a failed arm refuses
  the whole face (exit 9, the autognosis pattern).
- **THE TWO-SOURCE LAW**: every dep path holos pins must be cited by
  `COMPILER/BOOT/build_iii.sh` — table/build drift is COUNTED at every face.
  (It bit during construction: 24 uncited chain TUs, fixed by making the
  build's citation surface a load-bearing existence guard.)

This is what "beyond on and off" means concretely: no engine process exists
to be running or not running.  Skills have *standing* held between
invocations; any touch of the organism folds the ledger, surfaces drift, and
appends to the autobiography; activation is exactly circumstance — a question
asked (dispatch), a drift observed (`due`), a proof owed (`earn`).

## §3 The enablers (measured)

**THE DIET** (2c35861e): under the 8-bytes-per-element slot model,
`witness_hook`'s eight byte-buffers (1.36 GiB) and route V's `EMEM`
(1.07 GiB) lived in every linking image.  Both now claim their regions LAZILY
via VirtualAlloc at init/world entries — capacity unchanged, demand-zero like
.bss, failed claims refuse loudly, a process that never publishes never pays.
Proven by corpus cell 1340 (99/99) and the FULL event-waist gate (19/19
differential, tamper 193, byte-identical determinism).  Without the diet the
union body (4.95 GB of static arrays) could not fit the small code model's
2 GiB RIP-relative reach; with it, `iii` is **1.32 GiB SizeOfImage**.

**Fleet-wide virtual-image reduction**: the sum of the thirty retired images
was ≈ 18 GiB of reserved address space; the organism is one 1.32 GiB image.

## §4 The proof record (the supersession law, discharged)

1. **Two-path**: 46/46 probes agree old-fleet vs organism — byte-identical
   stdout AND equal exits (all six geometry `prove` batteries, kardia
   prove/status over 1,762 cells, doxa/ergon/eidolos/soma proves, eval
   executing a program, route-V `--diff`, exact algebraic probes,
   hexad/intent/typecheck/xeno probes, pulse/crypto hashes, every usage face).
2. **The census through the organism**: `iii ergon census` → **WHOLE** — all
   nine seats derived; seat 8 (EXEC) spawned `COMPILED\iii.exe <skill>`
   probes (the organism exercising its own limbs to OS-true exits); registry
   1791, matched 1791, phantom 0.
3. Only then: 30 build scripts `git rm`'d, 19 tracked + 11 untracked binaries
   removed; `iii soma map` still 0 UNRESOLVED after.

## §5 Consumers repointed

ergon.iii (≈110 spawn strings → `iii.exe <skill> …`; the `iii-no-such-tool`
spawn-fail negative control kept) · run_event_corpus.sh / run_event_waist.sh
(mint the organism via `build_iii.sh [--out]`, invoke `events`/`eval` skills)
· run_meaning.sh (EVAL_BIN → the organism, cache keys on its digest) ·
nomos_seal.sh (`substrate` verbs) · subsystem_test_gate.sh (`iii ergon
census`) · _theta2/_theta3w chains · cov_gate_driver.iii roots gained
iii_main.iii + holos.iii (entry-TU + verb-organ, the RITE root discipline).

## §6 What stands beside the organism (named, not engines)

The compiler chain iiis-0..3 + sanctum (the basal substrate, never a skill),
the XII `gen_*`/`sign_*`/`verify_*` utilities (build-ceremony substrate), and
the sovtc mains (sovas/sovld/sovlink — the sovereign toolchain, built
per-use by the evergreen sweep).

## §7 Growth rungs (named honestly, not promised)

- **Cross-skill wakes**: a RED standing could mark dependent skills DUE
  through shared closure membership (the dep lists already carry the graph).
- **The ledger as doxa evidence**: holos P-records are DERIVED evidence in
  doxa's sense; a mint could stake on them.
- **U-class narrowing**: a safe cheap self-derivation for testament/witness
  (e.g., a scratch-keypair sign→verify round-trip) would move them to P.
- **`iii earn` in the pulse**: the birth-rite attestor could fold the
  organism's own image pin into every earn record (pulse is already a skill).
