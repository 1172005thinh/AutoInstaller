;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     AutoInstaller.au3
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

; Modules
#include "../modules/i18n.au3"
#include "../modules/theme.au3"
#include "../modules/config.au3"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Views/Settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $g_hSettingsGUI = 0
Global $hViewSettingsTitle = 0
Global $hViewSettingsLangLabel = 0, $hViewSettingsLangCombo = 0
Global $hViewSettingsThemeLabel = 0, $hViewSettingsThemeCombo = 0
Global $hViewSettingsBtnSave = 0

Func viewSettingsCreate($hParentGUI, $iX, $iY, $iW, $iH)
    Global $hViewSettings = GUICreate("", $iW, $iH, $iX, $iY, $WS_CHILD, -1, $hParentGUI)
    
    $iX = $iP
    $iY = $iP
    $iW = $iW - $iP * 2
    $iH = $iLblH * 2 
    Global $hViewSettingsTitle = GUICtrlCreateLabel("", $iX, $iY, $iW, $iH)
    GUICtrlSetFont(-1, 16, 800)
    
    ; Language Selector
    Global $hViewSettingsLangLabel = GUICtrlCreateLabel("", 15, 55, 140, 20)
    Global $hViewSettingsLangCombo = GUICtrlCreateCombo("", 160, 52, 180, 25)
    GUICtrlSetData($hViewSettingsLangCombo, "English (en-us)|Tiếng Việt (vi-vn)", ($sCurrentLang = "vi-vn" ? "Tiếng Việt (vi-vn)" : "English (en-us)"))
    
    ; Theme Selector
    Global $hViewSettingsThemeLabel = GUICtrlCreateLabel("", 15, 95, 140, 20)
    Global $hViewSettingsThemeCombo = GUICtrlCreateCombo("", 160, 92, 180, 25)
    GUICtrlSetData($hViewSettingsThemeCombo, "Light|Dark", ($sCurrentTheme = "dark" ? "Dark" : "Light"))
    
    ; Save Button
    Global $hViewSettingsBtnSave = GUICtrlCreateButton("", 15, 145, 130, 32)
    
    viewSettingsApplyLang()
    viewSettingsApplyTheme()
    Return $hViewSettings
EndFunc

Func viewSettingsApplyLang()
    GUICtrlSetData($hViewSettingsTitle, i18nGet("settings.title"))
    GUICtrlSetData($hViewSettingsLangLabel, i18nGet("settings.lang.label"))
    GUICtrlSetData($hViewSettingsThemeLabel, i18nGet("settings.theme.label"))
    GUICtrlSetData($hViewSettingsBtnSave, i18nGet("save.btn.title"))
EndFunc

Func viewSettingsApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hViewSettings)
    
    GUICtrlSetColor($hViewSettingsTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($hViewSettingsTitle, themeColor("main.view.bg"))
    
    GUICtrlSetColor($hViewSettingsLangLabel, themeColor("text.secondary"))
    GUICtrlSetBkColor($hViewSettingsLangLabel, themeColor("main.view.bg"))
    
    GUICtrlSetColor($hViewSettingsThemeLabel, themeColor("text.secondary"))
    GUICtrlSetBkColor($hViewSettingsThemeLabel, themeColor("main.view.bg"))
EndFunc

Func viewSettingsHandleEvent($idMsg)
    Switch $idMsg
        Case $hViewSettingsBtnSave
            ; Resolve selected language
            Local $sSelectedLang = StringInStr(GUICtrlRead($hViewSettingsLangCombo), "vi-vn") ? "vi-vn" : "en-us"
            ; Resolve selected theme
            Local $sSelectedTheme = (GUICtrlRead($hViewSettingsThemeCombo) = "Dark") ? "dark" : "light"
            
            ; Save to config.ini
            configSave($sSelectedLang, $sSelectedTheme)
            
            ; Apply live changes
            appSetLanguage($sSelectedLang)
            appSetTheme($sSelectedTheme)
            appSetStatus(i18nGet("status.title") & i18nGet("status.saved"))
    EndSwitch
EndFunc