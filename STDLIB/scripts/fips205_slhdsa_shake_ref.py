#!/usr/bin/env python3
# C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\scripts\fips205_slhdsa_shake_ref.py
#
# Trusted FIPS-205 SLH-DSA-SHAKE-128s REFERENCE (dev scaffolding, NOT shipped /
# NOT linked / NOT part of the sovereign III stdlib).  Its sole purpose is to
# (a) confirm the persisted NIST ACVP vectors are reproducible and our reading
# of FIPS-205 is exact, and (b) emit INTERMEDIATE values (WOTS+/FORS/XMSS/HT)
# so the .iii SLH-DSA-SHAKE family can be bisected component-by-component when
# its 7856-byte signature differs from NIST's.  hashlib.shake_256 is the
# trusted hash layer; only the STRUCTURE here can be wrong, and the 1-byte
# internal vector is the byte-exact oracle.
#
# SLH-DSA-SHAKE-128s params (FIPS-205 Table 2).

import hashlib, json, sys

N=16; H=63; D=7; HP=9; A=12; K=14; LG_W=4; W=16; LEN1=32; LEN2=3; LEN=LEN1+LEN2  # 35
def ceildiv(a,b): return (a+b-1)//b
KA_BYTES=ceildiv(K*A,8)            # 21
TREE_BITS=H-H//D                   # 54
TREE_BYTES=ceildiv(TREE_BITS,8)    # 7
LEAF_BITS=H//D                     # 9
LEAF_BYTES=ceildiv(LEAF_BITS,8)    # 2
M_DIGEST=KA_BYTES+TREE_BYTES+LEAF_BYTES  # 30

def shake256(data, outlen): return hashlib.shake_256(data).digest(outlen)

WOTS_HASH=0; WOTS_PK=1; TREE=2; FORS_TREE=3; FORS_ROOTS=4; WOTS_PRF=5; FORS_PRF=6

class ADRS:
    __slots__=('a',)
    def __init__(self, a=None): self.a=bytearray(32) if a is None else bytearray(a)
    def copy(self): return ADRS(self.a)
    def set_layer(self,l): self.a[0:4]=l.to_bytes(4,'big')
    def set_tree(self,t): self.a[4:16]=t.to_bytes(12,'big')
    def set_type_clear(self,y): self.a[16:20]=y.to_bytes(4,'big'); self.a[20:32]=b'\x00'*12
    def set_keypair(self,i): self.a[20:24]=i.to_bytes(4,'big')
    def get_keypair(self): return int.from_bytes(self.a[20:24],'big')
    def set_chain(self,i): self.a[24:28]=i.to_bytes(4,'big')
    def set_hash(self,i): self.a[28:32]=i.to_bytes(4,'big')
    def set_tree_height(self,i): self.a[24:28]=i.to_bytes(4,'big')
    def set_tree_index(self,i): self.a[28:32]=i.to_bytes(4,'big')
    def get_tree_index(self): return int.from_bytes(self.a[28:32],'big')
    def b(self): return bytes(self.a)

# Hash family (FIPS-205 SHAKE instantiation, simple)
def H_msg(R,pks,pkr,M): return shake256(R+pks+pkr+M, M_DIGEST)
def PRF(pks,sks,ad):    return shake256(pks+ad.b()+sks, N)
def PRF_msg(skp,opt,M): return shake256(skp+opt+M, N)
def F(pks,ad,m1):       return shake256(pks+ad.b()+m1, N)
def Hh(pks,ad,m2):      return shake256(pks+ad.b()+m2, N)
def T_l(pks,ad,m):      return shake256(pks+ad.b()+m, N)

def base_2b(X,b,outlen):
    out=[]; inp=0; total=0; bits=0
    for _ in range(outlen):
        while bits<b:
            total=(total<<8)|X[inp]; inp+=1; bits+=8
        bits-=b
        out.append((total>>bits)&((1<<b)-1))
    return out

def chain(X,i,s,pks,ad):
    tmp=X
    for j in range(i,i+s):
        ad.set_hash(j); tmp=F(pks,ad,tmp)
    return tmp

