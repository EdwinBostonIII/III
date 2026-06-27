/* test_structval.c -- struct-by-value via the sret hidden-pointer ABI (seed: `iii_src_pos_t pos = iiip_pos_of(..)`).
 * SEPARATE field decls (matching the seed; comma-separated `int a,b,c` is a distinct unfixed bug -> 1 field). */
typedef struct { int a; int b; int c; int d; } pos;   /* 16 bytes */
static pos make(int x){ pos r; r.a=x; r.b=x+1; r.c=x+2; r.d=x+3; return r; }
typedef struct { int p; int q; int r3; } tri;          /* 12 bytes -> 8 + 4 tail */
static tri mk3(int x){ tri t; t.p=x; t.q=x*2; t.r3=x*3; return t; }
int main(void){
    pos p = make(10);
    if (p.a!=10) return 1;  if (p.b!=11) return 2;  if (p.c!=12) return 3;  if (p.d!=13) return 4;
    tri t = mk3(5);
    if (t.p!=5) return 5;  if (t.q!=10) return 6;  if (t.r3!=15) return 7;
    return 99;
}
