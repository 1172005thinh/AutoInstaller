;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/modules/xml.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Includes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Libraries
#include <FileConstants.au3>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Const
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Global Const $rUnattendDir = @ScriptDir & "/unattend/"
Global Const $rUnattendSampleXml = $rUnattendDir & "sample.xml"
Global Const $rUnattendAutoXml = $rUnattendDir & "AutoInstaller.xml"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Modules/XML
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Ensure AutoInstaller.xml exists by copying sample.xml if missing
Func xmlEnsureFile($sTargetFile = $rUnattendAutoXml, $sSampleFile = $rUnattendSampleXml)
    If Not FileExists($sTargetFile) Then
        If FileExists($sSampleFile) Then
            FileCopy($sSampleFile, $sTargetFile, $FC_CREATEPATH)
        EndIf
    EndIf
    Return FileExists($sTargetFile)
EndFunc

; Initialize and configure MSXML2.DOMDocument object
Func xmlCreateDoc()
    Local $oDoc = ObjCreate("MSXML2.DOMDocument.6.0")
    If Not IsObj($oDoc) Then
        $oDoc = ObjCreate("MSXML2.DOMDocument")
    EndIf
    If IsObj($oDoc) Then
        $oDoc.async = False
        $oDoc.preserveWhiteSpace = True
        $oDoc.setProperty("SelectionNamespaces", "xmlns:u='urn:schemas-microsoft-com:unattend' xmlns:wcm='http://schemas.microsoft.com/WMIConfig/2002/State'")
    EndIf
    Return $oDoc
EndFunc

; Get node text safely
Func _xmlGetText($oDoc, $sXPath, $sDefault = "")
    Local $oNode = $oDoc.selectSingleNode($sXPath)
    If IsObj($oNode) Then Return $oNode.text
    Return $sDefault
EndFunc

; Set node text safely
Func _xmlSetText($oDoc, $sXPath, $sText)
    Local $oNode = $oDoc.selectSingleNode($sXPath)
    If IsObj($oNode) Then
        $oNode.text = $sText
        Return True
    EndIf
    Return False
EndFunc

