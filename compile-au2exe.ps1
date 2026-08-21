<#
.SYNOPSIS
    Au2exe Batch & Single-Target Compiler Utility for AutoInstaller.

.DESCRIPTION
    Compiles AutoIt (.au3) source files into standalone Windows executables (.exe)
    using the official AutoIt Aut2Exe compiler. Supports batch compilation, custom
    input/output file mappings, exclusion filters, custom icon injection (.ico),
    live compiler logging, and dry-run preview.

.PARAMETER All
    (-a, --a) Recompile all .au3 scripts in the workspace, including the master installer
    (which generates both install-apps.exe and Auto-installer.exe).

.PARAMETER InputPaths
    (-i, --input) One or more specific .au3 script paths to compile.

.PARAMETER OutputPaths
    (-o, --output) One or more corresponding destination .exe paths. If omitted,
    each input file is compiled to an .exe with the same base name and directory.

.PARAMETER Exclude
    (-ex, --exclude) One or more script paths or file names to exclude from compilation.

.PARAMETER IconPath
    (-ic, --icon) Path to a custom .ico icon file (e.g. icon.ico). If omitted,
    the tool automatically checks for and uses 'icon.ico' in the workspace root if present.

.PARAMETER DryRun
    (-d, --dry-run) Preview compilation targets without invoking the compiler.

.PARAMETER Log
    (-l, --log) Stream detailed compiler stdout/stderr output to the console.

.PARAMETER Version
    (-v, --version) Display tool version and author information.

.PARAMETER Help
    (-h, --help) Display help documentation and usage examples.

.EXAMPLE
    .\compile-au2exe.ps1 -a
    # Compiles all .au3 files with icon.ico (producing both install-apps.exe and Auto-installer.exe)

.EXAMPLE
    .\compile-au2exe.ps1 -a --dry-run
    # Previews all compilation targets without compiling

.EXAMPLE
    .\compile-au2exe.ps1 -i Tools\Editors\install_notepadpp.au3 --icon icon.ico
    # Compiles notepad++ installer with custom icon

.EXAMPLE
    .\compile-au2exe.ps1 -i install-apps.au3 -o Auto-installer.exe
    # Compiles install-apps.au3 to Auto-installer.exe

.EXAMPLE
    .\compile-au2exe.ps1 -ex Socials\install_discord.au3 install-drivers.au3
    # Compiles all scripts except Discord and Drivers
#>

