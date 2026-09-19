;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     AutoInstaller.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Const
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global Const $rMainIconPath = @ScriptDir & "/gui/assets/icons/AutoInstaller.ico"

Global Const $iP = 10
Global Const $iMainW = 800
Global Const $iMainH = 600
Global Const $iNavW = $iMainW * 20 / 100
Global Const $iNavH = $iMainH * 70 / 100
Global Const $iStatusBarH = 24
Global Const $iBtnH = 32
Global Const $iLblH = 16
Global Const $iToolBarBtnCol = 10
Global Const $iCtrlBtnCol = 3
Global Const $iCtrlBtnRow = 2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Includes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Libraries
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GuiStatusBar.au3>
#include <StatusBarConstants.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <MsgBoxConstants.au3>

; Controls
#include "gui/controls/button.au3"

; Modules
#include "gui/modules/config.au3"
#include "gui/modules/i18n.au3"
#include "gui/modules/theme.au3"

; Pages
#include "gui/views/home.au3"
#include "gui/views/unattend.au3"
#include "gui/views/apps.au3"
#include "gui/views/drivers.au3"
#include "gui/views/confwin.au3"
#include "gui/views/ventoy.au3"
#include "gui/views/extract.au3"
#include "gui/views/settings.au3"
#include "gui/views/help.au3"
#include <FileConstants.au3>

; Compile
#pragma compile(Icon, $rMainIconPath)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $a_iPos[4]
Global $iX = 0
Global $iY = 0
Global $iW = 0
Global $iH = 0
Global $g_hCurrentView = 0

; 1. Load stored configuration
$aConfig = configLoad()
i18nLoad($aConfig[0])
themeLoad($aConfig[1])
;valueLoad($aConfig[2])

; 2. Initialize Main
$iX = 0
$iY = 0
$iW = $iMainW
$iH = $iMainH
Global $hMain = GUICreate(i18nGet("main.title"), $iW, $iH, -1, -1)
GUISetIcon($rMainIconPath, -1, $hMain)

; 3. Initialize Navigation Panel
Global $hNavGroup = GUICtrlCreateGroup(i18nGet("main.nav.title"), $iP, $iP, $iNavW, $iNavH)
; Navigation View Button
$iX = $iP * 2
$iY = $iP * 3
$iW = $iNavW - $iP * 2
$iH = $iBtnH
Global $a_idNavViewBtn[9]
For $i = 0 To 6
    $a_idNavViewBtn[$i] = GUICtrlCreateButton("", $iX, $iY + ($iH + $iP) * $i, $iW, $iH)
Next
$a_idNavViewBtn[7] = GUICtrlCreateButton("", $iX, $iNavH - $iBtnH * 2 - $iP * 1, $iW, $iH)
$a_idNavViewBtn[8] = GUICtrlCreateButton("", $iX, $iNavH - $iBtnH * 1 - $iP * 0, $iW, $iH)
GUICtrlCreateGroup("", -99, -99, -99, -99)

; 4. Instantiate View
$a_iPos = ControlGetPos($hMain, "", $hNavGroup)
$iX = $a_iPos[0] + $a_iPos[2] + $iP
$iY = $a_iPos[0]
$iW = $iMainW - $a_iPos[0] - $a_iPos[2] - $iP * 2
$iH = $a_iPos[3] - $iBtnH - $iP * 4
Global $hViewHome = viewHomeCreate($hMain, $iX, $iY, $iW, $iH)
Global $hViewUnattend = viewUnattendCreate($hMain, $iX, $iY, $iW, $iH)
Global $hViewApps = viewAppsCreate($hMain, $iX, $iY, $iW, $iH)
Global $hViewDrivers = viewDriversCreate($hMain, $iX, $iY, $iW, $iH)
Global $hViewConfwin = viewConfwinCreate($hMain, $iX, $iY, $iW, $iH)
Global $hViewVentoy = viewVentoyCreate($hMain, $iX, $iY, $iW, $iH)
Global $hViewExtract = viewExtractCreate($hMain, $iX, $iY, $iW, $iH)
Global $hViewSettings = viewSettingsCreate($hMain, $iX, $iY, $iW, $iH)
Global $hViewHelp = viewHelpCreate($hMain, $iX, $iY, $iW, $iH)
GUISwitch($hMain)

; 5. Instantiate Tool Bar
$iX = $a_iPos[0] + $a_iPos[2] + $iP
$iY = $a_iPos[3] - $iBtnH - $iP * 2
$iW = $iMainW - $a_iPos[0] - $a_iPos[2] - $iP * 2
$iH = $iBtnH + $iP * 3
Global $hToolBar = GUICtrlCreateGroup(i18nGet("main.tool.title"), $iX, $iY, $iW, $iH)
; Tool Bar Buttons
$iX = $a_iPos[0] + $a_iPos[2] + $iP * 2
$iY = $a_iPos[3] - $iBtnH
$iW = ($iMainW - $a_iPos[0] - $a_iPos[2] - $iP * ($iToolBarBtnCol + 3)) / $iToolBarBtnCol
$iH = $iBtnH
Global $a_idToolBarBtn[$iToolBarBtnCol]
For $i = 0 to $iToolBarBtnCol - 1
    $a_idToolBarBtn[$i] = GUICtrlCreateButton("", $iX + ($iW + $iP) * $i, $iY, $iW, $iH)
    ; Hide by default
    GUICtrlSetState($a_idToolBarBtn[$i], $GUI_HIDE)
