;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/ventoy.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Libraries
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <FileConstants.au3>
#include <GuiListView.au3>
#include <GuiComboBox.au3>
#include <GuiStatusBar.au3>
#include <File.au3>
#include <WinAPISys.au3>

; Controls
#include "../controls/button.au3"

; Modules
#include "../modules/i18n.au3"
#include "../modules/theme.au3"
#include "../modules/config.au3"
#include "../modules/scroll.au3"
#include "../modules/control.au3"
#include "../modules/dialog.au3"
#include "../modules/ventoy.au3"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Global View Controls & State
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global $hViewVentoy = 0
Global $idViewVentoyTitle = 0

; Section 1: Theme Selection
Global $hViewVentoyThemeGroup = 0
Global $idViewVentoyThemeLbl = 0
Global $idViewVentoyThemeCmb = 0

; Section 2: Theme Variant Selection
Global $hViewVentoyVariantGroup = 0
Global $idViewVentoyVariantLbl = 0
Global $idViewVentoyVariantResetBtn = 0
Global $idViewVentoyVariantPreviewBtn = 0
Global $idViewVentoyVariantRefreshBtn = 0
Global $idViewVentoyVariantSetBtn = 0
Global $idViewVentoyVariantList = 0
Global $hViewVentoyVariantList = 0
Global $g_sViewVentoyActiveVariant = "dark_fb"

; Section 3: Managing Boot Entries
Global $hViewVentoyBootGroup = 0
Global $idViewVentoyBootLbl = 0
Global $idViewVentoyBootResetBtn = 0
Global $idViewVentoyBootAddBtn = 0
Global $idViewVentoyBootRemoveBtn = 0
Global $idViewVentoyBootEditBtn = 0
Global $idViewVentoyBootList = 0
Global $hViewVentoyBootList = 0

