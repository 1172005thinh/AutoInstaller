#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon
#include <AutoItConstants.au3>

; Kaspersky antivirus installer.
; $CmdLine[1] = setup filename (e.g. "kaspersky.exe")
; $CmdLine[2] = desktop shortcut flag ("true"/"false")
; $CmdLine[4] = log path                                [optional, fallback "C:\Auto-installer\install-apps.log"]
;
; Detection: dynamically enumerates KasperskyLab registry hives across all versions,
; checks the Windows AVP service registration, and inspects Kaspersky installation directories.

Global $g_sSetupFilename = "kaspersky.exe"
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
If _IsKasperskyInstalled() Then
    _Log("INFO: App is already installed. Exiting with code 10.")
    _CreateDesktopShortcut()
    Exit 10
EndIf

; Kaspersky silent install flags
_Log("INFO: Starting installation...")
Local $iExitCode = RunWait('"' & $g_sSetupPath & '" EULA=1 PRIVACYPOLICY=1 /s /pSKIPPRODUCTCHECK=1', @ScriptDir, @SW_HIDE)
_Log("INFO: Installer finished with exit code: " & $iExitCode)
If @error Then
    _Log("ERROR: RunWait failed with AutoIt error: " & @error)
    Exit 21
EndIf

; Kaspersky may return 0 quickly while background install continues
Sleep(10000)

_Log("INFO: Waiting for app to be fully registered...")
If _WaitForKaspersky(300) Then
    _Log("INFO: Installation confirmed. Exiting with code 0.")
    _CreateDesktopShortcut()
    Exit 0
EndIf
_Log("ERROR: Installation validation timed out.")
Exit 22

Func _GetKasperskyExecutable()
    Local $aRoots[2] = ["HKLM64", "HKLM"]

    ; 1. Enumerate all subkeys under KasperskyLab
    For $iR = 0 To UBound($aRoots) - 1
        Local $sBase = $aRoots[$iR] & "\SOFTWARE\KasperskyLab"
        Local $iKey = 1
        While 1
            Local $sSubKey = RegEnumKey($sBase, $iKey)
            If @error Then ExitLoop
            Local $sSubPath = $sBase & "\" & $sSubKey
            
            ; Try ProductInstallDir under Environment or directly
            Local $aValNames[3] = ["ProductInstallDir", "InstallPath", "InstallDir"]
            For $iV = 0 To UBound($aValNames) - 1
                Local $sDir = RegRead($sSubPath & "\Environment", $aValNames[$iV])
                If @error Or $sDir = "" Then $sDir = RegRead($sSubPath, $aValNames[$iV])
                If Not @error And $sDir <> "" Then
                    If StringRight($sDir, 1) = "\" Then $sDir = StringTrimRight($sDir, 1)
                    If FileExists($sDir & "\avpui.exe") Then Return $sDir & "\avpui.exe"
                    If FileExists($sDir & "\avp.exe") Then Return $sDir & "\avp.exe"
                EndIf
            Next
            $iKey += 1
        WEnd
    Next

    ; 2. Enumerate Uninstall registry keys for Kaspersky
    For $iR = 0 To UBound($aRoots) - 1
        Local $sUninstBase = $aRoots[$iR] & "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
        Local $iU = 1
        While 1
            Local $sUKey = RegEnumKey($sUninstBase, $iU)
            If @error Then ExitLoop
            Local $sDisplay = RegRead($sUninstBase & "\" & $sUKey, "DisplayName")
            If Not @error And StringInStr($sDisplay, "Kaspersky") > 0 Then
                Local $sLoc = RegRead($sUninstBase & "\" & $sUKey, "InstallLocation")
                If StringRight($sLoc, 1) = "\" Then $sLoc = StringTrimRight($sLoc, 1)
                If FileExists($sLoc & "\avpui.exe") Then Return $sLoc & "\avpui.exe"
                If FileExists($sLoc & "\avp.exe") Then Return $sLoc & "\avp.exe"
            EndIf
            $iU += 1
        WEnd
    Next

    ; 3. Filesystem search
    Local $aProgramPaths[2] = [@ProgramFilesDir & "\Kaspersky Lab", @ProgramFilesDir & " (x86)\Kaspersky Lab"]
    For $iP = 0 To UBound($aProgramPaths) - 1
        Local $sKDir = $aProgramPaths[$iP]
        If FileExists($sKDir & "\avpui.exe") Then Return $sKDir & "\avpui.exe"
        Local $hSearch = FileFindFirstFile($sKDir & "\*")
        If $hSearch <> -1 Then
            While 1
                Local $sFolder = FileFindNextFile($hSearch)
                If @error Then ExitLoop
                If FileExists($sKDir & "\" & $sFolder & "\avpui.exe") Then
                    FileClose($hSearch)
                    Return $sKDir & "\" & $sFolder & "\avpui.exe"
                EndIf
                If FileExists($sKDir & "\" & $sFolder & "\avp.exe") Then
                    FileClose($hSearch)
                    Return $sKDir & "\" & $sFolder & "\avp.exe"
                EndIf
            WEnd
            FileClose($hSearch)
        EndIf
    Next

    ; 4. Service check
    Local $sSvc = RegRead("HKLM64\SYSTEM\CurrentControlSet\Services\AVP", "ImagePath")
    If Not @error And $sSvc <> "" Then
        $sSvc = StringReplace($sSvc, '"', '')
        If FileExists($sSvc) Then Return $sSvc
    EndIf

    Return ""
EndFunc

Func _IsKasperskyInstalled()
    Return (_GetKasperskyExecutable() <> "")
EndFunc

Func _WaitForKaspersky($iTimeoutSeconds)
    Local $hTimer = TimerInit()
    While TimerDiff($hTimer) < $iTimeoutSeconds * 1000
        If _IsKasperskyInstalled() Then Return True
        Sleep(5000)
    WEnd
    Return False
EndFunc

Func _CreateDesktopShortcut()
    If Not $g_bShortcut Then Return
    Local $sTarget = _GetKasperskyExecutable()
    If $sTarget = "" Or Not FileExists($sTarget) Then Return
    
    Local $iSlash = StringInStr($sTarget, "\", 0, -1)
    Local $sDir = StringLeft($sTarget, $iSlash - 1)
    Local $sLink = "C:\Users\Public\Desktop\Kaspersky.lnk"
    If FileExists($sLink) Then Return
    FileCreateShortcut($sTarget, $sLink, $sDir, "", "Kaspersky", $sTarget, "", 0, @SW_SHOW)
EndFunc

Func _Log($sMsg)
    Local $sLogPath = $g_sLogPath
    Local $hLog = FileOpen($sLogPath, 1 + 256) ; FO_APPEND (1) + FO_UTF8_NOBOM (256)
    If $hLog <> -1 Then
        FileWriteLine($hLog, "[" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & StringReplace($g_sSetupFilename, ".exe", "") & "] " & $sMsg)
        FileClose($hLog)
    EndIf
EndFunc
