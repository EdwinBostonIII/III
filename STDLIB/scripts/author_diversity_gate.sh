#!/usr/bin/env bash
# author_diversity_gate.sh -- SVIR-DDC-RESIDUAL item 2, the ENFORCEABLE half, made executable.
#
# Author-diversity closes where implementations of INDEPENDENT AUTHORSHIP witness the same bytes.
# This gate enforces every such joint that exists on this host, as one falsifiable sweep:
#
#   AXIS A  compiler lineages: the gcc-built and MSVC-built iiis-0 seeds (GNU project vs Microsoft
#           -- genuinely independent authors) emit IDENTICAL object code on the full chain + broad
#           witness (seed_ddc_msvc.sh; zero divergence).
#   AXIS B  the WITNESS TRIANGLE on every sealed trust anchor: three SHA-256 implementations of
#           three independent authorships -- III's numera/cad (this repo, via sovhash), GNU
#           coreutils sha256sum, Microsoft certutil -- must agree byte-for-byte, and match the
#           committed golden where one exists.  A lie in any one is exposed by the other two.
#   AXIS C  consumer witnesses: GNU binutils (objdump) structurally parses every anchor PE, and
#           Microsoft's loader executes the III-built tool (sovhash ran in AXIS B).
#   AXIS D  external vectors: corpus 665_cad -- NIST-authored FIPS 180-4/202 vectors gate the very
#           hasher AXIS B trusts (the vectors' authorship is independent of this repo).
#
#   RESIDUAL (stated, not silently passed): an independently-AUTHORED second .iii->SVIR emitter --
#   by definition a second team's work; no session of this repo's author-process can create it.
#   The enabling mechanism is delivered and gated (DOCS/SVIR-V1-CANONICAL.md + run_ddc.sh's
#   byte-exact conformance harness + this gate); the day a second team writes one, run_ddc judges
#   it instantly.
#
# exit 0 iff AXES A-D all green.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
LIB="$ROOT/STDLIB/build/iii/libiii_native.a"
W="$(mktemp -d)"
fail=0
say(){ echo "[authdiv] $*"; }

# ---- build the III-authored vertex fresh (self-contained; the archive carries cad) ----
"$IIIS" "$ROOT/STDLIB/iii/aether/sovhash.iii" --compile-only --out "$W/sovhash.o" 2>"$W/c.log" \
  || { say "FAIL: sovhash compile"; exit 1; }
gcc "$W/sovhash.o" "$LIB" -lws2_32 -lkernel32 -o "$W/sovhash.exe" 2>"$W/l.log" \
  || { say "FAIL: sovhash link"; exit 1; }

# ---- AXIS A: independent compiler lineages ----
say "AXIS A: seed lineages (GNU gcc vs Microsoft MSVC) ..."
if bash "$ROOT/COMPILER/BOOT/seed_ddc_msvc.sh" >"$W/a.log" 2>&1; then
    say "AXIS A: PASS -- zero divergence across independent compiler lineages"
else
    say "AXIS A: FAIL -- seed_ddc_msvc red (see log)"; tail -3 "$W/a.log"; fail=$((fail+1))
fi

# ---- AXIS B: the witness triangle on the sealed trust anchors ----
command -v certutil >/dev/null 2>&1 || { say "AXIS B: FAIL -- certutil (the Microsoft vertex) absent"; fail=$((fail+1)); }
ANCHORS=( "COMPILED/iiis-0.exe" "COMPILED/iiis-1.exe" "COMPILED/iiis-2.exe" "COMPILER/BOOT/xii_manifest.bin" )
for rel in "${ANCHORS[@]}"; do
    f="$ROOT/$rel"
    [ -f "$f" ] || { say "AXIS B: FAIL -- anchor missing: $rel"; fail=$((fail+1)); continue; }
    h_iii="$("$W/sovhash.exe" "$f" | tr -d '\r')"
    h_gnu="$(sha256sum "$f" | cut -d' ' -f1)"
    h_ms="$(certutil -hashfile "$(cygpath -w "$f")" SHA256 2>/dev/null | sed -n 2p | tr -d ' \r' | tr 'A-F' 'a-f')"
    if [ -n "$h_iii" ] && [ "$h_iii" = "$h_gnu" ] && [ "$h_iii" = "$h_ms" ]; then
        say "AXIS B: $rel  TRIANGLE-AGREES  $h_iii"
    else
        say "AXIS B: FAIL -- $rel  iii=$h_iii gnu=$h_gnu ms=$h_ms"; fail=$((fail+1))
    fi
    # golden equality where a committed pin exists (two formats: bare digest / 'digest  name')
    g=""
    if [ "$rel" = "COMPILED/iiis-1.exe" ] && [ -f "$ROOT/COMPILER/BOOT/iiis-1.mhash" ]; then
        g="$(head -n1 "$ROOT/COMPILER/BOOT/iiis-1.mhash" | tr -d '[:space:]')"
    elif [ -f "$f.mhash" ]; then
        g="$(head -n1 "$f.mhash" | awk '{print $1}')"
    fi
    if [ -n "$g" ] && [ "$g" != "$h_iii" ]; then
        say "AXIS B: FAIL -- $rel triangle digest != committed golden ($g)"; fail=$((fail+1))
    fi
done

# ---- AXIS C: independently-authored consumers accept the artifacts ----
for rel in "COMPILED/iiis-0.exe" "COMPILED/iiis-1.exe" "COMPILED/iiis-2.exe"; do
    if objdump -h "$ROOT/$rel" >/dev/null 2>&1; then
        say "AXIS C: $rel  parsed by GNU binutils (objdump -h rc=0)"
    else
        say "AXIS C: FAIL -- objdump cannot parse $rel"; fail=$((fail+1))
    fi
done
say "AXIS C: Microsoft loader witness -- sovhash.exe executed successfully in AXIS B (III-built PE, OS-run)"

# ---- AXIS D: NIST-authored vectors gate the hasher itself ----
"$IIIS" "$ROOT/STDLIB/corpus/665_cad.iii" --compile-only --out "$W/665.o" 2>"$W/665c.log" \
  || { say "AXIS D: FAIL -- 665_cad compile"; fail=$((fail+1)); }
if [ -f "$W/665.o" ]; then
    gcc "$W/665.o" "$LIB" -lws2_32 -lkernel32 -o "$W/665.exe" 2>"$W/665l.log" \
      || { say "AXIS D: FAIL -- 665_cad link"; fail=$((fail+1)); }
fi
if [ -x "$W/665.exe" ]; then
    "$W/665.exe" >/dev/null 2>&1; rc=$?
    if [ "$rc" = "99" ]; then
        say "AXIS D: PASS -- 665_cad exit 99 (NIST FIPS vectors hold on numera/cad)"
    else
        say "AXIS D: FAIL -- 665_cad exit $rc (want 99)"; fail=$((fail+1))
    fi
fi

echo "============================================================"
if [ "$fail" -eq 0 ]; then
    say "GATE PASS -- every author-diversity joint that CAN exist on this host is enforced green:"
    say "  A independent compiler lineages (GNU vs Microsoft) -- zero divergence"
    say "  B three-authorship hash triangle (III/cad + GNU + Microsoft) on every sealed anchor"
    say "  C independently-authored consumers parse (GNU) and execute (Microsoft) the artifacts"
    say "  D NIST-authored vectors gate the hasher"
    say "RESIDUAL (social, named): an independently-authored second SVIR emitter -- a second team's"
    say "  work by definition; the conformance mechanism that will judge it is delivered and gated."
    exit 0
fi
say "GATE FAILED: $fail joint(s) red"
exit 1