; Keyboard Accelerators for Re-ordering Boot Entries
Global $idViewVentoyDummyUp = 0
Global $idViewVentoyDummyDown = 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; View Creation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewVentoyCreate($hViewport, $iW, $iH)
    #forceref $iW, $iH
    Local $iContentW = scrollGetContentWidth($iP)
    Local $iContentH = $iH
    If $iContentH < 850 Then $iContentH = 850

    $hViewVentoy = scrollCreateCanvas($hViewport, $iContentH)
    GUISwitch($hViewVentoy)

    $idViewVentoyDummyUp = GUICtrlCreateDummy()
    $idViewVentoyDummyDown = GUICtrlCreateDummy()

    Local $iPx = $iLblH * 20 / 100
    Local $iRowH = $iLblH + $iP * 2
    Local $iInputH = $iLblH + $iPx * 2
    Local $iLblW = ($iContentW - $iP * 6) * 35 / 100
    Local $iInputW = ($iContentW - $iP * 6) * 58 / 100
    Local $iTableW = $iContentW - $iP * 4
    Local $iBtnW = ($iTableW * 92 / 100 - 4 * $iP) / 5

    ; 1. Title
    Local $iX = $iP
    Local $iY = $iP
    Local $iCtrlW = $iContentW
    Local $iCtrlH = $iLblH * 2
    $idViewVentoyTitle = GUICtrlCreateLabel("", $iX, $iY, $iCtrlW, $iCtrlH)
    GUICtrlSetFont(-1, $iHeader, 800)

    ; =========================================
    ; Section 1: Theme Selection
    ; =========================================
    $iY += $iCtrlH + $iP
    Local $iThemeGroupH = $iRowH + $iP * 3
    $hViewVentoyThemeGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iThemeGroupH)

    ; Theme Selection Dropdown Row
    $iX = $iP * 3
    Local $iItemY = $iY + $iP * 3
    Local $iSliderX = $iP * 3 + $iLblW
    $idViewVentoyThemeLbl = GUICtrlCreateLabel(i18nGet("ventoy.theme.label", "Theme: "), $iX, $iItemY, $iLblW, $iLblH)
    $idViewVentoyThemeCmb = GUICtrlCreateCombo("", $iSliderX, $iItemY - $iPx, $iInputW, $iInputH, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
    GUICtrlSetData($idViewVentoyThemeCmb, "1172005thinh (Full)|1172005thinh (Single)|Ventoy", "1172005thinh (Full)")
    GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; =========================================
    ; Section 2: Theme Variant Selection
    ; =========================================
    $iX = $iP
    $iY += $iThemeGroupH + $iP
    Local $iVarTableH = $iRowH * 4
    Local $iVariantGroupH = $iRowH + $iVarTableH + $iBtnH + $iP * 6
    $hViewVentoyVariantGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iVariantGroupH)

    ; Header Row: Label on left, Reset button on far right
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewVentoyVariantLbl = GUICtrlCreateLabel(i18nGet("ventoy.theme.variant.label", "Theme Variant: "), $iX, $iItemY + $iPx, $iTableW - $iBtnW - $iP, $iLblH)
    $idViewVentoyVariantResetBtn = GUICtrlCreateButton(i18nGet("ventoy.theme.variant.btn.reset", "Reset"), ($iX + $iTableW) - $iBtnW, $iItemY - $iPx, $iBtnW, $iBtnH)

    ; Theme Variant ListView
    $iItemY += $iRowH + $iP
    Local $sVarColHeaders = i18nGet("ventoy.theme.variant.col.name", "Variant Name") & "|" & i18nGet("ventoy.theme.variant.col.resolution", "Resolution")
    $idViewVentoyVariantList = GUICtrlCreateListView($sVarColHeaders, $iX, $iItemY, $iTableW, $iVarTableH)
    $hViewVentoyVariantList = GUICtrlGetHandle($idViewVentoyVariantList)
    _GUICtrlListView_SetExtendedListViewStyle($idViewVentoyVariantList, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))
    Local $iVarCol0W = Int($iTableW * 25 / 100)
    Local $iVarCol1W = $iTableW - $iVarCol0W - 2 * $iP - 2 * $iPx
    _GUICtrlListView_SetColumnWidth($idViewVentoyVariantList, 0, $iVarCol0W)
    _GUICtrlListView_SetColumnWidth($idViewVentoyVariantList, 1, $iVarCol1W)

    ; Variant Control Buttons below table (Preview, Refresh, Set right-aligned)
    $iItemY += $iVarTableH + $iP
    Local $iVarBtnRowW = 3 * $iBtnW + 2 * $iP
    Local $iVarBtnStartX = ($iX + $iTableW) - $iVarBtnRowW
    $idViewVentoyVariantPreviewBtn = GUICtrlCreateButton(i18nGet("ventoy.theme.variant.btn.preview", "Preview"), $iVarBtnStartX, $iItemY, $iBtnW, $iBtnH)
    $idViewVentoyVariantRefreshBtn = GUICtrlCreateButton(i18nGet("ventoy.theme.variant.btn.refresh", "Refresh"), $iVarBtnStartX + $iBtnW + $iP, $iItemY, $iBtnW, $iBtnH)
    $idViewVentoyVariantSetBtn = GUICtrlCreateButton(i18nGet("ventoy.theme.variant.btn.set", "Set"), $iVarBtnStartX + ($iBtnW + $iP) * 2, $iItemY, $iBtnW, $iBtnH)
    GUICtrlCreateGroup("", -99, -99, -99, -99)

    ; =========================================
    ; Section 3: Managing Boot Entries
    ; =========================================
    $iX = $iP
    $iY += $iVariantGroupH + $iP
    Local $iBootTableH = $iRowH * 5
    Local $iBootGroupH = $iRowH + $iBootTableH + $iBtnH + $iP * 6
    $hViewVentoyBootGroup = GUICtrlCreateGroup("", $iX, $iY, $iContentW, $iBootGroupH)

    ; Header Row: Label on left, Reset button on far right
    $iX = $iP * 3
    $iItemY = $iY + $iP * 3
    $idViewVentoyBootLbl = GUICtrlCreateLabel(i18nGet("ventoy.boot.label", "Boot Entries: "), $iX, $iItemY + $iPx, $iTableW - $iBtnW - $iP, $iLblH)
    $idViewVentoyBootResetBtn = GUICtrlCreateButton(i18nGet("ventoy.boot.btn.reset", "Reset"), ($iX + $iTableW) - $iBtnW, $iItemY - $iPx, $iBtnW, $iBtnH)

    ; Boot Entries Table (6 columns: ID|Icon|Alias|Image|Tip|Template)
    $iItemY += $iRowH + $iP
    Local $sBootColHeaders = i18nGet("ventoy.boot.col.id", "ID") & "|" & _
        i18nGet("ventoy.boot.col.icon", "Icon") & "|" & _
        i18nGet("ventoy.boot.col.alias", "Alias") & "|" & _
        i18nGet("ventoy.boot.col.image", "Image") & "|" & _
        i18nGet("ventoy.boot.col.tip", "Tip") & "|" & _
        i18nGet("ventoy.boot.col.template", "Template")

    Local $iBootVirtualW = Int($iTableW * 1.5)
    $idViewVentoyBootList = GUICtrlCreateListView($sBootColHeaders, $iX, $iItemY, $iTableW, $iBootTableH, BitOR($LVS_REPORT, $LVS_SINGLESEL, $WS_HSCROLL, $WS_VSCROLL))
    $hViewVentoyBootList = GUICtrlGetHandle($idViewVentoyBootList)
    _GUICtrlListView_SetExtendedListViewStyle($idViewVentoyBootList, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))

    Local $iBCol0 = 45                                    ; ID
    Local $iBCol1 = 80                                    ; Icon
    Local $iBCol2 = Int($iTableW * 26 / 100)              ; Alias
    Local $iBCol3 = Int($iTableW * 38 / 100)              ; Image
    Local $iBCol4 = Int($iBootVirtualW * 25 / 100)        ; Tip
    Local $iBCol5 = $iBootVirtualW - ($iBCol0 + $iBCol1 + $iBCol2 + $iBCol3 + $iBCol4) - 2 * $iP - 2 * $iPx ; Template
    _GUICtrlListView_SetColumnWidth($idViewVentoyBootList, 0, $iBCol0)
    _GUICtrlListView_SetColumnWidth($idViewVentoyBootList, 1, $iBCol1)
    _GUICtrlListView_SetColumnWidth($idViewVentoyBootList, 2, $iBCol2)
    _GUICtrlListView_SetColumnWidth($idViewVentoyBootList, 3, $iBCol3)
    _GUICtrlListView_SetColumnWidth($idViewVentoyBootList, 4, $iBCol4)
    _GUICtrlListView_SetColumnWidth($idViewVentoyBootList, 5, $iBCol5)

    ; Boot Entries Action Buttons below table (Add, Remove, Edit right-aligned)
    $iItemY += $iBootTableH + $iP
    Local $iBootBtnRowW = 3 * $iBtnW + 2 * $iP
    Local $iBootBtnStartX = ($iX + $iTableW) - $iBootBtnRowW
    $idViewVentoyBootAddBtn = GUICtrlCreateButton(i18nGet("ventoy.boot.btn.add", "Add"), $iBootBtnStartX, $iItemY, $iBtnW, $iBtnH)
    $idViewVentoyBootRemoveBtn = GUICtrlCreateButton(i18nGet("ventoy.boot.btn.remove", "Remove"), $iBootBtnStartX + $iBtnW + $iP, $iItemY, $iBtnW, $iBtnH)
    $idViewVentoyBootEditBtn = GUICtrlCreateButton(i18nGet("ventoy.boot.btn.edit", "Edit"), $iBootBtnStartX + ($iBtnW + $iP) * 2, $iItemY, $iBtnW, $iBtnH)
    GUICtrlCreateGroup("", -99, -99, -99, -99)

    Local $iContentBottom = $iY + $iBootGroupH + $iP * 2
    If $iContentBottom < $iH Then $iContentBottom = $iH
    scrollSetContentHeight($hViewVentoy, $iContentBottom)

    viewVentoyApplyLang()
    viewVentoyApplyTheme()
    viewVentoyLoadData()

    Return $hViewVentoy
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Theme & Variant Management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _ViewVentoyOnThemeChange()
    Local $sTheme = GUICtrlRead($idViewVentoyThemeCmb)
    Local $iVariantState = ($sTheme = "1172005thinh (Single)") ? $GUI_ENABLE : $GUI_DISABLE

    GUICtrlSetState($hViewVentoyVariantGroup, $iVariantState)
    GUICtrlSetState($idViewVentoyVariantLbl, $iVariantState)
    GUICtrlSetState($idViewVentoyVariantResetBtn, $iVariantState)
    GUICtrlSetState($idViewVentoyVariantList, $iVariantState)
    GUICtrlSetState($idViewVentoyVariantPreviewBtn, $iVariantState)
    GUICtrlSetState($idViewVentoyVariantRefreshBtn, $iVariantState)
    GUICtrlSetState($idViewVentoyVariantSetBtn, $iVariantState)
EndFunc

Func _ViewVentoyLoadVariants()
    _GUICtrlListView_DeleteAllItems($hViewVentoyVariantList)
    Local $aVariants = ventoyGetVariantsData()
    Local $iActiveIdx = 0

    For $i = 0 To UBound($aVariants, 1) - 1
        Local $sName = $aVariants[$i][0]
        Local $sRes = $aVariants[$i][1]
        Local $sDisplayName = $sName
        If $sName = $g_sViewVentoyActiveVariant Then
            $sDisplayName = "*" & $sName
            $iActiveIdx = $i
        EndIf
        GUICtrlCreateListViewItem($sDisplayName & "|" & $sRes, $idViewVentoyVariantList)
    Next

    _GUICtrlListView_SetItemSelected($hViewVentoyVariantList, $iActiveIdx, True, True)
EndFunc

Func _ViewVentoyResetVariant()
    $g_sViewVentoyActiveVariant = "dark_fb"
    _ViewVentoyLoadVariants()
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("ventoy.status.variant_set", "Set active theme variant") & " (*dark_fb)")
EndFunc

