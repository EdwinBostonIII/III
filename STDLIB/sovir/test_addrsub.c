/* &p->ptrfield[i].subfield (+ trailing inline-array [j]) -- walk_state_deserialize's
 * `memcpy(&ws->stack[i].depth, ..)` and `memcpy(&ws->stack[i].children[j], ..)` shapes:
 * the &-index arm stopped at the element address; the member chain (and a final [j] on
 * an inline-array member) now extend it.  Neighbor-untouched checks pin the offsets. */
#include <string.h>
typedef struct { unsigned node; unsigned depth; unsigned children[4]; } frame_t;
typedef struct { frame_t *stack; long n; } ws_t;
static frame_t FR[3];
static ws_t W;
static unsigned char SRC[4] = {0x2A, 0, 0, 0};
static unsigned char SRC2[4] = {0x37, 0, 0, 0};
int main(void) {
    W.stack = FR;
    ws_t *ws = &W;
    memcpy(&ws->stack[1].depth, SRC, 4);
    if (FR[1].depth != 42u) { return 1; }
    if (FR[1].node != 0u) { return 1; }
    memcpy(&ws->stack[1].children[2], SRC2, 4);
    if (FR[1].children[2] != 55u) { return 1; }
    if (FR[1].children[1] != 0u) { return 1; }
    if (FR[1].children[3] != 0u) { return 1; }
    long v = (long)ws->stack[1].depth;
    if (v != 42) { return 1; }
    return 99;
}
