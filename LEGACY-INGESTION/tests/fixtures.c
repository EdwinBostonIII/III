/* Hand-built minimal binary fixtures for the parser tests.
 * No external assembler; everything emitted as raw bytes. */
#include "fixtures.h"
#include "iii/legacy.h"
#include <stdlib.h>
#include <string.h>

static void w8 (uint8_t *p, size_t o, uint8_t v) { p[o] = v; }
static void w16(uint8_t *p, size_t o, uint16_t v) { p[o]=v; p[o+1]=v>>8; }
static void w32(uint8_t *p, size_t o, uint32_t v) {
    p[o]=v; p[o+1]=v>>8; p[o+2]=v>>16; p[o+3]=v>>24;
}
static void w64(uint8_t *p, size_t o, uint64_t v) {
    for (int i = 0; i < 8; i++) p[o+i] = (uint8_t)(v >> (i*8));
}
static void w32be(uint8_t *p, size_t o, uint32_t v) {
    p[o]=v>>24; p[o+1]=v>>16; p[o+2]=v>>8; p[o+3]=v;
}

/* ===== ELF64 ===== */
uint8_t *iiit_build_elf64(size_t *out_len) {
    /* Layout:
     *   [0..64)        Ehdr
     *   [64..184)      3 program headers (56 each)
     *   [184..504)     5 section headers (64 each)
     *   [504..540)     .shstrtab contents
     *   [540..570)     .strtab contents
     *   [570..618)     .symtab contents (2 syms * 24)
     */
    size_t sz = 1024;
    uint8_t *p = calloc(1, sz);
    /* Ehdr */
    p[0]=0x7f; p[1]='E'; p[2]='L'; p[3]='F';
    p[4]=2;    /* ELFCLASS64 */
    p[5]=1;    /* ELFDATA2LSB */
    p[6]=1;    /* version */
    p[7]=0;    /* SYSV osabi */
    w16(p, 16, III_ET_EXEC);
    w16(p, 18, III_EM_X86_64);
    w32(p, 20, 1);
    w64(p, 24, 0x401000ull);  /* e_entry */
    w64(p, 32, 64);            /* e_phoff */
    w64(p, 40, 184);           /* e_shoff */
    w32(p, 48, 0);             /* e_flags */
    w16(p, 52, 64);            /* e_ehsize */
    w16(p, 54, 56);            /* e_phentsize */
    w16(p, 56, 3);             /* e_phnum */
    w16(p, 58, 64);            /* e_shentsize */
    w16(p, 60, 5);             /* e_shnum */
    w16(p, 62, 1);             /* e_shstrndx -> section[1] */

    /* Program headers */
    /* PT_LOAD (R+X) */
    w32(p, 64+0, III_PT_LOAD);
    w32(p, 64+4, III_PF_R | III_PF_X);
    w64(p, 64+8, 0);
    w64(p, 64+16, 0x400000ull);
    w64(p, 64+32, 0x100);
    w64(p, 64+40, 0x100);
    /* PT_GNU_RELRO */
    w32(p, 120+0, III_PT_GNU_RELRO);
    w32(p, 120+4, III_PF_R);
    /* PT_GNU_STACK (no exec) */
    w32(p, 176+0-56*0, III_PT_GNU_STACK); /* off 176 */
    {
        size_t off = 64 + 56*2;
        w32(p, off+0, III_PT_GNU_STACK);
        w32(p, off+4, III_PF_R | III_PF_W);
    }

    /* Section headers - 5 entries, 64 bytes each, starting at 184 */
    /* shstrtab content at 504 */
    const char *names = "\0.shstrtab\0.strtab\0.symtab\0.text\0";
    size_t names_len = 1 + 10 + 8 + 8 + 6;  /* 33 with leading nul */
    memcpy(p + 504, names, names_len);
    /* strtab content at 540 */
    const char *strs = "\0main\0printf\0";
    size_t strs_len = 1 + 5 + 7;  /* 13 */
    memcpy(p + 540, strs, strs_len);

    /* SHN_UNDEF section [0] */
    /* default zero */

    /* .shstrtab section [1] */
    {
        size_t b = 184 + 64*1;
        w32(p, b+0,  1);            /* name -> ".shstrtab" */
        w32(p, b+4,  III_SHT_STRTAB);
        w64(p, b+8,  0);
        w64(p, b+16, 0);
        w64(p, b+24, 504);
        w64(p, b+32, names_len);
        w64(p, b+56, 1);
    }
    /* .strtab section [2] */
    {
        size_t b = 184 + 64*2;
        w32(p, b+0,  11);           /* name -> ".strtab" */
        w32(p, b+4,  III_SHT_STRTAB);
        w64(p, b+24, 540);
        w64(p, b+32, strs_len);
        w64(p, b+56, 1);
    }
    /* .symtab section [3] */
    {
        size_t b = 184 + 64*3;
        w32(p, b+0,  19);           /* name -> ".symtab" */
        w32(p, b+4,  III_SHT_SYMTAB);
        w64(p, b+24, 570);
        w64(p, b+32, 24*2);         /* two symbols */
        w32(p, b+40, 2);            /* sh_link -> .strtab idx */
        w64(p, b+56, 24);           /* sh_entsize */
    }
    /* .text section [4] */
    {
        size_t b = 184 + 64*4;
        w32(p, b+0,  27);           /* name -> ".text" */
        w32(p, b+4,  III_SHT_PROGBITS);
        w64(p, b+8,  III_SHF_ALLOC | III_SHF_EXECINSTR);
        w64(p, b+16, 0x401000ull);
        w64(p, b+24, 0);
        w64(p, b+32, 0x10);
    }

    /* Symbols at 570: sym[0]=undef(zero), sym[1]=main */
    /* sym[0] zero-initialized */
    /* sym[1] */
    w32(p, 570+24, 1);     /* st_name -> "main" at strtab+1 */
    w8 (p, 570+24+4, 0x12);/* STB_GLOBAL << 4 | STT_FUNC */
    w16(p, 570+24+6, 4);   /* shndx -> .text */
    w64(p, 570+24+8, 0x401000ull);
    w64(p, 570+24+16, 0x10);

    *out_len = 1024;
    return p;
}

