
typedef struct { const char *name; int code; } entry_t;
extern const entry_t XTBL[];
extern const size_t XTBL_COUNT;
static int probe(const char *s) {
    for (size_t i = 0; i < XTBL_COUNT; i++) {
        if (XTBL[i].name[0] == s[0]) return XTBL[i].code;
    }
    return -1;
}
int main(void) { if (probe("q") == -1) return 99; return 1; }
