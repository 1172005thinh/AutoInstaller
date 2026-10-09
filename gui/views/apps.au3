;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/apps.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Libraries
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <ProgressConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GuiListView.au3>

; Controls
#include "../controls/button.au3"

; Modules
#include "../modules/i18n.au3"
#include "../modules/theme.au3"
#include "../modules/config.au3"
#include "../modules/data.au3"
#include "../modules/scroll.au3"
#include "../../apps/download.au3"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Global View Controls & State
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $hViewApps = 0
Global $idViewAppsTitle = 0
Global $hViewAppsGroup = 0
Global $idViewAppsAvailableLbl = 0
Global $idViewAppsResetBtn = 0

Global $idViewAppsTable = 0
Global $hViewAppsTable = 0

Global $idViewAppsShortcutCmb = 0

Global $idViewAppsDownloadBtn = 0
Global $idViewAppsProgressBar = 0

Global $idViewAppsMaxIterLbl = 0
Global $idViewAppsMaxIterInput = 0
Global $idViewAppsMaxIterUpDown = 0

Global $idViewAppsLogPathLbl = 0
Global $idViewAppsLogPathInput = 0

Global $g_aViewAppsAppIds[64]
Global $g_iViewAppsAppCount = 0
Global $g_iViewAppsSelectedRow = -1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; View Creation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewAppsCreate($hViewport, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH
    If $iContentH < 680 Then $iContentH = 680

    $hViewApps = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewApps)

    Local $iPx = $iLblH * 20 / 100
    Local $iRowH = $iLblH + $iP * 2

    ; 1. Title
    Local $iX = $iP
    Local $iY = $iP
    Local $iCtrlW = $iContentW
    Local $iCtrlH = $iLblH * 2
    $idViewAppsTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)

    ; 2. Group Box
    $iY += $iCtrlH + $iP
    Local $iGroupH = $iRowH * 14 + $iP * 8
    $hViewAppsGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iGroupH)

    ; 3. Table Header & Reset Button Row
    $iX = $iP * 3
    Local $iItemY = $iY + $iP * 3
    Local $iTableW = $iContentW - $iP * 4
    Local $iBtnW = 100

    $idViewAppsAvailableLbl = GUICtrlCreateLabel("", $iX, $iItemY + $iPx, $iTableW - $iBtnW - $iP, $iLblH)
    $idViewAppsResetBtn = GUICtrlCreateButton(i18nGet("apps.btn.reset", "Reset"), ($iX + $iTableW) - $iBtnW, $iItemY - $iPx, $iBtnW, $iBtnH)
    GUICtrlSetTip($idViewAppsResetBtn, i18nGet("apps.btn.reset.tip", "Deselect all applications for installation"))

    ; 4. Applications Table Control (10 rows visible)
    $iItemY += $iRowH + $iP
    Local $iTableH = $iRowH * 9 + $iP * 2
    $idViewAppsTable = GUICtrlCreateListView("", $iX, $iItemY, $iTableW, $iTableH, _
        BitOR($LVS_REPORT, $LVS_SHOWSELALWAYS, $WS_BORDER), _
        BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
    $hViewAppsTable = GUICtrlGetHandle($idViewAppsTable)

    Local $iCol0W = Int($iTableW * 30 / 100) ; Name (30%)
    Local $iCol1W = Int($iTableW * 40 / 100) ; Description (40%)
    Local $iCol2W = Int($iTableW * 10 / 100) ; Version (10%)
    Local $iCol3W = Int($iTableW * 10 / 100) ; Shortcut (10%)
    Local $iCol4W = $iTableW - ($iCol0W + $iCol1W + $iCol2W + $iCol3W) - $iPx ; Ready

    _GUICtrlListView_InsertColumn($idViewAppsTable, 0, i18nGet("apps.col.name", "Name"), $iCol0W)
    _GUICtrlListView_InsertColumn($idViewAppsTable, 1, i18nGet("apps.col.description", "Description"), $iCol1W)
    _GUICtrlListView_InsertColumn($idViewAppsTable, 2, i18nGet("apps.col.version", "Version"), $iCol2W)
    _GUICtrlListView_InsertColumn($idViewAppsTable, 3, i18nGet("apps.col.shortcut", "Shortcut"), $iCol3W)
    _GUICtrlListView_InsertColumn($idViewAppsTable, 4, i18nGet("apps.col.ready", "Ready"), $iCol4W)
    GUICtrlSetTip($idViewAppsTable, i18nGet("apps.tbl.tip", "Interactive software catalog: check apps to install, view readiness and versions"))

    ; 5. Row 1 below Table: Input Fields (Shortcut ComboBox aligned with Column 3)
    $iItemY += $iTableH + $iP
    Local $iShortcutX = $iX + $iCol0W + $iCol1W + $iCol2W + $iPx
    Local $iShortcutW = $iCol3W - 2 * $iPx
    $idViewAppsShortcutCmb = GUICtrlCreateCombo("", $iShortcutX, $iItemY, $iShortcutW, $iBtnH, $CBS_DROPDOWNLIST)
    GUICtrlSetData($idViewAppsShortcutCmb, i18nGet("apps.status.yes", "Yes") & "|" & i18nGet("apps.status.no", "No"), i18nGet("apps.status.no", "No"))
    GUICtrlSetTip($idViewAppsShortcutCmb, i18nGet("apps.entry.shortcut.tip", "Create desktop shortcut after installation"))

    ; 6. Row 2 below Table: Download Component (Download button + Progress Bar)
    $iItemY += $iRowH + $iP
    Local $iDlBtnW = 110
    $idViewAppsDownloadBtn = GUICtrlCreateButton(i18nGet("apps.entry.download.btn", "Download"), $iX, $iItemY, $iDlBtnW, $iBtnH)
    GUICtrlSetTip($idViewAppsDownloadBtn, i18nGet("apps.entry.download.tip", "Download setup file for the selected application"))

    $idViewAppsProgressBar = GUICtrlCreateProgress($iX + $iDlBtnW + $iP, $iItemY + $iPx, $iTableW - $iDlBtnW - $iP, $iBtnH - $iPx * 2, $PBS_SMOOTH)
    GUICtrlSetTip($idViewAppsProgressBar, i18nGet("apps.entry.progress.tip", "Real-time download progress for the selected application"))

    ; 7. Row 3 below Table: Configuration Settings (Max Iteration + Log Path)
    $iItemY += $iRowH + $iP
    Local $iMaxIterLblW = 130
    Local $iMaxIterInputW = 60
    $idViewAppsMaxIterLbl = GUICtrlCreateLabel(i18nGet("apps.maxiter.label", "Max Iteration: "), $iX, $iItemY + $iPx, $iMaxIterLblW, $iLblH)
    $idViewAppsMaxIterInput = GUICtrlCreateInput("2", $iX + $iMaxIterLblW, $iItemY, $iMaxIterInputW, $iBtnH, $ES_NUMBER)
    $idViewAppsMaxIterUpDown = GUICtrlCreateUpdown($idViewAppsMaxIterInput)
    GUICtrlSetLimit($idViewAppsMaxIterUpDown, 5, 1)

    Local $iLogPathLblW = 130
    Local $iLogX = $iX + $iMaxIterLblW + $iMaxIterInputW + $iP * 3
    $idViewAppsLogPathLbl = GUICtrlCreateLabel(i18nGet("apps.logpath.label", "Log Path: "), $iLogX, $iItemY + $iPx, $iLogPathLblW, $iLblH)
    $idViewAppsLogPathInput = GUICtrlCreateInput("C:\AutoInstaller\apps.log", $iLogX + $iLogPathLblW, $iItemY, ($iX + $iTableW) - ($iLogX + $iLogPathLblW), $iBtnH)

    Local $iTotalContentH = $iY + $iGroupH + $iP * 2
    scrollSetContentHeight($hViewApps, $iTotalContentH)

    ; Load table data from apps.csv and config.ini
    viewAppsLoadData()

    viewAppsApplyLang()
    viewAppsApplyTheme()
    Return $hViewApps
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Application Description Localization
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _AppsGetAppDesc($sAppId, $sDefault)
    Switch $sAppId
        Case "7z"
            Return i18nGet("apps.desc.7z", "High compression ratio file archiver")
        Case "Brave"
            Return i18nGet("apps.desc.Brave", "Privacy-focused Chromium web browser")
        Case "Discord"
            Return i18nGet("apps.desc.Discord", "Voice, video, and text communication platform")
        Case "Docker"
            Return i18nGet("apps.desc.Docker", "Container runtime and development platform")
        Case "Fonts"
            Return i18nGet("apps.desc.Fonts", "Core fonts collection including Cascadia Code and JetBrains Mono")
        Case "Git"
            Return i18nGet("apps.desc.Git", "Distributed version control system")
        Case "GoogleChrome"
            Return i18nGet("apps.desc.GoogleChrome", "Fast and secure web browser by Google")
        Case "Java"
            Return i18nGet("apps.desc.Java", "Java Platform Standard Edition runtime environment")
        Case "Kaspersky"
            Return i18nGet("apps.desc.Kaspersky", "Antivirus and internet security suite")
        Case "LibreOffice"
            Return i18nGet("apps.desc.LibreOffice", "Free and open source office suite")
        Case "MicrosoftOffice"
            Return i18nGet("apps.desc.MicrosoftOffice", "Microsoft Office deployment package")
        Case "MPC-HC"
            Return i18nGet("apps.desc.MPC-HC", "Lightweight open source media player")
        Case "MSYS2"
            Return i18nGet("apps.desc.MSYS2", "Software distribution and building platform for Windows")
        Case "Notepad++"
            Return i18nGet("apps.desc.Notepad++", "Extensible source code editor and text replacement tool")
        Case "OBS"
            Return i18nGet("apps.desc.OBS", "Free and open source software for video recording and live streaming")
        Case "PotPlayer"
            Return i18nGet("apps.desc.PotPlayer", "Feature-rich multimedia player with hardware acceleration")
        Case "Python"
            Return i18nGet("apps.desc.Python", "Python programming language runtime and environment")
        Case "qBittorrent"
            Return i18nGet("apps.desc.qBittorrent", "Free and reliable BitTorrent client")
        Case "Shell"
            Return i18nGet("apps.desc.Shell", "Context menu customizer for Windows File Explorer")
        Case "Tailscale"
            Return i18nGet("apps.desc.Tailscale", "Zero config VPN built on WireGuard")
        Case "TeamViewer"
            Return i18nGet("apps.desc.TeamViewer", "Remote desktop access and support tool")
        Case "UltraViewer"
            Return i18nGet("apps.desc.UltraViewer", "Remote support software for Windows")
        Case "Unikey"
            Return i18nGet("apps.desc.Unikey", "Vietnamese keyboard input method editor")
        Case "VCRedist"
            Return i18nGet("apps.desc.VCRedist", "All-in-one package for Microsoft Visual C++ Runtimes (2005-2022)")
        Case "VisualStudio"
            Return i18nGet("apps.desc.VisualStudio", "Integrated development environment by Microsoft")
        Case "VLC"
            Return i18nGet("apps.desc.VLC", "Cross-platform multimedia player and framework")
        Case "VSCode"
            Return i18nGet("apps.desc.VSCode", "Source-code editor made by Microsoft")
        Case "WinRAR"
            Return i18nGet("apps.desc.WinRAR", "Powerful archiver and archive manager")
        Case "WireGuard"
            Return i18nGet("apps.desc.WireGuard", "Fast, modern, and secure VPN tunnel")
        Case "yt-dlp"
            Return i18nGet("apps.desc.yt-dlp", "Command-line audio and video download tool")
        Case "Zalo"
            Return i18nGet("apps.desc.Zalo", "Instant messaging and social networking app")
        Case Else
            Return $sDefault
    EndSwitch
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Data Population & State Management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewAppsLoadData()
    _GUICtrlListView_DeleteAllItems($hViewAppsTable)
    $g_iViewAppsAppCount = 0
    $g_iViewAppsSelectedRow = -1

    Local $sConfig = downloadGetConfigPath()
    Local $aApps = dataLoadCsv("apps.csv")
    If Not IsArray($aApps) Or UBound($aApps, 1) < 2 Then Return

    For $i = 1 To UBound($aApps, 1) - 1
        Local $sApp = $aApps[$i][0]
        Local $sName = $aApps[$i][1]
        Local $sDesc = _AppsGetAppDesc($sApp, $aApps[$i][2])
        Local $sVer = downloadGetAppVersion($sApp)
        If $sVer = "Unknown" Then $sVer = i18nGet("apps.status.unknown", "Unknown")

        Local $bInstall = (StringLower(IniRead($sConfig, $sApp, "install", "false")) = "true")
        Local $bShortcut = (StringLower(IniRead($sConfig, $sApp, "shortcut", "false")) = "true")
        Local $sShortcut = $bShortcut ? i18nGet("apps.status.yes", "Yes") : i18nGet("apps.status.no", "No")

        Local $bReady = downloadIsAppReady($sApp)
        Local $sReady = $bReady ? i18nGet("apps.status.yes", "Yes") : i18nGet("apps.status.no", "No")

        Local $iItem = _GUICtrlListView_AddItem($hViewAppsTable, $sName)
        _GUICtrlListView_AddSubItem($hViewAppsTable, $iItem, $sDesc, 1)
        _GUICtrlListView_AddSubItem($hViewAppsTable, $iItem, $sVer, 2)
        _GUICtrlListView_AddSubItem($hViewAppsTable, $iItem, $sShortcut, 3)
        _GUICtrlListView_AddSubItem($hViewAppsTable, $iItem, $sReady, 4)

        _GUICtrlListView_SetItemChecked($hViewAppsTable, $iItem, $bInstall)

        $g_aViewAppsAppIds[$g_iViewAppsAppCount] = $sApp
        $g_iViewAppsAppCount += 1
    Next

    ; Read max_iteration and log_path
    Local $sMaxIter = IniRead($sConfig, "Configuration", "max_iteration", "2")
    GUICtrlSetData($idViewAppsMaxIterInput, $sMaxIter)

    Local $sLogPath = IniRead($sConfig, "Configuration", "log_path", "C:\AutoInstaller\apps.log")
    GUICtrlSetData($idViewAppsLogPathInput, $sLogPath)

    If $g_iViewAppsAppCount > 0 Then
        _GUICtrlListView_SetItemSelected($hViewAppsTable, 0, True, True)
        _ViewAppsOnSelectRow(0)
    EndIf
EndFunc

Func viewAppsSaveData()
    Local $sConfig = downloadGetConfigPath()
    If Not FileExists($sConfig) Then Return False

    For $i = 0 To $g_iViewAppsAppCount - 1
        Local $sApp = $g_aViewAppsAppIds[$i]
        Local $bChecked = _GUICtrlListView_GetItemChecked($hViewAppsTable, $i)
        Local $sSc = _GUICtrlListView_GetItemText($hViewAppsTable, $i, 3)
        Local $bShortcut = ($sSc = i18nGet("apps.status.yes", "Yes") Or StringLower($sSc) = "yes")

        IniWrite($sConfig, $sApp, "install", $bChecked ? "true" : "false")
        IniWrite($sConfig, $sApp, "shortcut", $bShortcut ? "true" : "false")
    Next

    ; Save max_iteration and log_path
    Local $sMaxIter = GUICtrlRead($idViewAppsMaxIterInput)
    Local $iMaxIter = Int($sMaxIter)
    If $iMaxIter < 1 Then $iMaxIter = 1
    If $iMaxIter > 5 Then $iMaxIter = 5
    IniWrite($sConfig, "Configuration", "max_iteration", String($iMaxIter))

    Local $sLogPath = GUICtrlRead($idViewAppsLogPathInput)
    If $sLogPath <> "" Then IniWrite($sConfig, "Configuration", "log_path", $sLogPath)

    Return True
EndFunc

Func _ViewAppsOnSelectRow($iIdx = -1)
    If $iIdx < 0 Then
        Local $sSel = _GUICtrlListView_GetSelectedIndices($hViewAppsTable)
        If $sSel = "" Then Return
        $iIdx = Number($sSel)
    EndIf
    If $iIdx < 0 Or $iIdx >= $g_iViewAppsAppCount Then Return

    $g_iViewAppsSelectedRow = $iIdx
    Local $sApp = $g_aViewAppsAppIds[$iIdx]

    ; Check readiness
    Local $bReady = downloadIsAppReady($sApp)
    If $bReady Then
        GUICtrlSetData($idViewAppsProgressBar, 100)
    Else
        GUICtrlSetData($idViewAppsProgressBar, 0)
    EndIf

    ; Sync shortcut combo
    Local $sSc = _GUICtrlListView_GetItemText($hViewAppsTable, $iIdx, 3)
    If $sSc = i18nGet("apps.status.yes", "Yes") Or StringLower($sSc) = "yes" Then
        GUICtrlSetData($idViewAppsShortcutCmb, i18nGet("apps.status.yes", "Yes"))
    Else
        GUICtrlSetData($idViewAppsShortcutCmb, i18nGet("apps.status.no", "No"))
    EndIf
EndFunc

Func _ViewAppsDownloadSelectedRow()
    If $g_iViewAppsSelectedRow < 0 Or $g_iViewAppsSelectedRow >= $g_iViewAppsAppCount Then Return

    Local $sApp = $g_aViewAppsAppIds[$g_iViewAppsSelectedRow]
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.downloading", "Downloading setup file...") & " (" & $sApp & ")")

    Local $bSuccess = downloadApp($sApp, True, "_ViewAppsDownloadCallback")
    If $bSuccess Then
        GUICtrlSetData($idViewAppsProgressBar, 100)
        _GUICtrlListView_SetItemText($hViewAppsTable, $g_iViewAppsSelectedRow, i18nGet("apps.status.yes", "Yes"), 4)

        Local $sVer = downloadGetAppVersion($sApp)
        If $sVer <> "Unknown" Then _GUICtrlListView_SetItemText($hViewAppsTable, $g_iViewAppsSelectedRow, $sVer, 2)

        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.download_done", "Download completed successfully") & " (" & $sApp & ")")
    Else
        GUICtrlSetData($idViewAppsProgressBar, 0)
        _GUICtrlListView_SetItemText($hViewAppsTable, $g_iViewAppsSelectedRow, i18nGet("apps.status.no", "No"), 4)
        MsgBox(BitOR($MB_ICONERROR, $MB_OK), i18nGet("error.dialog.title", "Error"), i18nGet("apps.status.download_failed", "Failed to download setup file") & " (" & $sApp & ")")
        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.download_failed", "Failed to download setup file"))
    EndIf
EndFunc

Func _ViewAppsDownloadCallback($iPercent, $iBytes, $iTotal)
    GUICtrlSetData($idViewAppsProgressBar, $iPercent)
    #forceref $iBytes, $iTotal
EndFunc

Func _ViewAppsResetSelection()
    For $i = 0 To $g_iViewAppsAppCount - 1
        _GUICtrlListView_SetItemChecked($hViewAppsTable, $i, False)
    Next
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.reset", "Reset all application selections"))
EndFunc

Func _ViewAppsDownloadAllSelected()
    Local $iSelectedCount = 0
    For $i = 0 To $g_iViewAppsAppCount - 1
        If _GUICtrlListView_GetItemChecked($hViewAppsTable, $i) Then $iSelectedCount += 1
    Next

    If $iSelectedCount = 0 Then
        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.no_updates", "All applications are already up to date"))
        Return
    EndIf

    Local $iDownloaded = 0
    For $i = 0 To $g_iViewAppsAppCount - 1
        If _GUICtrlListView_GetItemChecked($hViewAppsTable, $i) Then
            Local $sApp = $g_aViewAppsAppIds[$i]
            _GUICtrlListView_SetItemSelected($hViewAppsTable, $i, True, True)
            _ViewAppsOnSelectRow($i)

            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.downloading", "Downloading setup file...") & " (" & $sApp & ")")
            Local $bOk = downloadApp($sApp, True, "_ViewAppsDownloadCallback")
            If $bOk Then
                _GUICtrlListView_SetItemText($hViewAppsTable, $i, i18nGet("apps.status.yes", "Yes"), 4)
                Local $sVer = downloadGetAppVersion($sApp)
                If $sVer <> "Unknown" Then _GUICtrlListView_SetItemText($hViewAppsTable, $i, $sVer, 2)
                $iDownloaded += 1
            Else
                _GUICtrlListView_SetItemText($hViewAppsTable, $i, i18nGet("apps.status.no", "No"), 4)
            EndIf
        EndIf
    Next

    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.download_batch_done", "Downloaded all selected applications successfully") & " (" & $iDownloaded & "/" & $iSelectedCount & ")")
EndFunc

Func _ViewAppsUpdateManifest()
    Local $iUpdated = downloadUpdateManifest()
    If $iUpdated > 0 Then
        viewAppsLoadData()
        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.updates_checked", "Checked for updates: updated application URLs") & " (" & $iUpdated & ")")
    Else
        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.no_updates", "All applications are already up to date"))
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Localization & Theming
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewAppsApplyLang()
    GUICtrlSetData($idViewAppsTitle, i18nGet("apps.title", "Customize App Installation"))
    GUICtrlSetData($hViewAppsGroup, i18nGet("apps.group.title", "Applications Installation"))
    GUICtrlSetTip($hViewAppsGroup, i18nGet("apps.group.tip", "Manage and select applications to deploy during setup"))

    GUICtrlSetData($idViewAppsAvailableLbl, i18nGet("apps.available.label", "Available Applications: "))
    GUICtrlSetTip($idViewAppsAvailableLbl, i18nGet("apps.available.tip", "List of software applications available in the library"))
    GUICtrlSetData($idViewAppsResetBtn, i18nGet("apps.btn.reset", "Reset"))
    GUICtrlSetTip($idViewAppsResetBtn, i18nGet("apps.btn.reset.tip", "Deselect all applications for installation"))

    _GUICtrlListView_SetColumn($idViewAppsTable, 0, i18nGet("apps.col.name", "Name"))
    _GUICtrlListView_SetColumn($idViewAppsTable, 1, i18nGet("apps.col.description", "Description"))
    _GUICtrlListView_SetColumn($idViewAppsTable, 2, i18nGet("apps.col.version", "Version"))
    _GUICtrlListView_SetColumn($idViewAppsTable, 3, i18nGet("apps.col.shortcut", "Shortcut"))
    _GUICtrlListView_SetColumn($idViewAppsTable, 4, i18nGet("apps.col.ready", "Ready"))

    GUICtrlSetData($idViewAppsDownloadBtn, i18nGet("apps.entry.download.btn", "Download"))
    GUICtrlSetTip($idViewAppsDownloadBtn, i18nGet("apps.entry.download.tip", "Download setup file for the selected application"))
    GUICtrlSetTip($idViewAppsProgressBar, i18nGet("apps.entry.progress.tip", "Real-time download progress for the selected application"))

    Local $sCurSc = GUICtrlRead($idViewAppsShortcutCmb)
    Local $bWasYes = ($sCurSc = "Yes" Or $sCurSc = i18nGet("apps.status.yes", "Yes"))
    GUICtrlSetData($idViewAppsShortcutCmb, "|" & i18nGet("apps.status.yes", "Yes") & "|" & i18nGet("apps.status.no", "No"), $bWasYes ? i18nGet("apps.status.yes", "Yes") : i18nGet("apps.status.no", "No"))
    GUICtrlSetTip($idViewAppsShortcutCmb, i18nGet("apps.entry.shortcut.tip", "Create desktop shortcut after installation"))

    ; Max Iteration controls
    GUICtrlSetData($idViewAppsMaxIterLbl, i18nGet("apps.maxiter.label", "Max Iteration: "))
    GUICtrlSetTip($idViewAppsMaxIterLbl, i18nGet("apps.maxiter.tip", "Maximum number of installation attempts for each application. Increasing this value may help with applications that fail to install on the first attempt."))
    GUICtrlSetTip($idViewAppsMaxIterInput, i18nGet("apps.maxiter.tip", "Maximum number of installation attempts for each application. Increasing this value may help with applications that fail to install on the first attempt."))
    GUICtrlSetTip($idViewAppsMaxIterUpDown, i18nGet("apps.maxiter.tip", "Maximum number of installation attempts for each application. Increasing this value may help with applications that fail to install on the first attempt."))

    ; Log Path controls
    GUICtrlSetData($idViewAppsLogPathLbl, i18nGet("apps.logpath.label", "Log Path: "))
    GUICtrlSetTip($idViewAppsLogPathLbl, i18nGet("apps.logpath.tip", "File path where installation logs will be saved. Changing this value may help with troubleshooting installation issues."))
    GUICtrlSetTip($idViewAppsLogPathInput, i18nGet("apps.logpath.tip", "File path where installation logs will be saved. Changing this value may help with troubleshooting installation issues."))

    ; Reload descriptions in table for current language
    Local $aApps = dataLoadCsv("apps.csv")
    If IsArray($aApps) Then
        For $j = 1 To UBound($aApps, 1) - 1
            Local $sDesc = _AppsGetAppDesc($aApps[$j][0], $aApps[$j][2])
            _GUICtrlListView_SetItemText($hViewAppsTable, $j - 1, $sDesc, 1)
        Next
    EndIf

    If $g_hCurrentView = $hViewApps Then
        GUICtrlSetData($a_idToolBarBtn[0], i18nGet("reset.btn.title", "Reset"))
        GUICtrlSetTip($a_idToolBarBtn[0], i18nGet("apps.btn.reset.tip", "Deselect all applications for installation"))

        GUICtrlSetData($a_idToolBarBtn[1], i18nGet("download.btn.title", "Download"))
        GUICtrlSetTip($a_idToolBarBtn[1], i18nGet("apps.toolbar.download.tip", "Download setup files for all selected applications"))

        GUICtrlSetData($a_idToolBarBtn[2], i18nGet("update.btn.title", "Update"))
        GUICtrlSetTip($a_idToolBarBtn[2], i18nGet("apps.toolbar.update.tip", "Update URLs and check for newer versions across the library"))

        GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("save.btn.title", "Save"))
        GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("apps.toolbar.save.tip", "Save application configuration to config.ini"))

        GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.title", "Cancel"))
        GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.tip", "Discard changes and reload saved configuration"))
    EndIf