/* ===== PE32+ ===== */
uint8_t *iiit_build_pe32plus(size_t *out_len) {
    /* Layout:
     *   [0..64)         DOS header (only e_lfanew matters)
     *   [64..0x80)      DOS stub padding
     *   [0x80..0x84)    PE\0\0
     *   [0x84..0x98)    file header (20 bytes)
     *   [0x98..0x148)   optional header64 (240 bytes incl 16 dirs)
     *   [0x148..0x170)  one section header (40 bytes)
     *
     * NOTE: optional header occupies [0x98 .. 0x98+240) = [0x98..0x188).
     * The section header therefore starts at 0x188.
     */
    size_t sz = 1024;
    uint8_t *p = calloc(1, sz);
    p[0]='M'; p[1]='Z';
    w32(p, 60, 0x80);           /* e_lfanew */
    w32(p, 0x80, 0x00004550);   /* PE\0\0 */
    /* file header */
    size_t fh = 0x84;
    w16(p, fh+0,  III_PE_MACHINE_AMD64);
    w16(p, fh+2,  1);           /* number_of_sections */
    w32(p, fh+4,  0);           /* timestamp */
    w16(p, fh+16, 240);         /* size_of_optional_header */
    w16(p, fh+18, III_PE_F_EXECUTABLE_IMAGE);
    /* optional header */
    size_t oh = 0x98;
    w16(p, oh+0,  III_PE_OPT_MAGIC_PE32PLUS);
    w32(p, oh+4,  0x100);       /* size_of_code */
    w32(p, oh+16, 0x1000);      /* address_of_entry_point (RVA) */
    w64(p, oh+24, 0x140000000ull); /* image_base */
    w32(p, oh+56, 0x2000);      /* size_of_image */
    w32(p, oh+60, 0x400);       /* size_of_headers */
    w16(p, oh+68, 3);           /* subsystem = console */
    w32(p, oh+108, 16);         /* number_of_rva_and_sizes */
    /* leave data directories zero (no Authenticode -> compromise.medium per spec) */
    /* one section: at end of optional header (0x98 + 240 = 0x188) */
    size_t sh = 0x188;
    memcpy(p + sh, ".text\0\0\0", 8);
    w32(p, sh+8,  0x100);
    w32(p, sh+12, 0x1000);
    w32(p, sh+16, 0x100);
    w32(p, sh+20, 0x400);
    w32(p, sh+36, III_PE_SCN_CNT_CODE | III_PE_SCN_MEM_EXECUTE | III_PE_SCN_MEM_READ);

    *out_len = sz;
    return p;
}

