<#
  KATABASIS crash-dump extractor (no kd/windbg needed).
  Self-elevates (one UAC), copies the latest C:\Windows\Minidump\*.dmp into
  KATABASIS-DEPLOY\crash\, and parses the kernel DUMP_HEADER64 directly:
    - bugcheck code + 4 params
    - the saved CPU CONTEXT at the crash (all 16 GPRs + RIP)  <- the key evidence
    - searches for the gate_resident driver's load base
  Writes crash\crash_report.txt. Read-only w.r.t. the system (only copies the dump).
#>
$ErrorActionPreference = 'Stop'
$pr = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $exe = (Get-Process -Id $PID).Path
    Write-Host "Requesting admin elevation (accept the UAC prompt)..." -ForegroundColor Yellow
    Start-Process -FilePath $exe -Verb RunAs -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"{0}"' -f $PSCommandPath))
    return
}

$dir = Join-Path (Split-Path -Parent $PSCommandPath) 'crash'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$report = Join-Path $dir 'crash_report.txt'
function Log($m){ $m | Tee-Object -FilePath $report -Append | Out-Host }
Set-Content -Path $report -Value ("KATABASIS crash report  {0}" -f (Get-Date)) -Encoding UTF8

$dmp = Get-ChildItem 'C:\Windows\Minidump\*.dmp' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $dmp) { Log "NO minidump found in C:\Windows\Minidump."; Read-Host "Enter to close"; return }
$dest = Join-Path $dir $dmp.Name
Copy-Item $dmp.FullName $dest -Force
Log ("dump: {0}  ({1:N0} bytes)  copied -> {2}" -f $dmp.FullName, $dmp.Length, $dest)

$b = [IO.File]::ReadAllBytes($dest)
function U32($o){ [BitConverter]::ToUInt32($b,$o) }
function U64($o){ [BitConverter]::ToUInt64($b,$o) }
$sig = [Text.Encoding]::ASCII.GetString($b,0,8)
Log ("signature: '{0}'  (PAGEDU64 = 64-bit kernel dump)" -f $sig)
Log ("BugCheckCode = 0x{0:x8}" -f (U32 0x38))
Log ("  P1=0x{0:x16}  P2=0x{1:x16}" -f (U64 0x40),(U64 0x48))
Log ("  P3=0x{0:x16}  P4=0x{1:x16}" -f (U64 0x50),(U64 0x58))
$rip_target = U64 0x48   # BugCheckParameter2 = faulting IP for 0x1E

# Locate the CONTEXT: DUMP_HEADER64.ContextRecord is at 0x348; CONTEXT.Rip at +0xF8.
# Verify by matching CONTEXT.Rip == P2; else scan for P2 as an 8-byte LE pattern.
function DumpContext($ctx){
  $names = 'Rax','Rcx','Rdx','Rbx','Rsp','Rbp','Rsi','Rdi','R8','R9','R10','R11','R12','R13','R14','R15'
  Log ("CONTEXT @ file 0x{0:x}:" -f $ctx)
  for($i=0;$i -lt 16;$i++){ $v=U64 ($ctx+0x78+8*$i); $mark = if($v -eq [uint64]::MaxValue){'  <== 0xFFFFFFFFFFFFFFFF (-1)'}elseif($v -eq 0){'  <== 0'}else{''}; Log ("  {0,-4}= 0x{1:x16}{2}" -f $names[$i],$v,$mark) }
  Log ("  RIP = 0x{0:x16}" -f (U64 ($ctx+0xF8)))
}
$ctxOff = 0x348
if ((U64 ($ctxOff+0xF8)) -eq $rip_target) { Log "CONTEXT found at 0x348 (RIP matches P2)."; DumpContext $ctxOff }
else {
  Log "CONTEXT not at 0x348; scanning for RIP pattern..."
  $pat = [BitConverter]::GetBytes($rip_target)
  for($o=0; $o -lt $b.Length-8; $o++){ $ok=$true; for($j=0;$j -lt 8;$j++){ if($b[$o+$j] -ne $pat[$j]){$ok=$false;break} }; if($ok){ Log ("  RIP pattern at file 0x{0:x}" -f $o); if($o -ge 0xF8){ DumpContext ($o-0xF8) } } }
}

# Find the driver load base: search for the UTF-16LE module name and report nearby qwords.
foreach($name in 'gate_resident','IIIKatabasisGate'){
  $u16 = [Text.Encoding]::Unicode.GetBytes($name)
  for($o=0;$o -lt $b.Length-$u16.Length;$o++){ $ok=$true; for($j=0;$j -lt $u16.Length;$j++){ if($b[$o+$j] -ne $u16[$j]){$ok=$false;break} }; if($ok){ Log ("module-name '{0}' (UTF16) at file 0x{1:x}" -f $name,$o); break } }
}
Log "`nDone. Report: $report"
Read-Host "Press Enter to close"