;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/drivers.au3
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
; Views/Drivers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $hViewDrivers = 0
Global $idViewDriversTitle = 0

Func viewDriversCreate($hViewport, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH
    If $iContentH < 360 Then $iContentH = 360

    Global $hViewDrivers = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewDrivers)

    Local $iX = $iP
    Local $iY = $iP
    Local $iCtrlW = $iContentW
    Local $iCtrlH = $iLblH * 2
    Global $idViewDriversTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)
    
    viewDriversApplyLang()
    viewDriversApplyTheme()
    Return $hViewDrivers
EndFunc

Func viewDriversApplyLang()
    GUICtrlSetData($idViewDriversTitle, i18nGet("drivers.title", "Customize Drivers Installation"))
EndFunc

Func viewDriversToolBar()
    
EndFunc

Func viewDriversApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hViewDrivers)
    
    GUICtrlSetColor($idViewDriversTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewDriversTitle, themeColor("main.view.bg"))
EndFunc

Func viewDriversHandleEvent($idMsg)

EndFunc