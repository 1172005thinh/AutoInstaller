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
#include <StaticConstants.au3>
#include <SliderConstants.au3>
#include <SendMessage.au3>


; Controls
#include "../controls/button.au3"

; Modules
#include "../modules/i18n.au3"
#include "../modules/theme.au3"
#include "../modules/config.au3"
#include "../modules/scroll.au3"
#include "../modules/xml.au3"
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
Global Const $g_sViewUnattendEditions = "Windows 11 Home|Windows 11 Home N|Windows 11 Home Single Language|Windows 11 Education|Windows 11 Education N|Windows 11 Pro|Windows 11 Pro N|Windows 11 Pro Education|Windows 11 Pro Education N|Windows 11 Pro for Workstations|Windows 11 Pro N for Workstations"
Global $idViewUnattendProductKeyLbl = 0, $idViewUnattendProductKeyInput = 0
Global $idViewUnattendArchLbl = 0, $idViewUnattendArchRdoC1 = 0, $idViewUnattendArchRdoC2 = 0
Global $idViewUnattendPCNameLbl = 0, $idViewUnattendPCNameInput = 0

Global $hViewUnattendRegionGroup = 0
Global $idViewUnattendSysLangLbl = 0, $idViewUnattendSysLangCmb = 0
Global $idViewUnattendUsrLangLbl = 0, $idViewUnattendUsrLangCmb = 0
Global $idViewUnattendSysUsrLangSameCkbx = 0
Global $idViewUnattendUILangLbl = 0, $idViewUnattendUILangCmb = 0
Global $idViewUnattendKbLayoutLbl = 0, $idViewUnattendKbLayoutCmb = 0 
Global $idViewUnattendTZLbl = 0, $idViewUnattendTZCmb = 0
Global Const $g_sViewUnattendTimeZones = _
    "(UTC-11:00) UTC-11|(UTC-10:00) Hawaiian Standard Time|(UTC-08:00) Pacific Standard Time|(UTC-07:00) Mountain Standard Time|" & _
    "(UTC-06:00) Central America Standard Time|(UTC-06:00) Central Standard Time (Mexico)|(UTC-05:00) Eastern Standard Time|(UTC-05:00) SA Pacific Standard Time|" & _
    "(UTC-04:30) Venezuela Standard Time|(UTC-04:00) Atlantic Standard Time|(UTC-04:00) Paraguay Standard Time|(UTC-04:00) SA Western Standard Time|" & _
    "(UTC-03:00) Argentina Standard Time|(UTC-03:00) E. South America Standard Time|(UTC-03:00) Greenland Standard Time|(UTC-03:00) Montevideo Standard Time|" & _
    "(UTC-03:00) Pacific SA Standard Time|(UTC-03:00) SA Eastern Standard Time|(UTC-02:00) UTC-02|(UTC-01:00) Cape Verde Standard Time|" & _
    "(UTC) GMT Standard Time|(UTC) Greenwich Standard Time|(UTC) Morocco Standard Time|(UTC) UTC|" & _
    "(UTC+01:00) Central Europe Standard Time|(UTC+01:00) Central European Standard Time|(UTC+01:00) Namibia Standard Time|(UTC+01:00) Romance Standard Time|" & _
    "(UTC+01:00) W. Central Africa Standard Time|(UTC+01:00) W. Europe Standard Time|(UTC+02:00) E. Europe Standard Time|(UTC+02:00) Egypt Standard Time|" & _
    "(UTC+02:00) FLE Standard Time|(UTC+02:00) GTB Standard Time|(UTC+02:00) Israel Standard Time|(UTC+02:00) Jordan Standard Time|" & _
    "(UTC+02:00) Middle East Standard Time|(UTC+02:00) South Africa Standard Time|(UTC+02:00) Syria Standard Time|(UTC+02:00) Türkiye Standard Time|" & _
    "(UTC+03:00) Arab Standard Time|(UTC+03:00) Arabic Standard Time|(UTC+03:00) Belarus Standard Time|(UTC+03:00) E. Africa Standard Time|" & _
    "(UTC+03:00) Russian Standard Time|(UTC+03:30) Iran Standard Time|(UTC+04:00) Arabian Standard Time|(UTC+04:00) Azerbaijan Standard Time|" & _
    "(UTC+04:00) Caucasus Standard Time|(UTC+04:00) Georgian Standard Time|(UTC+04:00) Mauritius Standard Time|(UTC+04:30) Afghanistan Standard Time|" & _
    "(UTC+05:00) Pakistan Standard Time|(UTC+05:00) West Asia Standard Time|(UTC+05:30) India Standard Time|(UTC+05:30) Sri Lanka Standard Time|" & _
    "(UTC+05:45) Nepal Standard Time|(UTC+06:00) Bangladesh Standard Time|(UTC+06:00) Central Asia Standard Time|(UTC+06:30) Myanmar Standard Time|" & _
    "(UTC+07:00) SE Asia Standard Time|(UTC+08:00) China Standard Time|(UTC+08:00) Singapore Standard Time|(UTC+08:00) Taipei Standard Time|" & _
    "(UTC+08:00) Ulaanbaatar Standard Time|(UTC+09:00) Korea Standard Time|(UTC+09:00) Tokyo Standard Time|(UTC+10:00) AUS Eastern Standard Time|" & _
    "(UTC+10:00) West Pacific Standard Time|(UTC+11:00) Central Pacific Standard Time|(UTC+12:00) Fiji Standard Time|(UTC+12:00) New Zealand Standard Time|" & _
    "(UTC+12:00) UTC+12|(UTC+13:00) Samoa Standard Time|(UTC+13:00) Tonga Standard Time"

Global $hViewUnattendPartitionGroup = 0
Global $idViewUnattendPartitionManLbl = 0, $idViewUnattendPartitionManSlider = 0
Global $idViewUnattendPartitionManManualLbl = 0, $idViewUnattendPartitionManHybridLbl = 0, $idViewUnattendPartitionManAutoLbl = 0
Global $idViewUnattendPartitionDiskIDLbl = 0, $idViewUnattendPartitionDiskIDInput = 0
Global $idViewUnattendPartitionTypeLbl = 0, $idViewUnattendPartitionTypeRdoC1 = 0, $idViewUnattendPartitionTypeRdoC2 = 0
Global $idViewUnattendPartitionTblLbl = 0, $idViewUnattendPartitionTblList = 0, $hViewUnattendPartitionTblList = 0
Global $idViewUnattendPartResetBtn = 0
Global $idViewUnattendPartTypeCmb = 0, $idViewUnattendPartLabelInput = 0, $idViewUnattendPartSizeInput = 0, $idViewUnattendPartLetterInput = 0, $idViewUnattendPartFormatCmb = 0
Global $idViewUnattendPartAddBtn = 0, $idViewUnattendPartDeleteBtn = 0, $idViewUnattendPartClearBtn = 0, $idViewUnattendPartSaveBtn = 0, $idViewUnattendPartCancelBtn = 0
Global $idViewUnattendPartitionOSPartIDLbl = 0, $idViewUnattendPartitionOSPartIDInput = 0

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
Global $idViewUnattendLocalAccTblLbl = 0, $idViewUnattendLocalAccTblList = 0, $hViewUnattendLocalAccTblList = 0
Global $idViewUnattendAccResetBtn = 0
Global $idViewUnattendAccTypeCmb = 0, $idViewUnattendAccNameInput = 0, $idViewUnattendAccDispNameInput = 0, $idViewUnattendAccPassInput = 0
Global $idViewUnattendAccAddBtn = 0, $idViewUnattendAccDeleteBtn = 0, $idViewUnattendAccClearBtn = 0, $idViewUnattendAccSaveBtn = 0, $idViewUnattendAccCancelBtn = 0
Global $idViewUnattendLocalAccAutoLogonLbl = 0, $idViewUnattendLocalAccAutoLogonInput = 0

Global $hViewUnattendBloatwareGroup = 0
Global $idViewUnattendBloatwareTblLbl = 0, $idViewUnattendBloatwareResetBtn = 0, $idViewUnattendBloatwareTblList = 0
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Helper Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _SetCueBannerW($hWnd, $sText, $bOnFocus = True)
    If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
    Local $tText = DllStructCreate("wchar[" & (StringLen($sText) + 1) & "]")
    DllStructSetData($tText, 1, $sText)
    Return _SendMessage($hWnd, $EM_SETCUEBANNER, $bOnFocus, $tText, 0, "wparam", "struct*") = 1
