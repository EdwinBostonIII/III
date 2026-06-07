#!/usr/bin/env bash
# Run the STDLIB conformance corpus.
# Each NN_*.iii compiles via iiis, links with stdlib .o files, and
# returns an expected exit code.

set -u
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STDLIB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CORPUS_DIR="$STDLIB_DIR/corpus"
BUILD_DIR="$STDLIB_DIR/build/iii"
RUN_DIR="$STDLIB_DIR/build/corpus"
mkdir -p "$RUN_DIR"

case "${OS:-}${OSTYPE:-}" in
    *Windows*|*mingw*|*msys*|*cygwin*) BIN_SUFFIX=".exe" ;;
    *)                                  BIN_SUFFIX=""     ;;
esac

# Default to the in-tree production compiler -- the SAME pin used by
# build_stdlib.sh and run_xii_corpus.sh (line 9 there).  An explicit
# `IIIS=...` env override still wins; PATH / Program Files is only a
# last-resort fallback for installed-only environments.  Auto-picking a
# stale external `iiis` silently measures the corpus against the WRONG
# compiler -- a determinism violation: the May-10 Program Files build
# predates the iiis-2 grammar and rejects Path-A tests at parse
# (rc=11/12), masquerading as ~20 corpus regressions.
REPO_ROOT="$(cd "$STDLIB_DIR/.." && pwd)"
IIIS="${IIIS:-}"
if [[ -z "$IIIS" ]]; then
    if [[ -x "$REPO_ROOT/COMPILED/iiis-2$BIN_SUFFIX" ]]; then
        IIIS="$REPO_ROOT/COMPILED/iiis-2$BIN_SUFFIX"
    elif command -v iiis >/dev/null 2>&1; then
        IIIS="$(command -v iiis)"
    elif [[ -x "/c/Program Files/III/bin/iiis$BIN_SUFFIX" ]]; then
        IIIS="/c/Program Files/III/bin/iiis$BIN_SUFFIX"
    else
        echo "[run_corpus] FATAL: no iiis (looked for COMPILED/iiis-2$BIN_SUFFIX, PATH, Program Files)" >&2
        exit 2
    fi
fi
echo "[run_corpus] iiis = $IIIS"

declare -A EXPECTED=(
    [01_scalar_u32_add_wrap]=42
    [02_sha256_kat_abc]=186
    [03_region_create_alloc_release]=99
    [04_span_load_store]=66
    [05_arena_alloc_used]=99
    [06_rune_ascii_lower]=104
    [07_string_byte_eq]=99
    [08_builder_push_seal]=99
    [09_option_u32_unwrap]=99
    [10_result_u32_ok_err]=99
    [11_iter_u8_count]=99
    [12_vec_u8_push_at]=99
    [13_mhash_domain_separation]=99
    [14_kchain_compose_underflow]=99
    [15_sha256_kat_empty]=227
    [16_hex_encode_roundtrip]=99
    [17_string_starts_with]=99
    [18_rune_utf8_encode_round]=233
    [19_vec_u8_max_bound]=99
    [20_iter_u8_skip]=99
    [21_map_put_get_grow_integrity]=99
    [22_set_insert_contains_remove]=99
    [23_queue_fifo_order]=99
    [24_pq_min_order]=99
    [25_fold_sum_xor_max]=99
    [26_zip_count]=99
    [27_either_left_right_swap]=99
    [28_checked_overflow]=99
    [29_modular_pow]=99
    [30_fixed_q32_arithmetic]=99
    [31_q128_add_shift]=99
    [32_parse_decimal]=99
    [33_bigint_mul_add]=99
    [34_format_decimal_hex]=99
    [35_regex_basic]=99
    [36_capability_attenuate_revoke]=99
    [37_handle_open_close]=99
    [38_fs_write_read_roundtrip]=99
    [39_instant_now_seal_verify]=99
    [40_duration_arithmetic]=99
    [41_deadline_check]=99
    [42_witness_chain_verify]=99
    [43_attest_self_nonce]=99
    [44_crystal_mint_verify]=99
    [45_mandate_audit_full]=99
    [46_closure_set_verify]=99
    [47_bigint_div_u64]=99
    [48_bigint_div_qr]=99
    [49_field_fp_arithmetic]=99
    [50_normalise_ascii]=99
    [51_net_pack_sockaddr]=99
    [52_json_parse_primitives]=99
    [53_json_parse_compound]=99
    [54_json_roundtrip]=99
    [55_sha512_kat_abc]=221
    [56_sha512_kat_empty]=207
    [57_http_parse_content_length]=99
    [58_http_parse_chunked]=99
    [59_ed25519_rfc8032_test1]=99
    [60_aes128_fips197_kat]=105
    [61_aes128_decrypt_roundtrip]=99
    [62_aes_gcm_nist_test2_seal]=99
    [63_aes_gcm_open_roundtrip]=99
    [64_http_parse_request]=99
    [65_http_send_response]=99
    [66_uri_parse]=99
    [67_uri_pct_encode_decode]=99
    [68_aes256_fips197_kat]=142
    [69_aes256_gcm_nist_test14]=99
    [70_chacha20_block_kat]=16
    [71_poly1305_rfc8439_kat]=168
    [72_chacha20_poly1305_aead_rfc8439]=99
    [73_x25519_rfc7748_test1]=195
    [74_ed25519_rfc8032_test2]=99
    [75_ed25519_rfc8032_test3]=99
    [76_bigint_normalize]=99
    [77_arena_reset]=99
    [78_normalise_nfd_nfc]=99
    [79_hmac_sha256_rfc4231]=176
    [80_base64_round_trip]=99
    [81_hkdf_sha256_rfc5869]=60
    [82_crc32_kat]=203
    [83_blake2s_kat]=80
    [84_xoshiro_determinism]=99
    [85_ini_parse]=99
    [86_pbkdf2_sha256_rfc7914]=85
    [87_uuid_v4_format]=99
    [88_murmur3_kat]=186
    [89_leb128]=99
    [90_gcm_ghash_pclmul_bitident]=88
    [91_csv_parse]=99
    [92_base32_kat]=99
    [93_ulid_format]=99
    [94_calendar_round_trip]=99
    [95_rfc3339]=99
    [96_timing_safe_eq]=99
    [97_endian]=99
    [98_path]=99
    [99_html_escape]=99
    [100_quality_gate_aggregate]=99
    [101_sid_direct_graph]=99
    [102_sid_transitive_closure]=99
    [103_sid_visualize_utf8]=99
    [104_modifier_crystal]=42
    [105_crystal_edges_baseline]=99
    [106_modifier_dynamic]=1
    [107_modifier_sealed]=7
    [108_modifier_linear]=42
    [109_modifier_bounded]=42
    [110_modifier_variant]=42
    [111_modifier_k]=42
    [112_modifier_provenance]=42
    [113_modifier_constant_time]=99
    [114_modifier_side_channel_resistant]=42
    [115_modifier_dynamic_impact]=42
    [116_modifier_provenance_linked_error]=42
    [117_modifier_arena_reset_safe]=42
    [118_modifier_crystal_self_attest]=42
    [119_ripple_analyze_baseline]=99
    [120_ripple_execute_strict]=99
    [121_arena_region_reset_safe]=99
    [122_stress_arena_1k_resets]=99
    [123_consumer_hello_arena]=99
    [124_proof_ripple_witness]=99
    [125_bitops]=99
    [126_inet_ipv4]=99
    [127_semver]=99
    [128_glob]=99
    [128_self_host_ripple]=99
    [129_list]=99
    [130_lru]=99
    [131_field_inv_crystal]=99
    [132_lru_debug_isolate]=99
    [410_xii_chd_bucket_bounds]=99
    [411_xii_audit_record_count_bound]=99
    [412_babel_wire_len_overflow]=99
    [413_rsa_sign_pool_exhaustion]=99
    [414_builder_oom_latch]=99
    [415_sovereign_witness_artifact]=99
    [416_sovereign_witness_affine]=99
    [417_sovereign_witness_replay]=99
    [418_sovereign_witness_align]=99
    [419_self_witness_iii_contracts]=99
    [133_arena_only]=99
    [134_lru_new_only]=99
    [135_lru_capacity]=99
    [136_lru_put_one]=99
    [137_lru_put_three]=99
    [138_lru_put_evict]=99
    [139_lru_just_evict]=99
    [140_modifier_strict_length]=42
    [141_http_isolate]=99
    [142_http_header_find]=99
    [143_bigint_karatsuba]=99
    [144_q128_to_f64]=99
    [145_checked_crystal]=99
    [146_modular_mont]=99
    [147_fixed_extra]=99
    [148_scalar_provenance]=99
    [149_cpufeat_dispatch]=99
    [150_cpufeat_only]=99
    [151_sha256_dispatch_kat]=99
    [152_dispatch_only]=99
    [153_crystal_http_header]=99
    [154_async_runtime_basic]=99
    [155_sha3_256_kat_abc]=99
    [156_sha3_512_kat_abc]=99
    [157_shake128_kat_empty]=99
    [158_shake256_kat_empty]=99
    [159_fed_tier_basic]=99
    [160_fed_sybil_pow]=99
    [161_fed_eclipse_basic]=99
    [162_sha3_diag]=183
    [163_fed_admit_gates]=99
    [164_fed_genesis_descent]=99
    [165_fed_seal_anchor]=99
    [166_sandbox_lifecycle]=99
    [167_merkle_basic]=99
    [168_keccak_zero]=231
    [169_sha3_256_empty]=167
    [170_obs_log_basic]=99
    [171_obs_metric_kinds]=99
    [172_obs_trace_tree]=99
    [173_obs_observatory_collapse]=99
    [174_catalyst_gates]=99
    [175_genesis_distance]=99
    [176_promote_demote_lifecycle]=99
    [177_glyph_v3_roundtrip]=99
    [178_glyph_v3_remainder]=99
    [179_dynamic_ripple_stub]=99
    [180_poly1305_scalar_avx512_bitident]=88
    [181_keccak_chi_scalar_avx512_bitident]=88
    [182_bigint_mul_scalar_avx512_bitident]=88
    [183_x25519_ed25519_field_bigint_bitident]=88
    [184_sha256_sched_scalar_avx512_bitident]=88
    [185_sha512_sched_scalar_avx512_bitident]=88
    [200_calculus_18_primitives]=99
    [201_lazy_crystal_levels]=99
    [202_memo_determinism]=99
    [203_jit_fuse_amortized]=99
    [204_prespec_hw_offload]=99
    [205_governance_full_loop]=99
    [206_observe_and_propose]=99
    [207_babel_wire_roundtrip]=99
    [208_cap_handshake]=99
    [209_idoc_roundtrip]=99
    [210_sealed_channel_handshake]=99
    [211_hip_resolve]=99
    [212_hip_verb_coverage]=99
    [213_reflect_introspection]=99
    [214_hip_intent_validation]=99
    [215_sealed_channel_session_id]=99
    [216_proof_ripple_equiv]=99
    [217_e2e_hip_idoc]=99
    [218_prespec_compositions]=99
    [219_witness_chain]=99
    [220_hip_concurrency]=99
    [221_hip_punctuation]=99
    [222_babel_wire_tamper]=99
    [223_mini_crystal_lifecycle]=99
    [224_hip_interrogative]=99
    [225_sealed_channel_multimsg]=99
    [226_intent_composition]=99
    [227_calculus_metadata]=99
    [228_idoc_multi_consumer]=99
    [229_governance_no_autoproposal]=99
    [230_memo_content_addressing]=99
    [231_calculus_idempotence]=99
    [232_pe_static_zero_overhead]=99
    [233_resolver_unit_dispatch]=99
    [234_compositions_ssot_drift]=99
    [235_resolver_unit_avx2_parity]=99
    [238_resolver_unit_avx512_parity]=99
    [237_insel_cycle_bench]=99
    [236_idsg_abstract_reflect]=99
    [239_fed_multi_node_mesh]=99
    [240_fed_e2e_admit_ceremony]=99
    [241_hip2_complex_sentences]=99
    [242_bench_resolver]=99
    [243_bench_sealed_channel]=99
    [244_bench_hip_idoc]=99
    [245_self_reformatter]=99
    [246_ai_resolve]=99
    [247_first_domain_pattern_set]=99
    [248_signed_compare]=99
    [249_u32_indexed_access]=99
    [250_multiline_fn]=99
    [251_newline_else]=99
    [252_nested_comments]=99
    [253_hex_underscores]=99
    [254_mut_param]=99
    [255_let_discard]=99
    [256_local_arrays]=99
    [257_iiis1_fn_annotations]=99
    [258_iiis1_param_annotations]=99
    [259_cap_required]=99
    [260_k_max]=99
    [261_hexad_kind]=99
    [262_cap_flow_static]=99
    [263_intent_kind_static]=99
    [264_k_floor_static]=99
    [265_return_kind_static]=99
    [266_all_rules_combined]=99
    [267_call_arg_cross_check]=99
    [268_iiis2_loop_break_continue]=99
    [269_iiis2_type_alias]=99
    [270_substrate_integration]=99
    [271_nested_call_chain]=99
    [272_cross_fn_pe]=99
    [273_cross_fn_dynamic_intent]=88
    [274_type_alias_multihop]=99
    [276_let_mut_checkpoint_flag]=99
    [277_arg5_param_spill]=99
    [278_addr_of_index_paren]=99
    [279_addr_of_index_bare]=99
    [186_signed_i64_ordering]=99
    [187_u32_pointer_store_width]=99
    [192_module_const_local]=99
    [188_multiline_fn_decl]=99
    [189_emdash_block_comment]=99
    [190_nested_block_comment]=99
    [191_local_var_array]=99
    [193_ed25519_sign_rfc8032_test1]=99
    [194_ed25519_verify_tamper]=99
    [195_ed25519_sign_rfc8032_test2]=99
    [196_ed25519_sign_rfc8032_test3]=99
    [197_ed25519_sign_long_message]=99
    [198_mldsa_roundtrip]=99
    [199_mlkem_roundtrip]=99
    [200_slhdsa_roundtrip]=99
    [201_pq_dispatch]=99
    [202_aes192_kat]=99
    [203_hmac_sha512_rfc4231]=99
    [204_drbg_sp80090a]=99
    [205_drbg_hw_entropy]=99
    [206_xchacha20_poly1305]=99
    [207_aes_siv_rfc5297]=99
    [208_ecdsa_p256]=99
    [209_ecdsa_p384]=99
    [373_rsa_pss_sign_verify]=99
    [374_zk_field_bls12381]=99
    [375_zk_snark_groth16]=99
    [376_zk_stark_fri]=99
    [377_zk_prune_rollup]=99
    [378_keccak256_wrapper]=99
    [379_identifier]=99
    [381_algebraic_time]=99
    [382_witness_hook]=99
    [383_hotstuff]=99
    [384_hotstuff_predict]=99
    [385_hotstuff_heal]=99
    [386_fed_qc_gate]=99
    [387_net_server_loopback]=99
    [388_fe25519_ed]=99
    [389_hexad_subsystem]=99
    [390_katabasis_svm_hexad]=99
    [391_katabasis_cycle_dominance]=99
    [392_katabasis_cycle_family]=99
    [393_specialize]=99
    [394_katabasis_bar_typing]=99
    [395_katabasis_cycle_admit]=99
    [600_katabasis_vmexit]=99
    [601_katabasis_ring_lattice]=99
    [602_katabasis_gate_verdict]=99
    [603_katabasis_census]=99
    [604_katabasis_bricking]=99
    [605_katabasis_cycle_term]=99
    [606_katabasis_gate]=99
    [607_katabasis_seal]=99
    [608_katabasis_caps]=99
    [609_katabasis_admit]=99
    [394_option_specialize]=99
    [395_result_specialize]=99
    [396_span_specialize]=99
    [397_iter_specialize]=99
    [398_vec_specialize]=99
    [610_rev_invoke]=99
    [611_tiebreak]=99
    [612_galois]=99
    [613_sat]=99
    [614_egraph]=99
    [615_cost_lattice]=99
    [616_microarch_model]=99
    [617_quine_verifier]=99
    [618_entropy_monitor]=99
    [619_curry_howard]=99
    [620_category]=99
    [621_sheaf]=99
    [622_manifest]=99
    [623_quarantine]=99
    [624_node_identity]=99
    [625_snapshot_lattice]=99
    [626_topology_atlas]=99
    [627_cap_forge]=99
    [628_xii_ldil]=99
    [629_triple_check]=99
    [630_context_awareness]=99
    [631_symbolic_regression]=99
    [632_constitution]=99
    [633_witness_spine]=99
    [634_reversible]=99
    [635_smt]=99
    [636_proof_term]=99
    [637_sat_at_scale]=99
    [638_groebner]=99
    [639_proof_carrying]=99
    [640_cost_calculus]=99
    [641_bone_marrow]=99
    [642_cost_lattice_synth]=99
    [643_basal_probe]=99
    [644_temporal_logic]=99
    [645_computation_graph]=99
    [646_memo_lattice]=99
    [647_theorem_carrier]=99
    [648_synthesis_spec]=99
    [649_reversibility_audit]=99
    [650_branch_anchor]=99
    [651_branch_governance]=99
    [652_math_library]=99
    [653_math_library_curation]=99
    [654_memo_query]=99
    [655_constitution_preserver]=99
    [656_bisimulation_witness]=99
    [657_witness_compactor]=99
    [658_distress_witness]=99
    [659_cost_overrun_handler]=99
    [660_firmware_quarantine]=99
    [661_shape_negotiator]=99
    [662_memo_compactor_coordination]=99
    [663_reflection_constrained]=99
    [664_reflection_governance]=99
    [665_cad]=99
    [666_trit]=99
    [667_hexad_reach]=99
    [668_uncertainty]=99
    [669_sovval]=99
    [671_hexad_mobius]=99
    [672_safety_type]=99
    [673_constitution_holds]=99
    [674_h2_charter]=99
    [688_h1_charter]=99
    [689_h3_charter]=99
    [690_h8_charter]=99
    [691_h10_charter]=99
    [692_h6_charter]=99
    [693_h9_charter]=99
    [694_h11_charter]=99
    [695_h4_charter]=99
    [696_h5_charter]=99
    [697_h7_charter]=99
    [698_h12_charter]=99
    [699_h13_charter]=99
    [700_charter_terminal]=99
    [701_cons_run_charter]=99
    [702_cat_laws_charter]=99
    [703_rev_compromise_charter]=99
    [704_sovval_boundary_type]=99
    [705_bound_selftest]=99
    [706_http_chunk_wrap]=99
    [707_pq_cap_wrap]=99
    [708_option_full_distinct]=99
    [709_reach_oracle_null_pin]=99
    [710_base32_sealed_builder]=99
    [711_format_sealed_builder]=99
    [713_inet_sealed_builder]=99
    [714_async_id_alias]=99
    [720_caindex]=99
    [754_cg_anchor_caindex]=99
    [755_ripple_sep_grouping]=99
    [756_ripple_loop_grouping]=99
    [757_bigint_knuth_div]=99
    [758_mont_ctx_organ]=99
    [759_mont_bigint_width]=99
    [760_field_mont_organ]=99
    [761_buffer_bound_falsifier]=99
    [762_merkle_keccak_suite]=99
    [763_tempaloc_mistype]=99
    [764_arena_reset_witness]=99
    [765_seal_organ]=99
    [766_pq_params]=99
    [767_ntt_ctx]=99
    [768_keccak_sponge]=99
    [769_pq_sealed_abi]=99
    [770_slhdsa_shake_fips205]=99
    [771_slhdsa_sha2_fips205]=99
    [772_map_full_table_sentinel]=99
    [721_tiebreak_leaves]=99
    [722_ntt]=99
    [723_ntt_convolve]=99
    [724_ntt_bigint]=99
    [725_bigint_large_route]=99
    [712_sovereign_pos]=99
    [714_sovflow_pos]=99
    [716_sovout_pos]=99
    [718_sovsink_pos]=99
    [675_decision_oracle]=99
    [676_cat_laws]=99
    [677_cost_lattice_laws]=99
    [678_memo_soundness]=99
    [679_synthesis_bounds]=99
    [680_proof_chain]=99
    [681_transform_iso]=99
    [682_arena_determinism]=99
    [683_unify]=99
    [684_crystal_seal]=99
    [685_observatory_sealed]=99
    [686_quota_append_only]=99
    [687_membrane_cap_gate]=99
    [800_nous_socket]=99
    [801_nous_costlin]=99
    [802_nous_search]=99
    [803_nous_charter]=99
    [804_nous_policy]=99
    [805_nous_completion]=99
    [806_nous_commons]=99
    [807_nous_train]=99
    [808_nous_synth]=99
    [809_nous_behavioral_key]=99
    [810_xii_rule_patterns]=99
    [811_xii_rule_overlap]=99
    [812_xii_critpair_enum]=99
    [813_xii_joinability]=99
    [814_xii_termination]=99
    [815_xii_admission]=99
    [816_xii_lower_compose]=99
    [817_xii_lower_decide]=99
    [818_xii_lower_iterate]=99
    [819_xii_lower_program]=99
    [820_xii_mig4_seal]=99
    [821_xii_lower_then]=99
    [822_xii_lower_with]=99
    [823_xii_lower_under]=99
    [824_xii_strategy_det]=99
    [825_xii_discharge]=99
    [826_xii_conf_cert]=99
    [827_reach_spine]=99
    [828_reach_memo]=99
    [829_reach_remote]=99
    [830_reach_oracle]=99
    [831_reach_ipc]=99
    [832_reach_loopback]=99
    [833_markup]=99
    [834_ripple_field]=99
    [835_self_reformatter_directed]=99
    [836_forcefield_pleroma]=99
    [837_forcefield_ripple]=99
    [838_forcefield_ripple_dyn]=99
    [839_forcefield_optinvoke]=99
    [840_forcefield_optinvoke_egraph]=99
    [841_typecheck_core]=99
    [842_typecheck_sigma]=99
    [843_typecheck_bool]=99
    [844_typecheck_id]=99
    [845_typecheck_nat]=99
    [846_typecheck_eta]=99
    [847_typecheck_natrec]=99
    [848_typecheck_j]=99
    [849_typecheck_bot]=99
    [850_typecheck_cumul]=99
    [851_typecheck_sum]=99
    [852_typecheck_meta]=99
    [853_combinator_ski]=99
    [854_combinator_data]=99
    [855_combinator_conv]=99
    [856_ccl_eta]=99
    [857_ccl_beta]=99
    [858_ccl_data]=99
    [859_ccl_conv]=99
    [860_ccl_oracle]=99
    [861_ccl_readback]=99
    [862_ccl_etahi]=99
    [863_ccl_confluence]=99
    [935_ccl_invalid]=99
    [936_typecheck_ctxdepth]=99
    [864_forcefield_commit_gate]=99
    [865_typecheck_qtt]=99
    [866_typecheck_qtt2]=99
    [867_typecheck_qtt_erase]=99
    [868_typecheck_wtype]=99
    [869_typecheck_wrec]=99
    [870_typecheck_sovereign]=99
    [871_typecheck_sov_field]=99
    [872_typecheck_lamcheck]=99
    [873_typecheck_reflcheck]=99
    [874_sov_isa_descent]=99
    [875_typecheck_isa_cert]=99
    [876_sov_isa_optimizer]=99
    [877_sov_pcc]=99
    [878_psi_superposition]=99
    [879_sov_evolve]=99
    [880_typecheck_induct]=99
    [881_typecheck_induct_use]=99
    [882_typecheck_open_conv]=99
    [883_sov_admit]=99
    [884_xii_rule_verify]=99
    [885_xii_fusion_verify]=99
    [886_arith_identity]=99
    [887_const_fold_ext]=99
    [888_nous_value]=99
    [889_nous_features]=99
    [890_sat_arith]=99
    [891_xii_subforms]=99
    [892_xii_nop_tables]=99
    [893_u64_div]=99
    [894_const_fold]=99
    [895_dead_branch]=99
    [896_identities]=99
    [897_optimizer_soundness]=99
    [898_ast_intent]=99
    [899_intent_form]=99
    [900_pattern_form]=99
    [901_transform_form]=99
    [902_babel]=99
    [903_babel_intent]=99
    [904_xii_curate]=99
    [905_tcp]=99
    [906_eg_integrity]=99
    [907_cl_rational]=99
    [908_shape_filter]=99
    [909_cl_dominates]=99
    [910_universe_subtype]=99
    [911_bv_ring]=99
    [912_congruence]=99
    [913_ecdsa_p256_det_sign]=99
    [914_xii_anchor_negative]=99
    [915_sov_self_improve]=99
    [916_sov_pipeline]=99
    [917_ripple_metric]=99
    [918_ripple_unify]=99
    [919_ripple_loop]=99
    [920_ripple_cut]=99
    [921_ripple_extract]=99
    [922_pcc_gate]=99
    [923_hdl]=99
    [924_phys_cost]=99
    [925_aeu]=99
    [926_hdl_seq]=99
    [927_phys_real]=99
    [928_hdl_opt]=99
    [929_aeu_scale]=99
    [930_ripple_value]=99
    [931_phi_ledger]=99
    [932_ripple_search]=99
    [933_induct]=99
    [934_cert]=99
    [937_xii_crypto_chokepoint]=99
    [938_cb_differential]=99
    [939_ccl_confluence_falsifier]=99
    [940_irreducibility_falsifier]=99
    [941_quality_q7_lint_falsifier]=99
    [942_proof_ripple_corpus_verify]=99
    [943_resolver_memo_guards]=99
    [944_resolver_replay_guard]=99
    [945_mandate_dead_chain]=99
    [946_pattern_set_fed_ancestry]=99
    [947_dynamic_impact_signed]=99
    [948_resolution_init_fail]=99
    [949_base32_pad_validation]=99
    [950_xii_emit_gen_catalog]=99
    [951_seal_resolver_refreeze]=99
    [952_microarch_rob_saturation]=99
    [953_mont_dmont5_falsifier]=99
    [954_ripple_extract_mdl]=99
    [955_optinvoke_cost_lattice]=99
    [956_egraph_cost_lattice]=99
    [957_engine_compound]=99
    [958_ecdsa_p384_zero_rs]=99
    [959_ecdsa_p384_range_rs]=99
    [960_keccak256_block_absorb]=99
    [961_xoshiro_jump]=99
    [962_bv_ring_colstack]=99
    [963_sov_isa_cost_gradient]=99
    [964_ripple_extract_audit_purity]=99
    [965_crystal_id_band]=99
    [966_ripple_merkle_domain_sep]=99
    [967_pq_dispatch_nibble_guard]=99
    [968_optinvoke_seal_domain]=99
    [969_bv_ring_shift_mask]=99
    [970_merkle_index_binding]=99
    [971_cpufeat_avx512dq]=99
    [972_ecdsa_lowS_range]=99
    [973_fe25519_canonical_decode]=99
    [974_aes_gcm_aad_nonaligned_tamper]=99
    [975_xii_lattice_payload_wrap_guard]=99
    [976_optinvoke_seal_padding_determinism]=99
    [977_egraph_rule_wrap_guard]=99
    [978_smt_lia_wrap_guard]=99
    [979_ripple_child_index_guard]=99
    [980_xii_subforms_salt_resolve]=99
    [981_ed25519_strict_s_malleability]=99
    [982_keccak_squeeze_rate_guard]=99
    [983_hexad_unpack6_range_guard]=99
    [984_bigint_assign_capacity_guard]=99
    [985_hexad_epistemic_floor_escalate]=99
    [986_mod_u64_mul_zero_modulus]=99
    [987_cai_put_table_full]=99
    [988_witness_redact]=99
    [989_mlkem_decaps_k_guard]=99
    [993_ed_decompress_canonical]=99
    [994_ecdsa_p256_zero_rs]=99
    [995_mldsa_siglen_guard]=99
    [996_slhdsa_siglen_guard]=99
    [997_zk_air_general]=99
    [998_zk_air_merkle]=99
    [999_zk_air_stark]=99
    [1000_checked_div_zero]=99
    [1001_cap_verify_invalid_id]=99
    [1002_quality_q4_growth]=99
    [1003_merkle_tree_open_many]=99
    [1004_fri_fold_consistency]=99
    [1005_zk_stark_seal]=99
    [1006_zk_stark_proof_seal]=99
    [1007_air_proof_seal]=99
    [1008_zkp_stark_sidecar]=99
    [1009_proof_ripple_unified]=99
    [1010_pareto_frontier]=99
    [1011_hotstuff_pacemaker]=99
    [1012_hotstuff_quorum_opt]=99
    [1013_cost_manifold]=99
    [1014_hdl_gate_identities]=99
    [1015_mechanistic_cycle_bound]=99
    [1016_proof_resolve]=99
    [1017_hdl_optimize]=99
    [1018_hdl_compiler]=99
    [1019_arena_slot_witness]=99
    [1020_sha_ni_differential]=99
    [1021_ed_mod_l_barrett]=99
    [1022_pq_dispatch_sha2_route]=99
    [1023_vec_overflow_guard]=99
    [1024_iter_null_base_guard]=99
    [1025_base64url_round_trip]=99
    [420_fed_qc_len_guard]=99
    [421_idoc_pack_outcap]=99
    [1026_xii_export_bounds]=99
    [1027_ripple_handle_exhaust_guard]=99
    [1028_tp_transpiler_bounds]=99
    [1029_ripple_arena_subtraction_guard]=99
    [1030_ripple_metric_underflow_floor]=99
    [1022_pq_dispatch_sha2_route]=99
    [1031_intent_form_int_overflow]=99
    [1032_cbor_len_overflow]=99
    [1033_transform_form_overflow]=99
    [1034_sf_field]=99
    [1035_zkf_fp]=99
    [1036_zkf_fp2]=99
    [1037_zkf_fp6]=99
    [1038_zkf_fp12]=99
    [1039_zkf_g1]=99
    [1040_zkf_g2]=99
    [1041_zkf_ec]=99
    [1042_zkf_fexp]=99
    [1043_curryh_kat]=99
    [1044_typecheck]=99
    [1045_zk_air_fs]=99
    [1046_ed25519_sign_seed]=99
    [1047_quine_seal]=99
    [1048_json_uescape]=99
    [1049_mig2_keystone]=99
    [1050_mig2_cost]=99
    [1051_mig2_sovval]=99
    [1052_sov_morphism]=99
    [1053_xii_morphism]=99
    [1112_opt_certified]=99
    # K5 CLOSED: the sov_isa "Path C" dependent-type kernel sr-schema tower is kernel-PROVEN.
    # The ccl_eta_contract reducer block was fixed (closed succ-step survives tc_shift_k), so the
    # mandatory tc_natrec induction over a symbolic var closes: 1113 proves the foundation
    # (mul_one + ap_succ + L1 add_left_zero) and 1114 proves L6 mul-over-double distributivity via
    # the additive Peano tower (add_succ_left/assoc/comm/left_comm + ap_add congruences + MLD).
    # Each positive is a tc_check==1; each negative control a tc_check==0; nothing green-washed.
    [1113_sr_schema_foundation]=99
    [1114_sr_schema_distrib]=99
    [1115_sr_schema_strength]=99
    [1116_sr_schema_apply]=99
    [1117_sr_schema_distrib_apply]=99
    [1118_sr_schema_semiring]=99
    [1119_sov_synth_nonvacuity]=99
    [1120_sov_synth_attempt]=99
    [1121_egraph_stochastic]=99
    [1122_cg_autocatalyst]=99
    [1123_daemon_dream]=99
    [1200_proof_bisimulation]=99
    [1201_ast_hunter]=99
    [1202_cg_surgical_strike]=99
    [1203_daemon_scythe]=99
    [1204_scythe_census]=99
    [1205_sovereign_optimizer]=99
    [1206_sovereign_continuous]=99
    [1207_shift_fold_certified]=99
    [1208_theorem_commons]=99
    [1209_theorem_commons_distinct]=99
    [1210_commons_feed]=99
    [1211_commons_cite_reuse]=99
    [1212_commons_root]=99
    [1213_bv_kernel]=99
    [1214_bv_kernel_differential]=99
    [1215_r3_identity_fold]=99
    [1216_bv_dispose]=99
    [1217_rscode]=99
    [1218_erasure_store]=99
    [1219_shamir]=99
    [1220_threshold_vault]=99
    [1221_hamming_secded]=99
    [1222_gf_poly]=99
    [1223_rscode_ec]=99
    [1224_lzss]=99
    [1225_cas_blob]=99
    [1226_crt]=99
    [1240_certified_morphism]=99
    [1241_ripple_journal]=99
    [1242_costed_cat]=99
    [1243_ru_kernel_merge]=99
    [1227_bitio]=99
    [1228_elias]=99
    [1230_huffman]=99
    [1231_lzh]=99
    [1232_heaplet]=99
    [1233_sep_logic]=99
    [1234_tso]=99
    [1235_ptr_provenance]=99
    [1236_mem_rewrite]=99
    [1237_csl]=99
    [1238_congruence_closure]=99
    [1239_mcmc_egraph]=99
    [1244_relational_ematch]=99
    [1245_algo_synth]=99
    [1247_k0_referee]=99
    [1248_golden_shift]=99
    [1249_conjecture_refute]=99
    [1250_self_engine]=99
    [1253_verified_search]=99
    [1254_omega_engine]=99
    [1255_pareto_frontier]=99
    [1256_verified_ripple]=99
    [1257_optimality_cert]=99
    [1258_logic_synth]=99
    [1259_contract_gate]=99
    [1260_ring_opt]=99
    [1261_matrix_ring]=99
    [1262_bft_quorum]=99
    [1263_affine_check]=99
    [1264_rewrite_schedule]=99
    [1265_interval_lattice]=99
    [1266_loop_optimizer]=99
    [1267_kleene_fixpoint]=99
    [1268_widening]=99
    [1269_align_domain]=99
    [1270_vectorizer]=99
    [1271_bce]=99
    [1272_reduced_product]=99
    [1251_xii_cap_preserve]=99
    [1246_bv_canon_addr]=99
    [1247_induct_wj]=99
    [1252_tcom_goalbound]=99
    [1124_fs_dir_enum]=99
    [1125_onelang_audit]=99
    [1126_founders_anchor]=99
    [1127_constants_ledger]=99
    [1110_tp_morphism]=99
    [1111_sha_ni_stream_diff]=99
    [1054_h9_mig2_tie]=99
    [1050_sealed_channel_forge_desync]=99
    [1051_base64_pad_reject]=99
    [1052_base32_trailing_reject]=99
    [1053_html_apos_unescape]=99
    [726_ntt_stage]=99
    [1054_q128_ops]=99
    [1055_modular_ops]=99
    [1056_fixed_ops]=99
    [1057_checked_u64_lifecycle]=99
    [1058_duration_ops]=99
    [1059_span_ops]=99
    [1060_rune_utf8]=99
    [1061_format_more]=99
    [1062_string_ops]=99
    [1063_hkdf_oneshot]=99
    [1064_pbkdf2_oneshot]=99
    [1065_sha256_dispatch]=99
    [1066_parse_primitives]=99
    [1067_uri_pct_decode_reject]=99
    [1068_pattern_set_arity]=99
    [1069_dynamic_record_rejects]=99
    [1070_vec_setters]=99
    [1071_hexad_epistemic_accessors]=99
    [1072_list_negatives]=99
    [1073_hexad_algebra]=99
    [1074_hexad_pfs]=99
    [1075_hexad_dynamic]=99
    [1076_instant_diff_ticks]=99
    [1077_crystal_tamper_reject]=99
    [1078_net_cap_deny]=99
    [1079_rsa_wrappers]=99
    [1080_chacha20_differential]=99
    [1081_blake2s_differential]=99
    [1082_pattern_table_getters]=99
    [1083_synthesis_propose_ratify]=99
    [1084_slhdsa_variant_keygen]=99
    [1085_http_build_request]=99
    [1086_http_response_accessors]=99
    [1087_node_identity_witnessed]=99
    [1088_pattern_set_fed_wire]=99
    [1089_local_array_runtime_index]=99
    [1090_nous_lattice]=99
    [1091_ripple_synthesizer]=99
    [1092_gate_cp1_guard]=99
    [1100_obs_witnessed]=99
    [1101_forked_walk]=99
    [1102_conjecture]=99
    [1103_conjecture_complete_all]=99
    [1104_conjecture_term]=99
    [1105_conjecture_gen]=99
    [1106_conjecture_lemma]=99
    [1107_egraph_saturate_capacity_gap]=99
    [1108_sov_self_extend]=99
    [1109_cast_stride_index]=36
)

