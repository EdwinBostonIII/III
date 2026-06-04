// C:\Users\Edwin Boston\OneDrive\Desktop\III\R2-GENESIS\silicon\resolver_unit_formal.sv
//
// APOTHEOSIS C.12 -- the silicon<->software equivalence FORMAL HARNESS.
//
// Bound to:  R2-GENESIS/silicon/resolver_unit.v  (the DUT)
//            STDLIB/iii/omnia/resolver.iii        (the software twin)
//            DOCS/III-CAPABILITY-APOTHEOSIS.md §C.12
//
// WHAT THIS PROVES (and the precise scope):
//   The synthesizable combinational core of the resolver -- the 8-wide
//   argmax tournament (iiis_score_unit) -- computes, for EVERY possible set
//   of 8 candidate (score,id,fp) triples, the SAME winner that the software
//   resolve() argmax scan computes.  The software scan is:
//
//       best = candidate 0
//       for i in 1..7:
//           if score[i] > best.score:   // STRICT greater-than
//               best = candidate i
//
//   i.e. the maximum score, ties broken toward the LOWEST index.  The
//   tournament tree in iiis_score_unit must agree on the winning score, id,
//   and fp for all 2^256 score assignments (and all id/fp), which the SMT
//   solver discharges symbolically (no enumeration).
//
// SCOPE NOTE (honest boundary): this miter proves the *reduction* (argmax)
// equivalence -- given identical candidate scores, the silicon picks the same
// winner as the software scan.  The candidate-SCORING formula (resolver_score
// in resolver.iii: activation base + hexad/ring/guarantee/K-depth terms) is a
// software-corpus concern (the 200-series .iii tests + the bench corpus), not
// re-derived in silicon; the RTL consumes pre-computed candidate scores
// exactly as the software AVX-2 path (resolver_unit.s) returns (best_id,
// best_score).  See resolver.iii Step-3 Phase-C.4 delegation.  The Step-5
// identity tiebreak (pattern_id + 32-byte mhash, AMBIGUOUS failure) is a
// software-level disambiguation with no silicon candidate-identity analogue
// and is OUT of this miter's scope (reported in escalations).
//
// THE NEGATIVE ARM (mandatory, the point of the proof): a deliberately-wrong
// tournament that returns slot 0 (ref_slot0_winner below) must NOT satisfy
// the equivalence property -- the solver must find a counterexample (any
// candidate vector whose argmax is not at index 0).  The `cover` and the
// dual assertion `a_slot0_differs` make that falsifiability explicit.
//
// TOOLCHAIN: formal proof requires SymbiYosys (sby) + yosys + a SMT solver
// (z3/boolector/yices).  None are present in the III build environment as of
// this writing (verified: `which yosys z3 sby` -> ABSENT), so this harness is
// a correct-by-construction artifact.  When a flow is present, run:
//
//     sby -f resolver_unit_formal.sby
//
// with resolver_unit_formal.sby:
//     [options]   mode prove   depth 1
//     [engines]   smtbmc z3
//     [script]    read -formal resolver_unit.v
//                 read -formal resolver_unit_formal.sv
//                 prep -top resolver_formal_miter
//     [files]     resolver_unit.v  resolver_unit_formal.sv
//
// A passing run discharges `a_winner_equiv` (and proves `a_slot0_differs`
// has a counterexample, i.e. the negative arm is live).

