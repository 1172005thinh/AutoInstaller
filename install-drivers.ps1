[CmdletBinding()]
param(
    [ValidateRange(1, 10)]
    [int] $MaxIteration = 3,

    [ValidateRange(1, 10)]
    [int] $Iteration = 1,

    [switch] $ReportAfterCompletion
)

$ErrorActionPreference = 'Stop'
$markerFile = 'aea541d7f9574587656dc5125116e548.md5'
$logDirectory = 'C:\Auto-installer'
$logPath = Join-Path $logDirectory 'install-drivers.log'
$taskName = 'AutoInstaller-Drivers'

function Write-DriverLog {
    param([ValidateSet('INFO', 'ERROR', 'WARN')] [string] $Level, [string] $Message)

    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    $line = '[{0:yyyy-MM-dd HH:mm:ss}] [{1}] {2}' -f (Get-Date), $Level, $Message
    Add-Content -LiteralPath $logPath -Value $line -Encoding utf8
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    if ($identity.IsSystem) { return $true }

    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-SoftwareRoot {
    if (Test-Path -LiteralPath (Join-Path $PSScriptRoot $markerFile)) {
        return $PSScriptRoot
    }

    foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        $candidate = Join-Path $drive.Root $markerFile
        if (Test-Path -LiteralPath $candidate) {
            return $drive.Root.TrimEnd('\')
        }
    }

    throw "Could not locate the software partition marker '$markerFile'."
}

function Test-InternetConnection {
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri 'http://www.msftconnecttest.com/connecttest.txt' -TimeoutSec 15 -ErrorAction Stop
        return $response.StatusCode -ge 200 -and $response.StatusCode -lt 400
    }
    catch {
        return $false
    }
}

function Find-SdioExecutable {
    param([string] $RootPath)

    $searchPaths = @(
        (Join-Path $RootPath 'Drivers\SDIO'),
        (Join-Path $RootPath 'Drivers'),
        (Join-Path $RootPath 'SDIO'),
        $RootPath
    )

    $is64 = [Environment]::Is64BitOperatingSystem
    $exePatterns = if ($is64) {
        @(
            'SDIO_x64_*.exe',
            'SDIO_x64.exe',
            'SDIO*x64*.exe',
            'SDI_x64_*.exe',
            'SDI_x64.exe',
            'SDI*x64*.exe',
            'SDIO_*.exe',
            'SDIO.exe',
            'SDI_*.exe',
            'SDI.exe'
        )
    } else {
        @(
            'SDIO_*.exe',
            'SDIO.exe',
            'SDI_*.exe',
            'SDI.exe'
        )
    }

    foreach ($dir in $searchPaths) {
        if (Test-Path -LiteralPath $dir) {
            foreach ($pattern in $exePatterns) {
                $matched = Get-ChildItem -Path $dir -Filter $pattern -File -ErrorAction SilentlyContinue |
                           Where-Object { $_.Name -notmatch '-XP' } |
                           Select-Object -First 1
                if ($matched) {
                    return $matched.FullName
                }
            }
        }
    }

    return $null
}

