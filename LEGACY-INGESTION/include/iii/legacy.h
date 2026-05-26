/* III LEGACY-INGESTION — umbrella API.
 * Items 33-46. Full NIH; depends only on libiii_lex (sha256) and libc.
 */
#ifndef III_LEGACY_H
#define III_LEGACY_H

#include <stdint.h>
#include <stddef.h>
#include "iii/elf.h"
#include "iii/pe.h"
#include "iii/macho.h"
#include "iii/coff.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ===== Format / OS / ABI / Architecture enums ===== */

typedef enum iii_legacy_format {
    III_LF_UNKNOWN = 0,
    III_LF_ELF,
    III_LF_PE,
    III_LF_MACHO,
    III_LF_MACHO_FAT,
    III_LF_COFF,
    III_LF_RAW
} iii_legacy_format_t;

typedef enum iii_legacy_arch {
    III_LA_UNKNOWN = 0,
    III_LA_X86,
    III_LA_X86_64,
    III_LA_ARM,
    III_LA_ARM64,
    III_LA_RISCV,
    III_LA_POWERPC
} iii_legacy_arch_t;

typedef enum iii_legacy_abi {
    III_LABI_UNKNOWN = 0,
    III_LABI_SYSV_ELF,
    III_LABI_WINDOWS_X64,
    III_LABI_WINDOWS_X86,
    III_LABI_MACHO_X64,
    III_LABI_MACHO_ARM64,
    III_LABI_COFF_X86
} iii_legacy_abi_t;

typedef enum iii_legacy_os {
    III_LOS_UNKNOWN = 0,
    III_LOS_LINUX,
    III_LOS_WINDOWS,
    III_LOS_MACOS,
    III_LOS_BSD,
    III_LOS_EMBEDDED
} iii_legacy_os_t;

typedef enum iii_legacy_compromise {
    III_LCT_NONE = 0,
    III_LCT_LOW,
    III_LCT_MEDIUM,
    III_LCT_HIGH
} iii_legacy_compromise_t;

/* ===== Status codes ===== */

typedef enum iii_legacy_status {
    III_LS_OK = 0,
    III_LS_TRUNCATED,
    III_LS_BAD_MAGIC,
    III_LS_UNSUPPORTED,
    III_LS_OVERFLOW,
    III_LS_BAD_OFFSET,
    III_LS_BAD_FIELD,
    III_LS_NO_MEMORY,
    III_LS_INVALID
} iii_legacy_status_t;

const char *iii_legacy_status_str(iii_legacy_status_t s);

/* ===== Per-format parsed module ===== */

typedef struct iii_elf_section_info {
    uint32_t name_off;
    uint32_t type;
    uint64_t flags;
    uint64_t addr;
    uint64_t offset;
    uint64_t size;
    char     name[64];
} iii_elf_section_info_t;

typedef struct iii_elf_segment_info {
    uint32_t type;
    uint32_t flags;
    uint64_t offset;
    uint64_t vaddr;
    uint64_t filesz;
    uint64_t memsz;
} iii_elf_segment_info_t;

typedef struct iii_elf_symbol_info {
    uint32_t name_off;
    uint8_t  info;
    uint16_t shndx;
    uint64_t value;
    uint64_t size;
    char     name[64];
} iii_elf_symbol_info_t;

typedef struct iii_elf_module {
    iii_elf64_ehdr_t ehdr;
    uint16_t arch;             /* e_machine */
    uint16_t etype;            /* e_type */
    uint64_t entry;
    uint16_t section_count;
    uint16_t segment_count;
    uint32_t symbol_count;
    uint32_t dyn_count;
    int      exec_stack;       /* PT_GNU_STACK with PF_X */
    int      has_relro;        /* PT_GNU_RELRO present */
    int      has_dynamic;
    iii_elf_section_info_t *sections;
    iii_elf_segment_info_t *segments;
    iii_elf_symbol_info_t  *symbols;
} iii_elf_module_t;

typedef struct iii_pe_section_info {
    char     name[9];
    uint32_t virtual_size;
    uint32_t virtual_address;
    uint32_t size_of_raw_data;
    uint32_t pointer_to_raw_data;
    uint32_t characteristics;
} iii_pe_section_info_t;

typedef struct iii_pe_module {
    iii_pe_dos_header_t dos;
    uint32_t nt_signature;
    iii_pe_file_header_t file;
    int      is_pe32_plus;
    /* opt headers — only one is valid per is_pe32_plus */
    iii_pe_optional_header64_t opt64;
    iii_pe_optional_header32_t opt32;
    uint16_t section_count;
    uint64_t image_base;
    uint64_t entry_point;       /* image_base + AddressOfEntryPoint */
    int      has_authenticode;
    int      has_tls_callbacks;
    int      has_debug;
    iii_pe_section_info_t *sections;
} iii_pe_module_t;