EndFunc

Func viewAppsToolBar()
    ; Button Index 0: [Reset]
    GUICtrlSetData($a_idToolBarBtn[0], i18nGet("reset.btn.title", "Reset"))
    GUICtrlSetTip($a_idToolBarBtn[0], i18nGet("apps.btn.reset.tip", "Deselect all applications for installation"))
    GUICtrlSetState($a_idToolBarBtn[0], $GUI_SHOW)

    ; Button Index 1: [Download]
    GUICtrlSetData($a_idToolBarBtn[1], i18nGet("download.btn.title", "Download"))
    GUICtrlSetTip($a_idToolBarBtn[1], i18nGet("apps.toolbar.download.tip", "Download setup files for all selected applications"))
    GUICtrlSetState($a_idToolBarBtn[1], $GUI_SHOW)

    ; Button Index 2: [Update]
    GUICtrlSetData($a_idToolBarBtn[2], i18nGet("update.btn.title", "Update"))
    GUICtrlSetTip($a_idToolBarBtn[2], i18nGet("apps.toolbar.update.tip", "Update URLs and check for newer versions across the library"))
    GUICtrlSetState($a_idToolBarBtn[2], $GUI_SHOW)

    ; Button Index 6: [Save]
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("save.btn.title", "Save"))
    GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("apps.toolbar.save.tip", "Save application configuration to config.ini"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 2], $GUI_SHOW)

    ; Button Index 7: [Cancel]
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.title", "Cancel"))
    GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.tip", "Discard changes and reload saved configuration"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 1], $GUI_SHOW)
