import random, sys
sys.setrecursionlimit(100000)
random.seed(123)

def attractor(V, owner, succ, target, player):
    A=set(target); ch=True
    while ch:
        ch=False
        for v in V:
            if v in A: continue
            ss=[u for u in succ[v] if u in V]
            if owner[v]==player:
                if any(u in A for u in ss): A.add(v); ch=True
            else:
                if ss and all(u in A for u in ss): A.add(v); ch=True
    return frozenset(A)

def zielonka(V, owner, prio, succ):
    if not V: return (frozenset(), frozenset())
    m=max(prio[v] for v in V); p=0 if m%2==0 else 1
    U=frozenset(v for v in V if prio[v]==m)
    A=attractor(V,owner,succ,U,p)
    W0a,W1a=zielonka(V-A,owner,prio,succ)
    Wop=(W0a,W1a)[1-p]
    if not Wop:
        return (frozenset(V),frozenset()) if p==0 else (frozenset(),frozenset(V))
    B=attractor(V,owner,succ,Wop,1-p)
    W0b,W1b=zielonka(V-B,owner,prio,succ)
    return (W0b,W1b|B) if p==0 else (W0b|B,W1b)

def rand_game(n,d,maxout=3):
    owner=[random.randint(0,1) for _ in range(n)]
    prio=[random.randint(0,d-1) for _ in range(n)]
    succ=[]
    for v in range(n):
        k=random.randint(1,maxout); s=random.sample(range(n),min(k,n))
        succ.append(s if s else [random.randrange(n)])
    return owner,prio,succ

def oracle(n,owner,prio,succ):
    W0,W1=zielonka(frozenset(range(n)),owner,prio,succ)
    return [0 if v in W0 else 1 for v in range(n)]

def hard_solve(n,owner,prio,succ,maxit=10000):
    d=max(prio)+1
    X=[[0.0]*n for _ in range(d)]
    def body():
        y=[0.0]*n
        for v in range(n):
            vals=[X[prio[v]][u] for u in succ[v]]
            y[v]=max(vals) if owner[v]==0 else min(vals)
        return y
    def ev(k):
        if k==-1: return body()
        init=1.0 if k%2==0 else 0.0
        X[k]=[init]*n
        for _ in range(maxit):
            prev=X[k]; cur=ev(k-1); X[k]=cur
            if cur==prev: return cur
        return X[k]
    return ev(d-1)

for d in [2,3,4]:
    mism=0; total=0
    for _ in range(400):
        n=random.choice([6,8,10,12])
        owner,prio,succ=rand_game(n,d)
        orc=oracle(n,owner,prio,succ)
        hv=hard_solve(n,owner,prio,succ)
        for v in range(n):
            total+=1
            pred=0 if hv[v]>0.5 else 1
            if pred!=orc[v]: mism+=1
    print(f"HARD d={d}: mism={mism}/{total}", flush=True)
