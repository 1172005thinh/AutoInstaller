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
#include <StaticConstants.au3>
#include <SliderConstants.au3>
#include <FileConstants.au3>
#include <GuiStatusBar.au3>
#include <GuiListView.au3>
#include <ButtonConstants.au3>
#include <GuiEdit.au3>
#include <GuiComboBox.au3>

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

; Mode Selection Header
Global $hViewAppsModeGroup = 0
Global $idViewAppsModeLbl = 0
Global $idViewAppsModeSlider = 0
Global $idViewAppsModeDisLbl = 0
Global $idViewAppsModeOffLbl = 0
Global $idViewAppsModeOnlLbl = 0
Global $g_iViewAppsCurMode = 2 ; 0: Disabled, 1: Offline, 2: Online (default)

; Section 1: Online Apps Library
Global $hViewAppsOnlineGroup = 0
Global $idViewAppsOnlineInfoLbl = 0
Global $idViewAppsOnlineResetBtn = 0
Global $idViewAppsOnlineTable = 0
Global $hViewAppsOnlineTable = 0
Global $idViewAppsOnlineSelectAllBtn = 0
Global $idViewAppsOnlineAddBtn = 0
Global $idViewAppsOnlineRemoveBtn = 0
Global $idViewAppsOnlineEditBtn = 0

; Section 2: Offline Apps Library
Global $hViewAppsOfflineGroup = 0
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

; Section 3: Fonts Library
Global $hViewAppsFontsGroup = 0
Global $idViewAppsFontsSliderLbl = 0
Global $idViewAppsFontsSlider = 0
Global $idViewAppsFontsDisLbl = 0
Global $idViewAppsFontsInstLbl = 0
Global $g_iViewAppsFontsState = 1 ; 0: Disabled, 1: Install (default)
Global $idViewAppsFontsAvailableLbl = 0
Global $idViewAppsFontsResetBtn = 0
Global $idViewAppsFontsTable = 0
Global $hViewAppsFontsTable = 0
Global $idViewAppsFontsSelectAllBtn = 0
Global $idViewAppsFontsAddBtn = 0
Global $idViewAppsFontsRemoveBtn = 0

; Section 4: Auto-installation
Global $hViewAppsInstallGroup = 0
Global $idViewAppsMaxIterLbl = 0
Global $idViewAppsMaxIterInput = 0
Global $idViewAppsMaxIterUpDown = 0

Global $idViewAppsLogPathLbl = 0
Global $idViewAppsLogPathInput = 0
Global $idViewAppsLogBrowseBtn = 0