EndFunc

Func viewAppsApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hViewApps)

    GUICtrlSetColor($idViewAppsTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsTitle, themeColor("main.view.bg"))

    GUICtrlSetColor($idViewAppsAvailableLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsAvailableLbl, themeColor("main.view.bg"))

    GUICtrlSetColor($idViewAppsMaxIterLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsMaxIterLbl, themeColor("main.view.bg"))

    GUICtrlSetColor($idViewAppsLogPathLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsLogPathLbl, themeColor("main.view.bg"))

    GUICtrlSetColor($idViewAppsMaxIterInput, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsMaxIterInput, themeColor("main.view.bg"))

    GUICtrlSetColor($idViewAppsLogPathInput, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsLogPathInput, themeColor("main.view.bg"))

    _GUICtrlListView_SetTextColor($idViewAppsTable, themeColor("text.primary"))
    _GUICtrlListView_SetTextBkColor($idViewAppsTable, themeColor("main.view.bg"))
    _GUICtrlListView_SetBkColor($idViewAppsTable, themeColor("main.view.bg"))
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Event Handling
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewAppsHandleEvent($idMsg)
    Switch $idMsg
        ; In-View Reset Button
        Case $idViewAppsResetBtn
            _ViewAppsResetSelection()

        ; Table selection
        Case $idViewAppsTable
            _ViewAppsOnSelectRow()

        ; Single app download button
        Case $idViewAppsDownloadBtn
            _ViewAppsDownloadSelectedRow()

        ; Shortcut combo change
        Case $idViewAppsShortcutCmb
            If $g_iViewAppsSelectedRow >= 0 And $g_iViewAppsSelectedRow < $g_iViewAppsAppCount Then
                Local $sNewSc = GUICtrlRead($idViewAppsShortcutCmb)
                _GUICtrlListView_SetItemText($hViewAppsTable, $g_iViewAppsSelectedRow, $sNewSc, 3)
            EndIf

        ; Toolbar Button 0: [Reset]
        Case $a_idToolBarBtn[0]
            _ViewAppsResetSelection()

        ; Toolbar Button 1: [Download]
        Case $a_idToolBarBtn[1]
            _ViewAppsDownloadAllSelected()

        ; Toolbar Button 2: [Update]
        Case $a_idToolBarBtn[2]
            _ViewAppsUpdateManifest()

        ; Toolbar Button 6: [Save]
        Case $a_idToolBarBtn[$iToolBarBtnCol - 2]
            If viewAppsSaveData() Then
                appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.saved", "Saved application configuration successfully"))
            Else
                appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.error", "Error"))
            EndIf

        ; Toolbar Button 7: [Cancel]
        Case $a_idToolBarBtn[$iToolBarBtnCol - 1]
            viewAppsLoadData()
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.canceled", "Reverted application selections to saved configuration"))
    EndSwitch
EndFunc