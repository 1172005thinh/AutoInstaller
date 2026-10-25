;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/drivers.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Libraries
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <SliderConstants.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <GuiComboBox.au3>
#include <FileConstants.au3>

; Controls
#include "../controls/button.au3"

; Modules
#include "../modules/i18n.au3"
#include "../modules/theme.au3"
#include "../modules/config.au3"
#include "../modules/scroll.au3"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Global View Controls & State
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $hViewDrivers = 0
Global $idViewDriversTitle = 0

; 1. Installation Mode Header
Global $hViewDriversModeGroup = 0
Global $idViewDriversModeLbl = 0
Global $idViewDriversModeSlider = 0
Global $idViewDriversModeDisLbl = 0
Global $idViewDriversModeOffLbl = 0
Global $idViewDriversModeOnlLbl = 0
Global $idViewDriversModeHybLbl = 0
Global $g_iViewDriversCurMode = 2 ; 0: Disabled, 1: Offline, 2: Online (default), 3: Hybrid

; 2. Section: Offline Drivers Library
Global $hViewDriversOfflineGroup = 0
Global $idViewDriversOfflineBanner = 0

; 3. Section: Online Drivers Library
Global $hViewDriversOnlineGroup = 0
Global $idViewDriversSourceLbl = 0
Global $idViewDriversSourceCmb = 0
Global $g_sViewDriversCurSource = "sdio" ; "winupdate", "sdio", "both"

; 3.1 Windows Update Component
Global $idViewDriversWinUpdateLbl = 0
Global $idViewDriversWinUpdateSlider = 0
Global $idViewDriversWinUpdateDrvLbl = 0
Global $idViewDriversWinUpdateSecLbl = 0
Global $idViewDriversWinUpdateFullLbl = 0
Global $g_iViewDriversWinUpdateLevel = 1 ; 0: Drivers Only, 1: Drivers + Security (default), 2: Full Updates

; 3.2 SDIO Component
Global $idViewDriversSDIOLbl = 0
Global $idViewDriversSDIOSlider = 0
Global $idViewDriversSDIOBasicLbl = 0
Global $idViewDriversSDIODevLbl = 0
Global $idViewDriversSDIOFullLbl = 0
Global $g_iViewDriversSDIOLevel = 1 ; 0: Basic, 1: Device-Specific (default), 2: Full

; 4. Section: Auto-installation
Global $hViewDriversInstallGroup = 0
Global $idViewDriversLogPathLbl = 0
Global $idViewDriversLogPathInput = 0
Global $idViewDriversLogBrowseBtn = 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Helper Functions & Path Resolution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _GetDriversConfigPath()
    If FileExists(@ScriptDir & "\drivers\config.ini") Then Return @ScriptDir & "\drivers\config.ini"
    If FileExists(@ScriptDir & "\config.ini") Then Return @ScriptDir & "\config.ini"
    Return @ScriptDir & "\drivers\config.ini"
EndFunc

