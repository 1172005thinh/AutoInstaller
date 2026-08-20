#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; WinRAR installer.
; $CmdLine[1] = setup filename (e.g. "winrar-723.exe")
; $CmdLine[2] = desktop shortcut flag ("true"/"false")
;
; Post-install: copies rarreg.key from @ScriptDir into the WinRAR installation
; directory to apply the bundled license.

Global $g_sSetupFilename = "winrar.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename
Global Const $g_sLicKeyPath = @ScriptDir & "\rarreg.key"

Global $g_bShortcut = False
Global $g_sLogPath = "C:\Auto-installer\install-apps.log"
If $CmdLine[0] >= 4 Then $g_sLogPath = $CmdLine[4]
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if app is already installed...")
If _IsWinRARInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CopyLicense()
    _CreateDesktopShortcut()
    Exit 10
EndIf

; WinRAR installer: /S for silent
_Log("INFO: Starting installation...")
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
If _WaitForWinRAR(60) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CopyLicense()
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _IsWinRARInstalled()
    Local $sPath = RegRead("HKLM64\SOFTWARE\WinRAR", "exe64")
    If Not @error And FileExists($sPath) Then Return True
    Local $sPath32 = RegRead("HKLM\SOFTWARE\WinRAR", "exe32")
    If Not @error And FileExists($sPath32) Then Return True
    Return FileExists(@ProgramFilesDir & "\WinRAR\WinRAR.exe")
EndFunc

Func _WaitForWinRAR($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsWinRARInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CopyLicense()
    If Not FileExists($g_sLicKeyPath) Then Return
    ; Resolve the WinRAR install directory from registry
    Local $sInstallDir = RegRead("HKLM64\SOFTWARE\WinRAR", "exe64")
    If @error Or $sInstallDir = "" Then
        $sInstallDir = RegRead("HKLM\SOFTWARE\WinRAR", "exe32")
    EndIf
    If @error Or $sInstallDir = "" Then
        $sInstallDir = @ProgramFilesDir & "\WinRAR\WinRAR.exe"
    EndIf
    ; Strip filename to get directory
    Local $iSlash = StringInStr($sInstallDir, "\", 0, -1)
    If $iSlash > 0 Then $sInstallDir = StringLeft($sInstallDir, $iSlash - 1)
    Local $sDest = $sInstallDir & "\rarreg.key"
    If Not FileExists($sDest) Then FileCopy($g_sLicKeyPath, $sDest, 0)
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sTarget = RegRead("HKLM64\SOFTWARE\WinRAR", "exe64")
    If @error Or $sTarget = "" Then $sTarget = @ProgramFilesDir & "\WinRAR\WinRAR.exe"
    If Not FileExists($sTarget) Then Return
    Local $iSlash = StringInStr($sTarget, "\", 0, -1)
    Local $sDir = StringLeft($sTarget, $iSlash - 1)
    Local $sLink = "C:\Users\Public\Desktop\WinRAR.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "WinRAR", $sTarget, "", 0, @SW_SHOW)
EndFunc


Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
