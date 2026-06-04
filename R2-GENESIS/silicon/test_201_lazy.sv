// C:\Users\Edwin Boston\OneDrive\Desktop\III\R2-GENESIS\silicon\test_201_lazy.sv
//
// APOTHEOSIS C.12 -- equivalence corpus test 201: argmax DEGENERATE-SPACE.
// Mirrors STDLIB/corpus/201_lazy_crystal_levels.iii (the lazy-evaluation
// crystal-levels scenario).  The lazy crystal subsystem itself is NOT in
// resolver_unit.v; what IS testable -- and what test 200 does NOT cover -- is
// the tournament's behavior on the DEGENERATE score spaces a lazy evaluator
// produces: all-equal (only slot 0 ever forced), single-non-zero, and a sweep
// of "max at exactly index k" for every k.  Distinct coverage of the argmax
// reduction's boundary behavior, with a live negative arm.

`default_nettype none
`timescale 1ns/1ps

module test_201_lazy;
    reg  [255:0] cand_score_vec, cand_id_vec;
    reg  [511:0] cand_fp_vec;
    wire [63:0] dut_fp; wire [31:0] dut_id, dut_sc;
    iiis_score_unit u_dut (.cand_score_vec(cand_score_vec), .cand_id_vec(cand_id_vec),
                           .cand_fp_vec(cand_fp_vec), .winner_fp(dut_fp),
                           .winner_id(dut_id), .winner_sc(dut_sc));

    integer i, k, fails;
    reg [31:0] ref_sc, ref_id, s;
    reg [63:0] ref_fp;

    task compute_ref; begin
        ref_sc = cand_score_vec[31:0]; ref_id = cand_id_vec[31:0]; ref_fp = cand_fp_vec[63:0];
        for (i = 1; i < 8; i = i + 1) begin
            s = cand_score_vec[32*i +: 32];
            if (s > ref_sc) begin ref_sc=s; ref_id=cand_id_vec[32*i +: 32]; ref_fp=cand_fp_vec[64*i +: 64]; end
        end
    end endtask

    task setids; begin
        for (i = 0; i < 8; i = i + 1) begin
            cand_id_vec[32*i +: 32] = 32'd200 + i[31:0];
            cand_fp_vec[64*i +: 64] = 64'hAAAA_0000 + i[63:0];
        end
    end endtask

    task chk; input integer cn; begin
        compute_ref;
        if (dut_sc!==ref_sc || dut_id!==ref_id || dut_fp!==ref_fp) begin
            $display("RESOLVER-EQUIV 201 FAIL case=%0d dut_id=%h ref_id=%h", cn, dut_id, ref_id);
            fails = fails + 1;
        end
    end endtask

    initial begin
        fails = 0;
        // case A: all-equal scores -> tie rule keeps slot 0.
        cand_score_vec = 256'd0; cand_id_vec = 256'd0; cand_fp_vec = 512'd0; setids;
        for (i=0;i<8;i=i+1) cand_score_vec[32*i +: 32] = 32'h0000_5555;
        #1; chk(1);
        if (dut_id !== 32'd200) begin $display("RESOLVER-EQUIV 201 FAIL all-equal not slot0"); fails=fails+1; end

        // case B: single non-zero at slot 6 (a lazy crystal that forced one level).
        cand_score_vec = 256'd0; cand_id_vec = 256'd0; cand_fp_vec = 512'd0; setids;
        cand_score_vec[32*6 +: 32] = 32'h0000_0001;
        #1; chk(2);
        if (dut_id !== 32'd206) begin $display("RESOLVER-EQUIV 201 FAIL single-nonzero not slot6"); fails=fails+1; end

        // case C..J: sweep max-at-index k for every k 0..7 (8 cases).
        for (k = 0; k < 8; k = k + 1) begin
            cand_score_vec = 256'd0; cand_id_vec = 256'd0; cand_fp_vec = 512'd0; setids;
            for (i=0;i<8;i=i+1) cand_score_vec[32*i +: 32] = 32'h0000_1000 + i[31:0];
            cand_score_vec[32*k +: 32] = 32'h00FF_0000;  // peak at k
            #1; chk(10 + k);
            if (dut_id !== (32'd200 + k[31:0])) begin
                $display("RESOLVER-EQUIV 201 FAIL sweep k=%0d dut_id=%h", k, dut_id); fails=fails+1;
            end
        end

        if (fails==0) $display("RESOLVER-EQUIV 201 PASS  (degenerate argmax space: all-equal, single, sweep)");
        else          $display("RESOLVER-EQUIV 201 FAIL  total_fails=%0d", fails);
        if (fails==0) $finish; else begin $stop; $finish; end
    end
endmodule

`default_nettype wire
