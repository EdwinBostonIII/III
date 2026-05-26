"""Provable forgetting: reversible redaction with continuity + blast-radius.

UNIFIED: this layer now uses the single `witnesscommons.Witness` type (no more
`DepWitness`). Each witness derives its value from its input witnesses via one
op, so dependence is explicit and the blast radius is computable.

Replacing a witnessed value with a typed `redacted` gap and re-sealing proves
three things at once:
  1. integrity   -- the re-sealed chain still verifies;
  2. continuity  -- witnesses that did NOT depend on it keep byte-identical
                    values (only the hash links re-seal);
  3. blast-radius -- witnesses that DID depend now hold an honest gap whose
                     provenance points at the redaction -- never silently wrong.
"""
from .mhash import mhash, ZERO_HASH
from .negknow import Known, gap, is_known, is_gap, apply_op
from .witnesscommons import Witness, chain_verify


def _mkwit(seq, producer, op, inputs, value, predecessor):
    return Witness(seq=seq, algebraic_time=seq + 1, producer=producer, op=op,
                   inputs=tuple(inputs), value=value, predecessor=predecessor)


def build_chain(specs):
    """specs: list of (producer, op, inputs:list[int], literal:int|None)."""
    chain = []
    head = ZERO_HASH
    values = {}
    for i, (producer, op, inputs, literal) in enumerate(specs):
        if not inputs:
            value = Known(literal)
        else:
            value = values[inputs[0]]
            for s in inputs[1:]:
                value = apply_op(op, value, values[s])
        w = _mkwit(i, producer, op, inputs, value, head)
        head = w.self_hash()
        values[i] = value
        chain.append(w)
    return chain


def verify(chain):
    return chain_verify(chain)


def dependents(chain, k):
    """Transitive closure of witnesses consuming k (includes k)."""
    dep = {k}
    for w in chain:
        if any(s in dep for s in w.inputs):
            dep.add(w.seq)
    return dep


def _reseal(chain, override_seq, override_value):
    new = []
    head = ZERO_HASH
    values = {}
    for w in chain:
        if w.seq == override_seq:
            value = override_value
        elif not w.inputs:
            value = w.value
        else:
            value = values[w.inputs[0]]
            for s in w.inputs[1:]:
                value = apply_op(w.op, value, values[s])
        nw = _mkwit(w.seq, w.producer, w.op, w.inputs, value, head)
        head = nw.self_hash()
        values[w.seq] = value
        new.append(nw)
    return new


def redact(chain, k, reason):
    return _reseal(chain, k, gap("redacted", reason))


def proves_forgetting(chain, k, reason):
    new = redact(chain, k, reason)
    dep = dependents(chain, k)
    integrity = verify(new)
    continuity = all(mhash(new[w.seq].value) == mhash(chain[w.seq].value)
                     for w in chain if w.seq not in dep)
    gone = is_gap(new[k].value) and new[k].value.kind == "redacted"
    blast = all(is_gap(new[j].value) for j in dep if j != k)
    return {"integrity": integrity, "continuity": continuity,
            "gone": gone, "blast": blast, "chain": new}
