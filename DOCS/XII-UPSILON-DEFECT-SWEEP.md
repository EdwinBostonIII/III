# Phase XII-υ — Genuine-Defect Sweep (post-τ continuation)

Status: IN PROGRESS (continuous loop per standing directive). Three
genuine defects fixed + one faithful classification, each
evidence-verified. Sweep continues.

## υ.1 — Global-namespace-collision class: proven eliminated repo-wide

After Phase XII-τ pt2 module-prefixed xii_critpairs.iii, a ground-truth
`nm` sweep over all `STDLIB/build/iii/*.iii.o` checked the *class*, not
just the instance:

- L_ text symbols defined in ≥2 libiii_native.a members: **0**
- corpus tests (ex-negatives) defining a module-scope fn colliding with
  any of libiii_native.a's 977 distinct L_ text symbols: **0**

xii_critpairs.iii was the **sole** offender. Standard 3 ("fix ALL
same-class preexisting") satisfied by evidence — no speculative churn.

## υ.2 — corpus/43_attest_self_nonce.iii: tautological test → real assertion

Line 49 was `if attest_byte(k) != attest_byte(k) { differ = 1u8 }
/* placeholder */` — always false; `differ` never read; line 52
self-admits "tautological". The real intent (header line 2): "same
inputs + different nonce -> different digest". Fix: snapshot the FULL
32-byte Run-1 digest into a `malloc(32)` buffer (matching the file's
`mh`/`cl` idiom), and after the nonce-2 run assert ≥1 byte differs
across all 32 (a deterministic crypto-binding gate; not statistical).
Dead loop + weak 3-byte heuristic removed; `r1`/`mh`/`cl` all freed on
every path. Verified: compile/link rc=0, **run rc=99 = EXPECTED**
(diff_count ≥ 1 ⇒ attestation is genuinely nonce-dependent — the test
now exercises the property). Satisfies feedback_no_tautological_proofs.

## υ.3 — numera/x25519.iii: out-as-scratch workaround + dead placeholder

Two genuine defects in `fn x25519`:

1. **Dead placeholder** — `let s_buf_id = bigint_from_u64(X_ARENA,
   0u64) /* placeholder so arena alloc'd */; bigint_drop(s_buf_id)`.
   Alloc+immediate-drop; X_ARENA already allocated/used. Pure cruft.
2. **out-as-scratch workaround** — comment "local 32-element array...
   no, W9. Use module-scope:" then clamps the scalar by mutating the
   caller's `out` buffer, which the 255-round ladder reads as the
   clamped scalar (`x_scalar_bit(out,t)`), later overwritten with the
   result. Using the output parameter as secret-scalar scratch in a
   `@constant_time @side_channel_resistant @crystal` X25519.

Fix (no workaround, the file's own module-scope idiom — it literally
said "Use module-scope:" then didn't): added `var X_SCALAR : [u8; 32]`
(established idiom: babel_intent.iii/babel.iii/call_context.iii); clamp
into X_SCALAR; `x_scalar_bit(idx)` reads X_SCALAR (parameterless, like
x_cswap reading module-scope ladder state); deleted the dead s_buf_id;
**explicitly wipe X_SCALAR before return** alongside the X_X1..X_Z3
zeroing — the secret scalar previously lived only transiently in `out`,
so a dedicated buffer must be cleared to match and *improve* the
side-channel posture. `out` is now written exactly once (x_encode_u).

Verified: triple-identity x25519.iii.o `5f1f0ae2…`×{iiis-0,1,2};
build_stdlib FAIL=0; **corpus 73 RFC 7748 X25519 KAT rc=195 =
EXPECTED** (functional exactness); run_corpus 258/0/94 genuine-FAIL=0;
run_xii 93/0; determinism — `build_iiis1`/`build_iiis2` rebuilt vs new
libiii_native.a → both `verify: OK`, golden MATCH, **no reseal** (the
change is compiler-unreferenced; drift-driven rule re-confirmed).

## υ.4 — cg_r3.iii:2665 "Lattice placeholder": faithful NON-defect

The XII @lattice gate emits via `r3_pe_lattice_emit(...)` —
`extern … from "cg_r3_xii.c"` (implemented C reference), called inside
a real `if xii_lat==1u8 { canonicalise; compute_circ; lattice_emit }`
block. "Lattice placeholder + call-site descriptor that LDIL will fill"
is the deliberate **LDIL deferred-fill runtime artifact**, the
sealed-ceremony-gated seam — consistent with the completed Phase μ
cg_r3_xii.c audit. Standard 13: NOT a code defect; not fabricable; no
make-work. Classified faithfully (delegated implementation present),
not hand-waved.

## ADR

- **Decision:** a test that cannot fail (tautology / self-compare /
  unread flag) is a defect even when "passing"; replace with an
  assertion that genuinely exercises the contract (full artifact, not
  a 3-sample heuristic). [feedback_no_tautological_proofs]
- **Decision:** never use a caller's output buffer as secret scratch;
  a primitive with `@side_channel_resistant` must own a dedicated
  buffer for secret-derived intermediates and wipe it before return.
- **Decision:** "placeholder/stub/workaround" keyword hits are
  triaged by reading, not pattern-panic: genuine Standard-2/3 defects
  are fixed; documented sealed-ceremony / FROZEN-SPEC / deferred-fill
  seams with a present delegated implementation are classified
  faithfully and left (Standard 12/13), as in Phases μ/ο.
- **Consequence:** both edited modules stay triple-bit-identical and
  trigger no compiler-binary drift (compiler-unreferenced changes);
  RFC 7748 / nonce-binding KATs prove functional exactness.
