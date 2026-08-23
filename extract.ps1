<#
.SYNOPSIS
    Ventoy USB Automated Deployment & Extraction Tool for AutoInstaller.

.DESCRIPTION
    Automates the deployment and extraction of AutoInstaller assets from the local
    workspace to the target Ventoy USB drive partitions (ISO Partition & Software Partition).
    Validates administrative privileges, locates partition drive letters via MD5 marker files,
    copies Ventoy configuration and Unattend templates to the ISO partition, executes full AutoIt
    script compilation, and deploys all application directories and root binaries to the Software partition.

.PARAMETER DryRun
    (-d, --dry-run) Simulates the deployment process, showing planned file operations,
    target drive locations, and potential errors without modifying the USB drive.

.PARAMETER Log
    (-l, --log) Streams detailed live log output to the console during execution.

.PARAMETER Version
    (-v, --version) Displays tool version (v1.0.0) and author information.

.PARAMETER Help
    (-h, --help) Displays help documentation and usage examples.

.PARAMETER NoPrompt
    Suppresses the interactive 'Press Enter to exit' prompt at completion (for automation/CI).

.EXAMPLE
    .\extract.ps1
    # Standard deployment to connected Ventoy USB drive

.EXAMPLE
    .\extract.ps1 --dry-run
    # Simulates USB deployment and validates partition markers

.EXAMPLE
    .\extract.ps1 -l
    # Deploys with live verbose streaming log output
#>

[CmdletBinding(PositionalBinding = $false)]
param(
    [Alias('d', 'dry-run')]
    [switch]$DryRun,

    [Alias('l')]
    [switch]$Log,

    [Alias('v')]
    [switch]$Version,

    [Alias('h', '?')]
    [switch]$Help,

    [switch]$NoPrompt,

    [string]$RootDir = '',

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

$ErrorActionPreference = 'Stop'

# Process remaining arguments for flexible CLI flag variations
if ($RemainingArgs -and $RemainingArgs.Count -gt 0) {
    foreach ($arg in $RemainingArgs) {
        $lower = $arg.ToLowerInvariant()
        if ($lower -in @('-l', '--l', '-log', '--log')) {
            $Log = $true
        } elseif ($lower -in @('-v', '--v', '-version', '--version')) {
            $Version = $true
        } elseif ($lower -in @('-h', '--h', '-help', '--help', '-?')) {
            $Help = $true
        } elseif ($lower -in @('-d', '--d', '-dry-run', '--dry-run', '-dryrun', '--dryrun')) {
            $DryRun = $true
        } elseif ($lower -in @('-noprompt', '--noprompt', '-no-prompt', '--no-prompt')) {
            $NoPrompt = $true
        }
    }
}

$TOOL_NAME    = 'extract'
$TOOL_VERSION = '1.0.0'
$TOOL_AUTHOR  = '1172005thinh'

# ------------------------------------------------------------------------------
# 1. Version Screen
# ------------------------------------------------------------------------------
if ($Version) {
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host " $TOOL_NAME - Ventoy USB Deployment & Extraction Utility" -ForegroundColor Cyan
    Write-Host " Version : $TOOL_VERSION" -ForegroundColor Green
    Write-Host " Author  : $TOOL_AUTHOR" -ForegroundColor Gray
    Write-Host "======================================================================" -ForegroundColor Cyan
    exit 0
}

# ------------------------------------------------------------------------------
# 2. Help Screen
# ------------------------------------------------------------------------------
if ($Help) {
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host " $TOOL_NAME (v$TOOL_VERSION) - Help & Usage Manual" -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host @"
USAGE:
    .\extract.ps1 [OPTIONS]

OPTIONS:
    -d,  --dry-run          Simulate extraction & show planned copy operations.
    -l,  --log              Stream live verbose log messages in the console.
    -v,  --version          Display tool version (v1.0.0) and author info.
    -h,  --help             Show this help screen.
    --no-prompt             Skip the 'Press Enter to exit' prompt upon completion.

PARTITION MARKERS:
    - ISO Partition      : Identified by root marker '5b512ee8a59deb284ad0a6a035ba10b1.md5'
    - SOFTWARE Partition : Identified by root marker 'aea541d7f9574587656dc5125116e548.md5'

DEPLOYMENT FLOW:
    1. Verify Administrator privileges & locate USB partition drive letters.
    2. Copy '/ventoy' directory to the root of the ISO partition.
    3. Copy XML unattended templates from '/Unattend' to the root of the ISO partition.
    4. Compile AutoIt installer scripts via './compile-au2exe.ps1 -a'.
    5. Copy application folders (/Antivirus, /Browsers, /Drivers, /Environment,
       /Office, /Socials, /Tools, /Utilities) and root files to the SOFTWARE partition.
    6. Display vendor setup file download reminder.
    7. Wait for user confirmation before exiting.

EXAMPLES:
    # 1. Normal automated deployment
    .\extract.ps1

    # 2. Dry-run preview
    .\extract.ps1 --dry-run

    # 3. Deployment with live verbose console logs
    .\extract.ps1 -l

"@ -ForegroundColor White
    exit 0
}

# ------------------------------------------------------------------------------
# 3. Root Directory Resolution & Logging Initialization
# ------------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($RootDir)) {
    if ($PSScriptRoot) {
        $RootDir = $PSScriptRoot
    } else {
        $RootDir = (Get-Location).Path
    }
}
$RootDir = (Resolve-Path -LiteralPath $RootDir).Path
$logPath = Join-Path $RootDir 'extract.log'

