;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/modules/control.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Libraries
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <SendMessage.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Edit Control Helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Sets a cue banner (placeholder text) for an input or edit control
Func controlSetCueBanner($hWnd, $sText, $bOnFocus = False)
    If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
    Local $tText = DllStructCreate("wchar[" & (StringLen($sText) + 1) & "]")
    DllStructSetData($tText, 1, $sText)
    Return _SendMessage($hWnd, 0x1501, $bOnFocus, $tText, 0, "wparam", "struct*") = 1 ; $EM_SETCUEBANNER = 0x1501
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ListView Helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Swaps the column values between two rows in a ListView
Func controlListViewSwapRows($hListView, $iIdx1, $iIdx2, $iStartCol = 0, $iEndCol = -1)
    If Not IsHWnd($hListView) Then $hListView = GUICtrlGetHandle($hListView)
    Local $iColCount = _GUICtrlListView_GetColumnCount($hListView)
    If $iEndCol < 0 Or $iEndCol >= $iColCount Then $iEndCol = $iColCount - 1
    For $c = $iStartCol To $iEndCol
        Local $sVal1 = _GUICtrlListView_GetItemText($hListView, $iIdx1, $c)
        Local $sVal2 = _GUICtrlListView_GetItemText($hListView, $iIdx2, $c)
        _GUICtrlListView_SetItemText($hListView, $iIdx1, $sVal2, $c)
        _GUICtrlListView_SetItemText($hListView, $iIdx2, $sVal1, $c)
    Next
EndFunc

; Moves the selected item up by one row
Func controlListViewMoveItemUp($hListView, $iStartCol = 0, $iEndCol = -1)
    If Not IsHWnd($hListView) Then $hListView = GUICtrlGetHandle($hListView)
    Local $sSel = _GUICtrlListView_GetSelectedIndices($hListView)
    If $sSel = "" Then Return False
    Local $iIndex = Number($sSel)
    If $iIndex <= 0 Then Return False
    controlListViewSwapRows($hListView, $iIndex, $iIndex - 1, $iStartCol, $iEndCol)
    _GUICtrlListView_SetItemSelected($hListView, $iIndex, False)
    _GUICtrlListView_SetItemSelected($hListView, $iIndex - 1, True, True)
    Return True
EndFunc

; Moves the selected item down by one row
Func controlListViewMoveItemDown($hListView, $iStartCol = 0, $iEndCol = -1)
    If Not IsHWnd($hListView) Then $hListView = GUICtrlGetHandle($hListView)
    Local $sSel = _GUICtrlListView_GetSelectedIndices($hListView)
    If $sSel = "" Then Return False
    Local $iIndex = Number($sSel)
    Local $iCount = _GUICtrlListView_GetItemCount($hListView)
    If $iIndex < 0 Or $iIndex >= $iCount - 1 Then Return False
    controlListViewSwapRows($hListView, $iIndex, $iIndex + 1, $iStartCol, $iEndCol)
    _GUICtrlListView_SetItemSelected($hListView, $iIndex, False)
    _GUICtrlListView_SetItemSelected($hListView, $iIndex + 1, True, True)
    Return True
EndFunc
