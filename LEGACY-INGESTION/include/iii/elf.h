/* III LEGACY-INGESTION — ELF64 little-endian on-disk layout (NIH).
 * Per System V ELF gABI v1.4. No libelf, no libbfd.
 */
#ifndef III_ELF_H
#define III_ELF_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* e_ident indices */
#define III_EI_MAG0       0
#define III_EI_MAG1       1
#define III_EI_MAG2       2
#define III_EI_MAG3       3
#define III_EI_CLASS      4
#define III_EI_DATA       5
#define III_EI_VERSION    6
#define III_EI_OSABI      7
#define III_EI_ABIVERSION 8
#define III_EI_NIDENT     16

#define III_ELFMAG0       0x7f
#define III_ELFMAG1       'E'
#define III_ELFMAG2       'L'
#define III_ELFMAG3       'F'

#define III_ELFCLASS32    1
#define III_ELFCLASS64    2
#define III_ELFDATA2LSB   1
#define III_ELFDATA2MSB   2

/* e_type */
#define III_ET_NONE 0
#define III_ET_REL  1
#define III_ET_EXEC 2
#define III_ET_DYN  3
#define III_ET_CORE 4

/* e_machine (subset) */
#define III_EM_NONE     0
#define III_EM_386      3
#define III_EM_ARM      40
#define III_EM_X86_64   62
#define III_EM_AARCH64  183
#define III_EM_RISCV    243

/* sh_type */
#define III_SHT_NULL        0
#define III_SHT_PROGBITS    1
#define III_SHT_SYMTAB      2
#define III_SHT_STRTAB      3
#define III_SHT_RELA        4
#define III_SHT_HASH        5
#define III_SHT_DYNAMIC     6
#define III_SHT_NOTE        7
#define III_SHT_NOBITS      8
#define III_SHT_REL         9
#define III_SHT_SHLIB       10
#define III_SHT_DYNSYM      11
#define III_SHT_INIT_ARRAY  14
#define III_SHT_FINI_ARRAY  15
#define III_SHT_GNU_HASH    0x6ffffff6
#define III_SHT_GNU_VERDEF  0x6ffffffd
#define III_SHT_GNU_VERNEED 0x6ffffffe
#define III_SHT_GNU_VERSYM  0x6fffffff

/* sh_flags */
#define III_SHF_WRITE        0x1
#define III_SHF_ALLOC        0x2
#define III_SHF_EXECINSTR    0x4
#define III_SHF_TLS          0x400

/* p_type */
#define III_PT_NULL          0
#define III_PT_LOAD          1
#define III_PT_DYNAMIC       2
#define III_PT_INTERP        3
#define III_PT_NOTE          4
#define III_PT_SHLIB         5
#define III_PT_PHDR          6
#define III_PT_TLS           7
#define III_PT_GNU_EH_FRAME  0x6474e550
#define III_PT_GNU_STACK     0x6474e551
#define III_PT_GNU_RELRO     0x6474e552

/* p_flags */
#define III_PF_X 0x1
#define III_PF_W 0x2
#define III_PF_R 0x4

/* Dynamic tags */
#define III_DT_NULL     0
#define III_DT_NEEDED   1
#define III_DT_PLTRELSZ 2
#define III_DT_HASH     4
#define III_DT_STRTAB   5
#define III_DT_SYMTAB   6
#define III_DT_RELA     7
#define III_DT_RELASZ   8
#define III_DT_INIT     12
#define III_DT_FINI     13
#define III_DT_INIT_ARRAY 25
#define III_DT_FINI_ARRAY 26

#pragma pack(push, 1)

typedef struct iii_elf64_ehdr {
    uint8_t  e_ident[III_EI_NIDENT];
    uint16_t e_type;
    uint16_t e_machine;
    uint32_t e_version;
    uint64_t e_entry;
    uint64_t e_phoff;
    uint64_t e_shoff;
    uint32_t e_flags;
    uint16_t e_ehsize;
    uint16_t e_phentsize;
    uint16_t e_phnum;
    uint16_t e_shentsize;
    uint16_t e_shnum;
    uint16_t e_shstrndx;
} iii_elf64_ehdr_t;

typedef struct iii_elf64_phdr {
    uint32_t p_type;
    uint32_t p_flags;
    uint64_t p_offset;
    uint64_t p_vaddr;
    uint64_t p_paddr;
    uint64_t p_filesz;
    uint64_t p_memsz;
    uint64_t p_align;
} iii_elf64_phdr_t;

typedef struct iii_elf64_shdr {
    uint32_t sh_name;
    uint32_t sh_type;
    uint64_t sh_flags;
    uint64_t sh_addr;
    uint64_t sh_offset;
    uint64_t sh_size;
    uint32_t sh_link;
    uint32_t sh_info;
    uint64_t sh_addralign;
    uint64_t sh_entsize;
} iii_elf64_shdr_t;

typedef struct iii_elf64_sym {
    uint32_t st_name;
    uint8_t  st_info;
    uint8_t  st_other;
    uint16_t st_shndx;
    uint64_t st_value;
    uint64_t st_size;
} iii_elf64_sym_t;

typedef struct iii_elf64_rela {
    uint64_t r_offset;
    uint64_t r_info;
    int64_t  r_addend;
} iii_elf64_rela_t;

typedef struct iii_elf64_rel {
    uint64_t r_offset;
    uint64_t r_info;
} iii_elf64_rel_t;

typedef struct iii_elf64_dyn {
    int64_t d_tag;
    uint64_t d_un;
} iii_elf64_dyn_t;

#pragma pack(pop)

#define III_ELF64_ST_BIND(i)  ((i) >> 4)
#define III_ELF64_ST_TYPE(i)  ((i) & 0xf)
#define III_ELF64_R_SYM(i)    ((i) >> 32)
#define III_ELF64_R_TYPE(i)   ((i) & 0xffffffff)

#ifdef __cplusplus
}
#endif
#endif
