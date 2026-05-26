/* KATABASIS Ring-1 FLOOR client (#19a, teardown-first) -- exercises the isolated floor driver.
 *
 * Opens \\.\IIIKatabasisFloor and runs two SAFE IOCTLs: (1) FLOOR_PROBE re-reads SVM capability from
 * the floor driver (sanity vs I0); (2) SVM_DISABLE runs the teardown primitive -- a Ring-0 WRMSR EFER
 * on a pinned core that clears only bit 12 (SVME). Because SVME is currently 0, that write is the
 * register's own value (a no-op): the proof is that the privileged WRMSR + per-core pin path EXECUTED
 * in Ring 0, preserved long mode, and the machine stayed up -- the foundation #19b's real enable needs.
 *
 * Build:  x86_64-w64-mingw32-gcc -O2 -o floor_client.exe floor_client.c
 * Run (after gate_floor is loaded): floor_client.exe   (exit 0 == teardown primitive proven). */

#include <windows.h>
#include <stdio.h>
#include <stdint.h>

#define IOCTL_FLOOR_PROBE    0x222000u
#define IOCTL_SVM_DISABLE    0x222004u
#define IOCTL_SVM_HOSTMODE   0x222008u
#define IOCTL_VMCB_BUILD     0x22200Cu
#define IOCTL_SVM_VMRUN      0x222010u
#define IOCTL_GATE_AT_VMEXIT 0x222014u
#define IOCTL_GATE_LOOP      0x222018u
#define IOCTL_NPT_INTERCEPT  0x22201Cu
#define IOCTL_VMRUN_DIAG     0x222020u
#define IOCTL_GATE_SELF      0x222024u

