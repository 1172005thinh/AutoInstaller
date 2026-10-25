;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/confwin.au3
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
#include <EditConstants.au3>
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

Global $hViewConfwin = 0
Global $idViewConfwinTitle = 0

; Mode Selection Header
Global $hViewConfwinModeGroup = 0
Global $idViewConfwinModeLbl = 0
Global $idViewConfwinModeSlider = 0
Global $idViewConfwinModeDisLbl = 0
Global $idViewConfwinModeBasLbl = 0
Global $idViewConfwinModeAdvLbl = 0
Global $idViewConfwinModeCusLbl = 0
Global $g_iViewConfwinCurMode = 1 ; 0: Disabled, 1: Basic (default), 2: Advanced, 3: Custom
Global $g_bViewConfwinInitializing = False

; Section 1: File Explorer
Global $hViewConfwinExplorerGroup = 0
Global $idViewConfwinShowExtCkbx = 0
Global $idViewConfwinLaunchToLbl = 0
Global $idViewConfwinLaunchToCmb = 0
Global $idViewConfwinHiddenItemsLbl = 0
Global $idViewConfwinHiddenItemsCmb = 0

; Section 2: Taskbar
Global $hViewConfwinTaskbarGroup = 0
Global $idViewConfwinAlignLbl = 0
Global $idViewConfwinAlignCmb = 0
Global $idViewConfwinEndTaskCkbx = 0
Global $idViewConfwinSearchModeLbl = 0
Global $idViewConfwinSearchModeCmb = 0
Global $idViewConfwinWidgetsCkbx = 0
Global $idViewConfwinTaskviewCkbx = 0
Global $idViewConfwinUnpinDefaultsCkbx = 0

; Section 3: Start Menu
Global $hViewConfwinStartGroup = 0
Global $idViewConfwinDisableBingCkbx = 0
Global $idViewConfwinRemoveStartPinsCkbx = 0
Global $idViewConfwinFoldersLbl = 0
Global $idViewConfwinFoldersInput = 0

; Section 4: Desktop & Control Panel
Global $hViewConfwinDesktopGroup = 0
Global $idViewConfwinDeskIconsLbl = 0
Global $idViewConfwinDeskIconsInput = 0
Global $idViewConfwinDeskSortLbl = 0
Global $idViewConfwinDeskSortCmb = 0
Global $idViewConfwinCPanelViewLbl = 0
Global $idViewConfwinCPanelViewCmb = 0

; Section 5: System & Developer
Global $hViewConfwinSystemGroup = 0
Global $idViewConfwinClipboardCkbx = 0
Global $idViewConfwinStickyKeysCkbx = 0
Global $idViewConfwinEdgeFirstRunCkbx = 0
Global $idViewConfwinLongPathsCkbx = 0
Global $idViewConfwinSudoModeLbl = 0
Global $idViewConfwinSudoModeCmb = 0
Global $idViewConfwinPsScriptsCkbx = 0
Global $idViewConfwinRdpCkbx = 0
Global $idViewConfwinSmartScreenCkbx = 0
Global $idViewConfwinWinOldCkbx = 0

; Section 6: Wallpapers
Global $hViewConfwinWallpaperGroup = 0
Global $idViewConfwinWallDeskLbl = 0
Global $idViewConfwinWallDeskInput = 0
Global $idViewConfwinWallDeskBrowseBtn = 0
Global $idViewConfwinWallLockLbl = 0
Global $idViewConfwinWallLockInput = 0
Global $idViewConfwinWallLockBrowseBtn = 0

; Section 7: Auto-installation
Global $hViewConfwinInstallGroup = 0
Global $idViewConfwinLogPathLbl = 0
Global $idViewConfwinLogPathInput = 0
Global $idViewConfwinLogBrowseBtn = 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Helper Functions & Path Resolution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _GetConfwinConfigPath()
    If FileExists(@ScriptDir & "\confwin\config.ini") Then Return @ScriptDir & "\confwin\config.ini"
    If FileExists(@ScriptDir & "\config.ini") Then Return @ScriptDir & "\config.ini"
    Return @ScriptDir & "\confwin\config.ini"
EndFunc

