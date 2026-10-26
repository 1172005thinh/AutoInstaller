;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/modules/confwin.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Libraries
#include <FileConstants.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Path Resolution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Resolves canonical path to confwin/config.ini
Func confwinGetConfigPath()
    If FileExists(@ScriptDir & "\confwin\config.ini") Then Return @ScriptDir & "\confwin\config.ini"
    If FileExists(@ScriptDir & "\config.ini") Then Return @ScriptDir & "\config.ini"
    Return @ScriptDir & "\confwin\config.ini"
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Preset Definitions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Returns a structured dictionary containing configuration settings for a preset
Func confwinGetPresetValues($iPresetIndex)
    Local $oD = ObjCreate("Scripting.Dictionary")

    Switch $iPresetIndex
        Case 0 ; Disabled
            $oD.Item("mode") = 0
            $oD.Item("show_extensions") = False
            $oD.Item("launch_to") = "ThisPC"
            $oD.Item("hidden_items") = "HideAll"
            $oD.Item("alignment") = "Left"
            $oD.Item("end_task") = False
            $oD.Item("search_mode") = "Icon"
            $oD.Item("widgets") = False
            $oD.Item("taskview") = False
            $oD.Item("unpin_defaults") = False
            $oD.Item("disable_bing_search") = False
            $oD.Item("remove_default_pins") = False
            $oD.Item("folders") = ""
            $oD.Item("icons") = ""
            $oD.Item("sort") = "None"
            $oD.Item("view") = "Large"
            $oD.Item("clipboard_history") = False
            $oD.Item("sticky_keys") = False
            $oD.Item("hide_edge_first_run") = False
            $oD.Item("enable_long_paths") = False
            $oD.Item("sudo_mode") = "Inline"
            $oD.Item("allow_powershell_scripts") = False
            $oD.Item("enable_rdp") = False
            $oD.Item("disable_smart_app_control") = False
            $oD.Item("delete_windows_old") = False
            $oD.Item("wallpaper_desktop") = "Default"
            $oD.Item("wallpaper_lockscreen") = "Default"

        Case 1 ; Basic Mode (Standard daily-driver quality of life)
            $oD.Item("mode") = 1
            $oD.Item("show_extensions") = True
            $oD.Item("launch_to") = "ThisPC"
            $oD.Item("hidden_items") = "HideAll"
            $oD.Item("alignment") = "Left"
            $oD.Item("end_task") = True
            $oD.Item("search_mode") = "Icon"
            $oD.Item("widgets") = False
            $oD.Item("taskview") = False
            $oD.Item("unpin_defaults") = False
            $oD.Item("disable_bing_search") = True
            $oD.Item("remove_default_pins") = False
            $oD.Item("folders") = "Settings, File Explorer"
            $oD.Item("icons") = "This PC, Recycle Bin"
            $oD.Item("sort") = "None"
            $oD.Item("view") = "Large"
            $oD.Item("clipboard_history") = True
            $oD.Item("sticky_keys") = False
            $oD.Item("hide_edge_first_run") = True
            $oD.Item("enable_long_paths") = False
            $oD.Item("sudo_mode") = "Inline"
            $oD.Item("allow_powershell_scripts") = False
            $oD.Item("enable_rdp") = False
            $oD.Item("disable_smart_app_control") = False
            $oD.Item("delete_windows_old") = False
            $oD.Item("wallpaper_desktop") = "Default"
            $oD.Item("wallpaper_lockscreen") = "Default"

        Case 2 ; Advanced Mode (Power-user and developer optimizations)
            $oD.Item("mode") = 2
            $oD.Item("show_extensions") = True
            $oD.Item("launch_to") = "ThisPC"
            $oD.Item("hidden_items") = "Show"
            $oD.Item("alignment") = "Left"
            $oD.Item("end_task") = True
            $oD.Item("search_mode") = "Hide"
            $oD.Item("widgets") = False
            $oD.Item("taskview") = False
            $oD.Item("unpin_defaults") = True
            $oD.Item("disable_bing_search") = True
            $oD.Item("remove_default_pins") = True
            $oD.Item("folders") = "Settings, File Explorer, Downloads"
            $oD.Item("icons") = "This PC, Recycle Bin, Control Panel"
            $oD.Item("sort") = "ItemType"
            $oD.Item("view") = "Large"
            $oD.Item("clipboard_history") = True
            $oD.Item("sticky_keys") = False
            $oD.Item("hide_edge_first_run") = True
            $oD.Item("enable_long_paths") = True
            $oD.Item("sudo_mode") = "Inline"
            $oD.Item("allow_powershell_scripts") = True
            $oD.Item("enable_rdp") = True
            $oD.Item("disable_smart_app_control") = True
            $oD.Item("delete_windows_old") = True
            $oD.Item("wallpaper_desktop") = "Default"
            $oD.Item("wallpaper_lockscreen") = "Default"
    EndSwitch

    Return $oD
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration File Serialization
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Reads and parses Windows customization settings into a structured dictionary
Func confwinLoadConfigData($sFilePath = "")
    Local $sConfig = ($sFilePath <> "" And FileExists($sFilePath)) ? $sFilePath : confwinGetConfigPath()
    If Not FileExists($sConfig) Then Return 0

    Local $oD = ObjCreate("Scripting.Dictionary")

    $oD.Item("mode") = Int(IniRead($sConfig, "Configuration", "mode", "1"))
    $oD.Item("log_path") = IniRead($sConfig, "Configuration", "log_path", "C:\AutoInstaller\confwin.log")

    ; Explorer
    $oD.Item("show_extensions") = (StringLower(IniRead($sConfig, "explorer", "show_extensions", "true")) = "true")
    $oD.Item("launch_to") = IniRead($sConfig, "explorer", "launch_to", "ThisPC")
    $oD.Item("hidden_items") = IniRead($sConfig, "explorer", "hidden_items", "HideAll")

    ; Taskbar
    $oD.Item("alignment") = IniRead($sConfig, "taskbar", "alignment", "Left")
    $oD.Item("end_task") = (StringLower(IniRead($sConfig, "taskbar", "end_task", "true")) = "true")
    $oD.Item("search_mode") = IniRead($sConfig, "taskbar", "search_mode", "Icon")
    $oD.Item("widgets") = (StringLower(IniRead($sConfig, "taskbar", "widgets", "false")) = "true")
    $oD.Item("taskview") = (StringLower(IniRead($sConfig, "taskbar", "taskview", "Hide")) = "show")
    $oD.Item("unpin_defaults") = (StringLower(IniRead($sConfig, "taskbar", "unpin_defaults", "false")) = "true")

    ; Start Menu
    $oD.Item("disable_bing_search") = (StringLower(IniRead($sConfig, "start_menu", "disable_bing_search", "true")) = "true")
    $oD.Item("remove_default_pins") = (StringLower(IniRead($sConfig, "start_menu", "remove_default_pins", "false")) = "true")
    $oD.Item("folders") = IniRead($sConfig, "start_menu", "folders", "Settings, File Explorer")

    ; Desktop & Control Panel
    $oD.Item("icons") = IniRead($sConfig, "desktop", "icons", "This PC, Recycle Bin")
    $oD.Item("sort") = IniRead($sConfig, "desktop", "sort", "None")
    $oD.Item("view") = IniRead($sConfig, "control_panel", "view", "Large")

    ; System
    $oD.Item("clipboard_history") = (StringLower(IniRead($sConfig, "system", "clipboard_history", "true")) = "true")
    $oD.Item("sticky_keys") = (StringLower(IniRead($sConfig, "system", "sticky_keys", "false")) = "true")
    $oD.Item("hide_edge_first_run") = (StringLower(IniRead($sConfig, "system", "hide_edge_first_run", "true")) = "true")
    $oD.Item("enable_long_paths") = (StringLower(IniRead($sConfig, "system", "enable_long_paths", "false")) = "true")
    $oD.Item("sudo_mode") = IniRead($sConfig, "system", "sudo_mode", "Inline")
    $oD.Item("allow_powershell_scripts") = (StringLower(IniRead($sConfig, "system", "allow_powershell_scripts", "false")) = "true")
    $oD.Item("enable_rdp") = (StringLower(IniRead($sConfig, "system", "enable_rdp", "false")) = "true")
    $oD.Item("disable_smart_app_control") = (StringLower(IniRead($sConfig, "system", "disable_smart_app_control", "false")) = "true")
    $oD.Item("delete_windows_old") = (StringLower(IniRead($sConfig, "system", "delete_windows_old", "false")) = "true")

    ; Wallpapers
    $oD.Item("wallpaper_desktop") = IniRead($sConfig, "wallpaper", "desktop", "Default")
    $oD.Item("wallpaper_lockscreen") = IniRead($sConfig, "wallpaper", "lockscreen", "Default")

    Return $oD