Func _ViewVentoySetVariant()
    Local $sSel = _GUICtrlListView_GetSelectedIndices($hViewVentoyVariantList)
    If $sSel = "" Then Return
    Local $iIdx = Number($sSel)
    Local $sName = _GUICtrlListView_GetItemText($hViewVentoyVariantList, $iIdx, 0)
    If StringLeft($sName, 1) = "*" Then $sName = StringTrimLeft($sName, 1)
    $g_sViewVentoyActiveVariant = $sName
    _ViewVentoyLoadVariants()
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("ventoy.status.variant_set", "Set active theme variant") & " (*" & $sName & ")")
EndFunc

Func _ViewVentoyPreviewVariant()
    Local $sSel = _GUICtrlListView_GetSelectedIndices($hViewVentoyVariantList)
    If $sSel = "" Then Return
    Local $iIdx = Number($sSel)
    Local $sName = _GUICtrlListView_GetItemText($hViewVentoyVariantList, $iIdx, 0)
    If StringLeft($sName, 1) = "*" Then $sName = StringTrimLeft($sName, 1)

    Local $sThemeDir = ventoyGetThemeDir()
    Local $sTargetImg = $sThemeDir & "\" & $sName & "_1920x1080.jpg"

    If Not FileExists($sTargetImg) Then
        ; Fallback: find first matching image for this variant
        Local $hSearch = FileFindFirstFile($sThemeDir & "\" & $sName & "_*.jpg")
        If $hSearch <> -1 Then
            Local $sFound = FileFindNextFile($hSearch)
            FileClose($hSearch)
            If $sFound <> "" Then $sTargetImg = $sThemeDir & "\" & $sFound
        EndIf
    EndIf

    If FileExists($sTargetImg) Then
        ShellExecute($sTargetImg)
    Else
        MsgBox(BitOR($MB_ICONINFORMATION, $MB_OK), i18nGet("info.dialog.title", "Information"), "Preview image not found: " & $sTargetImg)
    EndIf
EndFunc

Func _ViewVentoyRefreshVariants()
    _ViewVentoyLoadVariants()
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("ventoy.status.refreshed", "Refreshed theme variants"))
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Boot Entries Management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _ViewVentoyResetBootEntries()
    _GUICtrlListView_DeleteAllItems($hViewVentoyBootList)
    ; Default: 1|windows|*Windows 11|/Windows/Windows11/w11.iso|Windows 11 Installation|/AutoInstaller.xml; /Manual.xml
    Local $idItem = GUICtrlCreateListViewItem("1|windows|*Windows 11|/Windows/Windows11/w11.iso|Windows 11 Installation|/AutoInstaller.xml; /Manual.xml", $idViewVentoyBootList)
    #forceref $idItem
    _GUICtrlListView_SetItemSelected($hViewVentoyBootList, 0, True, True)
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("ventoy.status.boot_reset", "Reset boot entries to defaults"))
EndFunc

Func _ViewVentoyRemoveBootEntries()
    Local $sSel = _GUICtrlListView_GetSelectedIndices($hViewVentoyBootList)
    If $sSel = "" Then
        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("ventoy.status.select_remove", "Please select or check boot entries to remove"))
        Return
    EndIf

    Local $iDelIdx = Number($sSel)
    _GUICtrlListView_DeleteItem($hViewVentoyBootList, $iDelIdx)

    ; Renumber IDs sequentially 1..N at column 0
    Local $iCount = _GUICtrlListView_GetItemCount($hViewVentoyBootList)
    For $i = 0 To $iCount - 1
        _GUICtrlListView_SetItemText($hViewVentoyBootList, $i, String($i + 1), 0)
    Next

    If $iCount > 0 Then
        Local $iNewSel = ($iDelIdx < $iCount) ? $iDelIdx : ($iCount - 1)
        _GUICtrlListView_SetItemSelected($hViewVentoyBootList, $iNewSel, True, True)
    EndIf
    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("ventoy.status.boot_removed", "Removed selected boot entries"))
EndFunc

Func _ViewVentoyMoveEntryUp()
    controlListViewMoveItemUp($hViewVentoyBootList, 1, 5)
EndFunc

