param(
    [string]$IniFile = "$PSScriptRoot\configure-windows.ini",
    [string]$LogFile = 'C:\Auto-installer\configure-windows.log'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ==============================================================================
# Helper Functions
# ==============================================================================

function Write-Log {
    param([string]$msg)
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts] [WinConfig] $msg"
    try {
        $logDir = Split-Path -Path $LogFile -Parent
        if ($logDir -and -not (Test-Path -LiteralPath $logDir)) {
            $null = New-Item -ItemType Directory -Force -Path $logDir -ErrorAction SilentlyContinue
        }
        Add-Content -Path $LogFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {}
    Write-Host $line
}

function Set-RegValue {
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type = 'DWord'
    )
    try {
        if (-not (Test-Path -LiteralPath $Path)) {
            $null = New-Item -Path $Path -Force -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Log "WARN: Could not set registry value $Path\$Name : $($_.Exception.Message)"
    }
}

function Parse-IniFile {
    param([string]$Path)
    $ini = @{}
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Log "WARN: INI file not found: $Path. Using built-in defaults."
        return $ini
    }
    $currentSection = 'general'
    $ini[$currentSection] = @{}
    
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith('#') -or $trimmed.StartsWith(';')) {
            continue
        }
        if ($trimmed.StartsWith('[') -and $trimmed.EndsWith(']')) {
            $currentSection = $trimmed.Substring(1, $trimmed.Length - 2).Trim().ToLowerInvariant()
            if (-not $ini.ContainsKey($currentSection)) {
                $ini[$currentSection] = @{}
            }
            continue
        }
        $eqIdx = $trimmed.IndexOf('=')
        if ($eqIdx -gt 0) {
            $key = $trimmed.Substring(0, $eqIdx).Trim().ToLowerInvariant()
            $val = $trimmed.Substring($eqIdx + 1).Trim()
            # Strip trailing inline comments and semicolons
            $semiIdx = $val.IndexOf(';')
            if ($semiIdx -ge 0) {
                $val = $val.Substring(0, $semiIdx).Trim()
            }
            # Strip outer quotes if present
            if (($val.StartsWith('"') -and $val.EndsWith('"')) -or ($val.StartsWith("'") -and $val.EndsWith("'"))) {
                $val = $val.Substring(1, $val.Length - 2)
            }
            $ini[$currentSection][$key] = $val
        }
    }
    return $ini
}

function Get-IniValue {
    param(
        [hashtable]$Ini,
        [string]$Section,
        [string]$Key,
        [string]$Default = ''
    )
    $secKey = $Section.ToLowerInvariant()
    $k = $Key.ToLowerInvariant()
    if ($Ini.ContainsKey($secKey) -and $Ini[$secKey].ContainsKey($k)) {
        return $Ini[$secKey][$k]
    }
    return $Default
}

function Get-IniBool {
    param(
        [hashtable]$Ini,
        [string]$Section,
        [string]$Key,
        [bool]$Default = $false
    )
    $val = Get-IniValue -Ini $Ini -Section $Section -Key $Key -Default ($Default.ToString().ToLower())
    return ($val.ToLowerInvariant() -in @('true', '1', 'yes', 'enable', 'enabled'))
}

