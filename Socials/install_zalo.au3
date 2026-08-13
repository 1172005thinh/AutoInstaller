#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Zalo installer.
; $CmdLine[1] = setup filename (e.g. "zalo-26.8.10.exe")
; $CmdLine[2] = desktop shortcut flag ("true"/"false")
;
; Zalo uses NSIS; it installs per-user to %LocalAppData%\Zalo.

Global $g_sSetupFilename = "zalo.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename

Global $g_bShortcut = False
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if app is already installed...")
If _IsZaloInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

; Register a function to automatically click "Yes" if the Zalo uninstaller/reinstaller prompt appears
AdlibRegister("_HandleZaloPopup", 500)

_Log("INFO: Starting installation...")
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" /S', @ScriptDir, @SW_HIDE)
_Log("INFO: Installer finished with exit code: " & $iExitCode)
If @error Then
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf

Sleep(3000)   ; NSIS stubs may return before the inner installer finishes

AdlibUnRegister("_HandleZaloPopup")

_Log("INFO: Waiting for app to be fully registered...")
If _WaitForZalo(120) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _IsZaloInstalled()
    If FileExists(@LocalAppDataDir & "\Zalo\Zalo.exe") Then Return True
    If FileExists(@LocalAppDataDir & "\Programs\Zalo\Zalo.exe") Then Return True
    Local $sPath = RegRead("HKCU\SOFTWARE\Zalo\Update", "LastVersion")
    Return Not @error And (FileExists(@LocalAppDataDir & "\Zalo\Zalo.exe") Or FileExists(@LocalAppDataDir & "\Programs\Zalo\Zalo.exe"))
EndFunc

Func _WaitForZalo($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsZaloInstalled() Then Return True
        Sleep(2000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    ; Remove shortcuts Zalo's own installer may have placed
    Local $sUserDesktop   = @UserProfileDir & "\Desktop\Zalo.lnk"
    Local $sPublicDesktop = "C:\Users\Public\Desktop\Zalo.lnk"
    If FileExists($sUserDesktop)   Then FileDelete($sUserDesktop)
    If FileExists($sPublicDesktop) Then FileDelete($sPublicDesktop)

    If Not $g_bShortcut Then Return
    Local $sTarget = @LocalAppDataDir & "\Zalo\Zalo.exe"
    If Not FileExists($sTarget) Then $sTarget = @LocalAppDataDir & "\Programs\Zalo\Zalo.exe"
    If Not FileExists($sTarget) Then Return

    Local $iSlash = StringInStr($sTarget, "\", 0, -1)
    Local $sDir = StringLeft($sTarget, $iSlash - 1)

    _Log("INFO: Creating Zalo shortcut on Public Desktop.")
    FileCreateShortcut($sTarget, $sPublicDesktop, $sDir, "", "Zalo", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _HandleZaloPopup()
    ; Detect any window with title "Zalo" that might be a prompt
    ; Specifically look for the prompt asking to delete data (which usually has Yes/No options)
    If WinExists("Zalo", "") Then
        ; Try to click the Yes button if it is a confirmation dialog
        ControlClick("Zalo", "", "&Yes")
        ; In Vietnamese it might be "CÃ³"
        ControlClick("Zalo", "", "CÃ³")
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
