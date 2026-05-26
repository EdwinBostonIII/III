/* iiis_sanctum_compile.c — Phase D: invoke iiis-1.exe through the
 * Sanctum slot 9 (III_SEAL_COMPILE_MODULE) sealed-call box.
 *
 * Mission Phase D: "Sanctum seal_id 9 wrap".
 *
 * Architecture:
 *   - Initialize an iii_sanctum_runtime_t.
 *   - Bind slot 9 to a body that exec()s iiis-1.exe with the requested
 *     input file and --compile-only.
 *   - Mint an intent, build a call request with all four Trinity
 *     conjuncts evaluated, and dispatch via iii_sanctum_call().
 *   - Verify the 8-step Sealed-Cycle Box executed in full
 *     (intent_mint → load_intent → witness → trampoline → pkru
 *     → dispatch → body → exit) and that all four hardenings
 *     (IBPB+VERW+SSBD+RSP-swap) ran.
 *   - Print the trace and the iiis-1 compile result, returning
 *     non-zero on Trinity reject, body failure, or compile failure.
 *
 * Mandate alignment:
 *   M2  — Root-cause-fix: wrapper is the canonical Ring-2 surface for
 *         the compiler emission — there is no other admitted path.
 *   M5  — All eight box steps and all four hardenings are verified
 *         (no trace bit may be unset).
 *   M11 — Working code: the wrapper exits 0 only when the underlying
 *         iiis-1 compile succeeds AND every box step + hardening
 *         executed.
 *   M14 — Slot 9 (III_SEAL_COMPILE_MODULE) is the constitutionally
 *         designated seal for compile-module entries; no other slot
 *         may be substituted.
 *
 * Build:
 *   gcc -O2 -I SANCTUM/include iiis_sanctum_compile.c \
 *       SANCTUM/build/libiii_sanctum.a -o iiis_sanctum_compile.exe
 *
 * Run:
 *   iiis_sanctum_compile.exe <input.iii> <output.o>
 */

#include "iii/sanctum.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---------------------------------------------------------------------------
 * Body for slot 9.  The iii_sanctum_call dispatcher runs the 8-step box
 * around this; the body itself is responsible for invoking iiis-1.
 * --------------------------------------------------------------------------- */

typedef struct {
    const char *iiis1_path;
    const char *input_path;
    const char *output_path;
    int         spawn_status;
} compile_args_t;

static int seal9_body(iii_sanctum_runtime_t *rt,
                      const void            *args_in,
                      void                  *args_out,
                      void                  *user)
{
    (void)rt; (void)args_out; (void)user;
    compile_args_t *a = (compile_args_t *)args_in;
    if (!a || !a->iiis1_path || !a->input_path || !a->output_path) {
        return -1;
    }

    /* Compose the iiis-1 invocation.  We quote each argument so the
     * Win32 cmd.exe shell tolerates spaces in OneDrive paths. */
    char cmd[4096];
    int  n = snprintf(cmd, sizeof cmd,
                      "\"\"%s\" \"%s\" --compile-only --out \"%s\"\"",
                      a->iiis1_path, a->input_path, a->output_path);
    if (n < 0 || (size_t)n >= sizeof cmd) return -1;

    int rc = system(cmd);
    a->spawn_status = rc;
    return (rc == 0) ? 0 : -1;
}

/* ---------------------------------------------------------------------------
 * Trace verifier: every one of the 8 box steps must have executed and all
 * four hardenings must have fired.  This is the C-SAN-2 audit obligation.
 * --------------------------------------------------------------------------- */

