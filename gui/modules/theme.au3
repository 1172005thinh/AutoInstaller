;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/modules/theme.au3
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
; Modules/Theme
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GLobal Const $rThemePath = @ScriptDir & "/gui/assets/themes/"
Global $oThemeDict = ObjCreate("Scripting.Dictionary")
Global $sCurrentTheme = "light"

Func themeLoad($sThemeName)
    $oThemeDict.RemoveAll()
    Local $sFilePath = $rThemePath & $sThemeName & ".json"
    
    Local $hFile = FileOpen($sFilePath, BitOR($FO_READ, $FO_UTF8_NOBOM))
    If $hFile = -1 Then Return False
    
    Local $sContent = FileRead($hFile)
    FileClose($hFile)
    
    ; Parse "key": "value"
    Local $aMatches = StringRegExp($sContent, '(?m)"([^"\\]*(?:\\.[^"\\]*)*)"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"', 4)
    If Not @error Then
        For $i = 0 To UBound($aMatches) - 1
            Local $aPair = $aMatches[$i]
            $oThemeDict.Item($aPair[1]) = Number($aPair[2]) ; Store hex as numeric color value
        Next
    EndIf
    
    $sCurrentTheme = $sThemeName
    Return True
EndFunc

Func themeColor($sKey)
    If $oThemeDict.Exists($sKey) Then
        Return $oThemeDict.Item($sKey)
    EndIf
    Return 0x000000
EndFunc