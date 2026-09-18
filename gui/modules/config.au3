;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/modules/config.au3
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Modules/Config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global Const $rMainConfigPath = @ScriptDir & "/gui/config.ini"

Func configLoad()
    Local $aSettings[2]
    ; Default: en-us, light
    $aSettings[0] = IniRead($rMainConfigPath, "Preferences", "Language", "en-us")
    $aSettings[1] = IniRead($rMainConfigPath, "Preferences", "Theme", "light")
    Return $aSettings
EndFunc

Func configSave($sLang, $sTheme)
    IniWrite($rMainConfigPath, "Preferences", "Language", $sLang)
    IniWrite($rMainConfigPath, "Preferences", "Theme", $sTheme)
EndFunc