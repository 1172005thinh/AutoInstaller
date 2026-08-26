#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic 7-Zip installer.
; $CmdLine[1] = setup filename (e.g. "7z2602-x64.exe", "7z.exe") [optional, fallback "7z.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")            [optional, fallback false]
; $CmdLine[4] = log path                                          [optional, fallback "C:\Auto-installer\install-apps.log"]

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

_Log("INFO: Checking if 7-Zip is already installed...")
If _Is7ZipInstalled() Then
    _Log("INFO: 7-Zip is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation of 7-Zip: " & $g_sSetupPath)
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

_Log("INFO: Waiting for 7-Zip to be fully registered...")
If _WaitFor7Zip(120) Then
    _Log("INFO: 7-Zip installation confirmed. Creating shortcut and exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _Get7ZipDir()
    Local $aRoots[3] = ["HKLM64", "HKLM", "HKCU"]
    For $iR = 0 To UBound($aRoots) - 1
        Local $sPath = RegRead($aRoots[$iR] & "\SOFTWARE\7-Zip", "Path")
        If Not @error And $sPath <> "" Then
            If StringRight($sPath, 1) = "\" Then $sPath = StringTrimRight($sPath, 1)
            If FileExists($sPath & "\7z.exe") Or FileExists($sPath & "\7zFM.exe") Then Return $sPath
        EndIf
    Next

    If FileExists(@ProgramFilesDir & "\7-Zip\7z.exe") Then Return @ProgramFilesDir & "\7-Zip"
    If FileExists(@ProgramFilesDir & " (x86)\7-Zip\7z.exe") Then Return @ProgramFilesDir & " (x86)\7-Zip"
    Return ""
EndFunc

Func _Is7ZipInstalled()
    Return (_Get7ZipDir() <> "")
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
    Local $sDir = _Get7ZipDir()
    If $sDir = "" Then $sDir = @ProgramFilesDir & "\7-Zip"
    Local $sTarget = $sDir & "\7zFM.exe"   ; 7-Zip File Manager (GUI)
    If Not FileExists($sTarget) Then $sTarget = $sDir & "\7z.exe"
    If Not FileExists($sTarget) Then Return

    Local $sLink = "C:\Users\Public\Desktop\7-Zip File Manager.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "7-Zip File Manager", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
