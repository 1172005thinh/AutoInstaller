;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/confwin.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Const
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Includes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Libraries
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

; Controls
#include "../controls/button.au3"

; Modules
#include "../modules/i18n.au3"
#include "../modules/theme.au3"
#include <MsgBoxConstants.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Views/Confwin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewConfwinCreate($hParent, $iX, $iY, $iW, $iH)
    Global $hviewConfwin = GUICreate("", $iW, $iH, $iX, $iY, $WS_CHILD, -1, $hParent)
    
    $iX = $iP
    $iY = $iP
    $iW = $iW - $iP * 2
    $iH = $iLblH * 2
    Global $idviewConfwinTitle = GUICtrlCreateLabel("", $iX, $iY, $iW, $iH)
    GUICtrlSetFont(-1, 16, 800)
    
    viewConfwinApplyLang()
    viewConfwinApplyTheme()
    Return $hviewConfwin
EndFunc

Func viewConfwinApplyLang()
    GUICtrlSetData($idviewConfwinTitle, i18nGet("confwin.title"))
EndFunc

Func viewConfwinApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hviewConfwin)
    
    GUICtrlSetColor($idviewConfwinTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idviewConfwinTitle, themeColor("main.view.bg"))
EndFunc