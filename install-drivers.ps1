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

function Set-WindowsUpdatePolicy {
    # Configure WU to include drivers and security patches, exclude feature upgrades.
    # Wrapped in try/catch so that registry access errors (e.g. restricted policy paths
    # in some VM environments) are logged as warnings rather than crashing the script.
    try {
        $wuPolicyPath     = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
        $auPolicyPath     = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
        $targetPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsUpdate'

        New-Item -Path $wuPolicyPath     -Force -ErrorAction SilentlyContinue | Out-Null
        New-Item -Path $auPolicyPath     -Force -ErrorAction SilentlyContinue | Out-Null
        New-Item -Path $targetPolicyPath -Force -ErrorAction SilentlyContinue | Out-Null

        # Include driver updates in quality/Windows Update scans (overrides OEM suppression)
        Set-ItemProperty -Path $wuPolicyPath -Name 'ExcludeWUDriversInQualityUpdate' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        # Keep auto-update enabled (WU will be triggered manually by the script)
        Set-ItemProperty -Path $auPolicyPath -Name 'NoAutoUpdate' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        # Block Windows version upgrade offers entirely
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

function Test-InternetConnection {
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri 'http://www.msftconnecttest.com/connecttest.txt' -TimeoutSec 15 -ErrorAction Stop
        return $response.StatusCode -ge 200 -and $response.StatusCode -lt 400
    }
    catch {
        return $false
    }
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

try {
    if (-not (Test-Administrator)) {
        Write-DriverLog ERROR '[DRIVER] status=failed; detail=administrator privileges are required'
        exit 5
    }

    $softwareRoot = Get-SoftwareRoot
    Write-DriverLog INFO "[DRIVER] status=started; detail=iteration $Iteration of $MaxIteration; source=$softwareRoot"

    # Configure Windows Update policy before anything else (idempotent — safe to re-apply on each resume)
    Set-WindowsUpdatePolicy

    # Force-restart WU services to pick up the new policy and ensure a clean scan state
    Write-DriverLog INFO '[DRIVER] status=wu-service-restart; detail=restarting wuauserv and UsoSvc'
    Stop-Service -Name UsoSvc   -Force -ErrorAction SilentlyContinue
    Restart-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Start-Service  -Name UsoSvc          -ErrorAction SilentlyContinue

    # Check internet connectivity; skip driver installation gracefully if offline
    if (-not (Test-InternetConnection)) {
        Complete-DriverInstallation -RootPath $softwareRoot -Status 'skipped-no-internet' -Detail 'no Internet connection available for Windows Update'
        exit 0
    }

    # Use the Windows Update Agent COM API.
    # Search includes drivers (Type='Driver') and software/security updates (Type='Software')
    # but excludes hidden items (user-dismissed updates) to avoid re-installing unwanted items.
    $updateSession  = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()

    $searchResult       = $null
    $maxSearchAttempts  = 3
    for ($searchAttempt = 1; $searchAttempt -le $maxSearchAttempts; $searchAttempt++) {
        try {
            Write-DriverLog INFO "[DRIVER] status=searching; detail=attempt $searchAttempt of $maxSearchAttempts"
            $searchResult = $updateSearcher.Search("IsInstalled=0 and IsHidden=0 and (Type='Driver' or Type='Software')")
            Write-DriverLog INFO "[DRIVER] status=search-complete; detail=$($searchResult.Updates.Count) update(s) found"
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
        Write-DriverLog INFO "[DRIVER] status=queued; detail=$line"
        Write-Host $line -ForegroundColor White
        $idx++
    }
    Write-Host ''

    # Install all queued updates
    $installer             = $updateSession.CreateUpdateInstaller()
    $installer.Updates     = $updatesToInstall
    $installationResult    = $installer.Install()
    Write-DriverLog INFO ("[DRIVER] status=install-result; detail=result_code={0}; reboot_required={1}" -f $installationResult.ResultCode, $installationResult.RebootRequired)

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

    Complete-DriverInstallation -RootPath $softwareRoot
    exit 0
}
catch {
    Write-DriverLog ERROR ("[DRIVER] status=failed; detail={0}" -f $_.Exception.Message)
    exit 1
}
