;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:     gui/modules/import.au3
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

; Validate if a file is a valid autounattend.xml
Func unattendImportValidate($sFilePath)
    Return xmlIsValid($sFilePath)
EndFunc

; Import and parse an autounattend.xml into a Scripting.Dictionary
Func unattendImportFromFile($sFilePath)
    If Not unattendImportValidate($sFilePath) Then Return 0

    Local $oDoc = xmlCreateDoc()
    If Not IsObj($oDoc) Then Return 0
    If Not $oDoc.load($sFilePath) Then Return 0

    Local $oDict = ObjCreate("Scripting.Dictionary")

    ; 1. Windows Customization
    Local $oArchNode = $oDoc.selectSingleNode("//u:settings[@pass='specialize']/u:component[@name='Microsoft-Windows-Shell-Setup']")
    Local $sArch = IsObj($oArchNode) ? $oArchNode.getAttribute("processorArchitecture") : "amd64"
    If $sArch = "" Then $sArch = "amd64"
    $oDict.Item("Architecture") = $sArch

    $oDict.Item("Edition") = _xmlGetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:ImageInstall/u:OSImage/u:InstallFrom/u:MetaData[u:Key='/IMAGE/NAME']/u:Value", "Windows 11 Pro")
    $oDict.Item("ProductKey") = _xmlGetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:UserData/u:ProductKey/u:Key", "")
    $oDict.Item("ComputerName") = _xmlGetText($oDoc, "//u:settings[@pass='specialize']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:ComputerName", "PC")

    ; 2. Regional & Locales
    Local $sSysTag = _xmlGetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-International-Core-WinPE']/u:SystemLocale", "en-US")
    Local $sSysName = dataLookup("locales.csv", $sSysTag, 1, 0)
    If $sSysName = "" Then $sSysName = $sSysTag
    $oDict.Item("SysLang") = $sSysName

    Local $sUsrTag = _xmlGetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-International-Core-WinPE']/u:UserLocale", "en-US")
    Local $sUsrName = dataLookup("locales.csv", $sUsrTag, 1, 0)
    If $sUsrName = "" Then $sUsrName = $sUsrTag
    $oDict.Item("UsrLang") = $sUsrName
    $oDict.Item("SysUsrLangSame") = ($sSysTag = $sUsrTag) ? 1 : 0

    Local $sUITag = _xmlGetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-International-Core-WinPE']/u:UILanguage", "en-US")
    Local $sUIName = dataLookup("uilangs.csv", $sUITag, 1, 0)
    If $sUIName = "" Then $sUIName = $sUITag
    $oDict.Item("UILang") = $sUIName

    Local $sKbTag = _xmlGetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-International-Core-WinPE']/u:InputLocale", "0409:00000409")
    Local $sKbName = dataLookup("kblayouts.csv", $sKbTag, 1, 0)
    If $sKbName = "" Then $sKbName = $sKbTag
    $oDict.Item("KbLayout") = $sKbName

    Local $sTZTag = _xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:TimeZone", "SE Asia Standard Time")
    Local $sTZName = dataLookup("timezones.csv", $sTZTag, 1, 0)
    If $sTZName = "" Then $sTZName = $sTZTag
    $oDict.Item("TimeZone") = $sTZName

    ; 3. Disk Partitions Management
    $oDict.Item("DiskID") = _xmlGetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:DiskConfiguration/u:Disk/u:DiskID", "$$VT_WINDOWS_DISK_1ST_NONVTOY$$")
    $oDict.Item("OSPartitionID") = _xmlGetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:ImageInstall/u:OSImage/u:InstallTo/u:PartitionID", "3")

    Local $sDiskUI = StringLower(_xmlGetText($oDoc, "//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:DiskConfiguration/u:WillShowUI", "onerror"))
    Local $iPartAuto = 2
    If $sDiskUI = "always" Then
        $iPartAuto = 1
    ElseIf Not IsObj($oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:DiskConfiguration")) Then
        $iPartAuto = 0
    EndIf
    $oDict.Item("PartitionAutomation") = $iPartAuto

    Local $oCreateParts = $oDoc.selectNodes("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:DiskConfiguration/u:Disk/u:CreatePartitions/u:CreatePartition")
    Local $iPartCount = IsObj($oCreateParts) ? $oCreateParts.length : 0
    Local $bIsGPT = False

    If $iPartCount > 0 Then
        $oDict.Item("PartitionsCount") = $iPartCount
        For $i = 0 To $iPartCount - 1
            Local $oCP = $oCreateParts.item($i)
            Local $sOrder = _xmlGetText($oCP, "u:Order", String($i + 1))
            Local $sType = _xmlGetText($oCP, "u:Type", "Primary")
            If $sType = "EFI" Or $sType = "MSR" Then $bIsGPT = True
            Local $sSize = _xmlGetText($oCP, "u:Size", "")

            Local $oMP = $oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:DiskConfiguration/u:Disk/u:ModifyPartitions/u:ModifyPartition[u:Order='" & $sOrder & "']")
            If Not IsObj($oMP) Then
                $oMP = $oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:DiskConfiguration/u:Disk/u:ModifyPartitions/u:ModifyPartition[u:PartitionID='" & $sOrder & "']")
            EndIf

            Local $sLabel = IsObj($oMP) ? _xmlGetText($oMP, "u:Label", "") : ""
            Local $sLetter = IsObj($oMP) ? _xmlGetText($oMP, "u:Letter", "") : ""
            Local $sFormat = IsObj($oMP) ? _xmlGetText($oMP, "u:Format", "") : ""
            $oDict.Item("Partition_" & $i) = $sOrder & "|" & $sType & "|" & $sLabel & "|" & $sSize & "|" & $sLetter & "|" & $sFormat
        Next
    Else
        $bIsGPT = True
        $oDict.Item("PartitionsCount") = 4
        $oDict.Item("Partition_0") = "1|EFI|System|512||FAT32"
        $oDict.Item("Partition_1") = "2|MSR||16||"
        $oDict.Item("Partition_2") = "3|Primary|Windows|102400|C|NTFS"
        $oDict.Item("Partition_3") = "4|Recovery|Recovery|1024||NTFS"
    EndIf
    $oDict.Item("PartitionType") = $bIsGPT ? "GPT" : "MBR"

    ; 4. Bypass Hardware Checks
    $oDict.Item("BypassTPMCheck") = IsObj($oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:RunSynchronous/u:RunSynchronousCommand[contains(u:Path, 'BypassTPMCheck')]")) ? 1 : 0
    $oDict.Item("BypassRAMCheck") = IsObj($oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:RunSynchronous/u:RunSynchronousCommand[contains(u:Path, 'BypassRAMCheck')]")) ? 1 : 0
    $oDict.Item("BypassSecureBootCheck") = IsObj($oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:RunSynchronous/u:RunSynchronousCommand[contains(u:Path, 'BypassSecureBootCheck')]")) ? 1 : 0
    $oDict.Item("BypassCPUCheck") = IsObj($oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:RunSynchronous/u:RunSynchronousCommand[contains(u:Path, 'BypassCPUCheck')]")) ? 1 : 0
    $oDict.Item("BypassStorageCheck") = IsObj($oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:RunSynchronous/u:RunSynchronousCommand[contains(u:Path, 'BypassStorageCheck')]")) ? 1 : 0
    $oDict.Item("BypassDiskCheck") = IsObj($oDoc.selectSingleNode("//u:settings[@pass='windowsPE']/u:component[@name='Microsoft-Windows-Setup']/u:RunSynchronous/u:RunSynchronousCommand[contains(u:Path, 'BypassDiskCheck')]")) ? 1 : 0

    ; 5. OOBE & Privacy Settings
    $oDict.Item("HideEULAPage") = (StringLower(_xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideEULAPage", "true")) = "true") ? 1 : 0
    $oDict.Item("HideLocalAccountScreen") = (StringLower(_xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideLocalAccountScreen", "true")) = "true") ? 1 : 0
    $oDict.Item("HideOnlineAccountScreens") = (StringLower(_xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideOnlineAccountScreens", "true")) = "true") ? 1 : 0
    $oDict.Item("HideWirelessSetupInOOBE") = (StringLower(_xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:HideWirelessSetupInOOBE", "true")) = "true") ? 1 : 0

    Local $iProtectVal = Number(_xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:OOBE/u:ProtectYourPC", "3"))
    Local $iPrivacySlider = $iProtectVal - 1
    If $iPrivacySlider < 0 Then $iPrivacySlider = 0
    If $iPrivacySlider > 2 Then $iPrivacySlider = 2
    $oDict.Item("ProtectYourPC") = $iPrivacySlider
    $oDict.Item("PreventBitLocker") = IsObj($oDoc.selectSingleNode("//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:FirstLogonCommands/u:SynchronousCommand[contains(u:CommandLine, 'PreventDeviceEncryption')]")) ? 1 : 0

    ; 6. Local Accounts Management
    Local $sAutoLogonEnabled = StringLower(_xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:AutoLogon/u:Enabled", "true"))
    $oDict.Item("AccountAutomation") = ($sAutoLogonEnabled = "true" Or $sAutoLogonEnabled = "1") ? 1 : 0

    Local $oAccs = $oDoc.selectNodes("//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:UserAccounts/u:LocalAccounts/u:LocalAccount")
    Local $iAccCount = IsObj($oAccs) ? $oAccs.length : 0
    Local $sAutoLogonUser = _xmlGetText($oDoc, "//u:settings[@pass='oobeSystem']/u:component[@name='Microsoft-Windows-Shell-Setup']/u:AutoLogon/u:Username", "Admin")
    Local $iAutoLogonIdx = 1

    If $iAccCount > 0 Then
        $oDict.Item("AccountsCount") = $iAccCount
        For $j = 0 To $iAccCount - 1
            Local $oAcc = $oAccs.item($j)
            Local $sName = _xmlGetText($oAcc, "u:Name", "User" & ($j + 1))
            Local $sDisp = _xmlGetText($oAcc, "u:DisplayName", $sName)
            Local $sGrp = _xmlGetText($oAcc, "u:Group", "Administrators")
            Local $sType = ($sGrp = "Administrators") ? "Administrator" : "User"
            Local $sPass = _xmlGetText($oAcc, "u:Password/u:Value", "")
            If $sName = $sAutoLogonUser Then $iAutoLogonIdx = $j + 1
            $oDict.Item("Account_" & $j) = ($j + 1) & "|" & $sType & "|" & $sName & "|" & $sDisp & "|" & $sPass
        Next
    Else
        $oDict.Item("AccountsCount") = 1
        $oDict.Item("Account_0") = "1|Administrator|Admin|Administrator|Password123"
    EndIf
    $oDict.Item("AutoLogonID") = String($iAutoLogonIdx)

    ; 7. Bloatware Removals
    Local $oPkgFile = $oDoc.selectSingleNode("//*[@path='C:\Windows\Setup\Scripts\RemovePackages.ps1']")
    Local $sPkgScript = IsObj($oPkgFile) ? $oPkgFile.text : ""
    Local $aMatches = StringRegExp($sPkgScript, "'([^']+)'", 3)
    Local $sPkgList = ""
    If Not @error Then
        For $k = 0 To UBound($aMatches) - 1
            $sPkgList &= $aMatches[$k] & "|"
        Next
    EndIf
    $oDict.Item("BloatwareToRemove") = $sPkgList

    ; 8. Custom Scripts
    Local $oScriptFile = $oDoc.selectSingleNode("//*[@path='C:\Windows\Setup\Scripts\Specialize.ps1']")
    $oDict.Item("CustomScripts") = IsObj($oScriptFile) ? $oScriptFile.text : ""

    Return $oDict
EndFunc
