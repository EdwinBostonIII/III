import random, math

# ---- exact Zielonka oracle, ported from 1839_grail_parity_solver.iii (bitmask) ----
def max_prio(region, PRI, n):
    m=0
    for v in range(n):
        if region&(1<<v) and PRI[v]>m: m=PRI[v]
    return m

def attractor(region, player, target, OWN, SUC, n):
    a = target & region
    while True:
        added=False
        for v in range(n):
            bit=1<<v
            if (region&bit) and not (a&bit):
                if OWN[v]==player:
                    if SUC[v]&a&region: a|=bit; added=True
                else:
                    sir=SUC[v]&region
                    if sir and (sir & ~a)==0: a|=bit; added=True
        if not added: break
    return a

def zielonka(region, OWN, PRI, SUC, n):
    if region==0: return (0,0)  # (Weven, Wodd)
    d=max_prio(region,PRI,n); p=d&1
    u=0
    for v in range(n):
        if (region&(1<<v)) and PRI[v]==d: u|=(1<<v)
    a=attractor(region,p,u,OWN,SUC,n)
    w0a,w1a=zielonka(region & ~a & ((1<<n)-1), OWN,PRI,SUC,n)
    wopp = w1a if p==0 else w0a
    if wopp==0:
        return (region,0) if p==0 else (0,region)
    opp=1-p
    b=attractor(region,opp,wopp,OWN,SUC,n)
    w0b,w1b=zielonka(region & ~b & ((1<<n)-1), OWN,PRI,SUC,n)
    if p==0: return (w0b, (w1b|b))
    return ((w0b|b), w1b)

# validate on the 1839 hand game
OWN=[0,1]; PRI=[2,1]; SUC=[3,3]
assert zielonka(3,OWN,PRI,SUC,2)==(1,2), "oracle port failed"

def rand_game(n, dmax):
    OWN=[random.randint(0,1) for _ in range(n)]
    PRI=[random.randint(0,dmax) for _ in range(n)]
    SUC=[]
    for v in range(n):
        k=random.randint(1,n)
        outs=random.sample(range(n),k)
        m=0
        for t in outs: m|=(1<<t)
        SUC.append(m)
    return OWN,PRI,SUC

# ---- C4 null: control-free signed-zeta / balance invariant ----
# predict Even wins v iff sign of sum over reachable set R(v) of (-1)^{p(u)} weighted by 1 is >0
def reach(v, SUC, n):
    seen=1<<v; stack=[v]
    while stack:
        x=stack.pop()
        s=SUC[x]
        for t in range(n):
            if (s&(1<<t)) and not (seen&(1<<t)):
                seen|=(1<<t); stack.append(t)
    return seen

def c4_signed(OWN,PRI,SUC,n):
    pred=[0]*n
    for v in range(n):
        R=reach(v,SUC,n); s=0
        for u in range(n):
            if R&(1<<u): s += (1 if PRI[u]%2==0 else -1)*((u+1))  # weight; sign by parity
        pred[v]=0 if s>=0 else 1
    return pred

# ---- C1: finite-beta soft-Bellman (node), control-encoding ----
def softmax_b(vals, beta):
    m=max(vals); return m + math.log(sum(math.exp(beta*(x-m)) for x in vals))/beta
def softmin_b(vals, beta):
    m=min(vals); return m - math.log(sum(math.exp(-beta*(x-m)) for x in vals))/beta

def c1_softbellman(OWN,PRI,SUC,n, beta, lam, weightmode, iters=400):
    if weightmode=='bounded':
        w=[(1.0 if PRI[v]%2==0 else -1.0) for v in range(n)]
    else: # exp (n+1)^p
        w=[((1.0 if PRI[v]%2==0 else -1.0)*((n+1)**PRI[v])) for v in range(n)]
    phi=[0.0]*n
    for _ in range(iters):
        new=[0.0]*n
        for v in range(n):
            succ=[u for u in range(n) if SUC[v]&(1<<u)]
            vals=[phi[u] for u in succ]
            agg = softmax_b(vals,beta) if OWN[v]==0 else softmin_b(vals,beta)
            new[v]=w[v]+lam*agg
        d=max(abs(new[i]-phi[i]) for i in range(n)); phi=new
        if d<1e-12: break
    return [0 if phi[v]>0 else 1 for v in range(n)]

def winners_list(W0,W1,n):
    return [0 if (W0&(1<<v)) else 1 for v in range(n)]

random.seed(7)
configs=[('C4_signed_nullcontrolfree',None),
         ('C1_bounded_b1.0',('bounded',1.0,0.95)),
         ('C1_bounded_b4.0',('bounded',4.0,0.95)),
         ('C1_exp_b8.0',('exp',8.0,0.99)),
         ('C1_exp_b50',('exp',50.0,0.999))]
N_GAMES=600
for nval in [6,8,10]:
    print(f"--- n={nval}, {N_GAMES} random games, dmax={nval} ---")
    tot=0
    agree={c[0]:0 for c in configs}
    for _ in range(N_GAMES):
        OWN,PRI,SUC=rand_game(nval,nval)
        W0,W1=zielonka((1<<nval)-1,OWN,PRI,SUC,nval)
        truth=winners_list(W0,W1,nval); tot+=nval
        for name,cfg in configs:
            if cfg is None:
                pred=c4_signed(OWN,PRI,SUC,nval)
            else:
                wm,beta,lam=cfg
                pred=c1_softbellman(OWN,PRI,SUC,nval,beta,lam,wm)
            agree[name]+=sum(1 for i in range(nval) if pred[i]==truth[i])
    for name,_ in configs:
        print(f"  {name:28s} per-vertex agreement = {100*agree[name]/tot:5.1f}%")
