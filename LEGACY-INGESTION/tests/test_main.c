/* III LEGACY-INGESTION test runner — 30+ tests across all subsystems. */
#include "test.h"
#include "fixtures.h"

int iiit_pass = 0, iiit_fail = 0;

/* ============ Detection ============ */
void run_test_detect(void) {
    IIIT_BEGIN("detect: empty -> UNKNOWN");
    IIIT_ASSERT(iii_legacy_detect(NULL, 0) == III_LF_UNKNOWN, "expected UNKNOWN");
    IIIT_OK();

    IIIT_BEGIN("detect: ELF magic");
    {
        size_t n; uint8_t *b = iiit_build_elf64(&n);
        iii_legacy_format_t f = iii_legacy_detect(b, n);
        free(b);
        IIIT_ASSERT(f == III_LF_ELF, "got %d", f);
    }
    IIIT_OK();

    IIIT_BEGIN("detect: PE magic");
    {
        size_t n; uint8_t *b = iiit_build_pe32plus(&n);
        iii_legacy_format_t f = iii_legacy_detect(b, n);
        free(b);
        IIIT_ASSERT(f == III_LF_PE, "got %d", f);
    }
    IIIT_OK();

    IIIT_BEGIN("detect: Mach-O magic");
    {
        size_t n; uint8_t *b = iiit_build_macho64(&n);
        iii_legacy_format_t f = iii_legacy_detect(b, n);
        free(b);
        IIIT_ASSERT(f == III_LF_MACHO, "got %d", f);
    }
    IIIT_OK();

    IIIT_BEGIN("detect: Mach-O fat magic");
    {
        size_t n; uint8_t *b = iiit_build_macho_fat(&n);
        iii_legacy_format_t f = iii_legacy_detect(b, n);
        free(b);
        IIIT_ASSERT(f == III_LF_MACHO_FAT, "got %d", f);
    }
    IIIT_OK();

    IIIT_BEGIN("detect: COFF machine");
    {
        size_t n; uint8_t *b = iiit_build_coff(&n);
        iii_legacy_format_t f = iii_legacy_detect(b, n);
        free(b);
        IIIT_ASSERT(f == III_LF_COFF, "got %d", f);
    }
    IIIT_OK();

    IIIT_BEGIN("detect: garbage -> RAW");
    {
        uint8_t g[64]; memset(g, 0xCC, sizeof(g));
        iii_legacy_format_t f = iii_legacy_detect(g, sizeof(g));
        IIIT_ASSERT(f == III_LF_RAW || f == III_LF_UNKNOWN, "got %d", f);
    }
    IIIT_OK();

    IIIT_BEGIN("status_str returns non-NULL for all codes");
    for (int i = 0; i <= III_LS_INVALID; i++) {
        IIIT_ASSERT(iii_legacy_status_str((iii_legacy_status_t)i) != NULL, "null at %d", i);
    }
    IIIT_OK();
}

