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

; Controls
#include "../controls/button.au3"

; Modules
#include "../modules/i18n.au3"
#include "../modules/theme.au3"
#include "../modules/config.au3"
#include "../modules/scroll.au3"

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
Global $idViewUnattendSysUsrLangSameLbl = 0, $idViewUnattendSysUsrLangSameCkbx = 0
Global $idViewUnattendUILangLbl = 0, $idViewUnattendUILangCmb = 0
Global $idViewUnattendKbLayoutLbl = 0, $idViewUnattendKbLayoutCmb = 0 
Global $idViewUnattendTZLbl = 0, $idViewUnattendTZCmb = 0

Global $hViewUnattendPartitionGroup = 0
Global $idViewUnattendPartitionManLbl = 0, $idViewUnattendPartitionManRdoC1 = 0, $idViewUnattendPartitionManRdoC2 = 0, $idViewUnattendPartitionManRdoC3 = 0
Global $idViewUnattendPartitionDiskIDLbl = 0, $idViewUnattendPartitionDiskIDInput = 0
Global $idViewUnattendPartitionTypeLbl = 0, $idViewUnattendPartitionTypeRdoC1 = 0, $idViewUnattendPartitionTypeRdoC2 = 0
Global $idViewUnattendPartitionTblLbl = 0, $idViewUnattendPartitionTblList = 0

Global $hViewUnattendBypassGroup = 0
Global $idViewUnattendBypassAllLbl = 0, $idViewUnattendBypassAllCkbx = 0
Global $idViewUnattendBypassTPMLbl = 0, $idViewUnattendBypassTPMCkbx = 0
Global $idViewUnattendBypassRAMLbl = 0, $idViewUnattendBypassRAMCkbx = 0
Global $idViewUnattendBypassSBLbl = 0, $idViewUnattendBypassSBCkbx = 0
Global $idViewUnattendBypassCPULbl = 0, $idViewUnattendBypassCPUCkbx = 0
Global $idViewUnattendBypassStorageLbl = 0, $idViewUnattendBypassStorageCkbx = 0
Global $idViewUnattendBypassDiskLbl = 0, $idViewUnattendBypassDiskCkbx = 0

Global $hViewUnattendOOBEGroup = 0
Global $idViewUnattendOOBEAllLbl = 0, $idViewUnattendOOBEAllCkbx = 0
Global $idViewUnattendOOBEEULALbl = 0, $idViewUnattendOOBEEULACkbx = 0
Global $idViewUnattendOOBELocalAccLbl = 0, $idViewUnattendOOBELocalAccCkbx = 0
Global $idViewUnattendOOBEOnlAccLbl = 0, $idViewUnattendOOBEOnlAccCkbx = 0
Global $idViewUnattendOOBEWirelessLbl = 0, $idViewUnattendOOBEWirelessCkbx = 0
Global $idViewUnattendOOBEBitLockerLbl = 0, $idViewUnattendOOBEBitLockerCkbx = 0
Global $idViewUnattendOOBEPrivacyLbl = 0, $idViewUnattendOOBEPrivacyCmb = 0

Global $hViewUnattendLocalAccGroup = 0
Global $idViewUnattendLocalAccLbl = 0, $idViewUnattendLocalAccTbl = 0