Func _ViewVentoyMoveEntryDown()
    controlListViewMoveItemDown($hViewVentoyBootList, 1, 5)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Add & Edit Boot Entry Modal Dialog
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _ViewVentoyShowBootDialog($bEdit = False)
    Local $sCurIcon = "windows"
    Local $sCurAlias = ""
    Local $bCurAutosel = False
    Local $sCurImage = "/Windows/Windows11/w11.iso"
    Local $sCurAttach = ""
    Local $sCurTip = "Windows 11 Installation"
    Local $sCurTemplates = "/AutoInstaller.xml; /Manual.xml"
    Local $iEditRow = -1

    If $bEdit Then
        Local $sSel = _GUICtrlListView_GetSelectedIndices($hViewVentoyBootList)
        If $sSel = "" Then
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("ventoy.status.select_edit", "Please select a boot entry row to edit"))
            Return
        EndIf
        $iEditRow = Number($sSel)
        $sCurIcon = _GUICtrlListView_GetItemText($hViewVentoyBootList, $iEditRow, 1)
        $sCurAlias = _GUICtrlListView_GetItemText($hViewVentoyBootList, $iEditRow, 2)
        If StringLeft($sCurAlias, 1) = "*" Then
            $bCurAutosel = True
            $sCurAlias = StringTrimLeft($sCurAlias, 1)
        EndIf
        $sCurImage = _GUICtrlListView_GetItemText($hViewVentoyBootList, $iEditRow, 3)
        $sCurTip = _GUICtrlListView_GetItemText($hViewVentoyBootList, $iEditRow, 4)
        $sCurTemplates = _GUICtrlListView_GetItemText($hViewVentoyBootList, $iEditRow, 5)
    EndIf

    Local $sDlgTitle = $bEdit ? i18nGet("ventoy.dialog.edit.title", "Edit Boot Entry") : i18nGet("ventoy.dialog.add.title", "Add Boot Entry")
    Local $hDlg = GUICreate($sDlgTitle, 560, 520, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOPMOST, $hViewVentoy)
    GUISetBkColor(themeColor("main.view.bg"), $hDlg)

    ; Status Bar (matching Add Apps dialog style)
    Local $hStatus = _GUICtrlStatusBar_Create($hDlg)
    _GUICtrlStatusBar_SetText($hStatus, i18nGet("status.ready", "Ready"), 0)

    ; Group 1: Boot Entry Details
    Local $idGrpDetails = GUICtrlCreateGroup(i18nGet("ventoy.dialog.group.details", "Boot Entry Details"), 12, 10, 536, 195)
    #forceref $idGrpDetails

    ; Icon Row
    Local $idIconLbl = GUICtrlCreateLabel(i18nGet("ventoy.dialog.icon.label", "Icon: "), 24, 34, 85, 20)
    Local $idIconCmb = GUICtrlCreateCombo("", 115, 32, 421, 22, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
    Local $sAvailableIcons = ventoyGetAvailableIcons()
    GUICtrlSetData($idIconCmb, $sAvailableIcons, $sCurIcon)
    GUICtrlSetTip($idIconCmb, i18nGet("ventoy.dialog.icon.tip", "Icon representing this OS boot entry"))

    ; Alias Row
    Local $idAliasLbl = GUICtrlCreateLabel(i18nGet("ventoy.dialog.alias.label", "Alias: "), 24, 64, 85, 20)
    Local $idAliasInput = GUICtrlCreateInput($sCurAlias, 115, 62, 230, 22)
    controlSetCueBanner($idAliasInput, i18nGet("ventoy.dialog.alias.placeholder", "(Optional)"))
    GUICtrlSetTip($idAliasInput, i18nGet("ventoy.dialog.alias.tip", "Display name in Ventoy boot menu"))

    Local $idAutoselCkbx = GUICtrlCreateCheckbox(i18nGet("ventoy.dialog.ckbx.autosel", "Auto-select when booting"), 355, 62, 181, 22)
    GUICtrlSetTip($idAutoselCkbx, i18nGet("ventoy.dialog.ckbx.autosel.tip", "Automatically select this entry as the default boot target"))
    If $bCurAutosel Then GUICtrlSetState($idAutoselCkbx, $GUI_CHECKED)

    ; Image Row
    Local $idImageLbl = GUICtrlCreateLabel(i18nGet("ventoy.dialog.image.label", "Image: "), 24, 94, 85, 20)
    Local $idImageInput = GUICtrlCreateInput($sCurImage, 115, 92, 421, 22)
    controlSetCueBanner($idImageInput, i18nGet("ventoy.dialog.image.placeholder", "/Windows/Windows11/w11.iso"))
    GUICtrlSetTip($idImageInput, i18nGet("ventoy.dialog.image.tip", "Relative path of ISO image file on USB drive"))

    ; Attach ISO Row
    Local $idAttachLbl = GUICtrlCreateLabel(i18nGet("ventoy.dialog.attach_iso.label", "Attach ISO: "), 24, 124, 85, 20)
    Local $idAttachInput = GUICtrlCreateInput($sCurAttach, 115, 122, 336, 22)
    controlSetCueBanner($idAttachInput, i18nGet("ventoy.dialog.attach_iso.placeholder", "Select local ISO image..."))
    Local $idAttachBrowseBtn = GUICtrlCreateButton(i18nGet("ventoy.dialog.btn.browse", "Browse"), 456, 122, 80, 22)
    GUICtrlSetTip($idAttachBrowseBtn, i18nGet("ventoy.dialog.btn.browse.tip", "Browse for local ISO image file"))

    ; Tip Row
    Local $idTipLbl = GUICtrlCreateLabel(i18nGet("ventoy.dialog.tip.label", "Tip: "), 24, 154, 85, 20)
    Local $idTipInput = GUICtrlCreateInput($sCurTip, 115, 152, 421, 22)
    controlSetCueBanner($idTipInput, i18nGet("ventoy.dialog.tip.placeholder", "Windows 11 Installation"))
    GUICtrlSetTip($idTipInput, i18nGet("ventoy.dialog.tip.tip", "Helpful description shown in Ventoy boot menu"))
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    ; Group 2: Unattend Templates
    Local $idGrpTpl = GUICtrlCreateGroup(i18nGet("ventoy.dialog.group.template", "Unattend Templates"), 12, 212, 536, 226)
    #forceref $idGrpTpl

    ; Template ListView (4 rows height, 512 width)
    Local $idDlgTplList = GUICtrlCreateListView(i18nGet("ventoy.dialog.template.col.path", "Template Path"), 24, 234, 512, 96)
    Local $hDlgTplList = GUICtrlGetHandle($idDlgTplList)
    _GUICtrlListView_SetExtendedListViewStyle($idDlgTplList, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))
    _GUICtrlListView_SetColumnWidth($idDlgTplList, 0, 508)

    Local $aInitialTpls = StringSplit($sCurTemplates, ";", $STR_NOCOUNT)
    For $t = 0 To UBound($aInitialTpls) - 1
        Local $sCleanTpl = StringStripWS($aInitialTpls[$t], $STR_STRIPLEADING + $STR_STRIPTRAILING)
        If $sCleanTpl <> "" Then GUICtrlCreateListViewItem($sCleanTpl, $idDlgTplList)
    Next
    If _GUICtrlListView_GetItemCount($hDlgTplList) > 0 Then
        _GUICtrlListView_SetItemSelected($hDlgTplList, 0, True, True)
    EndIf

    ; Template Input Row
    Local $idTplItemLbl = GUICtrlCreateLabel(i18nGet("ventoy.dialog.template.label", "Template: "), 24, 338, 85, 20)
    Local $idDlgTplInput = GUICtrlCreateInput((_GUICtrlListView_GetItemCount($hDlgTplList) > 0) ? _GUICtrlListView_GetItemText($hDlgTplList, 0) : "", 115, 336, 421, 22)
    controlSetCueBanner($idDlgTplInput, i18nGet("ventoy.dialog.template.placeholder", "/AutoInstaller.xml"))

    ; Template Action Buttons Row (5 buttons right-aligned to table width: 152 to 536)
    Local $idTplAddBtn = GUICtrlCreateButton(i18nGet("ventoy.dialog.template.btn.add", "Add"), 152, 366, 72, 24)
    Local $idTplRemoveBtn = GUICtrlCreateButton(i18nGet("ventoy.dialog.template.btn.remove", "Remove"), 230, 366, 72, 24)
    Local $idTplClearBtn = GUICtrlCreateButton(i18nGet("ventoy.dialog.template.btn.clear", "Clear"), 308, 366, 72, 24)
    Local $idTplSaveBtn = GUICtrlCreateButton(i18nGet("ventoy.dialog.template.btn.save", "Save"), 386, 366, 72, 24)
    Local $idTplCancelBtn = GUICtrlCreateButton(i18nGet("ventoy.dialog.template.btn.cancel", "Cancel"), 464, 366, 72, 24)
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    ; Dialog Bottom Buttons (Reset on bottom-left, Save and Cancel on bottom-right matching Add Apps dialog)
    Local $idDlgResetBtn = GUICtrlCreateButton(i18nGet("ventoy.dialog.btn.reset", "Reset"), 12, 450, 80, 28)
    Local $idDlgSaveBtn = GUICtrlCreateButton(i18nGet("ventoy.dialog.btn.save", "Save"), 370, 450, 85, 28, $BS_DEFPUSHBUTTON)
    Local $idDlgCancelBtn = GUICtrlCreateButton(i18nGet("ventoy.dialog.btn.cancel", "Cancel"), 463, 450, 85, 28)

    ; Keyboard accelerator: Enter key triggers default save button
    Local $aDlgAccel[1][2] = [["{ENTER}", $idDlgSaveBtn]]
    GUISetAccelerators($aDlgAccel, $hDlg)

    ; Apply Theme Colors to Dialog Labels
    GUICtrlSetColor($idIconLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idIconLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idAliasLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idAliasLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idAutoselCkbx, themeColor("text.primary"))
    GUICtrlSetBkColor($idAutoselCkbx, themeColor("main.view.bg"))
    GUICtrlSetColor($idImageLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idImageLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idAttachLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idAttachLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idTipLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idTipLbl, themeColor("main.view.bg"))
    GUICtrlSetColor($idTplItemLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idTplItemLbl, themeColor("main.view.bg"))

    GUISetState(@SW_SHOW, $hDlg)

    Local $sLastTplSel = "-1"

    While 1
        ; Live tracking of template list selection
        Local $sCurTplSel = _GUICtrlListView_GetSelectedIndices($hDlgTplList)
        If $sCurTplSel <> "" And $sCurTplSel <> $sLastTplSel Then
            $sLastTplSel = $sCurTplSel
            Local $sTplText = _GUICtrlListView_GetItemText($hDlgTplList, Number($sCurTplSel))
            GUICtrlSetData($idDlgTplInput, $sTplText)
            _GUICtrlStatusBar_SetText($hStatus, "Selected template: " & $sTplText, 0)
        EndIf

        Local $idMsg = GUIGetMsg()
        Switch $idMsg
            Case $GUI_EVENT_CLOSE, $idDlgCancelBtn
                ExitLoop

            Case $idAttachBrowseBtn
                Local $sIsoFilter = i18nGet("ventoy.dialog.iso.filter", "ISO files (*.iso)|All files (*.*)")
                Local $sSelectedIso = FileOpenDialog("Select ISO File", @ScriptDir, $sIsoFilter, BitOR($FD_FILEMUSTEXIST, $FD_PATHMUSTEXIST), "", $hDlg)
                If Not @error And $sSelectedIso <> "" Then
                    GUICtrlSetData($idAttachInput, $sSelectedIso)
                    Local $sIsoFilename = StringRegExpReplace($sSelectedIso, '^.*[\\/]', '')
                    Local $sCurImgVal = GUICtrlRead($idImageInput)
                    If $sCurImgVal = "" Or $sCurImgVal = "/Windows/Windows11/w11.iso" Then
                        GUICtrlSetData($idImageInput, "/Windows/" & $sIsoFilename)
                    EndIf
                    _GUICtrlStatusBar_SetText($hStatus, "Attached ISO: " & $sIsoFilename, 0)
                EndIf

            ; Template Management
            Case $idTplAddBtn
                Local $sNewTpl = StringStripWS(GUICtrlRead($idDlgTplInput), $STR_STRIPLEADING + $STR_STRIPTRAILING)
                If $sNewTpl = "" Then $sNewTpl = "/AutoInstaller.xml"
                Local $iNewItem = GUICtrlCreateListViewItem($sNewTpl, $idDlgTplList)
                #forceref $iNewItem
                Local $iTplCount = _GUICtrlListView_GetItemCount($hDlgTplList)
                _GUICtrlListView_SetItemSelected($hDlgTplList, $iTplCount - 1, True, True)
                GUICtrlSetData($idDlgTplInput, "")
                _GUICtrlStatusBar_SetText($hStatus, "Added template: " & $sNewTpl, 0)

            Case $idTplRemoveBtn
                Local $sTplSel = _GUICtrlListView_GetSelectedIndices($hDlgTplList)
                If $sTplSel <> "" Then
                    Local $iDelIdx = Number($sTplSel)
                    _GUICtrlListView_DeleteItem($hDlgTplList, $iDelIdx)
                    Local $iRemaining = _GUICtrlListView_GetItemCount($hDlgTplList)
                    If $iRemaining > 0 Then
                        Local $iNewSelect = ($iDelIdx < $iRemaining) ? $iDelIdx : ($iRemaining - 1)
                        _GUICtrlListView_SetItemSelected($hDlgTplList, $iNewSelect, True, True)
                        GUICtrlSetData($idDlgTplInput, _GUICtrlListView_GetItemText($hDlgTplList, $iNewSelect))
                    Else
                        GUICtrlSetData($idDlgTplInput, "")
                    EndIf
                    _GUICtrlStatusBar_SetText($hStatus, "Removed template", 0)
                EndIf

            Case $idTplClearBtn
                GUICtrlSetData($idDlgTplInput, "")
                _GUICtrlStatusBar_SetText($hStatus, "Cleared template input", 0)

            Case $idTplSaveBtn
                Local $sTplSel = _GUICtrlListView_GetSelectedIndices($hDlgTplList)
                If $sTplSel <> "" Then
                    _GUICtrlListView_SetItemText($hDlgTplList, Number($sTplSel), GUICtrlRead($idDlgTplInput))
                    _GUICtrlStatusBar_SetText($hStatus, "Updated template", 0)
                EndIf

            Case $idTplCancelBtn
                Local $sTplSel = _GUICtrlListView_GetSelectedIndices($hDlgTplList)
                If $sTplSel <> "" Then
                    GUICtrlSetData($idDlgTplInput, _GUICtrlListView_GetItemText($hDlgTplList, Number($sTplSel)))
                Else
                    GUICtrlSetData($idDlgTplInput, "")
                EndIf
                _GUICtrlStatusBar_SetText($hStatus, "Canceled template edit", 0)

            Case $idDlgResetBtn
                _GUICtrlComboBox_SelectString($idIconCmb, -1, "windows")
                GUICtrlSetData($idAliasInput, "Windows 11")
                GUICtrlSetState($idAutoselCkbx, $GUI_CHECKED)
                GUICtrlSetData($idImageInput, "/Windows/Windows11/w11.iso")
                GUICtrlSetData($idAttachInput, "")
                GUICtrlSetData($idTipInput, "Windows 11 Installation")
                _GUICtrlListView_DeleteAllItems($hDlgTplList)
                GUICtrlCreateListViewItem("/AutoInstaller.xml", $idDlgTplList)
                GUICtrlCreateListViewItem("/Manual.xml", $idDlgTplList)
                _GUICtrlListView_SetItemSelected($hDlgTplList, 0, True, True)
                GUICtrlSetData($idDlgTplInput, "/AutoInstaller.xml")
                _GUICtrlStatusBar_SetText($hStatus, "Reset dialog values to defaults", 0)

            Case $idDlgSaveBtn
                Local $sIcon = GUICtrlRead($idIconCmb)
                If $sIcon = "" Then $sIcon = "windows"
                Local $sAlias = StringStripWS(GUICtrlRead($idAliasInput), $STR_STRIPLEADING + $STR_STRIPTRAILING)
                Local $bAutosel = (GUICtrlRead($idAutoselCkbx) = $GUI_CHECKED)
                If $bAutosel Then
                    If StringLeft($sAlias, 1) <> "*" Then $sAlias = "*" & $sAlias
                Else
                    If StringLeft($sAlias, 1) = "*" Then $sAlias = StringTrimLeft($sAlias, 1)
                EndIf

                Local $sImage = StringStripWS(GUICtrlRead($idImageInput), $STR_STRIPLEADING + $STR_STRIPTRAILING)
                If $sImage = "" Then $sImage = "/Windows/Windows11/w11.iso"
                Local $sTip = StringStripWS(GUICtrlRead($idTipInput), $STR_STRIPLEADING + $STR_STRIPTRAILING)

                ; Build template string
                Local $sTpls = ""
                Local $iTplCount = _GUICtrlListView_GetItemCount($hDlgTplList)
                For $t = 0 To $iTplCount - 1
                    Local $sTText = _GUICtrlListView_GetItemText($hDlgTplList, $t)
                    If $sTText <> "" Then
                        If $sTpls <> "" Then $sTpls &= "; "
                        $sTpls &= $sTText
                    EndIf
                Next
                If $sTpls = "" Then $sTpls = "/AutoInstaller.xml"

                If $bEdit And $iEditRow >= 0 Then
                    _GUICtrlListView_SetItemText($hViewVentoyBootList, $iEditRow, $sIcon, 1)
                    _GUICtrlListView_SetItemText($hViewVentoyBootList, $iEditRow, $sAlias, 2)
                    _GUICtrlListView_SetItemText($hViewVentoyBootList, $iEditRow, $sImage, 3)
                    _GUICtrlListView_SetItemText($hViewVentoyBootList, $iEditRow, $sTip, 4)
                    _GUICtrlListView_SetItemText($hViewVentoyBootList, $iEditRow, $sTpls, 5)
                    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("ventoy.status.boot_updated", "Updated boot entry"))
                Else
                    Local $iNextID = _GUICtrlListView_GetItemCount($hViewVentoyBootList) + 1
                    Local $idNewRow = GUICtrlCreateListViewItem($iNextID & "|" & $sIcon & "|" & $sAlias & "|" & $sImage & "|" & $sTip & "|" & $sTpls, $idViewVentoyBootList)
                    #forceref $idNewRow
                    _GUICtrlListView_SetItemSelected($hViewVentoyBootList, $iNextID - 1, True, True)
                    appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("ventoy.status.boot_added", "Added new boot entry"))
                EndIf

                ExitLoop
        EndSwitch
    WEnd

    GUISetAccelerators(0, $hDlg)
    GUIDelete($hDlg)
    GUISwitch($hViewVentoy)
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration Persistence (ventoy.json)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewVentoyLoadData($sCustomFile = "")
    Local $oData = ventoyLoadConfigData($sCustomFile)
    If Not IsObj($oData) Then
        viewVentoyReset()
        Return False
    EndIf

    Local $sThemeSelection = $oData.Item("Theme")
    $g_sViewVentoyActiveVariant = $oData.Item("Variant")
    _GUICtrlComboBox_SelectString($idViewVentoyThemeCmb, -1, $sThemeSelection)
    _ViewVentoyOnThemeChange()
    _ViewVentoyLoadVariants()

    _GUICtrlListView_DeleteAllItems($hViewVentoyBootList)
    Local $aEntries = $oData.Item("BootEntries")
    Local $iEntryCount = $oData.Item("EntryCount")

    If $iEntryCount > 0 Then
        For $i = 0 To $iEntryCount - 1
            Local $sIcon = $aEntries[$i][0]
            Local $sAlias = $aEntries[$i][1]
            Local $sImage = $aEntries[$i][2]
            Local $sTip = $aEntries[$i][3]
            Local $sTpls = $aEntries[$i][4]
            Local $iAutosel = $aEntries[$i][5]

            If $iAutosel = 1 And StringLeft($sAlias, 1) <> "*" Then
                $sAlias = "*" & $sAlias
            EndIf

            GUICtrlCreateListViewItem(($i + 1) & "|" & $sIcon & "|" & $sAlias & "|" & $sImage & "|" & $sTip & "|" & $sTpls, $idViewVentoyBootList)
        Next
        _GUICtrlListView_SetItemSelected($hViewVentoyBootList, 0, True, True)
    Else
        _ViewVentoyResetBootEntries()
    EndIf

    Return True
