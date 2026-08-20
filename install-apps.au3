#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#include <AutoItConstants.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <File.au3>

; ── ANSI colour constants (ASCII ESC sequences, work in any VT-capable console) ──
Global Const $g_ESC   = Chr(27)
Global Const $g_cRst  = $g_ESC & "[0m"    ; reset all attributes
Global Const $g_cBold = $g_ESC & "[1m"    ; bold
Global Const $g_cDim  = $g_ESC & "[2m"    ; dim
Global Const $g_cRed  = $g_ESC & "[91m"   ; bright red
Global Const $g_cGrn  = $g_ESC & "[92m"   ; bright green
Global Const $g_cYlw  = $g_ESC & "[93m"   ; bright yellow
Global Const $g_cCyn  = $g_ESC & "[96m"   ; bright cyan
Global Const $g_cWht  = $g_ESC & "[97m"   ; bright white

; ── Project globals ────────────────────────────────────────────────────────────
Global Const $g_sMarkerFile     = "aea541d7f9574587656dc5125116e548.md5"
Global Const $g_sDefaultLogPath = "C:\Auto-installer\install-apps.log"
Global $g_sRoot                 = ""
Global $g_sLogPath              = $g_sDefaultLogPath
Global $g_hConOut               = -1   ; FileOpen handle to the allocated console
Global $g_sCleanFonts           = "false"  ; clean_after_installing setting from INI

; ════════════════════════════════════════════════════════════════════════════════
;  STARTUP
; ════════════════════════════════════════════════════════════════════════════════
_ConsoleInit()

If Not _IsAdministrator() Then
    _ConsolePrint("ERROR", "Administrator privileges are required.")
    _ConsolePause()
    Exit 5
EndIf

$g_sRoot = _FindSoftwareRoot()
If $g_sRoot = "" Then
    _ConsolePrint("ERROR", "Software partition marker not found on any drive.")
    _ConsolePause()
    Exit 6
EndIf

Local $sMode = "--full"
If $CmdLine[0] > 0 Then $sMode = StringLower($CmdLine[1])

_ConsoleBanner($sMode)
_WriteLog("INFO", "Console opened. Mode=" & $sMode & "; Root=" & $g_sRoot)

Switch $sMode
    Case "--full"
        _WriteLog("INFO", "Master launcher started in full mode.")
        _InstallApplications()
        _RunWindowsConfig()
        _RunDrivers(False)
        _RunReport()
    Case "--drivers-only"
        _WriteLog("INFO", "Master launcher started in drivers-only mode.")
        _RunDrivers(False)
    Case "--report"
        _WriteLog("INFO", "Generating installation report only.")
        _RunReport()
    Case Else
        _WriteLog("ERROR", "Unknown command-line mode: " & $sMode)
        _ConsolePrint("ERROR", "Unknown mode '" & $sMode & "'. Valid: --full | --drivers-only | --resume-apps | --report")
        _ConsolePause()
        Exit 7
EndSwitch

_WriteLog("INFO", "All tasks handed off or completed.")
_ConsolePrint("INFO", "Done. Full log: " & $g_sLogPath)
_ConsolePause()

; ════════════════════════════════════════════════════════════════════════════════
;  CORE FLOW FUNCTIONS
; ════════════════════════════════════════════════════════════════════════════════

Func _RunDrivers($bResumeApps)
    _ConsoleSectionHeader("Driver Installation")
    Local $sDriverLauncher = $g_sRoot & "\install-drivers.exe"
    If Not FileExists($sDriverLauncher) Then
        _WriteLog("ERROR", "install-drivers.exe was not found at " & $sDriverLauncher)
        _ConsolePrint("ERROR", "install-drivers.exe not found: " & $sDriverLauncher)
        Exit 20
    EndIf

    Local $sArguments = "-ReportAfterCompletion"
    If $bResumeApps Then $sArguments = "-ResumeApps"

    _ConsolePrint("INFO", "Launching driver installer (Windows Update -- system may restart)...")
    Local $iExitCode = ShellExecuteWait($sDriverLauncher, $sArguments, $g_sRoot, "open", @SW_HIDE)
    If @error Then
        _WriteLog("ERROR", "Could not start install-drivers.exe. AutoIt error=" & @error)
        _ConsolePrint("ERROR", "Could not launch driver installer (AutoIt error=" & @error & ").")
        Exit 21
    EndIf

    If $iExitCode <> 0 Then
        _WriteLog("ERROR", "Driver launcher returned exit code " & $iExitCode & ".")
        _ConsolePrint("ERROR", "Driver installer returned exit code " & $iExitCode & " -- continuing to report.")
        Return  ; Don't Exit — fall through so _RunReport still generates the report
    EndIf

    _WriteLog("INFO", "Driver launcher completed or handed off to its continuation.")
    _ConsolePrint("OK", "Driver installation phase done (or handed off for reboot-continuation).")
