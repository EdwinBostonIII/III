# COMPILER/BOOT/mhash_lib.sh -- SEAL AUTHORSHIP: III hashes III.  (sourced, not executed)
#
# THE BASAL LAW, applied to the verification membrane: the exact-math organs are
# not a subsphere the toolchain routes around -- they ARE the toolchain's own
# decision and attestation substrate.  Before this library, every seal in the
# compiler spine (the iiis-0/1/2/3 .mhash goldens, the stdlib archive seal, the
# trusted-base root, the determinism twins) was AUTHORED by GNU coreutils alone,
# while III's own FIPS-gated SHA-256 (numera/cad, via aether/sovhash.iii) sat
# unwired.  This library inverts the authorship:
#
#     sovereign (III numera/cad)  = PRIMARY AUTHOR of every seal value
#     GNU sha256sum               = cross-WITNESS -- it can veto (disagreement
#                                   is a hard fail, rc 97), it no longer authors
#
# Same algorithm (FIPS 180-4 SHA-256) => every existing golden VALUE is
# unchanged byte-for-byte.  What changes hands is who computes it.
#
# Existing basal precedents this extends (the idiom is the tree's own):
#   - seal_sources.sh:122   the three-authorship witness triangle (III/GNU/MS)
#   - forge_manifest_keccak.sh   in-tree numera/keccak authors the forge root
#   - build_iiis1.sh:216    cg_r3 calls seg_*/bv_*/sat_* provers AT COMPILE TIME
#
# API (all diagnostics to stderr; stdout carries ONLY hash values):
#   mhash_init [--require-sovereign]
#       Mint COMPILED/_sovhash/sovhash.exe from STDLIB/iii/aether/sovhash.iii
#       using the committed COMPILED/iiis-2.exe + libiii_native.a (the exact
#       invocation seal_sources.sh's triangle already proves), then SELF-KAT it
#       against two FIPS 180-4 vectors ("abc", empty input).  On success:
#       MHASH_AUTHOR=sovereign.  If the mint is IMPOSSIBLE (no archive yet --
#       a pristine clone before bootstrap stage 2): MHASH_AUTHOR=gnu, loudly;
#       with --require-sovereign that is fatal instead.  A hasher that MINTS but
#       FAILS its KAT is ALWAYS fatal in both modes -- "soft" covers cannot-mint,
#       never minted-but-wrong.
#   mhash_file <path>
#       Print the 64-hex SHA-256 of the file.  sovereign-primary; GNU witness
#       must agree or rc=97 (authorship disagreement -- tamper or bug, never
#       silently resolved).  Lazy soft-init if mhash_init was not called.
#   mhash_stdin
#       Same, for piped content (via a temp file).
#
# AUTHORSHIP BOUNDARY (deliberate, honest): seals, golden verifies, and
# determinism ATTESTATIONS route through this library.  Pure equality probes on
# transient artifacts (corpus h0==h1 twins, section-diff diagnostics) are
# authorship-neutral comparisons and may keep raw sha256sum -- they attest
# nothing; they only compare.  basal_census_gate.sh pins this boundary.
#
# Trust argument for minting against the archive being sealed (build_stdlib):
# a corrupted archive would have to produce a sovhash that lies about the
# archive's own digest EXACTLY matching GNU's independent value -- the witness
# triangle argument (seal_sources.sh:122).  The FIPS self-KAT independently
# rejects functional corruption before the first real byte is hashed.
#
# rc discipline: no value-bearing pipes; command substitutions checked; \r from
# msvcrt text-mode stdout stripped via parameter expansion (no tr pipe).
# No EXIT traps (sourcing scripts own theirs).  LF-only.  Bash 4+.

MHASH_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MHASH_III_ROOT="$(cd "$MHASH_LIB_DIR/../.." && pwd)"
MHASH_AUTHOR=""          # sovereign | gnu | "" (uninitialised)
MHASH_SOVHASH=""         # path to the minted, KAT-proven hasher

# FIPS 180-4 known-answer vectors (the same constants numera/sha256's KAT pins).
MHASH_KAT_ABC="ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
MHASH_KAT_EMPTY="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

_mhash_log() { printf '[mhash] %s\n' "$*" >&2; }

# _mhash_gnu <file> -> hex on stdout, rc!=0 on failure.  The WITNESS vertex.
_mhash_gnu() {
    local _line
    _line="$(sha256sum "$1")" || return 1
    printf '%s\n' "${_line%%[[:space:]]*}"
}

# _mhash_sov <file> -> hex on stdout, rc!=0 on failure.  The AUTHOR vertex.
_mhash_sov() {
    local _raw _rc
    _raw="$("$MHASH_SOVHASH" "$1")"; _rc=$?
    [[ $_rc -eq 0 ]] || { _mhash_log "sovhash rc=$_rc on: $1"; return 1; }
    _raw="${_raw//$'\r'/}"                      # msvcrt text-mode CR strip
    [[ "$_raw" =~ ^[0-9a-f]{64}$ ]] || { _mhash_log "sovhash malformed output on: $1"; return 1; }
    printf '%s\n' "$_raw"
}

