;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/confwin.au3
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
; Views/Confwin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $hViewConfwin = 0
Global $idviewConfwinTitle = 0

Func viewConfwinCreate($hViewport, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH
    If $iContentH < 360 Then $iContentH = 360

    $hViewConfwin = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewConfwin)

    Local $iX = $iP
    Local $iY = $iP
    Local $iCtrlW = $iContentW
    Local $iCtrlH = $iLblH * 2
    $idViewConfwinTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)
    
    viewConfwinApplyLang()
    viewConfwinApplyTheme()
    Return $hViewConfwin
EndFunc

Func viewConfwinApplyLang()
    GUICtrlSetData($idViewConfwinTitle, i18nGet("confwin.title", "Customize Windows Settings"))
EndFunc

Func viewConfwinToolBar()
    
EndFunc

Func viewConfwinApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hViewConfwin)
    
    GUICtrlSetColor($idViewConfwinTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewConfwinTitle, themeColor("main.view.bg"))
EndFunc

Func viewConfwinHandleEvent($idMsg)

EndFunc