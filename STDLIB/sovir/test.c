/* a real C program (integer core): Gauss sum 0..99 == 4950, Collatz(27) == 111 steps -> 99 */
int collatz(int n0) {
    int n = n0;
    int steps = 0;
    while (n != 1) {
        if ((n & 1) == 0) { n = n / 2; } else { n = 3 * n + 1; }
        steps = steps + 1;
    }
    return steps;
}
int main() {
    int acc = 0;
    int i = 0;
    while (i < 100) { acc = acc + i; i = i + 1; }
    if (acc != 4950) { return 1; }
    if (collatz(27) != 111) { return 2; }
    return 99;
}
