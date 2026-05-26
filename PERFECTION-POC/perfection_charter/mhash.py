"""Content addressing (Pi7 substrate).

`canon` is a deterministic, type-tagged serializer: equal values always produce
equal bytes, and values of different shape can never collide on encoding. `mhash`
is the SHA-256 of that canonical encoding.

Determinism notes:
  * We hash canonical BYTES via hashlib, never Python's salted builtin hash(),
    so PYTHONHASHSEED is irrelevant.
  * dict keys are sorted; there is no float case (the no-float mandate).
In real III this is `numera/sha256.iii`; here hashlib is the stand-in.
"""
import dataclasses
import hashlib

ZERO_HASH = "0" * 64


def canon(obj) -> bytes:
    if obj is None:
        return b"N;"
    if obj is True:
        return b"T;"
    if obj is False:
        return b"F;"
    if isinstance(obj, int):
        return b"i" + str(obj).encode("ascii") + b";"
    if isinstance(obj, str):
        b = obj.encode("utf-8")
        return b"s" + str(len(b)).encode("ascii") + b":" + b + b";"
    if isinstance(obj, (bytes, bytearray)):
        b = bytes(obj)
        return b"b" + str(len(b)).encode("ascii") + b":" + b + b";"
    if isinstance(obj, (list, tuple)):
        out = b"l" + str(len(obj)).encode("ascii") + b":"
        for x in obj:
            out += canon(x)
        return out + b";"
    if isinstance(obj, dict):
        items = sorted(obj.items(), key=lambda kv: canon(kv[0]))
        out = b"d" + str(len(items)).encode("ascii") + b":"
        for k, v in items:
            out += canon(k) + canon(v)
        return out + b";"
    if dataclasses.is_dataclass(obj) and not isinstance(obj, type):
        # type-tagged so Known(0) and Gap("0") can never collide on encoding
        return (b"D" + canon(type(obj).__name__)
                + canon(dataclasses.asdict(obj)) + b";")
    raise TypeError("noncanonical type: %r" % (type(obj),))


def _hashlib_backend(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


# Pluggable hash backend (bytes -> hex string). Defaults to hashlib, but can be
# swapped for the hand-rolled SHA-256 -- they are byte-identical (proven by Pi20),
# so content addresses are invariant to the choice. This is what lets the NIH
# hash be load-bearing rather than merely an oracle.
_BACKEND = _hashlib_backend


def set_backend(fn):
    global _BACKEND
    _BACKEND = fn


def get_backend():
    return _BACKEND


def mhash(obj) -> str:
    return _BACKEND(canon(obj))