EndFunc

Func _InstallApplications()
    _ConsoleSectionHeader("Application Installation")
    Local $aTargets[0][5]
    Local $iMaxIteration = 0
    Local $sConfigPath = $g_sRoot & "\install-apps.ini"

    If Not _LoadConfiguration($sConfigPath, $aTargets, $iMaxIteration) Then
        _WriteLog("ERROR", "Configuration validation failed: " & $sConfigPath)
        _ConsolePrint("ERROR", "Failed to load/parse install-apps.ini.")
        Exit 30
    EndIf

    Local $iTargetCount = UBound($aTargets)
    If $iTargetCount = 0 Then
        _WriteLog("ERROR", "Configuration contains no application targets.")
        _ConsolePrint("WARN", "No application targets found in install-apps.ini.")
        Exit 31
    EndIf

    ; Count enabled apps for informational display
    Local $iEnabledCount = 0
    For $i = 0 To $iTargetCount - 1
        If StringLower($aTargets[$i][3]) = "true" Then $iEnabledCount += 1
    Next

    Local $aStatus[$iTargetCount]
    For $i = 0 To $iTargetCount - 1
        $aStatus[$i] = -1   ; -1=pending, 0=failed, 1=installed, 2=already installed, 3=disabled
    Next

    If $iMaxIteration = 0 Then
        _WriteLog("INFO", "max_iteration is 0; no application installers will be run.")
        _ConsolePrint("WARN", "max_iteration=0 -- application installation skipped.")
        Return
    EndIf

    _ConsolePrint("INFO", $iTargetCount & " target(s) loaded, " & $iEnabledCount & " enabled, max " & $iMaxIteration & " iteration(s).")
    
    _CW(@CRLF & $g_cDim & "  === Target List ===" & $g_cRst & @CRLF)
    For $i = 0 To $iTargetCount - 1
        Local $sName = $aTargets[$i][1]
        Local $iSlash = StringInStr($sName, "/", 0, -1)
        If $iSlash > 0 Then $sName = StringMid($sName, $iSlash + 1)
        
        Local $sInstallFlag = $aTargets[$i][3]
        Local $sShortcutFlag = $aTargets[$i][4]
        
        Local $sStatusStr = $g_cDim & "install=" & $sInstallFlag & "  shortcut=" & $sShortcutFlag & $g_cRst
        If StringLower($sInstallFlag) = "true" Then
            $sStatusStr = $g_cCyn & "install=true  " & $g_cDim & "shortcut=" & $sShortcutFlag & $g_cRst
        Else
            $sStatusStr = $g_cYlw & "install=false " & $g_cDim & "shortcut=" & $sShortcutFlag & $g_cRst
        EndIf
        
        _CW("    " & StringFormat("%-40s", $sName) & " " & $sStatusStr & @CRLF)
    Next
    _CW(@CRLF)

    For $iIteration = 1 To $iMaxIteration
        Local $bHasPendingTarget = False
        _WriteLog("INFO", "Starting application installation iteration " & $iIteration & " of " & $iMaxIteration & ".")
        If $iMaxIteration > 1 Then
            _CW(@CRLF & $g_cDim & "  -- Iteration " & $iIteration & " of " & $iMaxIteration & " --" & $g_cRst & @CRLF)
        EndIf

        For $i = 0 To $iTargetCount - 1
            Local $iIndex               = Int($aTargets[$i][0])
            Local $sSetupRelativePath   = $aTargets[$i][1]
            Local $sInstallRelativePath = $aTargets[$i][2]
            Local $bInstallEnabled      = StringLower($aTargets[$i][3]) = "true"
            Local $sShortcutFlag        = StringLower($aTargets[$i][4])  ; "true" or "false"

            ; Short display name (filename portion of the relative path)
            Local $sName = $sSetupRelativePath
            Local $iSlash = StringInStr($sName, "/", 0, -1)
            If $iSlash > 0 Then $sName = StringMid($sName, $iSlash + 1)

            If Not $bInstallEnabled Then
                If $aStatus[$i] = -1 Then
                    $aStatus[$i] = 3
                    _WriteLog("INFO", "[APP] index=" & $iIndex & "; name=" & $sSetupRelativePath & "; status=disabled; detail=install_flag is false")
                    _CW($g_cDim & "  [DIS] " & $sName & " -- disabled in config" & $g_cRst & @CRLF)
                EndIf
                ContinueLoop
            EndIf

            If $aStatus[$i] = 1 Or $aStatus[$i] = 2 Then ContinueLoop
            $bHasPendingTarget = True

            ; Print ">> appname ... " then append result on the same line after install completes
            _CW(@CRLF & $g_cWht & $g_cBold & "  >> " & $sName & $g_cRst & " ... ")

            Local $sSetupPath   = _ResolveTargetPath($sSetupRelativePath)
            Local $sInstallPath = _ResolveTargetPath($sInstallRelativePath)
            ; setup_file may be a directory (e.g. for the font installer)
            Local $bSetupExists = FileExists($sSetupPath) Or (StringInStr(FileGetAttrib($sSetupPath), "D") > 0)
            If Not $bSetupExists Or Not FileExists($sInstallPath) Then
                $aStatus[$i] = 0
                _WriteLog("ERROR", "[APP] index=" & $iIndex & "; name=" & $sSetupRelativePath & "; status=failed; detail=setup or install script is missing")
                _CW($g_cRed & "[FAIL] missing files" & $g_cRst & @CRLF)
                ContinueLoop
            EndIf

            ; Pass setup filename (basename) and shortcut flag as CLI args to the installer.
            ; The installer uses $CmdLine[1] to find its setup file and $CmdLine[2] to decide
            ; whether to place a Desktop shortcut -- no recompile needed when versions change.
            Local $sSetupBasename = $sSetupRelativePath
            Local $iSetupSlash = StringInStr($sSetupBasename, "/", 0, -1)
            If $iSetupSlash > 0 Then $sSetupBasename = StringMid($sSetupBasename, $iSetupSlash + 1)
            ; Pass setup name, shortcut flag, and (for special installers) the clean flag as CLI args
            Local $sInstallArgs = '"' & $sSetupBasename & '" "' & $sShortcutFlag & '" "' & $g_sCleanFonts & '" "' & $g_sLogPath & '"'
            Local $iExitCode = ShellExecuteWait($sInstallPath, $sInstallArgs, $g_sRoot, "open", @SW_HIDE)
            If @error Then
                $aStatus[$i] = 0
                _WriteLog("ERROR", "[APP] index=" & $iIndex & "; name=" & $sSetupRelativePath & "; status=failed; detail=could not launch installer script; autoit_error=" & @error)
                _CW($g_cRed & "[FAIL] could not launch (AutoIt error=" & @error & ")" & $g_cRst & @CRLF)
                ContinueLoop
            EndIf

            Switch $iExitCode
                Case 0
                    $aStatus[$i] = 1
                    _WriteLog("INFO", "[APP] index=" & $iIndex & "; name=" & $sSetupRelativePath & "; status=installed; detail=installer script completed and verified the installation")
                    _CW($g_cGrn & "[OK]" & $g_cRst & @CRLF)
                Case 10
                    $aStatus[$i] = 2
                    _WriteLog("INFO", "[APP] index=" & $iIndex & "; name=" & $sSetupRelativePath & "; status=already-installed; detail=installer script detected an existing installation")
                    _CW($g_cDim & "[SKIP] already installed" & $g_cRst & @CRLF)
                Case Else
                    $aStatus[$i] = 0
                    _WriteLog("ERROR", "[APP] index=" & $iIndex & "; name=" & $sSetupRelativePath & "; status=failed; detail=installer script exit code " & $iExitCode)
                    _CW($g_cRed & "[FAIL] exit=" & $iExitCode & $g_cRst & @CRLF)
            EndSwitch
        Next

        If Not $bHasPendingTarget Then ExitLoop
    Next

    Local $iFailureCount = 0
    For $i = 0 To $iTargetCount - 1
        If $aStatus[$i] = 0 Or $aStatus[$i] = -1 Then $iFailureCount += 1
    Next

    If $iFailureCount = 0 Then
        _WriteLog("INFO", "Application installation completed without pending failures.")
    Else
        _WriteLog("ERROR", "Application installation completed with " & $iFailureCount & " failed or pending target(s).")
    EndIf

    _ConsolePrintSummary($aStatus, $aTargets)