Func _ViewConfwinBrowseLogPath()
    Local $sCurPath = GUICtrlRead($idViewConfwinLogPathInput)
    Local $sInitDir = $sCurPath
    If StringInStr($sInitDir, "\") Then
        $sInitDir = StringLeft($sInitDir, StringInStr($sInitDir, "\", 0, -1))
    EndIf
    Local $sSelected = FileSelectFolder(i18nGet("confwin.dialog.browse.title", "Select Log Folder"), $sInitDir)
    If Not @error And $sSelected <> "" Then
        If StringRight($sSelected, 1) <> "\" Then $sSelected &= "\"
        GUICtrlSetData($idViewConfwinLogPathInput, $sSelected & "confwin.log")
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; View Creation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewConfwinCreate($hViewport, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH

    $hViewConfwin = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewConfwin)

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
    $idViewConfwinTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)

    ; =========================================
    ; Header: Personalization Mode Slider
    ; =========================================
    $iY += $iCtrlH + $iP
    Local $iModeGroupH = $iRowH * 2 + $iP * 2
    $hViewConfwinModeGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iModeGroupH)

    $iX = $iP * 3
    Local $iItemY = $iY + $iP * 3
    $idViewConfwinModeLbl = GUICtrlCreateLabel(i18nGet("confwin.mode.label", "Personalization Mode: "), $iX, $iItemY, $iLblW, $iLblH)

    $idViewConfwinModeSlider = GUICtrlCreateSlider($iP * 3 + $iLblW, $iItemY - $iPx, $iInputW, $iInputH)
    GUICtrlSetLimit($idViewConfwinModeSlider, 3, 0)
    GUICtrlSetData($idViewConfwinModeSlider, 1) ; Default: Basic

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

    $idViewConfwinModeDisLbl = GUICtrlCreateLabel(i18nGet("confwin.mode.disabled.label", "Disabled"), $iSliderX, $iTickLblY, $iCol0W, $iLblH)
    $idViewConfwinModeBasLbl = GUICtrlCreateLabel(i18nGet("confwin.mode.basic.label", "Basic"), $iSliderX + $iSplit1, $iTickLblY, $iCol1W, $iLblH, $SS_CENTER)
    $idViewConfwinModeAdvLbl = GUICtrlCreateLabel(i18nGet("confwin.mode.advanced.label", "Advanced"), $iSliderX + $iSplit2, $iTickLblY, $iCol2W, $iLblH, $SS_CENTER)
    $idViewConfwinModeCusLbl = GUICtrlCreateLabel(i18nGet("confwin.mode.custom.label", "Custom"), $iSliderX + $iSplit3, $iTickLblY, $iCol3W, $iLblH, $SS_RIGHT)

    ; =========================================
    ; Section 1: File Explorer
    ; =========================================
    $iX = $iP
    $iY += $iModeGroupH + $iP
    Local $iExplorerGroupH = $iRowH * 3 + $iP * 3
    $hViewConfwinExplorerGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iExplorerGroupH)

    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewConfwinShowExtCkbx = GUICtrlCreateCheckbox(i18nGet("confwin.explorer.show_extensions", "Show known file extensions"), $iX, $iItemY, $iContentW - $iP * 6, $iLblH)

    $iItemY += $iRowH
    $idViewConfwinLaunchToLbl = GUICtrlCreateLabel(i18nGet("confwin.explorer.launch_to", "Open File Explorer to: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewConfwinLaunchToCmb = GUICtrlCreateCombo("", $iSliderX, $iItemY - $iPx, $iInputW, $iInputH, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
    GUICtrlSetData($idViewConfwinLaunchToCmb, "ThisPC|QuickAccess|Downloads", "ThisPC")

    $iItemY += $iRowH
    $idViewConfwinHiddenItemsLbl = GUICtrlCreateLabel(i18nGet("confwin.explorer.hidden_items", "Hidden items: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewConfwinHiddenItemsCmb = GUICtrlCreateCombo("", $iSliderX, $iItemY - $iPx, $iInputW, $iInputH, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
    GUICtrlSetData($idViewConfwinHiddenItemsCmb, "HideAll|HideHidden|Show", "HideAll")

    ; =========================================
    ; Section 2: Taskbar
    ; =========================================
    $iX = $iP
    $iY += $iExplorerGroupH + $iP
    Local $iTaskbarGroupH = $iRowH * 6 + $iP * 3
    $hViewConfwinTaskbarGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iTaskbarGroupH)

    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewConfwinAlignLbl = GUICtrlCreateLabel(i18nGet("confwin.taskbar.alignment", "Taskbar alignment: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewConfwinAlignCmb = GUICtrlCreateCombo("", $iSliderX, $iItemY - $iPx, $iInputW, $iInputH, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
    GUICtrlSetData($idViewConfwinAlignCmb, "Left|Center", "Left")

    $iItemY += $iRowH
    $idViewConfwinEndTaskCkbx = GUICtrlCreateCheckbox(i18nGet("confwin.taskbar.end_task", "Show 'End task' in context menu"), $iX, $iItemY, $iContentW - $iP * 6, $iLblH)

    $iItemY += $iRowH
    $idViewConfwinSearchModeLbl = GUICtrlCreateLabel(i18nGet("confwin.taskbar.search_mode", "Search box mode: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewConfwinSearchModeCmb = GUICtrlCreateCombo("", $iSliderX, $iItemY - $iPx, $iInputW, $iInputH, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
    GUICtrlSetData($idViewConfwinSearchModeCmb, "Hide|Icon|Full|IconAndLabel", "Icon")

    $iItemY += $iRowH
    $idViewConfwinWidgetsCkbx = GUICtrlCreateCheckbox(i18nGet("confwin.taskbar.widgets", "Show Widgets (News & Interests)"), $iX, $iItemY, $iContentW - $iP * 6, $iLblH)

    $iItemY += $iRowH
    $idViewConfwinTaskviewCkbx = GUICtrlCreateCheckbox(i18nGet("confwin.taskbar.taskview", "Show Taskview button"), $iX, $iItemY, $iContentW - $iP * 6, $iLblH)

    $iItemY += $iRowH
    $idViewConfwinUnpinDefaultsCkbx = GUICtrlCreateCheckbox(i18nGet("confwin.taskbar.unpin_defaults", "Remove default taskbar pinned apps"), $iX, $iItemY, $iContentW - $iP * 6, $iLblH)

    ; =========================================
    ; Section 3: Start Menu
    ; =========================================
    $iX = $iP
    $iY += $iTaskbarGroupH + $iP
    Local $iStartGroupH = $iRowH * 3 + $iP * 3
    $hViewConfwinStartGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iStartGroupH)

    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewConfwinDisableBingCkbx = GUICtrlCreateCheckbox(i18nGet("confwin.start.disable_bing", "Disable Bing web search results"), $iX, $iItemY, $iContentW - $iP * 6, $iLblH)

    $iItemY += $iRowH
    $idViewConfwinRemoveStartPinsCkbx = GUICtrlCreateCheckbox(i18nGet("confwin.start.remove_pins", "Remove default Start Menu pinned apps"), $iX, $iItemY, $iContentW - $iP * 6, $iLblH)

    $iItemY += $iRowH
    $idViewConfwinFoldersLbl = GUICtrlCreateLabel(i18nGet("confwin.start.folders", "Folders beside Power button: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewConfwinFoldersInput = GUICtrlCreateInput("Settings, File Explorer", $iSliderX, $iItemY - $iPx, $iInputW, $iInputH)

    ; =========================================
    ; Section 4: Desktop & Control Panel
    ; =========================================
    $iX = $iP
    $iY += $iStartGroupH + $iP
    Local $iDesktopGroupH = $iRowH * 3 + $iP * 3
    $hViewConfwinDesktopGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iDesktopGroupH)

    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewConfwinDeskIconsLbl = GUICtrlCreateLabel(i18nGet("confwin.desktop.icons", "Desktop icons: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewConfwinDeskIconsInput = GUICtrlCreateInput("This PC, Recycle Bin", $iSliderX, $iItemY - $iPx, $iInputW, $iInputH)

    $iItemY += $iRowH
    $idViewConfwinDeskSortLbl = GUICtrlCreateLabel(i18nGet("confwin.desktop.sort", "Desktop icons sorting: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewConfwinDeskSortCmb = GUICtrlCreateCombo("", $iSliderX, $iItemY - $iPx, $iInputW, $iInputH, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
    GUICtrlSetData($idViewConfwinDeskSortCmb, "None|ItemType|Name|Size|DateModified", "None")

    $iItemY += $iRowH
    $idViewConfwinCPanelViewLbl = GUICtrlCreateLabel(i18nGet("confwin.cpanel.view", "Control Panel view: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewConfwinCPanelViewCmb = GUICtrlCreateCombo("", $iSliderX, $iItemY - $iPx, $iInputW, $iInputH, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
    GUICtrlSetData($idViewConfwinCPanelViewCmb, "Large|Small|Category|Skip", "Large")

    ; =========================================
    ; Section 5: System & Developer
    ; =========================================
    $iX = $iP
    $iY += $iDesktopGroupH + $iP
    Local $iSystemGroupH = $iRowH * 9 + $iP * 3
    $hViewConfwinSystemGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iSystemGroupH)

    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewConfwinClipboardCkbx = GUICtrlCreateCheckbox(i18nGet("confwin.system.clipboard", "Enable Clipboard history (Win+V)"), $iX, $iItemY, $iContentW - $iP * 6, $iLblH)

    $iItemY += $iRowH
    $idViewConfwinStickyKeysCkbx = GUICtrlCreateCheckbox(i18nGet("confwin.system.sticky_keys", "Enable Sticky Keys shortcut (5x Shift)"), $iX, $iItemY, $iContentW - $iP * 6, $iLblH)

    $iItemY += $iRowH
    $idViewConfwinEdgeFirstRunCkbx = GUICtrlCreateCheckbox(i18nGet("confwin.system.edge_first_run", "Hide Microsoft Edge first run wizard"), $iX, $iItemY, $iContentW - $iP * 6, $iLblH)

    $iItemY += $iRowH
    $idViewConfwinLongPathsCkbx = GUICtrlCreateCheckbox(i18nGet("confwin.system.long_paths", "Enable Win32 long paths (>260 chars)"), $iX, $iItemY, $iContentW - $iP * 6, $iLblH)

    $iItemY += $iRowH
    $idViewConfwinSudoModeLbl = GUICtrlCreateLabel(i18nGet("confwin.system.sudo", "Sudo command mode: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewConfwinSudoModeCmb = GUICtrlCreateCombo("", $iSliderX, $iItemY - $iPx, $iInputW, $iInputH, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
    GUICtrlSetData($idViewConfwinSudoModeCmb, "Inline|NewWindow|DisableInput|Disable", "Inline")

    $iItemY += $iRowH
    $idViewConfwinPsScriptsCkbx = GUICtrlCreateCheckbox(i18nGet("confwin.system.ps_scripts", "Allow PowerShell scripts (RemoteSigned)"), $iX, $iItemY, $iContentW - $iP * 6, $iLblH)

    $iItemY += $iRowH
    $idViewConfwinRdpCkbx = GUICtrlCreateCheckbox(i18nGet("confwin.system.rdp", "Enable Remote Desktop (RDP)"), $iX, $iItemY, $iContentW - $iP * 6, $iLblH)

    $iItemY += $iRowH
    $idViewConfwinSmartScreenCkbx = GUICtrlCreateCheckbox(i18nGet("confwin.system.smart_screen", "Disable Smart App Control"), $iX, $iItemY, $iContentW - $iP * 6, $iLblH)

    $iItemY += $iRowH
    $idViewConfwinWinOldCkbx = GUICtrlCreateCheckbox(i18nGet("confwin.system.win_old", "Delete empty C:\Windows.old folder"), $iX, $iItemY, $iContentW - $iP * 6, $iLblH)

    ; =========================================
    ; Section 6: Wallpapers
    ; =========================================
    $iX = $iP
    $iY += $iSystemGroupH + $iP
    Local $iWallpaperGroupH = $iRowH * 2 + $iP * 3
    $hViewConfwinWallpaperGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iWallpaperGroupH)

    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    Local $iBrowseBtnW = 75
    Local $iPathInputW = $iInputW - $iBrowseBtnW - $iPx

    $idViewConfwinWallDeskLbl = GUICtrlCreateLabel(i18nGet("confwin.wallpaper.desktop", "Desktop wallpaper: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewConfwinWallDeskInput = GUICtrlCreateInput("Default", $iSliderX, $iItemY - $iPx, $iPathInputW, $iInputH)
    $idViewConfwinWallDeskBrowseBtn = GUICtrlCreateButton(i18nGet("confwin.wallpaper.browse", "Browse"), $iSliderX + $iPathInputW + $iPx, $iItemY - $iPx, $iBrowseBtnW, $iInputH)

    $iItemY += $iRowH
    $idViewConfwinWallLockLbl = GUICtrlCreateLabel(i18nGet("confwin.wallpaper.lockscreen", "Lock screen wallpaper: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewConfwinWallLockInput = GUICtrlCreateInput("Default", $iSliderX, $iItemY - $iPx, $iPathInputW, $iInputH)
    $idViewConfwinWallLockBrowseBtn = GUICtrlCreateButton(i18nGet("confwin.wallpaper.browse", "Browse"), $iSliderX + $iPathInputW + $iPx, $iItemY - $iPx, $iBrowseBtnW, $iInputH)
    GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; =========================================
    ; Section 7: Auto-installation
    ; =========================================
    $iX = $iP
    $iY += $iWallpaperGroupH + $iP
    Local $iInstallGroupH = $iRowH + $iP * 3
    $hViewConfwinInstallGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iInstallGroupH)

    ; Log Path Row
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    Local $iLogInputW = $iInputW - $iBrowseBtnW - $iPx
    $idViewConfwinLogPathLbl = GUICtrlCreateLabel(i18nGet("confwin.logpath.label", "Log Path: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewConfwinLogPathInput = GUICtrlCreateInput("C:\AutoInstaller\confwin.log", $iSliderX, $iItemY - $iPx, $iLogInputW, $iInputH)
    $idViewConfwinLogBrowseBtn = GUICtrlCreateButton(i18nGet("confwin.btn.browse", "Browse"), $iSliderX + $iLogInputW + $iPx, $iItemY - $iPx, $iBrowseBtnW, $iInputH)
    GUICtrlCreateGroup("", -99, -99, -99, -99)

    Local $iContentBottom = $iY + $iInstallGroupH + $iP
    If $iContentBottom < $iH Then $iContentBottom = $iH
    scrollSetContentHeight($hViewConfwin, $iContentBottom)

    viewConfwinApplyLang()
    viewConfwinApplyTheme()
    viewConfwinLoadData()

    Return $hViewConfwin
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Presets & Mode State Management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _ViewConfwinApplyPreset($iMode)
    $g_bViewConfwinInitializing = True
    $g_iViewConfwinCurMode = $iMode
    GUICtrlSetData($idViewConfwinModeSlider, $iMode)

    Local $iState = ($iMode = 0) ? $GUI_DISABLE : $GUI_ENABLE

    ; Enable/disable all controls based on mode
    _ViewConfwinSetControlsState($iState)

    Switch $iMode
        Case 0 ; Disabled
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("confwin.mode.status.disabled", "Personalization mode: Disabled"))
            ; Clear/uncheck all
            GUICtrlSetState($idViewConfwinShowExtCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinEndTaskCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinWidgetsCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinTaskviewCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinUnpinDefaultsCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinDisableBingCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinRemoveStartPinsCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinClipboardCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinStickyKeysCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinEdgeFirstRunCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinLongPathsCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinPsScriptsCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinRdpCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinSmartScreenCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinWinOldCkbx, $GUI_UNCHECKED)

        Case 1 ; Basic Mode (Standard daily-driver quality of life)
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("confwin.mode.status.basic", "Personalization mode: Basic (standard daily-driver tweaks)"))
            ; Explorer
            GUICtrlSetState($idViewConfwinShowExtCkbx, $GUI_CHECKED)
            GUICtrlSetData($idViewConfwinLaunchToCmb, "ThisPC")
            GUICtrlSetData($idViewConfwinHiddenItemsCmb, "HideAll")

            ; Taskbar
            GUICtrlSetData($idViewConfwinAlignCmb, "Left")
            GUICtrlSetState($idViewConfwinEndTaskCkbx, $GUI_CHECKED)
            GUICtrlSetData($idViewConfwinSearchModeCmb, "Icon")
            GUICtrlSetState($idViewConfwinWidgetsCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinTaskviewCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinUnpinDefaultsCkbx, $GUI_UNCHECKED)

            ; Start Menu
            GUICtrlSetState($idViewConfwinDisableBingCkbx, $GUI_CHECKED)
            GUICtrlSetState($idViewConfwinRemoveStartPinsCkbx, $GUI_UNCHECKED)
            GUICtrlSetData($idViewConfwinFoldersInput, "Settings, File Explorer")

            ; Desktop & Control Panel
            GUICtrlSetData($idViewConfwinDeskIconsInput, "This PC, Recycle Bin")
            GUICtrlSetData($idViewConfwinDeskSortCmb, "None")
            GUICtrlSetData($idViewConfwinCPanelViewCmb, "Large")

            ; System
            GUICtrlSetState($idViewConfwinClipboardCkbx, $GUI_CHECKED)
            GUICtrlSetState($idViewConfwinStickyKeysCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinEdgeFirstRunCkbx, $GUI_CHECKED)
            GUICtrlSetState($idViewConfwinLongPathsCkbx, $GUI_UNCHECKED)
            GUICtrlSetData($idViewConfwinSudoModeCmb, "Inline")
            GUICtrlSetState($idViewConfwinPsScriptsCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinRdpCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinSmartScreenCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinWinOldCkbx, $GUI_UNCHECKED)

            ; Wallpapers
            GUICtrlSetData($idViewConfwinWallDeskInput, "Default")
            GUICtrlSetData($idViewConfwinWallLockInput, "Default")

        Case 2 ; Advanced Mode (Full developer and power-user optimizations)
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("confwin.mode.status.advanced", "Personalization mode: Advanced (power-user & developer tweaks)"))
            ; Explorer
            GUICtrlSetState($idViewConfwinShowExtCkbx, $GUI_CHECKED)
            GUICtrlSetData($idViewConfwinLaunchToCmb, "ThisPC")
            GUICtrlSetData($idViewConfwinHiddenItemsCmb, "Show")

            ; Taskbar
            GUICtrlSetData($idViewConfwinAlignCmb, "Left")
            GUICtrlSetState($idViewConfwinEndTaskCkbx, $GUI_CHECKED)
            GUICtrlSetData($idViewConfwinSearchModeCmb, "Hide")
            GUICtrlSetState($idViewConfwinWidgetsCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinTaskviewCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinUnpinDefaultsCkbx, $GUI_CHECKED)

            ; Start Menu
            GUICtrlSetState($idViewConfwinDisableBingCkbx, $GUI_CHECKED)
            GUICtrlSetState($idViewConfwinRemoveStartPinsCkbx, $GUI_CHECKED)
            GUICtrlSetData($idViewConfwinFoldersInput, "Settings, File Explorer, Downloads")

            ; Desktop & Control Panel
            GUICtrlSetData($idViewConfwinDeskIconsInput, "This PC, Recycle Bin, Control Panel")
            GUICtrlSetData($idViewConfwinDeskSortCmb, "ItemType")
            GUICtrlSetData($idViewConfwinCPanelViewCmb, "Large")

            ; System
            GUICtrlSetState($idViewConfwinClipboardCkbx, $GUI_CHECKED)
            GUICtrlSetState($idViewConfwinStickyKeysCkbx, $GUI_UNCHECKED)
            GUICtrlSetState($idViewConfwinEdgeFirstRunCkbx, $GUI_CHECKED)
            GUICtrlSetState($idViewConfwinLongPathsCkbx, $GUI_CHECKED)
            GUICtrlSetData($idViewConfwinSudoModeCmb, "Inline")
            GUICtrlSetState($idViewConfwinPsScriptsCkbx, $GUI_CHECKED)
            GUICtrlSetState($idViewConfwinRdpCkbx, $GUI_CHECKED)
            GUICtrlSetState($idViewConfwinSmartScreenCkbx, $GUI_CHECKED)
            GUICtrlSetState($idViewConfwinWinOldCkbx, $GUI_CHECKED)

            ; Wallpapers
            GUICtrlSetData($idViewConfwinWallDeskInput, "Default")
            GUICtrlSetData($idViewConfwinWallLockInput, "Default")

        Case 3 ; Custom
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("confwin.mode.status.custom", "Personalization mode: Custom (user customized settings)"))
    EndSwitch

    $g_bViewConfwinInitializing = False
EndFunc

Func _ViewConfwinOnControlModified()
    If $g_bViewConfwinInitializing Then Return

    ; If user modifies any control while in Preset mode (0, 1, 2), shift to Custom (3)
    If $g_iViewConfwinCurMode <> 3 Then
        $g_iViewConfwinCurMode = 3
        GUICtrlSetData($idViewConfwinModeSlider, 3)
        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("confwin.mode.status.custom", "Personalization mode: Custom (user customized settings)"))
    EndIf
EndFunc

Func _ViewConfwinSetControlsState($iState)
    ; Explorer
    GUICtrlSetState($idViewConfwinShowExtCkbx, $iState)
    GUICtrlSetState($idViewConfwinLaunchToLbl, $iState)
    GUICtrlSetState($idViewConfwinLaunchToCmb, $iState)
    GUICtrlSetState($idViewConfwinHiddenItemsLbl, $iState)
    GUICtrlSetState($idViewConfwinHiddenItemsCmb, $iState)

    ; Taskbar
    GUICtrlSetState($idViewConfwinAlignLbl, $iState)
    GUICtrlSetState($idViewConfwinAlignCmb, $iState)
    GUICtrlSetState($idViewConfwinEndTaskCkbx, $iState)
    GUICtrlSetState($idViewConfwinSearchModeLbl, $iState)
    GUICtrlSetState($idViewConfwinSearchModeCmb, $iState)
    GUICtrlSetState($idViewConfwinWidgetsCkbx, $iState)
    GUICtrlSetState($idViewConfwinTaskviewCkbx, $iState)
    GUICtrlSetState($idViewConfwinUnpinDefaultsCkbx, $iState)

    ; Start Menu
    GUICtrlSetState($idViewConfwinDisableBingCkbx, $iState)
    GUICtrlSetState($idViewConfwinRemoveStartPinsCkbx, $iState)
    GUICtrlSetState($idViewConfwinFoldersLbl, $iState)
    GUICtrlSetState($idViewConfwinFoldersInput, $iState)

    ; Desktop & Control Panel
    GUICtrlSetState($idViewConfwinDeskIconsLbl, $iState)
    GUICtrlSetState($idViewConfwinDeskIconsInput, $iState)
    GUICtrlSetState($idViewConfwinDeskSortLbl, $iState)
    GUICtrlSetState($idViewConfwinDeskSortCmb, $iState)
    GUICtrlSetState($idViewConfwinCPanelViewLbl, $iState)
    GUICtrlSetState($idViewConfwinCPanelViewCmb, $iState)

    ; System
    GUICtrlSetState($idViewConfwinClipboardCkbx, $iState)
    GUICtrlSetState($idViewConfwinStickyKeysCkbx, $iState)
    GUICtrlSetState($idViewConfwinEdgeFirstRunCkbx, $iState)
    GUICtrlSetState($idViewConfwinLongPathsCkbx, $iState)
    GUICtrlSetState($idViewConfwinSudoModeLbl, $iState)
    GUICtrlSetState($idViewConfwinSudoModeCmb, $iState)
    GUICtrlSetState($idViewConfwinPsScriptsCkbx, $iState)
    GUICtrlSetState($idViewConfwinRdpCkbx, $iState)
    GUICtrlSetState($idViewConfwinSmartScreenCkbx, $iState)
    GUICtrlSetState($idViewConfwinWinOldCkbx, $iState)

    ; Wallpapers
    GUICtrlSetState($idViewConfwinWallDeskLbl, $iState)
    GUICtrlSetState($idViewConfwinWallDeskInput, $iState)
    GUICtrlSetState($idViewConfwinWallDeskBrowseBtn, $iState)
    GUICtrlSetState($idViewConfwinWallLockLbl, $iState)
    GUICtrlSetState($idViewConfwinWallLockInput, $iState)
    GUICtrlSetState($idViewConfwinWallLockBrowseBtn, $iState)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration Persistence
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewConfwinLoadData($sCustomFile = "")
    Local $sConfig = ($sCustomFile <> "" And FileExists($sCustomFile)) ? $sCustomFile : _GetConfwinConfigPath()
    If Not FileExists($sConfig) Then
        _ViewConfwinApplyPreset(1)
        Return False
    EndIf

    $g_bViewConfwinInitializing = True
    Local $iMode = Int(IniRead($sConfig, "Configuration", "mode", "1"))
    $g_iViewConfwinCurMode = $iMode
    GUICtrlSetData($idViewConfwinModeSlider, $iMode)

    Local $sLogPath = IniRead($sConfig, "Configuration", "log_path", "C:\AutoInstaller\confwin.log")
    GUICtrlSetData($idViewConfwinLogPathInput, $sLogPath)

    Local $iState = ($iMode = 0) ? $GUI_DISABLE : $GUI_ENABLE
    _ViewConfwinSetControlsState($iState)

    ; Explorer
    GUICtrlSetState($idViewConfwinShowExtCkbx, (StringLower(IniRead($sConfig, "explorer", "show_extensions", "true")) = "true") ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetData($idViewConfwinLaunchToCmb, IniRead($sConfig, "explorer", "launch_to", "ThisPC"))
    GUICtrlSetData($idViewConfwinHiddenItemsCmb, IniRead($sConfig, "explorer", "hidden_items", "HideAll"))

    ; Taskbar
    GUICtrlSetData($idViewConfwinAlignCmb, IniRead($sConfig, "taskbar", "alignment", "Left"))
    GUICtrlSetState($idViewConfwinEndTaskCkbx, (StringLower(IniRead($sConfig, "taskbar", "end_task", "true")) = "true") ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetData($idViewConfwinSearchModeCmb, IniRead($sConfig, "taskbar", "search_mode", "Icon"))
    GUICtrlSetState($idViewConfwinWidgetsCkbx, (StringLower(IniRead($sConfig, "taskbar", "widgets", "false")) = "true") ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($idViewConfwinTaskviewCkbx, (StringLower(IniRead($sConfig, "taskbar", "taskview", "Hide")) = "show") ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($idViewConfwinUnpinDefaultsCkbx, (StringLower(IniRead($sConfig, "taskbar", "unpin_defaults", "false")) = "true") ? $GUI_CHECKED : $GUI_UNCHECKED)

    ; Start Menu
    GUICtrlSetState($idViewConfwinDisableBingCkbx, (StringLower(IniRead($sConfig, "start_menu", "disable_bing_search", "true")) = "true") ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($idViewConfwinRemoveStartPinsCkbx, (StringLower(IniRead($sConfig, "start_menu", "remove_default_pins", "false")) = "true") ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetData($idViewConfwinFoldersInput, IniRead($sConfig, "start_menu", "folders", "Settings, File Explorer"))

    ; Desktop & Control Panel
    GUICtrlSetData($idViewConfwinDeskIconsInput, IniRead($sConfig, "desktop", "icons", "This PC, Recycle Bin"))
    GUICtrlSetData($idViewConfwinDeskSortCmb, IniRead($sConfig, "desktop", "sort", "None"))
    GUICtrlSetData($idViewConfwinCPanelViewCmb, IniRead($sConfig, "control_panel", "view", "Large"))

    ; System
    GUICtrlSetState($idViewConfwinClipboardCkbx, (StringLower(IniRead($sConfig, "system", "clipboard_history", "true")) = "true") ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($idViewConfwinStickyKeysCkbx, (StringLower(IniRead($sConfig, "system", "sticky_keys", "false")) = "true") ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($idViewConfwinEdgeFirstRunCkbx, (StringLower(IniRead($sConfig, "system", "hide_edge_first_run", "true")) = "true") ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($idViewConfwinLongPathsCkbx, (StringLower(IniRead($sConfig, "system", "enable_long_paths", "false")) = "true") ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetData($idViewConfwinSudoModeCmb, IniRead($sConfig, "system", "sudo_mode", "Inline"))
    GUICtrlSetState($idViewConfwinPsScriptsCkbx, (StringLower(IniRead($sConfig, "system", "allow_powershell_scripts", "false")) = "true") ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($idViewConfwinRdpCkbx, (StringLower(IniRead($sConfig, "system", "enable_rdp", "false")) = "true") ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($idViewConfwinSmartScreenCkbx, (StringLower(IniRead($sConfig, "system", "disable_smart_app_control", "false")) = "true") ? $GUI_CHECKED : $GUI_UNCHECKED)
    GUICtrlSetState($idViewConfwinWinOldCkbx, (StringLower(IniRead($sConfig, "system", "delete_windows_old", "false")) = "true") ? $GUI_CHECKED : $GUI_UNCHECKED)

    ; Wallpapers
    GUICtrlSetData($idViewConfwinWallDeskInput, IniRead($sConfig, "wallpaper", "desktop", "Default"))
    GUICtrlSetData($idViewConfwinWallLockInput, IniRead($sConfig, "wallpaper", "lockscreen", "Default"))

    $g_bViewConfwinInitializing = False
    Return True
EndFunc

Func viewConfwinSaveData($sCustomFile = "")
    Local $sBaseConfig = _GetConfwinConfigPath()
    Local $sConfig = $sBaseConfig
    If $sCustomFile <> "" Then
        $sConfig = $sCustomFile
        If Not FileExists($sConfig) And FileExists($sBaseConfig) Then
            FileCopy($sBaseConfig, $sConfig, $FC_OVERWRITE)
        EndIf
    EndIf

    Local $sDir = StringLeft($sConfig, StringInStr($sConfig, "\", 0, -1) - 1)
    If $sDir <> "" And Not FileExists($sDir) Then DirCreate($sDir)

    IniWrite($sConfig, "Configuration", "mode", String($g_iViewConfwinCurMode))
    IniWrite($sConfig, "Configuration", "log_path", GUICtrlRead($idViewConfwinLogPathInput))

    ; Explorer
    IniWrite($sConfig, "explorer", "show_extensions", (GUICtrlRead($idViewConfwinShowExtCkbx) = $GUI_CHECKED) ? "true" : "false")
    IniWrite($sConfig, "explorer", "launch_to", GUICtrlRead($idViewConfwinLaunchToCmb))
    IniWrite($sConfig, "explorer", "hidden_items", GUICtrlRead($idViewConfwinHiddenItemsCmb))

    ; Taskbar
    IniWrite($sConfig, "taskbar", "alignment", GUICtrlRead($idViewConfwinAlignCmb))
    IniWrite($sConfig, "taskbar", "end_task", (GUICtrlRead($idViewConfwinEndTaskCkbx) = $GUI_CHECKED) ? "true" : "false")
    IniWrite($sConfig, "taskbar", "search_mode", GUICtrlRead($idViewConfwinSearchModeCmb))
    IniWrite($sConfig, "taskbar", "widgets", (GUICtrlRead($idViewConfwinWidgetsCkbx) = $GUI_CHECKED) ? "true" : "false")
    IniWrite($sConfig, "taskbar", "taskview", (GUICtrlRead($idViewConfwinTaskviewCkbx) = $GUI_CHECKED) ? "Show" : "Hide")
    IniWrite($sConfig, "taskbar", "unpin_defaults", (GUICtrlRead($idViewConfwinUnpinDefaultsCkbx) = $GUI_CHECKED) ? "true" : "false")

    ; Start Menu
    IniWrite($sConfig, "start_menu", "disable_bing_search", (GUICtrlRead($idViewConfwinDisableBingCkbx) = $GUI_CHECKED) ? "true" : "false")
    IniWrite($sConfig, "start_menu", "remove_default_pins", (GUICtrlRead($idViewConfwinRemoveStartPinsCkbx) = $GUI_CHECKED) ? "true" : "false")
    IniWrite($sConfig, "start_menu", "folders", GUICtrlRead($idViewConfwinFoldersInput))

    ; Desktop & Control Panel
    IniWrite($sConfig, "desktop", "icons", GUICtrlRead($idViewConfwinDeskIconsInput))
    IniWrite($sConfig, "desktop", "sort", GUICtrlRead($idViewConfwinDeskSortCmb))
    IniWrite($sConfig, "control_panel", "view", GUICtrlRead($idViewConfwinCPanelViewCmb))

    ; System
    IniWrite($sConfig, "system", "clipboard_history", (GUICtrlRead($idViewConfwinClipboardCkbx) = $GUI_CHECKED) ? "true" : "false")
    IniWrite($sConfig, "system", "sticky_keys", (GUICtrlRead($idViewConfwinStickyKeysCkbx) = $GUI_CHECKED) ? "true" : "false")
    IniWrite($sConfig, "system", "hide_edge_first_run", (GUICtrlRead($idViewConfwinEdgeFirstRunCkbx) = $GUI_CHECKED) ? "true" : "false")
    IniWrite($sConfig, "system", "enable_long_paths", (GUICtrlRead($idViewConfwinLongPathsCkbx) = $GUI_CHECKED) ? "true" : "false")
    IniWrite($sConfig, "system", "sudo_mode", GUICtrlRead($idViewConfwinSudoModeCmb))
    IniWrite($sConfig, "system", "allow_powershell_scripts", (GUICtrlRead($idViewConfwinPsScriptsCkbx) = $GUI_CHECKED) ? "true" : "false")
    IniWrite($sConfig, "system", "enable_rdp", (GUICtrlRead($idViewConfwinRdpCkbx) = $GUI_CHECKED) ? "true" : "false")
    IniWrite($sConfig, "system", "disable_smart_app_control", (GUICtrlRead($idViewConfwinSmartScreenCkbx) = $GUI_CHECKED) ? "true" : "false")
    IniWrite($sConfig, "system", "delete_windows_old", (GUICtrlRead($idViewConfwinWinOldCkbx) = $GUI_CHECKED) ? "true" : "false")

    ; Wallpapers
    IniWrite($sConfig, "wallpaper", "desktop", GUICtrlRead($idViewConfwinWallDeskInput))
    IniWrite($sConfig, "wallpaper", "lockscreen", GUICtrlRead($idViewConfwinWallLockInput))
    Return True
EndFunc

Func viewConfwinReset()
    GUICtrlSetData($idViewConfwinLogPathInput, "C:\AutoInstaller\confwin.log")
    _ViewConfwinApplyPreset(1) ; Reset to Basic
EndFunc

Func _ViewConfwinImportConfig()
    Local $sImportFile = FileOpenDialog(i18nGet("confwin.dialog.import.title", "Select Windows configuration to import"), @ScriptDir, i18nGet("confwin.dialog.import.filter", "Configuration files (*.ini)|All files (*.*)"), BitOR($FD_FILEMUSTEXIST, $FD_PATHMUSTEXIST))
    If Not @error And $sImportFile <> "" Then
        If viewConfwinLoadData($sImportFile) Then
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("confwin.status.imported", "Imported Windows configuration successfully"))
        Else
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.error", "Error"))
        EndIf
    EndIf
EndFunc

Func _ViewConfwinExportConfig()
    Local $sExportFile = FileSaveDialog(i18nGet("confwin.dialog.export.title", "Export Windows configuration"), @ScriptDir, i18nGet("confwin.dialog.export.filter", "Configuration files (*.ini)|All files (*.*)"), $FD_PROMPTOVERWRITE, "config.ini")
    If Not @error And $sExportFile <> "" Then
        If Not StringRegExp($sExportFile, '(?i)\.ini$') Then $sExportFile &= ".ini"
        If viewConfwinSaveData($sExportFile) Then
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("confwin.status.exported", "Exported Windows configuration successfully"))
        Else
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.error", "Error"))
        EndIf
    EndIf
EndFunc

Func _ViewConfwinOpenConfigFile()
    Local $sConfig = _GetConfwinConfigPath()
    If FileExists($sConfig) Then
        ShellExecute($sConfig)
        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("confwin.status.opened", "Opened Windows configuration in editor"))
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Localization & Theming
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewConfwinApplyLang()
    GUICtrlSetData($idViewConfwinTitle, i18nGet("confwin.title", "Customize Windows Settings"))

    ; Header
    GUICtrlSetData($hViewConfwinModeGroup, i18nGet("confwin.mode.title", "Personalization Mode"))
    GUICtrlSetTip($hViewConfwinModeGroup, i18nGet("confwin.mode.tip", "Switch between Disabled, Basic, Advanced, and Custom personalization modes"))
    GUICtrlSetData($idViewConfwinModeLbl, i18nGet("confwin.mode.label", "Personalization Mode: "))
    GUICtrlSetData($idViewConfwinModeDisLbl, i18nGet("confwin.mode.disabled.label", "Disabled"))
    GUICtrlSetTip($idViewConfwinModeDisLbl, i18nGet("confwin.mode.disabled.tip", "Disable all Windows personalization options"))
    GUICtrlSetData($idViewConfwinModeBasLbl, i18nGet("confwin.mode.basic.label", "Basic"))
    GUICtrlSetTip($idViewConfwinModeBasLbl, i18nGet("confwin.mode.basic.tip", "Apply standard quality-of-life Windows tweaks"))
    GUICtrlSetData($idViewConfwinModeAdvLbl, i18nGet("confwin.mode.advanced.label", "Advanced"))
    GUICtrlSetTip($idViewConfwinModeAdvLbl, i18nGet("confwin.mode.advanced.tip", "Apply comprehensive power-user and developer optimizations"))
    GUICtrlSetData($idViewConfwinModeCusLbl, i18nGet("confwin.mode.custom.label", "Custom"))
    GUICtrlSetTip($idViewConfwinModeCusLbl, i18nGet("confwin.mode.custom.tip", "Freely customize individual personalization settings"))

    ; Section 1: Explorer
    GUICtrlSetData($hViewConfwinExplorerGroup, i18nGet("confwin.group.explorer", "File Explorer"))
    GUICtrlSetTip($hViewConfwinExplorerGroup, i18nGet("confwin.group.explorer.tip", "File Explorer view settings, extensions, and default folder"))
    GUICtrlSetData($idViewConfwinShowExtCkbx, i18nGet("confwin.explorer.show_extensions", "Show known file extensions"))
    GUICtrlSetTip($idViewConfwinShowExtCkbx, i18nGet("confwin.explorer.show_extensions.tip", "Display file extensions such as .txt, .exe, .au3 in File Explorer"))
    GUICtrlSetData($idViewConfwinLaunchToLbl, i18nGet("confwin.explorer.launch_to", "Open File Explorer to: "))
    GUICtrlSetTip($idViewConfwinLaunchToLbl, i18nGet("confwin.explorer.launch_to.tip", "Initial location when opening a new File Explorer window"))
    GUICtrlSetData($idViewConfwinHiddenItemsLbl, i18nGet("confwin.explorer.hidden_items", "Hidden items: "))
    GUICtrlSetTip($idViewConfwinHiddenItemsLbl, i18nGet("confwin.explorer.hidden_items.tip", "Control visibility of hidden and protected operating system files"))

    ; Section 2: Taskbar
    GUICtrlSetData($hViewConfwinTaskbarGroup, i18nGet("confwin.group.taskbar", "Taskbar"))
    GUICtrlSetTip($hViewConfwinTaskbarGroup, i18nGet("confwin.group.taskbar.tip", "Taskbar alignment, search mode, buttons, and context menu options"))
    GUICtrlSetData($idViewConfwinAlignLbl, i18nGet("confwin.taskbar.alignment", "Taskbar alignment: "))
    GUICtrlSetTip($idViewConfwinAlignLbl, i18nGet("confwin.taskbar.alignment.tip", "Align Taskbar items to the Left or Center"))
    GUICtrlSetData($idViewConfwinEndTaskCkbx, i18nGet("confwin.taskbar.end_task", "Show 'End task' in context menu"))
    GUICtrlSetTip($idViewConfwinEndTaskCkbx, i18nGet("confwin.taskbar.end_task.tip", "Add End Task option directly to taskbar right-click menu"))
    GUICtrlSetData($idViewConfwinSearchModeLbl, i18nGet("confwin.taskbar.search_mode", "Search box mode: "))
    GUICtrlSetTip($idViewConfwinSearchModeLbl, i18nGet("confwin.taskbar.search_mode.tip", "Configure search appearance: Hide, Icon only, or Full box"))
    GUICtrlSetData($idViewConfwinWidgetsCkbx, i18nGet("confwin.taskbar.widgets", "Show Widgets (News & Interests)"))
    GUICtrlSetTip($idViewConfwinWidgetsCkbx, i18nGet("confwin.taskbar.widgets.tip", "Enable or disable Widgets weather and news feed on the taskbar"))
    GUICtrlSetData($idViewConfwinTaskviewCkbx, i18nGet("confwin.taskbar.taskview", "Show Taskview button"))
    GUICtrlSetTip($idViewConfwinTaskviewCkbx, i18nGet("confwin.taskbar.taskview.tip", "Display or hide the Task View button next to Search"))
    GUICtrlSetData($idViewConfwinUnpinDefaultsCkbx, i18nGet("confwin.taskbar.unpin_defaults", "Remove default taskbar pinned apps"))
    GUICtrlSetTip($idViewConfwinUnpinDefaultsCkbx, i18nGet("confwin.taskbar.unpin_defaults.tip", "Unpin Microsoft default apps (Store, Mail, Chat) from taskbar"))

    ; Section 3: Start Menu
    GUICtrlSetData($hViewConfwinStartGroup, i18nGet("confwin.group.start", "Start Menu"))
    GUICtrlSetTip($hViewConfwinStartGroup, i18nGet("confwin.group.start.tip", "Start Menu search behavior, pinned apps, and folder shortcuts"))
    GUICtrlSetData($idViewConfwinDisableBingCkbx, i18nGet("confwin.start.disable_bing", "Disable Bing web search results"))
    GUICtrlSetTip($idViewConfwinDisableBingCkbx, i18nGet("confwin.start.disable_bing.tip", "Prevent Start Menu search from querying Bing and showing online results"))
    GUICtrlSetData($idViewConfwinRemoveStartPinsCkbx, i18nGet("confwin.start.remove_pins", "Remove default Start Menu pinned apps"))
    GUICtrlSetTip($idViewConfwinRemoveStartPinsCkbx, i18nGet("confwin.start.remove_pins.tip", "Clear promotional and default pinned app tiles in Start Menu"))
    GUICtrlSetData($idViewConfwinFoldersLbl, i18nGet("confwin.start.folders", "Folders beside Power button: "))
    GUICtrlSetTip($idViewConfwinFoldersLbl, i18nGet("confwin.start.folders.tip", "Select which folder shortcuts appear next to the power button in Start Menu"))

    ; Section 4: Desktop & Control Panel
    GUICtrlSetData($hViewConfwinDesktopGroup, i18nGet("confwin.group.desktop", "Desktop & Control Panel"))
    GUICtrlSetTip($hViewConfwinDesktopGroup, i18nGet("confwin.group.desktop.tip", "Desktop system icons, sorting behavior, and Control Panel view"))
    GUICtrlSetData($idViewConfwinDeskIconsLbl, i18nGet("confwin.desktop.icons", "Desktop icons: "))
    GUICtrlSetTip($idViewConfwinDeskIconsLbl, i18nGet("confwin.desktop.icons.tip", "Select standard system icons to display on the desktop"))
    GUICtrlSetData($idViewConfwinDeskSortLbl, i18nGet("confwin.desktop.sort", "Desktop icons sorting: "))
    GUICtrlSetTip($idViewConfwinDeskSortLbl, i18nGet("confwin.desktop.sort.tip", "Automatic desktop icons sort order"))
    GUICtrlSetData($idViewConfwinCPanelViewLbl, i18nGet("confwin.cpanel.view", "Control Panel view: "))
    GUICtrlSetTip($idViewConfwinCPanelViewLbl, i18nGet("confwin.cpanel.view.tip", "Default view style when opening Windows Control Panel"))

    ; Section 5: System & Developer
    GUICtrlSetData($hViewConfwinSystemGroup, i18nGet("confwin.group.system", "System & Developer"))
    GUICtrlSetTip($hViewConfwinSystemGroup, i18nGet("confwin.group.system.tip", "System policies, developer tools, clipboard, and maintenance"))
    GUICtrlSetData($idViewConfwinClipboardCkbx, i18nGet("confwin.system.clipboard", "Enable Clipboard history (Win+V)"))
    GUICtrlSetTip($idViewConfwinClipboardCkbx, i18nGet("confwin.system.clipboard.tip", "Save multiple copied items and access them via Win+V"))
    GUICtrlSetData($idViewConfwinStickyKeysCkbx, i18nGet("confwin.system.sticky_keys", "Enable Sticky Keys shortcut (5x Shift)"))
    GUICtrlSetTip($idViewConfwinStickyKeysCkbx, i18nGet("confwin.system.sticky_keys.tip", "Trigger Sticky Keys confirmation when pressing Shift 5 times"))
    GUICtrlSetData($idViewConfwinEdgeFirstRunCkbx, i18nGet("confwin.system.edge_first_run", "Hide Microsoft Edge first run wizard"))
    GUICtrlSetTip($idViewConfwinEdgeFirstRunCkbx, i18nGet("confwin.system.edge_first_run.tip", "Skip splash screens and initial setup prompts when opening Microsoft Edge"))
    GUICtrlSetData($idViewConfwinLongPathsCkbx, i18nGet("confwin.system.long_paths", "Enable Win32 long paths (>260 chars)"))
    GUICtrlSetTip($idViewConfwinLongPathsCkbx, i18nGet("confwin.system.long_paths.tip", "Allow file paths exceeding the 260-character MAX_PATH limit"))
    GUICtrlSetData($idViewConfwinSudoModeLbl, i18nGet("confwin.system.sudo", "Sudo command mode: "))
    GUICtrlSetTip($idViewConfwinSudoModeLbl, i18nGet("confwin.system.sudo.tip", "Configure elevation behavior for sudo command on Windows 11 24H2+"))
    GUICtrlSetData($idViewConfwinPsScriptsCkbx, i18nGet("confwin.system.ps_scripts", "Allow PowerShell scripts (RemoteSigned)"))
    GUICtrlSetTip($idViewConfwinPsScriptsCkbx, i18nGet("confwin.system.ps_scripts.tip", "Set execution policy to RemoteSigned for local script execution"))
    GUICtrlSetData($idViewConfwinRdpCkbx, i18nGet("confwin.system.rdp", "Enable Remote Desktop (RDP)"))
    GUICtrlSetTip($idViewConfwinRdpCkbx, i18nGet("confwin.system.rdp.tip", "Allow remote desktop connections and configure Windows Firewall rule"))
    GUICtrlSetData($idViewConfwinSmartScreenCkbx, i18nGet("confwin.system.smart_screen", "Disable Smart App Control"))
    GUICtrlSetTip($idViewConfwinSmartScreenCkbx, i18nGet("confwin.system.smart_screen.tip", "Disable Smart App Control verification for third-party executables"))
    GUICtrlSetData($idViewConfwinWinOldCkbx, i18nGet("confwin.system.win_old", "Delete empty C:\Windows.old folder"))
    GUICtrlSetTip($idViewConfwinWinOldCkbx, i18nGet("confwin.system.win_old.tip", "Automatically remove leftover empty Windows.old directory if present"))

    ; Section 6: Wallpapers
    GUICtrlSetData($hViewConfwinWallpaperGroup, i18nGet("confwin.group.wallpaper", "Wallpapers"))
    GUICtrlSetTip($hViewConfwinWallpaperGroup, i18nGet("confwin.group.wallpaper.tip", "Configure custom desktop and lock screen wallpaper images"))
    GUICtrlSetData($idViewConfwinWallDeskLbl, i18nGet("confwin.wallpaper.desktop", "Desktop wallpaper: "))
    GUICtrlSetTip($idViewConfwinWallDeskLbl, i18nGet("confwin.wallpaper.desktop.tip", "Path to image file for desktop background"))
    GUICtrlSetData($idViewConfwinWallLockLbl, i18nGet("confwin.wallpaper.lockscreen", "Lock screen wallpaper: "))
    GUICtrlSetTip($idViewConfwinWallLockLbl, i18nGet("confwin.wallpaper.lockscreen.tip", "Path to image file for lock screen background"))
    GUICtrlSetData($idViewConfwinWallDeskBrowseBtn, i18nGet("confwin.wallpaper.browse", "Browse"))
    GUICtrlSetData($idViewConfwinWallLockBrowseBtn, i18nGet("confwin.wallpaper.browse", "Browse"))

    ; Section 7: Auto-installation
    GUICtrlSetData($hViewConfwinInstallGroup, i18nGet("confwin.autoinstall.title", "Auto-installation"))
    GUICtrlSetTip($hViewConfwinInstallGroup, i18nGet("confwin.autoinstall.tip", "Configuration settings for Windows configuration deployment and logging"))
    GUICtrlSetData($idViewConfwinLogPathLbl, i18nGet("confwin.logpath.label", "Log Path: "))
    GUICtrlSetTip($idViewConfwinLogPathLbl, i18nGet("confwin.logpath.tip", "File path where Windows configuration logs will be saved"))
    GUICtrlSetTip($idViewConfwinLogPathInput, i18nGet("confwin.logpath.tip", "File path where Windows configuration logs will be saved"))
    GUICtrlSetData($idViewConfwinLogBrowseBtn, i18nGet("confwin.btn.browse", "Browse"))
    GUICtrlSetTip($idViewConfwinLogBrowseBtn, i18nGet("confwin.btn.browse.tip", "Select destination folder for Windows configuration logs"))

    ; Toolbar Buttons
    If $g_hCurrentView = $hViewConfwin Then
        GUICtrlSetData($a_idToolBarBtn[0], i18nGet("reset.btn.title", "Reset"))
        GUICtrlSetTip($a_idToolBarBtn[0], i18nGet("confwin.toolbar.reset.tip", "Reset all Windows configuration settings to defaults"))
        GUICtrlSetData($a_idToolBarBtn[1], i18nGet("import.btn.title", "Import"))
        GUICtrlSetTip($a_idToolBarBtn[1], i18nGet("confwin.toolbar.import.tip", "Import Windows configuration file"))
        GUICtrlSetData($a_idToolBarBtn[2], i18nGet("export.btn.title", "Export"))
        GUICtrlSetTip($a_idToolBarBtn[2], i18nGet("confwin.toolbar.export.tip", "Export Windows configuration to file"))
        GUICtrlSetData($a_idToolBarBtn[3], i18nGet("open.btn.title", "Open"))
        GUICtrlSetTip($a_idToolBarBtn[3], i18nGet("confwin.toolbar.open.tip", "Open Windows configuration file in text editor"))
        GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("save.btn.title", "Save"))
        GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("confwin.toolbar.save.tip", "Save Windows configuration to config.ini"))
        GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.title", "Cancel"))
        GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.tip", "Discard changes and reload saved configuration"))
    EndIf
EndFunc

Func viewConfwinToolBar()
    ; Button Index 0: [Reset]
    GUICtrlSetData($a_idToolBarBtn[0], i18nGet("reset.btn.title", "Reset"))
    GUICtrlSetTip($a_idToolBarBtn[0], i18nGet("confwin.toolbar.reset.tip", "Reset all Windows configuration settings to defaults"))
    GUICtrlSetState($a_idToolBarBtn[0], $GUI_SHOW)

    ; Button Index 1: [Import]
    GUICtrlSetData($a_idToolBarBtn[1], i18nGet("import.btn.title", "Import"))
    GUICtrlSetTip($a_idToolBarBtn[1], i18nGet("confwin.toolbar.import.tip", "Import Windows configuration file"))
    GUICtrlSetState($a_idToolBarBtn[1], $GUI_SHOW)

    ; Button Index 2: [Export]
    GUICtrlSetData($a_idToolBarBtn[2], i18nGet("export.btn.title", "Export"))
    GUICtrlSetTip($a_idToolBarBtn[2], i18nGet("confwin.toolbar.export.tip", "Export Windows configuration to file"))
    GUICtrlSetState($a_idToolBarBtn[2], $GUI_SHOW)

    ; Button Index 3: [Open]
    GUICtrlSetData($a_idToolBarBtn[3], i18nGet("open.btn.title", "Open"))
    GUICtrlSetTip($a_idToolBarBtn[3], i18nGet("confwin.toolbar.open.tip", "Open Windows configuration file in text editor"))
    GUICtrlSetState($a_idToolBarBtn[3], $GUI_SHOW)

    ; Button Index 6: [Save]
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("save.btn.title", "Save"))
    GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("confwin.toolbar.save.tip", "Save Windows configuration to config.ini"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 2], $GUI_SHOW)

    ; Button Index 7: [Cancel]
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.title", "Cancel"))
    GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.tip", "Discard changes and reload saved configuration"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 1], $GUI_SHOW)
EndFunc

Func viewConfwinApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hViewConfwin)

    GUICtrlSetColor($idViewConfwinTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinTitle, themeColor("main.view.bg"))

    ; Header
    GUICtrlSetBkColor($idViewConfwinModeSlider, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinModeLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinModeLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinModeDisLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinModeDisLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinModeBasLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinModeBasLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinModeAdvLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinModeAdvLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinModeCusLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinModeCusLbl, themeColor("main.view.bg"))

    ; Section 1: Explorer
    GUICtrlSetColor($idViewConfwinShowExtCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinShowExtCkbx, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinLaunchToLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinLaunchToLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinHiddenItemsLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinHiddenItemsLbl, themeColor("main.view.bg"))

    ; Section 2: Taskbar
    GUICtrlSetColor($idViewConfwinAlignLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinAlignLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinEndTaskCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinEndTaskCkbx, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinSearchModeLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinSearchModeLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinWidgetsCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinWidgetsCkbx, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinTaskviewCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinTaskviewCkbx, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinUnpinDefaultsCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinUnpinDefaultsCkbx, themeColor("main.view.bg"))

    ; Section 3: Start Menu
    GUICtrlSetColor($idViewConfwinDisableBingCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinDisableBingCkbx, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinRemoveStartPinsCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinRemoveStartPinsCkbx, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinFoldersLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinFoldersLbl, themeColor("main.view.bg"))

    ; Section 4: Desktop & Control Panel
    GUICtrlSetColor($idViewConfwinDeskIconsLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinDeskIconsLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinDeskSortLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinDeskSortLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinCPanelViewLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinCPanelViewLbl, themeColor("main.view.bg"))

    ; Section 5: System
    GUICtrlSetColor($idViewConfwinClipboardCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinClipboardCkbx, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinStickyKeysCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinStickyKeysCkbx, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinEdgeFirstRunCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinEdgeFirstRunCkbx, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinLongPathsCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinLongPathsCkbx, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinSudoModeLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinSudoModeLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinPsScriptsCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinPsScriptsCkbx, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinRdpCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinRdpCkbx, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinSmartScreenCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinSmartScreenCkbx, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinWinOldCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinWinOldCkbx, themeColor("main.view.bg"))

    ; Section 6: Wallpapers
    GUICtrlSetColor($idViewConfwinWallDeskLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinWallDeskLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idViewConfwinWallLockLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinWallLockLbl, themeColor("main.view.bg"))

    ; Section 7: Auto-installation
    GUICtrlSetColor($idViewConfwinLogPathLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinLogPathLbl, themeColor("main.view.bg"))
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Event Dispatcher
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewConfwinHandleEvent($idMsg)
    Switch $idMsg
        ; Mode Slider Events
        Case $idViewConfwinModeDisLbl
            _ViewConfwinApplyPreset(0)

        Case $idViewConfwinModeBasLbl
            _ViewConfwinApplyPreset(1)

        Case $idViewConfwinModeAdvLbl
            _ViewConfwinApplyPreset(2)

        Case $idViewConfwinModeCusLbl
            _ViewConfwinApplyPreset(3)

        Case $idViewConfwinModeSlider
            _ViewConfwinApplyPreset(GUICtrlRead($idViewConfwinModeSlider))

        ; Browse Wallpapers
        Case $idViewConfwinWallDeskBrowseBtn
            Local $sFile = FileOpenDialog(i18nGet("confwin.wallpaper.browse", "Browse"), @WindowsDir, "Images (*.jpg;*.jpeg;*.png;*.bmp)", BitOR($FD_FILEMUSTEXIST, $FD_PATHMUSTEXIST))
            If Not @error And $sFile <> "" Then
                GUICtrlSetData($idViewConfwinWallDeskInput, $sFile)
                _ViewConfwinOnControlModified()
            EndIf

        Case $idViewConfwinWallLockBrowseBtn
            Local $sFile = FileOpenDialog(i18nGet("confwin.wallpaper.browse", "Browse"), @WindowsDir, "Images (*.jpg;*.jpeg;*.png;*.bmp)", BitOR($FD_FILEMUSTEXIST, $FD_PATHMUSTEXIST))
            If Not @error And $sFile <> "" Then
                GUICtrlSetData($idViewConfwinWallLockInput, $sFile)
                _ViewConfwinOnControlModified()
            EndIf

        ; Auto-installation Log Path Browse Button
        Case $idViewConfwinLogBrowseBtn
            _ViewConfwinBrowseLogPath()

        ; Toolbar Button 0: [Reset]
        Case $a_idToolBarBtn[0]
            viewConfwinReset()
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("confwin.status.reset", "Reset Windows configuration settings to defaults"))

        ; Toolbar Button 1: [Import]
        Case $a_idToolBarBtn[1]
            _ViewConfwinImportConfig()

        ; Toolbar Button 2: [Export]
        Case $a_idToolBarBtn[2]
            _ViewConfwinExportConfig()

        ; Toolbar Button 3: [Open]
        Case $a_idToolBarBtn[3]
            _ViewConfwinOpenConfigFile()

        ; Toolbar Button 6: [Save]
        Case $a_idToolBarBtn[$iToolBarBtnCol - 2]
            If viewConfwinSaveData() Then
                appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("confwin.status.saved", "Saved Windows configuration successfully"))
            Else
                appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.error", "Error"))
            EndIf

        ; Toolbar Button 7: [Cancel]
        Case $a_idToolBarBtn[$iToolBarBtnCol - 1]
            viewConfwinLoadData()
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("confwin.status.canceled", "Reverted Windows configuration to saved settings"))

        ; Control Modifications (flip to Custom if in preset mode)
        Case $idViewConfwinShowExtCkbx, _
             $idViewConfwinLaunchToCmb, _
             $idViewConfwinHiddenItemsCmb, _
             $idViewConfwinAlignCmb, _
             $idViewConfwinEndTaskCkbx, _
             $idViewConfwinSearchModeCmb, _
             $idViewConfwinWidgetsCkbx, _
             $idViewConfwinTaskviewCkbx, _
             $idViewConfwinUnpinDefaultsCkbx, _
             $idViewConfwinDisableBingCkbx, _
             $idViewConfwinRemoveStartPinsCkbx, _
             $idViewConfwinFoldersInput, _
             $idViewConfwinDeskIconsInput, _
             $idViewConfwinDeskSortCmb, _
             $idViewConfwinCPanelViewCmb, _
             $idViewConfwinClipboardCkbx, _
             $idViewConfwinStickyKeysCkbx, _
             $idViewConfwinEdgeFirstRunCkbx, _
             $idViewConfwinLongPathsCkbx, _
             $idViewConfwinSudoModeCmb, _
             $idViewConfwinPsScriptsCkbx, _
             $idViewConfwinRdpCkbx, _
             $idViewConfwinSmartScreenCkbx, _
             $idViewConfwinWinOldCkbx, _
             $idViewConfwinWallDeskInput, _
             $idViewConfwinWallLockInput
            _ViewConfwinOnControlModified()
    EndSwitch
EndFunc