def wots_pkgen(sks,pks,ad):
    ska=ad.copy(); ska.set_type_clear(WOTS_PRF); ska.set_keypair(ad.get_keypair())
    tmp=b''
    for i in range(LEN):
        ska.set_chain(i); ska.set_hash(0); sk=PRF(pks,sks,ska)
        ad.set_chain(i); ad.set_hash(0); tmp+=chain(sk,0,W-1,pks,ad)
    wp=ad.copy(); wp.set_type_clear(WOTS_PK); wp.set_keypair(ad.get_keypair())
    return T_l(pks,wp,tmp)

def _wots_msg(M):
    msg=base_2b(M,LG_W,LEN1)
    csum=sum(W-1-msg[i] for i in range(LEN1))
    csum<<=((8-((LEN2*LG_W)%8))%8)
    msg+=base_2b(csum.to_bytes(ceildiv(LEN2*LG_W,8),'big'),LG_W,LEN2)
    return msg

def wots_sign(M,sks,pks,ad):
    msg=_wots_msg(M)
    ska=ad.copy(); ska.set_type_clear(WOTS_PRF); ska.set_keypair(ad.get_keypair())
    sig=b''
    for i in range(LEN):
        ska.set_chain(i); ska.set_hash(0); sk=PRF(pks,sks,ska)
        ad.set_chain(i); ad.set_hash(0); sig+=chain(sk,0,msg[i],pks,ad)
    return sig

def wots_pkfromsig(sig,M,pks,ad):
    msg=_wots_msg(M); tmp=b''
    for i in range(LEN):
        ad.set_chain(i)
        tmp+=chain(sig[i*N:(i+1)*N],msg[i],W-1-msg[i],pks,ad)
    wp=ad.copy(); wp.set_type_clear(WOTS_PK); wp.set_keypair(ad.get_keypair())
    return T_l(pks,wp,tmp)

def xmss_node(sks,i,z,pks,ad):
    if z==0:
        ad.set_type_clear(WOTS_HASH); ad.set_keypair(i)
        return wots_pkgen(sks,pks,ad)
    l=xmss_node(sks,2*i,z-1,pks,ad); r=xmss_node(sks,2*i+1,z-1,pks,ad)
    ad.set_type_clear(TREE); ad.set_tree_height(z); ad.set_tree_index(i)
    return Hh(pks,ad,l+r)

def xmss_sign(M,sks,idx,pks,ad):
    auth=b''
    for j in range(HP):
        k=(idx>>j)^1
        auth+=xmss_node(sks,k,j,pks,ad.copy())
    ad.set_type_clear(WOTS_HASH); ad.set_keypair(idx)
    return wots_sign(M,sks,pks,ad)+auth

