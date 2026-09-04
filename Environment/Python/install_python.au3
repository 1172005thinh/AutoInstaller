; Version: v0.1.2
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic Python installer.
; $CmdLine[1] = setup filename (e.g. "python-3.14.7.exe", "python.exe") [optional, fallback "python.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")                   [optional, fallback false]
; $CmdLine[4] = log path                                                 [optional, fallback "C:\Auto-installer\install-apps.log"]
;
; The installer dynamically inspects the registry (HKLM64, HKCU64, HKLM, HKCU) under
; SOFTWARE\Python\PythonCore for installed versions, parses ExecutablePath and InstallPath,
; and falls back to filesystem searches in Program Files / AppData. Works reliably with
; any Python version (3.14.2, 3.14.7, 3.15, etc.) regardless of setup filename.

Global $g_sSetupFilename = "python.exe"
If $CmdLine[0] >= 1 Then $g_sSetupFilename = $CmdLine[1]
Global Const $g_sSetupPath = @ScriptDir & "\" & $g_sSetupFilename

Global $g_bShortcut = False
Global $g_sLogPath = "C:\Auto-installer\install-apps.log"
If $CmdLine[0] >= 4 Then $g_sLogPath = $CmdLine[4]
If $CmdLine[0] >= 2 And StringLower($CmdLine[2]) = "true" Then $g_bShortcut = True

; Optionally derive major.minor (e.g. "3.14") and folder suffix (e.g. "314") from filename if present
Global $g_sPyMajorMinor = ""
Global $g_sPyDirSuffix  = ""
Local $aVer = StringRegExp($g_sSetupFilename, "(?:python-)?(\d+)\.(\d+)", 1)
If Not @error And UBound($aVer) = 2 Then
    $g_sPyMajorMinor = $aVer[0] & "." & $aVer[1]   ; e.g. "3.14"
    $g_sPyDirSuffix  = $aVer[0] & $aVer[1]          ; e.g. "314"
EndIf

If Not FileExists($g_sSetupPath) Then
    _Log("ERROR: Setup file not found: " & $g_sSetupPath)
    Exit 20
EndIf

