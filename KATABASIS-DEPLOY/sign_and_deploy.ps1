<#
  KATABASIS Tier-2 resident Gate-decision .sys  -  sign + deploy (test-signing, operator-triggered).

  WHAT THIS DOES (all on YOUR machine, all reversible):
    1. Self-elevates (one UAC prompt).
    2. Confirms test-signing mode is ON (the .sys will not load otherwise).
    3. Creates a System Restore checkpoint (best-effort).
    4. Verifies build\gate.sys matches the exact byte-hash this script was reviewed against.
    5. Creates a self-signed CODE-SIGNING cert, trusts it (LocalMachine Root + TrustedPublisher).
    6. Signs a COPY (build\gate.signed.sys) - leaves the verified gate.sys pristine.
    7. Repairs the PE checksum on the signed file (verified algorithm).
    8. Registers the driver service  type=kernel  start=DEMAND  (never auto/boot-loaded).
    9. Starts it. Our DriverEntry returns STATUS_NOT_SUPPORTED (0xC00000BB) on purpose, so
       Windows UNLOADS the driver the instant it returns - zero resident code, no reboot.
   10. Interprets the result and prints a verdict.
   11. Deletes the service (self-cleaning).

  WHY IT IS SAFE:
    * start=demand  => the driver is NEVER loaded at boot. A worst-case bugcheck is
      recoverable by a single normal reboot; there is NO possibility of a boot loop.
    * error-return  => the driver auto-unloads immediately; nothing stays resident.
    * The image has been disassembled and verified: correct entry, no imports, no CRT,
      a register-preserving witness leaf, balanced prologue/epilogue.

  PROOF OF SUCCESS:
    `sc start` will FAIL with Win32 error 50 ("not supported"). DriverEntry returns
    STATUS_NOT_SUPPORTED (0xC00000BB) ONLY when all four gate verdicts were correct; a wrong
    verdict returns 0xC00000E1..E4 instead, and image load-rejection gives yet different errors
    (193 bad-format, 577 bad-hash, 1275 blocked). So error 50 == the ENTIRE KATABASIS gate
    decision -- cycle-term build in the BSS arena, SHA-256/keccak content-address seal,
    capability verification, hexad admissibility, all four verdicts -- executed correctly in
    Ring 0 without bugcheck, then self-unloaded.

  RECOVERY (if anything ever hangs): just reboot. The driver is demand-start; it will not
  reload. Then run:  powershell -ExecutionPolicy Bypass -File sign_and_deploy.ps1 -Uninstall

  TEARDOWN:  -Uninstall  removes the service, the signed copy, and the test cert from all stores.
#>

[CmdletBinding()]
param([switch]$Uninstall)

$ErrorActionPreference = 'Stop'

# ---- self-elevation (single UAC) -------------------------------------------------
$pr = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $host_exe = (Get-Process -Id $PID).Path
    $a = @('-NoProfile','-ExecutionPolicy','Bypass','-File', ('"{0}"' -f $PSCommandPath))
    if ($Uninstall) { $a += '-Uninstall' }
    Write-Host "Requesting administrator elevation (accept the UAC prompt)..." -ForegroundColor Yellow
    Start-Process -FilePath $host_exe -Verb RunAs -ArgumentList $a
    return
}

# ---- config ----------------------------------------------------------------------
$ScriptDir   = Split-Path -Parent $PSCommandPath
$GateSys     = Join-Path $ScriptDir 'build\gate_resident.sys'
$SignedSys   = Join-Path $ScriptDir 'build\gate_resident.signed.sys'
$SvcName     = 'IIIKatabasisGate'
$CertSubject = 'CN=III KATABASIS Test Cert'
# Known-good byte hash of build\gate_resident.sys (deterministic; the FULL gate-decision
# closure: cycle-term arena + SHA-256/keccak seal + capability + hexad admissibility).
$ExpectedHash = '472152E3C6C21894E3B8DDA83A9B00B1DEB521E93309DFE20AC84A80A262651B'

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
    [IO.File]::WriteAllBytes($Path,$b)
    return ('0x{0:x}' -f $s)
}

function Remove-TestCerts {
    foreach($store in 'Cert:\CurrentUser\My','Cert:\LocalMachine\Root','Cert:\LocalMachine\TrustedPublisher'){
        Get-ChildItem $store -ErrorAction SilentlyContinue | Where-Object { $_.Subject -eq $CertSubject } |
            ForEach-Object { Remove-Item $_.PSPath -Force -ErrorAction SilentlyContinue; Write-Host "  removed cert from $store" }
    }
}

