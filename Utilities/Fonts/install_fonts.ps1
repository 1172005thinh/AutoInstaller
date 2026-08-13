param(
    [string]$FontDir,
    [string]$ResultFile,
    [string]$LogFile,
    [string]$CleanBroken = 'false'
)

# Parse CleanBroken as a bool (accepts "true"/"false"/"1"/"0")
$doClean = $CleanBroken -eq 'true' -or $CleanBroken -eq '1'

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$fontsDir = 'C:\Windows\Fonts'
$regPath  = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'

$installed = 0
$skipped   = 0
$failed    = 0
$broken    = [System.Collections.Generic.List[string]]::new()

function Write-Log {
    param([string]$msg)
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts] [Fonts] $msg"
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
    Write-Host $line
}

# Ensure log directory exists
$null = New-Item -ItemType Directory -Force -Path (Split-Path $LogFile)

Write-Log "INFO: Scanning font directory: $FontDir"

# Guard: directory must exist
if (-not (Test-Path $FontDir -PathType Container)) {
    Write-Log "INFO: Font directory not found: $FontDir. Exiting."
    "" | Set-Content -Path $ResultFile -Encoding UTF8
    exit 0
}

# Collect font files
$fontFiles = Get-ChildItem -Path $FontDir -File |
    Where-Object { $_.Extension -match '^\.(ttf|otf|ttc)$' }

if ($fontFiles.Count -eq 0) {
    Write-Log "INFO: No font files (.ttf/.otf/.ttc) found. Exiting."
    "" | Set-Content -Path $ResultFile -Encoding UTF8
    exit 0
}

Write-Log "INFO: Found $($fontFiles.Count) font file(s) to process."

# Load GDI+ once
Add-Type -AssemblyName System.Drawing

foreach ($file in $fontFiles) {
    $src   = $file.FullName
    $fname = $file.Name
    $dest  = Join-Path $fontsDir $fname

    # Validate font via GDI+ PrivateFontCollection
    $valid = $false
    $familyName = ''
    try {
        $pfc = New-Object System.Drawing.Text.PrivateFontCollection
        $pfc.AddFontFile($src)
        if ($pfc.Families.Count -gt 0) {
            $valid = $true
            $familyName = $pfc.Families[0].Name
        }
    } catch {
        $valid = $false
    }

    if (-not $valid) {
        Write-Log "SKIP (invalid/uninstallable): $fname"
        $broken.Add($src)
        $failed++
        continue
    }

    # Check if already installed (same file size = assume identical)
    if (Test-Path $dest) {
        $srcSize  = $file.Length
        $destSize = (Get-Item $dest).Length
        if ($srcSize -eq $destSize) {
            Write-Log "SKIP (already installed): $fname"
            $skipped++
            continue
        }
    }

    # Copy font file
    try {
        Copy-Item -Path $src -Destination $dest -Force
    } catch {
        Write-Log "FAIL (copy error): $fname - $_"
        $broken.Add($src)
        $failed++
        continue
    }

    # Build registry name
    $ext = $file.Extension.ToLower()
    $typeTag = switch ($ext) {
        '.ttf' { '(TrueType)' }
        '.otf' { '(OpenType)' }
        '.ttc' { '(TrueType)' }
        default { '' }
    }
    $regName = "$familyName $typeTag".Trim()

    # Register font
    try {
        Set-ItemProperty -Path $regPath -Name $regName -Value $fname -Type String
        Write-Log "OK: $fname -> $regName"
        $installed++
    } catch {
        Write-Log "WARN (registry): $fname copied but reg write failed: $_"
        $installed++
    }
}

# Write result summary
$summary = @"
installed=$installed
skipped=$skipped
failed=$failed
broken=$($broken -join '|')
"@
$summary | Set-Content -Path $ResultFile -Encoding UTF8

# Clean broken/invalid source files if requested
if ($doClean -and $broken.Count -gt 0) {
    Write-Log "INFO: Cleaning $($broken.Count) invalid/broken font file(s) from source..."
    foreach ($f in $broken) {
        try {
            Remove-Item $f -Force
            Write-Log "CLEAN: Deleted $f"
        } catch {
            Write-Log "WARN: Could not delete $f - $_"
        }
    }
}

# Broadcast WM_FONTCHANGE so running apps see new fonts immediately
$HWND_BROADCAST = [IntPtr]0xFFFF
$WM_FONTCHANGE  = 0x001D
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class WinMsg {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd, uint Msg, UIntPtr wParam, IntPtr lParam,
        uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
'@
$result = [UIntPtr]::Zero
[WinMsg]::SendMessageTimeout($HWND_BROADCAST, $WM_FONTCHANGE, [UIntPtr]::Zero, [IntPtr]::Zero, 2, 2000, [ref]$result) | Out-Null

Write-Log "INFO: Font installation complete. installed=$installed skipped=$skipped failed=$failed"
exit 0
