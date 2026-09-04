; Version: v0.1.2
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; configure-windows.exe - thin admin wrapper for configure-windows.ps1
; Passes @ScriptDir & "\configure-windows.ini" and log path to the PS1 engine.

Global $g_sPsScript = @ScriptDir & "\configure-windows.ps1"
Global $g_sIniFile  = @ScriptDir & "\configure-windows.ini"
Global $g_sLogFile  = "C:\Auto-installer\configure-windows.log"

; Read log_path from INI if present
Local $sIniLog = _ReadIniValue($g_sIniFile, "log_path")
If $sIniLog <> "" Then $g_sLogFile = $sIniLog

_Log("INFO: Starting Windows post-installation configuration.")

If Not FileExists($g_sPsScript) Then
    _Log("ERROR: configure-windows.ps1 not found: " & $g_sPsScript)
    Exit 20
EndIf

Local $sPsArgs = "-NonInteractive -NoProfile -ExecutionPolicy Bypass" & _
    " -File """ & $g_sPsScript & """" & _
    " -IniFile """ & $g_sIniFile & """" & _
    " -LogFile """ & $g_sLogFile & """"

Local $iExitCode = RunWait("powershell.exe " & $sPsArgs, @ScriptDir, @SW_HIDE)
If @error Then
    _Log("ERROR: Failed to launch PowerShell. AutoIt error=" & @error)
    Exit 21
EndIf
If $iExitCode <> 0 Then
    _Log("ERROR: configure-windows.ps1 exited with code: " & $iExitCode)
    Exit $iExitCode
EndIf

_Log("INFO: Windows configuration completed successfully.")
Exit 0

; --- Helpers ---

Func _ReadIniValue($sPath, $sKey)
    If Not FileExists($sPath) Then Return ""
    Local $hFile = FileOpen($sPath, 0)
    If $hFile = -1 Then Return ""
    Local $sResult = ""
    While True
        Local $sLine = FileReadLine($hFile)
        If @error Then ExitLoop
        $sLine = StringStripWS($sLine, 3)
        If StringLeft($sLine, 1) = "#" Or StringLeft($sLine, 1) = ";" Then ContinueLoop
        If StringLeft($sLine, StringLen($sKey) + 1) = $sKey & "=" Then
            $sResult = StringMid($sLine, StringLen($sKey) + 2)
            $sResult = StringReplace($sResult, ";", "")
            $sResult = StringStripWS($sResult, 3)
            ExitLoop
        EndIf
    WEnd
    FileClose($hFile)
    Return $sResult
EndFunc

Func _Log($sMsg)
    DirCreate("C:\Auto-installer")
    Local $hLog = FileOpen($g_sLogFile, 1 + 256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [WinConfig] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc