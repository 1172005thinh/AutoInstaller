; Version: v0.2.0
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic Brave Browser installer.
; $CmdLine[1] = setup filename or path (e.g. "brave.exe", "BraveBrowserStandaloneSilentSetup.exe") [optional, fallback "brave.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")                                             [optional, fallback false]
; $CmdLine[4] = log path                                                                           [optional, fallback "C:\Auto-installer\install-apps.log"]

Global $g_sSetupFilename = "brave.exe"
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

_Log("INFO: Checking if Brave is already installed...")
If _IsBraveInstalled() Then
    _Log("INFO: Brave is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation of Brave: " & $g_sSetupPath)
; Standard silent installation flags for Brave standalone installer
Local $sSilentArgs = "/silent /install"
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

_Log("INFO: Waiting for Brave installation verification...")
If _WaitForBrave(120) Then
    _Log("INFO: Brave installation confirmed. Creating shortcut and exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf

_Log("ERROR: Installation validation timed out.")
Exit 22

Func _GetBraveDir()
    Local $aRoots[3] = ["HKLM64", "HKLM", "HKCU"]
    For $iR = 0 To UBound($aRoots) - 1
        Local $sReg = RegRead($aRoots[$iR] & "\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\brave.exe", "")
        If Not @error And $sReg <> "" Then
            If FileExists($sReg) Then Return StringLeft($sReg, StringInStr($sReg, "\", 0, -1) - 1)
        EndIf
    Next

    If FileExists(@ProgramFilesDir & "\BraveSoftware\Brave-Browser\Application\brave.exe") Then
        Return @ProgramFilesDir & "\BraveSoftware\Brave-Browser\Application"
    EndIf
    If FileExists(@ProgramFilesDir & " (x86)\BraveSoftware\Brave-Browser\Application\brave.exe") Then
        Return @ProgramFilesDir & " (x86)\BraveSoftware\Brave-Browser\Application"
    EndIf
    If FileExists(@LocalAppDataDir & "\BraveSoftware\Brave-Browser\Application\brave.exe") Then
        Return @LocalAppDataDir & "\BraveSoftware\Brave-Browser\Application"
    EndIf
    Return ""
EndFunc

Func _IsBraveInstalled()
    Return (_GetBraveDir() <> "")
EndFunc

Func _WaitForBrave($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsBraveInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sDir = _GetBraveDir()
    If $sDir = "" Then Return
    Local $sTarget = $sDir & "\brave.exe"
    If Not FileExists($sTarget) Then Return

    Local $sLink = "C:\Users\Public\Desktop\Brave.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "Brave Web Browser", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $hLog = FileOpen($g_sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [Brave] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
