;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/unattend.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Includes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Libraries
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <GuiListView.au3>
#include <EditConstants.au3>

; Controls
#include "../controls/button.au3"

; Modules
#include "../modules/i18n.au3"
#include "../modules/theme.au3"
#include "../modules/config.au3"
#include "../modules/scroll.au3"
#include <Array.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Const
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Views/Unattend
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $hViewUnattend = 0
Global $idViewUnattendTitle = 0

Global $hViewUnattendWindowsGroup = 0
Global $idViewUnattendEditionLbl = 0, $idViewUnattendEditionCmb = 0
Global $idViewUnattendProductKeyLbl = 0, $idViewUnattendProductKeyInput = 0
Global $idViewUnattendArchLbl = 0, $idViewUnattendArchCmb = 0
Global $idViewUnattendPCNameLbl = 0, $idViewUnattendPCNameInput = 0

Global $hViewUnattendRegionGroup = 0
Global $idViewUnattendSysLangLbl = 0, $idViewUnattendSysLangCmb = 0
Global $idViewUnattendUsrLangLbl = 0, $idViewUnattendUsrLangCmb = 0
Global $idViewUnattendSysUsrLangSameCkbx = 0
Global $idViewUnattendUILangLbl = 0, $idViewUnattendUILangCmb = 0
Global $idViewUnattendKbLayoutLbl = 0, $idViewUnattendKbLayoutCmb = 0 
Global $idViewUnattendTZLbl = 0, $idViewUnattendTZCmb = 0

Global $hViewUnattendPartitionGroup = 0
Global $idViewUnattendPartitionManLbl = 0, $idViewUnattendPartitionManRdoC1 = 0, $idViewUnattendPartitionManRdoC2 = 0, $idViewUnattendPartitionManRdoC3 = 0
Global $idViewUnattendPartitionDiskIDLbl = 0, $idViewUnattendPartitionDiskIDInput = 0
Global $idViewUnattendPartitionTypeLbl = 0, $idViewUnattendPartitionTypeRdoC1 = 0, $idViewUnattendPartitionTypeRdoC2 = 0
Global $idViewUnattendPartitionTblLbl = 0, $idViewUnattendPartitionTblList = 0

Global $hViewUnattendBypassGroup = 0
Global $idViewUnattendBypassAllCkbx = 0
Global $idViewUnattendBypassTPMCkbx = 0
Global $idViewUnattendBypassRAMCkbx = 0
Global $idViewUnattendBypassSBCkbx = 0
Global $idViewUnattendBypassCPUCkbx = 0
Global $idViewUnattendBypassStorageCkbx = 0
Global $idViewUnattendBypassDiskCkbx = 0

Global $hViewUnattendOOBEGroup = 0
Global $idViewUnattendOOBEAllCkbx = 0
Global $idViewUnattendOOBEEULACkbx = 0
Global $idViewUnattendOOBELocalAccCkbx = 0
Global $idViewUnattendOOBEOnlAccCkbx = 0
Global $idViewUnattendOOBEWirelessCkbx = 0
Global $idViewUnattendOOBEBitLockerCkbx = 0
Global $idViewUnattendOOBEPrivacyLbl = 0, $idViewUnattendOOBEPrivacyRdoC1 = 0, $idViewUnattendOOBEPrivacyRdoC2 = 0, $idViewUnattendOOBEPrivacyRdoC3 = 0

Global $hViewUnattendLocalAccGroup = 0
Global $idViewUnattendLocalAccTblLbl = 0, $idViewUnattendLocalAccTblList = 0

