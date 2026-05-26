"""The Sovereign Value -- the deepening integration.

A SovVal binds, in one type, the three charter properties that were previously
bolted onto separate modules:

    SovVal = { payload : Known | PGap      # gap-aware + provenance (Pi11/Pi13/Pi15)
               hexad   : 6-trit safety tag } # damage/recovery algebra (REP)

Every operation `sv_op`:
  * composes the payload via the unified, sound, precise arithmetic (negknow);
  * composes the hexad per III's rule -- AND on the structural pillars P1..P4
    (damage compounds), OR on the recovery pillars P5..P6;
  * REFUSES the operation if the composed hexad is unrepresentable (a bricking
    composition) -- returning a typed Refused, never an illegal value;
  * emits a witness to the shared commons when one is supplied.

So gap-totality, provenance, safety-typing, and witnessing become intrinsic to
the value, not per-module add-ons. That is what "deepen" means here.
"""
from dataclasses import dataclass

from .negknow import Known, is_gap, apply_op
from .hexad import is_representable, compose6
from .mhash import mhash


@dataclass(frozen=True)
class SovVal:
    payload: object      # Known | PGap
    hexad: tuple         # 6 trits


@dataclass(frozen=True)
class Refused:
    hexad: tuple         # the unrepresentable composition that was refused
    reason: str


def sv_lift(value_int, hexad):
    return SovVal(Known(value_int), hexad)


def sv_gap(g, hexad):
    return SovVal(g, hexad)


def addr(sv):
    """Content address of a sovereign value (payload + safety together)."""
    return mhash({"payload": sv.payload, "hexad": list(sv.hexad)})


def sv_op(op, a, b, commons=None, producer="sv"):
    """Total: returns a SovVal, or a typed Refused if the safety composition is
    unrepresentable. Emits a witness when a commons is supplied.
    """
    h = compose6(a.hexad, b.hexad)
    if not is_representable(h):
        return Refused(h, "composition reaches a structurally unrepresentable hexad")
    r = SovVal(apply_op(op, a.payload, b.payload), h)
    if commons is not None:
        commons.append(producer, op, r, inputs=(addr(a), addr(b)))
    return r


def is_refused(x):
    return isinstance(x, Refused)
