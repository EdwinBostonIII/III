/* test_structparam.c -- Boss-2 struct-value PARAMS >8B via COPY-IN value-semantics (SRET_ON=1 KAT).
 * read-only param, MUTATING param (write isolated to the callee's copy), SAME var to two params (separate
 * copies), AND a fn that BOTH returns a struct (sret) and takes struct params (span) -- the case whose
 * first struct param used to alias the sret slot (leftover LO/LL name-table; fixed by the per-fn LL reset). */
typedef struct { int a; int b; int c; int d; } pos;
static pos mk(int v){ pos r; r.a=v; r.b=v+1; r.c=v+2; r.d=v+3; return r; }
static int sumab(pos p){ return p.a + p.b; }
static void bump(pos p){ p.a = p.a + 1000; }
static int diff(pos p, pos q){ return p.a - q.b; }
static pos span(pos p, pos q){ pos r; r.a=p.a; r.b=q.b; r.c=p.c; r.d=q.d; return r; }
int main(void){
    pos g = mk(10);
    if (sumab(g) != 21) return 1;
    bump(g);  if (g.a != 10) return 2;
    if (diff(g, g) != -1) return 3;
    pos h = mk(20);  pos s = span(g, h);            /* sret + struct-params */
    if (s.a != 10) return 4; if (s.b != 21) return 5; if (s.c != 12) return 6; if (s.d != 23) return 7;
    return 99;
}
