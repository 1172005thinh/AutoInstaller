#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; UltraViewer remote desktop installer.
; $CmdLine[1] = setup filename (e.g. "ultraviewer-6.6.133.exe")
; $CmdLine[2] = desktop shortcut flag ("true"/"false")

Global $g_sSetupFilename = "ultraviewer.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename

Global $g_bShortcut = False
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if app is already installed...")
If _IsUltraViewerInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

; UltraViewer uses Inno Setup
_Log("INFO: Starting installation...")
Local $sInnoLog = "C:\Auto-installer\install_ultraviewer_inno.log"
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" /VERYSILENT /NORESTART /SUPPRESSMSGBOXES /LOG="' & $sInnoLog & '"', @ScriptDir, @SW_HIDE)
_Log("INFO: Installer finished with exit code: " & $iExitCode)
_LogInnoFile($sInnoLog, "[UltraViewer]")
If @error Then
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf

If $iExitCode <> 0 Then
    _Log("ERROR: Installer returned non-zero exit code: " & $iExitCode)
    Exit $iExitCode
EndIf

_Log("INFO: Waiting for app to be fully registered...")
If _WaitForUltraViewer(60) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _IsUltraViewerInstalled()
    Local $sPath = RegRead("HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\UltraViewer_is1", "InstallLocation")
    If Not @error And FileExists($sPath & "\UltraViewer_Desktop.exe") Then Return True
    Local $sPath32 = RegRead("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\UltraViewer_is1", "InstallLocation")
    If Not @error And FileExists($sPath32 & "\UltraViewer_Desktop.exe") Then Return True
    Return FileExists(@ProgramFilesDir & "\UltraViewer\UltraViewer_Desktop.exe") Or FileExists(@ProgramFilesDir & " (x86)\UltraViewer\UltraViewer_Desktop.exe")
EndFunc

Func _WaitForUltraViewer($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsUltraViewerInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sTarget = @ProgramFilesDir & " (x86)\UltraViewer\UltraViewer_Desktop.exe"
    If Not FileExists($sTarget) Then $sTarget = @ProgramFilesDir & "\UltraViewer\UltraViewer_Desktop.exe"
    Local $sReg = RegRead("HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\UltraViewer_is1", "InstallLocation")
    If @error Or $sReg = "" Then $sReg = RegRead("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\UltraViewer_is1", "InstallLocation")
    If Not @error And $sReg <> "" Then $sTarget = $sReg & "\UltraViewer_Desktop.exe"
    
    If Not FileExists($sTarget) Then Return
    Local $iSlash = StringInStr($sTarget, "\", 0, -1)
    Local $sDir = StringLeft($sTarget, $iSlash - 1)
    Local $sLink = "C:\Users\Public\Desktop\UltraViewer.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "UltraViewer", $sTarget, "", 0, @SW_SHOW)
EndFunc


Func _LogInnoFile($sInnoPath, $sTag)
    If Not FileExists($sInnoPath) Then Return
    Local $hInno = FileOpen($sInnoPath, 0)
    If $hInno = -1 Then Return
    Local $sLogPath = "C:\Auto-installer\install-apps.log"
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
    Local $sLogPath = "C:\Auto-installer\install-apps.log"
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
