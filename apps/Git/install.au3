;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     apps/Git/install.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Includes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include <AutoItConstants.au3>
#include <FileConstants.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration & Parameters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Includes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include <AutoItConstants.au3>
#include <FileConstants.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration & Parameters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Generic Git for Windows installer.
; $CmdLine[1] = setup filename or path (e.g. "git.exe", "Git-64-bit.exe") [optional, fallback "git.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")                   [optional, fallback false]
; $CmdLine[4] = log path                                                 [optional, fallback "C:\AutoInstaller\apps.log"]

Global $g_sSetupFilename = "git.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]

Global $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename
If FileExists($g_sSetupFilename) Then $g_sSetupPath = $g_sSetupFilename

Global $g_bShortcut = False
Global $g_sLogPath = "C:\AutoInstaller\apps.log"
If $CmdLine[0] >= 4 Then $g_sLogPath = $CmdLine[4]
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main Installation Execution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main Installation Execution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if Git is already installed...")
If _IsGitInstalled() Then
    _Log("INFO: Git is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation of Git: " & $g_sSetupPath)
; Inno Setup silent flags for Git for Windows
Local $sSilentArgs = "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS"
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

_Log("INFO: Waiting for Git installation verification...")
If _WaitForGit(120) Then
    _Log("INFO: Git installation confirmed. Creating shortcut and exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf

_Log("ERROR: Installation validation timed out.")
Exit 22

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Helper Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Helper Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _GetGitDir()
    Local $aRoots[3] = ["HKLM64", "HKLM", "HKCU"]
    For $iR = 0 To UBound($aRoots) - 1
        Local $sInstallPath = RegRead($aRoots[$iR] & "\SOFTWARE\GitForWindows", "InstallPath")
        If Not @error And $sInstallPath <> "" And FileExists($sInstallPath & "\cmd\git.exe") Then
            Return $sInstallPath
        EndIf
    Next

    If FileExists(@ProgramFilesDir & "\Git\cmd\git.exe") Then Return @ProgramFilesDir & "\Git"
    If FileExists(@ProgramFilesDir & " (x86)\Git\cmd\git.exe") Then Return @ProgramFilesDir & " (x86)\Git"
    Return ""
EndFunc

Func _IsGitInstalled()
    Return (_GetGitDir() <> "")
EndFunc

Func _WaitForGit($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsGitInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sDir = _GetGitDir()
    If $sDir = "" Then Return
    Local $sTarget = $sDir & "\git-bash.exe"
    If Not FileExists($sTarget) Then Return

    Local $sLink = "C:\Users\Public\Desktop\Git Bash.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "Git Bash", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $sDir = StringLeft($g_sLogPath, StringInStr($g_sLogPath, "\", 0, -1) - 1)
    If $sDir <> "" And Not FileExists($sDir) Then DirCreate($sDir)
    Local $hLog = FileOpen($g_sLogPath, BitOR($FO_APPEND, $FO_UTF8_NOBOM, $FO_CREATEPATH))
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [Git] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
