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
; $CmdLine[0] = 0 -> Automatic Batch Mode (reads mode and apps from config.ini)
; $CmdLine[1] = App identifier (e.g. "7z", "Git", "Git.Git", "--all", "--batch") OR Setup file path
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
        If $CmdLine[0] < 4 And $sCfgLog <> "" Then
            $sCfgLog = StringReplace($sCfgLog, "/", "\")
            If StringRight($sCfgLog, 1) = "\" Then
                $g_sLogPath = $sCfgLog & "apps.log"
            ElseIf FileExists($sCfgLog) And StringInStr(FileGetAttrib($sCfgLog), "D") Then
                $g_sLogPath = $sCfgLog & "\apps.log"
            Else
                $g_sLogPath = $sCfgLog
            EndIf
        EndIf
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

    Local $sTag = ($g_sAppId <> "") ? "[" & $g_sAppId & "] " : "[Master] "
    Local $sTS = @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & _
                 StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & ":" & StringFormat("%02d", @SEC)

    FileWriteLine($hFile, "[" & $sTS & "] " & $sTag & $sMsg)
    FileClose($hFile)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System & Network Prerequisite Checks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _IsWingetAvailable()
    Local $iExit = RunWait(@ComSpec & " /c winget --version", @SystemDir, @SW_HIDE)
    Return ($iExit = 0)
EndFunc

Func _IsInternetAvailable()
    Local $aCall = DllCall("wininet.dll", "bool", "InternetGetConnectedState", "dword*", 0, "dword", 0)
    If @error Or Not $aCall[0] Then Return False
    Return (Ping("1.1.1.1", 1000) > 0 Or Ping("8.8.8.8", 1000) > 0)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Online Application Installer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _InstallOnlineApp($sId, $sName, $sVersion = "Latest", $sLocation = "Default", $bShortcut = False)
    If Not _IsWingetAvailable() Then
        _Log("WARNING: winget package manager is not available. Skipping online installation for: " & $sName & " (" & $sId & ")")
        Return 0
    EndIf

    If Not _IsInternetAvailable() Then
        _Log("WARNING: No active Internet connection detected. Skipping online installation for: " & $sName & " (" & $sId & ")")
        Return 0
    EndIf

    Local $sCmd = 'winget install --id "' & $sId & '" --exact --silent --accept-package-agreements --accept-source-agreements'
    If $sVersion <> "" And StringLower($sVersion) <> "latest" Then
        $sCmd &= ' --version "' & $sVersion & '"'
    EndIf
    If $sLocation <> "" And StringLower($sLocation) <> "default" Then
        $sCmd &= ' --location "' & $sLocation & '"'
    EndIf

    _Log("INFO: Installing online package: " & $sName & " (" & $sId & ") via winget: " & $sCmd)
    Local $iExitCode = RunWait($sCmd, @TempDir, @SW_HIDE)
    _Log("INFO: winget process completed for " & $sId & " with exit code: " & $iExitCode)

    If ($iExitCode = 0 Or $iExitCode = 3010) Then
        _Log("INFO: Online installation succeeded for " & $sName & ".")
        If $bShortcut Then
            _CreateOnlineShortcut($sName)
        EndIf
        Return 0
    ElseIf $iExitCode = 10 Then
        _Log("INFO: Online package " & $sName & " is already installed (code 10).")
        If $bShortcut Then
            _CreateOnlineShortcut($sName)
        EndIf
        Return 10
    Else
        _Log("ERROR: winget failed for " & $sName & " with exit code: " & $iExitCode)
        Return $iExitCode
    EndIf
EndFunc

Func _CreateOnlineShortcut($sName)
    Local $sDesktop = "C:\Users\Public\Desktop"
    If Not FileExists($sDesktop) Then $sDesktop = @DesktopCommonDir
    If FileExists($sDesktop & "\" & $sName & ".lnk") Then Return

    Local $aStartDirs[2] = [@ProgramsCommonDir, @ProgramsDir]
    For $d = 0 To 1
        Local $hSearch = FileFindFirstFile($aStartDirs[$d] & "\*" & $sName & "*.lnk")
        If $hSearch <> -1 Then
            Local $sFound = FileFindNextFile($hSearch)
            FileClose($hSearch)
            If $sFound <> "" Then
                FileCopy($aStartDirs[$d] & "\" & $sFound, $sDesktop & "\" & $sName & ".lnk", $FC_OVERWRITE)
                _Log("INFO: Created desktop shortcut from Start Menu: " & $sDesktop & "\" & $sName & ".lnk")
                Return
            EndIf
        EndIf
    Next
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Batch Installation Workflows
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _RunOfflineBatch()
    Local $sConfig = _GetConfigPath()
    Local $aSections = IniReadSectionNames($sConfig)
    If @error Or Not IsArray($aSections) Then
        _Log("WARNING: No application sections found in " & $sConfig)
        Return
    EndIf

    For $i = 1 To $aSections[0]
        Local $sApp = $aSections[$i]
        If $sApp = "Configuration" Or StringLeft($sApp, 7) = "Online_" Or $sApp = "Fonts" Then ContinueLoop

        Local $sInstall = StringLower(IniRead($sConfig, $sApp, "install", "false"))
        If $sInstall <> "true" Then ContinueLoop

        Local $sSetupFile = IniRead($sConfig, $sApp, "setup_file", "")
        Local $sSetupPath = _GetAppsDir() & "\" & $sApp & "\" & $sSetupFile
        If Not FileExists($sSetupPath) Then
            If FileExists(@ScriptDir & "\" & $sSetupFile) Then
                $sSetupPath = @ScriptDir & "\" & $sSetupFile
            Else
                _Log("WARNING: Offline setup file not found for " & $sApp & ": " & $sSetupPath & ". Skipping.")
                ContinueLoop
            EndIf
        EndIf

        Local $sWiz = StringLower(IniRead($sConfig, $sApp, "wizard", ""))
        Local $sArgs = IniRead($sConfig, $sApp, "args", "")
        Local $bSc = (StringLower(IniRead($sConfig, $sApp, "shortcut", "false")) = "true")

        _InstallSingleOffline($sApp, $sSetupPath, $sWiz, $sArgs, $bSc)
    Next
EndFunc

Func _RunOnlineBatch()
    Local $sConfig = _GetConfigPath()
    Local $aSections = IniReadSectionNames($sConfig)
    If @error Or Not IsArray($aSections) Then
        _Log("WARNING: No sections found in " & $sConfig)
        Return
    EndIf

    For $i = 1 To $aSections[0]
        Local $sSec = $aSections[$i]
        If StringLeft($sSec, 7) = "Online_" Then
            Local $sInstall = StringLower(IniRead($sConfig, $sSec, "install", "true"))
            If $sInstall <> "true" Then ContinueLoop

            Local $sId = IniRead($sConfig, $sSec, "id", StringTrimLeft($sSec, 7))
            Local $sName = IniRead($sConfig, $sSec, "name", $sId)
            Local $sVer = IniRead($sConfig, $sSec, "version", "Latest")
            Local $sLoc = IniRead($sConfig, $sSec, "location", "Default")
            Local $bSc = (StringLower(IniRead($sConfig, $sSec, "shortcut", "false")) = "true")

            _InstallOnlineApp($sId, $sName, $sVer, $sLoc, $bSc)
        EndIf
    Next
EndFunc

Func _InstallFontsIfConfigured()
    Local $sFontsScript = _GetAppsDir() & "\Fonts\install.au3"
    If FileExists($sFontsScript) Then
        _Log("INFO: Executing Fonts installer script: " & $sFontsScript)
        Local $sAutoItExe = @AutoItExe
        If Not FileExists($sAutoItExe) Then $sAutoItExe = @ScriptDir & "\..\tools\AutoIt\AutoIt3_x64.exe"
        If Not FileExists($sAutoItExe) Then $sAutoItExe = "AutoIt3.exe"
        RunWait('"' & $sAutoItExe & '" "' & $sFontsScript & '" "Fonts" "false" "false" "' & $g_sLogPath & '"', _GetAppsDir() & "\Fonts", @SW_HIDE)
    EndIf
EndFunc

Func _RunBatchInstallation()
    Local $sConfig = _GetConfigPath()
    If Not FileExists($sConfig) Then
        _Log("ERROR: Configuration file not found: " & $sConfig)
        Exit 20
    EndIf

    Local $iMode = Int(IniRead($sConfig, "Configuration", "mode", "2"))
    _Log("INFO: Master apps installation started with configured mode: " & $iMode)

    Switch $iMode
        Case 0 ; Disabled
            _Log("INFO: Apps installation mode is Disabled (0). Skipping all application installations.")
            Exit 0

        Case 1 ; Offline Mode
            _Log("INFO: Running Offline applications installation...")
            _RunOfflineBatch()

        Case 2 ; Online Mode
            _Log("INFO: Running Online applications installation...")
            If Not _IsWingetAvailable() Then
                _Log("WARNING: winget package manager is not available. Skipping online apps installation to proceed to next step.")
                Exit 0
            EndIf

            If Not _IsInternetAvailable() Then
                _Log("WARNING: No active Internet connection detected. Skipping online apps installation to proceed to next step.")
                Exit 0
            EndIf

            _RunOnlineBatch()

        Case Else
            _Log("WARNING: Unrecognized installation mode: " & $iMode & ". Skipping.")
            Exit 0
    EndSwitch

    ; Fonts installation if enabled
    Local $iFontsState = Int(IniRead($sConfig, "Configuration", "fonts_state", "1"))
    If $iFontsState = 1 Then
        _InstallFontsIfConfigured()
    EndIf

    _Log("INFO: Master apps installation completed successfully.")
    Exit 0
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

    ; Default to custom
    Return "custom"
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Offline Installation Dispatcher
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _InstallSingleOffline($sApp, $sPath, $sWiz, $sArgs, $bSc)
    If $sWiz = "" Then $sWiz = _DetectWizardType($sPath)

    _Log("INFO: Starting installation of " & $sApp & " (Type: " & $sWiz & ", Path: " & $sPath & ")")
    Local $iExitCode = 0

    Switch $sWiz
        Case "nsis"
            Local $sCmd = '"' & $sPath & '" ' & ($sArgs <> "" ? $sArgs : "/S")
            _Log("INFO: Executing NSIS installer: " & $sCmd)
            $iExitCode = RunWait($sCmd, @TempDir, @SW_HIDE)

        Case "inno"
            Local $sInnoArgs = ($sArgs <> "" ? $sArgs : "/VERYSILENT /NORESTART /SP- /CLOSEAPPLICATIONS")
            Local $sCmd = '"' & $sPath & '" ' & $sInnoArgs
            _Log("INFO: Executing Inno Setup installer: " & $sCmd)
            $iExitCode = RunWait($sCmd, @TempDir, @SW_HIDE)

        Case "msi"
            Local $sMsiArgs = ($sArgs <> "" ? $sArgs : "/qn /norestart")
            Local $sCmd = 'msiexec.exe /i "' & $sPath & '" ' & $sMsiArgs
            _Log("INFO: Executing MSI installer: " & $sCmd)
            $iExitCode = RunWait($sCmd, @TempDir, @SW_HIDE)

        Case "archive"
            $iExitCode = _InstallArchive($sPath, $sApp)

        Case "custom"
            Local $sCustomScript = _GetAppsDir() & "\" & $sApp & "\install.au3"
            If FileExists($sCustomScript) Then
                _Log("INFO: Delegating to custom app installer script: " & $sCustomScript)
                Local $sAutoItExe = @AutoItExe
                If Not FileExists($sAutoItExe) Then $sAutoItExe = @ScriptDir & "\..\tools\AutoIt\AutoIt3_x64.exe"
                If Not FileExists($sAutoItExe) Then $sAutoItExe = "AutoIt3.exe"

                Local $sCmd = '"' & $sAutoItExe & '" "' & $sCustomScript & '" "' & $sPath & '" "' & ($bSc ? "true" : "false") & '" "false" "' & $g_sLogPath & '"'
                $iExitCode = RunWait($sCmd, _GetAppsDir() & "\" & $sApp, @SW_HIDE)
            Else
                Local $sCmd = '"' & $sPath & '" ' & $sArgs
                _Log("INFO: Executing custom binary directly: " & $sCmd)
                $iExitCode = RunWait($sCmd, @TempDir, @SW_HIDE)
            EndIf

        Case Else
            Local $sCmd = '"' & $sPath & '" ' & $sArgs
            _Log("INFO: Executing binary with default args: " & $sCmd)
            $iExitCode = RunWait($sCmd, @TempDir, @SW_HIDE)
    EndSwitch

    If @error Then
        _Log("ERROR: RunWait failed with AutoIt error: " & @error)
        Return 21
    EndIf

    _Log("INFO: Installer process completed with exit code: " & $iExitCode)

    If $iExitCode = 0 Or $iExitCode = 3010 Then
        _Log("INFO: Installation successful.")
        If $bSc Then _CreateAppShortcutForApp($sApp)
        Return 0
    ElseIf $iExitCode = 10 Then
        _Log("INFO: Application is already installed (code 10).")
        If $bSc Then _CreateAppShortcutForApp($sApp)
        Return 10
    Else
        _Log("ERROR: Installer returned failure exit code: " & $iExitCode)
        Return $iExitCode
    EndIf
EndFunc

Func _RunInstallation()
    If Not FileExists($g_sSetupPath) And $g_sAppId <> "Fonts" Then
        _Log("ERROR: Setup file not found: " & $g_sSetupPath)
        Exit 20
    EndIf

    Local $iExit = _InstallSingleOffline($g_sAppId, $g_sSetupPath, $g_sWizardType, $g_sSilentArgs, $g_bShortcut)
    Exit $iExit
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Archive Extraction Helper
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _InstallArchive($sArchivePath, $sTargetAppId = "")
    If $sTargetAppId = "" Then $sTargetAppId = $g_sAppId
    Local $sDestDir = @ProgramFilesDir & "\" & $sTargetAppId
    If Not FileExists($sDestDir) Then DirCreate($sDestDir)

    Local $s7zExe = @ProgramFilesDir & "\7-Zip\7z.exe"
    If Not FileExists($s7zExe) Then $s7zExe = _GetAppsDir() & "\7z\7z.exe"

    If FileExists($s7zExe) Then
        Local $sCmd = '"' & $s7zExe & '" x -y -o"' & $sDestDir & '" "' & $sArchivePath & '"'
        _Log("INFO: Extracting archive via 7-Zip: " & $sCmd)
        Local $iRes = RunWait($sCmd, @TempDir, @SW_HIDE)
        Return $iRes
    Else
        Local $sCmd = 'tar -xf "' & $sArchivePath & '" -C "' & $sDestDir & '"'
        _Log("INFO: Extracting archive via tar: " & $sCmd)
        Local $iRes = RunWait($sCmd, @TempDir, @SW_HIDE)
        Return $iRes
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Desktop Shortcut Creator
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _CreateAppShortcutForApp($sTargetAppId)
    Local $sDesktop = "C:\Users\Public\Desktop"
    If Not FileExists($sDesktop) Then $sDesktop = @DesktopCommonDir

    Local $sTarget = ""
    Local $sLinkName = $sTargetAppId & ".lnk"

    Switch $sTargetAppId
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
            If FileExists(@ProgramFilesDir & "\" & $sTargetAppId & "\" & $sTargetAppId & ".exe") Then
                $sTarget = @ProgramFilesDir & "\" & $sTargetAppId & "\" & $sTargetAppId & ".exe"
            EndIf
    EndSwitch

    If $sTarget <> "" And FileExists($sTarget) Then
        Local $sLink = $sDesktop & "\" & $sLinkName
        Local $sWorkDir = StringLeft($sTarget, StringInStr($sTarget, "\", 0, -1) - 1)
        FileCreateShortcut($sTarget, $sLink, $sWorkDir, "", $sTargetAppId, $sTarget, "", 0, @SW_SHOW)
        _Log("INFO: Created desktop shortcut: " & $sLink)
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Execution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_SuperInstallerInit()

If $g_sAppId = "" Or $g_sAppId = "--all" Or $g_sAppId = "--batch" Then
    _RunBatchInstallation()
ElseIf StringLeft($g_sAppId, 7) = "Online_" Or (StringInStr($g_sAppId, ".") > 0 And Not FileExists($g_sAppId)) Then
    Local $sConfig = _GetConfigPath()
    Local $sSec = (StringLeft($g_sAppId, 7) = "Online_") ? $g_sAppId : "Online_" & $g_sAppId
    Local $sName = IniRead($sConfig, $sSec, "name", $g_sAppId)
    Local $sVer = IniRead($sConfig, $sSec, "version", "Latest")
    Local $sLoc = IniRead($sConfig, $sSec, "location", "Default")
    Local $iExit = _InstallOnlineApp($g_sAppId, $sName, $sVer, $sLoc, $g_bShortcut)
    Exit $iExit
Else
    _RunInstallation()
EndIf
