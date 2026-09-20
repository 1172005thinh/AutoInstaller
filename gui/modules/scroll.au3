;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/modules/scroll.au3
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
#include <GuiScrollBars.au3>
#include <ScrollBarConstants.au3>
#include <StructureConstants.au3>
#include <WinAPI.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Const
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global Const $g_iScrollbarW = _WinAPI_GetSystemMetrics($SM_CXVSCROLL) > 0 ? _WinAPI_GetSystemMetrics($SM_CXVSCROLL) : 17
Global Const $g_iScrollLineStep = 30
Global Const $g_iScrollWheelStep = 50

Global $g_hMasterViewport = 0
Global $g_iViewportX = 0
Global $g_iViewportY = 0
Global $g_iViewportW = 0
Global $g_iViewportH = 0

Global $g_hActiveCanvas = 0

Global $g_oCanvases = ObjCreate("Scripting.Dictionary")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Modules/Scroll
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Initialize the master clipping Viewport window
Func scrollInitViewport($hParent, $iX, $iY, $iW, $iH)
    $g_iViewportX = $iX
    $g_iViewportY = $iY
    $g_iViewportW = $iW
    $g_iViewportH = $iH

    ; Master Viewport window with clipping and vertical scrollbar capability
    $g_hMasterViewport = GUICreate("", $iW, $iH, $iX, $iY, BitOR($WS_CHILD, $WS_VSCROLL, $WS_CLIPCHILDREN), -1, $hParent)
    _GUIScrollBars_Init($g_hMasterViewport)
    _GUIScrollBars_ShowScrollBar($g_hMasterViewport, $SB_HORZ, False)
    _GUIScrollBars_ShowScrollBar($g_hMasterViewport, $SB_VERT, False)
    GUISetState(@SW_SHOW, $g_hMasterViewport)

    Return $g_hMasterViewport
EndFunc

; Get usable content width to avoid overlap with vertical scrollbar
Func scrollGetContentWidth($iPadding = 0)
    Local $iWidth = $g_iViewportW - $g_iScrollbarW - $iPadding * 2
    If $iWidth <= 0 Then $iWidth = 100
    Return $iWidth
EndFunc

; Create an inner Canvas child window inside the Viewport
Func scrollCreateCanvas($hViewport, $iContentH)
    Local $iCanvasW = $g_iViewportW - $g_iScrollbarW
    ; Canvas window positioned at top-left of Viewport
    Local $hCanvas = GUICreate("", $iCanvasW, $iContentH, 0, 0, $WS_CHILD, -1, $hViewport)

    ; Register Canvas in tracking dictionary
    Local $sKey = String($hCanvas)
    Local $aData[2] = [$iContentH, 0]
    $g_oCanvases.Item($sKey) = $aData

    Return $hCanvas
EndFunc

; Switch active view Canvas, restore its saved position, and configure the viewport scrollbar
Func scrollActivateCanvas($hTargetCanvas)
    If $hTargetCanvas = $g_hActiveCanvas And $g_hActiveCanvas <> 0 Then Return

    ; Hide previously active Canvas
    If $g_hActiveCanvas <> 0 And IsHWnd($g_hActiveCanvas) Then
        GUISetState(@SW_HIDE, $g_hActiveCanvas)
    EndIf

    Local $sKey = String($hTargetCanvas)
    If Not $g_oCanvases.Exists($sKey) Then Return

    Local $aData = $g_oCanvases.Item($sKey)
    Local $iContentH = $aData[0]
    Local $iSavedPos = $aData[1]

    ; Slide target canvas to its remembered scroll position
    WinMove($hTargetCanvas, "", 0, -$iSavedPos)
    GUISetState(@SW_SHOW, $hTargetCanvas)
    $g_hActiveCanvas = $hTargetCanvas

    ; Configure the Master Viewport scrollbar
    Local $tSI = DllStructCreate($tagSCROLLINFO)
    DllStructSetData($tSI, "cbSize", DllStructGetSize($tSI))
    DllStructSetData($tSI, "fMask", BitOR($SIF_RANGE, $SIF_PAGE, $SIF_POS))
    DllStructSetData($tSI, "nMin", 0)
    DllStructSetData($tSI, "nMax", $iContentH)
    DllStructSetData($tSI, "nPage", $g_iViewportH)
    DllStructSetData($tSI, "nPos", $iSavedPos)
    _GUIScrollBars_SetScrollInfo($g_hMasterViewport, $SB_VERT, $tSI)

    ; Show scrollbar only if content exceeds viewport
    If $iContentH > $g_iViewportH Then
        _GUIScrollBars_ShowScrollBar($g_hMasterViewport, $SB_VERT, True)
    Else
        _GUIScrollBars_ShowScrollBar($g_hMasterViewport, $SB_VERT, False)
    EndIf
    _GUIScrollBars_ShowScrollBar($g_hMasterViewport, $SB_HORZ, False)
EndFunc