Func _ViewDriversBrowseLogPath()
    Local $sCurPath = GUICtrlRead($idViewDriversLogPathInput)
    Local $sInitDir = $sCurPath
    If StringInStr($sInitDir, "\") Then
        $sInitDir = StringLeft($sInitDir, StringInStr($sInitDir, "\", 0, -1))
    EndIf
    Local $sSelected = FileSelectFolder(i18nGet("drivers.dialog.browse.title", "Select Log Folder"), $sInitDir)
    If Not @error And $sSelected <> "" Then
        If StringRight($sSelected, 1) <> "\" Then $sSelected &= "\"
        GUICtrlSetData($idViewDriversLogPathInput, $sSelected & "drivers.log")
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; View Creation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewDriversCreate($hViewport, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH

    $hViewDrivers = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewDrivers)

    Local $iPx = $iLblH * 20 / 100
    Local $iRowH = $iLblH + $iP * 2
    Local $iInputH = $iLblH + $iPx * 2
    Local $iLblW = ($iContentW - $iP * 6) * 35 / 100
    Local $iInputW = ($iContentW - $iP * 6) * 58 / 100

    ; 1. Title
    Local $iX = $iP
    Local $iY = $iP
    Local $iCtrlW = $iContentW
    Local $iCtrlH = $iLblH * 2
    $idViewDriversTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)

    ; =========================================
    ; Header: Installation Mode Slider
    ; =========================================
    $iY += $iCtrlH + $iP
    Local $iModeGroupH = $iRowH * 2 + $iP * 2
    $hViewDriversModeGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iModeGroupH)

    $iX = $iP * 3
    Local $iItemY = $iY + $iP * 3
    $idViewDriversModeLbl = GUICtrlCreateLabel(i18nGet("drivers.mode.label", "Installation Mode: "), $iX, $iItemY, $iLblW, $iLblH)

    $idViewDriversModeSlider = GUICtrlCreateSlider($iP * 3 + $iLblW, $iItemY - $iPx, $iInputW, $iInputH)
    GUICtrlSetLimit($idViewDriversModeSlider, 3, 0)
    GUICtrlSetData($idViewDriversModeSlider, 2) ; Default: Online

    Local $iSliderX = $iP * 3 + $iLblW
    Local $iTickLblY = $iItemY + $iLblH + $iPx

    ; Evenly distributed 4-state label geometry (matching apps.au3)
    Local $iMargin = 14
    Local $iStepW = ($iInputW - ($iMargin * 2)) / 3

    Local $iSplit1 = Int($iMargin + ($iStepW / 2))
    Local $iSplit2 = Int($iMargin + ($iStepW * 1.5))
    Local $iSplit3 = Int($iMargin + ($iStepW * 2.5))

    Local $iCol0W = $iSplit1
    Local $iCol1W = $iSplit2 - $iSplit1
    Local $iCol2W = $iSplit3 - $iSplit2
    Local $iCol3W = $iInputW - $iSplit3

    $idViewDriversModeDisLbl = GUICtrlCreateLabel(i18nGet("drivers.mode.disabled.label", "Disabled"), $iSliderX, $iTickLblY, $iCol0W, $iLblH)
    $idViewDriversModeOffLbl = GUICtrlCreateLabel(i18nGet("drivers.mode.offline.label", "Offline"), $iSliderX + $iSplit1, $iTickLblY, $iCol1W, $iLblH, $SS_CENTER)
    $idViewDriversModeOnlLbl = GUICtrlCreateLabel(i18nGet("drivers.mode.online.label", "Online"), $iSliderX + $iSplit2, $iTickLblY, $iCol2W, $iLblH, $SS_CENTER)
    $idViewDriversModeHybLbl = GUICtrlCreateLabel(i18nGet("drivers.mode.hybrid.label", "Hybrid"), $iSliderX + $iSplit3, $iTickLblY, $iCol3W, $iLblH, $SS_RIGHT)
    GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; =========================================
    ; Section 1: Offline Drivers Library
    ; =========================================
    $iX = $iP
    $iY += $iModeGroupH + $iP
    Local $iOfflineGroupH = $iRowH * 2 + $iP * 2
    $hViewDriversOfflineGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iOfflineGroupH)

    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    Local $iBannerW = $iContentW - $iP * 6
    Local $iBannerH = $iRowH + $iP
    $idViewDriversOfflineBanner = GUICtrlCreateLabel(i18nGet("drivers.offline.banner", "Under development..."), $iX, $iItemY, $iBannerW, $iBannerH, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    GUICtrlSetFont(-1, $iBullet, 600)
    GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; =========================================
    ; Section 2: Online Drivers Library
    ; =========================================
    $iX = $iP
    $iY += $iOfflineGroupH + $iP
    Local $iOnlineGroupH = $iRowH * 5 + $iP * 1
    $hViewDriversOnlineGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iOnlineGroupH)

    ; Row 1: Driver Sources ComboBox
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewDriversSourceLbl = GUICtrlCreateLabel(i18nGet("drivers.online.source.label", "Driver Sources: "), $iX, $iItemY, $iLblW, $iLblH)

    $idViewDriversSourceCmb = GUICtrlCreateCombo("", $iSliderX, $iItemY - $iPx, $iInputW, $iInputH, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
    _GUICtrlComboBox_AddString($idViewDriversSourceCmb, i18nGet("drivers.online.source.winupdate", "Windows Update"))
    _GUICtrlComboBox_AddString($idViewDriversSourceCmb, i18nGet("drivers.online.source.sdio", "SDIO"))
    _GUICtrlComboBox_AddString($idViewDriversSourceCmb, i18nGet("drivers.online.source.both", "Both"))
    _GUICtrlComboBox_SetCurSel($idViewDriversSourceCmb, 1) ; Default: SDIO (index 1)

    ; Row 2: Windows Update Component
    $iItemY += $iRowH + $iP
    $idViewDriversWinUpdateLbl = GUICtrlCreateLabel(i18nGet("drivers.winupdate.label", "Windows Update: "), $iX, $iItemY, $iLblW, $iLblH)

    $idViewDriversWinUpdateSlider = GUICtrlCreateSlider($iSliderX, $iItemY - $iPx, $iInputW, $iInputH)
    GUICtrlSetLimit($idViewDriversWinUpdateSlider, 2, 0)
    GUICtrlSetData($idViewDriversWinUpdateSlider, 1) ; Default: Drivers + Security

    Local $iWuTickY = $iItemY + $iLblH + $iPx
    Local $iWuTickColW = $iInputW / 3
    $idViewDriversWinUpdateDrvLbl = GUICtrlCreateLabel(i18nGet("drivers.winupdate.level.drivers", "Drivers Only"), $iSliderX, $iWuTickY, $iWuTickColW, $iLblH)
    $idViewDriversWinUpdateSecLbl = GUICtrlCreateLabel(i18nGet("drivers.winupdate.level.security", "Drivers + Security"), $iSliderX + $iWuTickColW, $iWuTickY, $iWuTickColW, $iLblH, $SS_CENTER)
    $idViewDriversWinUpdateFullLbl = GUICtrlCreateLabel(i18nGet("drivers.winupdate.level.full", "Full Updates"), $iSliderX + $iWuTickColW * 2, $iWuTickY, $iWuTickColW, $iLblH, $SS_RIGHT)

    ; Row 3: SDIO Component
    $iItemY += $iRowH + $iP * 2
    $idViewDriversSDIOLbl = GUICtrlCreateLabel(i18nGet("drivers.sdio.label", "SDIO: "), $iX, $iItemY, $iLblW, $iLblH)

    $idViewDriversSDIOSlider = GUICtrlCreateSlider($iSliderX, $iItemY - $iPx, $iInputW, $iInputH)
    GUICtrlSetLimit($idViewDriversSDIOSlider, 2, 0)
    GUICtrlSetData($idViewDriversSDIOSlider, 1) ; Default: Device-Specific

    Local $iSdioTickY = $iItemY + $iLblH + $iPx
    Local $iSdioTickColW = $iInputW / 3
    $idViewDriversSDIOBasicLbl = GUICtrlCreateLabel(i18nGet("drivers.sdio.level.basic", "Basic"), $iSliderX, $iSdioTickY, $iSdioTickColW, $iLblH)
    $idViewDriversSDIODevLbl = GUICtrlCreateLabel(i18nGet("drivers.sdio.level.device", "Device-Specific"), $iSliderX + $iSdioTickColW, $iSdioTickY, $iSdioTickColW, $iLblH, $SS_CENTER)
    $idViewDriversSDIOFullLbl = GUICtrlCreateLabel(i18nGet("drivers.sdio.level.full", "Full"), $iSliderX + $iSdioTickColW * 2, $iSdioTickY, $iSdioTickColW, $iLblH, $SS_RIGHT)
    GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; =========================================
    ; Section 3: Auto-installation
    ; =========================================
    $iX = $iP
    $iY += $iOnlineGroupH + $iP
    Local $iInstallGroupH = $iRowH + $iP * 3
    $hViewDriversInstallGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iInstallGroupH)

    ; Log Path Row
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    Local $iBrowseBtnW = 75
    Local $iLogInputW = $iInputW - $iBrowseBtnW - $iPx
    $idViewDriversLogPathLbl = GUICtrlCreateLabel(i18nGet("drivers.logpath.label", "Log Path: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewDriversLogPathInput = GUICtrlCreateInput("C:\AutoInstaller\drivers.log", $iSliderX, $iItemY - $iPx, $iLogInputW, $iInputH)
    $idViewDriversLogBrowseBtn = GUICtrlCreateButton(i18nGet("drivers.btn.browse", "Browse..."), $iSliderX + $iLogInputW + $iPx, $iItemY - $iPx, $iBrowseBtnW, $iInputH)
    GUICtrlCreateGroup("", -99, -99, -99, -99)

    Local $iContentBottom = $iY + $iInstallGroupH + $iP
    If $iContentBottom < $iH Then $iContentBottom = $iH
    scrollSetContentHeight($hViewDrivers, $iContentBottom)

    viewDriversApplyLang()
    viewDriversApplyTheme()
    viewDriversLoadData()

    Return $hViewDrivers
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State Management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _ViewDriversUpdateModeState($iMode)
    $g_iViewDriversCurMode = $iMode
    GUICtrlSetData($idViewDriversModeSlider, $iMode)

    Local $iOffState = $GUI_DISABLE
    Local $iOnlState = $GUI_DISABLE

    Switch $iMode
        Case 0 ; Disabled
            $iOffState = $GUI_DISABLE
            $iOnlState = $GUI_DISABLE
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("drivers.mode.status.disabled", "Driver installation mode: Disabled"))

        Case 1 ; Offline
            $iOffState = $GUI_ENABLE
            $iOnlState = $GUI_DISABLE
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("drivers.mode.status.offline", "Driver installation mode: Offline (local packages)"))

        Case 2 ; Online
            $iOffState = $GUI_DISABLE
            $iOnlState = $GUI_ENABLE
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("drivers.mode.status.online", "Driver installation mode: Online"))

        Case 3 ; Hybrid
            $iOffState = $GUI_ENABLE
            $iOnlState = $GUI_ENABLE
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("drivers.mode.status.hybrid", "Driver installation mode: Hybrid (both Offline and Online enabled)"))
    EndSwitch

    ; Offline section state
    GUICtrlSetState($idViewDriversOfflineBanner, $iOffState)

    ; Online section state
    GUICtrlSetState($idViewDriversSourceLbl, $iOnlState)
    GUICtrlSetState($idViewDriversSourceCmb, $iOnlState)

    If $iOnlState = $GUI_ENABLE Then
        _ViewDriversUpdateSourceState($g_sViewDriversCurSource)
    Else
        _ViewDriversSetWinUpdateState($GUI_DISABLE)
        _ViewDriversSetSDIOState($GUI_DISABLE)
    EndIf
