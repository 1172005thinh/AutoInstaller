;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     apps/run.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#RequireAdmin
#AutoIt3Wrapper_UseX64=y

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Includes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once
#include <AutoItConstants.au3>
#include <FileConstants.au3>
#include <Array.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Globals
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $g_sAppsDir = ""
Global $g_sConfigPath = ""
Global $g_iMaxThreads = 4
Global $g_iMaxIteration = 2
Global $g_sLogPath = "C:\AutoInstaller\apps.log"

Func _InitEnvironment()
    If FileExists(@ScriptDir & "\config.ini") Then
        $g_sAppsDir = @ScriptDir
    ElseIf FileExists(@ScriptDir & "\apps\config.ini") Then
        $g_sAppsDir = @ScriptDir & "\apps"
    Else
        $g_sAppsDir = @ScriptDir
    EndIf

    $g_sConfigPath = $g_sAppsDir & "\config.ini"

    If FileExists($g_sConfigPath) Then
        $g_iMaxThreads = Int(IniRead($g_sConfigPath, "Configuration", "max_threads", "4"))
        If $g_iMaxThreads < 1 Then $g_iMaxThreads = 1

        $g_iMaxIteration = Int(IniRead($g_sConfigPath, "Configuration", "max_iteration", "2"))
        If $g_iMaxIteration < 1 Then $g_iMaxIteration = 1

        Local $sLog = IniRead($g_sConfigPath, "Configuration", "log_path", "")
        If $sLog <> "" Then $g_sLogPath = $sLog
    EndIf
EndFunc

