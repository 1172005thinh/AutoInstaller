;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/ventoy.au3
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
; Views/Ventoy
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $hViewVentoy = 0
Global $idViewVentoyTitle = 0

Func viewVentoyCreate($hViewport, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH
    If $iContentH < 360 Then $iContentH = 360

    Global $hViewVentoy = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewVentoy)

    Local $iX = $iP
    Local $iY = $iP
    Local $iCtrlW = $iContentW
    Local $iCtrlH = $iLblH * 2
    Global $idViewVentoyTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)
    
    viewVentoyApplyLang()
    viewVentoyApplyTheme()
    Return $hViewVentoy
EndFunc

Func viewVentoyApplyLang()
    GUICtrlSetData($idViewVentoyTitle, i18nGet("ventoy.title", "Customize Ventoy"))
EndFunc

Func viewVentoyToolBar()
    
EndFunc

Func viewVentoyApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hViewVentoy)
    
    GUICtrlSetColor($idViewVentoyTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewVentoyTitle, themeColor("main.view.bg"))
EndFunc

Func viewVentoyHandleEvent($idMsg)

EndFunc