EndFunc

Func _ViewDriversUpdateSourceState($sSource)
    $g_sViewDriversCurSource = StringLower($sSource)

    Local $iSel = 1
    Switch $g_sViewDriversCurSource
        Case "winupdate", "windows update"
            $g_sViewDriversCurSource = "winupdate"
            $iSel = 0
            If $g_iViewDriversCurMode = 2 Or $g_iViewDriversCurMode = 3 Then
                _ViewDriversSetWinUpdateState($GUI_ENABLE)
                _ViewDriversSetSDIOState($GUI_DISABLE)
            EndIf

        Case "sdio"
            $g_sViewDriversCurSource = "sdio"
            $iSel = 1
            If $g_iViewDriversCurMode = 2 Or $g_iViewDriversCurMode = 3 Then
                _ViewDriversSetWinUpdateState($GUI_DISABLE)
                _ViewDriversSetSDIOState($GUI_ENABLE)
            EndIf

        Case "both"
            $g_sViewDriversCurSource = "both"
            $iSel = 2
            If $g_iViewDriversCurMode = 2 Or $g_iViewDriversCurMode = 3 Then
                _ViewDriversSetWinUpdateState($GUI_ENABLE)
                _ViewDriversSetSDIOState($GUI_ENABLE)
            EndIf
    EndSwitch

    _GUICtrlComboBox_SetCurSel($idViewDriversSourceCmb, $iSel)
