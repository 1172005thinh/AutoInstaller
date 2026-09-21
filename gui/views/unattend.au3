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

Func viewUnattendLoadValues($sSourceFile)
    Local $oData = xmlLoadValues($sSourceFile)
    If Not IsObj($oData) Or $oData.Count = 0 Then Return False
    
    Return True
EndFunc

Func viewUnattendSaveValues($sTargetFile)
    Local $oData = ObjCreate("Scripting.Dictionary")
    
    Return xmlSaveValues($sTargetFile, $oData)
EndFunc

Func viewUnattendApplyLang()
    GUICtrlSetData($idViewUnattendTitle, i18nGet("unattend.title"))
EndFunc

Func viewUnattendToolBar()
    ; Button Index 0: [Clear]
    GUICtrlSetData($a_idToolBarBtn[0], i18nGet("clear.btn.title", "Clear"))
    GUICtrlSetState($a_idToolBarBtn[0], $GUI_SHOW)

    ; Button Index 8: [Save]
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("save.btn.title", "Save"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 2], $GUI_SHOW)

    ; Button Index 9: [Cancel]
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.title", "Cancel"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 1], $GUI_SHOW)    
EndFunc

Func viewUnattendApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hViewUnattend)
    
    GUICtrlSetColor($idViewUnattendTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewUnattendTitle, themeColor("main.view.bg"))
EndFunc

Func viewUnattendHandleEvent($idMsg)
    Switch $idMsg
        Case $a_idToolBarBtn[0]
            ; [Clear] - Reset all fields to default template values from sample.xml
            viewUnattendLoadValues($rUnattendSampleXml)
            appSetStatus(i18nGet("status.title") & i18nGet("status.cleared"))

        Case $a_idToolBarBtn[$iToolBarBtnCol - 2]
            ; [Save] - Write current form values to AutoInstaller.xml
            If viewUnattendSaveValues($rUnattendAutoXml) Then
                appSetStatus(i18nGet("status.title") & i18nGet("status.saved"))
            Else
                appSetStatus(i18nGet("status.title") & i18nGet("status.error"))
            EndIf

        Case $a_idToolBarBtn[$iToolBarBtnCol - 1]
            ; [Cancel] - Discard changes & restore saved AutoInstaller.xml values
            viewUnattendLoadValues($rUnattendAutoXml)
            appSetStatus(i18nGet("status.title") & i18nGet("status.ready"))
    EndSwitch
EndFunc