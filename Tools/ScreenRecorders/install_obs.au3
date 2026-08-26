#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; OBS Studio installer.
; $CmdLine[1] = setup filename (e.g. "obs.exe")
; $CmdLine[2] = desktop shortcut flag ("true"/"false")
; $CmdLine[4] = log path                                [optional, fallback "C:\Auto-installer\install-apps.log"]
;
; OBS Studio uses NSIS installer:
; /S for silent install

Global $g_sSetupFilename = "obs.exe"
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
If _IsOBSInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation of OBS Studio: " & $g_sSetupPath)
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

_Log("INFO: Waiting for app to be fully registered...")
If _WaitForOBS(120) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _GetOBSExe()
    If FileExists(@ProgramFilesDir & "\obs-studio\bin\64bit\obs64.exe") Then Return @ProgramFilesDir & "\obs-studio\bin\64bit\obs64.exe"
    If FileExists(@ProgramFilesDir & "\obs-studio\bin\32bit\obs32.exe") Then Return @ProgramFilesDir & "\obs-studio\bin\32bit\obs32.exe"

    Local $aRoots[2] = ["HKLM64", "HKLM"]
    For $iR = 0 To UBound($aRoots) - 1
        Local $sPath = RegRead($aRoots[$iR] & "\SOFTWARE\OBS Studio", "")
        If Not @error And $sPath <> "" Then
            If StringRight($sPath, 1) = "\" Then $sPath = StringTrimRight($sPath, 1)
            If FileExists($sPath & "\bin\64bit\obs64.exe") Then Return $sPath & "\bin\64bit\obs64.exe"
            If FileExists($sPath & "\bin\32bit\obs32.exe") Then Return $sPath & "\bin\32bit\obs32.exe"
        EndIf

        Local $sUninst = RegRead($aRoots[$iR] & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OBS Studio", "InstallLocation")
        If Not @error And $sUninst <> "" Then
            If StringRight($sUninst, 1) = "\" Then $sUninst = StringTrimRight($sUninst, 1)
            If FileExists($sUninst & "\bin\64bit\obs64.exe") Then Return $sUninst & "\bin\64bit\obs64.exe"
            If FileExists($sUninst & "\bin\32bit\obs32.exe") Then Return $sUninst & "\bin\32bit\obs32.exe"
        EndIf
    Next

    Return ""
EndFunc

Func _IsOBSInstalled()
    Return (_GetOBSExe() <> "")
EndFunc

Func _WaitForOBS($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsOBSInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sTarget = _GetOBSExe()
    If $sTarget = "" Or Not FileExists($sTarget) Then Return

    Local $iSlash = StringInStr($sTarget, "\", 0, -1)
    Local $sDir = StringLeft($sTarget, $iSlash - 1)
    Local $sLink = "C:\Users\Public\Desktop\OBS Studio.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "OBS Studio", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