# Resolve target application executable or shortcut
function Resolve-AppPath {
    param([string]$AppKey)
    $key = $AppKey.Trim().ToLowerInvariant()
    switch ($key) {
        'explorer' { return "$env:WinDir\explorer.exe" }
        'chrome' {
            $c = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
            if (-not (Test-Path -LiteralPath $c)) { $c = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe" }
            if (Test-Path -LiteralPath $c) { return $c }
        }
        'edge' {
            $e = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
            if (-not (Test-Path -LiteralPath $e)) { $e = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe" }
            if (Test-Path -LiteralPath $e) { return $e }
        }
        'word' {
            $w = Get-ChildItem 'C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE' -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($w) { return $w.FullName }
        }
        'excel' {
            $x = Get-ChildItem 'C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE' -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($x) { return $x.FullName }
        }
        'powerpoint' {
            $p = Get-ChildItem 'C:\Program Files\Microsoft Office\root\Office16\POWERPNT.EXE' -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($p) { return $p.FullName }
        }
        'outlook' {
            $o = Get-ChildItem 'C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE' -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($o) { return $o.FullName }
        }
        'onenote' {
            $n = Get-ChildItem 'C:\Program Files\Microsoft Office\root\Office16\ONENOTE.EXE' -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($n) { return $n.FullName }
        }
        'notepadpp' {
            $npp = "$env:ProgramFiles\Notepad++\notepad++.exe"
            if (-not (Test-Path -LiteralPath $npp)) { $npp = "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe" }
            if (Test-Path -LiteralPath $npp) { return $npp }
        }
        'vscode' {
            $vsc = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
            if (-not (Test-Path -LiteralPath $vsc)) { $vsc = "$env:ProgramFiles\Microsoft VS Code\Code.exe" }
            if (Test-Path -LiteralPath $vsc) { return $vsc }
        }
        'zalo' {
            $z = "$env:LOCALAPPDATA\Zalo\Zalo.exe"
            if (-not (Test-Path -LiteralPath $z)) { $z = "$env:LOCALAPPDATA\Programs\Zalo\Zalo.exe" }
            if (Test-Path -LiteralPath $z) { return $z }
        }
        'powershell' {
            return "$env:WinDir\System32\WindowsPowerShell\v1.0\powershell.exe"
        }
        'settings' {
            return 'windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel'
        }
        default {
            if (Test-Path -LiteralPath $AppKey) {
                return (Resolve-Path -LiteralPath $AppKey).Path
            }
        }
    }
    return $null
}

# ==============================================================================
# Initialization
# ==============================================================================

Write-Log "======================================================================"
Write-Log "Starting Windows Post-Installation Configuration Engine"
Write-Log "INI File: $IniFile"

$iniConfig = Parse-IniFile -Path $IniFile

# Override LogFile if specified in INI
$iniLog = Get-IniValue -Ini $iniConfig -Section 'general' -Key 'log_path' -Default ''
if ($iniLog -ne '') {
    $LogFile = $iniLog
}

$buildNumber = 0
try {
    $buildNumber = [int](Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber
} catch {}
Write-Log "OS Build Number: $buildNumber"

$explorerAdv = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

# ==============================================================================
# 1, 2, 3. File Explorer Configuration
# ==============================================================================
Write-Log "INFO: [1..3] Configuring File Explorer..."

# 1. Hidden items
$hiddenMode = Get-IniValue -Ini $iniConfig -Section 'explorer' -Key 'hidden_items' -Default 'HideAll'
switch -Regex ($hiddenMode) {
    '^(show|showall)$' {
        Set-RegValue $explorerAdv 'Hidden' 1 'DWord'
        Set-RegValue $explorerAdv 'ShowSuperHidden' 0 'DWord'
        Write-Log "INFO: [1] Explorer: Hidden items visible (Hidden=1, ShowSuperHidden=0)."
    }
    '^(hidehidden)$' {
        Set-RegValue $explorerAdv 'Hidden' 2 'DWord'
        Set-RegValue $explorerAdv 'ShowSuperHidden' 0 'DWord'
        Write-Log "INFO: [1] Explorer: Hidden items hidden (Hidden=2)."
    }
    default {
        # HideAll (Hidden & System items)
        Set-RegValue $explorerAdv 'Hidden' 2 'DWord'
        Set-RegValue $explorerAdv 'ShowSuperHidden' 0 'DWord'
        Write-Log "INFO: [1] Explorer: Hidden and protected operating system files hidden (Hidden=2, ShowSuperHidden=0)."
    }
}

# 2. Show file extensions
$showExt = Get-IniBool -Ini $iniConfig -Section 'explorer' -Key 'show_extensions' -Default $true
if ($showExt) {
    Set-RegValue $explorerAdv 'HideFileExt' 0 'DWord'
    Write-Log "INFO: [2] Explorer: Show file extensions enabled (HideFileExt=0)."
} else {
    Set-RegValue $explorerAdv 'HideFileExt' 1 'DWord'
    Write-Log "INFO: [2] Explorer: Show file extensions disabled (HideFileExt=1)."
}

# 3. Launch To (This PC vs Quick Access vs Downloads)
$launchTo = Get-IniValue -Ini $iniConfig -Section 'explorer' -Key 'launch_to' -Default 'ThisPC'
switch -Regex ($launchTo) {
    '^(quickaccess|home)$' {
        Set-RegValue $explorerAdv 'LaunchTo' 2 'DWord'
        Write-Log "INFO: [3] Explorer: Open to Home / Quick Access (LaunchTo=2)."
    }
    '^(downloads)$' {
        Set-RegValue $explorerAdv 'LaunchTo' 3 'DWord'
        Write-Log "INFO: [3] Explorer: Open to Downloads (LaunchTo=3)."
    }
    default {
        Set-RegValue $explorerAdv 'LaunchTo' 1 'DWord'
        Write-Log "INFO: [3] Explorer: Open to This PC (LaunchTo=1)."
    }
}

# ==============================================================================
# 4, 5, 6, 7, 8, 9, 10. Taskbar Configuration
# ==============================================================================
Write-Log "INFO: [4..10] Configuring Taskbar..."

# 4. End Task context menu
$endTask = Get-IniBool -Ini $iniConfig -Section 'taskbar' -Key 'end_task' -Default $true
$devKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'
Set-RegValue $devKey 'TaskbarEndTask' ($(if ($endTask) { 1 } else { 0 })) 'DWord'
Write-Log "INFO: [4] Taskbar: End Task context menu = $endTask (TaskbarEndTask=$(if ($endTask) { 1 } else { 0 }))."

# 5. Search box mode
$searchMode = Get-IniValue -Ini $iniConfig -Section 'taskbar' -Key 'search_mode' -Default 'Hide'
$searchKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
switch -Regex ($searchMode) {
    '^(icon|searchicon)$' {
        Set-RegValue $searchKey 'SearchboxTaskbarMode' 1 'DWord'
        Write-Log "INFO: [5] Taskbar: Search Icon only (SearchboxTaskbarMode=1)."
    }
    '^(full|box|searchbox)$' {
        Set-RegValue $searchKey 'SearchboxTaskbarMode' 2 'DWord'
        Write-Log "INFO: [5] Taskbar: Search Box (SearchboxTaskbarMode=2)."
    }
    '^(iconandlabel)$' {
        Set-RegValue $searchKey 'SearchboxTaskbarMode' 3 'DWord'
        Write-Log "INFO: [5] Taskbar: Search Icon and Label (SearchboxTaskbarMode=3)."
    }
    default {
        Set-RegValue $searchKey 'SearchboxTaskbarMode' 0 'DWord'
        Write-Log "INFO: [5] Taskbar: Search Hidden (SearchboxTaskbarMode=0)."
    }
}

# 8. Widgets (News and Interests)
$widgetsEnabled = Get-IniBool -Ini $iniConfig -Section 'taskbar' -Key 'widgets' -Default $false
if ($widgetsEnabled) {
    Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 1 'DWord'
    Set-RegValue $explorerAdv 'TaskbarDa' 1 'DWord'
    Write-Log "INFO: [8] Taskbar: Widgets enabled."
} else {
    Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0 'DWord'
    Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Dsh' 'OpenOnHover' 0 'DWord'
    Set-RegValue $explorerAdv 'TaskbarDa' 0 'DWord'
    Write-Log "INFO: [8] Taskbar: Widgets disabled (GPO AllowNewsAndInterests=0, TaskbarDa=0)."
}

# 9. Alignment (Left vs Center)
$alignment = Get-IniValue -Ini $iniConfig -Section 'taskbar' -Key 'alignment' -Default 'Left'
if ($alignment.ToLowerInvariant() -eq 'center') {
    Set-RegValue $explorerAdv 'TaskbarAl' 1 'DWord'
    Write-Log "INFO: [9] Taskbar: Center aligned (TaskbarAl=1)."
} else {
    Set-RegValue $explorerAdv 'TaskbarAl' 0 'DWord'
    Write-Log "INFO: [9] Taskbar: Left aligned (TaskbarAl=0)."
}

# 10. Taskview button
$taskview = Get-IniValue -Ini $iniConfig -Section 'taskbar' -Key 'taskview' -Default 'Hide'
if ($taskview.ToLowerInvariant() -eq 'show') {
    Set-RegValue $explorerAdv 'ShowTaskViewButton' 1 'DWord'
    Write-Log "INFO: [10] Taskbar: Task View button shown (ShowTaskViewButton=1)."
} else {
    Set-RegValue $explorerAdv 'ShowTaskViewButton' 0 'DWord'
    Write-Log "INFO: [10] Taskbar: Task View button hidden (ShowTaskViewButton=0)."
}

# Hide Copilot button by default
Set-RegValue $explorerAdv 'ShowCopilotButton' 0 'DWord'

# 6 & 7. Taskbar Unpin Defaults & Pinned Apps
$unpinDefaults = Get-IniBool -Ini $iniConfig -Section 'taskbar' -Key 'unpin_defaults' -Default $true
$taskbarPinsStr = Get-IniValue -Ini $iniConfig -Section 'taskbar' -Key 'pins' -Default 'explorer;chrome;word;excel;powerpoint;zalo'

$shell = New-Object -ComObject Shell.Application
$taskbarFolder = $shell.NameSpace("$env:AppData\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar")

if ($unpinDefaults -and $taskbarFolder) {
    foreach ($item in $taskbarFolder.Items()) {
        try {
            $item.InvokeVerb('taskbarunpin')
            Write-Log "INFO: [6] Unpinned default taskbar shortcut: $($item.Name)"
        } catch {}
    }
}

# Pin configured apps
$pinItems = $taskbarPinsStr.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
$pinnedCount = 0
foreach ($pKey in $pinItems) {
    $target = Resolve-AppPath -AppKey $pKey
    if ($target -eq 'windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel') {
        Write-Log "INFO: [7] Settings app pinned layout registered."
        $pinnedCount++
    } elseif ($target -and (Test-Path -LiteralPath $target)) {
        try {
            $dir = Split-Path -Path $target -Parent
            $leaf = Split-Path -Path $target -Leaf
            $folder = $shell.NameSpace($dir)
            $item = $folder.ParseName($leaf)
            if ($item) {
                $item.InvokeVerb('taskbarpin')
                Write-Log "INFO: [7] Pinned to taskbar: $leaf"
                $pinnedCount++
            } else {
                Write-Log "INFO: [7] Taskbar pin skipped (item not accessible in namespace): $pKey"
            }
        } catch {
            Write-Log "WARN: [7] Could not pin $target to taskbar: $($_.Exception.Message)"
        }
    } else {
        Write-Log "INFO: [7] Taskbar pin skipped (app not installed/not found): $pKey"
    }
}
Write-Log "INFO: [6..7] Taskbar pinning processed. Pinned $pinnedCount item(s)."

# ==============================================================================
# 11, 12, 13, 22. Start Menu Configuration
# ==============================================================================
Write-Log "INFO: [11..13, 22] Configuring Start Menu..."

# 11. Disable Bing search in Start Menu
$disableBing = Get-IniBool -Ini $iniConfig -Section 'start_menu' -Key 'disable_bing_search' -Default $true
if ($disableBing) {
    Set-RegValue 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1 'DWord'
    Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0 'DWord'
    Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent' 0 'DWord'
    Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'DisableWebSearch' 1 'DWord'
    Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'ConnectedSearchUseWeb' 0 'DWord'
    Write-Log "INFO: [11] Start Menu: Bing web search results disabled."
}

# Recommendations and Layout
Set-RegValue $explorerAdv 'Start_IrisRecommendations' 0 'DWord'
Set-RegValue $explorerAdv 'Start_ShowRecentList' 0 'DWord'
Set-RegValue $explorerAdv 'Start_TrackDocs' 0 'DWord'
if ($buildNumber -ge 26100) {
    Set-RegValue $explorerAdv 'Start_Layout' 1 'DWord'
}

# 12 & 13. Start Menu Pins (ConfigureStartPins JSON policy)
$removeDefaultStartPins = Get-IniBool -Ini $iniConfig -Section 'start_menu' -Key 'remove_default_pins' -Default $true
$startPinsStr = Get-IniValue -Ini $iniConfig -Section 'start_menu' -Key 'pins' -Default 'edge;explorer;settings;chrome;notepadpp'

if ($buildNumber -ge 20000) {
    $pinList = @()
    $startPinItems = $startPinsStr.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
    foreach ($sp in $startPinItems) {
        $spKey = $sp.Trim().ToLowerInvariant()
        $lnkPath = $null
        $isPackaged = $false

        switch ($spKey) {
            'edge' {
                $lnkPath = "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
                if (-not (Test-Path -LiteralPath $lnkPath)) {
                    $lnkPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
                }
            }
            'explorer' {
                $lnkPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\File Explorer.lnk"
                if (-not (Test-Path -LiteralPath $lnkPath)) {
                    $lnkPath = "$env:SystemRoot\explorer.exe"
                }
            }
            'settings' {
                $isPackaged = $true
                $pinList += @{ packagedAppId = "windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel" }
                Write-Log "INFO: [13] Start Menu pin registered: Settings"
            }
            'chrome' {
                $lnkPath = "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk"
                if (-not (Test-Path -LiteralPath $lnkPath)) {
                    $lnkPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk"
                }
            }
            'notepadpp' {
                $lnkPath = "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Notepad++.lnk"
                if (-not (Test-Path -LiteralPath $lnkPath)) {
                    $lnkPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Notepad++.lnk"
                }
            }
            default {
                $resolved = Resolve-AppPath -AppKey $sp
                if ($resolved) {
                    $lnkPath = $resolved
                }
            }
        }

        if (-not $isPackaged) {
            if ($lnkPath -and (Test-Path -LiteralPath $lnkPath)) {
                # Convert physical path back to environment variable template if applicable
                $envLnk = $lnkPath.Replace($env:ALLUSERSPROFILE, '%ALLUSERSPROFILE%').Replace($env:APPDATA, '%APPDATA%')
                $pinList += @{ desktopAppLink = $envLnk }
                Write-Log "INFO: [13] Start Menu pin added: $sp ($lnkPath)"
            } else {
                Write-Log "INFO: [13] Start Menu pin skipped (app not installed/shortcut not found): $sp"
            }
        }
    }
    
    $jsonObj = @{ pinnedList = $pinList }
    $jsonStr = $jsonObj | ConvertTo-Json -Depth 3 -Compress
    
    $polKey = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start'
    if (-not (Test-Path -LiteralPath $polKey)) {
        $null = New-Item -Path $polKey -Force -ErrorAction SilentlyContinue
    }
    Set-ItemProperty -LiteralPath $polKey -Name 'ConfigureStartPins' -Value $jsonStr -Type 'String' -Force -ErrorAction SilentlyContinue
    Write-Log "INFO: [12..13] Start Menu: ConfigureStartPins applied with $($pinList.Count) app(s)."
}

# 22. Start Menu Folders beside Power Button
$startFoldersStr = Get-IniValue -Ini $iniConfig -Section 'start_menu' -Key 'folders' -Default 'Settings;File Explorer;Downloads'
$folderList = $startFoldersStr.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim().ToLowerInvariant() }

$folderMappings = @{
    'settings'        = 'Start_ShowSettings'
    'file explorer'   = 'Start_ShowFileExplorer'
    'documents'       = 'Start_ShowDocuments'
    'downloads'       = 'Start_ShowDownloads'
    'music'           = 'Start_ShowMusic'
    'pictures'        = 'Start_ShowPictures'
    'videos'          = 'Start_ShowVideos'
    'network'         = 'Start_ShowNetwork'
    'personal folder' = 'Start_ShowUser'
}

foreach ($fName in $folderMappings.Keys) {
    $regName = $folderMappings[$fName]
    $enableFolder = ($fName -in $folderList)
    Set-RegValue $explorerAdv $regName ($(if ($enableFolder) { 1 } else { 0 })) 'DWord'
}
Write-Log "INFO: [22] Start Menu: Folder shortcuts configured ($startFoldersStr)."

# ==============================================================================
# 14, 15, 16, 17, 18, 19, 23, 26, 27. System Settings Configuration
# ==============================================================================
Write-Log "INFO: [14..19, 23, 26, 27] Configuring System Settings..."

# 14. Disable Smart App Control
$disableSAC = Get-IniBool -Ini $iniConfig -Section 'system' -Key 'disable_smart_app_control' -Default $true
if ($disableSAC) {
    Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' 'VerifiedAndReputablePolicyState' 0 'DWord'
    Write-Log "INFO: [14] Smart App Control disabled (VerifiedAndReputablePolicyState=0)."
}

# 15. Enable Long Paths
$enableLongPaths = Get-IniBool -Ini $iniConfig -Section 'system' -Key 'enable_long_paths' -Default $true
if ($enableLongPaths) {
    Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'LongPathsEnabled' 1 'DWord'
    Write-Log "INFO: [15] Win32 Long Paths (>260 chars) enabled (LongPathsEnabled=1)."
}

# 16. Enable Remote Desktop (RDP)
$enableRDP = Get-IniBool -Ini $iniConfig -Section 'system' -Key 'enable_rdp' -Default $true
if ($enableRDP) {
    Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' 'fDenyTSConnections' 0 'DWord'
    Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' 'UserAuthentication' 1 'DWord'
    try {
        netsh.exe advfirewall firewall set rule group="@FirewallAPI.dll,-28752" new enable=Yes | Out-Null
        Write-Log "INFO: [16] Remote Desktop (RDP) enabled and firewall rule allowed."
    } catch {
        Write-Log "WARN: [16] Could not enable RDP firewall rule: $($_.Exception.Message)"
    }
}

# 17. Allow PowerShell Script Execution
$allowPS = Get-IniBool -Ini $iniConfig -Section 'system' -Key 'allow_powershell_scripts' -Default $true
if ($allowPS) {
    try {
        Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force
        Set-RegValue 'HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell' 'ExecutionPolicy' 'RemoteSigned' 'String'
        Write-Log "INFO: [17] PowerShell ExecutionPolicy set to RemoteSigned."
    } catch {
        Write-Log "WARN: [17] Could not set PowerShell ExecutionPolicy: $($_.Exception.Message)"
    }
}

# 18. Hide Microsoft Edge First Run Experience
$hideEdgeFirstRun = Get-IniBool -Ini $iniConfig -Section 'system' -Key 'hide_edge_first_run' -Default $true
if ($hideEdgeFirstRun) {
    Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'HideFirstRunExperience' 1 'DWord'
    Write-Log "INFO: [18] Edge First Run Experience hidden."
}

# 19. Delete empty C:\Windows.old folder
$deleteWinOld = Get-IniBool -Ini $iniConfig -Section 'system' -Key 'delete_windows_old' -Default $true
if ($deleteWinOld) {
    $winOldPath = 'C:\Windows.old'
    if (Test-Path -LiteralPath $winOldPath) {
        $items = Get-ChildItem -LiteralPath $winOldPath -Recurse -File -ErrorAction SilentlyContinue
        if ($null -eq $items -or $items.Count -eq 0) {
            Remove-Item -LiteralPath $winOldPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "INFO: [19] Deleted empty C:\Windows.old folder."
        } else {
            Write-Log "INFO: [19] C:\Windows.old contains files, preserving."
        }
    }
}

# 23. Sticky Keys Popup (5x Shift)
$stickyKeys = Get-IniBool -Ini $iniConfig -Section 'system' -Key 'sticky_keys' -Default $false
if (-not $stickyKeys) {
    # 506 (0x1FA) disables the shortcut hotkey
    Set-RegValue 'HKCU:\Control Panel\Accessibility\StickyKeys' 'Flags' '506' 'String'
    Set-RegValue 'HKCU:\Control Panel\Accessibility\ToggleKeys' 'Flags' '58' 'String'
    Set-RegValue 'HKCU:\Control Panel\Accessibility\FilterKeys' 'Flags' '122' 'String'
    Set-RegValue 'HKU:\.DEFAULT\Control Panel\Accessibility\StickyKeys' 'Flags' '10' 'String'
    Write-Log "INFO: [23] Sticky keys hotkey popup disabled (Flags=506/10)."
} else {
    Set-RegValue 'HKCU:\Control Panel\Accessibility\StickyKeys' 'Flags' '510' 'String'
    Write-Log "INFO: [23] Sticky keys hotkey enabled (Flags=510)."
}

# 26. Sudo Mode
$sudoMode = Get-IniValue -Ini $iniConfig -Section 'system' -Key 'sudo_mode' -Default 'Inline'
if ($buildNumber -ge 26100) {
    $sudoVal = switch -Regex ($sudoMode) {
        '^(newwindow)$'   { 1 }
        '^(disableinput)$' { 2 }
        '^(disable|off)$'  { 0 }
        default           { 3 } # Inline
    }
    Set-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo' 'Enabled' $sudoVal 'DWord'
    Write-Log "INFO: [26] Sudo mode configured = $sudoMode (Enabled=$sudoVal)."
} else {
    Write-Log "INFO: [26] Sudo skipped (build $buildNumber is below 26100)."
}

# 27. Clipboard History (Win+V)
$clipHist = Get-IniBool -Ini $iniConfig -Section 'system' -Key 'clipboard_history' -Default $true
Set-RegValue 'HKCU:\SOFTWARE\Microsoft\Clipboard' 'EnableClipboardHistory' ($(if ($clipHist) { 1 } else { 0 })) 'DWord'
Write-Log "INFO: [27] Clipboard history = $clipHist (EnableClipboardHistory=$(if ($clipHist) { 1 } else { 0 }))."

# Power Monitor Timeouts
try {
    powercfg /change monitor-timeout-ac 60
    powercfg /change monitor-timeout-dc 15
    Write-Log "INFO: Power screen timeout set (AC: 60m, DC: 15m)."
} catch {}

# Startup apps cleanup
$allowedStartup = @('UnikeyNT.exe', 'SecurityHealthSystray.exe', 'UnikeyNT', 'SecurityHealthSystray')
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
    if (Test-Path -LiteralPath $runKeys[$i]) {
        $items = Get-ItemProperty -LiteralPath $runKeys[$i]
        foreach ($prop in $items.psobject.properties) {
            $name = $prop.Name
            if ($name -notin @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')) {
                $val = $prop.Value -as [string]
                $isAllowed = $false
                foreach ($a in $allowedStartup) {
                    if ($val -match $a -or $name -match $a) { $isAllowed = $true; break }
                }
                if (-not $isAllowed) {
                    if (-not (Test-Path -LiteralPath $startupApproved[$i])) {
                        $null = New-Item -Path $startupApproved[$i] -Force -ErrorAction SilentlyContinue
                    }
                    Set-ItemProperty -LiteralPath $startupApproved[$i] -Name $name -Value ([byte[]](0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)) -Type Binary -Force -ErrorAction SilentlyContinue
                    Write-Log "INFO: Disabled startup application: $name"
                }
            }
        }
    }
}

# ==============================================================================
# 20, 21. Desktop Icons & Sorting
# ==============================================================================
Write-Log "INFO: [20..21] Configuring Desktop Icons & Sorting..."

# 20. Desktop Icons
$desktopIconsStr = Get-IniValue -Ini $iniConfig -Section 'desktop' -Key 'icons' -Default "This PC;Recycle Bin;User's Files;Network;Control Panel"
$chosenIcons = $desktopIconsStr.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim().ToLowerInvariant() }