EndFunc

Func _RunWindowsConfig()
    _ConsoleSectionHeader("Windows Configuration")
    Local $sConfigLauncher = $g_sRoot & "\configure-windows.exe"
    If Not FileExists($sConfigLauncher) Then
        _WriteLog("WARN", "configure-windows.exe not found at " & $sConfigLauncher & " -- skipping Windows configuration.")
        _ConsolePrint("WARN", "configure-windows.exe not found -- skipping Windows configuration.")
        Return
    EndIf

    _ConsolePrint("INFO", "Applying post-installation Windows settings...")
    Local $iExitCode = ShellExecuteWait($sConfigLauncher, "", $g_sRoot, "open", @SW_HIDE)
    If @error Or $iExitCode <> 0 Then
        _WriteLog("ERROR", "configure-windows.exe failed. exit_code=" & $iExitCode & "; autoit_error=" & @error)
        _ConsolePrint("ERROR", "Windows configuration failed (exit=" & $iExitCode & ").")
    Else
        _WriteLog("INFO", "Windows configuration completed successfully.")
        _ConsolePrint("OK", "Windows settings applied. Log: C:\Auto-installer\configure-windows.log")
    EndIf
EndFunc

Func _RunReport()
    _ConsoleSectionHeader("Report Generation")
    Local $sReportLauncher = $g_sRoot & "\report.exe"
    If Not FileExists($sReportLauncher) Then
        _WriteLog("ERROR", "report.exe was not found at " & $sReportLauncher)
        _ConsolePrint("WARN", "report.exe not found -- skipping report generation.")
        Return
    EndIf

    _ConsolePrint("INFO", "Generating installation report...")
    Local $iExitCode = ShellExecuteWait($sReportLauncher, "", $g_sRoot, "open", @SW_HIDE)
    If @error Or $iExitCode <> 0 Then
        _WriteLog("ERROR", "Report launcher failed. exit_code=" & $iExitCode & "; autoit_error=" & @error)
        _ConsolePrint("ERROR", "Report generation failed (exit=" & $iExitCode & ").")
    Else
        _WriteLog("INFO", "Report generation completed.")
        _ConsolePrint("OK", "Report saved to C:\Auto-installer\report.md")
    EndIf