EndFunc

Func _ViewDriversSetWinUpdateState($iState)
    GUICtrlSetState($idViewDriversWinUpdateLbl, $iState)
    GUICtrlSetState($idViewDriversWinUpdateSlider, $iState)
    GUICtrlSetState($idViewDriversWinUpdateDrvLbl, $iState)
    GUICtrlSetState($idViewDriversWinUpdateSecLbl, $iState)
    GUICtrlSetState($idViewDriversWinUpdateFullLbl, $iState)
EndFunc

Func _ViewDriversSetSDIOState($iState)
    GUICtrlSetState($idViewDriversSDIOLbl, $iState)
    GUICtrlSetState($idViewDriversSDIOSlider, $iState)
    GUICtrlSetState($idViewDriversSDIOBasicLbl, $iState)
    GUICtrlSetState($idViewDriversSDIODevLbl, $iState)
    GUICtrlSetState($idViewDriversSDIOFullLbl, $iState)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration Persistence
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewDriversLoadData($sCustomFile = "")
    Local $sConfig = ($sCustomFile <> "" And FileExists($sCustomFile)) ? $sCustomFile : _GetDriversConfigPath()
    If Not FileExists($sConfig) Then Return False

    Local $iMode = Int(IniRead($sConfig, "Configuration", "mode", "2"))
    Local $sSource = IniRead($sConfig, "Configuration", "source", "sdio")
    Local $iWuLevel = Int(IniRead($sConfig, "Configuration", "winupdate_level", "1"))
    Local $iSdioLevel = Int(IniRead($sConfig, "Configuration", "sdio_level", "1"))
    Local $sLogPath = IniRead($sConfig, "Configuration", "log_path", "C:\AutoInstaller\drivers.log")

    $g_iViewDriversWinUpdateLevel = $iWuLevel
    GUICtrlSetData($idViewDriversWinUpdateSlider, $iWuLevel)

    $g_iViewDriversSDIOLevel = $iSdioLevel
    GUICtrlSetData($idViewDriversSDIOSlider, $iSdioLevel)

    GUICtrlSetData($idViewDriversLogPathInput, $sLogPath)

    $g_sViewDriversCurSource = $sSource
    _ViewDriversUpdateSourceState($sSource)
    _ViewDriversUpdateModeState($iMode)
    Return True
EndFunc

