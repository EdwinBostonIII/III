#!/usr/bin/env bash
# run_evergreen.sh -- Φ7 exit gate (III-COMPLETION-PLAN Part 3 / III-UNIFIED-ARCHITECTURE §9):
#
#   THE EVERGREEN GUARANTEE: every standalone program is INDEPENDENTLY functional -- it builds from
#   source through the SOVEREIGN toolchain (sovas assemble, sovld link -- gcc NEVER assembles, ld NEVER
#   links) and runs to its real exit code.  Plus the no-stubs scan: zero incomplete-work markers in the
#   load-bearing sources.
#
# WHAT IT PROVES, per program (discovered: every `fn main` under STDLIB/sovir + STDLIB/sovtc):
#   build : sovbuild.sh routes EVERY module SOVEREIGN (witness=0).  A witness (gcc-as) module count > 0
#           is a FAIL -- "a gcc dependency reappears -> run_evergreen reddens" (the arch doc's falsifier).
#   run   : mode=kat programs run bare and must exit 99 (the tree's gate convention; measured exceptions
#           get an OVERRIDE row).  mode=buildonly programs (GUI event loops / drivers needing canonical
#           input) must LINK sovereignly; their run is owned by their own interactive/KAT gates.
#
# NO-STUBS SCAN: strict WORK-MARKERS only (TODO/FIXME/XXX/HACK/NOT IMPLEMENTED).  Technical vocabulary
# ("layout-pass placeholder bytes", "import trap-stub") is legitimate mechanism prose, NOT debt -- the
# 2026-07-07 census: 29 vocabulary uses, 0 work-markers.  The scan holds that floor at zero.
#
# EVERGREEN_FILTER=<ERE> subsets by program name (iteration aid; the Φ7 claim is the full run).
# Exit 0 = all green ; 1 = any red (named).
set -u
export LC_ALL=C
SD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SD/../.." && pwd)"
FILTER="${EVERGREEN_FILTER:-.}"
TO="${EVERGREEN_TIMEOUT_S:-900}"
OUTDIR="$ROOT/STDLIB/build/evergreen"; mkdir -p "$OUTDIR"

# measured non-99 legitimate exits: "name|rc|reason"  (populated from observed first-run reality)
OVERRIDES=(
)
override_rc() { local n="$1"; local o; for o in "${OVERRIDES[@]}"; do [ "${o%%|*}" = "$n" ] && { echo "$o" | cut -d'|' -f2; return 0; }; done; return 1; }

