;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/help.au3
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
; Views/Help
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $hViewHelp = 0
Global $idViewHelpTitle = 0

Func viewHelpCreate($hViewport, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH
    If $iContentH < 360 Then $iContentH = 360

    $hViewHelp = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewHelp)

    Local $iX = $iP
    Local $iY = $iP
    Local $iCtrlW = $iContentW
    Local $iCtrlH = $iLblH * 2
    $idViewHelpTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)
    
    viewHelpApplyLang()
    viewHelpApplyTheme()
    Return $hViewHelp
EndFunc

Func viewHelpApplyLang()
    GUICtrlSetData($idViewHelpTitle, i18nGet("help.title", "Help"))
EndFunc

Func viewHelpToolBar()
    
EndFunc

Func viewHelpApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hViewHelp)
    
    GUICtrlSetColor($idViewHelpTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewHelpTitle, themeColor("main.view.bg"))
EndFunc

Func viewHelpHandleEvent($idMsg)

EndFunc