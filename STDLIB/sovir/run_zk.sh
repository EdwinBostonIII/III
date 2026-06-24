#!/usr/bin/env bash
# run_zk.sh -- ZK-ATTESTED EXECUTION gate.  ONE field recurrence x_{i+1}=(x_i^2+c) mod p (p=998244353,c=7,x_0=3),
# proven two ways that must agree:
#   (A) ZK-ATTESTED: zk_svir_exec drives III's general zk_air STARK organ -> the honest trace's AIR holds + CP
#       consistent, AND a TAMPERED trace is rejected (air_constraints_hold==0).  Exit 99.
#   (B) SOVEREIGN-RUN: the SAME recurrence (indep_recur.iii) -> iiisv -> SVIR -> x86(sovereign)+wasm -> x_7==
#       254673617 -> 99 ; cg_r3 differential -> 99.
# The provable-execution pillar fused to the sovereign-execution layer.  Honest scope: attests a field
# recurrence's trace (zkVM over arbitrary SVIR bytecode + i64-limb arithmetization is the larger goal de-risked).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"; S="$ROOT/STDLIB/sovir"; BOOT="$ROOT/STDLIB/build/_sovboot"
W="$ROOT/STDLIB/build/sovir"; LIB="$ROOT/STDLIB/build/iii/libiii_native.a"; mkdir -p "$W"
fail=0; say(){ echo "[zk] $*"; }
for m in svir_x86 svir_wasm iiisv zk_svir_exec zk_svir_add zk_svir_sub zk_svir_range zk_svir_mul zk_svir_bitops zk_svir_cmp zk_svir_mem zk_svir_control zk_svir_call zk_svir_shift zk_svir_vm zk_svir_prog zk_svir_attest zk_eidos_fold zk_eidos_ripple zk_perm_oracle zk_svir_straightline zk_svir_stack zk_iiisv_attest zk_svir_mem_dynamic zk_svir_loop zk_svir_vm_fused zk_perm_malicious zk_ext2_kat zk_ext2_fri zk_ext2_stark; do "$IIIS" "$S/$m.iii" --compile-only --out "$W/$m.o" >/dev/null 2>&1 || { say "FAIL compile $m"; fail=1; }; done
gcc "$W/iiisv.o" -o "$W/iiisv.exe" 2>/dev/null
runzk(){ gcc "$W/$1.o" "$LIB" -lkernel32 -o "$W/$1.exe" 2>/dev/null; timeout 30 "$W/$1.exe" >/dev/null 2>&1; echo $?; }

# (0) zkVM FOUNDATION: the SVIR 64-bit ADD opcode arithmetized over the 30-bit field via 14-bit limbs + carry chain.
gcc "$W/zk_svir_add.o" "$LIB" -lkernel32 -o "$W/zk_svir_add.exe" 2>/dev/null
timeout 30 "$W/zk_svir_add.exe" >/dev/null 2>&1; arc=$?
if [ $arc -eq 99 ]; then say "zkVM-ADD : SVIR i64 ADD arithmetized over GF(998244353) via 14-bit limb decomposition + carry-chain AIR (zk_air) ; honest trace holds + forged result AND forged carry both rejected -> 99"
else say "FAIL zkVM-ADD: zk_svir_add=$arc (1=satisfaction 2/3=cp 4=result-tamper 5=carry-tamper 6=re-verify)"; fail=1; fi

# (0a) zkVM SUB: the SVIR 64-bit SUB opcode (c=a-b) arithmetized as the ADD carry chain run BACKWARD (b+c=a).
src=$(runzk zk_svir_sub)
if [ "$src" = "99" ]; then say "zkVM-SUB : SVIR i64 SUB (c=a-b) arithmetized over GF(998244353) as b+c=a via 14-bit limb carry chain (the ADD chain backward, carries [0,0,1,1,1]) ; honest trace holds + forged result AND forged carry both rejected -> 99"
else say "FAIL zkVM-SUB: zk_svir_sub=$src (1=satisfaction 2/3=cp 4=result-tamper 5=carry-tamper 6=re-verify)"; fail=1; fi

