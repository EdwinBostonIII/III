import sys
sys.setrecursionlimit(100000)
from pg_probe import random_game, oracle_winners

def sccs(N, succ):
    N=set(N); idx={}; low={}; onst={}; st=[]; out=[]; c=[0]
    import sys as _s
    def strong(v):
        stack=[(v,0)]
        while stack:
            node,pi=stack[-1]
            if pi==0:
                idx[node]=low[node]=c[0]; c[0]+=1; st.append(node); onst[node]=True
            recurse=False
            nbrs=[w for w in succ[node] if w in N]
            if pi<len(nbrs):
                stack[-1]=(node,pi+1)
                w=nbrs[pi]
                if w not in idx:
                    stack.append((w,0)); recurse=True
                elif onst.get(w):
                    low[node]=min(low[node],idx[w])
            if not recurse:
                if pi>=len(nbrs):
                    if low[node]==idx[node]:
                        comp=set()
                        while True:
                            w=st.pop(); onst[w]=False; comp.add(w)
                            if w==node: break
                        out.append(comp)
                    stack.pop()
                    if stack:
                        par=stack[-1][0]; low[par]=min(low[par],low[node])
    for v in N:
        if v not in idx: strong(v)
    return out

def has_self(v, succ, N):
    return v in succ[v] and v in N

def oneplayer_win(N, succ, prio, want):
    # sole player controls ALL nodes in N, wants max-inf-often parity == want (0 even,1 odd).
    # returns set of nodes from which player can guarantee it (within induced subgraph N).
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
    good=find_good(N)
    # nodes in N that can reach good (player controls all -> walk there)
    # reverse BFS
    from collections import deque
    win=set(good); Q=deque(good)
    pred={v:[] for v in N}
    for u in N:
        for w in succ[u]:
            if w in N: pred[w].append(u)
    while Q:
        w=Q.popleft()
        for u in pred[w]:
            if u not in win:
                win.add(u); Q.append(u)
    return win

def sandwich(owner, prio, succ):
    n=len(owner); N=list(range(n))
    R_E = oneplayer_win(N, succ, prio, 0)        # Even controls all & wins -> upper bound on TrueEven
    odd_all = oneplayer_win(N, succ, prio, 1)    # Odd controls all & wins
    R_A = set(N) - odd_all                       # Even wins even when Odd controls all -> lower bound
    # sound: R_A subset TrueEven subset R_E
    gap = R_E - R_A
    return R_E, R_A, gap

def run(n,d,trials,seed0):
    tot=0; gapsum=0; empty=0; unsound=0
    for t in range(trials):
        owner,prio,succ=random_game(n,d,seed0+t)
        R_E,R_A,gap=sandwich(owner,prio,succ)
        orc=oracle_winners(owner,prio,succ)
        TrueEven=set(i for i in range(n) if orc[i]==0)
        # soundness check
        if not (R_A<=TrueEven and TrueEven<=R_E): unsound+=1
        tot+=n; gapsum+=len(gap)
        if len(gap)==0: empty+=1
    print(f"n={n} d={d}: gap nodes {gapsum}/{tot} ({100*gapsum/tot:.1f}%), fully-decided games {empty}/{trials}, soundness-violations {unsound}")

if __name__=="__main__":
    for (n,d) in [(6,3),(8,4),(10,5),(12,6),(16,8)]:
        run(n,d,300,1000)
