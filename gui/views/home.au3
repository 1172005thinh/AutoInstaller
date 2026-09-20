;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/home.au3
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
; Views/Home
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $hViewHome = 0
Global $idViewHomeTitle = 0

Func viewHomeCreate($hViewPort, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH
    If $iContentH < 360 Then $iContentH = 360

    Global $hViewHome = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewHome)

    Local $iX = $iP
    Local $iY = $iP
    Local $iCtrlW = $iContentW
    Local $iCtrlH = $iLblH * 2
    Global $idViewHomeTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)
    
    viewHomeApplyLang()
    viewHomeApplyTheme()
    Return $hViewHome
EndFunc

Func viewHomeApplyLang()
    GUICtrlSetData($idViewHomeTitle, i18nGet("home.title"))
EndFunc

Func viewHomeToolBar()
    
EndFunc

Func viewHomeApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hViewHome)
    
    GUICtrlSetColor($idViewHomeTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewHomeTitle, themeColor("main.view.bg"))
EndFunc

Func viewHomeHandleEvent($idMsg)

EndFunc