int main(void)
{
    HANDLE h = CreateFileA("\\\\.\\IIIKatabasisFloor", GENERIC_READ | GENERIC_WRITE,
                           0, NULL, OPEN_EXISTING, 0, NULL);
    if (h == INVALID_HANDLE_VALUE) {
        printf("open \\\\.\\IIIKatabasisFloor FAILED (err=%lu) -- is gate_floor loaded?\n", GetLastError());
        return 2;
    }
    printf("opened \\\\.\\IIIKatabasisFloor -- Ring-1 floor #19a (teardown-first):\n\n");
    int fail = 0;

    /* 1. re-probe SVM from the floor driver (must match I0) */
    {
        uint64_t in[6] = {0}, out[4] = {0}; DWORD ret = 0;
        if (!DeviceIoControl(h, IOCTL_FLOOR_PROBE, in, (DWORD)sizeof in, out, (DWORD)sizeof out, &ret, NULL)) {
            printf("  [probe]   DeviceIoControl FAILED (err=%lu)\n", GetLastError()); fail++;
        } else {
            printf("  [probe]   SVM=%llu  EFER=0x%llx  VM_CR=0x%llx  ECX=0x%08llx\n",
                   (unsigned long long)out[0], (unsigned long long)out[1],
                   (unsigned long long)out[2], (unsigned long long)(out[3] & 0xFFFFFFFFull));
        }
    }

    /* 2. the teardown primitive: Ring-0 WRMSR EFER (no-op while SVME=0), on a pinned core */
    {
        uint64_t in[6] = {0}, out[3] = {0}; DWORD ret = 0;
        if (!DeviceIoControl(h, IOCTL_SVM_DISABLE, in, (DWORD)sizeof in, out, (DWORD)sizeof out, &ret, NULL)) {
            printf("  [disable] DeviceIoControl FAILED (err=%lu)\n", GetLastError()); fail++;
        } else {
            uint64_t e0 = out[0], e1 = out[1], e2 = out[2];
            printf("  [disable] EFER before=0x%llx  written=0x%llx  after=0x%llx\n",
                   (unsigned long long)e0, (unsigned long long)e1, (unsigned long long)e2);
            int svme_was = (e0 & 0x1000ull) ? 1 : 0;
            int mask_ok  = (e1 == (e0 & ~0x1000ull));   /* cleared ONLY bit 12 */
            int noop_ok  = (e2 == e0);                  /* readback == original (true no-op) */
            int lm_ok    = ((e2 & 0x500ull) == 0x500ull); /* LME(b8)|LMA(b10) still set -> long mode intact */
            printf("    SVME(before)=%d   mask=cleared-bit12-only:%s   no-op(after==before):%s   long-mode-intact:%s\n",
                   svme_was, mask_ok ? "YES" : "NO", noop_ok ? "YES" : "NO", lm_ok ? "YES" : "NO");
            if (!mask_ok || !noop_ok || !lm_ok) { printf("    => FAIL: the WRMSR EFER RMW did not behave as a safe no-op\n"); fail++; }
            else printf("    => PASS: privileged WRMSR EFER executed in Ring 0 on a pinned core, long mode preserved, no wedge.\n");
        }
    }

    /* 3. SVM host-mode enter/exit round-trip (#19b): enable SVM, set VM_HSAVE_PA, fully reverse */
    {
        uint64_t in[6] = {0}, out[5] = {0}; DWORD ret = 0;
        if (!DeviceIoControl(h, IOCTL_SVM_HOSTMODE, in, (DWORD)sizeof in, out, (DWORD)sizeof out, &ret, NULL)) {
            printf("  [hostmode] DeviceIoControl FAILED (err=%lu)\n", GetLastError()); fail++;
        } else {
            uint64_t e0 = out[0], e1 = out[1], e2 = out[2], rv = out[3], rp = out[4];
            printf("  [hostmode] EFER before=0x%llx  enabled=0x%llx  after=0x%llx\n",
                   (unsigned long long)e0, (unsigned long long)e1, (unsigned long long)e2);
            printf("             SVM region: virt=0x%llx  phys=0x%llx\n",
                   (unsigned long long)rv, (unsigned long long)rp);
            int en_ok     = (e1 == (e0 | 0x1000ull));            /* enable set SVME, kept the rest */
            int svme_on   = (e1 & 0x1000ull) ? 1 : 0;
            int lm_kept   = ((e1 & 0x500ull) == 0x500ull);       /* LME|LMA still set while enabled */
            int rev_ok    = (e2 == e0);                          /* disabled back to the original EFER */
            int region_ok = (rv != 0 && rp != 0 && rp < 0x100000000ull); /* allocated, phys <4GB */
            printf("             SVM-enabled(SVME set)=%s  long-mode-kept=%s  reversed=%s  region<4GB=%s\n",
                   (en_ok && svme_on) ? "YES" : "NO", lm_kept ? "YES" : "NO",
                   rev_ok ? "YES" : "NO", region_ok ? "YES" : "NO");
            if (!(en_ok && svme_on) || !lm_kept || !rev_ok || !region_ok) { printf("    => FAIL\n"); fail++; }
            else printf("    => PASS: III entered SVM host mode (SVME on, long mode intact), set VM_HSAVE_PA, fully reversed -- on metal.\n");
        }
    }

    /* 4. VMCB build verification (#19c-i): build the VMCB+NPT+guest in a region, read back, verify. NO VMRUN. */
    {
        uint64_t in[6] = {0}, out[12] = {0}; DWORD ret = 0;
        if (!DeviceIoControl(h, IOCTL_VMCB_BUILD, in, (DWORD)sizeof in, out, (DWORD)sizeof out, &ret, NULL)) {
            printf("  [vmcb]    DeviceIoControl FAILED (err=%lu)\n", GetLastError()); fail++;
        } else {
            uint64_t f008=out[0], f010=out[1], f058=out[2], np=out[3], ncr3=out[4], efer=out[5],
                     cr0=out[6], rip=out[7], pml4=out[8], pd0=out[9], gc=out[10], phys=out[11];
            printf("  [vmcb]    region_phys=0x%llx\n", (unsigned long long)phys);
            printf("            INTERCEPT_EXC=0x%08llx MISC1=0x%08llx MISC2=0x%llx  ASID=%llu TLB=%llu NP=%llu\n",
                   (unsigned long long)(f008&0xFFFFFFFF), (unsigned long long)(f008>>32),
                   (unsigned long long)(f010&0xFFFFFFFF), (unsigned long long)(f058&0xFFFFFFFF),
                   (unsigned long long)(f058>>32), (unsigned long long)np);
            printf("            N_CR3=0x%llx(want 0x%llx) EFER=0x%llx CR0=0x%llx RIP=0x%llx(want 0x%llx)\n",
                   (unsigned long long)ncr3, (unsigned long long)(phys+0x2000), (unsigned long long)efer,
                   (unsigned long long)cr0, (unsigned long long)rip, (unsigned long long)(phys+0xA000));
            printf("            PML4[0]=0x%llx(want 0x%llx) PD[0]=0x%llx(want 0xE7) guestcode=0x%08llx(want 0xF4D9010F)\n",
                   (unsigned long long)pml4, (unsigned long long)((phys+0x3000)|0x67),
                   (unsigned long long)pd0, (unsigned long long)(gc&0xFFFFFFFF));
            int ok = (f008&0xFFFFFFFF)==0xFFFFFFFFull && (f008>>32)==0x9906000Full && (f010&0xFFFFFFFF)==0x3Full
                  && (f058&0xFFFFFFFF)==1 && (f058>>32)==1 && np==1
                  && ncr3==(phys+0x2000) && efer==0x1000 && cr0==0x11 && rip==(phys+0xA000)
                  && pml4==((phys+0x3000)|0x67) && pd0==0xE7 && (gc&0xFFFFFFFF)==0xF4D9010Full;
            if (ok) printf("    => PASS: VMCB built in Ring 0, every field matches CHARIOT-proven -- ready for VMRUN (#19c-ii).\n");
            else { printf("    => FAIL: a VMCB field mismatched its CHARIOT-proven value\n"); fail++; }
        }
    }

    /* 5. THE VMRUN (#19c-ii / I2): build VMCB, enable SVM, VMRUN the throwaway guest, expect VMEXIT 0x81 */
    {
        uint64_t in[6] = {0}, out[4] = {0}; DWORD ret = 0;
        if (!DeviceIoControl(h, IOCTL_SVM_VMRUN, in, (DWORD)sizeof in, out, (DWORD)sizeof out, &ret, NULL)) {
            printf("  [vmrun]   DeviceIoControl FAILED (err=%lu)\n", GetLastError()); fail++;
        } else {
            uint64_t exitcode=out[0], ei1=out[1], rip=out[2], phys=out[3];
            printf("  [vmrun]   EXITCODE=0x%llx (want 0x81=VMEXIT_VMMCALL)  EXITINFO1=0x%llx\n",
                   (unsigned long long)exitcode, (unsigned long long)ei1);
            printf("            guest RIP(post-#VMEXIT)=0x%llx  region_phys=0x%llx\n",
                   (unsigned long long)rip, (unsigned long long)phys);
            if (exitcode == 0x81ull)
                printf("    => PASS: the guest EXECUTED VMMCALL in Ring -1 and #VMEXIT'd cleanly --\n"
                       "             III ran a guest under its OWN III-emitted hypervisor in Ring -1 of live Windows.\n");
            else if (exitcode == 0xFFFFFFFFFFFFFFFFull)
                { printf("    => FAIL: EXITCODE=-1 (VMEXIT_INVALID) -- the VMCB was rejected; VMRUN did not run the guest\n"); fail++; }
            else { printf("    => FAIL: unexpected EXITCODE 0x%llx (a different exit reason)\n", (unsigned long long)exitcode); fail++; }
        }
    }

    /* 6. THE GATE AT THE RING-1 VMEXIT (I3-i): each case VMRUNs a guest (-> VMEXIT 0x81) then runs the
       full katabasis gate on the request. Proves the Ring-1 hypercall triggers the CORRECT verdict for
       all four cases (OK + the three rejects -- a gate that only says OK is no gate). */
    {
        static const char *VN[4] = { "OK", "REJECT_SEAL", "REJECT_CAP", "REJECT_HEXAD" };
        /* {family, target_kind, target, action_hexad, cap_rights, seal_mode, expected_verdict} */
        uint64_t cs[4][7] = {
            { 2,1,0x20000,728,0x200000,0, 0 },   /* OK            */
            { 2,1,0x20000,728,0x200000,1, 1 },   /* REJECT_SEAL   (wrong seal) */
            { 2,1,0x20000,728,0x800000,0, 2 },   /* REJECT_CAP    (cap lacks WriteMetal right) */
            { 2,1,0x1000, 728,0x200000,0, 3 },   /* REJECT_HEXAD  (HSAVE-brick target) */
        };
        printf("  [gate@VMEXIT] the full gate decision DRIVEN BY a Ring-1 VMEXIT, 4 cases:\n");
        for (int i = 0; i < 4; i++) {
            uint64_t in[6] = { cs[i][0],cs[i][1],cs[i][2],cs[i][3],cs[i][4],cs[i][5] };
            uint64_t out[4] = {0}; DWORD ret = 0;
            if (!DeviceIoControl(h, IOCTL_GATE_AT_VMEXIT, in, (DWORD)sizeof in, out, (DWORD)sizeof out, &ret, NULL)) {
                printf("    %-13s DeviceIoControl FAILED (err=%lu)\n", VN[i], GetLastError()); fail++; continue;
            }
            uint64_t exitcode = out[0], verdict = out[1], expect = cs[i][6];
            const char *vn = (verdict < 4) ? VN[verdict] : "??";
            int pass = (exitcode == 0x81ull) && (verdict == expect);
            printf("    %-13s VMEXIT=0x%llx  verdict=%llu (%-12s) expect=%llu  %s\n",
                   VN[i], (unsigned long long)exitcode, (unsigned long long)verdict, vn,
                   (unsigned long long)expect, pass ? "PASS" : "FAIL");
            if (!pass) fail++;
        }
        if (!fail) printf("    => PASS: the gate decision ran AT the Ring-1 VMEXIT for all 4 cases -- III's gate adjudicated\n"
                          "             guest hypercalls from the hypervisor seat. Tier-2/3 gate FUSED with Ring -1.\n");
    }

    /* 7. THE RESUME LOOP (I3-ii): host adjudicates the guest's 1st VMMCALL, writes the verdict to its RAX,
       RESUMES; the guest carries the verdict to a 2nd VMMCALL where we read it back (echo). echo==verdict
       proves the host->guest->host round-trip -- the I5 adjudicate-and-resume loop, disposable guest. */
    {
        static const char *VN[4] = { "OK", "REJECT_SEAL", "REJECT_CAP", "REJECT_HEXAD" };
        uint64_t cs[4][7] = {
            { 2,1,0x20000,728,0x200000,0, 0 },
            { 2,1,0x20000,728,0x200000,1, 1 },
            { 2,1,0x20000,728,0x800000,0, 2 },
            { 2,1,0x1000, 728,0x200000,0, 3 },
        };
        printf("  [resume-loop] adjudicate-and-resume; the guest ECHOES the verdict it received, 4 cases:\n");
        for (int i = 0; i < 4; i++) {
            uint64_t in[6] = { cs[i][0],cs[i][1],cs[i][2],cs[i][3],cs[i][4],cs[i][5] };
            uint64_t out[4] = {0}; DWORD ret = 0;
            if (!DeviceIoControl(h, IOCTL_GATE_LOOP, in, (DWORD)sizeof in, out, (DWORD)sizeof out, &ret, NULL)) {
                printf("    %-13s DeviceIoControl FAILED (err=%lu)\n", VN[i], GetLastError()); fail++; continue;
            }
            uint64_t exitcode=out[0], verdict=out[1], echoed=out[2], expect=cs[i][6];
            int pass = (exitcode==0x81ull) && (verdict==expect) && (echoed==verdict);
            printf("    %-13s VMEXIT=0x%llx  verdict=%llu echoed=%llu (guest read it back) expect=%llu  %s\n",
                   VN[i], (unsigned long long)exitcode, (unsigned long long)verdict,
                   (unsigned long long)echoed, (unsigned long long)expect, pass ? "PASS" : "FAIL");
            if (!pass) fail++;
        }
        if (!fail) printf("    => PASS: host adjudicated, RESUMED the guest, and the guest carried the verdict back --\n"
                          "             the I5 adjudicate-and-resume loop, proven with a disposable guest in Ring -1.\n");
    }

    /* 8. NPT page-fault interception (I4): the guest's CODE page is marked not-present; the host catches the
       NPF, reads the faulting GPA, maps the page, and RESUMES (no RIP advance); the guest then runs its
       VMMCALL. Proves III MEDIATES guest memory -- the §0.6 NPT-CoW / observe brick-defense basis. */
    {
        uint64_t in[6] = {0}, out[5] = {0}; DWORD ret = 0;
        if (!DeviceIoControl(h, IOCTL_NPT_INTERCEPT, in, (DWORD)sizeof in, out, (DWORD)sizeof out, &ret, NULL)) {
            printf("  [npt-intercept] DeviceIoControl FAILED (err=%lu)\n", GetLastError()); fail++;
        } else {
            uint64_t iter=out[0], gpa=out[1], npf=out[2], vmm=out[3], phys=out[4];
            printf("  [npt-intercept] iter=%llu  faulting GPA=0x%llx  NPF=0x%llx  VMMCALL=0x%llx  region_phys=0x%llx\n",
                   (unsigned long long)iter, (unsigned long long)gpa, (unsigned long long)npf,
                   (unsigned long long)vmm, (unsigned long long)phys);
            int npf_ok = (npf == 0x400ull);                              /* VMEXIT_NPF was caught */
            int ran_ok = (vmm == 0x81ull);                              /* guest ran after the page was mapped */
            int gpa_ok = ((gpa >> 21) == ((phys + 0xA000ull) >> 21));   /* faulting GPA in the code page's 2MB */
            printf("    NPF-caught=%s  guest-ran-after-map=%s  faulting-GPA-in-code-page=%s\n",
                   npf_ok?"YES":"NO", ran_ok?"YES":"NO", gpa_ok?"YES":"NO");
            if (npf_ok && ran_ok && gpa_ok)
                printf("    => PASS: III intercepted the guest's NPT fault, mapped the page, and resumed --\n"
                       "             guest memory MEDIATED from Ring -1 (the CoW/observe brick-defense basis).\n");
            else { printf("    => FAIL\n"); fail++; }
        }
    }

    /* 9. VMCB diag-copy [E7]: VMRUN the guest, dump the full VMCB (1536B) to R3 -- fault-as-data forensics.
       R3 reads the complete post-exit VMCB: EXITCODE@0x070, guest RIP@0x578, guest CR0@0x558, etc. */
    {
        uint64_t in[6] = {0}; unsigned char dump[2048] = {0}; DWORD ret = 0;
        if (!DeviceIoControl(h, IOCTL_VMRUN_DIAG, in, (DWORD)sizeof in, dump, (DWORD)sizeof dump, &ret, NULL)) {
            printf("  [vmcb-diag] DeviceIoControl FAILED (err=%lu)\n", GetLastError()); fail++;
        } else {
            uint64_t *d = (uint64_t *)dump;
            uint64_t exitcode = d[0x070/8];   /* control EXITCODE */
            uint64_t grip     = d[0x578/8];   /* state-save guest RIP */
            uint64_t gcr0     = d[0x558/8];   /* state-save guest CR0  */
            printf("  [vmcb-diag] dumped %lu VMCB bytes to R3: EXITCODE=0x%llx  guest RIP=0x%llx  guest CR0=0x%llx\n",
                   (unsigned long)ret, (unsigned long long)exitcode, (unsigned long long)grip, (unsigned long long)gcr0);
            int ok = (ret >= 1536) && (exitcode == 0x81ull) && (gcr0 == 0x11ull);
            if (ok) printf("    => PASS: the FULL post-VMRUN VMCB is readable from R3 -- fault-as-data forensics live.\n");
            else { printf("    => FAIL: VMCB dump incomplete or fields wrong (EXITCODE should be 0x81, CR0 0x11)\n"); fail++; }
        }
    }

    /* 10. I3-iii: the guest AUTHORS its own request. The host gives it the shared-area GPA in RAX; the
       guest writes its 6-value cycle request there + VMMCALLs; the host reads the GUEST's request, gates
       it, writes the verdict back, resumes; the guest carries the verdict to a 2nd VMMCALL (echo). The
       guest authored the OK case (family=2, ..., seal_mode=0) -> verdict 0. */
    {
        uint64_t in[6] = {0}, out[5] = {0}; DWORD ret = 0;
        if (!DeviceIoControl(h, IOCTL_GATE_SELF, in, (DWORD)sizeof in, out, (DWORD)sizeof out, &ret, NULL)) {
            printf("  [gate-self] DeviceIoControl FAILED (err=%lu)\n", GetLastError()); fail++;
        } else {
            uint64_t exitcode=out[0], verdict=out[1], echoed=out[2], fam=out[3], phys=out[4];
            printf("  [gate-self] guest-authored family=%llu  EXITCODE=0x%llx  verdict=%llu  echoed=%llu  region_phys=0x%llx\n",
                   (unsigned long long)fam, (unsigned long long)exitcode, (unsigned long long)verdict,
                   (unsigned long long)echoed, (unsigned long long)phys);
            int ok = (exitcode == 0x81ull) && (fam == 2ull) && (verdict == 0ull) && (echoed == verdict);
            if (ok) printf("    => PASS: the GUEST authored its cycle request (family=2, the OK case); the host read it,\n"
                           "             gated it (verdict OK), and the guest carried the verdict back. Guest = full participant.\n");
            else { printf("    => FAIL: expected guest-authored family=2, verdict=0, echoed==verdict\n"); fail++; }
        }
    }

    CloseHandle(h);
    if (fail) printf("\nRESULT: %d failing step(s)\n", fail);
    else      printf("\nRESULT: floor #19a..I4 + [E7] + I3-iii PROVEN -- the full Ring -1 ladder, fault-as-data VMCB\n"
                     "        forensics, and a guest that AUTHORS its own gated request -- all in Ring 0/-1 of live Windows.\n");
    return fail;
}
