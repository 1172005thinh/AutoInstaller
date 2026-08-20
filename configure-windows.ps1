param(
    [string]$LogFile = 'C:\Auto-installer\configure-windows.log',
    [switch]$Disableexplorer,
    [switch]$Disabletaskbar,
    [switch]$Disabledesktop,
    [switch]$Disablesystem,
    [switch]$Disablestart_menu,
    [switch]$Disablecontrol_panel,
    [switch]$Disableregion,
    [switch]$Disablewallpaper
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$msg)
    $ts   = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts] [WinConfig] $msg"
    $null = New-Item -ItemType Directory -Force -Path (Split-Path $LogFile)
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
    Write-Host $line
}

function Set-RegValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
    if (-not (Test-Path $Path)) { $null = New-Item -Path $Path -Force }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
}

# 1. Explorer defaults
if (-not $Disableexplorer) {
Write-Log 'INFO: [1] Configuring Windows Explorer...'
$explorerAdv = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-RegValue $explorerAdv 'LaunchTo'    1 'DWord'
Set-RegValue $explorerAdv 'HideFileExt' 0 'DWord'
Write-Log 'INFO: [1] Explorer: LaunchTo=1 (This PC), HideFileExt=0 (show extensions).'
} # end explorer

# 2. Taskbar
if (-not $Disabletaskbar) {
Write-Log 'INFO: [2] Configuring taskbar...'
$searchKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
Set-RegValue $searchKey 'SearchboxTaskbarMode' 0 'DWord'
Set-RegValue $explorerAdv 'ShowCopilotButton' 0 'DWord'
Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Dsh' 'OpenOnHover' 0 'DWord'
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0 'DWord'
Write-Log 'INFO: [2] Taskbar: search hidden, Copilot hidden, Widgets disabled via GPO.'

$shell = New-Object -ComObject Shell.Application
$taskbarFolder = $shell.NameSpace("$env:AppData\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar")
if ($taskbarFolder) {
    foreach ($item in $taskbarFolder.Items()) {
        try {
            $item.InvokeVerb('taskbarunpin')
            Write-Log "INFO: [2] Unpinned existing taskbar item: $($item.Name)"
        } catch {}
    }
}

$pinTargets = [System.Collections.Generic.List[string]]::new()
$pinTargets.Add("$env:WinDir\explorer.exe") | Out-Null

$chromeExe = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromeExe)) { $chromeExe = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe" }
if (Test-Path $chromeExe) { $pinTargets.Add($chromeExe) | Out-Null }

$wordCand = Get-ChildItem 'C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($wordCand) { $pinTargets.Add($wordCand.FullName) | Out-Null }

$pptCand = Get-ChildItem 'C:\Program Files\Microsoft Office\root\Office16\POWERPNT.EXE' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($pptCand) { $pinTargets.Add($pptCand.FullName) | Out-Null }

$xlCand = Get-ChildItem 'C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($xlCand) { $pinTargets.Add($xlCand.FullName) | Out-Null }

$zaloExe = "$env:LOCALAPPDATA\Zalo\Zalo.exe"
if (-not (Test-Path $zaloExe)) { $zaloExe = "$env:LOCALAPPDATA\Programs\Zalo\Zalo.exe" }
if (Test-Path $zaloExe) { $pinTargets.Add($zaloExe) | Out-Null }

$pinnedCount = 0
foreach ($target in $pinTargets) {
    if (Test-Path $target) {
        $folder = $shell.NameSpace((Split-Path $target))
        $item = $folder.ParseName((Split-Path $target -Leaf))
        if ($item) {
            try {
                $item.InvokeVerb('taskbarpin')
                Write-Log "INFO: [2] Pinned to taskbar: $($item.Name)"
                $pinnedCount++
            } catch {
                Write-Log "WARN: [2] Failed to pin to taskbar: $($item.Name)"
            }
        }
    }
}
Write-Log "INFO: [2] Taskbar pinning complete. Pinned $pinnedCount app(s)."
} # end taskbar

