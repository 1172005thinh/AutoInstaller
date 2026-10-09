;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/modules/export.au3
; Author:   1172005thinh
; Repo:     github.com/1172005thinh/AutoInstaller
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include-once

; Modules
#include "xml.au3"
#include "data.au3"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Export configuration from Scripting.Dictionary to an autounattend.xml file
Func unattendExportToFile($sFilePath, $oData, $sBaseSampleFile = "")
    If Not IsObj($oData) Then Return False

    If $sBaseSampleFile = "" Then $sBaseSampleFile = xmlGetSamplePath()
    xmlEnsureFile("", $sBaseSampleFile)
    Local $oDoc = xmlCreateDoc()
    If Not IsObj($oDoc) Then Return False
    If Not $oDoc.load($sBaseSampleFile) Then Return False

    ; 1. Windows Customization
    Local $sArch = $oData.Exists("Architecture") ? $oData.Item("Architecture") : "amd64"
    If $sArch = "" Then $sArch = "amd64"
    Local $oComponents = $oDoc.selectNodes("//u:component[@processorArchitecture]")
    If IsObj($oComponents) Then
        For $i = 0 To $oComponents.length - 1
            $oComponents.item($i).setAttribute("processorArchitecture", $sArch)
        Next
    EndIf

    If $oData.Exists("Edition") Then
        _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:ImageInstall/u:OSImage/u:InstallFrom/u:MetaData[u:Key='/IMAGE/NAME']/u:Value", $oData.Item("Edition"))
    EndIf

    If $oData.Exists("ProductKey") Then
        _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:UserData/u:ProductKey/u:Key", $oData.Item("ProductKey"))
    EndIf

    If $oData.Exists("ComputerName") Then
        _xmlSetText($oDoc, "//u:settings[@pass='specialize']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:ComputerName", $oData.Item("ComputerName"))
    EndIf

    ; 2. Regional & Locales
    Local $sSysLang = $oData.Exists("SysLang") ? $oData.Item("SysLang") : "English (United States)"
    Local $sSysTag = dataLookup("locales.csv", $sSysLang, 0, 1)
    If $sSysTag = "" Then $sSysTag = $sSysLang

    Local $sUsrLang = $oData.Exists("UsrLang") ? $oData.Item("UsrLang") : "English (United States)"
    Local $sUsrTag = dataLookup("locales.csv", $sUsrLang, 0, 1)
    If $sUsrTag = "" Then $sUsrTag = $sUsrLang

    Local $sUILang = $oData.Exists("UILang") ? $oData.Item("UILang") : "English (United States)"
    Local $sUITag = dataLookup("uilangs.csv", $sUILang, 0, 1)
    If $sUITag = "" Then $sUITag = $sUILang

    Local $sLangHex = dataLookup("uilangs.csv", $sUILang, 0, 2)
    If $sLangHex = "" Then $sLangHex = "0409"

    Local $sKbLayout = $oData.Exists("KbLayout") ? $oData.Item("KbLayout") : "US"
    Local $sKbCode = dataLookup("kblayouts.csv", $sKbLayout, 0, 1)
    If $sKbCode = "" Then $sKbCode = $sKbLayout

    Local $sFullInputLocale = $sKbCode
    If Not StringInStr($sKbCode, ":") Then
        $sFullInputLocale = $sLangHex & ":" & $sKbCode
    EndIf

    Local $sTZ = $oData.Exists("TimeZone") ? $oData.Item("TimeZone") : "(UTC+07:00) SE Asia Standard Time"
    Local $sTZTag = dataLookup("timezones.csv", $sTZ, 0, 1)
    If $sTZTag = "" Then $sTZTag = $sTZ

    _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-International-Core-WinPE']/u:InputLocale", $sFullInputLocale)
    _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-International-Core-WinPE']/u:SystemLocale", $sSysTag)
    _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-International-Core-WinPE']/u:UILanguage", $sUITag)
    _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-International-Core-WinPE']/u:UserLocale", $sUsrTag)
    _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-International-Core-WinPE']/u:SetupUILanguage/u:UILanguage", $sUITag)

    _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-International-Core']/u:InputLocale", $sFullInputLocale)
    _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-International-Core']/u:SystemLocale", $sSysTag)
    _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-International-Core']/u:UILanguage", $sUITag)
    _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-International-Core']/u:UserLocale", $sUsrTag)
    _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:TimeZone", $sTZTag)

    ; 3. Disk Partitions Management
    Local $sDiskID = $oData.Exists("DiskID") ? $oData.Item("DiskID") : "$$VT_WINDOWS_DISK_1ST_NONVTOY$$"
    Local $sOSPartID = $oData.Exists("OSPartitionID") ? $oData.Item("OSPartitionID") : "3"
    Local $iPartAuto = $oData.Exists("PartitionAutomation") ? Number($oData.Item("PartitionAutomation")) : 2

    _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:DiskConfiguration/u:Disk/u:DiskID", $sDiskID)
    _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:ImageInstall/u:OSImage/u:InstallTo/u:DiskID", $sDiskID)
    _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:ImageInstall/u:OSImage/u:InstallTo/u:PartitionID", $sOSPartID)

    If $iPartAuto = 2 Then
        _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:DiskConfiguration/u:Disk/u:WillWipeDisk", "true")
        _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:DiskConfiguration/u:WillShowUI", "OnError")
        _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:ImageInstall/u:OSImage/u:InstallTo/u:WillShowUI", "Never")
    Else
        _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:DiskConfiguration/u:Disk/u:WillWipeDisk", "false")
        _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:DiskConfiguration/u:WillShowUI", "Always")
        _xmlSetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:ImageInstall/u:OSImage/u:InstallTo/u:WillShowUI", "Always")
    EndIf

    ; Rebuild CreatePartitions and ModifyPartitions
    Local $oCreatePartitions = $oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:DiskConfiguration/u:Disk/u:CreatePartitions")
    Local $oModifyPartitions = $oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:DiskConfiguration/u:Disk/u:ModifyPartitions")

    If IsObj($oCreatePartitions) And IsObj($oModifyPartitions) Then
        While $oCreatePartitions.hasChildNodes()
            $oCreatePartitions.removeChild($oCreatePartitions.firstChild)
        WEnd
        While $oModifyPartitions.hasChildNodes()
            $oModifyPartitions.removeChild($oModifyPartitions.firstChild)
        WEnd

        Local $iPartCount = $oData.Exists("PartitionsCount") ? Number($oData.Item("PartitionsCount")) : 0
        For $i = 0 To $iPartCount - 1
            If Not $oData.Exists("Partition_" & $i) Then ContinueLoop
            Local $aPart = StringSplit($oData.Item("Partition_" & $i), "|", 2)
            If UBound($aPart) < 6 Then ContinueLoop

            Local $sOrder = String($i + 1)
            Local $sType = $aPart[1]
            Local $sLabel = $aPart[2]
            Local $sSize = $aPart[3]
            Local $sLetter = $aPart[4]
            Local $sFormat = $aPart[5]

            Local $oCP = _xmlCreateElement($oDoc, "CreatePartition", "", "add")
            $oCP.appendChild(_xmlCreateElement($oDoc, "Order", $sOrder))
            $oCP.appendChild(_xmlCreateElement($oDoc, "Type", $sType))
            If $sSize <> "" And Number($sSize) > 0 Then
                $oCP.appendChild(_xmlCreateElement($oDoc, "Size", $sSize))
            Else
                $oCP.appendChild(_xmlCreateElement($oDoc, "Extend", "true"))
            EndIf
            $oCreatePartitions.appendChild($oCP)

            Local $oMP = _xmlCreateElement($oDoc, "ModifyPartition", "", "add")
            $oMP.appendChild(_xmlCreateElement($oDoc, "Order", $sOrder))
            $oMP.appendChild(_xmlCreateElement($oDoc, "PartitionID", $sOrder))
            If $sLabel <> "" Then $oMP.appendChild(_xmlCreateElement($oDoc, "Label", $sLabel))
            If $sLetter <> "" Then $oMP.appendChild(_xmlCreateElement($oDoc, "Letter", $sLetter))
            If $sFormat <> "" Then $oMP.appendChild(_xmlCreateElement($oDoc, "Format", $sFormat))
            $oModifyPartitions.appendChild($oMP)
        Next
    EndIf

    ; 4. Bypass Hardware Checks
    Local $oRunSync = $oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:RunSynchronous")
    If IsObj($oRunSync) Then
        While $oRunSync.hasChildNodes()
            $oRunSync.removeChild($oRunSync.firstChild)
        WEnd

        Local $aBypasses[6][2] = [ _
            ["BypassTPMCheck", "BypassTPMCheck"], _
            ["BypassRAMCheck", "BypassRAMCheck"], _
            ["BypassSecureBootCheck", "BypassSecureBootCheck"], _
            ["BypassCPUCheck", "BypassCPUCheck"], _
            ["BypassStorageCheck", "BypassStorageCheck"], _
            ["BypassDiskCheck", "BypassDiskCheck"] _
        ]
        Local $iOrder = 1
        For $i = 0 To UBound($aBypasses, 1) - 1
            Local $sKey = $aBypasses[$i][0]
            If $oData.Exists($sKey) And Number($oData.Item($sKey)) = 1 Then
                $oRunSync.appendChild($oDoc.createTextNode(@CRLF & @TAB & @TAB & @TAB & @TAB))
                Local $oCmd = _xmlCreateElement($oDoc, "RunSynchronousCommand", "", "add")
                $oCmd.appendChild($oDoc.createTextNode(@CRLF & @TAB & @TAB & @TAB & @TAB & @TAB))
                $oCmd.appendChild(_xmlCreateElement($oDoc, "Order", String($iOrder)))
                $oCmd.appendChild($oDoc.createTextNode(@CRLF & @TAB & @TAB & @TAB & @TAB & @TAB))
                $oCmd.appendChild(_xmlCreateElement($oDoc, "Path", 'reg.exe add "HKLM\SYSTEM\Setup\LabConfig" /v "' & $aBypasses[$i][1] & '" /t REG_DWORD /d 1 /f'))
                $oCmd.appendChild($oDoc.createTextNode(@CRLF & @TAB & @TAB & @TAB & @TAB & @TAB))
                $oCmd.appendChild(_xmlCreateElement($oDoc, "Description", "Add " & $aBypasses[$i][1]))
                $oCmd.appendChild($oDoc.createTextNode(@CRLF & @TAB & @TAB & @TAB & @TAB))
                $oRunSync.appendChild($oCmd)
                $iOrder += 1
            EndIf
        Next
        If $iOrder > 1 Then
            $oRunSync.appendChild($oDoc.createTextNode(@CRLF & @TAB & @TAB & @TAB))
        EndIf
    EndIf

    ; 5. OOBE & Privacy Settings
    If $oData.Exists("HideEULAPage") Then _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideEULAPage", (Number($oData.Item("HideEULAPage")) = 1) ? "true" : "false")
    If $oData.Exists("HideLocalAccountScreen") Then _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideLocalAccountScreen", (Number($oData.Item("HideLocalAccountScreen")) = 1) ? "true" : "false")
    If $oData.Exists("HideOnlineAccountScreens") Then _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideOnlineAccountScreens", (Number($oData.Item("HideOnlineAccountScreens")) = 1) ? "true" : "false")
    If $oData.Exists("HideWirelessSetupInOOBE") Then _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideWirelessSetupInOOBE", (Number($oData.Item("HideWirelessSetupInOOBE")) = 1) ? "true" : "false")
    If $oData.Exists("ProtectYourPC") Then _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:ProtectYourPC", String(Number($oData.Item("ProtectYourPC")) + 1))

    Local $oFirstLogon = $oDoc.selectSingleNode("//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:FirstLogonCommands")
    If IsObj($oFirstLogon) Then
        Local $oBitLockerCmd = $oDoc.selectSingleNode("//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:FirstLogonCommands/u:SynchronousCommand[contains(u:CommandLine, 'PreventDeviceEncryption')]")
        Local $bBitLockerBypass = ($oData.Exists("PreventBitLocker") And Number($oData.Item("PreventBitLocker")) = 1)
        If $bBitLockerBypass Then
            If Not IsObj($oBitLockerCmd) Then
                Local $oNewBL = _xmlCreateElement($oDoc, "SynchronousCommand", "", "add")
                $oNewBL.appendChild(_xmlCreateElement($oDoc, "Order", "2"))
                $oNewBL.appendChild(_xmlCreateElement($oDoc, "CommandLine", 'reg add "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v "PreventDeviceEncryption" /t REG_DWORD /d 1 /f'))
                $oNewBL.appendChild(_xmlCreateElement($oDoc, "Description", "Disable BitLocker automatic device encryption"))
                $oFirstLogon.appendChild($oNewBL)
            EndIf
        Else
            If IsObj($oBitLockerCmd) Then $oFirstLogon.removeChild($oBitLockerCmd)
        EndIf
    EndIf

    ; 6. Local Accounts Management
    Local $iAccAuto = $oData.Exists("AccountAutomation") ? Number($oData.Item("AccountAutomation")) : 1
    Local $iAccCount = $oData.Exists("AccountsCount") ? Number($oData.Item("AccountsCount")) : 0
    Local $iAutoLogonID = $oData.Exists("AutoLogonID") ? Number($oData.Item("AutoLogonID")) : 1

    Local $oLocalAccounts = $oDoc.selectSingleNode("//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:UserAccounts/u:LocalAccounts")
    If IsObj($oLocalAccounts) Then
        While $oLocalAccounts.hasChildNodes()
            $oLocalAccounts.removeChild($oLocalAccounts.firstChild)
        WEnd

        Local $sAutoUser = ""
        Local $sAutoPass = ""

        For $j = 0 To $iAccCount - 1
            If Not $oData.Exists("Account_" & $j) Then ContinueLoop
            Local $aAcc = StringSplit($oData.Item("Account_" & $j), "|", 2)
            If UBound($aAcc) < 5 Then ContinueLoop

            Local $sID = $aAcc[0]
            Local $sType = $aAcc[1]
            Local $sName = $aAcc[2]
            Local $sDisp = $aAcc[3]
            Local $sPass = $aAcc[4]

            If Number($sID) = $iAutoLogonID Or ($sAutoUser = "" And $j = 0) Then
                $sAutoUser = $sName
                $sAutoPass = $sPass
            EndIf

            Local $oLA = _xmlCreateElement($oDoc, "LocalAccount", "", "add")
            $oLA.appendChild(_xmlCreateElement($oDoc, "Name", $sName))
            $oLA.appendChild(_xmlCreateElement($oDoc, "DisplayName", $sDisp))
            $oLA.appendChild(_xmlCreateElement($oDoc, "Group", ($sType = "Administrator" ? "Administrators" : "Users")))
            Local $oPw = _xmlCreateElement($oDoc, "Password")
            $oPw.appendChild(_xmlCreateElement($oDoc, "Value", $sPass))
            $oPw.appendChild(_xmlCreateElement($oDoc, "PlainText", "true"))
            $oLA.appendChild($oPw)
            $oLocalAccounts.appendChild($oLA)
        Next

        If $iAccAuto = 1 And $sAutoUser <> "" Then
            _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:AutoLogon/u:Username", $sAutoUser)
            _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:AutoLogon/u:Password/u:Value", $sAutoPass)
            _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:AutoLogon/u:Enabled", "true")
        Else
            _xmlSetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:AutoLogon/u:Enabled", "false")
        EndIf
    EndIf

    ; 7. Bloatware Removals
    If $oData.Exists("BloatwareToRemove") Then
        Local $sPkgs = $oData.Item("BloatwareToRemove")
        Local $aPkgs = StringSplit($sPkgs, "|", 2)
        Local $sNewScript = "$selectors = @(" & @CRLF
        For $p = 0 To UBound($aPkgs) - 1
            Local $sPkgItem = StringStripWS($aPkgs[$p], 3)
            If $sPkgItem <> "" Then
                $sNewScript &= @TAB & "'" & $sPkgItem & "';" & @CRLF
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
        If IsObj($oPkgNode) Then $oPkgNode.text = $sNewScript
    EndIf

    ; 8. Custom Scripts
    If $oData.Exists("CustomScripts") And StringStripWS($oData.Item("CustomScripts"), 3) <> "" Then
        Local $oScriptNode = $oDoc.selectSingleNode("//*[@path='C:\Windows\Setup\Scripts\Specialize.ps1']")
        If IsObj($oScriptNode) Then $oScriptNode.text = $oData.Item("CustomScripts")
    EndIf

    $oDoc.save($sFilePath)
    Return FileExists($sFilePath)
EndFunc
