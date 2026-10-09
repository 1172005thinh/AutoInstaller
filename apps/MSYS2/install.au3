;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     apps/MSYS2/install.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Includes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include <AutoItConstants.au3>
#include <FileConstants.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration & Parameters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Includes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include <AutoItConstants.au3>
#include <FileConstants.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration & Parameters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Generic MSYS2 installer.
; $CmdLine[1] = setup filename or path (e.g. "msys2.exe", "msys2-x86_64.exe") [optional, fallback "msys2.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")                       [optional, fallback false]
; $CmdLine[4] = log path                                                     [optional, fallback "C:\AutoInstaller\apps.log"]

Global $g_sSetupFilename = "msys2.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]

Global $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename
If FileExists($g_sSetupFilename) Then $g_sSetupPath = $g_sSetupFilename

Global $g_bShortcut = False
Global $g_sLogPath = "C:\AutoInstaller\apps.log"
If $CmdLine[0] >= 4 Then $g_sLogPath = $CmdLine[4]
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main Installation Execution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main Installation Execution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if MSYS2 is already installed...")
If _IsMSYS2Installed() Then
    _Log("INFO: MSYS2 is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation of MSYS2: " & $g_sSetupPath)
; Standard unattended flags for Qt Installer Framework (MSYS2)
Local $sSilentArgs = "in --confirm-command --accept-messages --root C:\msys64"
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" ' & $sSilentArgs, @ScriptDir, @SW_HIDE)
_Log("INFO: Installer finished with exit code: " & $iExitCode)
If @error Then
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf

If $iExitCode <> 0 Then
    _Log("ERROR: Installer returned non-zero exit code: " & $iExitCode)
    Exit $iExitCode
EndIf

_Log("INFO: Waiting for MSYS2 installation verification...")
If _WaitForMSYS2(180) Then
    _Log("INFO: MSYS2 installation confirmed. Creating shortcut and exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf

_Log("ERROR: Installation validation timed out.")
Exit 22

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Helper Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Helper Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _GetMSYS2Dir()
    If FileExists("C:\msys64\msys2.exe") Then Return "C:\msys64"
    If FileExists("C:\msys32\msys2.exe") Then Return "C:\msys32"
    Return ""
EndFunc

Func _IsMSYS2Installed()
    Return (_GetMSYS2Dir() <> "")
EndFunc

Func _WaitForMSYS2($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsMSYS2Installed() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sDir = _GetMSYS2Dir()
    If $sDir = "" Then Return
    Local $sTarget = $sDir & "\ucrt64.exe"
    If Not FileExists($sTarget) Then $sTarget = $sDir & "\msys2.exe"
    If Not FileExists($sTarget) Then Return

    Local $sLink = "C:\Users\Public\Desktop\MSYS2 UCRT64.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "MSYS2 UCRT64 Environment", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $sDir = StringLeft($g_sLogPath, StringInStr($g_sLogPath, "\", 0, -1) - 1)
    If $sDir <> "" And Not FileExists($sDir) Then DirCreate($sDir)
    Local $hLog = FileOpen($g_sLogPath, BitOR($FO_APPEND, $FO_UTF8_NOBOM, $FO_CREATEPATH))
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [MSYS2] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