typedef struct iii_macho_section_info {
    char     sectname[17];
    char     segname[17];
    uint64_t addr;
    uint64_t size;
    uint32_t offset;
    uint32_t flags;
} iii_macho_section_info_t;

typedef struct iii_macho_segment_info {
    char     segname[17];
    uint64_t vmaddr;
    uint64_t vmsize;
    uint64_t fileoff;
    uint64_t filesize;
    uint32_t initprot;
    uint32_t maxprot;
    uint32_t nsects;
    uint32_t section_first;     /* index into sections[] */
} iii_macho_segment_info_t;

typedef struct iii_macho_module {
    iii_macho_header64_t hdr;
    int      is_64;
    int      is_fat;
    uint32_t fat_count;
    uint32_t segment_count;
    uint32_t section_count;
    uint32_t symbol_count;
    uint32_t lc_count;          /* total load commands */
    uint64_t entry_offset;      /* LC_MAIN entryoff */
    int      has_code_signature;
    iii_macho_segment_info_t *segments;
    iii_macho_section_info_t *sections;
} iii_macho_module_t;

typedef struct iii_coff_section_info {
    char     name[9];
    uint32_t size_of_raw_data;
    uint32_t pointer_to_raw_data;
    uint32_t characteristics;
} iii_coff_section_info_t;

typedef struct iii_coff_module {
    iii_coff_file_header_t file;
    uint16_t section_count;
    uint32_t symbol_count;
    iii_coff_section_info_t *sections;
} iii_coff_module_t;

typedef struct iii_legacy_module {
    iii_legacy_format_t  format;
    iii_legacy_arch_t    arch;
    iii_legacy_abi_t     abi;
    iii_legacy_os_t      os;
    iii_legacy_compromise_t compromise;
    uint8_t              sha256[32];
    size_t               image_size;
    union {
        iii_elf_module_t  elf;
        iii_pe_module_t   pe;
        iii_macho_module_t macho;
        iii_coff_module_t coff;
    } u;
} iii_legacy_module_t;

/* ===== Canonical normalized IR (cross-format) ===== */

typedef struct iii_legacy_canon_section {
    char     name[32];
    uint64_t vaddr;
    uint64_t vsize;
    uint64_t foffset;
    uint64_t fsize;
    uint32_t flags;       /* III_CANON_F_* */
} iii_legacy_canon_section_t;

#define III_CANON_F_READ    0x1
#define III_CANON_F_WRITE   0x2
#define III_CANON_F_EXEC    0x4
#define III_CANON_F_BSS     0x8
#define III_CANON_F_TLS     0x10

typedef struct iii_legacy_canonical {
    iii_legacy_format_t format;
    iii_legacy_arch_t   arch;
    iii_legacy_os_t     os;
    uint64_t            entry_vaddr;
    uint32_t            section_count;
    uint32_t            symbol_count;
    iii_legacy_canon_section_t *sections;
} iii_legacy_canonical_t;

/* ===== Top-level API ===== */

iii_legacy_format_t iii_legacy_detect(const uint8_t *bytes, size_t len);

iii_legacy_status_t iii_legacy_parse_elf  (const uint8_t *b, size_t n, iii_legacy_module_t *out);
iii_legacy_status_t iii_legacy_parse_pe   (const uint8_t *b, size_t n, iii_legacy_module_t *out);
iii_legacy_status_t iii_legacy_parse_macho(const uint8_t *b, size_t n, iii_legacy_module_t *out);
iii_legacy_status_t iii_legacy_parse_coff (const uint8_t *b, size_t n, iii_legacy_module_t *out);

iii_legacy_status_t iii_legacy_parse_auto (const uint8_t *b, size_t n, iii_legacy_module_t *out);

void iii_legacy_module_free(iii_legacy_module_t *m);

iii_legacy_status_t iii_legacy_normalize(const iii_legacy_module_t *m, iii_legacy_canonical_t *out);
void iii_legacy_canonical_free(iii_legacy_canonical_t *c);

/* ===== Syscall translation ===== */

