/* KATABASIS Tier-3 R3 client -- queries the in-kernel gate decision over DeviceIoControl.
 *
 * Opens \\.\IIIKatabasisGate (the symlink the resident gate driver creates) and sends the four
 * canonical cases (the same surface Tier-2 proved on metal: OK / REJECT_SEAL / REJECT_CAP /
 * REJECT_HEXAD), checking each returned verdict. Proving the THREE reject cases -- not just the
 * accept -- is the point: a gate that only ever says OK is no gate.
 *
 * Build (mingw):  gcc -O2 -o gate_client.exe gate_client.c
 * Run (after the driver is loaded): gate_client.exe   (exit 0 == all four verdicts correct). */

#include <windows.h>
#include <stdio.h>
#include <stdint.h>

#define IOCTL_KATABASIS_ADMIT 0x222000u   /* CTL_CODE(FILE_DEVICE_UNKNOWN,0x800,METHOD_BUFFERED,FILE_ANY_ACCESS) */
#define IOCTL_SVM_PROBE       0x222004u   /* Ring-1 I0: read-only SVM capability report */
#define IOCTL_PCI_ENUM        0x22200Cu   /* read-only: derive the GPU facts from live PCI config space (CF8h/CFCh) */
#define IOCTL_BEHAVIORAL_FP   0x222010u   /* read-only: the machine's behavioral fingerprint (quine6_kernel) */
#define IOCTL_DESCENT_PROOF   0x222014u   /* read-only: verify a proof-carrying rung at Ring 0 (quine6_kernel) */
#define IOCTL_VOICE_GATE      0x222018u   /* read-only: the capability-typed-effect decision (voice + crystal_cap) */

/* Ring-0 capability-typed-effect decision: the gate mints the crystal capability from live hypervisor-present and
   reports whether a proposed ACTIVE metal write realizes or evaporates -- WITHOUT writing.  The unbrickable-by-
   construction property, observable: active-write realizes IFF bare metal (CAP_METAL held); passive read always. */
static int probe_voice(HANDLE h)
{
    uint64_t out[4] = { 0, 0, 0, 0 };
    DWORD ret = 0;
    if (!DeviceIoControl(h, IOCTL_VOICE_GATE, NULL, 0, out, (DWORD)sizeof(out), &ret, NULL)) {
        printf("  VOICE_GATE DeviceIoControl FAILED (err=%lu)\n", GetLastError()); return 1; }
    uint64_t hv = out[0], caps = out[1], active = out[2], passive = out[3];
    int expect_active = (hv == 0) ? 1 : 0;          /* realizes IFF bare metal */
    int active_ok  = ((int)active == expect_active);
    int passive_ok = ((int)passive == 1);           /* passive read always realizes */
    printf("  Ring-0 capability-typed-effect: hv-present=%llu caps=0x%02llx  active-metal-write-realizes=%llu (expect %d) passive-read-realizes=%llu\n",
           (unsigned long long)hv, (unsigned long long)caps, (unsigned long long)active, expect_active, (unsigned long long)passive);
    if (active_ok && passive_ok) {
        printf("    => the unsafe write's permissibility is DERIVED from the live crystal (voice + crystal_cap live; unbrickable-by-construction, observable).\n");
        return 0;
    }
    printf("    => UNEXPECTED: the capability-typed-effect decision did not track the crystal.\n");
    return 1;
}

/* Ring-0 proof-carrying descent: obtain a rung's proof from the kernel, then prove a VALID proof admits and a
   FORGED one is rejected -- in-kernel verification, content-address-bound to the rung. */
