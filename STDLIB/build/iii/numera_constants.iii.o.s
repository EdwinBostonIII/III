# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "sha256.iii\0"
L_str_1:
    .ascii "Q14\0"
L_str_2:
    .ascii "range\0"
L_str_3:
    .ascii "(N,K)\0"
L_str_4:
    .ascii "bool\0"
L_str_5:
    .ascii "utf8\0"
L_str_6:
    .ascii "\302\2472\0"
L_str_7:
    .ascii "LEX_KEYWORD_COUNT\0"
L_str_8:
    .ascii "count\0"
L_str_9:
    .ascii "LEX \302\2474\0"
L_str_10:
    .ascii "LEX_KEYWORD_RESERVED_SLOTS\0"
L_str_11:
    .ascii "count\0"
L_str_12:
    .ascii "LEX \302\2474\0"
L_str_13:
    .ascii "LEX_KEYWORD_MAX\0"
L_str_14:
    .ascii "count\0"
L_str_15:
    .ascii "LEX \302\2474\0"
L_str_16:
    .ascii "LEX_MODIFIER_COUNT\0"
L_str_17:
    .ascii "count\0"
L_str_18:
    .ascii "LEX \302\2475\0"
L_str_19:
    .ascii "LEX_MODIFIER_RESERVED_SLOTS\0"
L_str_20:
    .ascii "count\0"
L_str_21:
    .ascii "LEX \302\2475\0"
L_str_22:
    .ascii "LEX_MODIFIER_MAX\0"
L_str_23:
    .ascii "count\0"
L_str_24:
    .ascii "LEX \302\2475\0"
L_str_25:
    .ascii "LEX_OPERATOR_COUNT\0"
L_str_26:
    .ascii "count\0"
L_str_27:
    .ascii "LEX \302\2476\0"
L_str_28:
    .ascii "LEX_OPERATOR_RESERVED_SLOTS\0"
L_str_29:
    .ascii "count\0"
L_str_30:
    .ascii "LEX \302\2476\0"
L_str_31:
    .ascii "LEX_OPERATOR_MAX\0"
L_str_32:
    .ascii "count\0"
L_str_33:
    .ascii "LEX \302\2476\0"
L_str_34:
    .ascii "LEX_PUNCTUATOR_COUNT\0"
L_str_35:
    .ascii "count\0"
L_str_36:
    .ascii "LEX \302\2477\0"
L_str_37:
    .ascii "LEX_RESERVED_UNUSED_CHARS\0"
L_str_38:
    .ascii "count\0"
L_str_39:
    .ascii "LEX \302\2477.3\0"
L_str_40:
    .ascii "LEX_LITERAL_TOKEN_KINDS\0"
L_str_41:
    .ascii "count\0"
L_str_42:
    .ascii "LEX \302\2473.1\0"
L_str_43:
    .ascii "LEX_COMMENT_KINDS\0"
L_str_44:
    .ascii "count\0"
L_str_45:
    .ascii "LEX \302\24710\0"
L_str_46:
    .ascii "LEX_WHITESPACE_CHARS\0"
L_str_47:
    .ascii "count\0"
L_str_48:
    .ascii "LEX \302\24711\0"
L_str_49:
    .ascii "LEX_IDENT_MAX_CODEPOINTS\0"
L_str_50:
    .ascii "codepoints\0"
L_str_51:
    .ascii "LEX \302\2478.3\0"
L_str_52:
    .ascii "LEX_SOURCE_MAX_BYTES\0"
L_str_53:
    .ascii "bytes\0"
L_str_54:
    .ascii "LEX \302\2472.7\0"
L_str_55:
    .ascii "LEX_SOURCE_EXTENSION\0"
L_str_56:
    .ascii ".III\0"
L_str_57:
    .ascii "LEX \302\2472.6\0"
L_str_58:
    .ascii "LEX_MOBIUS_DIACRITIC\0"
L_str_59:
    .ascii "U+\0"
L_str_60:
    .ascii "LEX \302\2474.3\0"
L_str_61:
    .ascii "LEX_BOM_FORBIDDEN\0"
L_str_62:
    .ascii "LEX \302\2472.2\0"
L_str_63:
    .ascii "LEX_LINE_ENDING\0"
L_str_64:
    .ascii "LF\0"
L_str_65:
    .ascii "LEX \302\2472.3\0"
L_str_66:
    .ascii "\302\2473\0"
L_str_67:
    .ascii "TYPE_UNIVERSE_COUNT\0"
L_str_68:
    .ascii "count\0"
L_str_69:
    .ascii "TYPES \302\2472\0"
L_str_70:
    .ascii "TYPE_IMPREDICATIVE_TOP_INDEX\0"
L_str_71:
    .ascii "index\0"
L_str_72:
    .ascii "TYPES \302\2472.4\0"
L_str_73:
    .ascii "TYPE_Q14_BITS_TOTAL\0"
L_str_74:
    .ascii "bits\0"
L_str_75:
    .ascii "TYPES \302\2476\0"
L_str_76:
    .ascii "TYPE_Q14_FRAC_BITS\0"
L_str_77:
    .ascii "bits\0"
L_str_78:
    .ascii "TYPES \302\2476\0"
L_str_79:
    .ascii "TYPE_MHASH_SIZE\0"
L_str_80:
    .ascii "bytes\0"
L_str_81:
    .ascii "TYPES \302\2476\0"
L_str_82:
    .ascii "TYPE_GLYPH_SIZE\0"
L_str_83:
    .ascii "bytes\0"
L_str_84:
    .ascii "LEX \302\2474.1.1\0"
L_str_85:
    .ascii "TYPE_WITNESS_SIZE\0"
L_str_86:
    .ascii "bytes\0"
L_str_87:
    .ascii "CYCLES \302\2474.1\0"
L_str_88:
    .ascii "TYPE_HEXAD_PACK_BITS_USED\0"
L_str_89:
    .ascii "bits\0"
L_str_90:
    .ascii "HEXAD \302\2472.2\0"
L_str_91:
    .ascii "TYPE_HEXAD_PACK_BITS_RESERVED\0"
L_str_92:
    .ascii "bits\0"
L_str_93:
    .ascii "HEXAD \302\2472.2\0"
L_str_94:
    .ascii "TYPE_TRIT_CARDINALITY\0"
L_str_95:
    .ascii "count\0"
L_str_96:
    .ascii "HEXAD \302\2471.1\0"
L_str_97:
    .ascii "TYPE_REDUCTION_ARITY\0"
L_str_98:
    .ascii "count\0"
L_str_99:
    .ascii "TYPES \302\2473\0"
L_str_100:
    .ascii "TYPE_COMPROMISE_TIERS\0"
L_str_101:
    .ascii "count\0"
L_str_102:
    .ascii "EFFECTS \302\2471.2\0"
L_str_103:
    .ascii "TYPE_PROOF_KERNEL_LOC_BUDGET\0"
L_str_104:
    .ascii "LoC\0"
L_str_105:
    .ascii "TYPES \302\24711\0"
L_str_106:
    .ascii "\302\2474\0"
L_str_107:
    .ascii "EFFECT_SE_KIND_COUNT\0"
L_str_108:
    .ascii "count\0"
L_str_109:
    .ascii "EFFECTS \302\2471.1\0"
L_str_110:
    .ascii "EFFECT_COMPROMISE_TIER_COUNT\0"
L_str_111:
    .ascii "count\0"
L_str_112:
    .ascii "EFFECTS \302\2471.2\0"
L_str_113:
    .ascii "EFFECT_PFS_BRICKING_OPS\0"
L_str_114:
    .ascii "count\0"
L_str_115:
    .ascii "EFFECTS \302\2471.3\0"
L_str_116:
    .ascii "EFFECT_WAVEFRONT_TERMINATORS\0"
L_str_117:
    .ascii "count\0"
L_str_118:
    .ascii "EFFECTS \302\2477\0"
L_str_119:
    .ascii "\302\2475\0"
L_str_120:
    .ascii "CYCLE_WITNESS_BYTE_SIZE\0"
L_str_121:
    .ascii "bytes\0"
L_str_122:
    .ascii "CYCLES \302\2474.1\0"
L_str_123:
    .ascii "CYCLE_WITNESS_PRED_OFFSET\0"
L_str_124:
    .ascii "offset\0"
L_str_125:
    .ascii "CYCLES \302\2474.1\0"
L_str_126:
    .ascii "CYCLE_WITNESS_PRED_BYTES\0"
L_str_127:
    .ascii "bytes\0"
L_str_128:
    .ascii "CYCLES \302\2474.1\0"
L_str_129:
    .ascii "CYCLE_WITNESS_SUCC_OFFSET\0"
L_str_130:
    .ascii "offset\0"
L_str_131:
    .ascii "CYCLES \302\2474.1\0"
L_str_132:
    .ascii "CYCLE_WITNESS_SUCC_BYTES\0"
L_str_133:
    .ascii "bytes\0"
L_str_134:
    .ascii "CYCLES \302\2474.1\0"
L_str_135:
    .ascii "CYCLE_WITNESS_STEP_KIND_OFFSET\0"
L_str_136:
    .ascii "offset\0"
L_str_137:
    .ascii "CYCLES \302\2474.1\0"
L_str_138:
    .ascii "CYCLE_WITNESS_STEP_KIND_BYTES\0"
L_str_139:
    .ascii "bytes\0"
L_str_140:
    .ascii "CYCLES \302\2474.1\0"
L_str_141:
    .ascii "CYCLE_WITNESS_FLAGS_OFFSET\0"
L_str_142:
    .ascii "offset\0"
L_str_143:
    .ascii "STDLIB \302\2475.6\0"
L_str_144:
    .ascii "CYCLE_WITNESS_FLAGS_BYTES\0"
L_str_145:
    .ascii "bytes\0"