Global $hViewUnattendBloatwareGroup = 0
Global $idViewUnattendBloatwareAllCkbx = 0
Global $idViewUnattendBloatwareTblLbl = 0, $idViewUnattendBloatwareTblList = 0
Global $a_sKnownBloatwares[25][2] = [ _
    ["Microsoft.Copilot", "Windows Copilot AI assistant integration"], _
    ["Clipchamp.Clipchamp", "Clipchamp video editor application"], _
    ["Microsoft.BingSearch", "Bing web search integration in Windows"], _
    ["Microsoft.BingNews", "Microsoft Bing News widget and application"], _
    ["MicrosoftTeams", "Microsoft Teams personal / work client"], _
    ["MSTeams", "Microsoft Teams alternate package"], _
    ["Microsoft.OutlookForWindows", "New web-based Outlook email client"], _
    ["Microsoft.MicrosoftSolitaireCollection", "Microsoft Solitaire collection games"], _
    ["Microsoft.Microsoft3DViewer", "3D Model Viewer utility"], _
    ["Microsoft.SkypeApp", "Skype instant messaging and calling app"], _
    ["Microsoft.People", "Windows People address book app"], _
    ["Microsoft.Todos", "Microsoft To Do task manager"], _
    ["Microsoft.Wallet", "Microsoft Wallet payment autofill"], _
    ["Microsoft.WindowsMaps", "Windows Maps application"], _
    ["Microsoft.Getstarted", "Tips and Get Started application"], _
    ["Microsoft.GetHelp", "Get Help diagnostic assistance app"], _
    ["Microsoft.WindowsFeedbackHub", "Windows Feedback Hub telemetry app"], _
    ["Microsoft.Office.OneNote", "OneNote for Windows application"], _
    ["Microsoft.MicrosoftOfficeHub", "Microsoft 365 / Office Hub portal"], _
    ["Microsoft.MixedReality.Portal", "Windows Mixed Reality portal app"], _
    ["MicrosoftCorporationII.QuickAssist", "Remote assistance support client"], _
    ["MicrosoftCorporationII.MicrosoftFamily", "Microsoft Family Safety monitor"], _
    ["Microsoft.MicrosoftStickyNotes", "Sticky Notes desktop application"], _
    ["Microsoft.549981C3F5F10", "Cortana voice assistant component"], _
    ["App.Support.QuickAssist", "Quick Assist capability component"] _
]

Global $hViewUnattendScriptsGroup = 0
Global $idViewUnattendScriptsEditLbl = 0, $idViewUnattendScriptsEditEdit = 0