$desktopGuids = @{
    'this pc'        = '{20D04FE0-3AEA-1069-A2D8-08002B30309D}'
    "user's files"   = '{59031A47-3F72-44A7-89C5-5595FE6B30EE}'
    'user files'     = '{59031A47-3F72-44A7-89C5-5595FE6B30EE}'
    'recycle bin'    = '{645FF040-5081-101B-9F08-00AA002F954E}'
    'control panel'  = '{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}'
    'network'        = '{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}'
}

$desktopKeys = @(
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu'
)

foreach ($dk in $desktopKeys) {
    if (-not (Test-Path -LiteralPath $dk)) {
        $null = New-Item -Path $dk -Force -ErrorAction SilentlyContinue
    }
    foreach ($iconName in $desktopGuids.Keys) {
        $guid = $desktopGuids[$iconName]
        $show = ($iconName -in $chosenIcons)
        # 0 = Show, 1 = Hide
        Set-ItemProperty -LiteralPath $dk -Name $guid -Value ($(if ($show) { 0 } else { 1 })) -Type DWord -Force -ErrorAction SilentlyContinue
    }
}
Write-Log "INFO: [20] Desktop icons configured ($desktopIconsStr)."

# ==============================================================================
# 28. Control Panel View Mode
# ==============================================================================
Write-Log "INFO: [28] Configuring Control Panel View Mode..."
$cpView = Get-IniValue -Ini $iniConfig -Section 'control_panel' -Key 'view' -Default 'Large'
$cpKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel'