EndFunc

; ════════════════════════════════════════════════════════════════════════════════
;  CONSOLE HELPERS
; ════════════════════════════════════════════════════════════════════════════════

Func _ConsoleInit()
    ; Allocate a visible console window. Safe to call from any parent (GUI app,
    ; Task Scheduler, RunSynchronousCommand) -- creates a new console if none exists.
    DllCall("kernel32.dll", "bool", "AllocConsole")
    DllCall("kernel32.dll", "bool", "SetConsoleTitleW", "wstr", "AutoInstaller - Live Progress")

    ; Open the new console's output buffer as an AutoIt file handle
    $g_hConOut = FileOpen("CONOUT$", 1)   ; FO_APPEND (write mode for device)

    ; Enable ANSI/VT100 virtual-terminal processing via the Win32 console handle
    Local $aH = DllCall("kernel32.dll", "handle", "CreateFileW", _
        "wstr", "CONOUT$", "dword", 0xC0000000, "dword", 3, "ptr", 0, "dword", 3, "dword", 0, "ptr", 0)
    If Not @error And IsArray($aH) And $aH[0] <> -1 Then
        Local $aM = DllCall("kernel32.dll", "bool", "GetConsoleMode", "handle", $aH[0], "dword*", 0)
        If Not @error And IsArray($aM) Then
            ; ENABLE_PROCESSED_OUTPUT(0x01) | ENABLE_VIRTUAL_TERMINAL_PROCESSING(0x04)
            DllCall("kernel32.dll", "bool", "SetConsoleMode", "handle", $aH[0], "dword", BitOR($aM[2], 0x0001, 0x0004))
        EndIf
        DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $aH[0])
    EndIf
EndFunc

; Raw write to the console (no trailing newline added)
Func _CW($s)
    If $g_hConOut <> -1 Then FileWrite($g_hConOut, $s)
EndFunc

Func _ConsoleBanner($sMode)
    Local $sTS = @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) _
               & " " & @HOUR & ":" & @MIN & ":" & @SEC
    _CW($g_cCyn & $g_cBold & "============================================" & @CRLF)
    _CW(          "  AutoInstaller -- Live Log" & @CRLF)
    _CW(          "============================================" & $g_cRst & @CRLF)
    _CW($g_cDim & "  Started : " & $sTS        & @CRLF)
    _CW(          "  Root    : " & $g_sRoot    & @CRLF)
    _CW(          "  Mode    : " & $sMode      & @CRLF)
    _CW(          "  Log     : " & $g_sLogPath & $g_cRst & @CRLF & @CRLF)
