/* III LEGACY-INGESTION — COFF object on-disk layout (NIH).
 * Per COFF Specification (also subset of PE/COFF).
 */
#ifndef III_COFF_H
#define III_COFF_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Same machine constants as PE */
#define III_COFF_MACHINE_I386   0x014c
#define III_COFF_MACHINE_AMD64  0x8664
#define III_COFF_MACHINE_ARM    0x01c0
#define III_COFF_MACHINE_ARM64  0xaa64

/* Storage classes (subset) */
#define III_COFF_SC_NULL      0
#define III_COFF_SC_EXTERNAL  2
#define III_COFF_SC_STATIC    3
#define III_COFF_SC_LABEL     6
#define III_COFF_SC_FILE      103
#define III_COFF_SC_SECTION   104

#pragma pack(push, 1)

typedef struct iii_coff_file_header {
    uint16_t machine;
    uint16_t number_of_sections;
    uint32_t time_date_stamp;
    uint32_t pointer_to_symbol_table;
    uint32_t number_of_symbols;
    uint16_t size_of_optional_header;
    uint16_t characteristics;
} iii_coff_file_header_t;

typedef struct iii_coff_section_header {
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
} iii_coff_section_header_t;

/* COFF symbol record is 18 bytes; force exact layout */
typedef struct iii_coff_symbol {
    union {
        char      short_name[8];
        struct {
            uint32_t zeroes;
            uint32_t offset;
        } long_name;
    } n;
    uint32_t value;
    int16_t  section_number;
    uint16_t type;
    uint8_t  storage_class;
    uint8_t  number_of_aux_symbols;
} iii_coff_symbol_t;

typedef struct iii_coff_relocation {
    uint32_t virtual_address;
    uint32_t symbol_table_index;
    uint16_t type;
} iii_coff_relocation_t;

#pragma pack(pop)

#ifdef __cplusplus
}
#endif
#endif