_Log("INFO: Checking if app is already installed...")
If _IsPythonInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation...")
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=1', @ScriptDir, @SW_HIDE)
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
If _WaitForPython(120) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _GetInstalledPythonPath(ByRef $sInstallDir, ByRef $sExePath, ByRef $sWindowedExe, ByRef $sVersion)
    Local $aRoots[4] = ["HKLM64", "HKCU64", "HKLM", "HKCU"]

    ; 1. If major.minor was matched from filename, query it directly across roots
    If $g_sPyMajorMinor <> "" Then
        For $iR = 0 To UBound($aRoots) - 1
            Local $sBase = $aRoots[$iR] & "\SOFTWARE\Python\PythonCore\" & $g_sPyMajorMinor
            Local $sExe = RegRead($sBase & "\InstallPath", "ExecutablePath")
            If Not @error And FileExists($sExe) Then
                $sExePath = $sExe
                $sInstallDir = RegRead($sBase & "\InstallPath", "")
                If StringRight($sInstallDir, 1) = "\" Then $sInstallDir = StringTrimRight($sInstallDir, 1)
                $sWindowedExe = RegRead($sBase & "\InstallPath", "WindowedExecutablePath")
                If @error Or Not FileExists($sWindowedExe) Then $sWindowedExe = $sInstallDir & "\pythonw.exe"
                $sVersion = $g_sPyMajorMinor
                Return True
            EndIf
            
            Local $sDir = RegRead($sBase & "\InstallPath", "")
            If Not @error And $sDir <> "" Then
                If StringRight($sDir, 1) = "\" Then $sDir = StringTrimRight($sDir, 1)
                If FileExists($sDir & "\python.exe") Then
                    $sInstallDir = $sDir
                    $sExePath = $sDir & "\python.exe"
                    $sWindowedExe = $sDir & "\pythonw.exe"
                    $sVersion = $g_sPyMajorMinor
                    Return True
                EndIf
            EndIf
        Next
    EndIf

    ; 2. Enumerate all versions under SOFTWARE\Python\PythonCore across roots
    For $iR = 0 To UBound($aRoots) - 1
        Local $iKey = 1
        While 1
            Local $sSubKey = RegEnumKey($aRoots[$iR] & "\SOFTWARE\Python\PythonCore", $iKey)
            If @error Then ExitLoop
            Local $sBase = $aRoots[$iR] & "\SOFTWARE\Python\PythonCore\" & $sSubKey
            
            Local $sExe = RegRead($sBase & "\InstallPath", "ExecutablePath")
            If Not @error And FileExists($sExe) Then
                $sExePath = $sExe
                $sInstallDir = RegRead($sBase & "\InstallPath", "")
                If StringRight($sInstallDir, 1) = "\" Then $sInstallDir = StringTrimRight($sInstallDir, 1)
                $sWindowedExe = RegRead($sBase & "\InstallPath", "WindowedExecutablePath")
                If @error Or Not FileExists($sWindowedExe) Then $sWindowedExe = $sInstallDir & "\pythonw.exe"
                $sVersion = $sSubKey
                Return True
            EndIf

            Local $sDir = RegRead($sBase & "\InstallPath", "")
            If Not @error And $sDir <> "" Then
                If StringRight($sDir, 1) = "\" Then $sDir = StringTrimRight($sDir, 1)
                If FileExists($sDir & "\python.exe") Then
                    $sInstallDir = $sDir
                    $sExePath = $sDir & "\python.exe"
                    $sWindowedExe = $sDir & "\pythonw.exe"
                    $sVersion = $sSubKey
                    Return True
                EndIf
            EndIf
            $iKey += 1
        WEnd
    Next

    ; 3. Filesystem fallback: Program Files & AppData
    If $g_sPyDirSuffix <> "" And FileExists(@ProgramFilesDir & "\Python" & $g_sPyDirSuffix & "\python.exe") Then
        $sInstallDir = @ProgramFilesDir & "\Python" & $g_sPyDirSuffix
        $sExePath = $sInstallDir & "\python.exe"
        $sWindowedExe = $sInstallDir & "\pythonw.exe"
        $sVersion = $g_sPyMajorMinor
        Return True
    EndIf

    ; Search for any Python3* directory under @ProgramFilesDir
    Local $hSearch = FileFindFirstFile(@ProgramFilesDir & "\Python3*")
    If $hSearch <> -1 Then
        While 1
            Local $sFile = FileFindNextFile($hSearch)
            If @error Then ExitLoop
            If FileExists(@ProgramFilesDir & "\" & $sFile & "\python.exe") Then
                $sInstallDir = @ProgramFilesDir & "\" & $sFile
                $sExePath = $sInstallDir & "\python.exe"
                $sWindowedExe = $sInstallDir & "\pythonw.exe"
                $sVersion = StringReplace($sFile, "Python", "")
                FileClose($hSearch)
                Return True
            EndIf
        WEnd
        FileClose($hSearch)
    EndIf

    Return False
EndFunc

Func _IsPythonInstalled()
    Local $sDir = "", $sExe = "", $sWinExe = "", $sVer = ""
    Return _GetInstalledPythonPath($sDir, $sExe, $sWinExe, $sVer)
EndFunc

Func _WaitForPython($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsPythonInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sDir = "", $sExe = "", $sWinExe = "", $sVer = ""
    If Not _GetInstalledPythonPath($sDir, $sExe, $sWinExe, $sVer) Then Return

    If Not FileExists($sWinExe) Then $sWinExe = $sDir & "\pythonw.exe"
    If Not FileExists($sWinExe) Then $sWinExe = $sExe
    If Not FileExists($sWinExe) Then Return

    Local $sTitleVer = $sVer
    If $sTitleVer = "" Then $sTitleVer = $g_sPyMajorMinor
    If $sTitleVer = "" Then $sTitleVer = "3"

    Local $sLink = "C:\Users\Public\Desktop\IDLE (Python " & $sTitleVer & ").lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sWinExe, $sLink, $sDir, "-m idlelib", "IDLE (Python " & $sTitleVer & ")", $sWinExe, "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