function Invoke-SdioDriverInstallation {
    param(
        [string] $SdioPath,
        [string] $LogDir = 'C:\Auto-installer\sdio_logs'
    )

    New-Item -ItemType Directory -Path $LogDir -Force -ErrorAction SilentlyContinue | Out-Null
    $sdioDir = Split-Path -Path $SdioPath -Parent

    Write-DriverLog INFO "[DRIVER] source=SDIO; status=starting; detail=launching SDIO tool from $SdioPath"
    Write-Host "`n[DRIVER] Starting Snappy Driver Installer Origin (SDIO)..." -ForegroundColor Cyan

    # SDIO command line switches:
    # -autoinstall : automatically match and install missing hardware drivers
    # -autoupdate  : update outdated drivers to better matches
    # -autoclose   : terminate SDIO upon completion
    # -nosnapshot  : skip system restore point creation for speed and unattended stability
    # -license     : accept SDIO license agreement
    # -logdir      : specify destination directory for SDIO logs
    $sdioArgs = @(
        '-autoinstall',
        '-autoupdate',
        '-autoclose',
        '-nosnapshot',
        '-license',
        ('-logdir:"{0}"' -f $LogDir)
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $proc = Start-Process -FilePath $SdioPath -ArgumentList ($sdioArgs -join ' ') -WorkingDirectory $sdioDir -PassThru -Wait
    $sw.Stop()
    $exitCode = $proc.ExitCode

    Write-DriverLog INFO ("[DRIVER] source=SDIO; status=finished; detail=exit_code={0}; elapsed_ms={1}" -f $exitCode, $sw.ElapsedMilliseconds)

    # Parse SDIO log files in $LogDir to extract individual driver items installed/failed
    $installedDrivers = [System.Collections.Generic.List[pscustomobject]]::new()
    $sdioLogs = Get-ChildItem -Path $LogDir -Filter '*.log' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    foreach ($logFile in $sdioLogs) {
        $lines = Get-Content -LiteralPath $logFile.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            if ($line -match 'Install:\s*(?<driver>.*?)\s*\[(?<status>OK|SUCCESS|INSTALLED|DONE)\]' -or
                $line -match 'Installing\s+(?<driver>.*?)\s*\.\.\.\s*(?<status>OK|SUCCESS|DONE)' -or
                $line -match '(?<driver>DP_.*?)\s*->\s*(?<status>Installed|Success)') {
                $driverName = $Matches.driver.Trim()
                $driverStatus = $Matches.status.Trim()
                $installedDrivers.Add([pscustomobject]@{
                    Name   = $driverName
                    Status = 'installed'
                    Detail = "Installed via SDIO ($driverStatus)"
                })
                Write-DriverLog INFO ("[DRIVER] source=SDIO; name={0}; status=installed; detail=Installed via SDIO ({1})" -f $driverName, $driverStatus)
            }
            elseif ($line -match 'Install:\s*(?<driver>.*?)\s*\[(?<status>FAIL|ERROR|FAILED)\]') {
                $driverName = $Matches.driver.Trim()
                $installedDrivers.Add([pscustomobject]@{
                    Name   = $driverName
                    Status = 'failed'
                    Detail = "SDIO installation failed ($($Matches.status))"
                })
                Write-DriverLog WARN ("[DRIVER] source=SDIO; name={0}; status=failed; detail=SDIO failed ({1})" -f $driverName, $Matches.status)
            }
        }
    }

    $success = ($exitCode -eq 0)
    return @{
        Success          = $success
        ExitCode         = $exitCode
        InstalledDrivers = $installedDrivers
        LogDirectory     = $LogDir
    }
}

function Set-WindowsUpdatePolicy {
    # Configure WU to include drivers and security patches, exclude feature upgrades.
    try {
        $wuPolicyPath     = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
        $auPolicyPath     = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
        $targetPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsUpdate'

        New-Item -Path $wuPolicyPath     -Force -ErrorAction SilentlyContinue | Out-Null
        New-Item -Path $auPolicyPath     -Force -ErrorAction SilentlyContinue | Out-Null
        New-Item -Path $targetPolicyPath -Force -ErrorAction SilentlyContinue | Out-Null

        # Include driver updates in quality/Windows Update scans
        Set-ItemProperty -Path $wuPolicyPath -Name 'ExcludeWUDriversInQualityUpdate' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        # Keep auto-update enabled
        Set-ItemProperty -Path $auPolicyPath -Name 'NoAutoUpdate' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        # Block Windows version upgrade offers
        Set-ItemProperty -Path $targetPolicyPath -Name 'DisableOSUpgrade'     -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $targetPolicyPath -Name 'TargetReleaseVersion' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        Write-DriverLog INFO '[DRIVER] status=policy-set; detail=WU configured to include drivers+security, exclude feature upgrades'
    }
    catch {
        Write-DriverLog WARN "[DRIVER] status=policy-warn; detail=could not fully apply WU policy (non-fatal): $($_.Exception.Message)"
    }
}

function Register-DriverResumeTask {
    param([string] $ScriptPath)

    $arguments = @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $ScriptPath),
        '-MaxIteration', $MaxIteration,
        '-Iteration', ($Iteration + 1)
    )
    if ($ReportAfterCompletion) { $arguments += '-ReportAfterCompletion' }

    $action    = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument ($arguments -join ' ')
    $trigger   = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    $settings  = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 2)
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    Write-DriverLog INFO "[DRIVER] status=restart-pending; detail=scheduled iteration $($Iteration + 1) of $MaxIteration"
}