/* ============ ELF ============ */
void run_test_elf(void) {
    size_t n; uint8_t *b = iiit_build_elf64(&n);
    iii_legacy_module_t m;

    IIIT_BEGIN("elf: parse OK");
    iii_legacy_status_t s = iii_legacy_parse_elf(b, n, &m);
    IIIT_ASSERT(s == III_LS_OK, "status=%s", iii_legacy_status_str(s));
    IIIT_OK();

    IIIT_BEGIN("elf: format/arch/abi/os");
    IIIT_ASSERT(m.format == III_LF_ELF, "format");
    IIIT_ASSERT(m.arch   == III_LA_X86_64, "arch=%d", m.arch);
    IIIT_ASSERT(m.abi    == III_LABI_SYSV_ELF, "abi");
    IIIT_ASSERT(m.os     == III_LOS_LINUX, "os");
    IIIT_OK();

    IIIT_BEGIN("elf: entry point");
    IIIT_ASSERT(m.u.elf.entry == 0x401000ull, "entry=%llx", (unsigned long long)m.u.elf.entry);
    IIIT_OK();

    IIIT_BEGIN("elf: section count");
    IIIT_ASSERT(m.u.elf.section_count == 5, "got %u", m.u.elf.section_count);
    IIIT_OK();

    IIIT_BEGIN("elf: segment count");
    IIIT_ASSERT(m.u.elf.segment_count == 3, "got %u", m.u.elf.segment_count);
    IIIT_OK();

    IIIT_BEGIN("elf: symbol count");
    IIIT_ASSERT(m.u.elf.symbol_count == 2, "got %u", m.u.elf.symbol_count);
    IIIT_OK();

    IIIT_BEGIN("elf: section names parsed");
    int found_text = 0, found_symtab = 0;
    for (uint16_t i = 0; i < m.u.elf.section_count; i++) {
        if (strcmp(m.u.elf.sections[i].name, ".text")   == 0) found_text = 1;
        if (strcmp(m.u.elf.sections[i].name, ".symtab") == 0) found_symtab = 1;
    }
    IIIT_ASSERT(found_text && found_symtab, "missing names");
    IIIT_OK();

    IIIT_BEGIN("elf: symbol 'main' present");
    int found_main = 0;
    for (uint32_t i = 0; i < m.u.elf.symbol_count; i++) {
        if (strcmp(m.u.elf.symbols[i].name, "main") == 0) { found_main = 1; break; }
    }
    IIIT_ASSERT(found_main, "no main");
    IIIT_OK();

    IIIT_BEGIN("elf: GNU_RELRO present, exec_stack absent");
    IIIT_ASSERT(m.u.elf.has_relro,  "relro");
    IIIT_ASSERT(m.u.elf.exec_stack == 0, "exec stack should be off");
    IIIT_OK();

    IIIT_BEGIN("elf: bad magic rejected");
    {
        iii_legacy_module_t bm;
        uint8_t bad[64] = {0};
        IIIT_ASSERT(iii_legacy_parse_elf(bad, sizeof(bad), &bm) == III_LS_BAD_MAGIC, "no reject");
    }
    IIIT_OK();

    IIIT_BEGIN("elf: truncated rejected");
    {
        iii_legacy_module_t bm;
        IIIT_ASSERT(iii_legacy_parse_elf(b, 8, &bm) == III_LS_TRUNCATED, "no reject");
    }
    IIIT_OK();

    iii_legacy_module_free(&m);
    free(b);
}

/* ============ PE ============ */
void run_test_pe(void) {
    size_t n; uint8_t *b = iiit_build_pe32plus(&n);
    iii_legacy_module_t m;

    IIIT_BEGIN("pe: parse OK");
    iii_legacy_status_t s = iii_legacy_parse_pe(b, n, &m);
    IIIT_ASSERT(s == III_LS_OK, "status=%s", iii_legacy_status_str(s));
    IIIT_OK();

    IIIT_BEGIN("pe: PE32+ flagged");
    IIIT_ASSERT(m.u.pe.is_pe32_plus, "not pe32plus");
    IIIT_OK();

    IIIT_BEGIN("pe: machine = AMD64");
    IIIT_ASSERT(m.u.pe.file.machine == III_PE_MACHINE_AMD64, "got %x", m.u.pe.file.machine);
    IIIT_ASSERT(m.arch == III_LA_X86_64, "arch");
    IIIT_OK();

    IIIT_BEGIN("pe: section count");
    IIIT_ASSERT(m.u.pe.section_count == 1, "got %u", m.u.pe.section_count);
    IIIT_ASSERT(strcmp(m.u.pe.sections[0].name, ".text") == 0, "name=%s", m.u.pe.sections[0].name);
    IIIT_OK();

    IIIT_BEGIN("pe: entry point computed");
    IIIT_ASSERT(m.u.pe.entry_point == 0x140001000ull, "entry=%llx",
                (unsigned long long)m.u.pe.entry_point);
    IIIT_OK();

    IIIT_BEGIN("pe: no Authenticode -> compromise.medium");
    IIIT_ASSERT(m.compromise == III_LCT_MEDIUM, "got %d", m.compromise);
    IIIT_OK();

    IIIT_BEGIN("pe: bad MZ rejected");
    {
        iii_legacy_module_t bm;
        uint8_t bad[128] = {0};
        IIIT_ASSERT(iii_legacy_parse_pe(bad, sizeof(bad), &bm) == III_LS_BAD_MAGIC, "no reject");
    }
    IIIT_OK();

    iii_legacy_module_free(&m);
    free(b);
}

/* ============ Mach-O ============ */
void run_test_macho(void) {
    size_t n; uint8_t *b = iiit_build_macho64(&n);
    iii_legacy_module_t m;

    IIIT_BEGIN("macho: parse OK");
    iii_legacy_status_t s = iii_legacy_parse_macho(b, n, &m);
    IIIT_ASSERT(s == III_LS_OK, "status=%s", iii_legacy_status_str(s));
    IIIT_OK();

    IIIT_BEGIN("macho: x86_64");
    IIIT_ASSERT(m.arch == III_LA_X86_64, "arch=%d", m.arch);
    IIIT_OK();

    IIIT_BEGIN("macho: 1 segment, 1 section");
    IIIT_ASSERT(m.u.macho.segment_count == 1, "seg=%u", m.u.macho.segment_count);
    IIIT_ASSERT(m.u.macho.section_count == 1, "sec=%u", m.u.macho.section_count);
    IIIT_OK();

    IIIT_BEGIN("macho: __TEXT segment name");
    IIIT_ASSERT(strcmp(m.u.macho.segments[0].segname, "__TEXT") == 0,
                "name=%s", m.u.macho.segments[0].segname);
    IIIT_OK();

    IIIT_BEGIN("macho: LC_MAIN entry offset");
    IIIT_ASSERT(m.u.macho.entry_offset == 0x1000, "entry=%llx",
                (unsigned long long)m.u.macho.entry_offset);
    IIIT_OK();

    IIIT_BEGIN("macho: lc_count=3");
    IIIT_ASSERT(m.u.macho.lc_count == 3, "lc=%u", m.u.macho.lc_count);
    IIIT_OK();

    IIIT_BEGIN("macho: bad magic rejected");
    {
        iii_legacy_module_t bm;
        uint8_t bad[64] = {0};
        IIIT_ASSERT(iii_legacy_parse_macho(bad, sizeof(bad), &bm) == III_LS_BAD_MAGIC, "no reject");
    }
    IIIT_OK();

    iii_legacy_module_free(&m);
    free(b);
}

void run_test_macho_fat(void) {
    size_t n; uint8_t *b = iiit_build_macho_fat(&n);
    iii_legacy_module_t m;

    IIIT_BEGIN("macho-fat: parse OK");
    iii_legacy_status_t s = iii_legacy_parse_macho(b, n, &m);
    IIIT_ASSERT(s == III_LS_OK, "status=%s", iii_legacy_status_str(s));
    IIIT_OK();

    IIIT_BEGIN("macho-fat: format=MACHO_FAT, fat_count=1");
    IIIT_ASSERT(m.format == III_LF_MACHO_FAT, "format=%d", m.format);
    IIIT_ASSERT(m.u.macho.is_fat, "not fat");
    IIIT_ASSERT(m.u.macho.fat_count == 1, "fat_count=%u", m.u.macho.fat_count);
    IIIT_OK();

    iii_legacy_module_free(&m);
    free(b);
}