Func viewUnattendCreate($hViewPort, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH
    Local $iEstCanvasH = 2000
    If $iContentH < $iEstCanvasH Then $iContentH = $iEstCanvasH

    $hViewUnattend = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewUnattend)
    
    Local $iLblW = ($iContentW - $iP * 6) * 35 / 100
    Local $iInputW = ($iContentW - $iP * 6) * 58 / 100
    Local $iColW = ($iContentW - $iP * 6) / 2
    Local $iPx = $iLblH * 20 / 100
    Local $iGroupH = 0
    Local $iItemY = 0
    Local $iRowH = $iLblH + $iP * 2

    ; View Unattend Title
    Local $iX = $iP
    Local $iY = $iP
    Local $iCtrlW = $iContentW
    Local $iCtrlH = $iLblH * 2
    $idViewUnattendTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)

    ; Initialize Windows Group
    $iGroupH = $iRowH * 4 + $iP * 3
    $iX = $iP
    $iY += $iLblH * 2 + $iP
    $hViewUnattendWindowsGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iGroupH)

    ; Edition
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewUnattendEditionLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendEditionCmb = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendEditionCmb, "Windows 11 Pro|Windows 11 Home|Windows 11 Enterprise|Windows 11 Education|Windows 11 Pro for Workstations", "Windows 11 Pro")

    ; Product Key
    $iItemY += $iRowH
    $idViewUnattendProductKeyLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendProductKeyInput = GUICtrlCreateInput("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    
    ; Architecture
    $iItemY += $iRowH
    $idViewUnattendArchLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendArchCmb = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendArchCmb, "x64|ARM", "x64")

    ; PC Name
    $iItemY += $iRowH
    $idViewUnattendPcNameLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendPcNameInput = GUICtrlCreateInput("PC", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)

    ;GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; Initialize Region Group
    $iX = $iP
    $iY += $iGroupH + $iP
    $iGroupH = $iRowH * 6 + $iP * 3
    $hViewUnattendRegionGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iGroupH)

    ; System Language
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewUnattendSysLangLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendSysLangCmb = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendSysLangCmb, "English|Tiếng Việt", "English")

    ; User Language
    $iItemY += $iRowH
    $idViewUnattendUsrLangLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendUsrLangCmb = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendUsrLangCmb, "English|Tiếng Việt", "English")

    ; System & User Language Same Checkbox
    $iItemY += $iRowH
    $idViewUnattendSysUsrLangSameCkbx = GUICtrlCreateCheckbox("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)

    ; UI Language
    $iItemY += $iRowH
    $idViewUnattendUILangLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendUILangCmb = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendUILangCmb, "English|Tiếng Việt", "English")

    ; Keyboard Layout
    $iItemY += $iRowH
    $idViewUnattendKbLayoutLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendKbLayoutCmb = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendKbLayoutCmb, "en-us|vi-vn", "en-us")

    ; Time Zone
    $iItemY += $iRowH
    $idViewUnattendTZLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendTZCmb = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendTZCmb, "UTC-8|UTC-7|UTC-6|UTC-5|UTC-4|UTC-3|UTC-2|UTC-1|UTC|UTC+1|UTC+2|UTC+3|UTC+4|UTC+5|UTC+6|UTC+7|UTC+8|UTC+9|UTC+10", "UTC+7")

    ;GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; Initialize Partition Group
    $iX = $iP
    $iY += $iGroupH + $iP
    $iGroupH = $iRowH * 6 + $iP * 3
    $hViewUnattendPartitionGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iGroupH)

    ; Partition Auto/Manual/Hybrid
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewUnattendPartitionManLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendPartitionManRdoC1 = GUICtrlCreateRadio("", $iP * 3 + $iLblW, $iItemY - $iPx, $iInputW / 3 - $iP * 2, $iLblH + $iPx)
    $idViewUnattendPartitionManRdoC2 = GUICtrlCreateRadio("", $iP * 3 + $iLblW + $iInputW / 3 + $iP, $iItemY - $iPx, $iInputW / 3 - $iP * 2, $iLblH + $iPx)
    $idViewUnattendPartitionManRdoC3 = GUICtrlCreateRadio("", $iP * 3 + $iLblW + $iInputW / 3 * 2 + $iP * 2, $iItemY - $iPx, $iInputW / 3 - $iP * 2, $iLblH + $iPx)
    GUICtrlSetState($idViewUnattendPartitionManRdoC1, $GUI_CHECKED)

    ; Partition Disk ID
    $iItemY += $iRowH
    $idViewUnattendPartitionDiskIDLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendPartitionDiskIDInput = GUICtrlCreateInput("$$VT_WINDOWS_DISK_1ST_NONVTOY$$", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)

    ; Parition Type
    $iItemY += $iRowH
    $idViewUnattendPartitionTypeLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendPartitionTypeRdoC1 = GUICtrlCreateRadio("", $iP * 3 + $iLblW, $iItemY - $iPx, $iInputW / 2 - $iP, $iLblH + $iPx)
    $idViewUnattendPartitionTypeRdoC2 = GUICtrlCreateRadio("", $iP * 3 + $iLblW + $iInputW / 2 + $iP, $iItemY - $iPx, $iInputW / 2 - $iP, $iLblH + $iPx)
    GUICtrlSetState($idViewUnattendPartitionTypeRdoC1, $GUI_CHECKED)

    ; Partition Table (Not implemented)
    $iItemY += $iRowH
    $idViewUnattendPartitionTblLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    
    ;GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; Initialize Bypass Group
    $iX = $iP
    $iY += $iGroupH + $iP
    $iGroupH = $iRowH * 4 + $iP * 3
    $hViewUnattendBypassGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iGroupH)

    ; Bypass All Checks
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewUnattendBypassAllCkbx = GUICtrlCreateCheckbox("", $iX, $iItemY, $iInputW, $iLblH)

    ; Bypass TPM
    $iItemY += $iRowH
    $idViewUnattendBypassTPMCkbx = GUICtrlCreateCheckbox("", $iX, $iItemY, $iColW, $iLblH)
    
    ; Bypass RAM
    $idViewUnattendBypassRAMCkbx = GUICtrlCreateCheckbox("", $iX, $iItemY + $iRowH, $iColW, $iLblH)

    ; Bypass Secure Boot
    $idViewUnattendBypassSBCkbx = GUICtrlCreateCheckbox("", $iX, $iItemY + $iRowH * 2, $iColW, $iLblH)

    ; Bypass CPU
    Local $iRightColX = $iP * 3 + $iColW + $iP
    $idViewUnattendBypassCPUCkbx = GUICtrlCreateCheckbox("", $iRightColX, $iItemY, $iColW, $iLblH)

    ; Bypass Storage
    $idViewUnattendBypassStorageCkbx = GUICtrlCreateCheckbox("", $iRightColX, $iItemY + $iRowH, $iColW, $iLblH)

    ; Bypass Disk
    $idViewUnattendBypassDiskCkbx = GUICtrlCreateCheckbox("", $iRightColX, $iItemY + $iRowH * 2, $iColW, $iLblH)

    ;GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; Initialize OOBE Group
    $iX = $iP
    $iY += $iGroupH + $iP
    $iGroupH = $iRowH * 5 + $iP * 3
    $hViewUnattendOOBEGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iGroupH)

    ; Hide All OOBE
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewUnattendOOBEAllCkbx = GUICtrlCreateCheckbox("", $iX, $iItemY, $iInputW, $iLblH)

    ; Hide EULA
    $iItemY += $iRowH
    $idViewUnattendOOBEEULACkbx = GUICtrlCreateCheckbox("", $iX, $iItemY, $iColW, $iLblH)

    ; Hide Local Account
    $idViewUnattendOOBELocalAccCkbx = GUICtrlCreateCheckbox("", $iX, $iItemY + $iRowH, $iColW, $iLblH)
    
    ; Hide Online Account
    $idViewUnattendOOBEOnlAccCkbx = GUICtrlCreateCheckbox("", $iX, $iItemY + $iRowH * 2, $iColW, $iLblH)

    ; Hide Wireless
    $idViewUnattendOOBEWirelessCkbx = GUICtrlCreateCheckbox("", $iRightColX, $iItemY, $iColW, $iLblH)

    ; Disable BitLocker
    $idViewUnattendOOBEBitLockerCkbx = GUICtrlCreateCheckbox("", $iRightColX, $iItemY + $iRowH, $iColW, $iLblH)

    ; Privacy Protect
    $iItemY += $iRowH * 3
    $idViewUnattendOOBEPrivacyLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendOOBEPrivacyRdoC1 = GUICtrlCreateRadio("", $iP * 3 + $iLblW, $iItemY - $iPx, $iInputW / 3 - $iP * 2, $iLblH + $iPx)
    $idViewUnattendOOBEPrivacyRdoC2 = GUICtrlCreateRadio("", $iP * 3 + $iLblW + $iInputW / 3 + $iP, $iItemY - $iPx, $iInputW / 3 - $iP * 2, $iLblH + $iPx)
    $idViewUnattendOOBEPrivacyRdoC3 = GUICtrlCreateRadio("", $iP * 3 + $iLblW + $iInputW / 3 * 2 + $iP * 2, $iItemY - $iPx, $iInputW / 3 - $iP * 2, $iLblH + $iPx)
    GUICtrlSetState($idViewUnattendOOBEPrivacyRdoC1, $GUI_CHECKED)

    ;GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; Initialize Local Account Group
    $iX = $iP
    $iY += $iGroupH + $iP
    $iGroupH = $iRowH * 5 + $iP * 3
    $hViewUnattendLocalAccGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iGroupH)

    ; Local Account
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewUnattendLocalAccTblLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iColW, $iLblH)
    
    ;GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; Initialize Bloatware Group
    $iX = $iP
    $iY += $iGroupH + $iP
    $iGroupH = $iRowH * 9 + $iP * 3
    $hViewUnattendBloatwareGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iGroupH)

    ; Bloatware All
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewUnattendBloatwareAllCkbx = GUICtrlCreateCheckbox("", $iX, $iItemY, $iColW, $iLblH)
    
    ; Bloatware List Label
    $iItemY += $iRowH
    $idViewUnattendBloatwareTblLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iColW, $iLblH)

    ; Bloatware List
    $iItemY += $iRowH
    Local $iListW = $iContentW - $iP * 4
    Local $iListH = $iRowH * 7 - $iP * 2
    $idViewUnattendBloatwareTblList = GUICtrlCreateListView(i18nGet("unattend.bloatware.list.col1.label", "Package Name") & "|" & i18nGet("unattend.bloatware.list.col2.label", "Description"), $iX, $iItemY, $iListW, $iListH)
    _GUICtrlListView_SetExtendedListViewStyle($idViewUnattendBloatwareTblList, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))
    _GUICtrlListView_SetColumnWidth($idViewUnattendBloatwareTblList, 0, $iListW * 45 / 100)
    _GUICtrlListView_SetColumnWidth($idViewUnattendBloatwareTblList, 1, $iListW * 51 / 100)
    For $i = 0 To UBound($a_sKnownBloatwares) - 1
        GUICtrlCreateListViewItem($a_sKnownBloatwares[$i][0] & "|" & $a_sKnownBloatwares[$i][1], $idViewUnattendBloatwareTblList)
    Next

    ;GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; Initialize Scripts Group
    $iX = $iP
    $iY += $iGroupH + $iP
    $iGroupH = $iRowH * 12 + $iP * 3
    $hViewUnattendScriptsGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iGroupH)

    ; Scripts Label
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewUnattendScriptsEditLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)

    ; Scripts Edit
    $iItemY += $iRowH
    $iListW = $iContentW - $iP * 4
    $iListH = $iRowH * 11 - $iP * 2
    $idViewUnattendScriptsEditEdit = GUICtrlCreateEdit("", $iX, $iItemY, $iListW, $iListH)
    GUICtrlSetFont($idViewUnattendScriptsEditEdit, $iPrimary)
    GUICtrlSetLimit($idViewUnattendScriptsEditEdit, 4096)
    
    ;GUICtrlCreateGroup("", -99, -99, -99, -99)

    Local $iTotalContentH = $iY + $iGroupH + $iP
    scrollSetContentHeight($hViewUnattend, $iTotalContentH)

    viewUnattendApplyLang()
    viewUnattendApplyTheme()
    Return $hViewUnattend