PASS=0
FAIL=0
SKIP=0
RESULTS=()
# Aggregate any hand-written-asm .o files that live alongside the iii
# modules in $BUILD_DIR.  These are produced by build_stdlib.sh and are
# normally absorbed into libiii_native.a, but we record their presence
# in ALL_OBJS for diagnostics / future loose-link fallbacks.
ALL_OBJS=()
if [[ -f "$BUILD_DIR/resolver_unit.o" ]]; then
    ALL_OBJS+=("$BUILD_DIR/resolver_unit.o")
fi
if [[ -f "$BUILD_DIR/resolver_unit_avx512.o" ]]; then
    ALL_OBJS+=("$BUILD_DIR/resolver_unit_avx512.o")
fi
if [[ -f "$BUILD_DIR/bench_helpers.o" ]]; then
    ALL_OBJS+=("$BUILD_DIR/bench_helpers.o")
fi
# Link against the deterministic static archive produced by build_stdlib.sh.
# SELECTIVE --whole-archive (CONVERGENCE fix): the prior blanket
# `--whole-archive libiii_native.a` force-linked EVERY module into EVERY test
# exe.  Once witness_hook's spec-mandated ~1.38 GiB BSS landed, the cumulative
# ~1.96 GiB exceeded the loadable-image limit and every test died ENOEXEC.
# Fix: force-link ONLY the side-effecting global-init modules (pattern/resolver/
# codegen registrations that some tests rely on WITHOUT a direct symbol
# reference -- e.g. resolution_init), and NORMAL-link the rest of the archive so
# each test pulls just its dependency closure (witness_hook enters only the
# exes that reference it -> ~1.4 GiB, loadable).  Validated: governance/
# resolver/intent (205/226/233/246) + witness_spine (633) all = 99 under this.
LIB_ARCHIVE="$BUILD_DIR/libiii_native.a"
if [[ ! -f "$LIB_ARCHIVE" ]]; then
    echo "[run_corpus] FATAL: $LIB_ARCHIVE missing -- run build_stdlib.sh first" >&2
    exit 2