EndFunc

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
    GUICtrlSetData($idViewUnattendEditionCmb, $g_sViewUnattendEditions, "Windows 11 Pro")

    ; Product Key
    $iItemY += $iRowH
    $idViewUnattendProductKeyLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendProductKeyInput = GUICtrlCreateInput("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    
    ; Architecture
    $iItemY += $iRowH
    $idViewUnattendArchLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendArchRdoC1 = GUICtrlCreateRadio("", $iP * 3 + $iLblW, $iItemY - $iPx, $iInputW / 2 - $iP, $iLblH + $iPx)
    $idViewUnattendArchRdoC2 = GUICtrlCreateRadio("", $iP * 3 + $iLblW + $iInputW / 2 + $iP, $iItemY - $iPx, $iInputW / 2 - $iP, $iLblH + $iPx)
    GUICtrlSetState($idViewUnattendArchRdoC1, $GUI_CHECKED)

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
    GUICtrlSetData($idViewUnattendTZCmb, $g_sViewUnattendTimeZones, "(UTC+07:00) SE Asia Standard Time")

    ;GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; Initialize Partition Group
    Local $iPartListH = $iRowH * 5
    $iX = $iP
    $iY += $iGroupH + $iP
    $iGroupH = 8 * $iRowH + $iPartListH + 5 * $iP
    $hViewUnattendPartitionGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iGroupH)

    ; Partition Automation Slider (Manual -> Hybrid -> Automated)
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewUnattendPartitionManLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendPartitionManSlider = GUICtrlCreateSlider($iP * 3 + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetLimit($idViewUnattendPartitionManSlider, 2, 0)
    GUICtrlSetData($idViewUnattendPartitionManSlider, 2)

    Local $iTickLblY = $iItemY + $iLblH + $iPx
    Local $iTickColW = $iInputW / 3
    $idViewUnattendPartitionManManualLbl = GUICtrlCreateLabel("", $iP * 3 + $iLblW, $iTickLblY, $iTickColW, $iLblH)
    $idViewUnattendPartitionManHybridLbl = GUICtrlCreateLabel("", $iP * 3 + $iLblW + $iTickColW, $iTickLblY, $iTickColW, $iLblH, $SS_CENTER)
    $idViewUnattendPartitionManAutoLbl = GUICtrlCreateLabel("", $iP * 3 + $iLblW + $iTickColW * 2, $iTickLblY, $iTickColW, $iLblH, $SS_RIGHT)

    ; Partition Disk ID
    $iItemY += $iRowH + $iLblH
    $idViewUnattendPartitionDiskIDLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendPartitionDiskIDInput = GUICtrlCreateInput("$$VT_WINDOWS_DISK_1ST_NONVTOY$$", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)

    ; Partition Type
    $iItemY += $iRowH
    $idViewUnattendPartitionTypeLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendPartitionTypeRdoC1 = GUICtrlCreateRadio("", $iP * 3 + $iLblW, $iItemY - $iPx, $iInputW / 2 - $iP, $iLblH + $iPx)
    $idViewUnattendPartitionTypeRdoC2 = GUICtrlCreateRadio("", $iP * 3 + $iLblW + $iInputW / 2 + $iP, $iItemY - $iPx, $iInputW / 2 - $iP, $iLblH + $iPx)
    GUICtrlSetState($idViewUnattendPartitionTypeRdoC1, $GUI_CHECKED)
    GUIStartGroup()

    ; Partition Table Header Row
    $iItemY += $iRowH
    $idViewUnattendPartitionTblLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    Local $iPartListW = $iContentW - $iP * 4
    Local $iBtnW = ($iPartListW * 92 / 100 - 4 * $iP) / 5
    $idViewUnattendPartResetBtn = GUICtrlCreateButton(i18nGet("unattend.partition.btn.reset", "Reset"), ($iX + $iPartListW) - $iBtnW, $iItemY - $iPx, $iBtnW, $iBtnH)

    ; Partition Table ListView (6 cols, max 8 rows)
    $iItemY += $iRowH + $iP
    $idViewUnattendPartitionTblList = GUICtrlCreateListView( _
        i18nGet("unattend.partition.col.id", "ID") & "|" & _
        i18nGet("unattend.partition.col.type", "Type") & "|" & _
        i18nGet("unattend.partition.col.label", "Label") & "|" & _
        i18nGet("unattend.partition.col.size", "Size MB") & "|" & _
        i18nGet("unattend.partition.col.letter", "Letter") & "|" & _
        i18nGet("unattend.partition.col.format", "Format"), _
        $iX, $iItemY, $iPartListW, $iPartListH)
    $hViewUnattendPartitionTblList = GUICtrlGetHandle($idViewUnattendPartitionTblList)
    _GUICtrlListView_SetExtendedListViewStyle($idViewUnattendPartitionTblList, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))
    Local $iPartCol0W = Int($iPartListW * 8 / 100)
    Local $iPartCol1W = Int($iPartListW * 18 / 100)
    Local $iPartCol2W = Int($iPartListW * 28 / 100)
    Local $iPartCol3W = Int($iPartListW * 20 / 100)
    Local $iPartCol4W = Int($iPartListW * 11 / 100)
    Local $iPartCol5W = $iPartListW - ($iPartCol0W + $iPartCol1W + $iPartCol2W + $iPartCol3W + $iPartCol4W) - $iPx
    _GUICtrlListView_SetColumnWidth($idViewUnattendPartitionTblList, 0, $iPartCol0W)
    _GUICtrlListView_SetColumnWidth($idViewUnattendPartitionTblList, 1, $iPartCol1W)
    _GUICtrlListView_SetColumnWidth($idViewUnattendPartitionTblList, 2, $iPartCol2W)
    _GUICtrlListView_SetColumnWidth($idViewUnattendPartitionTblList, 3, $iPartCol3W)
    _GUICtrlListView_SetColumnWidth($idViewUnattendPartitionTblList, 4, $iPartCol4W)
    _GUICtrlListView_SetColumnWidth($idViewUnattendPartitionTblList, 5, $iPartCol5W)

    ; Insert default GPT partition rows
    GUICtrlCreateListViewItem("1|EFI|System|512||FAT32", $idViewUnattendPartitionTblList)
    GUICtrlCreateListViewItem("2|MSR||16||", $idViewUnattendPartitionTblList)
    GUICtrlCreateListViewItem("3|Primary|Windows|102400|C|NTFS", $idViewUnattendPartitionTblList)
    GUICtrlCreateListViewItem("4|Recovery|Recovery|1024||NTFS", $idViewUnattendPartitionTblList)
    _GUICtrlListView_SetItemSelected($idViewUnattendPartitionTblList, 0, True, True)

    ; Partition Input Edit Row (aligned with columns 1..5)
    $iItemY += $iPartListH + $iP
    Local $iEditX = $iX + $iPartCol0W
    $idViewUnattendPartTypeCmb = GUICtrlCreateCombo("", $iEditX + $iPx, $iItemY, $iPartCol1W - 2 * $iPx, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendPartTypeCmb, "EFI|MSR|Primary|Extended|Logical|Recovery", "EFI")
    $iEditX += $iPartCol1W
    $idViewUnattendPartLabelInput = GUICtrlCreateInput("System", $iEditX + $iPx, $iItemY, $iPartCol2W - 2 * $iPx, $iLblH + $iPx * 2)
    $iEditX += $iPartCol2W
    $idViewUnattendPartSizeInput = GUICtrlCreateInput("512", $iEditX + $iPx, $iItemY, $iPartCol3W - 2 * $iPx, $iLblH + $iPx * 2, $ES_NUMBER)
    $iEditX += $iPartCol3W
    $idViewUnattendPartLetterInput = GUICtrlCreateInput("", $iEditX + $iPx, $iItemY, $iPartCol4W - 2 * $iPx, $iLblH + $iPx * 2)
    GUICtrlSetLimit($idViewUnattendPartLetterInput, 1)
    $iEditX += $iPartCol4W
    $idViewUnattendPartFormatCmb = GUICtrlCreateCombo("", $iEditX + $iPx, $iItemY, $iPartCol5W, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendPartFormatCmb, "NTFS|FAT32", "FAT32")

    ; Partition Action Buttons Row (right-aligned to table width)
    $iItemY += $iRowH
    Local $iBtnRowW = 5 * $iBtnW + 4 * $iP
    Local $iBtnStartX = ($iX + $iPartListW) - $iBtnRowW
    $idViewUnattendPartAddBtn = GUICtrlCreateButton(i18nGet("unattend.partition.btn.add", "Add"), $iBtnStartX, $iItemY, $iBtnW, $iBtnH)
    $idViewUnattendPartDeleteBtn = GUICtrlCreateButton(i18nGet("unattend.partition.btn.delete", "Delete"), $iBtnStartX + $iBtnW + $iP, $iItemY, $iBtnW, $iBtnH)
    $idViewUnattendPartClearBtn = GUICtrlCreateButton(i18nGet("unattend.partition.btn.clear", "Clear"), $iBtnStartX + ($iBtnW + $iP) * 2, $iItemY, $iBtnW, $iBtnH)
    $idViewUnattendPartSaveBtn = GUICtrlCreateButton(i18nGet("unattend.partition.btn.save", "Save"), $iBtnStartX + ($iBtnW + $iP) * 3, $iItemY, $iBtnW, $iBtnH)
    $idViewUnattendPartCancelBtn = GUICtrlCreateButton(i18nGet("unattend.partition.btn.cancel", "Cancel"), $iBtnStartX + ($iBtnW + $iP) * 4, $iItemY, $iBtnW, $iBtnH)

    ; Install OS on Partition ID Row
    $iItemY += $iRowH + $iP * 2
    $idViewUnattendPartitionOSPartIDLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendPartitionOSPartIDInput = GUICtrlCreateInput("3", $iX + $iLblW, $iItemY - $iPx, $iInputW / 3, $iLblH + $iPx * 2, $ES_NUMBER)
    GUICtrlSetLimit($idViewUnattendPartitionOSPartIDInput, 1)
    
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
    GUICtrlSetState($idViewUnattendBypassAllCkbx, $GUI_CHECKED)

    ; Bypass TPM
    $iItemY += $iRowH
    $idViewUnattendBypassTPMCkbx = GUICtrlCreateCheckbox("", $iX, $iItemY, $iColW, $iLblH)
    GUICtrlSetState($idViewUnattendBypassTPMCkbx, $GUI_CHECKED)
    
    ; Bypass RAM
    $idViewUnattendBypassRAMCkbx = GUICtrlCreateCheckbox("", $iX, $iItemY + $iRowH, $iColW, $iLblH)
    GUICtrlSetState($idViewUnattendBypassRAMCkbx, $GUI_CHECKED)

    ; Bypass Secure Boot
    $idViewUnattendBypassSBCkbx = GUICtrlCreateCheckbox("", $iX, $iItemY + $iRowH * 2, $iColW, $iLblH)
    GUICtrlSetState($idViewUnattendBypassSBCkbx, $GUI_CHECKED)

    ; Bypass CPU
    Local $iRightColX = $iP * 3 + $iColW + $iP
    $idViewUnattendBypassCPUCkbx = GUICtrlCreateCheckbox("", $iRightColX, $iItemY, $iColW, $iLblH)
    GUICtrlSetState($idViewUnattendBypassCPUCkbx, $GUI_CHECKED)

    ; Bypass Storage
    $idViewUnattendBypassStorageCkbx = GUICtrlCreateCheckbox("", $iRightColX, $iItemY + $iRowH, $iColW, $iLblH)
    GUICtrlSetState($idViewUnattendBypassStorageCkbx, $GUI_CHECKED)

    ; Bypass Disk
    $idViewUnattendBypassDiskCkbx = GUICtrlCreateCheckbox("", $iRightColX, $iItemY + $iRowH * 2, $iColW, $iLblH)
    GUICtrlSetState($idViewUnattendBypassDiskCkbx, $GUI_CHECKED)

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
    GUICtrlSetState($idViewUnattendOOBEAllCkbx, $GUI_CHECKED)

    ; Hide EULA
    $iItemY += $iRowH
    $idViewUnattendOOBEEULACkbx = GUICtrlCreateCheckbox("", $iX, $iItemY, $iColW, $iLblH)
    GUICtrlSetState($idViewUnattendOOBEEULACkbx, $GUI_CHECKED)

    ; Hide Local Account
    $idViewUnattendOOBELocalAccCkbx = GUICtrlCreateCheckbox("", $iX, $iItemY + $iRowH, $iColW, $iLblH)
    GUICtrlSetState($idViewUnattendOOBELocalAccCkbx, $GUI_CHECKED)
    
    ; Hide Online Account
    $idViewUnattendOOBEOnlAccCkbx = GUICtrlCreateCheckbox("", $iX, $iItemY + $iRowH * 2, $iColW, $iLblH)
    GUICtrlSetState($idViewUnattendOOBEOnlAccCkbx, $GUI_CHECKED)

    ; Hide Wireless
    $idViewUnattendOOBEWirelessCkbx = GUICtrlCreateCheckbox("", $iRightColX, $iItemY, $iColW, $iLblH)
    GUICtrlSetState($idViewUnattendOOBEWirelessCkbx, $GUI_CHECKED)

    ; Disable BitLocker
    $idViewUnattendOOBEBitLockerCkbx = GUICtrlCreateCheckbox("", $iRightColX, $iItemY + $iRowH, $iColW, $iLblH)
    GUICtrlSetState($idViewUnattendOOBEBitLockerCkbx, $GUI_CHECKED)

    ; Privacy Protect
    $iItemY += $iRowH * 3
    $idViewUnattendOOBEPrivacyLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendOOBEPrivacyRdoC1 = GUICtrlCreateRadio("", $iP * 3 + $iLblW, $iItemY - $iPx, $iInputW / 3 - $iP * 2, $iLblH + $iPx)
    $idViewUnattendOOBEPrivacyRdoC2 = GUICtrlCreateRadio("", $iP * 3 + $iLblW + $iInputW / 3 + $iP, $iItemY - $iPx, $iInputW / 3 - $iP * 2, $iLblH + $iPx)
    $idViewUnattendOOBEPrivacyRdoC3 = GUICtrlCreateRadio("", $iP * 3 + $iLblW + $iInputW / 3 * 2 + $iP * 2, $iItemY - $iPx, $iInputW / 3 - $iP * 2, $iLblH + $iPx)
    GUICtrlSetState($idViewUnattendOOBEPrivacyRdoC1, $GUI_CHECKED)
    GUIStartGroup()

    ;GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; Initialize Local Account Group
    Local $iAccListH = $iRowH * 5
    $iX = $iP
    $iY += $iGroupH + $iP
    $iGroupH = 5 * $iRowH + $iAccListH + 3 * $iP
    $hViewUnattendLocalAccGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iGroupH)

    ; Local Account Table Header Row
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewUnattendLocalAccTblLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iColW, $iLblH)
    Local $iAccListW = $iContentW - $iP * 4
    $iBtnW = ($iAccListW * 92 / 100 - 4 * $iP) / 5
    $idViewUnattendAccResetBtn = GUICtrlCreateButton(i18nGet("unattend.localacc.btn.reset", "Reset"), ($iX + $iAccListW) - $iBtnW, $iItemY - $iPx, $iBtnW, $iBtnH)

    ; Accounts Table ListView (5 cols, max 8 rows)
    $iItemY += $iRowH + $iP
    $idViewUnattendLocalAccTblList = GUICtrlCreateListView( _
        i18nGet("unattend.localacc.col.id", "ID") & "|" & _
        i18nGet("unattend.localacc.col.type", "Type") & "|" & _
        i18nGet("unattend.localacc.col.name", "Name") & "|" & _
        i18nGet("unattend.localacc.col.displayname", "DisplayName") & "|" & _
        i18nGet("unattend.localacc.col.password", "Password"), _
        $iX, $iItemY, $iAccListW, $iAccListH)
    $hViewUnattendLocalAccTblList = GUICtrlGetHandle($idViewUnattendLocalAccTblList)
    _GUICtrlListView_SetExtendedListViewStyle($idViewUnattendLocalAccTblList, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))
    Local $iAccCol0W = Int($iAccListW * 8 / 100)
    Local $iAccCol1W = Int($iAccListW * 18 / 100)
    Local $iAccCol2W = Int($iAccListW * 24 / 100)
    Local $iAccCol3W = Int($iAccListW * 24 / 100)
    Local $iAccCol4W = $iAccListW - ($iAccCol0W + $iAccCol1W + $iAccCol2W + $iAccCol3W) - $iPx
    _GUICtrlListView_SetColumnWidth($idViewUnattendLocalAccTblList, 0, $iAccCol0W)
    _GUICtrlListView_SetColumnWidth($idViewUnattendLocalAccTblList, 1, $iAccCol1W)
    _GUICtrlListView_SetColumnWidth($idViewUnattendLocalAccTblList, 2, $iAccCol2W)
    _GUICtrlListView_SetColumnWidth($idViewUnattendLocalAccTblList, 3, $iAccCol3W)
    _GUICtrlListView_SetColumnWidth($idViewUnattendLocalAccTblList, 4, $iAccCol4W)

    ; Default account item (unhidden plain-text password)
    GUICtrlCreateListViewItem("1|Administrator|Admin|Administrator|Password123", $idViewUnattendLocalAccTblList)
    _GUICtrlListView_SetItemSelected($idViewUnattendLocalAccTblList, 0, True, True)

    ; Accounts Input Edit Row (aligned with columns 1..4)
    $iItemY += $iAccListH + $iP
    Local $iAccEditX = $iX + $iAccCol0W
    $idViewUnattendAccTypeCmb = GUICtrlCreateCombo("", $iAccEditX + $iPx, $iItemY, $iAccCol1W - 2 * $iPx, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendAccTypeCmb, "Administrator|User", "Administrator")
    $iAccEditX += $iAccCol1W
    $idViewUnattendAccNameInput = GUICtrlCreateInput("Admin", $iAccEditX + $iPx, $iItemY, $iAccCol2W - 2 * $iPx, $iLblH + $iPx * 2)
    $iAccEditX += $iAccCol2W
    $idViewUnattendAccDispNameInput = GUICtrlCreateInput("Administrator", $iAccEditX + $iPx, $iItemY, $iAccCol3W - 2 * $iPx, $iLblH + $iPx * 2)
    $iAccEditX += $iAccCol3W
    $idViewUnattendAccPassInput = GUICtrlCreateInput("Password123", $iAccEditX + $iPx, $iItemY, $iAccCol4W, $iLblH + $iPx * 2)

    ; Accounts Action Buttons Row (right-aligned to table width)
    $iItemY += $iRowH
    Local $iAccBtnStartX = ($iX + $iAccListW) - $iBtnRowW
    $idViewUnattendAccAddBtn = GUICtrlCreateButton(i18nGet("unattend.localacc.btn.add", "Add"), $iAccBtnStartX, $iItemY, $iBtnW, $iBtnH)
    $idViewUnattendAccDeleteBtn = GUICtrlCreateButton(i18nGet("unattend.localacc.btn.delete", "Delete"), $iAccBtnStartX + $iBtnW + $iP, $iItemY, $iBtnW, $iBtnH)
    $idViewUnattendAccClearBtn = GUICtrlCreateButton(i18nGet("unattend.localacc.btn.clear", "Clear"), $iAccBtnStartX + ($iBtnW + $iP) * 2, $iItemY, $iBtnW, $iBtnH)
    $idViewUnattendAccSaveBtn = GUICtrlCreateButton(i18nGet("unattend.localacc.btn.save", "Save"), $iAccBtnStartX + ($iBtnW + $iP) * 3, $iItemY, $iBtnW, $iBtnH)
    $idViewUnattendAccCancelBtn = GUICtrlCreateButton(i18nGet("unattend.localacc.btn.cancel", "Cancel"), $iAccBtnStartX + ($iBtnW + $iP) * 4, $iItemY, $iBtnW, $iBtnH)

    ; Auto-Logon Account Row
    $iItemY += $iRowH + $iP * 2
    $idViewUnattendLocalAccAutoLogonLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    $idViewUnattendLocalAccAutoLogonInput = GUICtrlCreateInput("1", $iX + $iLblW, $iItemY - $iPx, $iInputW / 3, $iLblH + $iPx * 2, $ES_NUMBER)
    GUICtrlSetLimit($idViewUnattendLocalAccAutoLogonInput, 1)
    
    ;GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; Initialize Bloatware Group
    $iX = $iP
    $iY += $iGroupH + $iP
    $iGroupH = $iRowH * 8 + $iP * 4
    $hViewUnattendBloatwareGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iGroupH)

    ; Bloatware List Label & Reset Button Row
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewUnattendBloatwareTblLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iColW, $iLblH)
    Local $iListW = $iContentW - $iP * 4
    Local $iListH = $iRowH * 7 - $iP * 2
    $idViewUnattendBloatwareResetBtn = GUICtrlCreateButton(i18nGet("unattend.bloatware.btn.reset", "Reset"), ($iX + $iListW) - $iBtnW, $iItemY - $iPx, $iBtnW, $iBtnH)

    ; Bloatware List
    $iItemY += $iRowH + $iP
    $idViewUnattendBloatwareTblList = GUICtrlCreateListView(i18nGet("unattend.bloatware.list.col1.label", "Package Name") & "|" & i18nGet("unattend.bloatware.list.col2.label", "Description"), $iX, $iItemY, $iListW, $iListH)
    _GUICtrlListView_SetExtendedListViewStyle($idViewUnattendBloatwareTblList, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))
    _GUICtrlListView_SetColumnWidth($idViewUnattendBloatwareTblList, 0, $iListW * 45 / 100)
    _GUICtrlListView_SetColumnWidth($idViewUnattendBloatwareTblList, 1, $iListW * 51 / 100)
    For $i = 0 To UBound($a_sKnownBloatwares) - 1
        Local $sPkg = $a_sKnownBloatwares[$i][0]
        Local $sDesc = _UnattendGetBloatwareDesc($sPkg, $a_sKnownBloatwares[$i][1])
        GUICtrlCreateListViewItem($sPkg & "|" & $sDesc, $idViewUnattendBloatwareTblList)
        _GUICtrlListView_SetItemChecked($idViewUnattendBloatwareTblList, $i, True)
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

    GUIRegisterMsg($WM_COMMAND, "unattendOnWM_COMMAND")
    GUIRegisterMsg($WM_NOTIFY,  "unattendOnWM_NOTIFY")

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

    ; Windows Customization
    GUICtrlSetData($hViewUnattendWindowsGroup, i18nGet("unattend.windows.title", "Windows Customization"))

    GUICtrlSetData($idViewUnattendEditionLbl, i18nGet("unattend.windows.edition.label", "Windows Edition: "))
    GUICtrlSetTip($idViewUnattendEditionLbl, i18nGet("unattend.windows.edition.tip", "Select the Windows edition to install"))
    GUICtrlSetTip($idViewUnattendEditionCmb, i18nGet("unattend.windows.edition.tip", "Select the Windows edition to install"))

    GUICtrlSetData($idViewUnattendProductKeyLbl, i18nGet("unattend.windows.productkey.label", "Product Key: "))
    GUICtrlSetTip($idViewUnattendProductKeyLbl, i18nGet("unattend.windows.productkey.tip", "Enter 25-character Windows product key (auto-formatted)"))
    GUICtrlSetTip($idViewUnattendProductKeyInput, i18nGet("unattend.windows.productkey.tip", "Enter 25-character Windows product key (auto-formatted)"))
    _SetCueBannerW($idViewUnattendProductKeyInput, i18nGet("unattend.windows.productkey.placeholder", "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"), True)

    GUICtrlSetData($idViewUnattendArchLbl, i18nGet("unattend.windows.arch.label", "Architecture: "))
    GUICtrlSetTip($idViewUnattendArchLbl, i18nGet("unattend.windows.arch.tip", "Select system CPU architecture"))
    GUICtrlSetData($idViewUnattendArchRdoC1, i18nGet("unattend.windows.arch.x64.label", "x64"))
    GUICtrlSetTip($idViewUnattendArchRdoC1, i18nGet("unattend.windows.arch.x64.tip", "64-bit x86 architecture (AMD64 / Intel 64)"))
    GUICtrlSetData($idViewUnattendArchRdoC2, i18nGet("unattend.windows.arch.arm.label", "ARM"))
    GUICtrlSetTip($idViewUnattendArchRdoC2, i18nGet("unattend.windows.arch.arm.tip", "64-bit ARM architecture (ARM64)"))

    GUICtrlSetData($idViewUnattendPCNameLbl, i18nGet("unattend.windows.pcname.label", "PC Name: "))
    GUICtrlSetTip($idViewUnattendPCNameLbl, i18nGet("unattend.windows.pcname.tip", "Specify computer NetBIOS name (max 15 characters)"))
    GUICtrlSetTip($idViewUnattendPCNameInput, i18nGet("unattend.windows.pcname.tip", "Specify computer NetBIOS name (max 15 characters)"))
    _SetCueBannerW($idViewUnattendPCNameInput, i18nGet("unattend.windows.pcname.placeholder", "e.g. DESKTOP-PC"), True)
    
    ; Language - Region
    GUICtrlSetData($hViewUnattendRegionGroup, i18nGet("unattend.region.title", "Language - Region"))

    GUICtrlSetData($idViewUnattendSysLangLbl, i18nGet("unattend.region.syslang.label", "System Language"))
    GUICtrlSetTip($idViewUnattendSysLangLbl, i18nGet("unattend.region.syslang.tip", "System language for services and default profile"))
    GUICtrlSetTip($idViewUnattendSysLangCmb, i18nGet("unattend.region.syslang.tip", "System language for services and default profile"))

    GUICtrlSetData($idViewUnattendUsrLangLbl, i18nGet("unattend.region.usrlang.label", "User Language"))
    GUICtrlSetTip($idViewUnattendUsrLangLbl, i18nGet("unattend.region.usrlang.tip", "User interface and account locale"))
    GUICtrlSetTip($idViewUnattendUsrLangCmb, i18nGet("unattend.region.usrlang.tip", "User interface and account locale"))

    GUICtrlSetData($idViewUnattendSysUsrLangSameCkbx, i18nGet("unattend.region.sysusrlangsame.label", "Same as System Language"))
    GUICtrlSetTip($idViewUnattendSysUsrLangSameCkbx, i18nGet("unattend.region.sysusrlangsame.tip", "Keep user language synced with system language"))

    GUICtrlSetData($idViewUnattendUILangLbl, i18nGet("unattend.region.uilang.label", "UI Language: "))
    GUICtrlSetTip($idViewUnattendUILangLbl, i18nGet("unattend.region.uilang.tip", "Display language for Windows UI"))
    GUICtrlSetTip($idViewUnattendUILangCmb, i18nGet("unattend.region.uilang.tip", "Display language for Windows UI"))

    GUICtrlSetData($idViewUnattendKbLayoutLbl, i18nGet("unattend.region.kblayout.label", "Keyboard Layout: "))
    GUICtrlSetTip($idViewUnattendKbLayoutLbl, i18nGet("unattend.region.kblayout.tip", "Keyboard input method and layout"))
    GUICtrlSetTip($idViewUnattendKbLayoutCmb, i18nGet("unattend.region.kblayout.tip", "Keyboard input method and layout"))

    GUICtrlSetData($idViewUnattendTZLbl, i18nGet("unattend.region.timezone.label", "Time Zone: "))
    GUICtrlSetTip($idViewUnattendTZLbl, i18nGet("unattend.region.timezone.tip", "Default system time zone"))
    GUICtrlSetTip($idViewUnattendTZCmb, i18nGet("unattend.region.timezone.tip", "Default system time zone"))

    ; Partition Management
    GUICtrlSetData($hViewUnattendPartitionGroup, i18nGet("unattend.partition.title", "Disk Partitions Management"))

    GUICtrlSetData($idViewUnattendPartitionManLbl, i18nGet("unattend.partition.man.label", "Partition Automation: "))
    GUICtrlSetTip($idViewUnattendPartitionManLbl, i18nGet("unattend.partition.man.tip", "Choose partitioning strategy: Auto, Manual, or Hybrid"))
    GUICtrlSetData($idViewUnattendPartitionManManualLbl, i18nGet("unattend.partition.man.manual.label", "Manual"))
    GUICtrlSetTip($idViewUnattendPartitionManManualLbl, i18nGet("unattend.partition.man.manual.tip", "Prompt for manual partitioning during Windows setup"))
    GUICtrlSetData($idViewUnattendPartitionManHybridLbl, i18nGet("unattend.partition.man.hybrid.label", "Hybrid"))
    GUICtrlSetTip($idViewUnattendPartitionManHybridLbl, i18nGet("unattend.partition.man.hybrid.tip", "Apply the custom partition layout while installing Windows"))
    GUICtrlSetData($idViewUnattendPartitionManAutoLbl, i18nGet("unattend.partition.man.auto.label", "Automated"))
    GUICtrlSetTip($idViewUnattendPartitionManAutoLbl, i18nGet("unattend.partition.man.auto.tip", "Automatically wipe disk and create Windows partitions according to the selected partition scheme below"))

    GUICtrlSetData($idViewUnattendPartitionDiskIDLbl, i18nGet("unattend.partition.diskid.label", "Disk ID: "))
    GUICtrlSetTip($idViewUnattendPartitionDiskIDLbl, i18nGet("unattend.partition.diskid.tip", "Target disk index (0, 1, ...) or Ventoy disk variable"))
    GUICtrlSetTip($idViewUnattendPartitionDiskIDInput, i18nGet("unattend.partition.diskid.tip", "Target disk index (0, 1, ...) or Ventoy disk variable"))
    _SetCueBannerW($idViewUnattendPartitionDiskIDInput, i18nGet("unattend.partition.diskid.placeholder", "0 or $$VT_WINDOWS_DISK_1ST_NONVTOY$$"), True)

    GUICtrlSetData($idViewUnattendPartitionTypeLbl, i18nGet("unattend.partition.type.label", "Partition Type: "))
    GUICtrlSetTip($idViewUnattendPartitionTypeLbl, i18nGet("unattend.partition.type.tip", "Disk partition scheme: GPT (UEFI) or MBR (Legacy BIOS)"))
    GUICtrlSetData($idViewUnattendPartitionTypeRdoC1, i18nGet("unattend.partition.type.gpt.label", "GPT"))
    GUICtrlSetTip($idViewUnattendPartitionTypeRdoC1, i18nGet("unattend.partition.type.gpt.tip", "GUID Partition Table for modern UEFI systems"))
    GUICtrlSetData($idViewUnattendPartitionTypeRdoC2, i18nGet("unattend.partition.type.mbr.label", "MBR"))
    GUICtrlSetTip($idViewUnattendPartitionTypeRdoC2, i18nGet("unattend.partition.type.mbr.tip", "Master Boot Record for legacy BIOS systems"))

    GUICtrlSetData($idViewUnattendPartitionTblLbl, i18nGet("unattend.partition.tbl.label", "Partitions Table: "))
    GUICtrlSetTip($idViewUnattendPartitionTblLbl, i18nGet("unattend.partition.tbl.tip", "Interactive disk partition layout (max 8 partitions)"))
    GUICtrlSetTip($idViewUnattendPartitionTblList, i18nGet("unattend.partition.tbl.tip", "Interactive disk partition layout (max 8 partitions)"))
    GUICtrlSetData($idViewUnattendPartResetBtn, i18nGet("unattend.partition.btn.reset", "Reset"))
    GUICtrlSetTip($idViewUnattendPartResetBtn, i18nGet("unattend.partition.btn.reset.tip", "Reset partition table to default layout"))

    _GUICtrlListView_SetColumn($idViewUnattendPartitionTblList, 0, i18nGet("unattend.partition.col.id", "ID"))
    _GUICtrlListView_SetColumn($idViewUnattendPartitionTblList, 1, i18nGet("unattend.partition.col.type", "Type"))
    _GUICtrlListView_SetColumn($idViewUnattendPartitionTblList, 2, i18nGet("unattend.partition.col.label", "Label"))
    _GUICtrlListView_SetColumn($idViewUnattendPartitionTblList, 3, i18nGet("unattend.partition.col.size", "Size MB"))
    _GUICtrlListView_SetColumn($idViewUnattendPartitionTblList, 4, i18nGet("unattend.partition.col.letter", "Letter"))
    _GUICtrlListView_SetColumn($idViewUnattendPartitionTblList, 5, i18nGet("unattend.partition.col.format", "Format"))

    _SetCueBannerW($idViewUnattendPartLabelInput, i18nGet("unattend.partition.placeholder.label", "Label"), True)
    _SetCueBannerW($idViewUnattendPartSizeInput, i18nGet("unattend.partition.placeholder.size", "Size MB"), True)
    _SetCueBannerW($idViewUnattendPartLetterInput, i18nGet("unattend.partition.placeholder.letter", "Letter"), True)

    GUICtrlSetData($idViewUnattendPartAddBtn, i18nGet("unattend.partition.btn.add", "Add"))
    GUICtrlSetTip($idViewUnattendPartAddBtn, i18nGet("unattend.partition.btn.add.tip", "Add a new partition to the table"))
    GUICtrlSetData($idViewUnattendPartDeleteBtn, i18nGet("unattend.partition.btn.delete", "Delete"))
    GUICtrlSetTip($idViewUnattendPartDeleteBtn, i18nGet("unattend.partition.btn.delete.tip", "Delete the selected partition"))
    GUICtrlSetData($idViewUnattendPartClearBtn, i18nGet("unattend.partition.btn.clear", "Clear"))
    GUICtrlSetTip($idViewUnattendPartClearBtn, i18nGet("unattend.partition.btn.clear.tip", "Clear all input fields in the edit row"))
    GUICtrlSetData($idViewUnattendPartSaveBtn, i18nGet("unattend.partition.btn.save", "Save"))
    GUICtrlSetTip($idViewUnattendPartSaveBtn, i18nGet("unattend.partition.btn.save.tip", "Save changes to the selected partition"))
    GUICtrlSetData($idViewUnattendPartCancelBtn, i18nGet("unattend.partition.btn.cancel", "Cancel"))
    GUICtrlSetTip($idViewUnattendPartCancelBtn, i18nGet("unattend.partition.btn.cancel.tip", "Discard changes and restore selected partition values"))

    GUICtrlSetData($idViewUnattendPartitionOSPartIDLbl, i18nGet("unattend.partition.ospartid.label", "Install OS on Partition ID: "))
    GUICtrlSetTip($idViewUnattendPartitionOSPartIDLbl, i18nGet("unattend.partition.ospartid.tip", "Partition ID where Windows will be installed (default: 3)"))
    GUICtrlSetTip($idViewUnattendPartitionOSPartIDInput, i18nGet("unattend.partition.ospartid.tip", "Partition ID where Windows will be installed (default: 3)"))
    _SetCueBannerW($idViewUnattendPartitionOSPartIDInput, "3", True)

    ; Bypass Hardware Checks
    GUICtrlSetData($hViewUnattendBypassGroup, i18nGet("unattend.bypass.title", "Bypass Hardware Checks"))
    GUICtrlSetData($idViewUnattendBypassAllCkbx, i18nGet("unattend.bypass.all.label", "Select All"))
    GUICtrlSetTip($idViewUnattendBypassAllCkbx, i18nGet("unattend.bypass.all.tip", "Toggle all Windows 11 hardware requirement bypasses"))
    GUICtrlSetData($idViewUnattendBypassTPMCkbx, i18nGet("unattend.bypass.tpm.label", "Bypass TPM"))
    GUICtrlSetTip($idViewUnattendBypassTPMCkbx, i18nGet("unattend.bypass.tpm.tip", "Bypass Trusted Platform Module 2.0 check"))
    GUICtrlSetData($idViewUnattendBypassRAMCkbx, i18nGet("unattend.bypass.ram.label", "Bypass RAM"))
    GUICtrlSetTip($idViewUnattendBypassRAMCkbx, i18nGet("unattend.bypass.ram.tip", "Bypass minimum 4GB RAM requirement"))
    GUICtrlSetData($idViewUnattendBypassSBCkbx, i18nGet("unattend.bypass.sb.label", "Bypass Secure Boot"))
    GUICtrlSetTip($idViewUnattendBypassSBCkbx, i18nGet("unattend.bypass.sb.tip", "Bypass UEFI Secure Boot check"))
    GUICtrlSetData($idViewUnattendBypassCPUCkbx, i18nGet("unattend.bypass.cpu.label", "Bypass CPU"))
    GUICtrlSetTip($idViewUnattendBypassCPUCkbx, i18nGet("unattend.bypass.cpu.tip", "Bypass unsupported processor requirement"))
    GUICtrlSetData($idViewUnattendBypassStorageCkbx, i18nGet("unattend.bypass.storage.label", "Bypass Storage"))
    GUICtrlSetTip($idViewUnattendBypassStorageCkbx, i18nGet("unattend.bypass.storage.tip", "Bypass minimum 64GB storage requirement"))
    GUICtrlSetData($idViewUnattendBypassDiskCkbx, i18nGet("unattend.bypass.disk.label", "Bypass Disk"))
    GUICtrlSetTip($idViewUnattendBypassDiskCkbx, i18nGet("unattend.bypass.disk.tip", "Bypass disk drive type checks"))

    ; OOBE Settings
    GUICtrlSetData($hViewUnattendOOBEGroup, i18nGet("unattend.oobe.title", "Out-of-box-experience Settings"))
    GUICtrlSetData($idViewUnattendOOBEAllCkbx, i18nGet("unattend.oobe.all.label", "Select All"))
    GUICtrlSetTip($idViewUnattendOOBEAllCkbx, i18nGet("unattend.oobe.all.tip", "Toggle all Out-of-Box Experience skips"))
    GUICtrlSetData($idViewUnattendOOBEEULACkbx, i18nGet("unattend.oobe.eula.label", "Hide EULA Screen"))
    GUICtrlSetTip($idViewUnattendOOBEEULACkbx, i18nGet("unattend.oobe.eula.tip", "Automatically accept and skip End User License Agreement"))
    GUICtrlSetData($idViewUnattendOOBELocalAccCkbx, i18nGet("unattend.oobe.localacc.label", "Hide Local Account Screen"))
    GUICtrlSetTip($idViewUnattendOOBELocalAccCkbx, i18nGet("unattend.oobe.localacc.tip", "Skip local account creation screen in setup"))
    GUICtrlSetData($idViewUnattendOOBEOnlAccCkbx, i18nGet("unattend.oobe.onlacc.label", "Hide Online Account Screen"))
    GUICtrlSetTip($idViewUnattendOOBEOnlAccCkbx, i18nGet("unattend.oobe.onlacc.tip", "Skip mandatory Microsoft online account requirement"))
    GUICtrlSetData($idViewUnattendOOBEWirelessCkbx, i18nGet("unattend.oobe.wireless.label", "Hide Wireless Setup"))
    GUICtrlSetTip($idViewUnattendOOBEWirelessCkbx, i18nGet("unattend.oobe.wireless.tip", "Skip network connection screen during OOBE"))
    GUICtrlSetData($idViewUnattendOOBEBitLockerCkbx, i18nGet("unattend.oobe.bitlocker.label", "Disable BitLocker"))
    GUICtrlSetTip($idViewUnattendOOBEBitLockerCkbx, i18nGet("unattend.oobe.bitlocker.tip", "Disable automatic BitLocker drive encryption"))
    GUICtrlSetData($idViewUnattendOOBEPrivacyLbl, i18nGet("unattend.oobe.privacy.label", "Privacy Settings: "))
    GUICtrlSetTip($idViewUnattendOOBEPrivacyLbl, i18nGet("unattend.oobe.privacy.tip", "Select privacy and telemetry level"))
    GUICtrlSetData($idViewUnattendOOBEPrivacyRdoC1, i18nGet("unattend.oobe.privacy.express.label", "Express"))
    GUICtrlSetTip($idViewUnattendOOBEPrivacyRdoC1, i18nGet("unattend.oobe.privacy.express.tip", "Default Windows express privacy settings"))
    GUICtrlSetData($idViewUnattendOOBEPrivacyRdoC2, i18nGet("unattend.oobe.privacy.recom.label", "Recommended"))
    GUICtrlSetTip($idViewUnattendOOBEPrivacyRdoC2, i18nGet("unattend.oobe.privacy.recom.tip", "Recommended balanced privacy options"))
    GUICtrlSetData($idViewUnattendOOBEPrivacyRdoC3, i18nGet("unattend.oobe.privacy.disable.label", "Disable All"))
    GUICtrlSetTip($idViewUnattendOOBEPrivacyRdoC3, i18nGet("unattend.oobe.privacy.disable.tip", "Disable telemetry, tracking, and diagnostics"))

    ; Local Accounts Management
    GUICtrlSetData($hViewUnattendLocalAccGroup, i18nGet("unattend.localacc.title", "Local Accounts Management"))
    GUICtrlSetData($idViewUnattendLocalAccTblLbl, i18nGet("unattend.localacc.tbl.label", "Accounts Table: "))
    GUICtrlSetTip($idViewUnattendLocalAccTblLbl, i18nGet("unattend.localacc.tbl.tip", "Manage local user accounts (max 8 accounts)"))
    GUICtrlSetTip($idViewUnattendLocalAccTblList, i18nGet("unattend.localacc.tbl.tip", "Manage local user accounts (max 8 accounts)"))
    GUICtrlSetData($idViewUnattendAccResetBtn, i18nGet("unattend.localacc.btn.reset", "Reset"))
    GUICtrlSetTip($idViewUnattendAccResetBtn, i18nGet("unattend.localacc.btn.reset.tip", "Reset accounts table to default administrator account"))

    _GUICtrlListView_SetColumn($idViewUnattendLocalAccTblList, 0, i18nGet("unattend.localacc.col.id", "ID"))
    _GUICtrlListView_SetColumn($idViewUnattendLocalAccTblList, 1, i18nGet("unattend.localacc.col.type", "Type"))
    _GUICtrlListView_SetColumn($idViewUnattendLocalAccTblList, 2, i18nGet("unattend.localacc.col.name", "Name"))
    _GUICtrlListView_SetColumn($idViewUnattendLocalAccTblList, 3, i18nGet("unattend.localacc.col.displayname", "DisplayName"))
    _GUICtrlListView_SetColumn($idViewUnattendLocalAccTblList, 4, i18nGet("unattend.localacc.col.password", "Password"))

    _SetCueBannerW($idViewUnattendAccNameInput, i18nGet("unattend.localacc.placeholder.name", "Username"), True)
    _SetCueBannerW($idViewUnattendAccDispNameInput, i18nGet("unattend.localacc.placeholder.displayname", "Display Name"), True)
    _SetCueBannerW($idViewUnattendAccPassInput, i18nGet("unattend.localacc.placeholder.password", "Password (unhidden)"), True)

    GUICtrlSetData($idViewUnattendAccAddBtn, i18nGet("unattend.localacc.btn.add", "Add"))
    GUICtrlSetTip($idViewUnattendAccAddBtn, i18nGet("unattend.localacc.btn.add.tip", "Add a new local account to the table"))
    GUICtrlSetData($idViewUnattendAccDeleteBtn, i18nGet("unattend.localacc.btn.delete", "Delete"))
    GUICtrlSetTip($idViewUnattendAccDeleteBtn, i18nGet("unattend.localacc.btn.delete.tip", "Delete the selected local account"))
    GUICtrlSetData($idViewUnattendAccClearBtn, i18nGet("unattend.localacc.btn.clear", "Clear"))
    GUICtrlSetTip($idViewUnattendAccClearBtn, i18nGet("unattend.localacc.btn.clear.tip", "Clear all input fields in the edit row"))
    GUICtrlSetData($idViewUnattendAccSaveBtn, i18nGet("unattend.localacc.btn.save", "Save"))
    GUICtrlSetTip($idViewUnattendAccSaveBtn, i18nGet("unattend.localacc.btn.save.tip", "Save changes to the selected local account"))
    GUICtrlSetData($idViewUnattendAccCancelBtn, i18nGet("unattend.localacc.btn.cancel", "Cancel"))
    GUICtrlSetTip($idViewUnattendAccCancelBtn, i18nGet("unattend.localacc.btn.cancel.tip", "Discard changes and restore selected local account values"))

    GUICtrlSetData($idViewUnattendLocalAccAutoLogonLbl, i18nGet("unattend.localacc.autologon.label", "Auto-Logon Account ID: "))
    GUICtrlSetTip($idViewUnattendLocalAccAutoLogonLbl, i18nGet("unattend.localacc.autologon.tip", "Account ID to automatically log into on boot (default: 1)"))
    GUICtrlSetTip($idViewUnattendLocalAccAutoLogonInput, i18nGet("unattend.localacc.autologon.tip", "Account ID to automatically log into on boot (default: 1)"))
    _SetCueBannerW($idViewUnattendLocalAccAutoLogonInput, i18nGet("unattend.localacc.autologon.placeholder", "1"), True)

    ; Bloatware Removal
    GUICtrlSetData($hViewUnattendBloatwareGroup, i18nGet("unattend.bloatware.title", "Bloatware Removal"))
    GUICtrlSetData($idViewUnattendBloatwareTblLbl, i18nGet("unattend.bloatware.tbl.label", "Bloatwares List: "))
    GUICtrlSetTip($idViewUnattendBloatwareTblLbl, i18nGet("unattend.bloatware.tbl.tip", "Select pre-installed apps and UWP packages to remove"))
    GUICtrlSetTip($idViewUnattendBloatwareTblList, i18nGet("unattend.bloatware.tbl.tip", "Select pre-installed apps and UWP packages to remove"))
    GUICtrlSetData($idViewUnattendBloatwareResetBtn, i18nGet("unattend.bloatware.btn.reset", "Reset"))
    GUICtrlSetTip($idViewUnattendBloatwareResetBtn, i18nGet("unattend.bloatware.btn.reset.tip", "Select all bloatware packages for removal"))

    _GUICtrlListView_SetColumn($idViewUnattendBloatwareTblList, 0, i18nGet("unattend.bloatware.list.col1.label", "Package Name"))
    _GUICtrlListView_SetColumn($idViewUnattendBloatwareTblList, 1, i18nGet("unattend.bloatware.list.col2.label", "Description"))
    For $i = 0 To UBound($a_sKnownBloatwares) - 1
        Local $sPkg = $a_sKnownBloatwares[$i][0]
        Local $sDesc = _UnattendGetBloatwareDesc($sPkg, $a_sKnownBloatwares[$i][1])
        _GUICtrlListView_SetItemText($idViewUnattendBloatwareTblList, $i, $sDesc, 1)
    Next

    ; Custom Scripts
    GUICtrlSetData($hViewUnattendScriptsGroup, i18nGet("unattend.scripts.title", "Custom Scripts"))
    GUICtrlSetData($idViewUnattendScriptsEditLbl, i18nGet("unattend.scripts.edit.label", "PowerShell Scripts: "))
    GUICtrlSetTip($idViewUnattendScriptsEditLbl, i18nGet("unattend.scripts.edit.tip", "PowerShell commands to execute after installation"))
    GUICtrlSetTip($idViewUnattendScriptsEditEdit, i18nGet("unattend.scripts.edit.tip", "PowerShell commands to execute after installation"))

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

    GUICtrlSetBkColor($idViewUnattendPartitionManSlider, themeColor("main.view.bg"))

    Local $aLabels[] = [ _
        $idViewUnattendEditionLbl, _
        $idViewUnattendProductKeyLbl, _
        $idViewUnattendArchLbl, _
        $idViewUnattendArchRdoC1, _
        $idViewUnattendArchRdoC2, _
        $idViewUnattendPcNameLbl, _
        $idViewUnattendSysLangLbl, _
        $idViewUnattendUsrLangLbl, _
        $idViewUnattendSysUsrLangSameCkbx, _
        $idViewUnattendUILangLbl, _
        $idViewUnattendKbLayoutLbl, _
        $idViewUnattendTZLbl, _
        $idViewUnattendPartitionManLbl, _
        $idViewUnattendPartitionManManualLbl, _
        $idViewUnattendPartitionManHybridLbl, _
        $idViewUnattendPartitionManAutoLbl, _
        $idViewUnattendPartitionDiskIDLbl, _
        $idViewUnattendPartitionTypeLbl, _
        $idViewUnattendPartitionTypeRdoC1, _
        $idViewUnattendPartitionTypeRdoC2, _
        $idViewUnattendPartitionTblLbl, _
        $idViewUnattendPartitionOSPartIDLbl, _
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
        $idViewUnattendLocalAccAutoLogonLbl, _
        $idViewUnattendBloatwareTblLbl, _
        $idViewUnattendBloatwareTblList, _
        $idViewUnattendScriptsEditLbl, _
        $idViewUnattendScriptsEditEdit _
    ]
    For $i = 0 to UBound($aLabels) - 1
        GUICtrlSetColor($aLabels[$i], themeColor("text.primary"))
        GUICtrlSetBkColor($aLabels[$i], themeColor("main.view.bg"))
    Next

    Local $aInputs[] = [ _
        $idViewUnattendProductKeyInput, _
        $idViewUnattendPcNameInput, _
        $idViewUnattendPartitionDiskIDInput, _
        $idViewUnattendPartLabelInput, _
        $idViewUnattendPartSizeInput, _
        $idViewUnattendPartLetterInput, _
        $idViewUnattendPartitionOSPartIDInput, _
        $idViewUnattendAccNameInput, _
        $idViewUnattendAccDispNameInput, _
        $idViewUnattendAccPassInput, _
        $idViewUnattendLocalAccAutoLogonInput, _
        $idViewUnattendScriptsEditEdit _
    ]
    For $i = 0 To UBound($aInputs) - 1
        GUICtrlSetColor($aInputs[$i], themeColor("text.primary"))
        GUICtrlSetBkColor($aInputs[$i], themeColor("main.view.bg"))
    Next

    Local $aLists[] = [$idViewUnattendBloatwareTblList, $idViewUnattendPartitionTblList, $idViewUnattendLocalAccTblList]
    For $i = 0 To UBound($aLists) - 1
        _GUICtrlListView_SetTextColor($aLists[$i], themeColor("text.primary"))
        _GUICtrlListView_SetTextBkColor($aLists[$i], themeColor("main.view.bg"))
        _GUICtrlListView_SetBkColor($aLists[$i], themeColor("main.view.bg"))
    Next
    
