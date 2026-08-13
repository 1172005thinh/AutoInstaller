[CmdletBinding()]
param(
    [ValidateRange(1, 10)]
    [int] $MaxIteration = 3,

    [ValidateRange(1, 10)]
    [int] $Iteration = 1,

    [switch] $ResumeApps,

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

function Register-DriverResumeTask {
    param([string] $ScriptPath, [string] $RootPath)

    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $ScriptPath), '-MaxIteration', $MaxIteration, '-Iteration', ($Iteration + 1))
    if ($ResumeApps) { $arguments += '-ResumeApps' }
    if ($ReportAfterCompletion) { $arguments += '-ReportAfterCompletion' }

    $action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument ($arguments -join ' ')
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 2)
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    Write-DriverLog INFO "[DRIVER] status=restart-pending; detail=scheduled iteration $($Iteration + 1) of $MaxIteration from $RootPath"
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

    if ($ResumeApps) {
        $launcher = Join-Path $RootPath 'Auto-installer.exe'
        if (-not (Test-Path -LiteralPath $launcher)) { throw "Continuation launcher not found: $launcher" }
        Write-DriverLog INFO '[DRIVER] status=handoff-apps; detail=starting application installation continuation'
        Start-Process -FilePath $launcher -ArgumentList '--resume-apps' -WorkingDirectory $RootPath
    }
    elseif ($ReportAfterCompletion) {
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

    # Log WU service state to aid post-hoc diagnosis
    $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
    Write-DriverLog INFO "[DRIVER] status=wu-service; detail=Windows Update service status=$($wuService.Status)"

    # Force-restart the Windows Update service to prevent search hangs
    Write-DriverLog INFO "[DRIVER] status=wu-service-restart; detail=restarting wuauserv to ensure a clean state"
    Restart-Service -Name wuauserv -Force -ErrorAction SilentlyContinue

    if (-not (Test-InternetConnection)) {
        Complete-DriverInstallation -RootPath $softwareRoot -Status 'skipped-no-internet' -Detail 'no Internet connection was available for Windows Update'
        exit 0
    }

    # The Windows Update Agent COM API is used to select only driver-class updates.
    # The search is retried up to 3 times with a 60-second wait between attempts
    # because WU may still be initializing on a freshly installed system.
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()

    $searchResult = $null
    $maxSearchAttempts = 3
    for ($searchAttempt = 1; $searchAttempt -le $maxSearchAttempts; $searchAttempt++) {
        try {
            Write-DriverLog INFO "[DRIVER] status=searching; detail=attempt $searchAttempt of $maxSearchAttempts"
            $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Driver'")
            Write-DriverLog INFO "[DRIVER] status=search-complete; detail=$($searchResult.Updates.Count) driver update(s) found"
            break
        }
        catch {
            Write-DriverLog WARN "[DRIVER] status=search-error; detail=attempt $searchAttempt failed: $($_.Exception.Message)"
            if ($searchAttempt -lt $maxSearchAttempts) {
                Write-DriverLog INFO "[DRIVER] status=search-retry; detail=waiting 60 seconds before next attempt"
                Start-Sleep -Seconds 60
            }
            else {
                throw
            }
        }
    }

    if ($searchResult.Updates.Count -eq 0) {
        Complete-DriverInstallation -RootPath $softwareRoot -Status 'no-updates' -Detail 'Windows Update did not offer any driver updates'
        exit 0
    }

    $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
    foreach ($update in $searchResult.Updates) {
        if (-not $update.EulaAccepted) { $update.AcceptEula() }
        [void] $updatesToInstall.Add($update)
        Write-DriverLog INFO ("[DRIVER] status=selected; detail={0}" -f $update.Title)
    }

    $installer = $updateSession.CreateUpdateInstaller()
    $installer.Updates = $updatesToInstall
    $installationResult = $installer.Install()
    Write-DriverLog INFO ("[DRIVER] status=install-result; detail=result_code={0}; reboot_required={1}" -f $installationResult.ResultCode, $installationResult.RebootRequired)

    if ($installationResult.RebootRequired) {
        if ($Iteration -ge $MaxIteration) {
            Write-DriverLog WARN '[DRIVER] status=reboot-required; detail=iteration limit reached; reboot manually to complete driver installation'
            Complete-DriverInstallation -RootPath $softwareRoot -Status 'reboot-required' -Detail 'iteration limit reached; a manual reboot is required to complete driver installation'
            exit 0
        }

        Register-DriverResumeTask -ScriptPath $PSCommandPath -RootPath $softwareRoot
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