# ---- no-stubs scan (fail fast: debt gates everything) ----
marks=$(grep -rnE "\bTODO\b|\bFIXME\b|\bXXX\b|\bHACK\b|\bNOT IMPLEMENTED\b|\bnot yet implemented\b" \
        "$ROOT/STDLIB/sovir"/*.iii "$ROOT/STDLIB/sovtc"/*.iii "$ROOT/COMPILER/BOOT"/*.iii 2>/dev/null)
if [ -n "$marks" ]; then
    echo "$marks" | head -20
    echo "EVERGREEN: FAIL -- incomplete-work markers in load-bearing sources (floor is ZERO)"
    exit 1
fi
echo "[evergreen] no-stubs scan: clean (0 work-markers)"

pass=0; fail=0; ran=0; declare -a REDS
for f in "$ROOT/STDLIB/sovir"/*.iii "$ROOT/STDLIB/sovtc"/*.iii; do
    [ -f "$f" ] || continue
    grep -qE "^fn main|fn main\(" "$f" || continue
    name="$(basename "$f" .iii)"
    # crt0 is the RUNTIME SHIM (the cstart argv bridge every sovereign exe links), not a standalone
    # program -- sovbuilding it "as a program" would be a category error, not a claim.
    if [ "$name" = "crt0" ]; then continue; fi
    # PROBE VEHICLES by tree convention: leading-underscore (_vprobe, _svir_ci_oob) OR a _probe suffix
    # (eidos_ripple_probe -> a cg_r3 driver returning a DIAGNOSTIC 0; zk_ext4_probe -> 200).  A probe
    # emits a diagnostic code, not the 99 gate convention, and is owned by its subsystem gate
    # (run_eidos_svir.sh, run_zk.sh); scoring it against 99 is a category error.
    case "$name" in _*) continue;; esac
    case "$name" in *_probe) continue;; esac
    # *_w files are WAIST-SUBSET sources (the iiisv dialect: suffix-less literals, svir_putc builtin)
    # compiled BY iiisv into anchor-verified SVIR -- not win64 standalone programs.  Their gate is
    # run_retarget.sh (a Γ leg below): anchor + byte-match + fixpoint, on every host route.
    case "$name" in *_w) continue;; esac
    # PAYLOAD CONSUMERS: modules whose main() consumes the SVIR payload contract (extern svir_ptr/
    # svir_len/verify_body, or a "svir_prog.iii"/"gen_svir.iii" companion).  They are main-bearing
    # LIBRARIES -- a translator/dumper/verifier/interp is meaningless without a payload module linked
    # in, so building one standalone leaves those externs unresolved and it exits 127.  Their REAL
    # gates link them WITH a real payload and prove them byte-exact: run_host_matrix.sh (6 routes) and
    # run_retarget.sh (byte-match + fixpoint) -- both Γ legs below.  Excluding them here is the same
    # category call as crt0 (a shim, not a program), and it is what makes the FULL gate honest: before
    # this rule the unfiltered run was RED on svir_x86/svir_elf/... (127!=99), a discovery over-reach.
    if grep -qE 'extern[^\n]*fn (svir_ptr|svir_len|verify_body)|from "(svir_prog|gen_svir)\.iii"' "$f"; then continue; fi
    printf '%s' "$name" | grep -qE "$FILTER" || continue
    ran=$((ran+1))
    # Modes: kat (bare-run must exit 99) / driver (argv tool: must LOAD + exit DELIBERATELY on empty
    # argv -- any rc except the crash/timeout class; its full behavior is owned by its own gates) /
    # buildonly (GUI event loop: sovereign LINK is the claim; the run belongs to its windowed gates).
    mode="kat"
    if grep -q "fn main(argc" "$f"; then mode="driver"; fi
    if grep -qE "CreateWindow|GetMessageA|PeekMessageA|RegisterClass" "$f"; then mode="buildonly"; fi
    exe="$OUTDIR/${name}.sov.exe"
    blog="$OUTDIR/${name}.build.log"
    # sovbuild RUNS the program after linking and exits with the PROGRAM's rc -- so its exit code is
    # NOT the build verdict (a driver's bare-run usage-exit would read as a build failure).  The build
    # succeeded iff sovld reported LINKED and the PE exists; the per-mode run below is OURS.
    timeout "$TO" bash "$ROOT/STDLIB/sovtc/sovbuild.sh" "$f" "$exe" > "$blog" 2>&1
    if ! grep -q "LINKED (sovld" "$blog" || [ ! -f "$exe" ]; then
        printf '[evergreen] FAIL %-32s (sovereign build/link failed; log %s)\n' "$name" "${blog#$ROOT/}"
        fail=$((fail+1)); REDS+=("$name build"); continue
    fi
    wit=$(sed -n 's/.*ROUTE MANIFEST: sovereign=[0-9]* *witness=\([0-9]*\).*/\1/p' "$blog" | head -1)
    if [ -n "$wit" ] && [ "$wit" -gt 0 ]; then
        printf '[evergreen] FAIL %-32s (witness=%s modules -- gcc-as re-entered the build)\n' "$name" "$wit"
        fail=$((fail+1)); REDS+=("$name witness=$wit"); continue
    fi
    if [ "$mode" = "buildonly" ]; then
        printf '[evergreen] PASS %-32s (sovereign link OK; GUI driver -- run owned by its windowed gate)\n' "$name"
        pass=$((pass+1)); continue
    fi
    timeout 120 "$exe" >/dev/null 2>&1
    rc=$?
    if [ "$mode" = "driver" ]; then
        # a sovereign-built argv tool on empty argv must EXIT DELIBERATELY (usage/refusal), never
        # crash (SIGSEGV 139 / SIGABRT 134 / SIGFPE 136 / SIGILL 132) or hang (timeout 124/143).
        case "$rc" in
            124|132|134|136|139|143)
                printf '[evergreen] FAIL %-32s (driver crashed/hung bare: rc=%s)\n' "$name" "$rc"
                fail=$((fail+1)); REDS+=("$name driver-crash rc=$rc") ;;
            *)
                printf '[evergreen] PASS %-32s (sovereign build + driver exits deliberately, rc=%s)\n' "$name" "$rc"
                pass=$((pass+1)) ;;
        esac
        continue
    fi
    want=99
    if w=$(override_rc "$name"); then want="$w"; fi
    if [ "$rc" -eq "$want" ]; then
        printf '[evergreen] PASS %-32s (sovereign build + run rc=%s)\n' "$name" "$rc"
        pass=$((pass+1))
    else
        printf '[evergreen] FAIL %-32s (ran rc=%s, expected %s)\n' "$name" "$rc" "$want"
        fail=$((fail+1)); REDS+=("$name rc=$rc!=$want")
    fi
done

echo "-------------------------------------------------------------"
# ---- Γ legs (Γ5, the living-invariant extension; full runs only, not filtered iterations):
# host matrix (every route agrees) + retargeting closure (translators self-translate to fixpoint)
# + germination (the spore regrows on virgin prefixes) -- each a full gate with falsifiers.
if [ "$FILTER" = "." ]; then
    for g in sovir/run_host_matrix.sh sovir/run_retarget.sh sovir/run_germinate.sh; do
        gname="$(basename "$g")"
        if bash "$ROOT/STDLIB/$g" > "$ROOT/COMPILED/_evg_${gname%.sh}.log" 2>&1; then
            printf '[evergreen] PASS %-32s (Γ gate green)\n' "$gname"; pass=$((pass+1))
        else
            printf '[evergreen] FAIL %-32s (Γ gate red; log COMPILED/_evg_%s.log)\n' "$gname" "${gname%.sh}"
            fail=$((fail+1)); REDS+=("$gname Γ-gate")
        fi
        ran=$((ran+1))
    done
    echo "-------------------------------------------------------------"
fi
echo "[evergreen] programs: ran=$ran pass=$pass fail=$fail"
if [ "$fail" -gt 0 ]; then
    printf '[evergreen] RED: %s\n' "${REDS[@]}"
    echo "EVERGREEN: FAIL"
    exit 1
fi
echo "EVERGREEN: PASS -- every standalone program self-builds sovereignly (witness=0) + no stubs + the Γ living invariant (host matrix, retargeting fixpoint, spore germination) holds."
exit 0