Func viewDriversSaveData($sCustomFile = "")
    Local $sBaseConfig = _GetDriversConfigPath()
    Local $sConfig = $sBaseConfig
    If $sCustomFile <> "" Then
        $sConfig = $sCustomFile
        If Not FileExists($sConfig) And FileExists($sBaseConfig) Then
            FileCopy($sBaseConfig, $sConfig, $FC_OVERWRITE)
        EndIf
    EndIf

    Local $sDir = StringLeft($sConfig, StringInStr($sConfig, "\", 0, -1) - 1)
    If $sDir <> "" And Not FileExists($sDir) Then DirCreate($sDir)

    IniWrite($sConfig, "Configuration", "mode", String($g_iViewDriversCurMode))
    IniWrite($sConfig, "Configuration", "source", $g_sViewDriversCurSource)
    IniWrite($sConfig, "Configuration", "winupdate_level", String($g_iViewDriversWinUpdateLevel))
    IniWrite($sConfig, "Configuration", "sdio_level", String($g_iViewDriversSDIOLevel))
    IniWrite($sConfig, "Configuration", "log_path", GUICtrlRead($idViewDriversLogPathInput))
    Return True
EndFunc

Func viewDriversReset()
    $g_iViewDriversWinUpdateLevel = 1
    GUICtrlSetData($idViewDriversWinUpdateSlider, 1)

    $g_iViewDriversSDIOLevel = 1
    GUICtrlSetData($idViewDriversSDIOSlider, 1)

    GUICtrlSetData($idViewDriversLogPathInput, "C:\AutoInstaller\drivers.log")

    _ViewDriversUpdateSourceState("sdio")
    _ViewDriversUpdateModeState(2)
EndFunc

Func _ViewDriversImportConfig()
    Local $sImportFile = FileOpenDialog(i18nGet("drivers.dialog.import.title", "Select driver configuration to import"), @ScriptDir, i18nGet("drivers.dialog.import.filter", "Configuration files (*.ini)|All files (*.*)"), BitOR($FD_FILEMUSTEXIST, $FD_PATHMUSTEXIST))
    If Not @error And $sImportFile <> "" Then
        If viewDriversLoadData($sImportFile) Then
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("drivers.status.imported", "Imported driver configuration successfully"))
        Else
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.error", "Error"))
        EndIf
    EndIf
EndFunc

Func _ViewDriversExportConfig()
    Local $sExportFile = FileSaveDialog(i18nGet("drivers.dialog.export.title", "Export driver configuration"), @ScriptDir, i18nGet("drivers.dialog.export.filter", "Configuration files (*.ini)|All files (*.*)"), $FD_PROMPTOVERWRITE, "config.ini")
    If Not @error And $sExportFile <> "" Then
        If Not StringRegExp($sExportFile, '(?i)\.ini$') Then $sExportFile &= ".ini"
        If viewDriversSaveData($sExportFile) Then
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("drivers.status.exported", "Exported driver configuration successfully"))
        Else
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.error", "Error"))
        EndIf
    EndIf
EndFunc