# ---- uninstall mode --------------------------------------------------------------
if ($Uninstall) {
    Write-Section 'UNINSTALL'
    sc.exe stop $SvcName    | Out-Null
    sc.exe delete $SvcName  | Out-Null
    Write-Host "  service '$SvcName' removed (if present)."
    Remove-TestCerts
    if (Test-Path $SignedSys) { Remove-Item $SignedSys -Force; Write-Host "  removed $SignedSys" }
    Write-Host "`nUninstall complete. (Reboot if the driver was ever resident.)" -ForegroundColor Green
    Read-Host "Press Enter to close"; return
}

try {
    Write-Section 'KATABASIS Gate (resident decision) .sys  -  sign + deploy'
    Write-Host "Driver  : $GateSys"
    Write-Host "Service : $SvcName  (type=kernel start=demand)"

    # 1. test-signing must be ON
    Write-Section '1/8  test-signing mode'
    $bcd = (bcdedit /enum '{current}' | Out-String)
    if ($bcd -match '(?im)^\s*testsigning\s+Yes') {
        Write-Host "  testsigning = Yes  (OK)" -ForegroundColor Green
    } else {
        Write-Host "  testsigning is NOT enabled. The signed driver will be REJECTED (error 577)." -ForegroundColor Red
        Write-Host "  Enable with (elevated) then REBOOT:   bcdedit /set testsigning on" -ForegroundColor Yellow
        if ((Read-Host "  Continue anyway? (y/N)") -ne 'y') { Read-Host "Press Enter to close"; return }
    }

    # 1b. HVCI / Memory Integrity rejects non-WHQL drivers even under test-signing.
    Write-Section '1b/8  HVCI / Memory Integrity'
    try {
        $dg = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction Stop
        if ($dg.SecurityServicesRunning -contains 2) {
            Write-Host "  WARNING: HVCI (Memory Integrity) is RUNNING - it rejects self-signed/test drivers" -ForegroundColor Red
            Write-Host "  regardless of test-signing (load fails ~0x428). Turn OFF Core Isolation > Memory" -ForegroundColor Yellow
            Write-Host "  Integrity (Settings > Privacy & security > Windows Security > Device security) + reboot." -ForegroundColor Yellow
            if ((Read-Host "  Continue anyway? (y/N)") -ne 'y') { Read-Host "Press Enter to close"; return }
        } else { Write-Host "  HVCI/Memory Integrity not running (OK)" -ForegroundColor Green }
    } catch { Write-Host "  (HVCI state query skipped: $($_.Exception.Message))" -ForegroundColor DarkYellow }

    # 2. restore point (best-effort)
    Write-Section '2/8  System Restore checkpoint (best-effort)'
    try { Checkpoint-Computer -Description 'Pre III-KATABASIS gate.sys load' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
          Write-Host "  checkpoint created." -ForegroundColor Green }
    catch { Write-Host "  (skipped: $($_.Exception.Message))" -ForegroundColor DarkYellow }

    # 3. verify the exact verified artifact
    Write-Section '3/8  verify gate.sys byte-hash'
    if (-not (Test-Path $GateSys)) { throw "gate.sys not found - run build_gate_sys.sh first." }
    $h = (Get-FileHash $GateSys -Algorithm SHA256).Hash
    Write-Host "  sha256 = $h"
    if ($h -ne $ExpectedHash) {
        Write-Host "  MISMATCH vs reviewed hash $ExpectedHash" -ForegroundColor Red
        if ((Read-Host "  This is not the disassembly-verified build. Continue? (y/N)") -ne 'y') { Read-Host "Press Enter to close"; return }
    } else { Write-Host "  matches the disassembly-verified build  (OK)" -ForegroundColor Green }

    # 4. cert (reuse if present)
    Write-Section '4/8  code-signing certificate'
    $cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -eq $CertSubject } | Select-Object -First 1
    if (-not $cert) {
        $cert = New-SelfSignedCertificate -Subject $CertSubject -Type CodeSigningCert `
                  -CertStoreLocation Cert:\CurrentUser\My -KeyUsage DigitalSignature `
                  -KeyExportPolicy Exportable -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(3)
        Write-Host "  created cert $($cert.Thumbprint)"
    } else { Write-Host "  reusing cert $($cert.Thumbprint)" }
    $cer = Join-Path $env:TEMP 'iii_katabasis_test.cer'
    Export-Certificate -Cert $cert -FilePath $cer | Out-Null
    Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
    Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null
    Remove-Item $cer -Force -ErrorAction SilentlyContinue
    Write-Host "  trusted in LocalMachine Root + TrustedPublisher  (OK)" -ForegroundColor Green

    # 5. sign a COPY
    Write-Section '5/8  sign'
    Copy-Item $GateSys $SignedSys -Force
    $sig = Set-AuthenticodeSignature -FilePath $SignedSys -Certificate $cert -HashAlgorithm SHA256
    Write-Host "  signature status: $($sig.Status)"
    if ($sig.Status -ne 'Valid') { throw "signing failed: $($sig.StatusMessage)" }

    # 6. repair PE checksum on signed file
    Write-Section '6/8  repair PE checksum'
    $newcs = Repair-PeChecksum $SignedSys
    Write-Host "  checksum set to $newcs  (OK)"

    # 7. (re)register the service, demand start
    Write-Section '7/8  register kernel service (start=demand)'
    sc.exe stop $SvcName   2>$null | Out-Null
    sc.exe delete $SvcName 2>$null | Out-Null
    Start-Sleep -Milliseconds 300
    $created = sc.exe create $SvcName type= kernel start= demand binPath= "$SignedSys" DisplayName= "III KATABASIS Gate (resident decision)"
    Write-Host "  $created"

    # 8. start + interpret  (driver returns error -> auto-unloads)
    Write-Section '8/8  load + execute DriverEntry'
    $out = (sc.exe start $SvcName 2>&1 | Out-String)
    $code = $LASTEXITCODE
    Write-Host $out.Trim()
    Write-Host "  sc.exe exit code (Win32) = $code"

    Write-Section 'VERDICT'
    switch ($code) {
        50  { Write-Host "SUCCESS - the FULL KATABASIS gate decision executed in Ring 0." -ForegroundColor Green
              Write-Host "All 4 verdicts correct: OK / REJECT_SEAL / REJECT_CAP / REJECT_HEXAD." -ForegroundColor Green
              Write-Host "The gate ran in-kernel (cycle-term BSS arena, SHA-256/keccak seal, capability" -ForegroundColor Green
              Write-Host "verification, hexad admissibility) without bugcheck, then self-unloaded." -ForegroundColor Green }
        0   { Write-Host "Driver loaded and is RUNNING (returned STATUS_SUCCESS)." -ForegroundColor Green
              Write-Host "NOTE: this build was expected to return an error and self-unload; it is resident now." -ForegroundColor Yellow }
        577 { Write-Host "REJECTED (577 ERROR_INVALID_IMAGE_HASH): signature not trusted / test-signing off+reboot needed." -ForegroundColor Red }
        193 { Write-Host "REJECTED (193 ERROR_BAD_EXE_FORMAT): PE image malformed - DriverEntry did NOT run." -ForegroundColor Red }
        1275{ Write-Host "REJECTED (1275 ERROR_DRIVER_BLOCKED): blocked by policy." -ForegroundColor Red }
        default { Write-Host "Start returned Win32 $code (not 50)." -ForegroundColor Yellow
                  Write-Host "If the driver loaded but a gate verdict was WRONG, DriverEntry returned" -ForegroundColor Yellow
                  Write-Host "0xC00000E1..E4 (the index of the failing case) - see the raw NTSTATUS in" -ForegroundColor Yellow
                  Write-Host "the System event log lines below, then report it back for diagnosis." -ForegroundColor Yellow }
    }

    Write-Section 'recent System event-log lines (driver load)'
    try {
        Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=(Get-Date).AddMinutes(-3)} -ErrorAction Stop |
            Where-Object { $_.Message -match $SvcName -or $_.Id -in 7000,7026,7001,219 } |
            Select-Object -First 6 TimeCreated, Id, ProviderName, Message |
            Format-List | Out-String | Write-Host
    } catch { Write-Host "  (event query skipped)" }

    Write-Section 'cleanup'
    sc.exe stop $SvcName   2>$null | Out-Null
    sc.exe delete $SvcName 2>$null | Out-Null
    Write-Host "  service deregistered (self-cleaning). Signed copy kept at: $SignedSys"
    Write-Host "  full teardown (incl. test cert): re-run with  -Uninstall" -ForegroundColor DarkGray
}
catch {
    Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
}
finally {
    Read-Host "`nPress Enter to close"
}