L_str_146:
    .ascii "STDLIB \302\2475.6\0"
L_str_147:
    .ascii "CYCLE_WITNESS_HEXAD_OFFSET\0"
L_str_148:
    .ascii "offset\0"
L_str_149:
    .ascii "CYCLES \302\2474.1\0"
L_str_150:
    .ascii "CYCLE_WITNESS_HEXAD_BYTES\0"
L_str_151:
    .ascii "bytes\0"
L_str_152:
    .ascii "CYCLES \302\2474.1\0"
L_str_153:
    .ascii "CYCLE_BCWL_BLOOM_BITS\0"
L_str_154:
    .ascii "bits\0"
L_str_155:
    .ascii "CYCLES \302\2474.3\0"
L_str_156:
    .ascii "CYCLE_BCWL_BUCKETS\0"
L_str_157:
    .ascii "count\0"
L_str_158:
    .ascii "CYCLES \302\2474.3\0"
L_str_159:
    .ascii "CYCLE_BCWL_FP_TARGET_PERCENT\0"
L_str_160:
    .ascii "percent\0"
L_str_161:
    .ascii "STDLIB \302\24714.3\0"
L_str_162:
    .ascii "CYCLE_STEP_KIND_TOTAL_SLOTS\0"
L_str_163:
    .ascii "count\0"
L_str_164:
    .ascii "CYCLES \302\2475.3\0"
L_str_165:
    .ascii "SK_RESERVED_BOOT\0"
L_str_166:
    .ascii "CYCLES \302\2475.3\0"
L_str_167:
    .ascii "SK_IRPD_PRIV_WRITE\0"
L_str_168:
    .ascii "CYCLES \302\2475.3\0"
L_str_169:
    .ascii "SK_IRPD_PRIV_READ\0"
L_str_170:
    .ascii "CYCLES \302\2475.3\0"
L_str_171:
    .ascii "SK_CYCLE_LIFECYCLE\0"
L_str_172:
    .ascii "CYCLES \302\2475.3\0"
L_str_173:
    .ascii "SK_WAVEFRONT\0"
L_str_174:
    .ascii "CYCLES \302\2475.3\0"
L_str_175:
    .ascii "SK_SANCTUM\0"
L_str_176:
    .ascii "CYCLES \302\2475.3\0"
L_str_177:
    .ascii "SK_TRINITY\0"
L_str_178:
    .ascii "CYCLES \302\2475.3\0"
L_str_179:
    .ascii "SK_CEILING\0"
L_str_180:
    .ascii "CYCLES \302\2475.3\0"
L_str_181:
    .ascii "SK_FEDERATION\0"
L_str_182:
    .ascii "CYCLES \302\2475.3\0"
L_str_183:
    .ascii "SK_DRTM\0"
L_str_184:
    .ascii "CYCLES \302\2475.3\0"
L_str_185:
    .ascii "SK_VDF\0"
L_str_186:
    .ascii "CYCLES \302\2475.3\0"
L_str_187:
    .ascii "SK_OBSERVATORY\0"
L_str_188:
    .ascii "CYCLES \302\2475.3\0"
L_str_189:
    .ascii "SK_CATALYST\0"
L_str_190:
    .ascii "CYCLES \302\2475.3\0"
L_str_191:
    .ascii "SK_NARRATIVE\0"
L_str_192:
    .ascii "CYCLES \302\2475.3\0"
L_str_193:
    .ascii "SK_COGNITIVE\0"
L_str_194:
    .ascii "CYCLES \302\2475.3\0"
L_str_195:
    .ascii "SK_PFS\0"
L_str_196:
    .ascii "CYCLES \302\2475.3\0"
L_str_197:
    .ascii "SK_FED_RESERVED\0"
L_str_198:
    .ascii "CYCLES \302\2475.3\0"
L_str_199:
    .ascii "SK_USER_RESERVED\0"
L_str_200:
    .ascii "CYCLES \302\2475.3\0"
L_str_201:
    .ascii "SK_MNEME_PROMOTE\0"
L_str_202:
    .ascii "CYCLES \302\2475.3\0"
L_str_203:
    .ascii "SK_RESERVED_FUTURE\0"
L_str_204:
    .ascii "CYCLES \302\2475.3\0"
L_str_205:
    .ascii "\302\2476\0"
L_str_206:
    .ascii "HEXAD_PILLAR_COUNT\0"
L_str_207:
    .ascii "count\0"
L_str_208:
    .ascii "HEXAD \302\2472\0"
L_str_209:
    .ascii "HEXAD_PILLAR_1_NAME\0"
L_str_210:
    .ascii "INVERSE_DERIVABILITY\0"
L_str_211:
    .ascii "HEXAD \302\2472.1\0"
L_str_212:
    .ascii "HEXAD_PILLAR_2_NAME\0"
L_str_213:
    .ascii "CAUSALITY_DEPTH\0"
L_str_214:
    .ascii "HEXAD \302\2472.1\0"
L_str_215:
    .ascii "HEXAD_PILLAR_3_NAME\0"
L_str_216:
    .ascii "CONSENT_RECENCY\0"
L_str_217:
    .ascii "HEXAD \302\2472.1\0"
L_str_218:
    .ascii "HEXAD_PILLAR_4_NAME\0"
L_str_219:
    .ascii "REPLICATION_TIER\0"
L_str_220:
    .ascii "HEXAD \302\2472.1\0"
L_str_221:
    .ascii "HEXAD_PILLAR_5_NAME\0"
L_str_222:
    .ascii "ADVERSARIALITY_CLASS\0"
L_str_223:
    .ascii "HEXAD \302\2472.1\0"
L_str_224:
    .ascii "HEXAD_PILLAR_6_NAME\0"
L_str_225:
    .ascii "COHERENCE_IMPACT\0"
L_str_226:
    .ascii "HEXAD \302\2472.1\0"
L_str_227:
    .ascii "HEXAD_TRIT_NEG_ASYM\0"
L_str_228:
    .ascii "trit-asym\0"
L_str_229:
    .ascii "HEXAD \302\2471.1\0"
L_str_230:
    .ascii "HEXAD_TRIT_NEG_BALANCED\0"
L_str_231:
    .ascii "trit-bal\0"
L_str_232:
    .ascii "HEXAD \302\2471.1\0"
L_str_233:
    .ascii "HEXAD_TRIT_NEG_PACKED\0"
L_str_234:
    .ascii "bits\0"
L_str_235:
    .ascii "HEXAD \302\2471.1\0"
L_str_236:
    .ascii "HEXAD_TRIT_ZERO_PACKED\0"
L_str_237:
    .ascii "bits\0"
L_str_238:
    .ascii "HEXAD \302\2471.1\0"
L_str_239:
    .ascii "HEXAD_TRIT_POS_PACKED\0"
L_str_240:
    .ascii "bits\0"
L_str_241:
    .ascii "HEXAD \302\2471.1\0"
L_str_242:
    .ascii "HEXAD_RESERVED_TRIT_BITPATTERN\0"
L_str_243:
    .ascii "bits\0"
L_str_244:
    .ascii "HEXAD \302\2472.2\0"
L_str_245:
    .ascii "HEXAD_TOTAL_POSSIBLE\0"
L_str_246:
    .ascii "count\0"
L_str_247:
    .ascii "HEXAD \302\2473.1\0"
L_str_248:
    .ascii "HEXAD_ADMISSIBLE\0"
L_str_249:
    .ascii "count\0"
L_str_250:
    .ascii "STDLIB \302\2476.5\0"
L_str_251:
    .ascii "HEXAD_ASYM_REACH6_BYTES\0"
L_str_252:
    .ascii "bytes\0"
L_str_253:
    .ascii "HEXAD \302\2473.1\0"
L_str_254:
    .ascii "HEXAD_REACH_CODE_BIT_HI\0"
L_str_255:
    .ascii "bit\0"
L_str_256:
    .ascii "STDLIB \302\2476.5\0"
L_str_257:
    .ascii "HEXAD_REACH_CODE_BIT_LO\0"
L_str_258:
    .ascii "bit\0"
L_str_259:
    .ascii "STDLIB \302\2476.5\0"
L_str_260:
    .ascii "HEXAD_METADATA_BIT_HI\0"
L_str_261:
    .ascii "bit\0"
L_str_262:
    .ascii "STDLIB \302\2476.5\0"
L_str_263:
    .ascii "HEXAD_METADATA_BIT_LO\0"
L_str_264:
    .ascii "bit\0"
L_str_265:
    .ascii "STDLIB \302\2476.5\0"
L_str_266:
    .ascii "HEXAD_REACH_CODE_COUNT\0"
L_str_267:
    .ascii "count\0"
L_str_268:
    .ascii "HEXAD \302\2473.1\0"
L_str_269:
    .ascii "HEXAD_PFS_BRICKING_HEXADS\0"
L_str_270:
    .ascii "count\0"
L_str_271:
    .ascii "HEXAD \302\2474.2\0"
L_str_272:
    .ascii "HEXAD_BITMAP_MHASH_FUNC\0"
L_str_273:
    .ascii "SHA-256\0"
L_str_274:
    .ascii "HEXAD \302\2473.4\0"
L_str_275:
    .ascii "\302\2477\0"
L_str_276:
    .ascii "PHASE_RING_COUNT\0"
L_str_277:
    .ascii "count\0"
L_str_278:
    .ascii "PHASES \302\2471\0"
L_str_279:
    .ascii "PHASE_RING_LATTICE_ORDER\0"
L_str_280:
    .ascii "R-2<=R-1<=R0<=R3\0"
L_str_281:
    .ascii "PHASES \302\2471\0"
L_str_282:
    .ascii "PHASE_CROSS_RING_CONSTRUCTORS\0"
L_str_283:
    .ascii "count\0"
