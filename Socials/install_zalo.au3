; Version: v0.1.2
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Zalo installer.
; $CmdLine[1] = setup filename (e.g. "zalo.exe")
; $CmdLine[2] = desktop shortcut flag ("true"/"false")
; $CmdLine[4] = log path                                [optional, fallback "C:\Auto-installer\install-apps.log"]
;
; Zalo uses NSIS; it installs per-user to %LocalAppData%\Zalo or Programs\Zalo.
; Detection checks user and machine profiles, registry hives, and filesystem locations.

Global $g_sSetupFilename = "zalo.exe"
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

Func _GetZaloExecutable()
    ; 1. Current user LocalAppData
    If FileExists(@LocalAppDataDir & "\Zalo\Zalo.exe") Then Return @LocalAppDataDir & "\Zalo\Zalo.exe"
    If FileExists(@LocalAppDataDir & "\Programs\Zalo\Zalo.exe") Then Return @LocalAppDataDir & "\Programs\Zalo\Zalo.exe"

    ; 2. Scan across all user profiles under C:\Users (covers OEM/FirstLogon passes)
    Local $hUsers = FileFindFirstFile("C:\Users\*")
    If $hUsers <> -1 Then
        While 1
            Local $sUser = FileFindNextFile($hUsers)
            If @error Then ExitLoop
            If $sUser <> "." And $sUser <> ".." And $sUser <> "Public" And $sUser <> "Default" Then
                Local $sC1 = "C:\Users\" & $sUser & "\AppData\Local\Zalo\Zalo.exe"
                If FileExists($sC1) Then
                    FileClose($hUsers)
                    Return $sC1
                EndIf
                Local $sC2 = "C:\Users\" & $sUser & "\AppData\Local\Programs\Zalo\Zalo.exe"
                If FileExists($sC2) Then
                    FileClose($hUsers)
                    Return $sC2
                EndIf
            EndIf
        WEnd
        FileClose($hUsers)
    EndIf

    ; 3. Program Files
    If FileExists(@ProgramFilesDir & "\Zalo\Zalo.exe") Then Return @ProgramFilesDir & "\Zalo\Zalo.exe"
    If FileExists(@ProgramFilesDir & " (x86)\Zalo\Zalo.exe") Then Return @ProgramFilesDir & " (x86)\Zalo\Zalo.exe"

    ; 4. Registry check
    Local $aRoots[3] = ["HKCU", "HKLM64", "HKLM"]
    For $iR = 0 To UBound($aRoots) - 1
        Local $sLoc = RegRead($aRoots[$iR] & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Zalo", "InstallLocation")
        If Not @error And $sLoc <> "" Then
            If StringRight($sLoc, 1) = "\" Then $sLoc = StringTrimRight($sLoc, 1)
            If FileExists($sLoc & "\Zalo.exe") Then Return $sLoc & "\Zalo.exe"
        EndIf
    Next

    Return ""
EndFunc

Func _IsZaloInstalled()
    Return (_GetZaloExecutable() <> "")
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
    Local $sUserDesktop   = @UserProfileDir & "\Desktop\Zalo.lnk"
    Local $sPublicDesktop = "C:\Users\Public\Desktop\Zalo.lnk"
    If FileExists($sUserDesktop)   Then FileDelete($sUserDesktop)
    If FileExists($sPublicDesktop) Then FileDelete($sPublicDesktop)

    If Not $g_bShortcut Then Return
    Local $sTarget = _GetZaloExecutable()
    If $sTarget = "" Or Not FileExists($sTarget) Then Return

    Local $iSlash = StringInStr($sTarget, "\", 0, -1)
    Local $sDir = StringLeft($sTarget, $iSlash - 1)

    _Log("INFO: Creating Zalo shortcut on Public Desktop.")
    FileCreateShortcut($sTarget, $sPublicDesktop, $sDir, "", "Zalo", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _HandleZaloPopup()
    If WinExists("Zalo", "") Then
        ControlClick("Zalo", "", "&Yes")
        ControlClick("Zalo", "", "Có")
    EndIf
EndFunc

Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