# 3. Desktop icons
if (-not $Disabledesktop) {
Write-Log 'INFO: [3] Adding standard desktop icons...'
$desktopIconsKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel'
if (-not (Test-Path $desktopIconsKey)) { $null = New-Item -Path $desktopIconsKey -Force }
Set-ItemProperty -Path $desktopIconsKey -Name '{20D04FE0-3AEA-1069-A2D8-08002B30309D}' -Value 0 -Type DWord
Set-ItemProperty -Path $desktopIconsKey -Name '{59031A47-3F72-44A7-89C5-5595FE6B30EE}' -Value 0 -Type DWord
Set-ItemProperty -Path $desktopIconsKey -Name '{645FF040-5081-101B-9F08-00AA002F954E}' -Value 0 -Type DWord
Set-ItemProperty -Path $desktopIconsKey -Name '{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}' -Value 0 -Type DWord
Set-ItemProperty -Path $desktopIconsKey -Name '{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}' -Value 0 -Type DWord
Write-Log 'INFO: [3] Desktop icons: This PC, User Files, Recycle Bin, Control Panel, Network.'
} # end desktop

# Sort desktop by Type via Bags registry
try {
    $fvmKey = 'HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\1\Desktop'
    if (-not (Test-Path $fvmKey)) { $null = New-Item -Path $fvmKey -Force }
    Set-ItemProperty -Path $fvmKey -Name 'Sort' -Value ([byte[]](
        0x00,0x00,0x00,0x00,
        0x01,0x00,0x00,0x00,
        0x30,0xF1,0x25,0xB7,0x79,0x23,0xD0,0x11,0xBE,0x41,0x00,0xAA,0x00,0x6C,0x00,0x00,
        0x0A,0x00,0x00,0x00,
        0x01,0x00,0x00,0x00
    )) -Type Binary
    Write-Log 'INFO: [3] Desktop sort-by-type registry key set.'
} catch {
    Write-Log "WARN: [3] Could not set desktop sort: $($_.Exception.Message)"
}

# 4. System settings
if (-not $Disablesystem) {
Write-Log 'INFO: [4] Configuring system settings...'

$devKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'
Set-RegValue $devKey 'TaskbarEndTask' 1 'DWord'
Write-Log 'INFO: [4] End Task context menu enabled.'

$buildNumber = [int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber
if ($buildNumber -ge 26100) {
    Set-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo' 'Enabled' 3 'DWord'
    Write-Log "INFO: [4] Sudo inline enabled (build=$buildNumber)."
} else {
    Write-Log "INFO: [4] Sudo inline skipped (build $buildNumber is below 26100)."
}

$clipKey = 'HKCU:\SOFTWARE\Microsoft\Clipboard'
Set-RegValue $clipKey 'EnableClipboardHistory' 1 'DWord'
Write-Log 'INFO: [4] Clipboard history enabled.'

Write-Log 'INFO: [4] Configuring Power settings...'
try {
    powercfg /change monitor-timeout-ac 60
    powercfg /change monitor-timeout-dc 15
    Write-Log 'INFO: [4] Screen timeout applied (AC: 1h, DC: 15m).'
} catch {
    Write-Log "WARN: [4] Could not set powercfg: $_"
}

Write-Log 'INFO: [4] Disabling unwanted Startup apps...'
$allowed = @('UnikeyNT.exe', 'SecurityHealthSystray.exe', 'UnikeyNT', 'SecurityHealthSystray')
$runKeys = @(
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',
    'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
)
$startupApproved = @(
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run', 
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32'
)
for ($i = 0; $i -lt $runKeys.Count; $i++) {
    if (Test-Path $runKeys[$i]) {
        $items = Get-ItemProperty $runKeys[$i]
        foreach ($prop in $items.psobject.properties) {
            $name = $prop.Name
            if ($name -notin @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')) {
                $val = $prop.Value -as [string]
                $isAllowed = $false
                foreach ($a in $allowed) {
                    if ($val -match $a -or $name -match $a) { $isAllowed = $true; break }
                }
                if (-not $isAllowed) {
                    if (-not (Test-Path $startupApproved[$i])) { $null = New-Item -Path $startupApproved[$i] -Force }
                    Set-ItemProperty -Path $startupApproved[$i] -Name $name -Value ([byte[]](0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)) -Type Binary
                    Write-Log "INFO: [4] Disabled registry startup app: $name"
                }
            }
        }
    }
}

# Also process physical Startup folders
$startupFolders = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Startup"
)
foreach ($folder in $startupFolders) {
    if (Test-Path $folder) {
        Get-ChildItem -Path $folder -Filter "*.lnk" | ForEach-Object {
            $shortcutName = $_.Name
            $isAllowed = $false
            foreach ($a in $allowed) {
                if ($shortcutName -match $a) { $isAllowed = $true; break }
            }
            if (-not $isAllowed) {
                Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                Write-Log "INFO: [4] Deleted startup folder shortcut: $shortcutName"
            }
        }
    }
}

} # end system