def xmss_pkfromsig(idx,sig,M,pks,ad):
    wsig=sig[:LEN*N]; auth=sig[LEN*N:]
    ad.set_type_clear(WOTS_HASH); ad.set_keypair(idx)
    node=wots_pkfromsig(wsig,M,pks,ad)
    ad.set_type_clear(TREE); ad.set_tree_index(idx)
    for k in range(HP):
        ad.set_tree_height(k+1)
        ak=auth[k*N:(k+1)*N]
        if (idx>>k)&1==0:
            ad.set_tree_index(ad.get_tree_index()//2); node=Hh(pks,ad,node+ak)
        else:
            ad.set_tree_index((ad.get_tree_index()-1)//2); node=Hh(pks,ad,ak+node)
    return node

def ht_sign(M,sks,pks,idx_tree,idx_leaf):
    ad=ADRS(); ad.set_tree(idx_tree)
    sig=xmss_sign(M,sks,idx_leaf,pks,ad)
    root=xmss_pkfromsig(idx_leaf,sig,M,pks,ad.copy())
    it=idx_tree
    for j in range(1,D):
        il=it&((1<<HP)-1); it=it>>HP
        ad.set_layer(j); ad.set_tree(it)
        s=xmss_sign(root,sks,il,pks,ad)
        sig+=s
        if j<D-1:
            root=xmss_pkfromsig(il,s,root,pks,ad.copy())
    return sig

def fors_skgen(sks,pks,ad,idx):
    ska=ad.copy(); ska.set_type_clear(FORS_PRF); ska.set_keypair(ad.get_keypair()); ska.set_tree_index(idx)
    return PRF(pks,sks,ska)

def fors_node(sks,i,z,pks,ad):
    if z==0:
        sk=fors_skgen(sks,pks,ad,i)
        ad.set_tree_height(0); ad.set_tree_index(i)
        return F(pks,ad,sk)
    l=fors_node(sks,2*i,z-1,pks,ad); r=fors_node(sks,2*i+1,z-1,pks,ad)
    ad.set_tree_height(z); ad.set_tree_index(i)
    return Hh(pks,ad,l+r)

def fors_sign(md,sks,pks,ad):
    idxs=base_2b(md,A,K); sig=b''
    for i in range(K):
        sig+=fors_skgen(sks,pks,ad,i*(1<<A)+idxs[i])
        for j in range(A):
            s=(idxs[i]>>j)^1
            sig+=fors_node(sks,i*(1<<(A-j))+s,j,pks,ad)
    return sig

def fors_pkfromsig(sig,md,pks,ad):
    idxs=base_2b(md,A,K); roots=b''
    per=N*(A+1)
    for i in range(K):
        sk=sig[i*per:i*per+N]
        auth=sig[i*per+N:i*per+per]
        ad.set_tree_height(0); ad.set_tree_index(i*(1<<A)+idxs[i])
        node=F(pks,ad,sk)
        for j in range(A):
            ak=auth[j*N:(j+1)*N]; ad.set_tree_height(j+1)
            if (idxs[i]>>j)&1==0:
                ad.set_tree_index(ad.get_tree_index()//2); node=Hh(pks,ad,node+ak)
            else:
                ad.set_tree_index((ad.get_tree_index()-1)//2); node=Hh(pks,ad,ak+node)
        roots+=node
    fpa=ad.copy(); fpa.set_type_clear(FORS_ROOTS); fpa.set_keypair(ad.get_keypair())
    return shake256(pks+fpa.b()+roots, N)  # T_k over K*N roots

def slh_sign_internal(M,sk,addrnd):
    skseed=sk[0:N]; skprf=sk[N:2*N]; pkseed=sk[2*N:3*N]; pkroot=sk[3*N:4*N]
    R=PRF_msg(skprf,addrnd,M)
    digest=H_msg(R,pkseed,pkroot,M)
    md=digest[0:KA_BYTES]
    tmp_it=digest[KA_BYTES:KA_BYTES+TREE_BYTES]
    tmp_il=digest[KA_BYTES+TREE_BYTES:KA_BYTES+TREE_BYTES+LEAF_BYTES]
    idx_tree=int.from_bytes(tmp_it,'big')&((1<<TREE_BITS)-1)
    idx_leaf=int.from_bytes(tmp_il,'big')&((1<<LEAF_BITS)-1)
    ad=ADRS(); ad.set_tree(idx_tree); ad.set_type_clear(FORS_TREE); ad.set_keypair(idx_leaf)
    sig_fors=fors_sign(md,skseed,pkseed,ad)
    pk_fors=fors_pkfromsig(sig_fors,md,pkseed,ad)
    sig_ht=ht_sign(pk_fors,skseed,pkseed,idx_tree,idx_leaf)
    return R+sig_fors+sig_ht

def main():
    vp=r"C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\corpus\_fips205_slhdsa_128s.vectors.json"
    V=json.load(open(vp))
    c=next(x for x in V["cases"] if x["parameterSet"]=="SLH-DSA-SHAKE-128s" and x["signatureInterface"]=="internal")
    sk=bytes.fromhex(c["sk"]); M=bytes.fromhex(c["message"]); want=bytes.fromhex(c["signature"])
    addrnd=sk[2*N:3*N]  # deterministic: addrnd = PK.seed
    got=slh_sign_internal(M,sk,addrnd)
    print("sig len got=%d want=%d"%(len(got),len(want)))
    if got==want:
        print("MATCH OK -- FIPS-205 SLH-DSA-SHAKE-128s reference reproduces the NIST vector")
        return 0
    # first divergence
    for i in range(min(len(got),len(want))):
        if got[i]!=want[i]:
            print("FIRST DIFF at byte %d: got %02x want %02x"%(i,got[i],want[i]))
            print(" got [%d:%d]=%s"%(i,i+16,got[i:i+16].hex()))
            print(" want[%d:%d]=%s"%(i,i+16,want[i:i+16].hex()))
            print(" R (first %d) match=%s"%(N, got[:N]==want[:N]))
            break
    return 1

if __name__=="__main__": sys.exit(main())
