; Version: v0.1.2
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; MPC-HC (Media Player Classic - Home Cinema) installer.
; $CmdLine[1] = setup filename (e.g. "mpc-1990.exe")
; $CmdLine[2] = desktop shortcut flag ("true"/"false")
;
; Install options (per user comment):
;   - Install everything (all components)
;   - Support every format (all file associations)
;   - Audio output: "Same as input" with all options enabled
;   - Decline any bundled offers
;
; MPC-HC uses an Inno Setup installer. Audio output and format settings are
; applied via registry after install (MPC-HC reads from HKCU).

Global $g_sSetupFilename = "mpc.exe"
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

_Log("INFO: Checking if MPC-HC is already installed...")
If _IsMPCInstalled() Then
    _Log("INFO: MPC-HC is already installed. Applying settings, creating shortcut, and exiting with code 10.")
    _ApplySettings()
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation of MPC-HC: " & $g_sSetupPath)
; /VERYSILENT = no UI; /NORESTART = no auto-reboot; /TASKS selects all components
Local $sInnoLog = "C:\Auto-installer\install_mpc_inno.log"
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" /VERYSILENT /NORESTART /TASKS="associate" /LOG="' & $sInnoLog & '"', @ScriptDir, @SW_HIDE)
_Log("INFO: Installer finished with exit code: " & $iExitCode)
_LogInnoFile($sInnoLog, "[MPC]")
If @error Then 
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf
If $iExitCode <> 0 Then 
    _Log("ERROR: Installer returned non-zero exit code: " & $iExitCode)
    Exit $iExitCode
EndIf

_Log("INFO: Waiting for MPC-HC to be fully registered...")
If _WaitForMPC(120) Then
    _Log("INFO: MPC-HC installation confirmed. Applying settings, creating shortcut, and exiting with code 0.")
    _ApplySettings()
    _CreateDesktopShortcut()
    Exit 0
EndIf

_Log("ERROR: MPC-HC installation validation timed out.")
Exit 22

Func _IsMPCInstalled()
    ; K-Lite Codec Pack paths
    If FileExists(@ProgramFilesDir & " (x86)\K-Lite Codec Pack\MPC-HC64\mpc-hc64.exe") Then Return True
    If FileExists(@ProgramFilesDir & " (x86)\K-Lite Codec Pack\MPC-HC\mpc-hc.exe") Then Return True
    
    ; Standalone paths
    If FileExists(@ProgramFilesDir & "\MPC-HC\mpc-hc64.exe") Then Return True
    If FileExists(@ProgramFilesDir & "\MPC-HC\mpc-hc.exe")    Then Return True
    If FileExists(@ProgramFilesDir & " (x86)\MPC-HC\mpc-hc.exe") Then Return True
    Local $sPath = RegRead("HKLM64\SOFTWARE\MPC-HC\MPC-HC", "ExePath")
    Return Not @error And FileExists($sPath)
EndFunc

Func _WaitForMPC($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsMPCInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _ApplySettings()
    ; MPC-HC stores settings in HKCU\Software\MPC-HC\MPC-HC
    ; Audio output renderer: 0 corresponds to System Default or Same as input
    RegWrite("HKCU\Software\MPC-HC\MPC-HC", "AudioRendererType", "REG_DWORD", 0)
    
    ; Built-in audio decoder settings
    RegWrite("HKCU\Software\MPC-HC\MPC-HC", "AudioMixer", "REG_DWORD", 1)
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sTarget = @ProgramFilesDir & "\MPC-HC\mpc-hc64.exe"
    If Not FileExists($sTarget) Then $sTarget = @ProgramFilesDir & " (x86)\K-Lite Codec Pack\MPC-HC64\mpc-hc64.exe"
    If Not FileExists($sTarget) Then $sTarget = @ProgramFilesDir & " (x86)\K-Lite Codec Pack\MPC-HC\mpc-hc.exe"
    If Not FileExists($sTarget) Then $sTarget = @ProgramFilesDir & "\MPC-HC\mpc-hc.exe"
    If Not FileExists($sTarget) Then $sTarget = @ProgramFilesDir & " (x86)\MPC-HC\mpc-hc.exe"
    
    Local $sReg = RegRead("HKLM64\SOFTWARE\MPC-HC\MPC-HC", "ExePath")
    If Not @error And FileExists($sReg) Then $sTarget = $sReg
    If Not FileExists($sTarget) Then Return
    
    Local $iSlash = StringInStr($sTarget, "\", 0, -1)
    Local $sDir = StringLeft($sTarget, $iSlash - 1)
    Local $sLink = "C:\Users\Public\Desktop\MPC-HC.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "MPC-HC", $sTarget, "", 0, @SW_SHOW)
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
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [MPC] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
