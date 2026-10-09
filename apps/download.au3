;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     apps/download.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Includes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once
#include <InetConstants.au3>
#include <FileConstants.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Path Resolvers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func downloadGetAppsDir()
    If FileExists(@ScriptDir & "\config.ini") And FileExists(@ScriptDir & "\install.au3") Then
        Return @ScriptDir
    ElseIf FileExists(@ScriptDir & "\apps\config.ini") Then
        Return @ScriptDir & "\apps"
    EndIf
    Return @ScriptDir & "\apps"
EndFunc

Func downloadGetConfigPath()
    Return downloadGetAppsDir() & "\config.ini"
EndFunc

Func downloadGetManifestPath()
    Return downloadGetAppsDir() & "\manifest.json"
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Download Operations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func downloadGetAppSetupPath($sAppId)
    Local $sConfig = downloadGetConfigPath()
    Local $sSetupFile = IniRead($sConfig, $sAppId, "setup_file", "")
    If $sSetupFile = "" Then Return ""
    Return downloadGetAppsDir() & "\" & $sAppId & "\" & $sSetupFile
EndFunc

Func downloadIsAppReady($sAppId)
    Local $sPath = downloadGetAppSetupPath($sAppId)
    If $sPath = "" Then Return False
    Return FileExists($sPath)
EndFunc

Func downloadGetAppVersion($sAppId)
    Local $sPath = downloadGetAppSetupPath($sAppId)
    If $sPath = "" Or Not FileExists($sPath) Then
        Local $sCfgVer = IniRead(downloadGetConfigPath(), $sAppId, "version", "")
        If $sCfgVer <> "" Then Return $sCfgVer
        Return "Unknown"
    EndIf

    ; Attempt reading PE file version
    Local $sVer = FileGetVersion($sPath)
    If $sVer <> "" And $sVer <> "0.0.0.0" Then Return $sVer

    ; Fallback to config version
    Local $sConfigVer = IniRead(downloadGetConfigPath(), $sAppId, "version", "")
    If $sConfigVer <> "" Then Return $sConfigVer

    Return "Unknown"
EndFunc

Func downloadApp($sAppId, $bOverwrite = True, $hProgressCallback = 0)
    Local $sConfig = downloadGetConfigPath()
    Local $sUrl = IniRead($sConfig, $sAppId, "url", "")
    Local $sSetupFile = IniRead($sConfig, $sAppId, "setup_file", "")

    If $sUrl = "" Or $sSetupFile = "" Then Return False

    Local $sAppDir = downloadGetAppsDir() & "\" & $sAppId
    If Not FileExists($sAppDir) Then DirCreate($sAppDir)

    Local $sDestPath = $sAppDir & "\" & $sSetupFile
    If FileExists($sDestPath) And Not $bOverwrite Then
        If $hProgressCallback <> 0 Then Call($hProgressCallback, 100, 1, 1)
        Return True
    EndIf

    ; Start background non-blocking download
    Local $hDownload = InetGet($sUrl, $sDestPath, BitOR($INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND), 1)
    If @error Or $hDownload = 0 Then Return False

    Local $iPercent = 0
    While Not InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
        Local $iBytes = InetGetInfo($hDownload, $INET_DOWNLOADREAD)
        Local $iSize = InetGetInfo($hDownload, $INET_DOWNLOADSIZE)

        If $iSize > 0 Then
            $iPercent = Int(($iBytes / $iSize) * 100)
            If $iPercent > 100 Then $iPercent = 100
        Else
            $iPercent = 0
        EndIf

        If $hProgressCallback <> 0 Then Call($hProgressCallback, $iPercent, $iBytes, $iSize)
        Sleep(50)
    WEnd

    Local $bSuccess = InetGetInfo($hDownload, $INET_DOWNLOADSUCCESS)
    InetClose($hDownload)

    If $bSuccess And FileExists($sDestPath) And FileGetSize($sDestPath) > 0 Then
        If $hProgressCallback <> 0 Then Call($hProgressCallback, 100, FileGetSize($sDestPath), FileGetSize($sDestPath))
        Return True
    Else
        If FileExists($sDestPath) Then FileDelete($sDestPath)
        If $hProgressCallback <> 0 Then Call($hProgressCallback, 0, 0, 0)
        Return False
    EndIf
EndFunc

Func downloadUpdateManifest($sManifestContent = "")
    Local $sManifestPath = downloadGetManifestPath()
    Local $sContent = $sManifestContent

    If $sContent = "" Then
        ; Read from local manifest.json
        If FileExists($sManifestPath) Then
            Local $hFile = FileOpen($sManifestPath, BitOR($FO_READ, $FO_UTF8_NOBOM))
            If $hFile <> -1 Then
                $sContent = FileRead($hFile)
                FileClose($hFile)
            EndIf
        EndIf
    EndIf

    If $sContent = "" Then Return 0

    Local $sConfig = downloadGetConfigPath()
    Local $aSections = IniReadSectionNames($sConfig)
    If @error Then Return 0

    Local $iUpdatedCount = 0
    For $i = 1 To $aSections[0]
        Local $sApp = $aSections[$i]
        If $sApp = "Configuration" Then ContinueLoop

        ; Match "AppId": { "version": "...", "url": "..." }
        Local $sPattern = '(?s)"' & $sApp & '"\s*:\s*\{[^}]*"version"\s*:\s*"([^"]+)"[^}]*"url"\s*:\s*"([^"]+)"'
        Local $aMatch = StringRegExp($sContent, $sPattern, 1)
        If Not @error And UBound($aMatch) >= 2 Then
            Local $sNewVer = $aMatch[0]
            Local $sNewUrl = $aMatch[1]
            Local $sCurUrl = IniRead($sConfig, $sApp, "url", "")
            Local $sCurVer = IniRead($sConfig, $sApp, "version", "")

            Local $bChanged = False
            If $sNewUrl <> "" And $sNewUrl <> $sCurUrl Then
                IniWrite($sConfig, $sApp, "url", $sNewUrl)
                $bChanged = True
            EndIf
            If $sNewVer <> "" And $sNewVer <> $sCurVer Then
                IniWrite($sConfig, $sApp, "version", $sNewVer)
                $bChanged = True
            EndIf

            If $bChanged Then $iUpdatedCount += 1
        EndIf
    Next

    Return $iUpdatedCount
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Standalone CLI Entry Point
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

If @ScriptName = "download.au3" Then
    If $CmdLine[0] >= 1 Then
        Local $sTarget = StringLower($CmdLine[1])
        If $sTarget = "update" Then
            Local $iUpdated = downloadUpdateManifest()
            ConsoleWrite("Updated " & $iUpdated & " application entries." & @CRLF)
        ElseIf $sTarget = "all" Then
            Local $sConfig = downloadGetConfigPath()
            Local $aSections = IniReadSectionNames($sConfig)
            If Not @error Then
                For $i = 1 To $aSections[0]
                    If $aSections[$i] = "Configuration" Then ContinueLoop
                    ConsoleWrite("Downloading " & $aSections[$i] & "..." & @CRLF)
                    downloadApp($aSections[$i], True)
                Next
            EndIf
        Else
            ConsoleWrite("Downloading " & $CmdLine[1] & "..." & @CRLF)
            downloadApp($CmdLine[1], True)
        EndIf
    EndIf
EndIf