Next
GUICtrlCreateGroup("", -99, -99, -99, -99)

; 6. Initialize Control Panel
$iX = $a_iPos[0]
$iY = $a_iPos[1] + $a_iPos[3] + $iP
$iW = $iMainW - $iP * 2
$iH = $iMainH - $iNavH - $iStatusBarH - $iP * 3
Global $hCtrlGroup = GUICtrlCreateGroup(i18nGet("main.ctrl.title"), $iX, $iY, $iW, $iH)
; Log Edit
$iX = $a_iPos[0] + $iP
$iY = $a_iPos[1] + $a_iPos[3] + $iP * 3
$iW = ($iMainW - $iP * 5) / 2
$iH = $iMainH - $iNavH - $iStatusBarH - $iP * 6
Global $hCtrlLogEdit = GUICtrlCreateEdit("", $iX, $iY, $iW, $iH, BitOR($ES_AUTOVSCROLL, $ES_READONLY, $WS_VSCROLL, $WS_HSCROLL))
; Control Buttons
$iX = $a_iPos[0] + ($iMainW - $iP * 5) / 2 + $iP * 2
$iY = $a_iPos[1] + $a_iPos[3] + $iP * 3
$iW = (($iMainW - $iP * 5) / 2 - $iP * ($iCtrlBtnCol - 1)) / $iCtrlBtnCol
$iH = ($iMainH - $iNavH - $iStatusBarH - $iP * ($iCtrlBtnRow + 5)) / $iCtrlBtnRow
Global $a_idCtrlBtn[$iCtrlBtnCol][$iCtrlBtnRow]
For $i = 0 to $iCtrlBtnCol - 1
    For $j = 0 to $iCtrlBtnRow - 1
        $a_idCtrlBtn[$i][$j] = GUICtrlCreateButton("", $iX + ($iW + $iP) * $i, $iY + ($iH + $iP) * $j, $iW, $iH)
    Next
Next
GUICtrlCreateGroup("", -99, -99, -99, -99)

; 7. Initialize Status Bar
Global $hStatusBar = _GUICtrlStatusBar_Create($hMain)
_SendMessage($hStatusBar, $SB_SETMINHEIGHT, $iStatusBarH, 0)
_GUICtrlStatusBar_Resize($hStatusBar)

; 8. Central App State Controllers
Func appApplyLanguage()
    WinSetTitle($hMain, "", i18nGet("main.title"))
    GUICtrlSetData($hNavGroup, i18nGet("main.nav.title"))
    GUICtrlSetData($hToolBar, i18nGet("main.tool.title"))
    GUICtrlSetData($hCtrlGroup, i18nGet("main.ctrl.title"))
    GUICtrlSetData($a_idNavViewBtn[0], i18nGet("home.btn.title"))
    GUICtrlSetData($a_idNavViewBtn[1], i18nGet("unattend.btn.title"))
    GUICtrlSetData($a_idNavViewBtn[2], i18nGet("apps.btn.title"))
    GUICtrlSetData($a_idNavViewBtn[3], i18nGet("drivers.btn.title"))
    GUICtrlSetData($a_idNavViewBtn[4], i18nGet("confwin.btn.title"))
    GUICtrlSetData($a_idNavViewBtn[5], i18nGet("ventoy.btn.title"))
    GUICtrlSetData($a_idNavViewBtn[6], i18nGet("extract.btn.title"))
    GUICtrlSetData($a_idNavViewBtn[7], i18nGet("settings.btn.title"))
    GUICtrlSetData($a_idNavViewBtn[8], i18nGet("help.btn.title"))
    viewHomeApplyLang()
    viewUnattendApplyLang()
    viewAppsApplyLang()
    viewDriversApplyLang()
    viewConfwinApplyLang()
    viewVentoyApplyLang()
    viewExtractApplyLang()
    viewSettingsApplyLang()
    viewHelpApplyLang()
EndFunc

Func appApplyTheme()
    GUISetBkColor(themeColor("main.bg"), $hMain)
    GUICtrlSetColor($hNavGroup, themeColor("text.primary"))
    viewHomeApplyTheme()
    viewUnattendApplyTheme()
    viewAppsApplyTheme()
    viewDriversApplyTheme()
    viewConfwinApplyTheme()
    viewVentoyApplyTheme()
    viewExtractApplyTheme()
    viewSettingsApplyTheme()
    viewHelpApplyTheme()
