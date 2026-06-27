/* test_dblptr.c -- `T **p = call()` + the pool-accessor element ops `(*pf)[i]` / `&(*pf)[i]` (seed idiom). */
static int row[4]={10,20,30,40}; static int* tab[1];
static int** gpf(void){ tab[0]=row; return tab; }
static int sink(int *p){ return *p; }
int main(void){
    int **pf = gpf();                 /* T**=call : was DROPPED, pf unregistered */
    if (pf == 0) return 1;
    if ((*pf)[2] != 30) return 2;     /* (*pf)[i] rvalue */
    if (sink(&(*pf)[3]) != 40) return 3;  /* &(*pf)[i] address (seed `&(*pf)[slot]`) */
    int *p = *pf; if (p[0] != 10) return 4;
    return 99;
}
