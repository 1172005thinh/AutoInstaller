;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/modules/data.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Libraries
#include <FileConstants.au3>
#include <Array.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Global Data Cache
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $g_oDataCache = ObjCreate("Scripting.Dictionary")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Helper: Parse single CSV line
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _dataParseCsvLine($sLine)
    Local $aFields[32]
    Local $iCount = 0
    Local $sCur = ""
    Local $bInQuotes = False
    Local $iLen = StringLen($sLine)

    For $i = 1 To $iLen
        Local $sChar = StringMid($sLine, $i, 1)
        If $sChar = '"' Then
            $bInQuotes = Not $bInQuotes
        ElseIf $sChar = ',' And Not $bInQuotes Then
            If $iCount >= UBound($aFields) Then ReDim $aFields[$iCount * 2]
            $aFields[$iCount] = $sCur
            $iCount += 1
            $sCur = ""
        Else
            $sCur &= $sChar
        EndIf
    Next

    If $iCount >= UBound($aFields) Then ReDim $aFields[$iCount + 1]
    $aFields[$iCount] = $sCur
    $iCount += 1
    ReDim $aFields[$iCount]

    Return $aFields
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Public API: Path Resolution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func dataGetCsvPath($sFilename)
    Local $sRel = @ScriptDir & "\gui\assets\data\" & $sFilename
    If FileExists($sRel) Then Return $sRel
    If FileExists($sFilename) Then Return $sFilename
    Return $sRel
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Public API: Load CSV to 2D Array
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func dataLoadCsv($sFilename)
    If Not IsObj($g_oDataCache) Then $g_oDataCache = ObjCreate("Scripting.Dictionary")
    If $g_oDataCache.Exists($sFilename) Then
        Return $g_oDataCache.Item($sFilename)
    EndIf

    Local $sPath = dataGetCsvPath($sFilename)
    If Not FileExists($sPath) Then
        Local $aEmpty[0][0]
        Return $aEmpty
    EndIf

    Local $hFile = FileOpen($sPath, $FO_READ + $FO_UTF8_NOBOM)
    If $hFile = -1 Then
        Local $aEmpty[0][0]
        Return $aEmpty
    EndIf

    Local $sContent = FileRead($hFile)
    FileClose($hFile)

    Local $aLines = StringSplit(StringStripCR($sContent), @LF, 1)
    Local $aTempRows[UBound($aLines)]
    Local $iValidRows = 0
    Local $iMaxCols = 0

    For $i = 1 To $aLines[0]
        Local $sLine = StringStripWS($aLines[$i], 3)
        If $sLine = "" Then ContinueLoop
        Local $aRow = _dataParseCsvLine($sLine)
        If UBound($aRow) > $iMaxCols Then $iMaxCols = UBound($aRow)
        $aTempRows[$iValidRows] = $aRow
        $iValidRows += 1
    Next

    If $iValidRows = 0 Or $iMaxCols = 0 Then
        Local $aEmpty[0][0]
        Return $aEmpty
    EndIf

    Local $aResult[$iValidRows][$iMaxCols]
    For $r = 0 To $iValidRows - 1
        Local $aRow = $aTempRows[$r]
        For $c = 0 To UBound($aRow) - 1
            $aResult[$r][$c] = $aRow[$c]
        Next
    Next

    $g_oDataCache.Item($sFilename) = $aResult
    Return $aResult
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Public API: Column Delimited String
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func dataGetColumnList($sFilename, $iCol = 0, $sDelimiter = "|")
    Local $aData = dataLoadCsv($sFilename)
    Local $iRows = UBound($aData, 1)
    If $iRows <= 1 Then Return ""

    Local $iCols = UBound($aData, 2)
    If $iCol >= $iCols Then Return ""

    Local $sResult = ""
    ; Skip header row (index 0)
    For $i = 1 To $iRows - 1
        Local $sVal = $aData[$i][$iCol]
        If $sResult = "" Then
            $sResult = $sVal
        Else
            $sResult &= $sDelimiter & $sVal
        EndIf
    Next

    Return $sResult
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Public API: Lookup Field Value
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func dataLookup($sFilename, $sKey, $iKeyCol = 0, $iValCol = 1)
    Local $aData = dataLoadCsv($sFilename)
    Local $iRows = UBound($aData, 1)
    If $iRows <= 1 Then Return ""

    Local $iCols = UBound($aData, 2)
    If $iKeyCol >= $iCols Or $iValCol >= $iCols Then Return ""

    ; Skip header row (index 0)
    For $i = 1 To $iRows - 1
        If $aData[$i][$iKeyCol] = $sKey Then
            Return $aData[$i][$iValCol]
        EndIf
    Next

    Return ""
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Public API: Get Row Count
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func dataGetRowCount($sFilename)
    Local $aData = dataLoadCsv($sFilename)
    Local $iRows = UBound($aData, 1)
    If $iRows <= 1 Then Return 0
    Return $iRows - 1
EndFunc
