#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic Nilesoft Shell installer (MSI-based).
; $CmdLine[1] = setup filename (e.g. "shell.msi")     [optional, fallback "shell.msi"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false") [optional, ignored -- no launchable EXE]
;
; NOTE: Nilesoft Shell is a shell extension with no standalone launch executable,
; so no Desktop shortcut is created regardless of the shortcut flag.

Global Const $g_sProductCode = "{3025C475-D665-4288-99A8-3382654F7E11}"

Global $g_sSetupFilename = "shell.msi"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if app is already installed...")
If _IsNilesoftShellInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _Log("INFO: App is already installed. Exiting with code 10.")
    Exit 10
EndIf

_Log("INFO: Starting installation...")
Local $iExitCode = RunWait('"' & @SystemDir & '\msiexec.exe" /i "' & $g_sSetupPath & '" /qn /norestart', @ScriptDir, @SW_HIDE)
_Log("INFO: Installer finished with exit code: " & $iExitCode)
If @error Then
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf

If $iExitCode <> 0 Then
    _Log("ERROR: Installer returned non-zero exit code: " & $iExitCode)
    Exit $iExitCode
EndIf

If _WaitForNilesoftShell(900) Then Exit 0
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _IsNilesoftShellInstalled()
    ; Primary: check by product code
    Local $sDisplayName = RegRead("HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" & $g_sProductCode, "DisplayName")
    If Not @error And $sDisplayName = "Nilesoft Shell" Then Return True
    ; Fallback: check by display name scan (handles MSI product code changes)
    Local $sDisplayName2 = RegRead("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" & $g_sProductCode, "DisplayName")
    Return Not @error And $sDisplayName2 = "Nilesoft Shell"
EndFunc

Func _WaitForNilesoftShell($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsNilesoftShellInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc


Func _Log($sMsg)
    Local $sLogPath = "C:\Auto-installer\install-apps.log"
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
