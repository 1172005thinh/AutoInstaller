;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/modules/config.au3
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Modules/Config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global Const $rMainConfigPath = @ScriptDir & "/gui/config.ini"

Func configLoad()
    Local $aSettings[2]
    Local $sConfig = $rMainConfigPath
    If FileExists(@ScriptDir & "/config.ini") And IniRead(@ScriptDir & "/config.ini", "Preferences", "Language", "") <> "" Then
        $sConfig = @ScriptDir & "/config.ini"
    EndIf
    ; Default: en-us, light
    $aSettings[0] = IniRead($sConfig, "Preferences", "Language", "en-us")
    $aSettings[1] = IniRead($sConfig, "Preferences", "Theme", "light")
    Return $aSettings
EndFunc

Func configSave($sLang, $sTheme)
    IniWrite($rMainConfigPath, "Preferences", "Language", $sLang)
    IniWrite($rMainConfigPath, "Preferences", "Theme", $sTheme)
EndFunc