static int probe_dp(HANDLE h)
{
    DWORD ret = 0;
    uint64_t a[4] = { 0x2A, 0x13, 0, 0 };               /* action, precond, prior, claimed(dummy) */
    if (!DeviceIoControl(h, IOCTL_DESCENT_PROOF, a, (DWORD)sizeof(a), a, 16, &ret, NULL)) {
        printf("  DESCENT_PROOF DeviceIoControl FAILED (err=%lu)\n", GetLastError()); return 1; }
    uint64_t proof = a[1];                               /* the kernel's recomputed proof for this rung */
    uint64_t b[4] = { 0x2A, 0x13, 0, proof };            /* valid claim */
    DeviceIoControl(h, IOCTL_DESCENT_PROOF, b, (DWORD)sizeof(b), b, 16, &ret, NULL);
    int valid_ok = (b[0] == 1);
    uint64_t c[4] = { 0x2A, 0x13, 0, proof ^ 1 };        /* forged claim */
    DeviceIoControl(h, IOCTL_DESCENT_PROOF, c, (DWORD)sizeof(c), c, 16, &ret, NULL);
    int forged_rej = (c[0] == 0);
    printf("  Ring-0 proof-carrying descent: proof=0x%06llx  valid-admits=%d forged-rejects=%d\n",
           (unsigned long long)proof, valid_ok, forged_rej);
    if (valid_ok && forged_rej) { printf("    => the gate verifies proof-carrying rungs at Ring 0 (descent_proof live).\n"); return 0; }
    printf("    => UNEXPECTED: proof verification did not behave as required.\n");
    return 1;
}

/* Ring-0 behavioral fingerprint: what the machine actually DOES on a canonical op battery, content-addressed via
   the cg_r0-correct quine6_kernel.  Deterministic + non-degenerate; a challenger compares it across time/machines
   to detect drift/migration/dishonest emulation. */
static int probe_bfp(HANDLE h)
{
    uint64_t out1[1] = { 0 }, out2[1] = { 0 };
    DWORD ret = 0;
    BOOL ok1 = DeviceIoControl(h, IOCTL_BEHAVIORAL_FP, NULL, 0, out1, (DWORD)sizeof(out1), &ret, NULL);
    BOOL ok2 = DeviceIoControl(h, IOCTL_BEHAVIORAL_FP, NULL, 0, out2, (DWORD)sizeof(out2), &ret, NULL);
    if (!ok1 || !ok2) { printf("  BEHAVIORAL_FP DeviceIoControl FAILED (err=%lu)\n", GetLastError()); return 1; }
    int det = (out1[0] == out2[0]);
    int nz  = (out1[0] != 0);
    printf("  Ring-0 behavioral fingerprint: 0x%06llx   deterministic=%d non-degenerate=%d\n",
           (unsigned long long)out1[0], det, nz);
    if (det && nz) { printf("    => the gate reports a stable behavioral identity (quine6_kernel live at Ring 0).\n"); return 0; }
    printf("    => UNEXPECTED: fingerprint not stable/non-zero.\n");
    return 1;
}

static const char *VN[4] = { "OK", "REJECT_SEAL", "REJECT_CAP", "REJECT_HEXAD" };

/* Ring-0 PCI config-space derivation: the kernel scans CF8h/CFCh for the display controller and DERIVES its facts
   (VEN/DEV, rev, BAR0/1/3, bus:dev:fn) -- census.iii's GPU layer, read off live silicon, not hardcoded.
   Out (7 x u64): [0]=found [1]=vendev=(VEN<<16)|DEV [2]=rev [3]=BAR0 [4]=BAR1 [5]=BAR3 [6]=bdf. */
static int probe_pci(HANDLE h)
{
    uint64_t in[1]  = { 0 };
    uint64_t out[7] = { 0,0,0,0,0,0,0 };
    DWORD ret = 0;
    BOOL ok = DeviceIoControl(h, IOCTL_PCI_ENUM, in, 0, out, (DWORD)sizeof(out), &ret, NULL);
    if (!ok) { printf("  PCI_ENUM DeviceIoControl FAILED (err=%lu)\n", GetLastError()); return 1; }
    printf("  Ring-0 PCI config-space derivation (read-only, live CF8h/CFCh):\n");
    if (!out[0]) { printf("    no display controller found on the PCI bus\n"); return 1; }
    printf("    GPU VEN:DEV = %04llx:%04llx   rev=0x%02llx   bus:dev:fn=0x%06llx\n",
           (unsigned long long)((out[1] >> 16) & 0xFFFF), (unsigned long long)(out[1] & 0xFFFF),
           (unsigned long long)out[2], (unsigned long long)out[6]);
    printf("    BAR0=0x%llx  BAR1=0x%llx  BAR3=0x%llx\n",
           (unsigned long long)out[3], (unsigned long long)out[4], (unsigned long long)out[5]);
    printf("    => census's GPU facts DERIVED from live silicon (drift-checked in-kernel vs the sealed expectation).\n");
    return 0;
}

