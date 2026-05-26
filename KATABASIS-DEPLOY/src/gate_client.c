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

static const char *VN[4] = { "OK", "REJECT_SEAL", "REJECT_CAP", "REJECT_HEXAD" };

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
    /* family=2 (F2 WriteMetal), tk=1, target 0x20000=SHARED / 0x1000=HSAVE-brick, hexad=728 (all-POS),
       wcap=0x200000 (WriteMetal right), dcap=0x800000 (Descend-only -> wrong for WriteMetal). */
    fail += run_case(h, "OK",           2,1,0x20000,728,0x200000,0, 0);
    fail += run_case(h, "REJECT_SEAL",  2,1,0x20000,728,0x200000,1, 1);
    fail += run_case(h, "REJECT_CAP",   2,1,0x20000,728,0x800000,0, 2);
    fail += run_case(h, "REJECT_HEXAD", 2,1,0x1000, 728,0x200000,0, 3);
    CloseHandle(h);
    if (fail) printf("\nRESULT: %d case(s) FAILED\n", fail);
    else      printf("\nRESULT: ALL 4 GATE VERDICTS CORRECT -- R3 queried the Ring-0 gate decision.\n");
    return fail;
}
