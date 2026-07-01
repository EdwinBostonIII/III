# TOOLS-QUOTIENT — the reusable quotient/involution kit

Five proven tools (each an exit-99 KAT) plus their two supporting organs, restored from branch
`reorg-backup-2026-07-01` and verified to build+run against the current tree (`df7ef796`). Fully
isolated: nothing here is wired into `build_stdlib.sh`, `run_corpus.sh`, or the seal — delete this
folder to undo, with zero effect on the system.

## What each tool is

| file | role | deps |
|---|---|---|
| `2276_quotient_space_compute.iii` | **The quotient calculator.** Runs exact-sign search in the QUOTIENT (sign/orientation-abstracted shape address) at O(1) per candidate; touches the exact-sign "wall" (PosSLP-family) only ONCE per distinct shape. Each candidate's strict sign = shape-rep sign XOR its reflect (orientation) bit. Proven: 60 candidates from 6 shapes → 6 wall touches, all signs correct. | none (standalone) |
| `2277_quotient_oracle_orbit.iii` | **The O(1) theorem multiplier.** Proving an exact identity for ONE orbit representative proves it for the whole 2^m-1 orbit for free, via Galois action = REFLECT. Concrete: incenter + 3 excenters = one orbit; σ_A(incenter) is a pure sign-flip (zero multiplies) yet content-addresses identically to I_A built by a fully independent construction. | `kfield.iii` (+ `coincidence`, `sha256` from libiii_native.a) |
| `2274_meta_involution_orbit.iii` | **The meta-theorem.** Cost, analogy, conservation are the SIZE, QUOTIENT, and FIXED POINTS of one order-2 involution (REFLECT). Two Z/2 actions (field Galois orbit, ring negation) coincide at rank 1, bifurcate above. | `exact_surd_value.iii` |
| `2149_universal_block.iii` | **The universal block — one kernel, four verbs, many faces.** Proves the disparate exact-geometry scopes are ONE kernel (a point in K under CONSTRUCT/IDENTIFY/DECIDE/QUOTIENT) by *composition*, not a facade. FACE 3: the unifying law `kf_point_addr(P)==kf_point_addr(Q) ⟺ kf_sign(Px−Qx)==0 ∧ kf_sign(Py−Qy)==0` (Eidolon and exact-sign are one relation). FACE 1: exact 2-link inverse kinematics to `W=(3,0)` in `ℚ(√7)` — the √7 cancels, wrist proven `==(3,0)` by DECIDE + IDENTIFY, and the other elbow is the Galois conjugate (O(1) REFLECT, mutation-checked distinct). FACE 2: the fuzzer's `coin_observe` engine detects the kinematics identity (both elbows → one Eidolon). FACE 4: the honest wall — `kf_rat_in_field` refuses out-of-K reach surds; exact reach/singularity sign is *exactly* 0 at full extension. HONEST: an architecture/unification proven by composition, NOT new arithmetic beyond kfield; transcendental joint angles + general degree-16 6R IK are OUT of scope (see `UNIVERSAL-BLOCK.md`). | `kfield.iii` (+ `coincidence`, `sha256`) |
| `2148_theorem_fuzzer.iii` | **The coincidence fuzzer (POC).** Constructs exact values in K=ℚ(√2,√3,√5) via DIFFERENT paths, content-addresses each (`kf_point_addr`), and the coincidence engine flags collisions = exact identities — SOUND (equal address ⟺ equal value; every collision re-verified by `kf_sign(A−B)==0`, so a SHA artifact can't fake a theorem). **Genuine discovery (no target named):** it enumerates all 21 pairwise products of the field surds through the real `kf_mul`, and the engine *surfaces* 16 distinct classes / 5 collisions including the 3-way `√30 = √2·√15 = √3·√10 = √5·√6` — probe-confirmed max-class = 3, engine seen-bit == an independent 32-byte address classing, every member Galois-verified. Also finds `(√2+√3)²=5+2√6`, `√2·√3=√6`, `(1+√2)²=3+2√2`; a float fuzzer would false-collide `√6` vs `218/89` (shown). HONEST: a sound theorem-VERIFIER / candidate-finder, NOT an autonomous novel-theorem prover — novelty adjudication stays unautomated; scope = in-field + kfield's i64 envelope. | `kfield.iii` (+ `coincidence`, `sha256`) |

Supporting organs (reusable in their own right):
- `kfield.iii` — the exact number-field calculator: `kf_radix / kf_zero / kf_mul / kf_point_addr` (content-addressed points via sha256). This is the real geometry engine `2277` drives.
- `exact_surd_value.iii` — the eidolon surd canonicaliser: `ep_gestate / ep_verb / ep_ingest_coeff`.

## Build + run

```powershell
powershell -ExecutionPolicy Bypass -File TOOLS-QUOTIENT\build_and_run.ps1
```

Or by hand (from the III root):
```
COMPILED\iiis-2.exe TOOLS-QUOTIENT\<file>.iii --compile-only --out TOOLS-QUOTIENT\build\<name>.o
gcc TOOLS-QUOTIENT\build\<name>.o [<organ>.o] STDLIB\build\iii\libiii_native.a -lws2_32 -lkernel32 -o TOOLS-QUOTIENT\build\<name>.exe
TOOLS-QUOTIENT\build\<name>.exe     # exit 99 == GREEN
```

Verified 2026-07-01: 2276 = 99, 2274 = 99, 2277 = 99, 2148 = 99, 2149 = 99 (all five via `build_and_run.ps1`).

## Reusing the capability elsewhere
`kfield.iii` and `exact_surd_value.iii` are ordinary III organs — to make them first-class library
capabilities, drop them under `STDLIB/iii/<domain>/` and add their module path to the `MODULES` array
in `STDLIB/scripts/build_stdlib.sh`, then reseal. (Not done here, to keep this kit non-invasive.)
