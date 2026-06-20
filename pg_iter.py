import sys
sys.setrecursionlimit(100000)
from pg_probe import random_game, oracle_winners
from pg_sandwich import sccs, has_self

def oneplayer_win_with_sinks(N, succ, prio, want, sinks):
    # sole player controls all of N, wants parity 'want'; also wins immediately at any node
    # that can reach a 'sink' (a node already decided winning for this player), and edges to
    # the OTHER player's decided nodes are treated as unavailable... but player controls all,
    # so reaching own-sink = win. We just add sinks to 'good'.
    N=set(N)
    def find_good(M):
        M=set(M); res=set()
        for comp in sccs(M, succ):
            if len(comp)==1:
                v=next(iter(comp))
                if not has_self(v,succ,M):
                    continue
            m=max(prio[v] for v in comp)
            if (m%2)==want:
                res|=comp
            else:
                sub={v for v in comp if prio[v]!=m}
                res|=find_good(sub)
        return res
    good=find_good(N) | (set(sinks)&N)
    from collections import deque
    win=set(good); Q=deque(win)
    pred={v:[] for v in N}
    for u in N:
        for w in succ[u]:
            if w in N: pred[w].append(u)
    while Q:
        w=Q.popleft()
        for u in pred[w]:
            if u not in win: win.add(u); Q.append(u)
    return win

def iterated_sandwich(owner, prio, succ):
    n=len(owner); allN=set(range(n))
    decE=set(); decO=set()
    while True:
        gap=allN-decE-decO
        if not gap: break
        # Even controls all of gap; can reach decE-sinks OR good even cycle in gap
        RE = oneplayer_win_with_sinks(gap, succ, prio, 0, decE)
        # Odd controls all of gap; can reach decO-sinks OR good odd cycle
        Rodd = oneplayer_win_with_sinks(gap, succ, prio, 1, decO)
        newE = RE                 # in gap, Even wins even when... no: RE = Even-controls-all wins
        # lower bound for Even within gap = gap \ (Odd-controls-all wins)
        newE_lb = gap - Rodd
        newO_lb = gap - RE
        progress=False
        if newE_lb - decE:
            decE |= newE_lb; progress=True
        if newO_lb - decO:
            decO |= newO_lb; progress=True
        if not progress:
            break  # residual core: gap undecided by the relaxation bounds
    core = allN-decE-decO
    return decE, decO, core

def run(n,d,trials,seed0):
    tot=0; coresum=0; emptycore=0; wrong=0; unsound=0
    for t in range(trials):
        owner,prio,succ=random_game(n,d,seed0+t)
        decE,decO,core=iterated_sandwich(owner,prio,succ)
        orc=oracle_winners(owner,prio,succ)
        TrueE=set(i for i in range(n) if orc[i]==0)
        # soundness of the DECIDED part
        if not (decE<=TrueE and decO<=(set(range(n))-TrueE)): unsound+=1
        tot+=n; coresum+=len(core)
        if not core: emptycore+=1
    print(f"n={n} d={d}: residual-core nodes {coresum}/{tot} ({100*coresum/tot:.1f}%), "
          f"fully-decided games {emptycore}/{trials}, soundness-violations {unsound}")

if __name__=="__main__":
    for (n,d) in [(6,3),(8,4),(10,5),(12,6),(16,8),(20,10)]:
        run(n,d,300,1000)
