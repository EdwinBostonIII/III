import random, math, sys
sys.setrecursionlimit(100000)
random.seed(7)

def attractor(V, owner, succ, target, player):
    A = set(target)
    changed = True
    while changed:
        changed = False
        for v in V:
            if v in A: continue
            ss = [u for u in succ[v] if u in V]
            if owner[v]==player:
                if any(u in A for u in ss): A.add(v); changed=True
            else:
                if ss and all(u in A for u in ss): A.add(v); changed=True
    return frozenset(A)

def zielonka(V, owner, prio, succ):
    if not V: return (frozenset(), frozenset())
    m = max(prio[v] for v in V)
    p = 0 if m%2==0 else 1
    U = frozenset(v for v in V if prio[v]==m)
    A = attractor(V, owner, succ, U, p)
    W0a, W1a = zielonka(V - A, owner, prio, succ)
    Wop = (W0a, W1a)[1-p]
    if not Wop:
        return (frozenset(V), frozenset()) if p==0 else (frozenset(), frozenset(V))
    B = attractor(V, owner, succ, Wop, 1-p)
    W0b, W1b = zielonka(V - B, owner, prio, succ)
    return (W0b, W1b | B) if p==0 else (W0b | B, W1b)

def softmax_b(vals, beta):
    mx=max(vals)
    s=sum(math.exp(beta*(z-mx)) for z in vals)/len(vals)
    return mx + math.log(s)/beta
def softmin_b(vals, beta):
    return -softmax_b([-z for z in vals], beta)

def soft_solve(n, owner, prio, succ, beta, tol=1e-7, maxit=120):
    d = max(prio)+1
    X=[[0.0]*n for _ in range(d)]
    def body():
        y=[0.0]*n
        for v in range(n):
            vals=[X[prio[v]][u] for u in succ[v]]
            y[v]= softmax_b(vals,beta) if owner[v]==0 else softmin_b(vals,beta)
        return y
    def ev(k):
        if k==-1: return body()
        init = 1.0 if k%2==0 else 0.0
        X[k]=[init]*n
        for _ in range(maxit):
            prev=X[k]; cur=ev(k-1); X[k]=cur
            if max(abs(cur[i]-prev[i]) for i in range(n))<tol: return cur
        return X[k]
    return ev(d-1)

def rand_game(n, d, maxout=3):
    owner=[random.randint(0,1) for _ in range(n)]
    prio=[random.randint(0,d-1) for _ in range(n)]
    succ=[]
    for v in range(n):
        k=random.randint(1,maxout)
        s=random.sample(range(n), min(k,n))
        succ.append(s if s else [random.randrange(n)])
    return owner,prio,succ

def winners_oracle(n,owner,prio,succ):
    W0,W1=zielonka(frozenset(range(n)),owner,prio,succ)
    return [0 if v in W0 else 1 for v in range(n)]

def run(n, d, beta, trials):
    mism=0; total=0; gaps=[]
    for _ in range(trials):
        owner,prio,succ=rand_game(n,d)
        orc=winners_oracle(n,owner,prio,succ)
        sv=soft_solve(n,owner,prio,succ,beta)
        for v in range(n):
            total+=1
            pred = 0 if sv[v]>0.5 else 1
            gaps.append(abs(sv[v]-0.5))
            if pred!=orc[v]: mism+=1
    gaps.sort()
    return mism,total,(gaps[0] if gaps else 0)

for n in [8,12,16,20]:
    for beta in [8,20,60]:
        mism,total,mn=run(n,3,beta,25)
        print(f"n={n:3d} d=3 beta={beta:4d}  mism={mism}/{total}  min|gap|={mn:.2e}", flush=True)
print("---- d=4 ----", flush=True)
for n in [8,12]:
    for beta in [20,60]:
        mism,total,mn=run(n,4,beta,20)
        print(f"n={n:3d} d=4 beta={beta:4d}  mism={mism}/{total}  min|gap|={mn:.2e}", flush=True)