EndFunc

Func viewVentoySaveData($sCustomFile = "")
    Local $sTheme = GUICtrlRead($idViewVentoyThemeCmb)
    Local $iEntryCount = _GUICtrlListView_GetItemCount($hViewVentoyBootList)
    Local $aEntries[0][6] ; [Icon, CleanAlias, Image, Tip, Templates, Autosel]

    For $i = 0 To $iEntryCount - 1
        Local $sIcon = _GUICtrlListView_GetItemText($hViewVentoyBootList, $i, 1)
        Local $sRawAlias = _GUICtrlListView_GetItemText($hViewVentoyBootList, $i, 2)
        Local $iAutosel = (StringLeft($sRawAlias, 1) = "*") ? 1 : 0
        Local $sAlias = ($iAutosel = 1) ? StringTrimLeft($sRawAlias, 1) : $sRawAlias
        Local $sImage = _GUICtrlListView_GetItemText($hViewVentoyBootList, $i, 3)
        Local $sTip = _GUICtrlListView_GetItemText($hViewVentoyBootList, $i, 4)
        Local $sTpls = _GUICtrlListView_GetItemText($hViewVentoyBootList, $i, 5)

        ReDim $aEntries[UBound($aEntries, 1) + 1][6]
        $aEntries[UBound($aEntries, 1) - 1][0] = $sIcon
        $aEntries[UBound($aEntries, 1) - 1][1] = $sAlias
        $aEntries[UBound($aEntries, 1) - 1][2] = $sImage
        $aEntries[UBound($aEntries, 1) - 1][3] = $sTip
        $aEntries[UBound($aEntries, 1) - 1][4] = $sTpls
        $aEntries[UBound($aEntries, 1) - 1][5] = $iAutosel
    Next

    Return ventoySaveConfigData($sCustomFile, $sTheme, $g_sViewVentoyActiveVariant, $aEntries)