L_str_284:
    .ascii "PHASES \302\2473\0"
L_str_285:
    .ascii "PHASE_MARSHALLING_RULES\0"
L_str_286:
    .ascii "count\0"
L_str_287:
    .ascii "PHASES \302\2474\0"
L_str_288:
    .ascii "XII_PHASE_PROMOTE_RATE\0"
L_str_289:
    .ascii "per-tick\0"
L_str_290:
    .ascii "PHASES \302\2475\0"
L_str_291:
    .ascii "PHASE_MAGIC_MSR_ADDRESS\0"
L_str_292:
    .ascii "MSR\0"
L_str_293:
    .ascii "PHASES \302\2473.1\0"
L_str_294:
    .ascii "\302\2478\0"
L_str_295:
    .ascii "SANCTUM_SEAL_COUNT\0"
L_str_296:
    .ascii "slots\0"
L_str_297:
    .ascii "SANCTUM \302\2471.1\0"
L_str_298:
    .ascii "SANCTUM_SLOT_INVALID\0"
L_str_299:
    .ascii "slot\0"
L_str_300:
    .ascii "SANCTUM \302\2471.1\0"
L_str_301:
    .ascii "SANCTUM_SLOT_DRTM_RELAUNCH\0"
L_str_302:
    .ascii "slot\0"
L_str_303:
    .ascii "SANCTUM \302\2471.1\0"
L_str_304:
    .ascii "SANCTUM_SLOT_PFS_VAR_SET\0"
L_str_305:
    .ascii "slot\0"
L_str_306:
    .ascii "SANCTUM \302\2471.1\0"
L_str_307:
    .ascii "SANCTUM_SLOT_PFS_DENY_QUOTE\0"
L_str_308:
    .ascii "slot\0"
L_str_309:
    .ascii "SANCTUM \302\2471.1\0"
L_str_310:
    .ascii "SANCTUM_SLOT_CRCC_KEY_EXPORT\0"
L_str_311:
    .ascii "slot\0"
L_str_312:
    .ascii "SANCTUM \302\2471.1\0"
L_str_313:
    .ascii "SANCTUM_SLOT_PHOENIX_EMERGENCY\0"
L_str_314:
    .ascii "slot\0"
L_str_315:
    .ascii "SANCTUM \302\2471.1\0"
L_str_316:
    .ascii "SANCTUM_SLOT_CHRONOS_SET_EPOCH\0"
L_str_317:
    .ascii "slot\0"
L_str_318:
    .ascii "SANCTUM \302\2471.1\0"
L_str_319:
    .ascii "SANCTUM_SLOT_COMPROMISE_QUOTE\0"
L_str_320:
    .ascii "slot\0"
L_str_321:
    .ascii "SANCTUM \302\2471.1\0"
L_str_322:
    .ascii "SANCTUM_SLOT_PHOENIX_BOOKMARK\0"
L_str_323:
    .ascii "slot\0"
L_str_324:
    .ascii "SANCTUM \302\2471.1\0"
L_str_325:
    .ascii "SANCTUM_SLOT_COMPILE_MODULE\0"
L_str_326:
    .ascii "slot\0"
L_str_327:
    .ascii "SANCTUM \302\2471.1\0"
L_str_328:
    .ascii "SANCTUM_GATE_HARDENING\0"
L_str_329:
    .ascii "IBPB+VERW+SSBD+RSP-swap+GPR/FPR/XMM-save\0"
L_str_330:
    .ascii "SANCTUM \302\2472.1\0"
L_str_331:
    .ascii "DRTM_QUOTE_BYTE_SIZE\0"
L_str_332:
    .ascii "bytes\0"
L_str_333:
    .ascii "SANCTUM \302\2474\0"
L_str_334:
    .ascii "SANCTUM_PER_CPU_FRAME_SIZE\0"
L_str_335:
    .ascii "bytes\0"
L_str_336:
    .ascii "STDLIB \302\2478.8\0"
L_str_337:
    .ascii "\302\2479\0"
L_str_338:
    .ascii "TRINITY_LAYER_COUNT\0"
L_str_339:
    .ascii "count\0"
L_str_340:
    .ascii "TRINITY \302\2471\0"
L_str_341:
    .ascii "TRINITY_GATE_CONJUNCTS\0"
L_str_342:
    .ascii "count\0"
L_str_343:
    .ascii "TRINITY \302\2471.3\0"
L_str_344:
    .ascii "TRINITY_SCBA_BYTES\0"
L_str_345:
    .ascii "bytes\0"
L_str_346:
    .ascii "TRINITY \302\2471.1\0"
L_str_347:
    .ascii "TRINITY_SCBA_BITS\0"
L_str_348:
    .ascii "bits\0"
L_str_349:
    .ascii "TRINITY \302\2471.1\0"
L_str_350:
    .ascii "TRINITY_SCBA_HASH_FN\0"
L_str_351:
    .ascii "first16(BLAKE3(post_state))\0"
L_str_352:
    .ascii "TRINITY \302\2471.1\0"
L_str_353:
    .ascii "TRINITY_FAILURE_MODE_CODES\0"
L_str_354:
    .ascii "count\0"
L_str_355:
    .ascii "TRINITY \302\2472\0"
L_str_356:
    .ascii "TRINITY_CONVERGENCE_PT_SIZE\0"
L_str_357:
    .ascii "bytes\0"
L_str_358:
    .ascii "STDLIB \302\2479.5\0"
L_str_359:
    .ascii "\302\24710\0"
L_str_360:
    .ascii "MODULE_CLOSURE_ROOT_HASH_FN\0"
L_str_361:
    .ascii "SHA-256\0"
L_str_362:
    .ascii "MODULES \302\2471\0"
L_str_363:
    .ascii "MODULE_DEPLOY_FLAG_COUNT\0"
L_str_364:
    .ascii "count\0"
L_str_365:
    .ascii "MODULES \302\2476.1\0"
L_str_366:
    .ascii "XII_MOD_PROMOTE_RATE\0"
L_str_367:
    .ascii "per-tick\0"
L_str_368:
    .ascii "MODULES \302\24710\0"
L_str_369:
    .ascii "MODULE_TRANSMISSION_RULES\0"
L_str_370:
    .ascii "count\0"
L_str_371:
    .ascii "MODULES \302\2473.1\0"
L_str_372:
    .ascii "MODULE_FP_TOLERANCE_PERCENT\0"
L_str_373:
    .ascii "percent\0"
L_str_374:
    .ascii "MODULES \302\2474.1\0"
L_str_375:
    .ascii "\302\24711\0"
L_str_376:
    .ascii "XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK\0"
L_str_377:
    .ascii "per-tick\0"
L_str_378:
    .ascii "CATALYST \302\2472.3\0"
L_str_379:
    .ascii "CATALYST_PROMOTION_GATE_COUNT\0"
L_str_380:
    .ascii "count\0"
L_str_381:
    .ascii "CATALYST \302\2472.1\0"
L_str_382:
    .ascii "CATALYST_SYNTHESIS_CAP_COUNT\0"
L_str_383:
    .ascii "count\0"
L_str_384:
    .ascii "CATALYST \302\2473\0"
L_str_385:
    .ascii "CATALYST_INVIOLABLE_RAILS\0"
L_str_386:
    .ascii "count\0"
L_str_387:
    .ascii "CATALYST \302\2474.1\0"
L_str_388:
    .ascii "MOBIUS_COHERENCE_FLOOR_Q14\0"
L_str_389:
    .ascii "CATALYST \302\2472.1\0"
L_str_390:
    .ascii "CATALYST_BURN_IN_TICKS\0"
L_str_391:
    .ascii "ticks\0"
L_str_392:
    .ascii "CATALYST \302\2472.1\0"
L_str_393:
    .ascii "CATALYST_OPERATOR_OVERRIDE_MECHS\0"
L_str_394:
    .ascii "count\0"
L_str_395:
    .ascii "CATALYST \302\2474.3\0"
L_str_396:
    .ascii "\302\24712\0"
L_str_397:
    .ascii "FED_TIER_COUNT\0"
L_str_398:
    .ascii "count\0"
L_str_399:
    .ascii "FEDERATION \302\2471\0"
L_str_400:
    .ascii "FED_TIER1_QUORUM\0"
L_str_401:
    .ascii "FEDERATION \302\2474\0"
L_str_402:
    .ascii "FED_TIER2_QUORUM\0"
L_str_403:
    .ascii "FEDERATION \302\2474\0"
L_str_404:
    .ascii "FED_TIER3_QUORUM\0"
L_str_405:
    .ascii "(N,N) unanimous\0"
L_str_406:
    .ascii "FEDERATION \302\2474\0"
L_str_407:
    .ascii "FED_REPLICATION_POLICY_VALUES\0"
L_str_408:
    .ascii "count\0"
L_str_409:
    .ascii "LEX \302\2475.1\0"
L_str_410:
    .ascii "FED_DISCOVERY_CADENCE_PER_TICK\0"
L_str_411:
    .ascii "per-tick\0"
L_str_412:
    .ascii "STDLIB \302\24712.6\0"
L_str_413:
    .ascii "FED_AH_TRAILER_ACTIVE\0"
L_str_414:
    .ascii "FEDERATION \302\2475\0"
L_str_415:
    .ascii "\302\24713\0"
L_str_416:
    .ascii "COG_PRIMITIVE_COUNT\0"
L_str_417:
    .ascii "count\0"
L_str_418:
    .ascii "LEX \302\2474.1.5\0"
L_str_419:
    .ascii "EPISTEMIC_CONFIDENCE_THRESHOLD_Q14\0"
L_str_420:
    .ascii "TYPES \302\2478.3\0"
L_str_421:
    .ascii "COG_EXPLAIN_LEVELS\0"
L_str_422:
    .ascii "count\0"
