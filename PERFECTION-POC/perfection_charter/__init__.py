"""perfection_charter — a runnable proof-of-concept of the III Perfection Charter.

A small, stdlib-only, deterministic substrate that embodies the charter's
*checkable* predicates and self-audits them. Every predicate carries both a
positive check (verify) and a falsifier (a deliberately-bad case that MUST be
caught) so the audit proves the negative, not just the happy path.

NIH note: `hashlib.sha256` stands in for III's hand-rolled `numera/sha256.iii`.
Everything else is hand-rolled here over the Python standard library only.
"""

__version__ = "0.1.0"
