static int arr[4] = {10,20,30,40};
static int *p1 = arr;
static int **pp = &p1;
int main(void){
    int **bd = pp;
    if ((*bd)[2] != 30) return 1;      /* (*bd)[i] READ — set_binder_id's bound check shape */
    (*bd)[2] = 99;                      /* (*bd)[i] STORE — set_binder_id's write */
    if (arr[2] != 99) return 2;
    return 99;
}
