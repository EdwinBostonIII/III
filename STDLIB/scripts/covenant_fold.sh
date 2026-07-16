#!/usr/bin/env sh
# STDLIB/scripts/covenant_fold.sh -- an INDEPENDENT re-implementation of `iii-judge fold`.
#
# This is the SECOND OBSERVER, not a member of III: it recomputes the covenant fold
#   h_0 = 0^32 ; h_k = SHA256(h_{k-1} || row_k)   over the non-empty rows of <file>
# using only POSIX sh + coreutils sha256sum + perl (pack). Its whole purpose is to be run on a
# DIFFERENT host/OS with a DIFFERENT SHA-256 implementation and reproduce iii-judge's core
# byte-for-byte -- turning "host-invariant by construction" into "host-invariant by OBSERVATION".
# Validated against iii-judge's own vectors before use.
#
# Usage: covenant_fold.sh <core-lines-file>   -> prints the 64-hex fold root on stdout.
set -u
f="$1"
h="0000000000000000000000000000000000000000000000000000000000000000"
while IFS= read -r line || [ -n "$line" ]; do
    [ -z "$line" ] && continue
    h=$( { printf '%s' "$h" | perl -ne 'print pack("H*", $_)'; printf '%s' "$line"; } | sha256sum | cut -d' ' -f1 )
done < "$f"
printf '%s' "$h"
