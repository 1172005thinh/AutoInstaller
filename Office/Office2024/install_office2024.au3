#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Office 2024 installer (ODT-based).
; $CmdLine[1] = setup filename (e.g. "office2024.exe")  [optional, fallback "office2024.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")   [optional, fallback false]
; $CmdLine[4] = log path                                 [optional, fallback "C:\Auto-installer\install-apps.log"]
;
; Detection: dynamically resolves Office root from ClickToRun registry configuration
; and verifies presence of core Office executables across 64-bit and 32-bit install paths.

Global $g_sSetupFilename = "office2024.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename
Global Const $g_sXmlPath   = @ScriptDir & "\full_en.xml"

Global $g_bShortcut = False
Global $g_sLogPath = "C:\Auto-installer\install-apps.log"
If $CmdLine[0] >= 4 Then $g_sLogPath = $CmdLine[4]
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

If Not FileExists($g_sXmlPath) Then
    _Log("ERROR: Configuration XML not found: " & $g_sXmlPath)
    Exit 20
EndIf

_Log("INFO: Checking if Office 2024 is already installed...")
If _IsOffice2024Installed() Then
    _Log("INFO: Office 2024 is already installed. Exiting with code 10.")
    _CreateDesktopShortcuts()
    Exit 10
EndIf

_Log("INFO: Starting Office 2024 installation via ODT...")
Local $sCmd = '"' & $g_sSetupPath & '" /configure "' & $g_sXmlPath & '"'
Local $iExitCode = RunWait($sCmd, @ScriptDir, @SW_HIDE)
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
If _WaitForOffice2024(60) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcuts()
    Exit 0
EndIf
_CreateDesktopShortcuts()
Exit 0

Func _GetOffice16Dir()
    Local $aRoots[2] = ["HKLM64", "HKLM"]
    For $iR = 0 To UBound($aRoots) - 1
        Local $sRoot = RegRead($aRoots[$iR] & "\SOFTWARE\Microsoft\Office\ClickToRun\Configuration", "InstallationPath")
        If Not @error And $sRoot <> "" Then
            If StringRight($sRoot, 1) = "\" Then $sRoot = StringTrimRight($sRoot, 1)
            If FileExists($sRoot & "\root\Office16\WINWORD.EXE") Then Return $sRoot & "\root\Office16"
            If FileExists($sRoot & "\Office16\WINWORD.EXE") Then Return $sRoot & "\Office16"
        EndIf
    Next

    Local $aCandidates[4] = [ _
        @ProgramFilesDir & "\Microsoft Office\root\Office16", _
        @ProgramFilesDir & "\Microsoft Office\Office16", _
        @ProgramFilesDir & " (x86)\Microsoft Office\root\Office16", _
        @ProgramFilesDir & " (x86)\Microsoft Office\Office16" _
    ]

    For $iC = 0 To UBound($aCandidates) - 1
        If FileExists($aCandidates[$iC] & "\WINWORD.EXE") Or FileExists($aCandidates[$iC] & "\EXCEL.EXE") Then
            Return $aCandidates[$iC]
        EndIf
    Next

    Return ""
EndFunc

Func _IsOffice2024Installed()
    Local $sOffice16 = _GetOffice16Dir()
    If $sOffice16 <> "" Then Return True

    Local $aRoots[2] = ["HKLM64", "HKLM"]
    For $iR = 0 To UBound($aRoots) - 1
        Local $sIds = RegRead($aRoots[$iR] & "\SOFTWARE\Microsoft\Office\ClickToRun\Configuration", "ProductReleaseIds")
        If Not @error And (StringInStr($sIds, "2024") > 0 Or StringInStr($sIds, "ProPlus") > 0) Then Return True
    Next

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

Func _CreateDesktopShortcuts()
    If Not $g_bShortcut Then Return

    Local $sOffice16 = _GetOffice16Dir()
    If $sOffice16 = "" Or Not FileExists($sOffice16) Then Return

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
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
