; Version: v0.1.2
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic qBittorrent installer.
; $CmdLine[1] = setup filename (e.g. "qbittorrent_5.0.4_x64_setup.exe", "qbittorrent.exe") [optional, fallback "qbittorrent.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")                                      [optional, fallback false]
; $CmdLine[4] = log path                                                                    [optional, fallback "C:\Auto-installer\install-apps.log"]

Global $g_sSetupFilename = "qbittorrent.exe"
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

_Log("INFO: Checking if qBittorrent is already installed...")
If _IsqBittorrentInstalled() Then 
    _Log("INFO: qBittorrent is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation of qBittorrent: " & $g_sSetupPath)
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" /S', @ScriptDir, @SW_HIDE)
_Log("INFO: Installer finished with exit code: " & $iExitCode)
If @error Then 
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf

If $iExitCode <> 0 Then 
    _Log("ERROR: Installer returned non-zero exit code: " & $iExitCode)
    Exit $iExitCode
EndIf

_Log("INFO: Waiting for qBittorrent to be fully registered...")
If _WaitForqBittorrent(60) Then 
    _Log("INFO: qBittorrent installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf

_Log("WARN: Registry check timed out; falling back to exit code 0.")
_CreateDesktopShortcut()
Exit 0

Func _GetqBittorrentExe()
    Local $aRoots[2] = ["HKLM64", "HKLM"]
    For $iR = 0 To UBound($aRoots) - 1
        Local $sInstallPath = RegRead($aRoots[$iR] & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\qBittorrent", "InstallLocation")
        If Not @error And $sInstallPath <> "" Then
            If StringRight($sInstallPath, 1) = "\" Then $sInstallPath = StringTrimRight($sInstallPath, 1)
            If FileExists($sInstallPath & "\qbittorrent.exe") Then Return $sInstallPath & "\qbittorrent.exe"
        EndIf

        Local $sAppPath = RegRead($aRoots[$iR] & "\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\qbittorrent.exe", "")
        If Not @error And $sAppPath <> "" Then
            $sAppPath = StringReplace($sAppPath, '"', '')
            If FileExists($sAppPath) Then Return $sAppPath
        EndIf
    Next

    If FileExists(@ProgramFilesDir & "\qBittorrent\qbittorrent.exe") Then Return @ProgramFilesDir & "\qBittorrent\qbittorrent.exe"
    If FileExists(@ProgramFilesDir & " (x86)\qBittorrent\qbittorrent.exe") Then Return @ProgramFilesDir & " (x86)\qBittorrent\qbittorrent.exe"
    Return ""
EndFunc

Func _IsqBittorrentInstalled()
    Return (_GetqBittorrentExe() <> "")
EndFunc

Func _WaitForqBittorrent($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsqBittorrentInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sTarget = _GetqBittorrentExe()
    If $sTarget = "" Or Not FileExists($sTarget) Then Return

    Local $iSlash = StringInStr($sTarget, "\", 0, -1)
    Local $sDir = StringLeft($sTarget, $iSlash - 1)
    Local $sLink = "C:\Users\Public\Desktop\qBittorrent.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "qBittorrent", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [qBittorrent] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
