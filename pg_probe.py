import random, itertools

# Parity game: max-parity. Even (player 0) wins if max priority seen infinitely often is even.
# game: n nodes. owner[i] in {0,1}. prio[i] in 0..d. succ[i] = list of successors (>=1).

def random_game(n, d, seed):
    r = random.Random(seed)
    owner = [r.randint(0,1) for _ in range(n)]
    prio  = [r.randint(0,d) for _ in range(n)]
    succ  = []
    for i in range(n):
        k = r.randint(1, max(1, min(n, 3)))
        s = set(r.randrange(n) for _ in range(k))
        s.add(r.randrange(n))
        succ.append(sorted(s))
    return owner, prio, succ

# ---- Zielonka oracle (ground truth) ----
def attractor(nodes, succ, owner, target, player):
    # set of nodes from which 'player' can force reaching target within subgraph 'nodes'
    nodeset = set(nodes)
    A = set(target)
    # precompute predecessors within nodeset
    preds = {v: [] for v in nodes}
    outcount = {v: 0 for v in nodes}
    for u in nodes:
        for w in succ[u]:
            if w in nodeset:
                preds[w].append(u)
                outcount[u]+=1
    from collections import deque
    cnt = {v: outcount[v] for v in nodes}
    Q = deque(A & nodeset)
    A = set(A & nodeset)
    while Q:
        w = Q.popleft()
        for u in preds[w]:
            if u in A: continue
            if owner[u]==player:
                A.add(u); Q.append(u)
            else:
                cnt[u]-=1
                if cnt[u]==0:
                    A.add(u); Q.append(u)
    return A

def zielonka(nodes, succ, owner, prio):
    nodes = list(nodes)
    if not nodes:
        return set(), set()  # (W0, W1)
    nodeset=set(nodes)
    d = max(prio[v] for v in nodes)
    par = d & 1            # player who owns parity d (0 if even)
    opp = 1-par
    U = [v for v in nodes if prio[v]==d]
    A = attractor(nodes, succ, owner, U, par)
    rest = [v for v in nodes if v not in A]
    W0a, W1a = zielonka(rest, succ, owner, prio)
    Wopp = W1a if opp==1 else W0a
    if not Wopp:
        # par wins everything
        Wp = set(nodes)
        if par==0: return Wp, set()
        else: return set(), Wp
    B = attractor(nodes, succ, owner, Wopp, opp)
    rest2 = [v for v in nodes if v not in B]
    W0b, W1b = zielonka(rest2, succ, owner, prio)
    # opp wins (its region in subgame) plus the attractor B; par keeps its region.
    if opp==0:
        Wopp_final = W0b | B
        Wpar_final = W1b
        return Wopp_final, Wpar_final
    else:
        Wopp_final = W1b | B
        Wpar_final = W0b
        return Wpar_final, Wopp_final

def oracle_winners(owner, prio, succ):
    n=len(owner)
    W0,W1 = zielonka(list(range(n)), succ, owner, prio)
    return [0 if v in W0 else 1 for v in range(n)]

# ---- Candidate 3: single-fixpoint 'highest forceable priority' labeling ----
# dominant[u] = highest priority that owner can force to appear; winner=parity.
# fixpoint: Even node wants to maximize numeric reachable max-priority that is even-good...
# concrete rule: val[u]=max over its preference of combine(prio[u], val[succ]); combine=numeric max.
def candidate3(owner, prio, succ):
    n=len(owner)
    val=[prio[i] for i in range(n)]
    for _ in range(n+1):
        new=val[:]
        for u in range(n):
            cand=[max(prio[u], val[w]) for w in succ[u]]
            # owner 0 (Even) prefers larger even; owner 1 prefers larger odd.
            def keyfun(x, who):
                # higher numeric priority dominates a cycle; owner wants that dominating
                # priority's parity to be his. Preference: pick max x whose parity == who-good,
                # else minimize. Encode as a sortable key.
                good = (x % 2) == (0 if who==0 else 1)
                return (1 if good else 0, x if good else -x)
            best=max(cand, key=lambda x: keyfun(x, owner[u]))
            new[u]=best
        if new==val: break
        val=new
    return [val[i]%2 for i in range(n)]  # 0=Even wins guess

# ---- Candidate 2: non-Archimedean harmonic / resolvent (numeric epsilon) ----
def candidate2(owner, prio, succ, eps=1e-3, teleport=1e-6):
    n=len(owner)
    # uniform random walk transition; reward r(v)=(-1)^p * eps^{-p}
    # solve x = r + (1-teleport) P x  (discounted), winner = sign(x[u]) (>0 -> Even)
    import math
    r=[((-1.0)**prio[v]) * (eps**(-prio[v])) for v in range(n)]
    # normalize magnitudes to avoid overflow: factor eps^{d}
    d=max(prio)
    r=[((-1.0)**prio[v]) * (eps**(d-prio[v])) for v in range(n)]
    P=[[0.0]*n for _ in range(n)]
    for u in range(n):
        m=len(succ[u])
        for w in succ[u]:
            P[u][w]+=1.0/m
    # solve (I-(1-tp)P) x = r via Gaussian elimination
    g=(1-teleport)
    A=[[ (1.0 if i==j else 0.0) - g*P[i][j] for j in range(n)] for i in range(n)]
    b=r[:]
    # gaussian elim
    for col in range(n):
        piv=max(range(col,n), key=lambda i: abs(A[i][col]))
        if abs(A[piv][col])<1e-15: continue
        A[col],A[piv]=A[piv],A[col]; b[col],b[piv]=b[piv],b[col]
        pv=A[col][col]
        for i in range(n):
            if i==col: continue
            f=A[i][col]/pv
            if f==0: continue
            for j in range(col,n):
                A[i][j]-=f*A[col][j]
            b[i]-=f*b[col]
    x=[ b[i]/A[i][i] if abs(A[i][i])>1e-15 else 0.0 for i in range(n)]
    return [0 if x[i]>0 else 1 for i in range(n)]

def run(n, d, trials, seed0):
    dis3=0; dis2=0; tot=0; gamesdis3=0; gamesdis2=0
    for t in range(trials):
        owner,prio,succ=random_game(n,d,seed0+t)
        orc=oracle_winners(owner,prio,succ)
        c3=candidate3(owner,prio,succ)
        c2=candidate2(owner,prio,succ)
        m3=sum(1 for i in range(n) if c3[i]!=orc[i])
        m2=sum(1 for i in range(n) if c2[i]!=orc[i])
        dis3+=m3; dis2+=m2; tot+=n
        if m3>0: gamesdis3+=1
        if m2>0: gamesdis2+=1
    print(f"n={n} d={d} trials={trials}: cand3 node-disagree {dis3}/{tot} ({100*dis3/tot:.1f}%), games-wrong {gamesdis3}/{trials}; "
          f"cand2 node-disagree {dis2}/{tot} ({100*dis2/tot:.1f}%), games-wrong {gamesdis2}/{trials}")

if __name__=="__main__":
    for (n,d) in [(6,3),(8,4),(10,5),(12,6)]:
        run(n,d,300,1000)