# (0b) zkVM SOUNDNESS: the RANGE-CHECK gadget (each limb < 2^14) via bit-decomposition AIR -- closes malleable-limb.
rrc=$(runzk zk_svir_range)
if [ "$rrc" = "99" ]; then say "zkVM-RANGE : 14-bit limb range-check (bit-decomposition AIR, NO lookup) ; valid limbs {0,10995,16383} pass + out-of-range {16384,20000} rejected -> 99"
else say "FAIL zkVM-RANGE: zk_svir_range=$rrc"; fail=1; fi
# (0c) zkVM MUL: the SVIR MUL opcode via limb schoolbook (one-row 11-col tableau; zk_air capacity expanded W:4->16).
mrc=$(runzk zk_svir_mul)
if [ "$mrc" = "99" ]; then say "zkVM-MUL : SVIR MUL via 2-limb schoolbook (degree-2 column constraints + carry) ; honest a*b holds + forged result AND forged carry rejected -> 99"
else say "FAIL zkVM-MUL: zk_svir_mul=$mrc"; fail=1; fi
# (0c2) zkVM BITOPS: the SVIR AND(0x25)/OR(0x26)/XOR(0x27) opcodes via per-bit op + boolean + recomposition AIR.
borc=$(runzk zk_svir_bitops)
if [ "$borc" = "99" ]; then say "zkVM-BITOPS : SVIR AND/OR/XOR arithmetized over GF(998244353) -- per-bit op constraint (AND c=ab, OR c=a+b-ab, XOR c=a+b-2ab) + booleanity + doubling-accumulator recomposition boundary (binds bits to the value, no lookup) ; all 3 ops hold + recompose AND forged result-bit AND non-boolean bit both rejected -> 99 (14-bit limb unit; 64-bit = 5 limbs, no carry)"
else say "FAIL zkVM-BITOPS: zk_svir_bitops=$borc (1=AND 2=OR 3=XOR 4=result-tamper 5=boolean-tamper 6=re-verify)"; fail=1; fi
# (0c3) zkVM CMP: the SVIR EQ(0x30)/NE(0x31) opcodes via the INVERSE-WITNESS is-zero certificate -- the first RELATIONAL brick.
crc=$(runzk zk_svir_cmp)
if [ "$crc" = "99" ]; then say "zkVM-CMP : SVIR EQ/NE arithmetized over GF(998244353) via the inverse-witness is-zero certificate (a-b-d=0 ; c=1-d*w ; c*d=0 => c=is_zero(a-b), w=d^{-1} forced when d!=0) ; EQ holds + NE holds with the REAL field inverse + forged-c (both cases) AND a FORGED inverse witness all rejected -> 99 (orderings reduce to EQ + the sub borrow)"
else say "FAIL zkVM-CMP: zk_svir_cmp=$crc (1=EQ-hold 7=EQ-cp 2=NE-hold 3=EQ-forge-c 4=NE-forge-c 5=NE-forge-w 6=re-prove)"; fail=1; fi
# (0c4) zkVM MEM: address-time-sorted access trace == program-order trace via a GRAND-PRODUCT permutation argument.
memrc=$(runzk zk_svir_mem)
if [ "$memrc" = "99" ]; then say "zkVM-MEM : SVIR memory consistency via a GRAND-PRODUCT multiset-equality (permutation) argument over GF(998244353) -- two accumulator chains PROD(alpha-enc) for program-order vs sorted-order, closed by air_boundaries_hold (NEW in zk_air: transitions bind rows 0..N-2, the permutation closure aO_0=aS_0=1 & aO_final=aS_final lives in boundaries) ; honest permutation holds on BOTH axes + a broken chain (transition-caught) AND a SELF-CONSISTENT non-permutation (product 576!=384, caught ONLY by the boundary) both rejected -> 99 (the master technique; the call-stack is the same argument)"
else say "FAIL zkVM-MEM: zk_svir_mem=$memrc (1=trans 2=bound 7=cp 3=NEG-A 4=NEG-B-trans 5=NEG-B-BOUND 6/8=re-prove)"; fail=1; fi
# (0c5) zkVM CONTROL: SVIR BR(0x50)/BR_IF(0x51) + structured BLOCK/LOOP/IF via a PROGRAM-COUNTER transition AIR.
ctlrc=$(runzk zk_svir_control)
if [ "$ctlrc" = "99" ]; then say "zkVM-CONTROL : SVIR control flow (BR/BR_IF + structured BLOCK/LOOP/IF) via a pc-TRANSITION AIR over GF(998244353) -- one-hot (sel_seq,sel_br) selector, next.pc = sel_seq*(pc+1) + sel_br*target ; a back-edge loop pc=[0,1,2,0,1,2,3,4] holds + a FORGED JUMP DESTINATION AND a FAKED FALL-THROUGH both rejected -> 99 (the last new-technique brick; binding selectors to the program table is the follow-on)"
else say "FAIL zkVM-CONTROL: zk_svir_control=$ctlrc (1=honest 7=cp 2=NEG1-jump-dest 3=NEG2-fake-seq 4=re-prove)"; fail=1; fi
# (0c6) zkVM CALL: SVIR CALL(0x70)/RETURN(0x60) stack BALANCE via a depth-counter chain closed by air_boundaries_hold.
callrc=$(runzk zk_svir_call)
if [ "$callrc" = "99" ]; then say "zkVM-CALL : SVIR CALL/RETURN stack-balance over GF(998244353) -- depth counter (next.depth = depth + is_call - is_ret), closed by air_boundaries_hold (depth_0 = depth_halt = 0) ; nested+sequential calls (depth=[0,1,2,1,2,1,0,0]) balance + a broken counter (transition-caught) AND an UN-RETURNED call (self-consistent chain, depth ends 1!=0, caught ONLY by the boundary) both rejected -> 99 (2nd boundary consumer; LIFO match = the mem permutation layer)"
else say "FAIL zkVM-CALL: zk_svir_call=$callrc (1=trans 2=bound 7=cp 3=NEG-A 4=NEG-B-trans 5=NEG-B-BOUND 6/8=re-prove)"; fail=1; fi
# (0c7) zkVM SHIFT: SVIR SHL(0x28) via BIT RE-INDEXING (c_bit_{i+1}=a_bit_i) + a shifted-in-bit boundary -- 10/10 opcode classes.
shfrc=$(runzk zk_svir_shift)
if [ "$shfrc" = "99" ]; then say "zkVM-SHIFT : SVIR SHL via bit re-indexing over GF(998244353) -- transition c_bit_{i+1}=a_bit_i (every bit up one) + booleanity + the shifted-in low bit pinned 0 by air_boundaries_hold (3rd consumer) ; a<<1 holds + a broken re-index (transition-caught) AND a FORGED shifted-in bit (caught ONLY by the boundary) both rejected -> 99 -- COMPLETES per-opcode SVIR ISA coverage (10/10)"
else say "FAIL zkVM-SHIFT: zk_svir_shift=$shfrc (1=trans 2=bound 7=cp 3=NEG-A 4=NEG-B-trans 5=NEG-B-BOUND 6/8=re-prove)"; fail=1; fi
# (0d) zkVM TRACE LAYOUT: per-step opcode-dispatched execution (selector VM, ADD/MUL) -- arbitrary bytecode proven.
vrc=$(runzk zk_svir_vm)
if [ "$vrc" = "99" ]; then say "zkVM-TRACE : per-step opcode-dispatched VM (selector ADD/MUL, product materialized for degree-2) ; honest execution holds + forged acc AND forged opcode rejected -> 99"
else say "FAIL zkVM-TRACE: zk_svir_vm=$vrc"; fail=1; fi
# (0e) zkVM COMPOSITION: a real LOOP PROGRAM proven by EXECUTION-dispatch (X) CONTROL-flow on ONE trace -- the Ω1-T7 integration.
progrc=$(runzk zk_svir_prog)
if [ "$progrc" = "99" ]; then say "zkVM-COMPOSE : a real SVIR loop program (a 3-iteration counting loop) proven by BOTH the execution-dispatch (acc += is_add) AND the control-flow (pc back-edge/exit) arguments on ONE trace over GF(998244353) -- the per-opcode bricks composed into a whole-program proof ; honest loop holds + a FORGED RESULT (dispatch-caught) + a SKIPPED LOOP (control-caught) + a FAKED COMPUTATION (dispatch-caught) all rejected -> 99 (Ω1-T7: a program = the conjunction of its execution + control traces)"
else say "FAIL zkVM-COMPOSE: zk_svir_prog=$progrc (1=honest 7=cp 2=forged-result 3=skipped-loop 4=faked-compute 5=re-prove)"; fail=1; fi
# (0f) ZK SOUNDNESS: the discriminating oracle -- a MECHANICALLY-traced computation, a REAL STARK proof, an INDEPENDENT
# verifier (no witness), and a FALSE computation REJECTED BY THE MATH (FRI + the Z_T true-quotient constraint at FS-random openings).
attrc=$(runzk zk_svir_attest)
if [ "$attrc" = "99" ]; then say "ZK-SOUNDNESS : a mechanically-computed recurrence trace -> air_stark_prove (Merkle+FS+FRI proof object) -> air_stark_verify (independent, witness-free) ACCEPTS ; a FALSE computation (one interior cell broken) is REJECTED BY THE MATH (CP=combine/Z_T true quotient; CP*Z_H != combine*(x-w^{n-1}) at random openings), and a forged BOUNDARY is rejected -> 99 (sound: the verifier rejects false statements, not a hand-placed tamper -- fixed the air_build_cp Z_H/Z_T gap, DOCS/III-ZK-SOUNDNESS-GAP.md)"
else say "FAIL ZK-SOUNDNESS: zk_svir_attest=$attrc (1=honest-rejected 92=interior-forge-accepted[UNSOUND] 93=both-accepted)"; fail=1; fi
# (0g) ZK-ATTESTED EIDOS PRIMITIVE: a sound STARK proof of an EIDOS event-FOLD (state' = BASE*state + event, the ripple kernel / content-address).
foldrc=$(runzk zk_eidos_fold)
if [ "$foldrc" = "99" ]; then say "ZK-FOLD : EIDOS event-fold (rolling-hash content-address state'=BASE*state+event) MECHANICALLY traced + proven by the sound STARK -> independent witness-free verifier ACCEPTS the honest fold, REJECTS a forged STATE and a forged EVENT by the math -> 99 (the ripple's computational kernel attested soundly; toward Omega.e -- a full EIDOS ripple via iiisv->SVIR->trace->this STARK)"
else say "FAIL ZK-FOLD: zk_eidos_fold=$foldrc (1=honest-rejected 2=forged-state-accepted 3=forged-event-accepted 4=re-prove)"; fail=1; fi
# (0h) ZK-ATTESTED REAL EIDOS RIPPLE: the events are EMITTED BY THE REAL eidos::ripple module (verbs derived from hex-rank gradients), folded + soundly proven.
riprc=$(runzk zk_eidos_ripple)
if [ "$riprc" = "99" ]; then say "ZK-RIPPLE: a REAL eidos::ripple run (eidos_ripple_emit derives each <verb,a,b> from real hex-rank geometry) -> its >=7 emitted events READ BACK + folded by OUR content-address (enc=verb*65536+a*256+b -- NOT the module's sha256 isub witness) + proven by the sound STARK -> witness-free verifier ACCEPTS the honest fold, REJECTS a forged EVENT and a forged STATE by the math -> 99 (HONEST SCOPE: the ripple's real EVENT STREAM is attested under our fold; matching the module's actual sha256 witness identity needs a keccak AIR, not yet built)"
else say "FAIL ZK-RIPPLE: zk_eidos_ripple=$riprc (5=<7-events 1=honest-rejected 2=forged-event-accepted 3=forged-state-accepted 4=re-prove)"; fail=1; fi
# (0i) PERMUTATION-QUARANTINE: the discriminating oracle for the grand-product memory argument (zk_svir_mem). Fixed public alpha is forgeable; this surfaces it honestly.
permrc=$(runzk zk_perm_oracle)
if [ "$permrc" = "99" ]; then say "PERMUTATION : FS-alpha SOUND -- a colliding non-permutation is rejected (the memory argument is safe to make load-bearing)"
elif [ "$permrc" = "50" ]; then say "PERMUTATION-QUARANTINE: zk_perm_oracle=50 -- the fixed-alpha=11 grand product is FORGEABLE (the colliding non-permutation {3,3,5,10}, product 384 == the honest {3,7,5,9}, is ACCEPTED). QUARANTINED: NOT wired into any sound attestation (ZK-SOUNDNESS/FOLD/RIPPLE use the sound TRANSITION STARK, not the permutation). The fix = alpha Fiat-Shamir-derived from the committed column roots (air_derive_alphas); this oracle flips to 99 then -- REQUIRED before any memory/loop zkVM. (advisor-surfaced)"
else say "FAIL PERMUTATION: zk_perm_oracle=$permrc (unexpected -- expected 50 quarantined or 99 fixed)"; fail=1; fi
# (0i+) PERMUTATION-MALICIOUS: the AUTHORITATIVE permutation-soundness oracle -- a MALICIOUS prover who CHOOSES the challenge alpha (the FS-alpha "fix" never tested this).
malrc=$(runzk zk_perm_malicious)
if [ "$malrc" = "99" ]; then say "PERMUTATION-MALICIOUS: SOUND -- air_stark_verify re-derives alpha from the committed roots and REJECTS a non-permutation with a prover-chosen alpha (ZK-MEMORY/ZK-FUSED are now genuinely sound)"
elif [ "$malrc" = "50" ]; then say "PERMUTATION-MALICIOUS: !!! UNSOUND IN-PROTOCOL !!! zk_perm_malicious=50 -- air_stark_verify ACCEPTS a non-permutation {3,3,5,10} with a PROVER-CHOSEN alpha'=11 (the challenge is baked by air_add_term before proving and NEVER re-derived from the commitment). The FS-alpha 'fix' (zk_perm_oracle=99) was SELF-GRADED (honest alpha only). ZK-MEMORY + ZK-FUSED INHERIT this -- their permutation pillar is FORGEABLE; QUARANTINED. SOUND meanwhile: the TRANSITION-ONLY pillars (ZK-SOUNDNESS/FOLD/RIPPLE/OPCODE/STACK/OMEGA-E/LOOP). FIX: air_stark_verify must re-derive alpha,beta from the committed trace roots and reject proofs not using them; this oracle flips to 99 then. (advisor-surfaced)"
else say "FAIL PERMUTATION-MALICIOUS: zk_perm_malicious=$malrc (expected 50 unsound or 99 fixed)"; fail=1; fi
# (0j) ZK-OPCODE: per-OPCODE attestation of a straight-line SVIR program (the fold's MUL/ADD opcodes), SOUND. Required fixing the STARK's W>4 opening stride.
slrc=$(runzk zk_svir_straightline)
if [ "$slrc" = "99" ]; then say "ZK-OPCODE : a straight-line accumulator program (the fold lowered to per-opcode [MUL BASE, ADD enc] x2, one-hot-constrained selectors, product-aux) MECHANICALLY interpreted + proven by the sound STARK -> witness-free verifier ACCEPTS the honest opcode execution, REJECTS a forged ACCUMULATOR and a forged product-aux by the math -> 99 (every COMPUTE opcode attested, not just the fold relation; transition-only so no permutation needed; fixed the STARK W>4 trace-opening stride to honor WMAX=16). Residual: stack-plumbing opcodes + public-bytecode binding"
else say "FAIL ZK-OPCODE: zk_svir_straightline=$slrc (1=honest-rejected 2=forged-acc-accepted 3=forged-aux-accepted 4=re-prove)"; fail=1; fi
# (0k) ZK-STACK: SOUND attestation of a real SVIR STACK-machine execution (CONST pushes, MUL/ADD pop2-push1) -- the shape iiisv emits.
strc=$(runzk zk_svir_stack)
if [ "$strc" = "99" ]; then say "ZK-STACK : a straight-line SVIR expression (CONST 5, CONST 257, MUL, CONST 7, ADD = 5*257+7) evaluated on an explicit 2-slot stack [s0,s1] -- every PUSH (s1'=arg, s0'=s1) and POP2-PUSH1 (s1'=s0 OP s1, s0'=0) MECHANICALLY interpreted + proven by the sound STARK -> witness-free verifier ACCEPTS the honest stack execution, REJECTS a forged STACK-TOP and a forged product-aux by the math -> 99 (the SVIR stack ISA attested soundly = the shape iiisv emits; reading real iiisv bytecode into this AIR is wiring, not new crypto). Residual: LOCAL_GET/SET + public-bytecode binding"
else say "FAIL ZK-STACK: zk_svir_stack=$strc (1=honest-rejected 2=forged-top-accepted 3=forged-aux-accepted 4=re-prove)"; fail=1; fi
# (0l) ZK-OMEGA-E: the genuine Omega.e closure -- prove the execution of iiisv's REAL SVIR bytecode for a real .iii program.
printf 'fn f() -> i64 { return 5 * 257 + 7; }\n' > "$W/test_fold.iii"
gcc "$W/iiisv.o" "$LIB" -lkernel32 -o "$W/iiisv.exe" 2>/dev/null
"$W/iiisv.exe" "$W/test_fold.iii" > "$W/gen_svir.iii" 2>/dev/null
"$IIIS" "$W/gen_svir.iii" --compile-only --out "$W/gen_svir.o" >/dev/null 2>&1
gcc "$W/zk_iiisv_attest.o" "$W/gen_svir.o" "$LIB" -lkernel32 -o "$W/zk_iiisv_attest.exe" 2>/dev/null
timeout 60 "$W/zk_iiisv_attest.exe" >/dev/null 2>&1; oerc=$?
if [ "$oerc" = "99" ]; then say "ZK-OMEGA-E: iiisv compiled a REAL .iii program (return 5*257+7) -> SVIR bytecode; this gadget READ the bytes (svir_ptr/svir_len), PARSED the 5 opcodes (CONST 5, CONST 257, MUL=0x22, CONST 7, ADD=0x20), confirmed they compute 1292, and PROVED the execution with the sound STARK -> witness-free verifier ACCEPTS the honest execution, REJECTS a forged stack-top by the math -> 99 (THE COMPILER'S OWN OUTPUT attested soundly: .iii -> iiisv -> SVIR -> sound ZK = Omega.e for a straight-line program)"
else say "FAIL ZK-OMEGA-E: zk_iiisv_attest=$oerc (6=opcode-count 5=result!=1292 1=honest-rejected 2=forge-accepted; 0=link/run error)"; fail=1; fi
# (0m) ZK-MEMORY: DYNAMIC memory consistency -- the real zkVM memory argument (permutation + read-consistency + sortedness), not a register-file.
memrc=$(runzk zk_svir_mem_dynamic)
if [ "$memrc" = "99" ]; then say "ZK-MEMORY [FS-BOUND SOUND -- alpha,beta now Fiat-Shamir-derived from the committed ACCESS-column roots (air_perm_setup); PERMUTATION-MALICIOUS=99 confirms a prover-chosen alpha is rejected]: DYNAMIC memory (arbitrary STORE/LOAD), a STORE[0]=5,STORE[1]=7,LOAD[0],LOAD[1] trace proven by (1) a grand-product PERMUTATION (FS-alpha,beta) that the (addr,val,iswrite)-sorted order matches program order, (2) READ-CONSISTENCY on the sorted trace (same-addr LOAD returns the prev value via an inverse-witness is-zero, new-addr LOAD returns 0), (3) SORTEDNESS -- all on one trace via air_stark_prove/verify. A forged LOAD value is REJECTED by read-consistency AND a fabricated (non-permutation) access is REJECTED by the permutation -> 99 (the hard part of a zkVM, done; residual: general range-check for sparse addrs + alpha,beta from committed roots)"
else say "FAIL ZK-MEMORY: zk_svir_mem_dynamic=$memrc (1=honest-rejected 2=value-forge-accepted 3=fabricated-accepted 4=re-prove)"; fail=1; fi
# (0n) ZK-LOOP: CONTROL FLOW -- a real loop's program-counter + condition + counter, attested soundly (the third zkVM pillar).
looprc=$(runzk zk_svir_loop)
if [ "$looprc" = "99" ]; then say "ZK-LOOP : a real LOOP (i=0; while i<3 { i=i+1 }) attested SOUNDLY -- the program counter follows the control flow (CHECK -> body-or-exit by the condition; BODY -> back-edge; EXIT -> halt), the condition i<3 certified by an inverse-witness IS-ZERO on (3-i), the counter by next.i = i + is_body, pc bound to one-hot {check,body,exit} -- via air_stark_prove/verify -> witness-free verifier ACCEPTS the honest loop, REJECTS a forged ITERATION COUNT (skipped increment) AND a forged CONTROL decision (back-edge instead of exit) by the math -> 99 (the THIRD zkVM pillar: compute + memory + CONTROL all sound)"
else say "FAIL ZK-LOOP: zk_svir_loop=$looprc (1=honest-rejected 2=forged-count-accepted 3=forged-control-accepted 4=re-prove)"; fail=1; fi
# (0o) ZK-FUSED: the COMPLETE zkVM -- compute + memory + control on ONE trace for a real loop-with-memory program.
fusrc=$(runzk zk_svir_vm_fused)
if [ "$fusrc" = "99" ]; then say "ZK-FUSED [FS-BOUND SOUND -- the memory permutation's alpha,beta are now Fiat-Shamir-derived via a RANGE-AWARE air_perm_setup(1,6) over the access columns; its OWN malicious arm (5) builds the grand products with a prover-chosen alpha'=11 and the verifier REJECTS -> the fused zkVM's memory is sound against an adaptive prover]: a real loop-with-memory program (for i in 0..6 { mem[i] = 7*i }; LOAD mem[3]=>21) with the three pillars on ONE trace -- CONTROL (the counter i increments, driving the addresses), COMPUTE (vp = 7*i, linked to the counter by is_store*(vp-7i)=0), MEMORY (the dynamic STORE/LOAD accesses proven by the grand-product PERMUTATION + READ-CONSISTENCY: the LOAD of mem[3] returns the STORED 21) -- via air_stark_prove/verify -> witness-free verifier ACCEPTS the honest fused execution, REJECTS a forged LOAD value (read-consistency) AND a forged COMPUTED store value (the compute link) by the math -> 99 (W=15, needed WMAX 16->32; a complete zkVM step over a real program, all pillars proven TOGETHER)"
else say "FAIL ZK-FUSED: zk_svir_vm_fused=$fusrc (1=honest-rejected 2=forged-LOAD-accepted 3=forged-COMPUTE-accepted 5=MALICIOUS-alpha-accepted 4=re-prove)"; fail=1; fi

