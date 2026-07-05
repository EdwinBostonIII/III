/* Class D falsifier: CHAINED ARRAY-ELEMENT assignment (witness_commit's
 * `buf[20] = buf[21] = buf[22] = buf[23] = 0;`).  The inner assignments are
 * EXPRESSIONS that must store AND leave the value (the fix-#23 DOT-chain lesson,
 * array complement).  Distinct sentinel values pin every element. */
int main(void) {
    unsigned char b[6];
    b[0] = 1;
    b[2] = b[3] = b[4] = b[5] = 7;
    if (b[2] != 7) { return 1; }
    if (b[3] != 7) { return 1; }
    if (b[4] != 7) { return 1; }
    if (b[5] != 7) { return 1; }
    if (b[0] != 1) { return 1; }
    return 99;
}
