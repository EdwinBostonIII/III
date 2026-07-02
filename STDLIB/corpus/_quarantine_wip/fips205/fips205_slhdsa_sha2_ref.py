#!/usr/bin/env python3
# C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\scripts\fips205_slhdsa_sha2_ref.py
#
# Trusted FIPS-205 SLH-DSA-SHA2-128s REFERENCE (dev scaffolding, NOT shipped).
# Reuses the VALIDATED SHAKE reference's structure (WOTS+/FORS/XMSS/hypertree/
# ADRS/base_2b/digest-split are IDENTICAL for the 128s set) and overrides ONLY
# the hash layer with the FIPS-205 SHA-2 instantiation (FIPS-205 sec.11.2.1,
# security category 1):
#   ADRSc            = 22-byte compressed address (layer[1] tree[8] type[1] tail[12])
#   F/H/T_l/PRF      = Trunc_n( SHA-256( PK.seed || 0^(64-n) || ADRSc || M ) )
#   PRF_msg          = Trunc_n( HMAC-SHA-256( SK.prf, opt_rand || M ) )
#   H_msg            = MGF1-SHA-256( R || PK.seed || SHA-256(R||PK.seed||PK.root||M), m )
# (cat-1 uses SHA-256 throughout; SHA-512 only enters at cat 3/5 = 192s/256s.)
#
# Validates byte-exact against NIST ACVP SLH-DSA-SHA2-128s internal vector.

import hashlib, hmac, json, sys
sys.path.insert(0, r"C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\scripts")
import fips205_slhdsa_shake_ref as R   # the validated structure

N = R.N  # 16

def _sha256(d): return hashlib.sha256(d).digest()

def adrsc(ad):
    a = ad.a
    return bytes([a[3]]) + bytes(a[8:16]) + bytes([a[19]]) + bytes(a[20:32])  # 1+8+1+12 = 22

def mgf1(seed, outlen):
    out = b''; c = 0
    while len(out) < outlen:
        out += _sha256(seed + c.to_bytes(4, 'big')); c += 1
    return out[:outlen]

# --- SHA-2 hash layer (overrides the SHAKE module globals) ---
def F_sha2(pks, ad, m1):   return _sha256(pks + b'\x00'*(64-N) + adrsc(ad) + m1)[:N]
def H_sha2(pks, ad, m2):   return _sha256(pks + b'\x00'*(64-N) + adrsc(ad) + m2)[:N]
def T_sha2(pks, ad, m):    return _sha256(pks + b'\x00'*(64-N) + adrsc(ad) + m)[:N]
def PRF_sha2(pks, sks, ad):return _sha256(pks + b'\x00'*(64-N) + adrsc(ad) + sks)[:N]
def PRFmsg_sha2(skprf, optrand, M): return hmac.new(skprf, optrand + M, hashlib.sha256).digest()[:N]
def Hmsg_sha2(Rr, pks, pkr, M):
    inner = _sha256(Rr + pks + pkr + M)
    return mgf1(Rr + pks + inner, R.M_DIGEST)

def main():
    # monkey-patch the structure's hash layer
    R.F = F_sha2; R.Hh = H_sha2; R.T_l = T_sha2
    R.PRF = PRF_sha2; R.PRF_msg = PRFmsg_sha2; R.H_msg = Hmsg_sha2
    V = json.load(open(r"C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\corpus\_fips205_slhdsa_128s.vectors.json"))
    c = next(x for x in V["cases"] if x["parameterSet"]=="SLH-DSA-SHA2-128s" and x["signatureInterface"]=="internal")
    sk = bytes.fromhex(c["sk"]); M = bytes.fromhex(c["message"]); want = bytes.fromhex(c["signature"])
    addrnd = sk[2*N:3*N]   # deterministic: addrnd = PK.seed
    got = R.slh_sign_internal(M, sk, addrnd)
    print("sig len got=%d want=%d" % (len(got), len(want)))
    if got == want:
        print("MATCH OK -- FIPS-205 SLH-DSA-SHA2-128s reference reproduces the NIST vector")
        return 0
    for i in range(min(len(got), len(want))):
        if got[i] != want[i]:
            comp = "R" if i < 16 else ("FORS" if i < 2928 else "HT")
            print("FIRST DIFF at byte %d (%s): got %02x want %02x" % (i, comp, got[i], want[i]))
            print(" got [%d:%d]=%s" % (i, i+16, got[i:i+16].hex()))
            print(" want[%d:%d]=%s" % (i, i+16, want[i:i+16].hex()))
            break
    return 1

if __name__ == "__main__": sys.exit(main())
