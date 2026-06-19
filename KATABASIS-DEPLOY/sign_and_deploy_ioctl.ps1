<#
  KATABASIS Tier-3 R3-invokable IOCTL gate  -  sign + deploy + query + unload (operator-triggered).

  Unlike the Tier-2 selftest (which self-unloaded on an error return), this driver STAYS RESIDENT:
  DriverEntry creates \Device\IIIKatabasisGate + \??\IIIKatabasisGate and returns STATUS_SUCCESS.
  So this script LOADS it, runs the user-mode client (gate_client.exe) which DeviceIoControls the
  four canonical cases and checks the verdicts, then STOPS it (-> DriverUnload deletes the device).

  WHAT THIS DOES (all on YOUR machine, all reversible):
    1. Self-elevates (one UAC).  2. Confirms test-signing on + HVCI off.  3. System Restore point.
    4. Verifies gate_ioctl.sys byte-hash.  5. Reuses/creates the test code-signing cert.
    6. Signs a COPY.  7. Repairs the PE checksum.  8. sc create type=kernel start=DEMAND.
    9. sc start (loads + stays resident).  10. Runs gate_client.exe (R3 -> Ring-0 gate query).
   11. sc stop (DriverUnload) + sc delete (self-cleaning).

  SAFETY: start=demand => never boot-loaded; a worst-case bugcheck is fixed by one normal reboot.
  The driver is resident only between step 9 and step 11 (seconds). RECOVERY: reboot, then
  powershell -ExecutionPolicy Bypass -File sign_and_deploy_ioctl.ps1 -Uninstall

  PROOF OF SUCCESS: gate_client.exe prints "ALL 4 GATE VERDICTS CORRECT" and exits 0 -- i.e. a
  Ring-3 process opened the device and the in-kernel gate returned OK / REJECT_SEAL / REJECT_CAP /
  REJECT_HEXAD correctly. The gate decision is now a standing kernel service queryable from R3.

  RING-1 I0 (this build): the client ALSO runs a READ-ONLY SVM capability probe first -- the kernel
  reads CPUID(0x80000001).ECX[2], EFER, and (only if SVM is present) VM_CR, and reports whether the
  metal can host a Ring -1. No SVM is enabled, no VMRUN -- pure capability ground truth.
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
$GateSys     = Join-Path $ScriptDir 'build\gate_ioctl.sys'
$SignedSys   = Join-Path $ScriptDir 'build\gate_ioctl.signed.sys'
$Client      = Join-Path $ScriptDir 'build\gate_client.exe'
$SvcName     = 'IIIKatabasisGate'
$CertSubject = 'CN=III KATABASIS Test Cert'
$ExpectedHash = '36929B7D195A4BD3D8ADAE100FFE388C680C28E36E62E73758742BCEB67C9272'

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
    Remove-TestCerts
    if (Test-Path $SignedSys) { Remove-Item $SignedSys -Force; Write-Host "  removed $SignedSys" }
    Write-Host "`nUninstall complete. (Reboot if the driver was ever resident.)" -ForegroundColor Green
    Read-Host "Press Enter to close"; return
}

try {
    Write-Section 'KATABASIS Tier-3 IOCTL gate  -  sign + deploy + query'
    Write-Host "Driver  : $GateSys"
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
    try { Checkpoint-Computer -Description 'Pre III-KATABASIS IOCTL gate' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
          Write-Host "  checkpoint created." -ForegroundColor Green }
    catch { Write-Host "  (skipped: $($_.Exception.Message))" -ForegroundColor DarkYellow }

    Write-Section '3/9  verify gate_ioctl.sys byte-hash'
    if (-not (Test-Path $GateSys)) { throw "gate_ioctl.sys not found - run build_gate_ioctl.sh first." }
    $h = (Get-FileHash $GateSys -Algorithm SHA256).Hash
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
    Copy-Item $GateSys $SignedSys -Force
    $sig = Set-AuthenticodeSignature -FilePath $SignedSys -Certificate $cert -HashAlgorithm SHA256
    Write-Host "  signature status: $($sig.Status)"
    if ($sig.Status -ne 'Valid') { throw "signing failed: $($sig.StatusMessage)" }

    Write-Section '6/9  repair PE checksum'
    Write-Host "  checksum set to $(Repair-PeChecksum $SignedSys)  (OK)"

    Write-Section '7/9  register kernel service (start=demand)'
    sc.exe stop $SvcName 2>$null | Out-Null; sc.exe delete $SvcName 2>$null | Out-Null
    Start-Sleep -Milliseconds 300
    Write-Host "  $(sc.exe create $SvcName type= kernel start= demand binPath= "$SignedSys" DisplayName= 'III KATABASIS IOCTL Gate')"

    Write-Section '8/9  load (resident)'
    $out = (sc.exe start $SvcName 2>&1 | Out-String); $code = $LASTEXITCODE
    Write-Host $out.Trim()
    Write-Host "  sc.exe start exit = $code"
    if ($code -ne 0) {
        Write-Host "  driver did NOT load (expected 0 for the resident gate). 577=signature, 193=bad PE," -ForegroundColor Red
        Write-Host "  1275=blocked, 0x428/1066=HVCI. See the System event log; not running the client." -ForegroundColor Yellow
    } else {
        Write-Host "  LOADED + RESIDENT. \\.\IIIKatabasisGate should now be open." -ForegroundColor Green
        Write-Section '9/9  R3 query  (gate_client.exe)'
        if (Test-Path $Client) {
            & $Client; $cc = $LASTEXITCODE
            if ($cc -eq 0) { Write-Host "`nSUCCESS - the Ring-0 gate decision answered all four queries correctly from R3." -ForegroundColor Green }
            else { Write-Host "`nclient reported $cc failing case(s) - see above." -ForegroundColor Yellow }
        } else { Write-Host "  gate_client.exe not found (build it: gcc -O2 -o build/gate_client.exe src/gate_client.c)" -ForegroundColor Yellow }
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
