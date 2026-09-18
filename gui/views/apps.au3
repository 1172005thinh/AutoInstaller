;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/views/apps.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Const
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Includes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Libraries
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

; Controls
#include "../controls/button.au3"

; Modules
#include "../modules/i18n.au3"
#include "../modules/theme.au3"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Views/Apps
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func viewAppsCreate($hParent, $iX, $iY, $iW, $iH)
    Global $hviewApps = GUICreate("", $iW, $iH, $iX, $iY, $WS_CHILD, -1, $hParent)
    
    $iX = $iP
    $iY = $iP
    $iW = $iW - $iP * 2
    $iH = $iLblH * 2
    Global $idviewAppsTitle = GUICtrlCreateLabel("", $iX, $iY, $iW, $iH)
    GUICtrlSetFont(-1, 16, 800)
    
    viewAppsApplyLang()
    viewAppsApplyTheme()
    Return $hviewApps
EndFunc

Func viewAppsApplyLang()
    GUICtrlSetData($idviewAppsTitle, i18nGet("apps.title"))
EndFunc

Func viewAppsApplyTheme()
    GUISetBkColor(themeColor("main.view.bg"), $hviewApps)
    
    GUICtrlSetColor($idviewAppsTitle, themeColor("text.primary"))
    GUICtrlSetBkColor($idviewAppsTitle, themeColor("main.view.bg"))
EndFunc