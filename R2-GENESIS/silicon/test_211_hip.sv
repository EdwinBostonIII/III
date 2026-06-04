// C:\Users\Edwin Boston\OneDrive\Desktop\III\R2-GENESIS\silicon\test_211_hip.sv
//
// APOTHEOSIS C.12 -- equivalence corpus test 211: full resolve + 960-bit
// witness field packing.  Mirrors STDLIB/corpus/211_hip_resolve.iii.
//
// This is the deepest integration test: it drives the TOP-LEVEL
// iiis_resolver_unit through the F->D->S->R->W pipeline with a real I-INSTR
// word and an 8-candidate vector whose argmax sits at a NON-ZERO slot, then
// asserts the emitted 960-bit witness record (wc_data) packs the fields the
// software resolver records:
//   w0  seq, w1 pattern_id(=winner id), w6 {flags,score}, w7 dispatch_fp,
//   w5  k_now (= sealed K-cost of the opcode).
//
// Negative arm (the point): the winning pattern_id packed into w1 MUST be the
// argmax winner (slot 6 here), NOT slot 0.  A slot-0 tournament would pack the
// wrong id -> a_w1_winner FAILS.  We also assert w6's score is the argmax
// score, not slot 0's.

`default_nettype none
`timescale 1ns/1ps

