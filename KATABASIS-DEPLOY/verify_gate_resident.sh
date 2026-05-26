#!/usr/bin/env bash
# Independently verify the Tier-2 resident gate-decision .sys before signing/deploying.
# Read-only; asserts every load-gating + structural property.
set -uo pipefail
cd "$(dirname "$0")/.."
export SYS="KATABASIS-DEPLOY/build/gate_resident.sys"
export KNOWN="472152e3c6c21894e3b8dda83a9b00b1deb521e93309dfe20ac84a80a262651b"
[ -f "$SYS" ] || { echo "gate_resident.sys missing - run build_gate_resident.sh first"; exit 1; }
export H="$(sha256sum "$SYS" | cut -d' ' -f1)"
echo "gate_resident.sys sha256 = $H"
fail=0
chk(){ if bash -c "$2" >/dev/null 2>&1; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s\n' "$1"; fail=1; fi; }

chk "byte-hash matches the verified build"             '[ "$H" = "$KNOWN" ]'
chk "PE32+ (pei-x86-64)"                               'objdump -f "$SYS" | grep -q pei-x86-64'
chk "Subsystem = NT native"                            'objdump -p "$SYS" | grep -qi "Subsystem.*native"'
chk "entry == DriverEntry (VA 0x140001000)"            'objdump -f "$SYS" | grep -q "start address 0x0000000140001000"'
chk "DriverEntry symbol present"                       'objdump -t "$SYS" | grep -qw DriverEntry'
chk "NO DLL imports (pure compute; no ntoskrnl)"       '! objdump -p "$SYS" | grep -qi "DLL Name"'
chk "relocatable (.reloc + HAS_RELOC)"                 'objdump -h "$SYS" | grep -q "\.reloc" && objdump -f "$SYS" | grep -q HAS_RELOC'
chk "the full gate-admit closure is linked in"         'objdump -t "$SYS" | grep -q "L_p_katabasis_gate_admit" && objdump -t "$SYS" | grep -q "L_p_sha256" && objdump -t "$SYS" | grep -q "L_p_keccak"'
chk "DriverEntry all-pass return 0xc00000bb present"   'objdump -d "$SYS" | grep -A1200 "<DriverEntry>:" | grep -q "movabs .0xc00000bb"'
chk "witness bus is a register-preserving leaf (ret)"  'objdump -d "$SYS" | grep -A1 "<iii_witness_emit_kernel>:" | grep -qw ret'

echo ""
if [ "$fail" = 0 ]; then
    echo "ALL CHECKS PASS - gate_resident.sys is the verified gate-decision artifact, ready for sign_and_deploy.ps1."
else
    echo "VERIFICATION FAILED - do NOT deploy; rebuild and re-audit."
    exit 1
fi