/* ============ COFF ============ */
void run_test_coff(void) {
    size_t n; uint8_t *b = iiit_build_coff(&n);
    iii_legacy_module_t m;

    IIIT_BEGIN("coff: parse OK");
    iii_legacy_status_t s = iii_legacy_parse_coff(b, n, &m);
    IIIT_ASSERT(s == III_LS_OK, "status=%s", iii_legacy_status_str(s));
    IIIT_OK();

    IIIT_BEGIN("coff: 2 sections, 3 symbols");
    IIIT_ASSERT(m.u.coff.section_count == 2, "sec=%u", m.u.coff.section_count);
    IIIT_ASSERT(m.u.coff.symbol_count  == 3, "sym=%u", m.u.coff.symbol_count);
    IIIT_OK();

    IIIT_BEGIN("coff: section names");
    IIIT_ASSERT(strcmp(m.u.coff.sections[0].name, ".text") == 0, "0=%s", m.u.coff.sections[0].name);
    IIIT_ASSERT(strcmp(m.u.coff.sections[1].name, ".data") == 0, "1=%s", m.u.coff.sections[1].name);
    IIIT_OK();

    IIIT_BEGIN("coff: compromise.medium per spec");
    IIIT_ASSERT(m.compromise == III_LCT_MEDIUM, "got %d", m.compromise);
    IIIT_OK();

    iii_legacy_module_free(&m);
    free(b);
}

/* ============ Normalize ============ */
void run_test_normalize(void) {
    size_t n;
    uint8_t *b;
    iii_legacy_module_t m;
    iii_legacy_canonical_t c;

    IIIT_BEGIN("normalize: ELF -> canonical");
    b = iiit_build_elf64(&n);
    iii_legacy_parse_elf(b, n, &m);
    IIIT_ASSERT(iii_legacy_normalize(&m, &c) == III_LS_OK, "norm");
    IIIT_ASSERT(c.format == III_LF_ELF, "format");
    IIIT_ASSERT(c.entry_vaddr == 0x401000ull, "entry");
    IIIT_ASSERT(c.section_count == 5, "sec");
    iii_legacy_canonical_free(&c);
    iii_legacy_module_free(&m);
    free(b);
    IIIT_OK();

    IIIT_BEGIN("normalize: PE -> canonical");
    b = iiit_build_pe32plus(&n);
    iii_legacy_parse_pe(b, n, &m);
    IIIT_ASSERT(iii_legacy_normalize(&m, &c) == III_LS_OK, "norm");
    IIIT_ASSERT(c.format == III_LF_PE, "format");
    IIIT_ASSERT(c.section_count == 1, "sec");
    IIIT_ASSERT(c.sections[0].flags & III_CANON_F_EXEC, "exec flag");
    iii_legacy_canonical_free(&c);
    iii_legacy_module_free(&m);
    free(b);
    IIIT_OK();

    IIIT_BEGIN("normalize: Mach-O -> canonical");
    b = iiit_build_macho64(&n);
    iii_legacy_parse_macho(b, n, &m);
    IIIT_ASSERT(iii_legacy_normalize(&m, &c) == III_LS_OK, "norm");
    IIIT_ASSERT(c.section_count == 1, "sec");
    iii_legacy_canonical_free(&c);
    iii_legacy_module_free(&m);
    free(b);
    IIIT_OK();
}