switch -Regex ($cpView) {
    '^(large)$' {
        # Large icons: StartupPage = 1 (Classic view), AllItemsIconView = 0 (Large Icons)
        Set-RegValue $cpKey 'StartupPage' 1 'DWord'
        Set-RegValue $cpKey 'AllItemsIconView' 0 'DWord'
        Write-Log "INFO: [28] Control Panel set to Large Icons view (StartupPage=1, AllItemsIconView=0)."
    }
    '^(small)$' {
        # Small icons: StartupPage = 1, AllItemsIconView = 1 (Small Icons)
        Set-RegValue $cpKey 'StartupPage' 1 'DWord'
        Set-RegValue $cpKey 'AllItemsIconView' 1 'DWord'
        Write-Log "INFO: [28] Control Panel set to Small Icons view (StartupPage=1, AllItemsIconView=1)."
    }
    '^(category)$' {
        # Category view: StartupPage = 0
        Set-RegValue $cpKey 'StartupPage' 0 'DWord'
        Write-Log "INFO: [28] Control Panel set to Category view (StartupPage=0)."
    }
    default {
        Write-Log "INFO: [28] Control Panel view unchanged (Skip)."
    }
}

# ==============================================================================
# 24, 25. Wallpapers Configuration
# ==============================================================================
Write-Log "INFO: [24..25] Configuring Wallpapers..."

