;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/modules/drivers.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Libraries
#include <FileConstants.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Path Resolution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Resolves canonical path to drivers/config.ini
Func driversGetConfigPath()
    If FileExists(@ScriptDir & "\drivers\config.ini") Then Return @ScriptDir & "\drivers\config.ini"
    If FileExists(@ScriptDir & "\config.ini") Then Return @ScriptDir & "\config.ini"
    Return @ScriptDir & "\drivers\config.ini"
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration File Serialization
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Reads and parses driver configuration into a structured dictionary
Func driversLoadConfigData($sFilePath = "")
    Local $sConfig = ($sFilePath <> "" And FileExists($sFilePath)) ? $sFilePath : driversGetConfigPath()
    If Not FileExists($sConfig) Then Return 0

    Local $oDict = ObjCreate("Scripting.Dictionary")
    $oDict.Item("mode") = Int(IniRead($sConfig, "Configuration", "mode", "2"))
    $oDict.Item("source") = IniRead($sConfig, "Configuration", "source", "sdio")
    $oDict.Item("winupdate_level") = Int(IniRead($sConfig, "Configuration", "winupdate_level", "1"))
    $oDict.Item("sdio_level") = Int(IniRead($sConfig, "Configuration", "sdio_level", "1"))
    $oDict.Item("log_path") = IniRead($sConfig, "Configuration", "log_path", "C:\AutoInstaller\drivers.log")

    Return $oDict
EndFunc

; Writes driver configuration settings to config.ini
Func driversSaveConfigData($sFilePath, $iMode, $sSource, $iWuLevel, $iSdioLevel, $sLogPath)
    Local $sBaseConfig = driversGetConfigPath()
    Local $sConfig = $sBaseConfig
    If $sFilePath <> "" Then
        $sConfig = $sFilePath
        If Not FileExists($sConfig) And FileExists($sBaseConfig) Then
            FileCopy($sBaseConfig, $sConfig, $FC_OVERWRITE)
        EndIf
    EndIf

    Local $sDir = StringLeft($sConfig, StringInStr($sConfig, "\", 0, -1) - 1)
    If $sDir <> "" And Not FileExists($sDir) Then DirCreate($sDir)

    IniWrite($sConfig, "Configuration", "mode", String($iMode))
    IniWrite($sConfig, "Configuration", "source", String($sSource))
    IniWrite($sConfig, "Configuration", "winupdate_level", String($iWuLevel))
    IniWrite($sConfig, "Configuration", "sdio_level", String($iSdioLevel))
    IniWrite($sConfig, "Configuration", "log_path", String($sLogPath))
    Return True
EndFunc
