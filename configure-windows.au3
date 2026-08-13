#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; configure-windows.exe — thin admin wrapper for configure-windows.ps1
; Launched automatically by install-apps.exe after all applications are installed.

Global $g_sPsScript = @ScriptDir & "\configure-windows.ps1"
Global $g_sLogFile  = "C:\Auto-installer\configure-windows.log"

_Log("INFO: Starting Windows post-installation configuration.")

If Not FileExists($g_sPsScript) Then
    _Log("ERROR: configure-windows.ps1 not found: " & $g_sPsScript)
    Exit 20
EndIf

Local $sPsArgs = '-NonInteractive -NoProfile -ExecutionPolicy Bypass' & _
    ' -File "' & $g_sPsScript & '"' & _
    ' -LogFile "' & $g_sLogFile & '"'

Local $iExitCode = RunWait('powershell.exe ' & $sPsArgs, @ScriptDir, @SW_HIDE)
If @error Then
    _Log("ERROR: Failed to launch PowerShell. AutoIt error=" & @error)
    Exit 21
EndIf
If $iExitCode <> 0 Then
    _Log("ERROR: configure-windows.ps1 exited with code: " & $iExitCode)
    Exit $iExitCode
EndIf

_Log("INFO: Triggering desktop sort via UI automation...")
Send("#d")
Sleep(1500)
ControlClick("[CLASS:Progman]", "", "")
Sleep(500)
Send("{APPSKEY}")
Sleep(1500)
Send("{DOWN 2}")
Sleep(1000)
Send("{RIGHT}")
Sleep(1000)
Send("{DOWN 2}")
Sleep(1000)
Send("{ENTER}")
Sleep(1000)
Send("#d") ; Restore from desktop
_Log("INFO: Desktop sort triggered.")

_Log("INFO: Windows configuration completed successfully.")
Exit 0

Func _Log($sMsg)
    DirCreate("C:\Auto-installer")
    Local $hLog = FileOpen($g_sLogFile, 1 + 256)   ; FO_APPEND + FO_UTF8_NOBOM
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [WinConfig] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