Func _ViewDriversOpenConfigFile()
    Local $sConfig = _GetDriversConfigPath()
    If FileExists($sConfig) Then
        ShellExecute($sConfig)
        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("drivers.status.opened", "Opened driver configuration in editor"))
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Localization & Theming
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewDriversApplyLang()
    GUICtrlSetData($idViewDriversTitle, i18nGet("drivers.title", "Customize Driver Installation"))

    ; Header Mode Slider
    GUICtrlSetData($hViewDriversModeGroup, i18nGet("drivers.mode.title", "Installation Mode"))
    GUICtrlSetTip($hViewDriversModeGroup, i18nGet("drivers.mode.tip", "Switch between Disabled, Offline, Online, and Hybrid driver installation modes"))
    GUICtrlSetData($idViewDriversModeLbl, i18nGet("drivers.mode.label", "Installation Mode: "))
    GUICtrlSetData($idViewDriversModeDisLbl, i18nGet("drivers.mode.disabled.label", "Disabled"))
    GUICtrlSetTip($idViewDriversModeDisLbl, i18nGet("drivers.mode.disabled.tip", "Disable all driver installations"))
    GUICtrlSetData($idViewDriversModeOffLbl, i18nGet("drivers.mode.offline.label", "Offline"))
    GUICtrlSetTip($idViewDriversModeOffLbl, i18nGet("drivers.mode.offline.tip", "Install drivers from local sources only"))
    GUICtrlSetData($idViewDriversModeOnlLbl, i18nGet("drivers.mode.online.label", "Online"))
    GUICtrlSetTip($idViewDriversModeOnlLbl, i18nGet("drivers.mode.online.tip", "Install drivers from online sources only"))
    GUICtrlSetData($idViewDriversModeHybLbl, i18nGet("drivers.mode.hybrid.label", "Hybrid"))
    GUICtrlSetTip($idViewDriversModeHybLbl, i18nGet("drivers.mode.hybrid.tip", "Install drivers from both local and online sources"))

    ; Section 1: Offline
    GUICtrlSetData($hViewDriversOfflineGroup, i18nGet("drivers.offline.title", "Offline Drivers Library"))
    GUICtrlSetTip($hViewDriversOfflineGroup, i18nGet("drivers.offline.tip", "Manage and extract drivers from local media"))
    GUICtrlSetData($idViewDriversOfflineBanner, i18nGet("drivers.offline.banner", "Under development..."))
    GUICtrlSetTip($idViewDriversOfflineBanner, i18nGet("drivers.offline.banner.tip", "Offline driver extraction and local package repository management is currently being implemented"))

    ; Section 2: Online
    GUICtrlSetData($hViewDriversOnlineGroup, i18nGet("drivers.online.title", "Online Drivers Library"))
    GUICtrlSetTip($hViewDriversOnlineGroup, i18nGet("drivers.online.tip", "Configure automated online driver retrieval sources"))

    ; Driver Sources
    GUICtrlSetData($idViewDriversSourceLbl, i18nGet("drivers.online.source.label", "Driver Sources: "))
    GUICtrlSetTip($idViewDriversSourceLbl, i18nGet("drivers.online.source.tip", "Select which online driver source(s) to use"))

    _GUICtrlComboBox_ResetContent($idViewDriversSourceCmb)
    _GUICtrlComboBox_AddString($idViewDriversSourceCmb, i18nGet("drivers.online.source.winupdate", "Windows Update"))
    _GUICtrlComboBox_AddString($idViewDriversSourceCmb, i18nGet("drivers.online.source.sdio", "SDIO"))
    _GUICtrlComboBox_AddString($idViewDriversSourceCmb, i18nGet("drivers.online.source.both", "Both"))
    _ViewDriversUpdateSourceState($g_sViewDriversCurSource)

    ; Windows Update Slider
    GUICtrlSetData($idViewDriversWinUpdateLbl, i18nGet("drivers.winupdate.label", "Windows Update: "))
    GUICtrlSetTip($idViewDriversWinUpdateLbl, i18nGet("drivers.winupdate.tip", "Configure the scope of updates retrieved via Windows Update"))
    GUICtrlSetData($idViewDriversWinUpdateDrvLbl, i18nGet("drivers.winupdate.level.drivers", "Drivers Only"))
    GUICtrlSetTip($idViewDriversWinUpdateDrvLbl, i18nGet("drivers.winupdate.level.drivers.tip", "Install only driver updates via Windows Update"))
    GUICtrlSetData($idViewDriversWinUpdateSecLbl, i18nGet("drivers.winupdate.level.security", "Drivers + Security"))
    GUICtrlSetTip($idViewDriversWinUpdateSecLbl, i18nGet("drivers.winupdate.level.security.tip", "Install driver and security updates via Windows Update"))
    GUICtrlSetData($idViewDriversWinUpdateFullLbl, i18nGet("drivers.winupdate.level.full", "Full Updates"))
    GUICtrlSetTip($idViewDriversWinUpdateFullLbl, i18nGet("drivers.winupdate.level.full.tip", "Install all available updates (drivers, security, features) via Windows Update"))

    ; SDIO Slider
    GUICtrlSetData($idViewDriversSDIOLbl, i18nGet("drivers.sdio.label", "SDIO: "))
    GUICtrlSetTip($idViewDriversSDIOLbl, i18nGet("drivers.sdio.tip", "Configure the installation mode for Snappy Driver Installer Origin"))
    GUICtrlSetData($idViewDriversSDIOBasicLbl, i18nGet("drivers.sdio.level.basic", "Basic"))
    GUICtrlSetTip($idViewDriversSDIOBasicLbl, i18nGet("drivers.sdio.level.basic.tip", "Install only missing critical drivers"))
    GUICtrlSetData($idViewDriversSDIODevLbl, i18nGet("drivers.sdio.level.device", "Device-Specific"))
    GUICtrlSetTip($idViewDriversSDIODevLbl, i18nGet("drivers.sdio.level.device.tip", "Install missing drivers and optimal device-specific updates"))
    GUICtrlSetData($idViewDriversSDIOFullLbl, i18nGet("drivers.sdio.level.full", "Full"))
    GUICtrlSetTip($idViewDriversSDIOFullLbl, i18nGet("drivers.sdio.level.full.tip", "Install all available matching and alternative drivers"))

    ; Section 3: Auto-installation
    GUICtrlSetData($hViewDriversInstallGroup, i18nGet("drivers.autoinstall.title", "Auto-installation"))
    GUICtrlSetTip($hViewDriversInstallGroup, i18nGet("drivers.autoinstall.tip", "Configuration settings for driver deployment and logging"))
    GUICtrlSetData($idViewDriversLogPathLbl, i18nGet("drivers.logpath.label", "Log Path: "))
    GUICtrlSetTip($idViewDriversLogPathLbl, i18nGet("drivers.logpath.tip", "File path where driver installation logs will be saved"))
    GUICtrlSetTip($idViewDriversLogPathInput, i18nGet("drivers.logpath.tip", "File path where driver installation logs will be saved"))
    GUICtrlSetData($idViewDriversLogBrowseBtn, i18nGet("drivers.btn.browse", "Browse..."))
    GUICtrlSetTip($idViewDriversLogBrowseBtn, i18nGet("drivers.btn.browse.tip", "Select destination folder for driver installation logs"))

    ; Toolbar Buttons
    If $g_hCurrentView = $hViewDrivers Then
        GUICtrlSetData($a_idToolBarBtn[0], i18nGet("reset.btn.title", "Reset"))
        GUICtrlSetTip($a_idToolBarBtn[0], i18nGet("drivers.toolbar.reset.tip", "Reset all driver installation settings to defaults"))
        GUICtrlSetData($a_idToolBarBtn[1], i18nGet("import.btn.title", "Import"))
        GUICtrlSetTip($a_idToolBarBtn[1], i18nGet("drivers.toolbar.import.tip", "Import driver configuration file"))
        GUICtrlSetData($a_idToolBarBtn[2], i18nGet("export.btn.title", "Export"))
        GUICtrlSetTip($a_idToolBarBtn[2], i18nGet("drivers.toolbar.export.tip", "Export driver configuration to file"))
        GUICtrlSetData($a_idToolBarBtn[3], i18nGet("open.btn.title", "Open"))
        GUICtrlSetTip($a_idToolBarBtn[3], i18nGet("drivers.toolbar.open.tip", "Open driver configuration file in text editor"))
        GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("save.btn.title", "Save"))
        GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("drivers.toolbar.save.tip", "Save driver configuration to config.ini"))
        GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.title", "Cancel"))
        GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.tip", "Discard changes and reload saved configuration"))
    EndIf