module test_211_hip;
    reg         clk, rst_n;
    wire [63:0] pt_addr;
    reg  [31:0] pt_word;
    reg         pt_valid;
    reg  [255:0] cand_score_vec, cand_id_vec;
    reg  [511:0] cand_fp_vec;
    wire        wc_we;
    wire [63:0] wc_addr;
    wire [959:0] wc_data;
    reg         wc_ready;
    wire        kc_we;
    wire [63:0] kc_addr, kc_data;
    wire [2:0]  cap_check_idx;
    wire [63:0] cap_check_target;
    reg         cap_check_ok;
    wire        bus_we;
    wire [63:0] bus_addr, bus_data;
    reg  [63:0] bus_rdata;
    reg         bus_ack;
    reg  [31:0] hw_feature_mask;
    reg  [255:0] sealed_root_mhash;
    reg         ictl_force_cold, ictl_memo_en, ictl_flush;
    wire        cap_fault, idle, kcost_seal_fault, memo_hit_o;
    wire [5:0]  stage_valid_o;

    iiis_resolver_unit u_top (
        .clk(clk), .rst_n(rst_n),
        .pt_addr(pt_addr), .pt_word(pt_word), .pt_valid(pt_valid),
        .cand_score_vec(cand_score_vec), .cand_id_vec(cand_id_vec), .cand_fp_vec(cand_fp_vec),
        .wc_we(wc_we), .wc_addr(wc_addr), .wc_data(wc_data), .wc_ready(wc_ready),
        .kc_we(kc_we), .kc_addr(kc_addr), .kc_data(kc_data),
        .cap_check_idx(cap_check_idx), .cap_check_target(cap_check_target), .cap_check_ok(cap_check_ok),
        .bus_we(bus_we), .bus_addr(bus_addr), .bus_data(bus_data), .bus_rdata(bus_rdata), .bus_ack(bus_ack),
        .hw_feature_mask(hw_feature_mask), .sealed_root_mhash(sealed_root_mhash),
        .ictl_force_cold(ictl_force_cold), .ictl_memo_en(ictl_memo_en), .ictl_flush(ictl_flush),
        .cap_fault(cap_fault), .idle(idle), .kcost_seal_fault(kcost_seal_fault),
        .memo_hit_o(memo_hit_o), .stage_valid_o(stage_valid_o)
    );

    always #5 clk = ~clk;
    integer fails, i;

    // witness field accessors (little-endian word order; w0 in [63:0]).
    function [63:0] wword; input integer wi; begin wword = wc_data[64*wi +: 64]; end endfunction

    // opcode COMPOSE = 5'h05; LUT k-cost = 1_000_000.
    localparam [4:0] OP_COMPOSE = 5'h05;

    initial begin
        fails = 0;
        clk = 0; rst_n = 0;
        pt_word = 32'd0; pt_valid = 0;
        cand_score_vec = 256'd0; cand_id_vec = 256'd0; cand_fp_vec = 512'd0;
        wc_ready = 1; cap_check_ok = 1; bus_rdata = 0; bus_ack = 0;
        hw_feature_mask = 32'd0;
        ictl_force_cold = 1;     // skip memo fast path -> exercise the tournament
        ictl_memo_en = 0; ictl_flush = 0;
        capture_en = 0;          // phase-1 records are NOT captured into rec[]

        // sealed root programmed so the K-cost ROM does NOT fault (k_cost valid).
        // The canonical fold value is computed by the ROM; we read it via a
        // helper instance to program correctly.
        sealed_root_mhash = {192'd0, kcost_fold()};

        // plant 8 candidates: argmax at slot 6 (id 306, score 0x00AB_0000, fp F6).
        for (i = 0; i < 8; i = i + 1) begin
            cand_id_vec[32*i +: 32]    = 32'd300 + i[31:0];
            cand_fp_vec[64*i +: 64]    = 64'hF000_0000_0000_00F0 + i[63:0];
            cand_score_vec[32*i +: 32] = 32'h0000_1000 + i[31:0];
        end
        cand_score_vec[32*6 +: 32] = 32'h00AB_0000;   // peak at slot 6

        @(negedge clk); rst_n = 1;

        // ---- F: present a COMPOSE I-INSTR word ----
        // word = {opcode[5], operands[27]}.  operands arbitrary but stable.
        pt_word = {OP_COMPOSE, 27'h012_3456};
        pt_valid = 1;
        @(negedge clk);   // posedge after this latches F
        pt_valid = 0;
        // Each subsequent posedge advances one stage: D, S, R, W.
        @(negedge clk);   // past D posedge
        @(negedge clk);   // past S posedge (tournament + memo key)
        @(negedge clk);   // past R posedge (winner -> r_*; k_now = KAR + kcost)
        @(negedge clk);   // past W posedge (witness record built, wc_we asserted)
        @(negedge clk);   // settle: read W-stage outputs after the W posedge

        // ---- assert the witness record ----
        if (wc_we !== 1'b1) begin $display("RESOLVER-EQUIV 211 FAIL wc_we not asserted"); fails=fails+1; end

        // w1 = pattern_id = winner id = 306 (slot 6), NOT 300 (slot 0).
        if (wword(1) !== 64'd306) begin
            $display("RESOLVER-EQUIV 211 FAIL w1 pattern_id=%0d expect 306 (argmax slot6, not slot0=300)", wword(1));
            fails=fails+1;
        end
        // negative-arm explicit: must NOT be the slot-0 id.
        if (wword(1) === 64'd300) begin
            $display("RESOLVER-EQUIV 211 FAIL negative-arm: w1 == slot0 id (slot-0 picker would do this)"); fails=fails+1; end

        // w6 = {flags:32=0, score:32} = argmax score 0x00AB0000.
        if (wword(6) !== {32'd0, 32'h00AB_0000}) begin
            $display("RESOLVER-EQUIV 211 FAIL w6 flags|score=%h expect 0x00AB0000", wword(6)); fails=fails+1; end

        // w7 = dispatch_fp of the winner (slot 6).
        if (wword(7) !== (64'hF000_0000_0000_00F0 + 64'd6)) begin
            $display("RESOLVER-EQUIV 211 FAIL w7 dispatch_fp=%h", wword(7)); fails=fails+1; end

        // w5 = k_now = 0 (initial KAR) + COMPOSE k-cost (1_000_000).
        if (wword(5) !== 64'd1000000) begin
            $display("RESOLVER-EQUIV 211 FAIL w5 k_now=%0d expect 1000000", wword(5)); fails=fails+1; end

        // w0 = seq = 0 for the first record.
        if (wword(0) !== 64'd0) begin
            $display("RESOLVER-EQUIV 211 FAIL w0 seq=%0d expect 0", wword(0)); fails=fails+1; end

        // ====================================================================
        // PHASE 2: back-to-back issue (pipeline-attribution falsifier).
        // Issue COMPOSE then SEAL on consecutive cycles; capture BOTH witness
        // records as wc_we asserts.  Each record MUST carry ITS OWN opcode (w13)
        // and K-cost (w5).  If the decode opcode were read combinationally at
        // R/W (the bug), the first record would carry SEAL's opcode/K-cost.
        // ====================================================================
        @(negedge clk);   // drain any pending W
        run_two();

        if (fails==0) $display("RESOLVER-EQUIV 211 PASS  (full pipeline; 960-bit witness packs argmax-slot6 winner + sealed K-cost; back-to-back opcode/K-cost attributed per-instruction)");
        else          $display("RESOLVER-EQUIV 211 FAIL  total_fails=%0d", fails);
        if (fails==0) $finish; else begin $stop; $finish; end
    end

    // Capture witness records as they are emitted (wc_we) into a small log.
    localparam [4:0] OP_SEAL = 5'h06;   // K-cost LUT = 20_000_000
    reg [959:0] rec [0:7];
    reg [31:0]  rec_n;
    always @(posedge clk) begin
        if (!rst_n) rec_n <= 32'd0;
        else if (wc_we && wc_ready && capture_en) begin
            rec[rec_n[2:0]] <= wc_data;
            rec_n <= rec_n + 32'd1;
        end
    end
    reg capture_en;

    function [63:0] rword; input integer ri; input integer wi;
        begin rword = rec[ri][64*wi +: 64]; end
    endfunction

    task run_two;
        integer base_seq;
        begin
            capture_en = 1;
            rec_n = 0;
            // candidate vector: argmax at slot 3 (id 303) for both instrs.
            for (i = 0; i < 8; i = i + 1) begin
                cand_id_vec[32*i +: 32]    = 32'd300 + i[31:0];
                cand_fp_vec[64*i +: 64]    = 64'hF000_0000_0000_00F0 + i[63:0];
                cand_score_vec[32*i +: 32] = 32'h0000_1000 + i[31:0];
            end
            cand_score_vec[32*3 +: 32] = 32'h0055_0000;   // peak at slot 3
            base_seq = 1;  // first record already consumed seq 0 in phase 1

            // Issue COMPOSE then SEAL on consecutive valid cycles.
            pt_word = {OP_COMPOSE, 27'h000_0001}; pt_valid = 1; @(negedge clk);
            pt_word = {OP_SEAL,    27'h000_0002}; pt_valid = 1; @(negedge clk);
            pt_valid = 0;
            // let both drain through W (a few cycles).
            @(negedge clk); @(negedge clk); @(negedge clk);
            @(negedge clk); @(negedge clk); @(negedge clk);
            capture_en = 0;

            if (rec_n < 32'd2) begin
                $display("RESOLVER-EQUIV 211 FAIL phase2: only %0d records emitted (expect >=2)", rec_n);
                fails = fails + 1;
            end else begin
                // record 0 = COMPOSE: w13 opcode == 5, w5 k_now == prior + 1_000_000.
                if ((rword(0,13) & 64'h1F) !== 64'd5) begin
                    $display("RESOLVER-EQUIV 211 FAIL phase2: rec0 opcode=%0d expect 5(COMPOSE) -- decode field NOT pipelined!", rword(0,13)&64'h1F);
                    fails = fails + 1;
                end
                // record 1 = SEAL: w13 opcode == 6.
                if ((rword(1,13) & 64'h1F) !== 64'd6) begin
                    $display("RESOLVER-EQUIV 211 FAIL phase2: rec1 opcode=%0d expect 6(SEAL)", rword(1,13)&64'h1F);
                    fails = fails + 1;
                end
                // K-cost attribution: rec0 delta = 1_000_000 (COMPOSE), rec1
                // delta = 20_000_000 (SEAL).  k_now is cumulative; the DELTA
                // between rec1 and rec0 must equal SEAL's cost.
                if ((rword(1,5) - rword(0,5)) !== 64'd20000000) begin
                    $display("RESOLVER-EQUIV 211 FAIL phase2: SEAL K-cost delta=%0d expect 20000000 (mis-attributed opcode K-cost)", rword(1,5)-rword(0,5));
                    fails = fails + 1;
                end
                // winner id pipelined correctly for both (slot 3 = id 303).
                if (rword(0,1) !== 64'd303 || rword(1,1) !== 64'd303) begin
                    $display("RESOLVER-EQUIV 211 FAIL phase2: winner id rec0=%0d rec1=%0d expect 303", rword(0,1), rword(1,1));
                    fails = fails + 1;
                end
            end
        end
    endtask

    // helper: the canonical K-cost table fold (must match iiis_kcost_rom).
    function [63:0] kcost_fold;
        integer oi; reg [63:0] acc, v;
        begin
            acc = 64'h0;
            for (oi = 0; oi < 18; oi = oi + 1) begin
                v = klut(oi[4:0]);
                acc = ((acc << 7) | (acc >> 57)) ^ (v + oi);
            end
            kcost_fold = acc;
        end
    endfunction
    function [63:0] klut; input [4:0] o; begin
        case (o)
            5'h00: klut=64'd1000000;  5'h01: klut=64'd2000000;  5'h02: klut=64'd5000000;
            5'h03: klut=64'd3000000;  5'h04: klut=64'd5000000;  5'h05: klut=64'd1000000;
            5'h06: klut=64'd20000000; 5'h07: klut=64'd50000000; 5'h08: klut=64'd2000000;
            5'h09: klut=64'd10000000; 5'h0A: klut=64'd25000000; 5'h0B: klut=64'd1000000;
            5'h0C: klut=64'd1000000;  5'h0D: klut=64'd1000000;  5'h0E: klut=64'd2000000;
            5'h0F: klut=64'd5000000;  5'h10: klut=64'd10000000; 5'h11: klut=64'd1000000;
            default: klut=64'd0;
        endcase
    end endfunction
endmodule

`default_nettype wire
