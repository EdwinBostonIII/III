/* IMPORTS (0x8A) TRAP arm: main ACTUALLY CALLS the unresolved import.  Single-file execution
 * of a cross-module call must NEVER read as green -- pinned traps: interp=198 (UNRES_IMP
 * sentinel), x86=198 (import stub -> ExitProcess(198)), wasm=1 (stub `unreachable` -> native
 * RuntimeError), mirroring the CALL_INDIRECT OOB gate (199/199/1).  EVERY C path returns 99,
 * so ONLY a trap can make any executor read not-99; a 99 from any executor = the
 * silent-execution false-accept (pre-fix the x86 name-bytes-as-code SEGFAULTED here). */
int ext_mul(int a, int b);
int main(void) {
    int r = ext_mul(6, 7);
    if (r == 42) { return 99; }
    return 99;
}