L_str_423:
    .ascii "LEX \302\2474.1.5\0"
L_str_424:
    .ascii "COG_REFLECT_TARGETS\0"
L_str_425:
    .ascii "count\0"
L_str_426:
    .ascii "LEX \302\2474.1.5\0"
L_str_427:
    .ascii "COG_NARRATIVE_DECL_PER_MODULE\0"
L_str_428:
    .ascii "count\0"
L_str_429:
    .ascii "GRAMMAR \302\2475.6\0"
L_str_430:
    .ascii "\302\24714\0"
L_str_431:
    .ascii "CONF_CRITERION_COUNT\0"
L_str_432:
    .ascii "count\0"
L_str_433:
    .ascii "CONFORMANCE \302\2471-3\0"
L_str_434:
    .ascii "CONF_CORE_LANG_CRITERIA\0"
L_str_435:
    .ascii "count\0"
L_str_436:
    .ascii "CONFORMANCE \302\2471\0"
L_str_437:
    .ascii "CONF_SUBSTRATE_RUNTIME_CRITERIA\0"
L_str_438:
    .ascii "count\0"
L_str_439:
    .ascii "CONFORMANCE \302\2472\0"
L_str_440:
    .ascii "CONF_COGNITIVE_LAYER_CRITERIA\0"
L_str_441:
    .ascii "count\0"
L_str_442:
    .ascii "CONFORMANCE \302\2473\0"
L_str_443:
    .ascii "\302\24715\0"
L_str_444:
    .ascii "ABI_LEGAL_NAME_COUNT\0"
L_str_445:
    .ascii "count\0"
L_str_446:
    .ascii "ABI \302\2471.1\0"
L_str_447:
    .ascii "ABI_LEGAL_NAME\0"
L_str_448:
    .ascii "c-msvc-x64\0"
L_str_449:
    .ascii "ABI \302\2471.1\0"
L_str_450:
    .ascii "ABI_RESERVED_NAME_COUNT\0"
L_str_451:
    .ascii "count\0"
L_str_452:
    .ascii "ABI \302\2473\0"
L_str_453:
    .ascii "ABI_EXTERN_INVERSE\0"
L_str_454:
    .ascii "Compromise<MEDIUM>\0"
L_str_455:
    .ascii "ABI \302\2471.2\0"
L_str_456:
    .ascii "ABI_EXTERN_HEXAD\0"
L_str_457:
    .ascii "EXTERN_C_CALL\0"
L_str_458:
    .ascii "ABI \302\2471.2\0"
L_str_459:
    .ascii "ABI_EXTERN_RING_R0\0"
L_str_460:
    .ascii "ring\0"
L_str_461:
    .ascii "ABI \302\2471.2\0"
L_str_462:
    .ascii "ABI_EXTERN_RING_R3\0"
L_str_463:
    .ascii "ring\0"
L_str_464:
    .ascii "ABI \302\2471.2\0"
L_str_465:
    .ascii "\302\24716\0"
L_str_466:
    .ascii "R1_SLOT_COUNT_SEALED\0"
L_str_467:
    .ascii "count\0"
L_str_468:
    .ascii "INDEX \302\2471\0"
L_str_469:
    .ascii "R1_COMPOSITE_HASH_FN\0"
L_str_470:
    .ascii "SHA-256\0"
L_str_471:
    .ascii "INDEX \302\2472\0"
L_str_472:
    .ascii "R1_CONCATENATION_DISCIPLINE\0"
L_str_473:
    .ascii "INDEX \302\2471 order, big-endian, no separator\0"
L_str_474:
    .ascii "STDLIB \302\24717.1\0"
L_str_475:
    .ascii "R1_RESERVED_WAVE_SLOTS\0"
L_str_476:
    .ascii "count\0"
L_str_477:
    .ascii "STDLIB \302\24720\0"
L_str_478:
    .ascii "\302\24717.1\0"
L_str_479:
    .ascii "ZK_ROLLUP_COMPACTION_THRESHOLD\0"
L_str_480:
    .ascii "witnesses\0"
L_str_481:
    .ascii "Item 175\0"
L_str_482:
    .ascii "ZK_PROOF_TARGET_BYTES\0"
L_str_483:
    .ascii "bytes\0"
L_str_484:
    .ascii "Item 175\0"
L_str_485:
    .ascii "ZK_DECOMMITMENT_RETENTION\0"
L_str_486:
    .ascii "segments\0"
L_str_487:
    .ascii "Item 175\0"
L_str_488:
    .ascii "\302\24717.2\0"
L_str_489:
    .ascii "CRYPTO_SUITE_ID_WIDTH_BITS\0"
L_str_490:
    .ascii "bits\0"
L_str_491:
    .ascii "Item 176\0"
L_str_492:
    .ascii "CRYPTO_SUITE_PRE_QUANTUM\0"
L_str_493:
    .ascii "suite-id\0"
L_str_494:
    .ascii "Item 176\0"
L_str_495:
    .ascii "CRYPTO_SUITE_POST_QUANTUM_1\0"
L_str_496:
    .ascii "suite-id\0"
L_str_497:
    .ascii "Item 176\0"
L_str_498:
    .ascii "CRYPTO_SUITE_POST_QUANTUM_2\0"
L_str_499:
    .ascii "suite-id\0"
L_str_500:
    .ascii "Item 176\0"
L_str_501:
    .ascii "CRYPTO_SUITE_HYBRID\0"
L_str_502:
    .ascii "suite-id\0"
L_str_503:
    .ascii "Item 176\0"
L_str_504:
    .ascii "CRYPTO_ACTIVE_SUITE_DRTM_OFFSET\0"
L_str_505:
    .ascii "offset\0"
L_str_506:
    .ascii "Item 176\0"
L_str_507:
    .ascii "\302\24717.3\0"
L_str_508:
    .ascii "GENESIS_INSTALLER_ABI\0"
L_str_509:
    .ascii "c-msvc-x64\0"
L_str_510:
    .ascii "Item 177\0"
L_str_511:
    .ascii "GENESIS_DISCOVERY_CADENCE_PER_TICK\0"
L_str_512:
    .ascii "per-tick\0"
L_str_513:
    .ascii "Item 177\0"
L_str_514:
    .ascii "\302\24717.4\0"
L_str_515:
    .ascii "FOUNDERS_ANCHOR_PUBKEY_SIZE_ED25519\0"
L_str_516:
    .ascii "bytes\0"
L_str_517:
    .ascii "Item 178\0"
L_str_518:
    .ascii "FOUNDERS_ANCHOR_COSIGNED_FLAG_BIT\0"
L_str_519:
    .ascii "bit\0"
L_str_520:
    .ascii "Item 178\0"
L_str_521:
    .ascii "FOUNDERS_ANCHOR_K_RECOMMENDED\0"
L_str_522:
    .ascii "count\0"
L_str_523:
    .ascii "Item 178\0"
L_str_524:
    .ascii "FOUNDERS_ANCHOR_N_RECOMMENDED\0"
L_str_525:
    .ascii "count\0"
L_str_526:
    .ascii "Item 178\0"
L_str_527:
    .ascii "FOUNDERS_ANCHOR_REJECTION_LAYERS\0"
L_str_528:
    .ascii "count\0"
L_str_529:
    .ascii "Item 178\0"
L_str_530:
    .ascii "\302\24718\0"
L_str_531:
    .ascii "FOUNDERS_ANCHOR_INVARIANT_COUNT\0"
L_str_532:
    .ascii "count\0"
L_str_533:
    .ascii "\302\24718 list\0"
L_str_534:
    .ascii "FA_INV_PFS_BRICKING_UNREP\0"
L_str_535:
    .ascii "6 PFS bricking-class hexads unrepresentable\0"
L_str_536:
    .ascii "HEXAD \302\2474\0"
L_str_537:
    .ascii "FA_INV_PUBKEY_SOVEREIGN_VETO\0"
L_str_538:
    .ascii "founders_anchor_pubkey is Cap<sovereign_veto,FOUNDER>\0"
L_str_539:
    .ascii "FOUNDERS-ANCHOR \302\2473\0"
L_str_540:
    .ascii "FA_INV_TIER3_REQUIRES_COSIG\0"
L_str_541:
    .ascii "every Tier-3 amend.apply requires Anchor cosig\0"
L_str_542:
    .ascii "FOUNDERS-ANCHOR \302\2473\0"
L_str_543:
    .ascii "FA_INV_REMOVE_ANCHOR_UNREP\0"
L_str_544:
    .ascii "removing Anchor produces unrepresentable hexad\0"
L_str_545:
    .ascii "FOUNDERS-ANCHOR \302\2473\0"
L_str_546:
    .ascii "FA_INV_5_CATALYST_RAILS\0"
L_str_547:
    .ascii "5 Catalyst inviolable safety rails\0"
L_str_548:
    .ascii "CATALYST \302\2474.1\0"
L_str_549:
    .ascii "FA_INV_3_PFS_REJECT_LAYERS\0"
L_str_550:
    .ascii "3 PFS-bricking rejection layers\0"
L_str_551:
    .ascii "HEXAD \302\2474.5\0"
L_str_552:
    .ascii "FA_INV_32STEP_SID_TOTAL\0"
L_str_553:
    .ascii "32-step SID plan total\0"
L_str_554:
    .ascii "CYCLES \302\2473.2\0"
L_str_555:
    .ascii "FA_INV_LAYER3_FULL_4CONJUNCT\0"
L_str_556:
    .ascii "Layer 3 Trinity full 4-conjunct (no shortcut)\0"
L_str_557:
    .ascii "TRINITY \302\2471.3\0"
L_str_558:
    .ascii "FA_INV_WITNESS_CHAIN_CONTINUITY\0"
L_str_559:
    .ascii "witness chain continuity across rings/modules\0"
