# III-KOINONIA — the money-engine in communion with the aether federation

**κοινωνία (koinonia):** communion, fellowship, a sharing-in-common. This is the organ that was missing — not a
new network stack (III already has the sealed federation), but the **composition** that puts the ZK-hunt
money-engine *onto* that federation, under one law.

## The one law: tier-gated outbound (III-FEDERATION §2), applied to money

Every value in III carries a tier. The federation admits a value across a machine boundary only by its tier. The
tiers (`aether/fed_tier.iii`): `HOST(1) < CLUSTER(2) < REGION(3) < SOVEREIGN(4) < PLANETARY(5)`.

KOINONIA's law: **a finding crosses only when it is exact-proven.**

- An unproven / false finding is admitted at `HOST(1)` — it never leaves the machine.
- A finding whose forgery the exact engine **confirms** (`row·w0 ≡ 0` over the field; the ELENCHOS/APORIA verdict)
  lifts to `SOVEREIGN(4)` — cross-organization sealed-trust, i.e. *a disclosure to a bounty program* — and is
  sealed into the append-only witness chain (`fed_seal`), anchored under the `PLANETARY(5)` bounty fabric.

**The proof is the passport.** A fabricated finding is worthless here by construction: with no proof it stays
`HOST`-local forever. This is precisely why "never fake a finding" is not a rule bolted on — the architecture
*enforces* it.

## Status (built + verified vs. designed)

- **BUILT, GREEN, mutation-tested — `omnia/koinonia.iii`:** the core communion. Composes `omnia/isub`
  (the witnessed event / merkle root of a finding) + `aether/fed_tier` (the tier registry) + `aether/fed_seal`
  (the append-only, tier-ordered witness chain) + the exact GF(p) forgery check (the ELENCHOS verdict in
  miniature). Proven finding → `SOVEREIGN` + sealed; false finding → `HOST`, unsealed. Removing the proof gate
  makes a false finding wrongly federate — the gate is load-bearing.

## The extension layers (the same gate, more primitives — designed, on-disk to compose)

Each is an existing, gated organ that plugs onto the identical proof-gate:

| Primitive | Organ (on disk, gated) | Role in the communion |
|---|---|---|
| **Consensus ordering** | `aether/hotstuff` (BFT; corpus 1011/1314/1324) | Multiple hunting nodes propose findings; BFT orders them into the shared chain — no double-submit, no Byzantine forgery. |
| **Anonymity** | `aether/cap_handshake` + `capability` | Peers negotiate sessions by capability/pattern-set digest, not identity — the hunt federates without doxxing a node. |
| **Signature** | `aether/testament` + `numera/slhdsa` (FIPS-205) | The disclosure is SLH-DSA-signed to a pseudonymous key — anonymous yet accountable; the reputation chain that turns findings into standing. |
| **Transport** | `aether/backend_remote` (+ `http`) | The witnessed finding actually crosses the wire to a peer/endpoint. |
| **Sybil / eclipse** | `fed_sybil` (PoW admission), `fed_eclipse` | Planetary-scale resistance (III-PLANETARY, Wave 9): the open bounty fabric can't be flooded or partitioned. |

## Why this matters to the money thread

The THERA/AUXESIS wall-test — *does III earn anonymous money solo?* — gains its coordination substrate here. A solo
hunter is one `HOST` node. The federation lets many III nodes hunt in communion: each carries every primitive,
findings are witnessed and consensus-ordered, only proofs cross, disclosure is signed-yet-anonymous. The engine
(ELENCHOS/APORIA/`zk-hunt/scan.js`) is the producer; KOINONIA is the fabric that carries what it proves. Neither
the money nor the federation is on the *critical path to the first bounty* (that is: run the hunt on a real
less-audited in-scope circuit) — but this is the honest, maximally-ambitious substrate the operation runs *over*
once there is more than one node, and it is built on primitives III already sealed, not invented from nothing.