function Complete-DriverInstallation {
    param(
        [string] $RootPath,
        [string] $Status = 'completed',
        [string] $Detail = 'driver update processing completed'
    )

    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-DriverLog INFO ("[DRIVER] status={0}; detail={1}" -f $Status, $Detail)

    if ($ReportAfterCompletion) {
        $reportLauncher = Join-Path $RootPath 'report.exe'
        if (Test-Path -LiteralPath $reportLauncher) {
            Write-DriverLog INFO '[DRIVER] status=handoff-report; detail=starting report generation'
            Start-Process -FilePath $reportLauncher -WorkingDirectory $RootPath -Wait
        }
        else {
            Write-DriverLog WARN "[DRIVER] status=report-missing; detail=report.exe was not found at $reportLauncher"
        }
    }
}

function Apply-WindowsUpdatePolicyAndServices {
    # Configure Windows Update policy to include drivers+security and block feature upgrades
    Set-WindowsUpdatePolicy

    # Force-restart WU services to pick up the new policy and ensure clean service state
    Write-DriverLog INFO '[DRIVER] status=wu-service-restart; detail=restarting wuauserv and UsoSvc to apply policy'
    Stop-Service -Name UsoSvc   -Force -ErrorAction SilentlyContinue
    Restart-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Start-Service  -Name UsoSvc          -ErrorAction SilentlyContinue
}