EndFunc

Func viewUnattendLoadValues($sSourceFile)
    Local $oData = xmlLoadValues($sSourceFile)
    If Not IsObj($oData) Or $oData.Count = 0 Then Return False
    
    Return True
EndFunc

Func viewUnattendSaveValues($sTargetFile)
    Local $oData = ObjCreate("Scripting.Dictionary")
    
    Return xmlSaveValues($sTargetFile, $oData)
EndFunc

Func viewUnattendApplyLang()
    GUICtrlSetData($idViewUnattendTitle, i18nGet("unattend.title", "Customize Unattend Script"))

    GUICtrlSetData($hViewUnattendWindowsGroup, i18nGet("unattend.windows.title", "Windows Customization"))
    GUICtrlSetData($idViewUnattendEditionLbl, i18nGet("unattend.windows.edition.label", "Windows Edition: "))
    GUICtrlSetData($idViewUnattendProductKeyLbl, i18nGet("unattend.windows.productkey.label", "Product Key: "))
    GUICtrlSetData($idViewUnattendArchLbl, i18nGet("unattend.windows.arch.label", "Architecture: "))
    GUICtrlSetData($idViewUnattendPCNameLbl, i18nGet("unattend.windows.pcname.label", "Computer Name: "))
    
    GUICtrlSetData($hViewUnattendRegionGroup, i18nGet("unattend.region.title", "Language - Region"))
    GUICtrlSetData($idViewUnattendSysLangLbl, i18nGet("unattend.region.syslang.label", "System Language: "))
    GUICtrlSetData($idViewUnattendUsrLangLbl, i18nGet("unattend.region.usrlang.label", "User Language: "))
    GUICtrlSetData($idViewUnattendSysUsrLangSameCkbx, i18nGet("unattend.region.sysusrlangsame.label", "Same as System Language"))
    GUICtrlSetData($idViewUnattendUILangLbl, i18nGet("unattend.region.uilang.label", "UI Language: "))
    GUICtrlSetData($idViewUnattendKbLayoutLbl, i18nGet("unattend.region.kblayout.label", "Keyboard Layout: "))
    GUICtrlSetData($idViewUnattendTZLbl, i18nGet("unattend.region.timezone.label", "Time Zone: "))

    GUICtrlSetData($hViewUnattendPartitionGroup, i18nGet("unattend.partition.title", "Disk Partitions Management"))
    GUICtrlSetData($idViewUnattendPartitionManLbl, i18nGet("unattend.partition.man.label", "Partition Automation: "))
    GUICtrlSetData($idViewUnattendPartitionManRdoC1, i18nGet("unattend.partition.man.auto.label", "Auto"))
    GUICtrlSetData($idViewUnattendPartitionManRdoC2, i18nGet("unattend.partition.man.manual.label", "Manual"))
    GUICtrlSetData($idViewUnattendPartitionManRdoC3, i18nGet("unattend.partition.man.hybrid.label", "Hybrid"))
    GUICtrlSetData($idViewUnattendPartitionDiskIDLbl, i18nGet("unattend.partition.diskid.label", "Disk ID: "))
    GUICtrlSetData($idViewUnattendPartitionTypeLbl, i18nGet("unattend.partition.type.label", "Partition Type: "))
    GUICtrlSetData($idViewUnattendPartitionTypeRdoC1, i18nGet("unattend.partition.type.gpt.label", "GPT"))
    GUICtrlSetData($idViewUnattendPartitionTypeRdoC2, i18nGet("unattend.partition.type.mbr.label", "MBR"))
    GUICtrlSetData($idViewUnattendPartitionTblLbl, i18nGet("unattend.partition.tbl.label", "Partitions Table: "))

    GUICtrlSetData($hViewUnattendBypassGroup, i18nGet("unattend.bypass.title", "Bypass Hardware Checks"))
    GUICtrlSetData($idViewUnattendBypassAllCkbx, i18nGet("unattend.bypass.all.label", "Select All"))
    GUICtrlSetData($idViewUnattendBypassTPMCkbx, i18nGet("unattend.bypass.tpm.label", "Bypass TPM"))
    GUICtrlSetData($idViewUnattendBypassRAMCkbx, i18nGet("unattend.bypass.ram.label", "Bypass RAM"))
    GUICtrlSetData($idViewUnattendBypassSBCkbx, i18nGet("unattend.bypass.sb.label", "Bypass Secure Boot"))
    GUICtrlSetData($idViewUnattendBypassCPUCkbx, i18nGet("unattend.bypass.cpu.label", "Bypass CPU"))
    GUICtrlSetData($idViewUnattendBypassStorageCkbx, i18nGet("unattend.bypass.storage.label", "Bypass Storage"))
    GUICtrlSetData($idViewUnattendBypassDiskCkbx, i18nGet("unattend.bypass.disk.label", "Bypass Disk"))

    GUICtrlSetData($hViewUnattendOOBEGroup, i18nGet("unattend.oobe.title", "Out-of-box-experience Settings"))
    GUICtrlSetData($idViewUnattendOOBEAllCkbx, i18nGet("unattend.oobe.all.label", "Select All"))
    GUICtrlSetData($idViewUnattendOOBEEULACkbx, i18nGet("unattend.oobe.eula.label", "Hide EULA Screen"))
    GUICtrlSetData($idViewUnattendOOBELocalAccCkbx, i18nGet("unattend.oobe.localacc.label", "Hide Local Account Screen"))
    GUICtrlSetData($idViewUnattendOOBEOnlAccCkbx, i18nGet("unattend.oobe.onlacc.label", "Hide Online Account Screen"))
    GUICtrlSetData($idViewUnattendOOBEWirelessCkbx, i18nGet("unattend.oobe.wireless.label", "Hide Wireless Screen"))
    GUICtrlSetData($idViewUnattendOOBEBitLockerCkbx, i18nGet("unattend.oobe.bitlocker.label", "Disable BitLocker"))
    GUICtrlSetData($idViewUnattendOOBEPrivacyLbl, i18nGet("unattend.oobe.privacy.label", "Privacy Settings: "))
    GUICtrlSetData($idViewUnattendOOBEPrivacyRdoC1, i18nGet("unattend.oobe.privacy.express.label", "Express"))
    GUICtrlSetData($idViewUnattendOOBEPrivacyRdoC2, i18nGet("unattend.oobe.privacy.recom.label", "Recommended"))
    GUICtrlSetData($idViewUnattendOOBEPrivacyRdoC3, i18nGet("unattend.oobe.privacy.disable.label", "Disable All"))

    GUICtrlSetData($hViewUnattendLocalAccGroup, i18nGet("unattend.localacc.title", "Local Accounts Management"))
    GUICtrlSetData($idViewUnattendLocalAccTblLbl, i18nGet("unattend.localacc.tbl.label", "Accounts Table: "))

    GUICtrlSetData($hViewUnattendBloatwareGroup, i18nGet("unattend.bloatware.title", "Bloatwares Removal"))
    GUICtrlSetData($idViewUnattendBloatwareAllCkbx, i18nGet("unattend.bloatware.all.label", "Select All"))
    GUICtrlSetData($idViewUnattendBloatwareTblLbl, i18nGet("unattend.bloatware.tbl.label", "Bloatwares Table: "))
    GUICtrlSetData($idViewUnattendBloatwareTblList, i18nGet("unattend.bloatware.list.col1.label", "Package Name") & "|" & i18nGet("unattend.bloatware.list.col2.label", "Description"))

    GUICtrlSetData($hViewUnattendScriptsGroup, i18nGet("unattend.scripts.title", "Custom Scripts"))
    GUICtrlSetData($idViewUnattendScriptsEditLbl, i18nGet("unattend.scripts.edit.label", "PowerShell Scripts:"))

    If $g_hCurrentView = $hViewUnattend Then
        GUICtrlSetData($a_idToolBarBtn[0], i18nGet("clear.btn.title", "Clear"))
        GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.title", "Cancel"))
        GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("save.btn.title", "Save"))
    EndIf
EndFunc

Func viewUnattendToolBar()
    ; Button Index 0: [Clear]
    GUICtrlSetData($a_idToolBarBtn[0], i18nGet("clear.btn.title", "Clear"))
    GUICtrlSetState($a_idToolBarBtn[0], $GUI_SHOW)

    ; Button Index 8: [Save]
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("save.btn.title", "Save"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 2], $GUI_SHOW)

    ; Button Index 9: [Cancel]
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.title", "Cancel"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 1], $GUI_SHOW)    
EndFunc

Func viewUnattendApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hViewUnattend)
    
    GUICtrlSetColor($idViewUnattendTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewUnattendTitle, themeColor("main.view.bg"))

    Local $aLabels[42] = [ _
        $idViewUnattendEditionLbl, _
        $idViewUnattendProductKeyLbl, _
        $idViewUnattendArchLbl, _
        $idViewUnattendPcNameLbl, _
        $idViewUnattendSysLangLbl, _
        $idViewUnattendUsrLangLbl, _
        $idViewUnattendSysUsrLangSameCkbx, _
        $idViewUnattendUILangLbl, _
        $idViewUnattendKbLayoutLbl, _
        $idViewUnattendTZLbl, _
        $idViewUnattendPartitionManLbl, _
        $idViewUnattendPartitionManRdoC1, _
        $idViewUnattendPartitionManRdoC2, _
        $idViewUnattendPartitionManRdoC3, _
        $idViewUnattendPartitionDiskIDLbl, _
        $idViewUnattendPartitionTypeLbl, _
        $idViewUnattendPartitionTypeRdoC1, _
        $idViewUnattendPartitionTypeRdoC2, _
        $idViewUnattendPartitionTblLbl, _
        $idViewUnattendBypassAllCkbx, _
        $idViewUnattendBypassTPMCkbx, _
        $idViewUnattendBypassRAMCkbx, _
        $idViewUnattendBypassSBCkbx, _
        $idViewUnattendBypassCPUCkbx, _
        $idViewUnattendBypassStorageCkbx, _
        $idViewUnattendBypassDiskCkbx, _
        $idViewUnattendOOBEAllCkbx, _
        $idViewUnattendOOBEEULACkbx, _
        $idViewUnattendOOBELocalAccCkbx, _
        $idViewUnattendOOBEOnlAccCkbx, _
        $idViewUnattendOOBEWirelessCkbx, _
        $idViewUnattendOOBEBitLockerCkbx, _
        $idViewUnattendOOBEPrivacyLbl, _
        $idViewUnattendOOBEPrivacyRdoC1, _
        $idViewUnattendOOBEPrivacyRdoC2, _
        $idViewUnattendOOBEPrivacyRdoC3, _
        $idViewUnattendLocalAccTblLbl, _
        $idViewUnattendBloatwareAllCkbx, _
        $idViewUnattendBloatwareTblLbl, _
        $idViewUnattendBloatwareTblList, _
        $idViewUnattendScriptsEditLbl, _
        $idViewUnattendScriptsEditEdit _
    ]
    For $i = 0 to UBound($aLabels) - 1
        GUICtrlSetColor($aLabels[$i], themeColor("text.primary"))
        GUICtrlSetBkColor($aLabels[$i], themeColor("main.view.bg"))
    Next
    
EndFunc

Func viewUnattendHandleEvent($idMsg)
    Switch $idMsg
        Case $a_idToolBarBtn[0]
            ; [Clear] - Reset all fields to default template values from sample.xml
            viewUnattendLoadValues($rUnattendSampleXml)
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.cleared", "Reset to default values"))

        Case $a_idToolBarBtn[$iToolBarBtnCol - 2]
            ; [Save] - Write current form values to AutoInstaller.xml
            If viewUnattendSaveValues($rUnattendAutoXml) Then
                appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.saved", "Saved"))
            Else
                appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.error", "Error"))
            EndIf

        Case $a_idToolBarBtn[$iToolBarBtnCol - 1]
            ; [Cancel] - Discard changes & restore saved AutoInstaller.xml values
            viewUnattendLoadValues($rUnattendAutoXml)
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.ready", "Ready"))
    EndSwitch
EndFunc