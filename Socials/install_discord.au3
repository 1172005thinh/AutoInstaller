#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Discord installer.
; $CmdLine[1] = setup filename (e.g. "discord.exe")
; $CmdLine[2] = desktop shortcut flag ("true"/"false")
; $CmdLine[4] = log path                                [optional, fallback "C:\Auto-installer\install-apps.log"]
;
; Discord's installer is a stub that self-extracts and installs per-user.
; Detection checks user and machine profiles, registry hives, and filesystem locations.

Global $g_sSetupFilename = "discord.exe"
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

_Log("INFO: Checking if Discord is already installed...")
If _IsDiscordInstalled() Then
    _Log("INFO: Discord is already installed. Creating shortcut and exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation of Discord: " & $g_sSetupPath)
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" /S', @ScriptDir, @SW_HIDE)
_Log("INFO: Installer stub finished with exit code: " & $iExitCode)
If @error Then 
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf
_Log("INFO: Waiting for Squirrel updater (Update.exe) to finish...")
ProcessWait("Update.exe", 30)

Local $hTimer = TimerInit()
While ProcessExists("Update.exe") And TimerDiff($hTimer) < 120000
    Sleep(1000)
WEnd

_Log("INFO: Terminating any launched Discord processes...")
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
If _WaitForDiscord(120) Then
    _Log("INFO: Discord installation confirmed. Creating shortcut and exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf

_Log("ERROR: Discord installation validation failed.")
Exit 22

Func _GetDiscordDir()
    ; 1. Current user LocalAppData
    If FileExists(@LocalAppDataDir & "\Discord\Update.exe") Then Return @LocalAppDataDir & "\Discord"

    ; 2. Scan across all user profiles under C:\Users (covers OEM/FirstLogon passes)
    Local $hUsers = FileFindFirstFile("C:\Users\*")
    If $hUsers <> -1 Then
        While 1
            Local $sUser = FileFindNextFile($hUsers)
            If @error Then ExitLoop
            If $sUser <> "." And $sUser <> ".." And $sUser <> "Public" And $sUser <> "Default" Then
                Local $sCandidate = "C:\Users\" & $sUser & "\AppData\Local\Discord"
                If FileExists($sCandidate & "\Update.exe") Then
                    FileClose($hUsers)
                    Return $sCandidate
                EndIf
            EndIf
        WEnd
        FileClose($hUsers)
    EndIf

    ; 3. Program Files
    If FileExists(@ProgramFilesDir & "\Discord\Discord.exe") Then Return @ProgramFilesDir & "\Discord"
    If FileExists(@ProgramFilesDir & " (x86)\Discord\Discord.exe") Then Return @ProgramFilesDir & " (x86)\Discord"

    ; 4. Registry check
    Local $aRoots[3] = ["HKCU", "HKLM64", "HKLM"]
    For $iR = 0 To UBound($aRoots) - 1
        Local $sLoc = RegRead($aRoots[$iR] & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Discord", "InstallLocation")
        If Not @error And $sLoc <> "" Then
            If StringRight($sLoc, 1) = "\" Then $sLoc = StringTrimRight($sLoc, 1)
            If FileExists($sLoc & "\Update.exe") Or FileExists($sLoc & "\Discord.exe") Then Return $sLoc
        EndIf
    Next

    Return ""
EndFunc

Func _IsDiscordInstalled()
    Return (_GetDiscordDir() <> "")
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
    Local $sUserDesktop   = @UserProfileDir & "\Desktop\Discord.lnk"
    Local $sPublicDesktop = "C:\Users\Public\Desktop\Discord.lnk"
    If FileExists($sUserDesktop)   Then FileDelete($sUserDesktop)
    If FileExists($sPublicDesktop) Then FileDelete($sPublicDesktop)

    If Not $g_bShortcut Then Return
    Local $sDiscordDir = _GetDiscordDir()
    If $sDiscordDir = "" Then Return

    Local $sTarget = $sDiscordDir & "\Update.exe"
    Local $sArgs = "--processStart Discord.exe"
    Local $sIcon = $sDiscordDir & "\app.ico"
    If Not FileExists($sTarget) Then
        $sTarget = $sDiscordDir & "\Discord.exe"
        $sArgs = ""
        $sIcon = $sTarget
    EndIf
    If Not FileExists($sTarget) Then Return

    _Log("INFO: Creating Discord shortcut on Public Desktop.")
    FileCreateShortcut($sTarget, $sPublicDesktop, $sDiscordDir, $sArgs, "Discord", $sIcon, "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [Discord] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
