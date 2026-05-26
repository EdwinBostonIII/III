/* III LEGACY-INGESTION — sandbox step interpreter (NIH).
 * §6: every privileged op is rejected; every memory access is bounds-checked;
 * every syscall is translated through the syscall layer and witnessed. */
#include "iii/legacy.h"
#include <stdlib.h>
#include <string.h>

#define DEFAULT_STEP_LIMIT 1000000ull

iii_legacy_sandbox_t *iii_legacy_sandbox_create(void) {
    iii_legacy_sandbox_t *s = calloc(1, sizeof(*s));
    if (!s) return NULL;
    s->state      = III_SS_INIT;
    s->step_limit = DEFAULT_STEP_LIMIT;
    return s;
}

void iii_legacy_sandbox_destroy(iii_legacy_sandbox_t *s) {
    if (!s) return;
    free(s->program);
    free(s);
}

iii_legacy_status_t iii_legacy_sandbox_load(
    iii_legacy_sandbox_t *s,
    const iii_legacy_canonical_t *canon,
    const iii_legacy_insn_t *program, size_t program_len)
{
    if (!s || !program) return III_LS_INVALID;
    free(s->program);
    s->program = malloc(program_len * sizeof(*program));
    if (!s->program && program_len) return III_LS_NO_MEMORY;
    memcpy(s->program, program, program_len * sizeof(*program));
    s->program_len   = program_len;
    s->ip            = 0;
    s->step_count    = 0;
    s->witness_count = 0;
    s->syscall_seq   = 0;
    s->fault_reason  = 0;
    memset(s->regs, 0, sizeof(s->regs));
    memset(s->memory, 0, sizeof(s->memory));
    if (canon) {
        s->os   = canon->os;
        s->arch = canon->arch;
    }
    s->state = III_SS_LOADED;
    return III_LS_OK;
}

static void emit_witness(iii_legacy_sandbox_t *s, const iii_legacy_witness_t *w) {
    if (s->witness_count >= III_SANDBOX_MAX_WITNESSES) return;
    s->witnesses[s->witness_count] = *w;
    s->witnesses[s->witness_count].seq = ++s->syscall_seq;
    s->witness_count++;
}

iii_legacy_status_t iii_legacy_sandbox_exec_step(iii_legacy_sandbox_t *s) {
    if (!s) return III_LS_INVALID;
    if (s->state != III_SS_LOADED && s->state != III_SS_RUNNING) return III_LS_INVALID;
    s->state = III_SS_RUNNING;
    if (s->ip >= s->program_len) { s->state = III_SS_HALTED; return III_LS_INVALID; }
    if (s->step_count >= s->step_limit) {
        s->state = III_SS_FAULTED; s->fault_reason = 1; return III_LS_INVALID;
    }
    iii_legacy_insn_t in = s->program[s->ip++];
    s->step_count++;
    if (in.dst >= 8 || in.src >= 8) {
        s->state = III_SS_FAULTED; s->fault_reason = 2; return III_LS_INVALID;
    }
    switch (in.op) {
        case III_OP_NOP: break;
        case III_OP_LOAD_IMM: s->regs[in.dst] = in.imm; break;
        case III_OP_ADD: s->regs[in.dst] += s->regs[in.src]; break;
        case III_OP_SUB: s->regs[in.dst] -= s->regs[in.src]; break;
        case III_OP_LOAD_MEM: {
            uint64_t addr = s->regs[in.src];
            if (addr + 8 > III_SANDBOX_MEM_BYTES) {
                s->state = III_SS_FAULTED; s->fault_reason = 3; return III_LS_INVALID;
            }
            uint64_t v = 0;
            for (int i = 0; i < 8; i++) v |= (uint64_t)s->memory[addr + i] << (i * 8);
            s->regs[in.dst] = v;
            break;
        }
        case III_OP_STORE_MEM: {
            uint64_t addr = s->regs[in.dst];
            uint64_t v    = s->regs[in.src];
            if (addr + 8 > III_SANDBOX_MEM_BYTES) {
                s->state = III_SS_FAULTED; s->fault_reason = 3; return III_LS_INVALID;
            }
            for (int i = 0; i < 8; i++) s->memory[addr + i] = (uint8_t)(v >> (i * 8));
            break;
        }
        case III_OP_SYSCALL: {
            uint64_t args[6];
            for (int i = 0; i < 6; i++) args[i] = s->regs[i];
            iii_legacy_syscall_translated_t t;
            iii_legacy_status_t st = iii_legacy_syscall_translate(
                s->os, s->arch, (uint32_t)in.imm, args, &t);
            iii_legacy_witness_t w = {0};
            w.kind       = 1;
            w.syscall_no = (uint32_t)in.imm;
            for (int i = 0; i < 6; i++) w.args[i] = args[i];
            w.cycle      = t.cycle;
            w.compromise = t.compromise;
            if (st == III_LS_OK) {
                /* Sandbox-modelled syscall return: each translated cycle
                 * provides a witnessed return value matching its abstract
                 * effect — getpid yields a fixed sandbox-PID, exit halts
                 * the sandbox with status 0, others yield 0 (success). */
                switch (t.cycle) {
                    case III_CYC_PROC_GETPID: s->regs[0] = 1; break;
                    case III_CYC_PROC_EXIT:   s->state = III_SS_HALTED; s->regs[0] = 0; break;
                    default:                  s->regs[0] = 0; break;
                }
                w.ret = s->regs[0];
            } else {
                /* ENOSYS-style negative return */
                s->regs[0] = (uint64_t)(int64_t)-38;
                w.ret = s->regs[0];
            }
            emit_witness(s, &w);
            if (s->state == III_SS_HALTED) return III_LS_INVALID;
            break;
        }
        case III_OP_HALT:
            s->state = III_SS_HALTED;
            return III_LS_INVALID;
        case III_OP_PRIV: {
            /* Privileged op — sandbox rejects unconditionally per §6.4. */
            iii_legacy_witness_t w = {0};
            w.kind = 3;
            w.compromise = III_LCT_HIGH;
            emit_witness(s, &w);
            s->state = III_SS_FAULTED;
            s->fault_reason = 0xFF;
            return III_LS_INVALID;
        }
        default:
            s->state = III_SS_FAULTED; s->fault_reason = 4; return III_LS_INVALID;
    }
    return III_LS_OK;
}

iii_legacy_status_t iii_legacy_sandbox_run(iii_legacy_sandbox_t *s) {
    if (!s) return III_LS_INVALID;
    while (s->state == III_SS_LOADED || s->state == III_SS_RUNNING) {
        iii_legacy_sandbox_exec_step(s);
    }
    return (s->state == III_SS_HALTED) ? III_LS_OK : III_LS_INVALID;
}
