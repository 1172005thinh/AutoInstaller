; Version: v0.1.2
; Author: 1172005thinh

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Generic Java installer.
; $CmdLine[1] = setup filename (e.g. "java-8u441.exe", "java.exe") [optional, fallback "java.exe"]
; $CmdLine[2] = desktop shortcut flag ("true"/"false")            [optional, fallback false]
; $CmdLine[4] = log path                                          [optional, fallback "C:\Auto-installer\install-apps.log"]
;
; Detection: dynamically inspects JavaSoft, Eclipse Adoptium, and OpenJDK registry hives
; across 64-bit and 32-bit locations, with filesystem search fallbacks across Program Files.

Global $g_sSetupFilename = "java.exe"
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

_Log("INFO: Checking if app is already installed...")
If _IsJavaInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

_Log("INFO: Starting installation...")
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" /s', @ScriptDir, @SW_HIDE)
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
If _WaitForJava(900) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _GetJavaHome()
    Local $aRoots[2] = ["HKLM64", "HKLM"]
    Local $aKeys[4]  = ["SOFTWARE\JavaSoft\Java Runtime Environment", "SOFTWARE\JavaSoft\Java Development Kit", "SOFTWARE\JavaSoft\JDK", "SOFTWARE\Eclipse Adoptium\JDK"]

    For $iR = 0 To UBound($aRoots) - 1
        For $iK = 0 To UBound($aKeys) - 1
            Local $sBase = $aRoots[$iR] & "\" & $aKeys[$iK]
            Local $sCurrentVer = RegRead($sBase, "CurrentVersion")
            If Not @error And $sCurrentVer <> "" Then
                Local $sHome = RegRead($sBase & "\" & $sCurrentVer, "JavaHome")
                If StringRight($sHome, 1) = "\" Then $sHome = StringTrimRight($sHome, 1)
                If FileExists($sHome & "\bin\java.exe") Then Return $sHome
            EndIf

            ; Enumerate subkeys under this key
            Local $iSub = 1
            While 1
                Local $sSubKey = RegEnumKey($sBase, $iSub)
                If @error Then ExitLoop
                Local $sHomeSub = RegRead($sBase & "\" & $sSubKey, "JavaHome")
                If StringRight($sHomeSub, 1) = "\" Then $sHomeSub = StringTrimRight($sHomeSub, 1)
                If FileExists($sHomeSub & "\bin\java.exe") Then Return $sHomeSub
                $iSub += 1
            WEnd
        Next
    Next

    ; Filesystem Search Fallbacks
    Local $aSearchPaths[4] = [@ProgramFilesDir & "\Java", @ProgramFilesDir & " (x86)\Java", @ProgramFilesDir & "\Eclipse Adoptium", @ProgramFilesDir & "\Common Files\Oracle\Java\javapath"]
    For $iP = 0 To UBound($aSearchPaths) - 1
        Local $sPath = $aSearchPaths[$iP]
        If FileExists($sPath & "\bin\java.exe") Then Return $sPath
        If FileExists($sPath & "\java.exe") Then Return $sPath

        Local $hSearch = FileFindFirstFile($sPath & "\*")
        If $hSearch <> -1 Then
            While 1
                Local $sFile = FileFindNextFile($hSearch)
                If @error Then ExitLoop
                Local $sCandidate = $sPath & "\" & $sFile
                If FileExists($sCandidate & "\bin\java.exe") Then
                    FileClose($hSearch)
                    Return $sCandidate
                EndIf
            WEnd
            FileClose($hSearch)
        EndIf
    Next

    If FileExists(@WindowsDir & "\System32\java.exe") Then Return @WindowsDir & "\System32"
    Return ""
EndFunc

Func _IsJavaInstalled()
    Return (_GetJavaHome() <> "")
EndFunc

Func _WaitForJava($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsJavaInstalled() Then Return True
        Sleep(1000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sJavaHome = _GetJavaHome()
    If $sJavaHome = "" Then Return

    ; Check for javaws.exe (Java Web Start in Java 8)
    Local $sTarget = $sJavaHome & "\bin\javaws.exe"
    If Not FileExists($sTarget) Then $sTarget = $sJavaHome & "\javaws.exe"
    If Not FileExists($sTarget) Then Return ; Modern Java (9+) does not include Java Web Start

    Local $sLink = "C:\Users\Public\Desktop\Java Web Start.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sJavaHome & "\bin", "", "Java Web Start", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
