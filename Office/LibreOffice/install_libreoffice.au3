#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; LibreOffice MSI installer.
; $CmdLine[1] = setup filename (e.g. "libreoffice-26.2.5.msi")
; $CmdLine[2] = desktop shortcut flag ("true"/"false")

Global $g_sSetupFilename = "libreoffice.msi"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename

Global $g_bShortcut = False
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if app is already installed...")
If _IsLibreOfficeInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

; MSI silent install; UI_LANGS=en_US keeps the UI in English
_Log("INFO: Starting installation...")
Local $iExitCode = RunWait('"' & @SystemDir & '\msiexec.exe" /i "' & $g_sSetupPath & '" /qn /norestart CREATEDESKTOPLINK=0 UI_LANGS=en_US', @ScriptDir, @SW_HIDE)
_Log("INFO: Installer finished with exit code: " & $iExitCode)
If @error Then
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf

; msiexec returns 3010 for "success, reboot required" -- treat as success
If $iExitCode <> 0 And $iExitCode <> 3010 Then Exit $iExitCode

_Log("INFO: Waiting for app to be fully registered...")
If _WaitForLibreOffice(180) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _IsLibreOfficeInstalled()
    If FileExists(@ProgramFilesDir & "\LibreOffice\program\soffice.exe") Then Return True
    Local $sPath = RegRead("HKLM64\SOFTWARE\LibreOffice\UNO\InstallPath", "")
    Return Not @error And FileExists($sPath & "\soffice.exe")
EndFunc

Func _WaitForLibreOffice($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsLibreOfficeInstalled() Then Return True
        Sleep(2000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sTarget = @ProgramFilesDir & "\LibreOffice\program\soffice.exe"
    If Not FileExists($sTarget) Then Return
    Local $sLink = "C:\Users\Public\Desktop\LibreOffice.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, @ProgramFilesDir & "\LibreOffice\program", "", "LibreOffice", $sTarget, "", 0, @SW_SHOW)
EndFunc


Func _Log($sMsg)
    Local $sLogPath = "C:\Auto-installer\install-apps.log"
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
