; Version: v0.1.2
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; TeamViewer installer.
; $CmdLine[1] = setup filename (e.g. "teamviewer.exe")
; $CmdLine[2] = desktop shortcut flag ("true"/"false")
; $CmdLine[4] = log path                                [optional, fallback "C:\Auto-installer\install-apps.log"]
;
; TeamViewer uses custom command-line parameters:
; /S for silent install

Global $g_sSetupFilename = "teamviewer.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename

Global $g_bShortcut = False
Global $g_sLogPath = "C:\Auto-installer\install-apps.log"
If $CmdLine[0] >= 4 Then $g_sLogPath = $CmdLine[4]
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

If Not FileExists($g_sSetupPath) Then 
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if app is already installed...")
If _IsTeamViewerInstalled() Then 
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation of TeamViewer: " & $g_sSetupPath)
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" /S', @ScriptDir, @SW_HIDE)
_Log("INFO: Installer finished with exit code: " & $iExitCode)
If @error Then 
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf

If $iExitCode <> 0 Then 
    _Log("ERROR: Installer returned non-zero exit code: " & $iExitCode)
    Exit $iExitCode
EndIf

_Log("INFO: Waiting for app to be fully registered...")
If _WaitForTeamViewer(120) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _GetTeamViewerExe()
    Local $aRoots[3] = ["HKLM64", "HKLM", "HKCU"]
    For $iR = 0 To UBound($aRoots) - 1
        Local $sPath = RegRead($aRoots[$iR] & "\SOFTWARE\TeamViewer", "InstallationDirectory")
        If Not @error And $sPath <> "" Then
            If StringRight($sPath, 1) = "\" Then $sPath = StringTrimRight($sPath, 1)
            If FileExists($sPath & "\TeamViewer.exe") Then Return $sPath & "\TeamViewer.exe"
        EndIf
    Next

    If FileExists(@ProgramFilesDir & "\TeamViewer\TeamViewer.exe") Then Return @ProgramFilesDir & "\TeamViewer\TeamViewer.exe"
    If FileExists(@ProgramFilesDir & " (x86)\TeamViewer\TeamViewer.exe") Then Return @ProgramFilesDir & " (x86)\TeamViewer\TeamViewer.exe"
    Return ""
EndFunc

Func _IsTeamViewerInstalled()
    Return (_GetTeamViewerExe() <> "")
EndFunc

Func _WaitForTeamViewer($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsTeamViewerInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sTarget = _GetTeamViewerExe()
    If $sTarget = "" Or Not FileExists($sTarget) Then Return

    Local $iSlash = StringInStr($sTarget, "\", 0, -1)
    Local $sDir = StringLeft($sTarget, $iSlash - 1)
    Local $sLink = "C:\Users\Public\Desktop\TeamViewer.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "TeamViewer", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
