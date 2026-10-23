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

; Section 1: Apps Library
Global $hViewAppsLibraryGroup = 0
Global $idViewAppsAvailableLbl = 0
Global $idViewAppsResetBtn = 0

Global $idViewAppsTable = 0
Global $hViewAppsTable = 0

Global $idViewAppsNameInput = 0
Global $idViewAppsDescInput = 0
Global $idViewAppsVerInput = 0
Global $idViewAppsShortcutCmb = 0
Global $idViewAppsReadyInput = 0

Global $idViewAppsDownloadBtn = 0
Global $idViewAppsRefreshBtn = 0
Global $idViewAppsClearBtn = 0
Global $idViewAppsSaveBtn = 0
Global $idViewAppsCancelBtn = 0

Global $idViewAppsStatusLbl = 0
Global $idViewAppsProgressBar = 0

; Section 2: Auto-installation
Global $hViewAppsInstallGroup = 0
Global $idViewAppsMaxIterLbl = 0
Global $idViewAppsMaxIterInput = 0
Global $idViewAppsMaxIterUpDown = 0

Global $idViewAppsLogPathLbl = 0
Global $idViewAppsLogPathInput = 0
Global $idViewAppsLogBrowseBtn = 0

Global $g_aViewAppsAppIds[64]
Global $g_iViewAppsAppCount = 0
Global $g_iViewAppsSelectedRow = -1
Global $g_sViewAppsCurStatusKey = "apps.status.not_downloaded"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; View Creation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewAppsCreate($hViewport, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH
    If $iContentH < 800 Then $iContentH = 800

    $hViewApps = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewApps)

    Local $iPx = $iLblH * 20 / 100
    Local $iRowH = $iLblH + $iP * 2
    Local $iInputH = $iLblH + $iPx * 2
    Local $iLblW = ($iContentW - $iP * 6) * 35 / 100
    Local $iInputW = ($iContentW - $iP * 6) * 58 / 100

    ; 1. View Title
    Local $iX = $iP
    Local $iY = $iP
    Local $iCtrlW = $iContentW
    Local $iCtrlH = $iLblH * 2
    $idViewAppsTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)

    ; =========================================
    ; Section 1: Apps Library
    ; =========================================
    $iY += $iCtrlH + $iP
    Local $iLibGroupH = $iRowH * 12 + $iP * 6
    $hViewAppsLibraryGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iLibGroupH)

    ; Table Header & Reset Button Row
    $iX = $iP * 3
    Local $iItemY = $iY + $iP * 3
    Local $iTableW = $iContentW - $iP * 4
    Local $iBtnW = ($iTableW * 92 / 100 - 4 * $iP) / 5

    $idViewAppsAvailableLbl = GUICtrlCreateLabel("", $iX, $iItemY + $iPx, $iTableW - $iBtnW - $iP, $iLblH)
    $idViewAppsResetBtn = GUICtrlCreateButton(i18nGet("apps.btn.reset", "Reset"), ($iX + $iTableW) - $iBtnW, $iItemY - $iPx, $iBtnW, $iBtnH)
    GUICtrlSetTip($idViewAppsResetBtn, i18nGet("apps.btn.reset.tip", "Deselect all applications for installation"))

    ; Applications Table Control
    $iItemY += $iRowH + $iP
    Local $iTableH = $iRowH * 8
    $idViewAppsTable = GUICtrlCreateListView("", $iX, $iItemY, $iTableW, $iTableH, _
        BitOR($LVS_REPORT, $LVS_SHOWSELALWAYS, $WS_BORDER), _
        BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
    $hViewAppsTable = GUICtrlGetHandle($idViewAppsTable)

    Local $iCol0W = Int($iTableW * 27 / 100) ; Name (27%)
    Local $iCol1W = Int($iTableW * 34 / 100) ; Description (34%)
    Local $iCol2W = Int($iTableW * 13 / 100) ; Version (13%)
    Local $iCol3W = Int($iTableW * 12 / 100) ; Shortcut (12%)
    Local $iCol4W = Int($iTableW * 10 / 100) ; Ready (10%)

    _GUICtrlListView_InsertColumn($idViewAppsTable, 0, i18nGet("apps.col.name", "Name"), $iCol0W)
    _GUICtrlListView_InsertColumn($idViewAppsTable, 1, i18nGet("apps.col.description", "Description"), $iCol1W)
    _GUICtrlListView_InsertColumn($idViewAppsTable, 2, i18nGet("apps.col.version", "Version"), $iCol2W)
    _GUICtrlListView_InsertColumn($idViewAppsTable, 3, i18nGet("apps.col.shortcut", "Shortcut"), $iCol3W)
    _GUICtrlListView_InsertColumn($idViewAppsTable, 4, i18nGet("apps.col.ready", "Ready"), $iCol4W)
    GUICtrlSetTip($idViewAppsTable, i18nGet("apps.tbl.tip", "Interactive software catalog: check apps to install, view readiness and versions"))

    ; Edit Row (aligned with columns 0..4)
    $iItemY += $iTableH + $iP
    Local $iEditX = $iX
    $idViewAppsNameInput = GUICtrlCreateInput("", $iEditX, $iItemY, $iCol0W - $iPx, $iInputH, BitOR($ES_READONLY, $ES_AUTOHSCROLL))
    $iEditX += $iCol0W
    $idViewAppsDescInput = GUICtrlCreateInput("", $iEditX + $iPx, $iItemY, $iCol1W - 2 * $iPx, $iInputH, BitOR($ES_READONLY, $ES_AUTOHSCROLL))
    $iEditX += $iCol1W
    $idViewAppsVerInput = GUICtrlCreateInput("", $iEditX + $iPx, $iItemY, $iCol2W - 2 * $iPx, $iInputH, BitOR($ES_READONLY, $ES_AUTOHSCROLL))
    $iEditX += $iCol2W
    $idViewAppsShortcutCmb = GUICtrlCreateCombo("", $iEditX + $iPx, $iItemY, $iCol3W - 2 * $iPx, $iInputH, $CBS_DROPDOWNLIST)
    GUICtrlSetData($idViewAppsShortcutCmb, i18nGet("apps.status.yes", "Yes") & "|" & i18nGet("apps.status.no", "No"), i18nGet("apps.status.no", "No"))
    $iEditX += $iCol3W
    $idViewAppsReadyInput = GUICtrlCreateInput("", $iEditX + $iPx, $iItemY, ($iX + $iTableW) - ($iEditX + $iPx), $iInputH, BitOR($ES_READONLY, $ES_AUTOHSCROLL))

    ; Control Edit Row Buttons (right-aligned to table width)
    $iItemY += $iRowH
    Local $iBtnRowW = 5 * $iBtnW + 4 * $iP
    Local $iBtnStartX = ($iX + $iTableW) - $iBtnRowW
    $idViewAppsDownloadBtn = GUICtrlCreateButton(i18nGet("apps.entry.download.btn", "Download"), $iBtnStartX, $iItemY, $iBtnW, $iBtnH)
    $idViewAppsRefreshBtn = GUICtrlCreateButton(i18nGet("apps.btn.refresh", "Refresh"), $iBtnStartX + $iBtnW + $iP, $iItemY, $iBtnW, $iBtnH)
    $idViewAppsClearBtn = GUICtrlCreateButton(i18nGet("apps.btn.clear", "Clear"), $iBtnStartX + ($iBtnW + $iP) * 2, $iItemY, $iBtnW, $iBtnH)
    $idViewAppsSaveBtn = GUICtrlCreateButton(i18nGet("apps.btn.save", "Save"), $iBtnStartX + ($iBtnW + $iP) * 3, $iItemY, $iBtnW, $iBtnH)
    $idViewAppsCancelBtn = GUICtrlCreateButton(i18nGet("apps.btn.cancel", "Cancel"), $iBtnStartX + ($iBtnW + $iP) * 4, $iItemY, $iBtnW, $iBtnH)

    ; Additional Controls Edit Info (Download status label + Download progress bar)
    $iItemY += $iRowH + $iP
    Local $iStatusLblW = Int($iTableW * 35 / 100)
    $idViewAppsStatusLbl = GUICtrlCreateLabel("", $iX, $iItemY + $iPx, $iStatusLblW, $iLblH)
    $idViewAppsProgressBar = GUICtrlCreateProgress($iX + $iStatusLblW + $iP, $iItemY, $iTableW - $iStatusLblW - $iP, $iInputH, $PBS_SMOOTH)

    ; =========================================
    ; Section 2: Auto-installation
    ; =========================================
    $iX = $iP
    $iY += $iLibGroupH + $iP
    Local $iInstallGroupH = $iRowH * 2 + $iP * 3
    $hViewAppsInstallGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iInstallGroupH)

    ; Max Iteration Row
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewAppsMaxIterLbl = GUICtrlCreateLabel(i18nGet("apps.maxiter.label", "Max Iteration: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewAppsMaxIterInput = GUICtrlCreateInput("2", $iX + $iLblW, $iItemY - $iPx, $iInputW / 3, $iInputH, $ES_NUMBER)
    $idViewAppsMaxIterUpDown = GUICtrlCreateUpdown($idViewAppsMaxIterInput)
    GUICtrlSetLimit($idViewAppsMaxIterUpDown, 5, 1)

    ; Log Path Row
    $iItemY += $iRowH
    Local $iLogInputW = $iTableW - $iLblW - $iBtnW - $iP
    $idViewAppsLogPathLbl = GUICtrlCreateLabel(i18nGet("apps.logpath.label", "Log Path: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewAppsLogPathInput = GUICtrlCreateInput("C:\AutoInstaller\apps.log", $iX + $iLblW, $iItemY - $iPx, $iLogInputW, $iInputH)
    $idViewAppsLogBrowseBtn = GUICtrlCreateButton(i18nGet("apps.btn.browse", "Browse"), ($iX + $iTableW) - $iBtnW, $iItemY - $iPx, $iBtnW, $iInputH)

    Local $iTotalContentH = $iY + $iInstallGroupH + $iP * 2
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

Func _ViewAppsSetDownloadStatus($sStatusKey)
    $g_sViewAppsCurStatusKey = $sStatusKey
    Local $sStatusText = ""
    Switch $sStatusKey
        Case "apps.status.ready"
            $sStatusText = i18nGet("apps.status.ready", "Ready")
        Case "apps.status.downloading"
            $sStatusText = i18nGet("apps.status.downloading", "Downloading setup file...")
        Case "apps.status.download_done"
            $sStatusText = i18nGet("apps.status.download_done", "Download completed successfully")
        Case "apps.status.download_failed"
            $sStatusText = i18nGet("apps.status.download_failed", "Failed to download setup file")
        Case Else
            $sStatusText = i18nGet("apps.status.not_downloaded", "Not downloaded")
    EndSwitch
    GUICtrlSetData($idViewAppsStatusLbl, i18nGet("apps.status.label", "Download Status: ") & $sStatusText)
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

    ; Populate edit row fields from selected table row
    Local $sName = _GUICtrlListView_GetItemText($hViewAppsTable, $iIdx, 0)
    Local $sDesc = _GUICtrlListView_GetItemText($hViewAppsTable, $iIdx, 1)
    Local $sVer = _GUICtrlListView_GetItemText($hViewAppsTable, $iIdx, 2)
    Local $sSc = _GUICtrlListView_GetItemText($hViewAppsTable, $iIdx, 3)
    Local $sReady = _GUICtrlListView_GetItemText($hViewAppsTable, $iIdx, 4)

    GUICtrlSetData($idViewAppsNameInput, $sName)
    GUICtrlSetData($idViewAppsDescInput, $sDesc)
    GUICtrlSetData($idViewAppsVerInput, $sVer)
    GUICtrlSetData($idViewAppsReadyInput, $sReady)

    If $sSc = i18nGet("apps.status.yes", "Yes") Or StringLower($sSc) = "yes" Then
        GUICtrlSetData($idViewAppsShortcutCmb, i18nGet("apps.status.yes", "Yes"))
    Else
        GUICtrlSetData($idViewAppsShortcutCmb, i18nGet("apps.status.no", "No"))
    EndIf

    ; Check readiness for progress bar and status label
    Local $bReady = downloadIsAppReady($sApp)
    If $bReady Then
        GUICtrlSetData($idViewAppsProgressBar, 100)
        _ViewAppsSetDownloadStatus("apps.status.ready")
    Else
        GUICtrlSetData($idViewAppsProgressBar, 0)
        _ViewAppsSetDownloadStatus("apps.status.not_downloaded")
    EndIf
EndFunc

Func _ViewAppsDownloadSelectedRow()
    If $g_iViewAppsSelectedRow < 0 Or $g_iViewAppsSelectedRow >= $g_iViewAppsAppCount Then Return

    Local $sApp = $g_aViewAppsAppIds[$g_iViewAppsSelectedRow]
    _ViewAppsSetDownloadStatus("apps.status.downloading")
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.downloading", "Downloading setup file...") & " (" & $sApp & ")")

    Local $bSuccess = downloadApp($sApp, True, "_ViewAppsDownloadCallback")
    If $bSuccess Then
        GUICtrlSetData($idViewAppsProgressBar, 100)
        _ViewAppsSetDownloadStatus("apps.status.download_done")
        Local $sYes = i18nGet("apps.status.yes", "Yes")
        _GUICtrlListView_SetItemText($hViewAppsTable, $g_iViewAppsSelectedRow, $sYes, 4)
        GUICtrlSetData($idViewAppsReadyInput, $sYes)

        Local $sVer = downloadGetAppVersion($sApp)
        If $sVer <> "Unknown" Then
            _GUICtrlListView_SetItemText($hViewAppsTable, $g_iViewAppsSelectedRow, $sVer, 2)
            GUICtrlSetData($idViewAppsVerInput, $sVer)
        EndIf

        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.download_done", "Download completed successfully") & " (" & $sApp & ")")
    Else
        GUICtrlSetData($idViewAppsProgressBar, 0)
        _ViewAppsSetDownloadStatus("apps.status.download_failed")
        Local $sNo = i18nGet("apps.status.no", "No")
        _GUICtrlListView_SetItemText($hViewAppsTable, $g_iViewAppsSelectedRow, $sNo, 4)
        GUICtrlSetData($idViewAppsReadyInput, $sNo)
        MsgBox(BitOR($MB_ICONERROR, $MB_OK), i18nGet("error.dialog.title", "Error"), i18nGet("apps.status.download_failed", "Failed to download setup file") & " (" & $sApp & ")")
        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.download_failed", "Failed to download setup file"))
    EndIf
EndFunc

Func _ViewAppsRefreshSelectedRow()
    If $g_iViewAppsSelectedRow < 0 Or $g_iViewAppsSelectedRow >= $g_iViewAppsAppCount Then Return

    Local $sApp = $g_aViewAppsAppIds[$g_iViewAppsSelectedRow]
    Local $sVer = downloadGetAppVersion($sApp)
    If $sVer = "Unknown" Then $sVer = i18nGet("apps.status.unknown", "Unknown")

    Local $bReady = downloadIsAppReady($sApp)
    Local $sReady = $bReady ? i18nGet("apps.status.yes", "Yes") : i18nGet("apps.status.no", "No")

    _GUICtrlListView_SetItemText($hViewAppsTable, $g_iViewAppsSelectedRow, $sVer, 2)
    _GUICtrlListView_SetItemText($hViewAppsTable, $g_iViewAppsSelectedRow, $sReady, 4)

    _ViewAppsOnSelectRow($g_iViewAppsSelectedRow)
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.refreshed", "Refreshed application information") & " (" & $sApp & ")")
EndFunc

Func _ViewAppsOnClear()
    GUICtrlSetData($idViewAppsShortcutCmb, i18nGet("apps.status.no", "No"))
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.row_cleared", "Cleared edit row fields"))
EndFunc

Func _ViewAppsOnSave()
    If $g_iViewAppsSelectedRow < 0 Or $g_iViewAppsSelectedRow >= $g_iViewAppsAppCount Then Return

    Local $sNewSc = GUICtrlRead($idViewAppsShortcutCmb)
    _GUICtrlListView_SetItemText($hViewAppsTable, $g_iViewAppsSelectedRow, $sNewSc, 3)
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.row_saved", "Saved changes to application entry"))
EndFunc

Func _ViewAppsOnCancel()
    If $g_iViewAppsSelectedRow < 0 Or $g_iViewAppsSelectedRow >= $g_iViewAppsAppCount Then Return

    _ViewAppsOnSelectRow($g_iViewAppsSelectedRow)
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.row_canceled", "Reverted edit row changes"))
EndFunc

Func _ViewAppsBrowseLogPath()
    Local $sCurPath = GUICtrlRead($idViewAppsLogPathInput)
    Local $sInitDir = $sCurPath
    If StringInStr($sInitDir, "\") Then
        $sInitDir = StringLeft($sInitDir, StringInStr($sInitDir, "\", 0, -1))
    EndIf
    Local $sSelected = FileSelectFolder(i18nGet("apps.dialog.browse.title", "Select Log Folder"), $sInitDir)
    If Not @error And $sSelected <> "" Then
        If StringRight($sSelected, 1) <> "\" Then $sSelected &= "\"
        GUICtrlSetData($idViewAppsLogPathInput, $sSelected & "apps.log")
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

            _ViewAppsSetDownloadStatus("apps.status.downloading")
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.downloading", "Downloading setup file...") & " (" & $sApp & ")")
            Local $bOk = downloadApp($sApp, True, "_ViewAppsDownloadCallback")
            If $bOk Then
                Local $sYes = i18nGet("apps.status.yes", "Yes")
                _GUICtrlListView_SetItemText($hViewAppsTable, $i, $sYes, 4)
                GUICtrlSetData($idViewAppsReadyInput, $sYes)
                Local $sVer = downloadGetAppVersion($sApp)
                If $sVer <> "Unknown" Then
                    _GUICtrlListView_SetItemText($hViewAppsTable, $i, $sVer, 2)
                    GUICtrlSetData($idViewAppsVerInput, $sVer)
                EndIf
                _ViewAppsSetDownloadStatus("apps.status.download_done")
                $iDownloaded += 1
            Else
                Local $sNo = i18nGet("apps.status.no", "No")
                _GUICtrlListView_SetItemText($hViewAppsTable, $i, $sNo, 4)
                GUICtrlSetData($idViewAppsReadyInput, $sNo)
                _ViewAppsSetDownloadStatus("apps.status.download_failed")
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

    ; Section 1: Apps Library
    GUICtrlSetData($hViewAppsLibraryGroup, i18nGet("apps.library.title", "Apps Library"))
    GUICtrlSetTip($hViewAppsLibraryGroup, i18nGet("apps.library.tip", "Software catalog and individual application management"))

    GUICtrlSetData($idViewAppsAvailableLbl, i18nGet("apps.available.label", "Available Applications: "))
    GUICtrlSetTip($idViewAppsAvailableLbl, i18nGet("apps.available.tip", "List of software applications available in the library"))
    GUICtrlSetData($idViewAppsResetBtn, i18nGet("apps.btn.reset", "Reset"))
    GUICtrlSetTip($idViewAppsResetBtn, i18nGet("apps.btn.reset.tip", "Deselect all applications for installation"))

    _GUICtrlListView_SetColumn($idViewAppsTable, 0, i18nGet("apps.col.name", "Name"))
    _GUICtrlListView_SetColumn($idViewAppsTable, 1, i18nGet("apps.col.description", "Description"))
    _GUICtrlListView_SetColumn($idViewAppsTable, 2, i18nGet("apps.col.version", "Version"))
    _GUICtrlListView_SetColumn($idViewAppsTable, 3, i18nGet("apps.col.shortcut", "Shortcut"))
    _GUICtrlListView_SetColumn($idViewAppsTable, 4, i18nGet("apps.col.ready", "Ready"))

    ; Edit row tooltips & combobox
    GUICtrlSetTip($idViewAppsNameInput, i18nGet("apps.entry.name.tip", "Selected application name (read-only)"))
    GUICtrlSetTip($idViewAppsDescInput, i18nGet("apps.entry.desc.tip", "Selected application description (read-only)"))
    GUICtrlSetTip($idViewAppsVerInput, i18nGet("apps.entry.version.tip", "Selected application version (read-only)"))
    GUICtrlSetTip($idViewAppsReadyInput, i18nGet("apps.entry.ready.tip", "Selected application setup file readiness (read-only)"))

    Local $sCurSc = GUICtrlRead($idViewAppsShortcutCmb)
    Local $bWasYes = ($sCurSc = "Yes" Or $sCurSc = i18nGet("apps.status.yes", "Yes"))
    GUICtrlSetData($idViewAppsShortcutCmb, "|" & i18nGet("apps.status.yes", "Yes") & "|" & i18nGet("apps.status.no", "No"), $bWasYes ? i18nGet("apps.status.yes", "Yes") : i18nGet("apps.status.no", "No"))
    GUICtrlSetTip($idViewAppsShortcutCmb, i18nGet("apps.entry.shortcut.tip", "Create desktop shortcut after installation"))

    ; Edit row buttons
    GUICtrlSetData($idViewAppsDownloadBtn, i18nGet("apps.entry.download.btn", "Download"))
    GUICtrlSetTip($idViewAppsDownloadBtn, i18nGet("apps.entry.download.tip", "Download setup file for the selected application"))

    GUICtrlSetData($idViewAppsRefreshBtn, i18nGet("apps.btn.refresh", "Refresh"))
    GUICtrlSetTip($idViewAppsRefreshBtn, i18nGet("apps.btn.refresh.tip", "Refresh version and readiness information for the selected application"))

    GUICtrlSetData($idViewAppsClearBtn, i18nGet("apps.btn.clear", "Clear"))
    GUICtrlSetTip($idViewAppsClearBtn, i18nGet("apps.btn.clear.tip", "Reset edit row fields to default values"))

    GUICtrlSetData($idViewAppsSaveBtn, i18nGet("apps.btn.save", "Save"))
    GUICtrlSetTip($idViewAppsSaveBtn, i18nGet("apps.btn.save.tip", "Save edit row changes to the selected application"))

    GUICtrlSetData($idViewAppsCancelBtn, i18nGet("apps.btn.cancel", "Cancel"))
    GUICtrlSetTip($idViewAppsCancelBtn, i18nGet("apps.btn.cancel.tip", "Discard edit row changes and revert to the selected application state"))

    ; Additional controls edit info
    _ViewAppsSetDownloadStatus($g_sViewAppsCurStatusKey)
    GUICtrlSetTip($idViewAppsProgressBar, i18nGet("apps.entry.progress.tip", "Real-time download progress for the selected application"))

    ; Section 2: Auto-installation
    GUICtrlSetData($hViewAppsInstallGroup, i18nGet("apps.autoinstall.title", "Auto-installation"))
    GUICtrlSetTip($hViewAppsInstallGroup, i18nGet("apps.autoinstall.tip", "Configuration settings for unattended application deployment"))

    GUICtrlSetData($idViewAppsMaxIterLbl, i18nGet("apps.maxiter.label", "Max Iteration: "))
    GUICtrlSetTip($idViewAppsMaxIterLbl, i18nGet("apps.maxiter.tip", "Maximum number of installation attempts for each application. Increasing this value may help with applications that fail to install on the first attempt."))
    GUICtrlSetTip($idViewAppsMaxIterInput, i18nGet("apps.maxiter.tip", "Maximum number of installation attempts for each application. Increasing this value may help with applications that fail to install on the first attempt."))
    GUICtrlSetTip($idViewAppsMaxIterUpDown, i18nGet("apps.maxiter.tip", "Maximum number of installation attempts for each application. Increasing this value may help with applications that fail to install on the first attempt."))

    GUICtrlSetData($idViewAppsLogPathLbl, i18nGet("apps.logpath.label", "Log Path: "))
    GUICtrlSetTip($idViewAppsLogPathLbl, i18nGet("apps.logpath.tip", "File path where installation logs will be saved. Changing this value may help with troubleshooting installation issues."))
    GUICtrlSetTip($idViewAppsLogPathInput, i18nGet("apps.logpath.tip", "File path where installation logs will be saved. Changing this value may help with troubleshooting installation issues."))

    GUICtrlSetData($idViewAppsLogBrowseBtn, i18nGet("apps.btn.browse", "Browse"))
    GUICtrlSetTip($idViewAppsLogBrowseBtn, i18nGet("apps.btn.browse.tip", "Select destination folder for installation logs"))

    ; Reload descriptions in table for current language
    Local $aApps = dataLoadCsv("apps.csv")
    If IsArray($aApps) Then
        For $j = 1 To UBound($aApps, 1) - 1
            Local $sDesc = _AppsGetAppDesc($aApps[$j][0], $aApps[$j][2])
            _GUICtrlListView_SetItemText($hViewAppsTable, $j - 1, $sDesc, 1)
        Next
    EndIf

    If $g_iViewAppsSelectedRow >= 0 And $g_iViewAppsSelectedRow < $g_iViewAppsAppCount Then
        GUICtrlSetData($idViewAppsDescInput, _GUICtrlListView_GetItemText($hViewAppsTable, $g_iViewAppsSelectedRow, 1))
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

    GUICtrlSetColor($idViewAppsStatusLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsStatusLbl, themeColor("main.view.bg"))

    GUICtrlSetColor($idViewAppsMaxIterLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsMaxIterLbl, themeColor("main.view.bg"))

    GUICtrlSetColor($idViewAppsLogPathLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsLogPathLbl, themeColor("main.view.bg"))

    Local $aInputs[] = [ _
        $idViewAppsNameInput, _
        $idViewAppsDescInput, _
        $idViewAppsVerInput, _
        $idViewAppsReadyInput, _
        $idViewAppsMaxIterInput, _
        $idViewAppsLogPathInput _
    ]
    For $i = 0 To UBound($aInputs) - 1
        GUICtrlSetColor($aInputs[$i], themeColor("text.primary"))
        GUICtrlSetBkColor($aInputs[$i], themeColor("main.view.bg"))
    Next

    _GUICtrlListView_SetTextColor($idViewAppsTable, themeColor("text.primary"))
    _GUICtrlListView_SetTextBkColor($idViewAppsTable, themeColor("main.view.bg"))
    _GUICtrlListView_SetBkColor($idViewAppsTable, themeColor("main.view.bg"))
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Event Handling
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewAppsHandleEvent($idMsg)
    ; Track ListView row selection changes
    Local $sSel = _GUICtrlListView_GetSelectedIndices($hViewAppsTable)
    If $sSel <> "" Then
        Local $iCurSel = Number($sSel)
        If $iCurSel <> $g_iViewAppsSelectedRow Then
            _ViewAppsOnSelectRow($iCurSel)
        EndIf
    EndIf

    Switch $idMsg
        ; In-View Reset Button
        Case $idViewAppsResetBtn
            _ViewAppsResetSelection()

        ; Table selection
        Case $idViewAppsTable
            _ViewAppsOnSelectRow()

        ; Edit Row Control Buttons
        Case $idViewAppsDownloadBtn
            _ViewAppsDownloadSelectedRow()

        Case $idViewAppsRefreshBtn
            _ViewAppsRefreshSelectedRow()

        Case $idViewAppsClearBtn
            _ViewAppsOnClear()

        Case $idViewAppsSaveBtn
            _ViewAppsOnSave()

        Case $idViewAppsCancelBtn
            _ViewAppsOnCancel()

        ; Auto-installation Log Path Browse Button
        Case $idViewAppsLogBrowseBtn
            _ViewAppsBrowseLogPath()

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
