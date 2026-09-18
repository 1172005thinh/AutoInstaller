;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/drivers.au3
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Views/Drivers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewDriversCreate($hParent, $iX, $iY, $iW, $iH)
    Global $hviewDrivers = GUICreate("", $iW, $iH, $iX, $iY, $WS_CHILD, -1, $hParent)
    
    $iX = $iP
    $iY = $iP
    $iW = $iW - $iP * 2
    $iH = $iLblH * 2
    Global $idviewDriversTitle = GUICtrlCreateLabel("", $iX, $iY, $iW, $iH)
    GUICtrlSetFont(-1, 16, 800)
    
    viewDriversApplyLang()
    viewDriversApplyTheme()
    Return $hviewDrivers
EndFunc

Func viewDriversApplyLang()
    GUICtrlSetData($idviewDriversTitle, i18nGet("drivers.title"))
EndFunc

Func viewDriversApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hviewDrivers)
    
    GUICtrlSetColor($idviewDriversTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idviewDriversTitle, themeColor("main.view.bg"))
EndFunc