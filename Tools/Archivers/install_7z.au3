#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic 7-Zip installer.
; $CmdLine[1] = setup filename (e.g. "7z-2602.exe")
; $CmdLine[2] = desktop shortcut flag ("true"/"false")

Global $g_sSetupFilename = "7z.exe"
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
If _Is7ZipInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

; 7-Zip NSIS installer: /S for silent
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

_Log("INFO: Waiting for app to be fully registered...")
If _WaitFor7Zip(60) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _Is7ZipInstalled()
    Local $sPath = RegRead("HKLM64\SOFTWARE\7-Zip", "Path")
    If Not @error And FileExists($sPath & "\7z.exe") Then Return True
    Local $sPath32 = RegRead("HKLM\SOFTWARE\7-Zip", "Path")
    If Not @error And FileExists($sPath32 & "\7z.exe") Then Return True
    Return FileExists(@ProgramFilesDir & "\7-Zip\7z.exe")
EndFunc

Func _WaitFor7Zip($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _Is7ZipInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sTarget = RegRead("HKLM64\SOFTWARE\7-Zip", "Path")
    If @error Or $sTarget = "" Then $sTarget = @ProgramFilesDir & "\7-Zip"
    $sTarget = $sTarget & "\7zFM.exe"   ; 7-Zip File Manager (GUI)
    If Not FileExists($sTarget) Then Return
    Local $sLink = "C:\Users\Public\Desktop\7-Zip File Manager.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, @ProgramFilesDir & "\7-Zip", "", "7-Zip File Manager", $sTarget, "", 0, @SW_SHOW)
EndFunc


Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