# 24. Desktop Wallpaper
$desktopWp = Get-IniValue -Ini $iniConfig -Section 'wallpaper' -Key 'desktop' -Default 'Default'
$wpPath = 'C:\Windows\Web\Wallpaper\Windows\img0.jpg'

if ($desktopWp.ToLowerInvariant() -ne 'default') {
    if ($desktopWp.StartsWith('http://') -or $desktopWp.StartsWith('https://')) {
        try {
            $destWp = 'C:\Auto-installer\wallpaper.jpg'
            Invoke-WebRequest -Uri $desktopWp -OutFile $destWp -UseBasicParsing -TimeoutSec 30
            $wpPath = $destWp
            Write-Log "INFO: [24] Downloaded desktop wallpaper from $desktopWp."
        } catch {
            Write-Log "WARN: [24] Failed to download wallpaper URL: $($_.Exception.Message)"
        }
    } elseif (Test-Path -LiteralPath $desktopWp) {
        $wpPath = (Resolve-Path -LiteralPath $desktopWp).Path
    } elseif (Test-Path -LiteralPath (Join-Path $PSScriptRoot $desktopWp)) {
        $wpPath = (Join-Path $PSScriptRoot $desktopWp)
    }
}

if (Test-Path -LiteralPath $wpPath) {
    Set-RegValue 'HKCU:\Control Panel\Desktop' 'Wallpaper' $wpPath 'String'
    try {
        $csharp_wp = @'
using System;
using System.Runtime.InteropServices;
public class WPSetter {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
        Add-Type -TypeDefinition $csharp_wp -ErrorAction SilentlyContinue
        [WPSetter]::SystemParametersInfo(20, 0, $wpPath, 3) | Out-Null
        Write-Log "INFO: [24] Desktop wallpaper applied: $wpPath."
    } catch {
        Write-Log "WARN: [24] Could not invoke SystemParametersInfo for wallpaper: $($_.Exception.Message)"
    }
}

# 25. Lock Screen Wallpaper
$lockscreenWp = Get-IniValue -Ini $iniConfig -Section 'wallpaper' -Key 'lockscreen' -Default 'Default'
if ($lockscreenWp.ToLowerInvariant() -ne 'default') {
    $lockPath = $null
    if ($lockscreenWp.StartsWith('http://') -or $lockscreenWp.StartsWith('https://')) {
        try {
            $destLock = 'C:\Auto-installer\lockscreen.jpg'
            Invoke-WebRequest -Uri $lockscreenWp -OutFile $destLock -UseBasicParsing -TimeoutSec 30
            $lockPath = $destLock
        } catch {
            Write-Log "WARN: [25] Failed to download lockscreen URL: $($_.Exception.Message)"
        }
    } elseif (Test-Path -LiteralPath $lockscreenWp) {
        $lockPath = (Resolve-Path -LiteralPath $lockscreenWp).Path
    } elseif (Test-Path -LiteralPath (Join-Path $PSScriptRoot $lockscreenWp)) {
        $lockPath = (Join-Path $PSScriptRoot $lockscreenWp)
    }

    if ($lockPath -and (Test-Path -LiteralPath $lockPath)) {
        Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' 'LockScreenImage' $lockPath 'String'
        Set-RegValue 'HKLM:\Software\Microsoft\Windows\CurrentVersion\PersonalizationCSP' 'LockScreenImagePath' $lockPath 'String'
        Write-Log "INFO: [25] Lock screen wallpaper set: $lockPath."
    }
}

# ==============================================================================
# 29. Region & Format Settings
# ==============================================================================
$regionEnabled = Get-IniBool -Ini $iniConfig -Section 'region' -Key 'enabled' -Default $true
if ($regionEnabled) {
    Write-Log "INFO: [29] Configuring Region & Format Settings..."
    $intlKey = 'HKCU:\Control Panel\International'
    
    $locale         = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'locale'           -Default '0000042A'
    $localeName     = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'locale_name'      -Default 'vi-VN'
    $language       = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'language'         -Default 'VIT'
    $country        = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'country'          -Default 'Viet Nam'
    $countryCode    = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'country_code'     -Default '84'
    $longDate       = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'long_date'        -Default 'dddd, d MMMM, yyyy'
    $shortDate      = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'short_date'       -Default 'dd/MM/yyyy'
    $yearMonth      = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'year_month'       -Default 'MMMM yyyy'
    $timeFormat     = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'time_format'      -Default 'h:mm:ss tt'
    $shortTime      = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'short_time'       -Default 'h:mm tt'
    $firstDayOfWeek = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'first_day_of_week' -Default '0'
    $measure        = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'measure'          -Default '0'
    $currency       = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'currency'         -Default ([char]0x20AB)
    $decimal        = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'decimal'          -Default ','
    $thousand       = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'thousand'         -Default '.'
    $digits         = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'digits'           -Default '2'
    $geoNation      = Get-IniValue -Ini $iniConfig -Section 'region' -Key 'geo_nation'       -Default '251'

    Set-RegValue $intlKey 'Locale'          $locale         'String'
    Set-RegValue $intlKey 'LocaleName'      $localeName     'String'
    Set-RegValue $intlKey 'sLanguage'       $language       'String'
    Set-RegValue $intlKey 'sCountry'        $country        'String'
    Set-RegValue $intlKey 'iCountry'        $countryCode    'String'
    Set-RegValue $intlKey 'sLongDate'       $longDate       'String'
    Set-RegValue $intlKey 'sShortDate'      $shortDate      'String'
    Set-RegValue $intlKey 'sYearMonth'      $yearMonth      'String'
    Set-RegValue $intlKey 'sTimeFormat'     $timeFormat     'String'
    Set-RegValue $intlKey 'sShortTime'      $shortTime      'String'
    Set-RegValue $intlKey 'iFirstDayOfWeek' $firstDayOfWeek 'String'
    Set-RegValue $intlKey 'iMeasure'        $measure        'String'
    Set-RegValue $intlKey 'sCurrency'       $currency       'String'
    Set-RegValue $intlKey 'sDecimal'        $decimal        'String'
    Set-RegValue $intlKey 'sThousand'       $thousand       'String'
    Set-RegValue $intlKey 'iDigits'         $digits         'String'
    Set-RegValue 'HKCU:\Control Panel\International\Geo' 'Nation' $geoNation 'String'
    
    Write-Log "INFO: [29] Region format set to $localeName ($country, $shortDate, $shortTime)."
    
    try {
        Start-Service w32time -ErrorAction SilentlyContinue
        w32tm /resync /nowait | Out-Null
        Write-Log "INFO: [29] Triggered Windows Time synchronization (w32tm)."
    } catch {}
}

# ==============================================================================
# Restart Explorer & Apply Desktop Sorting
# ==============================================================================
Write-Log "INFO: Restarting Explorer to apply shell modifications..."
try {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 2000
    Start-Process explorer -ErrorAction SilentlyContinue
    Write-Log "INFO: Explorer restarted successfully."
} catch {
    Write-Log "WARN: Explorer restart error: $($_.Exception.Message)"
}

# 21. Desktop Icons Sorting via WM_COMMAND
$sortMode = Get-IniValue -Ini $iniConfig -Section 'desktop' -Key 'sort' -Default 'ItemType'
if ($sortMode.ToLowerInvariant() -ne 'none') {
    Write-Log "INFO: [21] Sorting desktop icons ($sortMode)..."
    $wmCommandId = switch -Regex ($sortMode) {
        '^(name)$'         { 31491 }
        '^(size)$'         { 31492 }
        '^(datemodified)$' { 31493 }
        default            { 31494 } # ItemType
    }
    
    try {
        $code = @"
using System;
using System.Runtime.InteropServices;

public class DesktopSorter
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

    public static void Sort(int commandId)
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
            SendMessage(hShellView, WM_COMMAND, new IntPtr(commandId), IntPtr.Zero);
        }
    }
}
"@
        Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
        [DesktopSorter]::Sort($wmCommandId)
        Write-Log "INFO: [21] Desktop icons sorted by $sortMode (WM_COMMAND ID=$wmCommandId)."
    } catch {
        Write-Log "WARN: [21] Desktop sort interop failed: $($_.Exception.Message)"
    }
}