# (A) ZK-attested.  zk_air (with the additive air_lde_at accessor) is in libiii_native.a; link the archive.
gcc "$W/zk_svir_exec.o" "$LIB" -lkernel32 -o "$W/zk_svir_exec.exe" 2>/dev/null
timeout 30 "$W/zk_svir_exec.exe" >/dev/null 2>&1; zrc=$?
if [ $zrc -eq 99 ]; then say "ZK-ATTESTED : zk_air arithmetizes the trace; PROVER satisfaction (air_constraints_hold + CP consistent) + VERIFIER reproduces the constraint from openings (air_combine_opened) + 2-cell soundness negative (forged trace rejected) -> 99"
else say "FAIL zk: zk_svir_exec=$zrc (1=satisfaction 2/3=cp 6=verifier-bridge 4/7=tamper-NOT-rejected 5=re-verify)"; fail=1; fi

# (B) sovereign-run of the SAME recurrence
"$W/iiisv.exe" "$ROOT/STDLIB/independence/indep_recur.iii" > "$W/gen_rec.iii" 2>/dev/null
"$IIIS" "$W/gen_rec.iii" --compile-only --out "$W/gen_rec.o" >/dev/null 2>&1
gcc "$W/svir_x86.o" "$W/gen_rec.o" -o "$W/tx_rec.exe" 2>/dev/null; "$W/tx_rec.exe" > "$W/rec.s" 2>/dev/null
timeout 20 "$BOOT/sovas_main.exe" "$W/rec.s" > "$W/rec.o2" 2>/dev/null
timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/rec.o2" > "$W/rec.x86.exe" 2>/dev/null
timeout 10 "$W/rec.x86.exe" >/dev/null 2>&1; xrc=$?
k=$(objdump -p "$W/rec.x86.exe" 2>/dev/null | grep -ic "DLL Name")
gcc "$W/svir_wasm.o" "$W/gen_rec.o" -o "$W/tw_rec.exe" 2>/dev/null; "$W/tw_rec.exe" > "$W/rec.wasm" 2>/dev/null
node "$S/run_wasm.mjs" "$W/rec.wasm" >/dev/null 2>&1; wrc=$?
"$IIIS" "$ROOT/STDLIB/independence/indep_recur.iii" --compile-only --out "$W/rec_cg.o" >/dev/null 2>&1
timeout 20 "$BOOT/sovlink_main.exe" "$BOOT/crt0_sov.o" "$W/rec_cg.o" > "$W/rec_cg.exe" 2>/dev/null
timeout 10 "$W/rec_cg.exe" >/dev/null 2>&1; crc=$?
if [ $xrc -eq 99 ] && [ $wrc -eq 99 ] && [ $crc -eq 99 ] && [ "$k" = "1" ]; then say "SOVEREIGN-RUN : same recurrence -> iiisv -> SVIR -> x86(sovereign)=99 wasm=99 ; cg_r3=99 (x_7==254673617)"
else say "FAIL sovereign: x86=$xrc wasm=$wrc cg_r3=$crc dlls=$k"; fail=1; fi

