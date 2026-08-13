#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Discord installer.
; $CmdLine[1] = setup filename (e.g. "discord.exe")
; $CmdLine[2] = desktop shortcut flag ("true"/"false")
;
; Discord's installer is a stub that self-extracts and installs per-user to
; %LocalAppData%\Discord. It does not support true silent installation but
; accepts /S (NSIS-style) to suppress most UI.

Global $g_sSetupFilename = "discord.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename

Global $g_bShortcut = False
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

If Not FileExists($g_sSetupPath) Then 
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if Discord is already installed...")
If _IsDiscordInstalled() Then
    _Log("INFO: Discord is already installed. Creating shortcut and exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation of Discord: " & $g_sSetupPath)
; Discord installs to %LOCALAPPDATA%; run as the current user (no /RunAs)
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" /S', @ScriptDir, @SW_HIDE)
_Log("INFO: Installer stub finished with exit code: " & $iExitCode)
If @error Then 
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf
_Log("INFO: Waiting for Squirrel updater (Update.exe) to finish...")
; Squirrel takes a moment to spawn. Ensure we wait for it to start.
ProcessWait("Update.exe", 30)

; Now wait for it to exit completely so it finishes dropping its shortcuts.
Local $hTimer = TimerInit()
While ProcessExists("Update.exe") And TimerDiff($hTimer) < 120000
    Sleep(1000)
WEnd

_Log("INFO: Terminating any launched Discord processes...")
; Kill Discord, DiscordSystemHelper, and any leftover Update.exe
Local $aProcs = ["Discord.exe", "DiscordSystemHelper.exe", "Update.exe"]
For $i = 1 To 10
    Local $bAnyAlive = False
    For $sProc In $aProcs
        If ProcessExists($sProc) Then
            ProcessClose($sProc)
            $bAnyAlive = True
            _Log("INFO: Terminated " & $sProc)
        EndIf
    Next
    If Not $bAnyAlive Then ExitLoop
    Sleep(500)
Next

_Log("INFO: Validating installation...")
If _IsDiscordInstalled() Then
    _Log("INFO: Discord installation confirmed. Creating shortcut and exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf

_Log("ERROR: Discord installation validation failed.")
Exit 22

Func _IsDiscordInstalled()
    ; Discord uses Squirrel; the main executable is usually Update.exe in the root
    Return FileExists(@LocalAppDataDir & "\Discord\Update.exe")
EndFunc

Func _WaitForDiscord($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsDiscordInstalled() Then Return True
        Sleep(2000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    ; Remove shortcuts Discord's own installer may have placed
    Local $sUserDesktop   = @UserProfileDir & "\Desktop\Discord.lnk"
    Local $sPublicDesktop = "C:\Users\Public\Desktop\Discord.lnk"
    If FileExists($sUserDesktop)   Then FileDelete($sUserDesktop)
    If FileExists($sPublicDesktop) Then FileDelete($sPublicDesktop)

    If Not $g_bShortcut Then Return
    Local $sTarget = @LocalAppDataDir & "\Discord\Update.exe"
    If Not FileExists($sTarget) Then Return
    _Log("INFO: Creating Discord shortcut on Public Desktop.")
    FileCreateShortcut($sTarget, $sPublicDesktop, @LocalAppDataDir & "\Discord", "--processStart Discord.exe", "Discord", @LocalAppDataDir & "\Discord\app.ico", "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $sLogPath = "C:\Auto-installer\install-apps.log"
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [Discord] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