EndFunc

Func viewUnattendHandleEvent($idMsg)
    Switch $idMsg
        ; Partition Management Slider Logic
        Case $idViewUnattendPartitionManManualLbl
            GUICtrlSetData($idViewUnattendPartitionManSlider, 0)

        Case $idViewUnattendPartitionManHybridLbl
            GUICtrlSetData($idViewUnattendPartitionManSlider, 1)

        Case $idViewUnattendPartitionManAutoLbl
            GUICtrlSetData($idViewUnattendPartitionManSlider, 2)

        ; Partition Scheme Type (GPT / MBR)
        Case $idViewUnattendPartitionTypeRdoC1, $idViewUnattendPartitionTypeRdoC2
            _UnattendPartReset()
        
        ; Language Same Checkbox logic
        Case $idViewUnattendSysUsrLangSameCkbx
            If GUICtrlRead($idViewUnattendSysUsrLangSameCkbx) = $GUI_CHECKED Then
                GUICtrlSetState($idViewUnattendUsrLangCmb, $GUI_DISABLE)
                GUICtrlSetData($idViewUnattendUsrLangCmb, GUICtrlRead($idViewUnattendSysLangCmb))
            Else
                GUICtrlSetState($idViewUnattendUsrLangCmb, $GUI_ENABLE)
            EndIf

        Case $idViewUnattendSysLangCmb
            If GUICtrlRead($idViewUnattendSysUsrLangSameCkbx) = $GUI_CHECKED Then
                GUICtrlSetData($idViewUnattendUsrLangCmb, GUICtrlRead($idViewUnattendSysLangCmb))
            EndIf

        ; Bypass Hardware Checks "Select All" Logic
        Case $idViewUnattendBypassAllCkbx
            Local $iState = (GUICtrlRead($idViewUnattendBypassAllCkbx) = $GUI_CHECKED) ? $GUI_CHECKED : $GUI_UNCHECKED
            GUICtrlSetState($idViewUnattendBypassTPMCkbx, $iState)
            GUICtrlSetState($idViewUnattendBypassRAMCkbx, $iState)
            GUICtrlSetState($idViewUnattendBypassSBCkbx, $iState)
            GUICtrlSetState($idViewUnattendBypassCPUCkbx, $iState)
            GUICtrlSetState($idViewUnattendBypassStorageCkbx, $iState)
            GUICtrlSetState($idViewUnattendBypassDiskCkbx, $iState)

        Case $idViewUnattendBypassTPMCkbx, $idViewUnattendBypassRAMCkbx, $idViewUnattendBypassSBCkbx, _
             $idViewUnattendBypassCPUCkbx, $idViewUnattendBypassStorageCkbx, $idViewUnattendBypassDiskCkbx
            Local $bAllChecked = (GUICtrlRead($idViewUnattendBypassTPMCkbx) = $GUI_CHECKED) And _
                                 (GUICtrlRead($idViewUnattendBypassRAMCkbx) = $GUI_CHECKED) And _
                                 (GUICtrlRead($idViewUnattendBypassSBCkbx) = $GUI_CHECKED) And _
                                 (GUICtrlRead($idViewUnattendBypassCPUCkbx) = $GUI_CHECKED) And _
                                 (GUICtrlRead($idViewUnattendBypassStorageCkbx) = $GUI_CHECKED) And _
                                 (GUICtrlRead($idViewUnattendBypassDiskCkbx) = $GUI_CHECKED)
            GUICtrlSetState($idViewUnattendBypassAllCkbx, $bAllChecked ? $GUI_CHECKED : $GUI_UNCHECKED)

        ; OOBE Settings "Select All" Logic
        Case $idViewUnattendOOBEAllCkbx
            Local $iState = (GUICtrlRead($idViewUnattendOOBEAllCkbx) = $GUI_CHECKED) ? $GUI_CHECKED : $GUI_UNCHECKED
            GUICtrlSetState($idViewUnattendOOBEEULACkbx, $iState)
            GUICtrlSetState($idViewUnattendOOBELocalAccCkbx, $iState)
            GUICtrlSetState($idViewUnattendOOBEOnlAccCkbx, $iState)
            GUICtrlSetState($idViewUnattendOOBEWirelessCkbx, $iState)
            GUICtrlSetState($idViewUnattendOOBEBitLockerCkbx, $iState)

        Case $idViewUnattendOOBEEULACkbx, $idViewUnattendOOBELocalAccCkbx, $idViewUnattendOOBEOnlAccCkbx, _
             $idViewUnattendOOBEWirelessCkbx, $idViewUnattendOOBEBitLockerCkbx
            Local $bAllChecked = (GUICtrlRead($idViewUnattendOOBEEULACkbx) = $GUI_CHECKED) And _
                                 (GUICtrlRead($idViewUnattendOOBELocalAccCkbx) = $GUI_CHECKED) And _
                                 (GUICtrlRead($idViewUnattendOOBEOnlAccCkbx) = $GUI_CHECKED) And _
                                 (GUICtrlRead($idViewUnattendOOBEWirelessCkbx) = $GUI_CHECKED) And _
                                 (GUICtrlRead($idViewUnattendOOBEBitLockerCkbx) = $GUI_CHECKED)
            GUICtrlSetState($idViewUnattendOOBEAllCkbx, $bAllChecked ? $GUI_CHECKED : $GUI_UNCHECKED)

        ; Bloatware Reset Button
        Case $idViewUnattendBloatwareResetBtn
            Local $iCount = _GUICtrlListView_GetItemCount($idViewUnattendBloatwareTblList)
            For $i = 0 To $iCount - 1
                _GUICtrlListView_SetItemChecked($idViewUnattendBloatwareTblList, $i, True)
            Next
            appSetStatus(i18nGet("status.title", "Status: ") & "Reset bloatware list to all selected")

        ; Partition Table Actions
        Case $idViewUnattendPartitionTblList
            _UnattendPartOnSelect()

        Case $idViewUnattendPartResetBtn
            _UnattendPartReset()

        Case $idViewUnattendPartAddBtn
            _UnattendPartOnAdd()

        Case $idViewUnattendPartDeleteBtn
            _UnattendPartOnDelete()

        Case $idViewUnattendPartClearBtn
            _UnattendPartOnClear()

        Case $idViewUnattendPartSaveBtn
            _UnattendPartOnSave()

        Case $idViewUnattendPartCancelBtn
            _UnattendPartOnCancel()

        Case $idViewUnattendPartitionOSPartIDInput
            _UnattendValidateOSPartID()

        ; Accounts Table Actions
        Case $idViewUnattendLocalAccTblList
            _UnattendAccOnSelect()

        Case $idViewUnattendAccResetBtn
            _UnattendAccReset()

        Case $idViewUnattendAccAddBtn
            _UnattendAccOnAdd()

        Case $idViewUnattendAccDeleteBtn
            _UnattendAccOnDelete()

        Case $idViewUnattendAccClearBtn
            _UnattendAccOnClear()

        Case $idViewUnattendAccSaveBtn
            _UnattendAccOnSave()

        Case $idViewUnattendAccCancelBtn
            _UnattendAccOnCancel()

        Case $idViewUnattendLocalAccAutoLogonInput
            _UnattendValidateAutoLogonID()
        
        ; Toolbar Button Actions
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Bloatware Helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _UnattendGetBloatwareDesc($sPkg, $sDefault)
    Switch $sPkg
        Case "Microsoft.Copilot"
            Return i18nGet("unattend.bloatware.desc.Microsoft.Copilot", "Windows Copilot AI assistant integration")
        Case "Clipchamp.Clipchamp"
            Return i18nGet("unattend.bloatware.desc.Clipchamp.Clipchamp", "Clipchamp video editor application")
        Case "Microsoft.BingSearch"
            Return i18nGet("unattend.bloatware.desc.Microsoft.BingSearch", "Bing web search integration in Windows")
        Case "Microsoft.BingNews"
            Return i18nGet("unattend.bloatware.desc.Microsoft.BingNews", "Microsoft Bing News widget and application")
        Case "MicrosoftTeams"
            Return i18nGet("unattend.bloatware.desc.MicrosoftTeams", "Microsoft Teams personal / work client")
        Case "MSTeams"
            Return i18nGet("unattend.bloatware.desc.MSTeams", "Microsoft Teams alternate package")
        Case "Microsoft.OutlookForWindows"
            Return i18nGet("unattend.bloatware.desc.Microsoft.OutlookForWindows", "New web-based Outlook email client")
        Case "Microsoft.MicrosoftSolitaireCollection"
            Return i18nGet("unattend.bloatware.desc.Microsoft.MicrosoftSolitaireCollection", "Microsoft Solitaire collection games")
        Case "Microsoft.Microsoft3DViewer"
            Return i18nGet("unattend.bloatware.desc.Microsoft.Microsoft3DViewer", "3D Model Viewer utility")
        Case "Microsoft.SkypeApp"
            Return i18nGet("unattend.bloatware.desc.Microsoft.SkypeApp", "Skype instant messaging and calling app")
        Case "Microsoft.People"
            Return i18nGet("unattend.bloatware.desc.Microsoft.People", "Windows People address book app")
        Case "Microsoft.Todos"
            Return i18nGet("unattend.bloatware.desc.Microsoft.Todos", "Microsoft To Do task manager")
        Case "Microsoft.Wallet"
            Return i18nGet("unattend.bloatware.desc.Microsoft.Wallet", "Microsoft Wallet payment autofill")
        Case "Microsoft.WindowsMaps"
            Return i18nGet("unattend.bloatware.desc.Microsoft.WindowsMaps", "Windows Maps application")
        Case "Microsoft.Getstarted"
            Return i18nGet("unattend.bloatware.desc.Microsoft.Getstarted", "Tips and Get Started application")
        Case "Microsoft.GetHelp"
            Return i18nGet("unattend.bloatware.desc.Microsoft.GetHelp", "Get Help diagnostic assistance app")
        Case "Microsoft.WindowsFeedbackHub"
            Return i18nGet("unattend.bloatware.desc.Microsoft.WindowsFeedbackHub", "Windows Feedback Hub telemetry app")
        Case "Microsoft.Office.OneNote"
            Return i18nGet("unattend.bloatware.desc.Microsoft.Office.OneNote", "OneNote for Windows application")
        Case "Microsoft.MicrosoftOfficeHub"
            Return i18nGet("unattend.bloatware.desc.Microsoft.MicrosoftOfficeHub", "Microsoft 365 / Office Hub portal")
        Case "Microsoft.MixedReality.Portal"
            Return i18nGet("unattend.bloatware.desc.Microsoft.MixedReality.Portal", "Windows Mixed Reality portal app")
        Case "MicrosoftCorporationII.QuickAssist"
            Return i18nGet("unattend.bloatware.desc.MicrosoftCorporationII.QuickAssist", "Remote assistance support client")
        Case "MicrosoftCorporationII.MicrosoftFamily"
            Return i18nGet("unattend.bloatware.desc.MicrosoftCorporationII.MicrosoftFamily", "Microsoft Family Safety monitor")
        Case "Microsoft.MicrosoftStickyNotes"
            Return i18nGet("unattend.bloatware.desc.Microsoft.MicrosoftStickyNotes", "Sticky Notes desktop application")
        Case "Microsoft.549981C3F5F10"
            Return i18nGet("unattend.bloatware.desc.Microsoft.549981C3F5F10", "Cortana voice assistant component")
        Case "App.Support.QuickAssist"
            Return i18nGet("unattend.bloatware.desc.App.Support.QuickAssist", "Quick Assist capability component")
        Case Else
            Return $sDefault
    EndSwitch
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Partition Table Helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _UnattendPartOnSelect($iIdx = -1)
    If $iIdx < 0 Then
        Local $sSel = _GUICtrlListView_GetSelectedIndices($idViewUnattendPartitionTblList)
        If $sSel = "" Then Return
        $iIdx = Number($sSel)
    EndIf
    Local $iCount = _GUICtrlListView_GetItemCount($idViewUnattendPartitionTblList)
    If $iIdx < 0 Or $iIdx >= $iCount Then Return

    Local $sType = _GUICtrlListView_GetItemText($idViewUnattendPartitionTblList, $iIdx, 1)
    Local $sLabel = _GUICtrlListView_GetItemText($idViewUnattendPartitionTblList, $iIdx, 2)
    Local $sSize = _GUICtrlListView_GetItemText($idViewUnattendPartitionTblList, $iIdx, 3)
    Local $sLetter = _GUICtrlListView_GetItemText($idViewUnattendPartitionTblList, $iIdx, 4)
    Local $sFormat = _GUICtrlListView_GetItemText($idViewUnattendPartitionTblList, $iIdx, 5)

    GUICtrlSetData($idViewUnattendPartTypeCmb, $sType)
    GUICtrlSetData($idViewUnattendPartLabelInput, $sLabel)
    GUICtrlSetData($idViewUnattendPartSizeInput, $sSize)
    GUICtrlSetData($idViewUnattendPartLetterInput, $sLetter)
    GUICtrlSetData($idViewUnattendPartFormatCmb, $sFormat)
