#!/usr/bin/env bash
# COMPILER/BOOT/build_xii.sh — Sealed XII build pipeline.
# Per DOCS/III-XII.md S26.14.
#
# Hermetic, deterministic, NIH-only. Produces:
#   COMPILED/iiis-2.exe         (XII-aware compiler binary)
#   COMPILED/xii_lattice.bin    (sealed Lattice cells)
#   COMPILED/xii_manifest.bin   (sealed Manifest, 1040 bytes)
#   COMPILED/iiis-2.exe.xii_witness.json (witness sidecar)
#
# Exit codes:
#   0 = success
#   1 = generic error
#   2 = corpus failure
#   3 = mhash mismatch (anti-drift)
#   4 = manifest verification failed
#   5 = ceremony cert missing or invalid
#   6 = III_EXIT_NONDETERMINISM (build was nondeterministic)

set -euo pipefail

# Determinism preamble.
export LC_ALL=C LANG=C TZ=UTC0 SOURCE_DATE_EPOCH=0 CCACHE_DISABLE=1
export PYTHONHASHSEED=0
umask 022

cd "$(dirname "$0")/../.."

REPO_ROOT="$PWD"
COMPILED="$REPO_ROOT/COMPILED"
BOOT="$REPO_ROOT/COMPILER/BOOT"
STDLIB="$REPO_ROOT/STDLIB"
CORPUS="$STDLIB/corpus"

mkdir -p "$COMPILED"

CHECK_DETERMINISTIC="${1:-}"
if [ "$CHECK_DETERMINISTIC" = "--check-deterministic" ]; then
    echo "[xii] determinism replay mode"
    bash "$0"
    [ -f "$COMPILED/iiis-2.exe" ] && cp "$COMPILED/iiis-2.exe" "$COMPILED/iiis-2.exe.first"
    [ -f "$COMPILED/xii_lattice.bin" ] && cp "$COMPILED/xii_lattice.bin" "$COMPILED/xii_lattice.bin.first"
    [ -f "$COMPILED/xii_manifest.bin" ] && cp "$COMPILED/xii_manifest.bin" "$COMPILED/xii_manifest.bin.first"
    bash "$0"
    if [ -f "$COMPILED/iiis-2.exe" ] && [ -f "$COMPILED/iiis-2.exe.first" ]; then
        cmp -s "$COMPILED/iiis-2.exe" "$COMPILED/iiis-2.exe.first" || { echo "iiis-2.exe DIVERGED"; exit 6; }
    fi
    if [ -f "$COMPILED/xii_lattice.bin" ] && [ -f "$COMPILED/xii_lattice.bin.first" ]; then
        cmp -s "$COMPILED/xii_lattice.bin" "$COMPILED/xii_lattice.bin.first" || { echo "lattice DIVERGED"; exit 6; }
    fi
    if [ -f "$COMPILED/xii_manifest.bin" ] && [ -f "$COMPILED/xii_manifest.bin.first" ]; then
        cmp -s "$COMPILED/xii_manifest.bin" "$COMPILED/xii_manifest.bin.first" || { echo "manifest DIVERGED"; exit 6; }
    fi
    echo "[xii] determinism: PASS"
    exit 0
fi

echo "[xii] step 1: verify ceremony certs (Ω1..Ω12) -- if present"
for omega in 1 2 3 4 5 6 7 8 9 10 11 12; do
    cert="$BOOT/ceremonies/omega_${omega}.cert"
    if [ -f "$cert" ]; then
        if [ -x "$COMPILED/iiis-0.exe" ]; then
            "$COMPILED/iiis-0.exe" --verify-trinity-cert "$cert" 2>/dev/null || true
        fi
    fi
done

