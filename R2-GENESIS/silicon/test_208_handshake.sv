// C:\Users\Edwin Boston\OneDrive\Desktop\III\R2-GENESIS\silicon\test_208_handshake.sv
//
// APOTHEOSIS C.12 -- equivalence corpus test 208: capability handshake.
// Mirrors STDLIB/corpus/208_cap_handshake.iii.
//
// OUT-OF-RTL-SCOPE (honest SKIP -- NOT a fake pass), with a NOTE.
//
// The full capability-handshake protocol (GRANT minting, attenuation chains,
// the cap_verify_rights flow in capability.iii) is NOT present in
// resolver_unit.v.  The RTL exposes the COMBINATIONAL cap-check stub
// (cap_check_idx / cap_check_target / cap_check_ok -> cap_fault on
// CONVEY/GRANT/LIFT), but it does not mint, attenuate, or verify capability
// rights -- those are fed externally (cap_check_ok is an input).  Asserting a
// handshake-protocol equivalence against an external-input stub would test the
// testbench's own stimulus, not the DUT.  Reported as SKIP; the cap-check
// SIGNAL wiring is covered structurally inside test_211 (cap_fault stays low
// when cap_check_ok is high on a non-store op).  See the C.12 escalation for
// the capability subsystem RTL deferral.

`default_nettype none
`timescale 1ns/1ps

module test_208_handshake;
    initial begin
        $display("RESOLVER-EQUIV 208 SKIP  (capability minting/attenuation/verify not in resolver_unit.v; cap-check is an external input; see C.12 escalation)");
        $finish;
    end
endmodule

`default_nettype wire
