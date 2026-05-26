/* Internal interface shared between constants_table.c and the API
 * implementations.  Not part of the public surface. */
#ifndef III_CONSTANTS_INTERNAL_H
#define III_CONSTANTS_INTERNAL_H

#include "iii/constants.h"

const iii_constant_info_t *iii__constants_table(size_t *out_n);

#endif