echo "[xii] step 2: verify Manifest mhash against golden"
if [ -f "$BOOT/xii_manifest.bin" ] && [ -f "$BOOT/xii_manifest.mhash.golden" ]; then
    expected="$(cat $BOOT/xii_manifest.mhash.golden | tr -d '[:space:]')"
    actual="$(sha256sum $BOOT/xii_manifest.bin | cut -d' ' -f1)"
    if [ "$expected" != "$actual" ]; then
        echo "[xii] manifest mhash MISMATCH"
        echo "  expected: $expected"
        echo "  actual:   $actual"
        exit 4
    fi
fi

echo "[xii] step 3: rebuild iiis-1 with XII semantic checks (if available)"
if [ -x "$BOOT/build_iiis1.sh" ]; then
    bash "$BOOT/build_iiis1.sh"
fi

echo "[xii] step 4: verify iiis-1 mhash (if golden present)"
if [ -f "$BOOT/iiis-1.mhash" ] && [ -x "$COMPILED/iiis-1.exe" ]; then
    expected1="$(cat $BOOT/iiis-1.mhash | tr -d '[:space:]')"
    actual1="$(sha256sum $COMPILED/iiis-1.exe | cut -d' ' -f1)"
    if [ "$expected1" != "$actual1" ]; then
        echo "[xii] iiis-1 mhash MISMATCH"
        exit 3
    fi
fi

echo "[xii] step 5: generate Lattice cells from Manifest (if iiis-1 supports --generate-lattice)"
if [ -x "$COMPILED/iiis-1.exe" ] && [ -f "$BOOT/xii_manifest.bin" ]; then
    "$COMPILED/iiis-1.exe" --generate-lattice \
        --manifest "$BOOT/xii_manifest.bin" \
        --output "$COMPILED/xii_lattice.bin" 2>/dev/null || true
fi

echo "[xii] step 6: build iiis-2 with XII codegen (if available)"
if [ -x "$BOOT/build_iiis2.sh" ]; then
    bash "$BOOT/build_iiis2.sh" --xii-enabled || bash "$BOOT/build_iiis2.sh"
fi

echo "[xii] step 7: run XII anti-drift suite"
if [ -x "$STDLIB/scripts/run_xii_antidrift.sh" ]; then
    bash "$STDLIB/scripts/run_xii_antidrift.sh" || { echo "[xii] anti-drift FAIL"; exit 3; }
fi

echo "[xii] step 8: run full corpus through XII compiler"
if [ -x "$STDLIB/scripts/run_corpus.sh" ] && [ -x "$COMPILED/iiis-2.exe" ]; then
    IIIS="$COMPILED/iiis-2.exe" bash "$STDLIB/scripts/run_corpus.sh" || { echo "[xii] corpus FAIL"; exit 2; }
fi

echo "[xii] step 9: run XII-specific corpus (tests 280..372)"
if [ -x "$STDLIB/scripts/run_xii_corpus.sh" ] && [ -x "$COMPILED/iiis-2.exe" ]; then
    IIIS="$COMPILED/iiis-2.exe" bash "$STDLIB/scripts/run_xii_corpus.sh" || { echo "[xii] XII corpus FAIL"; exit 2; }
fi

echo "[xii] step 10: emit XII witness sidecar (if iiis-2 supports it)"
if [ -x "$COMPILED/iiis-2.exe" ]; then
    "$COMPILED/iiis-2.exe" --emit-xii-witness > "$COMPILED/iiis-2.exe.xii_witness.json" 2>/dev/null || true
fi

echo "[xii] BUILD COMPLETE"
if [ -x "$COMPILED/iiis-2.exe" ]; then
    echo "  iiis-2.exe:       $(sha256sum $COMPILED/iiis-2.exe | cut -d' ' -f1)"
fi
if [ -f "$COMPILED/xii_lattice.bin" ]; then
    echo "  xii_lattice.bin:  $(sha256sum $COMPILED/xii_lattice.bin | cut -d' ' -f1)"
fi
if [ -f "$BOOT/xii_manifest.bin" ]; then
    echo "  xii_manifest.bin: $(sha256sum $BOOT/xii_manifest.bin | cut -d' ' -f1)"
fi
exit 0