EndFunc

Func viewDriversToolBar()
    ; Button Index 0: [Reset]
    GUICtrlSetData($a_idToolBarBtn[0], i18nGet("reset.btn.title", "Reset"))
    GUICtrlSetTip($a_idToolBarBtn[0], i18nGet("drivers.toolbar.reset.tip", "Reset all driver installation settings to defaults"))
    GUICtrlSetState($a_idToolBarBtn[0], $GUI_SHOW)

    ; Button Index 1: [Import]
    GUICtrlSetData($a_idToolBarBtn[1], i18nGet("import.btn.title", "Import"))
    GUICtrlSetTip($a_idToolBarBtn[1], i18nGet("drivers.toolbar.import.tip", "Import driver configuration file"))
    GUICtrlSetState($a_idToolBarBtn[1], $GUI_SHOW)

    ; Button Index 2: [Export]
    GUICtrlSetData($a_idToolBarBtn[2], i18nGet("export.btn.title", "Export"))
    GUICtrlSetTip($a_idToolBarBtn[2], i18nGet("drivers.toolbar.export.tip", "Export driver configuration to file"))
    GUICtrlSetState($a_idToolBarBtn[2], $GUI_SHOW)

    ; Button Index 3: [Open]
    GUICtrlSetData($a_idToolBarBtn[3], i18nGet("open.btn.title", "Open"))
    GUICtrlSetTip($a_idToolBarBtn[3], i18nGet("drivers.toolbar.open.tip", "Open driver configuration file in text editor"))
    GUICtrlSetState($a_idToolBarBtn[3], $GUI_SHOW)

    ; Button Index 6: [Save]
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("save.btn.title", "Save"))
    GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("drivers.toolbar.save.tip", "Save driver configuration to config.ini"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 2], $GUI_SHOW)

    ; Button Index 7: [Cancel]
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.title", "Cancel"))
    GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.tip", "Discard changes and reload saved configuration"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 1], $GUI_SHOW)
EndFunc

