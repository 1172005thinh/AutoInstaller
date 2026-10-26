;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/modules/dialog.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Libraries
#include <GUIConstantsEx.au3>
#include <FileConstants.au3>

; Modules
#include "i18n.au3"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Folder & Log Browsing Dialogs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Opens a directory selection dialog to configure an auto-installation log file path
Func dialogBrowseLogPath($idInput, $sDefaultFilename, $sDialogTitleKey = "", $sDefaultTitle = "Select Log Folder")
    Local $sCurPath = GUICtrlRead($idInput)
    Local $sInitDir = @HomeDrive & "\AutoInstaller"
    If $sCurPath <> "" Then
        Local $sDir = StringRegExpReplace($sCurPath, "\\[^\\]*$", "")
        If FileExists($sDir) Then $sInitDir = $sDir
    EndIf

    Local $sTitle = ($sDialogTitleKey <> "") ? i18nGet($sDialogTitleKey, $sDefaultTitle) : $sDefaultTitle
    Local $sSelected = FileSelectFolder($sTitle, $sInitDir)
    If Not @error And $sSelected <> "" Then
        If StringRight($sSelected, 1) <> "\" Then $sSelected &= "\"
        Local $sFullPath = $sSelected & $sDefaultFilename
        GUICtrlSetData($idInput, $sFullPath)
        Return $sFullPath
    EndIf
    Return ""
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration File Import & Export
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Displays a standard file open dialog to import a configuration file
Func dialogImportConfig($sInitDir, $sFilter, $sTitleKey = "", $sDefaultTitle = "Select configuration to import")
    Local $sTitle = ($sTitleKey <> "") ? i18nGet($sTitleKey, $sDefaultTitle) : $sDefaultTitle
    Local $sFile = FileOpenDialog($sTitle, $sInitDir, $sFilter, BitOR($FD_FILEMUSTEXIST, $FD_PATHMUSTEXIST))
    If Not @error And $sFile <> "" Then Return $sFile
    Return ""
EndFunc

; Displays a standard file save dialog to export a configuration file
Func dialogExportConfig($sInitDir, $sFilter, $sDefaultFilename, $sExt = ".ini", $sTitleKey = "", $sDefaultTitle = "Export configuration")
    Local $sTitle = ($sTitleKey <> "") ? i18nGet($sTitleKey, $sDefaultTitle) : $sDefaultTitle
    Local $sFile = FileSaveDialog($sTitle, $sInitDir, $sFilter, BitOR($FD_PATHMUSTEXIST, $FD_PROMPTOVERWRITE), $sDefaultFilename)
    If Not @error And $sFile <> "" Then
        If $sExt <> "" And StringRight($sFile, StringLen($sExt)) <> $sExt Then $sFile &= $sExt
        Return $sFile
    EndIf
    Return ""
EndFunc

; Opens a configuration or script file in the system default text editor
Func dialogOpenFileInEditor($sFilePath)
    If Not FileExists($sFilePath) Then Return False
    Return ShellExecute($sFilePath) <> 0
EndFunc
