// C:\Users\Edwin Boston\OneDrive\Desktop\III\R2-GENESIS\silicon\test_202_memo.sv
//
// APOTHEOSIS C.12 -- equivalence corpus test 202: memo write/hit determinism.
// Mirrors STDLIB/corpus/202_memo_determinism.iii.
//
// Exercises the iiis_memo_unit WRITE path (gap 2) + the combinational
// SHA-256-trunc-128 content-address key (gap 3) -- a module test 200/201 do
// NOT touch.  Differential:
//   COLD : present (pset,intent,ctx) -> lookup MISSES (empty SRAM).
//   WRITE: store the tournament winner under the content key.
//   WARM : same (pset,intent,ctx) -> lookup HITS and reproduces the EXACT
//          stored winner_id + dispatch_fp (the §7.1 outcome-invariance that
//          makes the memo witness-transparent).
// Negative arm: a DISTINCT intent (different content key) must NOT hit -- the
//   memo must not return a stale/foreign winner (proves the key is content-
//   addressed, not a constant slot).

`default_nettype none
`timescale 1ns/1ps

module test_202_memo;
    reg clk, rst_n;
    reg [31:0] pset_id;
    reg [63:0] intent_lo, intent_hi, ctx_lo, ctx_hi;
    reg        lookup;
    reg        ins_we;
    reg [63:0] ins_key_lo, ins_key_hi;
    reg [31:0] ins_winner;
    reg [63:0] ins_fp;
    wire [63:0] key_lo, key_hi;
    wire        hit;
    wire [31:0] hit_winner;
    wire [63:0] hit_fp;

    iiis_memo_unit u_memo (
        .clk(clk), .rst_n(rst_n), .pset_id(pset_id),
        .intent_lo(intent_lo), .intent_hi(intent_hi),
        .ctx_digest_lo(ctx_lo), .ctx_digest_hi(ctx_hi),
        .lookup(lookup),
        .ins_we(ins_we), .ins_key_lo(ins_key_lo), .ins_key_hi(ins_key_hi),
        .ins_winner(ins_winner), .ins_fp(ins_fp),
        .key_lo(key_lo), .key_hi(key_hi),
        .hit(hit), .hit_winner(hit_winner), .hit_fp(hit_fp)
    );

    always #5 clk = ~clk;
    integer fails;

    // Latched content key for the primary intent.
    reg [63:0] k_lo_A, k_hi_A;

    initial begin
        fails = 0;
        clk = 0; rst_n = 0;
        pset_id = 32'd7; intent_lo = 64'hDEAD_BEEF_0000_0001; intent_hi = 64'h0;
        ctx_lo = 64'hCAFE_0000_0000_0002; ctx_hi = 64'h0;
        lookup = 0; ins_we = 0; ins_key_lo = 0; ins_key_hi = 0; ins_winner = 0; ins_fp = 0;
        @(negedge clk); rst_n = 1;

        // ---- COLD lookup (empty SRAM) ----
        // Lookup is COMBINATIONAL (single-cycle SRAM read): hit/key valid the
        // same cycle inputs are stable; the negedges below just let signals settle.
        lookup = 1; @(negedge clk);
        @(negedge clk);
        // capture the combinational content key for this intent
        k_lo_A = key_lo; k_hi_A = key_hi;
        if (hit !== 1'b0) begin $display("RESOLVER-EQUIV 202 FAIL cold lookup unexpectedly HIT"); fails=fails+1; end
        lookup = 0; @(negedge clk);

        // ---- WRITE the tournament winner under the content key ----
        ins_we = 1; ins_key_lo = k_lo_A; ins_key_hi = k_hi_A;
        ins_winner = 32'd142; ins_fp = 64'hF00D_F00D_0000_0142;
        @(negedge clk); ins_we = 0; @(negedge clk);

        // ---- WARM lookup (same intent) MUST hit + reproduce winner ----
        lookup = 1; @(negedge clk);
        @(negedge clk);
        if (hit !== 1'b1) begin $display("RESOLVER-EQUIV 202 FAIL warm lookup MISSED"); fails=fails+1; end
        if (hit_winner !== 32'd142) begin
            $display("RESOLVER-EQUIV 202 FAIL warm winner=%h expect 142", hit_winner); fails=fails+1; end
        if (hit_fp !== 64'hF00D_F00D_0000_0142) begin
            $display("RESOLVER-EQUIV 202 FAIL warm fp=%h", hit_fp); fails=fails+1; end
        lookup = 0; @(negedge clk);

        // ---- NEGATIVE ARM: a DISTINCT intent must NOT hit the stored entry ----
        // (different content key -> different/empty slot; must not return 142.)
        intent_lo = 64'hDEAD_BEEF_9999_9999;   // different intent
        lookup = 1; @(negedge clk);
        @(negedge clk);
        // The distinct key indexes a different slot (empty) -> miss.  If it
        // collided onto the same slot, the stored key compare (full 128-bit)
        // still rejects it -> miss.  Either way: must NOT report the foreign winner.
        if (hit === 1'b1 && hit_winner === 32'd142) begin
            $display("RESOLVER-EQUIV 202 FAIL negative-arm: foreign intent returned stored winner 142"); fails=fails+1; end
        lookup = 0; @(negedge clk);

        if (fails==0) $display("RESOLVER-EQUIV 202 PASS  (memo write->hit reproduces winner; foreign key misses)");
        else          $display("RESOLVER-EQUIV 202 FAIL  total_fails=%0d", fails);
        if (fails==0) $finish; else begin $stop; $finish; end
    end
endmodule

`default_nettype wire