L_str_560:
    .ascii "C-17\0"
L_str_561:
    .ascii "FA_INV_IRPD_ONLY_PRIV_WRITES\0"
L_str_562:
    .ascii "IRPD-only privileged writes (no raw WRMSR/MOV CR3)\0"
L_str_563:
    .ascii "C-16\0"
L_str_564:
    .ascii "\302\24719\0"
L_str_565:
    .ascii "CASCADE_RULE_COUNT\0"
L_str_566:
    .ascii "count\0"
L_str_567:
    .ascii "\302\24719 table\0"
L_str_568:
    .ascii "CASCADE_WITNESS_BYTE_SIZE\0"
L_str_569:
    .ascii "R1.A5+R1.A8+R1.B1\0"
L_str_570:
    .ascii "\302\24719\0"
L_str_571:
    .ascii "CASCADE_MOBIUS_FLOOR\0"
L_str_572:
    .ascii "R1.A9+R1.B1+R1.B3\0"
L_str_573:
    .ascii "\302\24719\0"
L_str_574:
    .ascii "CASCADE_MNEME_PROMOTION_RATE\0"
L_str_575:
    .ascii "R1.B1\0"
L_str_576:
    .ascii "\302\24719\0"
L_str_577:
    .ascii "CASCADE_CRYPTO_SUITE\0"
L_str_578:
    .ascii "R1.A1..R1.IDX (full)\0"
L_str_579:
    .ascii "\302\24719\0"
L_str_580:
    .ascii "CASCADE_SANCTUM_SLOT_COUNT\0"
L_str_581:
    .ascii "R1.A8\0"
L_str_582:
    .ascii "\302\24719\0"
L_str_583:
    .ascii "CASCADE_UNIVERSE_LADDER_DEPTH\0"
L_str_584:
    .ascii "R1.A3+R1.B3 (R2-territory)\0"
L_str_585:
    .ascii "\302\24719\0"
L_str_586:
    .ascii "CASCADE_HEXAD_PILLAR_COUNT\0"
L_str_587:
    .ascii "R1.A6+R1.A3+R1.B3 (R2-territory)\0"
L_str_588:
    .ascii "\302\24719\0"
L_str_589:
    .ascii "III-CONSTANTS-D2\0"
L_str_590:
    .ascii "LEX_KEYWORD_COUNT\0"
L_str_591:
    .ascii "NOT_A_CONSTANT\0"
L_str_592:
    .ascii "LEX_KEYWORD_COUNT\0"
L_str_593:
    .ascii "LEX_KEYWORD_COUNT\0"
L_str_594:
    .ascii "LEX_PUNCTUATOR_COUNT\0"
L_str_595:
    .ascii "EFFECT_PFS_BRICKING_OPS\0"
L_str_596:
    .ascii "LEX_PUNCTUATOR_COUNT\0"
L_str_597:
    .ascii "SANCTUM_SLOT_INVALID\0"
L_str_598:
    .ascii "LEX_KEYWORD_COUNT\0"
L_str_599:
    .ascii "TYPE_UNIVERSE_COUNT\0"
L_str_600:
    .ascii "LEX_PUNCTUATOR_COUNT\0"
L_str_601:
    .ascii "LEX_PUNCTUATOR_COUNT\0"
    .section .rodata
L_CT_U64:
    .quad 0x1
L_CT_S64:
    .quad 0x2
L_CT_Q14:
    .quad 0x3
L_CT_BAND:
    .quad 0x4
L_CT_TUPLE2:
    .quad 0x5
L_CT_BOOL:
    .quad 0x6
L_CT_STRING:
    .quad 0x7
L_MT_NEVER:
    .quad 0x1
L_MT_R2:
    .quad 0x2
L_MT_AMEND:
    .quad 0x3
L_MT_CATALYST:
    .quad 0x4
L_MT_DERIVED:
    .quad 0x5
L_MT_OPTARGET:
    .quad 0x6
L_MT_OPPOLICY:
    .quad 0x7
L_MT_SCHED:
    .quad 0x8
L_MT_SEALED:
    .quad 0x9
L_CV_OK:
    .quad 0x0
L_CV_NOT_FOUND:
    .quad 0x1
L_CV_WRONG_TIER:
    .quad 0x2
L_CV_NEVER:
    .quad 0x3
L_CV_REGRESS:
    .quad 0x4
L_CV_INVALID:
    .quad 0x5
L_CV_LOCKED:
    .quad 0x6
L_CL_MAX:
    .quad 0x100
    .section .bss
    .global L_CL_BUF
L_CL_BUF:
    .zero 196608
    .section .data
    .global L_CL_POS
L_CL_POS:
    .quad 0x0
    .global L_CL_COUNT
L_CL_COUNT:
    .quad 0x0
    .global L_CL_BUILT
L_CL_BUILT:
    .quad 0x0
    .section .bss
    .global L_CL_SECT
L_CL_SECT:
    .zero 128
    .section .data
    .global L_CL_SLEN
L_CL_SLEN:
    .quad 0x0
    .section .bss
    .global L_CL_VTMP
L_CL_VTMP:
    .zero 512
    .global L_CL_ROOT
L_CL_ROOT:
    .zero 256
    .global L_CL_TYPE
L_CL_TYPE:
    .zero 2048
    .global L_CL_TIER
L_CL_TIER:
    .zero 2048
    .global L_CL_NOFF
L_CL_NOFF:
    .zero 2048
    .global L_CL_NLEN
L_CL_NLEN:
    .zero 2048
    .global L_CL_VOFF
L_CL_VOFF:
    .zero 2048
    .global L_CL_VLEN
L_CL_VLEN:
    .zero 2048
    .global L_CL_NPOOL
L_CL_NPOOL:
    .zero 65536
    .section .data
    .global L_CL_NPOS
L_CL_NPOS:
    .quad 0x0
    .section .bss
    .global L_CL_VPOOL
L_CL_VPOOL:
    .zero 65536
    .section .data
    .global L_CL_VPOS
L_CL_VPOS:
    .quad 0x0
    .section .bss
    .global L_CL_RT
L_CL_RT:
    .zero 256
    .global L_CL_NV8
L_CL_NV8:
    .zero 64
    .section .iii.ring3,"n"
    .asciz "cl_put"
    .text
    .seh_proc L_cl_put