# 5. Start menu
if (-not $Disablestart_menu) {
Write-Log 'INFO: [5] Configuring Start menu...'
Set-RegValue $explorerAdv 'Start_IrisRecommendations' 0 'DWord'
Set-RegValue $explorerAdv 'Start_ShowRecentList'       0 'DWord'
Set-RegValue $explorerAdv 'Start_TrackDocs'            0 'DWord'

if ($buildNumber -ge 26100) {
    Set-RegValue $explorerAdv 'Start_Layout' 1 'DWord'
    Write-Log 'INFO: [5] Start_Layout=1 (More Pins).'
} else {
    Write-Log "INFO: [5] Start_Layout skipped (build $buildNumber is below 26100)."
}

$startLayoutDir  = "$env:LOCALAPPDATA\Microsoft\Windows\Shell"
$startLayoutFile = Join-Path $startLayoutDir 'LayoutModification.json'
$null = New-Item -ItemType Directory -Force -Path $startLayoutDir

$currentLayoutJson = $null
if (Test-Path $startLayoutFile) {
    try { $currentLayoutJson = Get-Content $startLayoutFile -Raw | ConvertFrom-Json } catch {}
}
if ($null -eq $currentLayoutJson) {
    $currentLayoutJson = New-Object psobject
}

# Create pinnedFolders if missing
$hasPinnedFolders = $false
foreach ($prop in $currentLayoutJson.psobject.properties) {
    if ($prop.Name -eq 'pinnedFolders') { $hasPinnedFolders = $true; break }
}
if (-not $hasPinnedFolders) {
    $currentLayoutJson | Add-Member -MemberType NoteProperty -Name 'pinnedFolders' -Value @()
}

$settingsGuid = '{442F8D41-4C24-4FE5-82F6-FEB3E8F31C6C}'
$alreadyAdded = $false
foreach ($f in $currentLayoutJson.pinnedFolders) {
    if ($f.folderID -eq $settingsGuid) { $alreadyAdded = $true; break }
}

if (-not $alreadyAdded) {
    $newList = [System.Collections.ArrayList]@($currentLayoutJson.pinnedFolders)
    $null = $newList.Add(@{ folderID = $settingsGuid })
    $currentLayoutJson.pinnedFolders = $newList.ToArray()
    
    $currentLayoutJson | ConvertTo-Json -Depth 4 | Set-Content -Path $startLayoutFile -Encoding UTF8
    Write-Log 'INFO: [5] Settings folder added to Start pinned folders.'
} else {
    Write-Log 'INFO: [5] Settings folder already pinned in Start.'
}
Write-Log 'INFO: [5] Start menu recommendations disabled.'
} # end start_menu

# 6. Control Panel large icons
if (-not $Disablecontrol_panel) {
Write-Log 'INFO: [6] Setting Control Panel to large icons view...'
$cpKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel'
Set-RegValue $cpKey 'AllItemsIconView' 1 'DWord'
Set-RegValue $cpKey 'StartupPage'      1 'DWord'
Write-Log 'INFO: [6] Control Panel: large icons, all items view.'
} # end control_panel

# 7. Region: Vietnamese format
if (-not $Disableregion) {
Write-Log 'INFO: [7] Setting region format to Vietnamese (vi-VN)...'
$intlKey = 'HKCU:\Control Panel\International'
Set-RegValue $intlKey 'Locale'          '0000042A' 'String'
Set-RegValue $intlKey 'LocaleName'      'vi-VN'    'String'
Set-RegValue $intlKey 'sLanguage'       'VIT'      'String'
Set-RegValue $intlKey 'sCountry'        'Viet Nam' 'String'
Set-RegValue $intlKey 'iCountry'        '84'       'String'
Set-RegValue $intlKey 'sLongDate'       'dddd, d MMMM, yyyy' 'String'
Set-RegValue $intlKey 'sShortDate'      'dd/MM/yyyy'         'String'
Set-RegValue $intlKey 'sYearMonth'      'MMMM yyyy'          'String'
Set-RegValue $intlKey 'sTimeFormat'     'h:mm:ss tt'         'String'
Set-RegValue $intlKey 'sShortTime'      'h:mm tt'            'String'
Set-RegValue $intlKey 'iFirstDayOfWeek' '0'                  'String'
Set-RegValue $intlKey 'iMeasure'        '0'                  'String'
Set-RegValue $intlKey 'sCurrency'       ([char]0x20AB)       'String'
Set-RegValue $intlKey 'sDecimal'        ','                  'String'
Set-RegValue $intlKey 'sThousand'       '.'                  'String'
Set-RegValue $intlKey 'iDigits'         '2'                  'String'
Set-RegValue 'HKCU:\Control Panel\International\Geo' 'Nation' '251' 'String'
Write-Log 'INFO: [7] Region format set to Vietnamese (vi-VN).'

# Trigger Windows Time (w32time) sync
try {
    Start-Service w32time -ErrorAction SilentlyContinue
    w32tm /resync /nowait | Out-Null
    Write-Log 'INFO: [7] Triggered Windows Time synchronization (w32tm).'
} catch {
    Write-Log "WARN: [7] Could not trigger time sync: $($_.Exception.Message)"
}
} # end region