EndFunc

Func viewVentoyReset()
    _GUICtrlComboBox_SelectString($idViewVentoyThemeCmb, -1, "1172005thinh (Full)")
    _ViewVentoyOnThemeChange()
    $g_sViewVentoyActiveVariant = "dark_fb"
    _ViewVentoyLoadVariants()
    _ViewVentoyResetBootEntries()
EndFunc

Func _ViewVentoyImportConfig()
    Local $sImportFile = dialogImportConfig(@ScriptDir, i18nGet("ventoy.dialog.import.filter", "JSON files (*.json)|All files (*.*)"), "ventoy.dialog.import.title", "Select Ventoy configuration to import")
    If $sImportFile <> "" Then
        If viewVentoyLoadData($sImportFile) Then
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("ventoy.status.imported", "Imported Ventoy configuration successfully"))
        Else
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.error", "Error"))
        EndIf
    EndIf
EndFunc

Func _ViewVentoyExportConfig()
    Local $sExportFile = dialogExportConfig(@ScriptDir, i18nGet("ventoy.dialog.export.filter", "JSON files (*.json)|All files (*.*)"), "ventoy.json", ".json", "ventoy.dialog.export.title", "Export Ventoy configuration")
    If $sExportFile <> "" Then
        If viewVentoySaveData($sExportFile) Then
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("ventoy.status.exported", "Exported Ventoy configuration successfully"))
        Else
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.error", "Error"))
        EndIf
    EndIf
EndFunc

Func _ViewVentoyOpenConfigFile()
    dialogOpenFileInEditor(ventoyGetJsonPath())
EndFunc

