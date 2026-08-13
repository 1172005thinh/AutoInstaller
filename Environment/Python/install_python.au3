#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic Python installer.
; $CmdLine[1] = setup filename (e.g. "python-3.14.2.exe")   [optional, fallback "python.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")       [optional, fallback false]
;
; The major.minor version (e.g. "3.14") is extracted from the setup filename so that
; the correct registry key and install folder are derived at runtime. When the setup
; filename changes to "python-3.14.7.exe" or "python-3.15.0.exe", only the INI needs
; updating -- this script does not need to be recompiled.

Global $g_sSetupFilename = "python.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename

Global $g_bShortcut = False
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

; Derive major.minor (e.g. "3.14") and folder suffix (e.g. "314") from the filename.
Global $g_sPyMajorMinor = "3"     ; fallback: just major
Global $g_sPyDirSuffix  = "3"     ; fallback: just major
Local $aVer = StringRegExp($g_sSetupFilename, "python-(\d+)\.(\d+)", 1)
If Not @error And UBound($aVer) = 2 Then
    $g_sPyMajorMinor = $aVer[0] & "." & $aVer[1]   ; "3.14"
    $g_sPyDirSuffix  = $aVer[0] & $aVer[1]          ; "314"
EndIf

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if app is already installed...")
If _IsPythonInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation...")
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=1', @ScriptDir, @SW_HIDE)
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
If _WaitForPython(900) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _IsPythonInstalled()
    Local $sPath = RegRead("HKLM64\SOFTWARE\Python\PythonCore\" & $g_sPyMajorMinor & "\InstallPath", "")
    If Not @error And FileExists($sPath & "\python.exe") Then Return True
    Return FileExists(@ProgramFilesDir & "\Python" & $g_sPyDirSuffix & "\python.exe")
EndFunc

Func _WaitForPython($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsPythonInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sPythonDir = RegRead("HKLM64\SOFTWARE\Python\PythonCore\" & $g_sPyMajorMinor & "\InstallPath", "")
    If @error Or $sPythonDir = "" Then $sPythonDir = @ProgramFilesDir & "\Python" & $g_sPyDirSuffix
    Local $sTarget = $sPythonDir & "\pythonw.exe"
    If Not FileExists($sTarget) Then Return
    Local $sLink = "C:\Users\Public\Desktop\IDLE (Python " & $g_sPyMajorMinor & ").lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sPythonDir, "-m idlelib", "IDLE (Python " & $g_sPyMajorMinor & ")", $sTarget, "", 0, @SW_SHOW)
EndFunc


Func _Log($sMsg)
    Local $sLogPath = "C:\Auto-installer\install-apps.log"
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
