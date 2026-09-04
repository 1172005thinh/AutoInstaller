; Version: v0.1.2
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Placeholder stub for Visual Studio installer.
; $CmdLine[1] = setup filename, $CmdLine[2] = shortcut flag, $CmdLine[4] = log path

Global $g_sSetupFilename = "vs.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]

Global $g_sLogPath = "C:\Auto-installer\install-apps.log"
If $CmdLine[0] >= 4 Then $g_sLogPath = $CmdLine[4]

_Log("INFO: Visual Studio installer stub - not yet implemented.")
Exit 0

Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc