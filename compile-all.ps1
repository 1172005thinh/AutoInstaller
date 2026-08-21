[CmdletBinding()]
param(
    [string]$RootDir = '',
    [string]$CompilerPath = '',
    [switch]$IncludeMaster = $false,
    [switch]$DryRun = $false
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RootDir)) {
    if ($PSScriptRoot) {
        $RootDir = $PSScriptRoot
    } else {
        $RootDir = (Get-Location).Path
    }
}
$RootDir = (Resolve-Path -LiteralPath $RootDir).Path

# 1. Locate AutoIt3 compiler
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
    Write-Error "AutoIt3 compiler (Aut2exe_x64.exe / Aut2exe.exe) was not found in standard paths."
    exit 1
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " AutoIt Compilation Utility" -ForegroundColor Cyan
Write-Host " Compiler : $foundCompiler" -ForegroundColor Gray
Write-Host " Root Dir : $RootDir" -ForegroundColor Gray
if ($IncludeMaster) {
    Write-Host " Mode     : Compiling ALL .au3 files (including master installer)" -ForegroundColor Yellow
} else {
    Write-Host " Mode     : Compiling .au3 files (EXCLUDING master installer: install-apps.au3)" -ForegroundColor Green
}
Write-Host "======================================================================" -ForegroundColor Cyan

# 2. Discover all .au3 files
$allAu3 = Get-ChildItem -Path $RootDir -Filter '*.au3' -Recurse -File

# Master installer patterns to exclude by default
$masterPatterns = @('install-apps.au3', 'auto-installer.au3')

$targets = @()
foreach ($file in $allAu3) {
    $isMaster = $file.Name.ToLowerInvariant() -in $masterPatterns
    if ($isMaster -and -not $IncludeMaster) {
        Write-Host "  [SKIP MASTER] $($file.FullName)" -ForegroundColor DarkGray
        continue
    }
    $targets += $file
}

Write-Host "`nFound $($targets.Count) file(s) to compile:`n" -ForegroundColor White

$successCount = 0
$failCount = 0
$results = @()

foreach ($src in $targets) {
    $outExe = [System.IO.Path]::ChangeExtension($src.FullName, '.exe')
    $relSrc = $src.FullName.Replace($RootDir, '').TrimStart('\', '/')
    $relOut = $outExe.Replace($RootDir, '').TrimStart('\', '/')

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

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $proc = Start-Process -FilePath $foundCompiler -ArgumentList "/in `"$($src.FullName)`" /out `"$outExe`"" -NoNewWindow -PassThru -Wait
    $sw.Stop()

    if ($proc.ExitCode -eq 0 -and (Test-Path -LiteralPath $outExe)) {
        Write-Host ("  [SUCCESS] {0} -> {1} ({2} ms)" -f $relSrc, $relOut, $sw.ElapsedMilliseconds) -ForegroundColor Green
        $results += [PSCustomObject]@{
            Source  = $relSrc
            Output  = $relOut
            Status  = 'SUCCESS'
            TimeMs  = $sw.ElapsedMilliseconds
        }
        $successCount++
    } else {
        Write-Host ("  [FAILED]  {0} (ExitCode: {1})" -f $relSrc, $proc.ExitCode) -ForegroundColor Red
        $results += [PSCustomObject]@{
            Source  = $relSrc
            Output  = $relOut
            Status  = "FAILED ($($proc.ExitCode))"
            TimeMs  = $sw.ElapsedMilliseconds
        }
        $failCount++
    }
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host (" Compilation Summary: Total={0} | Success={1} | Failed={2}" -f $targets.Count, $successCount, $failCount) -ForegroundColor $(if ($failCount -eq 0) { 'Green' } else { 'Red' })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failCount -gt 0) {
    exit 1
}
exit 0