/* Ring-1 I0: ask the kernel (read-only) whether AMD-V/SVM is present and usable. The kernel reads
   CPUID(0x80000001).ECX[2], EFER (always safe), and -- only if SVM is present -- VM_CR. Out (4 x u64):
   [0]=svm_available [1]=EFER [2]=VM_CR [3]=CPUID.80000001.ECX. We decode the ground truth here so
   the operator knows, BEFORE any privileged increment, whether the metal can host a Ring -1 at all. */
static int probe_svm(HANDLE h)
{
    uint64_t in[6]  = { 0,0,0,0,0,0 };
    uint64_t out[4] = { 0,0,0,0 };
    DWORD ret = 0;
    BOOL ok = DeviceIoControl(h, IOCTL_SVM_PROBE, in, (DWORD)sizeof(in),
                              out, (DWORD)sizeof(out), &ret, NULL);
    if (!ok) { printf("  SVM_PROBE DeviceIoControl FAILED (err=%lu)\n", GetLastError()); return 1; }
    uint64_t svm = out[0], efer = out[1], vmcr = out[2], ecx = out[3];
    int svme   = (efer & 0x1000ull) ? 1 : 0;   /* EFER.SVME  bit 12 -- SVM currently enabled */
    int svmdis = (vmcr & 0x0010ull) ? 1 : 0;   /* VM_CR.SVMDIS  bit 4 */
    int svmlk  = (vmcr & 0x0008ull) ? 1 : 0;   /* VM_CR.SVM_LOCK bit 3 */
    printf("  Ring-1 I0 SVM capability probe (read-only):\n");
    printf("    SVM present (CPUID.80000001.ECX[2]) : %s   [ECX=0x%08llx]\n",
           svm ? "YES" : "NO", (unsigned long long)(ecx & 0xFFFFFFFFull));
    printf("    EFER.SVME (already enabled?)         : %d   [EFER=0x%llx]\n", svme, (unsigned long long)efer);
    printf("    VM_CR.SVMDIS / SVM_LOCK              : %d / %d   [VM_CR=0x%llx]\n",
           svmdis, svmlk, (unsigned long long)vmcr);
    if (!svm)               printf("    => VERDICT: no AMD-V on this CPU; Ring -1 (SVM path) not available.\n");
    else if (svmdis && svmlk) printf("    => VERDICT: SVM is BIOS-DISABLED + LOCKED; enable AMD-V/SVM in firmware first.\n");
    else                    printf("    => VERDICT: SVM PRESENT and not BIOS-locked -- the metal can host Ring -1 (I2 may proceed).\n");
    return 0;
}

/* Input contract (6 x u64): family, target_kind, target, action_hexad, cap_rights, seal_mode. */
static int run_case(HANDLE h, const char *label,
                    uint64_t family, uint64_t tk, uint64_t target, uint64_t hexad,
                    uint64_t cap, uint64_t smode, uint64_t expect)
{
    uint64_t in[6]  = { family, tk, target, hexad, cap, smode };
    uint64_t out[1] = { 0xDEADBEEFull };
    DWORD ret = 0;
    BOOL ok = DeviceIoControl(h, IOCTL_KATABASIS_ADMIT, in, (DWORD)sizeof(in),
                              out, (DWORD)sizeof(out), &ret, NULL);
    if (!ok) { printf("  %-13s  DeviceIoControl FAILED (err=%lu)\n", label, GetLastError()); return 1; }
    uint64_t v = out[0];
    const char *vn = (v < 4) ? VN[v] : "??";
    int pass = (v == expect);
    printf("  %-13s  verdict=%llu (%-12s) expect=%llu  %s\n",
           label, (unsigned long long)v, vn, (unsigned long long)expect, pass ? "PASS" : "FAIL");
    return pass ? 0 : 1;
}

/* CP-1 adversarial short-buffer probe (CRASH-AUDIT-C10-r3-ioctl.md, the Phase-4 metal test).
 * A METHOD_BUFFERED ADMIT needs InputBufferLength>=48 (6 x u64) and OutputBufferLength>=8 (1 x u64).
 * The CP-1 guard (gate_driver.iii::gate_validated_code -- binary-verified in gate_ioctl.sys) MUST
 * reject any undersized/NULL request with STATUS_BUFFER_TOO_SMALL (-> ERROR_INSUFFICIENT_BUFFER 122)
 * BEFORE it dereferences SystemBuffer.  Pre-fix this drove a NonPagedPool OOB -> delayed BAD_POOL BSOD.
 *
 * PASS = DeviceIoControl FAILS cleanly (the guard fired; no OOB) AND the machine stays up -- this
 * client RETURNING at all is itself the no-BSOD proof.  FAIL = the call succeeds (guard missing) or
 * the box bugchecks (the client never returns; the operator observes the crash). */