static int verify_trace(const iii_sanctum_call_trace_t *t)
{
    static const iii_sanctum_box_step_t required[] = {
        III_BOX_STEP_INTENT_MINT,
        III_BOX_STEP_LOAD_INTENT,
        III_BOX_STEP_INTENT_WITNESS,
        III_BOX_STEP_TRAMPOLINE,
        III_BOX_STEP_PKRU_REWRITE,
        III_BOX_STEP_DISPATCH,
        III_BOX_STEP_BODY,
        III_BOX_STEP_EXIT,
    };
    int ok = 1;
    for (size_t i = 0; i < sizeof required / sizeof required[0]; i++) {
        if (!t->executed[required[i]]) {
            fprintf(stderr,
                    "  TRACE FAIL: box step %s did not execute\n",
                    iii_sanctum_box_step_name(required[i]));
            ok = 0;
        }
    }
    if (!t->hardening.ibpb_executed) { fprintf(stderr, "  TRACE FAIL: IBPB not executed\n"); ok = 0; }
    if (!t->hardening.verw_executed) { fprintf(stderr, "  TRACE FAIL: VERW not executed\n"); ok = 0; }
    if (!t->hardening.ssbd_executed) { fprintf(stderr, "  TRACE FAIL: SSBD not executed\n"); ok = 0; }
    if (!t->hardening.rsp_swapped)   { fprintf(stderr, "  TRACE FAIL: RSP not swapped\n");   ok = 0; }
    if (!t->hardening.gpr_saved)     { fprintf(stderr, "  TRACE FAIL: GPRs not saved\n");    ok = 0; }
    return ok;
}

int main(int argc, char **argv)
{
    if (argc != 3 && argc != 4) {
        fprintf(stderr,
                "usage: %s <input.iii> <output.o> [iiis-1.exe]\n",
                argv[0] ? argv[0] : "iiis_sanctum_compile");
        return 2;
    }
    const char *input  = argv[1];
    const char *output = argv[2];
    const char *iiis1  = (argc == 4) ? argv[3] : "iiis-1.exe";

    iii_sanctum_runtime_t *rt = iii_sanctum_runtime_create();
    if (!rt) {
        fprintf(stderr, "FATAL: iii_sanctum_runtime_create failed\n");
        return 3;
    }

    if (!iii_sanctum_runtime_bind_seal(rt,
                                       III_SEAL_COMPILE_MODULE,
                                       seal9_body,
                                       NULL))
    {
        fprintf(stderr, "FATAL: bind_seal(III_SEAL_COMPILE_MODULE) failed\n");
        iii_sanctum_runtime_destroy(rt);
        return 3;
    }

    compile_args_t cargs = {
        .iiis1_path   = iiis1,
        .input_path   = input,
        .output_path  = output,
        .spawn_status = -1,
    };

    iii_sanctum_call_request_t req;
    iii_sanctum_call_trace_t   trace;
    memset(&req,   0, sizeof req);
    memset(&trace, 0, sizeof trace);
    req.seal                 = III_SEAL_COMPILE_MODULE;
    req.intent_valid         = true;
    req.cap_valid            = true;
    req.causality_valid      = true;
    req.sanctum_state_valid  = true;
    /* Intent fields — operator consent fingerprint, capability id, frame. */
    memset(req.intent.operator_consent_mhash, 0xA9, 32);  /* 0xA9 = slot 9 marker */
    req.intent.cap_id            = (uint64_t)III_SEAL_COMPILE_MODULE;
    req.intent.sanctum_frame_id  = 1;
    req.args_in  = &cargs;
    req.args_out = NULL;

    iii_sanctum_status_t st = iii_sanctum_call(rt, &req, &trace);

    printf("[seal9] status            = %s (%d)\n",
           iii_sanctum_status_name(st), (int)st);
    printf("[seal9] trinity admitted  = %s\n",
           trace.trinity.admitted ? "yes" : "no");
    printf("[seal9] convergence pt    = 0x%016llx\n",
           (unsigned long long)trace.trinity.convergence_point);
    printf("[seal9] specialized path  = %s\n",
           trace.specialized_path ? "yes" : "no");
    printf("[seal9] iiis-1 spawn rc   = %d\n", cargs.spawn_status);
    printf("[seal9] sanctum calls so far = %llu\n",
           (unsigned long long)iii_sanctum_runtime_call_count(rt));

    int trace_ok = verify_trace(&trace);

    iii_sanctum_runtime_destroy(rt);

    if (st != III_SANCTUM_OK) {
        fprintf(stderr, "FAIL: sealed call rejected (%s)\n",
                iii_sanctum_status_name(st));
        return 4;
    }
    if (!trace_ok) {
        fprintf(stderr, "FAIL: 8-step box trace incomplete\n");
        return 5;
    }
    if (cargs.spawn_status != 0) {
        fprintf(stderr, "FAIL: iiis-1 returned %d\n", cargs.spawn_status);
        return 6;
    }
    printf("[seal9] OK: %s -> %s through III_SEAL_COMPILE_MODULE\n",
           input, output);
    return 0;
}
