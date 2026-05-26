#!/usr/bin/env bash
# Independently verify the Tier-1 gate.sys is the disassembly-checked artifact
# BEFORE signing/deploying. Read-only; asserts every load-gating property.
set -uo pipefail
cd "$(dirname "$0")/.."
export SYS="KATABASIS-DEPLOY/build/gate.sys"
export KNOWN="63ba66291f75882d69b2a5db46d69240b61327ef4be6fd39840f83589d6107cc"
[ -f "$SYS" ] || { echo "gate.sys missing - run build_gate_sys.sh first"; exit 1; }
export H="$(sha256sum "$SYS" | cut -d' ' -f1)"
echo "gate.sys sha256 = $H"
fail=0
chk(){ if bash -c "$2" >/dev/null 2>&1; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s\n' "$1"; fail=1; fi; }

chk "byte-hash matches the disassembly-verified build" '[ "$H" = "$KNOWN" ]'
chk "PE32+ (pei-x86-64)"                                'objdump -f "$SYS" | grep -q pei-x86-64'
chk "Subsystem = NT native"                            'objdump -p "$SYS" | grep -qi "Subsystem.*native"'
chk "entry point == DriverEntry (VA 0x140001000)"      'objdump -f "$SYS" | grep -q "start address 0x0000000140001000"'
chk "DriverEntry symbol present"                       'objdump -t "$SYS" | grep -qw DriverEntry'
chk "NO DLL imports (no ntoskrnl/user dependency)"     '! objdump -p "$SYS" | grep -qi "DLL Name"'
chk "relocatable (.reloc + HAS_RELOC)"                 'objdump -h "$SYS" | grep -q "\.reloc" && objdump -f "$SYS" | grep -q HAS_RELOC'
chk "DriverEntry returns STATUS_NOT_SUPPORTED 0xc00000bb" 'objdump -d "$SYS" | grep -A30 "<DriverEntry>:" | grep -q "movabs .0xc00000bb"'
chk "witness bus is a register-preserving leaf (ret)"  'objdump -d "$SYS" | grep -A1 "<iii_witness_emit_kernel>:" | grep -qw ret'

echo ""
if [ "$fail" = 0 ]; then
    echo "ALL CHECKS PASS - gate.sys is the verified artifact, ready for sign_and_deploy.ps1."
else
    echo "VERIFICATION FAILED - do NOT deploy; rebuild and re-audit."
    exit 1
fi
