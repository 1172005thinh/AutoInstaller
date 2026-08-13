#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; UniKey Vietnamese keyboard input method installer.
; $CmdLine[1] = setup filename (e.g. "unikey-4.6RC2.exe")
; $CmdLine[2] = desktop shortcut flag ("true"/"false")
;
; UniKey is a portable application -- there is no installer.
; Installation steps (per user comment):
;   1. Create C:\Program Files\UniKey\
;   2. Copy the exe from @ScriptDir into that directory
;   3. Register a run-at-startup entry so UniKey loads automatically

Global $g_sSetupFilename = "unikey.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename

Global Const $g_sInstallDir  = @ProgramFilesDir & "\UniKey"
Global Const $g_sInstallExe  = $g_sInstallDir & "\" & ($CmdLine[0] >= 1 ? $CmdLine[1] : "unikey.exe")

Global $g_bShortcut = False
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if app is already installed...")
If _IsUniKeyInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

; Create target directory and copy the portable exe
If Not DirCreate($g_sInstallDir) Then Exit 21
If Not FileCopy($g_sSetupPath, $g_sInstallExe, 1) Then Exit 22

_Log("INFO: Running Unikey to initialize defaults...")
Run('"' & $g_sInstallExe & '"', $g_sInstallDir, @SW_HIDE)
Sleep(2000)

_Log("INFO: Terminating Unikey...")
Local $sExeName = StringTrimLeft($g_sInstallExe, StringInStr($g_sInstallExe, "\", 0, -1))
While ProcessExists($sExeName)
    ProcessClose($sExeName)
    Sleep(500)
WEnd

_Log("INFO: Patching and importing unikey.reg settings...")
Local $sRegFile = @ScriptDir & "\unikey.reg"
If FileExists($sRegFile) Then
    ; Read the UTF-16LE registry file
    Local $sRegContent = FileRead($sRegFile)
    
    ; Update the MacroPath to point to %APPDATA%\Unikey\macro.txt
    Local $sMacroPath = @AppDataDir & "\Unikey\macro.txt"
    Local $sEscapedMacro = StringReplace($sMacroPath, "\", "\\")
    $sRegContent = StringRegExpReplace($sRegContent, '(?m)^"MacroPath"=.*$', '"MacroPath"="' & $sEscapedMacro & '"')
    
    ; Write patched content to a temp file (32 + 2 = UTF-16LE with BOM + Overwrite)
    Local $sTempReg = @TempDir & "\unikey_patched.reg"
    Local $hWrite = FileOpen($sTempReg, 32 + 2)
    FileWrite($hWrite, $sRegContent)
    FileClose($hWrite)
    
    RunWait('reg.exe import "' & $sTempReg & '"', "", @SW_HIDE)
    FileDelete($sTempReg)
EndIf

; Set "Start with Windows" explicitly in the Run key
RegWrite("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "UniKeyNT", "REG_SZ", '"' & $g_sInstallExe & '"')

_Log("INFO: Restarting Unikey with new settings...")
Run('"' & $g_sInstallExe & '"', $g_sInstallDir, @SW_HIDE)

_CreateDesktopShortcut()
Exit 0

Func _IsUniKeyInstalled()
    ; Check if any unikey*.exe exists in the install directory
    Return FileExists($g_sInstallExe) Or (FileFindFirstFile($g_sInstallDir & "\unikey*.exe") <> -1)
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    If Not FileExists($g_sInstallExe) Then Return
    Local $sLink = "C:\Users\Public\Desktop\UniKey.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($g_sInstallExe, $sLink, $g_sInstallDir, "", "UniKey", $g_sInstallExe, "", 0, @SW_SHOW)
EndFunc


Func _Log($sMsg)
    Local $sLogPath = "C:\Auto-installer\install-apps.log"
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