Func _ViewVentoyRunPlugson()
    If ventoyRunPlugson() Then
        appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("ventoy.status.plugson_launched", "Launched VentoyPlugson configuration tool"))
    Else
        MsgBox(BitOR($MB_ICONINFORMATION, $MB_OK), i18nGet("info.dialog.title", "Information"), "VentoyPlugson executable not found: " & ventoyGetPlugsonPath())
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Localization & Theming
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewVentoyApplyLang()
    GUICtrlSetData($idViewVentoyTitle, i18nGet("ventoy.title", "Customize Ventoy"))

    ; Section 1: Theme Selection
    GUICtrlSetData($hViewVentoyThemeGroup, i18nGet("ventoy.theme.group.title", "Theme Selection"))
    GUICtrlSetTip($hViewVentoyThemeGroup, i18nGet("ventoy.theme.group.tip", "Select Ventoy GRUB theme suite or variant"))
    GUICtrlSetData($idViewVentoyThemeLbl, i18nGet("ventoy.theme.label", "Theme: "))
    GUICtrlSetTip($idViewVentoyThemeLbl, i18nGet("ventoy.theme.tip", "Select GRUB boot menu theme"))
    GUICtrlSetTip($idViewVentoyThemeCmb, i18nGet("ventoy.theme.tip", "Select GRUB boot menu theme"))

    ; Section 2: Theme Variant Selection
    GUICtrlSetData($hViewVentoyVariantGroup, i18nGet("ventoy.theme.variant.group.title", "Theme Variant Selection"))
    GUICtrlSetTip($hViewVentoyVariantGroup, i18nGet("ventoy.theme.variant.group.tip", "Select and configure theme variant style"))
    GUICtrlSetData($idViewVentoyVariantLbl, i18nGet("ventoy.theme.variant.label", "Theme Variant: "))
    GUICtrlSetTip($idViewVentoyVariantLbl, i18nGet("ventoy.theme.variant.tip", "Active theme style and resolution variant"))
    GUICtrlSetData($idViewVentoyVariantResetBtn, i18nGet("ventoy.theme.variant.btn.reset", "Reset"))
    GUICtrlSetTip($idViewVentoyVariantResetBtn, i18nGet("ventoy.theme.variant.btn.reset.tip", "Reset selected variant to default"))
    GUICtrlSetData($idViewVentoyVariantPreviewBtn, i18nGet("ventoy.theme.variant.btn.preview", "Preview"))
    GUICtrlSetTip($idViewVentoyVariantPreviewBtn, i18nGet("ventoy.theme.variant.btn.preview.tip", "Preview selected theme variant image in default photo viewer"))
    GUICtrlSetData($idViewVentoyVariantRefreshBtn, i18nGet("ventoy.theme.variant.btn.refresh", "Refresh"))
    GUICtrlSetTip($idViewVentoyVariantRefreshBtn, i18nGet("ventoy.theme.variant.btn.refresh.tip", "Refresh list of theme variants"))
    GUICtrlSetData($idViewVentoyVariantSetBtn, i18nGet("ventoy.theme.variant.btn.set", "Set"))
    GUICtrlSetTip($idViewVentoyVariantSetBtn, i18nGet("ventoy.theme.variant.btn.set.tip", "Set selected variant as active"))

    _GUICtrlListView_SetColumn($idViewVentoyVariantList, 0, i18nGet("ventoy.theme.variant.col.name", "Variant Name"))
    _GUICtrlListView_SetColumn($idViewVentoyVariantList, 1, i18nGet("ventoy.theme.variant.col.resolution", "Resolution"))

    ; Section 3: Managing Boot Entries
    GUICtrlSetData($hViewVentoyBootGroup, i18nGet("ventoy.boot.group.title", "Managing Boot Entries"))
    GUICtrlSetTip($hViewVentoyBootGroup, i18nGet("ventoy.boot.group.tip", "Configure boot menu images, aliases, and automated installation mappings"))
    GUICtrlSetData($idViewVentoyBootLbl, i18nGet("ventoy.boot.label", "Boot Entries: "))

    GUICtrlSetData($idViewVentoyBootResetBtn, i18nGet("ventoy.boot.btn.reset", "Reset"))
    GUICtrlSetTip($idViewVentoyBootResetBtn, i18nGet("ventoy.boot.btn.reset.tip", "Reset boot entries to defaults"))
    GUICtrlSetData($idViewVentoyBootAddBtn, i18nGet("ventoy.boot.btn.add", "Add"))
    GUICtrlSetTip($idViewVentoyBootAddBtn, i18nGet("ventoy.boot.btn.add.tip", "Add new boot entry"))
    GUICtrlSetData($idViewVentoyBootRemoveBtn, i18nGet("ventoy.boot.btn.remove", "Remove"))
    GUICtrlSetTip($idViewVentoyBootRemoveBtn, i18nGet("ventoy.boot.btn.remove.tip", "Remove selected boot entry"))
    GUICtrlSetData($idViewVentoyBootEditBtn, i18nGet("ventoy.boot.btn.edit", "Edit"))
    GUICtrlSetTip($idViewVentoyBootEditBtn, i18nGet("ventoy.boot.btn.edit.tip", "Edit selected boot entry"))

    _GUICtrlListView_SetColumn($idViewVentoyBootList, 0, i18nGet("ventoy.boot.col.id", "ID"))
    _GUICtrlListView_SetColumn($idViewVentoyBootList, 1, i18nGet("ventoy.boot.col.icon", "Icon"))
    _GUICtrlListView_SetColumn($idViewVentoyBootList, 2, i18nGet("ventoy.boot.col.alias", "Alias"))
    _GUICtrlListView_SetColumn($idViewVentoyBootList, 3, i18nGet("ventoy.boot.col.image", "Image"))
    _GUICtrlListView_SetColumn($idViewVentoyBootList, 4, i18nGet("ventoy.boot.col.tip", "Tip"))
    _GUICtrlListView_SetColumn($idViewVentoyBootList, 5, i18nGet("ventoy.boot.col.template", "Template"))

    ; Toolbar Buttons
    If $g_hCurrentView = $hViewVentoy Then
        GUICtrlSetData($a_idToolBarBtn[0], i18nGet("reset.btn.title", "Reset"))
        GUICtrlSetTip($a_idToolBarBtn[0], i18nGet("ventoy.toolbar.reset.tip", "Reset all Ventoy settings to defaults"))
        GUICtrlSetData($a_idToolBarBtn[1], i18nGet("import.btn.title", "Import"))
        GUICtrlSetTip($a_idToolBarBtn[1], i18nGet("ventoy.toolbar.import.tip", "Import Ventoy configuration file"))
        GUICtrlSetData($a_idToolBarBtn[2], i18nGet("export.btn.title", "Export"))
        GUICtrlSetTip($a_idToolBarBtn[2], i18nGet("ventoy.toolbar.export.tip", "Export Ventoy configuration to file"))
        GUICtrlSetData($a_idToolBarBtn[3], i18nGet("open.btn.title", "Open"))
        GUICtrlSetTip($a_idToolBarBtn[3], i18nGet("ventoy.toolbar.open.tip", "Open ventoy.json file in text editor"))
        GUICtrlSetData($a_idToolBarBtn[4], i18nGet("ventoy.toolbar.plugson.title", "Ventoy"))
        GUICtrlSetTip($a_idToolBarBtn[4], i18nGet("ventoy.toolbar.plugson.tip", "Launch VentoyPlugson GUI configuration utility"))
        GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("save.btn.title", "Save"))
        GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("ventoy.toolbar.save.tip", "Save Ventoy configuration to ventoy.json"))
        GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.title", "Cancel"))
        GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.tip", "Discard changes and reload saved configuration"))
    EndIf
