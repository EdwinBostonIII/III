#include <stdio.h>
#include "a.h"
#include "b.h"
int main() {
    struct B b;
    b.val = BVAL;
    int r = getbval(&b);
    if (r != 42) { return 1; }
    return 99;
}
