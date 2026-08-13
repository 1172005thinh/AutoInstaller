#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Kaspersky antivirus installer.
; $CmdLine[1] = setup filename (e.g. "kaspersky.exe")
; $CmdLine[2] = desktop shortcut flag ("true"/"false")
;
; Kaspersky supports EULA=1 PRIVACYPOLICY=1 /s /pSKIPPRODUCTCHECK=1
; for silent installation without UI.

Global $g_sSetupFilename = "kaspersky.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename

Global $g_bShortcut = False
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if app is already installed...")
If _IsKasperskyInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

; Kaspersky silent install flags
_Log("INFO: Starting installation...")
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" EULA=1 PRIVACYPOLICY=1 /s /pSKIPPRODUCTCHECK=1', @ScriptDir, @SW_HIDE)
_Log("INFO: Installer finished with exit code: " & $iExitCode)
If @error Then
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf

; Kaspersky may return 0 quickly while background install continues
Sleep(10000)

_Log("INFO: Waiting for app to be fully registered...")
If _WaitForKaspersky(300) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _IsKasperskyInstalled()
    ; Check for Kaspersky service or executable
    Local $sPath = RegRead("HKLM64\SOFTWARE\KasperskyLab\avp22\Environment", "ProductInstallDir")
    If Not @error And FileExists($sPath & "\avpui.exe") Then Return True
    ; Broader fallback: any Kaspersky uninstall entry
    Local $sDisplay = RegRead("HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{8ECDE29A-8617-4E32-AAA0-4DA7D4C5006E}", "DisplayName")
    Return Not @error And StringInStr($sDisplay, "Kaspersky") > 0
EndFunc

Func _WaitForKaspersky($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsKasperskyInstalled() Then Return True
        Sleep(5000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sTarget = ""
    Local $sPath = RegRead("HKLM64\SOFTWARE\KasperskyLab\avp22\Environment", "ProductInstallDir")
    If Not @error And $sPath <> "" Then $sTarget = $sPath & "\avpui.exe"
    If Not FileExists($sTarget) Then Return
    Local $iSlash = StringInStr($sTarget, "\", 0, -1)
    Local $sDir = StringLeft($sTarget, $iSlash - 1)
    Local $sLink = "C:\Users\Public\Desktop\Kaspersky.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "Kaspersky", $sTarget, "", 0, @SW_SHOW)
EndFunc


Func _Log($sMsg)
    Local $sLogPath = "C:\Auto-installer\install-apps.log"
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