EndFunc

Func viewVentoyToolBar($hParent = 0)
    ; Set accelerators for Ventoy view: {UP} and {DOWN} for boot entry re-ordering
    Local $aVentoyAccel[2][2] = [["{UP}", $idViewVentoyDummyUp], ["{DOWN}", $idViewVentoyDummyDown]]
    If $hParent <> 0 Then
        GUISetAccelerators($aVentoyAccel, $hParent)
    ElseIf $hViewVentoy <> 0 Then
        GUISetAccelerators($aVentoyAccel, $hViewVentoy)
    EndIf

    ; Button Index 0: [Reset]
    GUICtrlSetData($a_idToolBarBtn[0], i18nGet("reset.btn.title", "Reset"))
    GUICtrlSetTip($a_idToolBarBtn[0], i18nGet("ventoy.toolbar.reset.tip", "Reset all Ventoy settings to defaults"))
    GUICtrlSetState($a_idToolBarBtn[0], $GUI_SHOW)

    ; Button Index 1: [Import]
    GUICtrlSetData($a_idToolBarBtn[1], i18nGet("import.btn.title", "Import"))
    GUICtrlSetTip($a_idToolBarBtn[1], i18nGet("ventoy.toolbar.import.tip", "Import Ventoy configuration file"))
    GUICtrlSetState($a_idToolBarBtn[1], $GUI_SHOW)

    ; Button Index 2: [Export]
    GUICtrlSetData($a_idToolBarBtn[2], i18nGet("export.btn.title", "Export"))
    GUICtrlSetTip($a_idToolBarBtn[2], i18nGet("ventoy.toolbar.export.tip", "Export Ventoy configuration to file"))
    GUICtrlSetState($a_idToolBarBtn[2], $GUI_SHOW)

    ; Button Index 3: [Open]
    GUICtrlSetData($a_idToolBarBtn[3], i18nGet("open.btn.title", "Open"))
    GUICtrlSetTip($a_idToolBarBtn[3], i18nGet("ventoy.toolbar.open.tip", "Open ventoy.json file in text editor"))
    GUICtrlSetState($a_idToolBarBtn[3], $GUI_SHOW)

    ; Button Index 4: [Ventoy]
    GUICtrlSetData($a_idToolBarBtn[4], i18nGet("ventoy.toolbar.plugson.title", "Ventoy"))
    GUICtrlSetTip($a_idToolBarBtn[4], i18nGet("ventoy.toolbar.plugson.tip", "Launch VentoyPlugson GUI configuration utility"))
    GUICtrlSetState($a_idToolBarBtn[4], $GUI_SHOW)

    ; Button Index 6: [Save]
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("save.btn.title", "Save"))
    GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 2], i18nGet("ventoy.toolbar.save.tip", "Save Ventoy configuration to ventoy.json"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 2], $GUI_SHOW)

    ; Button Index 7: [Cancel]
    GUICtrlSetData($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.title", "Cancel"))
    GUICtrlSetTip($a_idToolBarBtn[$iToolBarBtnCol - 1], i18nGet("cancel.btn.tip", "Discard changes and reload saved configuration"))
    GUICtrlSetState($a_idToolBarBtn[$iToolBarBtnCol - 1], $GUI_SHOW)
EndFunc

Func viewVentoyApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hViewVentoy)

    GUICtrlSetColor($idViewVentoyTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewVentoyTitle, themeColor("main.view.bg"))

    ; Section 1: Theme
    GUICtrlSetColor($idViewVentoyThemeLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewVentoyThemeLbl, themeColor("main.view.bg"))

    ; Section 2: Variant
    GUICtrlSetColor($idViewVentoyVariantLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewVentoyVariantLbl, themeColor("main.view.bg"))

    ; Section 3: Boot Entries
    GUICtrlSetColor($idViewVentoyBootLbl, themeColor("text.primary"))
    GUICtrlSetBkColor($idViewVentoyBootLbl, themeColor("main.view.bg"))
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Event Dispatcher
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewVentoyHandleEvent($idMsg)
    Switch $idMsg
        ; Keyboard Accelerators for Boot Entries
        Case $idViewVentoyDummyUp
            Local $sSel = _GUICtrlListView_GetSelectedIndices($hViewVentoyBootList)
            If $sSel <> "" Then _ViewVentoyMoveEntryUp()

        Case $idViewVentoyDummyDown
            Local $sSel = _GUICtrlListView_GetSelectedIndices($hViewVentoyBootList)
            If $sSel <> "" Then _ViewVentoyMoveEntryDown()

        ; Theme Dropdown Change
        Case $idViewVentoyThemeCmb
            _ViewVentoyOnThemeChange()

        ; Theme Variant Controls
        Case $idViewVentoyVariantResetBtn
            _ViewVentoyResetVariant()

        Case $idViewVentoyVariantPreviewBtn
            _ViewVentoyPreviewVariant()

        Case $idViewVentoyVariantRefreshBtn
            _ViewVentoyRefreshVariants()

        Case $idViewVentoyVariantSetBtn
            _ViewVentoySetVariant()

        ; Boot Entries Controls
        Case $idViewVentoyBootResetBtn
            _ViewVentoyResetBootEntries()

        Case $idViewVentoyBootAddBtn
            _ViewVentoyShowBootDialog(False)

        Case $idViewVentoyBootRemoveBtn
            _ViewVentoyRemoveBootEntries()

        Case $idViewVentoyBootEditBtn
            _ViewVentoyShowBootDialog(True)

        ; Toolbar Button 0: [Reset]
        Case $a_idToolBarBtn[0]
            viewVentoyReset()
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("ventoy.status.reset", "Reset Ventoy configuration settings to defaults"))

        ; Toolbar Button 1: [Import]
        Case $a_idToolBarBtn[1]
            _ViewVentoyImportConfig()

        ; Toolbar Button 2: [Export]
        Case $a_idToolBarBtn[2]
            _ViewVentoyExportConfig()

        ; Toolbar Button 3: [Open]
        Case $a_idToolBarBtn[3]
            _ViewVentoyOpenConfigFile()

        ; Toolbar Button 4: [Ventoy / Plugson]
        Case $a_idToolBarBtn[4]
            _ViewVentoyRunPlugson()

        ; Toolbar Button 6: [Save]
        Case $a_idToolBarBtn[$iToolBarBtnCol - 2]
            If viewVentoySaveData() Then
                appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("ventoy.status.saved", "Saved Ventoy configuration successfully"))
            Else
                appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("status.error", "Error"))
            EndIf

        ; Toolbar Button 7: [Cancel]
        Case $a_idToolBarBtn[$iToolBarBtnCol - 1]
            viewVentoyLoadData()
            appSetStatus(i18nGet("status.title", "Status: ") & i18nGet("ventoy.status.canceled", "Reverted Ventoy configuration to saved settings"))
    EndSwitch
EndFunc
