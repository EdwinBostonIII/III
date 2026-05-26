/* III TYPES — diagnostic code names + messages.  Hand-rolled, no string
 * tables generated; just clean switch statements (NIH).
 */
#include "iii/types_errors.h"

const char *iii_type_err_code_name(iii_type_err_code_t c) {
    switch (c) {
    case TYPE_CHK_OK:                          return "TYPE-CHK-000";
    case TYPE_CHK_001_UNIVERSE_OVERFLOW:       return "TYPE-CHK-001";
    case TYPE_CHK_002_UNIVERSE_INCONSISTENT:   return "TYPE-CHK-002";
    case TYPE_CHK_003_NON_CUMULATIVE:          return "TYPE-CHK-003";
    case TYPE_CHK_004_PROP_LIFT_BAD:           return "TYPE-CHK-004";
    case TYPE_CHK_010_PI_DOMAIN_NOT_TYPE:      return "TYPE-CHK-010";
    case TYPE_CHK_011_PI_CODOMAIN_NOT_TYPE:    return "TYPE-CHK-011";
    case TYPE_CHK_012_LAMBDA_NOT_PI:           return "TYPE-CHK-012";
    case TYPE_CHK_013_APP_FUNCTION_NOT_PI:     return "TYPE-CHK-013";
    case TYPE_CHK_014_APP_ARG_MISMATCH:        return "TYPE-CHK-014";
    case TYPE_CHK_020_REDUCTION_ARITY:         return "TYPE-CHK-020";
    case TYPE_CHK_021_REDUCTION_FIELD_KIND:    return "TYPE-CHK-021";
    case TYPE_CHK_022_REDUCTION_NOT_TRINITY:   return "TYPE-CHK-022";
    case TYPE_CHK_023_REDUCTION_PROJ:          return "TYPE-CHK-023";
    case TYPE_CHK_024_REDUCTION_COMPOSE_PHASE: return "TYPE-CHK-024";
    case TYPE_CHK_025_REDUCTION_COMPOSE_EPOCH: return "TYPE-CHK-025";
    case TYPE_CHK_026_REDUCTION_INVERSE:       return "TYPE-CHK-026";
    case TYPE_HEXAD_001_TAG_BAD_TYPE:          return "TYPE-HEXAD-001";
    case TYPE_HEXAD_002_OUT_OF_REACH:          return "TYPE-HEXAD-002";
    case TYPE_HEXAD_003_COMPOSE_OUT_OF_REACH:  return "TYPE-HEXAD-003";
    case TYPE_HEXAD_004_TAG_NOT_ERASABLE:      return "TYPE-HEXAD-004";
    case TYPE_HEXAD_005_BRICKING:              return "TYPE-HEXAD-005";
    case TYPE_RING_001_NO_MARSHAL:             return "TYPE-RING-001";
    case TYPE_RING_002_BAD_PHASE_SET:          return "TYPE-RING-002";
    case TYPE_RING_003_EMPTY_PHASE_SET:        return "TYPE-RING-003";
    case TYPE_RING_004_IMPLICIT_RING_SUB:      return "TYPE-RING-004";
    case TYPE_TIER_001_BAD_TIER:               return "TYPE-TIER-001";
    case TYPE_TIER_002_DEMOTION:               return "TYPE-TIER-002";
    case TYPE_EPOCH_001_CROSS_EPOCH_NO_BRIDGE: return "TYPE-EPOCH-001";
    case TYPE_EPOCH_002_BAD_EPOCH:             return "TYPE-EPOCH-002";
    case TYPE_LIN_001_USED_TWICE:              return "TYPE-LIN-001";
    case TYPE_LIN_002_DROPPED_UNUSED:          return "TYPE-LIN-002";
    case TYPE_LIN_003_BAD_PERM:                return "TYPE-LIN-003";
    case TYPE_LIN_004_NO_GLYPH:                return "TYPE-LIN-004";
    case TYPE_LIN_005_REPLICATE_BAD_TIER:      return "TYPE-LIN-005";
    case TYPE_EPI_001_BAD_CONFIDENCE:          return "TYPE-EPI-001";
    case TYPE_EPI_002_THRESHOLD_NOT_MET:       return "TYPE-EPI-002";
    case TYPE_EPI_003_OPEN_QUESTIONS:          return "TYPE-EPI-003";
    case TYPE_CON_001_NOT_PROP:                return "TYPE-CON-001";
    case TYPE_CON_002_CEILING_DENIED:          return "TYPE-CON-002";
    case TYPE_MOB_001_COHERENCE_BELOW_FLOOR:   return "TYPE-MOB-001";
    case TYPE_TRI_001_ADMIT_INCOMPLETE:        return "TYPE-TRI-001";
    case TYPE_BIDIR_001_CHECK_FAILED:          return "TYPE-BIDIR-001";
    case TYPE_BIDIR_002_SYNTH_FAILED:          return "TYPE-BIDIR-002";
    case TYPE_HOLE_001_UNINFERRED:             return "TYPE-HOLE-001";
    case TYPE_HOLE_002_OCCURS_CHECK:           return "TYPE-HOLE-002";
    case TYPE_HOLE_003_CONFLICT:               return "TYPE-HOLE-003";
    case TYPE_PROOF_001_VAR_UNBOUND:           return "TYPE-PROOF-001";
    case TYPE_PROOF_002_NOT_CONVERTIBLE:       return "TYPE-PROOF-002";
    case TYPE_PROOF_003_BAD_SORT:              return "TYPE-PROOF-003";
    case TYPE_PROOF_004_POSITIVITY:            return "TYPE-PROOF-004";
    case TYPE_PROOF_005_BAD_CERT:              return "TYPE-PROOF-005";
    case TYPE_PROOF_006_KERNEL_DIVERGED:       return "TYPE-PROOF-006";
    case TYPE_PROOF_007_BAD_INDUCTIVE:         return "TYPE-PROOF-007";
    case TYPE_PROOF_008_PATTERN_NONEXHAUSTIVE: return "TYPE-PROOF-008";
    case TYPE_CHK__COUNT: break;
    }
    return "TYPE-CHK-???";
}