typedef enum iii_legacy_cycle_kind {
    III_CYC_UNKNOWN = 0,
    III_CYC_FS_READ,
    III_CYC_FS_WRITE,
    III_CYC_FS_OPEN,
    III_CYC_FS_CLOSE,
    III_CYC_FS_STAT,
    III_CYC_FS_LSEEK,
    III_CYC_FS_UNLINK,
    III_CYC_FS_MKDIR,
    III_CYC_MEM_ALLOC,
    III_CYC_MEM_FREE,
    III_CYC_MEM_PROTECT,
    III_CYC_PROC_EXIT,
    III_CYC_PROC_FORK,
    III_CYC_PROC_EXEC,
    III_CYC_PROC_WAIT,
    III_CYC_PROC_GETPID,
    III_CYC_NET_SOCKET,
    III_CYC_NET_CONNECT,
    III_CYC_NET_BIND,
    III_CYC_NET_SEND,
    III_CYC_NET_RECV,
    III_CYC_IPC_MSG,
    III_CYC_TIME_NOW,
    III_CYC_UNSUPPORTED
} iii_legacy_cycle_kind_t;

typedef struct iii_legacy_syscall_translated {
    iii_legacy_cycle_kind_t cycle;
    uint64_t                args[6];
    uint32_t                arg_count;
    iii_legacy_compromise_t compromise;
    int                     supported;
    char                    name[32];
} iii_legacy_syscall_translated_t;

iii_legacy_status_t iii_legacy_syscall_translate(
    iii_legacy_os_t os,
    iii_legacy_arch_t arch,
    uint32_t syscall_no,
    const uint64_t args[6],
    iii_legacy_syscall_translated_t *out);

size_t iii_legacy_syscall_table_size(iii_legacy_os_t os, iii_legacy_arch_t arch);

/* ===== Sandbox ===== */

#define III_SANDBOX_MEM_BYTES  (64u * 1024u)   /* per-sandbox flat memory */
#define III_SANDBOX_MAX_FDS    16
#define III_SANDBOX_MAX_WITNESSES 256

typedef struct iii_legacy_witness {
    uint32_t                kind;        /* 1=syscall, 2=section, 3=memory_anom */
    uint32_t                syscall_no;
    uint64_t                args[6];
    uint64_t                ret;
    iii_legacy_cycle_kind_t cycle;
    iii_legacy_compromise_t compromise;
    uint64_t                seq;
} iii_legacy_witness_t;

typedef enum iii_legacy_op {
    III_OP_NOP = 0,
    III_OP_LOAD_IMM,        /* dst = imm */
    III_OP_LOAD_MEM,        /* dst = mem[src] (uint64) */
    III_OP_STORE_MEM,       /* mem[dst] = src */
    III_OP_ADD,             /* dst += src */
    III_OP_SUB,             /* dst -= src */
    III_OP_SYSCALL,         /* invoke syscall_no, args r0..r5 -> r0 */
    III_OP_HALT,            /* stop */
    III_OP_PRIV             /* privileged op — should be rejected */
} iii_legacy_op_t;

typedef struct iii_legacy_insn {
    iii_legacy_op_t op;
    uint8_t         dst;     /* register index 0..7 */
    uint8_t         src;     /* register index 0..7 */
    uint64_t        imm;     /* immediate or syscall_no */
} iii_legacy_insn_t;

typedef enum iii_legacy_sandbox_state {
    III_SS_INIT = 0,
    III_SS_LOADED,
    III_SS_RUNNING,
    III_SS_HALTED,
    III_SS_FAULTED
} iii_legacy_sandbox_state_t;

typedef struct iii_legacy_sandbox {
    iii_legacy_sandbox_state_t state;
    iii_legacy_os_t   os;
    iii_legacy_arch_t arch;
    uint64_t          regs[8];
    uint8_t           memory[III_SANDBOX_MEM_BYTES];
    iii_legacy_insn_t *program;
    size_t            program_len;
    size_t            ip;
    uint64_t          step_count;
    uint64_t          step_limit;
    iii_legacy_witness_t witnesses[III_SANDBOX_MAX_WITNESSES];
    uint32_t          witness_count;
    uint32_t          fault_reason;
    uint64_t          syscall_seq;
} iii_legacy_sandbox_t;

iii_legacy_sandbox_t *iii_legacy_sandbox_create(void);
void                  iii_legacy_sandbox_destroy(iii_legacy_sandbox_t *s);

iii_legacy_status_t iii_legacy_sandbox_load(
    iii_legacy_sandbox_t *s,
    const iii_legacy_canonical_t *canon,
    const iii_legacy_insn_t *program,
    size_t program_len);

/* Single-step. Returns III_LS_OK while still running; III_LS_INVALID on halt/fault. */
iii_legacy_status_t iii_legacy_sandbox_exec_step(iii_legacy_sandbox_t *s);

iii_legacy_status_t iii_legacy_sandbox_run(iii_legacy_sandbox_t *s);

#ifdef __cplusplus
}
#endif
#endif