EndFunc

Func appSetLanguage($sLangCode)
    If i18nLoad($sLangCode) Then appApplyLanguage()
EndFunc

Func appSetTheme($sThemeName)
    If themeLoad($sThemeName) Then appApplyTheme()
EndFunc

Func appSetStatus($sText)
    _GUICtrlStatusBar_SetText($hStatusBar, $sText, 0)
EndFunc

Func appView($hTargetPage)
    GUISetState(@SW_HIDE, $hViewHome)
    GUISetState(@SW_HIDE, $hViewUnattend)
    GUISetState(@SW_HIDE, $hViewApps)
    GUISetState(@SW_HIDE, $hViewDrivers)
    GUISetState(@SW_HIDE, $hViewConfwin)
    GUISetState(@SW_HIDE, $hViewVentoy)
    GUISetState(@SW_HIDE, $hViewExtract)
    GUISetState(@SW_HIDE, $hViewSettings)
    GUISetState(@SW_HIDE, $hViewHelp)
    GUISetState(@SW_SHOW, $hTargetPage)
    $g_hCurrentView = $hTargetPage

    ; Update Tool Bar Buttons based on current page
    ; Assign this local variable to get the current page
    Local $hView = $hTargetPage

    ; Reset toolbar: hide all buttons by default
    For $i = 0 To $iToolBarBtnCol - 1
        GUICtrlSetState($a_idToolBarBtn[$i], $GUI_HIDE)
    Next

    Switch $hView
        Case $hViewHome
            ; No tool bar buttons shown
        Case $hViewUnattend
            ; Decide later
        Case $hViewApps
            ; Decide later
        Case $hViewDrivers
            ; Decide later
        Case $hViewConfwin
            ; Decide later
        Case $hViewVentoy
            ; Decide later
        Case $hViewExtract
            ; Decide later
        Case $hViewSettings
            viewSettingsToolBar()
        Case $hViewHelp
            ; Decide later
        Case Else
            ; Default
    EndSwitch
EndFunc

; 9. Render Default State
appApplyLanguage()
appApplyTheme()
appSetStatus(i18nGet("status.welcome"))
appView($hViewHome)
;appView($hViewUnattend)
;appView($hViewApps)
;appView($hViewDrivers)
;appView($hViewConfwin)
;appView($hViewVentoy)
;appView($hViewExtract)
;appView($hViewSettings)
;appView($hViewHelp)
GUISetState(@SW_SHOW, $hMain)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

While 1
    Local $iMsg = GUIGetMsg()
    
    Switch $iMsg
        Case $GUI_EVENT_CLOSE
            ExitLoop
            
        Case $a_idNavViewBtn[0]
            appView($hViewHome)
            appSetStatus(i18nGet("status.title") & i18nGet("home.btn.title"))
            
        Case $a_idNavViewBtn[1]
            appView($hViewUnattend)
            appSetStatus(i18nGet("status.title") & i18nGet("unattend.btn.title"))
        
        Case $a_idNavViewBtn[2]
            appView($hViewApps)
            appSetStatus(i18nGet("status.title") & i18nGet("apps.btn.title"))
        
        Case $a_idNavViewBtn[3]
            appView($hViewDrivers)
            appSetStatus(i18nGet("status.title") & i18nGet("drivers.btn.title"))
        
        Case $a_idNavViewBtn[4]
            appView($hViewConfwin)
            appSetStatus(i18nGet("status.title") & i18nGet("confwin.btn.title"))
        
        Case $a_idNavViewBtn[5]
            appView($hViewVentoy)
            appSetStatus(i18nGet("status.title") & i18nGet("ventoy.btn.title"))
        
        Case $a_idNavViewBtn[6]
            appView($hViewExtract)
            appSetStatus(i18nGet("status.title") & i18nGet("extract.btn.title"))
        
        Case $a_idNavViewBtn[7]
            appView($hViewSettings)
            appSetStatus(i18nGet("status.title") & i18nGet("settings.btn.title"))
        
        Case $a_idNavViewBtn[8]
            appView($hViewHelp)
            appSetStatus(i18nGet("status.title") & i18nGet("help.btn.title"))
    EndSwitch

    Switch $g_hCurrentView
        ;Case $hViewUnattend
        ;    viewUnattendHandleEvent($iMsg)
        ;Case $hViewApps
        ;    viewAppsHandleEvent($iMsg)
        ;Case $hViewDrivers
        ;    viewDriversHandleEvent($iMsg)
        ;Case $hViewConfwin
        ;    viewConfwinHandleEvent($iMsg)
        ;Case $hViewExtract
        ;    viewExtractHandleEvent($iMsg)
        Case $hViewSettings
            viewSettingsHandleEvent($iMsg)
        ;Case $hViewHelp
        ;    viewHelpHandleEvent($iMsg)
    EndSwitch
WEnd

GUIDelete($hMain)
