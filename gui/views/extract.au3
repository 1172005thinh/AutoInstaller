;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/extract.au3
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
; Views/Extract
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $hViewExtract = 0
Global $idviewExtractTitle = 0

Func viewExtractCreate($hViewport, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH
    If $iContentH < 360 Then $iContentH = 360

    Global $hViewExtract = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewExtract)

    Local $iX = $iP
    Local $iY = $iP
    Local $iCtrlW = $iContentW
    Local $iCtrlH = $iLblH * 2
    Global $idViewExtractTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)
    
    viewExtractApplyLang()
    viewExtractApplyTheme()
    Return $hViewExtract
EndFunc

Func viewExtractApplyLang()
    GUICtrlSetData($idViewExtractTitle, i18nGet("extract.title"))
EndFunc

Func viewExtractToolBar()
    
EndFunc

Func viewExtractApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hViewExtract)
    
    GUICtrlSetColor($idViewExtractTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewExtractTitle, themeColor("main.view.bg"))
EndFunc

Func viewExtractHandleEvent($idMsg)

EndFunc