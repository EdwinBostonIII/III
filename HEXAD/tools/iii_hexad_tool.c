/* III HEXAD — command-line tool. */
#include "iii/hexad.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int parse_trit(const char *s, iii_trit_t *out) {
    if (!s) return -1;
    if (!strcmp(s, "NEG")  || !strcmp(s, "neg")  || !strcmp(s, "-1")) { *out = III_TRIT_NEG;  return 0; }
    if (!strcmp(s, "ZERO") || !strcmp(s, "zero") || !strcmp(s,  "0")) { *out = III_TRIT_ZERO; return 0; }
    if (!strcmp(s, "POS")  || !strcmp(s, "pos")  || !strcmp(s, "+1") || !strcmp(s, "1")) { *out = III_TRIT_POS; return 0; }
    return -1;
}

static const char *trit_str(iii_trit_t t) {
    switch (t) {
    case III_TRIT_NEG:  return "NEG";
    case III_TRIT_ZERO: return "ZERO";
    case III_TRIT_POS:  return "POS";
    }
    return "?";
}

static int parse_hexad(const char *s, iii_hexad_t *out) {
    char *end = NULL;
    unsigned long v = strtoul(s, &end, 0);
    if (!end || *end != '\0' || v >= III_HEXAD_MAX) return -1;
    *out = (iii_hexad_t)v;
    return 0;
}

static int usage(void) {
    fprintf(stderr,
        "iii_hexad_tool — III asymmetric ternary ground (R1.A6)\n"
        "Usage:\n"
        "  pack <t0> <t1> <t2> <t3> <t4> <t5>\n"
        "  unpack <H>\n"
        "  reach <H>\n"
        "  pfs <H>\n"
        "  bitmap-dump\n"
        "  bitmap-hash\n"
        "  bitmap-stats\n"
        "  algebra add|sub|mul <H1> <H2>\n"
        "  compose <H1> <H2>\n"
        "  pfs-list\n"
        "Trits: NEG/ZERO/POS or -1/0/+1.\n");
    return 2;
}

int main(int argc, char **argv) {
    if (argc < 2) return usage();
    iii_hexad_init();
    const char *cmd = argv[1];

    if (!strcmp(cmd, "pack")) {
        if (argc != 8) return usage();
        iii_trit_t t[6];
        for (int i = 0; i < 6; ++i)
            if (parse_trit(argv[2 + i], &t[i])) { fprintf(stderr, "bad trit %s\n", argv[2+i]); return 1; }
        iii_hexad_t h = iii_hexad_pack6(t);
        printf("%u\n", (unsigned)h);
        return 0;
    }
    if (!strcmp(cmd, "unpack")) {
        if (argc != 3) return usage();
        iii_hexad_t h;
        if (parse_hexad(argv[2], &h)) { fprintf(stderr, "bad hexad\n"); return 1; }
        iii_trit_t t[6];
        iii_hexad_unpack6(h, t);
        for (int i = 0; i < 6; ++i)
            printf("%sP%d=%s", i ? " " : "", i + 1, trit_str(t[i]));
        printf("\n");
        return 0;
    }
    if (!strcmp(cmd, "reach")) {
        if (argc != 3) return usage();
        iii_hexad_t h;
        if (parse_hexad(argv[2], &h)) return 1;
        printf("%s\n", iii_hexad_reachable(h) ? "REACHABLE" : "UNREACHABLE");
        return 0;
    }
    if (!strcmp(cmd, "pfs")) {
        if (argc != 3) return usage();
        iii_hexad_t h;
        if (parse_hexad(argv[2], &h)) return 1;
        iii_pfs_op_t k = iii_hexad_pfs_kind(h);
        printf("%s\n", iii_hexad_pfs_name(k));
        return 0;
    }
    if (!strcmp(cmd, "pfs-list")) {
        for (int i = 1; i < (int)III_PFS__COUNT; ++i) {
            iii_hexad_t h = iii_hexad_pfs((iii_pfs_op_t)i);
            iii_trit_t t[6]; iii_hexad_unpack6(h, t);
            printf("%-20s pack=%-3u  pillars=( %s %s %s %s %s %s )  reach=%d\n",
                iii_hexad_pfs_name((iii_pfs_op_t)i), (unsigned)h,
                trit_str(t[0]), trit_str(t[1]), trit_str(t[2]),
                trit_str(t[3]), trit_str(t[4]), trit_str(t[5]),
                iii_hexad_reachable(h));
        }
        return 0;
    }
    if (!strcmp(cmd, "bitmap-dump")) {
        for (size_t i = 0; i < III_HEXAD_BITMAP_LEN; ++i) {
            printf("%02x", xii_asym_reach6[i]);
            if ((i & 31) == 31) printf("\n"); else printf(" ");
        }
        if (III_HEXAD_BITMAP_LEN % 32) printf("\n");
        return 0;
    }
    if (!strcmp(cmd, "bitmap-hash")) {
        uint8_t h[32];
        iii_hexad_bitmap_sha256(h);
        for (int i = 0; i < 32; ++i) printf("%02x", h[i]);
        printf("\n");
        return 0;
    }
    if (!strcmp(cmd, "bitmap-stats")) {
        printf("len=%u  reachable=%zu  unreachable=%zu  pfs=%d\n",
            III_HEXAD_BITMAP_LEN, iii_hexad_reachable_count(),
            (size_t)III_HEXAD_MAX - iii_hexad_reachable_count(),
            (int)III_PFS__COUNT - 1);
        return 0;
    }
    if (!strcmp(cmd, "compose")) {
        if (argc != 4) return usage();
        iii_hexad_t a, b;
        if (parse_hexad(argv[2], &a) || parse_hexad(argv[3], &b)) return 1;
        printf("%u\n", (unsigned)iii_hexad_compose6(a, b));
        return 0;
    }
    if (!strcmp(cmd, "algebra")) {
        if (argc != 5) return usage();
        iii_hexad_t a, b;
        if (parse_hexad(argv[3], &a) || parse_hexad(argv[4], &b)) return 1;
        iii_hexad_t r;
        if      (!strcmp(argv[2], "add")) r = iii_hexad_add(a, b);
        else if (!strcmp(argv[2], "sub")) r = iii_hexad_sub(a, b);
        else if (!strcmp(argv[2], "mul")) r = iii_hexad_mul(a, b);
        else return usage();
        printf("%u\n", (unsigned)r);
        return 0;
    }
    return usage();
}
