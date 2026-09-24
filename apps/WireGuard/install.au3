; Version: v0.2.0
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic WireGuard installer.
; $CmdLine[1] = setup filename or path (e.g. "wireguard.exe", "wireguard-installer.exe") [optional, fallback "wireguard.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")                                   [optional, fallback false]
; $CmdLine[4] = log path                                                                 [optional, fallback "C:\Auto-installer\install-apps.log"]

Global $g_sSetupFilename = "wireguard.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]

Global $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename
If FileExists($g_sSetupFilename) Then $g_sSetupPath = $g_sSetupFilename

Global $g_bShortcut = False
Global $g_sLogPath = "C:\Auto-installer\install-apps.log"
If $CmdLine[0] >= 4 Then $g_sLogPath = $CmdLine[4]
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if WireGuard is already installed...")
If _IsWireGuardInstalled() Then
    _Log("INFO: WireGuard is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation of WireGuard: " & $g_sSetupPath)
; Standard silent installation flags for WireGuard (supports installer wrapper and MSI)
Local $sSilentArgs = "/install /quiet"
If StringRegExp($g_sSetupPath, "(?i)\.msi$") Then
    $sSilentArgs = "/qn /norestart"
EndIf

Local $iExitCode = 0
If StringRegExp($g_sSetupPath, "(?i)\.msi$") Then
    $iExitCode = RunWait('"' & @SystemDir & '\msiexec.exe" /i "' & $g_sSetupPath & '" ' & $sSilentArgs, @ScriptDir, @SW_HIDE)
Else
    $iExitCode = RunWait('"' & $g_sSetupPath & '" ' & $sSilentArgs, @ScriptDir, @SW_HIDE)
EndIf

_Log("INFO: Installer finished with exit code: " & $iExitCode)
If @error Then
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf

If $iExitCode <> 0 Then
    _Log("ERROR: Installer returned non-zero exit code: " & $iExitCode)
    Exit $iExitCode
EndIf

_Log("INFO: Waiting for WireGuard installation verification...")
If _WaitForWireGuard(120) Then
    _Log("INFO: WireGuard installation confirmed. Creating shortcut and exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf

_Log("ERROR: Installation validation timed out.")
Exit 22

Func _GetWireGuardDir()
    If FileExists(@ProgramFilesDir & "\WireGuard\wireguard.exe") Then
        Return @ProgramFilesDir & "\WireGuard"
    EndIf

    Local $sInstallLoc = RegRead("HKLM64\SOFTWARE\WireGuard", "InstallDir")
    If Not @error And $sInstallLoc <> "" And FileExists($sInstallLoc & "\wireguard.exe") Then
        Return $sInstallLoc
    EndIf
    Return ""
EndFunc

Func _IsWireGuardInstalled()
    Return (_GetWireGuardDir() <> "")
EndFunc

Func _WaitForWireGuard($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsWireGuardInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sDir = _GetWireGuardDir()
    If $sDir = "" Then Return
    Local $sTarget = $sDir & "\wireguard.exe"
    If Not FileExists($sTarget) Then Return

    Local $sLink = "C:\Users\Public\Desktop\WireGuard.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "WireGuard", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $hLog = FileOpen($g_sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [WireGuard] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
