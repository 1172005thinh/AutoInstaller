; Version: v0.1.2
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Font installer - batch-installs all .ttf / .otf / .ttc files in the same directory
; for ALL users (copies to C:\Windows\Fonts + registry, no Shell.Application dialogs).
;
; $CmdLine[1] = setup directory name or basename (informational only, e.g. "Fonts")
; $CmdLine[2] = desktop shortcut flag (ignored - no launchable EXE)
; $CmdLine[3] = clean_after_installing ("true"/"false") - delete broken font files after install

Global $g_sSetupFilename = "Fonts"
Global $g_sLogPath = "C:\Auto-installer\install-apps.log"
If $CmdLine[0] >= 4 Then $g_sLogPath = $CmdLine[4]
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]

Global $g_bClean = False
If $CmdLine[0] >= 3 And StringLower($CmdLine[3]) = "true" Then $g_bClean = True

Global $g_sFontDir  = @ScriptDir
Global $g_sPsScript = @ScriptDir & "\install_fonts.ps1"

_Log("INFO: Starting batch font installation from: " & $g_sFontDir)
_Log("INFO: clean_after_installing=" & String($g_bClean))

; Verify the PS1 helper exists
If Not FileExists($g_sPsScript) Then
    _Log("ERROR: Helper script not found: " & $g_sPsScript)
    Exit 20
EndIf

; Temp files for result output
Local $sResultFile = @TempDir & "\autoinst_fonts_result.txt"
FileDelete($sResultFile)

_Log("INFO: Launching PowerShell font installer...")

; Build PowerShell arguments
Local $sPsArgs = '-NonInteractive -NoProfile -ExecutionPolicy Bypass' & _
    ' -File "' & $g_sPsScript & '"' & _
    ' -FontDir "' & $g_sFontDir & '"' & _
    ' -ResultFile "' & $sResultFile & '"' & _
    ' -LogFile "C:\Auto-installer\install-apps.log"' & _
    ' -CleanBroken ' & ($g_bClean ? "true" : "false")

Local $iPsExit = RunWait('powershell.exe ' & $sPsArgs, @SystemDir, @SW_HIDE)
If @error Then
    _Log("ERROR: Failed to launch PowerShell. AutoIt error=" & @error)
    Exit 21
EndIf
If $iPsExit <> 0 Then
    _Log("ERROR: PowerShell exited with code: " & $iPsExit)
    Exit $iPsExit
EndIf

; Read result summary written by PS1
Local $sResult    = FileRead($sResultFile)
Local $aInstalled = StringRegExp($sResult, "installed=(\d+)", 1)
Local $aSkipped   = StringRegExp($sResult, "skipped=(\d+)", 1)
Local $aFailed    = StringRegExp($sResult, "failed=(\d+)", 1)

Local $sInstalled = (Not @error And UBound($aInstalled) >= 1) ? $aInstalled[0] : "?"
Local $sSkipped   = (Not @error And UBound($aSkipped)   >= 1) ? $aSkipped[0]  : "?"
Local $sFailed    = (Not @error And UBound($aFailed)    >= 1) ? $aFailed[0]   : "?"

_Log("INFO: Done. installed=" & $sInstalled & " skipped=" & $sSkipped & " failed=" & $sFailed)

Exit 0

Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    DirCreate("C:\Auto-installer")
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND + FO_UTF8_NOBOM
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [Fonts] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