EndFunc

Func _ConsoleSectionHeader($sTitle)
    _CW(@CRLF & $g_cCyn & $g_cBold & "=== " & $sTitle & " ===" & $g_cRst & @CRLF)
EndFunc

Func _ConsolePrint($sLevel, $sMessage)
    Local $sTS = @HOUR & ":" & @MIN & ":" & @SEC
    Switch $sLevel
        Case "OK"
            _CW($g_cGrn & "  [OK]   " & $sMessage & $g_cRst & @CRLF)
        Case "ERROR"
            _CW($g_cRed & "  [FAIL] " & $sMessage & $g_cRst & @CRLF)
        Case "WARN"
            _CW($g_cYlw & "  [WARN] " & $sMessage & $g_cRst & @CRLF)
        Case "SKIP"
            _CW($g_cDim & "  [SKIP] " & $sMessage & $g_cRst & @CRLF)
        Case Else   ; INFO
            _CW($g_cDim & "  [" & $sTS & "] " & $g_cRst & $sMessage & @CRLF)
    EndSwitch
EndFunc

Func _ConsolePrintSummary($aStatus, $aTargets)
    Local $iInstalled = 0, $iAlready = 0, $iFailed = 0, $iDisabled = 0, $iPending = 0
    For $i = 0 To UBound($aStatus) - 1
        Switch $aStatus[$i]
            Case 1
                $iInstalled += 1
            Case 2
                $iAlready  += 1
            Case 0
                $iFailed   += 1
            Case 3
                $iDisabled += 1
            Case -1
                $iPending  += 1
        EndSwitch
    Next

    _CW(@CRLF & $g_cCyn & $g_cBold)
    _CW("============================================" & @CRLF)
    _CW("  Installation Summary" & @CRLF)
    _CW("============================================" & $g_cRst & @CRLF)

    ; Drivers run after apps+config; by the time the report runs, drivers are complete.
    _CW($g_cGrn  & "  [OK]   Windows Update (Drivers) : Done" & $g_cRst & @CRLF)
    _CW($g_cGrn  & "  [OK]   Installed       : " & $iInstalled & $g_cRst & @CRLF)
    _CW($g_cDim  & "  [---]  Already present : " & $iAlready   & $g_cRst & @CRLF)
    _CW($g_cRed  & "  [FAIL] Failed          : " & $iFailed    & $g_cRst & @CRLF)
    _CW($g_cYlw  & "  [DIS]  Disabled        : " & $iDisabled  & $g_cRst & @CRLF)
    If $iPending > 0 Then
        _CW($g_cYlw & "  [???]  Still pending   : " & $iPending & $g_cRst & @CRLF)
    EndIf

    _CW(@CRLF & $g_cDim & "  Per-app status:" & $g_cRst & @CRLF)
    For $i = 0 To UBound($aStatus) - 1
        Local $sName = $aTargets[$i][1]
        Local $iSlash = StringInStr($sName, "/", 0, -1)
        If $iSlash > 0 Then $sName = StringMid($sName, $iSlash + 1)

        Local $sLabel = "", $sColor = $g_cWht
        Switch $aStatus[$i]
            Case 1
                $sLabel = "[OK]   Installed"
                $sColor = $g_cGrn
            Case 2
                $sLabel = "[---]  Already present"
                $sColor = $g_cDim
            Case 0
                $sLabel = "[FAIL] FAILED"
                $sColor = $g_cRed
            Case 3
                $sLabel = "[DIS]  Disabled"
                $sColor = $g_cYlw
            Case -1
                $sLabel = "[???]  Pending"
                $sColor = $g_cYlw
        EndSwitch
        _CW("    " & $g_cDim & StringFormat("%-40s", $sName) & $g_cRst & $sColor & " " & $sLabel & $g_cRst & @CRLF)
    Next
    _CW(@CRLF)
EndFunc

Func _ConsolePause()
    _CW(@CRLF & $g_cDim & "--------------------------------------------" & $g_cRst & @CRLF)
    _CW($g_cWht & "  Press Enter to close this window..." & $g_cRst & @CRLF)
    Local $hStdin = FileOpen("CONIN$", 0)
    FileReadLine($hStdin)
    FileClose($hStdin)
    If $g_hConOut <> -1 Then
        FileClose($g_hConOut)
        $g_hConOut = -1
    EndIf