mhash_init() {
    local _require=0
    [[ "${1:-}" == "--require-sovereign" ]] && _require=1

    # Minting-compiler candidates, preference order: the committed/pinned iiis-2,
    # then the golden-verified stage neighbours.  bootstrap_from_clean deletes
    # iiis-2.exe at stage-4 entry (build_iiis2 must reproduce it); at that moment
    # the freshly golden-verified iiis-1.exe is the sealed compiler on disk.
    local _iiis="" _cand
    for _cand in iiis-2.exe iiis-1.exe iiis-3.exe; do
        if [[ -x "$MHASH_III_ROOT/COMPILED/$_cand" ]]; then _iiis="$MHASH_III_ROOT/COMPILED/$_cand"; break; fi
    done
    local _lib="$MHASH_III_ROOT/STDLIB/build/iii/libiii_native.a"
    local _src="$MHASH_III_ROOT/STDLIB/iii/aether/sovhash.iii"
    local _dir="$MHASH_III_ROOT/COMPILED/_sovhash"

    if [[ -z "$_iiis" || ! -f "$_lib" || ! -f "$_src" ]] || ! command -v gcc >/dev/null 2>&1; then
        if [[ $_require -eq 1 ]]; then
            _mhash_log "FATAL: sovereign hasher unmintable (need iiis-2.exe + libiii_native.a + gcc + sovhash.iii) and --require-sovereign is set"
            return 96
        fi
        MHASH_AUTHOR="gnu"
        _mhash_log "sovereign hasher UNMINTABLE pre-stdlib -- GNU-only authorship THIS RUN (retro-attested by bootstrap stage 2b)"
        return 0
    fi

    mkdir -p "$_dir" || { _mhash_log "FATAL: cannot mkdir $_dir"; return 96; }
    local _o="$_dir/sovhash.$$.o" _exe_tmp="$_dir/sovhash.$$.exe" _exe="$_dir/sovhash.exe"

    if ! "$_iiis" "$_src" --compile-only --out "$_o" >/dev/null 2>&1; then
        rm -f "$_o"
        if [[ $_require -eq 1 ]]; then _mhash_log "FATAL: sovhash.iii compile failed (--require-sovereign)"; return 96; fi
        MHASH_AUTHOR="gnu"; _mhash_log "sovhash compile failed -- GNU-only authorship THIS RUN"; return 0
    fi
    if ! gcc "$_o" "$_lib" -lws2_32 -lkernel32 -o "$_exe_tmp" >/dev/null 2>&1; then
        rm -f "$_o" "$_exe_tmp"
        if [[ $_require -eq 1 ]]; then _mhash_log "FATAL: sovhash link failed (--require-sovereign)"; return 96; fi
        MHASH_AUTHOR="gnu"; _mhash_log "sovhash link failed -- GNU-only authorship THIS RUN"; return 0
    fi
    rm -f "$_o"
    mv -f "$_exe_tmp" "$_exe" || { _mhash_log "FATAL: cannot publish $_exe"; return 96; }
    MHASH_SOVHASH="$_exe"

    # SELF-KAT: minted-but-wrong is ALWAYS fatal (never a fallback).
    local _kat _got
    _kat="$_dir/kat.$$.bin"
    printf 'abc' > "$_kat" || { _mhash_log "FATAL: KAT fixture write failed"; rm -f "$_kat"; return 95; }
    _got="$(_mhash_sov "$_kat")" || { _mhash_log "FATAL: minted sovhash failed to run its FIPS KAT"; rm -f "$_kat"; return 95; }
    if [[ "$_got" != "$MHASH_KAT_ABC" ]]; then
        _mhash_log "FATAL: FIPS 180-4 KAT('abc') MISMATCH: got $_got want $MHASH_KAT_ABC -- the crypto organ or toolchain is broken; refusing ALL hashing"
        rm -f "$_kat"; return 95
    fi
    : > "$_kat" || { _mhash_log "FATAL: KAT fixture truncate failed"; rm -f "$_kat"; return 95; }
    _got="$(_mhash_sov "$_kat")" || { _mhash_log "FATAL: minted sovhash failed the empty-input KAT run"; rm -f "$_kat"; return 95; }
    rm -f "$_kat"
    if [[ "$_got" != "$MHASH_KAT_EMPTY" ]]; then
        _mhash_log "FATAL: FIPS 180-4 KAT(empty) MISMATCH: got $_got want $MHASH_KAT_EMPTY -- refusing ALL hashing"
        return 95
    fi

    MHASH_AUTHOR="sovereign"
    _mhash_log "seal authorship = SOVEREIGN (III numera/cad; FIPS KATs green; GNU as witness)"
    return 0
}

mhash_file() {
    local _f="$1" _s _g _rc
    [[ -f "$_f" ]] || { _mhash_log "no such file: $_f"; return 2; }
    if [[ -z "$MHASH_AUTHOR" ]]; then
        mhash_init; _rc=$?
        [[ $_rc -eq 0 ]] || return $_rc
    fi
    _g="$(_mhash_gnu "$_f")" || { _mhash_log "witness sha256sum failed on: $_f"; return 1; }
    if [[ "$MHASH_AUTHOR" == "sovereign" ]]; then
        _s="$(_mhash_sov "$_f")" || return 1
        if [[ "$_s" != "$_g" ]]; then
            _mhash_log "FATAL: AUTHORSHIP DISAGREEMENT on $_f"
            _mhash_log "  sovereign(III) = $_s"
            _mhash_log "  witness(GNU)   = $_g"
            _mhash_log "  one authorship is lying or broken -- refusing to seal"
            return 97
        fi
        printf '%s\n' "$_s"
    else
        printf '%s\n' "$_g"
    fi
}

mhash_stdin() {
    local _t _h _rc
    _t="$(mktemp)" || { _mhash_log "mktemp failed"; return 1; }
    cat > "$_t" || { rm -f "$_t"; _mhash_log "stdin capture failed"; return 1; }
    _h="$(mhash_file "$_t")"; _rc=$?
    rm -f "$_t"
    [[ $_rc -eq 0 ]] || return $_rc
    printf '%s\n' "$_h"
}
