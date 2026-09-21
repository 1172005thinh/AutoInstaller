;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/apps.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Includes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Libraries
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>

; Controls
#include "../controls/button.au3"

; Modules
#include "../modules/i18n.au3"
#include "../modules/theme.au3"
#include "../modules/config.au3"
#include "../modules/scroll.au3"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Const
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Views/Apps
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $hViewApps = 0
Global $idViewAppsTitle = 0

Func viewAppsCreate($hViewport, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH
    If $iContentH < 360 Then $iContentH = 360

    Global $hViewApps = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewApps)

    Local $iX = $iP
    Local $iY = $iP
    Local $iCtrlW = $iContentW
    Local $iCtrlH = $iLblH * 2
    Global $idViewAppsTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)
    
    viewAppsApplyLang()
    viewAppsApplyTheme()
    Return $hViewApps
EndFunc

Func viewAppsApplyLang()
    GUICtrlSetData($idViewAppsTitle, i18nGet("apps.title", "Customize App Installation"))
EndFunc

Func viewAppsToolBar()
    
EndFunc

Func viewAppsApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hViewApps)
    
    GUICtrlSetColor($idViewAppsTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewAppsTitle, themeColor("main.view.bg"))
EndFunc

Func viewAppsHandleEvent($idMsg)

EndFunc