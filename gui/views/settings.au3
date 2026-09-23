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
    Local $iEstCanvasH = 360
    If $iContentH < $iEstCanvasH Then $iContentH = $iEstCanvasH

    $hViewSettings = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewSettings)

    Local $iLblW = ($iContentW - $iP * 6) * 30 / 100
    Local $iInputW = ($iContentW - $iP * 6) * 58 / 100
    Local $iColW = ($iContentW - $iP * 6) / 2
    Local $iPx = $iLblH * 20 / 100
    Local $iGroupH = 0
    Local $iItemY = 0
    Local $iRowH = $iLblH + $iP * 2

    ; View Settings Title
    Local $iX = $iP
    Local $iY = $iP
    Local $iCtrlW = $iContentW
    Local $iCtrlH = $iLblH * 2
    $hViewSettingsTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)
    
    ; Initialize Preferences Group
    $iGroupH = $iRowH * 2 + $iP * 3
    $iX = $iP
    $iY += $iLblH * 2 + $iP
    $hViewSettingsPreferGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iGroupH)
    
    ; Language Selector
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $hViewSettingsLangLabel = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $hViewSettingsLangCombo = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($hViewSettingsLangCombo, "English (en-us)|Tiếng Việt (vi-vn)", ($sCurrentLang = "vi-vn" ? "Tiếng Việt (vi-vn)" : "English (en-us)"))
    
    ; Theme Selector
    $iX = $iP * 3
    $iItemY += $iRowH
    $hViewSettingsThemeLabel = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $hViewSettingsThemeCombo = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($hViewSettingsThemeCombo, "Light|Dark", ($sCurrentTheme = "dark" ? "Dark" : "Light"))
    GUICtrlCreateGroup("", -99, -99, -99, -99)
    
    viewSettingsApplyLang()
    viewSettingsApplyTheme()
    Return $hViewSettings
EndFunc

Func viewSettingsApplyLang()
    GUICtrlSetData($hViewSettingsTitle, i18nGet("settings.title", "Settings"))
    
    GUICtrlSetData($hViewSettingsPreferGroup, i18nGet("settings.prefer.title", "Preferences"))
    GUICtrlSetData($hViewSettingsLangLabel, i18nGet("settings.prefer.lang.label", "Language: "))
    GUICtrlSetData($hViewSettingsThemeLabel, i18nGet("settings.prefer.theme.label", "Theme (Experimental): "))
    
    If $g_hCurrentView = $hViewSettings Then
        GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.title", "Cancel"))
        GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("save.btn.title", "Save"))
    EndIf
EndFunc

Func viewSettingsToolBar()    
    ; Button Index 8: [Save]
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("save.btn.title", "Save"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 2], $GUI_SHOW)
    
    ; Button Index 9: [Cancel]
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.title", "Cancel"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 1], $GUI_SHOW)
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
            ; [Save] - Save settings to config.ini and apply live changes
            ; Resolve selected language
            Local $sSelectedLang = StringInStr(GUICtrlRead($hViewSettingsLangCombo), "vi-vn") ? "vi-vn" : "en-us"
            ; Resolve selected theme
            Local $sSelectedTheme = (GUICtrlRead($hViewSettingsThemeCombo) = "Dark") ? "dark" : "light"
            configSave($sSelectedLang, $sSelectedTheme)   
                     
            ; Apply live changes
            appSetLanguage($sSelectedLang)
            appSetTheme($sSelectedTheme)
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.saved", "Saved"))

        Case $a_idToolBarBtn[$iToolBarBtnCol - 1]
            ; [Cancel] - Discard changes & restore saved configuration
            Local $aConfig = configLoad()
            GUICtrlSetData($hViewSettingsLangCombo, ($aConfig[0] = "vi-vn" ? "Tiếng Việt (vi-vn)" : "English (en-us)"))
            GUICtrlSetData($hViewSettingsThemeCombo, ($aConfig[1] = "dark" ? "Dark" : "Light"))
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.ready", "Ready"))
    EndSwitch
EndFunc