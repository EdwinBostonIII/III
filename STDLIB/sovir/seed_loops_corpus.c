int affine()  { int acc = 0; int i = 0; while (i < 10) { acc = acc + 5; i = i + 1; } return acc; }
int geo()     { int acc = 1; int i = 0; while (i < 10) { acc = acc * 2; i = i + 1; } return acc; }
int chaotic() { int acc = 1; int i = 0; while (i < 10) { acc = acc * acc + 1; i = i + 1; } return acc; }
int main()    { return affine() + geo() + chaotic(); }
