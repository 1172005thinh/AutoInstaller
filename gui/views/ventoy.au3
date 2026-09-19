;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/ventoy.au3
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
#include <MsgBoxConstants.au3>

; Controls
#include "../controls/button.au3"

; Modules
#include "../modules/i18n.au3"
#include "../modules/theme.au3"
#include "../modules/config.au3"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Views/Ventoy
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewVentoyCreate($hParent, $iX, $iY, $iW, $iH)
    Global $hviewVentoy = GUICreate("", $iW, $iH, $iX, $iY, $WS_CHILD, -1, $hParent)
    Local $iViewX = $iX
    Local $iViewY = $iY
    Local $iViewW = $iW
    Local $iViewH = $iH
    
    $iX = $iP
    $iY = $iP
    $iW = $iViewW - $iP * 2
    $iH = $iLblH * 2
    Global $idviewVentoyTitle = GUICtrlCreateLabel("", $iX, $iY, $iW, $iH)
    GUICtrlSetFont(-1, $iHeader, 800)
    
    viewVentoyApplyLang()
    viewVentoyApplyTheme()
    Return $hviewVentoy
EndFunc

Func viewVentoyApplyLang()
    GUICtrlSetData($idviewVentoyTitle, i18nGet("ventoy.title"))
EndFunc

Func viewVentoyApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hviewVentoy)
    
    GUICtrlSetColor($idviewVentoyTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idviewVentoyTitle, themeColor("main.view.bg"))
EndFunc