EndFunc

; ════════════════════════════════════════════════════════════════════════════════
;  CONFIGURATION & UTILITIES  (logic unchanged from original)
; ════════════════════════════════════════════════════════════════════════════════

Func _LoadConfiguration($sConfigPath, ByRef $aTargets, ByRef $iMaxIteration)
    If Not FileExists($sConfigPath) Then Return False

    Local $sContent = FileRead($sConfigPath)
    If @error Then Return False

    Local $aMaxIter = StringRegExp($sContent, "(?im)^\s*max_iteration\s*=\s*(\d+)\s*;", 1)
    If @error Or UBound($aMaxIter) <> 1 Then Return False
    $iMaxIteration = Int($aMaxIter[0])

    Local $aLogPath = StringRegExp($sContent, "(?im)^\s*log_path\s*=\s*([^;\r\n]+)\s*;", 1)
    If Not @error And UBound($aLogPath) = 1 Then _InitializeLog(_ToWindowsPath($aLogPath[0]))

    Local $aClean = StringRegExp($sContent, "(?im)^\s*clean_after_installing\s*=\s*(true|false)\s*;", 1)
    If Not @error And UBound($aClean) = 1 Then $g_sCleanFonts = StringLower($aClean[0])

    Local $aMatches = StringRegExp($sContent, '(?im)^\s*(\d+)\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*(true|false)\s*,\s*(true|false)\s*;', 3)
    If @error Or UBound($aMatches) = 0 Or Mod(UBound($aMatches), 5) <> 0 Then Return False

    Local $iTargetCount = UBound($aMatches) / 5
    ReDim $aTargets[$iTargetCount][5]
    Local $iMatch = 0
    For $i = 0 To $iTargetCount - 1
        For $j = 0 To 4
            $aTargets[$i][$j] = $aMatches[$iMatch]
            $iMatch += 1
        Next
    Next

    ; Sort by configured index, then reject duplicate indexes.
    For $i = 0 To $iTargetCount - 2
        For $j = $i + 1 To $iTargetCount - 1
            If Int($aTargets[$j][0]) < Int($aTargets[$i][0]) Then
                For $k = 0 To 4
                    Local $sSwap = $aTargets[$i][$k]
                    $aTargets[$i][$k] = $aTargets[$j][$k]
                    $aTargets[$j][$k] = $sSwap
                Next
            EndIf
        Next
    Next

    For $i = 1 To $iTargetCount - 1
        If Int($aTargets[$i - 1][0]) = Int($aTargets[$i][0]) Then Return False
    Next

    Return True
EndFunc

Func _InitializeLog($sLogPath)
    If $sLogPath = "" Then Return
    Local $sDir = StringLeft($sLogPath, StringInStr($sLogPath, "\", 0, -1) - 1)
    If $sDir <> "" Then DirCreate($sDir)
    $g_sLogPath = $sLogPath
EndFunc

Func _WriteLog($sLevel, $sMessage)
    Local $sDir = StringLeft($g_sLogPath, StringInStr($g_sLogPath, "\", 0, -1) - 1)
    If $sDir <> "" Then DirCreate($sDir)
    Local $hLog = FileOpen($g_sLogPath, $FO_APPEND + $FO_UTF8_NOBOM + $FO_CREATEPATH)
    If $hLog = -1 Then Return
    FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & $sLevel & "] " & $sMessage)
    FileClose($hLog)
EndFunc

Func _ResolveTargetPath($sRelativePath)
    Return $g_sRoot & "\" & StringReplace(StringStripWS($sRelativePath, 3), "/", "\")
EndFunc

Func _ToWindowsPath($sPath)
    Return StringReplace(StringStripWS($sPath, 3), "/", "\")
EndFunc

Func _FindSoftwareRoot()
    If FileExists(@ScriptDir & "\" & $g_sMarkerFile) Then Return @ScriptDir

    Local $aDrives = DriveGetDrive("ALL")
    If @error Then Return ""
    For $i = 1 To $aDrives[0]
        Local $sCandidate = $aDrives[$i] & "\" & $g_sMarkerFile
        If FileExists($sCandidate) Then Return $aDrives[$i]
    Next
    Return ""
EndFunc

Func _IsAdministrator()
    Local $aResult = DllCall("shell32.dll", "bool", "IsUserAnAdmin")
    Return IsArray($aResult) And $aResult[0]
EndFunc
