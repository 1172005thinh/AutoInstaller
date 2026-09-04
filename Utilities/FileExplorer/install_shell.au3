; Version: v0.1.2
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic Nilesoft Shell installer (MSI-based).
; $CmdLine[1] = setup filename (e.g. "shell.msi")     [optional, fallback "shell.msi"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false") [optional, ignored -- no launchable EXE]
; $CmdLine[4] = log path                               [optional, fallback "C:\Auto-installer\install-apps.log"]
;
; NOTE: Nilesoft Shell is a shell extension with no standalone launch executable,
; so no Desktop shortcut is created regardless of the shortcut flag.

Global $g_sSetupFilename = "shell.msi"
Global $g_sLogPath = "C:\Auto-installer\install-apps.log"
If $CmdLine[0] >= 4 Then $g_sLogPath = $CmdLine[4]
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if app is already installed...")
If _IsNilesoftShellInstalled() Then
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

; msiexec returns 3010 for "success, reboot required" -- treat as success
If $iExitCode <> 0 And $iExitCode <> 3010 Then
    _Log("ERROR: Installer returned non-zero exit code: " & $iExitCode)
    Exit $iExitCode
EndIf

If _WaitForNilesoftShell(120) Then
    _Log("INFO: Nilesoft Shell installation confirmed. Exiting with code 0.")
    Exit 0
EndIf

_Log("ERROR: Installation validation timed out.")
Exit 22

Func _IsNilesoftShellInstalled()
    ; 1. Direct binary / extension check
    If FileExists(@ProgramFilesDir & "\Nilesoft Shell\shell.dll") Then Return True
    If FileExists(@ProgramFilesDir & "\Nilesoft Shell\shell.exe") Then Return True
    If FileExists(@ProgramFilesDir & " (x86)\Nilesoft Shell\shell.dll") Then Return True

    ; 2. Nilesoft product registry key
    Local $sInst = RegRead("HKLM64\SOFTWARE\Nilesoft\Shell", "Path")
    If Not @error And $sInst <> "" Then
        If StringRight($sInst, 1) = "\" Then $sInst = StringTrimRight($sInst, 1)
        If FileExists($sInst & "\shell.dll") Or FileExists($sInst & "\shell.exe") Then Return True
    EndIf

    ; 3. Scan Uninstall registry keys across 64-bit and 32-bit hives
    Local $aRoots[2] = ["HKLM64", "HKLM"]
    For $iR = 0 To UBound($aRoots) - 1
        Local $sUninst = $aRoots[$iR] & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
        Local $iKey = 1
        While 1
            Local $sSubKey = RegEnumKey($sUninst, $iKey)
            If @error Then ExitLoop
            Local $sDisplay = RegRead($sUninst & "\" & $sSubKey, "DisplayName")
            If Not @error And StringInStr($sDisplay, "Nilesoft Shell") > 0 Then Return True
            $iKey += 1
        WEnd
    Next

    Return False
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
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".msi", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