[CmdletBinding(PositionalBinding = $false)]
param(
    [Alias('a')]
    [switch]$All,

    [Alias('i', 'input')]
    [string[]]$InputPaths = @(),

    [Alias('o', 'output')]
    [string[]]$OutputPaths = @(),

    [Alias('ex')]
    [string[]]$Exclude = @(),

    [Alias('ic', 'icon')]
    [string]$IconPath = '',

    [Alias('d', 'dry-run')]
    [switch]$DryRun,

    [Alias('l')]
    [switch]$Log,

    [Alias('v')]
    [switch]$Version,

    [Alias('h', '?')]
    [switch]$Help,

    [string]$CompilerPath = '',
    [string]$RootDir = '',

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

$ErrorActionPreference = 'Stop'

# Process remaining arguments to support space-separated list for -i, -o, -ex, --icon, etc.
if ($RemainingArgs -and $RemainingArgs.Count -gt 0) {
    $currentFlag = if ($InputPaths.Count -gt 0 -and $OutputPaths.Count -eq 0 -and $Exclude.Count -eq 0) { 'input' } `
                   elseif ($OutputPaths.Count -gt 0) { 'output' } `
                   elseif ($Exclude.Count -gt 0) { 'exclude' } `
                   else { $null }
    foreach ($arg in $RemainingArgs) {
        $lower = $arg.ToLowerInvariant()
        if ($lower -in @('-a', '--a', '-all', '--all')) {
            $All = $true
            $currentFlag = $null
        } elseif ($lower -in @('-l', '--l', '-log', '--log')) {
            $Log = $true
            $currentFlag = $null
        } elseif ($lower -in @('-v', '--v', '-version', '--version')) {
            $Version = $true
            $currentFlag = $null
        } elseif ($lower -in @('-h', '--h', '-help', '--help', '-?')) {
            $Help = $true
            $currentFlag = $null
        } elseif ($lower -in @('-d', '--d', '-dry-run', '--dry-run', '-dryrun', '--dryrun')) {
            $DryRun = $true
            $currentFlag = $null
        } elseif ($lower -in @('-ic', '--ic', '-icon', '--icon')) {
            $currentFlag = 'icon'
        } elseif ($lower -in @('-i', '--i', '-input', '--input')) {
            $currentFlag = 'input'
        } elseif ($lower -in @('-o', '--o', '-output', '--output')) {
            $currentFlag = 'output'
        } elseif ($lower -in @('-ex', '--ex', '-exclude', '--exclude')) {
            $currentFlag = 'exclude'
        } elseif ($arg.StartsWith('-')) {
            $currentFlag = $null
        } else {
            if ($currentFlag -eq 'icon') {
                $IconPath = $arg
                $currentFlag = $null
            } elseif ($currentFlag -eq 'input') {
                $InputPaths += $arg
            } elseif ($currentFlag -eq 'output') {
                $OutputPaths += $arg
            } elseif ($currentFlag -eq 'exclude') {
                $Exclude += $arg
            }
        }
    }
}

$TOOL_NAME    = 'compile-au2exe'
$TOOL_VERSION = '1.2.0'
$TOOL_AUTHOR  = 'AutoInstaller Team'

# If no flags/parameters were parsed, display the help screen by default
$hasExplicitTarget = ($All) -or ($InputPaths -and $InputPaths.Count -gt 0) -or ($Exclude -and $Exclude.Count -gt 0) -or ($Version)
if (-not $hasExplicitTarget) {
    $Help = $true
}

# ------------------------------------------------------------------------------
# 1. Version Screen
# ------------------------------------------------------------------------------
if ($Version) {
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host " $TOOL_NAME - AutoIt3 Au2exe Compilation Tool" -ForegroundColor Cyan
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
    .\compile-au2exe.ps1 [OPTIONS]

OPTIONS:
    -a,  --a, -all          Recompile everything (including the master installer).
    -i,  --input <files>    Specify one or more AU3 script paths to compile.
    -o,  --output <files>   Specify output EXE path(s) respectively for each input.
    -ex, --exclude <files>  Exclude specified script path(s) or file name(s).
    -ic, --icon <file>      Specify a custom .ico icon file (defaults to icon.ico if present).
    -d,  --dry-run          Preview compilation targets without invoking compiler.
    -l,  --log              Stream live verbose output from Au2exe compiler.
    -v,  --version          Display tool version and author info.
    -h,  --help             Show this help screen.

MASTER INSTALLER NOTE:
    install-apps.au3 is the single source for both 'install-apps.exe' and
    'Auto-installer.exe'. When compiling install-apps.au3, the tool compiles
    and mirrors both executable binaries in the root directory.

EXAMPLES:
    # 1. Show help (default when invoked without parameters)
    .\compile-au2exe.ps1

    # 2. Recompile everything with default icon (icon.ico)
    .\compile-au2exe.ps1 -a

    # 3. Dry-run preview of all targets
    .\compile-au2exe.ps1 -a --dry-run

    # 4. Compile specific scripts with custom icon
    .\compile-au2exe.ps1 -i Tools\Editors\install_notepadpp.au3 --icon icon.ico

    # 5. Compile with custom output executable name
    .\compile-au2exe.ps1 -i install-apps.au3 -o Auto-installer.exe

    # 6. Compile with multiple custom outputs
    .\compile-au2exe.ps1 -i app1.au3 app2.au3 -o out1.exe out2.exe

    # 7. Compile all except specific scripts
    .\compile-au2exe.ps1 -a -ex install_discord.au3 Utilities\Fonts\install_fonts.au3

    # 8. Compile with live compiler logs
    .\compile-au2exe.ps1 -i configure-windows.au3 -l

"@ -ForegroundColor White
    exit 0
}

# ------------------------------------------------------------------------------
# 3. Root Directory Resolution
# ------------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($RootDir)) {
    if ($PSScriptRoot) {
        $RootDir = $PSScriptRoot
    } else {
        $RootDir = (Get-Location).Path
    }
}
$RootDir = (Resolve-Path -LiteralPath $RootDir).Path

# ------------------------------------------------------------------------------
# 4. Compiler Auto-Detection
# ------------------------------------------------------------------------------
$candidateCompilers = @(
    $CompilerPath,
    'D:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe_x64.exe',
    'C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe_x64.exe',
    "${env:ProgramFiles(x86)}\AutoIt3\Aut2Exe\Aut2exe_x64.exe",
    "${env:ProgramFiles}\AutoIt3\Aut2Exe\Aut2exe_x64.exe",
    'D:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe.exe',
    'C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe.exe',
    "${env:ProgramFiles(x86)}\AutoIt3\Aut2Exe\Aut2exe.exe",
    "${env:ProgramFiles}\AutoIt3\Aut2Exe\Aut2exe.exe"
) | Where-Object { [string]::IsNullOrWhiteSpace($_) -eq $false }

$foundCompiler = $null
foreach ($cand in $candidateCompilers) {
    if (Test-Path -LiteralPath $cand) {
        $foundCompiler = (Resolve-Path -LiteralPath $cand).Path
        break
    }
}

if (-not $foundCompiler) {
    $cmd = Get-Command 'Aut2exe_x64.exe' -ErrorAction SilentlyContinue
    if (-not $cmd) { $cmd = Get-Command 'Aut2exe.exe' -ErrorAction SilentlyContinue }
    if ($cmd) { $foundCompiler = $cmd.Source }
}

if (-not $foundCompiler) {
    Write-Error "AutoIt3 compiler (Aut2exe_x64.exe / Aut2exe.exe) was not found. Please specify -CompilerPath."
    exit 1
}

# ------------------------------------------------------------------------------
# 5. Icon Resolution
# ------------------------------------------------------------------------------
$resolvedIcon = $null
if (-not [string]::IsNullOrWhiteSpace($IconPath)) {
    if (Test-Path -LiteralPath $IconPath) {
        $resolvedIcon = (Resolve-Path -LiteralPath $IconPath).Path
    } else {
        $combinedIcon = Join-Path $RootDir $IconPath
        if (Test-Path -LiteralPath $combinedIcon) {
            $resolvedIcon = (Resolve-Path -LiteralPath $combinedIcon).Path
        }
    }
    if (-not $resolvedIcon) {
        Write-Error "Specified icon file not found: $IconPath"
        exit 1
    }
} else {
    # Default to icon.ico in the script/root directory; return error if not found
    $defaultIcon = Join-Path $RootDir 'icon.ico'
    if (Test-Path -LiteralPath $defaultIcon) {
        $resolvedIcon = (Resolve-Path -LiteralPath $defaultIcon).Path
    } else {
        Write-Error "Default icon file not found: $defaultIcon. Please ensure 'icon.ico' exists in the same folder or specify a custom icon path using --icon <path>."
        exit 1
    }
}

# ------------------------------------------------------------------------------
# 6. Build Target Worklist
# ------------------------------------------------------------------------------
$compilationTasks = @()
$masterPatterns   = @('install-apps.au3', 'auto-installer.au3')

# Helper to normalize paths for comparison
function Normalize-PathKey {
    param([string]$p)
    if ([string]::IsNullOrWhiteSpace($p)) { return '' }
    $clean = $p.Trim().Trim('"', "'").Replace('/', '\')
    if (Test-Path -LiteralPath $clean) {
        return (Resolve-Path -LiteralPath $clean).Path.ToLowerInvariant()
    }
    $combined = Join-Path $RootDir $clean
    if (Test-Path -LiteralPath $combined) {
        return (Resolve-Path -LiteralPath $combined).Path.ToLowerInvariant()
    }
    return $clean.ToLowerInvariant()
}

# Prepare exclusion set
$excludeSet = @{}
if ($Exclude -and $Exclude.Count -gt 0) {
    foreach ($ex in $Exclude) {
        $norm = Normalize-PathKey $ex
        $excludeSet[$norm] = $true
        $leaf = (Split-Path -Path $ex -Leaf).ToLowerInvariant()
        $excludeSet[$leaf] = $true
    }
}

if ($InputPaths -and $InputPaths.Count -gt 0) {
    # Custom Input Mode
    if ($OutputPaths -and $OutputPaths.Count -gt 0 -and $OutputPaths.Count -ne $InputPaths.Count) {
        Write-Error "The number of outputs ($($OutputPaths.Count)) does not match the number of inputs ($($InputPaths.Count))."
        exit 1
    }

    for ($idx = 0; $idx -lt $InputPaths.Count; $idx++) {
        $inPath = $InputPaths[$idx]
        $resolvedIn = $null
        if (Test-Path -LiteralPath $inPath) {
            $resolvedIn = (Resolve-Path -LiteralPath $inPath).Path
        } else {
            $combined = Join-Path $RootDir $inPath
            if (Test-Path -LiteralPath $combined) {
                $resolvedIn = (Resolve-Path -LiteralPath $combined).Path
            }
        }

        if (-not $resolvedIn) {
            Write-Error "Specified input file not found: $inPath"
            exit 1
        }

        if ($OutputPaths -and $OutputPaths.Count -gt $idx) {
            $outPath = $OutputPaths[$idx]
            if (-not [System.IO.Path]::IsPathRooted($outPath)) {
                $outPath = Join-Path $RootDir $outPath
            }
        } else {
            $outPath = [System.IO.Path]::ChangeExtension($resolvedIn, '.exe')
        }

        $compilationTasks += [PSCustomObject]@{
            SourceFile = $resolvedIn
            OutputFile = $outPath
        }
    }
} else {
    # Discovery Mode
    $allAu3 = Get-ChildItem -Path $RootDir -Filter '*.au3' -Recurse -File
    foreach ($file in $allAu3) {
        $normFull = $file.FullName.ToLowerInvariant()
        $leafName = $file.Name.ToLowerInvariant()

        # Check explicit exclusion
        if ($excludeSet.ContainsKey($normFull) -or $excludeSet.ContainsKey($leafName)) {
            Write-Host "  [EXCLUDED] $($file.FullName)" -ForegroundColor DarkGray
            continue
        }

        # Check default master installer skip if not -All
        $isMaster = $leafName -in $masterPatterns
        if ($isMaster -and -not $All) {
            Write-Host "  [SKIP MASTER] $($file.FullName)" -ForegroundColor DarkGray
            continue
        }

        $outExe = [System.IO.Path]::ChangeExtension($file.FullName, '.exe')
        $compilationTasks += [PSCustomObject]@{
            SourceFile = $file.FullName
            OutputFile = $outExe
        }
    }
}

# ------------------------------------------------------------------------------
# 7. Execute Compilation
# ------------------------------------------------------------------------------
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " $TOOL_NAME - Au2exe Compilation Utility" -ForegroundColor Cyan
Write-Host " Compiler : $foundCompiler" -ForegroundColor Gray
Write-Host " Root Dir : $RootDir" -ForegroundColor Gray
Write-Host " Icon     : $(if ($resolvedIcon) { $resolvedIcon } else { 'None (Default AutoIt icon)' })" -ForegroundColor $(if ($resolvedIcon) { 'Green' } else { 'DarkGray' })
Write-Host " Targets  : $($compilationTasks.Count) file(s)" -ForegroundColor Gray
if ($Log) {
    Write-Host " Logging  : Verbose console streaming enabled (-l)" -ForegroundColor Yellow
}
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

if ($compilationTasks.Count -eq 0) {
    Write-Host "No compilation tasks to process." -ForegroundColor Yellow
    exit 0
}

$successCount = 0
$failCount = 0
$results = @()

foreach ($task in $compilationTasks) {
    $src = $task.SourceFile
    $out = $task.OutputFile
    
    $relSrc = $src.Replace($RootDir, '').TrimStart('\', '/')
    $relOut = $out.Replace($RootDir, '').TrimStart('\', '/')
    
    # Ensure destination parent directory exists
    $outDir = Split-Path -Path $out -Parent
    if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
        $null = New-Item -ItemType Directory -Path $outDir -Force -ErrorAction SilentlyContinue
    }

    if ($DryRun) {
        Write-Host ("  [DRY-RUN] {0} -> {1}" -f $relSrc, $relOut) -ForegroundColor Cyan
        $results += [PSCustomObject]@{
            Source = $relSrc
            Output = $relOut
            Status = 'DRY-RUN'
        }
        $successCount++
        continue
    }

    $argList = "/in `"$src`" /out `"$out`""
    if ($resolvedIcon) {
        $argList += " /icon `"$resolvedIcon`""
    }

    if ($Log) {
        Write-Host ("`n>>> Compiling: {0}" -f $relSrc) -ForegroundColor Magenta
        Write-Host ("    Command: & `"$foundCompiler`" $argList") -ForegroundColor DarkGray
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    
    if ($Log) {
        $procInfo = New-Object System.Diagnostics.ProcessStartInfo
        $procInfo.FileName = $foundCompiler
        $procInfo.Arguments = $argList
        $procInfo.RedirectStandardOutput = $true
        $procInfo.RedirectStandardError = $true
        $procInfo.UseShellExecute = $false
        $procInfo.CreateNoWindow = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $procInfo
        $null = $proc.Start()

        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()
        $sw.Stop()

        if (-not [string]::IsNullOrWhiteSpace($stdout)) {
            Write-Host "    [STDOUT] $stdout" -ForegroundColor Gray
        }
        if (-not [string]::IsNullOrWhiteSpace($stderr)) {
            Write-Host "    [STDERR] $stderr" -ForegroundColor Yellow
        }
        $exitCode = $proc.ExitCode
    } else {
        $proc = Start-Process -FilePath $foundCompiler -ArgumentList $argList -NoNewWindow -PassThru -Wait
        $sw.Stop()
        $exitCode = $proc.ExitCode
    }

    if ($exitCode -eq 0 -and (Test-Path -LiteralPath $out)) {
        Write-Host ("  [SUCCESS] {0} -> {1} ({2} ms)" -f $relSrc, $relOut, $sw.ElapsedMilliseconds) -ForegroundColor Green
        
        # Mirror master installer if install-apps.au3 is compiled
        if ($src.EndsWith('install-apps.au3', [System.StringComparison]::OrdinalIgnoreCase)) {
            $autoInstallerExe = Join-Path (Split-Path -Path $out -Parent) 'Auto-installer.exe'
            $installAppsExe   = Join-Path (Split-Path -Path $out -Parent) 'install-apps.exe'
            try {
                Copy-Item -LiteralPath $out -Destination $autoInstallerExe -Force -ErrorAction SilentlyContinue
                Copy-Item -LiteralPath $out -Destination $installAppsExe -Force -ErrorAction SilentlyContinue
                Write-Host "    [MIRROR] Synchronized both install-apps.exe and Auto-installer.exe" -ForegroundColor DarkCyan
            } catch {}
        }

        $results += [PSCustomObject]@{
            Source  = $relSrc
            Output  = $relOut
            Status  = 'SUCCESS'
            TimeMs  = $sw.ElapsedMilliseconds
        }
        $successCount++
    } else {
        Write-Host ("  [FAILED]  {0} (ExitCode: {1})" -f $relSrc, $exitCode) -ForegroundColor Red
        $results += [PSCustomObject]@{
            Source  = $relSrc
            Output  = $relOut
            Status  = "FAILED ($exitCode)"
            TimeMs  = $sw.ElapsedMilliseconds
        }
        $failCount++
    }
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host (" Compilation Summary: Total={0} | Success={1} | Failed={2}" -f $compilationTasks.Count, $successCount, $failCount) -ForegroundColor $(if ($failCount -eq 0) { 'Green' } else { 'Red' })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failCount -gt 0) {
    exit 1
}
exit 0
