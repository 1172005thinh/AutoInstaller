;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/modules/apps.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Libraries
#include <FileConstants.au3>

; Modules
#include "i18n.au3"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Path Resolution & Tool Discovery
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Resolves canonical path to apps/config.ini
Func appsGetConfigPath()
    If FileExists(@ScriptDir & "\apps\config.ini") Then Return @ScriptDir & "\apps\config.ini"
    If FileExists(@ScriptDir & "\config.ini") Then Return @ScriptDir & "\config.ini"
    Return @ScriptDir & "\apps\config.ini"
EndFunc

; Resolves path to Chocolatey CLI executable if present
Func appsGetChocoPath()
    If FileExists(@ScriptDir & "\tools\Chocolatey\choco.exe") Then Return @ScriptDir & "\tools\Chocolatey\choco.exe"
    If FileExists(@ScriptDir & "\..\tools\Chocolatey\choco.exe") Then Return @ScriptDir & "\..\tools\Chocolatey\choco.exe"
    Local $sSysChoco = @SystemDir & "\choco.exe"
    If FileExists($sSysChoco) Then Return $sSysChoco
    Return "choco.exe"
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Application Catalog & Metadata
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Retrieves localized description for a standard catalog application
Func appsGetAppDesc($sAppId, $sDefault = "")
    Switch $sAppId
        Case "7z"
            Return i18nGet("apps.desc.7z", "High compression ratio file archiver")
        Case "Brave"
            Return i18nGet("apps.desc.Brave", "Privacy-focused Chromium web browser")
        Case "Discord"
            Return i18nGet("apps.desc.Discord", "Voice, video, and text communication platform")
        Case "Docker"
            Return i18nGet("apps.desc.Docker", "Container runtime and development platform")
        Case "Git"
            Return i18nGet("apps.desc.Git", "Distributed version control system")
        Case "GoogleChrome"
            Return i18nGet("apps.desc.GoogleChrome", "Fast and secure web browser by Google")
        Case "Java"
            Return i18nGet("apps.desc.Java", "Java Platform Standard Edition runtime environment")
        Case "Kaspersky"
            Return i18nGet("apps.desc.Kaspersky", "Antivirus and internet security suite")
        Case "LibreOffice"
            Return i18nGet("apps.desc.LibreOffice", "Free and open source office suite")
        Case "MicrosoftOffice"
            Return i18nGet("apps.desc.MicrosoftOffice", "Microsoft Office deployment package")
        Case "MPC-HC"
            Return i18nGet("apps.desc.MPC-HC", "Lightweight open source media player")
        Case "MSYS2"
            Return i18nGet("apps.desc.MSYS2", "Software distribution and building platform for Windows")
        Case "Notepad++"
            Return i18nGet("apps.desc.Notepad++", "Extensible source code editor and text replacement tool")
        Case "OBS"
            Return i18nGet("apps.desc.OBS", "Free and open source software for video recording and live streaming")
        Case "PotPlayer"
            Return i18nGet("apps.desc.PotPlayer", "Feature-rich multimedia player with hardware acceleration")
        Case "Python"
            Return i18nGet("apps.desc.Python", "Python programming language runtime and environment")
        Case "qBittorrent"
            Return i18nGet("apps.desc.qBittorrent", "Free and reliable BitTorrent client")
        Case "Shell"
            Return i18nGet("apps.desc.Shell", "Context menu customizer for Windows File Explorer")
        Case "Tailscale"
            Return i18nGet("apps.desc.Tailscale", "Zero config VPN built on WireGuard")
        Case "TeamViewer"
            Return i18nGet("apps.desc.TeamViewer", "Remote desktop access and support tool")
        Case "UltraViewer"
            Return i18nGet("apps.desc.UltraViewer", "Remote support software for Windows")
        Case "Unikey"
            Return i18nGet("apps.desc.Unikey", "Vietnamese keyboard input method editor")
        Case "VCRedist"
            Return i18nGet("apps.desc.VCRedist", "All-in-one package for Microsoft Visual C++ Runtimes (2005-2022)")
        Case "VisualStudio"
            Return i18nGet("apps.desc.VisualStudio", "Integrated development environment by Microsoft")
        Case "VLC"
            Return i18nGet("apps.desc.VLC", "Cross-platform multimedia player and framework")
        Case "VSCode"
            Return i18nGet("apps.desc.VSCode", "Source-code editor made by Microsoft")
        Case "WinRAR"
            Return i18nGet("apps.desc.WinRAR", "Powerful archiver and archive manager")
        Case "WireGuard"
            Return i18nGet("apps.desc.WireGuard", "Fast, modern, and secure VPN tunnel")
        Case "yt-dlp"
            Return i18nGet("apps.desc.yt-dlp", "Command-line audio and video download tool")
        Case "Zalo"
            Return i18nGet("apps.desc.Zalo", "Instant messaging and social networking app")
        Case Else
            Return $sDefault
    EndSwitch
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Package Search Engine (Winget & Fallback)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Searches available software packages from WinGet repository with curated fallback
Func appsSearchPackages($sQuery)
    Local $aResults[0][5] ; [Name, Id, Manager, Desc, Versions]
    If StringStripWS($sQuery, 3) = "" Then Return $aResults

    ; Curated Catalog with rich descriptions and version options
    Local $aCatalog[11][5] = [ _
        ["Git", "Git.Git", "winget", "Fast, scalable, distributed revision control system", "Latest|2.55.0|2.54.0|2.53.0"], _
        ["Google Chrome", "Google.Chrome", "winget", "Fast and secure web browser by Google", "Latest"], _
        ["Visual Studio Code", "Microsoft.VisualStudioCode", "winget", "Code editing redefined by Microsoft", "Latest|1.94.0|1.93.0"], _
        ["7-Zip", "7zip.7zip", "winget", "High compression ratio file archiver", "Latest|24.08|23.01"], _
        ["Discord", "Discord.Discord", "winget", "Voice, video and text communication service", "Latest"], _
        ["VLC media player", "VideoLAN.VLC", "winget", "Free and open source cross-platform multimedia player", "Latest|3.0.21|3.0.20"], _
        ["Notepad++", "Notepad++.Notepad++", "winget", "Free source code editor and Notepad replacement", "Latest|8.7.0|8.6.9"], _
        ["Python 3.12", "Python.Python.3.12", "winget", "High-level programming language with dynamic semantics", "Latest|3.12.7|3.12.6"], _
        ["Docker Desktop", "Docker.DockerDesktop", "winget", "Container application development platform", "Latest|4.35.0|4.34.0"], _
        ["Brave Browser", "Brave.Brave", "winget", "Privacy-oriented browser blocking trackers and ads", "Latest"], _
        ["Zalo", "VNGCorp.Zalo", "winget", "Instant messaging and social networking app", "Latest|26.10.20"] _
    ]

    ; 1. Query WinGet Repository
    Local $sWingetOut = @TempDir & "\winget_search_" & @AutoItPID & ".txt"
    If FileExists($sWingetOut) Then FileDelete($sWingetOut)

    Local $iExit = RunWait(@ComSpec & ' /c chcp 65001 >nul & winget search "' & $sQuery & '" --accept-source-agreements > "' & $sWingetOut & '"', @SystemDir, @SW_HIDE)
    If $iExit = 0 And FileExists($sWingetOut) Then
        Local $hFile = FileOpen($sWingetOut, BitOR($FO_READ, $FO_UTF8_NOBOM))
        If $hFile <> -1 Then
            Local $sText = FileRead($hFile)
            FileClose($hFile)
            FileDelete($sWingetOut)

            Local $aLines = StringSplit(StringStripCR($sText), @LF)
            Local $iHeaderLine = -1
            Local $iSepLine = -1

            For $i = 1 To $aLines[0]
                If StringInStr($aLines[$i], "---") Then
                    $iSepLine = $i
                    $iHeaderLine = $i - 1
                    ExitLoop
                EndIf
            Next

            If $iHeaderLine > 0 Then
                Local $sHeader = $aLines[$iHeaderLine]
                Local $iIdPos = StringInStr($sHeader, "Id")
                Local $iVerPos = StringInStr($sHeader, "Version")
                Local $iMatchPos = StringInStr($sHeader, "Match")
                Local $iSourcePos = StringInStr($sHeader, "Source")

                Local $iNextPos = -1
                If $iMatchPos > $iVerPos Then $iNextPos = $iMatchPos
                If $iSourcePos > $iVerPos And ($iNextPos = -1 Or $iSourcePos < $iNextPos) Then $iNextPos = $iSourcePos

                For $j = $iSepLine + 1 To $aLines[0]
                    Local $sLine = $aLines[$j]
                    If StringStripWS($sLine, 3) = "" Then ContinueLoop

                    Local $sPkgName = ""
                    Local $sPkgId = ""
                    Local $sPkgVer = "Latest"

                    If $iIdPos > 0 Then
                        $sPkgName = StringStripWS(StringLeft($sLine, $iIdPos - 1), 3)
                        If $iVerPos > $iIdPos Then
                            $sPkgId = StringStripWS(StringMid($sLine, $iIdPos, $iVerPos - $iIdPos), 3)
                            If $iNextPos > $iVerPos Then
                                $sPkgVer = StringStripWS(StringMid($sLine, $iVerPos, $iNextPos - $iVerPos), 3)
                            Else
                                $sPkgVer = StringStripWS(StringMid($sLine, $iVerPos), 3)
                            EndIf
                        Else
                            $sPkgId = StringStripWS(StringMid($sLine, $iIdPos), 3)
                        EndIf
                    EndIf

                    If $sPkgName <> "" And $sPkgId <> "" Then
                        Local $sVersions = "Latest"
                        If $sPkgVer <> "" And $sPkgVer <> "Latest" Then $sVersions = "Latest|" & $sPkgVer

                        Local $iCur = UBound($aResults, 1)
                        ReDim $aResults[$iCur + 1][5]
                        $aResults[$iCur][0] = $sPkgName
                        $aResults[$iCur][1] = $sPkgId
                        $aResults[$iCur][2] = "winget"
                        $aResults[$iCur][3] = $sPkgName & " via WinGet"
                        $aResults[$iCur][4] = $sVersions

                        If UBound($aResults, 1) >= 15 Then ExitLoop
                    EndIf
                Next
            EndIf
        EndIf
    EndIf

    ; 2. Fallback to Curated Catalog
    If UBound($aResults, 1) = 0 Then
        For $k = 0 To UBound($aCatalog, 1) - 1
            If StringInStr($aCatalog[$k][0], $sQuery) Or StringInStr($aCatalog[$k][1], $sQuery) Then
                Local $iIdx = UBound($aResults, 1)
                ReDim $aResults[$iIdx + 1][5]
                $aResults[$iIdx][0] = $aCatalog[$k][0]
                $aResults[$iIdx][1] = $aCatalog[$k][1]
                $aResults[$iIdx][2] = $aCatalog[$k][2]
                $aResults[$iIdx][3] = $aCatalog[$k][3]
                $aResults[$iIdx][4] = $aCatalog[$k][4]
            EndIf
        Next
    EndIf

    Return $aResults
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration File Serialization
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Reads and parses applications configuration into a structured dictionary
Func appsLoadConfigData($sFilePath = "")
    Local $sConfig = ($sFilePath <> "" And FileExists($sFilePath)) ? $sFilePath : appsGetConfigPath()
    If Not FileExists($sConfig) Then Return 0

    Local $oD = ObjCreate("Scripting.Dictionary")
    $oD.Item("mode") = Int(IniRead($sConfig, "Configuration", "mode", "3"))
    $oD.Item("fonts_state") = Int(IniRead($sConfig, "Configuration", "fonts_state", "1"))
    $oD.Item("max_iteration") = Int(IniRead($sConfig, "Configuration", "max_iteration", "2"))
    $oD.Item("log_path") = IniRead($sConfig, "Configuration", "log_path", "C:\AutoInstaller\apps.log")

    Return $oD
EndFunc

; Writes application configuration settings to config.ini
Func appsSaveConfigData($sFilePath, $iMode, $iFontsState, $iMaxIter, $sLogPath)
    Local $sBaseConfig = appsGetConfigPath()
    Local $sConfig = $sBaseConfig
    If $sFilePath <> "" Then
        $sConfig = $sFilePath
        If Not FileExists($sConfig) And FileExists($sBaseConfig) Then
            FileCopy($sBaseConfig, $sConfig, $FC_OVERWRITE)
        EndIf
    EndIf
    If Not FileExists($sConfig) And Not FileExists($sBaseConfig) Then Return False

    Local $sDir = StringLeft($sConfig, StringInStr($sConfig, "\", 0, -1) - 1)
    If $sDir <> "" And Not FileExists($sDir) Then DirCreate($sDir)

    IniWrite($sConfig, "Configuration", "mode", String($iMode))
    IniWrite($sConfig, "Configuration", "fonts_state", String($iFontsState))
    IniWrite($sConfig, "Configuration", "max_iteration", String($iMaxIter))
    IniWrite($sConfig, "Configuration", "log_path", String($sLogPath))
    Return True
EndFunc
