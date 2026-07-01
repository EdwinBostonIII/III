# Rebuild + verify the quotient/involution kit. Non-invasive: only reads COMPILED\iiis-2.exe and
# STDLIB\build\iii\libiii_native.a; writes only into TOOLS-QUOTIENT\build. Expect all three = 99.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$IIIS = (Resolve-Path 'COMPILED\iiis-2.exe').Path
$LIB  = (Resolve-Path 'STDLIB\build\iii\libiii_native.a').Path
$T = 'TOOLS-QUOTIENT'; $O = "$T\build"; New-Item -ItemType Directory -Force -Path $O | Out-Null

function Compile($src,$obj){ & $IIIS $src --compile-only --out $obj 2>&1 | Out-Null; $global:LASTEXITCODE }
function Link($objs,$exe){ & gcc @objs $LIB -lws2_32 -lkernel32 -o $exe 2>&1 | Out-Null; $global:LASTEXITCODE }

$tools = @(
  @{ name='2276_quotient_space_compute'; kat="$T\2276_quotient_space_compute.iii"; organ=$null;                   organsrc=$null },
  @{ name='2274_meta_involution_orbit';  kat="$T\2274_meta_involution_orbit.iii";  organ="$O\esv.o";              organsrc="$T\exact_surd_value.iii" },
  @{ name='2277_quotient_oracle_orbit';  kat="$T\2277_quotient_oracle_orbit.iii";  organ="$O\kfield.o";           organsrc="$T\kfield.iii" },
  @{ name='2148_theorem_fuzzer';         kat="$T\2148_theorem_fuzzer.iii";         organ="$O\kfield.o";           organsrc="$T\kfield.iii" },
  @{ name='2149_universal_block';        kat="$T\2149_universal_block.iii";        organ="$O\kfield.o";           organsrc="$T\kfield.iii" }
)

$all = 0
foreach($t in $tools){
  $objs = @()
  if($t.organsrc){ if((Compile $t.organsrc $t.organ) -ne 0){ Write-Host "$($t.name): ORGAN COMPILE FAIL"; $all=1; continue }; $objs += $t.organ }
  $kobj = "$O\$($t.name).o"
  if((Compile $t.kat $kobj) -ne 0){ Write-Host "$($t.name): KAT COMPILE FAIL"; $all=1; continue }
  $objs = @($kobj) + $objs
  $exe = "$O\$($t.name).exe"
  if((Link $objs $exe) -ne 0){ Write-Host "$($t.name): LINK FAIL"; $all=1; continue }
  & $exe | Out-Null; $rc = $LASTEXITCODE
  $verdict = if($rc -eq 99){ 'GREEN (99)' } else { "RED (exit $rc)"; $all=1 }
  Write-Host ("{0,-32} {1}" -f $t.name, $verdict)
}
if($all -eq 0){ Write-Host "`nALL GREEN." } else { Write-Host "`nSOME FAILED." ; exit 1 }