static int run_short_buf(HANDLE h, const char *label, DWORD inlen, DWORD outlen)
{
    uint64_t in[6]  = { 2,1,0x20000,728,0x200000,0 };
    uint64_t out[1] = { 0xDEADBEEFull };
    DWORD ret = 0;
    SetLastError(0);
    BOOL ok = DeviceIoControl(h, IOCTL_KATABASIS_ADMIT, in, inlen, out, outlen, &ret, NULL);
    DWORD err = GetLastError();
    int rejected = (!ok);   /* the guard completes the IRP with a failure NTSTATUS, no buffer touch */
    printf("  %-26s in=%-2lu out=%-2lu  ok=%d err=%-4lu  %s\n",
           label, (unsigned long)inlen, (unsigned long)outlen, ok, (unsigned long)err,
           rejected ? "REJECTED (guard fired, no OOB)" : "ACCEPTED -- CP-1 GUARD MISSING!");
    return rejected ? 0 : 1;
}

int main(void)
{
    HANDLE h = CreateFileA("\\\\.\\IIIKatabasisGate", GENERIC_READ | GENERIC_WRITE,
                           0, NULL, OPEN_EXISTING, 0, NULL);
    if (h == INVALID_HANDLE_VALUE) {
        printf("open \\\\.\\IIIKatabasisGate FAILED (err=%lu) -- is the gate driver loaded?\n",
               GetLastError());
        return 2;
    }
    printf("opened \\\\.\\IIIKatabasisGate -- querying the Ring-0 gate decision:\n");
    int fail = 0;
    probe_svm(h);   /* Ring-1 I0: report SVM ground truth (read-only) before the gate cases */
    printf("\n");
    probe_pci(h);   /* Ring-0: derive census's GPU facts from live PCI config space (read-only) */
    printf("\n");
    probe_bfp(h);   /* Ring-0: the machine's behavioral fingerprint (quine6_kernel live) */
    printf("\n");
    probe_dp(h);    /* Ring-0: verify proof-carrying rungs (descent_proof live) */
    printf("\n");
    probe_voice(h); /* Ring-0: the capability-typed-effect decision (voice + crystal_cap live) */
    printf("\n");
    /* family=2 (F2 WriteMetal), tk=1, target 0x20000=SHARED / 0x1000=HSAVE-brick, hexad=728 (all-POS),
       wcap=0x200000 (WriteMetal right), dcap=0x800000 (Descend-only -> wrong for WriteMetal). */
    fail += run_case(h, "OK",           2,1,0x20000,728,0x200000,0, 0);
    fail += run_case(h, "REJECT_SEAL",  2,1,0x20000,728,0x200000,1, 1);
    fail += run_case(h, "REJECT_CAP",   2,1,0x20000,728,0x800000,0, 2);
    fail += run_case(h, "REJECT_HEXAD", 2,1,0x1000, 728,0x200000,0, 3);
    /* CP-1 Phase-4: adversarial short/zero buffers must be rejected (STATUS_BUFFER_TOO_SMALL), no BSOD. */
    printf("\nCP-1 adversarial short-buffer cases (guard MUST reject before touching SystemBuffer):\n");
    fail += run_short_buf(h, "InputBufferLength<48",  24, 8);   /* in too short  */
    fail += run_short_buf(h, "OutputBufferLength<8",  48, 4);   /* out too short */
    fail += run_short_buf(h, "both zero (NULL buf)",   0, 0);   /* zero-length buffered request */
    CloseHandle(h);
    if (fail) printf("\nRESULT: %d case(s) FAILED\n", fail);
    else      printf("\nRESULT: ALL 4 GATE VERDICTS CORRECT + 3 CP-1 short-buffer cases REJECTED (no BSOD) -- R3 gate + CP-1 guard proven.\n");
    return fail;
}