function Write-ExtractLog {
    param(
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS', 'DRY-RUN')]
        [string]$Level,
        [string]$Message,
        [ConsoleColor]$ConsoleColor = [ConsoleColor]::Gray
    )

    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $logLine   = "[$timestamp] [$Level] $Message"
    try {
        Add-Content -LiteralPath $logPath -Value $logLine -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {}

    if ($Log -or $Level -in @('WARN', 'ERROR', 'SUCCESS')) {
        $color = switch ($Level) {
            'ERROR'   { [ConsoleColor]::Red }
            'WARN'    { [ConsoleColor]::Yellow }
            'SUCCESS' { [ConsoleColor]::Green }
            'DRY-RUN' { [ConsoleColor]::Cyan }
            default   { $ConsoleColor }
        }
        Write-Host "  [$Level] $Message" -ForegroundColor $color
    }
}

# ------------------------------------------------------------------------------
# 4. Administrator Privilege Check
# ------------------------------------------------------------------------------
function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    if ($identity.IsSystem) { return $true }
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Initialize fresh log session
"======================================================================" | Set-Content -LiteralPath $logPath -Encoding UTF8
" extract.ps1 (v$TOOL_VERSION) - Deployment Session Started at $(Get-Date)" | Add-Content -LiteralPath $logPath -Encoding UTF8
"======================================================================" | Add-Content -LiteralPath $logPath -Encoding UTF8

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " $TOOL_NAME - Ventoy USB Deployment & Extraction Utility" -ForegroundColor Cyan
Write-Host " Root Dir : $RootDir" -ForegroundColor Gray
Write-Host " Log File : $logPath" -ForegroundColor Gray
if ($DryRun) {
    Write-Host " Mode     : DRY-RUN SIMULATION (No files will be modified)" -ForegroundColor Cyan
} else {
    Write-Host " Mode     : LIVE DEPLOYMENT" -ForegroundColor Green
}
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Administrator)) {
    if ($DryRun) {
        Write-ExtractLog WARN "Non-administrator execution detected (Allowed under Dry-Run simulation)."
        Write-Host "  [WARN] Running without Administrator privileges (Allowed under Dry-Run mode).`n" -ForegroundColor Yellow
    } else {
        Write-ExtractLog ERROR "Administrator privileges are required to deploy files to USB partitions."
        Write-Host "`n[ERROR] Administrator privileges are required. Please run PowerShell as Administrator.`n" -ForegroundColor Red
        exit 5
    }
}

# ------------------------------------------------------------------------------
# 5. Locate USB Partitions via MD5 Markers
# ------------------------------------------------------------------------------
$isoMarker      = '5b512ee8a59deb284ad0a6a035ba10b1.md5'
$softwareMarker = 'aea541d7f9574587656dc5125116e548.md5'

$isoRoot      = $null
$softwareRoot = $null

Write-Host "[STEP 1/5] Probing connected drives for Ventoy USB partition markers..." -ForegroundColor Cyan
Write-ExtractLog INFO "Scanning filesystem drives for ISO marker '$isoMarker' and Software marker '$softwareMarker'."

$allDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -and (Test-Path -LiteralPath $_.Root) }

foreach ($drive in $allDrives) {
    $driveRoot = $drive.Root.TrimEnd('\')
    
    # Check for ISO marker
    $candIso = Join-Path $drive.Root $isoMarker
    if (Test-Path -LiteralPath $candIso) {
        # Ensure we prioritize USB partitions over workspace root if distinct
        if (-not $isoRoot) {
            $isoRoot = $driveRoot
        }
    }

    # Check for Software marker
    $candSoftware = Join-Path $drive.Root $softwareMarker
    if (Test-Path -LiteralPath $candSoftware) {
        if (-not $softwareRoot) {
            $softwareRoot = $driveRoot
        }
    }
}

# Dry-run fallback simulation if USB is not physically attached during dry-run preview
if ($DryRun) {
    if (-not $isoRoot) {
        $isoRoot = "X:"
        Write-ExtractLog DRY-RUN "Simulated ISO Partition at '$isoRoot' (Marker '$isoMarker')"
    }
    if (-not $softwareRoot) {
        $softwareRoot = "Y:"
        Write-ExtractLog DRY-RUN "Simulated SOFTWARE Partition at '$softwareRoot' (Marker '$softwareMarker')"
    }
}

$missingMarkers = @()
if (-not $isoRoot) { $missingMarkers += "ISO Partition marker '$isoMarker'" }
if (-not $softwareRoot) { $missingMarkers += "SOFTWARE Partition marker '$softwareMarker'" }

if ($missingMarkers.Count -gt 0) {
    $errMsg = "Missing partition marker file(s): $($missingMarkers -join ', '). Ensure the Ventoy USB is connected and partition markers are placed at root."
    Write-ExtractLog ERROR $errMsg
    Write-Host "`n[ERROR] $errMsg`n" -ForegroundColor Red
    exit 1
}

Write-Host ("  [FOUND] ISO Partition      : {0}\ ({1})" -f $isoRoot, $isoMarker) -ForegroundColor Green
Write-Host ("  [FOUND] SOFTWARE Partition : {0}\ ({1})" -f $softwareRoot, $softwareMarker) -ForegroundColor Green
Write-ExtractLog INFO "Located ISO partition at '$isoRoot\' and SOFTWARE partition at '$softwareRoot\'."

$totalOperations = 0
$successCount    = 0
$failCount       = 0
$taskResults     = [System.Collections.Generic.List[pscustomobject]]::new()

function Copy-DeployDirectory {
    param(
        [string]$SourceDir,
        [string]$DestinationDir,
        [string]$Description
    )

    $script:totalOperations++
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    if (-not (Test-Path -LiteralPath $SourceDir)) {
        Write-ExtractLog WARN "Source directory not found: $SourceDir"
        $script:taskResults.Add([pscustomobject]@{
            Step   = $Description
            Target = $DestinationDir
            Status = 'SKIPPED (Source missing)'
            TimeMs = 0
        })
        return
    }

    if ($DryRun) {
        $sw.Stop()
        Write-Host ("  [DRY-RUN] Directory: {0} -> {1}" -f $SourceDir, $DestinationDir) -ForegroundColor Cyan
        Write-ExtractLog DRY-RUN "Copy directory: '$SourceDir' -> '$DestinationDir'"
        $script:taskResults.Add([pscustomobject]@{
            Step   = $Description
            Target = $DestinationDir
            Status = 'DRY-RUN'
            TimeMs = 0
        })
        $script:successCount++
        return
    }

    try {
        if (-not (Test-Path -LiteralPath $DestinationDir)) {
            $null = New-Item -ItemType Directory -Path $DestinationDir -Force -ErrorAction SilentlyContinue
        }
        Copy-Item -Path (Join-Path $SourceDir '*') -Destination $DestinationDir -Recurse -Force -ErrorAction Stop
        $sw.Stop()
        Write-Host ("  [SUCCESS] {0} -> {1} ({2} ms)" -f $Description, $DestinationDir, $sw.ElapsedMilliseconds) -ForegroundColor Green
        Write-ExtractLog SUCCESS "Copied directory '$SourceDir' to '$DestinationDir' in $($sw.ElapsedMilliseconds) ms"
        $script:taskResults.Add([pscustomobject]@{
            Step   = $Description
            Target = $DestinationDir
            Status = 'SUCCESS'
            TimeMs = $sw.ElapsedMilliseconds
        })
        $script:successCount++
    } catch {
        $sw.Stop()
        Write-Host ("  [FAILED]  {0} -> {1}: {2}" -f $Description, $DestinationDir, $_.Exception.Message) -ForegroundColor Red
        Write-ExtractLog ERROR "Failed copying directory '$SourceDir' to '$DestinationDir': $($_.Exception.Message)"
        $script:taskResults.Add([pscustomobject]@{
            Step   = $Description
            Target = $DestinationDir
            Status = 'FAILED'
            TimeMs = $sw.ElapsedMilliseconds
        })
        $script:failCount++
    }
}

function Copy-DeployFiles {
    param(
        [string]$SourcePattern,
        [string]$DestinationDir,
        [string]$Description
    )

    $script:totalOperations++
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $matchingFiles = @(Get-ChildItem -Path $SourcePattern -File -ErrorAction SilentlyContinue)
    if ($matchingFiles.Count -eq 0) {
        Write-ExtractLog WARN "No files matched pattern: $SourcePattern"
        $script:taskResults.Add([pscustomobject]@{
            Step   = $Description
            Target = $DestinationDir
            Status = 'SKIPPED (No files)'
            TimeMs = 0
        })
        return
    }

    if ($DryRun) {
        $sw.Stop()
        Write-Host ("  [DRY-RUN] Files ({0} items): {1} -> {2}" -f $matchingFiles.Count, $SourcePattern, $DestinationDir) -ForegroundColor Cyan
        Write-ExtractLog DRY-RUN "Copy $($matchingFiles.Count) file(s) matching '$SourcePattern' to '$DestinationDir'"
        $script:taskResults.Add([pscustomobject]@{
            Step   = $Description
            Target = $DestinationDir
            Status = 'DRY-RUN'
            TimeMs = 0
        })
        $script:successCount++
        return
    }

    try {
        if (-not (Test-Path -LiteralPath $DestinationDir)) {
            $null = New-Item -ItemType Directory -Path $DestinationDir -Force -ErrorAction SilentlyContinue
        }
        foreach ($file in $matchingFiles) {
            Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $DestinationDir $file.Name) -Force -ErrorAction Stop
        }
        $sw.Stop()
        Write-Host ("  [SUCCESS] {0} ({1} file(s)) -> {2} ({3} ms)" -f $Description, $matchingFiles.Count, $DestinationDir, $sw.ElapsedMilliseconds) -ForegroundColor Green
        Write-ExtractLog SUCCESS "Copied $($matchingFiles.Count) file(s) to '$DestinationDir' in $($sw.ElapsedMilliseconds) ms"
        $script:taskResults.Add([pscustomobject]@{
            Step   = $Description
            Target = $DestinationDir
            Status = 'SUCCESS'
            TimeMs = $sw.ElapsedMilliseconds
        })
        $script:successCount++
    } catch {
        $sw.Stop()
        Write-Host ("  [FAILED]  {0}: {1}" -f $Description, $_.Exception.Message) -ForegroundColor Red
        Write-ExtractLog ERROR "Failed copying files from '$SourcePattern' to '$DestinationDir': $($_.Exception.Message)"
        $script:taskResults.Add([pscustomobject]@{
            Step   = $Description
            Target = $DestinationDir
            Status = 'FAILED'
            TimeMs = $sw.ElapsedMilliseconds
        })
        $script:failCount++
    }
}

