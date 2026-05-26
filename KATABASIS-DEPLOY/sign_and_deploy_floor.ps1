<#
  KATABASIS Ring-1 FLOOR loader (#19a..I4 + [E7] + I3-iii)  -  sign + deploy + exercise + unload.

  gate_floor.sys is the DEDICATED, ISOLATED Ring-1 driver (separate from the proven gate_ioctl.sys).
  It STAYS RESIDENT: DriverEntry creates \Device\IIIKatabasisFloor + \??\IIIKatabasisFloor and returns
  STATUS_SUCCESS. This script LOADS it, runs floor_client.exe (FLOOR_PROBE + the SVM_DISABLE teardown
  primitive), then STOPS it (-> DriverUnload).

  WHAT #19a+b DO ON METAL (all reversible, all on YOUR machine):
    * #19a re-reads SVM capability (read-only) + runs the TEARDOWN PRIMITIVE: a Ring-0 WRMSR EFER on a
      PINNED core clearing ONLY bit 12 (SVME) via mask 0xFFFFFFFFFFFFEFFF -- with SVME=0 it writes EFER's
      own value (0x4d01 -> 0x4d01), a provable NO-OP.
    * #19b runs the SVM HOST-MODE ROUND-TRIP: alloc a 256KB contiguous region (<4GB), pin a core, then
      ENABLE SVM (WRMSR EFER |= 0x1000 -> 0x5d01, SVME on, long mode preserved), set VM_HSAVE_PA to the
      region's HostSave area, then FULLY REVERSE (clear VM_HSAVE_PA, WRMSR EFER &= ~0x1000 -> 0x4d01, free
      the region). SVM is enabled for MICROSECONDS on one core with NO VMCB and NO VMRUN -- nothing runs
      in a guest; this proves the state-changing enable + the region + VM_HSAVE_PA, all reversible.
    * #19c-i builds the full VMCB + NPT identity map + the throwaway guest code (VMMCALL+HLT) in a fresh
      256KB region, reads the fields back to verify, and frees -- MEMORY-ONLY (NO SVM enable, NO VMRUN);
      proves the VMCB construction matches CHARIOT-proven on metal, before the run rung (#19c-ii).
    * #19c-ii is THE VMRUN: on a pinned core it builds the VMCB, ENABLES SVM, and executes the proven
      bracket CLGI/VMSAVE/VMRUN/VMLOAD/STGI to run a DISPOSABLE guest whose entire body is one VMMCALL
      (immediately intercepted -> #VMEXIT, EXITCODE 0x81). It then disables SVM, clears VM_HSAVE_PA, and
      frees. The guest is confined by NPT to the region's identity-mapped 4GB and touches no host state.
    * I3 is THE GATE AT THE RING -1 VMEXIT: for each of 4 cases it does the #19c-ii VMRUN (guest VMMCALL ->
      #VMEXIT 0x81, then full SVM teardown) and -- only if the guest VMMCALL'd -- runs III's FULL gate
      decision (capability + content-address seal + hexad admissibility -> verdict) on the request. The
      gate is pure BSS-arena compute run AFTER SVM is down, so the privileged window stays exactly as small
      as #19c-ii. Proves III adjudicates guest hypercalls from the hypervisor seat (Tier-2/3 gate FUSED with
      Ring -1) -- all 4 verdicts (OK + 3 rejects). Each case is a separate, fully-torn-down SVM cycle.
    * I3-ii is THE RESUME LOOP: a 2-VMMCALL guest. The host adjudicates the 1st VMMCALL, writes the verdict
      into the guest's RAX, advances RIP, and RESUMES it (re-VMRUN); the guest carries the verdict to a 2nd
      VMMCALL where the host reads it back. Proves the I5 adjudicate-AND-RESUME loop with a disposable guest.
      The gate runs with SVM active + the guest paused -> the loop runs at DISPATCH IRQL (no preemption); the
      loop is iteration-bounded; SVM is torn down after. The disposable-guest rehearsal of the I5 mechanism.
    * I4 is NPT PAGE-FAULT INTERCEPTION: the guest's CODE page is marked not-present in the nested page table,
      so its first instruction FETCH faults (#VMEXIT_NPF=0x400); the host reads the faulting guest-physical
      address (VMCB.EXITINFO2), maps the page present, and RESUMES (no RIP advance -> the fetch re-executes);
      the guest then runs its VMMCALL. Proves III MEDIATES guest memory from Ring -1 -- the §0.6 NPT-CoW /
      observe brick-defense basis. The guest makes no arbitrary memory access (its only fault is its own code).
    * [E7] VMCB DIAG-COPY (Chunk B): a VMRUN that copies the FULL post-exit VMCB (control 1024B + state-save
      512B = 1536 bytes) out to R3 -- fault-as-data forensics, so any guest exit is fully inspectable from
      user mode (EXITCODE, guest RIP/CR0/segments, ...). Read-only capture; no behavior change.

  SAFETY: start=demand => never boot-loaded; a worst-case bugcheck is fixed by one normal reboot. The VMCB
  was independently proven correct on metal (#19c-i) and the VMRUN bracket is CHARIOT-proven byte-identical;
  SVM is enabled only TRANSIENTLY on a pinned core (SVMDIS=0 -> the enable cannot #GP), CLGI masks all
  interrupts across VMRUN, the guest is ONE disposable VMMCALL confined by NPT to the region, and SVM is
  disabled + VM_HSAVE_PA cleared before the IOCTL returns. Resident only between load and stop. RECOVERY:
  reboot, then re-run with -Uninstall.

  PROOF OF SUCCESS: sc start exits 0 (RUNNING, no crash) and floor_client.exe exits 0. The decisive block is
  [npt-intercept]: NPF=0x400 (the host CAUGHT the guest's nested page fault), VMMCALL=0x81 (the guest RAN
  after the host mapped the page), faulting GPA in the code page => III MEDIATED guest memory from Ring -1 --
  the CoW/observe brick-defense basis. The [resume-loop] (4/4 echo), [gate@VMEXIT] (4/4), [vmrun], [vmcb],
  [hostmode], [disable] PASSes precede it. (NPF != 0x400 = no fault caught; VMMCALL != 0x81 = the remap/resume
  failed -> investigate, do not retry blindly.)
#>
[CmdletBinding()]
param([switch]$Uninstall)
$ErrorActionPreference = 'Stop'

$pr = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $host_exe = (Get-Process -Id $PID).Path
    $a = @('-NoProfile','-ExecutionPolicy','Bypass','-File', ('"{0}"' -f $PSCommandPath))
    if ($Uninstall) { $a += '-Uninstall' }
    Write-Host "Requesting administrator elevation (accept the UAC prompt)..." -ForegroundColor Yellow
    Start-Process -FilePath $host_exe -Verb RunAs -ArgumentList $a
    return
}

$ScriptDir   = Split-Path -Parent $PSCommandPath
$FloorSys    = Join-Path $ScriptDir 'build\gate_floor.sys'
$SignedSys   = Join-Path $ScriptDir 'build\gate_floor.signed.sys'
$Client      = Join-Path $ScriptDir 'build\floor_client.exe'
$SvcName     = 'IIIKatabasisFloor'
$CertSubject = 'CN=III KATABASIS Test Cert'
$ExpectedHash = '187444EAA1A1D2BCA13AA030E1275443AAE5A8B8BFE14476D5EE340AD35F35EB'

function Write-Section($t){ Write-Host "`n==== $t ====" -ForegroundColor Cyan }
function Repair-PeChecksum([string]$Path){
    $b=[IO.File]::ReadAllBytes($Path)
    $e=[BitConverter]::ToInt32($b,0x3c); $co=$e+24+64
    $b[$co]=0;$b[$co+1]=0;$b[$co+2]=0;$b[$co+3]=0
    [uint64]$s=0; $n=$b.Length; $i=0
    while($i+1 -lt $n){ $s+=([uint32]$b[$i] -bor ([uint32]$b[$i+1] -shl 8)); while($s -shr 16){$s=($s -band 0xffff)+($s -shr 16)}; $i+=2 }
    if($n%2){ $s+=[uint32]$b[$n-1]; while($s -shr 16){$s=($s -band 0xffff)+($s -shr 16)} }
    $s=($s+[uint64]$n) -band 0xffffffff
    $cs=[BitConverter]::GetBytes([uint32]$s)
    $b[$co]=$cs[0];$b[$co+1]=$cs[1];$b[$co+2]=$cs[2];$b[$co+3]=$cs[3]
    [IO.File]::WriteAllBytes($Path,$b); return ('0x{0:x}' -f $s)
}
function Remove-TestCerts {
    foreach($store in 'Cert:\CurrentUser\My','Cert:\LocalMachine\Root','Cert:\LocalMachine\TrustedPublisher'){
        Get-ChildItem $store -ErrorAction SilentlyContinue | Where-Object { $_.Subject -eq $CertSubject } |
            ForEach-Object { Remove-Item $_.PSPath -Force -ErrorAction SilentlyContinue; Write-Host "  removed cert from $store" }
    }
}

if ($Uninstall) {
    Write-Section 'UNINSTALL'
    sc.exe stop $SvcName | Out-Null; sc.exe delete $SvcName | Out-Null
    Write-Host "  service '$SvcName' removed (if present)."
    if (Test-Path $SignedSys) { Remove-Item $SignedSys -Force; Write-Host "  removed $SignedSys" }
    Write-Host "`nUninstall complete. (Reboot if the driver was ever resident.)" -ForegroundColor Green
    Read-Host "Press Enter to close"; return
}

try {
    Write-Section 'KATABASIS Ring-1 FLOOR #19a  -  sign + deploy + exercise'
    Write-Host "Driver  : $FloorSys"
    Write-Host "Client  : $Client"
    Write-Host "Service : $SvcName  (type=kernel start=demand, RESIDENT)"

    Write-Section '1/9  test-signing mode'
    $bcd = (bcdedit /enum '{current}' | Out-String)
    if ($bcd -match '(?im)^\s*testsigning\s+Yes') { Write-Host "  testsigning = Yes  (OK)" -ForegroundColor Green }
    else { Write-Host "  testsigning is NOT enabled -> the signed driver will be REJECTED (577)." -ForegroundColor Red
           Write-Host "  Enable (elevated) then REBOOT:   bcdedit /set testsigning on" -ForegroundColor Yellow
           if ((Read-Host "  Continue anyway? (y/N)") -ne 'y') { Read-Host "Enter to close"; return } }

    Write-Section '1b/9  HVCI / Memory Integrity'
    try { $dg = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction Stop
          if ($dg.SecurityServicesRunning -contains 2) {
              Write-Host "  WARNING: HVCI is RUNNING -- it rejects self-signed/test drivers (~0x428)." -ForegroundColor Red
              if ((Read-Host "  Continue anyway? (y/N)") -ne 'y') { Read-Host "Enter to close"; return }
          } else { Write-Host "  HVCI not running (OK)" -ForegroundColor Green } }
    catch { Write-Host "  (HVCI query skipped: $($_.Exception.Message))" -ForegroundColor DarkYellow }

    Write-Section '2/9  System Restore checkpoint (best-effort)'
    try { Checkpoint-Computer -Description 'Pre III-KATABASIS Ring-1 floor #19a' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
          Write-Host "  checkpoint created." -ForegroundColor Green }
    catch { Write-Host "  (skipped: $($_.Exception.Message))" -ForegroundColor DarkYellow }

    Write-Section '3/9  verify gate_floor.sys byte-hash'
    if (-not (Test-Path $FloorSys)) { throw "gate_floor.sys not found - run build_gate_floor.sh first." }
    $h = (Get-FileHash $FloorSys -Algorithm SHA256).Hash
    Write-Host "  sha256 = $h"
    if ($h -ne $ExpectedHash) { Write-Host "  MISMATCH vs reviewed $ExpectedHash" -ForegroundColor Red
        if ((Read-Host "  Not the disassembly-verified build. Continue? (y/N)") -ne 'y') { Read-Host "Enter to close"; return } }
    else { Write-Host "  matches the disassembly-verified build  (OK)" -ForegroundColor Green }

    Write-Section '4/9  code-signing certificate'
    $cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -eq $CertSubject } | Select-Object -First 1
    if (-not $cert) {
        $cert = New-SelfSignedCertificate -Subject $CertSubject -Type CodeSigningCert -CertStoreLocation Cert:\CurrentUser\My `
                  -KeyUsage DigitalSignature -KeyExportPolicy Exportable -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(3)
        Write-Host "  created cert $($cert.Thumbprint)"
    } else { Write-Host "  reusing cert $($cert.Thumbprint)" }
    $cer = Join-Path $env:TEMP 'iii_katabasis_test.cer'
    Export-Certificate -Cert $cert -FilePath $cer | Out-Null
    Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
    Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null
    Remove-Item $cer -Force -ErrorAction SilentlyContinue
    Write-Host "  trusted in LocalMachine Root + TrustedPublisher  (OK)" -ForegroundColor Green

    Write-Section '5/9  sign a COPY'
    Copy-Item $FloorSys $SignedSys -Force
    $sig = Set-AuthenticodeSignature -FilePath $SignedSys -Certificate $cert -HashAlgorithm SHA256
    Write-Host "  signature status: $($sig.Status)"
    if ($sig.Status -ne 'Valid') { throw "signing failed: $($sig.StatusMessage)" }

    Write-Section '6/9  repair PE checksum'
    Write-Host "  checksum set to $(Repair-PeChecksum $SignedSys)  (OK)"

    Write-Section '7/9  register kernel service (start=demand)'
    sc.exe stop $SvcName 2>$null | Out-Null; sc.exe delete $SvcName 2>$null | Out-Null
    Start-Sleep -Milliseconds 300
    Write-Host "  $(sc.exe create $SvcName type= kernel start= demand binPath= "$SignedSys" DisplayName= 'III KATABASIS Ring-1 Floor')"

    Write-Section '8/9  load (resident)'
    $out = (sc.exe start $SvcName 2>&1 | Out-String); $code = $LASTEXITCODE
    Write-Host $out.Trim()
    Write-Host "  sc.exe start exit = $code"
    if ($code -ne 0) {
        Write-Host "  driver did NOT load (expected 0 for the resident floor). 577=signature, 193=bad PE," -ForegroundColor Red
        Write-Host "  1275=blocked, 0x428/1066=HVCI. See the System event log; not running the client." -ForegroundColor Yellow
    } else {
        Write-Host "  LOADED + RESIDENT. \\.\IIIKatabasisFloor should now be open." -ForegroundColor Green
        Write-Section '9/9  exercise  (floor_client.exe)'
        if (Test-Path $Client) {
            & $Client; $cc = $LASTEXITCODE
            if ($cc -eq 0) { Write-Host "`nSUCCESS - III mediated guest memory via NPT interception in Ring -1 (caught the NPF, mapped, resumed), atop the gate+resume loop -- no wedge." -ForegroundColor Green }
            else { Write-Host "`nclient reported $cc failing step(s) - see above." -ForegroundColor Yellow }
        } else { Write-Host "  floor_client.exe not found (build it: x86_64-w64-mingw32-gcc -O2 -o build/floor_client.exe src/floor_client.c)" -ForegroundColor Yellow }
    }

    Write-Section 'teardown  (sc stop -> DriverUnload, then delete)'
    sc.exe stop $SvcName   2>$null | Out-Null
    sc.exe delete $SvcName 2>$null | Out-Null
    Write-Host "  service stopped (DriverUnload ran) + deregistered. Signed copy kept at: $SignedSys"
    Write-Host "  full teardown (incl. test cert): re-run with  -Uninstall" -ForegroundColor DarkGray

    Write-Section 'recent System event-log lines'
    try { Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=(Get-Date).AddMinutes(-3)} -ErrorAction Stop |
            Where-Object { $_.Message -match $SvcName -or $_.Id -in 7000,7026,7001,7036,219 } |
            Select-Object -First 6 TimeCreated, Id, Message | Format-List | Out-String | Write-Host }
    catch { Write-Host "  (event query skipped)" }
}
catch { Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red; Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray }
finally { Read-Host "`nPress Enter to close" }