EndFunc

Func _UnattendPartReset()
    _GUICtrlListView_DeleteAllItems(GUICtrlGetHandle($idViewUnattendPartitionTblList))
    Local $bIsGPT = (GUICtrlRead($idViewUnattendPartitionTypeRdoC1) = $GUI_CHECKED)
    If $bIsGPT Then
        GUICtrlCreateListViewItem("1|EFI|System|512||FAT32", $idViewUnattendPartitionTblList)
        GUICtrlCreateListViewItem("2|MSR||16||", $idViewUnattendPartitionTblList)
        GUICtrlCreateListViewItem("3|Primary|Windows|102400|C|NTFS", $idViewUnattendPartitionTblList)
        GUICtrlCreateListViewItem("4|Recovery|Recovery|1024||NTFS", $idViewUnattendPartitionTblList)
    Else
        GUICtrlCreateListViewItem("1|Primary|System|500||NTFS", $idViewUnattendPartitionTblList)
        GUICtrlCreateListViewItem("2|Primary|Windows|102400|C|NTFS", $idViewUnattendPartitionTblList)
        GUICtrlCreateListViewItem("3|Recovery|Recovery|1024||NTFS", $idViewUnattendPartitionTblList)
    EndIf
    _GUICtrlListView_SetItemSelected($idViewUnattendPartitionTblList, 0, True, True)
    _UnattendPartOnSelect()
    _UnattendValidateOSPartID()
    appSetStatus(i18nGet("status.title", "Status: ") & "Reset partition table to " & ($bIsGPT ? "GPT" : "MBR") & " defaults")