# ------------------------------------------------------------------------------
# 6. Step 2: Deploy /ventoy to ISO Partition
# ------------------------------------------------------------------------------
Write-Host "`n[STEP 2/5] Deploying Ventoy configuration to ISO partition..." -ForegroundColor Cyan
$ventoySrc = Join-Path $RootDir 'ventoy'
$ventoyDst = Join-Path $isoRoot 'ventoy'
Copy-DeployDirectory -SourceDir $ventoySrc -DestinationDir $ventoyDst -Description "Ventoy Folder (/ventoy)"

# ------------------------------------------------------------------------------
# 7. Step 3: Deploy /Unattend XMLs to Root of ISO Partition
# ------------------------------------------------------------------------------
Write-Host "`n[STEP 3/5] Deploying Unattend XML templates to root of ISO partition..." -ForegroundColor Cyan
$unattendSrc = Join-Path $RootDir 'Unattend\*.xml'
Copy-DeployFiles -SourcePattern $unattendSrc -DestinationDir $isoRoot -Description "Unattend XML Templates"

# ------------------------------------------------------------------------------
# 8. Step 4: Recompile AutoIt Scripts
# ------------------------------------------------------------------------------
Write-Host "`n[STEP 4/5] Compiling AutoIt3 executables..." -ForegroundColor Cyan
$compilerScript = Join-Path $RootDir 'compile-au2exe.ps1'
if (Test-Path -LiteralPath $compilerScript) {
    $compileSw = [System.Diagnostics.Stopwatch]::StartNew()
    $compileArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$compilerScript`"", '-a')
    if ($DryRun) { $compileArgs += '--dry-run' }
    if ($Log)    { $compileArgs += '-l' }

    Write-ExtractLog INFO "Executing compilation utility: $compilerScript -a $(if ($DryRun) { '--dry-run' })"
    
    $proc = Start-Process -FilePath "powershell.exe" -ArgumentList ($compileArgs -join ' ') -NoNewWindow -PassThru -Wait
    $compileSw.Stop()
    
    if ($proc.ExitCode -eq 0) {
        Write-Host ("  [SUCCESS] AutoIt scripts recompiled successfully ({0} ms)" -f $compileSw.ElapsedMilliseconds) -ForegroundColor Green
        Write-ExtractLog SUCCESS "Au2exe compilation completed successfully in $($compileSw.ElapsedMilliseconds) ms"
        $script:taskResults.Add([pscustomobject]@{
            Step   = 'Compile AutoIt Executables (-a)'
            Target = 'Workspace Root'
            Status = $(if ($DryRun) { 'DRY-RUN' } else { 'SUCCESS' })
            TimeMs = $compileSw.ElapsedMilliseconds
        })
        $script:successCount++
    } else {
        Write-Host ("  [FAILED]  Compilation utility returned non-zero exit code: {0}" -f $proc.ExitCode) -ForegroundColor Red
        Write-ExtractLog ERROR "Au2exe compilation failed with exit code $($proc.ExitCode)"
        $script:taskResults.Add([pscustomobject]@{
            Step   = 'Compile AutoIt Executables (-a)'
            Target = 'Workspace Root'
            Status = "FAILED ($($proc.ExitCode))"
            TimeMs = $compileSw.ElapsedMilliseconds
        })
        $script:failCount++
    }
} else {
    Write-ExtractLog WARN "Compilation utility '$compilerScript' not found."
}

# ------------------------------------------------------------------------------
# 9. Step 5: Deploy Folders and Assets to SOFTWARE Partition
# ------------------------------------------------------------------------------
Write-Host "`n[STEP 5/5] Deploying application packages and scripts to SOFTWARE partition..." -ForegroundColor Cyan

# Application directories to copy
$appFolders = @(
    'Antivirus',
    'Browsers',
    'Drivers',
    'Environment',
    'Office',
    'Socials',
    'Tools',
    'Utilities'
)

foreach ($folder in $appFolders) {
    $src = Join-Path $RootDir $folder
    $dst = Join-Path $softwareRoot $folder
    if (Test-Path -LiteralPath $src) {
        Copy-DeployDirectory -SourceDir $src -DestinationDir $dst -Description "App Folder (/$folder)"
    }
}

# Root files to copy: *.ps1 (excluding extract.ps1), *.exe, *.ico, *.png, *.ini, and marker md5
$rootExtensions = @('*.exe', '*.ico', '*.png', '*.ini', '*.ps1')
$rootFiles = @()
foreach ($ext in $rootExtensions) {
    $rootFiles += Get-ChildItem -Path $RootDir -Filter $ext -File -Force -ErrorAction SilentlyContinue |
                  Where-Object { $_.Name -ne 'extract.ps1' }
}

# Include software marker md5
$markerPath = Join-Path $RootDir $softwareMarker
if (Test-Path -LiteralPath $markerPath) {
    $rootFiles += Get-Item -LiteralPath $markerPath -Force -ErrorAction SilentlyContinue
}

if ($rootFiles.Count -gt 0) {
    $script:totalOperations++
    $rootFilesSw = [System.Diagnostics.Stopwatch]::StartNew()
    
    if ($DryRun) {
        $rootFilesSw.Stop()
        Write-Host ("  [DRY-RUN] Root Assets ({0} file(s)) -> {1}\" -f $rootFiles.Count, $softwareRoot) -ForegroundColor Cyan
        Write-ExtractLog DRY-RUN "Copy $($rootFiles.Count) root asset file(s) to '$softwareRoot\'"
        $script:taskResults.Add([pscustomobject]@{
            Step   = "Root Scripts & Binaries"
            Target = "$softwareRoot\"
            Status = 'DRY-RUN'
            TimeMs = 0
        })
        $script:successCount++
    } else {
        try {
            foreach ($rf in $rootFiles) {
                Copy-Item -LiteralPath $rf.FullName -Destination (Join-Path $softwareRoot $rf.Name) -Force -ErrorAction Stop
            }
            $rootFilesSw.Stop()
            Write-Host ("  [SUCCESS] Root Scripts & Binaries ({0} file(s)) -> {1}\ ({2} ms)" -f $rootFiles.Count, $softwareRoot, $rootFilesSw.ElapsedMilliseconds) -ForegroundColor Green
            Write-ExtractLog SUCCESS "Copied $($rootFiles.Count) root files to '$softwareRoot\' in $($rootFilesSw.ElapsedMilliseconds) ms"
            $script:taskResults.Add([pscustomobject]@{
                Step   = "Root Scripts & Binaries"
                Target = "$softwareRoot\"
                Status = 'SUCCESS'
                TimeMs = $rootFilesSw.ElapsedMilliseconds
            })
            $script:successCount++
        } catch {
            $rootFilesSw.Stop()
            Write-Host ("  [FAILED]  Root Scripts & Binaries -> {0}\: {1}" -f $softwareRoot, $_.Exception.Message) -ForegroundColor Red
            Write-ExtractLog ERROR "Failed copying root files to '$softwareRoot\': $($_.Exception.Message)"
            $script:taskResults.Add([pscustomobject]@{
                Step   = "Root Scripts & Binaries"
                Target = "$softwareRoot\"
                Status = 'FAILED'
                TimeMs = $rootFilesSw.ElapsedMilliseconds
            })
            $script:failCount++
        }
    }
}

# ------------------------------------------------------------------------------
# 10. Summary Table & Vendor Download Reminder
# ------------------------------------------------------------------------------
Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host " Deployment Summary" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
foreach ($r in $script:taskResults) {
    $statColor = switch -Regex ($r.Status) {
        'SUCCESS' { [ConsoleColor]::Green }
        'DRY-RUN' { [ConsoleColor]::Cyan }
        'SKIPPED' { [ConsoleColor]::Yellow }
        default   { [ConsoleColor]::Red }
    }
    Write-Host ("  {0,-35} | {1,-18} | {2}" -f $r.Step, $r.Status, $r.Target) -ForegroundColor $statColor
}
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host (" Total Tasks: {0} | Success: {1} | Failed: {2}" -f $script:taskResults.Count, $script:successCount, $script:failCount) -ForegroundColor $(if ($script:failCount -eq 0) { 'Green' } else { 'Red' })
Write-Host "======================================================================" -ForegroundColor Cyan

# Step 6: Download Reminder
Write-Host @"

======================================================================
 [NOTICE] VENDOR SETUP FILES DOWNLOAD REMINDER
======================================================================
 Please ensure you have manually downloaded and placed the required
 vendor installation binaries into their respective folders on the
 SOFTWARE partition as configured in 'install-apps.ini'.
======================================================================
"@ -ForegroundColor Yellow

Write-ExtractLog INFO "Deployment completed. Total tasks: $($script:taskResults.Count), Success: $script:successCount, Failed: $script:failCount."

# Step 7: Press Enter to exit
if (-not $NoPrompt -and -not $DryRun) {
    Write-Host ""
    $null = Read-Host -Prompt "Press Enter to exit"
}

if ($script:failCount -gt 0) {
    exit 1
}
exit 0
