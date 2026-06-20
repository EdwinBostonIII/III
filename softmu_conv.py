import random, math, sys
sys.setrecursionlimit(100000)
random.seed(321)
exec(open(r"C:/Users/Edwin Boston/OneDrive/Desktop/III/softmu_hard.py").read().split("for d in")[0])

def smax(vals,b):
    mx=max(vals); s=sum(math.exp(b*(z-mx)) for z in vals)/len(vals); return mx+math.log(s)/b
def smin(vals,b): return -smax([-z for z in vals],b)

def soft_solve(n,owner,prio,succ,beta,tol=1e-9,maxit=20000):
    d=max(prio)+1; X=[[0.0]*n for _ in range(d)]; it=[0]
    def body():
        y=[0.0]*n
        for v in range(n):
            vals=[X[prio[v]][u] for u in succ[v]]
            y[v]=smax(vals,beta) if owner[v]==0 else smin(vals,beta)
        return y
    def ev(k):
        if k==-1: return body()
        init=1.0 if k%2==0 else 0.0; X[k]=[init]*n
        for _ in range(maxit):
            it[0]+=1; prev=X[k]; cur=ev(k-1); X[k]=cur
            if max(abs(cur[i]-prev[i]) for i in range(n))<tol: return cur
        return X[k]
    return ev(d-1), it[0]

for n in [6,8,10]:
    for beta in [30,100,300]:
        mism=0;total=0;gaps=[];iters=[]
        for _ in range(40):
            owner,prio,succ=rand_game(n,3)
            orc=oracle(n,owner,prio,succ)
            sv,nit=soft_solve(n,owner,prio,succ,beta)
            iters.append(nit)
            for v in range(n):
                total+=1; pred=0 if sv[v]>0.5 else 1; gaps.append(abs(sv[v]-0.5))
                if pred!=orc[v]: mism+=1
        gaps.sort()
        print(f"n={n} b={beta:4d} mism={mism}/{total} min|gap|={gaps[0]:.2e} med_iter={sorted(iters)[len(iters)//2]}", flush=True)
