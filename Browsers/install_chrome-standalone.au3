#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic Chrome standalone installer (EXE and MSI support).
; $CmdLine[1] = setup filename (e.g. "chrome-standalone.exe", "GoogleChromeStandaloneEnterprise64.msi") [optional, fallback "chrome-standalone.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")                                                  [optional, fallback false]
; $CmdLine[4] = log path                                                                                [optional, fallback "C:\Auto-installer\install-apps.log"]

Global $g_sSetupFilename = "chrome-standalone.exe"
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
If _IsChromeInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation...")
Local $iExitCode = 0
Local $sExt = StringLower(StringRight($g_sSetupFilename, 4))
If $sExt = ".msi" Then
    $iExitCode = RunWait('"' & @SystemDir & '\msiexec.exe" /i "' & $g_sSetupPath & '" /qn /norestart', @ScriptDir, @SW_HIDE)
Else
    $iExitCode = RunWait('"' & $g_sSetupPath & '" /silent /install', @ScriptDir, @SW_HIDE)
EndIf

_Log("INFO: Installer finished with exit code: " & $iExitCode)
If @error Then
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf

If $sExt = ".msi" Then
    ; msiexec returns 3010 for "success, reboot required" -- treat as success
    If $iExitCode <> 0 And $iExitCode <> 3010 Then
        _Log("ERROR: Installer returned non-zero exit code: " & $iExitCode)
        Exit $iExitCode
    EndIf
Else
    If $iExitCode <> 0 Then
        _Log("ERROR: Installer returned non-zero exit code: " & $iExitCode)
        Exit $iExitCode
    EndIf
EndIf

_Log("INFO: Waiting for app to be fully registered...")
If _WaitForChrome(120) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _GetChromeExe()
    Local $aRoots[4] = ["HKLM64", "HKLM", "HKCU64", "HKCU"]
    For $iR = 0 To UBound($aRoots) - 1
        Local $sPath = RegRead($aRoots[$iR] & "\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe", "")
        If Not @error And $sPath <> "" Then
            $sPath = StringReplace($sPath, '"', '')
            If FileExists($sPath) Then Return $sPath
        EndIf
    Next

    If FileExists(@ProgramFilesDir & "\Google\Chrome\Application\chrome.exe") Then Return @ProgramFilesDir & "\Google\Chrome\Application\chrome.exe"
    If FileExists(@ProgramFilesDir & " (x86)\Google\Chrome\Application\chrome.exe") Then Return @ProgramFilesDir & " (x86)\Google\Chrome\Application\chrome.exe"
    If FileExists(@LocalAppDataDir & "\Google\Chrome\Application\chrome.exe") Then Return @LocalAppDataDir & "\Google\Chrome\Application\chrome.exe"

    ; Scan across all user profiles
    Local $hUsers = FileFindFirstFile("C:\Users\*")
    If $hUsers <> -1 Then
        While 1
            Local $sUser = FileFindNextFile($hUsers)
            If @error Then ExitLoop
            If $sUser <> "." And $sUser <> ".." And $sUser <> "Public" And $sUser <> "Default" Then
                Local $sC = "C:\Users\" & $sUser & "\AppData\Local\Google\Chrome\Application\chrome.exe"
                If FileExists($sC) Then
                    FileClose($hUsers)
                    Return $sC
                EndIf
            EndIf
        WEnd
        FileClose($hUsers)
    EndIf

    Return ""
EndFunc

Func _IsChromeInstalled()
    Return (_GetChromeExe() <> "")
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

    ; Remove per-user shortcut if present
    Local $sUserLink = @DesktopDir & "\Google Chrome.lnk"
    If FileExists($sUserLink) Then FileDelete($sUserLink)

    Local $sTarget = _GetChromeExe()
    If $sTarget = "" Or Not FileExists($sTarget) Then Return

    Local $iSlash = StringInStr($sTarget, "\", 0, -1)
    Local $sDir = StringLeft($sTarget, $iSlash - 1)
    Local $sLink = "C:\Users\Public\Desktop\Google Chrome.lnk"
    If Not FileExists($sLink) Then
        FileCreateShortcut($sTarget, $sLink, $sDir, "", "Google Chrome", $sTarget, "", 0, @SW_SHOW)
    EndIf
EndFunc

Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        Local $sTag = StringRegExpReplace($g_sSetupFilename, "\.[^.]+$", "")
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & $sTag & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