EndFunc

; Writes Windows customization settings to config.ini
Func confwinSaveConfigData($sFilePath, $oD)
    If Not IsObj($oD) Then Return False

    Local $sBaseConfig = confwinGetConfigPath()
    Local $sConfig = $sBaseConfig
    If $sFilePath <> "" Then
        $sConfig = $sFilePath
        If Not FileExists($sConfig) And FileExists($sBaseConfig) Then
            FileCopy($sBaseConfig, $sConfig, $FC_OVERWRITE)
        EndIf
    EndIf

    Local $sDir = StringLeft($sConfig, StringInStr($sConfig, "\", 0, -1) - 1)
    If $sDir <> "" And Not FileExists($sDir) Then DirCreate($sDir)

    IniWrite($sConfig, "Configuration", "mode", String($oD.Item("mode")))
    IniWrite($sConfig, "Configuration", "log_path", String($oD.Item("log_path")))

    ; Explorer
    IniWrite($sConfig, "explorer", "show_extensions", $oD.Item("show_extensions") ? "true" : "false")
    IniWrite($sConfig, "explorer", "launch_to", String($oD.Item("launch_to")))
    IniWrite($sConfig, "explorer", "hidden_items", String($oD.Item("hidden_items")))

    ; Taskbar
    IniWrite($sConfig, "taskbar", "alignment", String($oD.Item("alignment")))
    IniWrite($sConfig, "taskbar", "end_task", $oD.Item("end_task") ? "true" : "false")
    IniWrite($sConfig, "taskbar", "search_mode", String($oD.Item("search_mode")))
    IniWrite($sConfig, "taskbar", "widgets", $oD.Item("widgets") ? "true" : "false")
    IniWrite($sConfig, "taskbar", "taskview", $oD.Item("taskview") ? "Show" : "Hide")
    IniWrite($sConfig, "taskbar", "unpin_defaults", $oD.Item("unpin_defaults") ? "true" : "false")

    ; Start Menu
    IniWrite($sConfig, "start_menu", "disable_bing_search", $oD.Item("disable_bing_search") ? "true" : "false")
    IniWrite($sConfig, "start_menu", "remove_default_pins", $oD.Item("remove_default_pins") ? "true" : "false")
    IniWrite($sConfig, "start_menu", "folders", String($oD.Item("folders")))

    ; Desktop & Control Panel
    IniWrite($sConfig, "desktop", "icons", String($oD.Item("icons")))
    IniWrite($sConfig, "desktop", "sort", String($oD.Item("sort")))
    IniWrite($sConfig, "control_panel", "view", String($oD.Item("view")))

    ; System
    IniWrite($sConfig, "system", "clipboard_history", $oD.Item("clipboard_history") ? "true" : "false")
    IniWrite($sConfig, "system", "sticky_keys", $oD.Item("sticky_keys") ? "true" : "false")
    IniWrite($sConfig, "system", "hide_edge_first_run", $oD.Item("hide_edge_first_run") ? "true" : "false")
    IniWrite($sConfig, "system", "enable_long_paths", $oD.Item("enable_long_paths") ? "true" : "false")
    IniWrite($sConfig, "system", "sudo_mode", String($oD.Item("sudo_mode")))
    IniWrite($sConfig, "system", "allow_powershell_scripts", $oD.Item("allow_powershell_scripts") ? "true" : "false")
    IniWrite($sConfig, "system", "enable_rdp", $oD.Item("enable_rdp") ? "true" : "false")
    IniWrite($sConfig, "system", "disable_smart_app_control", $oD.Item("disable_smart_app_control") ? "true" : "false")
    IniWrite($sConfig, "system", "delete_windows_old", $oD.Item("delete_windows_old") ? "true" : "false")

    ; Wallpapers
    IniWrite($sConfig, "wallpaper", "desktop", String($oD.Item("wallpaper_desktop")))
    IniWrite($sConfig, "wallpaper", "lockscreen", String($oD.Item("wallpaper_lockscreen")))
    Return True
EndFunc
