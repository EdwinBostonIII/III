int classify(int x) {
    if (x == 1) { return 10; }
    else if (x == 2) { return 20; }
    else if (x == 3) { return 30; }
    else { return 0; }
}
int main(void) {
    if (classify(1) != 10) return 1;
    if (classify(2) != 20) return 2;
    if (classify(3) != 30) return 3;
    if (classify(9) != 0)  return 4;
    return 99;
}
