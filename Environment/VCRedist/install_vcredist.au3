; Version: v0.1.2
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Visual C++ Redistributable AIO installer (2005-2026, x86 + x64).
; $CmdLine[1] = setup filename (e.g. "vcredist-AIO-2005-2026.exe")
; $CmdLine[2] = desktop shortcut flag (ignored - no launchable EXE)
;
; Detection: checks that both the x64 and x86 2026 runtimes are present,
; which the AIO always installs last and which cover 2015-2026 inclusive.

Global $g_sSetupFilename = "vcredist-AIO.exe"
Global $g_sLogPath = "C:\Auto-installer\install-apps.log"
If $CmdLine[0] >= 4 Then $g_sLogPath = $CmdLine[4]
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename

If Not FileExists($g_sSetupPath) Then 
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if VCRedist is already installed...")
If _IsVCRedistInstalled() Then 
    _Log("INFO: VCRedist is already installed. Exiting with code 10.")
    Exit 10
EndIf

_Log("INFO: Starting installation of VCRedist AIO: " & $g_sSetupPath)
; The AIO installer supports /y for silent install
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" /y', @ScriptDir, @SW_HIDE)
_Log("INFO: Installer finished with exit code: " & $iExitCode)
If @error Then 
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf
; Some AIO builds exit with 3010 (success, reboot needed) -- treat as success
If $iExitCode <> 0 And $iExitCode <> 3010 Then 
    _Log("ERROR: Installer returned non-zero exit code: " & $iExitCode)
    Exit $iExitCode
EndIf

_Log("INFO: Waiting for VCRedist to be fully registered...")
If _WaitForVCRedist(120) Then 
    _Log("INFO: VCRedist installation confirmed. Exiting with code 0.")
    Exit 0
EndIf

_Log("ERROR: VCRedist installation validation timed out.")
Exit 22

Func _IsVCRedistInstalled()
    ; Check for vcruntime140.dll which covers 2015-2026 Redistributables
    Local $bX64 = FileExists(@SystemDir & "\vcruntime140.dll")
    Local $bX86 = FileExists(@WindowsDir & "\SysWOW64\vcruntime140.dll")
    
    If $bX64 And $bX86 Then Return True
    Return False
EndFunc

Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [VCRedist] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc

Func _WaitForVCRedist($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsVCRedistInstalled() Then Return True
        Sleep(2000)
    WEnd
    Return False
EndFunc