; Internal State Tracking
Global $g_aViewAppsAppIds[64]
Global $g_iViewAppsAppCount = 0
Global $g_iViewAppsSelectedRow = -1
Global $g_sViewAppsCurStatusKey = "apps.status.not_downloaded"
Global $g_iViewAppsOnlineSelectedRow = -1
Global $g_aViewAppsOnlineIds[128]
Global $g_iViewAppsOnlineCount = 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Helper Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; View Creation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewAppsCreate($hViewport, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH
    If $iContentH < 1350 Then $iContentH = 1350

    $hViewApps = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewApps)

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
    $idViewAppsTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)

    ; =========================================
    ; Header: Mode Selection Slider
    ; =========================================
    $iY += $iCtrlH + $iP
    Local $iModeGroupH = $iRowH * 2 + $iP * 2
    $hViewAppsModeGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iModeGroupH)

    $iX = $iP * 3
    Local $iItemY = $iY + $iP * 3
    $idViewAppsModeLbl = GUICtrlCreateLabel(i18nGet("apps.mode.label", "Installation Mode: "), $iX, $iItemY, $iLblW, $iLblH)

    $idViewAppsModeSlider = GUICtrlCreateSlider($iP * 3 + $iLblW, $iItemY - $iPx, $iInputW, $iInputH)
    GUICtrlSetLimit($idViewAppsModeSlider, 2, 0)
    GUICtrlSetData($idViewAppsModeSlider, 2) ; Default: Online

    Local $iTickLblY = $iItemY + $iLblH + $iPx
    Local $iTickColW = $iInputW / 3
    $idViewAppsModeDisLbl = GUICtrlCreateLabel(i18nGet("apps.mode.disabled.label", "Disabled"), $iP * 3 + $iLblW, $iTickLblY, $iTickColW, $iLblH)
    $idViewAppsModeOffLbl = GUICtrlCreateLabel(i18nGet("apps.mode.offline.label", "Offline"), $iP * 3 + $iLblW + $iTickColW, $iTickLblY, $iTickColW, $iLblH, $SS_CENTER)
    $idViewAppsModeOnlLbl = GUICtrlCreateLabel(i18nGet("apps.mode.online.label", "Online"), $iP * 3 + $iLblW + $iTickColW * 2, $iTickLblY, $iTickColW, $iLblH, $SS_RIGHT)

    ; =========================================
    ; Section 1: Online Apps Library
    ; =========================================
    $iX = $iP
    $iY += $iModeGroupH + $iP
    Local $iOnlineGroupH = $iRowH * 10 + $iP * 7
    $hViewAppsOnlineGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iOnlineGroupH)

    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    Local $iTableW = $iContentW - $iP * 4
    Local $iBtnW = ($iTableW * 92 / 100 - 4 * $iP) / 5

    $idViewAppsOnlineInfoLbl = GUICtrlCreateLabel(i18nGet("apps.online.info.label", "Requires an active internet connection."), $iX, $iItemY + $iPx, $iTableW - $iBtnW - $iP, $iLblH)
    $idViewAppsOnlineResetBtn = GUICtrlCreateButton(i18nGet("apps.online.btn.reset", "Reset"), ($iX + $iTableW) - $iBtnW, $iItemY - $iPx, $iBtnW, $iBtnH)

    $iItemY += $iRowH + $iP
    Local $iOnlineTableH = $iRowH * 8
    Local $sOnlineHeaders = i18nGet("apps.online.col.name", "App name") & "|" & _
        i18nGet("apps.online.col.description", "Description") & "|" & _
        i18nGet("apps.online.col.version", "Version") & "|" & _
        i18nGet("apps.online.col.shortcut", "Shortcut") & "|" & _
        i18nGet("apps.online.col.location", "Location")
    $idViewAppsOnlineTable = GUICtrlCreateListView($sOnlineHeaders, $iX, $iItemY, $iTableW, $iOnlineTableH)
    $hViewAppsOnlineTable = GUICtrlGetHandle($idViewAppsOnlineTable)
    _GUICtrlListView_SetExtendedListViewStyle($idViewAppsOnlineTable, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))

    Local $iOnCol0W = Int($iTableW * 27 / 100) ; App name
    Local $iOnCol1W = Int($iTableW * 34 / 100) ; Description
    Local $iOnCol2W = Int($iTableW * 13 / 100) ; Version
    Local $iOnCol3W = Int($iTableW * 12 / 100) ; Shortcut
    Local $iOnCol4W = $iTableW - ($iOnCol0W + $iOnCol1W + $iOnCol2W + $iOnCol3W) - 2 * $iP - 2 * $iPx ; Location

    _GUICtrlListView_SetColumnWidth($idViewAppsOnlineTable, 0, $iOnCol0W)
    _GUICtrlListView_SetColumnWidth($idViewAppsOnlineTable, 1, $iOnCol1W)
    _GUICtrlListView_SetColumnWidth($idViewAppsOnlineTable, 2, $iOnCol2W)
    _GUICtrlListView_SetColumnWidth($idViewAppsOnlineTable, 3, $iOnCol3W)
    _GUICtrlListView_SetColumnWidth($idViewAppsOnlineTable, 4, $iOnCol4W)

    ; Online Action Buttons
    $iItemY += $iOnlineTableH + $iP
    Local $iOnBtnRowW = 4 * $iBtnW + 3 * $iP
    Local $iOnBtnStartX = ($iX + $iTableW) - $iOnBtnRowW
    $idViewAppsOnlineSelectAllBtn = GUICtrlCreateButton(i18nGet("apps.online.btn.select_all", "Select All"), $iOnBtnStartX, $iItemY, $iBtnW, $iBtnH)
    $idViewAppsOnlineAddBtn = GUICtrlCreateButton(i18nGet("apps.online.btn.add", "Add"), $iOnBtnStartX + $iBtnW + $iP, $iItemY, $iBtnW, $iBtnH)
    $idViewAppsOnlineRemoveBtn = GUICtrlCreateButton(i18nGet("apps.online.btn.remove", "Remove"), $iOnBtnStartX + ($iBtnW + $iP) * 2, $iItemY, $iBtnW, $iBtnH)
    $idViewAppsOnlineEditBtn = GUICtrlCreateButton(i18nGet("apps.online.btn.edit", "Edit"), $iOnBtnStartX + ($iBtnW + $iP) * 3, $iItemY, $iBtnW, $iBtnH)
    GUICtrlSetState($idViewAppsOnlineEditBtn, $GUI_DISABLE)

    ; =========================================
    ; Section 2: Offline Apps Library
    ; =========================================
    $iX = $iP
    $iY += $iOnlineGroupH + $iP
    Local $iOfflineGroupH = $iRowH * 12 + $iP * 6
    $hViewAppsOfflineGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iOfflineGroupH)

    $iX = $iP * 3
    $iItemY = $iY + $iP * 3

    $idViewAppsAvailableLbl = GUICtrlCreateLabel("", $iX, $iItemY + $iPx, $iTableW - $iBtnW - $iP, $iLblH)
    $idViewAppsResetBtn = GUICtrlCreateButton(i18nGet("apps.btn.reset", "Reset"), ($iX + $iTableW) - $iBtnW, $iItemY - $iPx, $iBtnW, $iBtnH)

    $iItemY += $iRowH + $iP
    Local $iTableH = $iRowH * 8
    Local $sOfflineHeaders = i18nGet("apps.col.name", "Name") & "|" & _
        i18nGet("apps.col.description", "Description") & "|" & _
        i18nGet("apps.col.version", "Version") & "|" & _
        i18nGet("apps.col.shortcut", "Shortcut") & "|" & _
        i18nGet("apps.col.ready", "Ready")
    $idViewAppsTable = GUICtrlCreateListView($sOfflineHeaders, $iX, $iItemY, $iTableW, $iTableH)
    $hViewAppsTable = GUICtrlGetHandle($idViewAppsTable)
    _GUICtrlListView_SetExtendedListViewStyle($idViewAppsTable, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))

    Local $iCol0W = Int($iTableW * 27 / 100) ; Name
    Local $iCol1W = Int($iTableW * 34 / 100) ; Description
    Local $iCol2W = Int($iTableW * 13 / 100) ; Version
    Local $iCol3W = Int($iTableW * 12 / 100) ; Shortcut
    Local $iCol4W = $iTableW - ($iCol0W + $iCol1W + $iCol2W + $iCol3W) - 2 * $iP - 2 * $iPx ; Ready

    _GUICtrlListView_SetColumnWidth($idViewAppsTable, 0, $iCol0W)
    _GUICtrlListView_SetColumnWidth($idViewAppsTable, 1, $iCol1W)
    _GUICtrlListView_SetColumnWidth($idViewAppsTable, 2, $iCol2W)
    _GUICtrlListView_SetColumnWidth($idViewAppsTable, 3, $iCol3W)
    _GUICtrlListView_SetColumnWidth($idViewAppsTable, 4, $iCol4W)

    ; Edit Row (ReadOnly inputs are disabled per prompt instruction)
    $iItemY += $iTableH + $iP
    Local $iEditX = $iX
    $idViewAppsNameInput = GUICtrlCreateInput("", $iEditX, $iItemY, $iCol0W - $iPx, $iInputH, BitOR($ES_READONLY, $ES_AUTOHSCROLL))
    GUICtrlSetState($idViewAppsNameInput, $GUI_DISABLE)

    $iEditX += $iCol0W
    $idViewAppsDescInput = GUICtrlCreateInput("", $iEditX + $iPx, $iItemY, $iCol1W - 2 * $iPx, $iInputH, BitOR($ES_READONLY, $ES_AUTOHSCROLL))
    GUICtrlSetState($idViewAppsDescInput, $GUI_DISABLE)

    $iEditX += $iCol1W
    $idViewAppsVerInput = GUICtrlCreateInput("", $iEditX + $iPx, $iItemY, $iCol2W - 2 * $iPx, $iInputH, BitOR($ES_READONLY, $ES_AUTOHSCROLL))
    GUICtrlSetState($idViewAppsVerInput, $GUI_DISABLE)

    $iEditX += $iCol2W
    $idViewAppsShortcutCmb = GUICtrlCreateCombo("", $iEditX + $iPx, $iItemY, $iCol3W - 2 * $iPx, $iInputH, $CBS_DROPDOWNLIST)
    GUICtrlSetData($idViewAppsShortcutCmb, i18nGet("apps.status.yes", "Yes") & "|" & i18nGet("apps.status.no", "No"), i18nGet("apps.status.no", "No"))

    $iEditX += $iCol3W
    $idViewAppsReadyInput = GUICtrlCreateInput("", $iEditX + $iPx, $iItemY, ($iX + $iTableW) - ($iEditX + $iPx), $iInputH, BitOR($ES_READONLY, $ES_AUTOHSCROLL))
    GUICtrlSetState($idViewAppsReadyInput, $GUI_DISABLE)

    ; Control Edit Row Buttons
    $iItemY += $iRowH
    Local $iBtnRowW = 5 * $iBtnW + 4 * $iP
    Local $iBtnStartX = ($iX + $iTableW) - $iBtnRowW
    $idViewAppsDownloadBtn = GUICtrlCreateButton(i18nGet("apps.entry.download.btn", "Download"), $iBtnStartX, $iItemY, $iBtnW, $iBtnH)
    $idViewAppsRefreshBtn = GUICtrlCreateButton(i18nGet("apps.btn.refresh", "Refresh"), $iBtnStartX + $iBtnW + $iP, $iItemY, $iBtnW, $iBtnH)
    $idViewAppsClearBtn = GUICtrlCreateButton(i18nGet("apps.btn.clear", "Clear"), $iBtnStartX + ($iBtnW + $iP) * 2, $iItemY, $iBtnW, $iBtnH)
    $idViewAppsSaveBtn = GUICtrlCreateButton(i18nGet("apps.btn.save", "Save"), $iBtnStartX + ($iBtnW + $iP) * 3, $iItemY, $iBtnW, $iBtnH)
    $idViewAppsCancelBtn = GUICtrlCreateButton(i18nGet("apps.btn.cancel", "Cancel"), $iBtnStartX + ($iBtnW + $iP) * 4, $iItemY, $iBtnW, $iBtnH)

    ; Download Info: Status Label + Progress Bar
    $iItemY += $iRowH + $iP
    Local $iStatusLblW = Int($iTableW * 35 / 100)
    $idViewAppsStatusLbl = GUICtrlCreateLabel("", $iX, $iItemY + $iPx, $iStatusLblW, $iLblH)
    $idViewAppsProgressBar = GUICtrlCreateProgress($iX + $iStatusLblW + $iP, $iItemY, $iTableW - $iStatusLblW - $iP, $iInputH, $PBS_SMOOTH)

    ; =========================================
    ; Section 3: Fonts Library
    ; =========================================
    $iX = $iP
    $iY += $iOfflineGroupH + $iP
    Local $iFontsGroupH = $iRowH * 10 + $iP * 12
    $hViewAppsFontsGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iFontsGroupH)

    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewAppsFontsSliderLbl = GUICtrlCreateLabel(i18nGet("apps.fonts.slider.label", "Fonts Installation: "), $iX, $iItemY, $iLblW, $iLblH)

    $idViewAppsFontsSlider = GUICtrlCreateSlider($iP * 3 + $iLblW, $iItemY - $iPx, $iInputW, $iInputH)
    GUICtrlSetLimit($idViewAppsFontsSlider, 1, 0)
    GUICtrlSetData($idViewAppsFontsSlider, 1) ; Default: Install

    Local $iFontsTickY = $iItemY + $iLblH + $iPx
    Local $iFontsTickColW = $iInputW / 2
    $idViewAppsFontsDisLbl = GUICtrlCreateLabel(i18nGet("apps.fonts.disabled.label", "Disabled"), $iP * 3 + $iLblW, $iFontsTickY, $iFontsTickColW, $iLblH)
    $idViewAppsFontsInstLbl = GUICtrlCreateLabel(i18nGet("apps.fonts.install.label", "Install"), $iP * 3 + $iLblW + $iFontsTickColW, $iFontsTickY, $iFontsTickColW, $iLblH, $SS_RIGHT)

    ; Fonts Table Header & Reset Button
    $iItemY += $iRowH + $iP
    $idViewAppsFontsAvailableLbl = GUICtrlCreateLabel(i18nGet("apps.fonts.available.label", "Available Fonts: "), $iX, $iItemY + $iPx, $iTableW - $iBtnW - $iP, $iLblH)
    $idViewAppsFontsResetBtn = GUICtrlCreateButton(i18nGet("apps.fonts.btn.reset", "Reset"), ($iX + $iTableW) - $iBtnW, $iItemY - $iPx, $iBtnW, $iBtnH)

    ; Fonts ListView Table
    $iItemY += $iRowH + $iP
    Local $iFontsTableH = $iRowH * 8
    Local $sFontsHeaders = i18nGet("apps.fonts.col.name", "Font name") & "|" & _
        i18nGet("apps.fonts.col.location", "Location")

    $idViewAppsFontsTable = GUICtrlCreateListView($sFontsHeaders, $iX, $iItemY, $iTableW, $iFontsTableH)
    $hViewAppsFontsTable = GUICtrlGetHandle($idViewAppsFontsTable)
    _GUICtrlListView_SetExtendedListViewStyle($idViewAppsFontsTable, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))

    Local $iFCol0W = Int($iTableW * 27 / 100) ; Font name
    Local $iFCol1W = $iTableW - $iFCol0W - 2 * $iP - 2 * $iPx ; Location

    _GUICtrlListView_SetColumnWidth($idViewAppsFontsTable, 0, $iFCol0W)
    _GUICtrlListView_SetColumnWidth($idViewAppsFontsTable, 1, $iFCol1W)

    ; Fonts Control Buttons
    $iItemY += $iFontsTableH + $iP
    Local $iFBtnRowW = 3 * $iBtnW + 2 * $iP
    Local $iFBtnStartX = ($iX + $iTableW) - $iFBtnRowW
    $idViewAppsFontsSelectAllBtn = GUICtrlCreateButton(i18nGet("apps.fonts.btn.select_all", "Select All"), $iFBtnStartX, $iItemY, $iBtnW, $iBtnH)
    $idViewAppsFontsAddBtn = GUICtrlCreateButton(i18nGet("apps.fonts.btn.add", "Add"), $iFBtnStartX + $iBtnW + $iP, $iItemY, $iBtnW, $iBtnH)
    $idViewAppsFontsRemoveBtn = GUICtrlCreateButton(i18nGet("apps.fonts.btn.remove", "Remove"), $iFBtnStartX + ($iBtnW + $iP) * 2, $iItemY, $iBtnW, $iBtnH)

    ; =========================================
    ; Section 4: Auto-installation
    ; =========================================
    $iX = $iP
    $iY += $iFontsGroupH + $iP
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

    ; Load data
    viewAppsLoadData()
    _ViewAppsFontsReset()

    viewAppsApplyLang()
    viewAppsApplyTheme()
    Return $hViewApps
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Mode & State Controllers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _ViewAppsUpdateModeState($iMode)
    $g_iViewAppsCurMode = $iMode
    GUICtrlSetData($idViewAppsModeSlider, $iMode)

    Local $iOnState = $GUI_DISABLE
    Local $iOffState = $GUI_DISABLE

    Switch $iMode
        Case 0 ; Disabled
            $iOnState = $GUI_DISABLE
            $iOffState = $GUI_DISABLE
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.mode.status.disabled", "Apps installation is disabled (skipped)"))

        Case 1 ; Offline
            $iOnState = $GUI_DISABLE
            $iOffState = $GUI_ENABLE
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.mode.status.offline", "Installation mode: Offline (using local offline installers)"))

        Case 2 ; Online
            $iOnState = $GUI_ENABLE
            $iOffState = $GUI_DISABLE
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.mode.status.online", "Installation mode: Online (using winget package manager)"))
    EndSwitch

    ; Online controls
    GUICtrlSetState($idViewAppsOnlineResetBtn, $iOnState)
    GUICtrlSetState($idViewAppsOnlineTable, $iOnState)
    GUICtrlSetState($idViewAppsOnlineSelectAllBtn, $iOnState)
    GUICtrlSetState($idViewAppsOnlineAddBtn, $iOnState)
    GUICtrlSetState($idViewAppsOnlineRemoveBtn, $iOnState)
    If $iOnState = $GUI_ENABLE And _GUICtrlListView_GetSelectedCount($hViewAppsOnlineTable) == 1 Then
        GUICtrlSetState($idViewAppsOnlineEditBtn, $GUI_ENABLE)
    Else
        GUICtrlSetState($idViewAppsOnlineEditBtn, $GUI_DISABLE)
    EndIf

    ; Offline controls
    GUICtrlSetState($idViewAppsResetBtn, $iOffState)
    GUICtrlSetState($idViewAppsTable, $iOffState)
    GUICtrlSetState($idViewAppsShortcutCmb, $iOffState)
    GUICtrlSetState($idViewAppsDownloadBtn, $iOffState)
    GUICtrlSetState($idViewAppsRefreshBtn, $iOffState)
    GUICtrlSetState($idViewAppsClearBtn, $iOffState)
    GUICtrlSetState($idViewAppsSaveBtn, $iOffState)
    GUICtrlSetState($idViewAppsCancelBtn, $iOffState)
    GUICtrlSetState($idViewAppsProgressBar, $iOffState)
EndFunc

Func _ViewAppsUpdateFontsState($iState)
    $g_iViewAppsFontsState = $iState
    GUICtrlSetData($idViewAppsFontsSlider, $iState)

    Local $iOptState = ($iState = 1) ? $GUI_ENABLE : $GUI_DISABLE

    GUICtrlSetState($idViewAppsFontsResetBtn, $iOptState)
    GUICtrlSetState($idViewAppsFontsTable, $iOptState)
    GUICtrlSetState($idViewAppsFontsSelectAllBtn, $iOptState)
    GUICtrlSetState($idViewAppsFontsAddBtn, $iOptState)
    GUICtrlSetState($idViewAppsFontsRemoveBtn, $iOptState)

    If $iState = 1 Then
        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.fonts.status.install", "Fonts installation mode: Install"))
    Else
        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.fonts.status.disabled", "Fonts installation is disabled (skipped)"))
    EndIf
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

    ; Read mode and fonts_state from [Configuration]
    Local $iMode = Int(IniRead($sConfig, "Configuration", "mode", "2"))
    _ViewAppsUpdateModeState($iMode)

    Local $iFontsState = Int(IniRead($sConfig, "Configuration", "fonts_state", "1"))
    _ViewAppsUpdateFontsState($iFontsState)

    ; Load Offline Apps
    Local $aApps = dataLoadCsv("apps.csv")
    If IsArray($aApps) And UBound($aApps, 1) >= 2 Then
        For $i = 1 To UBound($aApps, 1) - 1
            Local $sApp = $aApps[$i][0]
            If $sApp = "Fonts" Then ContinueLoop ; Fonts handled separately

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
    EndIf

    ; Load Online Apps
    _GUICtrlListView_DeleteAllItems($hViewAppsOnlineTable)
    $g_iViewAppsOnlineCount = 0
    $g_iViewAppsOnlineSelectedRow = -1
    For $r = 0 To UBound($g_aViewAppsOnlineIds) - 1
        $g_aViewAppsOnlineIds[$r] = ""
    Next

    Local $aSections = IniReadSectionNames($sConfig)
    If Not @error And IsArray($aSections) Then
        For $s = 1 To $aSections[0]
            Local $sSec = $aSections[$s]
            If StringLeft($sSec, 7) = "Online_" Then
                Local $sId = IniRead($sConfig, $sSec, "id", StringTrimLeft($sSec, 7))
                Local $sName = IniRead($sConfig, $sSec, "name", $sId)
                Local $sDesc = IniRead($sConfig, $sSec, "description", "")
                Local $sVer = IniRead($sConfig, $sSec, "version", "Latest")
                Local $bShortcut = (StringLower(IniRead($sConfig, $sSec, "shortcut", "false")) = "true")
                Local $sShortcut = $bShortcut ? i18nGet("apps.status.yes", "Yes") : i18nGet("apps.status.no", "No")
                Local $sLoc = IniRead($sConfig, $sSec, "location", i18nGet("apps.online.status.default", "Default"))
                Local $bInstall = (StringLower(IniRead($sConfig, $sSec, "install", "true")) = "true")

                Local $iOnItem = _GUICtrlListView_AddItem($hViewAppsOnlineTable, $sName)
                _GUICtrlListView_AddSubItem($hViewAppsOnlineTable, $iOnItem, $sDesc, 1)
                _GUICtrlListView_AddSubItem($hViewAppsOnlineTable, $iOnItem, $sVer, 2)
                _GUICtrlListView_AddSubItem($hViewAppsOnlineTable, $iOnItem, $sShortcut, 3)
                _GUICtrlListView_AddSubItem($hViewAppsOnlineTable, $iOnItem, $sLoc, 4)
                _GUICtrlListView_SetItemChecked($hViewAppsOnlineTable, $iOnItem, $bInstall)

                If $iOnItem >= UBound($g_aViewAppsOnlineIds) Then ReDim $g_aViewAppsOnlineIds[$iOnItem + 32]
                $g_aViewAppsOnlineIds[$iOnItem] = $sId
                $g_iViewAppsOnlineCount = $iOnItem + 1
            EndIf
        Next
    EndIf

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

    ; Save mode and fonts_state
    IniWrite($sConfig, "Configuration", "mode", String($g_iViewAppsCurMode))
    IniWrite($sConfig, "Configuration", "fonts_state", String($g_iViewAppsFontsState))

    ; Save Offline Apps
    For $i = 0 To $g_iViewAppsAppCount - 1
        Local $sApp = $g_aViewAppsAppIds[$i]
        Local $bChecked = _GUICtrlListView_GetItemChecked($hViewAppsTable, $i)
        Local $sSc = _GUICtrlListView_GetItemText($hViewAppsTable, $i, 3)
        Local $bShortcut = ($sSc = i18nGet("apps.status.yes", "Yes") Or StringLower($sSc) = "yes")

        IniWrite($sConfig, $sApp, "install", $bChecked ? "true" : "false")
        IniWrite($sConfig, $sApp, "shortcut", $bShortcut ? "true" : "false")
    Next

    ; Clean existing [Online_*] sections
    Local $aSections = IniReadSectionNames($sConfig)
    If Not @error And IsArray($aSections) Then
        For $s = 1 To $aSections[0]
            If StringLeft($aSections[$s], 7) = "Online_" Then
                IniDelete($sConfig, $aSections[$s])
            EndIf
        Next
    EndIf

    ; Save Online Apps
    Local $iOnlineCount = _GUICtrlListView_GetItemCount($hViewAppsOnlineTable)
    For $j = 0 To $iOnlineCount - 1
        Local $sName = _GUICtrlListView_GetItemText($hViewAppsOnlineTable, $j, 0)
        Local $sDesc = _GUICtrlListView_GetItemText($hViewAppsOnlineTable, $j, 1)
        Local $sVer = _GUICtrlListView_GetItemText($hViewAppsOnlineTable, $j, 2)
        Local $sSc = _GUICtrlListView_GetItemText($hViewAppsOnlineTable, $j, 3)
        Local $bShortcut = ($sSc = i18nGet("apps.status.yes", "Yes") Or StringLower($sSc) = "yes")
        Local $sLoc = _GUICtrlListView_GetItemText($hViewAppsOnlineTable, $j, 4)
        Local $bInstall = _GUICtrlListView_GetItemChecked($hViewAppsOnlineTable, $j)
        Local $sId = ($j < $g_iViewAppsOnlineCount And $g_aViewAppsOnlineIds[$j] <> "") ? $g_aViewAppsOnlineIds[$j] : $sName

        Local $sSection = "Online_" & $sId
        IniWrite($sConfig, $sSection, "name", $sName)
        IniWrite($sConfig, $sSection, "id", $sId)
        IniWrite($sConfig, $sSection, "description", $sDesc)
        IniWrite($sConfig, $sSection, "version", $sVer)
        IniWrite($sConfig, $sSection, "shortcut", $bShortcut ? "true" : "false")
        IniWrite($sConfig, $sSection, "location", $sLoc)
        IniWrite($sConfig, $sSection, "install", $bInstall ? "true" : "false")
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
; Online Apps Library Operations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _ViewAppsOnlineReset()
    _GUICtrlListView_DeleteAllItems($hViewAppsOnlineTable)
    $g_iViewAppsOnlineSelectedRow = -1
    $g_iViewAppsOnlineCount = 0
    For $r = 0 To UBound($g_aViewAppsOnlineIds) - 1
        $g_aViewAppsOnlineIds[$r] = ""
    Next
    GUICtrlSetState($idViewAppsOnlineEditBtn, $GUI_DISABLE)
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.online.btn.reset.tip", "Reset online applications list to empty"))
EndFunc

Func _ViewAppsOnlineSelectAll()
    Local $iCount = _GUICtrlListView_GetItemCount($hViewAppsOnlineTable)
    For $i = 0 To $iCount - 1
        _GUICtrlListView_SetItemChecked($hViewAppsOnlineTable, $i, True)
    Next
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.online.btn.select_all.tip", "Select all applications in the online list"))
EndFunc

Func _ViewAppsOnlineRemove()
    Local $sSel = _GUICtrlListView_GetSelectedIndices($hViewAppsOnlineTable)
    If $sSel = "" Then Return
    Local $iIdx = Number($sSel)
    _GUICtrlListView_DeleteItem($hViewAppsOnlineTable, $iIdx)
    If $iIdx < $g_iViewAppsOnlineCount Then
        For $k = $iIdx To $g_iViewAppsOnlineCount - 2
            $g_aViewAppsOnlineIds[$k] = $g_aViewAppsOnlineIds[$k + 1]
        Next
        $g_aViewAppsOnlineIds[$g_iViewAppsOnlineCount - 1] = ""
        $g_iViewAppsOnlineCount -= 1
    EndIf
    $g_iViewAppsOnlineSelectedRow = -1
    GUICtrlSetState($idViewAppsOnlineEditBtn, $GUI_DISABLE)
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.online.status.removed", "Removed selected application from online list"))
EndFunc

Func _ViewAppsOnlineOnSelect()
    Local $sSel = _GUICtrlListView_GetSelectedIndices($hViewAppsOnlineTable)
    If $sSel <> "" Then
        $g_iViewAppsOnlineSelectedRow = Number($sSel)
        If $g_iViewAppsCurMode = 2 Then GUICtrlSetState($idViewAppsOnlineEditBtn, $GUI_ENABLE)
    Else
        $g_iViewAppsOnlineSelectedRow = -1
        GUICtrlSetState($idViewAppsOnlineEditBtn, $GUI_DISABLE)
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Winget Search Engine & Fallback Catalog
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _ViewAppsSearchWinget($sQuery)
    Local $aResults[0][4] ; [Name, Id, Desc, Versions]
    If StringStripWS($sQuery, 3) = "" Then Return $aResults

        ; Fallback Curated Catalog with rich descriptions and version options
    Local $aCatalog[11][4] = [ _
        ["Git", "Git.Git", "Fast, scalable, distributed revision control system", "Latest|2.55.0|2.54.0|2.53.0"], _
        ["Google Chrome", "Google.Chrome", "Fast and secure web browser by Google", "Latest"], _
        ["Visual Studio Code", "Microsoft.VisualStudioCode", "Code editing redefined by Microsoft", "Latest|1.94.0|1.93.0"], _
        ["7-Zip", "7zip.7zip", "High compression ratio file archiver", "Latest|24.08|23.01"], _
        ["Discord", "Discord.Discord", "Voice, video and text communication service", "Latest"], _
        ["VLC media player", "VideoLAN.VLC", "Free and open source cross-platform multimedia player", "Latest|3.0.21|3.0.20"], _
        ["Notepad++", "Notepad++.Notepad++", "Free source code editor and Notepad replacement", "Latest|8.7.0|8.6.9"], _
        ["Python 3.12", "Python.Python.3.12", "High-level programming language with dynamic semantics", "Latest|3.12.7|3.12.6"], _
        ["Docker Desktop", "Docker.DockerDesktop", "Container application development platform", "Latest|4.35.0|4.34.0"], _
        ["Brave Browser", "Brave.Brave", "Privacy-oriented browser blocking trackers and ads", "Latest"], _
        ["Zalo", "VNGCorp.Zalo", "Instant messaging and social networking app", "Latest|26.10.20"] _
    ]

    ; Attempt CLI winget search
    Local $sTempOut = @TempDir & "\winget_search_" & @AutoItPID & ".txt"
    If FileExists($sTempOut) Then FileDelete($sTempOut)

    Local $iExit = RunWait(@ComSpec & ' /c chcp 65001 >nul & winget search "' & $sQuery & '" --accept-source-agreements > "' & $sTempOut & '"', @SystemDir, @SW_HIDE)
    If $iExit = 0 And FileExists($sTempOut) Then
        Local $hFile = FileOpen($sTempOut, BitOR($FO_READ, $FO_UTF8_NOBOM))
        If $hFile <> -1 Then
            Local $sText = FileRead($hFile)
            FileClose($hFile)
            FileDelete($sTempOut)

            Local $aLines = StringSplit(StringStripCR($sText), @LF)
            Local $iHeaderLine = -1
            Local $iSepLine = -1

            For $i = 1 To $aLines[0]
                If StringInStr($aLines[$i], "---") Then
                    $iSepLine = $i
                    $iHeaderLine = $i - 1
                    ExitLoop
                EndIf
            Next

            If $iHeaderLine > 0 Then
                Local $sHeader = $aLines[$iHeaderLine]
                Local $iIdPos = StringInStr($sHeader, "Id")
                Local $iVerPos = StringInStr($sHeader, "Version")
                Local $iMatchPos = StringInStr($sHeader, "Match")
                Local $iSourcePos = StringInStr($sHeader, "Source")

                Local $iNextPos = -1
                If $iMatchPos > $iVerPos Then $iNextPos = $iMatchPos
                If $iSourcePos > $iVerPos And ($iNextPos = -1 Or $iSourcePos < $iNextPos) Then $iNextPos = $iSourcePos

                For $j = $iSepLine + 1 To $aLines[0]
                    Local $sLine = $aLines[$j]
                    If StringStripWS($sLine, 3) = "" Then ContinueLoop

                    Local $sName = "", $sId = "", $sVer = ""
                    If $iIdPos > 1 Then
                        $sName = StringStripWS(StringMid($sLine, 1, $iIdPos - 1), 3)
                        If $iVerPos > $iIdPos Then
                            $sId = StringStripWS(StringMid($sLine, $iIdPos, $iVerPos - $iIdPos), 3)
                        Else
                            $sId = StringStripWS(StringMid($sLine, $iIdPos), 3)
                        EndIf

                        If $iNextPos > $iVerPos Then
                            $sVer = StringStripWS(StringMid($sLine, $iVerPos, $iNextPos - $iVerPos), 3)
                        ElseIf $iVerPos > 0 Then
                            $sVer = StringStripWS(StringMid($sLine, $iVerPos), 3)
                        EndIf
                    EndIf

                    ; Fallback regex if column parsing yielded empty ID
                    If $sId = "" Then
                        Local $aParts = StringRegExp($sLine, '^(.+?)\s+([^\s]+)\s+([^\s]+)', 1)
                        If Not @error And UBound($aParts) >= 3 Then
                            $sName = StringStripWS($aParts[0], 3)
                            $sId = StringStripWS($aParts[1], 3)
                            $sVer = StringStripWS($aParts[2], 3)
                        EndIf
                    EndIf

                    If $sId <> "" And $sName <> "" Then
                        Local $sDesc = ""
                        Local $sVersions = "Latest"
                        If $sVer <> "" And $sVer <> "Unknown" Then $sVersions &= "|" & $sVer

                        For $c = 0 To UBound($aCatalog, 1) - 1
                            If StringCompare($aCatalog[$c][1], $sId, 1) = 0 Or StringCompare($aCatalog[$c][0], $sName, 1) = 0 Then
                                $sDesc = $aCatalog[$c][2]
                                $sVersions = $aCatalog[$c][3]
                                ExitLoop
                            EndIf
                        Next

                        If $sDesc = "" Then
                            $sDesc = StringFormat(i18nGet("apps.online.desc.winget", "%s package from winget repository"), $sName)
                        EndIf

                        Local $iNewIdx = UBound($aResults, 1)
                        ReDim $aResults[$iNewIdx + 1][4]
                        $aResults[$iNewIdx][0] = $sName
                        $aResults[$iNewIdx][1] = $sId
                        $aResults[$iNewIdx][2] = $sDesc
                        $aResults[$iNewIdx][3] = $sVersions
                    EndIf
                Next
            EndIf
        EndIf
    EndIf
    If FileExists($sTempOut) Then FileDelete($sTempOut)

    ; If winget search gave results, return them
    If UBound($aResults, 1) > 0 Then Return $aResults

    ; Fallback Catalog matching
    For $j = 0 To UBound($aCatalog, 1) - 1
        If StringInStr($aCatalog[$j][0], $sQuery) > 0 Or StringInStr($aCatalog[$j][1], $sQuery) > 0 Then
            Local $iCur = UBound($aResults, 1)
            ReDim $aResults[$iCur + 1][4]
            $aResults[$iCur][0] = $aCatalog[$j][0]
            $aResults[$iCur][1] = $aCatalog[$j][1]
            $aResults[$iCur][2] = $aCatalog[$j][2]
            $aResults[$iCur][3] = $aCatalog[$j][3]
        EndIf
    Next

    Return $aResults
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Add App Dialog (Modal, 400x300)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _ViewAppsShowAddDialog()
    Local $hAddDlg = GUICreate(i18nGet("apps.dialog.add.title", "Add App"), 560, 500, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOPMOST, $hViewApps)
    GUISetBkColor(themeColor("main.view.bg"), $hAddDlg)

    ; Status Bar
    Local $hStatus = _GUICtrlStatusBar_Create($hAddDlg)
    _GUICtrlStatusBar_SetText($hStatus, i18nGet("apps.dialog.status.ready", "Ready"), 0)

    ; Group 1: Search & Selection
    Local $idSearchGroup = GUICtrlCreateGroup(i18nGet("apps.dialog.group.search", "Search & Selection"), 12, 10, 536, 205)
    Local $idNameInput = GUICtrlCreateInput("", 24, 34, 406, 24)
    _SetCueBannerW($idNameInput, i18nGet("apps.dialog.appname.placeholder", "App Name"), True)
    GUICtrlSetTip($idNameInput, i18nGet("apps.dialog.appname.tip", "Enter app name to search in winget repository"))

    Local $idSearchBtn = GUICtrlCreateButton(i18nGet("apps.dialog.btn.search", "Search"), 438, 34, 98, 24, $BS_DEFPUSHBUTTON)
    GUICtrlSetTip($idSearchBtn, i18nGet("apps.dialog.btn.search.tip", "Search for application in winget repository"))

    ; Keyboard accelerator: Enter key triggers search button
    Local $aAccel[1][2] = [["{ENTER}", $idSearchBtn]]
    GUISetAccelerators($aAccel, $hAddDlg)

    ; Search Results List (Columns: Name, ID, Version)
    Local $sColHeaders = i18nGet("apps.dialog.col.name", "App name") & "|" & _
        i18nGet("apps.dialog.col.id", "App ID") & "|" & _
        i18nGet("apps.dialog.col.version", "Version")
    Local $idResultsList = GUICtrlCreateListView($sColHeaders, 24, 68, 512, 136)
    _GUICtrlListView_SetExtendedListViewStyle($idResultsList, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))
    _GUICtrlListView_SetColumnWidth($idResultsList, 0, 180)
    _GUICtrlListView_SetColumnWidth($idResultsList, 1, 200)
    _GUICtrlListView_SetColumnWidth($idResultsList, 2, 110)
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    ; Group 2: Package Configuration
    Local $idConfigGroup = GUICtrlCreateGroup(i18nGet("apps.dialog.group.config", "Package Configuration"), 12, 222, 536, 205)

    ; Name row
    Local $idNameLbl = GUICtrlCreateLabel(i18nGet("apps.dialog.appname.label", "App Name: "), 24, 246, 85, 20)
    Local $idAppNameInput = GUICtrlCreateInput("", 115, 244, 421, 22, BitOR($ES_READONLY, $ES_AUTOHSCROLL))
    GUICtrlSetState($idAppNameInput, $GUI_DISABLE)

    ; Description row
    Local $idDescLbl = GUICtrlCreateLabel(i18nGet("apps.dialog.desc.label", "Description: "), 24, 276, 85, 20)
    Local $idDescInput = GUICtrlCreateInput("", 115, 274, 421, 22, BitOR($ES_READONLY, $ES_AUTOHSCROLL))
    GUICtrlSetState($idDescInput, $GUI_DISABLE)

    ; Version & Shortcut row
    Local $idVerLbl = GUICtrlCreateLabel(i18nGet("apps.dialog.version.label", "Version: "), 24, 306, 85, 20)
    Local $idVerCmb = GUICtrlCreateCombo("", 115, 304, 110, 22, $CBS_DROPDOWNLIST)
    _GUICtrlComboBox_AddString(GUICtrlGetHandle($idVerCmb), i18nGet("apps.online.status.latest", "Latest"))
    _GUICtrlComboBox_SetCurSel(GUICtrlGetHandle($idVerCmb), 0)
    GUICtrlSetState($idVerCmb, $GUI_DISABLE)

    Local $idLatestCkbx = GUICtrlCreateCheckbox(i18nGet("apps.dialog.ckbx.latest", "Latest"), 232, 306, 80, 20)
    GUICtrlSetTip($idLatestCkbx, i18nGet("apps.dialog.ckbx.latest.tip", "Automatically select the latest version"))
    GUICtrlSetState($idLatestCkbx, $GUI_CHECKED)

    Local $idShortcutLbl = GUICtrlCreateLabel(i18nGet("apps.dialog.shortcut.label", "Shortcut: "), 322, 306, 65, 20)
    Local $idShortcutCmb = GUICtrlCreateCombo("", 392, 304, 144, 22, $CBS_DROPDOWNLIST)
    Local $sYes = i18nGet("apps.status.yes", "Yes")
    Local $sNo = i18nGet("apps.status.no", "No")
    GUICtrlSetData($idShortcutCmb, $sYes & "|" & $sNo, $sNo)

    ; Custom path row
    Local $idCustomPathCkbx = GUICtrlCreateCheckbox(i18nGet("apps.dialog.ckbx.custom_path", "Custom path"), 24, 338, 105, 20)
    GUICtrlSetTip($idCustomPathCkbx, i18nGet("apps.dialog.ckbx.custom_path.tip", "Specify a custom installation directory"))
    Local $idLocationInput = GUICtrlCreateInput("", 135, 336, 401, 22)
    GUICtrlSetTip($idLocationInput, i18nGet("apps.dialog.location.tip", "Custom installation directory path"))
    GUICtrlSetState($idLocationInput, $GUI_DISABLE)

    ; Requirement info label
    Local $idReqInfoLbl = GUICtrlCreateLabel(i18nGet("apps.online.info.label", "Requires an active internet connection."), 24, 396, 512, 20)
    GUICtrlSetFont($idReqInfoLbl, $iSmall, 400, 2)
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    ; Bottom Buttons: Reset (left), Apply, Cancel (right)
    Local $idResetBtn = GUICtrlCreateButton(i18nGet("apps.dialog.btn.reset", "Reset"), 12, 438, 80, 28)
    GUICtrlSetTip($idResetBtn, i18nGet("apps.dialog.btn.reset.tip", "Reset dialog input fields to defaults"))
    Local $idApplyBtn = GUICtrlCreateButton(i18nGet("apps.dialog.btn.apply", "Apply"), 370, 438, 85, 28)
    GUICtrlSetTip($idApplyBtn, i18nGet("apps.dialog.btn.apply.tip", "Save and apply application details"))
    Local $idCancelBtn = GUICtrlCreateButton(i18nGet("apps.dialog.btn.cancel", "Cancel"), 463, 438, 85, 28)
    GUICtrlSetTip($idCancelBtn, i18nGet("apps.dialog.btn.cancel.tip", "Close dialog without saving"))

    GUISetState(@SW_SHOW, $hAddDlg)

    Local $aCurSearchResults[0][4]
    Local $sLastSelIndices = "-1"
    Local $sCurSelectedId = ""
    Local $bApplied = False

    While 1
        ; Live selection tracking for Results ListView
        Local $sCurSel = _GUICtrlListView_GetSelectedIndices(GUICtrlGetHandle($idResultsList))
        If $sCurSel <> "" And $sCurSel <> $sLastSelIndices Then
            $sLastSelIndices = $sCurSel
            Local $iIdx = Number($sCurSel)
            If $iIdx >= 0 And $iIdx < UBound($aCurSearchResults, 1) Then
                $sCurSelectedId = $aCurSearchResults[$iIdx][1]
                GUICtrlSetData($idAppNameInput, $aCurSearchResults[$iIdx][0])
                GUICtrlSetData($idDescInput, $aCurSearchResults[$iIdx][2])

                ; Update Version dropdown options
                Local $sAppVers = $aCurSearchResults[$iIdx][3]
                If $sAppVers = "" Then $sAppVers = i18nGet("apps.online.status.latest", "Latest")
                If Not StringInStr($sAppVers, i18nGet("apps.online.status.latest", "Latest")) Then
                    $sAppVers = i18nGet("apps.online.status.latest", "Latest") & "|" & $sAppVers
                EndIf

                _GUICtrlComboBox_ResetContent(GUICtrlGetHandle($idVerCmb))
                Local $aVList = StringSplit($sAppVers, "|")
                For $v = 1 To $aVList[0]
                    _GUICtrlComboBox_AddString(GUICtrlGetHandle($idVerCmb), $aVList[$v])
                Next
                _GUICtrlComboBox_SetCurSel(GUICtrlGetHandle($idVerCmb), 0)

                If GUICtrlRead($idLatestCkbx) = $GUI_CHECKED Then
                    GUICtrlSetState($idVerCmb, $GUI_DISABLE)
                Else
                    GUICtrlSetState($idVerCmb, $GUI_ENABLE)
                EndIf

                _GUICtrlStatusBar_SetText($hStatus, i18nGet("apps.dialog.status.selected", "App selected"), 0)
            EndIf
        EndIf

        Local $iMsg = GUIGetMsg()
        Switch $iMsg
            Case $GUI_EVENT_CLOSE, $idCancelBtn
                ExitLoop

            Case $idSearchBtn
                Local $sQ = StringStripWS(GUICtrlRead($idNameInput), 3)
                _GUICtrlStatusBar_SetText($hStatus, i18nGet("apps.dialog.status.searching", "Searching..."), 0)
                _GUICtrlListView_DeleteAllItems(GUICtrlGetHandle($idResultsList))
                $sLastSelIndices = "-1"
                $sCurSelectedId = ""
                $aCurSearchResults = _ViewAppsSearchWinget($sQ)
                If UBound($aCurSearchResults, 1) > 0 Then
                    For $k = 0 To UBound($aCurSearchResults, 1) - 1
                        Local $iRow = _GUICtrlListView_AddItem(GUICtrlGetHandle($idResultsList), $aCurSearchResults[$k][0])
                        _GUICtrlListView_AddSubItem(GUICtrlGetHandle($idResultsList), $iRow, $aCurSearchResults[$k][1], 1)
                        Local $sFirstVer = $aCurSearchResults[$k][3]
                        If StringInStr($sFirstVer, "|") Then
                            Local $aVParts = StringSplit($sFirstVer, "|")
                            $sFirstVer = ($aVParts[0] >= 2) ? $aVParts[2] : $aVParts[1]
                        EndIf
                        _GUICtrlListView_AddSubItem(GUICtrlGetHandle($idResultsList), $iRow, $sFirstVer, 2)
                    Next
                    _GUICtrlListView_SetItemSelected(GUICtrlGetHandle($idResultsList), 0, True, True)
                    _GUICtrlStatusBar_SetText($hStatus, i18nGet("apps.dialog.status.ready", "Ready"), 0)
                Else
                    _GUICtrlStatusBar_SetText($hStatus, i18nGet("apps.dialog.status.no_results", "No results found."), 0)
                EndIf

            Case $idLatestCkbx
                If GUICtrlRead($idLatestCkbx) = $GUI_CHECKED Then
                    GUICtrlSetState($idVerCmb, $GUI_DISABLE)
                    _GUICtrlComboBox_SetCurSel(GUICtrlGetHandle($idVerCmb), 0)
                Else
                    GUICtrlSetState($idVerCmb, $GUI_ENABLE)
                EndIf

            Case $idCustomPathCkbx
                If GUICtrlRead($idCustomPathCkbx) = $GUI_CHECKED Then
                    GUICtrlSetState($idLocationInput, $GUI_ENABLE)
                Else
                    GUICtrlSetState($idLocationInput, $GUI_DISABLE)
                    GUICtrlSetData($idLocationInput, "")
                EndIf

            Case $idResetBtn
                GUICtrlSetData($idNameInput, "")
                GUICtrlSetData($idAppNameInput, "")
                GUICtrlSetData($idDescInput, "")
                _GUICtrlComboBox_ResetContent(GUICtrlGetHandle($idVerCmb))
                _GUICtrlComboBox_AddString(GUICtrlGetHandle($idVerCmb), i18nGet("apps.online.status.latest", "Latest"))
                _GUICtrlComboBox_SetCurSel(GUICtrlGetHandle($idVerCmb), 0)
                GUICtrlSetState($idVerCmb, $GUI_DISABLE)
                GUICtrlSetState($idLatestCkbx, $GUI_CHECKED)
                GUICtrlSetData($idShortcutCmb, $sNo)
                GUICtrlSetState($idCustomPathCkbx, $GUI_UNCHECKED)
                GUICtrlSetState($idLocationInput, $GUI_DISABLE)
                GUICtrlSetData($idLocationInput, "")
                _GUICtrlListView_DeleteAllItems(GUICtrlGetHandle($idResultsList))
                Dim $aCurSearchResults[0][4]
                $sLastSelIndices = "-1"
                $sCurSelectedId = ""
                _GUICtrlStatusBar_SetText($hStatus, i18nGet("apps.dialog.status.ready", "Ready"), 0)

            Case $idApplyBtn
                Local $sFinalName = StringStripWS(GUICtrlRead($idAppNameInput), 3)
                If $sFinalName = "" Then $sFinalName = StringStripWS(GUICtrlRead($idNameInput), 3)
                If $sFinalName = "" Then
                    _GUICtrlStatusBar_SetText($hStatus, i18nGet("apps.dialog.status.no_results", "No results found."), 0)
                    ContinueLoop
                EndIf
                Local $sFinalDesc = GUICtrlRead($idDescInput)
                If $sFinalDesc = "" Then $sFinalDesc = i18nGet("apps.online.status.unknown", "Unknown")

                Local $sFinalVer = (GUICtrlRead($idLatestCkbx) = $GUI_CHECKED) ? i18nGet("apps.online.status.latest", "Latest") : GUICtrlRead($idVerCmb)
                Local $sFinalSc = GUICtrlRead($idShortcutCmb)
                Local $sFinalLoc = (GUICtrlRead($idCustomPathCkbx) = $GUI_CHECKED And StringStripWS(GUICtrlRead($idLocationInput), 3) <> "") ? GUICtrlRead($idLocationInput) : i18nGet("apps.online.status.default", "Default")
                Local $sFinalId = ($sCurSelectedId <> "") ? $sCurSelectedId : $sFinalName

                Local $iNewItem = _GUICtrlListView_AddItem($hViewAppsOnlineTable, $sFinalName)
                _GUICtrlListView_AddSubItem($hViewAppsOnlineTable, $iNewItem, $sFinalDesc, 1)
                _GUICtrlListView_AddSubItem($hViewAppsOnlineTable, $iNewItem, $sFinalVer, 2)
                _GUICtrlListView_AddSubItem($hViewAppsOnlineTable, $iNewItem, $sFinalSc, 3)
                _GUICtrlListView_AddSubItem($hViewAppsOnlineTable, $iNewItem, $sFinalLoc, 4)
                _GUICtrlListView_SetItemChecked($hViewAppsOnlineTable, $iNewItem, True)

                If $iNewItem >= UBound($g_aViewAppsOnlineIds) Then ReDim $g_aViewAppsOnlineIds[$iNewItem + 32]
                $g_aViewAppsOnlineIds[$iNewItem] = $sFinalId
                $g_iViewAppsOnlineCount = $iNewItem + 1

                $bApplied = True
                ExitLoop
        EndSwitch
    WEnd

    GUISetAccelerators(0, $hAddDlg)
    GUIDelete($hAddDlg)
    If $bApplied Then
        _ViewAppsOnlineOnSelect()
        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.online.status.added", "Added application to online installation list"))
    EndIf
EndFunc

Func _ViewAppsShowEditDialog()
    Local $sSel = _GUICtrlListView_GetSelectedIndices($hViewAppsOnlineTable)
    If $sSel = "" Then Return
    Local $iRow = Number($sSel)

    Local $sCurName = _GUICtrlListView_GetItemText($hViewAppsOnlineTable, $iRow, 0)
    Local $sCurDesc = _GUICtrlListView_GetItemText($hViewAppsOnlineTable, $iRow, 1)
    Local $sCurVer = _GUICtrlListView_GetItemText($hViewAppsOnlineTable, $iRow, 2)
    Local $sCurSc = _GUICtrlListView_GetItemText($hViewAppsOnlineTable, $iRow, 3)
    Local $sCurLoc = _GUICtrlListView_GetItemText($hViewAppsOnlineTable, $iRow, 4)

    Local $hEditDlg = GUICreate(i18nGet("apps.dialog.edit.title", "Edit App") & " - " & $sCurName, 560, 420, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOPMOST, $hViewApps)
    GUISetBkColor(themeColor("main.view.bg"), $hEditDlg)

    Local $hStatus = _GUICtrlStatusBar_Create($hEditDlg)
    _GUICtrlStatusBar_SetText($hStatus, i18nGet("apps.dialog.status.ready", "Ready"), 0)

    ; Group: Package Configuration
    Local $idConfigGroup = GUICtrlCreateGroup(i18nGet("apps.dialog.group.config", "Package Configuration"), 12, 12, 536, 330)

    Local $idNameLbl = GUICtrlCreateLabel(i18nGet("apps.dialog.appname.label", "App Name: "), 24, 44, 85, 20)
    Local $idNameInput = GUICtrlCreateInput($sCurName, 115, 42, 421, 22, BitOR($ES_READONLY, $ES_AUTOHSCROLL))
    GUICtrlSetState($idNameInput, $GUI_DISABLE)

    Local $idDescLbl = GUICtrlCreateLabel(i18nGet("apps.dialog.desc.label", "Description: "), 24, 84, 85, 20)
    Local $idDescInput = GUICtrlCreateInput($sCurDesc, 115, 82, 421, 22, BitOR($ES_READONLY, $ES_AUTOHSCROLL))
    GUICtrlSetState($idDescInput, $GUI_DISABLE)

    ; Version & Shortcut
    Local $bIsLatest = ($sCurVer = "Latest" Or $sCurVer = i18nGet("apps.online.status.latest", "Latest"))
    Local $idVerLbl = GUICtrlCreateLabel(i18nGet("apps.dialog.version.label", "Version: "), 24, 124, 85, 20)
    Local $idVerCmb = GUICtrlCreateCombo("", 115, 122, 110, 22, $CBS_DROPDOWNLIST)
    _GUICtrlComboBox_AddString(GUICtrlGetHandle($idVerCmb), i18nGet("apps.online.status.latest", "Latest"))
    If Not $bIsLatest Then
        _GUICtrlComboBox_AddString(GUICtrlGetHandle($idVerCmb), $sCurVer)
    EndIf
    _GUICtrlComboBox_SetCurSel(GUICtrlGetHandle($idVerCmb), $bIsLatest ? 0 : 1)

    Local $idLatestCkbx = GUICtrlCreateCheckbox(i18nGet("apps.dialog.ckbx.latest", "Latest"), 232, 124, 80, 20)
    GUICtrlSetTip($idLatestCkbx, i18nGet("apps.dialog.ckbx.latest.tip", "Automatically select the latest version"))
    If $bIsLatest Then
        GUICtrlSetState($idLatestCkbx, $GUI_CHECKED)
        GUICtrlSetState($idVerCmb, $GUI_DISABLE)
    Else
        GUICtrlSetState($idLatestCkbx, $GUI_UNCHECKED)
        GUICtrlSetState($idVerCmb, $GUI_ENABLE)
    EndIf

    Local $idShortcutLbl = GUICtrlCreateLabel(i18nGet("apps.dialog.shortcut.label", "Shortcut: "), 322, 124, 65, 20)
    Local $idShortcutCmb = GUICtrlCreateCombo("", 392, 122, 144, 22, $CBS_DROPDOWNLIST)
    Local $sYes = i18nGet("apps.status.yes", "Yes")
    Local $sNo = i18nGet("apps.status.no", "No")
    GUICtrlSetData($idShortcutCmb, $sYes & "|" & $sNo, ($sCurSc = "Yes" Or $sCurSc = $sYes) ? $sYes : $sNo)

    ; Custom path
    Local $bIsCustom = ($sCurLoc <> "Default" And $sCurLoc <> i18nGet("apps.online.status.default", "Default") And $sCurLoc <> "")
    Local $idCustomPathCkbx = GUICtrlCreateCheckbox(i18nGet("apps.dialog.ckbx.custom_path", "Custom path"), 24, 164, 105, 20)
    GUICtrlSetTip($idCustomPathCkbx, i18nGet("apps.dialog.ckbx.custom_path.tip", "Specify a custom installation directory"))
    Local $idLocationInput = GUICtrlCreateInput($bIsCustom ? $sCurLoc : "", 135, 162, 401, 22)
    GUICtrlSetTip($idLocationInput, i18nGet("apps.dialog.location.tip", "Custom installation directory path"))
    If $bIsCustom Then
        GUICtrlSetState($idCustomPathCkbx, $GUI_CHECKED)
        GUICtrlSetState($idLocationInput, $GUI_ENABLE)
    Else
        GUICtrlSetState($idCustomPathCkbx, $GUI_UNCHECKED)
        GUICtrlSetState($idLocationInput, $GUI_DISABLE)
    EndIf

    Local $idReqInfoLbl = GUICtrlCreateLabel(i18nGet("apps.online.info.label", "Requires an active internet connection."), 24, 210, 512, 20)
    GUICtrlSetFont($idReqInfoLbl, $iSmall, 400, 2)
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    ; Bottom Buttons: Reset (left), Apply, Cancel (right)
    Local $idResetBtn = GUICtrlCreateButton(i18nGet("apps.dialog.btn.reset", "Reset"), 12, 354, 80, 28)
    GUICtrlSetTip($idResetBtn, i18nGet("apps.dialog.btn.reset.tip", "Reset dialog input fields to defaults"))
    Local $idApplyBtn = GUICtrlCreateButton(i18nGet("apps.dialog.btn.apply", "Apply"), 370, 354, 85, 28)
    GUICtrlSetTip($idApplyBtn, i18nGet("apps.dialog.btn.apply.tip", "Save and apply application details"))
    Local $idCancelBtn = GUICtrlCreateButton(i18nGet("apps.dialog.btn.cancel", "Cancel"), 463, 354, 85, 28)
    GUICtrlSetTip($idCancelBtn, i18nGet("apps.dialog.btn.cancel.tip", "Close dialog without saving"))

    GUISetState(@SW_SHOW, $hEditDlg)

    Local $bApplied = False
    While 1
        Local $iMsg = GUIGetMsg()
        Switch $iMsg
            Case $GUI_EVENT_CLOSE, $idCancelBtn
                ExitLoop

            Case $idLatestCkbx
                If GUICtrlRead($idLatestCkbx) = $GUI_CHECKED Then
                    GUICtrlSetState($idVerCmb, $GUI_DISABLE)
                    _GUICtrlComboBox_SetCurSel(GUICtrlGetHandle($idVerCmb), 0)
                Else
                    GUICtrlSetState($idVerCmb, $GUI_ENABLE)
                EndIf

            Case $idCustomPathCkbx
                If GUICtrlRead($idCustomPathCkbx) = $GUI_CHECKED Then
                    GUICtrlSetState($idLocationInput, $GUI_ENABLE)
                Else
                    GUICtrlSetState($idLocationInput, $GUI_DISABLE)
                    GUICtrlSetData($idLocationInput, "")
                EndIf

            Case $idResetBtn
                If $bIsLatest Then
                    GUICtrlSetState($idLatestCkbx, $GUI_CHECKED)
                    GUICtrlSetState($idVerCmb, $GUI_DISABLE)
                    _GUICtrlComboBox_SetCurSel(GUICtrlGetHandle($idVerCmb), 0)
                Else
                    GUICtrlSetState($idLatestCkbx, $GUI_UNCHECKED)
                    GUICtrlSetState($idVerCmb, $GUI_ENABLE)
                EndIf
                GUICtrlSetData($idShortcutCmb, ($sCurSc = "Yes" Or $sCurSc = $sYes) ? $sYes : $sNo)
                If $bIsCustom Then
                    GUICtrlSetState($idCustomPathCkbx, $GUI_CHECKED)
                    GUICtrlSetState($idLocationInput, $GUI_ENABLE)
                    GUICtrlSetData($idLocationInput, $sCurLoc)
                Else
                    GUICtrlSetState($idCustomPathCkbx, $GUI_UNCHECKED)
                    GUICtrlSetState($idLocationInput, $GUI_DISABLE)
                    GUICtrlSetData($idLocationInput, "")
                EndIf

            Case $idApplyBtn
                Local $sNewVer = (GUICtrlRead($idLatestCkbx) = $GUI_CHECKED) ? i18nGet("apps.online.status.latest", "Latest") : GUICtrlRead($idVerCmb)
                Local $sNewSc = GUICtrlRead($idShortcutCmb)
                Local $sNewLoc = (GUICtrlRead($idCustomPathCkbx) = $GUI_CHECKED And StringStripWS(GUICtrlRead($idLocationInput), 3) <> "") ? GUICtrlRead($idLocationInput) : i18nGet("apps.online.status.default", "Default")

                _GUICtrlListView_SetItemText($hViewAppsOnlineTable, $iRow, $sNewVer, 2)
                _GUICtrlListView_SetItemText($hViewAppsOnlineTable, $iRow, $sNewSc, 3)
                _GUICtrlListView_SetItemText($hViewAppsOnlineTable, $iRow, $sNewLoc, 4)

                $bApplied = True
                ExitLoop
        EndSwitch
    WEnd

    GUIDelete($hEditDlg)
    If $bApplied Then
        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.online.status.edited", "Saved changes to online application"))
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Fonts Library Operations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _ViewAppsFontsReset()
    _GUICtrlListView_DeleteAllItems($hViewAppsFontsTable)
    Local $sFontsDir = @ScriptDir & "\apps\Fonts"
    If Not FileExists($sFontsDir) Then $sFontsDir = @ScriptDir & "\Fonts"

    Local $hSearch = FileFindFirstFile($sFontsDir & "\*.ttf")
    If $hSearch <> -1 Then
        While 1
            Local $sFileName = FileFindNextFile($hSearch)
            If @error Then ExitLoop
            Local $sFull = $sFontsDir & "\" & $sFileName
            Local $iItem = _GUICtrlListView_AddItem($hViewAppsFontsTable, $sFileName)
            _GUICtrlListView_AddSubItem($hViewAppsFontsTable, $iItem, $sFull, 1)
            _GUICtrlListView_SetItemChecked($hViewAppsFontsTable, $iItem, True)
        WEnd
        FileClose($hSearch)
    EndIf
EndFunc

Func _ViewAppsFontsSelectAll()
    Local $iCount = _GUICtrlListView_GetItemCount($hViewAppsFontsTable)
    For $i = 0 To $iCount - 1
        _GUICtrlListView_SetItemChecked($hViewAppsFontsTable, $i, True)
    Next
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.fonts.btn.select_all.tip", "Select all fonts in the table"))
EndFunc

Func _ViewAppsFontsAdd()
    Local $sFilter = i18nGet("apps.fonts.dialog.add.filter", "TrueType Font files (*.ttf)|All files (*.*)")
    Local $sFile = FileOpenDialog(i18nGet("apps.fonts.dialog.add.title", "Select TrueType Font Files"), @ScriptDir, $sFilter, BitOR($FD_FILEMUSTEXIST, $FD_MULTISELECT))
    If Not @error And $sFile <> "" Then
        Local $aSelected = StringSplit($sFile, "|")
        If $aSelected[0] = 1 Then
            Local $sFullName = $aSelected[1]
            Local $sBase = StringMid($sFullName, StringInStr($sFullName, "\", 0, -1) + 1)
            Local $iItem = _GUICtrlListView_AddItem($hViewAppsFontsTable, $sBase)
            _GUICtrlListView_AddSubItem($hViewAppsFontsTable, $iItem, $sFullName, 1)
            _GUICtrlListView_SetItemChecked($hViewAppsFontsTable, $iItem, True)
        ElseIf $aSelected[0] > 1 Then
            Local $sDir = $aSelected[1]
            If StringRight($sDir, 1) <> "\" Then $sDir &= "\"
            For $k = 2 To $aSelected[0]
                Local $sBase = $aSelected[$k]
                Local $sFullName = $sDir & $sBase
                Local $iItem = _GUICtrlListView_AddItem($hViewAppsFontsTable, $sBase)
                _GUICtrlListView_AddSubItem($hViewAppsFontsTable, $iItem, $sFullName, 1)
                _GUICtrlListView_SetItemChecked($hViewAppsFontsTable, $iItem, True)
            Next
        EndIf
        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.fonts.status.added", "Added font(s) to the list"))
    EndIf
EndFunc

Func _ViewAppsFontsRemove()
    Local $sSel = _GUICtrlListView_GetSelectedIndices($hViewAppsFontsTable)
    If $sSel = "" Then Return
    Local $iIdx = Number($sSel)
    _GUICtrlListView_DeleteItem($hViewAppsFontsTable, $iIdx)
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.fonts.status.removed", "Removed selected font from the list"))
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Comprehensive Toolbar Reset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _ViewAppsResetAllSettings()
    ; 1. Reset Mode Slider to Online (2)
    _ViewAppsUpdateModeState(2)

    ; 2. Reset Online Apps list to empty
    _ViewAppsOnlineReset()

    ; 3. Deselect all Offline Apps
    _ViewAppsResetSelection()
    _ViewAppsOnClear()

    ; 4. Reset Fonts Installation Slider to Install (1) & reload all fonts
    _ViewAppsUpdateFontsState(1)
    _ViewAppsFontsReset()

    ; 5. Reset Max Iteration & Log Path to factory defaults
    GUICtrlSetData($idViewAppsMaxIterInput, "2")
    GUICtrlSetData($idViewAppsLogPathInput, "C:\AutoInstaller\apps.log")

    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("apps.status.reset_all", "Reset all application and font settings to defaults"))
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Localization & Theming
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewAppsApplyLang()
    GUICtrlSetData($idViewAppsTitle, i18nGet("apps.title", "Customize App Installation"))

    ; Header Mode Slider
    GUICtrlSetData($hViewAppsModeGroup, i18nGet("apps.mode.title", "Installation Mode"))
    GUICtrlSetTip($hViewAppsModeGroup, i18nGet("apps.mode.tip", "Switch between Disabled, Offline, and Online installation modes"))
    GUICtrlSetData($idViewAppsModeLbl, i18nGet("apps.mode.label", "Installation Mode: "))
    GUICtrlSetData($idViewAppsModeDisLbl, i18nGet("apps.mode.disabled.label", "Disabled"))
    GUICtrlSetTip($idViewAppsModeDisLbl, i18nGet("apps.mode.disabled.tip", "Disable all apps installation"))
    GUICtrlSetData($idViewAppsModeOffLbl, i18nGet("apps.mode.offline.label", "Offline"))
    GUICtrlSetTip($idViewAppsModeOffLbl, i18nGet("apps.mode.offline.tip", "Install applications from local offline packages"))
    GUICtrlSetData($idViewAppsModeOnlLbl, i18nGet("apps.mode.online.label", "Online"))
    GUICtrlSetTip($idViewAppsModeOnlLbl, i18nGet("apps.mode.online.tip", "Install applications online using winget package manager"))

    ; Section 1: Online Apps Library
    GUICtrlSetData($hViewAppsOnlineGroup, i18nGet("apps.online.title", "Online Apps Library"))
    GUICtrlSetTip($hViewAppsOnlineGroup, i18nGet("apps.online.tip", "Select and configure applications to install online via winget"))
    GUICtrlSetData($idViewAppsOnlineInfoLbl, i18nGet("apps.online.info.label", "Requires an active internet connection."))
    GUICtrlSetData($idViewAppsOnlineResetBtn, i18nGet("apps.online.btn.reset", "Reset"))
    GUICtrlSetTip($idViewAppsOnlineResetBtn, i18nGet("apps.online.btn.reset.tip", "Reset online applications list to empty"))

    _GUICtrlListView_SetColumn($idViewAppsOnlineTable, 0, i18nGet("apps.online.col.name", "App name"))
    _GUICtrlListView_SetColumn($idViewAppsOnlineTable, 1, i18nGet("apps.online.col.description", "Description"))
    _GUICtrlListView_SetColumn($idViewAppsOnlineTable, 2, i18nGet("apps.online.col.version", "Version"))
    _GUICtrlListView_SetColumn($idViewAppsOnlineTable, 3, i18nGet("apps.online.col.shortcut", "Shortcut"))
    _GUICtrlListView_SetColumn($idViewAppsOnlineTable, 4, i18nGet("apps.online.col.location", "Location"))

    GUICtrlSetData($idViewAppsOnlineSelectAllBtn, i18nGet("apps.online.btn.select_all", "Select All"))
    GUICtrlSetTip($idViewAppsOnlineSelectAllBtn, i18nGet("apps.online.btn.select_all.tip", "Select all applications in the online list"))
    GUICtrlSetData($idViewAppsOnlineAddBtn, i18nGet("apps.online.btn.add", "Add"))
    GUICtrlSetTip($idViewAppsOnlineAddBtn, i18nGet("apps.online.btn.add.tip", "Add an application to the online installation list"))
    GUICtrlSetData($idViewAppsOnlineRemoveBtn, i18nGet("apps.online.btn.remove", "Remove"))
    GUICtrlSetTip($idViewAppsOnlineRemoveBtn, i18nGet("apps.online.btn.remove.tip", "Remove selected application from the online installation list"))
    GUICtrlSetData($idViewAppsOnlineEditBtn, i18nGet("apps.online.btn.edit", "Edit"))
    GUICtrlSetTip($idViewAppsOnlineEditBtn, i18nGet("apps.online.btn.edit.tip", "Edit selected application details"))

    ; Section 2: Offline Apps Library
    GUICtrlSetData($hViewAppsOfflineGroup, i18nGet("apps.offline.title", "Offline Apps Library"))
    GUICtrlSetTip($hViewAppsOfflineGroup, i18nGet("apps.offline.tip", "Software catalog and offline local package management"))
    GUICtrlSetData($idViewAppsAvailableLbl, i18nGet("apps.available.label", "Available Applications: "))
    GUICtrlSetTip($idViewAppsAvailableLbl, i18nGet("apps.available.tip", "List of software applications available in the library"))
    GUICtrlSetData($idViewAppsResetBtn, i18nGet("apps.btn.reset", "Reset"))
    GUICtrlSetTip($idViewAppsResetBtn, i18nGet("apps.btn.reset.tip", "Deselect all applications for installation"))

    _GUICtrlListView_SetColumn($idViewAppsTable, 0, i18nGet("apps.col.name", "Name"))
    _GUICtrlListView_SetColumn($idViewAppsTable, 1, i18nGet("apps.col.description", "Description"))
    _GUICtrlListView_SetColumn($idViewAppsTable, 2, i18nGet("apps.col.version", "Version"))
    _GUICtrlListView_SetColumn($idViewAppsTable, 3, i18nGet("apps.col.shortcut", "Shortcut"))
    _GUICtrlListView_SetColumn($idViewAppsTable, 4, i18nGet("apps.col.ready", "Ready"))

    GUICtrlSetTip($idViewAppsNameInput, i18nGet("apps.entry.name.tip", "Selected application name (read-only)"))
    GUICtrlSetTip($idViewAppsDescInput, i18nGet("apps.entry.desc.tip", "Selected application description (read-only)"))
    GUICtrlSetTip($idViewAppsVerInput, i18nGet("apps.entry.version.tip", "Selected application version (read-only)"))
    GUICtrlSetTip($idViewAppsReadyInput, i18nGet("apps.entry.ready.tip", "Selected application setup file readiness (read-only)"))

    Local $sCurSc = GUICtrlRead($idViewAppsShortcutCmb)
    Local $bWasYes = ($sCurSc = "Yes" Or $sCurSc = i18nGet("apps.status.yes", "Yes"))
    GUICtrlSetData($idViewAppsShortcutCmb, "|" & i18nGet("apps.status.yes", "Yes") & "|" & i18nGet("apps.status.no", "No"), $bWasYes ? i18nGet("apps.status.yes", "Yes") : i18nGet("apps.status.no", "No"))
    GUICtrlSetTip($idViewAppsShortcutCmb, i18nGet("apps.entry.shortcut.tip", "Create desktop shortcut after installation"))

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

    _ViewAppsSetDownloadStatus($g_sViewAppsCurStatusKey)
    GUICtrlSetTip($idViewAppsProgressBar, i18nGet("apps.entry.progress.tip", "Real-time download progress for the selected application"))

    ; Section 3: Fonts Library
    GUICtrlSetData($hViewAppsFontsGroup, i18nGet("apps.fonts.title", "Fonts Library"))
    GUICtrlSetTip($hViewAppsFontsGroup, i18nGet("apps.fonts.tip", "Manage and select TrueType fonts for installation"))
    GUICtrlSetData($idViewAppsFontsSliderLbl, i18nGet("apps.fonts.slider.label", "Fonts Installation: "))
    GUICtrlSetData($idViewAppsFontsDisLbl, i18nGet("apps.fonts.disabled.label", "Disabled"))
    GUICtrlSetTip($idViewAppsFontsDisLbl, i18nGet("apps.fonts.disabled.tip", "Skip fonts installation"))
    GUICtrlSetData($idViewAppsFontsInstLbl, i18nGet("apps.fonts.install.label", "Install"))
    GUICtrlSetTip($idViewAppsFontsInstLbl, i18nGet("apps.fonts.install.tip", "Install selected TrueType fonts"))

    GUICtrlSetData($idViewAppsFontsAvailableLbl, i18nGet("apps.fonts.available.label", "Available Fonts: "))
    GUICtrlSetData($idViewAppsFontsResetBtn, i18nGet("apps.fonts.btn.reset", "Reset"))
    GUICtrlSetTip($idViewAppsFontsResetBtn, i18nGet("apps.fonts.btn.reset.tip", "Reload all fonts from apps/Fonts directory and select all"))

    _GUICtrlListView_SetColumn($idViewAppsFontsTable, 0, i18nGet("apps.fonts.col.name", "Font name"))
    _GUICtrlListView_SetColumn($idViewAppsFontsTable, 1, i18nGet("apps.fonts.col.location", "Location"))

    GUICtrlSetData($idViewAppsFontsSelectAllBtn, i18nGet("apps.fonts.btn.select_all", "Select All"))
    GUICtrlSetTip($idViewAppsFontsSelectAllBtn, i18nGet("apps.fonts.btn.select_all.tip", "Select all fonts in the table"))
    GUICtrlSetData($idViewAppsFontsAddBtn, i18nGet("apps.fonts.btn.add", "Add"))
    GUICtrlSetTip($idViewAppsFontsAddBtn, i18nGet("apps.fonts.btn.add.tip", "Add TrueType font files (.ttf) to the list"))
    GUICtrlSetData($idViewAppsFontsRemoveBtn, i18nGet("apps.fonts.btn.remove", "Remove"))
    GUICtrlSetTip($idViewAppsFontsRemoveBtn, i18nGet("apps.fonts.btn.remove.tip", "Remove selected font from the list"))

    ; Section 4: Auto-installation
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

    ; Reload descriptions in offline table
    Local $aApps = dataLoadCsv("apps.csv")
    If IsArray($aApps) Then
        Local $iRowCounter = 0
        For $j = 1 To UBound($aApps, 1) - 1
            If $aApps[$j][0] = "Fonts" Then ContinueLoop
            Local $sDesc = _AppsGetAppDesc($aApps[$j][0], $aApps[$j][2])
            _GUICtrlListView_SetItemText($hViewAppsTable, $iRowCounter, $sDesc, 1)
            $iRowCounter += 1
        Next
    EndIf

    If $g_iViewAppsSelectedRow >= 0 And $g_iViewAppsSelectedRow < $g_iViewAppsAppCount Then
        GUICtrlSetData($idViewAppsDescInput, _GUICtrlListView_GetItemText($hViewAppsTable, $g_iViewAppsSelectedRow, 1))
    EndIf

    ; Toolbar Buttons
    If $g_hCurrentView = $hViewApps Then
        GUICtrlSetData($a_idToolBarBtn[0], i18nGet("reset.btn.title", "Reset"))
        GUICtrlSetTip($a_idToolBarBtn[0], i18nGet("apps.toolbar.reset.tip", "Reset all application and font settings to default values"))

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
    ; Button Index 0: [Reset] - Overhauled to reset all settings to defaults
    GUICtrlSetData($a_idToolBarBtn[0], i18nGet("reset.btn.title", "Reset"))
    GUICtrlSetTip($a_idToolBarBtn[0], i18nGet("apps.toolbar.reset.tip", "Reset all application and font settings to default values"))
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

    GUICtrlSetBkColor($idViewAppsModeSlider, themeColor("main.view.bg"))
    GUICtrlSetBkColor($idViewAppsFontsSlider, themeColor("main.view.bg"))

    GUICtrlSetColor($idViewAppsModeLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsModeLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewAppsModeDisLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsModeDisLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewAppsModeOffLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsModeOffLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewAppsModeOnlLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsModeOnlLbl, themeColor("main.view.bg"))

    GUICtrlSetColor($idViewAppsOnlineInfoLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsOnlineInfoLbl, themeColor("main.view.bg"))

    GUICtrlSetColor($idViewAppsAvailableLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsAvailableLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewAppsStatusLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsStatusLbl, themeColor("main.view.bg"))

    GUICtrlSetColor($idViewAppsFontsSliderLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsFontsSliderLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewAppsFontsDisLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsFontsDisLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewAppsFontsInstLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsFontsInstLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewAppsFontsAvailableLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsFontsAvailableLbl, themeColor("main.view.bg"))

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

    _GUICtrlListView_SetTextColor($idViewAppsOnlineTable, themeColor("text.primary"))
    _GUICtrlListView_SetTextBkColor($idViewAppsOnlineTable, themeColor("main.view.bg"))
    _GUICtrlListView_SetBkColor($idViewAppsOnlineTable, themeColor("main.view.bg"))

    _GUICtrlListView_SetTextColor($idViewAppsTable, themeColor("text.primary"))
    _GUICtrlListView_SetTextBkColor($idViewAppsTable, themeColor("main.view.bg"))
    _GUICtrlListView_SetBkColor($idViewAppsTable, themeColor("main.view.bg"))

    _GUICtrlListView_SetTextColor($idViewAppsFontsTable, themeColor("text.primary"))
    _GUICtrlListView_SetTextBkColor($idViewAppsFontsTable, themeColor("main.view.bg"))
    _GUICtrlListView_SetBkColor($idViewAppsFontsTable, themeColor("main.view.bg"))
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Event Handling
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewAppsHandleEvent($idMsg)
    ; Track Offline ListView row selection changes
    Local $sSelOff = _GUICtrlListView_GetSelectedIndices($hViewAppsTable)
    If $sSelOff <> "" Then
        Local $iCurSelOff = Number($sSelOff)
        If $iCurSelOff <> $g_iViewAppsSelectedRow Then
            _ViewAppsOnSelectRow($iCurSelOff)
        EndIf
    EndIf

    ; Track Online ListView row selection changes
    Local $sSelOnl = _GUICtrlListView_GetSelectedIndices($hViewAppsOnlineTable)
    If $sSelOnl <> "" Then
        Local $iCurSelOnl = Number($sSelOnl)
        If $iCurSelOnl <> $g_iViewAppsOnlineSelectedRow Then
            _ViewAppsOnlineOnSelect()
        EndIf
    ElseIf $g_iViewAppsOnlineSelectedRow <> -1 Then
        _ViewAppsOnlineOnSelect()
    EndIf

    Switch $idMsg
        ; Mode Slider Events
        Case $idViewAppsModeDisLbl
            _ViewAppsUpdateModeState(0)

        Case $idViewAppsModeOffLbl
            _ViewAppsUpdateModeState(1)

        Case $idViewAppsModeOnlLbl
            _ViewAppsUpdateModeState(2)

        Case $idViewAppsModeSlider
            _ViewAppsUpdateModeState(GUICtrlRead($idViewAppsModeSlider))

        ; Online Apps Events
        Case $idViewAppsOnlineResetBtn
            _ViewAppsOnlineReset()

        Case $idViewAppsOnlineTable
            _ViewAppsOnlineOnSelect()

        Case $idViewAppsOnlineSelectAllBtn
            _ViewAppsOnlineSelectAll()

        Case $idViewAppsOnlineAddBtn
            _ViewAppsShowAddDialog()

        Case $idViewAppsOnlineRemoveBtn
            _ViewAppsOnlineRemove()

        Case $idViewAppsOnlineEditBtn
            _ViewAppsShowEditDialog()

        ; Offline Apps Events
        Case $idViewAppsResetBtn
            _ViewAppsResetSelection()

        Case $idViewAppsTable
            _ViewAppsOnSelectRow()

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

        ; Fonts Slider Events
        Case $idViewAppsFontsDisLbl
            _ViewAppsUpdateFontsState(0)

        Case $idViewAppsFontsInstLbl
            _ViewAppsUpdateFontsState(1)

        Case $idViewAppsFontsSlider
            _ViewAppsUpdateFontsState(GUICtrlRead($idViewAppsFontsSlider))

        ; Fonts Table Events
        Case $idViewAppsFontsResetBtn
            _ViewAppsFontsReset()

        Case $idViewAppsFontsSelectAllBtn
            _ViewAppsFontsSelectAll()

        Case $idViewAppsFontsAddBtn
            _ViewAppsFontsAdd()

        Case $idViewAppsFontsRemoveBtn
            _ViewAppsFontsRemove()

        ; Auto-installation Log Path Browse Button
        Case $idViewAppsLogBrowseBtn
            _ViewAppsBrowseLogPath()

        ; Toolbar Button 0: [Reset] - Resets all settings across all sections to defaults
        Case $a_idToolBarBtn[0]
            _ViewAppsResetAllSettings()

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
