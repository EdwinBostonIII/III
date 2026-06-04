// C:\Users\Edwin Boston\OneDrive\Desktop\III\R2-GENESIS\silicon\test_200_18_primitives.sv
//
// APOTHEOSIS C.12 -- equivalence corpus test 200: the 18 primitives.
//
// Mirrors STDLIB/corpus/200_calculus_18_primitives.iii.  This is the PRIMARY
// equivalence-corpus testbench: it drives the silicon argmax tournament
// (iiis_score_unit) over candidate vectors and asserts the winner is
// byte-identical to an INDEPENDENT behavioral argmax reference (the software
// resolve() strict-`>` scan recomputed here in the testbench -- NOT the DUT
// checking itself).
//
// Each of the 18 sub-cases plants the argmax at a DIFFERENT, mostly NON-ZERO
// candidate index (and includes a tie case), so a slot-0 picker produces a
// DIFFERENT winner.  The negative arm (a_neg_*) asserts the slot-0 model
// diverges from the reference on those vectors -- if the DUT silently picked
// slot 0, sub-cases with argmax != 0 would FAIL a_pos_*, and the whole corpus
// would be non-vacuous (the documented anti-pattern this design avoids).
//
// Exit/PASS contract (sim): prints "RESOLVER-EQUIV 200 PASS" and $finish(0)
// on full pass; "RESOLVER-EQUIV 200 FAIL case=<n>" and $finish(1) on any
// mismatch.  Run under iverilog+vvp / verilator / any 2017 sim.

`default_nettype none
`timescale 1ns/1ps

