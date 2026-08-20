#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; configure-windows.exe - thin admin wrapper for configure-windows.ps1
; Reads configure-windows.ini from @ScriptDir to pass section toggles and log path to the PS1.

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

; Build -Disable<Section> flags for any section set to false in the INI
Local $sSectionFlags = _BuildSectionFlags($g_sIniFile)

Local $sPsArgs = "-NonInteractive -NoProfile -ExecutionPolicy Bypass" & _
    " -File """ & $g_sPsScript & """" & _
    " -LogFile """ & $g_sLogFile & """" & _
    $sSectionFlags

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
    ; Reads a bare key=value; line from the project INI format
    If Not FileExists($sPath) Then Return ""
    Local $hFile = FileOpen($sPath, 0)
    If $hFile = -1 Then Return ""
    Local $sResult = ""
    While True
        Local $sLine = FileReadLine($hFile)
        If @error Then ExitLoop
        $sLine = StringStripWS($sLine, 3)
        If StringLeft($sLine, 1) = "#" Then ContinueLoop
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

Func _BuildSectionFlags($sPath)
    ; Parses config=[ ... ]; block and returns -Disable<Section> flags for false entries
    If Not FileExists($sPath) Then Return ""
    Local $hFile = FileOpen($sPath, 0)
    If $hFile = -1 Then Return ""
    Local $sFlags = ""
    Local $bInBlock = False
    While True
        Local $sLine = FileReadLine($hFile)
        If @error Then ExitLoop
        $sLine = StringStripWS($sLine, 3)
        If StringLeft($sLine, 1) = "#" Then ContinueLoop
        If StringInStr($sLine, "config=[") Then $bInBlock = True
        If Not $bInBlock Then ContinueLoop
        If StringInStr($sLine, "];") Then ExitLoop
        Local $aMatch = StringRegExp($sLine, '"([^"]+)"\s*,\s*(true|false)', 3)
        If Not @error And UBound($aMatch) >= 2 Then
            If StringLower($aMatch[1]) = "false" Then
                $sFlags = $sFlags & " -Disable" & $aMatch[0]
            EndIf
        EndIf
    WEnd
    FileClose($hFile)
    Return $sFlags
EndFunc

Func _Log($sMsg)
    DirCreate("C:\Auto-installer")
    Local $hLog = FileOpen($g_sLogFile, 1 + 256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [WinConfig] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc