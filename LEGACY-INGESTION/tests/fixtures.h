/* Test fixture builders: synthesize minimal ELF/PE/Mach-O/COFF byte arrays.
 * Each function fills out a heap buffer + length; caller frees buffer. */
#ifndef IIIT_FIXTURES_H
#define IIIT_FIXTURES_H

#include <stdint.h>
#include <stddef.h>

uint8_t *iiit_build_elf64(size_t *out_len);
uint8_t *iiit_build_pe32plus(size_t *out_len);
uint8_t *iiit_build_macho64(size_t *out_len);
uint8_t *iiit_build_macho_fat(size_t *out_len);
uint8_t *iiit_build_coff(size_t *out_len);

#endif
