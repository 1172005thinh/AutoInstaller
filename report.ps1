[CmdletBinding()]
param(
    [string] $LogDirectory = 'C:\Auto-installer',
    [string] $OutputPath = 'C:\Auto-installer\report.md'
)

$ErrorActionPreference = 'Stop'

function Get-LogLines {
    param([string] $Path)

    if (Test-Path -LiteralPath $Path) {
        return @(Get-Content -LiteralPath $Path -ErrorAction Stop)
    }
    return @()
}

function Escape-MarkdownTableValue {
    param([AllowNull()] [string] $Value)

    if ($null -eq $Value) { return '' }
    return $Value.Replace('|', '\|').Replace("`r", ' ').Replace("`n", ' ')
}

try {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null

    $driverLogPath = Join-Path $LogDirectory 'install-drivers.log'
    $appsLogPath = Join-Path $LogDirectory 'install-apps.log'
    $configLogPath = Join-Path $LogDirectory 'configure-windows.log'
    
    $driverLines = Get-LogLines $driverLogPath
    $appsLines = Get-LogLines $appsLogPath
    $configLines = Get-LogLines $configLogPath
    $allLines = @($driverLines + $appsLines + $configLines)

    $applicationStatus = @{}
    foreach ($line in $appsLines) {
        if ($line -match '\[APP\] index=(?<index>\d+); name=(?<name>.*?); status=(?<status>[^;]+); detail=(?<detail>.*)$') {
            $applicationStatus[[int] $Matches.index] = [pscustomobject]@{
                Index = [int] $Matches.index
                Name = $Matches.name
                Status = $Matches.status
                Detail = $Matches.detail
            }
        }
    }

    $driverStatus = 'not-run'
    foreach ($line in $driverLines) {
        if ($line -match '\[DRIVER\] status=(?<status>[^;\s]+)') {
            $driverStatus = $Matches.status
        }
    }

    $configStatus = 'not-run'
    if ($configLines.Count -gt 0) {
        $configStatus = 'failed'
        foreach ($line in $configLines) {
            if ($line -match 'Windows configuration complete and verified') {
                $configStatus = 'success'
            }
        }
    }

    $errors = @($allLines | Where-Object { $_ -match '\[ERROR\]' }).Count
    $warnings = @($allLines | Where-Object { $_ -match '\[WARN\]' }).Count
    $installed = @($applicationStatus.Values | Where-Object { $_.Status -eq 'installed' }).Count
    $alreadyInstalled = @($applicationStatus.Values | Where-Object { $_.Status -eq 'already-installed' }).Count
    $failed = @($applicationStatus.Values | Where-Object { $_.Status -eq 'failed' }).Count
    $disabled = @($applicationStatus.Values | Where-Object { $_.Status -eq 'disabled' }).Count

    $lines = [System.Collections.Generic.List[string]]::new()
    [void] $lines.Add('# Auto-installer report')
    [void] $lines.Add('')
    [void] $lines.Add(('Generated: {0:yyyy-MM-dd HH:mm:ss zzz}' -f (Get-Date)))
    [void] $lines.Add('')
    [void] $lines.Add('## Summary')
    [void] $lines.Add('')
    [void] $lines.Add('| Item | Result |')
    [void] $lines.Add('| --- | --- |')
    [void] $lines.Add("| Driver installation | $(Escape-MarkdownTableValue $driverStatus) |")
    [void] $lines.Add("| Windows configuration | $(Escape-MarkdownTableValue $configStatus) |")
    [void] $lines.Add("| Applications installed | $installed |")
    [void] $lines.Add("| Applications already installed | $alreadyInstalled |")
    [void] $lines.Add("| Applications failed | $failed |")
    [void] $lines.Add("| Applications disabled | $disabled |")
    [void] $lines.Add("| Logged errors | $errors |")
    [void] $lines.Add("| Logged warnings | $warnings |")
    [void] $lines.Add('')
    [void] $lines.Add('## Applications')
    [void] $lines.Add('')

    if ($applicationStatus.Count -eq 0) {
        [void] $lines.Add('No application installer results were recorded.')
    }
    else {
        [void] $lines.Add('| Index | Setup file | Status | Detail |')
        [void] $lines.Add('| ---: | --- | --- | --- |')
        foreach ($entry in $applicationStatus.Values | Sort-Object Index) {
            [void] $lines.Add(("| {0} | {1} | {2} | {3} |" -f $entry.Index, (Escape-MarkdownTableValue $entry.Name), (Escape-MarkdownTableValue $entry.Status), (Escape-MarkdownTableValue $entry.Detail)))
        }
    }

    [void] $lines.Add('')
    [void] $lines.Add('## Log sources')
    [void] $lines.Add('')
    [void] $lines.Add(('- Driver log: `{0}`' -f $driverLogPath))
    [void] $lines.Add(('- Application log: `{0}`' -f $appsLogPath))
    [void] $lines.Add(('- Config log: `{0}`' -f $configLogPath))

    Set-Content -LiteralPath $OutputPath -Value $lines -Encoding utf8
    exit 0
}
catch {
    try {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
        Add-Content -LiteralPath (Join-Path $LogDirectory 'report.log') -Value ('[{0:yyyy-MM-dd HH:mm:ss}] [ERROR] {1}' -f (Get-Date), $_.Exception.Message) -Encoding utf8
    }
    catch { }
    exit 1
}
