"""Asymmetric ternary algebra (the Hexad trit) — Pi1 / Pi13 substrate.

Three values: NEG(-1), ZERO(0), POS(+1). ZERO is the *gap* / undetermined value.
All five operations are TOTAL (defined on every input) and derived from the
balanced-integer interpretation, then checked against III's HEXAD spec tables as
an independent oracle (so the laws are proven, not asserted by fiat).

  NOT(x) = -x
  AND    = min   (under NEG < ZERO < POS)      -- damage dominates
  OR     = max                                  -- recovery propagates
  SUM    = clamp(a+b) to [-1,1]                 -- saturating add
  MUL    = a*b                                  -- balanced product (NEG*NEG=POS)
"""
from enum import IntEnum


class Trit(IntEnum):
    NEG = -1
    ZERO = 0
    POS = 1


ALL = (Trit.NEG, Trit.ZERO, Trit.POS)


def _clamp(n: int) -> Trit:
    return Trit(max(-1, min(1, n)))


def t_not(a: Trit) -> Trit:
    return Trit(-int(a))


def t_and(a: Trit, b: Trit) -> Trit:
    return Trit(min(int(a), int(b)))


def t_or(a: Trit, b: Trit) -> Trit:
    return Trit(max(int(a), int(b)))


def t_sum(a: Trit, b: Trit) -> Trit:
    return _clamp(int(a) + int(b))


def t_mul(a: Trit, b: Trit) -> Trit:
    return Trit(int(a) * int(b))


# --- Independent oracle: III HEXAD spec tables (verbatim from III-HEXAD/STDLIB) ---
# Rows are x; columns are y in order (NEG, ZERO, POS).
_SPEC_AND = {Trit.NEG: (Trit.NEG, Trit.NEG, Trit.NEG),
             Trit.ZERO: (Trit.NEG, Trit.ZERO, Trit.ZERO),
             Trit.POS: (Trit.NEG, Trit.ZERO, Trit.POS)}
_SPEC_OR = {Trit.NEG: (Trit.NEG, Trit.ZERO, Trit.POS),
            Trit.ZERO: (Trit.ZERO, Trit.ZERO, Trit.POS),
            Trit.POS: (Trit.POS, Trit.POS, Trit.POS)}
_SPEC_SUM = {Trit.NEG: (Trit.NEG, Trit.NEG, Trit.ZERO),
             Trit.ZERO: (Trit.NEG, Trit.ZERO, Trit.POS),
             Trit.POS: (Trit.ZERO, Trit.POS, Trit.POS)}
_SPEC_MUL = {Trit.NEG: (Trit.POS, Trit.ZERO, Trit.NEG),
             Trit.ZERO: (Trit.ZERO, Trit.ZERO, Trit.ZERO),
             Trit.POS: (Trit.NEG, Trit.ZERO, Trit.POS)}
_SPEC_NOT = {Trit.NEG: Trit.POS, Trit.ZERO: Trit.ZERO, Trit.POS: Trit.NEG}


def matches_spec_tables() -> bool:
    """True iff the derived ops reproduce III's HEXAD tables on every input."""
    for i, x in enumerate(ALL):
        if t_not(x) != _SPEC_NOT[x]:
            return False
        for j, y in enumerate(ALL):
            if t_and(x, y) != _SPEC_AND[x][j]:
                return False
            if t_or(x, y) != _SPEC_OR[x][j]:
                return False
            if t_sum(x, y) != _SPEC_SUM[x][j]:
                return False
            if t_mul(x, y) != _SPEC_MUL[x][j]:
                return False
    return True


def algebra_laws_hold(_and=t_and, _or=t_or, _not=t_not) -> bool:
    """Soundness laws over the full 3x3 domain (Pi1, scoped to the algebra).

    Parameterised on the ops so a falsifier can inject a corrupted op and watch
    a law break.
    """
    for x in ALL:
        if _not(_not(x)) != x:               # involution
            return False
        for y in ALL:
            if _and(x, y) != _and(y, x):      # AND commutative
                return False
            if _or(x, y) != _or(y, x):        # OR commutative
                return False
            # De Morgan: NOT(AND(x,y)) == OR(NOT x, NOT y)
            if _not(_and(x, y)) != _or(_not(x), _not(y)):
                return False
    return True


# packed storage (2 bits per trit); 0b11 reserved
_PACK = {Trit.NEG: 0b00, Trit.ZERO: 0b01, Trit.POS: 0b10}
_UNPACK = {v: k for k, v in _PACK.items()}


def pack_trit(t: Trit) -> int:
    return _PACK[t]


def unpack_trit(bits: int) -> Trit:
    return _UNPACK[bits]
