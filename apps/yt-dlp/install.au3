; Version: v0.2.0
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>
#include <FileConstants.au3>

; Generic yt-dlp installer and portable deployer.
; $CmdLine[1] = setup filename or path (e.g. "yt-dlp.exe") [optional, fallback "yt-dlp.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")     [optional, fallback false]
; $CmdLine[4] = log path                                   [optional, fallback "C:\Auto-installer\install-apps.log"]

Global $g_sSetupFilename = "yt-dlp.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]

Global $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename
If FileExists($g_sSetupFilename) Then $g_sSetupPath = $g_sSetupFilename

Global $g_bShortcut = False
Global $g_sLogPath = "C:\Auto-installer\install-apps.log"
If $CmdLine[0] >= 4 Then $g_sLogPath = $CmdLine[4]
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if yt-dlp is already installed...")
If _IsYtDlpInstalled() Then
    _Log("INFO: yt-dlp is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Deploying yt-dlp binary from: " & $g_sSetupPath)
Local $sTargetDir = @ProgramFilesDir & "\yt-dlp"
If Not FileExists($sTargetDir) Then DirCreate($sTargetDir)

Local $bCopied = FileCopy($g_sSetupPath, $sTargetDir & "\yt-dlp.exe", $FC_OVERWRITE)
If Not $bCopied Then
    _Log("ERROR: Failed to copy binary to target: " & $sTargetDir & "\yt-dlp.exe")
    Exit 21
EndIf

; Add target directory to System PATH environment variable if not already present
Local $sCurrentPath = RegRead("HKLM64\SYSTEM\CurrentControlSet\Control\Session Manager\Environment", "Path")
If Not @error And Not StringInStr(";" & $sCurrentPath & ";", ";" & $sTargetDir & ";") Then
    RegWrite("HKLM64\SYSTEM\CurrentControlSet\Control\Session Manager\Environment", "Path", "REG_EXPAND_SZ", $sCurrentPath & ";" & $sTargetDir)
    _Log("INFO: Added " & $sTargetDir & " to System PATH.")
EndIf

_Log("INFO: Waiting for yt-dlp installation verification...")
If _WaitForYtDlp(30) Then
    _Log("INFO: yt-dlp deployment confirmed. Creating shortcut and exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf

_Log("ERROR: Deployment validation timed out.")
Exit 22

Func _GetYtDlpDir()
    If FileExists(@ProgramFilesDir & "\yt-dlp\yt-dlp.exe") Then
        Return @ProgramFilesDir & "\yt-dlp"
    EndIf
    If FileExists(@LocalAppDataDir & "\yt-dlp\yt-dlp.exe") Then
        Return @LocalAppDataDir & "\yt-dlp"
    EndIf
    Return ""
EndFunc

Func _IsYtDlpInstalled()
    Return (_GetYtDlpDir() <> "")
EndFunc

Func _WaitForYtDlp($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsYtDlpInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sDir = _GetYtDlpDir()
    If $sDir = "" Then Return
    Local $sTarget = $sDir & "\yt-dlp.exe"
    If Not FileExists($sTarget) Then Return

    Local $sLink = "C:\Users\Public\Desktop\yt-dlp.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "yt-dlp Media Downloader", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $hLog = FileOpen($g_sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [yt-dlp] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
