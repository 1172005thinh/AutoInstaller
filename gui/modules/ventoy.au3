;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/modules/ventoy.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Libraries
#include <FileConstants.au3>
#include <Array.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Path Resolution & Tool Discovery
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Resolves canonical path to ventoy.json
Func ventoyGetJsonPath()
    If FileExists(@ScriptDir & "\tools\Ventoy\AutoInstaller\ventoy.json") Then Return @ScriptDir & "\tools\Ventoy\AutoInstaller\ventoy.json"
    If FileExists(@ScriptDir & "\ventoy.json") Then Return @ScriptDir & "\ventoy.json"
    Return @ScriptDir & "\tools\Ventoy\AutoInstaller\ventoy.json"
EndFunc

; Resolves path to Ventoy theme directory
Func ventoyGetThemeDir()
    If FileExists(@ScriptDir & "\tools\Ventoy\AutoInstaller\theme\1172005thinh") Then Return @ScriptDir & "\tools\Ventoy\AutoInstaller\theme\1172005thinh"
    Return @ScriptDir & "\tools\Ventoy\AutoInstaller\theme\1172005thinh"
EndFunc

; Resolves path to Ventoy theme icons directory
Func ventoyGetIconsDir()
    Local $sDir = ventoyGetThemeDir() & "\icons"
    If FileExists($sDir) Then Return $sDir
    Return $sDir
EndFunc

; Resolves path to VentoyPlugson utility executable
Func ventoyGetPlugsonPath()
    If FileExists(@ScriptDir & "\tools\Ventoy\VentoyPlugson.exe") Then Return @ScriptDir & "\tools\Ventoy\VentoyPlugson.exe"
    If FileExists(@ScriptDir & "\tools\Ventoy\altexe\VentoyPlugson_X64.exe") Then Return @ScriptDir & "\tools\Ventoy\altexe\VentoyPlugson_X64.exe"
    Return @ScriptDir & "\tools\Ventoy\VentoyPlugson.exe"
EndFunc

; Launches VentoyPlugson configuration utility
Func ventoyRunPlugson()
    Local $sPlugson = ventoyGetPlugsonPath()
    If FileExists($sPlugson) Then
        Return ShellExecute($sPlugson, "", @ScriptDir & "\tools\Ventoy") <> 0
    EndIf
    Return False
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Asset Scanners & Catalog
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Returns a pipe-delimited list of available theme icons
Func ventoyGetAvailableIcons()
    Local $sIconsDir = ventoyGetIconsDir()
    Local $sIcons = "windows|default|linux|ubuntu|arch|debian|fedora|android|macos"
    If FileExists($sIconsDir) Then
        Local $hSearch = FileFindFirstFile($sIconsDir & "\*.png")
        If $hSearch <> -1 Then
            Local $aIcons[0]
            While 1
                Local $sFile = FileFindNextFile($hSearch)
                If @error Then ExitLoop
                Local $sName = StringRegExpReplace($sFile, '(?i)\.png$', '')
                If $sName <> "" Then
                    ReDim $aIcons[UBound($aIcons) + 1]
                    $aIcons[UBound($aIcons) - 1] = $sName
                EndIf
            WEnd
            FileClose($hSearch)
            If UBound($aIcons) > 0 Then
                _ArraySort($aIcons)
                $sIcons = _ArrayToString($aIcons, "|")
            EndIf
        EndIf
    EndIf
    Return $sIcons
EndFunc

