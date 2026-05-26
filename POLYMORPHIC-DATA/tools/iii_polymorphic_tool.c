#include "iii/polymorphic.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static int cmd_info(void) {
    printf("III-POLYMORPHIC-DATA (Wave 6, items 47-53)\n");
    printf("  Glyph V3: %u bytes (1-byte tag + %u-byte payload)\n",
           III_GLYPH_BYTES, III_GLYPH_PAYLOAD_BYTES);
    printf("  Forms: 0x00..0x25 + 0xFF EXTENSION (catalog closure-pinned)\n");
    return 0;
}

static int cmd_forms(void) {
    for (int f = 0; f <= 0x25; ++f) {
        printf("  0x%02x  %s\n", f, iii_glyph_form_name((iii_glyph_form_t)f));
    }
    printf("  0xFF  %s\n", iii_glyph_form_name(III_FORM_EXTENSION));
    return 0;
}

static int cmd_detect(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) return 2;
    fseek(f, 0, SEEK_END);
    long n = ftell(f); fseek(f, 0, SEEK_SET);
    uint8_t *buf = malloc((size_t)n);
    fread(buf, 1, (size_t)n, f);
    fclose(f);
    iii_encoding_t e = iii_detect_encoding(buf, (size_t)n);
    printf("%s\n", iii_encoding_name(e));
    free(buf);
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: iii_poly_tool info|forms|detect <file>\n"); return 1; }
    if (strcmp(argv[1], "info") == 0)  return cmd_info();
    if (strcmp(argv[1], "forms") == 0) return cmd_forms();
    if (strcmp(argv[1], "detect") == 0 && argc == 3) return cmd_detect(argv[2]);
    return 1;
}