fi
# The force-linked side-effect set (registration-only modules + resolver
# dispatch units).  Built from whichever objects exist so a renamed/removed
# module degrades gracefully rather than failing the whole link.
SIDE_EFFECT_NAMES=(
    omnia_resolution_init.iii.o omnia_resolution_meta_dispatch.iii.o
    omnia_proof_ripple_resolution.iii.o omnia_resolver.iii.o
    omnia_resolver_memo.iii.o omnia_resolver_replay.iii.o
    omnia_codegen_patterns.iii.o omnia_transform_patterns.iii.o
    omnia_xii_curated_payloads.iii.o omnia_hw_offload.iii.o
    aether_pattern_set_federation.iii.o sanctus_calculus_v1.iii.o
    sanctus_resolver_replay.iii.o sanctus_seal_resolver.iii.o
    verba_nl_lex.iii.o resolver_hot.o resolver_unit.o
    resolver_unit_avx512.o bench_helpers.o
)
SIDE_EFFECT_OBJS=()
for _se in "${SIDE_EFFECT_NAMES[@]}"; do
    [[ -f "$BUILD_DIR/$_se" ]] && SIDE_EFFECT_OBJS+=("$BUILD_DIR/$_se")
done

for src in "$CORPUS_DIR"/[0-9][0-9]_*.iii "$CORPUS_DIR"/[0-9][0-9][0-9]_*.iii "$CORPUS_DIR"/[0-9][0-9][0-9][0-9]_*.iii; do
    [[ -f "$src" ]] || continue
    base="$(basename "$src" .iii)"
    obj="$RUN_DIR/${base}.iii.o"
    exe="$RUN_DIR/${base}${BIN_SUFFIX}"
    log="$RUN_DIR/${base}.log"
    rm -f "$obj" "$exe" "$log"

    # The XII corpus (280..372) is OWNED and authoritatively validated
    # by run_xii_corpus.sh (its own EXPECTED table, incl.
    # 299_bit_identity_probe=11 from Phase-sigma).  This conformance
    # runner's greedy 3-digit glob also enumerates it; re-judging it
    # here double-counts every XII test as FAIL purely for lacking a
    # *conformance* EXPECTED entry (the historical `expected=?`
    # miscount -- ~94 phantom FAILs).  Delegate, do not double-judge.
    case "$base" in
        2[89][0-9]_*|3[0-9][0-9]_*)
            num=$((10#${base%%_*}))
            if [[ "$num" -ge 280 && "$num" -le 372 ]]; then
                RESULTS+=("SKIP  $base : XII corpus -- owned by run_xii_corpus.sh")
                SKIP=$((SKIP+1)); continue
            fi
            ;;
    esac

    # Performance micro-benchmarks (237/242/243/244) assert ABSOLUTE cycle
    # budgets calibrated for a 3.6 GHz reference machine (see each test's
    # header).  Absolute cycle gates are machine-relative and
    # non-deterministic -- a correct substrate fails them on any machine
    # slower than the reference, under VM-virtualised TSC, or under
    # background load (RDTSCP serialization overhead alone dominates the
    # STATIC path's ~1-2-cycle work).  They are NOT correctness-conformance
    # tests; corpus 244's own header states: "This corpus tests TIMING
    # budgets, not bit-identity.  It MUST NOT participate in mhash / kchain
    # / witness sealing."  They are OWNED by run_bench_corpus.sh, which
    # hard-gates their CORRECTNESS assertions (bit-identity, round-trip,
    # fast-path-fired) and the portable relative-ordering invariants, while
    # treating absolute timing as advisory (egregious >10x overruns still
    # fail, preserving genuine-regression detection).  Delegate here, do
    # not double-judge -- identical discipline to the XII delegation above.
    # (RITCHIE convergence Stage 0.7-FIX; see DOCS/CONVERGENCE-AUDIT.md.)
    case "$base" in
        237_insel_cycle_bench|242_bench_resolver|243_bench_sealed_channel|244_bench_hip_idoc|990_bench_knuth_div|991_bench_montgomery_modpow|992_bench_fe25519_mul)
            RESULTS+=("SKIP  $base : perf benchmark -- owned by run_bench_corpus.sh")
            SKIP=$((SKIP+1)); continue
            ;;
    esac
    # Every conformance test this runner OWNS must carry a deterministic
    # EXPECTED exit code (Phase-sigma discipline, generalised).  A
    # missing entry is a HARD error -- never a silent `expected=?` --
    # so a newly-added conformance test cannot quietly miscount: add its
    # EXPECTED entry, or move the test into the XII range (>=280).
    # Negative-compile tests (*_neg_*) are rc-classified below and
    # legitimately carry no EXPECTED entry.
    case "$base" in
        *_neg_*|*_neg) : ;;
        *)
            if [[ -z "${EXPECTED[$base]+set}" ]]; then
                echo "[run_corpus] FATAL: no EXPECTED entry for conformance test '$base'" >&2
                echo "             -> add it to the EXPECTED table, or move the test to the XII corpus (>=280)" >&2
                exit 3
            fi
            ;;
    esac

    "$IIIS" "$src" --compile-only --out "$obj" >"$log" 2>&1
    rc=$?

    # NEGATIVE-COMPILE tests (NNN_neg_*): their headers declare
    # "THIS FILE MUST FAIL TO COMPILE" and they are authoritatively
    # validated by scripts/test_*_negative.sh (non-zero exit + the
    # III_*_VIOLATION marker).  For this generic loop the pass contract
    # is exactly "iiis rejects it" -- a non-zero compile rc is SUCCESS
    # (the static check fired); rc==0 means the negative case was
    # wrongly accepted (a real regression of the static check).
    # Same per-name classification discipline as the *_pe_* case below;
    # treating their correct rejection as FAIL was a harness bug.
    case "$base" in
        *_neg_*|*_neg)
            if [[ $rc -ne 0 ]]; then
                RESULTS+=("PASS  $base : negative-compile correctly rejected (rc=$rc)")
                PASS=$((PASS+1)); continue
            else
                RESULTS+=("FAIL  $base : NEGATIVE test compiled (static check did not fire)")
                FAIL=$((FAIL+1)); continue
            fi
            ;;
    esac

    if [[ $rc -ne 0 ]]; then
        RESULTS+=("FAIL  $base : iiis-compile rc=$rc")
        FAIL=$((FAIL+1)); continue
    fi

    # PE-marker assertion: tests whose name matches `*_pe_*` exercise
    # the Partial Evaluator's static-intent narrowing.  Their emitted
    # `.iii.o.s` MUST contain the `# III_PE_DIRECT_LOAD` marker, which
    # codegen writes when a `resolve(...)` call is replaced by a direct
    # symbol load.  If the marker is absent the PE didn't fire, so the
    # test FAILS even when the binary's exit code matches EXPECTED.
    # The check short-circuits before link/exec and is purely additive
    # (non-PE tests are untouched).  A missing `.iii.o.s` is tolerated
    # (some toolchain modes don't emit one) -- only an EXISTING file
    # without the marker is a failure.
    case "$base" in
        *_pe_*)
            asm="$RUN_DIR/${base}.iii.o.s"
            if [[ -f "$asm" ]]; then
                if ! grep -qF "# III_PE_DIRECT_LOAD" "$asm"; then
                    RESULTS+=("FAIL  $base : pe-marker-missing")
                    FAIL=$((FAIL+1)); continue
                fi
            fi
            ;;
    esac

    # OneDrive/Defender transient-lock hardening (DOCS/III-DISPOSITION-EXECUTION.md): the
    # freshly-synced $LIB_ARCHIVE can be momentarily READ-locked -> ld reports spurious
    # "undefined reference" against a partially-visible archive (the 817 flake); the
    # OneDrive-watched $exe can be WRITE-locked -> `ld returned 1` with no diagnostic. BOTH
    # are TRANSIENT. rm the output (fresh inode) + retry lets the lock release. A GENUINE
    # link error is deterministic -> it still fails every attempt, so this never masks a
    # real defect (it only removes spurious gate failures that would falsely REVERT a good
    # ripple_apply edit).
    rc=1
    for _la in 1 2 3 4 5; do
        rm -f "$exe"
        gcc "$obj" -Wl,--whole-archive "${SIDE_EFFECT_OBJS[@]}" -Wl,--no-whole-archive "$LIB_ARCHIVE" \
            -lws2_32 -lkernel32 -o "$exe" >>"$log" 2>&1
        rc=$?
        [[ $rc -eq 0 && -f "$exe" ]] && break
        sleep 1
    done
    if [[ $rc -ne 0 ]]; then
        RESULTS+=("FAIL  $base : link rc=$rc (after 5 lock-retries)")
        FAIL=$((FAIL+1)); continue
    fi

    # Some Defender heuristics in OneDrive-watched folders refuse to
    # exec specific .exe content patterns (e.g. cpufeat fingerprint +
    # crypto in same binary).  The binaries themselves are valid PE
    # images that run cleanly outside the watched folder, so we stage
    # each test in /tmp before invocation.  This is not a workaround
    # for a code bug; it is a workaround for a path-based AV policy.
    staged_exe="/tmp/run_$$_$RANDOM${BIN_SUFFIX}"
    cp "$exe" "$staged_exe"
    "$staged_exe" >>"$log" 2>&1
    actual=$?
    rm -f "$staged_exe"
    expected="${EXPECTED[$base]:-?}"
    if [[ "$actual" == "$expected" ]]; then
        RESULTS+=("PASS  $base : exit=$actual")
        PASS=$((PASS+1))
    else
        RESULTS+=("WRONG $base : exit=$actual expected=$expected")
        FAIL=$((FAIL+1))
    fi
done

echo "============================================================"
echo " STDLIB Conformance Corpus"
echo "============================================================"
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "------------------------------------------------------------"
echo "  PASS=$PASS  FAIL=$FAIL  SKIP=$SKIP  TOTAL=$((PASS+FAIL))"
echo "  (SKIP = XII corpus 280..372 [run_xii_corpus.sh] + perf"
echo "   benchmarks 237/242/243/244 [run_bench_corpus.sh])"
echo "============================================================"
exit $FAIL