# ==============================================================================
# Validation Block
# ==============================================================================
Write-Log "INFO: --- POST-CONFIGURATION VALIDATION ---"
$valFails = 0

function Assert-Reg {
    param($Path, $Name, $Expected)
    $val = (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue).$Name
    if ($val -eq $Expected) {
        Write-Log "INFO: [VALIDATION] PASS: $Name = $val"
        return $true
    }
    Write-Log "ERROR: [VALIDATION] FAIL: $Name = $val (Expected: $Expected)"
    return $false
}

if (-not (Assert-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' ($(if ($showExt) { 0 } else { 1 })))) { $valFails++ }
if (-not (Assert-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode' ($(switch ($searchMode.ToLowerInvariant()) { 'icon' { 1 } 'full' { 2 } 'iconandlabel' { 3 } default { 0 } })))) { $valFails++ }
if (-not (Assert-Reg 'HKCU:\SOFTWARE\Microsoft\Clipboard' 'EnableClipboardHistory' ($(if ($clipHist) { 1 } else { 0 })))) { $valFails++ }
if (-not (Assert-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'LongPathsEnabled' 1)) { $valFails++ }

if ($valFails -eq 0) {
    Write-Log "INFO: Windows configuration completed successfully with 0 validation errors."
} else {
    Write-Log "WARN: Windows configuration completed with $valFails validation warning(s)."
}

Write-Log "======================================================================"
exit 0
