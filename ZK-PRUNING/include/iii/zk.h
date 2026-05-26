/* III ZK-PRUNING — umbrella header.
 *
 * Implements the audit-chain compression mechanism specified by
 * DOCS/III-ZK-PRUNING.md (Cluster K item 175).  The module ships:
 *
 *   1. A NIH Groth16-style ZK-SNARK over a small supersingular
 *      pairing-friendly curve  (zk_field.h, zk_curve.h, zk_snark.h).
 *   2. A NIH FRI-based ZK-STARK with NTT, SHA-256 Merkle commitments
 *      and Reed–Solomon proximity testing  (zk_stark.h).
 *   3. The rollup pruning engine and closure-pinned preservation list
 *      (zk_prune.h).
 *
 * No external crypto library is linked.  All primitives are hand-rolled.
 */
#ifndef III_ZK_H
#define III_ZK_H

#include "iii/zk_field.h"
#include "iii/zk_curve.h"
#include "iii/zk_snark.h"
#include "iii/zk_stark.h"
#include "iii/zk_prune.h"

#endif