# 8. Wallpaper
if (-not $Disablewallpaper) {
Write-Log 'INFO: [8] Setting Light theme wallpaper...'
Set-RegValue 'HKCU:\Control Panel\Desktop' 'Wallpaper' 'C:\Windows\Web\Wallpaper\Windows\img0.jpg' 'String'
try {
    $csharp_wp = @'
using System;
using System.Runtime.InteropServices;
public class WP {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
    Add-Type -TypeDefinition $csharp_wp
    [WP]::SystemParametersInfo(20, 0, 'C:\Windows\Web\Wallpaper\Windows\img0.jpg', 3) | Out-Null
    Write-Log 'INFO: [8] Wallpaper applied.'
} catch {}


} # end wallpaper
# Restart Explorer to apply shell settings
Write-Log 'INFO: Restarting Explorer to apply shell settings...'
try {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 2000
    Start-Process explorer -ErrorAction SilentlyContinue
    Write-Log 'INFO: Explorer restarted.'
} catch {
    Write-Log "WARN: Could not restart Explorer: $($_.Exception.Message)"
}

Write-Log 'INFO: [3] Sorting desktop icons silently via WM_COMMAND...'
try {
    $code = @"
using System;
using System.Runtime.InteropServices;

public class DesktopManager
{
    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    private const uint WM_COMMAND = 0x0111;
    private const int SORT_BY_ITEM_TYPE = 31494;

    public static void SortByType()
    {
        IntPtr hShellView = IntPtr.Zero;
        
        IntPtr hProgman = FindWindow("Progman", null);
        if (hProgman != IntPtr.Zero)
        {
            hShellView = FindWindowEx(hProgman, IntPtr.Zero, "SHELLDLL_DefView", null);
        }

        if (hShellView == IntPtr.Zero)
        {
            EnumWindows((hwnd, lParam) =>
            {
                IntPtr child = FindWindowEx(hwnd, IntPtr.Zero, "SHELLDLL_DefView", null);
                if (child != IntPtr.Zero)
                {
                    hShellView = child;
                    return false;
                }
                return true;
            }, IntPtr.Zero);
        }

        if (hShellView != IntPtr.Zero)
        {
            SendMessage(hShellView, WM_COMMAND, new IntPtr(SORT_BY_ITEM_TYPE), IntPtr.Zero);
        }
    }
}
"@
    Add-Type -TypeDefinition $code -ErrorAction Stop
    [DesktopManager]::SortByType()
    Write-Log 'INFO: [3] Desktop icons sorted by Type.'
} catch {
    Write-Log "WARN: [3] Failed to sort desktop via C# API: $($_.Exception.Message)"
}

Write-Log 'INFO: --- VALIDATION ---'
$valFails = 0

function Test-RegValue {
    param($Path, $Name, $Expected)
    $val = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
    if ($val -eq $Expected) { Write-Log "INFO: [VALIDATION] PASS: $Name = $val"; return $true }
    Write-Log "ERROR: [VALIDATION] FAIL: $Name = $val (Expected: $Expected)"; return $false
}

if (-not (Test-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0)) { $valFails++ }
if (-not (Test-RegValue 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode' 0)) { $valFails++ }
if (-not (Test-RegValue 'HKCU:\SOFTWARE\Microsoft\Clipboard' 'EnableClipboardHistory' 1)) { $valFails++ }

$pcfg = powercfg /q SCHEME_CURRENT SUB_VIDEO VIDEOIDLE
if ($pcfg -match 'Current AC Power Setting Index: 0x00000e10') { Write-Log 'INFO: [VALIDATION] PASS: Monitor Timeout AC' }
else { Write-Log 'ERROR: [VALIDATION] FAIL: Monitor Timeout AC'; $valFails++ }

if ($valFails -eq 0) { Write-Log 'INFO: Windows configuration complete and verified.' }
else { Write-Log "WARN: Windows configuration finished with $valFails validation failure(s)." }
exit 0
