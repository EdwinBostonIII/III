import re
p = r"DOCS/III-HARMONY-BACKLOG.md"
s = open(p, encoding="utf-8").read()
done = {
 17: "**DONE** -- `cga_dispose_bv` + the width-faithful registry (bv_dispose two-tier gate; the (64,64) ideal-truth REFUSED by the kernel's count-mask iota); KAT `1344`=99.",
 18: "**DONE** -- NEW `numera/bv_bits` (Tseitin bit-blast -> numera/sat; bit-indirection table: consts/shifts are zero-clause): decides the mixed arithmetic+bitwise boundary exactly -- (x&y)+(x|y)==x+y at w=64 in seconds, mul commutativity w=8, triple-mul distributivity w=6 (the solver's practical boundary, pinned). Required + landed the sat.iii completion: deterministic VSIDS + geometric restarts + learned-clause reduction (formula-driven schedules, byte-reproducible). KAT `1345`=99; sat selftest + 613/635/637/890 green.",
 19: "**DONE** -- `tc_deserialize` (fail-closed inverse of the item-5 encoding; round-trip law byte-exact) + `tcom_receive` (zero-trust: the LOCAL kernel re-proves every received theorem; false math E_UNPROVEN, malformed wire E_NULL); KAT `1346`=99.",
 20: "**DONE** -- NEW `numera/barrett` (general HAC 14.42 over 2^64 limbs, ANY parity, mu once, Knuth fallback for totality); THE UNIFICATION: general organ == ed_mod_l == bigint_mod on Ed25519's L, limb-for-limb; KAT `1347`=99 (24-vector odd+even differential sweep, m^2-1 edge, refusals, slot lifecycle).",
 23: "**DONE** -- `fed_seal_anchor_witnessed` (+ QC variant): every successful cross-tier anchor publishes a bound fragment (producer/op/child-root/parent-root/tiers); refusals record nothing; honest FED_SEAL_UNWITNESSED; KAT `1348`=99.",
 24: "**DONE** -- `cga_bv_discover`: exhaustive observation-free (a,b) sweep through the width-faithful sieve.  THE DISCOVERY: the 0..64 grid admits exactly 65 = the 64-diagonal PLUS the count-mask truth (0,64) [x*1 == x<<64 on x86] -- a machine identity the ideal model cannot phrase, found autonomously; registry truth-law corrected to a<64 AND a==(b&63); KAT `1353`=99.",
 25: "**DONE** -- NEW `tempora/duration_cert`: the five hand-derived DUR_LIMIT_* saturation constants kernel-certified as EXACT boundaries via TC_BVMULOVF/TC_BVADDOVF (the lossless verdicts), add/mul saturation agrees with the kernel at every boundary witness; KAT `1351`=99.",
 26: "**DONE** -- NEW `omnia/xii_denote`: the third INDEPENDENT authority for IF-lift/equal-branch -- an EVALUATOR over a branch-picking u64 model (per-fusion injective mixes, environment-keyed F.IF); the lift law (both positions x three operators) + equal-branch hold pointwise; swapped-arm/dropped-operand/wrong-operator all discriminate; KAT `1352`=99.",
 27: "**DONE** -- NEW `omnia/xii_cost_monotone`: the MPO termination promise made mechanical -- every live rule fired on its joinability witness satisfies weight(RHS) <= weight(LHS) (the xii_cap_preserve harness, weight edition); KAT `1349`=99.",
 28: "**DONE** -- month-exact civil validity (`cal_days_in_month`/`cal_civil_valid`; Gregorian century/400-year law): 2026-02-31 no longer aliases 2026-03-03 -- accepted names are a BIJECTION with instants (and rfc3339 inherits the refusal); KAT `1350`=99.",
}
for n, txt in done.items():
    s = re.sub(r"(\| %d \|[^|]+\|[^|]+\|[^|]+\|[^|]+\|) TODO \|" % n, r"\1 %s |" % txt, s, count=1)
s = s.replace("Wave 6-16 GATED 2026-06-09:",
  "Wave 17-28 GATED 2026-06-09: build_stdlib 575/0 (lib 90226533); all 10 KATs =99; FULL corpus PASS=957 FAIL=0 zero WRONG; no reseal.\n\nWave 6-16 GATED 2026-06-09:")
open(p, "w", encoding="utf-8").write(s)
print("backlog 17-28 updated")