/* ============ Syscalls ============ */
void run_test_syscall(void) {
    iii_legacy_syscall_translated_t t;
    uint64_t args[6] = {1, 2, 3, 4, 5, 6};

    IIIT_BEGIN("syscall: linux read(0)");
    iii_legacy_status_t s = iii_legacy_syscall_translate(III_LOS_LINUX, III_LA_X86_64, 0, args, &t);
    IIIT_ASSERT(s == III_LS_OK && t.cycle == III_CYC_FS_READ, "read");
    IIIT_ASSERT(strcmp(t.name, "read") == 0, "name");
    IIIT_OK();

    IIIT_BEGIN("syscall: linux write(1)");
    iii_legacy_syscall_translate(III_LOS_LINUX, III_LA_X86_64, 1, args, &t);
    IIIT_ASSERT(t.cycle == III_CYC_FS_WRITE, "write");
    IIIT_OK();

    IIIT_BEGIN("syscall: linux exit_group(231)");
    iii_legacy_syscall_translate(III_LOS_LINUX, III_LA_X86_64, 231, args, &t);
    IIIT_ASSERT(t.cycle == III_CYC_PROC_EXIT, "exit");
    IIIT_OK();

    IIIT_BEGIN("syscall: windows NtClose");
    iii_legacy_syscall_translate(III_LOS_WINDOWS, III_LA_X86_64, 0x000F, args, &t);
    IIIT_ASSERT(t.cycle == III_CYC_FS_CLOSE, "close");
    IIIT_OK();

    IIIT_BEGIN("syscall: macos open(5)");
    iii_legacy_syscall_translate(III_LOS_MACOS, III_LA_X86_64, 5, args, &t);
    IIIT_ASSERT(t.cycle == III_CYC_FS_OPEN, "open");
    IIIT_OK();

    IIIT_BEGIN("syscall: linux mmap is compromise.low");
    iii_legacy_syscall_translate(III_LOS_LINUX, III_LA_X86_64, 9, args, &t);
    IIIT_ASSERT(t.cycle == III_CYC_MEM_ALLOC && t.compromise == III_LCT_LOW, "mmap");
    IIIT_OK();

    IIIT_BEGIN("syscall: unsupported -> UNSUPPORTED");
    iii_legacy_status_t s2 = iii_legacy_syscall_translate(III_LOS_LINUX, III_LA_X86_64, 9999, args, &t);
    IIIT_ASSERT(s2 == III_LS_UNSUPPORTED && t.supported == 0, "got %d", s2);
    IIIT_OK();

    IIIT_BEGIN("syscall: tables non-empty for all 3 OSes");
    IIIT_ASSERT(iii_legacy_syscall_table_size(III_LOS_LINUX,   III_LA_X86_64) > 10, "linux");
    IIIT_ASSERT(iii_legacy_syscall_table_size(III_LOS_WINDOWS, III_LA_X86_64) > 5, "win");
    IIIT_ASSERT(iii_legacy_syscall_table_size(III_LOS_MACOS,   III_LA_X86_64) > 10, "mac");
    IIIT_OK();
}

