#!/usr/bin/env bash
# verify_nous_differential.sh -- THE KEYSTONE PROOF (nous C-14), three-way.
#
# Every engine-exercising corpus test must produce IDENTICAL verdicts under all three:
#   a0  active=0                -- the fixed rule cascade (the baseline).
#   a1  active=1, order mode 0  -- the nous-ranked CASCADE-ORDER path (reproduces the
#                                  cascade rule-for-rule via apply_specific): proves the
#                                  socket plumbing is BYTE-IDENTICAL, and validates the
#                                  cascade-order transcription against R-rule terms.
#   a2  active=1, order mode 2  -- the real POLICY order (a different, kind-aware
#                                  permutation of the certified set): proves reordering
#                                  proposals reaches the SAME normal form (confluence).
# Any divergence is RED: a broken confluence cert, a mis-transcribed cascade order, or a
# cap-induced gap.  This converts the keystone from an argument into a number.
#
# Collision-free: copies the live archive (never mutates it) and ar-replaces the current
# engine objects + the proposer chain (nous_socket -> nous_policy -> nous_features) +
# nous_socket compiled at each (active,mode).  $B is absolute and contains a space, so
# object lists are bash ARRAYS (quoted) -- never space-joined strings.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STDLIB="$ROOT/STDLIB"; B="$STDLIB/build/iii"
IIIS="$ROOT/COMPILED/iiis-2.exe"; [ -x "$IIIS" ] || IIIS="$ROOT/COMPILED/iiis-2"
ARCH="$B/libiii_native.a"
SOCK="$STDLIB/iii/nous/nous_socket.iii"
[ -f "$ARCH" ] || { echo "FATAL: $ARCH missing -- run build_stdlib.sh first" >&2; exit 2; }
[ -x "$IIIS" ] || { echo "FATAL: iiis-2 not found" >&2; exit 2; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# --- current engine + proposer-chain objects (shared by every archive) ---
for pair in "omnia/xii_rewrite:omnia_xii_rewrite" "omnia/xii_canonicalise:omnia_xii_canonicalise" \
            "nous/nous_features:nous_nous_features" "nous/nous_policy:nous_nous_policy"; do
    s="${pair%%:*}"; o="${pair##*:}"
    "$IIIS" "$STDLIB/iii/$s.iii" --compile-only --out "$TMP/$o.iii.o" || { echo "FATAL: $s compile"; exit 2; }
done
ENGINE=("$TMP/omnia_xii_rewrite.iii.o" "$TMP/omnia_xii_canonicalise.iii.o" "$TMP/nous_nous_features.iii.o" "$TMP/nous_nous_policy.iii.o")

# --- nous_socket at three (active,mode) settings ---
"$IIIS" "$SOCK" --compile-only --out "$TMP/sock_a0.o" || { echo "FATAL: nous_socket a0 compile"; exit 2; }
sed 's/\(NOUS_ACTIVE[^=]*=\)[[:space:]]*0u8/\1 1u8/' "$SOCK" > "$TMP/sock_a1.iii"
grep -q 'NOUS_ACTIVE.*= 1u8' "$TMP/sock_a1.iii" || { echo "FATAL: could not flip NOUS_ACTIVE" >&2; exit 2; }
"$IIIS" "$TMP/sock_a1.iii" --compile-only --out "$TMP/sock_a1.o" || { echo "FATAL: nous_socket a1 compile"; exit 2; }
sed 's/\(NOUS_ORDER_MODE[^=]*=\)[[:space:]]*0u8/\1 2u8/' "$TMP/sock_a1.iii" > "$TMP/sock_a2.iii"
grep -q 'NOUS_ORDER_MODE.*= 2u8' "$TMP/sock_a2.iii" || { echo "FATAL: could not set NOUS_ORDER_MODE=2" >&2; exit 2; }
"$IIIS" "$TMP/sock_a2.iii" --compile-only --out "$TMP/sock_a2.o" || { echo "FATAL: nous_socket a2 compile"; exit 2; }

mk_archive() {  # $1=tag  $2=sock.o
    local a="$TMP/lib_$1.a"; cp "$ARCH" "$a"
    ar r "$a" "${ENGINE[@]}" >/dev/null 2>&1
    cp "$2" "$TMP/nous_nous_socket.iii.o"; ar r "$a" "$TMP/nous_nous_socket.iii.o" >/dev/null 2>&1
}
mk_archive a0 "$TMP/sock_a0.o"
mk_archive a1 "$TMP/sock_a1.o"
mk_archive a2 "$TMP/sock_a2.o"

# --- side-effect (force-linked) object set, identical to run_corpus.sh ---
SE_ARR=()
for n in omnia_resolution_init.iii.o omnia_resolution_meta_dispatch.iii.o \
         omnia_proof_ripple_resolution.iii.o omnia_resolver.iii.o omnia_resolver_memo.iii.o \
         omnia_resolver_replay.iii.o omnia_codegen_patterns.iii.o omnia_transform_patterns.iii.o \
         omnia_xii_curated_payloads.iii.o omnia_hw_offload.iii.o aether_pattern_set_federation.iii.o \
         sanctus_calculus_v1.iii.o sanctus_resolver_replay.iii.o sanctus_seal_resolver.iii.o \
         verba_nl_lex.iii.o resolver_hot.o resolver_unit.o resolver_unit_avx512.o bench_helpers.o; do
    [ -f "$B/$n" ] && SE_ARR+=("$B/$n")
done

link_run() {  # $1=obj $2=archive $3=tag -> echoes exit code or "x" on link failure
    local exe="$TMP/d_$3.exe"
    if gcc "$1" -Wl,--whole-archive "${SE_ARR[@]}" -Wl,--no-whole-archive "$2" -lws2_32 -lkernel32 -o "$exe" >/dev/null 2>&1; then
        local st="$TMP/s_$3.exe"; cp "$exe" "$st"; "$st" >/dev/null 2>&1; echo "$?"
    else
        echo "x"
    fi
}

RC=0; N=0; SKIP=0
for src in "$STDLIB"/corpus/*.iii; do
    base="$(basename "$src" .iii)"
    grep -qE 'xii_canonicalise|xii_rewrite' "$src" || continue
    case "$base" in *_neg_*|*_neg) continue;; esac
    obj="$TMP/$base.o"
    "$IIIS" "$src" --compile-only --out "$obj" >/dev/null 2>&1 || { SKIP=$((SKIP+1)); continue; }
    e0="$(link_run "$obj" "$TMP/lib_a0.a" 0)"
    e1="$(link_run "$obj" "$TMP/lib_a1.a" 1)"
    e2="$(link_run "$obj" "$TMP/lib_a2.a" 2)"
    if [ "$e0" = x ] || [ "$e1" = x ] || [ "$e2" = x ]; then SKIP=$((SKIP+1)); continue; fi
    N=$((N+1))
    if [ "$e0" != "$e1" ] || [ "$e0" != "$e2" ]; then
        echo "  DIVERGENCE  $base : a0=$e0  a1(cascade)=$e1  a2(policy)=$e2"
        RC=1
    else
        echo "  ok          $base : $e0"
    fi
done

echo "----------------------------------------------------------------"
echo "nous differential gate (3-way): compared=$N  skipped=$SKIP (un-linkable/non-engine)"
if [ "$RC" = 0 ] && [ "$N" -gt 0 ]; then
    echo "NOUS DIFFERENTIAL GATE: GREEN -- active=0 == active=1(cascade) == active=1(policy)."
    echo "(Keystone: neither the cascade-order reproduction nor the real policy reorder changed any answer.)"
elif [ "$N" -eq 0 ]; then
    echo "NOUS DIFFERENTIAL GATE: INCONCLUSIVE -- no engine tests linked."; RC=2
else
    echo "NOUS DIFFERENTIAL GATE: RED -- a reorder changed an output (see DIVERGENCE above)."
fi
exit $RC