L_cl_put:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    leaq L_CL_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_loop_top_0:
    movq -40(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_1
    movq -24(%rbp), %rax
    pushq %rax
    movq L_CL_POS(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_0
L_loop_end_1:
    movq L_CL_POS(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_CL_POS(%rip)
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_u32"
    .text
    .seh_proc L_cl_u32
L_cl_u32:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    leaq L_CL_BUF(%rip), %rax
    pushq %rax
    movq L_CL_POS(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_BUF(%rip), %rax
    pushq %rax
    movq L_CL_POS(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $8, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_BUF(%rip), %rax
    pushq %rax
    movq L_CL_POS(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $16, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_BUF(%rip), %rax
    pushq %rax
    movq L_CL_POS(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $24, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq L_CL_POS(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_CL_POS(%rip)
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_u8"
    .text
    .seh_proc L_cl_u8
L_cl_u8:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    leaq L_CL_BUF(%rip), %rax
    pushq %rax
    movq L_CL_POS(%rip), %rax
    pushq %rax
    movzbq -8(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq L_CL_POS(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_CL_POS(%rip)
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_lp"
    .text
    .seh_proc L_cl_lp
L_cl_lp:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_cl_u32
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_put
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_sect"
    .text
    .seh_proc L_cl_sect
L_cl_sect:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    leaq L_CL_SECT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_loop_top_2:
    movq -40(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_3
    movq -24(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_2
L_loop_end_3:
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, L_CL_SLEN(%rip)
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_v_u64"
    .text
    .seh_proc L_cl_v_u64
L_cl_v_u64:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_4:
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_5
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_4
L_loop_end_5:
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_emit"
    .text
    .seh_proc L_cl_emit
L_cl_emit:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq %r9, -32(%rbp)
    movq 48(%rbp), %rax
    movq %rax, -40(%rbp)
    movq 56(%rbp), %rax
    movq %rax, -48(%rbp)
    movq 64(%rbp), %rax
    movq %rax, -56(%rbp)
    movq 72(%rbp), %rax
    movq %rax, -64(%rbp)
    movq 80(%rbp), %rax
    movq %rax, -72(%rbp)
    movq 88(%rbp), %rax
    movq %rax, -80(%rbp)
    movl L_CL_COUNT(%rip), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movl L_CL_COUNT(%rip), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    leaq L_CL_NOFF(%rip), %rax
    pushq %rax
    movq -96(%rbp), %rax
    pushq %rax
    movq L_CL_NPOS(%rip), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_CL_NLEN(%rip), %rax
    pushq %rax
    movq -96(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_CL_NPOOL(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
L_loop_top_6:
    movq -120(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_7
    movq -104(%rbp), %rax
    pushq %rax
    movq L_CL_NPOS(%rip), %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -112(%rbp), %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -120(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_6
L_loop_end_7:
    movq L_CL_NPOS(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_CL_NPOS(%rip)
    leaq L_CL_VOFF(%rip), %rax
    pushq %rax
    movq -96(%rbp), %rax
    pushq %rax
    movq L_CL_VPOS(%rip), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_CL_VLEN(%rip), %rax
    pushq %rax
    movq -96(%rbp), %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_CL_VPOOL(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -128(%rbp)
    movq -72(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
L_loop_top_8:
    movq -144(%rbp), %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_9
    movq -128(%rbp), %rax
    pushq %rax
    movq L_CL_VPOS(%rip), %rax
    pushq %rax
    movq -144(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -136(%rbp), %rax
    pushq %rax
    movq -144(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -144(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_8
L_loop_end_9:
    movq L_CL_VPOS(%rip), %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_CL_VPOS(%rip)
    leaq L_CL_TYPE(%rip), %rax
    pushq %rax
    movq -96(%rbp), %rax
    pushq %rax
    movzbq -24(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_TIER(%rip), %rax
    pushq %rax
    movq -96(%rbp), %rax
    pushq %rax
    movzbq -32(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movl -88(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_cl_u32
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_cl_u8
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_cl_u8
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_lp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_lp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -64(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_lp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq L_CL_SLEN(%rip), %rax
    pushq %rax
    leaq L_CL_SECT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_lp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_cl_u32
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -80(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_put
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_cl_u8
    addq $32, %rsp
    pushq %rax
    popq %rax
    movl L_CL_COUNT(%rip), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_CL_COUNT(%rip)
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_u"
    .text
    .seh_proc L_cl_u
L_cl_u:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq %r9, -32(%rbp)
    movq 48(%rbp), %rax
    movq %rax, -40(%rbp)
    movq 56(%rbp), %rax
    movq %rax, -48(%rbp)
    movq 64(%rbp), %rax
    movq %rax, -56(%rbp)
    movq 72(%rbp), %rax
    movq %rax, -64(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_cl_v_u64
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -72(%rbp), %rax
    pushq %rax
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movzbq -64(%rbp), %rax
    pushq %rax
    movzbq L_CT_U64(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_emit
    addq $32, %rsp
    addq $48, %rsp
    pushq %rax
    popq %rax
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_s"
    .text
    .seh_proc L_cl_s
L_cl_s:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq %r9, -32(%rbp)
    movq 48(%rbp), %rax
    movq %rax, -40(%rbp)
    movq 56(%rbp), %rax
    movq %rax, -48(%rbp)
    movq 64(%rbp), %rax
    movq %rax, -56(%rbp)
    movq 72(%rbp), %rax
    movq %rax, -64(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_cl_v_u64
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -72(%rbp), %rax
    pushq %rax
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movzbq -64(%rbp), %rax
    pushq %rax
    movzbq L_CT_S64(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_emit
    addq $32, %rsp
    addq $48, %rsp
    pushq %rax
    popq %rax
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_q"
    .text
    .seh_proc L_cl_q
L_cl_q:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq %r9, -32(%rbp)
    movq 48(%rbp), %rax
    movq %rax, -40(%rbp)
    movq 56(%rbp), %rax
    movq %rax, -48(%rbp)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    shrq $8, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movabsq $0x2, %rax
    pushq %rax
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_1(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movzbq -48(%rbp), %rax
    pushq %rax
    movzbq L_CT_Q14(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_emit
    addq $32, %rsp
    addq $48, %rsp
    pushq %rax
    popq %rax
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_b"
    .text
    .seh_proc L_cl_b
L_cl_b:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq %r9, -32(%rbp)
    movq 48(%rbp), %rax
    movq %rax, -40(%rbp)
    movq 56(%rbp), %rax
    movq %rax, -48(%rbp)
    movq 64(%rbp), %rax
    movq %rax, -56(%rbp)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $8, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $16, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $24, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $8, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $16, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $24, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movabsq $0x8, %rax
    pushq %rax
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_2(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movzbq -56(%rbp), %rax
    pushq %rax
    movzbq L_CT_BAND(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_emit
    addq $32, %rsp
    addq $48, %rsp
    pushq %rax
    popq %rax
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_t2"
    .text
    .seh_proc L_cl_t2
L_cl_t2:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq %r9, -32(%rbp)
    movq 48(%rbp), %rax
    movq %rax, -40(%rbp)
    movq 56(%rbp), %rax
    movq %rax, -48(%rbp)
    movq 64(%rbp), %rax
    movq %rax, -56(%rbp)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $8, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $16, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $24, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $8, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $16, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $24, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movabsq $0x8, %rax
    pushq %rax
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_3(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movzbq -56(%rbp), %rax
    pushq %rax
    movzbq L_CT_TUPLE2(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_emit
    addq $32, %rsp
    addq $48, %rsp
    pushq %rax
    popq %rax
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_bool"
    .text
    .seh_proc L_cl_bool
L_cl_bool:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq %r9, -32(%rbp)
    movq 48(%rbp), %rax
    movq %rax, -40(%rbp)
    movq 56(%rbp), %rax
    movq %rax, -48(%rbp)
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movzbq -24(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movabsq $0x1, %rax
    pushq %rax
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_4(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movzbq -48(%rbp), %rax
    pushq %rax
    movzbq L_CT_BOOL(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_emit
    addq $32, %rsp
    addq $48, %rsp
    pushq %rax
    popq %rax
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_str"
    .text
    .seh_proc L_cl_str
L_cl_str:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq %r9, -32(%rbp)
    movq 48(%rbp), %rax
    movq %rax, -40(%rbp)
    movq 56(%rbp), %rax
    movq %rax, -48(%rbp)
    movq 64(%rbp), %rax
    movq %rax, -56(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_5(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movzbq -56(%rbp), %rax
    pushq %rax
    movzbq L_CT_STRING(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_emit
    addq $32, %rsp
    addq $48, %rsp
    pushq %rax
    popq %rax
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_build"
    .text
    .seh_proc L_cl_build
L_cl_build:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movzbq L_CL_BUILT(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_11
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movabsq $0x14, %rax
    pushq %rax
    popq %rax
    movq %rax, L_CL_POS(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movl %eax, L_CL_COUNT(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_CL_NPOS(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_CL_VPOS(%rip)
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_6(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_9(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_8(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2f, %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    leaq L_str_7(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_12(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_11(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    leaq L_str_10(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_15(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_14(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3f, %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    leaq L_str_13(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_18(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_17(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_16(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_21(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_20(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    leaq L_str_19(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_24(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_23(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_str_22(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_27(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_26(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_25(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_30(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_29(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    leaq L_str_28(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_33(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_32(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_str_31(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_36(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_35(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_34(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_39(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_38(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    leaq L_str_37(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_42(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_41(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    leaq L_str_40(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_45(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_44(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    leaq L_str_43(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_48(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_47(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_46(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_51(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    leaq L_str_50(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x100, %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    leaq L_str_49(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_54(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_53(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1000000, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_52(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_57(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_56(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_55(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_60(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    leaq L_str_59(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xf6, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_58(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_62(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    leaq L_str_61(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_bool
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_65(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    leaq L_str_64(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    leaq L_str_63(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_66(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_69(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_68(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_67(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_72(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_71(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    leaq L_str_70(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_75(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_74(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_73(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_78(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_77(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_76(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_81(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_80(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    leaq L_str_79(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_84(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_83(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xc0, %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    leaq L_str_82(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_87(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_86(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x80, %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    leaq L_str_85(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_90(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_89(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    leaq L_str_88(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_93(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_92(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    leaq L_str_91(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_96(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_95(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    leaq L_str_94(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_99(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_98(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_97(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_102(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_101(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    leaq L_str_100(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    leaq L_str_105(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_104(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xbb8, %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    leaq L_str_103(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_106(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_109(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_108(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_107(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_112(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_111(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    leaq L_str_110(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_115(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_114(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    leaq L_str_113(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_118(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_117(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    leaq L_str_116(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_119(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_122(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_121(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x80, %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    leaq L_str_120(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_125(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    leaq L_str_124(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    leaq L_str_123(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_128(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_127(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    leaq L_str_126(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_131(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    leaq L_str_130(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    leaq L_str_129(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_134(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_133(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    leaq L_str_132(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_137(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    leaq L_str_136(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    leaq L_str_135(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_140(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_139(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    leaq L_str_138(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_143(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    leaq L_str_142(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x64, %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    leaq L_str_141(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_146(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_145(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    leaq L_str_144(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_149(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    leaq L_str_148(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x68, %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    leaq L_str_147(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_152(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_151(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    leaq L_str_150(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_155(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_154(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1000, %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    leaq L_str_153(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_158(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_157(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_156(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_161(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_160(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    leaq L_str_159(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_164(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_163(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x200, %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    leaq L_str_162(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_166(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_str_165(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_168(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2f, %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_167(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_170(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4f, %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    leaq L_str_169(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_172(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6f, %rax
    pushq %rax
    movabsq $0x50, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_171(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_174(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x7f, %rax
    pushq %rax
    movabsq $0x70, %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_173(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_176(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x9f, %rax
    pushq %rax
    movabsq $0x80, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    leaq L_str_175(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_178(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xbf, %rax
    pushq %rax
    movabsq $0xa0, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    leaq L_str_177(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_180(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xcf, %rax
    pushq %rax
    movabsq $0xc0, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    leaq L_str_179(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_182(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xef, %rax
    pushq %rax
    movabsq $0xd0, %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_181(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_184(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    movabsq $0xf0, %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_183(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_186(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x10f, %rax
    pushq %rax
    movabsq $0x100, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    leaq L_str_185(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_188(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x12f, %rax
    pushq %rax
    movabsq $0x110, %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_187(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_190(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x14f, %rax
    pushq %rax
    movabsq $0x130, %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_189(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_192(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x15f, %rax
    pushq %rax
    movabsq $0x150, %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_191(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_194(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x17f, %rax
    pushq %rax
    movabsq $0x160, %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_193(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_196(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x18f, %rax
    pushq %rax
    movabsq $0x180, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    leaq L_str_195(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_198(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1af, %rax
    pushq %rax
    movabsq $0x190, %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    leaq L_str_197(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_200(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1c6, %rax
    pushq %rax
    movabsq $0x1b0, %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_str_199(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_202(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1cf, %rax
    pushq %rax
    movabsq $0x1c7, %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_str_201(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_204(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1ff, %rax
    pushq %rax
    movabsq $0x1d0, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_203(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_b
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_205(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_208(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_207(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_206(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_211(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_210(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_209(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_214(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    leaq L_str_213(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_212(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_217(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    leaq L_str_216(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_215(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_220(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_str_219(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_218(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_223(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_222(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_221(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_226(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_str_225(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_224(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_229(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_228(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    negq %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_227(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_s
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_232(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_231(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    negq %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    leaq L_str_230(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_s
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_235(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_234(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    leaq L_str_233(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_238(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_237(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    leaq L_str_236(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_241(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_240(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    leaq L_str_239(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_244(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_243(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    leaq L_str_242(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_247(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_246(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2d9, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_245(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_250(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_249(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x90, %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_str_248(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_253(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_252(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x90, %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    leaq L_str_251(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_256(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_255(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    leaq L_str_254(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_259(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_258(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    leaq L_str_257(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_262(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_261(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    leaq L_str_260(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_265(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_264(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    leaq L_str_263(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_268(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_267(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    leaq L_str_266(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_271(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_270(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    leaq L_str_269(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_DERIVED(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_274(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_273(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    leaq L_str_272(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_275(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    leaq L_str_278(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_277(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_str_276(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    leaq L_str_281(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_str_280(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    leaq L_str_279(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    leaq L_str_284(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_283(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    leaq L_str_282(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    leaq L_str_287(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_286(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    leaq L_str_285(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    leaq L_str_290(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_289(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    leaq L_str_288(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_293(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_292(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xc001f100, %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    leaq L_str_291(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_294(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_297(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_296(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_295(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_300(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_299(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_298(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_303(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_302(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    leaq L_str_301(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_306(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_305(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    leaq L_str_304(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_309(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_308(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    leaq L_str_307(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_312(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_311(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    leaq L_str_310(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_315(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_314(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    leaq L_str_313(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_318(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_317(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    leaq L_str_316(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_321(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_320(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    leaq L_str_319(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_324(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_323(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    leaq L_str_322(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_327(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_326(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    leaq L_str_325(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_330(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    leaq L_str_329(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    leaq L_str_328(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_333(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_332(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x138, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_331(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_336(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_335(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xa0, %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    leaq L_str_334(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_337(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_340(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_339(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_338(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_343(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_342(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    leaq L_str_341(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_346(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_345(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2000, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_344(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_349(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_348(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x10000, %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    leaq L_str_347(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_352(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    leaq L_str_351(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_350(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_355(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_354(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    leaq L_str_353(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_358(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_357(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x80, %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    leaq L_str_356(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_359(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_362(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_361(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    leaq L_str_360(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_365(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_364(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    leaq L_str_363(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_368(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_367(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_366(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_371(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_370(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    leaq L_str_369(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_374(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_373(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    leaq L_str_372(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_375(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_378(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_377(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movabsq $0x2a, %rax
    pushq %rax
    leaq L_str_376(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_381(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_380(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    leaq L_str_379(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_384(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_383(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    leaq L_str_382(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_387(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_386(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    leaq L_str_385(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_389(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3ae1, %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    leaq L_str_388(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_q
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_392(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_391(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x100000, %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    leaq L_str_390(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_395(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_394(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    leaq L_str_393(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_396(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_399(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_398(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_397(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_401(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_str_400(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_t2
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_403(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_str_402(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_t2
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_406(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    leaq L_str_405(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_str_404(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_409(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_408(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    leaq L_str_407(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_412(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_411(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    leaq L_str_410(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_414(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    leaq L_str_413(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_bool
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_415(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_418(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_417(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_416(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_420(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3666, %rax
    pushq %rax
    movabsq $0x22, %rax
    pushq %rax
    leaq L_str_419(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_q
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_423(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_422(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_421(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_426(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_425(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_424(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_429(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_428(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    leaq L_str_427(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_430(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    leaq L_str_433(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_432(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_431(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    leaq L_str_436(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_435(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    leaq L_str_434(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    leaq L_str_439(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_438(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x1f, %rax
    pushq %rax
    leaq L_str_437(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    leaq L_str_442(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_441(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    leaq L_str_440(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_443(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_446(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_445(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_444(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_449(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    leaq L_str_448(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_447(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_452(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_451(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    leaq L_str_450(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_455(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_454(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_453(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_458(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_457(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_str_456(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_461(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_460(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_459(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_464(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_463(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_462(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_465(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_468(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_467(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_466(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_471(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_470(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_469(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_474(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x29, %rax
    pushq %rax
    leaq L_str_473(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    leaq L_str_472(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_SCHED(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_477(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_476(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    leaq L_str_475(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x6, %rax
    pushq %rax
    leaq L_str_478(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_481(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_480(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x100000, %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    leaq L_str_479(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_484(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_483(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x100, %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    leaq L_str_482(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_487(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_486(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x400, %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    leaq L_str_485(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x6, %rax
    pushq %rax
    leaq L_str_488(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_491(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_490(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    leaq L_str_489(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_SEALED(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_494(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_493(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    leaq L_str_492(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_497(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_496(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x100, %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    leaq L_str_495(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_500(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_499(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x200, %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    leaq L_str_498(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_503(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_502(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x300, %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_501(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_506(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    leaq L_str_505(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x160, %rax
    pushq %rax
    movabsq $0x1f, %rax
    pushq %rax
    leaq L_str_504(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x6, %rax
    pushq %rax
    leaq L_str_507(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_510(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    leaq L_str_509(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    leaq L_str_508(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_513(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_512(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x22, %rax
    pushq %rax
    leaq L_str_511(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x6, %rax
    pushq %rax
    leaq L_str_514(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_517(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_516(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x23, %rax
    pushq %rax
    leaq L_str_515(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_520(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_str_519(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movabsq $0x21, %rax
    pushq %rax
    leaq L_str_518(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_OPPOLICY(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_523(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_522(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    leaq L_str_521(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_OPPOLICY(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_526(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_525(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    leaq L_str_524(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_str_529(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_528(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    leaq L_str_527(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_530(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_533(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_532(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x1f, %rax
    pushq %rax
    leaq L_str_531(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_536(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2b, %rax
    pushq %rax
    leaq L_str_535(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    leaq L_str_534(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_539(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x35, %rax
    pushq %rax
    leaq L_str_538(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    leaq L_str_537(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_542(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2e, %rax
    pushq %rax
    leaq L_str_541(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    leaq L_str_540(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_545(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2e, %rax
    pushq %rax
    leaq L_str_544(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    leaq L_str_543(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_548(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x22, %rax
    pushq %rax
    leaq L_str_547(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    leaq L_str_546(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_551(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1f, %rax
    pushq %rax
    leaq L_str_550(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    leaq L_str_549(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_554(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    leaq L_str_553(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    leaq L_str_552(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_557(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2d, %rax
    pushq %rax
    leaq L_str_556(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    leaq L_str_555(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_560(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2d, %rax
    pushq %rax
    leaq L_str_559(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1f, %rax
    pushq %rax
    leaq L_str_558(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_563(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x32, %rax
    pushq %rax
    leaq L_str_562(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    leaq L_str_561(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_564(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_cl_sect
    addq $32, %rsp
    pushq %rax
    popq %rax
    movzbq L_MT_DERIVED(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    leaq L_str_567(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_566(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    leaq L_str_565(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_u
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_570(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    leaq L_str_569(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    leaq L_str_568(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_573(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    leaq L_str_572(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_571(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_576(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_575(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    leaq L_str_574(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_579(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_578(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_577(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_582(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_581(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    leaq L_str_580(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_585(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    leaq L_str_584(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    leaq L_str_583(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_str_588(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    leaq L_str_587(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    leaq L_str_586(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_cl_str
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    leaq L_CL_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    leaq L_str_589(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_12:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_13
    movq -8(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_12
L_loop_end_13:
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    movl L_CL_COUNT(%rip), %eax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    movl L_CL_COUNT(%rip), %eax
    pushq %rax
    popq %rax
    shrq $8, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    movl L_CL_COUNT(%rip), %eax
    pushq %rax
    popq %rax
    shrq $16, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    movl L_CL_COUNT(%rip), %eax
    pushq %rax
    popq %rax
    shrq $24, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movb %al, L_CL_BUILT(%rip)
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "constants_count"
    .text
    .global constants_count
    .seh_proc constants_count
constants_count:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    subq $32, %rsp
    callq L_cl_build
    addq $32, %rsp
    pushq %rax
    popq %rax
    movl L_CL_COUNT(%rip), %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "constants_ledger_root"
    .text
    .global constants_ledger_root
    .seh_proc constants_ledger_root
constants_ledger_root:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_15
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    negq %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
    subq $32, %rsp
    callq L_cl_build
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movq L_CL_POS(%rip), %rax
    pushq %rax
    leaq L_CL_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq sha256_oneshot
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "constants_slot_type"
    .text
    .global constants_slot_type
    .seh_proc constants_slot_type
constants_slot_type:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    subq $32, %rsp
    callq L_cl_build
    addq $32, %rsp
    pushq %rax
    popq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_17
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    movl -8(%rbp), %eax
    pushq %rax
    movl L_CL_COUNT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_19
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
    leaq L_CL_TYPE(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "constants_slot_tier"
    .text
    .global constants_slot_tier
    .seh_proc constants_slot_tier
constants_slot_tier:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    subq $32, %rsp
    callq L_cl_build
    addq $32, %rsp
    pushq %rax
    popq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_21
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_21:
    movl -8(%rbp), %eax
    pushq %rax
    movl L_CL_COUNT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_23
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_23:
    leaq L_CL_TIER(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "constants_lookup"
    .text
    .global constants_lookup
    .seh_proc constants_lookup
constants_lookup:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    subq $32, %rsp
    callq L_cl_build
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_CL_NPOOL(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_loop_top_24:
    movl -40(%rbp), %eax
    pushq %rax
    movl L_CL_COUNT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_25
    movl -40(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    leaq L_CL_NLEN(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_27
    leaq L_CL_NOFF(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
L_loop_top_28:
    movq -64(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_29
    movq -24(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_else_30
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_31
L_if_else_30:
    movq -64(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_28
L_loop_end_29:
    movzbq -72(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_33
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_33:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_24
L_loop_end_25:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "constants_value"
    .text
    .global constants_value
    .seh_proc constants_value
constants_value:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    subq $32, %rsp
    callq L_cl_build
    addq $32, %rsp
    pushq %rax
    popq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_35
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_35:
    movl -8(%rbp), %eax
    pushq %rax
    movl L_CL_COUNT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_37
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_37:
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    leaq L_CL_VLEN(%rip), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_39
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_39:
    leaq L_CL_VPOOL(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    leaq L_CL_VOFF(%rip), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
L_loop_top_40:
    movq -80(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_41
    movq -72(%rbp), %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -80(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_40
L_loop_end_41:
    movq -40(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_new_ge"
    .text
    .seh_proc L_cl_new_ge
L_cl_new_ge:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    leaq L_CL_TYPE(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    leaq L_CL_VPOOL(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    leaq L_CL_VOFF(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movzbq -32(%rbp), %rax
    pushq %rax
    movzbq L_CT_U64(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_43
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_45
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    negq %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_45:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
L_loop_top_46:
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_47
    movq -56(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_46
L_loop_end_47:
    movq -64(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_49
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_49:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_43:
    movzbq -32(%rbp), %rax
    pushq %rax
    movzbq L_CT_S64(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_51
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_53
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    negq %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_53:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
L_loop_top_54:
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_55
    movq -56(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_54
L_loop_end_55:
    movq -64(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setge %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_57
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_57:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_51:
    movzbq -32(%rbp), %rax
    pushq %rax
    movzbq L_CT_Q14(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_59
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_61
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    negq %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_61:
    movq -40(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    shlq $8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movzwq %ax, %rax
    pushq %rax
    popq %rax
    movswq %ax, %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    shlq $8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movzwq %ax, %rax
    pushq %rax
    popq %rax
    movswq %ax, %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setge %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_63
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_63:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_59:
    movzbq -32(%rbp), %rax
    pushq %rax
    movzbq L_CT_BAND(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_65
    movq -24(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_cl_hi_ge
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_65:
    movzbq -32(%rbp), %rax
    pushq %rax
    movzbq L_CT_TUPLE2(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_67
    movq -24(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_cl_hi_ge
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_67:
    movzbq -32(%rbp), %rax
    pushq %rax
    movzbq L_CT_BOOL(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_69
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_71
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    negq %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_71:
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_73
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_73:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_69:
    movzbq -32(%rbp), %rax
    pushq %rax
    movzbq L_CT_STRING(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_75
    movq -24(%rbp), %rax
    pushq %rax
    leaq L_CL_VLEN(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_77
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_77:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_75:
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    negq %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_hi_ge"
    .text
    .seh_proc L_cl_hi_ge
L_cl_hi_ge:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_79
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    negq %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_79:
    leaq L_CL_VPOOL(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    leaq L_CL_VOFF(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    shlq $8, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    shlq $16, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    shlq $24, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    shlq $8, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    shlq $16, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    shlq $24, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movl -56(%rbp), %eax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_81
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_81:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "constants_validate_catalyst"
    .text
    .global constants_validate_catalyst
    .seh_proc constants_validate_catalyst
constants_validate_catalyst:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq %r9, -32(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq constants_lookup
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_83
    movslq L_CV_NOT_FOUND(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_83:
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    leaq L_CL_TIER(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_85
    movslq L_CV_NEVER(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_85:
    leaq L_CL_TIER(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_87
    movslq L_CV_WRONG_TIER(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_87:
    movq -32(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_cl_new_ge
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movslq -56(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    negq %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_89
    movslq L_CV_INVALID(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_89:
    movslq -56(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_91
    movslq L_CV_REGRESS(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_91:
    movslq L_CV_OK(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "constants_validate_amend"
    .text
    .global constants_validate_amend
    .seh_proc constants_validate_amend
constants_validate_amend:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq %r9, -32(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq constants_lookup
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_93
    movslq L_CV_NOT_FOUND(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_93:
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    leaq L_CL_TIER(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movzbq -56(%rbp), %rax
    pushq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_95
    movslq L_CV_LOCKED(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_95:
    movzbq -56(%rbp), %rax
    pushq %rax
    movzbq L_MT_AMEND(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_97
    movzbq -56(%rbp), %rax
    pushq %rax
    movzbq L_MT_SEALED(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_99
    movzbq -56(%rbp), %rax
    pushq %rax
    movzbq L_MT_SCHED(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_101
    movzbq -56(%rbp), %rax
    pushq %rax
    movzbq L_MT_OPPOLICY(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_103
    movslq L_CV_WRONG_TIER(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_103:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_101:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_99:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_97:
    movq -32(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_cl_new_ge
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movslq -64(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    negq %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_105
    movslq L_CV_INVALID(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_105:
    movslq L_CV_OK(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "constants_validate_r2"
    .text
    .global constants_validate_r2
    .seh_proc constants_validate_r2
constants_validate_r2:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq %r9, -32(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq constants_lookup
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_107
    movslq L_CV_NOT_FOUND(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_107:
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    leaq L_CL_TIER(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movzbq L_MT_NEVER(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_109
    movslq L_CV_LOCKED(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_109:
    leaq L_CL_TIER(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movzbq L_MT_R2(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_111
    movslq L_CV_WRONG_TIER(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_111:
    movq -32(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_cl_new_ge
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movslq -56(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    negq %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_113
    movslq L_CV_INVALID(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_113:
    movslq L_CV_OK(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "cl_set_nv_u64"
    .text
    .seh_proc L_cl_set_nv_u64
L_cl_set_nv_u64:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_114:
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_115
    leaq L_CL_NV8(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_114
L_loop_end_115:
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "constants_selftest"
    .text
    .global constants_selftest
    .seh_proc constants_selftest
constants_selftest:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    subq $32, %rsp
    callq L_cl_build
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq constants_count
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0xc4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_117
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_117:
    leaq L_CL_RT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq constants_ledger_root
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_CL_RT(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movabsq $0x57, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_119
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_119:
    leaq L_CL_RT(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movabsq $0x5b, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_121
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_121:
    leaq L_CL_RT(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movabsq $0x77, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_123
    movabsq $0x4, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_123:
    leaq L_CL_RT(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movabsq $0x22, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_125
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_125:
    leaq L_CL_RT(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movabsq $0xd9, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_127
    movabsq $0x6, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_127:
    leaq L_CL_RT(%rip), %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movabsq $0xfa, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_129
    movabsq $0x7, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_129:
    leaq L_CL_RT(%rip), %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movabsq $0xe9, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_131
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_131:
    leaq L_CL_RT(%rip), %rax
    pushq %rax
    movabsq $0x1f, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movabsq $0xce, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_133
    movabsq $0x9, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_133:
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq constants_ledger_root
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
L_loop_top_134:
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_135
    leaq L_CL_RT(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    leaq L_CL_VTMP(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_137
    movabsq $0xa, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_137:
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_134
L_loop_end_135:
    movabsq $0x11, %rax
    pushq %rax
    leaq L_str_590(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq constants_lookup
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_139
    movabsq $0xb, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_139:
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq constants_slot_tier
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    movzbq L_MT_CATALYST(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_141
    movabsq $0xc, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_141:
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq constants_slot_type
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    movzbq L_CT_U64(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_143
    movabsq $0xd, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_143:
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_591(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq constants_lookup
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_145
    movabsq $0xe, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_145:
    movabsq $0x30, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_cl_set_nv_u64
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_CL_NV8(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    leaq L_str_592(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq constants_validate_catalyst
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_CV_OK(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_147
    movabsq $0xf, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_147:
    movabsq $0x2e, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_cl_set_nv_u64
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_CL_NV8(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    leaq L_str_593(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq constants_validate_catalyst
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_CV_REGRESS(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_149
    movabsq $0x10, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_149:
    movabsq $0x63, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_cl_set_nv_u64
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_CL_NV8(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_594(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq constants_validate_catalyst
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_CV_WRONG_TIER(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_151
    movabsq $0x11, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_151:
    movabsq $0x8, %rax
    pushq %rax
    leaq L_CL_NV8(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    leaq L_str_595(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq constants_validate_catalyst
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_CV_NEVER(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_153
    movabsq $0x12, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_153:
    movabsq $0x8, %rax
    pushq %rax
    leaq L_CL_NV8(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_596(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq constants_validate_amend
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_CV_OK(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_155
    movabsq $0x13, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_155:
    movabsq $0x8, %rax
    pushq %rax
    leaq L_CL_NV8(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_597(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq constants_validate_amend
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_CV_LOCKED(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_157
    movabsq $0x14, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_157:
    movabsq $0x8, %rax
    pushq %rax
    leaq L_CL_NV8(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    leaq L_str_598(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq constants_validate_amend
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_CV_WRONG_TIER(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_159
    movabsq $0x15, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_159:
    movabsq $0x8, %rax
    pushq %rax
    leaq L_CL_NV8(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_str_599(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq constants_validate_r2
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_CV_OK(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_161
    movabsq $0x16, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_161:
    movabsq $0x8, %rax
    pushq %rax
    leaq L_CL_NV8(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_600(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq constants_validate_r2
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_CV_WRONG_TIER(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_163
    movabsq $0x17, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_163:
    movabsq $0x4, %rax
    pushq %rax
    leaq L_CL_NV8(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    leaq L_str_601(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq constants_validate_amend
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_CV_INVALID(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_165
    movabsq $0x18, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_165:
    movabsq $0x63, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
