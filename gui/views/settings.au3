;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/settings.au3
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
; Views/Settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $hViewSettings = 0
Global $hViewSettingsTitle = 0
Global $hViewSettingsPreferGroup = 0
Global $hViewSettingsLangLabel = 0
Global $hViewSettingsLangCombo = 0
Global $hViewSettingsThemeLabel = 0
Global $hViewSettingsThemeCombo = 0

Func viewSettingsCreate($hViewport, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH
    If $iContentH < 360 Then $iContentH = 360

    Global $hViewSettings = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewSettings)

    Local $iLblW = ($iW - $iP * 2) * 30 / 100
    Local $iCmbW = ($iW - $iP * 2) * 30 / 100 - $iP * 3
    Local $iPx = $iLblH * 20 / 100

    ; View Settings Title
    Local $iX = $iP
    Local $iY = $iP
    Local $iCtrlW = $iContentW
    Local $iCtrlH = $iLblH * 2
    Global $hViewSettingsTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)
    
    ; Initialize Preferences Group
    $iX = $iP
    $iY = $iLblH * 2 + $iP
    $iCtrlW = $iContentW
    $iCtrlH = $iLblH * 2 + $iP * (3 * 2 + 1)
    Global $hViewSettingsPreferGroup = GUICtrlCreateGroup(i18nGet("settings.prefer.title"), $iX, $iY, $iCtrlW, $iCtrlH)
    
    ; Language Selector
    $iX = $iP * 3
    $iY = $iLblH * 2 + $iP * 4
    $iCtrlW = $iLblW
    $iCtrlH = $iLblH
    Global $hViewSettingsLangLabel = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    $iX = $iLblW + $iP * 3
    $iY = $iLblH * 2 + $iP * 4 - $iPx
    $iCtrlW = $iCmbW
    $iCtrlH = $iLblH
    $hViewSettingsLangCombo = GUICtrlCreateCombo("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetData($hViewSettingsLangCombo, "English (en-us)|Tiếng Việt (vi-vn)", ($sCurrentLang = "vi-vn" ? "Tiếng Việt (vi-vn)" : "English (en-us)"))
    
    ; Theme Selector
    $iX = $iP * 3
    $iY = $iLblH * 2 + $iP * 8
    $iCtrlW = $iLblW
    $iCtrlH = $iLblH
    Global $hViewSettingsThemeLabel = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    $iX = $iLblW + $iP * 3
    $iY = $iLblH * 2 + $iP * 8 - $iPx
    $iCtrlW = $iCmbW
    $iCtrlH = $iLblH
    $hViewSettingsThemeCombo = GUICtrlCreateCombo("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetData($hViewSettingsThemeCombo, "Light|Dark", ($sCurrentTheme = "dark" ? "Dark" : "Light"))
    GUICtrlCreateGroup("", -99, -99, -99, -99)
    
    viewSettingsApplyLang()
    viewSettingsApplyTheme()
    Return $hViewSettings
EndFunc

Func viewSettingsApplyLang()
    GUICtrlSetData($hViewSettingsTitle, i18nGet("settings.title"))
    GUICtrlSetData($hViewSettingsPreferGroup, i18nGet("settings.prefer.title"))
    GUICtrlSetData($hViewSettingsLangLabel, i18nGet("settings.lang.label"))
    GUICtrlSetData($hViewSettingsThemeLabel, i18nGet("settings.theme.label"))
    If $g_hCurrentView = $hViewSettings Then
        GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.title", "Cancel"))
        GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("save.btn.title", "Save"))
    EndIf
EndFunc

Func viewSettingsToolBar()
    ; Cancel - last right button
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.title", "Cancel"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 1], $GUI_SHOW)
    
    ; Save - left next to Cancel
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("save.btn.title", "Save"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 2], $GUI_SHOW)
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
        Case $a_idToolBarBtn[$iToolBarBtnCol - 2]
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

        Case $a_idToolBarBtn[$iToolBarBtnCol - 1]
            ; Discard changes / reset to saved configuration
            Local $aConfig = configLoad()
            GUICtrlSetData($hViewSettingsLangCombo, ($aConfig[0] = "vi-vn" ? "Tiếng Việt (vi-vn)" : "English (en-us)"))
            GUICtrlSetData($hViewSettingsThemeCombo, ($aConfig[1] = "dark" ? "Dark" : "Light"))
            appSetStatus(i18nGet("status.title") & i18nGet("status.ready"))
    EndSwitch
EndFunc