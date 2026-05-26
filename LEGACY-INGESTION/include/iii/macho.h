/* III LEGACY-INGESTION — Mach-O on-disk layout (NIH).
 * Per Apple Mach-O Reference. No macholib, no LIEF.
 */
#ifndef III_MACHO_H
#define III_MACHO_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define III_MACHO_MAGIC32     0xfeedface
#define III_MACHO_CIGAM32     0xcefaedfe
#define III_MACHO_MAGIC64     0xfeedfacf
#define III_MACHO_CIGAM64     0xcffaedfe
#define III_MACHO_FAT_MAGIC   0xcafebabe   /* big-endian on disk */
#define III_MACHO_FAT_CIGAM   0xbebafeca
#define III_MACHO_FAT_MAGIC_64 0xcafebabf
#define III_MACHO_FAT_CIGAM_64 0xbfbafeca

/* CPU types (subset) */
#define III_MACHO_CPU_X86      7
#define III_MACHO_CPU_X86_64   (7 | 0x01000000)
#define III_MACHO_CPU_ARM      12
#define III_MACHO_CPU_ARM64    (12 | 0x01000000)
#define III_MACHO_CPU_POWERPC  18
#define III_MACHO_CPU_POWERPC64 (18 | 0x01000000)

/* File types */
#define III_MACHO_MH_OBJECT       0x1
#define III_MACHO_MH_EXECUTE      0x2
#define III_MACHO_MH_FVMLIB       0x3
#define III_MACHO_MH_CORE         0x4
#define III_MACHO_MH_PRELOAD      0x5
#define III_MACHO_MH_DYLIB        0x6
#define III_MACHO_MH_DYLINKER     0x7
#define III_MACHO_MH_BUNDLE       0x8

/* Load commands (subset) */
#define III_MACHO_LC_REQ_DYLD     0x80000000
#define III_MACHO_LC_SEGMENT      0x1
#define III_MACHO_LC_SYMTAB       0x2
#define III_MACHO_LC_DYSYMTAB     0xb
#define III_MACHO_LC_LOAD_DYLIB   0xc
#define III_MACHO_LC_ID_DYLIB     0xd
#define III_MACHO_LC_LOAD_DYLINKER 0xe
#define III_MACHO_LC_SEGMENT_64   0x19
#define III_MACHO_LC_UUID         0x1b
#define III_MACHO_LC_RPATH        (0x1c | III_MACHO_LC_REQ_DYLD)
#define III_MACHO_LC_CODE_SIGNATURE 0x1d
#define III_MACHO_LC_FUNCTION_STARTS 0x26
#define III_MACHO_LC_MAIN         (0x28 | III_MACHO_LC_REQ_DYLD)

#pragma pack(push, 1)

typedef struct iii_macho_header64 {
    uint32_t magic;
    uint32_t cputype;
    uint32_t cpusubtype;
    uint32_t filetype;
    uint32_t ncmds;
    uint32_t sizeofcmds;
    uint32_t flags;
    uint32_t reserved;
} iii_macho_header64_t;

typedef struct iii_macho_header32 {
    uint32_t magic;
    uint32_t cputype;
    uint32_t cpusubtype;
    uint32_t filetype;
    uint32_t ncmds;
    uint32_t sizeofcmds;
    uint32_t flags;
} iii_macho_header32_t;

typedef struct iii_macho_load_command {
    uint32_t cmd;
    uint32_t cmdsize;
} iii_macho_load_command_t;

typedef struct iii_macho_segment_command_64 {
    uint32_t cmd;            /* LC_SEGMENT_64 */
    uint32_t cmdsize;
    char     segname[16];
    uint64_t vmaddr;
    uint64_t vmsize;
    uint64_t fileoff;
    uint64_t filesize;
    uint32_t maxprot;
    uint32_t initprot;
    uint32_t nsects;
    uint32_t flags;
} iii_macho_segment_command_64_t;

typedef struct iii_macho_section_64 {
    char     sectname[16];
    char     segname[16];
    uint64_t addr;
    uint64_t size;
    uint32_t offset;
    uint32_t align;
    uint32_t reloff;
    uint32_t nreloc;
    uint32_t flags;
    uint32_t reserved1;
    uint32_t reserved2;
    uint32_t reserved3;
} iii_macho_section_64_t;

typedef struct iii_macho_symtab_command {
    uint32_t cmd;            /* LC_SYMTAB */
    uint32_t cmdsize;
    uint32_t symoff;
    uint32_t nsyms;
    uint32_t stroff;
    uint32_t strsize;
} iii_macho_symtab_command_t;

typedef struct iii_macho_dysymtab_command {
    uint32_t cmd;            /* LC_DYSYMTAB */
    uint32_t cmdsize;
    uint32_t ilocalsym;
    uint32_t nlocalsym;
    uint32_t iextdefsym;
    uint32_t nextdefsym;
    uint32_t iundefsym;
    uint32_t nundefsym;
    uint32_t tocoff;
    uint32_t ntoc;
    uint32_t modtaboff;
    uint32_t nmodtab;
    uint32_t extrefsymoff;
    uint32_t nextrefsyms;
    uint32_t indirectsymoff;
    uint32_t nindirectsyms;
    uint32_t extreloff;
    uint32_t nextrel;
    uint32_t locreloff;
    uint32_t nlocrel;
} iii_macho_dysymtab_command_t;

typedef struct iii_macho_nlist_64 {
    uint32_t n_strx;
    uint8_t  n_type;
    uint8_t  n_sect;
    uint16_t n_desc;
    uint64_t n_value;
} iii_macho_nlist_64_t;

typedef struct iii_macho_dylib_command {
    uint32_t cmd;
    uint32_t cmdsize;
    uint32_t name_offset;
    uint32_t timestamp;
    uint32_t current_version;
    uint32_t compatibility_version;
} iii_macho_dylib_command_t;

typedef struct iii_macho_entry_point_command {
    uint32_t cmd;            /* LC_MAIN */
    uint32_t cmdsize;
    uint64_t entryoff;
    uint64_t stacksize;
} iii_macho_entry_point_command_t;

/* Fat binary headers — stored big-endian on disk! */
typedef struct iii_macho_fat_header {
    uint32_t magic;
    uint32_t nfat_arch;
} iii_macho_fat_header_t;

typedef struct iii_macho_fat_arch {
    uint32_t cputype;
    uint32_t cpusubtype;
    uint32_t offset;
    uint32_t size;
    uint32_t align;
} iii_macho_fat_arch_t;

#pragma pack(pop)

#ifdef __cplusplus
}
#endif
#endif