Func _LogRunner($sMsg)
    Local $sDir = StringLeft($g_sLogPath, StringInStr($g_sLogPath, "\", 0, -1) - 1)
    If $sDir <> "" And Not FileExists($sDir) Then DirCreate($sDir)

    Local $hFile = FileOpen($g_sLogPath, BitOR($FO_APPEND, $FO_UTF8_NOBOM, $FO_CREATEPATH))
    If $hFile = -1 Then Return

    Local $sTS = @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & _
                 StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & ":" & StringFormat("%02d", @SEC)
    FileWriteLine($hFile, "[" & $sTS & "] [Runner] " & $sMsg)
    FileClose($hFile)
    ConsoleWrite("[" & $sTS & "] [Runner] " & $sMsg & @CRLF)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Target Queue Builder
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Target schema: [AppId, SetupPath, Wizard, Args, Shortcut, Retries, IsMSI, Status]
; Status: "pending", "running", "success", "already", "failed"

Func _BuildTargetQueue()
    Local $aSections = IniReadSectionNames($g_sConfigPath)
    If @error Then Return 0

    Local $aQueue[UBound($aSections)][8]
    Local $iCount = 0

    For $i = 1 To $aSections[0]
        Local $sApp = $aSections[$i]
        If $sApp = "Configuration" Then ContinueLoop

        Local $sInstall = StringLower(IniRead($g_sConfigPath, $sApp, "install", "false"))
        If $sInstall <> "true" Then ContinueLoop

        Local $sSetupFile = IniRead($g_sConfigPath, $sApp, "setup_file", "")
        Local $sSetupPath = $g_sAppsDir & "\" & $sApp & "\" & $sSetupFile
        Local $sWizard = StringLower(IniRead($g_sConfigPath, $sApp, "wizard", ""))
        Local $sArgs = IniRead($g_sConfigPath, $sApp, "args", "")
        Local $sShortcut = StringLower(IniRead($g_sConfigPath, $sApp, "shortcut", "false"))

        Local $bIsMSI = ($sWizard = "msi" Or StringRegExp($sSetupPath, '(?i)\.msi$'))

        $aQueue[$iCount][0] = $sApp
        $aQueue[$iCount][1] = $sSetupPath
        $aQueue[$iCount][2] = $sWizard
        $aQueue[$iCount][3] = $sArgs
        $aQueue[$iCount][4] = $sShortcut
        $aQueue[$iCount][5] = 0        ; Retries
        $aQueue[$iCount][6] = $bIsMSI  ; IsMSI
        $aQueue[$iCount][7] = "pending"
        $iCount += 1
    Next

    If $iCount = 0 Then Return 0
    ReDim $aQueue[$iCount][8]
    Return $aQueue
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Process Pool Orchestrator
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _RunTargetQueue(ByRef $aQueue)
    Local $iTotal = UBound($aQueue, 1)
    If $iTotal = 0 Then
        _LogRunner("No applications selected for installation.")
        Return
    EndIf

    _LogRunner("Starting installation orchestrator: " & $iTotal & " application(s) queued. Concurrency: " & $g_iMaxThreads)

    Local $sInstallScript = $g_sAppsDir & "\install.au3"
    Local $sAutoItExe = @AutoItExe
    If Not FileExists($sAutoItExe) Then $sAutoItExe = @ScriptDir & "\..\tools\AutoIt\AutoIt3_x64.exe"
    If Not FileExists($sAutoItExe) Then $sAutoItExe = "AutoIt3.exe"

    ; Active workers: 2D array [PID, TargetIndex, IsMSI, StartTime]
    Local $aActive[16][4]
    Local $iActiveCount = 0
    Local $bActiveMSI = False

    Local $iFinishedCount = 0

    While $iFinishedCount < $iTotal
        ; Check running worker processes
        Local $iActiveIdx = 0
        While $iActiveIdx < $iActiveCount
            Local $iPID = $aActive[$iActiveIdx][0]
            Local $iTargetIdx = $aActive[$iActiveIdx][1]
            Local $bJobIsMSI = $aActive[$iActiveIdx][2]

            If Not ProcessExists($iPID) Then
                ; Process completed
                _LogRunner("Completed: " & $aQueue[$iTargetIdx][0] & " (PID " & $iPID & ")")
                $aQueue[$iTargetIdx][7] = "success"
                $iFinishedCount += 1

                If $bJobIsMSI Then $bActiveMSI = False

                ; Remove from active array
                For $k = $iActiveIdx To $iActiveCount - 2
                    $aActive[$k][0] = $aActive[$k + 1][0]
                    $aActive[$k][1] = $aActive[$k + 1][1]
                    $aActive[$k][2] = $aActive[$k + 1][2]
                    $aActive[$k][3] = $aActive[$k + 1][3]
                Next
                $iActiveCount -= 1
            Else
                $iActiveIdx += 1
            EndIf
        WEnd

        ; Spawn new workers up to concurrency limit
        While $iActiveCount < $g_iMaxThreads
            Local $iNextJob = -1

            ; Find next eligible pending job
            For $j = 0 To $iTotal - 1
                If $aQueue[$j][7] = "pending" Then
                    ; MSI serialization check: do not start an MSI job if another MSI is currently active
                    If $aQueue[$j][6] And $bActiveMSI Then
                        ContinueLoop
                    EndIf
                    $iNextJob = $j
                    ExitLoop
                EndIf
            Next

            If $iNextJob = -1 Then ExitLoop ; No eligible jobs ready right now

            ; Launch worker
            Local $sApp = $aQueue[$iNextJob][0]
            Local $sSetup = $aQueue[$iNextJob][1]
            Local $sWiz = $aQueue[$iNextJob][2]
            Local $sArgs = $aQueue[$iNextJob][3]
            Local $sSc = $aQueue[$iNextJob][4]
            Local $bIsMSI = $aQueue[$iNextJob][6]

            Local $sCmd = '"' & $sAutoItExe & '" "' & $sInstallScript & '" "' & $sApp & '" "' & $sSetup & '" "' & $sSc & '" "' & $g_sLogPath & '" "' & $sWiz & '" "' & $sArgs & '"'
            _LogRunner("Spawning installer: " & $sApp & " (MSI=" & $bIsMSI & ")")

            Local $iNewPID = Run($sCmd, $g_sAppsDir, @SW_HIDE)
            If $iNewPID = 0 Then
                _LogRunner("ERROR: Failed to spawn process for " & $sApp)
                $aQueue[$iNextJob][7] = "failed"
                $iFinishedCount += 1
            Else
                $aQueue[$iNextJob][7] = "running"
                If $iActiveCount >= UBound($aActive) Then ReDim $aActive[$iActiveCount * 2][4]
                $aActive[$iActiveCount][0] = $iNewPID
                $aActive[$iActiveCount][1] = $iNextJob
                $aActive[$iActiveCount][2] = $bIsMSI
                $aActive[$iActiveCount][3] = TimerInit()
                $iActiveCount += 1

                If $bIsMSI Then $bActiveMSI = True
            EndIf
        WEnd

        Sleep(250)
    WEnd

    ; Report Summary
    _LogRunner("============================================")
    _LogRunner("  Application Installation Summary")
    _LogRunner("============================================")
    Local $iSuccess = 0, $iFailed = 0
    For $m = 0 To $iTotal - 1
        If $aQueue[$m][7] = "success" Then
            $iSuccess += 1
            _LogRunner("  [OK]   " & $aQueue[$m][0])
        Else
            $iFailed += 1
            _LogRunner("  [FAIL] " & $aQueue[$m][0])
        EndIf
    Next
    _LogRunner("Completed: " & $iSuccess & " succeeded, " & $iFailed & " failed.")
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Entry Point
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_InitEnvironment()
Local $aQueue = _BuildTargetQueue()
If IsArray($aQueue) Then
    _RunTargetQueue($aQueue)
Else
    _LogRunner("No applications configured for installation.")
EndIf
