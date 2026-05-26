"""Quine-seal: a reflective, self-verifying fixpoint.

The seal commits not only to the audit result but to a hash of the auditor's
OWN source. So the artifact can prove: "the run that produced this seal is the
auditor that this seal describes." The seal is a fixed point of
(audit then describe-self).

Goedel-safety: this verifies an INSTANCE -- this run against these exact
sources -- never a global claim of its own consistency. That instance check is
decidable and total; the forbidden self-consistency proof is never attempted.
"""
import hashlib
import importlib
import os
import types

from .mhash import mhash

# every module in the package -- the full substrate, for deep behavioral sealing
_PACKAGE_MODULES = [
    "mhash", "trit", "hexad", "gapval", "reversible", "rewrite",
    "witnesscommons", "modules", "charter", "negknow", "holes",
    "forgetting", "quineseal", "sovval", "kernel", "sha256_nih", "charter_ext",
]


def source_manifest(package_dir):
    """filename -> sha256(file bytes) for every .py in the package directory."""
    manifest = {}
    for fn in sorted(os.listdir(package_dir)):
        if fn.endswith(".py"):
            with open(os.path.join(package_dir, fn), "rb") as f:
                manifest[fn] = hashlib.sha256(f.read()).hexdigest()
    return manifest


def package_dir():
    return os.path.dirname(os.path.abspath(__file__))


def behavior_manifest(funcs):
    """name -> sha256 of the function's *bytecode*.

    This seals what actually EXECUTES, not just the source on disk. In-memory
    monkeypatching (which leaves the .py files untouched) changes a function's
    co_code and therefore breaks the fixpoint -- closing the source-vs-behavior
    gap. Caveat: bytecode is stable within a run / interpreter version, which is
    all the instance check requires.
    """
    out = {}
    for name, fn in funcs.items():
        out[name] = hashlib.sha256(fn.__code__.co_code).hexdigest()
    return out


def full_behavior_manifest():
    """sha256 of EVERY top-level function's bytecode across ALL package modules.

    This closes the deep-helper gap: monkeypatching any function anywhere in the
    substrate (not just a predicate) changes this manifest, so the quine-seal
    commits to the executed behavior of the whole system.
    """
    out = {}
    for modname in _PACKAGE_MODULES:
        mod = importlib.import_module("." + modname, __package__)
        full = mod.__name__
        for name in sorted(dir(mod)):
            obj = getattr(mod, name)
            if isinstance(obj, types.FunctionType) and obj.__module__ == full:
                out[modname + "." + name] = hashlib.sha256(obj.__code__.co_code).hexdigest()
    return out


def quine_seal(audit_payload, manifest=None, behavior=None):
    if manifest is None:
        manifest = source_manifest(package_dir())
    blob = {"audit": audit_payload, "sources": manifest}
    if behavior is not None:
        blob["behavior"] = behavior
    return mhash(blob)


def verify_fixpoint(seal, audit_payload, manifest=None, behavior=None):
    """True iff `seal` is exactly the seal of this payload under these sources
    (and, when supplied, this executed behavior).
    """
    return quine_seal(audit_payload, manifest, behavior) == seal
