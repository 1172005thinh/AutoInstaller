#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic VS Code installer (Inno Setup).
; $CmdLine[1] = setup filename (e.g. "vscode-1.132.0.exe")
; $CmdLine[2] = desktop shortcut flag ("true"/"false")
;
; Installed system-wide for all users. Does NOT launch after install.

Global $g_sSetupFilename = "vscode.exe"
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

_Log("INFO: Checking if VS Code is already installed...")
If _IsVSCodeInstalled() Then
    _Log("INFO: VS Code is already installed. Creating shortcut and exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation of VS Code: " & $g_sSetupPath)
; Inno Setup flags; MERGETASKS skips "Launch VS Code" post-install checkbox
Local $sInnoLog = "C:\Auto-installer\install_vscode_inno.log"
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" /VERYSILENT /NORESTART /MERGETASKS="!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath" /LOG="' & $sInnoLog & '"', @ScriptDir, @SW_HIDE)
_Log("INFO: Installer finished with exit code: " & $iExitCode)
_LogInnoFile($sInnoLog, "[VSCode]")
If @error Then 
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf
If $iExitCode <> 0 Then 
    _Log("ERROR: Installer returned non-zero exit code: " & $iExitCode)
    Exit $iExitCode
EndIf

_Log("INFO: Waiting for VS Code to be fully registered...")
If _WaitForVSCode(120) Then
    _Log("INFO: VS Code installation confirmed. Creating shortcut and exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf

_Log("ERROR: VS Code installation validation timed out.")
Exit 22

Func _IsVSCodeInstalled()
    ; System-wide install path
    If FileExists(@ProgramFilesDir & "\Microsoft VS Code\Code.exe") Then Return True
    ; User-level install path
    If FileExists(@LocalAppDataDir & "\Programs\Microsoft VS Code\Code.exe") Then Return True
    Return False
EndFunc

Func _WaitForVSCode($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsVSCodeInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sTarget = @ProgramFilesDir & "\Microsoft VS Code\Code.exe"
    If Not FileExists($sTarget) Then $sTarget = @LocalAppDataDir & "\Programs\Microsoft VS Code\Code.exe"
    If Not FileExists($sTarget) Then Return
    Local $sLink = "C:\Users\Public\Desktop\Visual Studio Code.lnk"
    If FileExists($sLink) Then Return
    Local $iSlash = StringInStr($sTarget, "\", 0, -1)
    Local $sDir = StringLeft($sTarget, $iSlash - 1)
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "Visual Studio Code", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _LogInnoFile($sInnoPath, $sTag)
    If Not FileExists($sInnoPath) Then Return
    Local $hInno = FileOpen($sInnoPath, 0)
    If $hInno = -1 Then Return
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256)
    If $hLog <> -1 Then
        While True
            Local $sLine = FileReadLine($hInno)
            If @error Then ExitLoop
            If $sLine <> "" Then
                FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sTag & " [INNO] " & $sLine)
            EndIf
        WEnd
        FileClose($hLog)
    EndIf
    FileClose($hInno)
    FileDelete($sInnoPath)
EndFunc
Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [VSCode] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc

