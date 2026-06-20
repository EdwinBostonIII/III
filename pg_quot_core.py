import sys
sys.setrecursionlimit(100000)
from pg_probe import random_game, oracle_winners

# ---------- C: standard bisimulation quotient size ----------
def bisim_quotient_size(owner, prio, succ):
    n=len(owner)
    block=[0]*n
    # initial partition by (owner,prio)
    sig0={}
    for v in range(n):
        block[v]=sig0.setdefault((owner[v],prio[v]), len(sig0))
    while True:
        sig={}; newblock=[0]*n; changed=False
        for v in range(n):
            key=(owner[v],prio[v], frozenset(block[w] for w in succ[v]))
            newblock[v]=sig.setdefault(key, len(sig))
        if newblock!=block:
            block=newblock
        # check stable: recompute again equality
        sig2={}; nb2=[0]*n
        for v in range(n):
            key=(owner[v],prio[v], frozenset(block[w] for w in succ[v]))
            nb2[v]=sig2.setdefault(key,len(sig2))
        if nb2==block: break
        block=nb2
    return len(set(block))

# ---------- B: winner-preserving local reduction to a core ----------
def reduce_core(owner, prio, succ):
    n=len(owner)
    dec={}  # node -> winner, sound decisions
    # R3: self-loop sinks
    for v in range(n):
        if v in succ[v]:
            p=prio[v]; o=owner[v]
            if o==0 and p%2==0: dec[v]=0
            elif o==1 and p%2==1: dec[v]=1
            elif len(succ[v])==1:
                # only move is the loop, bad for owner -> other player wins
                dec[v]= (p%2)   # max-inf = p ; winner=parity
    changed=True
    while changed:
        changed=False
        # R2: one-step forced resolution toward decided nodes
        for v in range(n):
            if v in dec: continue
            outs=succ[v]
            if owner[v]==0:
                # Even wins if SOME successor decided Even
                if any(dec.get(w)==0 for w in outs):
                    dec[v]=0; changed=True; continue
                # Even loses if ALL successors decided Odd
                if outs and all(dec.get(w)==1 for w in outs):
                    dec[v]=1; changed=True; continue
            else:
                if any(dec.get(w)==1 for w in outs):
                    dec[v]=1; changed=True; continue
                if outs and all(dec.get(w)==0 for w in outs):
                    dec[v]=0; changed=True; continue
    core=[v for v in range(n) if v not in dec]
    return dec, core

def run(n,d,trials,seed0):
    tot=0; quotsum=0; coresum=0; emptycore=0; unsound=0
    for t in range(trials):
        owner,prio,succ=random_game(n,d,seed0+t)
        q=bisim_quotient_size(owner,prio,succ)
        dec,core=reduce_core(owner,prio,succ)
        orc=oracle_winners(owner,prio,succ)
        for v,w in dec.items():
            if w!=orc[v]: unsound+=1
        tot+=n; quotsum+=q; coresum+=len(core)
        if not core: emptycore+=1
    print(f"n={n} d={d}: bisim-quotient avg {quotsum/trials:.1f}/{n} nodes; "
          f"reduction-core {coresum}/{tot} ({100*coresum/tot:.1f}%), "
          f"fully-decided {emptycore}/{trials}, unsound-decisions {unsound}")

if __name__=="__main__":
    for (n,d) in [(6,3),(8,4),(10,5),(12,6),(16,8),(20,10),(30,12)]:
        run(n,d,300,1000)
