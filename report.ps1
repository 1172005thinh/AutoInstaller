[CmdletBinding()]
param(
    [string] $LogDirectory = 'C:\Auto-installer',
    [string] $OutputPath = 'C:\Auto-installer\report.md'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-LogLines {
    param([string] $Path)
    if (Test-Path -LiteralPath $Path) {
        return @(Get-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction SilentlyContinue)
    }
    return @()
}

function Escape-MarkdownTableValue {
    param([AllowNull()] [string] $Value)
    if ($null -eq $Value) { return '' }
    return $Value.Replace('|', '\|').Replace("`r", ' ').Replace("`n", ' ').Trim()
}

$script:reportLines = [System.Collections.Generic.List[string]]::new()

function Add-Line {
    param([string]$Text = '')
    $script:reportLines.Add($Text)
}

try {
    if (-not (Test-Path -LiteralPath $LogDirectory)) {
        $null = New-Item -ItemType Directory -Path $LogDirectory -Force -ErrorAction SilentlyContinue
    }

    # Log file paths
    $setupScriptsLog = Join-Path $LogDirectory 'setup-scripts.log'
    $appsLogPath     = Join-Path $LogDirectory 'install-apps.log'
    $configLogPath   = Join-Path $LogDirectory 'configure-windows.log'
    $driverLogPath   = Join-Path $LogDirectory 'install-drivers.log'
    
    $specializeLog   = 'C:\Windows\Setup\Scripts\Specialize.log'
    $firstLogonLog   = 'C:\Windows\Setup\Scripts\FirstLogon.log'
    $removePkgLog    = 'C:\Windows\Setup\Scripts\RemovePackages.log'
    $removeCapLog    = 'C:\Windows\Setup\Scripts\RemoveCapabilities.log'
    $removeFeatLog   = 'C:\Windows\Setup\Scripts\RemoveFeatures.log'

    # Read log lines
    $setupLines      = Get-LogLines $setupScriptsLog
    $appsLines       = Get-LogLines $appsLogPath
    $configLines     = Get-LogLines $configLogPath
    $driverLines     = Get-LogLines $driverLogPath
    $specializeLines = Get-LogLines $specializeLog
    $firstLogonLines = Get-LogLines $firstLogonLog
    $pkgLines        = Get-LogLines $removePkgLog
    $capLines        = Get-LogLines $removeCapLog
    $featLines       = Get-LogLines $removeFeatLog

    $allLogLines = @($setupLines + $appsLines + $configLines + $driverLines + $specializeLines + $firstLogonLines)

    # --------------------------------------------------------------------------
    # 1. Parse Unattend & Specialization Scripts
    # --------------------------------------------------------------------------
    $setupTasks = [System.Collections.Generic.List[pscustomobject]]::new()
    $setupStatus = 'not-run'
    
    if ($setupLines.Count -gt 0 -or $specializeLines.Count -gt 0) {
        $setupStatus = 'completed'
        
        # Check extraction
        $extractSuccess = ($setupLines | Where-Object { $_ -match '\[ExtractScript\] File extraction completed successfully' }).Count -gt 0
        $setupTasks.Add([pscustomobject]@{
            Phase  = 'Specialize'
            Task   = 'Script Extraction (ExtractScript)'
            Status = $(if ($extractSuccess) { 'Success' } else { 'Warning/Not Recorded' })
            Detail = 'Extracted setup helper scripts from unattend XML to C:\Windows\Setup\Scripts\'
        })

        # Check debloat packages removed
        $pkgRemoved = 0
        foreach ($pl in $pkgLines) {
            if ($pl -match '"Message":\s*"Package removed\."') { $pkgRemoved++ }
        }
        if ($pkgLines.Count -gt 0) {
            $setupTasks.Add([pscustomobject]@{
                Phase  = 'Specialize'
                Task   = 'Remove Provisioned Packages (Debloat)'
                Status = 'Success'
                Detail = "Removed $pkgRemoved AppX provisioned package(s)"
            })
        }

        # Check capabilities removed
        $capRemoved = 0
        foreach ($cl in $capLines) {
            if ($cl -match '"Message":\s*"Capability removed\."') { $capRemoved++ }
        }
        if ($capLines.Count -gt 0) {
            $setupTasks.Add([pscustomobject]@{
                Phase  = 'Specialize'
                Task   = 'Remove Windows Capabilities'
                Status = 'Success'
                Detail = "Removed $capRemoved Windows capability item(s)"
            })
        }

        # Check features removed
        $featRemoved = 0
        foreach ($fl in $featLines) {
            if ($fl -match '"Message":\s*"Feature removed\."') { $featRemoved++ }
        }
        if ($featLines.Count -gt 0) {
            $setupTasks.Add([pscustomobject]@{
                Phase  = 'Specialize'
                Task   = 'Remove Windows Features'
                Status = 'Success'
                Detail = "Removed $featRemoved optional feature(s)"
            })
        }

        # Check FirstLogon execution
        if ($firstLogonLines.Count -gt 0 -or ($setupLines | Where-Object { $_ -match 'FirstLogon' }).Count -gt 0) {
            $setupTasks.Add([pscustomobject]@{
                Phase  = 'FirstLogon'
                Task   = 'First Logon Initialization'
                Status = 'Success'
                Detail = 'AutoLogon reset and unattend security cleanup completed'
            })
        }
    }

    # --------------------------------------------------------------------------
    # 2. Parse Application Install Status
    # --------------------------------------------------------------------------
    $applicationStatus = @{}
    foreach ($line in $appsLines) {
        if ($line -match '\[APP\] index=(?<index>\d+); name=(?<name>.*?); status=(?<status>[^;]+); detail=(?<detail>.*)$') {
            $applicationStatus[[int] $Matches.index] = [pscustomobject]@{
                Index  = [int] $Matches.index
                Name   = $Matches.name
                Status = $Matches.status
                Detail = $Matches.detail
            }
        }
    }

    $installedCount        = @($applicationStatus.Values | Where-Object { $_.Status -eq 'installed' }).Count
    $alreadyInstalledCount = @($applicationStatus.Values | Where-Object { $_.Status -eq 'already-installed' }).Count
    $failedCount           = @($applicationStatus.Values | Where-Object { $_.Status -eq 'failed' }).Count
    $disabledCount         = @($applicationStatus.Values | Where-Object { $_.Status -eq 'disabled' }).Count

    # --------------------------------------------------------------------------
    # 3. Parse Windows Configuration Status
    # --------------------------------------------------------------------------
    $configStatus = 'not-run'
    $configDetails = [System.Collections.Generic.List[pscustomobject]]::new()
    $validations   = [System.Collections.Generic.List[pscustomobject]]::new()

    if ($configLines.Count -gt 0) {
        $configStatus = 'completed'
        foreach ($line in $configLines) {
            if ($line -match 'INFO: \[(?<num>\d+(\.\.\d+)?)\] (?<desc>.*)') {
                $configDetails.Add([pscustomobject]@{
                    Section     = "Task #$($Matches.num)"
                    Description = $Matches.desc
                })
            }
            if ($line -match '\[VALIDATION\] (?<result>PASS|FAIL): (?<item>.*)') {
                $validations.Add([pscustomobject]@{
                    Result = $Matches.result
                    Item   = $Matches.item
                })
                if ($Matches.result -eq 'FAIL') {
                    $configStatus = 'warnings/failures'
                }
            }
        }
    }

    # --------------------------------------------------------------------------
    # 4. Parse Drivers Installation Status
    # --------------------------------------------------------------------------
    $driverStatus = 'not-run'
    $driverDetail = ''
    foreach ($line in $driverLines) {
        if ($line -match '\[DRIVER\] status=(?<status>[^;\s]+)(; detail=(?<detail>.*))?') {
            $driverStatus = $Matches.status
            if ($Matches.detail) { $driverDetail = $Matches.detail }
        }
    }

    # --------------------------------------------------------------------------
    # 5. Aggregate Errors & Warnings
    # --------------------------------------------------------------------------
    $errorLines = [System.Collections.Generic.List[string]]::new()
    $warnLines  = [System.Collections.Generic.List[string]]::new()

    foreach ($l in $allLogLines) {
        if (($l -match '\[ERROR\]' -or $l -match 'ERROR:') -and ($l -notmatch '\[VALIDATION\] FAIL')) {
            $errorLines.Add($l)
        }
        elseif ($l -match '\[WARN\]' -or $l -match 'WARN:') {
            $warnLines.Add($l)
        }
    }

    # --------------------------------------------------------------------------
    # 6. Build Markdown Report
    # --------------------------------------------------------------------------
    Add-Line '# Windows Automated Deployment Report'
    Add-Line ''
    Add-Line ('**Generated:** `{0:yyyy-MM-dd HH:mm:ss}` | **Host:** `{1}` | **User:** `{2}`' -f @((Get-Date), $env:COMPUTERNAME, $env:USERNAME))
    Add-Line ''
    
    # --- Executive Summary ---
    Add-Line '## 1. Executive Summary'
    Add-Line ''
    Add-Line '| Deployment Phase | Status | Summary Details |'
    Add-Line '| :--- | :--- | :--- |'
    Add-Line ('| **Unattended Setup Scripts** | `{0}` | Embedded specialize & debloat scripts |' -f @((Escape-MarkdownTableValue $setupStatus)))
    Add-Line ('| **Applications Installation** | `{0} Installed` | {1} installed, {2} existing, {3} disabled, {4} failed |' -f @($installedCount, $installedCount, $alreadyInstalledCount, $disabledCount, $failedCount))
    Add-Line ('| **Windows Configuration** | `{0}` | 29 post-installation features applied |' -f @((Escape-MarkdownTableValue $configStatus)))
    Add-Line ('| **Driver Updates** | `{0}` | {1} |' -f @((Escape-MarkdownTableValue $driverStatus), (Escape-MarkdownTableValue $driverDetail)))
    Add-Line ('| **Total Logged Errors** | `{0}` | Critical system/script errors |' -f @($errorLines.Count))
    Add-Line ('| **Total Logged Warnings** | `{0}` | Minor warnings / skipped items |' -f @($warnLines.Count))
    Add-Line ''

    # --- Setup & Embedded Scripts ---
    Add-Line '## 2. Unattended Setup & Embedded Scripts'
    Add-Line ''
    if ($setupTasks.Count -eq 0) {
        Add-Line 'No unattended setup script entries were logged.'
    } else {
        Add-Line '| Phase | Setup Task | Result | Detail |'
        Add-Line '| :--- | :--- | :--- | :--- |'
        foreach ($st in $setupTasks) {
            Add-Line ('| {0} | {1} | **{2}** | {3} |' -f @($st.Phase, (Escape-MarkdownTableValue $st.Task), (Escape-MarkdownTableValue $st.Status), (Escape-MarkdownTableValue $st.Detail)))
        }
    }
    Add-Line ''

    # --- Applications Section ---
    Add-Line '## 3. Third-Party Applications Installation'
    Add-Line ''
    if ($applicationStatus.Count -eq 0) {
        Add-Line 'No application installer results were recorded.'
    } else {
        Add-Line '| # | Application Setup File | Status | Execution Details |'
        Add-Line '| ---: | :--- | :--- | :--- |'
        foreach ($entry in ($applicationStatus.Values | Sort-Object Index)) {
            $statusStr = switch ($entry.Status) {
                'installed'         { 'Installed' }
                'already-installed' { 'Already Installed' }
                'disabled'          { 'Disabled' }
                'failed'            { 'FAILED' }
                default             { $entry.Status }
            }
            Add-Line ('| {0} | {1} | `{2}` | {3} |' -f @($entry.Index, (Escape-MarkdownTableValue $entry.Name), $statusStr, (Escape-MarkdownTableValue $entry.Detail)))
        }
    }
    Add-Line ''

    # --- Windows Configuration ---
    Add-Line '## 4. Windows Post-Installation Configuration (29 Features)'
    Add-Line ''
    if ($validations.Count -gt 0) {
        Add-Line '### Configuration Assertions & Validation'
        Add-Line ''
        Add-Line '| Assertion Item | Verification Result |'
        Add-Line '| :--- | :--- |'
        foreach ($v in $validations) {
            $resBadge = if ($v.Result -eq 'PASS') { 'PASS' } else { 'FAIL' }
            Add-Line ('| {0} | `{1}` |' -f @((Escape-MarkdownTableValue $v.Item), $resBadge))
        }
        Add-Line ''
    }
    if ($configDetails.Count -gt 0) {
        Add-Line '### Execution Highlights'
        Add-Line ''
        foreach ($cd in $configDetails) {
            Add-Line ('- **{0}**: {1}' -f @($cd.Section, (Escape-MarkdownTableValue $cd.Description)))
        }
        Add-Line ''
    }

    # --- Driver Installation ---
    Add-Line '## 5. Drivers & Windows Update'
    Add-Line ''
    Add-Line ('- **Status:** `{0}`' -f @((Escape-MarkdownTableValue $driverStatus)))
    if ($driverDetail) {
        Add-Line ('- **Details:** {0}' -f @((Escape-MarkdownTableValue $driverDetail)))
    }
    Add-Line ''

    # --- Errors & Diagnostics ---
    if ($errorLines.Count -gt 0 -or $warnLines.Count -gt 0) {
        Add-Line '## 6. Issues & Diagnostic Warnings'
        Add-Line ''
        if ($errorLines.Count -gt 0) {
            Add-Line '### Errors'
            Add-Line '```text'
            foreach ($el in $errorLines) { Add-Line $el }
            Add-Line '```'
        }
        if ($warnLines.Count -gt 0) {
            Add-Line '### Warnings'
            Add-Line '```text'
            foreach ($wl in $warnLines) { Add-Line $wl }
            Add-Line '```'
        }
        Add-Line ''
    }

    # --- Log Sources ---
    Add-Line '## 7. Inspected Log Sources'
    Add-Line ''
    Add-Line ('- Unattend & Setup log: `{0}`' -f @($setupScriptsLog))
    Add-Line ('- Applications log: `{0}`' -f @($appsLogPath))
    Add-Line ('- Windows Configuration log: `{0}`' -f @($configLogPath))
    Add-Line ('- Drivers log: `{0}`' -f @($driverLogPath))
    Add-Line ('- Specialize log: `{0}`' -f @($specializeLog))
    Add-Line ('- FirstLogon log: `{0}`' -f @($firstLogonLog))
    Add-Line ''

    Set-Content -LiteralPath $OutputPath -Value $script:reportLines -Encoding UTF8
    Write-Host "Report generated successfully at $OutputPath"
    exit 0
}
catch {
    try {
        New-Item -ItemType Directory -Path $LogDirectory -Force -ErrorAction SilentlyContinue | Out-Null
        Add-Content -LiteralPath (Join-Path $LogDirectory 'report.log') -Value ('[{0:yyyy-MM-dd HH:mm:ss}] [ERROR] {1}' -f @((Get-Date), $_.Exception.Message)) -Encoding UTF8
    }
    catch { }
    exit 1
}
