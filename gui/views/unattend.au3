;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/unattend.au3
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
; Views/Unattend
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $hViewUnattend = 0
Global $idViewUnattendTitle = 0

Func viewUnattendCreate($hViewPort, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH
    If $iContentH < 360 Then $iContentH = 360

    Global $hViewUnattend = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewUnattend)

    Local $iX = $iP
    Local $iY = $iP
    Local $iCtrlW = $iContentW
    Local $iCtrlH = $iLblH * 2
    Global $idViewUnattendTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)
    
    viewUnattendApplyLang()
    viewUnattendApplyTheme()
    Return $hViewUnattend
EndFunc

Func viewUnattendApplyLang()
    GUICtrlSetData($idViewUnattendTitle, i18nGet("unattend.title"))
EndFunc

Func viewUnattendToolBar()
    
EndFunc

Func viewUnattendApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hViewUnattend)
    
    GUICtrlSetColor($idViewUnattendTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewUnattendTitle, themeColor("main.view.bg"))
EndFunc

Func viewUnattendHandleEvent($idMsg)

EndFunc