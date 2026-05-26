/* III LEGACY-INGESTION — ELF64 LE parser (NIH).
 * Per System V ELF gABI v1.4. */
#include "iii/legacy.h"
#include "internal.h"
#include "iii/sha256.h"
#include <stdlib.h>
#include <string.h>

static iii_legacy_arch_t map_elf_machine(uint16_t m) {
    switch (m) {
        case III_EM_386:     return III_LA_X86;
        case III_EM_X86_64:  return III_LA_X86_64;
        case III_EM_ARM:     return III_LA_ARM;
        case III_EM_AARCH64: return III_LA_ARM64;
        case III_EM_RISCV:   return III_LA_RISCV;
        default:             return III_LA_UNKNOWN;
    }
}

static iii_legacy_status_t read_ehdr(const uint8_t *b, size_t n, iii_elf64_ehdr_t *e) {
    if (n < sizeof(*e)) return III_LS_TRUNCATED;
    if (b[III_EI_MAG0] != III_ELFMAG0 || b[III_EI_MAG1] != III_ELFMAG1 ||
        b[III_EI_MAG2] != III_ELFMAG2 || b[III_EI_MAG3] != III_ELFMAG3) {
        return III_LS_BAD_MAGIC;
    }
    if (b[III_EI_CLASS] != III_ELFCLASS64) return III_LS_UNSUPPORTED;
    if (b[III_EI_DATA]  != III_ELFDATA2LSB) return III_LS_UNSUPPORTED;

    memcpy(e->e_ident, b, III_EI_NIDENT);
    iii_le_read_u16(b, n, 16, &e->e_type);
    iii_le_read_u16(b, n, 18, &e->e_machine);
    iii_le_read_u32(b, n, 20, &e->e_version);
    iii_le_read_u64(b, n, 24, &e->e_entry);
    iii_le_read_u64(b, n, 32, &e->e_phoff);
    iii_le_read_u64(b, n, 40, &e->e_shoff);
    iii_le_read_u32(b, n, 48, &e->e_flags);
    iii_le_read_u16(b, n, 52, &e->e_ehsize);
    iii_le_read_u16(b, n, 54, &e->e_phentsize);
    iii_le_read_u16(b, n, 56, &e->e_phnum);
    iii_le_read_u16(b, n, 58, &e->e_shentsize);
    iii_le_read_u16(b, n, 60, &e->e_shnum);
    iii_le_read_u16(b, n, 62, &e->e_shstrndx);
    return III_LS_OK;
}