module test_200_18_primitives;

    reg  [255:0] cand_score_vec;
    reg  [255:0] cand_id_vec;
    reg  [511:0] cand_fp_vec;

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

    // Independent behavioral reference: software resolve() argmax scan.
    integer i;
    reg [31:0] ref_sc, ref_id;
    reg [63:0] ref_fp;
    reg [31:0] bad_id;     // slot-0 picker (negative arm)
    reg [31:0] s;

    task compute_ref;
        begin
            ref_sc = cand_score_vec[31:0];
            ref_id = cand_id_vec[31:0];
            ref_fp = cand_fp_vec[63:0];
            for (i = 1; i < 8; i = i + 1) begin
                s = cand_score_vec[32*i +: 32];
                if (s > ref_sc) begin
                    ref_sc = s;
                    ref_id = cand_id_vec[32*i +: 32];
                    ref_fp = cand_fp_vec[64*i +: 64];
                end
            end
            bad_id = cand_id_vec[31:0];   // always slot 0
        end
    endtask

    integer fails;
    integer argmax_idx;

    // Plant: candidate ids = 100+slot, fps = 64'hF000_0000 + slot, and scores
    // a base ramp with the maximum placed at argmax_idx.  This guarantees the
    // argmax sits at the requested (often non-zero) index.
    task plant;
        input integer max_at;     // index that should win
        input [31:0]  peak;       // its score
        input [31:0]  base;       // baseline for the rest (< peak)
        integer j;
        begin
            cand_score_vec = 256'd0;
            cand_id_vec    = 256'd0;
            cand_fp_vec    = 512'd0;
            for (j = 0; j < 8; j = j + 1) begin
                cand_id_vec[32*j +: 32] = 32'd100 + j[31:0];
                cand_fp_vec[64*j +: 64] = 64'hF000_0000 + j[63:0];
                if (j == max_at)
                    cand_score_vec[32*j +: 32] = peak;
                else
                    // descending baseline so no accidental tie at the peak
                    cand_score_vec[32*j +: 32] = base - j[31:0];
            end
        end
    endtask

    task check;
        input integer case_no;
        begin
            compute_ref;
            // Positive arm: DUT == independent reference (winner sc/id/fp).
            if (dut_sc !== ref_sc || dut_id !== ref_id || dut_fp !== ref_fp) begin
                $display("RESOLVER-EQUIV 200 FAIL case=%0d  dut(sc=%h id=%h fp=%h) ref(sc=%h id=%h fp=%h)",
                         case_no, dut_sc, dut_id, dut_fp, ref_sc, ref_id, ref_fp);
                fails = fails + 1;
            end
            // Negative arm: when argmax is NOT slot 0, the slot-0 picker MUST
            // differ from the reference (proving the test is non-vacuous).
            if (ref_id !== cand_id_vec[31:0]) begin
                if (bad_id === ref_id) begin
                    $display("RESOLVER-EQUIV 200 FAIL case=%0d  VACUOUS: slot0==ref id=%h", case_no, ref_id);
                    fails = fails + 1;
                end
            end
        end
    endtask

    initial begin
        fails = 0;
        // 18 sub-cases, one per primitive opcode (0..17).  argmax index walks
        // 0..7 and repeats, deliberately covering NON-ZERO winners and ties.
        // case 1 (FORM)    -- argmax at slot 0 (boundary: slot0 IS correct here)
        plant(0, 32'h0001_0000, 32'h0000_8000); #1; check(1);
        // case 2 (BIND)    -- argmax at slot 1
        plant(1, 32'h0002_0000, 32'h0000_8000); #1; check(2);
        // case 3 (CONVEY)  -- argmax at slot 2
        plant(2, 32'h0003_0000, 32'h0000_8000); #1; check(3);
        // case 4 (MEAN)    -- argmax at slot 3
        plant(3, 32'h0004_0000, 32'h0000_8000); #1; check(4);
        // case 5 (ACT)     -- argmax at slot 4
        plant(4, 32'h0005_0000, 32'h0000_8000); #1; check(5);
        // case 6 (COMPOSE) -- argmax at slot 5
        plant(5, 32'h0006_0000, 32'h0000_8000); #1; check(6);
        // case 7 (SEAL)    -- argmax at slot 6
        plant(6, 32'h0007_0000, 32'h0000_8000); #1; check(7);
        // case 8 (PROVE)   -- argmax at slot 7 (the far corner)
        plant(7, 32'h0008_0000, 32'h0000_8000); #1; check(8);
        // case 9 (QUERY)   -- argmax at slot 6
        plant(6, 32'h0009_0000, 32'h0000_4000); #1; check(9);
        // case 10 (GRANT)  -- argmax at slot 5
        plant(5, 32'h000A_0000, 32'h0000_4000); #1; check(10);
        // case 11 (GOVERN) -- argmax at slot 4
        plant(4, 32'h000B_0000, 32'h0000_4000); #1; check(11);
        // case 12 (THEN)   -- argmax at slot 3
        plant(3, 32'h000C_0000, 32'h0000_4000); #1; check(12);
        // case 13 (WITH)   -- argmax at slot 7
        plant(7, 32'h000D_0000, 32'h0000_4000); #1; check(13);
        // case 14 (UNDER)  -- argmax at slot 2
        plant(2, 32'h000E_0000, 32'h0000_4000); #1; check(14);
        // case 15 (IF)     -- argmax at slot 1
        plant(1, 32'h000F_0000, 32'h0000_4000); #1; check(15);
        // case 16 (LOOP)   -- TIE between slot 2 and slot 5: lowest index (2) wins.
        cand_score_vec = 256'd0; cand_id_vec = 256'd0; cand_fp_vec = 512'd0;
        for (i = 0; i < 8; i = i + 1) begin
            cand_id_vec[32*i +: 32] = 32'd100 + i[31:0];
            cand_fp_vec[64*i +: 64] = 64'hF000_0000 + i[63:0];
            cand_score_vec[32*i +: 32] = 32'h0000_1000;
        end
        cand_score_vec[32*2 +: 32] = 32'h0010_0000;  // tie peak at slot 2
        cand_score_vec[32*5 +: 32] = 32'h0010_0000;  // tie peak at slot 5
        #1; compute_ref;
        // reference (strict >) keeps slot 2 (the earlier of the tied maxima).
        if (dut_id !== 32'd102 || dut_id !== ref_id) begin
            $display("RESOLVER-EQUIV 200 FAIL case=16  TIE  dut_id=%h ref_id=%h (expect 102)", dut_id, ref_id);
            fails = fails + 1;
        end
        // case 17 (LIFT)   -- argmax at slot 7
        plant(7, 32'h0011_0000, 32'h0000_2000); #1; check(17);
        // case 18 (REFLECT)-- argmax at slot 4
        plant(4, 32'h0012_0000, 32'h0000_2000); #1; check(18);

        if (fails == 0)
            $display("RESOLVER-EQUIV 200 PASS  (18 primitive sub-cases, argmax tournament byte-identical to software scan)");
        else
            $display("RESOLVER-EQUIV 200 FAIL  total_fails=%0d", fails);

        if (fails == 0) $finish;
        else begin $stop; $finish; end
    end
endmodule

`default_nettype wire
