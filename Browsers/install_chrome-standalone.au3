#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic Chrome installer.
; $CmdLine[1] = setup filename (e.g. "chrome-standalone.exe")  [optional, fallback built-in]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")          [optional, fallback false]

Global $g_sSetupFilename = "chrome-standalone.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename

Global $g_bShortcut = False
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if app is already installed...")
If _IsChromeInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation...")
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" /silent /install', @ScriptDir, @SW_HIDE)
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
If _WaitForChrome(900) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _IsChromeInstalled()
    Local $sPath = RegRead("HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe", "")
    If Not @error And FileExists($sPath) Then Return True
    Return FileExists(@ProgramFilesDir & "\Google\Chrome\Application\chrome.exe")
EndFunc

Func _WaitForChrome($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsChromeInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return

    ; Chrome's /silent installer places its own shortcut on the current user's Desktop.
    ; Remove it so we don't end up with two Chrome icons on the merged Desktop view.
    Local $sUserLink = @DesktopDir & "\Google Chrome.lnk"
    If FileExists($sUserLink) Then FileDelete($sUserLink)

    Local $sTarget = RegRead("HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe", "")
    If @error Or Not FileExists($sTarget) Then
        $sTarget = @ProgramFilesDir & "\Google\Chrome\Application\chrome.exe"
    EndIf
    If Not FileExists($sTarget) Then Return

    Local $sLink = "C:\Users\Public\Desktop\Google Chrome.lnk"
    If Not FileExists($sLink) Then
        FileCreateShortcut($sTarget, $sLink, @ProgramFilesDir & "\Google\Chrome\Application", "", "Google Chrome", $sTarget, "", 0, @SW_SHOW)
    EndIf
EndFunc


Func _Log($sMsg)
    Local $sLogPath = "C:\Auto-installer\install-apps.log"
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
