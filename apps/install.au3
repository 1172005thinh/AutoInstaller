;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     apps/install.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#RequireAdmin
#AutoIt3Wrapper_UseX64=y
#NoTrayIcon

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Includes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once
#include <AutoItConstants.au3>
#include <FileConstants.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration & Parameters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; CLI Signature:
; $CmdLine[1] = App identifier (e.g. "7z", "Git") OR Setup file path
; $CmdLine[2] = Setup file path (optional if provided in CmdLine[1] or config.ini)
; $CmdLine[3] = Desktop shortcut flag ("true"/"false", default "false")
; $CmdLine[4] = Log path (default "C:\AutoInstaller\apps.log")
; $CmdLine[5] = Wizard type override ("nsis", "inno", "msi", "archive", "custom")
; $CmdLine[6] = Silent arguments override

Global $g_sAppId = ""
Global $g_sSetupPath = ""
Global $g_bShortcut = False
Global $g_sLogPath = "C:\AutoInstaller\apps.log"
Global $g_sWizardType = ""
Global $g_sSilentArgs = ""

Func _SuperInstallerInit()
    If $CmdLine[0] >= 1 Then $g_sAppId = $CmdLine[1]

    ; Check if CmdLine[1] is directly an executable file path
    If FileExists($g_sAppId) And (StringInStr($g_sAppId, "\") > 0 Or StringInStr($g_sAppId, "/") > 0) Then
        $g_sSetupPath = $g_sAppId
        ; Extract app folder/name from path
        Local $aParts = StringSplit(StringReplace($g_sAppId, "/", "\"), "\")
        If $aParts[0] >= 2 Then
            $g_sAppId = $aParts[$aParts[0] - 1]
        Else
            $g_sAppId = StringRegExpReplace($aParts[$aParts[0]], "\.[^.]+$", "")
        EndIf
    EndIf

    If $CmdLine[0] >= 2 And $CmdLine[2] <> "" Then $g_sSetupPath = $CmdLine[2]
    If $CmdLine[0] >= 3 And StringLower($CmdLine[3]) = "true" Then $g_bShortcut = True
    If $CmdLine[0] >= 4 And $CmdLine[4] <> "" Then $g_sLogPath = $CmdLine[4]
    If $CmdLine[0] >= 5 And $CmdLine[5] <> "" Then $g_sWizardType = StringLower($CmdLine[5])
    If $CmdLine[0] >= 6 Then $g_sSilentArgs = $CmdLine[6]

    ; Read from config.ini if AppId is known
    Local $sConfig = _GetConfigPath()
    If $g_sAppId <> "" And FileExists($sConfig) Then
        If $g_sSetupPath = "" Then
            Local $sSetupFile = IniRead($sConfig, $g_sAppId, "setup_file", "")
            If $sSetupFile <> "" Then
                $g_sSetupPath = _GetAppsDir() & "\" & $g_sAppId & "\" & $sSetupFile
                If Not FileExists($g_sSetupPath) And FileExists(@ScriptDir & "\" & $sSetupFile) Then
                    $g_sSetupPath = @ScriptDir & "\" & $sSetupFile
                EndIf
            EndIf
        EndIf

        If $g_sWizardType = "" Then
            $g_sWizardType = StringLower(IniRead($sConfig, $g_sAppId, "wizard", ""))
        EndIf

        If $g_sSilentArgs = "" Then
            $g_sSilentArgs = IniRead($sConfig, $g_sAppId, "args", "")
        EndIf

        If $CmdLine[0] < 3 Then
            Local $sCfgSc = IniRead($sConfig, $g_sAppId, "shortcut", "false")
            If StringLower($sCfgSc) = "true" Then $g_bShortcut = True
        EndIf

        Local $sCfgLog = IniRead($sConfig, "Configuration", "log_path", "")
        If $CmdLine[0] < 4 And $sCfgLog <> "" Then $g_sLogPath = $sCfgLog
    EndIf
EndFunc

Func _GetAppsDir()
    If FileExists(@ScriptDir & "\config.ini") Then Return @ScriptDir
    If FileExists(@ScriptDir & "\apps\config.ini") Then Return @ScriptDir & "\apps"
    Return @ScriptDir
EndFunc

Func _GetConfigPath()
    Return _GetAppsDir() & "\config.ini"
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Logging
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _Log($sMsg)
    Local $sDir = StringLeft($g_sLogPath, StringInStr($g_sLogPath, "\", 0, -1) - 1)
    If $sDir <> "" And Not FileExists($sDir) Then DirCreate($sDir)

    Local $hFile = FileOpen($g_sLogPath, BitOR($FO_APPEND, $FO_UTF8_NOBOM, $FO_CREATEPATH))
    If $hFile = -1 Then Return

    Local $sTag = ($g_sAppId <> "") ? "[" & $g_sAppId & "] " : ""
    Local $sTS = @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & _
                 StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & ":" & StringFormat("%02d", @SEC)

    FileWriteLine($hFile, "[" & $sTS & "] " & $sTag & $sMsg)
    FileClose($hFile)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Auto-Detection of Wizard Engine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _DetectWizardType($sPath)
    If StringRegExp($sPath, '(?i)\.msi$') Then Return "msi"
    If StringRegExp($sPath, '(?i)\.(zip|7z|tar\.gz)$') Then Return "archive"

    ; Check if dedicated custom script is present
    Local $sCustomScript = _GetAppsDir() & "\" & $g_sAppId & "\install.au3"
    If FileExists($sCustomScript) And ($g_sAppId = "Fonts" Or $g_sAppId = "MicrosoftOffice" Or $g_sAppId = "VCRedist") Then
        Return "custom"
    EndIf

    ; Default to inno/nsis/custom based on known app
    Return "custom"
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Installation Dispatcher
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _RunInstallation()
    If Not FileExists($g_sSetupPath) And $g_sAppId <> "Fonts" Then
        _Log("ERROR: Setup file not found: " & $g_sSetupPath)
        Exit 20
    EndIf

    If $g_sWizardType = "" Then
        $g_sWizardType = _DetectWizardType($g_sSetupPath)
    EndIf

    _Log("INFO: Starting installation of " & $g_sAppId & " (Type: " & $g_sWizardType & ", Path: " & $g_sSetupPath & ")")

    Local $iExitCode = 0

    Switch $g_sWizardType
        Case "nsis"
            Local $sCmd = '"' & $g_sSetupPath & '" ' & ($g_sSilentArgs <> "" ? $g_sSilentArgs : "/S")
            _Log("INFO: Executing NSIS installer: " & $sCmd)
            $iExitCode = RunWait($sCmd, @TempDir, @SW_HIDE)

        Case "inno"
            Local $sArgs = ($g_sSilentArgs <> "" ? $g_sSilentArgs : "/VERYSILENT /NORESTART /SP- /CLOSEAPPLICATIONS")
            Local $sCmd = '"' & $g_sSetupPath & '" ' & $sArgs
            _Log("INFO: Executing Inno Setup installer: " & $sCmd)
            $iExitCode = RunWait($sCmd, @TempDir, @SW_HIDE)

        Case "msi"
            Local $sArgs = ($g_sSilentArgs <> "" ? $g_sSilentArgs : "/qn /norestart")
            Local $sCmd = 'msiexec.exe /i "' & $g_sSetupPath & '" ' & $sArgs
            _Log("INFO: Executing MSI installer: " & $sCmd)
            $iExitCode = RunWait($sCmd, @TempDir, @SW_HIDE)

        Case "archive"
            $iExitCode = _InstallArchive($g_sSetupPath)

        Case "custom"
            ; Check if there is an app-specific custom script
            Local $sCustomScript = _GetAppsDir() & "\" & $g_sAppId & "\install.au3"
            If FileExists($sCustomScript) Then
                _Log("INFO: Delegating to custom app installer script: " & $sCustomScript)
                Local $sAutoItExe = @AutoItExe
                If Not FileExists($sAutoItExe) Then $sAutoItExe = @ScriptDir & "\..\tools\AutoIt\AutoIt3_x64.exe"
                If Not FileExists($sAutoItExe) Then $sAutoItExe = "AutoIt3.exe"

                Local $sCmd = '"' & $sAutoItExe & '" "' & $sCustomScript & '" "' & $g_sSetupPath & '" "' & ($g_bShortcut ? "true" : "false") & '" "false" "' & $g_sLogPath & '"'
                $iExitCode = RunWait($sCmd, _GetAppsDir() & "\" & $g_sAppId, @SW_HIDE)
            Else
                ; Direct execution with configured silent args
                Local $sCmd = '"' & $g_sSetupPath & '" ' & $g_sSilentArgs
                _Log("INFO: Executing custom binary directly: " & $sCmd)
                $iExitCode = RunWait($sCmd, @TempDir, @SW_HIDE)
            EndIf

        Case Else
            Local $sCmd = '"' & $g_sSetupPath & '" ' & $g_sSilentArgs
            _Log("INFO: Executing binary with default args: " & $sCmd)
            $iExitCode = RunWait($sCmd, @TempDir, @SW_HIDE)
    EndSwitch

    If @error Then
        _Log("ERROR: RunWait failed with AutoIt error: " & @error)
        Exit 21
    EndIf

    _Log("INFO: Installer process completed with exit code: " & $iExitCode)

    If $iExitCode = 0 Or $iExitCode = 3010 Then
        _Log("INFO: Installation successful. Creating shortcuts if enabled.")
        _CreateAppShortcut()
        Exit 0
    ElseIf $iExitCode = 10 Then
        _Log("INFO: Application is already installed (code 10).")
        _CreateAppShortcut()
        Exit 10
    Else
        _Log("ERROR: Installer returned failure exit code: " & $iExitCode)
        Exit $iExitCode
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Archive Extraction Helper
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _InstallArchive($sArchivePath)
    Local $sDestDir = @ProgramFilesDir & "\" & $g_sAppId
    If Not FileExists($sDestDir) Then DirCreate($sDestDir)

    Local $s7zExe = @ProgramFilesDir & "\7-Zip\7z.exe"
    If Not FileExists($s7zExe) Then $s7zExe = _GetAppsDir() & "\7z\7z.exe"

    If FileExists($s7zExe) Then
        Local $sCmd = '"' & $s7zExe & '" x -y -o"' & $sDestDir & '" "' & $sArchivePath & '"'
        _Log("INFO: Extracting archive via 7-Zip: " & $sCmd)
        Local $iRes = RunWait($sCmd, @TempDir, @SW_HIDE)
        Return $iRes
    Else
        ; Windows tar fallback
        Local $sCmd = 'tar -xf "' & $sArchivePath & '" -C "' & $sDestDir & '"'
        _Log("INFO: Extracting archive via tar: " & $sCmd)
        Local $iRes = RunWait($sCmd, @TempDir, @SW_HIDE)
        Return $iRes
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Desktop Shortcut Creator
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _CreateAppShortcut()
    If Not $g_bShortcut Then Return

    Local $sDesktop = "C:\Users\Public\Desktop"
    If Not FileExists($sDesktop) Then $sDesktop = @DesktopCommonDir

    Local $sTarget = ""
    Local $sLinkName = $g_sAppId & ".lnk"

    ; App-specific shortcut target lookup
    Switch $g_sAppId
        Case "7z"
            $sTarget = @ProgramFilesDir & "\7-Zip\7zFM.exe"
            $sLinkName = "7-Zip File Manager.lnk"
        Case "Brave"
            $sTarget = @ProgramFilesDir & "\BraveSoftware\Brave-Browser\Application\brave.exe"
            $sLinkName = "Brave.lnk"
        Case "Discord"
            $sTarget = @LocalAppDataDir & "\Discord\Update.exe"
            $sLinkName = "Discord.lnk"
        Case "Git"
            $sTarget = @ProgramFilesDir & "\Git\git-bash.exe"
            $sLinkName = "Git Bash.lnk"
        Case "GoogleChrome"
            $sTarget = @ProgramFilesDir & "\Google\Chrome\Application\chrome.exe"
            $sLinkName = "Google Chrome.lnk"
        Case "MPC-HC"
            $sTarget = @ProgramFilesDir & "\MPC-HC\mpc-hc64.exe"
            $sLinkName = "MPC-HC x64.lnk"
        Case "Notepad++"
            $sTarget = @ProgramFilesDir & "\Notepad++\notepad++.exe"
            $sLinkName = "Notepad++.lnk"
        Case "OBS"
            $sTarget = @ProgramFilesDir & "\obs-studio\bin\64bit\obs64.exe"
            $sLinkName = "OBS Studio.lnk"
        Case "PotPlayer"
            $sTarget = @ProgramFilesDir & "\DAUM\PotPlayer\PotPlayer64.exe"
            $sLinkName = "PotPlayer 64 bit.lnk"
        Case "qBittorrent"
            $sTarget = @ProgramFilesDir & "\qBittorrent\qbittorrent.exe"
            $sLinkName = "qBittorrent.lnk"
        Case "Unikey"
            $sTarget = @ProgramFilesDir & "\UniKey\UniKeyNT.exe"
            $sLinkName = "UniKey NT.lnk"
        Case "VLC"
            $sTarget = @ProgramFilesDir & "\VideoLAN\VLC\vlc.exe"
            $sLinkName = "VLC media player.lnk"
        Case "VSCode"
            $sTarget = @ProgramFilesDir & "\Microsoft VS Code\Code.exe"
            $sLinkName = "Visual Studio Code.lnk"
        Case "WinRAR"
            $sTarget = @ProgramFilesDir & "\WinRAR\WinRAR.exe"
            $sLinkName = "WinRAR.lnk"
        Case "Zalo"
            $sTarget = @LocalAppDataDir & "\Programs\Zalo\Zalo.exe"
            $sLinkName = "Zalo.lnk"
        Case Else
            If FileExists(@ProgramFilesDir & "\" & $g_sAppId & "\" & $g_sAppId & ".exe") Then
                $sTarget = @ProgramFilesDir & "\" & $g_sAppId & "\" & $g_sAppId & ".exe"
            EndIf
    EndSwitch

    If $sTarget <> "" And FileExists($sTarget) Then
        Local $sLink = $sDesktop & "\" & $sLinkName
        Local $sWorkDir = StringLeft($sTarget, StringInStr($sTarget, "\", 0, -1) - 1)
        FileCreateShortcut($sTarget, $sLink, $sWorkDir, "", $g_sAppId, $sTarget, "", 0, @SW_SHOW)
        _Log("INFO: Created desktop shortcut: " & $sLink)
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Execution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_SuperInstallerInit()
_RunInstallation()