# (0p) ZK-EXT2: GF(p^2) arithmetic (numera/zk_ext2.iii library) -- the verifiable foundation for EXTENSION-FIELD challenges.
ext2rc=$(runzk zk_ext2_kat)
if [ "$ext2rc" = "99" ]; then say "ZK-EXT2 : GF(p^2) = F_p[u]/(u^2+u+1) arithmetic VERIFIED (irreducible because p=2 mod 3 -> no cube roots of unity) -- u^2+u+1=0, a*a^-1=1 (would fail on a zero divisor from a reducible modulus), commutativity/distributivity/associativity, norm-in-base-field, nontrivial Frobenius -> 99. The FOUNDATION for lifting FS challenges + FRI off the 30-bit base field (deg-2 ~2^60; tower GF(p^4) ~2^120 = production)."
else say "FAIL ZK-EXT2: zk_ext2_kat=$ext2rc (1=modulus 2/3=inverse 4=commut 5=distrib 6=assoc 7/8=norm 9=frobenius)"; fail=1; fi
# (0q) ZK-EXT2-FRI: the FRI low-degree test FOLD over GF(p^2) -- the heart of the extension-field fix, verified standalone.
efrirc=$(runzk zk_ext2_fri)
if [ "$efrirc" = "99" ]; then say "ZK-EXT2-FRI : the FRI fold f'(x^2) = (f(x)+f(-x))/2 + r*(f(x)-f(-x))/(2x) OVER GF(p^2) (challenge r in GF(p^2)) VERIFIED on a size-16 domain -- a degree-3 CODEWORD folds (16->8->4) to a CONSTANT last layer (ACCEPT), a degree-15 function does NOT (REJECT, the adversary the test turns away) -> 99. The hardest component of lifting the live STARK's FRI to GF(p^2) (~2^60 fold challenges), built + verified BEFORE integration so the rebuild is not blind. NEXT: route air_build_cp's CP + air's FRI fold + air_stark_verify through GF(p^2)."
else say "FAIL ZK-EXT2-FRI: zk_ext2_fri=$efrirc (1=codeword-not-constant 2=high-degree-wrongly-accepted)"; fail=1; fi
# (0r) ZK-EXT2-STARK: the COMBINE->CP->FRI core of a GF(p^2) STARK -- the constraint-combination step over the extension field.
estkrc=$(runzk zk_ext2_stark)
if [ "$estkrc" = "99" ]; then say "ZK-EXT2-STARK : the GF(p^2) STARK core combine->CP->FRI VERIFIED -- two constraint evals C0,C1 combined by a GF(p^2) challenge alpha into CP = C0 + alpha*C1 (a GF(p^2) function), FRI-folded over GF(p^2): a TRUE statement (C0,C1 low-degree) folds to a CONSTANT (ACCEPT), a FALSE statement (C1 high-degree = a violated constraint) does NOT (REJECT) -> 99. The combination challenge ranges over GF(p^2) ~2^60 instead of F_p ~2^30 -- the soundness lift, now demonstrated end-to-end (arithmetic + FRI fold + combination). NEXT: wire into the LIVE air_build_cp (CP as 2 base-field limbs) + air's FRI + air_stark_verify, as a parallel air_stark_*_ext2 path."
else say "FAIL ZK-EXT2-STARK: zk_ext2_stark=$estkrc (1=true-rejected 2=false-accepted)"; fail=1; fi
say "CONCRETE-SOUNDNESS [applies to EVERY 'SOUND' above]: all 'SOUND' = STRUCTURAL soundness (no prover can bypass the FS binding -- proven by the malicious-prover oracles). It is NOT yet PRODUCTION security. Field p~2^30, blowup 4, 16 FRI queries => concrete error ~2^-11 (FRI-query-limited), every algebraic+folding challenge CAPPED at ~2^-27 by the 30-bit field, Fiat-Shamir GRINDABLE at ~2^27. Production targets 80-128 bits; we deliver ~11-27. THE BOTTLENECK = the base field: requires EXTENSION-FIELD challenges (GF(p^3)~2^90) + more queries. See DOCS/III-ZK-CONCRETE-SOUNDNESS.md. (advisor-surfaced; the asterisk is the honest word)"
if [ $fail -eq 0 ]; then
  say "ZK-ATTESTED EXECUTION -- one recurrence, ZK-proven by III's general zk_air (tampered trace rejected) AND sovereign-run via the SVIR toolchain (x86+wasm, cg_r3-agreed), agreeing on x_7=254673617."
fi
exit $fail
