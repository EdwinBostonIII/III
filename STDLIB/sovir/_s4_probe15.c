/* probe15.c -- STRUCT-POINTER ARITHMETIC STRIDE falsifier (the corpus-parity sema-arena killer):
 *   `structptr + N` must scale by sizeof(*structptr), NOT 1.  ccsv set EV_PSZ from LPSZ only; the
 *   `TypedefName *p` decl arm sets LPT (for p->field) but left LPSZ=0, so `p + 1` produced p + 1
 *   BYTE.  sema's arena does `nc->base = (uint8_t*)(nc + 1)` (skip the chunk header); with stride 1
 *   base overlapped `used`, so every sema_arena_alloc returned the same address -> each interned
 *   decl name overwrote the previous -> "duplicate declaration of 'main'" + unresolved 'counter'
 *   refs = 30 of the 54 corpus reds (rc=12 SEMA_FAIL).  Fix: struct-typedef pointer locals/params
 *   use STSZ(struct) as the arithmetic stride (deref/field access via LPT are unaffected).
 *   Asserts the SEQUENTIAL bump property (adjacency defeats a fresh-chunk false-pass): three
 *   strings interned into one chunk must be BYTE-ADJACENT and all readable simultaneously.
 *   60 = 2nd string not adjacent to 1st (used didn't advance / aliased)
 *   61 = 1st string clobbered   62 = 2nd clobbered   63 = 3rd clobbered   99 = all green */
#include <string.h>
#include <stdlib.h>
typedef struct chunk_s { struct chunk_s *next; unsigned long used; unsigned long cap; unsigned char *base; } chunk_t;
typedef struct { chunk_t *head; } arena_t;
static char *aalloc(arena_t *a, unsigned long n) {
    if (n == 0) n = 1;
    chunk_t *c = a->head;
    if (!c || c->used + n > c->cap) {
        unsigned long cap = 4096; while (cap < n) cap *= 2;
        chunk_t *nc = (chunk_t *)malloc(sizeof(*nc) + cap);
        if (!nc) return 0;
        nc->next = a->head; nc->used = 0; nc->cap = cap;
        nc->base = (unsigned char *)(nc + 1);
        a->head = nc; c = nc;
    }
    char *out = (char *)(c->base + c->used);
    c->used += n;
    return out;
}
static char *astrdup(arena_t *a, const char *s) {
    unsigned long n = strlen(s);
    char *out = aalloc(a, n + 1);
    unsigned long i = 0;
    while (i < n) { out[i] = s[i]; i = i + 1; }
    out[n] = 0;
    return out;
}
int main(void) {
    arena_t A; A.head = 0;
    char *a = astrdup(&A, "counter");   /* 8 bytes incl NUL */
    char *b = astrdup(&A, "main");       /* 5 bytes incl NUL */
    char *c = astrdup(&A, "third");      /* 6 bytes incl NUL */
    if (b - a != 8) return 60;           /* b must sit exactly 8 bytes after a (same chunk, used advanced) */
    if (c - b != 5) return 60;
    if (strcmp(a, "counter") != 0) return 61;
    if (strcmp(b, "main") != 0) return 62;
    if (strcmp(c, "third") != 0) return 63;
    return 99;
}
