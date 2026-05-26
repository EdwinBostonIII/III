"""Reversibility / SID (Pi9) + gated admission (Pi10).

State is a fixed-length tuple of ints. An Op bundles a forward map with its
inverse. A Cycle is a sequence of Ops; inverse-replay walks the ops in reverse,
applying each inverse, and must return the exact original state.

Pi10: an Op may enter the registry ONLY if (forward then inverse) is the
identity over a test domain -- unless it is explicitly tagged `compromise`
(typed irreversibility). An untagged lossy op is refused admission.
"""
from dataclasses import dataclass
from typing import Callable

from .mhash import mhash


@dataclass(frozen=True)
class Op:
    name: str
    forward: Callable
    inverse: Callable
    compromise: bool = False


# --- a small library of genuinely reversible ops ----------------------------
def _set(state, i, val):
    s = list(state)
    s[i] = val
    return tuple(s)


def add_const(i, k):
    return Op("add_const(%d,%d)" % (i, k),
              lambda s: _set(s, i, s[i] + k),
              lambda s: _set(s, i, s[i] - k))


def xor_const(i, k):
    return Op("xor_const(%d,%d)" % (i, k),
              lambda s: _set(s, i, s[i] ^ k),
              lambda s: _set(s, i, s[i] ^ k))


def swap(i, j):
    def f(s):
        s = list(s)
        s[i], s[j] = s[j], s[i]
        return tuple(s)
    return Op("swap(%d,%d)" % (i, j), f, f)


def negate(i):
    return Op("negate(%d)" % i,
              lambda s: _set(s, i, -s[i]),
              lambda s: _set(s, i, -s[i]))


# --- a deliberately LOSSY op (for the Pi9/Pi10 falsifier) -------------------
def zero_slot(i, compromise=False):
    """Irreversible: destroys slot i. Its 'inverse' cannot recover the value."""
    return Op("zero_slot(%d)" % i,
              lambda s: _set(s, i, 0),
              lambda s: s,            # cannot undo information loss
              compromise=compromise)


def round_trips(op: Op, samples) -> bool:
    """True iff inverse(forward(s)) == s for every sample state."""
    for s in samples:
        if op.inverse(op.forward(s)) != s:
            return False
    return True


def admit(op: Op, samples) -> bool:
    """Pi10 gate: admit iff reversible over the domain, or explicitly compromised."""
    if op.compromise:
        return True
    return round_trips(op, samples)


def forward_cycle(state, ops):
    for op in ops:
        state = op.forward(state)
    return state


def inverse_replay(state, ops):
    for op in reversed(ops):
        state = op.inverse(state)
    return state


def cycle_round_trips(state, ops) -> bool:
    """Forward the whole cycle, then inverse-replay; must return to origin."""
    end = forward_cycle(state, ops)
    back = inverse_replay(end, ops)
    return mhash(back) == mhash(state)
