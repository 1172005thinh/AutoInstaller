# Patch & Verification Report: Unattend Script Extraction & SMI Length Limit Fix

## Root Cause Analysis for Error `0x1f` (`0x80220005`)

From the new Panther log in `temp\Panther\UnattendGC\setuperr.log` and `temp\Panther\setuperr.log`:
```text
CSI 00000001 (F) 80220005 [Error,Facility=FACILITY_STATE_MANAGEMENT,Code=5] #121# from CWcmScalarInstanceCore::PutCurrentValue(...)
[setup.exe] SMI data results dump: Source = Name: Microsoft-Windows-Deployment, Language: neutral, ProcessorArchitecture: amd64, PublicKeyToken: 31bf3856ad364e35, VersionScope: nonSxS, /settings/RunSynchronous/RunSynchronousCommand/[Order="2"]/Path
[setup.exe] SMI data results dump: Description = Value is invalid.
[0x060432] IBS The provided unattend file is not valid; hrResult = 0x80220005
[windeploy.exe] Setup.exe failed, returning exit code [0x1f]
```

- **Root Cause**: Windows Setup's SMI schema (`CWcmScalarInstanceCore`) imposes a character limit on `<Path>` values (typically 1024 characters). The previous bootstrap script was ~1400 characters, exceeding this schema constraint and causing `oobe\setup.exe` to reject the answer file during deserialization.

## Resolution

1. **Ultra-Compact Multi-Path Bootstrap Extractor**:
   Condensed the bootstrap extraction command to **322 characters** (well within the SMI schema limit):
   ```xml
   <RunSynchronousCommand wcm:action="add">
       <Order>2</Order>
       <Path>powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "$p=@('C:\Windows\Panther\unattend.xml','C:\Windows\Panther\unattend-original.xml','C:\$WINDOWS.~BT\Sources\Payload\Unattend\Unattend.xml')|?{Test-Path $_}|select -f 1;$x=[xml]::new();$x.Load($p);&amp;([scriptblock]::Create($x.unattend.Extensions.ExtractScript)) $x;"</Path>
   </RunSynchronousCommand>
   ```
2. **Proper Pass Separation**:
   - `windowsPE` pass Order 2 remains `BypassRAMCheck`.
   - `specialize` pass Order 2 contains the compact bootstrap extractor.
3. **BOM-Free Encoding**:
   - All XML files in `ventoy/script/*.xml` remain encoded as clean UTF-8 without BOM.