/* ============ Sandbox ============ */
void run_test_sandbox(void) {
    IIIT_BEGIN("sandbox: create + halt");
    {
        iii_legacy_sandbox_t *s = iii_legacy_sandbox_create();
        IIIT_ASSERT(s != NULL, "alloc");
        iii_legacy_insn_t prog[] = {
            { III_OP_LOAD_IMM, 0, 0, 42 },
            { III_OP_HALT, 0, 0, 0 }
        };
        iii_legacy_canonical_t canon = {0};
        canon.os = III_LOS_LINUX; canon.arch = III_LA_X86_64;
        IIIT_ASSERT(iii_legacy_sandbox_load(s, &canon, prog, 2) == III_LS_OK, "load");
        iii_legacy_sandbox_run(s);
        IIIT_ASSERT(s->state == III_SS_HALTED, "state");
        IIIT_ASSERT(s->regs[0] == 42, "r0=%llu", (unsigned long long)s->regs[0]);
        iii_legacy_sandbox_destroy(s);
    }
    IIIT_OK();

    IIIT_BEGIN("sandbox: privileged op rejected");
    {
        iii_legacy_sandbox_t *s = iii_legacy_sandbox_create();
        iii_legacy_insn_t prog[] = { { III_OP_PRIV, 0, 0, 0 } };
        iii_legacy_canonical_t canon = {0};
        canon.os = III_LOS_LINUX; canon.arch = III_LA_X86_64;
        iii_legacy_sandbox_load(s, &canon, prog, 1);
        iii_legacy_sandbox_run(s);
        IIIT_ASSERT(s->state == III_SS_FAULTED, "state");
        IIIT_ASSERT(s->fault_reason == 0xFF, "fr");
        IIIT_ASSERT(s->witness_count == 1, "witness");
        iii_legacy_sandbox_destroy(s);
    }
    IIIT_OK();

    IIIT_BEGIN("sandbox: out-of-bounds memory faults");
    {
        iii_legacy_sandbox_t *s = iii_legacy_sandbox_create();
        iii_legacy_insn_t prog[] = {
            { III_OP_LOAD_IMM, 1, 0, III_SANDBOX_MEM_BYTES + 100 },
            { III_OP_LOAD_MEM, 0, 1, 0 }
        };
        iii_legacy_canonical_t canon = {0};
        iii_legacy_sandbox_load(s, &canon, prog, 2);
        iii_legacy_sandbox_run(s);
        IIIT_ASSERT(s->state == III_SS_FAULTED, "state");
        IIIT_ASSERT(s->fault_reason == 3, "fr=%u", s->fault_reason);
        iii_legacy_sandbox_destroy(s);
    }
    IIIT_OK();

    IIIT_BEGIN("sandbox: syscall translates and emits witness");
    {
        iii_legacy_sandbox_t *s = iii_legacy_sandbox_create();
        iii_legacy_insn_t prog[] = {
            { III_OP_SYSCALL, 0, 0, 39 /* getpid */ },
            { III_OP_HALT, 0, 0, 0 }
        };
        iii_legacy_canonical_t canon = {0};
        canon.os = III_LOS_LINUX; canon.arch = III_LA_X86_64;
        iii_legacy_sandbox_load(s, &canon, prog, 2);
        iii_legacy_sandbox_run(s);
        IIIT_ASSERT(s->witness_count == 1, "wc=%u", s->witness_count);
        IIIT_ASSERT(s->witnesses[0].cycle == III_CYC_PROC_GETPID, "cycle");
        IIIT_ASSERT(s->regs[0] == 1, "pid");
        iii_legacy_sandbox_destroy(s);
    }
    IIIT_OK();

    IIIT_BEGIN("sandbox: unsupported syscall returns ENOSYS");
    {
        iii_legacy_sandbox_t *s = iii_legacy_sandbox_create();
        iii_legacy_insn_t prog[] = {
            { III_OP_SYSCALL, 0, 0, 0xDEAD },
            { III_OP_HALT, 0, 0, 0 }
        };
        iii_legacy_canonical_t canon = {0};
        canon.os = III_LOS_LINUX;
        iii_legacy_sandbox_load(s, &canon, prog, 2);
        iii_legacy_sandbox_run(s);
        IIIT_ASSERT((int64_t)s->regs[0] == -38, "ret=%lld", (long long)s->regs[0]);
        iii_legacy_sandbox_destroy(s);
    }
    IIIT_OK();

    IIIT_BEGIN("sandbox: store/load roundtrip");
    {
        iii_legacy_sandbox_t *s = iii_legacy_sandbox_create();
        iii_legacy_insn_t prog[] = {
            { III_OP_LOAD_IMM, 1, 0, 0xCAFEBABEDEADBEEFull }, /* r1 = value */
            { III_OP_LOAD_IMM, 2, 0, 0x100 },                  /* r2 = addr */
            { III_OP_STORE_MEM, 2, 1, 0 },                     /* mem[r2] = r1 */
            { III_OP_LOAD_MEM,  0, 2, 0 },                     /* r0 = mem[r2] */
            { III_OP_HALT, 0, 0, 0 }
        };
        iii_legacy_canonical_t canon = {0};
        iii_legacy_sandbox_load(s, &canon, prog, 5);
        iii_legacy_sandbox_run(s);
        IIIT_ASSERT(s->regs[0] == 0xCAFEBABEDEADBEEFull, "rt");
        iii_legacy_sandbox_destroy(s);
    }
    IIIT_OK();
}

int main(void) {
    printf("=== III LEGACY-INGESTION Test Suite ===\n");
    printf("[group] detect\n");      run_test_detect();
    printf("[group] elf\n");         run_test_elf();
    printf("[group] pe\n");          run_test_pe();
    printf("[group] macho\n");       run_test_macho();
    printf("[group] macho-fat\n");   run_test_macho_fat();
    printf("[group] coff\n");        run_test_coff();
    printf("[group] normalize\n");   run_test_normalize();
    printf("[group] syscall\n");     run_test_syscall();
    printf("[group] sandbox\n");     run_test_sandbox();
    printf("\n=== %d passed, %d failed ===\n", iiit_pass, iiit_fail);
    return iiit_fail == 0 ? 0 : 1;
}
