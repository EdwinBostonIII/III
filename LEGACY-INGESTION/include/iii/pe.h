/* III LEGACY-INGESTION — PE / PE32+ on-disk layout (NIH).
 * Per Microsoft PE/COFF Specification v8.3+. No libpe, no LIEF.
 */
#ifndef III_PE_H
#define III_PE_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define III_PE_DOS_MAGIC 0x5A4D    /* "MZ" */
#define III_PE_NT_MAGIC  0x00004550 /* "PE\0\0" */

#define III_PE_OPT_MAGIC_PE32      0x10b
#define III_PE_OPT_MAGIC_PE32PLUS  0x20b
#define III_PE_OPT_MAGIC_ROM       0x107

/* COFF machine types (subset) */
#define III_PE_MACHINE_UNKNOWN  0x0000
#define III_PE_MACHINE_I386     0x014c
#define III_PE_MACHINE_AMD64    0x8664
#define III_PE_MACHINE_ARM      0x01c0
#define III_PE_MACHINE_ARM64    0xaa64

/* COFF characteristics */
#define III_PE_F_RELOCS_STRIPPED       0x0001
#define III_PE_F_EXECUTABLE_IMAGE      0x0002
#define III_PE_F_LARGE_ADDRESS_AWARE   0x0020
#define III_PE_F_32BIT_MACHINE         0x0100
#define III_PE_F_DLL                   0x2000

/* Section flags (subset) */
#define III_PE_SCN_CNT_CODE             0x00000020
#define III_PE_SCN_CNT_INITIALIZED_DATA 0x00000040
#define III_PE_SCN_CNT_UNINITIALIZED_DATA 0x00000080
#define III_PE_SCN_MEM_DISCARDABLE      0x02000000
#define III_PE_SCN_MEM_EXECUTE          0x20000000
#define III_PE_SCN_MEM_READ             0x40000000
#define III_PE_SCN_MEM_WRITE            0x80000000

#define III_PE_NUM_DIRECTORY_ENTRIES 16

/* Data directory indices */
#define III_PE_DIR_EXPORT       0
#define III_PE_DIR_IMPORT       1
#define III_PE_DIR_RESOURCE     2
#define III_PE_DIR_EXCEPTION    3
#define III_PE_DIR_SECURITY     4
#define III_PE_DIR_BASERELOC    5
#define III_PE_DIR_DEBUG        6
#define III_PE_DIR_TLS          9
#define III_PE_DIR_IAT          12

#pragma pack(push, 1)

typedef struct iii_pe_dos_header {
    uint16_t e_magic;
    uint16_t e_cblp;
    uint16_t e_cp;
    uint16_t e_crlc;
    uint16_t e_cparhdr;
    uint16_t e_minalloc;
    uint16_t e_maxalloc;
    uint16_t e_ss;
    uint16_t e_sp;
    uint16_t e_csum;
    uint16_t e_ip;
    uint16_t e_cs;
    uint16_t e_lfarlc;
    uint16_t e_ovno;
    uint16_t e_res[4];
    uint16_t e_oemid;
    uint16_t e_oeminfo;
    uint16_t e_res2[10];
    uint32_t e_lfanew;
} iii_pe_dos_header_t;

typedef struct iii_pe_file_header {
    uint16_t machine;
    uint16_t number_of_sections;
    uint32_t time_date_stamp;
    uint32_t pointer_to_symbol_table;
    uint32_t number_of_symbols;
    uint16_t size_of_optional_header;
    uint16_t characteristics;
} iii_pe_file_header_t;

typedef struct iii_pe_data_directory {
    uint32_t virtual_address;
    uint32_t size;
} iii_pe_data_directory_t;

typedef struct iii_pe_optional_header64 {
    uint16_t magic;                    /* 0x20b */
    uint8_t  major_linker_version;
    uint8_t  minor_linker_version;
    uint32_t size_of_code;
    uint32_t size_of_initialized_data;
    uint32_t size_of_uninitialized_data;
    uint32_t address_of_entry_point;
    uint32_t base_of_code;
    uint64_t image_base;
    uint32_t section_alignment;
    uint32_t file_alignment;
    uint16_t major_os_version;
    uint16_t minor_os_version;
    uint16_t major_image_version;
    uint16_t minor_image_version;
    uint16_t major_subsystem_version;
    uint16_t minor_subsystem_version;
    uint32_t win32_version_value;
    uint32_t size_of_image;
    uint32_t size_of_headers;
    uint32_t check_sum;
    uint16_t subsystem;
    uint16_t dll_characteristics;
    uint64_t size_of_stack_reserve;
    uint64_t size_of_stack_commit;
    uint64_t size_of_heap_reserve;
    uint64_t size_of_heap_commit;
    uint32_t loader_flags;
    uint32_t number_of_rva_and_sizes;
    iii_pe_data_directory_t data_directory[III_PE_NUM_DIRECTORY_ENTRIES];
} iii_pe_optional_header64_t;

typedef struct iii_pe_optional_header32 {
    uint16_t magic;                    /* 0x10b */
    uint8_t  major_linker_version;
    uint8_t  minor_linker_version;
    uint32_t size_of_code;
    uint32_t size_of_initialized_data;
    uint32_t size_of_uninitialized_data;
    uint32_t address_of_entry_point;
    uint32_t base_of_code;
    uint32_t base_of_data;
    uint32_t image_base;
    uint32_t section_alignment;
    uint32_t file_alignment;
    uint16_t major_os_version;
    uint16_t minor_os_version;
    uint16_t major_image_version;
    uint16_t minor_image_version;
    uint16_t major_subsystem_version;
    uint16_t minor_subsystem_version;
    uint32_t win32_version_value;
    uint32_t size_of_image;
    uint32_t size_of_headers;
    uint32_t check_sum;
    uint16_t subsystem;
    uint16_t dll_characteristics;
    uint32_t size_of_stack_reserve;
    uint32_t size_of_stack_commit;
    uint32_t size_of_heap_reserve;
    uint32_t size_of_heap_commit;
    uint32_t loader_flags;
    uint32_t number_of_rva_and_sizes;
    iii_pe_data_directory_t data_directory[III_PE_NUM_DIRECTORY_ENTRIES];
} iii_pe_optional_header32_t;

typedef struct iii_pe_section_header {
    char     name[8];
    uint32_t virtual_size;
    uint32_t virtual_address;
    uint32_t size_of_raw_data;
    uint32_t pointer_to_raw_data;
    uint32_t pointer_to_relocations;
    uint32_t pointer_to_linenumbers;
    uint16_t number_of_relocations;
    uint16_t number_of_linenumbers;
    uint32_t characteristics;
} iii_pe_section_header_t;

typedef struct iii_pe_import_descriptor {
    uint32_t original_first_thunk;
    uint32_t time_date_stamp;
    uint32_t forwarder_chain;
    uint32_t name_rva;
    uint32_t first_thunk;
} iii_pe_import_descriptor_t;

typedef struct iii_pe_export_directory {
    uint32_t characteristics;
    uint32_t time_date_stamp;
    uint16_t major_version;
    uint16_t minor_version;
    uint32_t name_rva;
    uint32_t base;
    uint32_t number_of_functions;
    uint32_t number_of_names;
    uint32_t address_of_functions;
    uint32_t address_of_names;
    uint32_t address_of_name_ordinals;
} iii_pe_export_directory_t;

#pragma pack(pop)

#ifdef __cplusplus
}
#endif
#endif