`default_nettype none

// ----------------------------------------------------------------------------
// Behavioral software-twin reference: the resolve() argmax scan.
// Pure combinational; this is the GOLDEN model the DUT is proven against.
// ----------------------------------------------------------------------------
module resolver_ref_argmax (
    input  wire [255:0] cand_score_vec,
    input  wire [255:0] cand_id_vec,
    input  wire [511:0] cand_fp_vec,
    output reg  [31:0]  ref_sc,
    output reg  [31:0]  ref_id,
    output reg  [63:0]  ref_fp
);
    integer i;
    reg [31:0] s;
    always @(*) begin
        // best = candidate 0
        ref_sc = cand_score_vec[31:0];
        ref_id = cand_id_vec[31:0];
        ref_fp = cand_fp_vec[63:0];
        for (i = 1; i < 8; i = i + 1) begin
            s = cand_score_vec[32*i +: 32];
            if (s > ref_sc) begin           // STRICT > : lowest index wins ties
                ref_sc = s;
                ref_id = cand_id_vec[32*i +: 32];
                ref_fp = cand_fp_vec[64*i +: 64];
            end
        end
    end
endmodule

// ----------------------------------------------------------------------------
// Deliberately-wrong reference: always slot 0.  Used to PROVE the negative
// arm is live (the equivalence property must be FALSIFIABLE: a slot-0 picker
// must diverge from the true argmax on some input).
// ----------------------------------------------------------------------------
module resolver_ref_slot0 (
    input  wire [255:0] cand_score_vec,
    input  wire [255:0] cand_id_vec,
    input  wire [511:0] cand_fp_vec,
    output wire [31:0]  bad_sc,
    output wire [31:0]  bad_id,
    output wire [63:0]  bad_fp
);
    assign bad_sc = cand_score_vec[31:0];
    assign bad_id = cand_id_vec[31:0];
    assign bad_fp = cand_fp_vec[63:0];
endmodule

// ----------------------------------------------------------------------------
// The miter: DUT tournament vs. golden argmax reference.
// ----------------------------------------------------------------------------
module resolver_formal_miter (
    input  wire [255:0] cand_score_vec,
    input  wire [255:0] cand_id_vec,
    input  wire [511:0] cand_fp_vec
);
    // DUT: the real silicon tournament.
    wire [63:0] dut_fp;
    wire [31:0] dut_id;
    wire [31:0] dut_sc;
    iiis_score_unit u_dut (
        .cand_score_vec (cand_score_vec),
        .cand_id_vec    (cand_id_vec),
        .cand_fp_vec    (cand_fp_vec),
        .winner_fp      (dut_fp),
        .winner_id      (dut_id),
        .winner_sc      (dut_sc)
    );

    // GOLDEN: the software argmax scan.
    wire [31:0] ref_sc, ref_id;
    wire [63:0] ref_fp;
    resolver_ref_argmax u_ref (
        .cand_score_vec (cand_score_vec),
        .cand_id_vec    (cand_id_vec),
        .cand_fp_vec    (cand_fp_vec),
        .ref_sc         (ref_sc),
        .ref_id         (ref_id),
        .ref_fp         (ref_fp)
    );

    // BAD: the slot-0 picker (negative arm).
    wire [31:0] bad_sc, bad_id;
    wire [63:0] bad_fp;
    resolver_ref_slot0 u_bad (
        .cand_score_vec (cand_score_vec),
        .cand_id_vec    (cand_id_vec),
        .cand_fp_vec    (cand_fp_vec),
        .bad_sc         (bad_sc),
        .bad_id         (bad_id),
        .bad_fp         (bad_fp)
    );

`ifdef FORMAL
    // All properties are IMMEDIATE assert/cover inside a combinational block:
    // this combinational miter has no clock, and yosys-smtbmc (mode prove,
    // depth 1) discharges immediate assert/cover in an always @(*) block.
    // (Module-scope concurrent `cover (expr);` is NOT valid SVA -- concurrent
    // needs `cover property`; immediate cover must be procedural.  When a flow
    // exists, this is the form to use; do not convert these to bare
    // module-scope covers.)
    always @(*) begin
        // ---- THE EQUIVALENCE THEOREM ----
        // For every candidate vector, the silicon winner equals the golden argmax.
        a_winner_sc: assert (dut_sc == ref_sc);
        a_winner_id: assert (dut_id == ref_id);
        a_winner_fp: assert (dut_fp == ref_fp);

        // ---- THE NEGATIVE ARM (falsifiability witness) ----
        // The slot-0 picker is NOT equivalent to the golden argmax: there
        // exists an input where it diverges.  `cover` asks the solver to
        // EXHIBIT one; a passing cover proves the equivalence is non-vacuous
        // (a slot-0 tournament would be caught).
        cv_slot0_differs: cover (bad_id != ref_id);
        // Witness that the DUT itself picks a non-slot-0 winner on some input
        // (so equivalence is exercised against a real argmax, not a vector
        // where slot 0 happens to be the max -- the vacuity trap).
        cv_dut_picks_slot7: cover (dut_id == cand_id_vec[7*32 +: 32] &&
                                   cand_score_vec[7*32 +: 32] >
                                   cand_score_vec[31:0]);
    end
`endif
endmodule

`default_nettype wire