Global $hViewUnattendBloatwareGroup = 0
Global $idViewUnattendBloatwareAllLbl = 0, $idViewUnattendBloatwareAllCkbx = 0
Global $idViewUnattendBloatwareLbl = 0, $idViewUnattendBloatwareList = 0
Global $a_sKnownBloatware[25][2] = [ _
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
Global $idViewUnattendScriptsLbl = 0, $idViewUnattendScriptsEdit = 0

Func viewUnattendCreate($hViewPort, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH
    Local $iEstCanvasH = 2000
    If $iContentH < $iEstCanvasH Then $iContentH = $iEstCanvasH

    Global $hViewUnattend = scrollCreateCanvas($hViewport, $iContentH)
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
    Global $idViewUnattendTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)

    ; Initialize Windows Group
    $iGroupH = $iRowH * 4 + $iP * 3
    $iX = $iP
    $iY += $iLblH * 2 + $iP
    Global $hViewUnattendWindowsGroup = GUICtrlCreateGroup(i18nGet("unattend.windows.title", "Windows"), $iX, $iY, $iContentW, $iGroupH)

    ; Edition
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    Global $idViewUnattendEditionLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    Global $idViewUnattendEditionCmb = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendEditionCmb, "Windows 11 Pro|Windows 11 Home|Windows 11 Enterprise|Windows 11 Education|Windows 11 Pro for Workstations", "Windows 11 Pro")

    ; Product Key
    $iItemY += $iRowH
    Global $idViewUnattendProductKeyLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    Global $idViewUnattendProductKeyInput = GUICtrlCreateInput("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    
    ; Architecture
    $iItemY += $iRowH
    Global $idViewUnattendArchLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    Global $idViewUnattendArchCmb = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendArchCmb, "x64|ARM", "x64")

    ; PC Name
    $iItemY += $iRowH
    Global $idViewUnattendPcNameLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    Global $idViewUnattendPcNameInput = GUICtrlCreateInput("PC", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)

    GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; Initialize Region Group
    $iX = $iP
    $iY += $iGroupH + $iP
    $iGroupH = $iRowH * 6 + $iP * 3
    Global $hViewUnattendRegionGroup = GUICtrlCreateGroup(i18nGet("unattend.region.title", "Language - Region"), $iX, $iY, $iContentW, $iGroupH)

    ; System Language
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    Global $idViewUnattendSysLangLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    Global $idViewUnattendSysLangCmb = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendSysLangCmb, "English|Tiếng Việt", "English")

    ; User Language
    $iItemY += $iRowH
    Global $idViewUnattendUsrLangLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    Global $idViewUnattendUsrLangCmb = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendUsrLangCmb, "English|Tiếng Việt", "English")

    ; System & User Language Same Checkbox
    $iItemY += $iRowH
    Global $idViewUnattendSysUsrLangSameLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    ;Check box size issue
    Global $idViewUnattendSysUsrLangSameCkbx = GUICtrlCreateCheckbox("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)

    ; UI Language
    $iItemY += $iRowH
    Global $idViewUnattendUILangLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    Global $idViewUnattendUILangCmb = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendUILangCmb, "English|Tiếng Việt", "English")

    ; Keyboard Layout
    $iItemY += $iRowH
    Global $idViewUnattendKbLayoutLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    Global $idViewUnattendKbLayoutCmb = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendKbLayoutCmb, "en-us|vi-vn", "en-us")

    ; Time Zone
    $iItemY += $iRowH
    Global $idViewUnattendTZLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    Global $idViewUnattendTZCmb = GUICtrlCreateCombo("", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)
    GUICtrlSetData($idViewUnattendTZCmb, "UTC-8|UTC-7|UTC-6|UTC-5|UTC-4|UTC-3|UTC-2|UTC-1|UTC|UTC+1|UTC+2|UTC+3|UTC+4|UTC+5|UTC+6|UTC+7|UTC+8|UTC+9|UTC+10", "UTC+7")

    GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; Initialize Partition Group
    $iX = $iP
    $iY += $iGroupH + $iP
    $iGroupH = $iRowH * 6 + $iP * 3
    Global $hViewUnattendPartitionGroup = GUICtrlCreateGroup(i18nGet("unattend.partition.title", "Disk Partitions"), $iX, $iY, $iContentW, $iGroupH)

    ; Partition Auto/Manual/Hybrid
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    Global $idViewUnattendPartitionManLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    Global $idViewUnattendPartitionManRdoC1 = GUICtrlCreateRadio(i18nGet("unattend.partitionman.auto", "Auto"), $iP * 3 + $iLblW, $iItemY - $iPx, $iInputW / 3 - $iP * 2, $iLblH + $iPx)
    Global $idViewUnattendPartitionManRdoC2 = GUICtrlCreateRadio(i18nGet("unattend.partitionman.manual", "Manual"), $iP * 3 + $iLblW + $iInputW / 3 + $iP, $iItemY - $iPx, $iInputW / 3 - $iP * 2, $iLblH + $iPx)
    Global $idViewUnattendPartitionManRdoC3 = GUICtrlCreateRadio(i18nGet("unattend.partitionman.hybrid", "Hybrid"), $iP * 3 + $iLblW + $iInputW / 3 * 2 + $iP * 2, $iItemY - $iPx, $iInputW / 3 - $iP * 2, $iLblH + $iPx)
    GUICtrlSetState($idViewUnattendPartitionManRdoC1, $GUI_CHECKED)

    ; Partition Disk ID
    $iItemY += $iRowH
    Global $idViewUnattendPartitionDiskIDLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    Global $idViewUnattendPartitionDiskIDInput = GUICtrlCreateInput("$$VT_WINDOWS_DISK_1ST_NONVTOY$$", $iX + $iLblW, $iItemY - $iPx, $iInputW, $iLblH + $iPx * 2)

    ; Parition Type
    $iItemY += $iRowH
    Global $idViewUnattendPartitionTypeLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    Global $idViewUnattendPartitionTypeRdoC1 = GUICtrlCreateRadio(i18nGet("unattend.partitiontype.gpt", "GPT"), $iP * 3 + $iLblW, $iItemY - $iPx, $iInputW / 2 - $iP, $iLblH + $iPx)
    Global $idViewUnattendPartitionTypeRdoC2 = GUICtrlCreateRadio(i18nGet("unattend.partitiontype.mbr", "MBR"), $iP * 3 + $iLblW + $iInputW / 2 + $iP, $iItemY - $iPx, $iInputW / 2 - $iP, $iLblH + $iPx)
    GUICtrlSetState($idViewUnattendPartitionTypeRdoC1, $GUI_CHECKED)

    ; Partition Table (Not implemented)
    $iItemY += $iRowH
    Global $idViewUnattendPartitionTblLbl = GUICtrlCreateLabel("", $iX, $iItemY, $iLblW, $iLblH)
    
    GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; Initialize Bypass Group
    $iX = $iP
    $iY += $iGroupH + $iP
    $iGroupH = $iRowH * 4 + $iP * 3
    Global $hViewUnattendBypassGroup = GUICtrlCreateGroup(i18nGet("unattend.bypass.title", "Bypass Hardware Checks"), $iX, $iY, $iContentW, $iGroupH)
    
    ; Initialize OOBE Group

    ; Initialize Local Account Group

    ; Initialize Bloatware Group

    ; Initialize Scripts Group
    
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

    GUICtrlSetData($hViewUnattendWindowsGroup, i18nGet("unattend.windows.title", "Windows"))
    GUICtrlSetData($idViewUnattendEditionLbl, i18nGet("unattend.edition.label", "Windows Edition"))
    GUICtrlSetData($idViewUnattendProductKeyLbl, i18nGet("unattend.productkey.label", "Product Key"))
    GUICtrlSetData($idViewUnattendArchLbl, i18nGet("unattend.arch.label", "Architecture"))
    GUICtrlSetData($idViewUnattendPCNameLbl, i18nGet("unattend.pcname.label", "Computer Name"))
    
    GUICtrlSetData($hViewUnattendRegionGroup, i18nGet("unattend.region.title", "Language - Region"))
    GUICtrlSetData($idViewUnattendSysLangLbl, i18nGet("unattend.syslang.label", "System Language"))
    GUICtrlSetData($idViewUnattendUsrLangLbl, i18nGet("unattend.usrlang.label", "User Language"))
    GUICtrlSetData($idViewUnattendSysUsrLangSameLbl, i18nGet("unattend.sysusrlangsame.label", "Same as System Language"))
    GUICtrlSetData($idViewUnattendUILangLbl, i18nGet("unattend.uilang.label", "UI Language"))
    GUICtrlSetData($idViewUnattendKbLayoutLbl, i18nGet("unattend.kblayout.label", "Keyboard Layout"))
    GUICtrlSetData($idViewUnattendTZLbl, i18nGet("unattend.timezone.label", "Time Zone"))

    GUICtrlSetData($hViewUnattendPartitionGroup, i18nGet("unattend.partition.title", "Disk Partitions"))
    GUICtrlSetData($idViewUnattendPartitionManLbl, i18nGet("unattend.partitionman.label", "Partition Method"))
    GUICtrlSetData($idViewUnattendPartitionManRdoC1, i18nGet("unattend.partitionman.auto", "Auto"))
    GUICtrlSetData($idViewUnattendPartitionManRdoC2, i18nGet("unattend.partitionman.manual", "Manual"))
    GUICtrlSetData($idViewUnattendPartitionManRdoC3, i18nGet("unattend.partitionman.hybrid", "Hybrid"))
    GUICtrlSetData($idViewUnattendPartitionTypeLbl, i18nGet("unattend.partitiontype.label", "Partition Type"))
    GUICtrlSetData($idViewUnattendPartitionTypeRdoC1, i18nGet("unattend.partitiontype.gpt", "GPT"))
    GUICtrlSetData($idViewUnattendPartitionTypeRdoC2, i18nGet("unattend.partitiontype.mbr", "MBR"))
    GUICtrlSetData($idViewUnattendPartitionTblLbl, i18nGet("unattend.partitiontbl.label", "Partition Table"))

    GUICtrlSetData($hViewUnattendBypassGroup, i18nGet("unattend.bypass.title", "Bypass Hardware Checks"))
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