try {
    if (-not (Test-Administrator)) {
        Write-DriverLog ERROR '[DRIVER] status=failed; detail=administrator privileges are required'
        exit 5
    }

    $softwareRoot = Get-SoftwareRoot
    Write-DriverLog INFO "[DRIVER] status=started; detail=iteration $Iteration of $MaxIteration; source=$softwareRoot"

    # --------------------------------------------------------------------------
    # 1. Mandatory Internet Check
    # --------------------------------------------------------------------------
    Write-DriverLog INFO '[DRIVER] status=checking-internet; detail=testing connection to Microsoft network endpoint'
    if (-not (Test-InternetConnection)) {
        Write-DriverLog WARN '[DRIVER] status=skipped-no-internet; detail=no Internet connection available. Driver installation requires active Internet.'
        Complete-DriverInstallation -RootPath $softwareRoot -Status 'skipped-no-internet' -Detail 'no Internet connection available. Driver installation requires active Internet connection.'
        exit 0
    }
    Write-DriverLog INFO '[DRIVER] status=internet-online; detail=Internet connection active and verified'

    # --------------------------------------------------------------------------
    # 2. SDIO Tool Execution (Primary Driver Engine)
    # --------------------------------------------------------------------------
    $sdioExe = Find-SdioExecutable -RootPath $softwareRoot
    if ($sdioExe) {
        Write-DriverLog INFO "[DRIVER] status=sdio-found; detail=found SDIO tool at $sdioExe"
        $sdioResult = Invoke-SdioDriverInstallation -SdioPath $sdioExe

        if ($sdioResult.Success) {
            $installedCount = $sdioResult.InstalledDrivers.Count
            $detailMsg = if ($installedCount -gt 0) { 
                "SDIO successfully matched and installed $installedCount hardware driver(s)" 
            } else { 
                "SDIO completed clean (all hardware drivers up to date)" 
            }
            Write-DriverLog INFO "[DRIVER] status=completed-sdio; detail=$detailMsg"

            # Apply Windows Update policies without triggering WU search/install command
            Apply-WindowsUpdatePolicyAndServices

            Complete-DriverInstallation -RootPath $softwareRoot -Status 'completed-sdio' -Detail "$detailMsg (WU policy applied)"
            exit 0
        } else {
            Write-DriverLog WARN "[DRIVER] status=sdio-fallback; detail=SDIO exited with code $($sdioResult.ExitCode). Proceeding to Windows Update fallback."
        }
    } else {
        Write-DriverLog INFO '[DRIVER] status=sdio-not-found; detail=SDIO tool was not found on Software partition. Proceeding with Windows Update.'
    }

    # --------------------------------------------------------------------------
    # 3. Windows Update Fallback Routine (Policy + Trigger Update Command)
    # --------------------------------------------------------------------------
    Apply-WindowsUpdatePolicyAndServices

    # Use the Windows Update Agent COM API.
    # Search includes drivers (Type='Driver') and software/security updates (Type='Software')
    # but excludes hidden items (user-dismissed updates) to avoid re-installing unwanted items.
    $updateSession  = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()

    $searchResult       = $null
    $maxSearchAttempts  = 3
    for ($searchAttempt = 1; $searchAttempt -le $maxSearchAttempts; $searchAttempt++) {
        try {
            Write-DriverLog INFO "[DRIVER] status=searching; detail=Windows Update scan attempt $searchAttempt of $maxSearchAttempts"
            $searchResult = $updateSearcher.Search("IsInstalled=0 and IsHidden=0 and (Type='Driver' or Type='Software')")
            Write-DriverLog INFO "[DRIVER] status=search-complete; detail=$($searchResult.Updates.Count) update(s) found via Windows Update"
            break
        }
        catch {
            Write-DriverLog WARN "[DRIVER] status=search-error; detail=attempt $searchAttempt failed: $($_.Exception.Message)"
            if ($searchAttempt -lt $maxSearchAttempts) {
                Write-DriverLog INFO '[DRIVER] status=search-retry; detail=waiting 60 seconds before next attempt'
                Start-Sleep -Seconds 60
            }
            else {
                throw
            }
        }
    }

    # On iteration > 1 (post-reboot resume), 0 results means all updates were applied — this is success.
    if ($searchResult.Updates.Count -eq 0) {
        $status = if ($Iteration -gt 1) { 'completed-clean' } else { 'no-updates' }
        $detail = if ($Iteration -gt 1) { 'all updates applied in previous iterations' } else { 'Windows Update did not offer any driver or security updates' }
        Complete-DriverInstallation -RootPath $softwareRoot -Status $status -Detail $detail
        exit 0
    }

    # List all queued updates to the log before installing
    Write-DriverLog INFO "[DRIVER] status=update-list; detail=$($searchResult.Updates.Count) update(s) queued for installation:"
    Write-Host "`n[DRIVER] Queued $($searchResult.Updates.Count) update(s):" -ForegroundColor Cyan
    $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
    $idx = 1
    foreach ($update in $searchResult.Updates) {
        if (-not $update.EulaAccepted) { $update.AcceptEula() }
        [void] $updatesToInstall.Add($update)
        $line = "  [$idx] $($update.Title)  (Type=$($update.Type))"
        Write-DriverLog INFO "[DRIVER] source=WindowsUpdate; name=$($update.Title); type=$($update.Type); status=queued; detail=$line"
        Write-Host $line -ForegroundColor White
        $idx++
    }
    Write-Host ''

    # Install all queued updates
    $installer             = $updateSession.CreateUpdateInstaller()
    $installer.Updates     = $updatesToInstall
    $installationResult    = $installer.Install()
    Write-DriverLog INFO ("[DRIVER] status=install-result; detail=result_code={0}; reboot_required={1}" -f $installationResult.ResultCode, $installationResult.RebootRequired)

    # Record granular per-update result
    for ($i = 0; $i -lt $updatesToInstall.Count; $i++) {
        $u = $updatesToInstall.Item($i)
        $res = $installationResult.GetUpdateResult($i)
        $uStatus = switch ($res.ResultCode) {
            2 { 'installed' }
            default { 'failed' }
        }
        Write-DriverLog INFO ("[DRIVER] source=WindowsUpdate; name={0}; type={1}; status={2}; detail=ResultCode={3}" -f $u.Title, $u.Type, $uStatus, $res.ResultCode)
    }

    if ($installationResult.RebootRequired) {
        if ($Iteration -ge $MaxIteration) {
            Write-DriverLog WARN '[DRIVER] status=reboot-required; detail=iteration limit reached; reboot manually to complete'
            Complete-DriverInstallation -RootPath $softwareRoot -Status 'reboot-required' -Detail 'iteration limit reached; a manual reboot is required to complete driver installation'
            exit 0
        }

        Register-DriverResumeTask -ScriptPath $PSCommandPath
        Write-Host '[DRIVER] Restarting computer to complete driver installation...' -ForegroundColor Yellow
        Restart-Computer -Force
        exit 0
    }

    Complete-DriverInstallation -RootPath $softwareRoot -Status 'completed-windows-update' -Detail "Successfully installed $($updatesToInstall.Count) update(s) via Windows Update"
    exit 0
}
catch {
    Write-DriverLog ERROR ("[DRIVER] status=failed; detail={0}" -f $_.Exception.Message)
    exit 1
}
