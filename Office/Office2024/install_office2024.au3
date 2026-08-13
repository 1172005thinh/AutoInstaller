#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Office 2024 ProPlus installer wrapper.
; $CmdLine[1] = setup filename (e.g. "office2024.exe")   [optional, fallback "office2024.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")   [optional, fallback false]
;
; Runs: office2024.exe /configure full_en.xml  (Office Deployment Tool, silent)
;
; Shortcuts: created for every Office app whose EXE is present in Office16 after install.
; This naturally honours the ExcludeApp entries in full_en.xml without XML parsing --
; excluded apps simply won't have an EXE on disk.
;
; Return codes:
;   0  = installed successfully
;   10 = already installed
;   20 = setup or config file missing
;   21 = RunWait failed to launch
;   22+ = setup returned a non-zero exit code (passed through)

Global $g_sSetupFilename = "office2024.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath  = @ScriptDir & "\" & $g_sSetupFilename
Global Const $g_sConfigPath = @ScriptDir & "\full_en.xml"

Global $g_bShortcut = False
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

If Not FileExists($g_sSetupPath)  Then Exit 20
If Not FileExists($g_sConfigPath) Then Exit 20

_Log("INFO: Checking if app is already installed...")
If _IsOffice2024Installed() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcuts()
    Exit 10
EndIf

_Log("INFO: Starting installation...")
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" /configure "' & $g_sConfigPath & '"', @ScriptDir, @SW_HIDE)
_Log("INFO: Installer finished with exit code: " & $iExitCode)
If @error Then
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf

If $iExitCode <> 0 Then
    _Log("ERROR: Installer returned non-zero exit code: " & $iExitCode)
    Exit $iExitCode
EndIf

; ODT may take time to write registry keys after the process exits.
; Poll up to 60 seconds, then trust the exit code.
_Log("INFO: Waiting for app to be fully registered...")
If _WaitForOffice2024(60) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcuts()
    Exit 0
EndIf
_CreateDesktopShortcuts()
Exit 0

; â”€â”€â”€ Detection â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

Func _IsOffice2024Installed()
    Local $sIds = RegRead("HKLM64\SOFTWARE\Microsoft\Office\ClickToRun\Configuration", "ProductReleaseIds")
    If Not @error And StringInStr($sIds, "ProPlus2024Volume") Then Return True
    Local $sRoot = RegRead("HKLM64\SOFTWARE\Microsoft\Office\ClickToRun\Configuration", "InstallationPath")
    If Not @error And $sRoot <> "" And FileExists($sRoot & "\root\Office16\WINWORD.EXE") Then Return True
    Return False
EndFunc

Func _WaitForOffice2024($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsOffice2024Installed() Then Return True
        Sleep(2000)
    WEnd
    Return False
EndFunc

; â”€â”€â”€ Shortcuts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
; Creates one shortcut per Office app whose EXE actually exists under Office16.
; This naturally handles ExcludeApp entries in full_en.xml -- excluded apps have
; no EXE on disk, so they simply get no shortcut.

Func _CreateDesktopShortcuts()
    If Not $g_bShortcut Then Return

    Local $sOfficePath = RegRead("HKLM64\SOFTWARE\Microsoft\Office\ClickToRun\Configuration", "InstallationPath")
    If @error Or $sOfficePath = "" Then Return
    Local $sOffice16 = $sOfficePath & "\root\Office16"

    ; All standard Office 2024 ProPlus executables and their friendly names.
    ; Apps absent from disk (excluded via ODT config) are silently skipped.
    Local $aApps[7][2]
    $aApps[0][0] = "WINWORD.EXE"
    $aApps[0][1] = "Microsoft Word"
    $aApps[1][0] = "EXCEL.EXE"
    $aApps[1][1] = "Microsoft Excel"
    $aApps[2][0] = "POWERPNT.EXE"
    $aApps[2][1] = "Microsoft PowerPoint"
    $aApps[3][0] = "OUTLOOK.EXE"
    $aApps[3][1] = "Microsoft Outlook"
    $aApps[4][0] = "ONENOTE.EXE"
    $aApps[4][1] = "Microsoft OneNote"
    $aApps[5][0] = "MSACCESS.EXE"
    $aApps[5][1] = "Microsoft Access"
    $aApps[6][0] = "MSPUB.EXE"
    $aApps[6][1] = "Microsoft Publisher"

    For $i = 0 To UBound($aApps) - 1
        Local $sExe = $sOffice16 & "\" & $aApps[$i][0]
        If Not FileExists($sExe) Then ContinueLoop
        Local $sLink = "C:\Users\Public\Desktop\" & $aApps[$i][1] & ".lnk"
        If Not FileExists($sLink) Then
            FileCreateShortcut($sExe, $sLink, $sOffice16, "", $aApps[$i][1], $sExe, "", 0, @SW_SHOW)
        EndIf
    Next
EndFunc


Func _Log($sMsg)
    Local $sLogPath = "C:\Auto-installer\install-apps.log"
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
