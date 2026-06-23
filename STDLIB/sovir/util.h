#ifndef UTIL_H
#define UTIL_H
struct Vec { int x; int y; };
#define SCALE 1000
int vlen2(struct Vec *v) { return v->x * v->x + v->y * v->y; }
#endif