EndFunc

Func _UnattendPartOnAdd()
    Local $iCount = _GUICtrlListView_GetItemCount($idViewUnattendPartitionTblList)
    If $iCount >= 8 Then
        appSetStatus(i18nGet("status.title", "Status: ") & "Partition table has reached maximum capacity (8 partitions)")
        Return
    EndIf

    Local $iNextID = $iCount + 1
    GUICtrlCreateListViewItem($iNextID & "|Primary|Data|10240||NTFS", $idViewUnattendPartitionTblList)
    _GUICtrlListView_SetItemSelected($idViewUnattendPartitionTblList, $iCount, True, True)
    _UnattendPartOnSelect()
    _UnattendValidateOSPartID()
    appSetStatus(i18nGet("status.title", "Status: ") & "Added partition " & $iNextID)
EndFunc

Func _UnattendPartOnDelete()
    Local $sSel = _GUICtrlListView_GetSelectedIndices($idViewUnattendPartitionTblList)
    If $sSel = "" Then
        appSetStatus(i18nGet("status.title", "Status: ") & "Please select a partition row to delete")
        Return
    EndIf
    Local $iIdx = Number($sSel)
    _GUICtrlListView_DeleteItem($idViewUnattendPartitionTblList, $iIdx)

    ; Re-number IDs
    Local $iCount = _GUICtrlListView_GetItemCount($idViewUnattendPartitionTblList)
    For $i = 0 To $iCount - 1
        _GUICtrlListView_SetItemText($idViewUnattendPartitionTblList, $i, String($i + 1), 0)
    Next

    If $iCount > 0 Then
        Local $iNewSel = ($iIdx < $iCount) ? $iIdx : ($iCount - 1)
        _GUICtrlListView_SetItemSelected($idViewUnattendPartitionTblList, $iNewSel, True, True)
        _UnattendPartOnSelect()
    Else
        GUICtrlSetData($idViewUnattendPartTypeCmb, "")
        GUICtrlSetData($idViewUnattendPartLabelInput, "")
        GUICtrlSetData($idViewUnattendPartSizeInput, "")
        GUICtrlSetData($idViewUnattendPartLetterInput, "")
        GUICtrlSetData($idViewUnattendPartFormatCmb, "")
    EndIf

    _UnattendValidateOSPartID()
    appSetStatus(i18nGet("status.title", "Status: ") & "Deleted partition")
EndFunc

Func _UnattendPartOnClear()
    GUICtrlSetData($idViewUnattendPartTypeCmb, "")
    GUICtrlSetData($idViewUnattendPartLabelInput, "")
    GUICtrlSetData($idViewUnattendPartSizeInput, "")
    GUICtrlSetData($idViewUnattendPartLetterInput, "")
    GUICtrlSetData($idViewUnattendPartFormatCmb, "")
    appSetStatus(i18nGet("status.title", "Status: ") & "Cleared partition inputs")
EndFunc

Func _UnattendPartOnSave()
    Local $sSel = _GUICtrlListView_GetSelectedIndices($idViewUnattendPartitionTblList)
    If $sSel = "" Then
        appSetStatus(i18nGet("status.title", "Status: ") & "Please select a partition row to save")
        Return
    EndIf
    Local $iIdx = Number($sSel)
    Local $sType = GUICtrlRead($idViewUnattendPartTypeCmb)
    Local $sLabel = GUICtrlRead($idViewUnattendPartLabelInput)
    Local $sSize = GUICtrlRead($idViewUnattendPartSizeInput)
    Local $sLetter = StringUpper(StringLeft(GUICtrlRead($idViewUnattendPartLetterInput), 1))
    Local $sFormat = GUICtrlRead($idViewUnattendPartFormatCmb)

    _GUICtrlListView_SetItemText($idViewUnattendPartitionTblList, $iIdx, $sType, 1)
    _GUICtrlListView_SetItemText($idViewUnattendPartitionTblList, $iIdx, $sLabel, 2)
    _GUICtrlListView_SetItemText($idViewUnattendPartitionTblList, $iIdx, $sSize, 3)
    _GUICtrlListView_SetItemText($idViewUnattendPartitionTblList, $iIdx, $sLetter, 4)
    _GUICtrlListView_SetItemText($idViewUnattendPartitionTblList, $iIdx, $sFormat, 5)
    appSetStatus(i18nGet("status.title", "Status: ") & "Saved partition " & ($iIdx + 1))
EndFunc

Func _UnattendPartOnCancel()
    _UnattendPartOnSelect()
    appSetStatus(i18nGet("status.title", "Status: ") & "Reverted partition inputs to selected row")
EndFunc

Func _UnattendValidateOSPartID()
    Local $iCount = _GUICtrlListView_GetItemCount($idViewUnattendPartitionTblList)
    If $iCount < 1 Then Return
    Local $sVal = GUICtrlRead($idViewUnattendPartitionOSPartIDInput)
    Local $iVal = Number($sVal)
    If $sVal = "" Or $iVal < 1 Or $iVal > $iCount Then
        Local $iReset = ($iCount >= 3) ? 3 : $iCount
        GUICtrlSetData($idViewUnattendPartitionOSPartIDInput, String($iReset))
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Accounts Table Helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _UnattendAccOnSelect($iIdx = -1)
    If $iIdx < 0 Then
        Local $sSel = _GUICtrlListView_GetSelectedIndices($idViewUnattendLocalAccTblList)
        If $sSel = "" Then Return
        $iIdx = Number($sSel)
    EndIf
    Local $iCount = _GUICtrlListView_GetItemCount($idViewUnattendLocalAccTblList)
    If $iIdx < 0 Or $iIdx >= $iCount Then Return

    Local $sType = _GUICtrlListView_GetItemText($idViewUnattendLocalAccTblList, $iIdx, 1)
    Local $sName = _GUICtrlListView_GetItemText($idViewUnattendLocalAccTblList, $iIdx, 2)
    Local $sDisp = _GUICtrlListView_GetItemText($idViewUnattendLocalAccTblList, $iIdx, 3)
    Local $sPass = _GUICtrlListView_GetItemText($idViewUnattendLocalAccTblList, $iIdx, 4)

    GUICtrlSetData($idViewUnattendAccTypeCmb, $sType)
    GUICtrlSetData($idViewUnattendAccNameInput, $sName)
    GUICtrlSetData($idViewUnattendAccDispNameInput, $sDisp)
    GUICtrlSetData($idViewUnattendAccPassInput, $sPass)
EndFunc

Func _UnattendAccReset()
    _GUICtrlListView_DeleteAllItems(GUICtrlGetHandle($idViewUnattendLocalAccTblList))
    GUICtrlCreateListViewItem("1|Administrator|Admin|Administrator|Password123", $idViewUnattendLocalAccTblList)
    _GUICtrlListView_SetItemSelected($idViewUnattendLocalAccTblList, 0, True, True)
    _UnattendAccOnSelect()
    _UnattendValidateAutoLogonID()
    appSetStatus(i18nGet("status.title", "Status: ") & "Reset accounts table to default")
EndFunc

Func _UnattendAccOnAdd()
    Local $iCount = _GUICtrlListView_GetItemCount($idViewUnattendLocalAccTblList)
    If $iCount >= 8 Then
        appSetStatus(i18nGet("status.title", "Status: ") & "Accounts table has reached maximum capacity (8 accounts)")
        Return
    EndIf

    Local $iNextID = $iCount + 1
    GUICtrlCreateListViewItem($iNextID & "|User|User" & $iNextID & "|User " & $iNextID & "|Password123", $idViewUnattendLocalAccTblList)
    _GUICtrlListView_SetItemSelected($idViewUnattendLocalAccTblList, $iCount, True, True)
    _UnattendAccOnSelect()
    _UnattendValidateAutoLogonID()
    appSetStatus(i18nGet("status.title", "Status: ") & "Added account " & $iNextID)
EndFunc

Func _UnattendAccOnDelete()
    Local $sSel = _GUICtrlListView_GetSelectedIndices($idViewUnattendLocalAccTblList)
    If $sSel = "" Then
        appSetStatus(i18nGet("status.title", "Status: ") & "Please select an account row to delete")
        Return
    EndIf
    Local $iIdx = Number($sSel)
    _GUICtrlListView_DeleteItem($idViewUnattendLocalAccTblList, $iIdx)

    ; Re-number IDs
    Local $iCount = _GUICtrlListView_GetItemCount($idViewUnattendLocalAccTblList)
    For $i = 0 To $iCount - 1
        _GUICtrlListView_SetItemText($idViewUnattendLocalAccTblList, $i, String($i + 1), 0)
    Next

    If $iCount > 0 Then
        Local $iNewSel = ($iIdx < $iCount) ? $iIdx : ($iCount - 1)
        _GUICtrlListView_SetItemSelected($idViewUnattendLocalAccTblList, $iNewSel, True, True)
        _UnattendAccOnSelect()
    Else
        GUICtrlSetData($idViewUnattendAccTypeCmb, "")
        GUICtrlSetData($idViewUnattendAccNameInput, "")
        GUICtrlSetData($idViewUnattendAccDispNameInput, "")
        GUICtrlSetData($idViewUnattendAccPassInput, "")
    EndIf

    _UnattendValidateAutoLogonID()
    appSetStatus(i18nGet("status.title", "Status: ") & "Deleted account")
EndFunc

Func _UnattendAccOnClear()
    GUICtrlSetData($idViewUnattendAccTypeCmb, "")
    GUICtrlSetData($idViewUnattendAccNameInput, "")
    GUICtrlSetData($idViewUnattendAccDispNameInput, "")
    GUICtrlSetData($idViewUnattendAccPassInput, "")
    appSetStatus(i18nGet("status.title", "Status: ") & "Cleared account inputs")
EndFunc

Func _UnattendAccOnSave()
    Local $sSel = _GUICtrlListView_GetSelectedIndices($idViewUnattendLocalAccTblList)
    If $sSel = "" Then
        appSetStatus(i18nGet("status.title", "Status: ") & "Please select an account row to save")
        Return
    EndIf
    Local $iIdx = Number($sSel)
    Local $sType = GUICtrlRead($idViewUnattendAccTypeCmb)
    Local $sName = GUICtrlRead($idViewUnattendAccNameInput)
    Local $sDisp = GUICtrlRead($idViewUnattendAccDispNameInput)
    Local $sPass = GUICtrlRead($idViewUnattendAccPassInput)

    _GUICtrlListView_SetItemText($idViewUnattendLocalAccTblList, $iIdx, $sType, 1)
    _GUICtrlListView_SetItemText($idViewUnattendLocalAccTblList, $iIdx, $sName, 2)
    _GUICtrlListView_SetItemText($idViewUnattendLocalAccTblList, $iIdx, $sDisp, 3)
    _GUICtrlListView_SetItemText($idViewUnattendLocalAccTblList, $iIdx, $sPass, 4)
    appSetStatus(i18nGet("status.title", "Status: ") & "Saved account " & ($iIdx + 1))
EndFunc

Func _UnattendAccOnCancel()
    _UnattendAccOnSelect()
    appSetStatus(i18nGet("status.title", "Status: ") & "Reverted account inputs to selected row")
EndFunc

Func _UnattendValidateAutoLogonID()
    Local $iCount = _GUICtrlListView_GetItemCount($idViewUnattendLocalAccTblList)
    If $iCount < 1 Then Return
    Local $sVal = GUICtrlRead($idViewUnattendLocalAccAutoLogonInput)
    Local $iVal = Number($sVal)
    If $sVal = "" Or $iVal < 1 Or $iVal > $iCount Then
        GUICtrlSetData($idViewUnattendLocalAccAutoLogonInput, "1")
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Window Messages Handler
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func unattendOnWM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
    #forceref $hWnd, $iMsg, $lParam
    Local $iCode = BitShift($wParam, 16)
    Local $iCtrlID = BitAND($wParam, 0xFFFF)

    If $g_hCurrentView = $hViewUnattend Then
        Switch $iCode
            Case 0x0200 ; EN_KILLFOCUS
                Switch $iCtrlID
                    Case $idViewUnattendPartitionOSPartIDInput
                        _UnattendValidateOSPartID()

                    Case $idViewUnattendLocalAccAutoLogonInput
                        _UnattendValidateAutoLogonID()
                EndSwitch
        EndSwitch
    EndIf

    Return $GUI_RUNDEFMSG
EndFunc

Func unattendOnWM_NOTIFY($hWnd, $iMsg, $wParam, $lParam)
    #forceref $hWnd, $iMsg, $wParam
    If $g_hCurrentView = $hViewUnattend Then
        Local $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
        Local $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
        Local $iCode = DllStructGetData($tNMHDR, "Code")

        If $hWndFrom = $hViewUnattendPartitionTblList Then
            Switch $iCode
                Case $LVN_ITEMCHANGED
                    Local $tNMLV = DllStructCreate($tagNMLISTVIEW, $lParam)
                    Local $iNewState = DllStructGetData($tNMLV, "NewState")
                    Local $iOldState = DllStructGetData($tNMLV, "OldState")
                    If BitAND($iNewState, $LVIS_SELECTED) <> 0 And BitAND($iOldState, $LVIS_SELECTED) = 0 Then
                        _UnattendPartOnSelect(DllStructGetData($tNMLV, "Item"))
                    EndIf

                Case $NM_CLICK
                    Local $tNMItem = DllStructCreate($tagNMITEMACTIVATE, $lParam)
                    Local $iItem = DllStructGetData($tNMItem, "Index")
                    If $iItem >= 0 Then _UnattendPartOnSelect($iItem)
            EndSwitch
        ElseIf $hWndFrom = $hViewUnattendLocalAccTblList Then
            Switch $iCode
                Case $LVN_ITEMCHANGED
                    Local $tNMLV = DllStructCreate($tagNMLISTVIEW, $lParam)
                    Local $iNewState = DllStructGetData($tNMLV, "NewState")
                    Local $iOldState = DllStructGetData($tNMLV, "OldState")
                    If BitAND($iNewState, $LVIS_SELECTED) <> 0 And BitAND($iOldState, $LVIS_SELECTED) = 0 Then
                        _UnattendAccOnSelect(DllStructGetData($tNMLV, "Item"))
                    EndIf

                Case $NM_CLICK
                    Local $tNMItem = DllStructCreate($tagNMITEMACTIVATE, $lParam)
                    Local $iItem = DllStructGetData($tNMItem, "Index")
                    If $iItem >= 0 Then _UnattendAccOnSelect($iItem)
            EndSwitch
        EndIf
    EndIf

    Return $GUI_RUNDEFMSG
EndFunc