; Returns a 2D array of available theme variants [Name, Resolutions]
Func ventoyGetVariantsData()
    Local $aNames[6] = ["dark_fb", "dark_gh", "dark_htc", "light_fb", "light_gh", "light_htc"]
    Local $aData[6][2]
    Local $sThemeDir = ventoyGetThemeDir()

    For $i = 0 To 5
        Local $sVar = $aNames[$i]
        $aData[$i][0] = $sVar
        Local $sRes = ""

        If FileExists($sThemeDir) Then
            Local $hSearch = FileFindFirstFile($sThemeDir & "\" & $sVar & "_*.txt")
            If $hSearch <> -1 Then
                While 1
                    Local $sFile = FileFindNextFile($hSearch)
                    If @error Then ExitLoop
                    Local $sR = StringRegExpReplace($sFile, '^' & $sVar & '_|\.txt$', '')
                    If $sR <> "" Then
                        If $sRes <> "" Then $sRes &= "; "
                        $sRes &= $sR
                    EndIf
                WEnd
                FileClose($hSearch)
            EndIf
        EndIf

        If $sRes = "" Then
            $sRes = "1024x768; 1152x864; 1280x720; 1366x768; 1600x1200; 1600x900; 1920x1080; 1920x1200; 2560x1080; 2560x1440; 2560x1600; 3440x1440; 3840x2160; 3840x2400"
        EndIf
        $aData[$i][1] = $sRes
    Next
    Return $aData
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration File Serialization (ventoy.json)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Reads and parses ventoy.json into a structured dictionary
Func ventoyLoadConfigData($sFilePath = "")
    Local $sConfig = ($sFilePath <> "" And FileExists($sFilePath)) ? $sFilePath : ventoyGetJsonPath()
    If Not FileExists($sConfig) Then Return 0

    Local $hFile = FileOpen($sConfig, BitOR($FO_READ, $FO_UTF8_NOBOM))
    If $hFile = -1 Then Return 0
    Local $sJson = FileRead($hFile)
    FileClose($hFile)

    Local $oResult = ObjCreate("Scripting.Dictionary")

    ; 1. Parse Theme
    Local $sThemeSelection = "1172005thinh (Full)"
    Local $sDetectedVariant = "dark_fb"

    If StringInStr($sJson, "/ventoy/theme/1172005thinh/") Then
        Local $aThemeFiles = StringRegExp($sJson, '(?m)"/ventoy/theme/1172005thinh/([^"]+)"', 3)
        If Not @error And UBound($aThemeFiles) > 0 Then
            If UBound($aThemeFiles) > 20 Then
                $sThemeSelection = "1172005thinh (Full)"
            Else
                $sThemeSelection = "1172005thinh (Single)"
                Local $sFirstFile = $aThemeFiles[0]
                Local $aVarMatch = StringRegExp($sFirstFile, '^([a-zA-Z0-9]+_[a-zA-Z0-9]+)_', 1)
                If Not @error Then $sDetectedVariant = $aVarMatch[0]
            EndIf
        EndIf
    ElseIf StringInStr($sJson, "/ventoy/theme/") Or StringInStr($sJson, "theme.txt") Then
        $sThemeSelection = "Ventoy"
    EndIf

    $oResult.Item("Theme") = $sThemeSelection
    $oResult.Item("Variant") = $sDetectedVariant

    ; 2. Parse Boot Entries
    Local $aAliases = StringRegExp($sJson, '(?s)\{\s*"image"\s*:\s*"([^"]+)"\s*,\s*"alias"\s*:\s*"([^"]*)"\s*\}', 4)
    Local $iAliasCount = @error ? 0 : UBound($aAliases)

    Local $aTips = StringRegExp($sJson, '(?s)\{\s*"image"\s*:\s*"([^"]+)"\s*,\s*"tip"\s*:\s*"([^"]*)"\s*\}', 4)
    Local $oTipMap = ObjCreate("Scripting.Dictionary")
    If Not @error Then
        For $i = 0 To UBound($aTips) - 1
            Local $aP = $aTips[$i]
            $oTipMap.Item($aP[1]) = $aP[2]
        Next
    EndIf

    Local $aClasses = StringRegExp($sJson, '(?s)\{\s*"key"\s*:\s*"([^"]+)"\s*,\s*"class"\s*:\s*"([^"]*)"\s*\}', 4)
    Local $oClassMap = ObjCreate("Scripting.Dictionary")
    If Not @error Then
        For $i = 0 To UBound($aClasses) - 1
            Local $aP = $aClasses[$i]
            $oClassMap.Item(StringLower($aP[1])) = $aP[2]
        Next
    EndIf

    Local $aAutoBlocks = StringRegExp($sJson, '(?s)\{\s*"image"\s*:\s*"([^"]+)"\s*,\s*"template"\s*:\s*\[([^\]]*)\](.*?)\}', 4)
    Local $oAutoTplMap = ObjCreate("Scripting.Dictionary")
    Local $oAutoSelMap = ObjCreate("Scripting.Dictionary")
    Local $oAutoTimeoutMap = ObjCreate("Scripting.Dictionary")
    If Not @error Then
        For $i = 0 To UBound($aAutoBlocks) - 1
            Local $aP = $aAutoBlocks[$i]
            Local $sImgKey = $aP[1]
            Local $sRawTpls = $aP[2]
            Local $sRest = $aP[3]

            Local $iAutosel = 0
            Local $aSelMatch = StringRegExp($sRest, '"autosel"\s*:\s*(\d+)', 1)
            If Not @error And UBound($aSelMatch) > 0 Then $iAutosel = Number($aSelMatch[0])

            Local $iTimeout = 10
            Local $aTimeMatch = StringRegExp($sRest, '"timeout"\s*:\s*(\d+)', 1)
            If Not @error And UBound($aTimeMatch) > 0 Then $iTimeout = Number($aTimeMatch[0])

            Local $aTplMatches = StringRegExp($sRawTpls, '"([^"]+)"', 3)
            Local $sJoinedTpl = ""
            If Not @error Then
                For $t = 0 To UBound($aTplMatches) - 1
                    If $sJoinedTpl <> "" Then $sJoinedTpl &= "; "
                    $sJoinedTpl &= $aTplMatches[$t]
                Next
            EndIf
            $oAutoTplMap.Item($sImgKey) = $sJoinedTpl
            $oAutoSelMap.Item($sImgKey) = $iAutosel
            $oAutoTimeoutMap.Item($sImgKey) = $iTimeout
        Next
    EndIf

    Local $aEntries[0][7] ; [Icon, Alias, Image, Tip, Templates, Autosel, Timeout]
    If $iAliasCount > 0 Then
        For $i = 0 To $iAliasCount - 1
            Local $aPair = $aAliases[$i]
            Local $sImage = $aPair[1]
            Local $sAlias = $aPair[2]
            If StringLeft($sAlias, 1) = "*" Then $sAlias = StringTrimLeft($sAlias, 1)

            Local $sTip = $oTipMap.Exists($sImage) ? $oTipMap.Item($sImage) : ""
            Local $sTpls = $oAutoTplMap.Exists($sImage) ? $oAutoTplMap.Item($sImage) : "/AutoInstaller.xml"
            Local $iAutosel = $oAutoSelMap.Exists($sImage) ? $oAutoSelMap.Item($sImage) : 0
            Local $iTimeout = $oAutoTimeoutMap.Exists($sImage) ? $oAutoTimeoutMap.Item($sImage) : 10

            Local $sIcon = "windows"
            Local $sImageBase = StringLower(StringRegExpReplace($sImage, '^.*[\\/]', ''))
            $sImageBase = StringRegExpReplace($sImageBase, '\.iso$', '')
            If $oClassMap.Exists($sImageBase) Then
                $sIcon = $oClassMap.Item($sImageBase)
            ElseIf $oClassMap.Exists("w11") Then
                $sIcon = $oClassMap.Item("w11")
            EndIf

            ReDim $aEntries[$i + 1][7]
            $aEntries[$i][0] = $sIcon
            $aEntries[$i][1] = $sAlias
            $aEntries[$i][2] = $sImage
            $aEntries[$i][3] = $sTip
            $aEntries[$i][4] = $sTpls
            $aEntries[$i][5] = $iAutosel
            $aEntries[$i][6] = $iTimeout
        Next
    EndIf

    $oResult.Item("BootEntries") = $aEntries
    $oResult.Item("EntryCount") = UBound($aEntries, 1)
    Return $oResult
EndFunc

; Serializes structured configuration into ventoy.json
Func ventoySaveConfigData($sFilePath, $sTheme, $sActiveVariant, $aEntries)
    Local $sConfig = ($sFilePath <> "") ? $sFilePath : ventoyGetJsonPath()
    Local $sDir = StringLeft($sConfig, StringInStr($sConfig, "\", 0, -1) - 1)
    If $sDir <> "" And Not FileExists($sDir) Then DirCreate($sDir)

    Local $sThemeDir = ventoyGetThemeDir()

    ; Build JSON string
    Local $sOut = "{" & @CRLF
    $sOut &= '    "control": [' & @CRLF
    $sOut &= '        {' & @CRLF
    $sOut &= '            "VTOY_DEFAULT_SEARCH_ROOT": "/"' & @CRLF
    $sOut &= '        }' & @CRLF
    $sOut &= '    ],' & @CRLF

    ; Theme block
    $sOut &= '    "theme": {' & @CRLF
    If $sTheme = "Ventoy" Then
        $sOut &= '        "file": "/ventoy/theme/theme.txt",' & @CRLF
        $sOut &= '        "gfxmode": "max"' & @CRLF
    Else
        $sOut &= '        "file": [' & @CRLF
        Local $aThemeFiles[0]
        Local $hSearch = FileFindFirstFile($sThemeDir & "\*.txt")
        If $hSearch <> -1 Then
            While 1
                Local $sF = FileFindNextFile($hSearch)
                If @error Then ExitLoop
                If $sTheme = "1172005thinh (Single)" Then
                    If Not StringInStr($sF, $sActiveVariant & "_") Then ContinueLoop
                EndIf
                ReDim $aThemeFiles[UBound($aThemeFiles) + 1]
                $aThemeFiles[UBound($aThemeFiles) - 1] = "/ventoy/theme/1172005thinh/" & $sF
            WEnd
            FileClose($hSearch)
        EndIf

        If UBound($aThemeFiles) = 0 Then
            ReDim $aThemeFiles[1]
            $aThemeFiles[0] = "/ventoy/theme/1172005thinh/" & $sActiveVariant & "_1920x1080.txt"
        EndIf

        For $f = 0 To UBound($aThemeFiles) - 1
            $sOut &= '            "' & $aThemeFiles[$f] & '"'
            If $f < UBound($aThemeFiles) - 1 Then $sOut &= ','
            $sOut &= @CRLF
        Next

        $sOut &= '        ],' & @CRLF
        $sOut &= '        "gfxmode": "max",' & @CRLF
        $sOut &= '        "resolution_fit": 1,' & @CRLF
        $sOut &= '        "ventoy_left": "72%",' & @CRLF
        $sOut &= '        "ventoy_top": "95%",' & @CRLF
        $sOut &= '        "ventoy_color": "#6F6F6F",' & @CRLF
        $sOut &= '        "fonts": [' & @CRLF
        $sOut &= '            "/ventoy/font/cascadia-code/cascadia-code_12.pf2",' & @CRLF
        $sOut &= '            "/ventoy/font/cascadia-code/cascadia-code_16.pf2",' & @CRLF
        $sOut &= '            "/ventoy/font/cascadia-code/cascadia-code_20.pf2",' & @CRLF
        $sOut &= '            "/ventoy/font/cascadia-code/cascadia-code_24.pf2",' & @CRLF
        $sOut &= '            "/ventoy/font/cascadia-code/cascadia-code_28.pf2",' & @CRLF
        $sOut &= '            "/ventoy/font/cascadia-code/cascadia-code_32.pf2"' & @CRLF
        $sOut &= '        ]' & @CRLF
    EndIf
    $sOut &= '    },' & @CRLF

    Local $iEntryCount = UBound($aEntries, 1)

    ; menu_alias block
    $sOut &= '    "menu_alias": [' & @CRLF
    For $i = 0 To $iEntryCount - 1
        Local $sAlias = $aEntries[$i][1]
        If StringLeft($sAlias, 1) = "*" Then $sAlias = StringTrimLeft($sAlias, 1)
        $sOut &= '        {' & @CRLF
        $sOut &= '            "image": "' & $aEntries[$i][2] & '",' & @CRLF
        $sOut &= '            "alias": "' & $sAlias & '"' & @CRLF
        $sOut &= '        }'
        If $i < $iEntryCount - 1 Then $sOut &= ','
        $sOut &= @CRLF
    Next
    $sOut &= '    ],' & @CRLF

    ; menu_tip block
    $sOut &= '    "menu_tip": {' & @CRLF
    $sOut &= '        "left": "30%",' & @CRLF
    $sOut &= '        "top": "11%",' & @CRLF
    $sOut &= '        "color": "#CDCDCD",' & @CRLF
    $sOut &= '        "tips": [' & @CRLF
    For $i = 0 To $iEntryCount - 1
        $sOut &= '            {' & @CRLF
        $sOut &= '                "image": "' & $aEntries[$i][2] & '",' & @CRLF
        $sOut &= '                "tip": "' & $aEntries[$i][3] & '"' & @CRLF
        $sOut &= '            }'
        If $i < $iEntryCount - 1 Then $sOut &= ','
        $sOut &= @CRLF
    Next
    $sOut &= '        ]' & @CRLF
    $sOut &= '    },' & @CRLF

    ; menu_class block
    $sOut &= '    "menu_class": [' & @CRLF
    For $i = 0 To $iEntryCount - 1
        Local $sKeyName = StringLower(StringRegExpReplace($aEntries[$i][2], '^.*[\\/]', ''))
        $sKeyName = StringRegExpReplace($sKeyName, '\.iso$', '')
        If $sKeyName = "" Then $sKeyName = "entry" & ($i + 1)

        $sOut &= '        {' & @CRLF
        $sOut &= '            "key": "' & $sKeyName & '",' & @CRLF
        $sOut &= '            "class": "' & $aEntries[$i][0] & '"' & @CRLF
        $sOut &= '        }'
        If $i < $iEntryCount - 1 Then $sOut &= ','
        $sOut &= @CRLF
    Next
    $sOut &= '    ],' & @CRLF

    ; auto_install block
    $sOut &= '    "auto_install": [' & @CRLF
    For $i = 0 To $iEntryCount - 1
        $sOut &= '        {' & @CRLF
        $sOut &= '            "image": "' & $aEntries[$i][2] & '",' & @CRLF
        $sOut &= '            "template": [' & @CRLF

        Local $aTList = StringSplit($aEntries[$i][4], ";", $STR_NOCOUNT)
        For $t = 0 To UBound($aTList) - 1
            Local $sTPath = StringStripWS($aTList[$t], $STR_STRIPLEADING + $STR_STRIPTRAILING)
            If StringLeft($sTPath, 1) = "*" Then $sTPath = StringTrimLeft($sTPath, 1)
            If $sTPath <> "" Then
                $sOut &= '                "' & $sTPath & '"'
                If $t < UBound($aTList) - 1 Then $sOut &= ','
                $sOut &= @CRLF
            EndIf
        Next

        Local $iTimeout = (UBound($aEntries, 2) >= 7) ? Number($aEntries[$i][6]) : 10
        If $iTimeout < 3 Then $iTimeout = 10
        If $iTimeout > 60 Then $iTimeout = 60

        $sOut &= '            ],' & @CRLF
        $sOut &= '            "timeout": ' & $iTimeout & ',' & @CRLF
        $sOut &= '            "autosel": ' & Number($aEntries[$i][5]) & @CRLF
        $sOut &= '        }'
        If $i < $iEntryCount - 1 Then $sOut &= ','
        $sOut &= @CRLF
    Next
    $sOut &= '    ]' & @CRLF
    $sOut &= '}' & @CRLF

    Local $hFile = FileOpen($sConfig, BitOR($FO_OVERWRITE, $FO_UTF8_NOBOM))
    If $hFile = -1 Then Return False
    FileWrite($hFile, $sOut)
    FileClose($hFile)
    Return True
EndFunc
