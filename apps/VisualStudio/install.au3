; Version: v0.2.0
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic Visual Studio installer.
; $CmdLine[1] = setup filename or path (e.g. "vs_community.exe", "vs.exe") [optional, fallback "vs_community.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")                     [optional, fallback false]
; $CmdLine[4] = log path                                                   [optional, fallback "C:\Auto-installer\install-apps.log"]

Global $g_sSetupFilename = "vs_community.exe"
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

_Log("INFO: Checking if Visual Studio is already installed...")
If _IsVisualStudioInstalled() Then
    _Log("INFO: Visual Studio is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation of Visual Studio: " & $g_sSetupPath)
; Standard silent unattended flags for Visual Studio Bootstrapper
Local $sSilentArgs = "--quiet --wait --norestart --nocache --add Microsoft.VisualStudio.Workload.ManagedDesktop --includeRecommended"
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" ' & $sSilentArgs, @ScriptDir, @SW_HIDE)
_Log("INFO: Installer finished with exit code: " & $iExitCode)
If @error Then
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf

; Visual Studio bootstrapper exit codes: 0 = Success, 3010 = Restart required (treated as success)
If $iExitCode <> 0 And $iExitCode <> 3010 Then
    _Log("ERROR: Installer returned non-zero exit code: " & $iExitCode)
    Exit $iExitCode
EndIf

_Log("INFO: Waiting for Visual Studio installation verification...")
If _WaitForVisualStudio(300) Then
    _Log("INFO: Visual Studio installation confirmed. Creating shortcut and exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf

_Log("ERROR: Installation validation timed out.")
Exit 22

Func _GetVisualStudioDir()
    Local $sInstallerDir = @ProgramFilesDir & " (x86)\Microsoft Visual Studio\Installer"
    If FileExists($sInstallerDir & "\vswhere.exe") Then
        Return $sInstallerDir
    EndIf

    Local $sReg = RegRead("HKLM64\SOFTWARE\Microsoft\VisualStudio\Setup", "SharedInstallationPath")
    If Not @error And $sReg <> "" And FileExists($sReg) Then
        Return $sReg
    EndIf
    Return ""
EndFunc

Func _IsVisualStudioInstalled()
    Return (_GetVisualStudioDir() <> "")
EndFunc

Func _WaitForVisualStudio($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsVisualStudioInstalled() Then Return True
        Sleep(2000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    ; Visual Studio typically places its own Start Menu and Desktop shortcuts upon workload installation
    Local $sVsWhere = @ProgramFilesDir & " (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
    If Not FileExists($sVsWhere) Then Return

    ; Query installed product path if possible
    Local $sDevenv = @ProgramFilesDir & "\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe"
    If Not FileExists($sDevenv) Then
        $sDevenv = @ProgramFilesDir & "\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe"
    EndIf
    If Not FileExists($sDevenv) Then
        $sDevenv = @ProgramFilesDir & "\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\devenv.exe"
    EndIf

    If FileExists($sDevenv) Then
        Local $sLink = "C:\Users\Public\Desktop\Visual Studio 2022.lnk"
        If Not FileExists($sLink) Then
            FileCreateShortcut($sDevenv, $sLink, StringLeft($sDevenv, StringInStr($sDevenv, "\", 0, -1) - 1), "", "Visual Studio 2022", $sDevenv, "", 0, @SW_SHOW)
        EndIf
    EndIf
EndFunc

Func _Log($sMsg)
    Local $hLog = FileOpen($g_sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [VisualStudio] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