Func viewDriversApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hViewDrivers)

    GUICtrlSetColor($idViewDriversTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversTitle, themeColor("main.view.bg"))

    ; Header
    GUICtrlSetBkColor($idViewDriversModeSlider, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewDriversModeLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversModeLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewDriversModeDisLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversModeDisLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewDriversModeOffLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversModeOffLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewDriversModeOnlLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversModeOnlLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewDriversModeHybLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversModeHybLbl, themeColor("main.view.bg"))

    ; Offline Section
    GUICtrlSetColor($idViewDriversOfflineBanner, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversOfflineBanner, themeColor("main.view.bg"))

    ; Online Section
    GUICtrlSetColor($idViewDriversSourceLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversSourceLbl, themeColor("main.view.bg"))

    ; Windows Update
    GUICtrlSetBkColor($idViewDriversWinUpdateSlider, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewDriversWinUpdateLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversWinUpdateLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewDriversWinUpdateDrvLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversWinUpdateDrvLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewDriversWinUpdateSecLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversWinUpdateSecLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewDriversWinUpdateFullLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversWinUpdateFullLbl, themeColor("main.view.bg"))

    ; SDIO
    GUICtrlSetBkColor($idViewDriversSDIOSlider, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewDriversSDIOLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversSDIOLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewDriversSDIOBasicLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversSDIOBasicLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewDriversSDIODevLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversSDIODevLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewDriversSDIOFullLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversSDIOFullLbl, themeColor("main.view.bg"))

    ; Auto-installation
    GUICtrlSetColor($idViewDriversLogPathLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversLogPathLbl, themeColor("main.view.bg"))
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Event Dispatcher
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewDriversHandleEvent($idMsg)
    Switch $idMsg
        ; Installation Mode Events
        Case $idViewDriversModeDisLbl
            _ViewDriversUpdateModeState(0)

        Case $idViewDriversModeOffLbl
            _ViewDriversUpdateModeState(1)

        Case $idViewDriversModeOnlLbl
            _ViewDriversUpdateModeState(2)

        Case $idViewDriversModeHybLbl
            _ViewDriversUpdateModeState(3)

        Case $idViewDriversModeSlider
            _ViewDriversUpdateModeState(GUICtrlRead($idViewDriversModeSlider))

        ; Online Driver Source ComboBox
        Case $idViewDriversSourceCmb
            Local $iSel = _GUICtrlComboBox_GetCurSel($idViewDriversSourceCmb)
            Switch $iSel
                Case 0
                    _ViewDriversUpdateSourceState("winupdate")
                Case 1
                    _ViewDriversUpdateSourceState("sdio")
                Case 2
                    _ViewDriversUpdateSourceState("both")
            EndSwitch

        ; Windows Update Slider
        Case $idViewDriversWinUpdateDrvLbl
            $g_iViewDriversWinUpdateLevel = 0
            GUICtrlSetData($idViewDriversWinUpdateSlider, 0)

        Case $idViewDriversWinUpdateSecLbl
            $g_iViewDriversWinUpdateLevel = 1
            GUICtrlSetData($idViewDriversWinUpdateSlider, 1)

        Case $idViewDriversWinUpdateFullLbl
            $g_iViewDriversWinUpdateLevel = 2
            GUICtrlSetData($idViewDriversWinUpdateSlider, 2)

        Case $idViewDriversWinUpdateSlider
            $g_iViewDriversWinUpdateLevel = GUICtrlRead($idViewDriversWinUpdateSlider)

        ; SDIO Slider
        Case $idViewDriversSDIOBasicLbl
            $g_iViewDriversSDIOLevel = 0
            GUICtrlSetData($idViewDriversSDIOSlider, 0)

        Case $idViewDriversSDIODevLbl
            $g_iViewDriversSDIOLevel = 1
            GUICtrlSetData($idViewDriversSDIOSlider, 1)

        Case $idViewDriversSDIOFullLbl
            $g_iViewDriversSDIOLevel = 2
            GUICtrlSetData($idViewDriversSDIOSlider, 2)

        Case $idViewDriversSDIOSlider
            $g_iViewDriversSDIOLevel = GUICtrlRead($idViewDriversSDIOSlider)

        ; Auto-installation Log Path Browse Button
        Case $idViewDriversLogBrowseBtn
            _ViewDriversBrowseLogPath()

        ; Toolbar Button 0: [Reset]
        Case $a_idToolBarBtn[0]
            viewDriversReset()
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("drivers.status.reset", "Reset driver installation settings to defaults"))

        ; Toolbar Button 1: [Import]
        Case $a_idToolBarBtn[1]
            _ViewDriversImportConfig()

        ; Toolbar Button 2: [Export]
        Case $a_idToolBarBtn[2]
            _ViewDriversExportConfig()

        ; Toolbar Button 3: [Open]
        Case $a_idToolBarBtn[3]
            _ViewDriversOpenConfigFile()

        ; Toolbar Button 6: [Save]
        Case $a_idToolBarBtn[$iToolBarBtnCol - 2]
            If viewDriversSaveData() Then
                appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("drivers.status.saved", "Saved driver configuration successfully"))
            Else
                appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.error", "Error"))
            EndIf

        ; Toolbar Button 7: [Cancel]
        Case $a_idToolBarBtn[$iToolBarBtnCol - 1]
            viewDriversLoadData()
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("drivers.status.canceled", "Reverted driver selections to saved configuration"))
    EndSwitch
EndFunc
