; Version: v0.2.0
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic Tailscale installer.
; $CmdLine[1] = setup filename or path (e.g. "tailscale.exe", "tailscale-setup.exe") [optional, fallback "tailscale.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")                               [optional, fallback false]
; $CmdLine[4] = log path                                                             [optional, fallback "C:\Auto-installer\install-apps.log"]

Global $g_sSetupFilename = "tailscale.exe"
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

_Log("INFO: Checking if Tailscale is already installed...")
If _IsTailscaleInstalled() Then
    _Log("INFO: Tailscale is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation of Tailscale: " & $g_sSetupPath)
; Standard silent installation flags for Tailscale setup executable
Local $sSilentArgs = "/quiet /install"
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" ' & $sSilentArgs, @ScriptDir, @SW_HIDE)
_Log("INFO: Installer finished with exit code: " & $iExitCode)
If @error Then
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf

If $iExitCode <> 0 Then
    _Log("ERROR: Installer returned non-zero exit code: " & $iExitCode)
    Exit $iExitCode
EndIf

_Log("INFO: Waiting for Tailscale installation verification...")
If _WaitForTailscale(120) Then
    _Log("INFO: Tailscale installation confirmed. Creating shortcut and exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf

_Log("ERROR: Installation validation timed out.")
Exit 22

Func _GetTailscaleDir()
    If FileExists(@ProgramFilesDir & "\Tailscale\tailscale.exe") Then
        Return @ProgramFilesDir & "\Tailscale"
    EndIf
    If FileExists(@ProgramFilesDir & "\Tailscale\tailscale-ipn.exe") Then
        Return @ProgramFilesDir & "\Tailscale"
    EndIf
    If FileExists(@ProgramFilesDir & " (x86)\Tailscale\tailscale.exe") Then
        Return @ProgramFilesDir & " (x86)\Tailscale"
    EndIf

    Local $sInstallLoc = RegRead("HKLM64\SOFTWARE\Tailscale IPN", "InstallDir")
    If Not @error And $sInstallLoc <> "" And FileExists($sInstallLoc) Then
        Return $sInstallLoc
    EndIf
    Return ""
EndFunc

Func _IsTailscaleInstalled()
    Return (_GetTailscaleDir() <> "")
EndFunc

Func _WaitForTailscale($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsTailscaleInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sDir = _GetTailscaleDir()
    If $sDir = "" Then Return
    Local $sTarget = $sDir & "\tailscale-ipn.exe"
    If Not FileExists($sTarget) Then $sTarget = $sDir & "\tailscale.exe"
    If Not FileExists($sTarget) Then Return

    Local $sLink = "C:\Users\Public\Desktop\Tailscale.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "Tailscale", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $hLog = FileOpen($g_sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [Tailscale] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
