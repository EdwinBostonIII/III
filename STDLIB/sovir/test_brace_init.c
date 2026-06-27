typedef struct { unsigned int offset; unsigned int count; } list_t;
static list_t mk(unsigned int s, unsigned int c){ list_t h = {0u, 0u}; h.offset = s; h.count = c; return h; }
int main(void){
    list_t h = {5u, 7u};   if (h.offset!=5) return 1;  if (h.count!=7) return 2;
    list_t z = {0u};       if (z.offset!=0) return 3;  if (z.count!=0) return 4;
    list_t r = mk(10u, 20u); if (r.offset!=10) return 5; if (r.count!=20) return 6;
    return 99;
}
