;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/modules/i18n.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Includes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Const
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Libraries
#include <FileConstants.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Modules/i18n
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global Const $rLangPath = @ScriptDir & "/gui/assets/langs/"
Global $oLangDict = ObjCreate("Scripting.Dictionary")
Global $sCurrentLang = "en-us"

Func i18nLoad($sLangCode)
    $oLangDict.RemoveAll()
    Local $rFilePath = $rLangPath & $sLangCode & ".json"
    
    Local $hFile = FileOpen($rFilePath, BitOR($FO_READ, $FO_UTF8_NOBOM))
    If $hFile = -1 Then Return False
    
    Local $sContent = FileRead($hFile)
    FileClose($hFile)
    
    ; Parse "key": "value"
    Local $aMatches = StringRegExp($sContent, '(?m)"([^"\\]*(?:\\.[^"\\]*)*)"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"', 4)
    If Not @error Then
        For $i = 0 To UBound($aMatches) - 1
            Local $aPair = $aMatches[$i]
            Local $sKey = StringReplace($aPair[1], '\"', '"')
            Local $sVal = StringReplace($aPair[2], '\"', '"')
            $oLangDict.Item($sKey) = $sVal
        Next
    EndIf
    
    $sCurrentLang = $sLangCode
    Return True
EndFunc

Func i18nGet($sKey, $sFallback = "")
    If $oLangDict.Exists($sKey) Then
        Return $oLangDict.Item($sKey)
    EndIf
    If $sFallback <> "" Then Return $sFallback
    Return $sKey
EndFunc