#!/usr/bin/env bash
# gen_world_graph.sh -- THE PRODUCER of STDLIB/iii/aether/world_graph.iii (reunification W4b-i.9.1:
# a GENERATED file must NAME its generator; this script is it, and regenerating is one command).
#
# Extraction semantics (reverse-engineered from the v1 data and preserved):
#   NODES  = every STDLIB/iii/<subsystem>/<module>.iii, grouped by subsystem in ALPHABETICAL
#            subsystem order, ALPHABETICAL basename order within; index = node id.
#   GCLU   = fixed subsystem -> cluster-id map (v1's arbitrary-but-frozen enumeration):
#            numera=0 omnia=1 aether=2 verba=3 sanctus=4 nous=5 forcefield=6 eidos=7
#            katabasis=8 tempora=9 memoria=10 intent=11
#   EDGES  = one edge PER EXTERN DECLARATION LINE `from "X.iii"` (duplicates preserved --
#            multiplicity = coupling strength), source = declaring module, target = basename X
#            resolved against the node set (path prefixes like "aether/witness_hook.iii" are
#            basenamed; non-.iii externs like msvcrt/kernel32 skipped).
#   Arrays sized to the next power-of-two-ish headroom above live counts so the data never
#   outgrows its slab silently (v1 shipped [800]/[8000] at 783/5108).
set -u
III="$(cd "$(dirname "$0")/../.." && pwd)"
ORG="$III/STDLIB/iii"
OUT="$ORG/aether/world_graph.iii"
TMP="$III/STDLIB/build/worldgraph.$$"
mkdir -p "$III/STDLIB/build"

declare -A CLU=( [numera]=0 [omnia]=1 [aether]=2 [verba]=3 [sanctus]=4 [nous]=5
                 [forcefield]=6 [eidos]=7 [katabasis]=8 [tempora]=9 [memoria]=10 [intent]=11 )

# ── nodes ───────────────────────────────────────────────────────────────────────────────────────
: > "$TMP.nodes"
for dp in "$ORG"/*/; do
    d="$(basename "$dp")"
    [[ -z "${CLU[$d]+x}" ]] && { echo "[gen_world_graph] FATAL: subsystem '$d' has no cluster id -- extend the frozen map deliberately" >&2; exit 2; }
    for p in "$ORG/$d"/*.iii; do
        [[ -f "$p" ]] || continue
        printf '%s\t%s\n' "$(basename "$p" .iii)" "$d" >> "$TMP.nodes"
    done
done
sort -o "$TMP.nodes.sorted" -t $'\t' -k2,2 -k1,1 "$TMP.nodes" 2>/dev/null || sort "$TMP.nodes" > "$TMP.nodes.sorted"
mv "$TMP.nodes.sorted" "$TMP.nodes"
N=$(wc -l < "$TMP.nodes")

declare -A IDX SUB
i=0
while IFS=$'\t' read -r name sub; do IDX["$name"]=$i; SUB["$name"]="$sub"; i=$((i+1)); done < "$TMP.nodes"

# ── edges (one per extern line; unresolvable targets skipped) ────────────────────────────────────
# edges stream to "$TMP.edges" via the loop redirect below
while IFS=$'\t' read -r name sub; do
    src=${IDX["$name"]}
    while IFS= read -r tgt; do
        base="${tgt##*/}"; base="${base%.iii}"
        [[ -n "${IDX[$base]+x}" ]] && printf '%s\t%s\n' "$src" "${IDX[$base]}"
    done < <(grep -oE 'from "[A-Za-z0-9_/]+\.iii"' "$ORG/$sub/$name.iii" 2>/dev/null | sed 's/from "//; s/"//')
done < "$TMP.nodes" > "$TMP.edges"
NE=$(wc -l < "$TMP.edges")

NCAP=$(( (N / 256 + 1) * 256 ))
ECAP=$(( (NE / 2000 + 1) * 2000 ))

# ── emit ─────────────────────────────────────────────────────────────────────────────────────────
{
printf '/* world_graph.iii -- GENERATED from real III source by STDLIB/scripts/gen_world_graph.sh (THE producer;\n'
printf ' * hand-edits forbidden -- rerun the script).  Nodes (module files) with names + subsystem cluster, and the\n'
printf ' * real extern-dependency edges (one per declaration line; multiplicity = coupling strength).\n'
printf ' * [APP-SURFACE-MODULE] -- consumed by aether_world (window surface) + ws_home; compiled by its family gate.\n'
printf ' * III'\''s actual architecture, extracted not hand-picked. */\n'
printf 'module world_graph\n'
printf 'var GCLU : [i64; %d]   var GE0 : [i64; %d]   var GE1 : [i64; %d]\n' "$NCAP" "$ECAP" "$ECAP"
printf 'fn gr_nodes() -> i64 @export { return %di64 }\n' "$N"
printf 'fn gr_edges() -> i64 @export { return %di64 }\n' "$NE"
printf 'fn gr_clu(i: u64) -> i64 @export { return GCLU[i] }\n'
printf 'fn gr_e0(i: u64) -> i64 @export { return GE0[i] }\n'
printf 'fn gr_e1(i: u64) -> i64 @export { return GE1[i] }\n'
printf 'fn gr_name(i: u64) -> u64 @export {\n'
i=0
while IFS=$'\t' read -r name sub; do
    printf 'if i == %du64 { return "%s" as u64 }\n' "$i" "$name"
    i=$((i+1))
done < "$TMP.nodes"
printf 'return "?" as u64 }\n'
# gi0: cluster fills
printf 'fn gi0() -> i32 {\n'
i=0
while IFS=$'\t' read -r name sub; do
    printf 'GCLU[%du64]=%di64 ' "$i" "${CLU[$sub]}"
    i=$((i+1))
    (( i % 10 == 0 )) && printf '\n'
done < "$TMP.nodes"
printf '\nreturn 0i32 }\n'
# geN: edge fills, 450 edges per fn
gfn=1; cnt=0
printf 'fn ge1() -> i32 {\n'
ei=0
while IFS=$'\t' read -r s t; do
    printf 'GE0[%du64]=%di64 GE1[%du64]=%di64 ' "$ei" "$s" "$ei" "$t"
    ei=$((ei+1)); cnt=$((cnt+1))
    (( cnt % 6 == 0 )) && printf '\n'
    if (( cnt >= 450 )); then
        printf '\nreturn 0i32 }\n'
        gfn=$((gfn+1)); cnt=0
        printf 'fn ge%d() -> i32 {\n' "$gfn"
    fi
done < "$TMP.edges"
printf '\nreturn 0i32 }\n'
printf 'fn gr_init() -> i32 @export { gi0() '
g=1
while (( g <= gfn )); do printf 'ge%d() ' "$g"; g=$((g+1)); done
printf ' return 0i32 }\n'
} > "$OUT"

rm -f "$TMP.nodes" "$TMP.edges"
echo "[gen_world_graph] nodes=$N edges=$NE caps=$NCAP/$ECAP fns=ge1..ge$gfn -> $OUT"
