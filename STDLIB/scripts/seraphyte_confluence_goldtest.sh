#!/usr/bin/env bash
# seraphyte_confluence_goldtest.sh -- the causal/kinduct confluence verdict, proven against the SILICON.
#
# Not a self-authored checker: for each ripple set, EVERY interleaving is rendered as real .iii, compiled by
# the production iiis-2, and RUN on the CPU.  The hardware decides confluence -- do all orderings produce the
# same output? -- by executing the actual compiled arithmetic, NOT my caus_apply_one interpreter.  ser_kinduct's
# ski_confluent_reduced (the causal-based verdict) is then checked against that observation.  The proof is the
# execution; the causal layer only PREDICTS it.  A mismatch is a real defect, printed.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IIIS="$ROOT/COMPILED/iiis-2.exe"
LIB="$ROOT/STDLIB/build/iii/libiii_native.a"
W="$ROOT/STDLIB/build/_confl"; mkdir -p "$W"
say(){ printf '[confl] %s\n' "$*"; }

# op symbol for the compiled expression, and op code for the causal probe
sym(){ case "$1" in ADD) echo '+';; SUB) echo '-';; MUL) echo '*';; SHL) echo '<<';; esac; }
code(){ case "$1" in ADD) echo 0;; SUB) echo 1;; MUL) echo 2;; SHL) echo 3;; esac; }

PERMS=()
permute(){ # $1=prefix $2=remaining indices -> fills PERMS
  if [ -z "$2" ]; then PERMS+=("${1# }"); return; fi
  local x rest
  for x in $2; do
    rest="$(echo $2 | tr ' ' '\n' | grep -vx "$x" | tr '\n' ' ')"
    permute "$1 $x" "$rest"
  done
}

# run ONE interleaving on the silicon: render f(x)=<ordering applied to x>, compile, run, echo f(7) (the CPU's answer)
hw_run(){ # $1=perm (space-sep indices); uses OPS[] ARGS[]
  local acc="x" idx
  for idx in $1; do acc="($acc $(sym "${OPS[$idx]}") ${ARGS[$idx]}u64)"; done
  printf 'module p\nfn f(x: u64) -> u64 { return %s }\nfn main() -> u64 { return f(7u64) }\n' "$acc" > "$W/_o.iii"
  "$IIIS" "$W/_o.iii" --compile-only --out "$W/_o.o" >/dev/null 2>&1 && gcc "$W/_o.o" "$LIB" -lkernel32 -o "$W/_o.exe" >/dev/null 2>&1
  "$W/_o.exe"; echo $?
}

# the causal-layer prediction: perceive the ripples, return ski_confluent_reduced(n)
causal_verdict(){ # uses OPS[] ARGS[] N
  { printf 'module q\n'
    printf 'extern @abi(c-msvc-x64) fn caus_reset() -> i32 from "ser_causal.iii"\n'
    printf 'extern @abi(c-msvc-x64) fn caus_ripple(op: u32, arg: u64) -> u64 from "ser_causal.iii"\n'
    printf 'extern @abi(c-msvc-x64) fn ski_confluent_reduced(n: u32) -> u32 from "ser_kinduct.iii"\n'
    printf 'fn main() -> u64 {\n  caus_reset()\n'
    local i
    for i in $(seq 0 $((N-1))); do printf '  caus_ripple(%su32, %su64)\n' "$(code "${OPS[$i]}")" "${ARGS[$i]}"; done
    printf '  return ski_confluent_reduced(%su32) as u64\n}\n' "$N"
  } > "$W/_c.iii"
  "$IIIS" "$W/_c.iii" --compile-only --out "$W/_c.o" >/dev/null 2>&1 && gcc "$W/_c.o" "$LIB" -lkernel32 -o "$W/_c.exe" >/dev/null 2>&1
  "$W/_c.exe"; echo $?
}

FAIL=0
test_set(){ # $1=name; OPS/ARGS/N already set
  PERMS=(); permute "" "$(seq 0 $((N-1)) | tr '\n' ' ')"
  local first="" out hw=1 p
  for p in "${PERMS[@]}"; do
    out="$(hw_run "$p")"
    [ -z "$first" ] && first="$out"
    [ "$out" != "$first" ] && hw=0
  done
  local cz="$(causal_verdict)"
  local verdict="MATCH"; [ "$hw" != "$cz" ] && { verdict="MISMATCH"; FAIL=$((FAIL+1)); }
  printf '[confl] %-22s n=%s perms=%-3s SILICON confluent=%s  causal=%s  %s\n' \
    "$1" "$N" "${#PERMS[@]}" "$hw" "$cz" "$verdict"
}

say "set                    n  perms  SILICON(ran on CPU)  causal(predicted)  result"
say "---------------------------------------------------------------------------------"
OPS=(ADD ADD SUB); ARGS=(3 5 2);   N=3; test_set "3-additive(confluent)"
OPS=(MUL MUL);     ARGS=(2 3);     N=2; test_set "2-mul(confluent)"
OPS=(ADD MUL);     ARGS=(3 5);     N=2; test_set "ADD,MUL(NOT)"
OPS=(ADD ADD MUL); ARGS=(2 3 4);   N=3; test_set "ADD,ADD,MUL(NOT)"
OPS=(MUL ADD SHL); ARGS=(3 5 1);   N=3; test_set "MUL,ADD,SHL(NOT)"
OPS=(ADD ADD ADD SUB); ARGS=(1 2 4 1); N=4; test_set "4-additive(confluent)"
say "---------------------------------------------------------------------------------"
if [ "$FAIL" = 0 ]; then
  say "GOLD: on every set the causal verdict EQUALS what the compiled orderings actually computed on the CPU."
  say "The oracle is the silicon, not a function I wrote. ski_confluent_reduced predicts execution exactly."
  exit 0
else say "GOLD: $FAIL set(s) where the causal prediction != the silicon -- a real defect, not a passing script."; exit 1; fi
