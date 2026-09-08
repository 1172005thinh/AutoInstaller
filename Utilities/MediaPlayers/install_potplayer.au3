; Version: v0.1.2
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic PotPlayer installer.
; $CmdLine[1] = setup filename (e.g. "PotPlayerSetup64.exe", "potplayer.exe") [optional, fallback "potplayer.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")                       [optional, fallback false]
; $CmdLine[4] = log path                                                     [optional, fallback "C:\Auto-installer\install-apps.log"]

AutoItSetOption("WinTitleMatchMode", 2)
AutoItSetOption("WinDetectHiddenText", 1)

Global $g_sSetupFilename = "potplayer.exe"
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

_Log("INFO: Checking if PotPlayer is already installed...")
If _IsPotPlayerInstalled() Then 
    _Log("INFO: PotPlayer is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

; Ensure working directories exist
If Not FileExists("C:\Auto-installer") Then DirCreate("C:\Auto-installer")
If Not FileExists(@TempDir) Then DirCreate(@TempDir)

; Register popup handler to automatically detect, log, and dismiss any prompt/error dialogs
AdlibRegister("_HandlePotPlayerPopups", 250)

; PotPlayer NSIS installer command line switches:
;   /S               : Standard NSIS silent install
;   /SkipLang=1      : Bypasses the LangDLL.dll language prompt in .onInit
;   /NoUAC           : Bypasses UAC.dll::RunElevated in .onInit (process is already elevated)
;   /NoRun           : Prevents auto-launching PotPlayer.exe upon completion
;   /NoHomePage      : Prevents modifying browser start page
;   /NoPPI           : Prevents installing promotional partner software/adware
;   /NoFLink         : Prevents creating desktop promotional links
;   /LOG=...         : Requests NSIS install log output if supported
Local $sNSISLog = "C:\Auto-installer\install_potplayer_nsis.log"
Local $sArgs = '/S /SkipLang=1 /NoUAC /NoRun /NoHomePage /NoPPI /NoFLink /LOG="' & $sNSISLog & '"'
_Log("INFO: Starting installation of PotPlayer: " & $g_sSetupPath & " with switches: " & $sArgs)

; Launch with @SW_SHOW so dialogs remain accessible to automation, and capture standard I/O streams
Local $iPID = Run('"' & $g_sSetupPath & '" ' & $sArgs, "C:\Auto-installer", @SW_SHOW, $STDERR_CHILD + $STDOUT_CHILD)
If @error Or Not $iPID Then 
    _Log("ERROR: Run failed with AutoIt error: " & @error)
    AdlibUnRegister("_HandlePotPlayerPopups")
    Exit 21
EndIf

; Monitor installer process with timeout and file detection to prevent hanging
Local $hTimer = TimerInit()
Local $iMaxTimeoutMs = 120 * 1000 ; 120 seconds max timeout
Local $bFilesFound = False

While TimerDiff($hTimer) < $iMaxTimeoutMs
    ; Stream live stdout/stderr from the installer into common log
    _ReadProcessOutput($iPID)

    ; Check if PotPlayer files and executables have been installed to disk
    If _IsPotPlayerInstalled() Then
        $bFilesFound = True
        ; Give 5 seconds for any auxiliary registry writes to complete
        Sleep(5000)
        _ReadProcessOutput($iPID)
        ; If installer process is still lingering (e.g. stuck on OpenCodec download), close it
        If ProcessExists($iPID) Then
            _Log("INFO: PotPlayer files detected on disk. Terminating lingering installer process.")
            ProcessClose($iPID)
        EndIf
        ExitLoop
    EndIf

    ; If installer process finished naturally
    If Not ProcessExists($iPID) Then
        _ReadProcessOutput($iPID)
        _Log("INFO: Installer process exited naturally.")
        ExitLoop
    EndIf

    Sleep(500)
WEnd

; Final flush of process output
_ReadProcessOutput($iPID)

; If timed out while installer process is still running without installing files, close it
If Not $bFilesFound And ProcessExists($iPID) Then
    _Log("WARNING: Installer process exceeded timeout without installing files. Terminating installer PID: " & $iPID)
    ProcessClose($iPID)
EndIf

AdlibUnRegister("_HandlePotPlayerPopups")

; Throw any generated NSIS install logs into the common log file (like install_mpc.au3)
_LogNSISFile($sNSISLog, "[PotPlayer]")
_LogNSISFile(@TempDir & "\install.log", "[PotPlayer]")
_LogNSISFile(@TempDir & "\potplayer.log", "[PotPlayer]")
_LogNSISFile(@ProgramFilesDir & "\DAUM\PotPlayer\install.log", "[PotPlayer]")
Local $sW64Dir = EnvGet("ProgramW6432")
If $sW64Dir <> "" Then _LogNSISFile($sW64Dir & "\DAUM\PotPlayer\install.log", "[PotPlayer]")

; Close any PotPlayer media player processes if auto-launched post-install
If ProcessExists("PotPlayer64.exe") Then ProcessClose("PotPlayer64.exe")
If ProcessExists("PotPlayerMini64.exe") Then ProcessClose("PotPlayerMini64.exe")
If ProcessExists("PotPlayer.exe") Then ProcessClose("PotPlayer.exe")
If ProcessExists("PotPlayerMini.exe") Then ProcessClose("PotPlayerMini.exe")

_Log("INFO: Waiting for PotPlayer to be fully registered...")
If _WaitForPotPlayer(30) Then 
    _Log("INFO: PotPlayer installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf

_Log("ERROR: PotPlayer installation validation timed out.")
Exit 22

Func _ReadProcessOutput($iPID)
    If Not $iPID Then Return
    Local $sStdout = StdoutRead($iPID)
    If $sStdout <> "" Then
        Local $aOutLines = StringSplit(StringStripCR($sStdout), @LF)
        For $j = 1 To $aOutLines[0]
            Local $sLine = StringStripWS($aOutLines[$j], 3)
            If $sLine <> "" Then _Log("[NSIS-STDOUT] " & $sLine)
        Next
    EndIf
    Local $sStderr = StderrRead($iPID)
    If $sStderr <> "" Then
        Local $aErrLines = StringSplit(StringStripCR($sStderr), @LF)
        For $k = 1 To $aErrLines[0]
            Local $sErrLine = StringStripWS($aErrLines[$k], 3)
            If $sErrLine <> "" Then _Log("[NSIS-STDERR] " & $sErrLine)
        Next
    EndIf
EndFunc

Func _LogNSISFile($sNSISPath, $sTag)
    If Not FileExists($sNSISPath) Then Return
    Local $hNSIS = FileOpen($sNSISPath, 0)
    If $hNSIS = -1 Then Return
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256)
    If $hLog <> -1 Then
        While True
            Local $sLine = FileReadLine($hNSIS)
            If @error Then ExitLoop
            Local $sClean = StringStripWS($sLine, 3)
            If $sClean <> "" Then
                FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $sTag & " [NSIS] " & $sClean)
            EndIf
        WEnd
        FileClose($hLog)
    EndIf
    FileClose($hNSIS)
    FileDelete($sNSISPath)
