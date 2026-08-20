#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic Java 8 installer.
; $CmdLine[1] = setup filename (e.g. "java-8u441.exe")   [optional, fallback "java.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")   [optional, fallback false]
;
; Detection: checks JavaSoft registry for any Java 8 (version "1.8.*").
; NOTE: If upgrading to Java 11+ the registry path changes; update _IsJavaInstalled accordingly.

Global $g_sSetupFilename = "java.exe"
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
If _IsJavaInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation...")
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" /s', @ScriptDir, @SW_HIDE)
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
If _WaitForJava(900) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _IsJavaInstalled()
    Local $sVersion = RegRead("HKLM64\SOFTWARE\JavaSoft\Java Runtime Environment", "CurrentVersion")
    If @error Or StringLeft($sVersion, 3) <> "1.8" Then Return False
    Local $sJavaHome = RegRead("HKLM64\SOFTWARE\JavaSoft\Java Runtime Environment\" & $sVersion, "JavaHome")
    Return Not @error And FileExists($sJavaHome & "\bin\java.exe")
EndFunc

Func _WaitForJava($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsJavaInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sVersion = RegRead("HKLM64\SOFTWARE\JavaSoft\Java Runtime Environment", "CurrentVersion")
    If @error Then Return
    Local $sJavaHome = RegRead("HKLM64\SOFTWARE\JavaSoft\Java Runtime Environment\" & $sVersion, "JavaHome")
    If @error Then Return
    Local $sTarget = $sJavaHome & "\bin\javaws.exe"
    If Not FileExists($sTarget) Then Return
    Local $sLink = "C:\Users\Public\Desktop\Java Web Start.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sJavaHome & "\bin", "", "Java Web Start", $sTarget, "", 0, @SW_SHOW)
EndFunc


Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