const char *iii_type_err_code_message(iii_type_err_code_t c) {
    switch (c) {
    case TYPE_CHK_OK:                          return "ok";
    case TYPE_CHK_001_UNIVERSE_OVERFLOW:       return "universe level exceeds Type_6";
    case TYPE_CHK_002_UNIVERSE_INCONSISTENT:   return "type contains its own universe";
    case TYPE_CHK_003_NON_CUMULATIVE:          return "implicit lift across non-cumulative universes";
    case TYPE_CHK_004_PROP_LIFT_BAD:           return "Prop lift target must be Type_0";
    case TYPE_CHK_010_PI_DOMAIN_NOT_TYPE:      return "Pi-type domain is not a type";
    case TYPE_CHK_011_PI_CODOMAIN_NOT_TYPE:    return "Pi-type codomain is not a type";
    case TYPE_CHK_012_LAMBDA_NOT_PI:           return "lambda checked against non-Pi type";
    case TYPE_CHK_013_APP_FUNCTION_NOT_PI:     return "application head is not a Pi-type";
    case TYPE_CHK_014_APP_ARG_MISMATCH:        return "application argument has wrong type";
    case TYPE_CHK_020_REDUCTION_ARITY:         return "Reduction must have arity 6";
    case TYPE_CHK_021_REDUCTION_FIELD_KIND:    return "Reduction field has wrong kind";
    case TYPE_CHK_022_REDUCTION_NOT_TRINITY:   return "Reduction missing trinity_admit obligation";
    case TYPE_CHK_023_REDUCTION_PROJ:          return "unknown Reduction projector name";
    case TYPE_CHK_024_REDUCTION_COMPOSE_PHASE: return "Reduction compose: phases must match";
    case TYPE_CHK_025_REDUCTION_COMPOSE_EPOCH: return "Reduction compose: epochs must match";
    case TYPE_CHK_026_REDUCTION_INVERSE:       return "Reduction inverse: not a Reduction value";
    case TYPE_HEXAD_001_TAG_BAD_TYPE:          return "hexad-tag applied to non-Type_i (i>5)";
    case TYPE_HEXAD_002_OUT_OF_REACH:          return "composed hexad outside reachable set";
    case TYPE_HEXAD_003_COMPOSE_OUT_OF_REACH:  return "hexad composition unreachable";
    case TYPE_HEXAD_004_TAG_NOT_ERASABLE:      return "hexad tag is not erasable; use a cycle to consume";
    case TYPE_HEXAD_005_BRICKING:              return "operation has a bricking hexad (untypable)";
    case TYPE_RING_001_NO_MARSHAL:             return "no marshalling constructor between rings";
    case TYPE_RING_002_BAD_PHASE_SET:          return "phase set has invalid ring";
    case TYPE_RING_003_EMPTY_PHASE_SET:        return "phase set must be non-empty";
    case TYPE_RING_004_IMPLICIT_RING_SUB:      return "implicit ring subtyping is forbidden";
    case TYPE_TIER_001_BAD_TIER:               return "invalid tier";
    case TYPE_TIER_002_DEMOTION:               return "tier demotion is forbidden";
    case TYPE_EPOCH_001_CROSS_EPOCH_NO_BRIDGE: return "cross-epoch combination without @epoch_bridge";
    case TYPE_EPOCH_002_BAD_EPOCH:             return "invalid epoch (greater than current)";
    case TYPE_LIN_001_USED_TWICE:              return "capability used twice";
    case TYPE_LIN_002_DROPPED_UNUSED:          return "capability dropped unused";
    case TYPE_LIN_003_BAD_PERM:                return "invalid capability permission";
    case TYPE_LIN_004_NO_GLYPH:                return "capability missing glyph binding";
    case TYPE_LIN_005_REPLICATE_BAD_TIER:      return "@replicates incompatible with this tier";
    case TYPE_EPI_001_BAD_CONFIDENCE:          return "confidence must be a Q14 in [0,1]";
    case TYPE_EPI_002_THRESHOLD_NOT_MET:       return "uncertainty below threshold; Trinity escalation required";
    case TYPE_EPI_003_OPEN_QUESTIONS:          return "open epistemic questions remain";
    case TYPE_CON_001_NOT_PROP:                return "expected a Prop-typed proposition";
    case TYPE_CON_002_CEILING_DENIED:          return "constitutional ceiling denied admission";
    case TYPE_MOB_001_COHERENCE_BELOW_FLOOR:   return "Möbius coherence below floor";
    case TYPE_TRI_001_ADMIT_INCOMPLETE:        return "Trinity admission has missing conjunct(s)";
    case TYPE_BIDIR_001_CHECK_FAILED:          return "bidirectional check failed";
    case TYPE_BIDIR_002_SYNTH_FAILED:          return "bidirectional synthesis failed";
    case TYPE_HOLE_001_UNINFERRED:             return "hole could not be inferred";
    case TYPE_HOLE_002_OCCURS_CHECK:           return "occurs-check failed for hole metavariable";
    case TYPE_HOLE_003_CONFLICT:               return "conflicting solutions for hole";
    case TYPE_PROOF_001_VAR_UNBOUND:           return "kernel: de Bruijn index out of range";
    case TYPE_PROOF_002_NOT_CONVERTIBLE:       return "kernel: types not convertible up to βιδζη";
    case TYPE_PROOF_003_BAD_SORT:              return "kernel: expected a sort";
    case TYPE_PROOF_004_POSITIVITY:            return "kernel: positivity check failed";
    case TYPE_PROOF_005_BAD_CERT:              return "kernel: malformed proof certificate";
    case TYPE_PROOF_006_KERNEL_DIVERGED:       return "kernel: reduction step budget exhausted";
    case TYPE_PROOF_007_BAD_INDUCTIVE:         return "kernel: bad inductive reference";
    case TYPE_PROOF_008_PATTERN_NONEXHAUSTIVE: return "kernel: pattern match not exhaustive";
    case TYPE_CHK__COUNT: break;
    }
    return "unknown error";
}
