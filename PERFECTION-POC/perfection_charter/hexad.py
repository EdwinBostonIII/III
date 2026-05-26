"""Six-pillar Hexad + the Representability rule (REP, supporting Pi13/Pi14).

A Hexad is six trits (pillars P1..P6) packed into a u16, 2 bits each. III's
structural safety rule: any NEG in pillars P1..P4 makes the hexad
UNREPRESENTABLE -- the catastrophic / "bricking" operations literally cannot be
typed. P5/P6 are informational (NEG allowed). This is total, decidable, and
demonstrates "defined, sound behavior on catastrophic inputs": such inputs are
rejected by construction rather than crashing the system.
"""
from .trit import Trit, pack_trit, unpack_trit, t_and, t_or

Hexad = tuple  # (Trit, Trit, Trit, Trit, Trit, Trit)


def pack_hexad(h) -> int:
    if len(h) != 6:
        raise ValueError("hexad needs 6 pillars")
    v = 0
    for i, t in enumerate(h):
        v |= pack_trit(t) << (2 * i)
    return v


def unpack_hexad(v: int):
    return tuple(unpack_trit((v >> (2 * i)) & 0b11) for i in range(6))


def is_representable(h) -> bool:
    """Structural rule: NEG in any of P1..P4 -> unrepresentable."""
    for i in range(4):
        if h[i] == Trit.NEG:
            return False
    return True


def compose6(h1, h2):
    """III hexad composition (EFFECTS S4.7): AND on the structural pillars
    P1..P4 (damage compounds -> any NEG makes the result unrepresentable), OR on
    the recovery pillars P5..P6 (recovery propagates)."""
    return tuple([t_and(h1[i], h2[i]) for i in range(4)]
                 + [t_or(h1[i], h2[i]) for i in range(4, 6)])


# Catalogue of the six PFS bricking-class operations (from III-EFFECTS).
# Each has a NEG in a structural pillar, so each is untypable.
N, Z, P = Trit.NEG, Trit.ZERO, Trit.POS
BRICKING_OPS = {
    "capsule_update":   (N, N, N, N, Z, Z),
    "microcode_load":   (N, N, N, Z, Z, Z),
    "bootorder_set":    (N, N, Z, N, Z, Z),
    "real_nvram_write": (N, Z, N, N, Z, Z),
    "me_psp_mailbox":   (Z, N, N, N, Z, Z),
    "smram_write":      (N, N, N, N, N, Z),
}

# A safe, fully-representable hexad (all structural pillars non-NEG).
SAFE_HEXAD = (P, P, Z, P, Z, P)