/* ===== Mach-O 64 ===== */
uint8_t *iiit_build_macho64(size_t *out_len) {
    /* Layout:
     *   [0..32)            mach_header_64
     *   [32..32+72+80)     LC_SEGMENT_64 (__TEXT) + 1 section_64 (80 bytes)  -> cmdsize 152
     *   [184..208)         LC_SYMTAB (24 bytes)
     *   [208..232)         LC_MAIN  (24 bytes)
     */
    size_t sz = 1024;
    uint8_t *p = calloc(1, sz);
    w32(p, 0,  III_MACHO_MAGIC64);
    w32(p, 4,  III_MACHO_CPU_X86_64);
    w32(p, 8,  3);                 /* cpusubtype */
    w32(p, 12, III_MACHO_MH_EXECUTE);
    w32(p, 16, 3);                 /* ncmds */
    w32(p, 20, 152 + 24 + 24);     /* sizeofcmds */
    w32(p, 24, 0);                 /* flags */
    w32(p, 28, 0);                 /* reserved */

    size_t off = 32;
    /* LC_SEGMENT_64 __TEXT */
    w32(p, off+0,  III_MACHO_LC_SEGMENT_64);
    w32(p, off+4,  152);
    memcpy(p + off + 8, "__TEXT", 6);
    w64(p, off+24, 0x100000000ull); /* vmaddr */
    w64(p, off+32, 0x1000);
    w64(p, off+40, 0);
    w64(p, off+48, 0x1000);
    w32(p, off+56, 7);  /* maxprot R+W+X */
    w32(p, off+60, 5);  /* initprot R+X */
    w32(p, off+64, 1);  /* nsects */
    w32(p, off+68, 0);
    /* one section */
    size_t soff = off + 72;
    memcpy(p + soff + 0,  "__text", 6);
    memcpy(p + soff + 16, "__TEXT", 6);
    w64(p, soff + 32, 0x100000000ull);
    w64(p, soff + 40, 0x100);
    w32(p, soff + 48, 0);
    w32(p, soff + 64, 0);
    off += 152;

    /* LC_SYMTAB */
    w32(p, off+0,  III_MACHO_LC_SYMTAB);
    w32(p, off+4,  24);
    w32(p, off+8,  0);
    w32(p, off+12, 2);   /* nsyms */
    w32(p, off+16, 0);
    w32(p, off+20, 0);
    off += 24;

    /* LC_MAIN */
    w32(p, off+0,  III_MACHO_LC_MAIN);
    w32(p, off+4,  24);
    w64(p, off+8,  0x1000); /* entry offset */
    w64(p, off+16, 0);
    off += 24;

    *out_len = sz;
    return p;
}

/* ===== Mach-O fat ===== */
uint8_t *iiit_build_macho_fat(size_t *out_len) {
    size_t thin_len;
    uint8_t *thin = iiit_build_macho64(&thin_len);
    /* Construct a fat header with one slice pointing into a buffer that contains the thin. */
    size_t header = 8 + 20;          /* fat_header + 1 fat_arch */
    size_t pad    = 64 - (header % 64);
    size_t slice_off = header + pad;
    size_t total = slice_off + thin_len;
    uint8_t *p = calloc(1, total);
    w32be(p, 0, III_MACHO_FAT_MAGIC);
    w32be(p, 4, 1);                  /* nfat_arch */
    w32be(p, 8,  III_MACHO_CPU_X86_64);
    w32be(p, 12, 3);
    w32be(p, 16, (uint32_t)slice_off);
    w32be(p, 20, (uint32_t)thin_len);
    w32be(p, 24, 12);
    memcpy(p + slice_off, thin, thin_len);
    free(thin);
    *out_len = total;
    return p;
}

/* ===== COFF ===== */
uint8_t *iiit_build_coff(size_t *out_len) {
    size_t sz = 256;
    uint8_t *p = calloc(1, sz);
    w16(p, 0,  III_COFF_MACHINE_AMD64);
    w16(p, 2,  2);              /* number_of_sections */
    w32(p, 4,  0);
    w32(p, 8,  20 + 40*2);      /* pointer_to_symbol_table */
    w32(p, 12, 3);              /* number_of_symbols */
    w16(p, 16, 0);              /* size_of_optional_header */
    w16(p, 18, 0);
    /* sections */
    size_t s = 20;
    memcpy(p + s, ".text\0\0\0", 8);
    w32(p, s+16, 0x40);         /* size_of_raw_data */
    w32(p, s+20, 0x60);         /* pointer_to_raw_data */
    w32(p, s+36, III_PE_SCN_CNT_CODE | III_PE_SCN_MEM_EXECUTE | III_PE_SCN_MEM_READ);
    s += 40;
    memcpy(p + s, ".data\0\0\0", 8);
    w32(p, s+16, 0x20);
    w32(p, s+20, 0xA0);
    w32(p, s+36, III_PE_SCN_CNT_INITIALIZED_DATA | III_PE_SCN_MEM_READ | III_PE_SCN_MEM_WRITE);
    *out_len = sz;
    return p;
}