EndFunc

Func _HandlePotPlayerPopups()
    ; Checks, logs, and dismisses any modal or popup dialogs that cause the installer to hang
    Local $aWinList = WinList("[CLASS:#32770]")
    For $i = 1 To $aWinList[0][0]
        Local $hWnd = $aWinList[$i][1]
        If WinExists($hWnd) Then
            Local $sTitle = WinGetTitle($hWnd)
            Local $sText = WinGetText($hWnd)
            Local $sCleanText = StringReplace(StringReplace(StringStripWS($sText, 3), @CR, " "), @LF, " ")
            If StringLen($sCleanText) > 150 Then $sCleanText = StringLeft($sCleanText, 150) & "..."
            
            ; Do NOT dismiss the installer's active file extraction/progress window
            If StringInStr($sCleanText, "being installed") > 0 Or _
               StringInStr($sCleanText, "Please wait") > 0 Or _
               StringInStr($sCleanText, "Copy core files") > 0 Or _
               StringInStr($sCleanText, "Extract:") > 0 Then
                ContinueLoop
            EndIf
            
            _Log("DEBUG: Popup Dialog Detected: Title='" & $sTitle & "', Text='" & $sCleanText & "'")
            
            If StringInStr($sTitle, "Language") > 0 Then
                _Log("ACTION: Language dialog detected. Clicking OK.")
                ControlClick($hWnd, "", "[TEXT:OK]")
                ControlClick($hWnd, "", "Button1")
            ElseIf StringInStr($sCleanText, "admin right") > 0 Or StringInStr($sCleanText, "plug-ins") > 0 Or StringInStr($sTitle, "Error") > 0 Then
                _Log("ACTION: Error dialog detected: '" & $sCleanText & "'. Clicking OK / Close.")
                ControlClick($hWnd, "", "[TEXT:OK]")
                ControlClick($hWnd, "", "Button1")
                WinClose($hWnd)
            Else
                ; For OpenCodec, partner offers, or completion dialogs
                _Log("ACTION: Dismissing prompt window: '" & $sTitle & "'")
                ControlClick($hWnd, "", "[TEXT:Close]")
                ControlClick($hWnd, "", "[TEXT:&Close]")
                ControlClick($hWnd, "", "[TEXT:Cancel]")
                ControlClick($hWnd, "", "[TEXT:&Cancel]")
                ControlClick($hWnd, "", "[TEXT:No]")
                ControlClick($hWnd, "", "[TEXT:&No]")
                ControlClick($hWnd, "", "[TEXT:Finish]")
                ControlClick($hWnd, "", "[TEXT:&Finish]")
                ControlClick($hWnd, "", "[TEXT:OK]")
                WinClose($hWnd)
            EndIf
        EndIf
    Next
