/* test_pifield.c -- behavioral gate for p[i].field (pointer-indexed struct-element field, read + store):
 * the seed's table idiom `s[0].id = ...` / `t->slots[i].id` (iii_intern_grow + the pool accessors). */
typedef struct { int id; int hash; } slot_t;
static int use(slot_t *s) {
    s[0].id = 5; s[1].id = 9;     /* p[i].field STORE */
    s[0].hash = 7;
    return s[0].id + s[1].id + s[0].hash;   /* p[i].field READ -> 5+9+7 = 21 */
}
static slot_t arr[4];
int main(void) {
    if (use(arr) != 21) return 1;
    if (arr[1].id != 9) return 2;
    return 99;
}
