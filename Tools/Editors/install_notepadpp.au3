#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic Notepad++ installer.
; $CmdLine[1] = setup filename (e.g. "notepadpp-8.4.4.exe")   [optional, fallback "notepadpp.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")         [optional, fallback false]

Global $g_sSetupFilename = "notepadpp.exe"
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
If _IsNotepadPlusPlusInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation...")
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

; Post-install registry check: up to 30 seconds, then trust the RunWait exit code.
_Log("INFO: Waiting for app to be fully registered...")
If _WaitForNotepadPlusPlus(30) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_CreateDesktopShortcut()
Exit 0

Func _IsNotepadPlusPlusInstalled()
    Local $sInstallPath = RegRead("HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Notepad++", "InstallLocation")
    If Not @error And FileExists($sInstallPath & "\notepad++.exe") Then Return True
    If FileExists(@ProgramFilesDir & "\Notepad++\notepad++.exe") Then Return True
    If FileExists(@ProgramFilesDir & " (x86)\Notepad++\notepad++.exe") Then Return True
    Return False
EndFunc

Func _WaitForNotepadPlusPlus($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsNotepadPlusPlusInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sTarget = RegRead("HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Notepad++", "InstallLocation")
    If Not @error And $sTarget <> "" Then $sTarget = $sTarget & "\notepad++.exe"
    If $sTarget = "" Or Not FileExists($sTarget) Then $sTarget = @ProgramFilesDir & "\Notepad++\notepad++.exe"
    If Not FileExists($sTarget) Then $sTarget = @ProgramFilesDir & " (x86)\Notepad++\notepad++.exe"
    If Not FileExists($sTarget) Then Return

    Local $iSlash = StringInStr($sTarget, "\", 0, -1)
    Local $sDir = StringLeft($sTarget, $iSlash - 1)
    Local $sLink = "C:\Users\Public\Desktop\Notepad++.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "Notepad++", $sTarget, "", 0, @SW_SHOW)
EndFunc


Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