EndFunc

Func _GetPotPlayerExe()
    Local $aRoots[3] = ["HKLM64", "HKLM", "HKCU"]
    For $iR = 0 To UBound($aRoots) - 1
        ; 1. Check Uninstall InstallLocation
        Local $sInstallPath = RegRead($aRoots[$iR] & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PotPlayer64", "InstallLocation")
        If @error Or $sInstallPath = "" Then
            $sInstallPath = RegRead($aRoots[$iR] & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PotPlayer", "InstallLocation")
        EndIf
        If Not @error And $sInstallPath <> "" Then
            If StringRight($sInstallPath, 1) = "\" Then $sInstallPath = StringTrimRight($sInstallPath, 1)
            If FileExists($sInstallPath & "\PotPlayer64.exe") Then Return $sInstallPath & "\PotPlayer64.exe"
            If FileExists($sInstallPath & "\PotPlayerMini64.exe") Then Return $sInstallPath & "\PotPlayerMini64.exe"
            If FileExists($sInstallPath & "\PotPlayerMini.exe") Then Return $sInstallPath & "\PotPlayerMini.exe"
            If FileExists($sInstallPath & "\PotPlayer.exe") Then Return $sInstallPath & "\PotPlayer.exe"
        EndIf

        ; 2. Check Uninstall DisplayIcon
        Local $sDisplayIcon = RegRead($aRoots[$iR] & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PotPlayer64", "DisplayIcon")
        If @error Or $sDisplayIcon = "" Then
            $sDisplayIcon = RegRead($aRoots[$iR] & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PotPlayer", "DisplayIcon")
        EndIf
        If Not @error And $sDisplayIcon <> "" Then
            $sDisplayIcon = StringReplace($sDisplayIcon, '"', '')
            Local $iComma = StringInStr($sDisplayIcon, ",")
            If $iComma > 0 Then $sDisplayIcon = StringLeft($sDisplayIcon, $iComma - 1)
            If FileExists($sDisplayIcon) Then Return $sDisplayIcon
        EndIf

        ; 3. Check DAUM ProgramPath
        Local $sProgPath = RegRead($aRoots[$iR] & "\SOFTWARE\DAUM\PotPlayer64", "ProgramPath")
        If @error Or $sProgPath = "" Then
            $sProgPath = RegRead($aRoots[$iR] & "\SOFTWARE\DAUM\PotPlayer", "ProgramPath")
        EndIf
        If Not @error And $sProgPath <> "" Then
            $sProgPath = StringReplace($sProgPath, '"', '')
            If FileExists($sProgPath) Then Return $sProgPath
        EndIf

        ; 4. Check App Paths
        Local $aAppNames[4] = ["PotPlayer64.exe", "PotPlayerMini64.exe", "PotPlayerMini.exe", "PotPlayer.exe"]
        For $iA = 0 To UBound($aAppNames) - 1
            Local $sAppPath = RegRead($aRoots[$iR] & "\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\" & $aAppNames[$iA], "")
            If Not @error And $sAppPath <> "" Then
                $sAppPath = StringReplace($sAppPath, '"', '')
                If FileExists($sAppPath) Then Return $sAppPath
            EndIf
        Next
    Next

    ; 5. Standard Filesystem Paths (64-bit and 32-bit Program Files)
    Local $aDirs[4] = [ _
        @ProgramFilesDir, _
        EnvGet("ProgramW6432"), _
        @ProgramFilesDir & " (x86)", _
        EnvGet("ProgramFiles(x86)") _
    ]
    For $iD = 0 To UBound($aDirs) - 1
        Local $sBase = $aDirs[$iD]
        If $sBase = "" Then ContinueLoop
        If FileExists($sBase & "\DAUM\PotPlayer\PotPlayer64.exe") Then Return $sBase & "\DAUM\PotPlayer\PotPlayer64.exe"
        If FileExists($sBase & "\DAUM\PotPlayer\PotPlayerMini64.exe") Then Return $sBase & "\DAUM\PotPlayer\PotPlayerMini64.exe"
        If FileExists($sBase & "\DAUM\PotPlayer\PotPlayer.exe") Then Return $sBase & "\DAUM\PotPlayer\PotPlayer.exe"
        If FileExists($sBase & "\DAUM\PotPlayer\PotPlayerMini.exe") Then Return $sBase & "\DAUM\PotPlayer\PotPlayerMini.exe"
        If FileExists($sBase & "\DAUM\PotPlayer 64 bit\PotPlayer64.exe") Then Return $sBase & "\DAUM\PotPlayer 64 bit\PotPlayer64.exe"
        If FileExists($sBase & "\Daum\PotPlayer 64 bit\PotPlayer64.exe") Then Return $sBase & "\Daum\PotPlayer 64 bit\PotPlayer64.exe"
        If FileExists($sBase & "\PotPlayer\PotPlayer64.exe") Then Return $sBase & "\PotPlayer\PotPlayer64.exe"
        If FileExists($sBase & "\PotPlayer\PotPlayerMini64.exe") Then Return $sBase & "\PotPlayer\PotPlayerMini64.exe"
        If FileExists($sBase & "\PotPlayer\PotPlayer.exe") Then Return $sBase & "\PotPlayer\PotPlayer.exe"
        If FileExists($sBase & "\PotPlayer\PotPlayerMini.exe") Then Return $sBase & "\PotPlayer\PotPlayerMini.exe"
    Next

    Return ""
EndFunc

Func _IsPotPlayerInstalled()
    Return (_GetPotPlayerExe() <> "")
EndFunc

Func _WaitForPotPlayer($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsPotPlayerInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sTarget = _GetPotPlayerExe()
    If $sTarget = "" Or Not FileExists($sTarget) Then Return

    Local $iSlash = StringInStr($sTarget, "\", 0, -1)
    Local $sDir = StringLeft($sTarget, $iSlash - 1)
    Local $sLink = "C:\Users\Public\Desktop\PotPlayer 64-bit.lnk"
    If StringInStr($sTarget, "64") = 0 Then $sLink = "C:\Users\Public\Desktop\PotPlayer.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "PotPlayer", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [PotPlayer] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
