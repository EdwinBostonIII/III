// C:\Users\Edwin Boston\OneDrive\Desktop\III\R2-GENESIS\silicon\test_204_prespec.sv
//
// APOTHEOSIS C.12 -- equivalence corpus test 204: sealed K-cost ROM bind.
// Mirrors STDLIB/corpus/204_prespec_hw_offload.iii (the pre-specialization /
// hardware-offload cost-policy scenario).  The prespec dispatch CAM is NOT in
// resolver_unit.v; the cost-policy ROM that prices each lowered op IS (gap 4).
// This testbench is the genuine differential for that module:
//   POSITIVE: sealed_root programmed to the canonical table fold -> seal_fault
//             deasserts AND k_cost == the per-opcode LUT value (all 18 ops).
//   NEGATIVE: a tampered sealed_root -> seal_fault asserts AND k_cost is
//             POISONED to 0 (a tampered policy cannot silently alter the
//             kchain).  This is the mandatory "prove the gate FAILS on bad
//             input" arm.

`default_nettype none
`timescale 1ns/1ps

module test_204_prespec;
    reg clk, rst_n;
    reg [255:0] sealed_root;
    reg [4:0]   op;
    wire [63:0] k_cost;
    wire [63:0] table_mhash;
    wire        seal_fault;

    iiis_kcost_rom u_rom (
        .clk(clk), .rst_n(rst_n), .sealed_root_mhash(sealed_root),
        .op(op), .k_cost(k_cost), .table_mhash(table_mhash), .seal_fault(seal_fault)
    );

    always #5 clk = ~clk;
    integer fails, j;

    // Reference LUT (independent copy of the canonical policy).
    function [63:0] ref_lut; input [4:0] o; begin
        case (o)
            5'h00: ref_lut=64'd1000000;  5'h01: ref_lut=64'd2000000;  5'h02: ref_lut=64'd5000000;
            5'h03: ref_lut=64'd3000000;  5'h04: ref_lut=64'd5000000;  5'h05: ref_lut=64'd1000000;
            5'h06: ref_lut=64'd20000000; 5'h07: ref_lut=64'd50000000; 5'h08: ref_lut=64'd2000000;
            5'h09: ref_lut=64'd10000000; 5'h0A: ref_lut=64'd25000000; 5'h0B: ref_lut=64'd1000000;
            5'h0C: ref_lut=64'd1000000;  5'h0D: ref_lut=64'd1000000;  5'h0E: ref_lut=64'd2000000;
            5'h0F: ref_lut=64'd5000000;  5'h10: ref_lut=64'd10000000; 5'h11: ref_lut=64'd1000000;
            default: ref_lut=64'd0;
        endcase
    end endfunction

    initial begin
        fails = 0;
        clk = 0; rst_n = 0; op = 5'h00; sealed_root = 256'd0;
        @(negedge clk);
        // read the canonical fold the ROM expects, then program the sealed root.
        rst_n = 1; @(negedge clk);
        sealed_root = {192'd0, table_mhash};   // POSITIVE: correctly sealed
        @(negedge clk); @(negedge clk);        // 1-cycle registered seal_fault

        if (seal_fault !== 1'b0) begin
            $display("RESOLVER-EQUIV 204 FAIL positive: seal_fault asserted on correct root"); fails=fails+1; end
        // all 18 opcodes price to the LUT.
        for (j = 0; j < 18; j = j + 1) begin
            op = j[4:0]; #1;
            if (k_cost !== ref_lut(j[4:0])) begin
                $display("RESOLVER-EQUIV 204 FAIL positive: op=%0d k_cost=%0d expect=%0d", j, k_cost, ref_lut(j[4:0]));
                fails=fails+1;
            end
        end

        // ---- NEGATIVE ARM: tamper the sealed root ----
        sealed_root = {192'd0, table_mhash ^ 64'h1};   // flip one bit
        @(negedge clk); @(negedge clk);
        if (seal_fault !== 1'b1) begin
            $display("RESOLVER-EQUIV 204 FAIL negative: seal_fault did NOT assert on tampered root"); fails=fails+1; end
        op = 5'h07; #1;   // PROVE (normally 50e6)
        if (k_cost !== 64'd0) begin
            $display("RESOLVER-EQUIV 204 FAIL negative: k_cost not poisoned (=%0d) under seal_fault", k_cost); fails=fails+1; end

        if (fails==0) $display("RESOLVER-EQUIV 204 PASS  (sealed K-cost ROM: correct bind prices LUT; tamper poisons to 0)");
        else          $display("RESOLVER-EQUIV 204 FAIL  total_fails=%0d", fails);
        if (fails==0) $finish; else begin $stop; $finish; end
    end
endmodule

`default_nettype wire