; Slide active Canvas to a new vertical position
Func scrollTo($iNewPos)
    If Not IsHWnd($g_hActiveCanvas) Then Return
    Local $sKey = String($g_hActiveCanvas)
    If Not $g_oCanvases.Exists($sKey) Then Return

    Local $aData = $g_oCanvases.Item($sKey)
    Local $iContentH = $aData[0]
    Local $iOldPos = $aData[1]

    Local $iMaxPos = $iContentH - $g_iViewportH
    If $iMaxPos < 0 Then $iMaxPos = 0
    If $iNewPos < 0 Then $iNewPos = 0
    If $iNewPos > $iMaxPos Then $iNewPos = $iMaxPos

    If $iNewPos = $iOldPos Then Return

    ; Smoothly move the entire Canvas window natively
    WinMove($g_hActiveCanvas, "", 0, -$iNewPos)

    ; Update Viewport scrollbar thumb
    Local $tSI = DllStructCreate($tagSCROLLINFO)
    DllStructSetData($tSI, "cbSize", DllStructGetSize($tSI))
    DllStructSetData($tSI, "fMask", $SIF_POS)
    DllStructSetData($tSI, "nPos", $iNewPos)
    _GUIScrollBars_SetScrollInfo($g_hMasterViewport, $SB_VERT, $tSI)

    ; Save current scroll position
    $aData[1] = $iNewPos
    $g_oCanvases.Item($sKey) = $aData
EndFunc

; Set background color of the Viewport window
Func scrollSetViewportBkColor($nColor)
    If IsHWnd($g_hMasterViewport) Then
        GUISetBkColor($nColor, $g_hMasterViewport)
    EndIf
EndFunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Windows Message Handlers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Handler for WM_VSCROLL messages
Func scrollOnWM_VSCROLL($hWnd, $iMsg, $wParam, $lParam)
    #forceref $iMsg, $lParam

    ; Only handle scroll messages targeted to the master viewport
    If $hWnd <> $g_hMasterViewport Then Return $GUI_RUNDEFMSG
    If Not IsHWnd($g_hActiveCanvas) Then Return 0

    Local $sKey = String($g_hActiveCanvas)
    If Not $g_oCanvases.Exists($sKey) Then Return 0

    Local $aData = $g_oCanvases.Item($sKey)
    Local $iContentH = $aData[0]
    Local $iOldPos = $aData[1]
    Local $iNewPos = $iOldPos

    Local $iScrollCode = BitAND($wParam, 0x0000FFFF)
    Switch $iScrollCode
        Case $SB_LINEUP
            $iNewPos -= $g_iScrollLineStep

        Case $SB_LINEDOWN
            $iNewPos += $g_iScrollLineStep

        Case $SB_PAGEUP
            $iNewPos -= $g_iViewportH

        Case $SB_PAGEDOWN
            $iNewPos += $g_iViewportH

        Case $SB_TOP
            $iNewPos = 0

        Case $SB_BOTTOM
            $iNewPos = $iContentH - $g_iViewportH

        Case $SB_THUMBTRACK, $SB_THUMBPOSITION
            Local $tSI = _GUIScrollBars_GetScrollInfoEx($g_hMasterViewport, $SB_VERT)
            $iNewPos = DllStructGetData($tSI, "nTrackPos")

        Case Else
            Return 0
    EndSwitch

    scrollTo($iNewPos)
    Return 0
EndFunc

; Handler for WM_MOUSEWHEEL messages
Func scrollOnWM_MOUSEWHEEL($hWnd, $iMsg, $wParam, $lParam)
    #forceref $hWnd, $iMsg, $lParam

    If Not IsHWnd($g_hActiveCanvas) Then Return $GUI_RUNDEFMSG

    ; Check if mouse cursor is over the Viewport window
    Local $tPoint = _WinAPI_GetMousePos()
    Local $tRect = _WinAPI_GetWindowRect($g_hMasterViewport)
    Local $iMouseX = DllStructGetData($tPoint, "X")
    Local $iMouseY = DllStructGetData($tPoint, "Y")

    If $iMouseX < DllStructGetData($tRect, "Left") Or $iMouseX > DllStructGetData($tRect, "Right") Or _
       $iMouseY < DllStructGetData($tRect, "Top") Or $iMouseY > DllStructGetData($tRect, "Bottom") Then
        Return $GUI_RUNDEFMSG
    EndIf

    ; Parse signed wheel delta
    Local $iWheelDelta = BitShift($wParam, 16)
    If $iWheelDelta > 0x7FFF Then $iWheelDelta -= 0x10000

    Local $sKey = String($g_hActiveCanvas)
    Local $aData = $g_oCanvases.Item($sKey)
    Local $iNewPos = $aData[1]

    If $iWheelDelta > 0 Then
        $iNewPos -= $g_iScrollWheelStep
    ElseIf $iWheelDelta < 0 Then
        $iNewPos += $g_iScrollWheelStep
    EndIf

    scrollTo($iNewPos)
    Return 0
EndFunc
