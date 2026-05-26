"""The witness commons -- a single, unified, hash-chained, append-only ledger.

UNIFIED: there is now ONE witness type (this `Witness`), used by both the module
bus and the forgetting layer. The earlier separate `forgetting.DepWitness` is
gone (drift removed). A witness records the value it produced, the input
witnesses it consumed (for dependence/blast-radius), and a predecessor link, so
any tamper anywhere breaks the chain from that point on.

`algebraic_time` mirrors III's `numera/algebraic_time.iii`: a strictly monotonic
counter advanced by exactly one per published witness.
"""
from dataclasses import dataclass

from .mhash import mhash, ZERO_HASH


@dataclass(frozen=True)
class Witness:
    seq: int
    algebraic_time: int
    producer: str
    op: str
    inputs: tuple        # seqs of input witnesses consumed (empty for a source)
    value: object        # the produced value (Known | PGap | SovVal | any canon-able)
    predecessor: str     # mhash of the prior witness body

    def body(self):
        return {"seq": self.seq, "algebraic_time": self.algebraic_time,
                "producer": self.producer, "op": self.op,
                "inputs": list(self.inputs), "value": self.value,
                "predecessor": self.predecessor}

    def self_hash(self):
        return mhash(self.body())

    def out_mhash(self):
        return mhash(self.value)


def chain_verify(chain):
    """Integrity + strict seq + monotonic clock. False on any break."""
    prev = ZERO_HASH
    last_time = 0
    for i, w in enumerate(chain):
        if w.seq != i:
            return False
        if w.predecessor != prev:
            return False
        if w.algebraic_time <= last_time:
            return False
        last_time = w.algebraic_time
        prev = w.self_hash()
    return True


class Commons:
    def __init__(self):
        self.chain = []
        self.head = ZERO_HASH
        self.clock = 0

    def append(self, producer, op, value, inputs=()):
        self.clock += 1
        w = Witness(seq=len(self.chain), algebraic_time=self.clock,
                    producer=producer, op=op, inputs=tuple(inputs),
                    value=value, predecessor=self.head)
        self.head = w.self_hash()
        self.chain.append(w)
        return w

    def verify(self):
        return chain_verify(self.chain)

    def find(self, value_mhash):
        """The commons: anyone may look up a witness by its output digest."""
        for w in self.chain:
            if w.out_mhash() == value_mhash:
                return w
        return None