; Load all values from XML file into a Scripting.Dictionary
Func xmlLoadValues($sFilePath = $rUnattendAutoXml)
    Local $oDict = ObjCreate("Scripting.Dictionary")
    xmlEnsureFile($sFilePath, $rUnattendSampleXml)

    Local $oDoc = xmlCreateDoc()
    If Not IsObj($oDoc) Then Return $oDict
    If Not $oDoc.load($sFilePath) Then Return $oDict

    ; 1. System & Identity
    $oDict.Item("ComputerName") = _xmlGetText($oDoc, "//u:settings[@pass='specialize']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:ComputerName", "PC")
    $oDict.Item("Username") = _xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:AutoLogon/u:Username", "OEM")
    $oDict.Item("Password") = _xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:AutoLogon/u:Password/u:Value", "")
    Local $sAutoLogon = _xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:AutoLogon/u:Enabled", "true")
    $oDict.Item("AutoLogonEnabled") = (StringLower($sAutoLogon) = "true" Or $sAutoLogon = "1") ? 1 : 0

    ; 2. Edition & Regional
    $oDict.Item("Edition") = _xmlGetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:ImageInstall/u:OSImage/u:InstallFrom/u:MetaData[u:Key='/IMAGE/NAME']/u:Value", "Windows 11 Pro")
    $oDict.Item("ProductKey") = _xmlGetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:UserData/u:ProductKey/u:Key", "")
    $oDict.Item("TimeZone") = _xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:TimeZone", "SE Asia Standard Time")
    $oDict.Item("UILanguage") = _xmlGetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-International-Core-WinPE']/u:UILanguage", "en-US")

    ; 3. LabConfig Bypasses
    $oDict.Item("BypassTPMCheck") = IsObj($oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:RunSynchronous/u:RunSynchronousCommand[contains(u:Path, 'BypassTPMCheck')]")) ? 1 : 0
    $oDict.Item("BypassRAMCheck") = IsObj($oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:RunSynchronous/u:RunSynchronousCommand[contains(u:Path, 'BypassRAMCheck')]")) ? 1 : 0
    $oDict.Item("BypassSecureBootCheck") = IsObj($oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:RunSynchronous/u:RunSynchronousCommand[contains(u:Path, 'BypassSecureBootCheck')]")) ? 1 : 0
    $oDict.Item("BypassCPUCheck") = IsObj($oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:RunSynchronous/u:RunSynchronousCommand[contains(u:Path, 'BypassCPUCheck')]")) ? 1 : 0
    $oDict.Item("BypassStorageCheck") = IsObj($oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:RunSynchronous/u:RunSynchronousCommand[contains(u:Path, 'BypassStorageCheck')]")) ? 1 : 0
    $oDict.Item("BypassDiskCheck") = IsObj($oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:RunSynchronous/u:RunSynchronousCommand[contains(u:Path, 'BypassDiskCheck')]")) ? 1 : 0

    ; 4. OOBE & Privacy
    $oDict.Item("HideEULAPage") = (StringLower(_xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideEULAPage", "true")) = "true") ? 1 : 0
    $oDict.Item("HideLocalAccountScreen") = (StringLower(_xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideLocalAccountScreen", "true")) = "true") ? 1 : 0
    $oDict.Item("HideOnlineAccountScreens") = (StringLower(_xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideOnlineAccountScreens", "true")) = "true") ? 1 : 0
    $oDict.Item("HideWirelessSetupInOOBE") = (StringLower(_xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideWirelessSetupInOOBE", "true")) = "true") ? 1 : 0
    $oDict.Item("ProtectYourPC") = Number(_xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:ProtectYourPC", "3"))
    $oDict.Item("PreventBitLocker") = IsObj($oDoc.selectSingleNode("//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:FirstLogonCommands/u:SynchronousCommand[contains(u:CommandLine, 'PreventDeviceEncryption')]")) ? 1 : 0

    ; 5. Package Removals
    Local $oPkgFile = $oDoc.selectSingleNode("//*[@path='C:\Windows\Setup\Scripts\RemovePackages.ps1']")
    Local $sPkgScript = IsObj($oPkgFile) ? $oPkgFile.text : ""
    Local $aMatches = StringRegExp($sPkgScript, "'([^']+)'", 3)
    Local $sPkgList = ""
    If Not @error Then
        For $i = 0 To UBound($aMatches) - 1
            $sPkgList &= $aMatches[$i] & "|"
        Next
    EndIf
    $oDict.Item("PackagesToRemove") = $sPkgList

    Return $oDict
EndFunc

; Save values from Dictionary back into XML file
Func xmlSaveValues($sFilePath, $oDict)
    Local $oDoc = xmlCreateDoc()
    If Not IsObj($oDoc) Then Return False
    If Not $oDoc.load($sFilePath) Then
        ; Fallback: load sample template
        If Not $oDoc.load($rUnattendSampleXml) Then Return False
    EndIf

    ; 1. System & Identity
    If $oDict.Exists("ComputerName") Then
        _xmlSetText($oDoc, "//u:settings[@pass='specialize']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:ComputerName", $oDict.Item("ComputerName"))
    EndIf
    If $oDict.Exists("Username") Then
        Local $sUser = $oDict.Item("Username")
        _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:AutoLogon/u:Username", $sUser)
        _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:UserAccounts/u:LocalAccounts/u:LocalAccount/u:Name", $sUser)
        _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:UserAccounts/u:LocalAccounts/u:LocalAccount/u:DisplayName", $sUser)
    EndIf
    If $oDict.Exists("Password") Then
        Local $sPass = $oDict.Item("Password")
        _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:AutoLogon/u:Password/u:Value", $sPass)
        _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:UserAccounts/u:LocalAccounts/u:LocalAccount/u:Password/u:Value", $sPass)
    EndIf
    If $oDict.Exists("AutoLogonEnabled") Then
        Local $sEnabled = ($oDict.Item("AutoLogonEnabled") = 1) ? "true" : "false"
        _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:AutoLogon/u:Enabled", $sEnabled)
    EndIf

    ; 2. Edition & Regional
    If $oDict.Exists("Edition") Then
        _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:ImageInstall/u:OSImage/u:InstallFrom/u:MetaData[u:Key='/IMAGE/NAME']/u:Value", $oDict.Item("Edition"))
    EndIf
    If $oDict.Exists("ProductKey") Then
        _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:UserData/u:ProductKey/u:Key", $oDict.Item("ProductKey"))
    EndIf
    If $oDict.Exists("TimeZone") Then
        _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:TimeZone", $oDict.Item("TimeZone"))
    EndIf
    If $oDict.Exists("UILanguage") Then
        Local $sLang = $oDict.Item("UILanguage")
        _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-International-Core-WinPE']/u:UILanguage", $sLang)
        _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-International-Core-WinPE']/u:SystemLocale", $sLang)
        _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-International-Core-WinPE']/u:UserLocale", $sLang)
        _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-International-Core-WinPE']/u:SetupUILanguage/u:UILanguage", $sLang)
        _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-International-Core']/u:UILanguage", $sLang)
        _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-International-Core']/u:SystemLocale", $sLang)
        _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-International-Core']/u:UserLocale", $sLang)
    EndIf

    ; 3. OOBE & Privacy
    If $oDict.Exists("HideEULAPage") Then
        _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideEULAPage", ($oDict.Item("HideEULAPage") = 1) ? "true" : "false")
    EndIf
    If $oDict.Exists("HideLocalAccountScreen") Then
        _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideLocalAccountScreen", ($oDict.Item("HideLocalAccountScreen") = 1) ? "true" : "false")
    EndIf
    If $oDict.Exists("HideOnlineAccountScreens") Then
        _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideOnlineAccountScreens", ($oDict.Item("HideOnlineAccountScreens") = 1) ? "true" : "false")
    EndIf
    If $oDict.Exists("HideWirelessSetupInOOBE") Then
        _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideWirelessSetupInOOBE", ($oDict.Item("HideWirelessSetupInOOBE") = 1) ? "true" : "false")
    EndIf
    If $oDict.Exists("ProtectYourPC") Then
        _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:ProtectYourPC", String($oDict.Item("ProtectYourPC")))
    EndIf

    ; 4. Update Package Removals in RemovePackages.ps1
    If $oDict.Exists("PackagesToRemove") Then
        Local $sPkgs = $oDict.Item("PackagesToRemove")
        Local $aPkgs = StringSplit($sPkgs, "|", 2)
        Local $sNewScript = "$selectors = @(" & @CRLF
        For $i = 0 To UBound($aPkgs) - 1
            If StringStripWS($aPkgs[$i], 3) <> "" Then
                $sNewScript &= @TAB & "'" & StringStripWS($aPkgs[$i], 3) & "';" & @CRLF
            EndIf
        Next
        $sNewScript &= ");" & @CRLF & _
            "$getCommand = {" & @CRLF & _
            "  Get-AppxProvisionedPackage -Online;" & @CRLF & _
            "};" & @CRLF & _
            "$filterCommand = {" & @CRLF & _
            "  $_.DisplayName -eq $selector;" & @CRLF & _
            "};" & @CRLF & _
            "$removeCommand = {" & @CRLF & _
            "  [CmdletBinding()]" & @CRLF & _
            "  param(" & @CRLF & _
            "    [Parameter( Mandatory, ValueFromPipeline )]" & @CRLF & _
            "    $InputObject" & @CRLF & _
            "  );" & @CRLF & _
            "  process {" & @CRLF & _
            "    $InputObject | Remove-AppxProvisionedPackage -AllUsers -Online -ErrorAction 'Continue';" & @CRLF & _
            "  }" & @CRLF & _
            "};" & @CRLF & _
            "$type = 'Package';" & @CRLF & _
            "$logfile = 'C:\Windows\Setup\Scripts\RemovePackages.log';" & @CRLF & _
            "& {" & @CRLF & _
            "	$installed = & $getCommand;" & @CRLF & _
            "	foreach( $selector in $selectors ) {" & @CRLF & _
            "		$result = [ordered] @{" & @CRLF & _
            "			Selector = $selector;" & @CRLF & _
            "		};" & @CRLF & _
            "		$found = $installed | Where-Object -FilterScript $filterCommand;" & @CRLF & _
            "		if( $found ) {" & @CRLF & _
            "			$result.Output = $found | & $removeCommand;" & @CRLF & _
            "			if( $? ) {" & @CRLF & _
            "				$result.Message = ""$type removed."";" & @CRLF & _
            "			} else {" & @CRLF & _
            "				$result.Message = ""$type not removed."";" & @CRLF & _
            "				$result.Error = $Error[0];" & @CRLF & _
            "			}" & @CRLF & _
            "		} else {" & @CRLF & _
            "			$result.Message = ""$type not installed."";" & @CRLF & _
            "		}" & @CRLF & _
            "		$result | ConvertTo-Json -Depth 3 -Compress;" & @CRLF & _
            "	}" & @CRLF & _
            "} *>&1 | Out-String -Width 1KB -Stream >> $logfile;"

        Local $oPkgNode = $oDoc.selectSingleNode("//*[@path='C:\Windows\Setup\Scripts\RemovePackages.ps1']")
        If IsObj($oPkgNode) Then
            $oPkgNode.text = $sNewScript
        EndIf
    EndIf

    ; Save DOM document
    $oDoc.save($sFilePath)
    Return True
EndFunc