iii_legacy_status_t iii_legacy_parse_elf(const uint8_t *b, size_t n,
                                         iii_legacy_module_t *out) {
    memset(out, 0, sizeof(*out));
    iii_elf_module_t *em = &out->u.elf;
    iii_legacy_status_t s = read_ehdr(b, n, &em->ehdr);
    if (s != III_LS_OK) return s;

    out->format = III_LF_ELF;
    out->arch   = map_elf_machine(em->ehdr.e_machine);
    out->abi    = III_LABI_SYSV_ELF;
    out->os     = III_LOS_LINUX;
    out->image_size = n;
    iii_sha256(b, n, out->sha256);

    em->arch  = em->ehdr.e_machine;
    em->etype = em->ehdr.e_type;
    em->entry = em->ehdr.e_entry;

    /* Program headers */
    if (em->ehdr.e_phnum && em->ehdr.e_phentsize >= 56 && em->ehdr.e_phoff < n) {
        size_t total = (size_t)em->ehdr.e_phnum * em->ehdr.e_phentsize;
        if (em->ehdr.e_phoff + total > n) return III_LS_BAD_OFFSET;
        em->segments = calloc(em->ehdr.e_phnum, sizeof(*em->segments));
        if (!em->segments) return III_LS_NO_MEMORY;
        for (uint16_t i = 0; i < em->ehdr.e_phnum; i++) {
            size_t off = em->ehdr.e_phoff + (size_t)i * em->ehdr.e_phentsize;
            iii_elf_segment_info_t *p = &em->segments[i];
            iii_le_read_u32(b, n, off + 0, &p->type);
            iii_le_read_u32(b, n, off + 4, &p->flags);
            iii_le_read_u64(b, n, off + 8, &p->offset);
            iii_le_read_u64(b, n, off + 16, &p->vaddr);
            iii_le_read_u64(b, n, off + 32, &p->filesz);
            iii_le_read_u64(b, n, off + 40, &p->memsz);
            if (p->type == III_PT_GNU_STACK && (p->flags & III_PF_X)) em->exec_stack = 1;
            if (p->type == III_PT_GNU_RELRO) em->has_relro = 1;
            if (p->type == III_PT_DYNAMIC)  em->has_dynamic = 1;
        }
        em->segment_count = em->ehdr.e_phnum;
    }

    /* Section headers */
    size_t shstr_off = 0, shstr_size = 0;
    if (em->ehdr.e_shnum && em->ehdr.e_shentsize >= 64 && em->ehdr.e_shoff < n) {
        size_t total = (size_t)em->ehdr.e_shnum * em->ehdr.e_shentsize;
        if (em->ehdr.e_shoff + total > n) return III_LS_BAD_OFFSET;
        em->sections = calloc(em->ehdr.e_shnum, sizeof(*em->sections));
        if (!em->sections) return III_LS_NO_MEMORY;
        /* First, locate section name string table */
        if (em->ehdr.e_shstrndx < em->ehdr.e_shnum) {
            size_t off = em->ehdr.e_shoff + (size_t)em->ehdr.e_shstrndx * em->ehdr.e_shentsize;
            uint64_t so, sz;
            iii_le_read_u64(b, n, off + 24, &so);
            iii_le_read_u64(b, n, off + 32, &sz);
            if (so < n && so + sz <= n) { shstr_off = (size_t)so; shstr_size = (size_t)sz; }
        }
        size_t symtab_off = 0, symtab_size = 0, symtab_entsize = 0;
        size_t strtab_off = 0, strtab_size = 0;
        for (uint16_t i = 0; i < em->ehdr.e_shnum; i++) {
            size_t off = em->ehdr.e_shoff + (size_t)i * em->ehdr.e_shentsize;
            iii_elf_section_info_t *sec = &em->sections[i];
            iii_le_read_u32(b, n, off + 0, &sec->name_off);
            iii_le_read_u32(b, n, off + 4, &sec->type);
            iii_le_read_u64(b, n, off + 8, &sec->flags);
            iii_le_read_u64(b, n, off + 16, &sec->addr);
            iii_le_read_u64(b, n, off + 24, &sec->offset);
            iii_le_read_u64(b, n, off + 32, &sec->size);
            if (shstr_size && sec->name_off < shstr_size) {
                iii_copy_cstr(sec->name, sizeof(sec->name), b, n, shstr_off + sec->name_off);
            }
            if (sec->type == III_SHT_SYMTAB) {
                symtab_off = (size_t)sec->offset;
                symtab_size = (size_t)sec->size;
                uint64_t es; iii_le_read_u64(b, n, off + 56, &es);
                symtab_entsize = (size_t)es;
                /* sh_link = strtab index */
                uint32_t link; iii_le_read_u32(b, n, off + 40, &link);
                if (link < em->ehdr.e_shnum) {
                    size_t loff = em->ehdr.e_shoff + (size_t)link * em->ehdr.e_shentsize;
                    uint64_t so, sz;
                    iii_le_read_u64(b, n, loff + 24, &so);
                    iii_le_read_u64(b, n, loff + 32, &sz);
                    strtab_off = (size_t)so; strtab_size = (size_t)sz;
                }
            }
            if (sec->type == III_SHT_DYNAMIC) em->has_dynamic = 1;
        }
        em->section_count = em->ehdr.e_shnum;

        if (symtab_off && symtab_entsize >= 24 && symtab_size &&
            symtab_off + symtab_size <= n) {
            uint32_t nsyms = (uint32_t)(symtab_size / symtab_entsize);
            em->symbols = calloc(nsyms ? nsyms : 1, sizeof(*em->symbols));
            if (!em->symbols) return III_LS_NO_MEMORY;
            for (uint32_t i = 0; i < nsyms; i++) {
                size_t off = symtab_off + (size_t)i * symtab_entsize;
                iii_elf_symbol_info_t *sy = &em->symbols[i];
                iii_le_read_u32(b, n, off + 0, &sy->name_off);
                iii_le_read_u8 (b, n, off + 4, &sy->info);
                uint8_t other; iii_le_read_u8(b, n, off + 5, &other); (void)other;
                iii_le_read_u16(b, n, off + 6, &sy->shndx);
                iii_le_read_u64(b, n, off + 8, &sy->value);
                iii_le_read_u64(b, n, off + 16, &sy->size);
                if (strtab_size && sy->name_off < strtab_size) {
                    iii_copy_cstr(sy->name, sizeof(sy->name), b, n, strtab_off + sy->name_off);
                }
            }
            em->symbol_count = nsyms;
        }
    }

    /* Compromise classification */
    out->compromise = III_LCT_NONE;
    if (em->exec_stack) out->compromise = III_LCT_MEDIUM;
    else if (!em->has_relro && em->etype == III_ET_EXEC) out->compromise = III_LCT_LOW;

    return III_LS_OK;
}
